# Winning Challenger Tracking 구현 계획

## 개요

FaultDisputeGame의 `resolveClaim` 함수 내에서 `_distributeBond` 호출 시 bond 수령자를 추적하여, 모든 승리한 challenger들에게 슬래싱 보상을 균등 분배하는 시스템을 구현합니다.

---

## 현재 구조 vs 새로운 구조

### 현재 구조

```
Layer2Manager_Slashing.slashingCandidate()
    ↓
_getWinningChallenger() → claimData(0).counteredBy (단일 주소)
    ↓
DepositManager_Slashing.slash(challenger) → 단일 challenger에게 전체 reward 전송
```

### 새로운 구조

```
FaultDisputeGame.resolveClaim()
    ↓
_distributeBond() 호출 시 → _recordWinningChallenger() 호출
    ↓
winningChallengers 배열에 승자 기록 (gameCreator 제외)
    ↓
Layer2Manager_Slashing.slashingCandidate()
    ↓
getWinningChallengers() → address[] 반환
    ↓
DepositManager_Slashing.slash(challengers[]) → 균등 분배
```

---

## 핵심 로직

### 승자 기록 조건

1. `_distributeBond(recipient, claim)` 호출 시
2. `recipient != gameCreator()` (Proposer 제외)
3. 중복 주소는 한 번만 기록

### 기록 시점

`resolveClaim` 함수 내 `_distributeBond` 호출 직후 (3곳):
- Line 793: 자식 없는 claim 해결 시
- Line 854: L2 block number challenge 시
- Line 861: 일반 subgame 해결 시

---

## 파일별 수정 사항

### 1. FaultDisputeGame.sol 수정

**파일:** `lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`

#### 1.1 State 변수 추가

```solidity
/// @notice Mapping to track if an address is a winning challenger
mapping(address => bool) public isWinningChallenger;

/// @notice Array of all winning challengers
address[] internal _winningChallengers;
```

#### 1.2 내부 함수 추가

```solidity
/// @notice Records a winning challenger address
/// @param recipient The address that received a bond
function _recordWinningChallenger(address recipient) internal {
    // gameCreator (Proposer)는 제외
    if (recipient == gameCreator()) return;
    
    // 중복 체크
    if (isWinningChallenger[recipient]) return;
    
    isWinningChallenger[recipient] = true;
    _winningChallengers.push(recipient);
}
```

#### 1.3 조회 함수 추가

```solidity
/// @notice Returns all winning challengers
/// @return challengers Array of winning challenger addresses
function getWinningChallengers() external view returns (address[] memory challengers) {
    return _winningChallengers;
}

/// @notice Returns the count of winning challengers
/// @return count Number of winning challengers
function getWinningChallengersCount() external view returns (uint256 count) {
    return _winningChallengers.length;
}
```

#### 1.4 resolveClaim 함수 수정

```solidity
// Case 1: Line 793 다음에 추가
_distributeBond(recipient, subgameRootClaim);
_recordWinningChallenger(recipient);  // 추가

// Case 2: Line 854 다음에 추가
_distributeBond(challenger, subgameRootClaim);
_recordWinningChallenger(challenger);  // 추가

// Case 3: Line 861 다음에 추가
_distributeBond(bondRecipient, subgameRootClaim);
_recordWinningChallenger(bondRecipient);  // 추가
```

---

### 2. IFaultDisputeGame 인터페이스 수정

**파일:** `src/layer2/interfaces/IFaultDisputeGame.sol`

```solidity
interface IFaultDisputeGame is IDisputeGame {
    // ... 기존 함수들 ...
    
    /// @notice Returns all winning challengers
    function getWinningChallengers() external view returns (address[] memory);
    
    /// @notice Returns the count of winning challengers
    function getWinningChallengersCount() external view returns (uint256);
    
    /// @notice Check if an address is a winning challenger
    function isWinningChallenger(address) external view returns (bool);
}
```

---

### 3. Layer2Manager_Slashing 수정

**파일:** `src/layer2/Layer2Manager_Slashing.sol`

#### 3.1 함수 시그니처 변경

```solidity
// 기존
function _getWinningChallenger(address disputeGame) internal view returns (address challenger)

// 변경
function _getWinningChallengers(address disputeGame) internal view returns (address[] memory challengers)
```

#### 3.2 구현 변경

```solidity
function _getWinningChallengers(address disputeGame) internal view returns (address[] memory challengers) {
    return IFaultDisputeGame(disputeGame).getWinningChallengers();
}
```

#### 3.3 slashingCandidate 함수 수정

```solidity
function slashingCandidate(
    address _operatorManager,
    GameType _gameType,
    Claim _rootClaim,
    bytes calldata _extraData,
    address _disputeGame
) external {
    // ... 기존 검증 로직 ...
    
    // 승리한 Challenger 주소들 추출
    address[] memory challengers = _getWinningChallengers(_disputeGame);
    require(challengers.length > 0, "no winning challengers");
    
    // Slashing the operator and reward the challengers
    if (
        !IIDepositManager(depositManager).slash(
            operatorInfo[_operatorManager].candidateAddOn,
            _operatorManager,
            challengers  // address[] 전달
        )
    ) revert SlashingError();
    
    // ... 나머지 로직 ...
}
```

---

### 4. IIDepositManager 인터페이스 수정

**파일:** `src/stake/interfaces/IIDepositManager.sol`

```solidity
// 기존
function slash(address layer2, address operator, address challenger) external returns (bool);

// 변경
function slash(address layer2, address operator, address[] calldata challengers) external returns (bool);
```

---

### 5. DepositManager_Slashing 수정

**파일:** `src/stake/managers/DepositManager_Slashing.sol`

#### 5.1 함수 시그니처 변경

```solidity
function slash(
    address layer2,
    address operator,
    address[] calldata challengers
) external onlyLayer2Manager returns (bool) {
    require(operator == ILayer2(layer2).operator(), "operator is not an operator");
    require(challengers.length > 0, "no challengers");
    
    // 모든 challenger 주소 유효성 검증
    for (uint256 i = 0; i < challengers.length; i++) {
        require(challengers[i] != address(0), "invalid challenger address");
    }
    
    // ... 기존 슬래싱 로직 ...
    
    uint256 totalSlashedAmount = ISeigManager(_seigManager).onSlash(layer2, operator);
    require(totalSlashedAmount > 0, "Slashed Amount is 0");
    
    // 보상 금액 계산
    uint256 rewardAmount = 0;
    if (slashingRewardRate > 0) {
        rewardAmount = (totalSlashedAmount * slashingRewardRate) / 10000;
    }
    
    // 보상 균등 분배
    if (rewardAmount > 0) {
        _distributeRewards(layer2, challengers, rewardAmount);
    }
    
    emit Slashed(layer2, operator, challengers[0], totalSlashedAmount, rewardAmount);
    
    return true;
}
```

#### 5.2 보상 분배 함수 추가

```solidity
/// @notice Distribute rewards equally among challengers
/// @param layer2 The layer2 address
/// @param challengers Array of challenger addresses
/// @param totalReward Total reward amount to distribute
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    uint256 rewardPerChallenger = totalReward / challengers.length;
    uint256 remainder = totalReward % challengers.length;
    
    for (uint256 i = 0; i < challengers.length; i++) {
        uint256 amount = rewardPerChallenger;
        // 나머지는 첫 번째 challenger에게
        if (i == 0) {
            amount += remainder;
        }
        
        IERC20(_wton).safeTransfer(challengers[i], amount);
        emit ChallengerRewarded(layer2, challengers[i], amount);
    }
}
```

#### 5.3 새 이벤트 추가 (선택적)

```solidity
/// @notice Emitted when multiple challengers receive rewards
event ChallengersRewarded(
    address indexed layer2,
    uint256 totalReward,
    uint256 challengerCount
);
```

---

## 테스트 계획

### 1. FaultDisputeGame 테스트

**파일:** `test/dispute/FaultDisputeGame.t.sol` (신규 또는 기존 수정)

```solidity
function test_WinningChallengersTracking() public {
    // 1. 게임 생성
    // 2. 여러 challenger가 move 수행
    // 3. 게임 resolve
    // 4. getWinningChallengers() 결과 검증
    // 5. gameCreator가 포함되지 않음 검증
    // 6. 중복 주소가 없음 검증
}
```

### 2. 슬래싱 보상 분배 테스트

**파일:** `test/v3/v3mode/BasicSlashing/SlashingMultiChallengerTest.t.sol` (신규)

```solidity
function test_MultipleChallengers_EqualDistribution() public {
    // 1. Operator 등록 및 스테이킹
    // 2. DisputeGame 생성
    // 3. 3명의 challenger가 각각 move 수행
    // 4. 게임 resolve (CHALLENGER_WINS)
    // 5. slashingCandidate 실행
    // 6. 3명 모두 균등한 보상 수령 검증
}

function test_SingleChallenger_FullReward() public {
    // 단일 challenger 시나리오 (기존 동작 호환성)
}

function test_Remainder_GoesToFirstChallenger() public {
    // 나머지 처리 검증
}
```

---

## TODO 체크리스트

### Phase 1: FaultDisputeGame 수정
- [ ] State 변수 추가 (isWinningChallenger, _winningChallengers)
- [ ] _recordWinningChallenger 함수 추가
- [ ] getWinningChallengers, getWinningChallengersCount 함수 추가
- [ ] resolveClaim 내 3곳에 _recordWinningChallenger 호출 추가
- [ ] 단위 테스트 작성

### Phase 2: 인터페이스 수정
- [ ] IFaultDisputeGame 인터페이스 업데이트
- [ ] IIDepositManager 인터페이스 업데이트

### Phase 3: Layer2Manager_Slashing 수정
- [ ] _getWinningChallengers 함수로 변경
- [ ] slashingCandidate 함수 수정

### Phase 4: DepositManager_Slashing 수정
- [ ] slash 함수 시그니처 변경
- [ ] _distributeRewards 함수 추가
- [ ] 이벤트 업데이트

### Phase 5: 통합 테스트
- [ ] 다중 challenger 균등 분배 테스트
- [ ] 단일 challenger 호환성 테스트
- [ ] 엣지 케이스 테스트

---

## 고려 사항

### 1. Gas 비용

| 항목 | 추가 비용 |
|------|----------|
| _recordWinningChallenger 호출 | ~20,000 gas (새 주소당) |
| getWinningChallengers 조회 | 배열 크기에 비례 |
| 다중 transfer | challenger 수 × ~21,000 gas |

### 2. 최대 Challenger 수 제한

DoS 방지를 위해 선택적으로 제한 추가 가능:

```solidity
uint256 public constant MAX_WINNING_CHALLENGERS = 100;

function _recordWinningChallenger(address recipient) internal {
    if (_winningChallengers.length >= MAX_WINNING_CHALLENGERS) return;
    // ...
}
```

### 3. 하위 호환성

- 기존 단일 challenger 시나리오도 정상 동작
- challengers.length == 1인 경우 기존과 동일한 결과

---

## 장점

1. **정확성**: 실제 bond를 받은 승자만 기록
2. **효율성**: resolve 시점에 한 번만 기록
3. **단순성**: gameCreator 필터링만으로 challenger 구분
4. **확장성**: 향후 가중치 기반 분배로 확장 가능

## 위험 요소

1. **FaultDisputeGame 수정 필요**: Optimism 원본 코드 수정
2. **Storage 비용**: 대규모 게임에서 많은 challenger 기록 시 비용 증가
3. **배열 무한 증가**: 게임당 배열이 계속 증가 (하지만 게임은 일회성)
