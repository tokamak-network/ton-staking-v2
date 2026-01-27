# 시뇨리지 갱신 관련 전체 케이스 정리

> **최종 업데이트**: 2026-01-27

---

## 시뇨리지 민팅 발생 시점

### 민팅 트리거

| 트리거 | 민팅 발생? |
|--------|----------|
| `updateSeigniorage()` 호출 | ✅ |
| 자격 변경 (가능↔불가) | ✅ |
| 자격 유지 (변화 없음) | ❌ |

### 자격 변경 케이스

| 상황 | 자격 변경 | 민팅 |
|------|----------|------|
| Portal TON 출금 → 자격 상실 | 가능→불가 | ✅ |
| 스테이킹 출금 → 자격 상실 | 가능→불가 | ✅ |
| 스테이킹 예금 → 자격 획득 | 불가→가능 | ✅ |
| Portal TON 입금 → 자격 획득 | 불가→가능 | ✅ |

**핵심**: 자격이 바뀌면 무조건 시뇨리지 정산 먼저 함

---

## 5. 함수 호출 경로

### 5.1 시뇨리지 분배 경로

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

### 5.2 자격 변경 경로

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

### 5.3 자격 상실 처리

```
_handleEligibilityLoss(layer2) [internal]
  └→ if (effectiveBridgedTON > 0)
       │  (effectiveBridgedTON > 0이면 allowed=true 보장됨)
       │
       ├→ rollupConfig 조회 (distributeL2Rewards에 필요)
       ├→ layer2Seigs 계산 (sequencer 보상)
       ├→ valReward 계산 (validator 보상)
       ├→ transferL2Seigniorage() (sequencer)
       ├→ distributeL2Rewards() (validator)
       ├→ totalEffectiveBridgedTON -= effectiveBridgedTON
       └→ info.effectiveBridgedTON = 0
```

**참고**: `allowed` 체크 불필요 - `effectiveBridgedTON > 0`이면 `allowed=true` 보장됨 (Case D 참조)

### 5.4 pause 중 claim (claimL2Seigniorage)

```
claimL2Seigniorage(layer2) [external]
  ├→ if (!v3Migrated) revert;
  ├→ if (!allowed || excluded) return (0, 0);
  ├→ if (!isEligible || effectiveBridgedTON == 0) return (0, 0);
  │
  ├→ layer2Seigs 계산 (sequencer 보상)
  ├→ valReward 계산 (validator 보상)
  ├→ transferL2Seigniorage() (sequencer)
  ├→ distributeL2Rewards() (validator)
  │
  └→ initialDebt, validatorInitialDebt 업데이트 (중복 claim 방지)
```

**claimL2Seigniorage vs _handleEligibilityLoss 비교**:

| | `claimL2Seigniorage` | `_handleEligibilityLoss` |
|---|---|---|
| **목적** | 단순 claim | 자격 상실 처리 |
| **pause 체크** | ❌ 없음 | ❌ 없음 |
| **claim** | ✅ | ✅ |
| **effectiveBridgedTON** | 유지 | 0으로 초기화 |
| **totalEffectiveBridgedTON** | 유지 | 차감 |
| **호출 시점** | 언제든 (external) | 자격 상실 시 (internal) |

### 5.5 자격 변경 전 시뇨리지 정산

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

## 6. 자격 변경 처리 원칙

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

---

## 7. 케이스별 동작

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
| `pause()` | V3: `_triggerSeigniorageDistribution()` 호출 (pause 블록까지 자동 발행) |
|           | V2: `require(_pausedBlock < _lastSeigBlock)` (수동 updateSeigniorage 필요) |
| `updateSeigniorage()` | early return (시뇨리지 분배 안 됨) |
| `claimL2Seigniorage()` | **claim 가능** ✓ (pause 체크 없음) |
| `onStakingChange()` | eligibility 업데이트 ✓ (일시정지 무시!) |
| `onBridgedTonChange()` | eligibility 업데이트 ✓ (일시정지 무시!) |
| 자격 상실 시 | `_handleEligibilityLoss()` → 미청구 보상 claim ✓ |

**V3 pause() 동작**:
- pause 블록까지 시뇨리지 자동 발행 (`_triggerSeigniorageDistribution`)
- `_lastSeigBlock = block.number`, `_pausedBlock = block.number + 1`
- pause 기간은 다음 블록부터 시작 (현재 블록은 시뇨리지 발행됨)
- pause 중 자격 변경 시 시뇨리지 손실 방지

**V3 claimL2Seigniorage() 동작**:
- pause 상태에서도 기존 발행분 claim 가능
- 시뇨리지 발행 없음 (rewardPerUnit 업데이트 없음)
- 자격 유지 (effectiveBridgedTON 변경 없음)

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

### Case D: allowed 상태 분석

**`allowed`의 의미**: `Layer2Manager.statusLayer2(rollupConfig) == 1` (L2 활성 상태)

| status | 의미 | allowed |
|--------|------|---------|
| 0 | 미등록 | ❌ false |
| 1 | 등록됨 (활성) | ✅ true |
| 2 | 일시정지 | ❌ false |

**`allowed=false + effectiveBridgedTON>0` 발생 불가능:**
- `status=2`가 되는 유일한 경로: `pauseCandidateAddOn()`
- 이 함수에서 `excludeFromL2Seigniorage()` → `effectiveBridgedTON=0` 먼저 설정
- 따라서 `_handleEligibilityLoss`에서 `allowed` 체크 불필요

---

## 8. 설계 결정 사항

| 케이스 | 현상 | 현재 동작 | 비고 |
|--------|------|----------|------|
| 전역 paused + 자격 변경 | eligibility 변경됨 | `_handleEligibilityLoss` 호출, claim됨 | ✅ 의도됨 |
| L2 paused + 자격 변경 | effectiveBridgedTON 이미 0 | 아무것도 안 함 | ✅ 안전 |
| allowed=false + 자격 상실 | - | 발생 불가능 | ✅ 설계상 보장 |

---

## 9. 현재 `_handleEligibilityLoss` 로직

```solidity
/// @dev 자격 상실 처리: 미청구 보상 자동 claim + effectiveBridgedTON 초기화
/// @param layer2 자격을 상실하는 L2 주소
/// @notice effectiveBridgedTON > 0이면 allowed=true 보장됨 (pauseCandidateAddOn에서 exclude 먼저 호출)
function _handleEligibilityLoss(address layer2) internal {
    BridgedTONInfo storage info = bridgedTONInfo[layer2];

    uint256 layer2Seigs = 0;
    uint256 valReward = 0;

    // 캐시: effectiveBridgedTON (여러 번 SLOAD → 1회)
    uint256 _effectiveBridged = info.effectiveBridgedTON;

    // effectiveBridgedTON > 0인 경우에만 처리 (이미 일시정지로 0인 경우 스킵)
    // allowed 체크 불필요:
    // - allowed=false가 되려면 Layer2Manager.statusLayer2() != 1 이어야 함
    // - status=2가 되는 유일한 경로: Layer2Manager.pauseCandidateAddOn()
    // - pauseCandidateAddOn()은 excludeFromL2Seigniorage()를 먼저 호출 → effectiveBridgedTON=0
    // - 따라서 effectiveBridgedTON > 0이면 status=1 (allowed=true) 보장됨
    if (_effectiveBridged > 0) {
        // rollupConfig 조회 (distributeL2Rewards에 필요)
        (address rollupConfig, ) = _allowIssuanceLayer2Seigs(layer2);

        // Sequencer 보상: bridgedTONRewardPerUint 기반
        layer2Seigs = (bridgedTONRewardPerUint * _effectiveBridged) / WEI_UNIT - info.initialDebt;

        // Validator 보상: validatorRewardPerUint 기반
        valReward = (validatorRewardPerUint * _effectiveBridged) / WEI_UNIT - info.validatorInitialDebt;

        // Sequencer 보상 transfer
        if (layer2Seigs > 0) {
            ILayer2Manager(layer2Manager).transferL2Seigniorage(layer2, layer2Seigs);
        }

        // Validator 보상 분배
        if (valReward > 0 && validatorReward != address(0)) {
            IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
        }

        // effectiveBridgedTON 초기화
        totalEffectiveBridgedTON -= _effectiveBridged;
        info.effectiveBridgedTON = 0;
    }

    emit AutoClaimBeforeEligibilityLoss(layer2, layer2Seigs, valReward);
}
```

---

## 10. 설계 근거

### 10.1 일시정지 상태에서 자격 변경 허용 이유

- 일시정지는 **새로운 시뇨리지 분배 중단**을 의미
- 기존 미청구 보상의 claim은 차단하지 않음
- 자격 변경(eligibility)은 상태 관리이므로 일시정지와 무관

### 10.2 L2별 일시정지가 안전한 이유

- `excludeFromL2Seigniorage` 호출 시 `effectiveBridgedTON = 0`으로 설정
- 따라서 `_handleEligibilityLoss`에서 `if (info.effectiveBridgedTON > 0)` 조건이 false
- 추가 처리 불필요

### 10.3 allowed=false + effectiveBridgedTON>0 케이스

**이 케이스는 발생 불가능:**
- `allowed=false`가 되려면 `Layer2Manager.statusLayer2() != 1`
- `status=2`가 되는 유일한 경로: `pauseCandidateAddOn()`
- `pauseCandidateAddOn()`은 `excludeFromL2Seigniorage()` 먼저 호출 → `effectiveBridgedTON=0`
- 따라서 `effectiveBridgedTON > 0`이면 `allowed=true` 보장됨
- `_handleEligibilityLoss`에서 `allowed` 체크 불필요 (코드 최적화됨)

### 10.4 자격 변경 시 시뇨리지 정산 이유

자격이 변경될 때 (`_updateEligibilityInternal`에서) `_triggerSeigniorageDistribution()`을 **먼저** 호출하는 이유:

#### 자격 상실 시:
1. **rewardPerUnit 최신화**: `lastSeigBlock` ~ 현재 블록까지의 시뇨리지 분배
2. **정확한 미청구 보상 계산**: `_handleEligibilityLoss`에서 최신 rewardPerUnit 기반으로 claim
3. **시뇨리지 손실 방지**: `updateSeigniorage` 없이 바로 `onStakingChange` 호출해도 보상 누락 없음

#### 자격 획득 시:
1. **공정성 보장**: 기존 L2들이 지금까지 축적한 시뇨리지를 먼저 정산
2. **rewardPerUnit 업데이트**: 새 L2의 initialDebt는 최신 rewardPerUnit 기준으로 설정
3. **중복 분배 방지**: 같은 블록에서 여러 L2가 자격 획득해도 시뇨리지는 한 번만 분배

---

## 11. V3 시뇨리지 흐름 다이어그램

```
updateSeigniorage() 호출
│
├─ block.number > _lastSeigBlock? NO → _claimL2RewardsOnly() (같은 블록 재분배)
│
└─ YES → _increaseTotV3()
   │
   ├─ span = block.number - _lastSeigBlock (일시정지 구간 제외)
   ├─ A = span * _seigPerBlock (전체 시뇨리지)
   ├─ _lastSeigBlock = block.number (업데이트)
   │
   └─ _distributeV3Seigniorage(A)
      │
      ├─ sDao = A * daoDistributionRatio / RAY_UNIT
      ├─ L = A - sDao
      │
      ├─ IF totalEffectiveBridgedTON > 0:
      │  │
      │  ├─ y = L * x / (k + x)  // 쌍곡선 포화
      │  │
      │  ├─ totalSeqReward = y * (RAY_UNIT - α) / RAY_UNIT
      │  ├─ totalValReward = y * α / RAY_UNIT
      │  │
      │  ├─ MINT: Sequencer → layer2Manager (totalSeqReward)
      │  ├─ MINT: Validator → validatorReward (totalValReward)
      │  │
      │  ├─ UPDATE: bridgedTONRewardPerUint += totalSeqReward * WEI_UNIT / x
      │  ├─ UPDATE: validatorRewardPerUint += totalValReward * WEI_UNIT / x
      │  │
      │  └─ _claimL2Rewards() (호출 L2의 보상 청구)
      │     │
      │     ├─ _syncEffectiveBridgedTon(layer2)
      │     ├─ layer2Seigs = bridgedTONRewardPerUint * effectiveBridgedTON / WEI_UNIT - initialDebt
      │     ├─ valReward = validatorRewardPerUint * effectiveBridgedTON / WEI_UNIT - validatorInitialDebt
      │     │
      │     ├─ TRANSFER: layer2Manager → layer2 (layer2Seigs)
      │     ├─ DISTRIBUTE: validatorReward.distributeL2Rewards (valReward)
      │     │
      │     └─ UPDATE: initialDebt, validatorInitialDebt (다음 클레임 방지)
      │
      └─ _mintDaoReward (sDao + (L - y))

자격 변경 시
│
└─ _updateEligibilityInternal(layer2)
   │
   ├─ currentBridgedTON = bridgedTon * GWEI_UNIT (L1 브리지에서 조회)
   ├─ newEligible = checkCurrentEligibility(layer2)
   │
   ├─ IF oldEligible == newEligible → RETURN (아무것도 안 함)
   │
   └─ ELSE (자격 변경)
      │
      ├─ _triggerSeigniorageDistribution() (먼저 분배)
      │  │
      │  └─ rewardPerUnit 업데이트 + WTON mint (claim 없음)
      │
      ├─ IF oldEligible && !newEligible (자격 상실)
      │  │
      │  └─ _handleEligibilityLoss(layer2)
      │     │
      │     ├─ 미청구 보상 자동 claim
      │     ├─ effectiveBridgedTON = 0
      │     └─ totalEffectiveBridgedTON -= old
      │
      └─ ELSE (자격 획득)
         │
         ├─ effectiveBridgedTON = currentBridgedTON
         ├─ totalEffectiveBridgedTON += new
         ├─ initialDebt = bridgedTONRewardPerUint * effectiveBridgedTON / WEI_UNIT
         └─ validatorInitialDebt = validatorRewardPerUint * effectiveBridgedTON / WEI_UNIT
```

---

## 12. 주요 공식 정리

### 12.1 시뇨리지 분배 (V3)

```
A₂ = span × seigPerBlock                    // 기간 시뇨리지

S_DAO = d × A₂                              // DAO 고정분
L = (1 - d) × A₂                            // L2 분배 가능량

y(x) = L × x / (k + x)                      // 쌍곡선 포화 (x = totalEffectiveBridgedTON)

Seig_i = y(x) × (B̃_i / x)                  // 개별 L2 시뇨리지

o_i = (1 - α) × Seig_i                      // 시퀀서 보상
v_i = α × Seig_i                            // 검증자 보상
```

### 12.2 자격 조건 (V3)

```
currentStake = coinage.balanceOf(operator)  // 시퀀서 담보금

minForSeigniorage = bridgedTON × GWEI_UNIT × θ / RAY_UNIT
minForFraudProof = hMax × cMax + Δ_sequencer

requiredStake = max(minForSeigniorage, minForFraudProof)

eligible = (currentStake ≥ requiredStake) && (bridgedTON > 0)
```

### 12.3 클레임 계산 (Debt 공식)

```
accSeq = bridgedTONRewardPerUint × B̃_i / WEI_UNIT - initialDebt
accVal = validatorRewardPerUint × B̃_i / WEI_UNIT - validatorInitialDebt
```

---

## 13. 관련 테스트

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

## 14. 관련 코드 위치

| 함수 | 파일 | 라인 |
|------|------|------|
| `pause()` | SeigManagerV3_1.sol | 212 |
| `unpause()` | SeigManagerV3_1.sol | 229 |
| `excludeFromL2Seigniorage()` | SeigManagerV3_1.sol | 239 |
| `includeFromL2Seigniorage()` | SeigManagerV3_1.sol | 246 |
| `claimL2Seigniorage()` | SeigManagerV3_1.sol | 259 |
| `onBridgedTonChange()` | SeigManagerV3_1.sol | 306 |
| `onStakingChange()` | SeigManagerV3_1.sol | 320 |
| `_updateEligibilityInternal()` | SeigManagerV3_1.sol | 325 |
| `checkCurrentEligibility()` | SeigManagerV3_1.sol | 385 |
| `updateSeigniorage()` | SeigManagerV3_1.sol | 591 |
| `_updateSeigniorageV3()` | SeigManagerV3_1.sol | 644 |
| `_claimL2RewardsOnly()` | SeigManagerV3_1.sol | 665 |
| `_increaseTotV3()` | SeigManagerV3_1.sol | 671 |
| `_distributeV3Seigniorage()` | SeigManagerV3_1.sol | 698 |
| `_claimL2Rewards()` | SeigManagerV3_1.sol | 740 |
| `_handleEligibilityLoss()` | SeigManagerV3_1.sol | 782 |
| `_triggerSeigniorageDistribution()` | SeigManagerV3_1.sol | 827 |
| `_mintDaoReward()` | SeigManagerV3_1.sol | 880 |
| `_syncEffectiveBridgedTon()` | SeigManagerV3_1.sol | 887 |
| `updateSeigniorageV2()` (V2) | SeigManagerV3_2.sol | 85 |
| `_increaseTot()` (V2) | SeigManagerV3_2.sol | 153 |

---

## 15. V2 vs V3 비교

| 항목 | V2 | V3 |
|------|----|----|
| 분배 기준 | `layer2Tvl` (L1BridgeRegistry) | `effectiveBridgedTON` (자격 기반) |
| 보상 분리 | 없음 (단일 `l2RewardPerUint`) | Sequencer/Validator 분리 |
| 자격 조건 | 없음 | `currentStake >= requiredStake` && `bridgedTON > 0` |
| 스테이커 시뇨리지 | 있음 (coinage factor 증가) | 없음 |
| DAO 분배 | `daoSeigRate` (unstakedSeig 기반) | `daoDistributionRatio` (전체 A₂ 기반) |
| 쌍곡선 포화 | 없음 | `y(x) = L × x / (k + x)` |
