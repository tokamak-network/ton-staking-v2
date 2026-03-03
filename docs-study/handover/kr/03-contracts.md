# 3. 핵심 컨트랙트 변경 상세

## 3.1 WinningChallengerTracker (신규)

**경로**: `lib/optimism/packages/contracts-bedrock/src/dispute/WinningChallengerTracker.sol`
**인터페이스**: `lib/optimism/packages/contracts-bedrock/src/dispute/IWinningChallengerTracker.sol`

FaultDisputeGame의 **EVM 24KB 제한**을 해결하기 위해 분리된 외부 컨트랙트. 사이즈 1,203 bytes.

```solidity
contract WinningChallengerTracker {
    // game address => challenger address => is winner
    mapping(address => mapping(address => bool)) private _isWinner;
    // game address => array of winners
    mapping(address => address[]) private _winners;

    function recordWinner(address game, address winner, address gameCreator) external {
        require(msg.sender == game, "only game can record");  // Access Control
        if (winner == gameCreator) return;                     // Proposer 제외
        if (_isWinner[game][winner]) return;                   // 중복 방지
        _isWinner[game][winner] = true;
        _winners[game].push(winner);
    }

    function getWinningChallengers(address game) external view returns (address[] memory);
    function getWinningChallengersCount(address game) external view returns (uint256);
    function isWinningChallenger(address game, address challenger) external view returns (bool);
}
```

---

## 3.2 FaultDisputeGame (수정)

**경로**: `lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`
**수정 후 사이즈**: 24,102 bytes (마진 +474 bytes)

### 추가된 State 변수

```solidity
address public winningChallengerTracker;
```

### 변경된 initialize 함수

```solidity
// 새 오버로드 추가
function initialize(address _rat, address _winningChallengerTracker) public payable virtual;
function initialize(address _rat) public payable virtual;  // 기존 유지
function initialize() public payable virtual;               // 기존 유지
```

### 추가된 내부 함수

```solidity
function _recordWinningChallenger(address _recipient) internal {
    if (winningChallengerTracker != address(0)) {
        try IWinningChallengerTracker(winningChallengerTracker).recordWinner(
            address(this), _recipient, gameCreator()
        ) {} catch {}  // try-catch로 외부 호출 실패 시에도 게임 로직 영향 없음
    }
}
```

### resolveClaim 내 호출 위치 (3곳)

| 위치 | Line | 상황 |
|------|------|------|
| Case 1 | ~800 | 자식 없는 claim 해결 시 |
| Case 2 | ~864 | L2 block number challenge 시 |
| Case 3 | ~870 | 일반 subgame 해결 시 |

각각 `_distributeBond(recipient, claim)` 호출 직후에 `_recordWinningChallenger(recipient)` 호출.

> **주의**: `getWinningChallengers()` 등 view 함수는 사이즈 최적화를 위해 FaultDisputeGame에서 **제거**됨. 외부에서 `WinningChallengerTracker` 컨트랙트를 직접 조회해야 함.

---

## 3.3 DisputeGameFactory (수정)

**경로**: `lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol`

```solidity
// 상태 변수 추가
address public winningChallengerTracker;

// Setter 추가 (onlyOwner)
function setWinningChallengerTracker(address _tracker) external onlyOwner {
    winningChallengerTracker = _tracker;
}

// create() 수정 - CANNON 타입 게임 생성 시 tracker 주소 전달
if (gameType.raw() == GameTypes.CANNON.raw() &&
    (rat != address(0) || winningChallengerTracker != address(0))) {
    IInitializable(proxy_).initialize{value: msg.value}(rat, winningChallengerTracker);
}
```

---

## 3.4 Layer2Manager_Slashing (수정)

**경로**: `src/layer2/Layer2Manager_Slashing.sol`

### 함수 변경

```solidity
// 변경 전: 단일 주소 반환
function _getWinningChallenger(address disputeGame) internal view returns (address)

// 변경 후: 배열 반환
function _getWinningChallengers(address disputeGame) internal view returns (address[] memory) {
    return IFaultDisputeGame(disputeGame).getWinningChallengers();
}
```

### 이벤트 변경

```solidity
// 변경 전
event CandidateSlashed(address indexed operator, address indexed challenger, address disputeGame);
// 변경 후
event CandidateSlashed(address indexed operator, uint256 challengerCount, address disputeGame);
```

### slashingCandidate 수정

```solidity
address[] memory challengers = _getWinningChallengers(_disputeGame);
require(challengers.length > 0, "no winning challengers");

IIDepositManager(depositManager).slash(
    candidateAddOn, operatorManager, challengers  // address[] 전달
);
```

---

## 3.5 DepositManager_Slashing (수정)

**경로**: `src/stake/managers/DepositManager_Slashing.sol`

### slash 함수 시그니처 변경

```solidity
// 변경 전
function slash(address layer2, address operator, address challenger) external ...
// 변경 후
function slash(address layer2, address operator, address[] calldata challengers) external ...
```

### 추가된 보상 분배 함수

```solidity
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    uint256 rewardPerChallenger = totalReward / challengers.length;
    uint256 remainder = totalReward % challengers.length;

    for (uint256 i = 0; i < challengers.length; i++) {
        uint256 amount = rewardPerChallenger;
        if (i == 0) amount += remainder;  // 나머지는 첫 번째에게

        IERC20(_wton).safeTransfer(challengers[i], amount);
        emit ChallengerRewarded(layer2, challengers[i], amount);
    }
}
```

---

## 3.6 인터페이스 변경 요약

| 파일 | 변경 내용 |
|------|-----------|
| `src/layer2/interfaces/IFaultDisputeGame.sol` | `getWinningChallengers()`, `getWinningChallengersCount()`, `isWinningChallenger()` 추가 |
| `src/stake/interfaces/IIDepositManager.sol` | `slash()` 시그니처: `address → address[] calldata` |
| `lib/optimism/.../interfaces/dispute/IInitializable.sol` | `initialize(address, address)` 시그니처 추가 |
| `lib/optimism/.../interfaces/dispute/IDisputeGameFactory.sol` | `winningChallengerTracker()`, `setWinningChallengerTracker()` 추가 |

---

다음: [04-reward-logic.md](./04-reward-logic.md)
