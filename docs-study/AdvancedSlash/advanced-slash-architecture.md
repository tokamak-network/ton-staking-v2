# Advanced Slash 시스템 아키텍처

> **작성일**: 2026-02-02  
> **버전**: 1.0  
> **상태**: 설계 완료 / 구현 진행 중

---

## 📋 목차

1. [개요](#개요)
2. [시스템 아키텍처](#시스템-아키텍처)
3. [핵심 컴포넌트](#핵심-컴포넌트)
4. [데이터 흐름](#데이터-흐름)
5. [구현 상세](#구현-상세)
6. [배포 파이프라인](#배포-파이프라인)
7. [보안 고려사항](#보안-고려사항)
8. [향후 확장](#향후-확장)

---

## 개요

### 목적

Advanced Slash 시스템은 Optimism Fault Proof 메커니즘과 TON Staking V3를 통합하여, **잘못된 L2 Output Proposal을 제출한 Operator를 슬래싱하고, 이를 성공적으로 Challenge한 모든 참여자에게 보상을 균등 분배**하는 시스템입니다.

### 핵심 목표

1. **공정성**: 모든 승리한 Challenger에게 균등한 보상 제공
2. **투명성**: 온체인에서 모든 승자를 추적 가능
3. **효율성**: 최소한의 Gas 비용으로 다중 참여자 보상
4. **확장성**: 향후 가중치 기반 보상 시스템으로 확장 가능

### 기존 시스템의 한계

```
기존 구조 (단일 Challenger):
┌─────────────────────────────────────────────────────┐
│ Layer2Manager_Slashing.slashingCandidate()         │
│   ↓                                                 │
│ _getWinningChallenger() → claimData(0).counteredBy │
│   ↓                                                 │
│ DepositManager.slash(challenger) → 단일 보상        │
└─────────────────────────────────────────────────────┘

문제점:
- 첫 번째 counter만 기록됨
- 나머지 Challenger들은 보상 받지 못함
- 불공정한 인센티브 구조
```

---

## 시스템 아키텍처

### 전체 구조도

```
┌─────────────────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Optimism Dispute System                         │ │
│  │                                                              │ │
│  │  ┌────────────────────┐      ┌──────────────────────────┐  │ │
│  │  │DisputeGameFactory  │─────▶│  FaultDisputeGame        │  │ │
│  │  │                    │      │  ┌────────────────────┐  │  │ │
│  │  │ - create()         │      │  │ resolveClaim()     │  │  │ │
│  │  │ - setWCT()         │      │  │   ↓                │  │  │ │
│  │  └────────────────────┘      │  │ _distributeBond()  │  │  │ │
│  │           │                  │  │   ↓                │  │  │ │
│  │           │ initialize       │  │ _recordWinning     │  │  │ │
│  │           │                  │  │   Challenger()     │  │  │ │
│  │           ▼                  │  └────────────────────┘  │  │ │
│  │  ┌────────────────────┐      │           │              │  │ │
│  │  │WinningChallenger   │◀─────┼───────────┘              │  │ │
│  │  │Tracker             │      │                          │  │ │
│  │  │                    │      │  - winningChallenger     │  │ │
│  │  │ - recordWinner()   │      │    Tracker (address)     │  │ │
│  │  │ - getWinning       │      │                          │  │ │
│  │  │   Challengers()    │      └──────────────────────────┘  │ │
│  │  └────────────────────┘                                    │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              TON Staking V3 System                       │ │
│  │                                                          │ │
│  │  ┌────────────────────┐      ┌──────────────────────┐  │ │
│  │  │Layer2Manager       │      │DepositManager        │  │ │
│  │  │_Slashing           │      │_Slashing             │  │ │
│  │  │                    │      │                      │  │ │
│  │  │ slashingCandidate()│─────▶│ slash()              │  │ │
│  │  │   ↓                │      │   ↓                  │  │ │
│  │  │ _getWinning        │      │ _distributeRewards() │  │ │
│  │  │   Challengers()    │      │                      │  │ │
│  │  └────────────────────┘      └──────────────────────┘  │ │
│  │           │                           │                 │ │
│  │           │ query                     │ transfer WTON   │ │
│  │           ▼                           ▼                 │ │
│  │  ┌────────────────────┐      ┌──────────────────────┐  │ │
│  │  │FaultDisputeGame    │      │ Challengers          │  │ │
│  │  │.getWinning         │      │ (address[])          │  │ │
│  │  │ Challengers()      │      │                      │  │ │
│  │  └────────────────────┘      └──────────────────────┘  │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 레이어 구조

```
┌─────────────────────────────────────────────────────┐
│ Layer 4: Application Layer                         │
│ - E2E Tests                                         │
│ - Integration Tests                                 │
│ - Monitoring & Analytics                            │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
┌─────────────────────────────────────────────────────┐
│ Layer 3: Business Logic Layer                      │
│ - Layer2Manager_Slashing                           │
│ - DepositManager_Slashing                          │
│ - SeigManager_Slashing                             │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
┌─────────────────────────────────────────────────────┐
│ Layer 2: Tracking Layer                            │
│ - WinningChallengerTracker                         │
│ - FaultDisputeGame (tracking logic)                │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
┌─────────────────────────────────────────────────────┐
│ Layer 1: Dispute Resolution Layer                  │
│ - DisputeGameFactory                               │
│ - FaultDisputeGame (core logic)                    │
│ - AnchorStateRegistry                              │
└─────────────────────────────────────────────────────┘
```

---

## 핵심 컴포넌트

### 1. WinningChallengerTracker

**역할**: 각 DisputeGame에서 승리한 모든 Challenger를 추적

```solidity
contract WinningChallengerTracker {
    // game address => challenger address => is winner
    mapping(address => mapping(address => bool)) public isWinner;
    
    // game address => array of winners
    mapping(address => address[]) internal winners;
    
    function recordWinner(
        address game,
        address winner,
        address gameCreator
    ) external;
    
    function getWinningChallengers(address game) 
        external view returns (address[] memory);
}
```

**특징**:
- 게임별로 독립적인 승자 목록 관리
- gameCreator(Proposer) 자동 필터링
- 중복 방지 메커니즘
- Gas 효율적인 조회 함수

### 2. FaultDisputeGame (수정)

**역할**: Bond 분배 시점에 승자 기록

```solidity
contract FaultDisputeGame {
    address public winningChallengerTracker;
    
    function initialize(
        address _rat,
        address _winningChallengerTracker
    ) public payable {
        // ...
        winningChallengerTracker = _winningChallengerTracker;
    }
    
    function _recordWinningChallenger(address recipient) internal {
        if (winningChallengerTracker != address(0)) {
            IWinningChallengerTracker(winningChallengerTracker)
                .recordWinner(
                    address(this),
                    recipient,
                    gameCreator()
                );
        }
    }
    
    function resolveClaim(...) external {
        // ...
        _distributeBond(recipient, claim);
        _recordWinningChallenger(recipient);  // 추가
        // ...
    }
}
```

**기록 시점** (3곳):
1. **자식 없는 claim 해결** (Line ~846)
2. **L2 block number challenge** (Line ~913)
3. **일반 subgame 해결** (Line ~921)

### 3. DisputeGameFactory (수정)

**역할**: WinningChallengerTracker 주소 관리 및 게임 초기화

```solidity
contract DisputeGameFactory {
    address public winningChallengerTracker;
    
    function setWinningChallengerTracker(address _tracker) 
        external onlyOwner {
        winningChallengerTracker = _tracker;
    }
    
    function create(...) external payable returns (IDisputeGame) {
        // ...
        if (gameType == CANNON && 
            (rat != address(0) || winningChallengerTracker != address(0))) {
            IInitializable(proxy_).initialize{value: msg.value}(
                rat,
                winningChallengerTracker
            );
        }
        // ...
    }
}
```

### 4. Layer2Manager_Slashing (수정)

**역할**: 승자 목록 조회 및 슬래싱 실행

```solidity
contract Layer2Manager_Slashing {
    function _getWinningChallengers(address disputeGame) 
        internal view returns (address[] memory) {
        return IFaultDisputeGame(disputeGame).getWinningChallengers();
    }
    
    function slashingCandidate(...) external {
        // 검증 로직
        address[] memory challengers = _getWinningChallengers(_disputeGame);
        require(challengers.length > 0, "no winning challengers");
        
        // 슬래싱 실행
        IIDepositManager(depositManager).slash(
            candidateAddOn,
            operatorManager,
            challengers  // 다중 주소 전달
        );
    }
}
```

### 5. DepositManager_Slashing (수정)

**역할**: 슬래싱 실행 및 보상 균등 분배

```solidity
contract DepositManager_Slashing {
    function slash(
        address layer2,
        address operator,
        address[] calldata challengers
    ) external onlyLayer2Manager returns (bool) {
        // 슬래싱 실행
        uint256 totalSlashed = ISeigManager(seigManager)
            .onSlash(layer2, operator);
        
        // 보상 계산
        uint256 rewardAmount = (totalSlashed * slashingRewardRate) / 10000;
        
        // 균등 분배
        if (rewardAmount > 0) {
            _distributeRewards(layer2, challengers, rewardAmount);
        }
        
        return true;
    }
    
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
            
            IERC20(wton).safeTransfer(challengers[i], amount);
            emit ChallengerRewarded(layer2, challengers[i], amount);
        }
    }
}
```

---

## 데이터 흐름

### 1. 게임 생성 및 초기화

```
Proposer
   │
   ▼
DisputeGameFactory.create(gameType, rootClaim, extraData)
   │
   ├─ Clone FaultDisputeGame implementation
   │
   ├─ IInitializable.initialize(rat, winningChallengerTracker)
   │     │
   │     └─▶ FaultDisputeGame.winningChallengerTracker = _tracker
   │
   └─ Return game proxy address
```

### 2. Challenge 및 Resolution

```
Challenger A, B, C
   │
   ├─▶ FaultDisputeGame.move() / attack() / defend()
   │
   ▼
FaultDisputeGame.resolveClaim()
   │
   ├─ Determine winner (recipient)
   │
   ├─ _distributeBond(recipient, claim)
   │
   └─ _recordWinningChallenger(recipient)
         │
         └─▶ WinningChallengerTracker.recordWinner(game, recipient, gameCreator)
               │
               ├─ Filter out gameCreator
               ├─ Check duplicate
               └─ winners[game].push(recipient)
```

### 3. 슬래싱 및 보상 분배

```
Anyone
   │
   ▼
Layer2Manager_Slashing.slashingCandidate(...)
   │
   ├─ Verify game status (CHALLENGER_WINS)
   │
   ├─ address[] challengers = _getWinningChallengers(disputeGame)
   │     │
   │     └─▶ FaultDisputeGame.getWinningChallengers()
   │           │
   │           └─▶ WinningChallengerTracker.getWinningChallengers(game)
   │
   └─ DepositManager.slash(layer2, operator, challengers)
         │
         ├─ SeigManager.onSlash() → totalSlashed
         │
         ├─ rewardAmount = totalSlashed * rate / 10000
         │
         └─ _distributeRewards(challengers, rewardAmount)
               │
               └─ For each challenger:
                     WTON.transfer(challenger, amount)
```

---

## 구현 상세

### Phase 1: Tracking Layer (완료 ✅)

**구현 파일**:
- `src/dispute/WinningChallengerTracker.sol`
- `src/dispute/IWinningChallengerTracker.sol`

**핵심 로직**:
```solidity
function recordWinner(
    address game,
    address winner,
    address gameCreator
) external {
    require(msg.sender == game, "only game can record");
    require(winner != gameCreator, "proposer cannot be winner");
    
    if (isWinner[game][winner]) return;  // 중복 방지
    
    isWinner[game][winner] = true;
    winners[game].push(winner);
    
    emit WinnerRecorded(game, winner);
}
```

### Phase 2: Integration Layer (완료 ✅)

**DisputeGameFactory 통합**:
```solidity
// 상태 변수
address public winningChallengerTracker;

// Setter
function setWinningChallengerTracker(address _tracker) external onlyOwner {
    winningChallengerTracker = _tracker;
}

// create() 수정
if (gameType.raw() == GameTypes.CANNON.raw() && 
    (rat != address(0) || winningChallengerTracker != address(0))) {
    IInitializable(proxy_).initialize{value: msg.value}(
        rat,
        winningChallengerTracker
    );
}
```

**FaultDisputeGame 통합**:
```solidity
// 상태 변수
address public winningChallengerTracker;

// 초기화
function initialize(address _rat, address _winningChallengerTracker) 
    public payable {
    _initialize(_rat, _winningChallengerTracker);
}

function _initialize(address _rat, address _winningChallengerTracker) 
    internal {
    // ...
    if (_winningChallengerTracker != address(0)) {
        winningChallengerTracker = _winningChallengerTracker;
    }
}

// 기록 로직
function _recordWinningChallenger(address recipient) internal {
    if (winningChallengerTracker != address(0)) {
        IWinningChallengerTracker(winningChallengerTracker)
            .recordWinner(address(this), recipient, gameCreator());
    }
}
```

### Phase 3: Slashing Layer (진행 중 🔄)

**Layer2Manager_Slashing**:
```solidity
// 기존: 단일 주소 반환
function _getWinningChallenger(address disputeGame) 
    internal view returns (address)

// 변경: 배열 반환
function _getWinningChallengers(address disputeGame) 
    internal view returns (address[] memory)
```

**DepositManager_Slashing**:
```solidity
// 기존: 단일 challenger
function slash(address layer2, address operator, address challenger)

// 변경: 다중 challengers
function slash(address layer2, address operator, address[] calldata challengers)
```

---

## 배포 파이프라인

### 1. Solidity 컴파일

```bash
cd lib/optimism/packages/contracts-bedrock
forge build --skip test
```

**최적화 설정** (`foundry.toml`):
```toml
[profile.default.optimizer_details.yul_details]
optimizerSteps = "..."

[[profile.default.optimizer_details.yul_details.optimizer_runs]]
src = "src/dispute/FaultDisputeGame.sol"
runs = 200  # 코드 크기 축소 (24KB → 22.2KB)
```

### 2. Go 파이프라인

**ChainIntent 구조**:
```go
// op-deployer/pkg/deployer/state/chain_intent.go
type ChainProofParams struct {
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // 추가
}
```

**DeployOPChainInput**:
```go
// op-deployer/pkg/deployer/opcm/opchain.go
type DeployOPChainInput struct {
    // ...
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // 추가
}
```

**Pipeline 전달**:
```go
// op-deployer/pkg/deployer/pipeline/opchain.go
func makeDCI(...) opcm.DeployOPChainInput {
    return opcm.DeployOPChainInput{
        // ...
        WinningChallengerTrackerAddress: intent.WinningChallengerTrackerAddress,
    }
}
```

### 3. Devnet Allocs 생성

```bash
cd lib/optimism
just devnet-allocs
```

**GlobalDeployOverrides** (`op-chain-ops/cmd/devnet-allocs/main.go`):
```go
GlobalDeployOverrides: map[string]any{
    "deployWinningChallengerTracker": true,
}
```

### 4. E2E 테스트 환경

```go
// op-e2e/system/ton_system.go
func (sys *TONSystem) DeployWinningChallengerTracker() {
    trackerAddr, _, tracker, err := bindings.DeployWinningChallengerTracker(
        sys.Cfg.Secrets.Deployer,
        sys.Clients["l1"],
    )
    // ...
    sys.WinningChallengerTracker = tracker
}
```

---

## 보안 고려사항

### 1. Access Control

```solidity
// WinningChallengerTracker
function recordWinner(...) external {
    require(msg.sender == game, "only game can record");
    // ✅ 오직 DisputeGame만 호출 가능
}

// DisputeGameFactory
function setWinningChallengerTracker(...) external onlyOwner {
    // ✅ 오직 Owner만 설정 가능
}
```

### 2. DoS 방지

```solidity
// 최대 Challenger 수 제한 (선택적)
uint256 public constant MAX_WINNING_CHALLENGERS = 100;

function _recordWinningChallenger(address recipient) internal {
    if (winners[game].length >= MAX_WINNING_CHALLENGERS) return;
    // ...
}
```

### 3. Reentrancy 방지

```solidity
// DepositManager_Slashing
function _distributeRewards(...) internal {
    // ✅ 외부 호출 전 상태 변경 완료
    // ✅ SafeERC20.safeTransfer 사용
    for (uint256 i = 0; i < challengers.length; i++) {
        IERC20(wton).safeTransfer(challengers[i], amount);
    }
}
```

### 4. 중복 방지

```solidity
// WinningChallengerTracker
mapping(address => mapping(address => bool)) public isWinner;

function recordWinner(...) external {
    if (isWinner[game][winner]) return;  // ✅ 중복 체크
    // ...
}
```

---

## 향후 확장

### 1. 가중치 기반 보상

```solidity
struct ChallengerContribution {
    address challenger;
    uint256 bondAmount;      // 투입한 bond 금액
    uint256 moveCount;       // 수행한 move 횟수
    uint256 timestamp;       // 첫 참여 시각
}

function _distributeRewards(...) internal {
    uint256 totalWeight = calculateTotalWeight(contributions);
    
    for (uint256 i = 0; i < challengers.length; i++) {
        uint256 weight = calculateWeight(contributions[i]);
        uint256 amount = (totalReward * weight) / totalWeight;
        // ...
    }
}
```

### 2. 시간 기반 인센티브

```solidity
// 조기 참여자에게 보너스
function calculateEarlyBirdBonus(uint256 timestamp) internal view returns (uint256) {
    uint256 elapsed = block.timestamp - gameCreatedAt;
    if (elapsed < 1 hours) return 120;  // 20% 보너스
    if (elapsed < 6 hours) return 110;  // 10% 보너스
    return 100;  // 보너스 없음
}
```

### 3. 멀티체인 지원

```solidity
// Cross-chain challenger tracking
interface ICrossChainTracker {
    function recordWinnerCrossChain(
        uint256 chainId,
        address game,
        address winner
    ) external;
}
```

### 4. Analytics & Monitoring

```solidity
event DetailedWinnerRecorded(
    address indexed game,
    address indexed winner,
    uint256 bondReceived,
    uint256 moveCount,
    uint256 timestamp
);

function getGameStatistics(address game) external view returns (
    uint256 totalChallengers,
    uint256 totalBondDistributed,
    uint256 averageReward
);
```

---

## 참고 자료

### 문서
- [Winning Challenger Tracking 구현 계획](./winning-challenger-tracking-plan.md)
- [WinningChallengerTracker 통합 구현](./e2e-test/winning-challenger-tracker-integration.md)
- [Integration Issues Log](./e2e-test/integration-issues-log.md)

### 코드
- `src/dispute/WinningChallengerTracker.sol`
- `src/dispute/FaultDisputeGame.sol`
- `src/layer2/Layer2Manager_Slashing.sol`
- `src/stake/managers/DepositManager_Slashing.sol`

### 테스트
- `test/dispute/WinningChallengerTracker.t.sol`
- `test/v3/v3mode/BasicSlashing/SlashingMultiChallenger.t.sol`
- `op-e2e/system/ton_system.go`

---

## 버전 히스토리

| 버전 | 날짜 | 변경 사항 |
|------|------|-----------|
| 1.0 | 2026-02-02 | 초기 아키텍처 문서 작성 |
| 0.9 | 2026-02-01 | WinningChallengerTracker 통합 완료 |
| 0.5 | 2026-01-30 | 기본 설계 및 계획 수립 |
