# API Documentation

DelegateStakingV3Upgradeable 스마트 컨트랙트 API 문서입니다.

## 목차

1. [개요](#개요)
2. [데이터 구조](#데이터-구조)
3. [상수](#상수)
4. [시퀀서 함수](#시퀀서-함수)
5. [위임자 함수](#위임자-함수)
6. [트리거 함수](#트리거-함수)
7. [비상 함수](#비상-함수)
8. [관리자 함수](#관리자-함수)
9. [조회 함수](#조회-함수)
10. [이벤트](#이벤트)
11. [에러](#에러)
12. [사용 예시](#사용-예시)

---

## 개요

DelegateStakingV3Upgradeable은 Tokamak Network V3를 위한 위임 스테이킹 컨트랙트입니다.

- **버전**: 1.3.0
- **라이선스**: MIT
- **Solidity**: ^0.8.24
- **패턴**: UUPS Upgradeable Proxy

### 주요 특징

| 기능 | 설명 |
|------|------|
| 스테이킹 | TON을 시퀀서에게 위임하여 보상 수령 |
| 커미션 타임락 | 7일 대기 후 커미션 변경 적용 |
| 플래시론 보호 | 12초 쿨다운 후 보상 수령 가능 |
| 비상 탈출 | L2 장애 시 즉시 출금 메커니즘 |
| UUPS 업그레이드 | 안전한 컨트랙트 업그레이드 지원 |

---

## 데이터 구조

### SequencerInfo

시퀀서 정보를 저장하는 구조체입니다.

```solidity
struct SequencerInfo {
    bool isRegistered;           // 등록 여부
    address layer2;              // L2 컨트랙트 주소
    address operatorManager;     // OperatorManager 주소
    uint256 commission;          // 커미션 (basis points, 10000 = 100%)
    uint256 totalStaked;         // 총 스테이킹량 (18 decimals)
    uint256 accRewardPerShare;   // 누적 보상/스테이크 (RAY precision)
    uint256 totalCommission;     // 누적 커미션 (27 decimals)
    bool autoTriggerEnabled;     // 자동 트리거 활성화 여부
}
```

### StakeInfo

스테이커의 스테이킹 정보를 저장하는 구조체입니다.

```solidity
struct StakeInfo {
    uint256 amount;         // 스테이킹량 (18 decimals)
    uint256 rewardDebt;     // 보상 부채 (MasterChef 계산용)
    uint256 unstakeAmount;  // 언스테이킹 대기량
    uint256 unstakeTime;    // 언스테이킹 요청 시간
}
```

### EmergencyConfig

비상 설정을 저장하는 구조체입니다.

```solidity
struct EmergencyConfig {
    bool isActive;            // 비상 모드 활성화 여부
    uint256 activationTime;   // 활성화 시간
    uint256 cooldownPeriod;   // 쿨다운 기간 (초)
    address guardian;         // Guardian 주소
}
```

### PendingCommission

커미션 변경 대기 정보를 저장하는 구조체입니다.

```solidity
struct PendingCommission {
    uint256 newCommission;   // 새 커미션 (basis points)
    uint256 effectiveTime;   // 적용 가능 시간
}
```

---

## 상수

### 공개 상수

| 상수 | 타입 | 값 | 설명 |
|------|------|-----|------|
| `MAX_COMMISSION` | uint256 | 3000 | 최대 커미션 (30%) |
| `COMMISSION_TIMELOCK` | uint256 | 7 days | 커미션 변경 타임락 |
| `STAKE_COOLDOWN` | uint256 | 12 seconds | 플래시론 보호 쿨다운 |
| `DEFAULT_MIN_STAKE` | uint256 | 100 ether | 기본 최소 스테이크 (100 TON) |
| `MAX_BATCH_SIZE` | uint256 | 50 | 배치 최대 크기 |
| `MIN_UNBONDING_PERIOD` | uint256 | 1 days | 최소 언본딩 기간 |
| `MAX_UNBONDING_PERIOD` | uint256 | 30 days | 최대 언본딩 기간 |
| `MIN_EMERGENCY_COOLDOWN` | uint256 | 1 hours | 최소 비상 쿨다운 |
| `MAX_EMERGENCY_COOLDOWN` | uint256 | 14 days | 최대 비상 쿨다운 |
| `DEFAULT_EMERGENCY_COOLDOWN` | uint256 | 3 days | 기본 비상 쿨다운 |

### 내부 상수

| 상수 | 타입 | 값 | 설명 |
|------|------|-----|------|
| `RAY` | uint256 | 1e27 | WTON 정밀도 |
| `WTON_FACTOR` | uint256 | 1e9 | TON → WTON 변환 계수 |
| `BASIS_POINTS` | uint256 | 10000 | 백분율 기준 (100% = 10000) |

---

## 시퀀서 함수

### registerSequencer

시퀀서로 등록합니다.

```solidity
function registerSequencer(
    address layer2,
    address operatorManager,
    uint256 commission
) external whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `layer2` | address | L2 컨트랙트 주소 |
| `operatorManager` | address | OperatorManager 컨트랙트 주소 |
| `commission` | uint256 | 커미션 (basis points, 최대 3000) |

**요구사항:**
- `layer2`, `operatorManager` ≠ address(0)
- 호출자가 OperatorManager의 operator여야 함
- 중복 등록 불가
- Layer2 중복 등록 불가

**이벤트:** `SequencerRegistered`

---

### deregisterSequencer

시퀀서 등록을 해제합니다.

```solidity
function deregisterSequencer() external whenNotPaused
```

**요구사항:**
- 등록된 시퀀서여야 함
- 스테이킹량이 0이어야 함

**이벤트:** `SequencerDeregistered`

**참고:** 미수령 커미션이 있으면 자동 전송됩니다.

---

### requestCommissionUpdate

커미션 변경을 요청합니다 (7일 타임락).

```solidity
function requestCommissionUpdate(uint256 newCommission) public whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `newCommission` | uint256 | 새 커미션 (basis points) |

**요구사항:**
- 등록된 시퀀서여야 함
- newCommission ≤ MAX_COMMISSION (3000)

**이벤트:** `CommissionUpdateRequested`

---

### applyCommissionUpdate

대기 중인 커미션 변경을 적용합니다.

```solidity
function applyCommissionUpdate() external whenNotPaused
```

**요구사항:**
- 등록된 시퀀서여야 함
- 대기 중인 변경이 있어야 함
- 7일 타임락이 지나야 함

**이벤트:** `CommissionUpdated`

---

### cancelCommissionUpdate

대기 중인 커미션 변경을 취소합니다.

```solidity
function cancelCommissionUpdate() external whenNotPaused
```

**요구사항:**
- 등록된 시퀀서여야 함
- 대기 중인 변경이 있어야 함

**이벤트:** `CommissionUpdateCancelled`

---

### setAutoTrigger

자동 트리거를 활성화/비활성화합니다.

```solidity
function setAutoTrigger(bool enabled) external whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `enabled` | bool | 활성화 여부 |

**이벤트:** `AutoTriggerToggled`

---

### receiveReward

보상을 수동으로 수령하고 분배합니다.

```solidity
function receiveReward(uint256 amount) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `amount` | uint256 | WTON 양 (27 decimals) |

**요구사항:**
- 등록된 시퀀서여야 함
- amount > 0
- WTON 승인 필요

**이벤트:** `RewardsReceived`

---

### claimCommission

누적된 커미션을 출금합니다.

```solidity
function claimCommission() external nonReentrant whenNotPaused
```

**요구사항:**
- 등록된 시퀀서여야 함
- 누적 커미션 > 0

**이벤트:** `CommissionClaimed`

---

## 위임자 함수

### stake

TON을 시퀀서에게 스테이킹합니다.

```solidity
function stake(address sequencer, uint256 amount) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `sequencer` | address | 시퀀서 주소 |
| `amount` | uint256 | TON 양 (18 decimals) |

**요구사항:**
- 등록된 시퀀서여야 함
- amount > 0
- 첫 스테이킹 시 최소 100 TON
- TON 승인 필요

**이벤트:** `Staked`

**참고:** 기존 미수령 보상은 자동 수령됩니다.

---

### unstake

스테이킹된 TON의 언스테이킹을 요청합니다.

```solidity
function unstake(address sequencer, uint256 amount) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `sequencer` | address | 시퀀서 주소 |
| `amount` | uint256 | TON 양 (18 decimals) |

**요구사항:**
- 충분한 스테이킹량
- amount > 0

**이벤트:** `UnstakeRequested`

**참고:**
- 기존 미수령 보상은 자동 수령됩니다.
- 언본딩 기간 후 `withdraw()` 호출 필요

---

### withdraw

언본딩 완료된 TON을 출금합니다.

```solidity
function withdraw(address sequencer) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `sequencer` | address | 시퀀서 주소 |

**요구사항:**
- 언스테이킹 요청이 있어야 함
- 언본딩 기간이 지나야 함

**이벤트:** `Withdrawn`

---

### claimRewards

미수령 보상을 수령합니다.

```solidity
function claimRewards(address sequencer) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `sequencer` | address | 시퀀서 주소 |

**요구사항:**
- 스테이킹 후 12초 쿨다운 필요 (플래시론 보호)

**이벤트:** `RewardsClaimed`

---

### redelegate

한 시퀀서에서 다른 시퀀서로 스테이킹을 이동합니다.

```solidity
function redelegate(
    address fromSequencer,
    address toSequencer,
    uint256 amount
) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `fromSequencer` | address | 출발 시퀀서 |
| `toSequencer` | address | 도착 시퀀서 |
| `amount` | uint256 | TON 양 (18 decimals) |

**요구사항:**
- fromSequencer ≠ toSequencer
- toSequencer가 등록된 시퀀서여야 함
- 충분한 스테이킹량
- amount > 0

**이벤트:** `Redelegated`

**참고:** 양쪽 시퀀서의 미수령 보상이 자동 수령됩니다.

---

## 트리거 함수

### triggerSeigniorage

시퀀서의 시뇨리지를 트리거합니다.

```solidity
function triggerSeigniorage(address sequencer) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `sequencer` | address | 시퀀서 주소 |

**요구사항:**
- 등록된 시퀀서여야 함
- 자동 트리거가 활성화되어 있거나 호출자가 시퀀서여야 함

**이벤트:** `SeigniorageTriggered`

---

### batchTriggerSeigniorage

여러 시퀀서의 시뇨리지를 배치로 트리거합니다.

```solidity
function batchTriggerSeigniorage(address[] calldata sequencerList) external nonReentrant whenNotPaused
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `sequencerList` | address[] | 시퀀서 주소 배열 |

**요구사항:**
- sequencerList.length ≤ MAX_BATCH_SIZE (50)

**이벤트:** `SeigniorageTriggered` (각 성공한 시퀀서마다)

**참고:** 자동 트리거가 비활성화된 시퀀서는 건너뜁니다.

---

## 비상 함수

### activateEmergency

L2의 비상 모드를 활성화합니다.

```solidity
function activateEmergency(address layer2) external
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `layer2` | address | L2 컨트랙트 주소 |

**요구사항:**
- Guardian 또는 Owner만 호출 가능
- 이미 활성화되어 있지 않아야 함

**이벤트:** `EmergencyActivated`

---

### deactivateEmergency

L2의 비상 모드를 해제합니다.

```solidity
function deactivateEmergency(address layer2) external
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `layer2` | address | L2 컨트랙트 주소 |

**요구사항:**
- Guardian 또는 Owner만 호출 가능
- 비상 모드가 활성화되어 있어야 함

**이벤트:** `EmergencyDeactivated`

---

### emergencyWithdraw

비상 모드에서 즉시 출금합니다.

```solidity
function emergencyWithdraw(address sequencer) external nonReentrant
```

**파라미터:**

| 이름 | 타입 | 설명 |
|------|------|------|
| `sequencer` | address | 시퀀서 주소 |

**요구사항:**
- 비상 모드가 활성화되어 있어야 함
- 쿨다운 기간이 지나야 함
- 출금할 잔액이 있어야 함

**이벤트:** `EmergencyWithdrawn`

**참고:**
- 스테이킹량 + 언스테이킹 대기량 모두 출금됩니다.
- 미수령 WTON 보상도 함께 수령됩니다.

---

## 관리자 함수

### pause / unpause

컨트랙트를 일시 정지/재개합니다.

```solidity
function pause() external onlyOwner
function unpause() external onlyOwner
```

---

### setUnbondingPeriod

언본딩 기간을 설정합니다.

```solidity
function setUnbondingPeriod(uint256 _unbondingPeriod) external onlyOwner
```

**요구사항:**
- MIN_UNBONDING_PERIOD ≤ 값 ≤ MAX_UNBONDING_PERIOD

**이벤트:** `UnbondingPeriodUpdated`

---

### setSeigManager / setLayer2Manager

V3 컨트랙트 주소를 설정합니다.

```solidity
function setSeigManager(address _seigManager) external onlyOwner
function setLayer2Manager(address _layer2Manager) external onlyOwner
```

**이벤트:** `SeigManagerUpdated`, `Layer2ManagerUpdated`

---

### setDefaultGuardian

기본 Guardian을 설정합니다.

```solidity
function setDefaultGuardian(address _guardian) external onlyOwner
```

**요구사항:**
- _guardian ≠ address(0)

**이벤트:** `DefaultGuardianUpdated`

---

### setLayer2Guardian

L2별 Guardian을 설정합니다.

```solidity
function setLayer2Guardian(address layer2, address guardian) external onlyOwner
```

**요구사항:**
- guardian ≠ address(0)

**이벤트:** `Layer2GuardianUpdated`

---

### setEmergencyCooldown

L2의 비상 쿨다운을 설정합니다.

```solidity
function setEmergencyCooldown(address layer2, uint256 cooldownPeriod) external onlyOwner
```

**요구사항:**
- MIN_EMERGENCY_COOLDOWN ≤ 값 ≤ MAX_EMERGENCY_COOLDOWN

**이벤트:** `EmergencyCooldownUpdated`

---

### setMinStakeAmount

최소 스테이크량을 설정합니다.

```solidity
function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner
```

**이벤트:** `MinStakeAmountUpdated`

---

### rescueTokens

잔류 토큰을 회수합니다.

```solidity
function rescueTokens(address token, address to, uint256 amount) external onlyOwner
```

**요구사항:**
- to ≠ address(0)
- token ≠ TON, WTON (스테이킹 토큰 보호)

**이벤트:** `TokensRescued`

---

## 조회 함수

### getStakeInfo

스테이커의 스테이킹 정보를 조회합니다.

```solidity
function getStakeInfo(address staker, address sequencer) external view returns (StakeInfo memory)
```

### getSequencerInfo

시퀀서 정보를 조회합니다.

```solidity
function getSequencerInfo(address sequencer) external view returns (SequencerInfo memory)
```

### pendingRewards

미수령 보상을 조회합니다.

```solidity
function pendingRewards(address staker, address sequencer) external view returns (uint256)
```

**반환값:** WTON 양 (27 decimals)

### getSequencerList

등록된 시퀀서 목록을 조회합니다.

```solidity
function getSequencerList() external view returns (address[] memory)
```

### getSequencerCount

등록된 시퀀서 수를 조회합니다.

```solidity
function getSequencerCount() external view returns (uint256)
```

### getSequencerByLayer2

L2에 매핑된 시퀀서를 조회합니다.

```solidity
function getSequencerByLayer2(address layer2) external view returns (address)
```

### getTotalStaked

전체 스테이킹량을 조회합니다.

```solidity
function getTotalStaked() external view returns (uint256)
```

**반환값:** TON 양 (18 decimals)

### getPendingCommission

대기 중인 커미션 변경을 조회합니다.

```solidity
function getPendingCommission(address sequencer) external view returns (uint256 newCommission, uint256 effectiveTime)
```

### getEmergencyConfig

비상 설정을 조회합니다.

```solidity
function getEmergencyConfig(address layer2) external view returns (EmergencyConfig memory)
```

### checkLayer2Eligibility

L2의 V3 자격 요건을 확인합니다.

```solidity
function checkLayer2Eligibility(address layer2) external view returns (
    bool eligible,
    uint256 requiredStake,
    uint256 currentStake
)
```

### estimateSeigniorage

예상 시뇨리지를 조회합니다.

```solidity
function estimateSeigniorage(address sequencer) external view returns (
    uint256 sequencerReward,
    uint256 validatorReward
)
```

### version

컨트랙트 버전을 조회합니다.

```solidity
function version() external pure returns (string memory)
```

**반환값:** "1.3.0"

---

## 이벤트

### 시퀀서 이벤트

```solidity
event SequencerRegistered(
    address indexed sequencer,
    address indexed layer2,
    address indexed operatorManager,
    uint256 commission
);

event SequencerDeregistered(address indexed sequencer);

event CommissionUpdated(
    address indexed sequencer,
    uint256 oldCommission,
    uint256 newCommission
);

event CommissionUpdateRequested(
    address indexed sequencer,
    uint256 currentCommission,
    uint256 newCommission,
    uint256 effectiveTime
);

event CommissionUpdateCancelled(
    address indexed sequencer,
    uint256 cancelledCommission
);

event AutoTriggerToggled(address indexed sequencer, bool enabled);
```

### 스테이킹 이벤트

```solidity
event Staked(
    address indexed staker,
    address indexed sequencer,
    uint256 amount
);

event UnstakeRequested(
    address indexed staker,
    address indexed sequencer,
    uint256 amount,
    uint256 unlockTime
);

event Withdrawn(
    address indexed staker,
    address indexed sequencer,
    uint256 amount
);

event Redelegated(
    address indexed staker,
    address indexed fromSequencer,
    address indexed toSequencer,
    uint256 amount
);
```

### 보상 이벤트

```solidity
event RewardsReceived(
    address indexed sequencer,
    uint256 totalAmount,
    uint256 commission,
    uint256 distributed
);

event RewardsClaimed(
    address indexed staker,
    address indexed sequencer,
    uint256 amount
);

event CommissionClaimed(address indexed sequencer, uint256 amount);

event SeigniorageTriggered(
    address indexed sequencer,
    uint256 amount,
    address indexed triggeredBy
);
```

### 비상 이벤트

```solidity
event EmergencyActivated(
    address indexed layer2,
    address indexed activatedBy,
    uint256 activationTime
);

event EmergencyDeactivated(
    address indexed layer2,
    address indexed deactivatedBy
);

event EmergencyWithdrawn(
    address indexed staker,
    address indexed sequencer,
    uint256 amount
);
```

### 관리 이벤트

```solidity
event UnbondingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
event SeigManagerUpdated(address oldManager, address newManager);
event Layer2ManagerUpdated(address oldManager, address newManager);
event DefaultGuardianUpdated(address oldGuardian, address newGuardian);
event Layer2GuardianUpdated(address indexed layer2, address oldGuardian, address newGuardian);
event EmergencyCooldownUpdated(address indexed layer2, uint256 oldCooldown, uint256 newCooldown);
event MinStakeAmountUpdated(uint256 oldAmount, uint256 newAmount);
event TokensRescued(address indexed token, address indexed to, uint256 amount);
```

---

## 에러

### 일반 에러

```solidity
error ZeroAddress();           // 주소가 0
error ZeroAmount();            // 양이 0
error InvalidCommission();     // 잘못된 커미션 값
error InsufficientBalance();   // 잔액 부족
error Unauthorized();          // 권한 없음
```

### 시퀀서 에러

```solidity
error SequencerAlreadyRegistered();  // 이미 등록됨
error SequencerNotRegistered();       // 등록되지 않음
error Layer2AlreadyRegistered();      // L2 중복 등록
error InvalidOperatorManager();       // 잘못된 OperatorManager
error AutoTriggerDisabled();          // 자동 트리거 비활성화
```

### 스테이킹 에러

```solidity
error NoUnstakeRequest();             // 언스테이킹 요청 없음
error UnstakingPeriodNotElapsed();    // 언본딩 기간 미경과
error NoPendingRewards();             // 미수령 보상 없음
error BelowMinimumStake();            // 최소 스테이크 미달
error StakeCooldownNotElapsed();      // 쿨다운 미경과
error CannotRedelegateToSame();       // 같은 시퀀서로 재위임
```

### 커미션 에러

```solidity
error NoPendingCommission();          // 대기 중인 변경 없음
error CommissionTimelockNotElapsed(); // 타임락 미경과
```

### 비상 에러

```solidity
error EmergencyNotActive();           // 비상 모드 비활성화
error EmergencyAlreadyActive();       // 이미 활성화됨
error EmergencyCooldownNotElapsed();  // 비상 쿨다운 미경과
error NotGuardian();                  // Guardian 아님
```

### 설정 에러

```solidity
error UnbondingPeriodOutOfBounds();       // 언본딩 기간 범위 초과
error EmergencyCooldownOutOfBounds();     // 비상 쿨다운 범위 초과
error BatchSizeExceeded();                // 배치 크기 초과
error CannotRescueStakingTokens();        // 스테이킹 토큰 회수 불가
```

---

## 사용 예시

### JavaScript/ethers.js

```javascript
import { ethers } from 'ethers';

const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

const staking = new ethers.Contract(PROXY_ADDRESS, ABI, signer);

// 스테이킹
const ton = new ethers.Contract(TON_ADDRESS, ERC20_ABI, signer);
await ton.approve(PROXY_ADDRESS, ethers.utils.parseEther('1000'));
await staking.stake(SEQUENCER_ADDRESS, ethers.utils.parseEther('1000'));

// 미수령 보상 확인
const pending = await staking.pendingRewards(signer.address, SEQUENCER_ADDRESS);
console.log('Pending rewards:', ethers.utils.formatUnits(pending, 27), 'WTON');

// 보상 수령
await staking.claimRewards(SEQUENCER_ADDRESS);

// 언스테이킹
await staking.unstake(SEQUENCER_ADDRESS, ethers.utils.parseEther('500'));

// 언본딩 후 출금
await staking.withdraw(SEQUENCER_ADDRESS);
```

### Foundry/Solidity

```solidity
// 테스트에서 사용
function testStaking() public {
    // 승인
    ton.approve(address(staking), 1000 ether);

    // 스테이킹
    staking.stake(sequencer, 1000 ether);

    // 정보 확인
    IDelegateStakingV3.StakeInfo memory info = staking.getStakeInfo(user, sequencer);
    assertEq(info.amount, 1000 ether);

    // 보상 확인
    uint256 pending = staking.pendingRewards(user, sequencer);

    // 언스테이킹
    staking.unstake(sequencer, 500 ether);

    // 시간 경과
    vm.warp(block.timestamp + 7 days);

    // 출금
    staking.withdraw(sequencer);
}
```

### Cast (CLI)

```bash
# 스테이킹 정보 조회
cast call $PROXY "getStakeInfo(address,address)" $USER $SEQUENCER --rpc-url $RPC

# 미수령 보상 조회
cast call $PROXY "pendingRewards(address,address)(uint256)" $USER $SEQUENCER --rpc-url $RPC

# 스테이킹 (트랜잭션)
cast send $PROXY "stake(address,uint256)" $SEQUENCER 1000000000000000000000 --private-key $KEY --rpc-url $RPC

# 시퀀서 목록 조회
cast call $PROXY "getSequencerList()(address[])" --rpc-url $RPC
```
