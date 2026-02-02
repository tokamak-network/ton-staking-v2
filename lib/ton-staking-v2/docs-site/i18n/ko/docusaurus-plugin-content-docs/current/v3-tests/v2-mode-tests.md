---
id: v2-mode-tests
title: V2 모드 테스트
sidebar_position: 2
---

# V2 모드 테스트 (44개)

V2 모드에서의 기본 기능 및 V2↔V3 모드 전환 테스트를 포함합니다.

## V2Functions.t.sol (16개)

### 시뇨리지 분배 테스트

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-001 | test_SM001_v2_updateSeigniorage_linearDistribution | V2 선형 분배: 블록 수 2배 → 시뇨리지 2배 |
| SM-002 | test_SM002_v2_updateSeigniorage_coinageStakingSeigniorage | Operator/Staker coinage factor 증가로 잔액 자동 증가 |
| SM-003 | test_SM003_v2_updateSeigniorage_layer2SequencerSeigniorage | OperatorManager로 WTON 직접 전송 확인 |
| SM-004 | test_SM004_v2_updateSeigniorage_ignoresV3Parameters | V3 파라미터(θ,α,k,d) 설정해도 V2 분배에 영향 없음 |
| SM-010 | test_SM010_v2_seigniorage_onlyMinimumAmount | minimumAmount만 충족하면 시뇨리지 분배 |
| SM-011 | test_SM011_v2_seigniorage_ignoresMinStakingRatio | θ(minStakingRatio) 무시 확인 |
| SM-012 | test_SM012_v2_seigniorage_noEffectiveBridgedTON | effectiveBridgedTON 미사용 (V3 전용) |

### V2 조회 함수 테스트

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-020-V2 | test_SM020_v2_estimatedDistributeV2 | V2 예상 시뇨리지 분배량 조회 |
| SM-021-V2 | test_SM021_v2_claimableL2SeigniorageV2 | V2 청구 가능 시뇨리지 조회 |
| SM-022-V2 | test_SM022_v2_estimatedDistributeV2_unregisteredLayer2 | 미등록 Layer2 → layer2Seigs=0 |
| SM-023-V2 | test_SM023_v2_estimatedDistributeV2_blockCondition | lastSeigBlock 이하 → 0 반환 |
| SM-024-V2 | test_SM024_v2_negativeCommissionRate_concept | 음수 커미션율 개념 테스트 |

### V2 예치/출금 테스트

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| DM-001 | test_DM001_v2_deposit_basicFlow | V2 기본 예치 동작 |
| DM-002 | test_DM002_v2_deposit_noV3Callback | V2에서 onStakingChange 콜백 미호출 |
| DM-003 | test_DM003_v2_withdraw_basicFlow | V2 기본 출금 동작 |
| DM-004 | test_DM004_v2_withdraw_operatorVsValidator | Operator: minimumAmount 제한 / Validator: 제한 없음 |

---

## V2V3ModeSwitching.t.sol (28개)

### V2 모드 함수 호출 테스트

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-020 | test_SM020_v2_hyperbolicSaturation_notUsed | V2에서 쌍곡선 함수 호출 가능하나 분배에 미사용 |
| SM-021 | test_SM021_v2_onBridgedTonChange_succeeds | V2에서 호출 시 early return (revert 안 함) |
| SM-022 | test_SM022_v2_transferCoinageToRat_revertInV2 | V2에서 RAT 전송 함수 revert |
| RAT-V2-001 | test_RAT_v2_registerValidator_revertInV2 | V2에서 검증자 등록 시 NotMigratedError |
| SM-023 | test_SM023_v2_onStakingChange_succeeds | V2에서 호출 시 early return (revert 안 함) |

### V2/V3 ValidatorReward 분배 차이

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-024-V2 | test_SM024_v2_validatorReward_shouldNotDistribute | V2에서 ValidatorReward 분배 없음 |
| SM-024-V3-NoVal | test_SM024_v3_noValidators_goesToDAO | V3 검증자 0명: ValidatorReward → DAO 전송 |
| SM-024-V3-WithVal | test_SM024_v3_withValidators_staysInValidatorReward | V3 검증자 1명+: ValidatorReward에 시뇨리지 잔류 |

### V2 모드 파라미터/컨트랙트 설정

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-025 | test_SM025_v2_canSetV3Parameters | V2에서 V3 파라미터 설정 가능 (분배에는 무영향) |
| SM-026 | test_SM026_v2_canSetV3Contracts | V2에서 V3 컨트랙트 설정 가능 (사용되지 않음) |
| SM-027 | test_SM027_v2_checkCurrentEligibility_returnsZero | V2에서 checkCurrentEligibility는 항상 false, 0 |
| SM-028 | test_SM028_v2_getEffectiveBridgedTon_returnsZero | V2에서 effectiveBridgedTON은 항상 0 |

### V2 모드 exclude/include 함수

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-033 | test_SM033_v2_excludeFromL2Seigniorage_shouldRevertOrIgnore | V2에서 excludeFromL2Seigniorage 호출 가능 (효과 없음) |
| SM-034 | test_SM034_v2_includeFromL2Seigniorage_shouldRevertOrIgnore | V2에서 includeFromL2Seigniorage 호출 시 revert |
| SM-035 | test_SM035_afterMigration_pause_shouldWork | V2→V3 마이그레이션 후 pause/unpause 정상 동작 |
| SM-036 | test_SM036_afterMigration_excludeFromL2Seigniorage_shouldWork | V2→V3 마이그레이션 후 excludeFromL2Seigniorage 정상 동작 |
| SM-037 | test_SM037_afterMigration_includeFromL2Seigniorage_shouldWork | V2→V3 마이그레이션 후 includeFromL2Seigniorage 정상 동작 |
| SM-038 | test_SM038_v2_excludeThenInclude_shouldWork | V2 모드 exclude→include 전체 흐름 (시뇨리지 전/후 검증) |
| SM-039 | test_SM039_v2ExcludeThenMigrateThenV3Include_shouldWork | V2 exclude → V3 마이그레이션 → V3 include 전환 |

### 마이그레이션 테스트

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| MIG-001 | test_MIG001_migration_stateChange | 마이그레이션 전후 v3Migrated 상태 변화 |
| MIG-002 | test_MIG002_migration_duplicateReverts | 중복 마이그레이션 시 AlreadyMigratedError |
| MIG-003-Type3 | test_MIG003_type3_getEffectiveBridgedTon_shouldUpdate | Type 3: Portal 호출로 effectiveBridgedTON 업데이트, eligible=true |
| MIG-003-Type2 | test_MIG003_type2_getEffectiveBridgedTon_shouldUpdate | Type 2: onBridgedTonChange 미지원, eligible=false, requiredStake=0 |
| MIG-004-Type3 | test_MIG004_type3_afterMigration_v3Functions_shouldActivate | Type 3: V3 마이그레이션 후 checkCurrentEligibility eligible=true |
| MIG-004-Type2 | test_MIG004_type2_afterMigration_v3Functions_shouldActivate | Type 2: V3 마이그레이션 후 checkCurrentEligibility eligible=false |
| MIG-005-Type3 | test_MIG005_type3_afterMigration_onStakingChange_shouldWork | Type 3: deposit으로 currentStake 증가 시 eligible false→true 변경 |
| MIG-005-Type2 | test_MIG005_type2_afterMigration_onStakingChange_shouldWork | Type 2: deposit으로 currentStake 증가해도 eligible=false 유지 |
| MIG-006 | test_MIG006_v3ToV2_downgradeNotPossible | V3→V2 다운그레이드 불가 (영구적 V3 모드) |

---

## 다음 단계

- [V3 모드 테스트](v3-mode-tests.md) - V3 모드 전용 기능 테스트
- [시나리오 테스트](scenario-tests.md) - 전체 워크플로우 테스트
- [테스트 개요로 돌아가기](overview.md)
