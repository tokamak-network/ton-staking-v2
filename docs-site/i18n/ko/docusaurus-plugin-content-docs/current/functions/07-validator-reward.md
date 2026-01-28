---
id: functions-validator-reward
sidebar_position: 7
---

# ValidatorReward 함수

밸리데이터 보상 분배 및 청구 함수입니다.

## distributeL2Rewards

L2별 검증자 보상을 분배합니다.

```solidity
function distributeL2Rewards(address systemConfig, uint256 amount) external onlySeigManager
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | SeigManager |
| **접근 제어** | `onlySeigManager` |
| **가스 복잡도** | O(1) - 검증자 수와 무관 |

**동작 흐름**:
```
1. RAT.getActiveValidatorCount(systemConfig) 조회
2. |V_i| = 0인 경우:
   └─► WTON.transfer(seigManager.dao(), amount)
       └─► 이벤트: RewardToDAO

3. |V_i| > 0인 경우:
   └─► perValidator = amount / activeCount
   └─► rewardPerValidator[systemConfig] += perValidator (O(1) 누적)
   └─► 이벤트: L2RewardDistributed
```

**RewardPerValidator 패턴**:
- O(1) 복잡도: 검증자별 순회 없이 전역 누적값만 업데이트
- L2별 보상 추적은 이벤트(`ValidatorRewardReceived`)를 통해 수행
- 검증자 없을 때 `seigManager.dao()`로 전송

---

## claimAllRewards

모든 L2에서 받은 보상을 청구합니다.

```solidity
function claimAllRewards() external ifFree
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **가스 복잡도** | O(L) - 검증자가 등록된 L2 수에 비례 |
| **주의** | 등록된 L2가 많으면 가스 한도 초과 가능 → `claimRewardsByL2s` 사용 권장 |

**동작 흐름**:
```
1. _syncAllRewards(validator): 모든 L2 보상 동기화
   └─► 각 L2에 대해:
       - earned = rewardPerValidator[systemConfig] - validatorRewardDebt[validator][systemConfig]
       - 활성 검증자인 경우에만 validatorPendingRewards[validator] += earned
       - validatorRewardDebt[validator][systemConfig] = rewardPerValidator[systemConfig]
       - 이벤트: ValidatorRewardReceived (각 L2)

2. total = validatorPendingRewards[msg.sender]
3. validatorPendingRewards[msg.sender] = 0
4. WTON.transfer(msg.sender, total)
5. 이벤트: RewardsClaimed
```

---

## claimRewardsByL2s

특정 L2들에서 받은 보상을 청구합니다 (가스 최적화용).

```solidity
function claimRewardsByL2s(address[] calldata systemConfigs) external ifFree
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **가스 복잡도** | O(N) - 지정된 L2 수에 비례 |
| **용도** | 등록된 L2가 많을 때 배치로 청구 |

**동작 흐름**:
```
1. 지정된 L2들만 보상 동기화
   └─► 각 systemConfig에 대해:
       - isValidatorInL2[validator][systemConfig] 확인
       - 등록된 L2만 _syncReward 호출

2. total = validatorPendingRewards[msg.sender]
3. validatorPendingRewards[msg.sender] = 0
4. WTON.transfer(msg.sender, total)
5. 이벤트: RewardsClaimed
```

**사용 예시** (100개 L2 등록 시):
```solidity
// 배치 1: 처음 50개 L2 청구
address[] memory batch1 = new address[](50);
// ... batch1 배열 설정
validatorReward.claimRewardsByL2s(batch1);

// 배치 2: 나머지 50개 L2 청구
address[] memory batch2 = new address[](50);
// ... batch2 배열 설정
validatorReward.claimRewardsByL2s(batch2);
```

**지연 계산 (Lazy Evaluation)**:
- 보상은 분배 시점이 아닌 청구 시점에 계산됨
- 비활성화된 검증자는 보상을 받지 않음

---

## registerValidatorToL2

검증자를 L2에 등록합니다 (RAT에서 호출).

```solidity
function registerValidatorToL2(address validator, address systemConfig) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | RAT 컨트랙트 |
| **접근 제어** | `msg.sender == ratContract` |

**동작 흐름**:
```
1. 이미 등록된 경우 스킵
2. validatorL2List[validator].push(systemConfig)
3. isValidatorInL2[validator][systemConfig] = true
4. validatorRewardDebt[validator][systemConfig] = rewardPerValidator[systemConfig]
5. 이벤트: ValidatorRegisteredToL2
```

---

## syncValidatorReward / resetValidatorDebt

검증자 비활성화/재활성화 시 보상 동기화를 처리합니다.

```solidity
function syncValidatorReward(address validator, address systemConfig) external
function resetValidatorDebt(address validator, address systemConfig) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | RAT 컨트랙트 |
| **접근 제어** | `msg.sender == ratContract` |

**syncValidatorReward** (비활성화 전):
- 현재까지의 보상을 `validatorPendingRewards`에 누적
- 비활성화되어도 누적된 보상은 청구 가능

**resetValidatorDebt** (재활성화 시):
- `validatorRewardDebt`를 현재 `rewardPerValidator`로 리셋
- 비활성화 기간 동안의 보상을 받지 않도록 처리

---

## 조회 함수

```solidity
// 총 청구 가능 보상 조회 (미동기화 보상 포함)
function getClaimableRewards(address validator) external view returns (uint256 total)

// 총 미청구 보상 조회 (동기화된 것만)
function getPendingRewards(address validator) external view returns (uint256)

// L2별 미청구 보상 조회 (이벤트 사용 권장)
function getPendingRewardsByL2(address validator, address systemConfig)
    external pure returns (uint256)  // 항상 0 반환
```

**권장 사용법**:
- 총 보상 조회: `getClaimableRewards(validator)`
- L2별 보상 추적: `ValidatorRewardReceived` 이벤트 구독

---

## 검증자 재등록 메커니즘

검증자가 비활성화 후 재등록할 때의 보상 처리 메커니즘입니다.

### 비활성화 시

```
1. RAT.deactivateValidator() 호출 (자발적 탈퇴)
   또는
   RAT.triggerAttentionTest() 자동 제거 (담보금 부족)
   ↓
2. RAT → ValidatorReward.syncValidatorReward(validator, systemConfig)
   ↓
3. 현재까지 누적 보상 저장:
   validatorPendingRewards[validator] += (earned - debt)
   ↓
4. isActive = false 설정
```

### 비활성화 기간

```
- 새 보상 분배 시 분배 대상에서 제외됨
- isActive = false이므로 activeValidatorCount에 포함되지 않음
- 분배량 = totalAmount / activeValidatorCount (비활성 검증자 제외)
- 비활성 검증자는 받지 못하고, 활성 검증자들만 나눠 받음
```

### 재등록 시

```
1. 담보금 보충: DepositManager.deposit()로 D_min 이상 예치
   ↓
2. RAT.registerValidator(systemConfig) 호출 (재등록)
   ↓
3. RAT → ValidatorReward.resetValidatorDebt(validator, systemConfig)
   ↓
4. debt[validator][systemConfig] = rewardPerValidator[systemConfig]
   (현재 시점으로 debt 리셋)
   ↓
5. isActive = true 설정
```

### 재등록 후

```
- 기존 동기화된 보상(3단계 저장분)만 청구 가능
- 비활성화 기간에는 분배 대상에서 제외되어 받지 못함 (활성 검증자들이 나눠 받음)
- 재등록 시점 이후 새 보상부터 다시 받음
```

**예시**:

```solidity
// 1. 검증자 등록 → 보상 1000 분배 → 청구 가능: 1000

// 2. 검증자 비활성화 (syncValidatorReward 호출)
//    → validatorPendingRewards[validator] = 1000

// 3. 비활성화 기간 → 보상 2000 분배
//    → 비활성이므로 분배 대상 제외 (활성 검증자들이 나눠 받음)
//    → validator1 청구 가능: 1000 (그대로)

// 4. 검증자 재등록 (resetValidatorDebt 호출)
//    → debt = 현재 rewardPerValidator(3000)로 리셋
//    → 청구 가능: 1000 (그대로)

// 5. 재등록 후 보상 500 분배
//    → rewardPerValidator = 3500
//    → earned = 3500 - 3000 = 500
//    → 청구 가능: 1000 + 500 = 1500
```

**참고**: 비활성화 기간의 보상(2000)은 validator1에게 분배되지 않고, 활성 검증자들이 나눠 받았음.

---

## 비활성 검증자 제외 메커니즘

보상 분배 시 비활성 검증자는 자동으로 제외됩니다.

```solidity
// distributeL2Rewards() 내부
activeValidatorCount = RAT.getActiveValidatorCount(systemConfig)
perValidator = totalAmount / activeValidatorCount  // 비활성 제외

// 예시:
// 총 검증자: 5명
// 활성 검증자: 3명 (2명 비활성)
// 보상: 1000 WTON
// → perValidator = 1000 / 3 = 333.33 WTON (활성 검증자만)
```

**효과**:
- 비활성 검증자는 보상 0
- 활성 검증자들이 더 많은 보상 받음
- 검증자 참여 인센티브 강화

---

## 검증자 없을 때 DAO 전송

검증자가 0명이면 전체 검증자 보상이 DAO Treasury로 전송됩니다.

```solidity
if (activeValidatorCount == 0) {
    address daoVault = ISeigManager(seigManager).dao();
    WTON.transfer(daoVault, amount);
    emit RewardToDAO(systemConfig, amount);
    return;
}
```

**이벤트**:
```solidity
event RewardToDAO(
    address indexed systemConfig,
    uint256 amount
);
```
