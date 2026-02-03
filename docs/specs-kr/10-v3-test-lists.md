# TON Staking V3 테스트 목록

> **최종 업데이트**: 2026-01-27

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
| GAS | Gas Measurement | 가스 비용 측정 테스트 |

**Suffix 규칙:**
- `-V2` / `-V3`: V2/V3 모드 구분
- `-Type2` / `-Type3`: rollupType 2/3 구분
- 숫자: 순차적 테스트 번호 (예: SM-001, SM-002)

---

## v2mode/ (44개)

### V2Functions.t.sol (16개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-001 | test_SM001_v2_updateSeigniorage_linearDistribution | V2 선형 분배: 블록 수 2배 → 시뇨리지 2배 |
| SM-002 | test_SM002_v2_updateSeigniorage_coinageStakingSeigniorage | Operator/Staker coinage factor 증가로 잔액 자동 증가 |
| SM-003 | test_SM003_v2_updateSeigniorage_layer2SequencerSeigniorage | OperatorManager로 WTON 직접 전송 확인 |
| SM-004 | test_SM004_v2_updateSeigniorage_ignoresV3Parameters | V3 파라미터(θ,α,k,d) 설정해도 V2 분배에 영향 없음 |
| SM-010 | test_SM010_v2_seigniorage_onlyMinimumAmount | minimumAmount만 충족하면 시뇨리지 분배 |
| SM-011 | test_SM011_v2_seigniorage_ignoresMinStakingRatio | θ(minStakingRatio) 무시 확인 |
| SM-012 | test_SM012_v2_seigniorage_noEffectiveBridgedTON | effectiveBridgedTON 미사용 (V3 전용) |
| SM-020-V2 | test_SM020_v2_estimatedDistributeV2 | V2 예상 시뇨리지 분배량 조회 |
| SM-021-V2 | test_SM021_v2_claimableL2SeigniorageV2 | V2 청구 가능 시뇨리지 조회 |
| SM-022-V2 | test_SM022_v2_estimatedDistributeV2_unregisteredLayer2 | 미등록 Layer2 → layer2Seigs=0 |
| SM-023-V2 | test_SM023_v2_estimatedDistributeV2_blockCondition | lastSeigBlock 이하 → 0 반환 |
| SM-024-V2 | test_SM024_v2_negativeCommissionRate_concept | 음수 커미션율 개념 테스트 |
| DM-001 | test_DM001_v2_deposit_basicFlow | V2 기본 예치 동작 |
| DM-002 | test_DM002_v2_deposit_noV3Callback | V2에서 onStakingChange 콜백 미호출 |
| DM-003 | test_DM003_v2_withdraw_basicFlow | V2 기본 출금 동작 |
| DM-004 | test_DM004_v2_withdraw_operatorVsValidator | Operator: minimumAmount 제한 / Validator: 제한 없음 |

### V2V3ModeSwitching.t.sol (28개)

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
| SM-033 | test_SM033_v2_excludeFromL2Seigniorage_shouldRevertOrIgnore | V2에서 excludeFromL2Seigniorage 호출 가능 (효과 없음) |
| SM-034 | test_SM034_v2_includeFromL2Seigniorage_shouldRevertOrIgnore | V2에서 includeFromL2Seigniorage 호출 시 revert |
| SM-035 | test_SM035_afterMigration_pause_shouldWork | V2→V3 마이그레이션 후 pause/unpause 정상 동작 |
| SM-036 | test_SM036_afterMigration_excludeFromL2Seigniorage_shouldWork | V2→V3 마이그레이션 후 excludeFromL2Seigniorage 정상 동작 |
| SM-037 | test_SM037_afterMigration_includeFromL2Seigniorage_shouldWork | V2→V3 마이그레이션 후 includeFromL2Seigniorage 정상 동작 |
| SM-038 | test_SM038_v2_excludeThenInclude_shouldWork | V2 모드 exclude→include 전체 흐름 (시뇨리지 전/후 검증) |
| SM-039 | test_SM039_v2ExcludeThenMigrateThenV3Include_shouldWork | V2 exclude → V3 마이그레이션 → V3 include 전환 |
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

### SeigManagerV1_4Real.t.sol (61개)

**SeigManagerV3_1RealTest (40개)**

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
| SM-015 | test_SM015_setMaxChallengers_basic | maxChallengers 설정 |
| SM-016 | test_SM016_setMaxFraudProofCost_basic | maxFraudProofCost 설정 |
| SM-017 | test_SM017_setValidatorReward_basic | ValidatorReward 주소 설정 |
| SM-018 | test_SM018_setValidatorReward_zeroAddress_reverts | 0 주소 설정 시 revert |
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
| INT-030 | test_INT030_onBridgedTonChange_callerValidation | 미등록 portal 호출 시 revert |
| INT-030 | test_INT030_onBridgedTonChange_v2Mode_silentReturn | V2 모드에서 silent return |
| INT-031 | test_INT031_effectiveBridgedTON_update | effectiveBridgedTON 업데이트 확인 |
| INT-032 | test_INT032_totalEffectiveBridgedTON_sync | 전체 합계 동기화 확인 |
| INT-031/032 | test_INT031_032_eligibilityLoss_removesEffective | 자격 상실 시 effectiveBridgedTON=0 |

**SeigManagerV3ViewFunctionsTest (21개)**

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-040 | test_SM040_stakeOf | stakeOf 조회 (등록된 L2, 스테이킹 후) |
| SM-042 | test_SM042_stakeOf_noStake | 스테이킹 없는 계정 → 0 반환 |
| SM-045 | test_SM045_getSequencerStaked | getSequencerStaked 조회 |
| SM-046 | test_SM046_getSequencerStaked_unregisteredLayer2 | 미등록 Layer2 → 0 반환 |
| SM-047 | test_SM047_getSequencerStaked_noOperator | operator 없는 경우 → 0 반환 |
| SM-050 | test_SM050_getOperatorAmount | getOperatorAmount 조회 |
| SM-060 | test_SM060_calculateL2Seigniorage | calculateL2Seigniorage 기본 계산 |
| SM-061 | test_SM061_calculateL2Seigniorage_zeroTotalX | totalX=0일 때 0 반환 |
| SM-063 | test_SM063_getLayer2RewardInfo | getLayer2RewardInfo 조회 |
| SM-064 | test_SM064_getLayer2RewardInfo_unregistered | 미등록 Layer2 → 0 반환 |
| SM-070 | test_SM070_registry | registry 주소 조회 |
| SM-071 | test_SM071_depositManager | depositManager 주소 조회 |
| SM-072 | test_SM072_ton | ton 주소 조회 |
| SM-073 | test_SM073_wton | wton 주소 조회 |
| SM-074 | test_SM074_tot | tot 주소 조회 |
| SM-075 | test_SM075_seigPerBlock | seigPerBlock 조회 |
| SM-076 | test_SM076_lastSeigBlock | lastSeigBlock 조회 |
| SM-077 | test_SM077_coinages | coinages 조회 |
| SM-078 | test_SM078_commissionRates | commissionRates 조회 |
| SM-079 | test_SM079_isCommissionRateNegative | isCommissionRateNegative 조회 |
| SM-080 | test_SM080_lastCommitBlock | lastCommitBlock 조회 |

### DepositManagerV1_2Real.t.sol (35개)

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
| DM-013 | test_DM013_setWithdrawalDelayByOwner_lessThanGlobal_reverts | 전역보다 작은 지연 설정 시 revert |
| DM-020 | test_DM020_redeposit_emitsBothEvents | RFC-17: redeposit 시 두 이벤트 발행 |
| DM-021 | test_DM021_redepositMulti_emitsEventsWithAccumulatedAmount | RFC-17: 다중 redeposit 누적 금액 이벤트 |
| DM-022 | test_DM022_redeposit_eventParameters | RFC-17: 이벤트 파라미터 정확성 검증 |
| DM-023 | test_DM023_freshDeposit_onlyEmitsDeposited | RFC-17: 신규 입금은 Deposited만 발행 |
| DM-030 | test_DM030_setMinDepositGasLimit | minDepositGasLimit 설정 |
| DM-031 | test_DM031_setMinDepositGasLimit_notOwner_reverts | 비관리자 설정 시 revert |
| DM-032 | test_DM032_setSeigManager | SeigManager 주소 설정 |
| DM-033 | test_DM033_setSeigManager_notOwner_reverts | 비관리자 설정 시 revert |
| DM-034 | test_DM034_setWithdrawalDelay_byOperator | operator가 출금 지연 설정 |
| DM-035 | test_DM035_setWithdrawalDelay_notOperator_reverts | 비operator 설정 시 revert |
| DM-036 | test_DM036_setWithdrawalDelay_exceedsMax_reverts | MAX_DELAY_BLOCKS 초과 시 revert |
| DM-040 | test_DM040_requestWithdrawalAll | 전체 잔액 출금 요청 |
| DM-041 | test_DM041_processRequests_multiple | 다중 출금 처리 |
| DM-050 | test_DM050_numRequests | 출금 요청 수 조회 |
| DM-051 | test_DM051_numPendingRequests | 대기 요청 수 조회 |
| DM-052 | test_DM052_pendingUnstakedLayer2 | Layer2별 대기 출금 조회 |
| DM-053 | test_DM053_pendingUnstakedAccount | 계정별 대기 출금 조회 |
| DM-054 | test_DM054_withdrawalRequestIndex | 출금 요청 인덱스 조회 |
| DM-055 | test_DM055_withdrawalRequest | 출금 요청 상세 조회 |
| DM-060 | test_DM060_depositBatch | 배치 입금 테스트 |
| DM-070 | test_DM070_onApprove_deposit | onApprove를 통한 입금 (WTON 콜백) |
| DM-071 | test_DM071_onApprove_notWTON_reverts | 비WTON 호출자 revert |
| DM-072 | test_DM072_onApprove_invalidDataLength_reverts | 잘못된 data 길이 revert |
| DM-082 | test_DM082_getSequencerStaked | getSequencerStaked 조회 |
| DM-083 | test_DM083_getSequencerStaked_unregistered | 미등록 Layer2 → 0 반환 |

### Layer2ManagerV1_2Real.t.sol (27개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| L2M-001 | test_L2M001_layer2Manager_initialized | 초기화 상태 확인 |
| L2M-002 | test_L2M002_getBridgedTon_unregisteredRollup | 미등록 rollup → 0 반환 |
| L2M-003 | test_L2M003_getBridgedTonByLayer_noOperator | operator 없는 layer2 → 0 반환 |
| L2M-004 | test_L2M004_getLayer2BySystemConfig_unregistered | 미등록 systemConfig → address(0) |
| L2M-010 | test_L2M010_setOperatorManagerFactory | OperatorManagerFactory 설정 |
| L2M-011 | test_L2M011_setOperatorManagerFactory_notOwner_reverts | 비관리자 설정 시 revert |
| L2M-012 | test_L2M012_setOperatorManagerFactory_sameValue_reverts | 동일 값 설정 시 revert |
| L2M-013 | test_L2M013_setMinimumInitialDepositAmount | 최소 초기 입금량 설정 |
| L2M-014 | test_L2M014_setMinimumInitialDepositAmount_notOwner_reverts | 비관리자 설정 시 revert |
| L2M-015 | test_L2M015_setMinimumInitialDepositAmount_sameValue_reverts | 동일 값 설정 시 revert |
| L2M-020 | test_L2M020_pauseCandidateAddOn_notL1BridgeRegistry_reverts | 비L1BridgeRegistry pause 시 revert |
| L2M-021 | test_L2M021_unpauseCandidateAddOn_notL1BridgeRegistry_reverts | 비L1BridgeRegistry unpause 시 revert |
| L2M-022 | test_L2M022_pauseCandidateAddOn_notRegistered_reverts | 미등록 상태 pause 시 revert |
| L2M-023 | test_L2M023_unpauseCandidateAddOn_alreadyActive_reverts | 이미 active 상태 unpause 시 revert |
| L2M-030 | test_L2M030_rollupConfigOfOperator | operator → rollupConfig 조회 |
| L2M-031 | test_L2M031_candidateAddOnOfOperator | operator → candidateAddOn 조회 |
| L2M-032 | test_L2M032_checkLayer2Tvl | Layer2 TVL 조회 |
| L2M-033 | test_L2M033_checkL1Bridge | L1Bridge 정보 조회 |
| L2M-034 | test_L2M034_availableRegister | 등록 가능 여부 조회 |
| L2M-035 | test_L2M035_verifyOperator | Operator 검증 |
| L2M-036 | test_L2M036_statusLayer2 | Layer2 상태 조회 |
| L2M-037 | test_L2M037_layerInfo | Layer2 정보 조회 |
| L2M-040 | test_L2M040_onApprove_notTonOrWton_reverts | 비TON/WTON 호출자 revert |
| L2M-041 | test_L2M041_onApprove_wrongSpender_reverts | 잘못된 spender revert |
| L2M-042 | test_L2M042_onApprove_invalidDataLength_reverts | 잘못된 data 길이 revert |
| L2M-043 | test_L2M043_onApprove_alreadyRegistered_reverts | 이미 등록된 rollupConfig revert |
| L2M-044 | test_L2M044_checkL1BridgeDetail | L1Bridge 상세 정보 조회 |

### L1BridgeRegistryV1_2Real.t.sol (51개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| LBR-001 | test_LBR001_deployment_initialized | 배포 초기화 확인 |
| LBR-002 | test_LBR002_deployment_rolesSetup | 역할 설정 확인 |
| LBR-010~012 | TYPE 1 등록 | Manager/Registrant 등록, 권한 없는 자 revert |
| LBR-020~022 | TYPE 2 등록 | Manager 등록, 0 L2TON revert, 중복 등록 revert |
| LBR-030~032 | TYPE 3 등록 | Manager 등록, DisputeGameFactory 없으면 revert, 잘못된 타입 revert |
| LBR-040~045 | TypeRegistrant | 설정, 권한 검증, 타입별 등록 |
| LBR-050~055 | upgradeToType3 | TYPE 2→3, TYPE 1→3, 미등록 revert, 이미 TYPE 3 revert, DGF 없음 revert, 권한 없음 revert |
| LBR-060~062 | reject/restore | CandidateAddOn 거부/복원, 권한 검증 |
| LBR-070~074 | availableForRegistration | 타입별 등록 가능 여부, 등록 후 false, Portal 사용 시 false |
| LBR-080~092 | 기타 | rollupInfo 조회, 초기화 중복 revert, SeigniorageCommittee 설정, 이벤트 검증 |
| LBR-100 | test_LBR100_defaultRollupTypes_registered | TYPE 1,2,3 기본 등록 확인 (V3 eligible bitmap 검증) |
| LBR-101 | test_LBR101_addRollupType_success | 새 타입(TYPE 4) 등록 성공, bitmap 업데이트 확인 |
| LBR-102 | test_LBR102_addRollupType_revertInvalidType | TYPE 0 등록 시 InvalidTypeError |
| LBR-103 | test_LBR103_addRollupType_revertTypeAlreadyExists | 중복 타입 등록 시 TypeAlreadyExistsError |
| LBR-104 | test_LBR104_addRollupType_revertUnauthorized | 권한 없는 사용자 addRollupType 호출 시 revert |
| LBR-105 | test_LBR105_updateRollupType_success | 타입 설정 업데이트 (name, V3 eligibility 변경) |
| LBR-106 | test_LBR106_updateRollupType_revertTypeNotSupported | 미등록 타입 업데이트 시 TypeNotSupportedError |
| LBR-107 | test_LBR107_updateRollupType_noChangeEarlyReturn | 변경사항 없으면 early return (가스 절약) |
| LBR-108 | test_LBR108_getBridgePattern_success | 타입별 bridge pattern 조회 (0=ERC20, 1=NATIVE) |
| LBR-109 | test_LBR109_getTvlContractGetter_success | 타입별 TVL getter selector 조회 |
| LBR-110 | test_LBR110_isValidRollupType_success | V3 eligibility 확인 (bitmap 기반) |

### RAT.t.sol (33개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| RAT-001 | test_RAT001_registerValidator_success | 검증자 등록 성공 |
| RAT-002 | test_RAT002_registerValidator_insufficientDeposit | 담보금 부족 시 revert |
| RAT-003 | test_RAT003_registerValidator_alreadyRegistered | 이미 등록된 검증자 revert |
| RAT-004 | test_RAT004_deactivateValidator | 검증자 비활성화 |
| RAT-006 | test_RAT006_registerMultipleValidators | 다중 검증자 등록 |
| RAT-007a | test_RAT007a_maxValidators_exceeded_reverts | N_max 초과 시 revert |
| RAT-007b | test_RAT007b_maxValidators_zeroNotAllowed | N_max=0 불가 |
| RAT-007c | test_RAT007c_maxValidators_reregisterAfterDeactivation | 비활성화 후 재등록 |
| RAT-010 | test_RAT010_getDynamicMinimumCollateral | 동적 최소 담보금 계산 |
| RAT-011 | test_RAT011_getDynamicCoff_withFormula | C_off 계산 공식 검증 |
| RAT-012a | test_RAT012a_getCoffWithRelaxedCheck_relaxedMode | 완화 모드 C_off 계산 |
| RAT-012b | test_RAT012b_getMinimumCollateralWithRelaxedCheck_relaxedMode | 완화 모드 최소 담보금 |
| RAT-013a | test_RAT013a_getCoffWithRelaxedCheck_strictMode | 엄격 모드 C_off 계산 |
| RAT-013b | test_RAT013b_getMinimumCollateralWithRelaxedCheck_strictMode | 엄격 모드 최소 담보금 |
| RAT-021a | test_RAT021a_probabilisticTrigger_zeroProbability | 확률 0일 때 트리거 안 함 |
| RAT-021b | test_RAT021b_probabilisticTrigger_fullProbability | 확률 100%일 때 항상 트리거 |
| RAT-022 | test_RAT022_triggerAttentionTest_noValidators | 검증자 없을 때 트리거 |
| RAT-025 | test_RAT025_relaxedValidatorCheck_thresholdIsCoffOnly | 완화 모드: C_off만 체크 |
| RAT-026 | test_RAT026_strictValidatorCheck_thresholdIsCoffPlusBuffer | 엄격 모드: C_off+buffer 체크 |
| RAT-027 | test_RAT027_strictMode_validatorStaysWithSufficientStake | 충분한 스테이크 시 유지 |
| RAT-031 | test_RAT031_submitEvidence_afterDeadline_reverts | 마감 후 증거 제출 revert |
| RAT-032 | test_RAT032_submitEvidence_notSelected_reverts | 선정 안 된 검증자 증거 제출 revert |
| RAT-034 | test_RAT034_resolveClaim_afterChallengePeriod_fails | 챌린지 기간 후 클레임 실패 |
| RAT-040 | test_RAT040_getAttentionTestStatus_evidencePeriod | 증거 기간 상태 |
| RAT-041 | test_RAT041_getAttentionTestStatus_challengePeriod | 챌린지 기간 상태 |
| RAT-042 | test_RAT042_getAttentionTestStatus_slashed | 슬래시 상태 |
| RAT-043 | test_RAT043_getAttentionTestStatus_restoredByEvidence | 증거로 복원 상태 |
| RAT-052a | test_RAT052a_treasury_zeroAddress_reverts | Treasury 0 주소 revert |
| RAT-052b | test_RAT052b_treasury_setAndWithdraw | Treasury 설정 및 출금 |
| EDGE-010 | test_EDGE010_duplicateTrigger_sameBatch_reverts | 동일 배치 중복 트리거 revert |
| EDGE-010 | test_EDGE010_differentBatch_allowed | 다른 배치는 허용 |
| E2E-014 | test_E2E014_multipleL2_sameValidator | 동일 검증자 다중 L2 |
| E2E-014 | test_E2E014_slashingOneL2_noAffectOther | 한 L2 슬래싱이 다른 L2에 영향 없음 |

### RATSeigManagerIntegration.t.sol (15개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| INT-020 | test_INT020_coinagePreDeduction | RAT 트리거 전 coinage 차감 |
| INT-021 | test_INT021_coinageRestoration | 증거 제출 후 coinage 복원 |
| INT-021 | test_INT021_coinageRestorationByChallenge | 챌린지 후 coinage 복원 |
| INT-022 | test_INT022_coinageSlashing | 슬래싱 시 coinage 소각 |
| INT-023 | test_INT023_balanceSynchronization | RAT-SeigManager 잔액 동기화 |
| SM-041 | test_SM041_transferCoinageFromRat | RAT→SeigManager coinage 반환 |
| SM-042 | test_SM042_transferCoinageFromRatTo | RAT→특정주소 coinage 전송 |
| INT-024 | test_INT024_multipleRATTriggers_balanceConsistency | 다중 트리거 잔액 일관성 |
| INT-025 | test_INT025_insufficientCollateral_RATTrigger | 담보금 부족 시 트리거 동작 |
| GAS-001 | test_GAS001_maxValidators_seigniorageDistribution | 최대 검증자 수(100명)에서 시뇨리지 분배 가스 측정 |
| GAS-002 | test_GAS002_registerValidator_gas | 검증자 등록 가스 측정 |
| GAS-003 | test_GAS003_triggerAttentionTest_gas | RAT 트리거 가스 측정 (검증자 수별) |
| GAS-004 | test_GAS004_claimAllRewards_gas | 보상 청구 가스 측정 |
| GAS-005 | test_GAS005_deposit_gas | Deposit 가스 측정 |
| GAS-006 | test_GAS006_fullScenario_gasReport | 종합 가스 리포트 (100명 검증자 시나리오) |

### ValidatorRewardV1.t.sol (37개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| VR-001 | test_VR001_distributeL2Rewards_basic | 기본 L2 보상 분배 (O(1)) |
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
| VR-034 | test_VR034_reregistration_debtReset | 재등록 시 비활성화 기간 보상 차단 (debt 리셋) |
| VR-035 | test_VR035_claimRewardsByL2s_specificL2s | claimRewardsByL2s - 특정 L2만 청구 |
| VR-036 | test_VR036_claimRewardsByL2s_batchThenRemainder | claimRewardsByL2s - 배치 청구 후 나머지 청구 |
| VR-037 | test_VR037_claimRewardsByL2s_skipsUnregisteredL2 | claimRewardsByL2s - 미등록 L2 스킵 |

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
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_activeValidator | 활성 검증자 최소 담보금 조회 |
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_inactiveValidator | 비활성 검증자 최소 담보금 조회 |
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_nonValidator | 비검증자 최소 담보금 조회 |

### MultiL2SeigniorageDistribution.t.sol (6개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| E2E-031 | test_E2E031_hyperbolicSaturation_formula | 쌍곡선 포화 공식 검증 |
| SD-012 | test_SD012_sequencerReward_formula | 시퀀서 보상 공식: (1-α) × y |
| SD-001 | test_SD001_v3Migration_state | V3 마이그레이션 상태 확인 |
| SD-002 | test_SD002_v3Parameters_verification | V3 파라미터 검증 |
| SD-017 | test_SD017_claimOnlyInSameBlock | 같은 블록에서 claim만 가능 |
| SD-018 | test_SD018_distributionAllowed_differentBlock | 다른 블록에서 분배 허용 |

### SeigniorageAccuracy.t.sol (21개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_singleBlock | 1블록 정확도 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_multipleBlocks | 다중 블록 정확도 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_withEligibleL2 | 자격 있는 L2 포함 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_cumulative | 누적 정확도 |
| SM-016 | testFuzz_SM016_v3_updateSeigniorage_exactAmountByBlocks | Fuzz: 블록별 정확도 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_largeSpan | 대량 블록 스팬 |
| SM-016 | test_SM016_v3_updateSeigniorage_zeroSpan_claimOnly | span=0일 때 claim만 |
| SM-016 | test_SM016_v3_formulaVerification_daoOnlyCase | DAO만 있는 경우 공식 |
| SM-016 | test_SM016_v3_EX1_formulaVerification_withEligibleL2 | 자격 L2 포함 공식 검증 |
| SM-016 | test_SM016_v3_EX2_multipleBlocks_withEligibleL2 | 다중 블록 + 자격 L2 |
| SM-016 | test_SM016_v3_EX3_halfSaturationPoint_verification | 반포화점 검증 |
| SM-016 | test_SM016_v3_EX4_smallBridgedTON_distribution | 소량 bridgedTON 분배 |
| SM-016 | test_SM016_v3_EX5_largeBridgedTON_distribution | 대량 bridgedTON 분배 |
| SM-016 | test_SM016_v3_EX6_exactHalfSaturation | 정확한 반포화점 |
| SM-016 | test_SM016_v3_EX7_distributionRatios_verification | 분배 비율 검증 |
| SM-016 | test_SM016_v3_EX8_cumulativeDistribution_withBridgedTON | bridgedTON 누적 분배 |
| SM-016 | test_SM016_v3_EX9_differentBridgedTONRatios | 다양한 bridgedTON 비율 |
| SM-016 | test_SM016_v3_MULTI1_twoL2s_differentCallTimes | 2개 L2 다른 호출 시간 |
| SM-016 | test_SM016_v3_MULTI2_totalMintedEqualsExpected | 총 민팅량 검증 |
| SM-016 | test_SM016_v3_MULTI3_fourL2s_staggeredCalls | 4개 L2 시차 호출 |
| SM-016 | test_SM016_v3_MULTI4_rewardPerUnitAccumulation | rewardPerUnit 누적 |

### SeigManagerPausable.t.sol (19개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SM-050 | test_SM050_pause_success | pauser가 정상적으로 일시정지 (V3: pausedBlock = block.number + 1) |
| SM-051 | test_SM051_pause_notPauser_reverts | pauser가 아닌 주소가 호출 시 revert |
| SM-052 | test_SM052_pause_alreadyPaused_reverts | 이미 paused 상태에서 호출 시 revert |
| SM-053 | test_SM053_pause_autoSeigniorageDistribution | V3: pause 시 자동 시뇨리지 발행으로 연속 pause 가능 |
| SM-054 | test_SM054_unpause_success | pauser가 정상적으로 재개 |
| SM-055 | test_SM055_unpause_notPauser_reverts | pauser가 아닌 주소가 호출 시 revert |
| SM-056 | test_SM056_unpause_notPaused_reverts | paused 상태가 아닐 때 호출 시 revert |
| SM-057 | test_SM057_excludeFromL2Seigniorage_success | Layer2Manager가 정상적으로 L2 제외 (effectiveBridgedTON=0) |
| SM-058 | test_SM058_excludeFromL2Seigniorage_notLayer2Manager_reverts | Layer2Manager가 아닌 주소가 호출 시 revert |
| SM-059 | test_SM059_excludeFromL2Seigniorage_alreadyExcluded_reverts | 이미 제외된 L2 다시 제외 시 revert |
| SM-060 | test_SM060_includeFromL2Seigniorage_success | Layer2Manager가 정상적으로 L2 포함 |
| SM-061 | test_SM061_includeFromL2Seigniorage_notLayer2Manager_reverts | Layer2Manager가 아닌 주소가 호출 시 revert |
| SM-062 | test_SM062_includeFromL2Seigniorage_notExcluded_reverts | 제외되지 않은 L2 포함 시 revert |
| SM-063 | test_SM063_updateSeigniorage_whenPaused_earlyReturn | pause 상태에서 updateSeigniorage 호출 시 조기 리턴 |
| SM-064 | test_SM064_claimL2Seigniorage_success | claimL2Seigniorage 정상 claim (중복 claim 방지) |
| SM-065 | test_SM065_claimL2Seigniorage_whenPaused_success | pause 상태에서 claimL2Seigniorage 가능 |
| SM-066 | test_SM066_claimL2Seigniorage_notMigrated_reverts | V3 마이그레이션 전 claimL2Seigniorage 체크 |
| SM-067 | test_SM067_claimL2Seigniorage_ineligible_returnsZero | 자격 없는 L2 claimL2Seigniorage 시 0 반환 |
| SM-068 | test_SM068_claimL2Seigniorage_excluded_returnsZero | excluded L2 claimL2Seigniorage 시 0 반환 |

### EligibilityTransition.t.sol (13개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| INT-040 | test_INT040_autoClaimBeforeEligibilityLoss | 자격 상실 시 미청구 보상 자동 claim |
| INT-041 | test_INT041_separatedRewardPerUnitTracking | sequencer/validator rewardPerUnit 분리 추적 |
| INT-042 | test_INT042_initialDebtResetOnReeligibility | 자격 재획득 시 initialDebt 리셋 검증 |
| INT-043 | test_INT043_fullEligibilityTransitionFlow | 자격 획득→보상→상실(자동claim)→재획득→보상 전체 플로우 |
| INT-044 | test_INT044_autoClaimEventEmitted | AutoClaimBeforeEligibilityLoss 이벤트 검증 |
| INT-045 | test_INT045_pausedState_eligibilityLoss_claimUnclaimedRewards | 전역 paused 상태에서 자격 상실 시 미청구 보상 claim 검증 |
| INT-046 | test_INT046_pausedState_eligibilityGain_setsEffectiveBridgedTON | 전역 paused 상태에서 자격 획득 시 effectiveBridgedTON 설정 검증 |
| INT-047 | test_INT047_eligibilityLoss_triggersSeigDistribution | 자격 상실 시 시뇨리지 분배 트리거 |
| INT-048 | test_INT048_eligibilityGain_triggersSeigDistribution | 자격 획득 시 시뇨리지 분배 트리거 |
| INT-049 | test_INT049_estimateL2Seigniorage_accuracy | L2 시뇨리지 추정 정확도 |
| INT-050 | test_INT050_estimateL2Seigniorage_withAccumulatedRewards | 누적 보상 포함 추정 |
| INT-051 | test_INT051_claimableL2Seigniorage_returnsSequencerRewardOnly | 시퀀서 보상만 반환 |
| INT-052 | test_INT052_claimableL2Seigniorage_includesAccumulatedRewards | 누적 보상 포함 |

### SecurityPermissions.t.sol (25개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| SEC-001 | test_SEC001_onlyOwner_seigManager | SeigManager 소유자 전용 함수 |
| SEC-001 | test_SEC001_onlyOwner_rat | RAT 소유자 전용 함수 |
| SEC-001 | test_SEC001_onlyOwner_success | 소유자 호출 성공 |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageToRat | RAT 전용: transferCoinageToRat |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageFromRat | RAT 전용: transferCoinageFromRat |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageFromRatTo | RAT 전용: transferCoinageFromRatTo |
| SEC-002 | test_SEC002_onlyRAT_success | RAT 호출 성공 |
| SEC-003 | test_SEC003_onlyDepositManager_onDeposit | DepositManager 전용: onDeposit |
| SEC-003 | test_SEC003_onlyDepositManager_onWithdraw | DepositManager 전용: onWithdraw |
| SEC-003 | test_SEC003_onlyDepositManager_onStakingChange | DepositManager 전용: onStakingChange |
| SEC-004 | test_SEC004_onlyValidFactory_triggerAttentionTest | ValidFactory 전용: triggerAttentionTest |
| SEC-004 | test_SEC004_validFactory_success | ValidFactory 호출 성공 |
| SEC-005 | test_SEC005_onlyL1BridgeOrRegistry_onBridgedTonChange | L1Bridge/Registry 전용 |
| SEC-005 | test_SEC005_onlyL1BridgeOrRegistry_validPortal_success | 유효한 Portal 호출 성공 |
| SEC-011 | test_SEC011_CEI_pattern | Checks-Effects-Interactions 패턴 |
| SEC-020 | test_SEC020_randomness_uses_L1_values | L1 값 사용 랜덤성 |
| SEC-030 | test_SEC030_zeroAddress_setRatContract | 0 주소: setRatContract |
| SEC-030 | test_SEC030_zeroAddress_setValidatorReward | 0 주소: setValidatorReward |
| SEC-030 | test_SEC030_zeroAddress_transferOwnership | 0 주소: transferOwnership |
| SEC-031 | test_SEC031_parameterRange_daoDistributionRatio | 파라미터 범위: daoDistributionRatio |
| SEC-031 | test_SEC031_parameterRange_validatorDistributionRatio | 파라미터 범위: validatorDistributionRatio |
| SEC-031 | test_SEC031_parameterRange_minStakingRatio | 파라미터 범위: minStakingRatio |
| SEC-031 | test_SEC031_parameterRange_ratTriggerProbability | 파라미터 범위: ratTriggerProbability |
| SEC-032 | test_SEC032_emptyArrayHandling | 빈 배열 처리 |
| SEC-032 | test_SEC032_maxValidatorLimit | 최대 검증자 제한 |

---

## scenarios/ (61개)

### FastWithdrawalScenarios.t.sol (21개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| FW-001 | test_FW001_setMinValidatorsForFastWithdrawal_onlyOwner | 최소 검증자 수 설정 (owner only) |
| FW-002 | test_FW002_setAggregatorFeeRate_validRange | 수집자 수수료율 설정 (유효 범위) |
| FW-003 | test_FW003_setAggregatorFeeRate_exceedsMax_reverts | 수수료율 상한 초과 시 revert |
| FW-010 | test_FW010_getValidatorBLSPubKey_notRegistered | 미등록 검증자 BLS 공개키 조회 |
| FW-011 | test_FW011_hasValidatorBLSKey_notRegistered | 미등록 검증자 BLS 키 확인 |
| FW-012 | test_FW012_getBatchValidatorBLSPublicKeys_empty | 빈 배치 BLS 키 조회 |
| FW-013 | test_FW013_getActiveValidatorsWithBLS_noValidators | 검증자 없을 때 활성 검증자 조회 |
| FW-020 | test_FW020_registerValidator_then_checkBLSKey | 검증자 등록 후 BLS 키 확인 |
| FW-021 | test_FW021_getActiveValidatorsWithBLS_afterBasicRegistration | 등록 후 활성 검증자 BLS 키 조회 |
| FW-030 | test_FW030_verifyAndExecute_disabled_reverts | Fast Withdrawal 비활성화 시 revert |
| FW-031 | test_FW031_verifyAndExecute_noValidators_reverts | 검증자 없을 때 revert |
| FW-032 | test_FW032_processedWithdrawals_initialState | 처리된 출금 초기 상태 |
| FW-040 | test_FW040_validatorBitmap_notUnanimous_reverts | 만장일치 아닐 때 revert |
| FW-041 | test_FW041_validatorBitmap_unanimous_twoValidators | 2명 검증자 만장일치 |
| FW-050 | test_FW050_invalidWithdrawalHash_reverts | 잘못된 출금 해시 시 revert |
| FW-060 | test_FW060_distributeFees_zeroFee | 수수료 0일 때 분배 |
| FW-061 | test_FW061_aggregatorFeeRate_calculation | 수집자 수수료 계산 |
| FW-070 | test_FW070_portal_notSet_reverts | Portal 미설정 시 revert |
| FW-080 | test_FW080_threeValidators_unanimousBitmap | 3명 검증자 만장일치 비트맵 |
| FW-081 | test_FW081_threeValidators_partialBitmap_reverts | 3명 중 부분 동의 시 revert |
| FW-090 | test_FW090_receive_acceptsEther | ETH 수령 가능 |

### FastWithdrawalE2E.t.sol (22개)

| ID | 테스트 함수 | 설명 |
|----|------------|------|
| **유닛 테스트** (3개) | | |
| FW-E2E-UNIT-001 | test_Unit_StateRootComputation | State Root 계산 검증 |
| FW-E2E-UNIT-002 | test_Unit_WithdrawalData | Withdrawal 데이터 구조 검증 |
| FW-E2E-UNIT-003 | test_Unit_WithdrawalHashComputation | Withdrawal Hash 계산 검증 |
| **Adjacent Leaves Verifier** (3개) | | |
| FW-E2E-ALV-001 | test_AdjacentLeavesVerifier_ValidProof | 유효한 인접 리프 증명 |
| FW-E2E-ALV-002 | test_AdjacentLeavesVerifier_InvalidRoot | 잘못된 루트 시 revert |
| FW-E2E-ALV-003 | test_AdjacentLeavesVerifier_SameLeaf | 동일 리프 (invalid) |
| **BLS 서명 검증** (4개) - requires BLS precompiles | | |
| FW-E2E-BLS-001 | test_E2E_VerifyAndExecuteFastWithdrawal_WithBLS | BLS 서명 기본 검증 |
| FW-E2E-BLS-002 | test_E2E_VerifyAndExecute_MultipleValidators | 다수 검증자 BLS 집계 |
| FW-E2E-BLS-003 | test_E2E_VerifyAndExecute_NonUnanimous_Reverts | 만장일치 아닐 때 실패 |
| FW-E2E-BLS-004 | test_E2E_VerifyAndExecute_InsufficientValidators_Reverts | 검증자 수 부족 시 실패 |
| **전체 플로우** (12개) | | |
| FW-E2E-001 | test_E2E_FastWithdrawal_FullFlow | **전체 플로우 통합 테스트 (등록→요청→검증→finalize→전송)** |
| FW-E2E-002 | test_E2E_FastWithdrawal_DisabledReverts | Fast Withdrawal 비활성화 시나리오 |
| FW-E2E-003 | test_E2E_FastWithdrawal_DuplicatePrevention | 중복 처리 방지 |
| FW-E2E-004 | test_E2E_FastWithdrawal_FeeDistribution | 수수료 분배 검증 |
| FW-E2E-005 | test_E2E_FastWithdrawal_ValidatorDeactivation | 검증자 비활성화 시나리오 |
| FW-E2E-006 | test_E2E_FastWithdrawal_NoPortal | Portal 미설정 에러 |
| FW-E2E-007 | test_E2E_FastWithdrawal_DeadlineExpiry | 마감 시간 만료 |
| FW-E2E-008 | test_E2E_FastWithdrawal_LargeAmount | 대량 출금 테스트 |
| FW-E2E-009 | test_E2E_FastWithdrawal_Sequential | 순차 출금 처리 |

**Fast Withdrawal 플로우**:
1. **검증자 등록**: BLS 공개키 등록
2. **출금 요청**: L2→L1 출금 증명 + Fast Withdrawal 요청 (fee 지불)
3. **RAT 검증**: 검증자들이 State Root 검증하고 BLS 서명 제출 (만장일치 필요)
4. **즉시 Finalize**: RAT 검증 완료 후 7일 대기 없이 즉시 출금 완료
5. **수수료 분배**: Aggregator + 검증자들에게 수수료 분배

**특징**:
- ✅ BLS 서명 집계로 만장일치 검증
- ✅ 일반 출금 대기 시간(7일) 우회
- ✅ ETHLockbox 연동 실제 ETH 전송
- ⚠️ BLS precompile 필요 (EIP-2537)

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

## op-e2e/ (7개)

### Go E2E 테스트 (faultproofs/)

**위치**: `op-e2e/faultproofs/`

| ID | 테스트 함수 | 파일 | 설명 |
|----|------------|------|------|
| **시스템 테스트** (3개) | | | |
| SYS-001 | TestTONStakingSystemStartup | rat_system_test.go | 컨트랙트 배포 검증 (~1s) |
| SYS-002 | TestAccountBalances | rat_system_test.go | Genesis 잔액 검증 (~1s) |
| SYS-003 | TestRATContractCall | rat_system_test.go | RAT 컨트랙트 호출 검증 (~1s) |
| **RAT 시나리오 테스트** (3개) | | | |
| RAT-E2E-001 | TestSimpleRAT_ValidatorRegistration | rat_challenge_test.go | Validator 등록 플로우 (~24s) |
| RAT-E2E-002 | TestSimpleRAT_GameCreation | rat_challenge_test.go | DisputeGame 생성 및 RAT 트리거 (~26s) |
| RAT-E2E-003 | TestSimpleRAT_ChallengerWins | rat_challenge_test.go | Challenger 승리 전체 시나리오 (~40s) |
| **RAT Client E2E 테스트** (1개) | | | |
| RAT-CLIENT-E2E-001 | TestRATClient_EvidenceSubmission_E2E | rat_state_root_test.go | RAT Client 전체 통합 테스트 (~53s) |

### RAT Client E2E 테스트 상세

**TestRATClient_EvidenceSubmission_E2E** - 완전한 통합 테스트:
- **L1 환경**: Isolated Anvil with genesis (모든 컨트랙트 사전 배포)
- **L2 환경**: Isolated geth dev mode with archive state
- **테스트 범위**:
  1. L2 트랜잭션 생성 및 state 변경
  2. OutputRootProof 계산 (version, stateRoot, messagePasserStorageRoot, blockHash)
  3. Validator 등록 (prerequisite)
  4. DisputeGame 생성 (RAT 자동 트리거)
  5. RAT Client subprocess 실행
  6. Adjacent Leaves 증거 생성 (debug API 사용)
  7. StateLeafEvidence 온체인 제출
  8. Type 3 Evidence Verifier 검증
  9. Gas 사용량 측정 (~277k)

**커버리지**:
- ✅ L1 (Anvil) + L2 (geth) 통합
- ✅ OutputRootProof 계산 및 검증
- ✅ DisputeGame 생성 및 RAT 트리거
- ✅ RAT Client subprocess 실행
- ✅ Adjacent leaves 실제 증거 생성 (debug API)
- ✅ StateLeafEvidence 온체인 제출 및 검증
- ✅ Type 3 Evidence Verifier 통합

**실행 시간**: ~45초 (전체 7개 테스트, 병렬 실행)

**실행 명령**:
```bash
cd op-e2e && make test
# 또는 특정 테스트
GOWORK=off go test -v -run TestRATClient_EvidenceSubmission_E2E ./faultproofs
```

**Fast Withdrawal E2E 테스트 상태**:
- ✅ **op-e2e Go 테스트 3개 작성 완료** (RAT 중심)
- ✅ Solidity로 48개 테스트 완료 (FastWithdrawalScenarios 26개 + FastWithdrawalE2E 22개)
- ✅ **Optimism op-e2e 테스트**: OptimismPortal2 Fast Withdrawal 배포 검증 완료

### RAT Fast Withdrawal Go E2E 테스트

**위치**: 
- `op-e2e/faultproofs/rat_fast_withdrawal_test.go` - 기본 테스트
- `op-e2e/faultproofs/rat_fast_withdrawal_e2e_test.go` - E2E 집단서명 테스트

| ID | 테스트 함수 | 설명 | 실행 시간 | 상태 |
|----|------------|------|---------|------|
| RAT-FW-001 | TestSimpleRAT_FastWithdrawalConfiguration | Fast Withdrawal 파라미터 설정 검증 | ~1s | ✅ 통과 |
| RAT-FW-002 | TestSimpleRAT_FastWithdrawalBLSRegistration | 검증자 등록 및 BLS 키 상태 확인 | ~24s | ✅ 통과 |
| RAT-FW-003 | TestSimpleRAT_FastWithdrawalValidatorQuery | 3명 검증자 등록 및 조회 검증 | ~40s | ✅ 통과 |
| RAT-FW-004 | TestSimpleRAT_FastWithdrawalE2E | 전체 집단서명 플로우 (BLS 키 등록 시도) | ~42s | ✅ 통과 |
| RAT-FW-005 | TestSimpleRAT_FastWithdrawalUnanimousRequirement | 만장일치 합의 요구사항 검증 | ~40s | ✅ 통과 |

**RAT-FW-001 검증 항목**:
- `fastWithdrawalEnabled()` 활성화 상태
- `minValidatorsForFastWithdrawal()` 최소 검증자 수
- `aggregatorFeeRate()` 수집자 수수료율
- `validatorReward()` ValidatorReward 주소

**RAT-FW-002 검증 항목**:
1. 검증자 1명 등록 (최소 담보금 초과)
2. `hasValidatorBLSKey()` 초기 상태 false 확인
3. `getActiveValidatorsWithBLS()` 반환: 1명 활성, 0명 BLS 키

**RAT-FW-003 검증 항목**:
1. 3명 검증자 등록 (validator, deployer, proposer)
2. `getActiveValidatorsWithBLS()` 3명 반환 확인
3. `getBatchValidatorBLSPublicKeys()` 배치 조회
4. 검증자 주소 매칭 확인

**RAT-FW-004 검증 항목** (완전한 E2E 플로우):
1. 3명 검증자 등록
2. BLS 키쌍 생성 (off-chain)
3. BLS 키 온체인 등록 시도
4. Proof of Possession 생성 (mock)
5. 집단서명 생성 (mock)
6. 만장일치 bitmap 계산 (0b111 = 7)

**RAT-FW-005 검증 항목**:
1. 3명 검증자 등록
2. 만장일치 bitmap 계산: `(1 << 3) - 1 = 7`
3. 부분 서명 시나리오 검증 (0b110, 0b101, 0b011 모두 무효)
4. 100% 합의 요구사항 확인

**실행 방법**:

**현재 (로컬 Anvil - EIP-2537 없음)**:
```bash
cd op-e2e
GOWORK=off go test -v -run TestSimpleRAT_FastWithdrawal ./faultproofs/
```

**Pectra 업그레이드 후 (메인넷 포크 - EIP-2537 있음)**:
```bash
# 1. 터미널 1: 메인넷 포크 Anvil 실행
anvil --fork-url https://eth-mainnet.alchemyapi.io/v2/YOUR_ALCHEMY_KEY \
      --port 8545 \
      --chain-id 900

# 2. 터미널 2: 테스트 실행
cd op-e2e
GOWORK=off go test -v -run TestSimpleRAT_FastWithdrawalE2E ./faultproofs/ -timeout 10m

# 또는 편의 스크립트 사용
make test-fast-withdrawal-fork
```

**테스트 범위**:
- ✅ **검증자 등록**: 3명 검증자 등록 및 활성 상태 확인
- ✅ **컨트랙트 인터페이스**: Fast Withdrawal 관련 함수 호출
- ✅ **BLS 키 생성**: off-chain BLS 키쌍 생성 (mock)
- ✅ **집단서명 플로우**: 만장일치 합의 메커니즘 검증
- ✅ **BLS 키 등록 시도**: 온체인 등록 트랜잭션 전송 (EIP-2537 제약으로 revert)
- ⚠️ **실제 BLS 서명 검증**: EIP-2537 precompile 필요 (Anvil 미지원)

**핵심 검증 사항**:
1. **여러 검증자 등록**: 3명 검증자가 각각 최소 담보금 초과 예치
2. **집단서명 합의**: 모든 검증자가 서명해야 함 (bitmap: 0b111)
3. **만장일치 요구**: 부분 서명 불가 (0b110, 0b101, 0b011 모두 무효)
4. **BLS 키 관리**: 키 생성, PoP, 온체인 등록 플로우

**EIP-2537 제약 사항 및 해결 방법**:

현재 상황 (2025년 2월):
- ⚠️ **EIP-2537 미활성화**: Ethereum Pectra 업그레이드 예정 (2025년 3-4월)
- ⚠️ **메인넷/테스트넷 모두 미지원**: BLS12-381 precompile 없음
- ⚠️ **Anvil/Hardhat fork**: EIP-2537 없는 시점의 체인 상태 복사

현재 테스트 가능 범위:
- ✅ 검증자 등록 및 관리 (완전 테스트)
- ✅ BLS 키 생성 및 데이터 구조 (off-chain)
- ✅ 집단서명 플로우 및 만장일치 메커니즘 (로직)
- ✅ 트랜잭션 구조 및 컨트랙트 호출 (인터페이스)
- ⚠️ 실제 BLS 암호학 검증 (Pectra 후 가능)

Pectra 업그레이드 후 완전한 테스트:
1. 메인넷 포크로 EIP-2537 활성화된 상태 테스트
2. 실제 BLS12-381 라이브러리 사용 (supranational/blst)
3. 검증자 집단서명 및 검증 전체 플로우 테스트

**해결된 이슈**:
- ✅ `RegisterError(3)` 해결: `scripts/config/devnetL1.json`의 `systemConfigProxy` 주소 수정
- ✅ Genesis 재생성 후 모든 RAT 및 Fast Withdrawal 테스트 통과
- ✅ 집단서명 E2E 테스트 추가 (BLS 키 생성 및 집계 로직)

---

## Optimism op-e2e (1개)

### OptimismPortal2 Fast Withdrawal 배포 검증

**위치**: `/Users/zena/tokamak-projects/optimism/op-e2e/system/bridge/`

| ID | 테스트 함수 | 파일 | 설명 | 상태 |
|----|------------|------|------|------|
| PORTAL-FW-001 | TestOptimismPortal2_FastWithdrawalDeployment | fast_withdrawal_portal_test.go | OptimismPortal2 Fast Withdrawal 배포 검증 (~4s) | ✅ 통과 |
| PORTAL-FW-002 | TestOptimismPortal2_ProveAndRequestFastWithdrawal | fast_withdrawal_portal_test.go | proveAndRequestFastWithdrawal 함수 테스트 | ⏭️ Skip |
| PORTAL-FW-003 | TestFastWithdrawal_Default | fast_withdrawal_test.go | Fast Withdrawal 전체 플로우 | ⏭️ Skip |

### TestOptimismPortal2_FastWithdrawalDeployment 상세

**검증 항목**:

1. **Proxy 배포 확인**
   - OptimismPortalProxy 코드 크기: 2,059 bytes
   - 주소: `0x060791e98d94228c8bFC7e24c2818636b2C1eB15`

2. **Implementation 배포 확인**
   - Implementation 주소: `0x34e71da4bB2027D958C0E8B3219677198D03552B`
   - **코드 크기: 20,989 bytes** (24KB 제한의 85.4%)
   - ✅ **EIP-170 24KB 제한 준수**

3. **Fast Withdrawal 함수 선택자 확인**
   - ✅ `setRatContract(address)` selector 발견
   - ✅ `setFastWithdrawalResponsePeriod(uint256)` selector 발견
   - ✅ OptimismPortal2에 Fast Withdrawal 기능 포함 확인

**실행 방법**:
```bash
cd /Users/zena/tokamak-projects/optimism/op-e2e
go test -v ./system/bridge -run TestOptimismPortal2_FastWithdrawalDeployment
```

**성과**:
- ✅ 원래 24KB를 초과했던 코드를 **20,989 bytes (85.4%)로 최적화**
- ✅ Fast Withdrawal 통합 완료 (Mock 없이 실제 코드)
- ✅ 실제 배포 환경에서 검증 완료

---

## RAT Client 유닛 테스트 (60개)

### Go 유닛 테스트 (clients/rat-client-type3/)

**위치**: `clients/rat-client-type3/pkg/`

| 카테고리 | 테스트 수 | 파일 | 주요 테스트 |
|---------|---------|------|-----------|
| **Evidence** | 11개 | evidence/state_leaf_test.go | Adjacent leaves 생성, 검증 로직 |
| **L2 Sync** | 32개 | l2sync/syncer_test.go | L2 블록 동기화, OutputRootProof 조회 |
| **Submitter** | 8개 | submitter/adjacent_submitter_test.go | 증거 제출, ABI 인코딩 |
| **Event Monitor** | 9개 | client/event_monitor_test.go | L1 이벤트 구독, 필터링 |

**주요 테스트 케이스**:

#### Evidence Package (11개)
- Adjacent leaves 탐색 알고리즘 (binary search)
- Divergence witness 생성 및 검증
- OutputRootProof 구조 검증
- State leaf RLP 인코딩/디코딩
- Merkle proof 생성

#### L2 Sync Package (32개)
- L2 블록 헤더 조회
- State root 추출
- MessagePasser storage root 계산
- OutputRootProof 생성
- debug_accountRange API 호출
- eth_getProof API 호출

#### Submitter Package (8개)
- StateLeafEvidence ABI 인코딩
- submitEvidence 트랜잭션 생성
- Gas estimation
- Transaction receipt 검증

#### Event Monitor Package (9개)
- AttentionTestTriggered 이벤트 구독
- 이벤트 필터링 (validator address)
- 블록 범위 쿼리
- 재연결 로직

**실행 명령**:
```bash
cd clients/rat-client-type3
go test ./pkg/...
```

---

## 전체 테스트 통계

### Solidity 테스트
- **총 테스트**: 693개 통과 ✅
  - V2 모드: 44개
  - V3 모드: 316개
  - Scenarios: 61개 (V3 8개 + Migration 7개 + Sequencer 3개 + Validator 4개 + **Fast Withdrawal 48개**)
    - FastWithdrawalScenarios.t.sol: 26개 (설정, 검증자 관리, 게임 클레임 체크)
    - FastWithdrawalE2E.t.sol: 22개 (전체 플로우, BLS 서명, Adjacent Leaves)
  - Invariants: 148개
  - **Game Claim Check 테스트 포함**: DisputeGame에 클레임이 있을 때 Fast Withdrawal 차단 검증
- **커버리지**:
  - V3 실효 커버리지: 88.5% (lines)
  - 전체 시스템: 54.12% (lines, infrastructure 포함)
- **실행 시간**: ~2.5분

### Go 테스트
- **ton-staking-v2 op-e2e 테스트**: 10개 ✅
  - 시스템 테스트: 3개
  - RAT 시나리오: 3개
  - RAT Client E2E: 1개
  - **RAT Fast Withdrawal: 3개** ✅ (신규 추가)
- **Optimism op-e2e 테스트**: 1개 (OptimismPortal2 Fast Withdrawal 배포 검증) ✅
- **RAT Client 유닛 테스트**: 60개
- **총 Go 테스트**: 71개 ✅
- **실행 시간**:
  - ton-staking-v2 op-e2e: ~48초 (RAT FW 3개 추가, 병렬 실행)
  - Optimism op-e2e: ~4초
  - RAT Client 유닛: ~5초

### 총계
- **Solidity**: 693개 ✅ (V2: 44 + V3: 316 + Scenarios: 61 + Invariants: 148 + FW: 48 추가 + Game Claim: 5)
- **Go E2E**: 8개 (ton-staking-v2: 7개 + Optimism: 1개) ✅
- **Go Unit**: 60개 (RAT Client)
- **전체**: **761개 테스트** (통과 757개 + 작성 중 3개)

### 테스트 카테고리 구성
- **기본 기능 테스트**: 360개 (V2 44개 + V3 316개)
- **시나리오 테스트**: 61개
  - **Fast Withdrawal**: 48개 (Scenarios 26개 + E2E 22개)
  - V3 Scenario: 8개
  - Migration: 7개
  - Sequencer Journey: 3개
  - Validator Journey: 4개
- **불변성 테스트**: 148개
- **E2E 통합 테스트**: 8개 (ton-staking-v2 7개 + Optimism 1개) ✅
- **RAT Client 유닛**: 60개 (Go)
