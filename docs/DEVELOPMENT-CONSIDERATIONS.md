# Delegate Staking 개발 고려사항

> **Version**: 1.0
> **Date**: 2026-01-26
> **Status**: Development Guide

이 문서는 Delegate Staking 서비스 개발 시 반드시 고려해야 할 기술적, 아키텍처적 사항을 정리합니다.

---

## 목차

1. [V3 프로토콜 통합](#1-v3-프로토콜-통합)
2. [핵심 기술적 과제](#2-핵심-기술적-과제)
3. [컨트랙트 아키텍처](#3-컨트랙트-아키텍처)
4. [보상 수령 메커니즘](#4-보상-수령-메커니즘)
5. [단위 변환 및 정밀도](#5-단위-변환-및-정밀도)
6. [보안 고려사항](#6-보안-고려사항)
7. [가스 최적화](#7-가스-최적화)
8. [테스트 전략](#8-테스트-전략)
9. [배포 및 업그레이드](#9-배포-및-업그레이드)
10. [미결정 사항 및 위험요소](#10-미결정-사항-및-위험요소)

---

## 1. V3 프로토콜 통합

### 1.1 시뇨리지 분배 흐름 이해

V3에서 시뇨리지가 어떻게 분배되는지 정확히 이해해야 합니다.

```
SeigManager.updateSeigniorage()
        │
        ▼
_distributeV3Seigniorage()
        │
        ├─► DAO 보상: d × A (고정 비율)
        │
        └─► L2 Pool: L = (1-d) × A
                │
                ▼
        _distributeL2Rewards()
                │
                ├─► 자격 있는 L2만 분배 대상
                │
                └─► 각 L2의 시뇨리지: S_i = y(B̃_i) × B̃_i / Σ B̃_j
                        │
                        ├─► Sequencer 보상: (1-α) × S_i
                        │       │
                        │       ▼
                        │   Layer2Manager.transferL2Seigniorage()
                        │       │
                        │       ▼
                        │   operatorOfLayer[layer2] ← WTON 전송
                        │
                        └─► Validator 보상: α × S_i
                                │
                                ▼
                            ValidatorReward 컨트랙트
```

### 1.2 핵심 통합 포인트

| 컴포넌트 | 함수/변수 | 파일 위치 | 설명 |
|----------|-----------|-----------|------|
| Layer2Manager | `operatorOfLayer[layer2]` | Layer2ManagerV3.sol:50 | **보상 수령 주소** |
| Layer2Manager | `transferL2Seigniorage()` | Layer2ManagerV3.sol:237-245 | 시뇨리지 전송 |
| SeigManager | `checkCurrentEligibility()` | SeigManagerV3_1.sol | 자격 검증 |
| SeigManager | `getSequencerStaked()` | SeigManagerV3_1.sol | 스테이킹 잔액 조회 |
| L1BridgeRegistry | `layer2TVL()` | L1BridgeRegistryV1_2.sol | Bridged TON 조회 |

### 1.3 중요한 발견: 보상 수령자 문제

**현재 V3 구조의 한계**:

```solidity
// Layer2ManagerV3.sol:237-245
function transferL2Seigniorage(address layer2, uint256 amount) external onlySeigManager {
    address operator = operatorOfLayer[layer2];  // ← 보상은 여기로 전송됨
    require(operator != address(0), "No operator");
    IWTON(wton).safeTransfer(operator, amount);
    emit L2SeigniorageTransferred(layer2, operator, amount);
}
```

**문제점**:
- `operatorOfLayer[layer2]`는 OperatorManager 컨트랙트 주소
- OperatorManager는 Sequencer가 직접 제어
- Delegate Staking 컨트랙트가 직접 보상을 받으려면 **프로토콜 수정** 필요

**해결 방안 옵션**:

| 옵션 | 설명 | 장단점 |
|------|------|--------|
| A. 프로토콜 수정 | `operatorOfLayer`를 DelegateStaking으로 설정 | 프로토콜 변경 필요 |
| B. OperatorManager 확장 | 보상 자동 전달 로직 추가 | 기존 구조 유지, 추가 가스 |
| C. Sequencer 신뢰 | Sequencer가 수동으로 보상 전달 | 중앙화, 신뢰 필요 |
| D. 래퍼 컨트랙트 | DelegateStaking이 OperatorManager 역할 | 복잡도 증가 |

**권장 방안**: 옵션 A (프로토콜 수정) 또는 옵션 B (OperatorManager 확장)

---

## 2. 핵심 기술적 과제

### 2.1 Bridged TON 증가 메커니즘

**위임 → Bridged TON 증가 흐름**:

```
User delegates TON
        │
        ▼
DelegateStaking 컨트랙트
        │
        ▼
L2 Bridge로 TON 브릿지
        │
        ▼
L2의 Sequencer Vault에 도착
        │
        ▼
L1BridgeRegistry.layer2TVL() 증가
        │
        ▼
SeigManager의 Bridged TON (B_i) 증가
        │
        ▼
시뇨리지 분배량 증가
```

**구현 시 확인 사항**:

1. **브릿지 인터페이스**: Tokamak L2 Bridge의 정확한 인터페이스 확인
2. **TVL 반영 시점**: 브릿지 후 언제 TVL에 반영되는지
3. **Vault 주소**: Sequencer별 Vault 주소 관리 방법

### 2.2 자격 요건 (Eligibility) 연동

V3에서 Sequencer가 시뇨리지를 받으려면 **자격 요건**을 충족해야 합니다:

```
T_i ≥ max(θ × B_i, D_sequencer)

여기서:
- T_i: Sequencer의 총 스테이킹 (OperatorManager 잔액)
- θ: 최소 스테이킹 비율 (minStakingRatio)
- B_i: Bridged TON
- D_sequencer = H_max × C_max + Δ_seq: 시퀀서 최소 담보금
```

**주의**: 위임이 증가하면 B_i가 증가하고, 따라서 필요한 T_i도 증가합니다.

```solidity
// 예시: θ = 10%, 현재 B_i = 1000 TON
// 필요 스테이킹: 0.1 × 1000 = 100 WTON

// 위임 후: B_i = 5000 TON
// 필요 스테이킹: 0.1 × 5000 = 500 WTON

// Sequencer가 추가 스테이킹하지 않으면 자격 상실!
```

**DelegateStaking에서 고려할 점**:
- 위임 전 Sequencer 자격 상태 확인
- 위임으로 인한 자격 상실 경고
- Sequencer의 스테이킹 여유분 표시

### 2.3 DTD (Dispute Time Delay) 처리

출금 시 14일 대기 기간이 있습니다:

```
requestUndelegate() 호출
        │
        ├─► L2 Vault에서 출금 요청
        │
        ▼
14일 DTD 대기 (L2 → L1 브릿지 시간)
        │
        ▼
withdraw() 호출 가능
```

**구현 시 고려사항**:
- L2 → L1 메시지 전달 메커니즘
- 실제 브릿지 완료 확인 방법
- Optimism의 출금 검증 기간과의 관계

---

## 3. 컨트랙트 아키텍처

### 3.1 컨트랙트 구조 제안

```
┌─────────────────────────────────────────────────────────────┐
│                    L1 (Ethereum)                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐     ┌──────────────────────────────┐  │
│  │ DelegateStaking │◄────│ Proxy (TransparentUpgradeable)│  │
│  │   (Logic)       │     └──────────────────────────────┘  │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ├─► SequencerRegistry: Sequencer 등록/관리        │
│           ├─► DelegationManager: 위임/출금 로직             │
│           ├─► RewardDistributor: 보상 분배 로직             │
│           └─► BridgeConnector: L2 브릿지 연동               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ L1 → L2 메시지
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    L2 (Tokamak L2)                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────┐               │
│  │           SequencerVault                 │               │
│  │  • owner: L1 DelegateStaking만          │               │
│  │  • 출금: L1 메시지로만 가능              │               │
│  │  • Sequencer 임의 사용 불가             │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Storage 설계

```solidity
// SequencerInfo: Sequencer별 정보
struct SequencerInfo {
    bool isRegistered;              // 등록 여부
    address l2Vault;                // L2 Vault 주소
    address layer2;                 // V3 Layer2 (CandidateAddOn) 주소
    address systemConfig;           // Optimism SystemConfig 주소
    uint256 commission;             // 수수료 (basis points)
    uint256 totalDelegated;         // 총 위임량
    uint256 accRewardPerShare;      // 누적 보상 per share
    uint256 lastRewardBlock;        // 마지막 보상 블록
}

// DelegationInfo: 사용자별 위임 정보
struct DelegationInfo {
    uint256 amount;                 // 위임 금액
    uint256 rewardDebt;             // 보상 계산용
    uint256 pendingWithdrawal;      // 출금 대기 금액
    uint256 withdrawalRequestTime;  // 출금 요청 시간
    uint256 withdrawalUnlockTime;   // 출금 가능 시간
}

// Storage Layout (업그레이드 고려)
mapping(address => SequencerInfo) public sequencers;
mapping(address => mapping(address => DelegationInfo)) public delegations;
mapping(address => uint256) public pendingRewards;  // 미분배 보상
address[] public sequencerList;
```

### 3.3 V3 컨트랙트 연동 인터페이스

```solidity
// ISeigManagerV3 (필요한 함수만)
interface ISeigManagerV3 {
    function checkCurrentEligibility(address layer2)
        external view returns (bool eligible, uint256 required, uint256 actual);
    function getSequencerStaked(address layer2)
        external view returns (uint256);
    function getEffectiveBridgedTon(address layer2)
        external view returns (uint256);
    function minStakingRatio() external view returns (uint256);
}

// ILayer2Manager (필요한 함수만)
interface ILayer2Manager {
    function operatorOfLayer(address layer2) external view returns (address);
    function getLayer2BySystemConfig(address systemConfig) external view returns (address);
    function getBridgedTonByLayer(address layer2) external view returns (uint256);
}

// IL1BridgeRegistry
interface IL1BridgeRegistry {
    function layer2TVL(address systemConfig) external view returns (uint256);
    function rollupConfigWithPortal(address portal) external view returns (address);
}
```

---

## 4. 보상 수령 메커니즘

### 4.1 MasterChef 패턴 구현

```solidity
uint256 private constant PRECISION = 1e27;  // WTON과 동일한 정밀도

function _distributeRewards(address sequencer, uint256 amount) internal {
    SequencerInfo storage seq = sequencers[sequencer];
    if (seq.totalDelegated == 0) {
        // 위임자가 없으면 Sequencer에게 전액
        IWTON(wton).safeTransfer(sequencer, amount);
        return;
    }

    // Commission 계산
    uint256 commission = (amount * seq.commission) / 10000;
    uint256 delegatorRewards = amount - commission;

    // Sequencer에게 Commission 전송
    if (commission > 0) {
        IWTON(wton).safeTransfer(sequencer, commission);
    }

    // accRewardPerShare 업데이트
    seq.accRewardPerShare += (delegatorRewards * PRECISION) / seq.totalDelegated;

    emit RewardsDistributed(sequencer, amount, commission);
}

function _updateRewardDebt(address user, address sequencer) internal {
    DelegationInfo storage del = delegations[user][sequencer];
    del.rewardDebt = (del.amount * sequencers[sequencer].accRewardPerShare) / PRECISION;
}

function _pendingReward(address user, address sequencer) internal view returns (uint256) {
    DelegationInfo storage del = delegations[user][sequencer];
    SequencerInfo storage seq = sequencers[sequencer];

    uint256 accReward = (del.amount * seq.accRewardPerShare) / PRECISION;
    return accReward > del.rewardDebt ? accReward - del.rewardDebt : 0;
}
```

### 4.2 보상 수령 트리거

**옵션 A: Push 방식 (권장)**

```solidity
// V3 프로토콜에서 직접 호출 (프로토콜 수정 필요)
function receiveReward(address sequencer, uint256 amount) external onlyLayer2Manager {
    IWTON(wton).safeTransferFrom(msg.sender, address(this), amount);
    pendingRewards[sequencer] += amount;
    emit RewardReceived(sequencer, amount);
}

// 또는 ERC20 receive hook 사용
function onWTONReceived(address from, uint256 amount, bytes calldata data) external returns (bytes4) {
    address sequencer = abi.decode(data, (address));
    pendingRewards[sequencer] += amount;
    return this.onWTONReceived.selector;
}
```

**옵션 B: Pull 방식**

```solidity
// 외부에서 Sequencer의 보상을 수집
function collectRewards(address sequencer) external {
    address operatorManager = sequencers[sequencer].operatorManager;
    uint256 balance = IWTON(wton).balanceOf(operatorManager);

    // OperatorManager에서 보상 인출 (OperatorManager 수정 필요)
    IOperatorManager(operatorManager).withdrawRewards(address(this), balance);

    pendingRewards[sequencer] += balance;
}
```

### 4.3 분배 함수 (Permissionless)

```solidity
/// @notice 누구나 호출 가능한 보상 분배 함수
function distribute(address sequencer) external nonReentrant {
    uint256 amount = pendingRewards[sequencer];
    if (amount == 0) return;

    pendingRewards[sequencer] = 0;
    _distributeRewards(sequencer, amount);
}

/// @notice 보상 청구
function claimRewards(address sequencer) external nonReentrant {
    // 미분배 보상이 있으면 먼저 분배
    if (pendingRewards[sequencer] > 0) {
        _distribute(sequencer);
    }

    uint256 reward = _pendingReward(msg.sender, sequencer);
    if (reward == 0) return;

    _updateRewardDebt(msg.sender, sequencer);
    IWTON(wton).safeTransfer(msg.sender, reward);

    emit RewardsClaimed(msg.sender, sequencer, reward);
}
```

---

## 5. 단위 변환 및 정밀도

### 5.1 토큰 단위 정리

| 토큰 | 단위 | Decimals | 예시 |
|------|------|----------|------|
| TON | 기본 | 18 | 1 TON = 1e18 |
| WTON | RAY | 27 | 1 WTON = 1e27 |
| RAY | 비율 | 27 | 100% = 1e27 |

### 5.2 단위 변환 함수

```solidity
uint256 constant RAY = 1e27;
uint256 constant WAD = 1e18;
uint256 constant GWEI_UNIT = 1e9;

/// @notice TON → WTON 변환
function toWTON(uint256 tonAmount) internal pure returns (uint256) {
    return tonAmount * GWEI_UNIT;  // 18 + 9 = 27 decimals
}

/// @notice WTON → TON 변환
function toTON(uint256 wtonAmount) internal pure returns (uint256) {
    return wtonAmount / GWEI_UNIT;
}

/// @notice RAY 비율 적용
function applyRatio(uint256 amount, uint256 ratioRay) internal pure returns (uint256) {
    return (amount * ratioRay) / RAY;
}
```

### 5.3 정밀도 손실 주의

```solidity
// 잘못된 예: 나눗셈 먼저
uint256 wrong = (amount / totalSupply) * rewardPerShare;  // 정밀도 손실!

// 올바른 예: 곱셈 먼저
uint256 correct = (amount * rewardPerShare) / totalSupply;

// MasterChef 패턴에서
uint256 accRewardPerShare = (rewards * PRECISION) / totalStaked;
uint256 pending = (userAmount * accRewardPerShare) / PRECISION - rewardDebt;
```

---

## 6. 보안 고려사항

### 6.1 Reentrancy 방지

```solidity
// ReentrancyGuard 사용
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DelegateStaking is ReentrancyGuard {
    function stake(...) external nonReentrant { ... }
    function unstake(...) external nonReentrant { ... }
    function claimRewards(...) external nonReentrant { ... }
}

// Checks-Effects-Interactions 패턴
function withdraw() external nonReentrant {
    // 1. Checks
    require(withdrawable > 0, "Nothing to withdraw");

    // 2. Effects (상태 변경)
    stakes[msg.sender].pendingWithdrawal = 0;

    // 3. Interactions (외부 호출)
    stakingToken.safeTransfer(msg.sender, withdrawable);
}
```

### 6.2 Access Control

```solidity
// 역할 기반 접근 제어
bytes32 public constant SEQUENCER_ROLE = keccak256("SEQUENCER_ROLE");
bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

modifier onlySequencer(address sequencer) {
    require(msg.sender == sequencer, "Not sequencer");
    _;
}

modifier onlyBridge() {
    require(hasRole(BRIDGE_ROLE, msg.sender), "Not bridge");
    _;
}
```

### 6.3 입력 검증

```solidity
function delegate(address sequencer, uint256 amount) external {
    // Zero address 검증
    require(sequencer != address(0), "Zero address");

    // Zero amount 검증
    require(amount > 0, "Zero amount");

    // Sequencer 등록 확인
    require(sequencers[sequencer].isRegistered, "Not registered");

    // 최소 위임 금액 확인
    require(amount >= MIN_DELEGATION, "Below minimum");

    // 오버플로우 확인 (Solidity 0.8+ 자동)
    // amount + currentDelegation은 자동으로 검증됨
}
```

### 6.4 Sequencer Vault 보안

```solidity
// L2 SequencerVault 컨트랙트
contract SequencerVault {
    address public immutable l1DelegateStaking;
    address public immutable l2Bridge;

    modifier onlyL1Contract() {
        // L2 Bridge를 통한 L1 메시지만 허용
        require(
            msg.sender == l2Bridge &&
            ICrossDomainMessenger(l2Bridge).xDomainMessageSender() == l1DelegateStaking,
            "Unauthorized"
        );
        _;
    }

    function withdraw(address to, uint256 amount) external onlyL1Contract {
        IERC20(ton).safeTransfer(to, amount);
    }

    // Sequencer도 임의 출금 불가
    // receive() 제거하여 ETH 전송 방지
}
```

### 6.5 Flash Loan 공격 방지

```solidity
// 스냅샷 기반 보상 계산
mapping(address => mapping(address => uint256)) public snapshotStake;
uint256 public snapshotBlock;

function takeSnapshot() external {
    require(block.number > snapshotBlock + SNAPSHOT_INTERVAL, "Too soon");
    snapshotBlock = block.number;
    // 스냅샷 로직
}

// 또는 시간 가중 평균 사용
function getTimeWeightedStake(address user, address sequencer) public view returns (uint256) {
    // 일정 기간 동안의 평균 스테이킹 계산
}
```

---

## 7. 가스 최적화

### 7.1 Storage 최적화

```solidity
// 잘못된 예: 여러 번 storage 읽기
function calculate() {
    uint256 a = data.value1;  // SLOAD
    uint256 b = data.value2;  // SLOAD
    uint256 c = data.value1;  // 다시 SLOAD
}

// 올바른 예: 캐싱
function calculate() {
    DataStruct memory cached = data;  // 한 번만 SLOAD
    uint256 a = cached.value1;
    uint256 b = cached.value2;
    uint256 c = cached.value1;
}
```

### 7.2 Loop 최적화

```solidity
// 잘못된 예: length 매번 계산
for (uint i = 0; i < array.length; i++) { ... }

// 올바른 예: length 캐싱
uint256 len = array.length;
for (uint i = 0; i < len; ) {
    // ...
    unchecked { ++i; }
}
```

### 7.3 Batch 처리

```solidity
// 여러 Sequencer의 보상을 한 번에 청구
function claimAllRewards(address[] calldata sequencers) external nonReentrant {
    uint256 totalReward = 0;

    for (uint256 i = 0; i < sequencers.length; ) {
        totalReward += _claimReward(msg.sender, sequencers[i]);
        unchecked { ++i; }
    }

    if (totalReward > 0) {
        IWTON(wton).safeTransfer(msg.sender, totalReward);
    }
}
```

---

## 8. 테스트 전략

### 8.1 테스트 계층

```
┌─────────────────────────────────────┐
│       E2E Tests (Scenarios)         │  ← 전체 플로우 검증
├─────────────────────────────────────┤
│      Integration Tests              │  ← V3 연동 검증
├─────────────────────────────────────┤
│        Unit Tests                   │  ← 개별 함수 검증
└─────────────────────────────────────┘
```

### 8.2 핵심 테스트 케이스

#### Unit Tests

```solidity
// 위임
test_stake_success()
test_stake_zeroAmount_reverts()
test_stake_unregisteredSequencer_reverts()
test_stake_belowMinimum_reverts()

// 출금
test_unstake_success()
test_unstake_exceedsBalance_reverts()
test_withdraw_beforeUnbonding_reverts()
test_withdraw_afterUnbonding_success()

// 보상
test_distribute_success()
test_distribute_noRewards_noOp()
test_claimRewards_success()
test_claimRewards_noRewards_noOp()
test_accRewardPerShare_calculation()
test_rewardDebt_update()
```

#### Integration Tests

```solidity
// V3 연동
test_eligibility_checkBeforeDelegate()
test_bridgedTON_increaseAfterDelegate()
test_seigniorage_distributionFlow()
test_rewardReceipt_fromLayer2Manager()

// 자격 상태 변화
test_eligibilityLoss_afterMassiveDelegation()
test_eligibilityRegain_afterSequencerTopUp()
```

#### E2E Scenarios

```solidity
// 사용자 여정
test_userJourney_delegateAndEarnRewards()
test_userJourney_partialUnstake()
test_userJourney_redelegate()

// 다중 사용자
test_multiUser_proportionalRewards()
test_multiUser_sequentialClaims()

// Edge Cases
test_lastUserUnstake_handlesRemainder()
test_firstUser_receivesAllRewards()
```

### 8.3 Mock 전략

```solidity
// V3 컨트랙트 Mock
contract MockSeigManager {
    mapping(address => bool) public eligibility;
    mapping(address => uint256) public bridgedTon;

    function checkCurrentEligibility(address layer2)
        external view returns (bool, uint256, uint256)
    {
        return (eligibility[layer2], 100e27, 150e27);
    }

    function setEligibility(address layer2, bool _eligible) external {
        eligibility[layer2] = _eligible;
    }
}

// 브릿지 Mock
contract MockL2Bridge {
    event BridgeInitiated(address to, uint256 amount);

    function bridgeToL2(address to, uint256 amount) external {
        emit BridgeInitiated(to, amount);
    }
}
```

### 8.4 Fuzz 테스트

```solidity
function testFuzz_stake_anyAmount(uint256 amount) public {
    amount = bound(amount, MIN_DELEGATION, type(uint128).max);

    deal(address(wton), user, amount);

    vm.startPrank(user);
    wton.approve(address(delegateStaking), amount);
    delegateStaking.stake(sequencer, amount);
    vm.stopPrank();

    assertEq(delegateStaking.stakes(user, sequencer).amount, amount);
}

function testFuzz_rewardDistribution(uint256 reward, uint256 stake1, uint256 stake2) public {
    reward = bound(reward, 1e18, 1e30);
    stake1 = bound(stake1, MIN_DELEGATION, 1e30);
    stake2 = bound(stake2, MIN_DELEGATION, 1e30);

    // 두 사용자 스테이킹
    _stake(user1, stake1);
    _stake(user2, stake2);

    // 보상 분배
    _distributeRewards(reward);

    // 비례 분배 검증
    uint256 expected1 = (reward * stake1) / (stake1 + stake2);
    uint256 expected2 = reward - expected1;

    assertApproxEqRel(delegateStaking.pendingRewards(user1, sequencer), expected1, 0.001e18);
    assertApproxEqRel(delegateStaking.pendingRewards(user2, sequencer), expected2, 0.001e18);
}
```

---

## 9. 배포 및 업그레이드

### 9.1 Proxy 패턴 선택

**TransparentUpgradeableProxy 권장**:

```solidity
// 배포 순서
1. Implementation 배포
2. ProxyAdmin 배포 (또는 기존 사용)
3. Proxy 배포 (implementation, admin, initData)
4. initialize() 자동 호출
```

```solidity
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// 배포 스크립트
address implementation = address(new DelegateStakingV1());
bytes memory initData = abi.encodeCall(
    DelegateStakingV1.initialize,
    (wton, seigManager, layer2Manager, owner)
);

address proxy = address(new TransparentUpgradeableProxy(
    implementation,
    proxyAdmin,
    initData
));
```

### 9.2 Storage Layout 관리

```solidity
// 업그레이드 시 storage 충돌 방지
contract DelegateStakingV1 {
    // 슬롯 0
    mapping(address => SequencerInfo) public sequencers;
    // 슬롯 1
    mapping(address => mapping(address => DelegationInfo)) public delegations;
    // ...

    // 업그레이드용 갭
    uint256[50] private __gap;
}

contract DelegateStakingV2 is DelegateStakingV1 {
    // 새 변수는 __gap 이후에 추가
    uint256 public newVariable;  // 기존 __gap에서 하나 차감

    uint256[49] private __gap;  // 49로 감소
}
```

### 9.3 배포 체크리스트

```
□ 컴파일 최적화 설정 (optimizer: 200 runs)
□ Hardhat/Foundry 설정 검토
□ 테스트넷 배포 및 검증
□ 컨트랙트 Verification (Etherscan)
□ Multisig 설정 (ProxyAdmin, Owner)
□ 초기 파라미터 설정
□ 권한 이전 (deployer → multisig)
□ 문서 업데이트
```

---

## 10. 미결정 사항 및 위험요소

### 10.1 미결정 사항

| 항목 | 상태 | 설명 | 의사결정 필요 |
|------|------|------|--------------|
| 보상 수령 방식 | 미정 | Push vs Pull | 프로토콜 팀과 협의 |
| L2 브릿지 인터페이스 | 확인 필요 | Tokamak L2 브릿지 스펙 | 기술 문서 확인 |
| Sequencer Vauㅂlt 배포 | 미정 | 누가 배포하는가 | 정책 결정 |
| 최소 위임 금액 | 미정 | 1,000 TON 가정 | 경제성 분석 |
| Commission 상한 | 미정 | 30% 가정 | 거버넌스 결정 |
| DTD 기간 | 확인 필요 | 14일 가정 | 프로토콜 확인 |

### 10.2 위험요소

| 위험 | 영향도 | 대응 방안 |
|------|--------|-----------|
| 브릿지 해킹 | 높음 | 점진적 위임, 보험 검토 |
| Sequencer 이탈 | 중간 | 위임 해제 프로세스 명확화 |
| 자격 상실 | 중간 | 자격 모니터링, 경고 시스템 |
| 가스비 급등 | 낮음 | Batch 처리, L2 전환 검토 |
| 스마트 컨트랙트 버그 | 높음 | 감사, 테스트, 단계적 배포 |

### 10.3 의존성

```
DelegateStaking
    │
    ├─► TON Staking V3 Protocol
    │       ├─► SeigManagerV3_1
    │       ├─► Layer2ManagerV3
    │       └─► L1BridgeRegistryV1_2
    │
    ├─► Tokamak L2 Bridge
    │       └─► (인터페이스 확인 필요)
    │
    └─► OpenZeppelin Contracts
            ├─► ReentrancyGuard
            ├─► SafeERC20
            └─► TransparentUpgradeableProxy
```

---

## 부록: 빠른 참조

### A. 주요 V3 함수 시그니처

```solidity
// SeigManagerV3_1
function checkCurrentEligibility(address layer2) external view returns (bool, uint256, uint256);
function getSequencerStaked(address layer2) external view returns (uint256);
function getEffectiveBridgedTon(address layer2) external view returns (uint256);
function minStakingRatio() external view returns (uint256);
function validatorDistributionRatio() external view returns (uint256);

// Layer2ManagerV3
function operatorOfLayer(address layer2) external view returns (address);
function getLayer2BySystemConfig(address systemConfig) external view returns (address);
function getBridgedTonByLayer(address layer2) external view returns (uint256);
function transferL2Seigniorage(address layer2, uint256 amount) external;

// L1BridgeRegistryV1_2
function layer2TVL(address systemConfig) external view returns (uint256);
```

### B. 테스트 명령어

```bash
# 단위 테스트
forge test --match-path "test/unit/**"

# 통합 테스트
forge test --match-path "test/integration/**"

# 특정 테스트
forge test --match-test "test_stake"

# 가스 리포트
forge test --gas-report

# 커버리지
forge coverage --report lcov
```

### C. 개발 체크리스트

```
Phase 1: 기본 구현
□ SequencerInfo, DelegationInfo 구조체
□ registerSequencer, deregisterSequencer
□ delegate, unstake, withdraw
□ 기본 단위 테스트

Phase 2: 보상 시스템
□ MasterChef 패턴 구현
□ distribute, claimRewards
□ V3 보상 수령 연동
□ 보상 계산 테스트

Phase 3: L2 연동
□ L2 브릿지 인터페이스 구현
□ SequencerVault 컨트랙트
□ 출금 플로우 (L2 → L1)
□ 통합 테스트

Phase 4: 보안 및 최적화
□ 보안 감사
□ 가스 최적화
□ Proxy 패턴 적용
□ E2E 테스트

Phase 5: 배포
□ 테스트넷 배포
□ 메인넷 배포
□ 문서화
```
