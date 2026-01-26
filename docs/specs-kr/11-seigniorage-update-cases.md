# 시뇨리지 갱신 관련 전체 케이스 정리

> **최종 업데이트**: 2026-01-26

---

## 1. 호출 경로별 일시정지 체크 현황

| 함수 | 전역 paused 체크 | L2별 paused 체크 | allowed 체크 |
|------|-----------------|-----------------|--------------|
| `updateSeigniorage()` | ✅ early return | - | - |
| `_claimL2RewardsOnly()` | - | ✅ early return | ✅ early return |
| `_claimL2Rewards()` | - | ✅ early return | ✅ early return |
| `onBridgedTonChange()` | ❌ 없음 | ❌ 없음 | ❌ 없음 |
| `onStakingChange()` | ❌ 없음 | ❌ 없음 | ❌ 없음 |
| `_updateEligibilityInternal()` | ❌ 없음 | ❌ 없음 | ❌ 없음 |
| `_triggerSeigniorageDistribution()` | ✅ early return | ❌ 없음 | ❌ 없음 |
| `_handleEligibilityLoss()` | ❌ 없음 | ❌ 없음 | ✅ claim만 |
| `checkCurrentEligibility()` | ❌ 없음 | ❌ 없음 | ❌ 없음 |

**참고**: `checkCurrentEligibility()`는 `bridgedTon = 0`이면 `eligible = false` 반환

---

## 2. 함수 호출 경로

### 2.1 시뇨리지 분배 경로

```
updateSeigniorage() [external]
  └→ _updateSeigniorageV3() [internal]
       ├→ if (paused) return true;  ← 전역 일시정지 체크
       ├→ _checkCoinage()  ← coinage 없으면 revert
       ├→ 같은 블록: _claimL2RewardsOnly()
       │              └→ if (!allowed || _isPauseL2Seigniorage) return;
       └→ 다른 블록: _increaseTotV3()
                      └→ _distributeV3Seigniorage()
                           ├→ 전역 시뇨리지 mint (layer2Manager, validatorReward)
                           ├→ rewardPerUnit 업데이트
                           └→ _claimL2Rewards()
                                └→ if (!allowed || _isPauseL2Seigniorage) return 0;
```

### 2.2 자격 변경 경로

```
onBridgedTonChange() [external, Portal 호출]
  └→ if (!v3Migrated) return;
  └→ _updateEligibilityInternal(layer2)

onStakingChange() [external, DepositManager 호출]
  └→ if (!v3Migrated) return;
  └→ _updateEligibilityInternal(layer2)

_updateEligibilityInternal(layer2) [internal]
  ├→ oldEligible = info.isEligible
  ├→ currentBridgedTON = Layer2Manager.getBridgedTonByLayer(layer2) * GWEI_UNIT
  ├→ (newEligible, , ) = checkCurrentEligibility(layer2)
  │    └→ bridgedTon = 0이면 eligible = false
  ├→ Case 1: 자격 유지 (oldEligible == newEligible)
  │    └→ 아무것도 안 함 (return)
  └→ Case 2: 자격 변경
       ├→ _triggerSeigniorageDistribution() ← 먼저 시뇨리지 정산!
       ├→ 자격 상실 (true → false): _handleEligibilityLoss(layer2)
       └→ 자격 획득 (false → true): effectiveBridgedTON 설정 + initialDebt 설정
```

### 2.4 자격 변경 처리 원칙

| 상태 변경 | 동작 |
|----------|------|
| 자격 유지 (eligible → eligible) | 아무것도 안 함 |
| 자격 유지 (ineligible → ineligible) | 아무것도 안 함 |
| 자격 상실 (eligible → ineligible) | **시뇨리지 정산** + 미청구 보상 자동 claim + effectiveBridgedTON = 0 |
| 자격 획득 (ineligible → eligible) | **시뇨리지 정산** + effectiveBridgedTON 설정 + initialDebt 설정 |

**자격 조건** (checkCurrentEligibility):
- `bridgedTon > 0` (필수)
- `currentStake >= requiredStake`

**bridgedTon = 0이면 무조건 자격 없음**:
- 최초 등록 시: TON 브릿지 전까지 자격 없음 → TON 브릿지 시 자격 획득
- 중간 출금 시: 자격 상실 → `_handleEligibilityLoss` 트리거 → 미청구 보상 자동 claim

**설계 근거**:
- 시뇨리지 청구는 `updateSeigniorage` 시점에만 발생
- `_updateEligibilityInternal`은 상태 추적만 담당
- 자격이 유지되면 `effectiveBridgedTON` 업데이트 불필요 (다음 `updateSeigniorage`에서 처리)
- bridgedTON 변경 시 즉시 반영하지 않고, `updateSeigniorage` 호출 시 반영
- **자격 획득 시 시뇨리지 정산**: 새 L2가 참여하기 전에 기존 L2들에게 공정하게 분배

### 2.3 자격 상실 처리

```
_handleEligibilityLoss(layer2) [internal]
  ├→ (rollupConfig, allowed) = _allowIssuanceLayer2Seigs(layer2)
  └→ if (info.effectiveBridgedTON > 0)
       ├→ if (allowed)  ← 일시정지(paused) 체크 없음!
       │    ├→ layer2Seigs 계산 (sequencer 보상)
       │    ├→ valReward 계산 (validator 보상)
       │    ├→ transferL2Seigniorage() (sequencer)
       │    └→ distributeL2Rewards() (validator)
       ├→ totalEffectiveBridgedTON -= info.effectiveBridgedTON
       └→ info.effectiveBridgedTON = 0
```

---

## 3. 케이스별 동작

### Case A: 정상 상태 (paused=false, allowed=true)

| 함수 | 동작 |
|------|------|
| `updateSeigniorage()` | 시뇨리지 분배 + claim ✓ |
| `onStakingChange()` | eligibility 업데이트 ✓ |
| `onBridgedTonChange()` | eligibility 업데이트 ✓ |
| 자격 상실 시 | `_handleEligibilityLoss()` → 미청구 보상 claim ✓ |

### Case B: 전역 일시정지 (paused=true)

| 함수 | 동작 |
|------|------|
| `updateSeigniorage()` | early return (시뇨리지 분배 안 됨) |
| `onStakingChange()` | eligibility 업데이트 ✓ (일시정지 무시!) |
| `onBridgedTonChange()` | eligibility 업데이트 ✓ (일시정지 무시!) |
| 자격 상실 시 | `_handleEligibilityLoss()` → 미청구 보상 claim ✓ |

**주의**: 전역 일시정지 상태에서도 자격 변경은 처리됨

### Case C: L2별 일시정지 (`_isPauseL2Seigniorage=true`)

| 함수 | 동작 |
|------|------|
| `updateSeigniorage()` | 전역 분배 O, 해당 L2 claim ✗ |
| `onStakingChange()` | eligibility 업데이트 ✓ (일시정지 무시!) |
| `onBridgedTonChange()` | eligibility 업데이트 ✓ (일시정지 무시!) |
| 자격 상실 시 | effectiveBridgedTON=0 (이미 `excludeFromL2Seigniorage`에서 설정) |
|             | `_handleEligibilityLoss()`에서 아무것도 안 함 |

**안전**: L2별 일시정지 시 `excludeFromL2Seigniorage`에서 이미 `effectiveBridgedTON=0`으로 설정됨

### Case D: 비허용 상태 (allowed=false)

| 함수 | 동작 |
|------|------|
| `updateSeigniorage()` | 전역 분배 O, 해당 L2 claim ✗ |
| `onStakingChange()` | eligibility 업데이트 ✓ |
| `onBridgedTonChange()` | eligibility 업데이트 ✓ |
| 자격 상실 시 | `_handleEligibilityLoss()` → claim ✗, effectiveBridgedTON=0 ✓ |
|             | **미청구 보상 손실 가능!** |

**주의**: 비허용 상태에서 자격 상실 시 미청구 보상이 손실될 수 있음

---

## 4. 잠재적 문제점 및 설계 결정

| 케이스 | 현상 | 현재 동작 | 의도된 동작? |
|--------|------|----------|-------------|
| 전역 paused + 자격 변경 | eligibility 변경됨 | `_handleEligibilityLoss` 호출, claim됨 | ✅ 의도됨 |
| L2 paused + 자격 변경 | effectiveBridgedTON 이미 0 | 아무것도 안 함 | ✅ 안전 |
| allowed=false + 자격 상실 | 미청구 보상 손실 | claim 안 됨 | ❓ 확인 필요 |

---

## 5. 현재 `_handleEligibilityLoss` 로직

```solidity
/// @dev 자격 상실 처리: 미청구 보상 자동 claim + effectiveBridgedTON 초기화
/// @param layer2 자격을 상실하는 L2 주소
function _handleEligibilityLoss(address layer2) internal {
    address rollupConfig;
    bool allowed;
    (rollupConfig, allowed) = _allowIssuanceLayer2Seigs(layer2);

    BridgedTONInfo storage info = bridgedTONInfo[layer2];

    uint256 layer2Seigs = 0;
    uint256 valReward = 0;

    // effectiveBridgedTON > 0인 경우에만 처리 (이미 일시정지/비허용으로 0인 경우 스킵)
    if (info.effectiveBridgedTON > 0) {
        // 미청구 보상 자동 claim (일시정지 상태에서도 기존 미청구 보상은 claim 허용)
        // 일시정지는 "새로운 시뇨리지 분배 중단"이지 "기존 미청구 보상 claim 차단"이 아님
        if (allowed) {
            // Sequencer 보상: bridgedTONRewardPerUint 기반
            layer2Seigs = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.initialDebt;

            // Validator 보상: validatorRewardPerUint 기반
            valReward = (validatorRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.validatorInitialDebt;

            // Sequencer 보상 transfer
            if (layer2Seigs > 0) {
                ILayer2Manager(layer2Manager).transferL2Seigniorage(layer2, layer2Seigs);
            }

            // Validator 보상 분배
            if (valReward > 0 && validatorReward != address(0)) {
                IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
            }
        }

        // effectiveBridgedTON 초기화
        totalEffectiveBridgedTON -= info.effectiveBridgedTON;
        info.effectiveBridgedTON = 0;
    }

    emit AutoClaimBeforeEligibilityLoss(layer2, layer2Seigs, valReward);
}
```

---

## 6. 설계 근거

### 6.1 일시정지 상태에서 자격 변경 허용 이유

- 일시정지는 **새로운 시뇨리지 분배 중단**을 의미
- 기존 미청구 보상의 claim은 차단하지 않음
- 자격 변경(eligibility)은 상태 관리이므로 일시정지와 무관

### 6.2 L2별 일시정지가 안전한 이유

- `excludeFromL2Seigniorage` 호출 시 `effectiveBridgedTON = 0`으로 설정
- 따라서 `_handleEligibilityLoss`에서 `if (info.effectiveBridgedTON > 0)` 조건이 false
- 추가 처리 불필요

### 6.3 allowed=false 시 미청구 보상 손실에 대해

- `allowed = false`는 L2가 시뇨리지 발행 비허용 상태
- 이 경우 보상을 받을 권리가 없다고 판단
- **의도된 동작**으로 볼 수 있음 (비허용 = 보상 권리 없음)

### 6.4 자격 변경 시 시뇨리지 정산 이유

자격이 변경될 때 (`_updateEligibilityInternal`에서) `_triggerSeigniorageDistribution()`을 **먼저** 호출하는 이유:

#### 자격 상실 시:
1. **rewardPerUnit 최신화**: `lastSeigBlock` ~ 현재 블록까지의 시뇨리지 분배
2. **정확한 미청구 보상 계산**: `_handleEligibilityLoss`에서 최신 rewardPerUnit 기반으로 claim
3. **시뇨리지 손실 방지**: `updateSeigniorage` 없이 바로 `onStakingChange` 호출해도 보상 누락 없음

#### 자격 획득 시:
1. **공정성 보장**: 기존 L2들이 지금까지 축적한 시뇨리지를 먼저 정산
2. **rewardPerUnit 업데이트**: 새 L2의 initialDebt는 최신 rewardPerUnit 기준으로 설정
3. **중복 분배 방지**: 같은 블록에서 여러 L2가 자격 획득해도 시뇨리지는 한 번만 분배

```
_triggerSeigniorageDistribution() [internal]
  ├→ if (paused) return;  ← 일시정지 시 스킵
  ├→ if (block.number <= _lastSeigBlock) return;  ← 같은 블록이면 스킵
  ├→ if (address(_tot) == address(0)) return;  ← tot 없으면 스킵
  ├→ if (_tot.totalSupply() == 0) → _lastSeigBlock 업데이트 후 return
  └→ 시뇨리지 분배 (claim 없이 rewardPerUnit만 업데이트)
       ├→ A = span * _seigPerBlock
       ├→ rewardPerUnit 업데이트
       ├→ WTON mint (Layer2Manager, ValidatorReward)
       └→ DAO 보상 mint
```

---

## 7. 관련 테스트

### EligibilityTransition.t.sol

| 테스트 ID | 테스트명 | 검증 내용 |
|----------|---------|----------|
| INT-040 | `test_INT040_autoClaimBeforeEligibilityLoss` | 자격 상실 시 미청구 보상 자동 claim |
| INT-041 | `test_INT041_separatedRewardPerUnitTracking` | sequencer/validator rewardPerUnit 분리 추적 |
| INT-042 | `test_INT042_initialDebtResetOnReeligibility` | 자격 재획득 시 initialDebt 리셋 |
| INT-043 | `test_INT043_fullEligibilityTransitionFlow` | 자격 획득→보상→상실→재획득 전체 플로우 |
| INT-044 | `test_INT044_autoClaimEventEmitted` | AutoClaimBeforeEligibilityLoss 이벤트 발생 |
| INT-045 | `test_INT045_pausedState_eligibilityLoss_claimUnclaimedRewards` | paused 상태에서 자격 상실 시 미청구 보상 claim |
| INT-046 | `test_INT046_pausedState_eligibilityGain_setsEffectiveBridgedTON` | paused 상태에서 자격 획득 시 effectiveBridgedTON 설정 |
| INT-047 | `test_INT047_eligibilityLoss_triggersSeigDistribution` | 자격 상실 시 시뇨리지 자동 정산 (updateSeigniorage 없이) |
| INT-048 | `test_INT048_eligibilityGain_triggersSeigDistribution` | 자격 획득 시 기존 L2에게 먼저 시뇨리지 정산 |

---

## 8. 관련 코드 위치

| 함수 | 파일 | 라인 |
|------|------|------|
| `updateSeigniorage()` | SeigManagerV3_1.sol | 482 |
| `_updateSeigniorageV3()` | SeigManagerV3_1.sol | 535 |
| `onBridgedTonChange()` | SeigManagerV3_1.sol | 252 |
| `onStakingChange()` | SeigManagerV3_1.sol | 268 |
| `_updateEligibilityInternal()` | SeigManagerV3_1.sol | 273 |
| `checkCurrentEligibility()` | SeigManagerV3_1.sol | 321 |
| `_handleEligibilityLoss()` | SeigManagerV3_1.sol | 693 |
| `_triggerSeigniorageDistribution()` | SeigManagerV3_1.sol | 738 |
| `_claimL2Rewards()` | SeigManagerV3_1.sol | 658 |
| `_claimL2RewardsOnly()` | SeigManagerV3_1.sol | 556 |
| `excludeFromL2Seigniorage()` | SeigManagerV3_1.sol | 229 |
| `includeFromL2Seigniorage()` | SeigManagerV3_1.sol | 235 |
