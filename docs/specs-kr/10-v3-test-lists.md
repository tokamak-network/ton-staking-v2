# TON Staking V3 테스트 목록

> **최종 업데이트**: 2026-01-23

---

## 테스트 ID 네이밍 규칙

| Prefix | 대상 컨트랙트/기능 | 설명 |
|--------|-------------------|------|
| SM | SeigManager | 시뇨리지 매니저 관련 테스트 |
| DM | DepositManager | 예치/출금 매니저 관련 테스트 |
| LBR | L1BridgeRegistry | L1 브릿지 레지스트리 관련 테스트 |
| L2M | Layer2Manager | Layer2 매니저 관련 테스트 |
| RAT | RAT (Random Attention Test) | 검증자 어텐션 테스트 관련 |
| VR | ValidatorReward | 검증자 보상 컨트랙트 관련 테스트 |
| MIG | Migration | V2→V3 마이그레이션 관련 테스트 |
| INT | Integration | 컨트랙트 간 통합 테스트 |
| SEC | Security | 보안/권한 관련 테스트 |
| SD | Seigniorage Distribution | 시뇨리지 분배 공식 검증 |
| INV | Invariant | 불변성 테스트 |
| E2E | End-to-End | 전체 시나리오 테스트 |
| EDGE | Edge Case | 경계값/엣지 케이스 테스트 |
| SCENSEQ | Scenario Sequencer | 시퀀서 시나리오 테스트 |
| SCENVAL | Scenario Validator | 검증자 시나리오 테스트 |

**Suffix 규칙:**
- `-V2` / `-V3`: V2/V3 모드 구분
- `-Type2` / `-Type3`: rollupType 2/3 구분
- 숫자: 순차적 테스트 번호 (예: SM-001, SM-002)

---

## v2mode/ (33개)

### V2Functions.t.sol (11개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-001 | test_SM001_v2_updateSeigniorage_linearDistribution | V2 선형 분배: 블록 수 2배 → 시뇨리지 2배 |
| SM-002 | test_SM002_v2_updateSeigniorage_coinageStakingSeigniorage | Operator/Staker coinage factor 증가로 잔액 자동 증가 |
| SM-003 | test_SM003_v2_updateSeigniorage_layer2SequencerSeigniorage | OperatorManager로 WTON 직접 전송 확인 |
| SM-004 | test_SM004_v2_updateSeigniorage_ignoresV3Parameters | V3 파라미터(θ,α,k,d) 설정해도 V2 분배에 영향 없음 |
| SM-010 | test_SM010_v2_seigniorage_onlyMinimumAmount | minimumAmount만 충족하면 시뇨리지 분배 |
| SM-011 | test_SM011_v2_seigniorage_ignoresMinStakingRatio | θ(minStakingRatio) 무시 확인 |
| SM-012 | test_SM012_v2_seigniorage_noEffectiveBridgedTON | effectiveBridgedTON 미사용 (V3 전용) |
| DM-001 | test_DM001_v2_deposit_basicFlow | V2 기본 예치 동작 |
| DM-002 | test_DM002_v2_deposit_noV3Callback | V2에서 onStakingChange 콜백 미호출 |
| DM-003 | test_DM003_v2_withdraw_basicFlow | V2 기본 출금 동작 |
| DM-004 | test_DM004_v2_withdraw_operatorVsValidator | Operator: minimumAmount 제한 / Validator: 제한 없음 |

### V2V3ModeSwitching.t.sol (22개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-020 | test_SM020_v2_hyperbolicSaturation_notUsed | V2에서 쌍곡선 함수 호출 가능하나 분배에 미사용 |
| SM-021 | test_SM021_v2_onBridgedTonChange_succeeds | V2에서 호출 시 early return (revert 안 함) |
| SM-022 | test_SM022_v2_transferCoinageToRat_revertInV2 | V2에서 RAT 전송 함수 revert |
| RAT-V2-001 | test_RAT_v2_registerValidator_revertInV2 | V2에서 검증자 등록 시 NotMigratedError |
| SM-023 | test_SM023_v2_onStakingChange_succeeds | V2에서 호출 시 early return (revert 안 함) |
| SM-024-V2 | test_SM024_v2_validatorReward_shouldNotDistribute | V2에서 ValidatorReward 분배 없음 |
| SM-024-V3-NoVal | test_SM024_v3_noValidators_goesToDAO | V3 검증자 0명: ValidatorReward → DAO 전송 |
| SM-024-V3-WithVal | test_SM024_v3_withValidators_staysInValidatorReward | V3 검증자 1명+: ValidatorReward에 시뇨리지 잔류 |
| SM-025 | test_SM025_v2_canSetV3Parameters | V2에서 V3 파라미터 설정 가능 (분배에는 무영향) |
| SM-026 | test_SM026_v2_canSetV3Contracts | V2에서 V3 컨트랙트 설정 가능 (사용되지 않음) |
| SM-027 | test_SM027_v2_checkCurrentEligibility_returnsZero | V2에서 checkCurrentEligibility는 항상 false, 0 |
| SM-028 | test_SM028_v2_getEffectiveBridgedTon_returnsZero | V2에서 effectiveBridgedTON은 항상 0 |
| SM-029 | test_SM029_v2_seigniorage_linearAccumulation | V2 시뇨리지 연속 누적의 가법성 검증 |
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

## v3mode/

### SeigManagerV1_4Real.t.sol (43개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-001 | test_SM001_hyperbolicSaturation_zero | x=0일 때 y=0 |
| SM-002 | test_SM002_hyperbolicSaturation_halfPoint | x=k일 때 y=L/2 |
| SM-003 | test_SM003_hyperbolicSaturation_large | x→∞일 때 y→L |
| SM-004 | test_SM004_hyperbolicSaturation_monotonic | x 증가 시 y 단조 증가 |
| SM-005 | testFuzz_SM005_hyperbolicSaturation_bounded | Fuzz: 임의 x,L에서 y≤L |
| SM-006 | test_SM006_v3Parameters | V3 파라미터 설정 및 조회 |
| SM-007 | test_SM007_v3MigrationState | 마이그레이션 전후 v3Migrated 상태 |
| SM-008 | test_SM008_slashingParameters | maxChallengers, maxFraudProofCost 설정 |
| SM-010 | test_SM010_calculateSequencerReward_basic | 시퀀서 보상 = (1-α) × seig |
| SM-011 | test_SM011_calculateSequencerReward_zeroAlpha | α=0일 때 시퀀서가 100% |
| SM-012 | testFuzz_SM012_calculateSequencerReward | Fuzz: 시퀀서 보상 계산 |
| SM-013 | test_SM013_setStakedSeigFactor_basic | λ(stakedSeigFactor) 설정 |
| SM-014 | test_SM014_setStakedSeigFactor_exceedsRAY_reverts | λ>1 설정 시 revert |
| SM-015 | test_SM015_setMaxChallengers_basic | maxChallengers 설정 |
| SM-016 | test_SM016_setMaxFraudProofCost_basic | maxFraudProofCost 설정 |
| SM-017 | test_SM017_setValidatorReward_basic | ValidatorReward 주소 설정 |
| SM-018 | test_SM018_setValidatorReward_zeroAddress_reverts | 0 주소 설정 시 revert |
| SM-019 | test_SM019_setStakedSeigFactor_notOwner_reverts | 비소유자 설정 시 revert |
| SM-020 | test_SM020_checkCurrentEligibility_qualified | 자격 충족 케이스: T_i ≥ max(θ×B_i, D_seq) |
| SM-021 | test_SM021_checkCurrentEligibility_unqualified | 자격 미달 케이스: T_i < required |
| SM-022 | test_SM022_DSequencer_calculation | D_seq = H_max × C_max + Δ_seq |
| SM-022 | test_SM022_DSequencer_allZero | D_seq 모든 파라미터 0일 때 |
| SM-022 | test_SM022_DSequencer_largeValues | D_seq 대량 값 테스트 |
| SM-022 | testFuzz_SM022_DSequencer | Fuzz: D_seq 계산 |
| SM-023 | test_SM023_thetaBi_calculation | θ×B_i 기본 계산 (TON→WTON 단위 변환) |
| SM-023 | test_SM023_thetaBi_unitConversion | θ=1일 때 1:1 변환 확인 |
| SM-023 | test_SM023_thetaBi_zeroTheta | θ=0일 때 θ×B_i=0 |
| SM-023 | test_SM023_thetaBi_zeroBridgedTON | B_i=0일 때 θ×B_i=0 |
| SM-023 | testFuzz_SM023_thetaBi | Fuzz: θ×B_i 계산 |
| SM-024 | test_SM024_setMaxChallengers_notOwner_reverts | 비소유자 설정 시 revert |
| SM-025 | test_SM025_setMaxFraudProofCost_notOwner_reverts | 비소유자 설정 시 revert |
| SM-030 | test_SM030_deployedContractsConnected | 배포된 컨트랙트 연결 확인 |
| SM-031 | test_SM031_validatorRewardConnected | ValidatorReward 연결 확인 |
| INT-012 | test_INT012_requiredStake_DSequencerDominant | max() 공식: D_seq > θ×B_i |
| INT-012 | test_INT012_requiredStake_ThetaBiDominant | max() 공식: θ×B_i > D_seq |
| INT-012 | test_INT012_requiredStake_bothZero | max() 공식: 둘 다 0 |
| INT-012 | test_INT012_requiredStake_equal | max() 공식: 같을 때 |
| INT-012 | testFuzz_INT012_requiredStake | Fuzz: max(θ×B_i, D_seq) |
| INT-030 | test_INT030_onBridgedTONChange_callerValidation | 미등록 portal 호출 시 revert |
| INT-030 | test_INT030_onBridgedTONChange_beforeMigration_reverts | V3 마이그레이션 전 호출 시 revert |
| INT-031 | test_INT031_effectiveBridgedTON_update | effectiveBridgedTON 업데이트 확인 |
| INT-032 | test_INT032_totalEffectiveBridgedTON_sync | 전체 합계 동기화 확인 |
| INT-031/032 | test_INT031_032_eligibilityLoss_removesEffective | 자격 상실 시 effectiveBridgedTON=0 |

### DepositManagerV1_2Real.t.sol (14개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| DM-001 | test_DM001_deployedContractsConnected | 컨트랙트 배포 및 연결 확인 |
| DM-002 | test_DM002_depositManager_initialized | 초기화 상태 확인 |
| DM-003 | test_DM003_deposit_zeroAmount_reverts | 0 금액 예치 시 revert |
| DM-004 | test_DM004_setGlobalWithdrawalDelay | 전역 출금 지연 설정 |
| DM-005 | test_DM005_setGlobalWithdrawalDelay_notOwner_reverts | 비소유자 설정 시 revert |
| DM-006 | test_DM006_getDelayBlocks_globalDelay | 전역 지연 블록 조회 |
| DM-010 | test_DM010_requestWithdrawal_zeroAmount_reverts | 0 금액 출금 요청 시 revert |
| DM-011 | testFuzz_DM011_setGlobalWithdrawalDelay | Fuzz: 전역 출금 지연 |
| DM-012 | test_DM012_getDelayBlocks_layer2Delay | Layer2별 지연 블록 조회 |
| DM-013 | test_DM013_getDelayBlocks_withLayer2Delay | Layer2 지연 있을 때 조회 |
| DM-014 | test_DM014_setWithdrawalDelayByOwner_lessThanGlobal_reverts | 전역보다 작은 지연 설정 시 revert |
| INT-015 | test_INT015_onDeposit_mintCoinage | 예치 시 coinage 민팅 |
| INT-016 | test_INT016_onWithdraw_burnCoinage | 출금 시 coinage 소각 |
| INT-015/016 | test_INT015_016_onlyDepositManager_reverts | DepositManager만 호출 가능 |

### Layer2ManagerV1_2Real.t.sol (5개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| L2M-001 | test_L2M001_deployedContractsConnected | 컨트랙트 배포 확인 |
| L2M-002 | test_L2M002_layer2Manager_initialized | 초기화 상태 확인 |
| L2M-003 | test_L2M003_getBridgedTON_unregisteredRollup | 미등록 rollup → 0 반환 |
| L2M-004 | test_L2M004_getBridgedTONByLayer_noOperator | operator 없는 layer2 → 0 반환 |
| L2M-005 | test_L2M005_getLayer2BySystemConfig_unregistered | 미등록 systemConfig → address(0) |

### L1BridgeRegistryV1_2Real.t.sol (46개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| LBR-001~008 | 초기화 테스트 | 배포, 역할, 기본값 확인 |
| LBR-010~012 | TYPE 1 등록 | Manager/Registrant 등록, 권한 없는 자 revert |
| LBR-020~022 | TYPE 2 등록 | Manager 등록, 0 L2TON revert, 중복 등록 revert |
| LBR-030~032 | TYPE 3 등록 | Manager 등록, DisputeGameFactory 없으면 revert |
| LBR-040~045 | TypeRegistrant | 설정, 권한 검증, 타입별 등록 |
| LBR-050~055 | upgradeToType3 | TYPE 2→3, TYPE 1→3, 이미 TYPE 3 revert |
| LBR-060~062 | reject/restore | CandidateAddOn 거부/복원 |
| LBR-070~074 | availableForRegistration | 타입별 등록 가능 여부 |
| LBR-080~092 | 기타 | rollupInfo, 이벤트 검증 |

### RAT.t.sol (31개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| RAT-001 | test_RAT001_registerValidator_success | 검증자 등록 성공 |
| RAT-002 | test_RAT002_registerValidator_insufficientDeposit | 담보금 부족 시 revert |
| RAT-003 | test_RAT003_registerValidator_alreadyRegistered | 이미 등록된 검증자 revert |
| RAT-004 | test_RAT004_deactivateValidator | 검증자 비활성화 |
| RAT-006 | test_RAT006_registerMultipleValidators | 다중 검증자 등록 |
| RAT-007 | test_RAT007_maxValidators_exceeded_reverts | N_max 초과 시 revert |
| RAT-010 | test_RAT010_getDynamicMinimumCollateral | 동적 최소 담보금 계산 |
| RAT-011 | test_RAT011_getDynamicCoff_withFormula | C_off 계산 공식 검증 |
| RAT-012~014 | relaxedCheck, attentionCost | 완화된 검사, 어텐션 비용 |
| RAT-020 | test_RAT020_triggerAttentionTest | RAT 트리거 성공 |
| RAT-021 | test_RAT021_probabilisticTrigger | 확률적 트리거 검증 |
| RAT-022 | test_RAT022_triggerAttentionTest_noValidators | 검증자 없을 때 트리거 |
| RAT-024 | test_RAT024_triggerAttentionTest_partialBond | 부분 담보금 트리거 |
| RAT-025 | test_RAT025_relaxedValidatorCheck_* | 완화/엄격 모드 검증자 제거 |
| RAT-026 | test_RAT026_triggerAttentionTest_zeroCollateral | 담보금 0일 때 트리거 |
| RAT-030 | test_RAT030_submitEvidence | 증거 제출 성공 |
| RAT-031 | test_RAT031_submitEvidence_afterDeadline_reverts | 마감 후 증거 제출 revert |
| RAT-032 | test_RAT032_submitEvidence_notSelected_reverts | 선정 안 된 검증자 증거 제출 revert |
| RAT-033 | test_RAT033_resolveClaim_duringChallengePeriod | 챌린지 기간 중 클레임 해결 |
| RAT-034 | test_RAT034_resolveClaim_afterChallengePeriod_fails | 챌린지 기간 후 클레임 실패 |
| RAT-035~036 | 재활성화 | 증거 제출 후 재활성화, 담보금 부족 시 비재활성화 |
| RAT-040~043 | getAttentionTestStatus | 증거기간/챌린지기간/슬래시/복원 상태 |
| RAT-050 | test_RAT050_withdrawSlashingsToTreasury | 슬래싱 금액 Treasury 출금 |
| RAT-052 | test_RAT052_treasury_zeroAddress_reverts | Treasury 0 주소 revert |
| EDGE-010 | test_EDGE010_duplicateTrigger_sameBatch_reverts | 동일 배치 중복 트리거 revert |
| EDGE-022 | test_EDGE022_withdrawExceedsBalance_reverts | 잔액 초과 출금 revert |
| E2E-014 | test_E2E014_multipleL2_sameValidator | 동일 검증자 다중 L2 |

### RATSeigManagerIntegration.t.sol (11개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| INT-020 | test_INT020_coinagePreDeduction | RAT 트리거 전 coinage 차감 |
| INT-021 | test_INT021_coinageRestoration | 증거 제출 후 coinage 복원 |
| INT-021 | test_INT021_coinageRestorationByChallenge | 챌린지 후 coinage 복원 |
| INT-022 | test_INT022_coinageSlashing | 슬래싱 시 coinage 소각 |
| INT-023 | test_INT023_balanceSynchronization | RAT-SeigManager 잔액 동기화 |
| SM-040 | test_SM040_transferCoinageToRAT | SeigManager→RAT coinage 전송 |
| SM-041 | test_SM041_transferCoinageFromRAT | RAT→SeigManager coinage 반환 |
| SM-042 | test_SM042_transferCoinageFromRATTo | RAT→특정주소 coinage 전송 |
| SM-043 | test_SM043_onlyRAT_revert | RAT만 호출 가능 함수 |
| INT-024 | test_INT024_multipleRATTriggers_balanceConsistency | 다중 트리거 잔액 일관성 |
| INT-025 | test_INT025_insufficientCollateral_RATTrigger | 담보금 부족 시 트리거 동작 |

### ValidatorRewardV1.t.sol (33개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| VR-001 | test_VR001_distributeL2Rewards_basic | 기본 L2 보상 분배 |
| VR-002 | test_VR002_distributeL2Rewards_noValidators_toDAO | 검증자 없으면 DAO로 전송 |
| VR-003 | test_VR003_distributeL2Rewards_multipleValidators | 다중 검증자 균등 분배: v_j = (α·S_i) / \|V_i\| |
| VR-004 | test_VR004_claimAllRewards_success | 보상 청구 성공 |
| VR-005 | test_VR005_initialize_success | 초기화 성공 |
| VR-006 | test_VR006_initialize_cannotReinitialize | 재초기화 불가 |
| VR-007 | test_VR007_distributeL2Rewards_excludeInactiveValidators | 비활성 검증자 제외 |
| VR-008 | test_VR008_distributeL2Rewards_multipleL2s | 여러 L2에서 보상 분배 |
| VR-009 | test_VR009_distributeL2Rewards_zeroAmount | 0 금액 분배 시 무시 |
| VR-010 | test_VR010_distributeL2Rewards_onlySeigManager | SeigManager만 호출 가능 |
| VR-011 | test_VR011_distributeL2Rewards_accumulation | 보상 누적 |
| VR-012 | test_VR012_distributeL2Rewards_remainder | 나머지 처리 (버림) |
| VR-013 | test_VR013_claimAllRewards_noRewards_reverts | 보상 없으면 revert |
| VR-014 | test_VR014_claimAllRewards_multipleL2s | 여러 L2 보상 한번에 청구 |
| VR-015 | test_VR015_claimAllRewards_claimDistributeClaim | 청구→분배→재청구 |
| VR-016 | test_VR016_getPendingRewards_accurate | 미청구 보상 조회 정확성 |
| VR-017 | test_VR017_getPendingRewardsByL2_accurate | L2별 미청구 보상 조회 |
| VR-018 | test_VR018_rewardCalculation_formula | 공식 검증: amount / activeCount |
| VR-019 | test_VR019_rewardCalculation_precision | 작은 금액 정밀도 |
| VR-020~027 | 거버넌스 | RAT/SeigManager/Treasury 설정, 소유권 이전 |
| VR-028~029 | 비상 | 비상 출금, 비소유자 revert |
| VR-030~033 | 이벤트 | L2RewardDistributed, ValidatorRewardReceived, RewardsClaimed, RewardToDAO |

### ValidatorWithdrawalRestriction.t.sol (12개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| INT-013 | test_INT013_validatorWithdrawal_aboveMinimum_success | 최소 담보금 이상 출금 성공 |
| INT-013 | test_INT013_validatorWithdrawal_belowMinimum_reverts | 최소 담보금 미만 출금 revert |
| INT-013 | test_INT013_validatorWithdrawal_exactMinimum_success | 정확히 최소 담보금 유지 시 출금 성공 |
| INT-013 | test_INT013_inactiveValidator_noRestriction | 비활성 검증자 출금 제한 없음 |
| INT-013 | test_INT013_nonValidator_noRestriction | 비검증자 출금 제한 없음 |
| INT-013 | test_INT013_dynamicMinimum_changesWithValidatorCount | 검증자 수에 따라 동적 최소 담보금 |
| INT-013 | test_INT013_partialWithdrawal_remainsActive | 부분 출금 후에도 활성 유지 |
| INT-013 | test_INT013_withdrawAfterRATDeduction | RAT 차감 후 출금 |
| INT-013 | test_INT013_withdrawBelowMinAfterRATDeduction_reverts | RAT 차감 후 최소 미만 출금 revert |
| - | test_getValidatorMinCollateralForLayer2_activeValidator | 활성 검증자 최소 담보금 조회 |
| - | test_getValidatorMinCollateralForLayer2_inactiveValidator | 비활성 검증자 최소 담보금 조회 |
| - | test_getValidatorMinCollateralForLayer2_nonValidator | 비검증자 최소 담보금 조회 |

### SeigniorageFormulaValidation.t.sol (12개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SD-003 | test_SD003_anyoneCanCallUpdateSeigniorage | 누구나 updateSeigniorage 호출 가능 |
| SD-004 | test_SD004_v2ModeDistribution | V2 모드 (λ=1, r=0.4) 분배 |
| SD-005 | test_SD005_v3FullModeDistribution | V3 완전 모드 (λ=0, r=0) 분배 |
| SD-006 | test_SD006_transitionLambdaDecrease | λ 감소에 따른 스테이커 시뇨리지 감소 |
| SD-007 | test_SD007_transitionRDecrease | r 감소에 따른 V3 분배 재원 증가 |
| SD-008 | test_SD008_multipleL2Distribution | 여러 L2 Bridged TON 비례 분배 |
| SD-009 | test_SD009_consecutiveUpdates | 여러 번 연속 updateSeigniorage |
| SD-013 | test_SD013_ineligibleL2Excluded | 자격 미달 L2 분배 제외 |
| SD-014 | test_SD014_slashedL2Excluded | 슬래싱된 L2 분배 제외 |
| SD-015 | test_SD015_allL2Slashed_allToDAO | 모든 L2 슬래싱 시 전액 DAO |
| EDGE-002 | test_EDGE002_halfSaturationPoint | x=k일 때 y=L/2 |
| EDGE-003 | test_EDGE003_hyperbolicSaturationConvergence | x 증가할수록 y→L 수렴 |

### MultiL2SeigniorageDistribution.t.sol (10개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SD-001 | test_SD001_v3Migration_state | V3 마이그레이션 상태 확인 |
| SD-002 | test_SD002_v3Parameters_verification | V3 파라미터 검증 |
| SD-010 | test_SD010_daoDistribution_formula | DAO 분배 공식: S_DAO = d × A |
| SD-012 | test_SD012_sequencerReward_formula | 시퀀서 보상 공식: (1-α) × y |
| SD-014 | test_SD014_proportionalDistribution_formula | 비례 분배 공식 |
| SD-015 | test_SD015_ineligibleL2_excluded | 자격 미달 L2 제외 |
| SD-016 | test_SD016_estimateL2Seigniorage | L2 시뇨리지 추정 |
| SD-017 | test_SD017_noDoubleDistribution_sameBlock | 같은 블록 중복 분배 방지 |
| E2E-031 | test_E2E031_multiL2_eligibilityCheck | 다중 L2 자격 검증 |
| E2E-031 | test_E2E031_hyperbolicSaturation_formula | 쌍곡선 포화 공식 검증 |

### SeigniorageAccuracy.t.sol (8개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_singleBlock | 1블록 정확도 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_multipleBlocks | 다중 블록 정확도 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_withEligibleL2 | 자격 있는 L2 포함 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_cumulative | 누적 정확도 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_largeSpan | 대량 블록 스팬 |
| SM-016 | test_SM016_v3_updateSeigniorage_zeroSpan_reverts | span=0 시 revert |
| SM-016 | test_SM016_v3_formulaVerification_daoOnlyCase | DAO만 있는 경우 공식 |
| SM-016 | testFuzz_SM016_v3_updateSeigniorage_exactAmountByBlocks | Fuzz: 블록별 정확도 |

### SecurityPermissions.t.sol (30개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SEC-001 | test_SEC001_onlyOwner_* | 소유자만 호출 가능 함수 검증 |
| SEC-002 | test_SEC002_onlyRAT_* | RAT만 호출 가능 함수 검증 |
| SEC-003 | test_SEC003_onlyDepositManager_* | DepositManager만 호출 가능 |
| SEC-004 | test_SEC004_onlyValidFactory_* | ValidFactory만 호출 가능 |
| SEC-005 | test_SEC005_onlyL1BridgeOrRegistry_* | L1Bridge/Registry만 호출 가능 |
| SEC-010 | test_SEC010_ifFree_* | 재진입 방지 (reentrancy guard) |
| SEC-011 | test_SEC011_CEI_pattern | Checks-Effects-Interactions 패턴 |
| SEC-012 | test_SEC012_stateConsistency | 상태 일관성 |
| SEC-020~022 | 랜덤성 | blockHash 랜덤성, 분포, timestamp 조작 |
| SEC-030 | test_SEC030_zeroAddress_* | 0 주소 입력 검증 |
| SEC-031 | test_SEC031_parameterRange_* | 파라미터 범위 검증 (≤RAY 등) |
| SEC-032 | test_SEC032_emptyArrayHandling | 빈 배열 처리 |

---

## scenarios/ (18개)

### V3ScenarioReal.t.sol (8개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| E2E-001 | test_E2E001_v3Migration | V3 마이그레이션 전체 플로우 |
| E2E-002 | test_E2E002_registerCandidateType3 | TYPE 3 후보 등록 |
| E2E-003 | test_E2E003_validatorDepositToRAT | 검증자 RAT 예치 |
| E2E-004 | test_E2E004_multipleValidatorsDeposit | 다중 검증자 예치 |
| E2E-005 | test_E2E005_updateSeigniorageAfterMigration | 마이그레이션 후 시뇨리지 업데이트 |
| E2E-006 | test_E2E006_updateSeigniorageMultipleTimes | 시뇨리지 다중 업데이트 |
| E2E-012 | test_E2E012_validatorDeactivateAndReregister | 검증자 비활성화 후 재등록 |
| E2E-040 | test_E2E040_fullV3Scenario | V3 전체 시나리오 |

### MigrationScenarios.t.sol (7개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| MIG-001 | test_MIG001_migrateToV3_success | 마이그레이션 성공 |
| MIG-002 | test_MIG002_migrateToV3_alreadyMigrated | 중복 마이그레이션 revert |
| MIG-003 | test_MIG003_migrateToV3_recordBlock | 마이그레이션 블록 기록 |
| MIG-010 | test_MIG010_migration_preservesStaking | 기존 스테이킹 보존 |
| MIG-011 | test_MIG011_migration_parametersPreset | 파라미터 사전 설정 |
| MIG-012 | test_MIG012_migration_firstV3Distribution | 첫 V3 분배 |
| MIG-013 | test_MIG013_migration_eligibilityReevaluation | 자격 재평가 |

### SequencerJourney.t.sol (3개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SCENSEQ-001 | test_SCENSEQ001_newSequencer_fullJourney | 신규 시퀀서 전체 여정 |
| SCENSEQ-002 | test_SCENSEQ002_sequencer_eligibilityTransition | 시퀀서 자격 전환 |
| SCENSEQ-003 | test_SCENSEQ003_sequencer_slashingRecovery | 시퀀서 슬래싱 복구 |

### ValidatorJourney.t.sol (4개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SCENVAL-001 | test_SCENVAL001_validator_rewardClaim_fullJourney | 검증자 보상 청구 전체 여정 |
| SCENVAL-002 | test_SCENVAL002_validator_slashing_concept | 검증자 슬래싱 개념 |
| SCENVAL-003 | test_SCENVAL003_validator_reactivation_concept | 검증자 재활성화 개념 |
| SCENVAL-004 | test_SCENVAL004_validator_multiL2_rewards | 검증자 다중 L2 보상 |

---

## 총계: **306개 테스트** (스킵 15개 제외)

---

## 변경 이력

### 2026-01-23
- **SM-024 테스트 분할**: V2/V3(검증자 0명)/V3(검증자 1명+) 3개 케이스로 분리
  - V2: ValidatorReward 분배 없음
  - V3 검증자 0명: 민팅 후 즉시 DAO로 전송
  - V3 검증자 1명+: ValidatorReward에 pendingRewards로 누적
- **currentBridgedTON 버그 수정**: `_updateEligibilityInternal`에서 `currentBridgedTON`을 Layer2Manager에서 읽어 저장하도록 수정
- **V2V3ModeSwitching.t.sol 코드 최적화**: 헬퍼 함수 추가 (`_migrateToV3`, `_depositForV3Eligibility`, `_getValidatorRewardAndDAOBalances` 등)
- **RAT V2 검증자 등록 차단**: `RAT.registerValidator`에 V3 마이그레이션 체크 추가 (`NotMigratedError`)
- **MIG-003 테스트 분할**: Type 2/Type 3 rollup별 분리
  - Type 3: Portal 호출로 effectiveBridgedTON 업데이트, checkCurrentEligibility에서 eligible=true
  - Type 2: onBridgedTonChange 미지원, checkCurrentEligibility에서 eligible=false, requiredStake=0
- **MIG-004 테스트 분할**: Type 2/Type 3 rollup별 분리
  - Type 3: V3 마이그레이션 후 checkCurrentEligibility에서 requiredStake>0, eligible 체크
  - Type 2: V3 마이그레이션 후 checkCurrentEligibility에서 requiredStake=0, eligible=false
- **MIG-005 테스트 분할**: Type 2/Type 3 rollup별 분리
  - Type 3: deposit으로 currentStake 증가 → eligible false→true 변경 확인
  - Type 2: deposit으로 currentStake 증가해도 eligible=false 유지 (rollupType != 3)
- **checkCurrentEligibility rollupType 3 전용**: rollupType이 3이 아니면 eligible=false, requiredStake=0 반환
- **V2ModeTestBase 헬퍼 함수 추가**: `_registerMockLayer2Type2WithOperatorStake()`
- **MIG-006 테스트 추가**: V3→V2 다운그레이드 불가 확인 (v3Migrated 영구적 true)
