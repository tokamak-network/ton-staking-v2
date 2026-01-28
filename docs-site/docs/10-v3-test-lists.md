---
id: 10-v3-test-lists
sidebar_position: 10
---
# TON Staking V3 Test List

> **Last Updated**: 2026-01-27

---

## Test ID Naming Rules

| Prefix | Target Contract/Feature | Description |
|--------|------------------------|-------------|
| SM | SeigManager | Seigniorage manager related tests |
| DM | DepositManager | Deposit/withdrawal manager related tests |
| LBR | L1BridgeRegistry | L1 bridge registry related tests |
| L2M | Layer2Manager | Layer2 manager related tests |
| RAT | RAT (Random Attention Test) | Validator attention test related |
| VR | ValidatorReward | Validator reward contract related tests |
| MIG | Migration | V2→V3 migration related tests |
| INT | Integration | Inter-contract integration tests |
| SEC | Security | Security/permission related tests |
| SD | Seigniorage Distribution | Seigniorage distribution formula verification |
| INV | Invariant | Invariant tests |
| E2E | End-to-End | Full scenario tests |
| EDGE | Edge Case | Boundary/edge case tests |
| SCENSEQ | Scenario Sequencer | Sequencer scenario tests |
| SCENVAL | Scenario Validator | Validator scenario tests |
| GAS | Gas Measurement | Gas cost measurement tests |

**Suffix Rules:**
- `-V2` / `-V3`: V2/V3 mode distinction
- `-Type2` / `-Type3`: rollupType 2/3 distinction
- Numbers: Sequential test numbers (e.g., SM-001, SM-002)

---

## v2mode/ (44 tests)

### V2Functions.t.sol (16 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| SM-001 | test_SM001_v2_updateSeigniorage_linearDistribution | V2 linear distribution: 2x blocks → 2x seigniorage |
| SM-002 | test_SM002_v2_updateSeigniorage_coinageStakingSeigniorage | Operator/Staker balance auto-increases via coinage factor increase |
| SM-003 | test_SM003_v2_updateSeigniorage_layer2SequencerSeigniorage | Verify direct WTON transfer to OperatorManager |
| SM-004 | test_SM004_v2_updateSeigniorage_ignoresV3Parameters | V3 parameters (θ,α,k,d) set but no effect on V2 distribution |
| SM-010 | test_SM010_v2_seigniorage_onlyMinimumAmount | Seigniorage distribution if only minimumAmount met |
| SM-011 | test_SM011_v2_seigniorage_ignoresMinStakingRatio | Verify θ(minStakingRatio) ignored |
| SM-012 | test_SM012_v2_seigniorage_noEffectiveBridgedTON | effectiveBridgedTON not used (V3 only) |
| SM-020-V2 | test_SM020_v2_estimatedDistributeV2 | Query V2 estimated seigniorage distribution amount |
| SM-021-V2 | test_SM021_v2_claimableL2SeigniorageV2 | Query V2 claimable seigniorage |
| SM-022-V2 | test_SM022_v2_estimatedDistributeV2_unregisteredLayer2 | Unregistered Layer2 → layer2Seigs=0 |
| SM-023-V2 | test_SM023_v2_estimatedDistributeV2_blockCondition | Returns 0 if ≤ lastSeigBlock |
| SM-024-V2 | test_SM024_v2_negativeCommissionRate_concept | Negative commission rate concept test |
| DM-001 | test_DM001_v2_deposit_basicFlow | V2 basic deposit operation |
| DM-002 | test_DM002_v2_deposit_noV3Callback | onStakingChange callback not called in V2 |
| DM-003 | test_DM003_v2_withdraw_basicFlow | V2 basic withdrawal operation |
| DM-004 | test_DM004_v2_withdraw_operatorVsValidator | Operator: minimumAmount restriction / Validator: no restriction |

### V2V3ModeSwitching.t.sol (28 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| SM-020 | test_SM020_v2_hyperbolicSaturation_notUsed | Hyperbolic function callable in V2 but not used in distribution |
| SM-021 | test_SM021_v2_onBridgedTonChange_succeeds | Early return on call in V2 (does not revert) |
| SM-022 | test_SM022_v2_transferCoinageToRat_revertInV2 | RAT transfer function reverts in V2 |
| RAT-V2-001 | test_RAT_v2_registerValidator_revertInV2 | NotMigratedError on validator registration in V2 |
| SM-023 | test_SM023_v2_onStakingChange_succeeds | Early return on call in V2 (does not revert) |
| SM-024-V2 | test_SM024_v2_validatorReward_shouldNotDistribute | No ValidatorReward distribution in V2 |
| SM-024-V3-NoVal | test_SM024_v3_noValidators_goesToDAO | V3 0 validators: ValidatorReward → DAO transfer |
| SM-024-V3-WithVal | test_SM024_v3_withValidators_staysInValidatorReward | V3 1+ validators: Seigniorage remains in ValidatorReward |
| SM-025 | test_SM025_v2_canSetV3Parameters | Can set V3 parameters in V2 (no effect on distribution) |
| SM-026 | test_SM026_v2_canSetV3Contracts | Can set V3 contracts in V2 (not used) |
| SM-027 | test_SM027_v2_checkCurrentEligibility_returnsZero | checkCurrentEligibility always returns false, 0 in V2 |
| SM-028 | test_SM028_v2_getEffectiveBridgedTon_returnsZero | effectiveBridgedTON always 0 in V2 |
| SM-033 | test_SM033_v2_excludeFromL2Seigniorage_shouldRevertOrIgnore | excludeFromL2Seigniorage callable in V2 (no effect) |
| SM-034 | test_SM034_v2_includeFromL2Seigniorage_shouldRevertOrIgnore | includeFromL2Seigniorage reverts on call in V2 |
| SM-035 | test_SM035_afterMigration_pause_shouldWork | pause/unpause works normally after V2→V3 migration |
| SM-036 | test_SM036_afterMigration_excludeFromL2Seigniorage_shouldWork | excludeFromL2Seigniorage works normally after V2→V3 migration |
| SM-037 | test_SM037_afterMigration_includeFromL2Seigniorage_shouldWork | includeFromL2Seigniorage works normally after V2→V3 migration |
| SM-038 | test_SM038_v2_excludeThenInclude_shouldWork | V2 mode exclude→include full flow (verify seigniorage before/after) |
| SM-039 | test_SM039_v2ExcludeThenMigrateThenV3Include_shouldWork | V2 exclude → V3 migration → V3 include transition |
| MIG-001 | test_MIG001_migration_stateChange | v3Migrated state change before/after migration |
| MIG-002 | test_MIG002_migration_duplicateReverts | AlreadyMigratedError on duplicate migration |
| MIG-003-Type3 | test_MIG003_type3_getEffectiveBridgedTon_shouldUpdate | Type 3: effectiveBridgedTON updated via Portal call, eligible=true |
| MIG-003-Type2 | test_MIG003_type2_getEffectiveBridgedTon_shouldUpdate | Type 2: onBridgedTonChange not supported, eligible=false, requiredStake=0 |
| MIG-004-Type3 | test_MIG004_type3_afterMigration_v3Functions_shouldActivate | Type 3: checkCurrentEligibility eligible=true after V3 migration |
| MIG-004-Type2 | test_MIG004_type2_afterMigration_v3Functions_shouldActivate | Type 2: checkCurrentEligibility eligible=false after V3 migration |
| MIG-005-Type3 | test_MIG005_type3_afterMigration_onStakingChange_shouldWork | Type 3: eligible changes false→true when currentStake increases via deposit |
| MIG-005-Type2 | test_MIG005_type2_afterMigration_onStakingChange_shouldWork | Type 2: eligible=false maintained even when currentStake increases via deposit |
| MIG-006 | test_MIG006_v3ToV2_downgradeNotPossible | V3→V2 downgrade impossible (permanent V3 mode) |

---

## v3mode/

### SeigManagerV1_4Real.t.sol (61 tests)

**SeigManagerV3_1RealTest (40 tests)**

| ID | Test Function | Description |
|----|---------------|-------------|
| SM-001 | test_SM001_hyperbolicSaturation_zero | y=0 when x=0 |
| SM-002 | test_SM002_hyperbolicSaturation_halfPoint | y=L/2 when x=k |
| SM-003 | test_SM003_hyperbolicSaturation_large | y→L when x→∞ |
| SM-004 | test_SM004_hyperbolicSaturation_monotonic | y monotonically increases as x increases |
| SM-005 | testFuzz_SM005_hyperbolicSaturation_bounded | Fuzz: y≤L for arbitrary x,L |
| SM-006 | test_SM006_v3Parameters | V3 parameter setup and query |
| SM-007 | test_SM007_v3MigrationState | v3Migrated state before/after migration |
| SM-008 | test_SM008_slashingParameters | maxChallengers, maxFraudProofCost setup |
| SM-010 | test_SM010_calculateSequencerReward_basic | Sequencer reward = (1-α) × seig |
| SM-011 | test_SM011_calculateSequencerReward_zeroAlpha | Sequencer gets 100% when α=0 |
| SM-012 | testFuzz_SM012_calculateSequencerReward | Fuzz: Sequencer reward calculation |
| SM-015 | test_SM015_setMaxChallengers_basic | maxChallengers setup |
| SM-016 | test_SM016_setMaxFraudProofCost_basic | maxFraudProofCost setup |
| SM-017 | test_SM017_setValidatorReward_basic | ValidatorReward address setup |
| SM-018 | test_SM018_setValidatorReward_zeroAddress_reverts | Reverts on 0 address setup |
| SM-020 | test_SM020_checkCurrentEligibility_qualified | Eligibility met case: T_i ≥ max(θ×B_i, D_seq) |
| SM-021 | test_SM021_checkCurrentEligibility_unqualified | Eligibility not met case: T_i < required |
| SM-022 | test_SM022_DSequencer_calculation | D_seq = H_max × C_max + Δ_seq |
| SM-022 | test_SM022_DSequencer_allZero | When all D_seq parameters are 0 |
| SM-022 | test_SM022_DSequencer_largeValues | D_seq large value test |
| SM-022 | testFuzz_SM022_DSequencer | Fuzz: D_seq calculation |
| SM-023 | test_SM023_thetaBi_calculation | θ×B_i basic calculation (TON→WTON unit conversion) |
| SM-023 | test_SM023_thetaBi_unitConversion | Verify 1:1 conversion when θ=1 |
| SM-023 | test_SM023_thetaBi_zeroTheta | θ×B_i=0 when θ=0 |
| SM-023 | test_SM023_thetaBi_zeroBridgedTON | θ×B_i=0 when B_i=0 |
| SM-023 | testFuzz_SM023_thetaBi | Fuzz: θ×B_i calculation |
| SM-024 | test_SM024_setMaxChallengers_notOwner_reverts | Reverts on non-owner setup |
| SM-025 | test_SM025_setMaxFraudProofCost_notOwner_reverts | Reverts on non-owner setup |
| SM-030 | test_SM030_deployedContractsConnected | Verify deployed contract connections |
| SM-031 | test_SM031_validatorRewardConnected | Verify ValidatorReward connection |
| INT-012 | test_INT012_requiredStake_DSequencerDominant | max() formula: D_seq > θ×B_i |
| INT-012 | test_INT012_requiredStake_ThetaBiDominant | max() formula: θ×B_i > D_seq |
| INT-012 | test_INT012_requiredStake_bothZero | max() formula: both 0 |
| INT-012 | test_INT012_requiredStake_equal | max() formula: equal |
| INT-012 | testFuzz_INT012_requiredStake | Fuzz: max(θ×B_i, D_seq) |
| INT-030 | test_INT030_onBridgedTonChange_callerValidation | Reverts on unregistered portal call |
| INT-030 | test_INT030_onBridgedTonChange_v2Mode_silentReturn | Silent return in V2 mode |
| INT-031 | test_INT031_effectiveBridgedTON_update | Verify effectiveBridgedTON update |
| INT-032 | test_INT032_totalEffectiveBridgedTON_sync | Verify total sum synchronization |
| INT-031/032 | test_INT031_032_eligibilityLoss_removesEffective | effectiveBridgedTON=0 on eligibility loss |

**SeigManagerV3ViewFunctionsTest (21 tests)**

| ID | Test Function | Description |
|----|---------------|-------------|
| SM-040 | test_SM040_stakeOf | Query stakeOf (registered L2, after staking) |
| SM-042 | test_SM042_stakeOf_noStake | Account with no staking → returns 0 |
| SM-045 | test_SM045_getSequencerStaked | Query getSequencerStaked |
| SM-046 | test_SM046_getSequencerStaked_unregisteredLayer2 | Unregistered Layer2 → returns 0 |
| SM-047 | test_SM047_getSequencerStaked_noOperator | No operator → returns 0 |
| SM-050 | test_SM050_getOperatorAmount | Query getOperatorAmount |
| SM-060 | test_SM060_calculateL2Seigniorage | Basic calculateL2Seigniorage calculation |
| SM-061 | test_SM061_calculateL2Seigniorage_zeroTotalX | Returns 0 when totalX=0 |
| SM-063 | test_SM063_getLayer2RewardInfo | Query getLayer2RewardInfo |
| SM-064 | test_SM064_getLayer2RewardInfo_unregistered | Unregistered Layer2 → returns 0 |
| SM-070 | test_SM070_registry | Query registry address |
| SM-071 | test_SM071_depositManager | Query depositManager address |
| SM-072 | test_SM072_ton | Query ton address |
| SM-073 | test_SM073_wton | Query wton address |
| SM-074 | test_SM074_tot | Query tot address |
| SM-075 | test_SM075_seigPerBlock | Query seigPerBlock |
| SM-076 | test_SM076_lastSeigBlock | Query lastSeigBlock |
| SM-077 | test_SM077_coinages | Query coinages |
| SM-078 | test_SM078_commissionRates | Query commissionRates |
| SM-079 | test_SM079_isCommissionRateNegative | Query isCommissionRateNegative |
| SM-080 | test_SM080_lastCommitBlock | Query lastCommitBlock |

### DepositManagerV1_2Real.t.sol (35 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| DM-001 | test_DM001_deployedContractsConnected | Verify contract deployment and connections |
| DM-002 | test_DM002_depositManager_initialized | Verify initialization state |
| DM-003 | test_DM003_deposit_zeroAmount_reverts | Revert on 0 amount deposit |
| DM-004 | test_DM004_setGlobalWithdrawalDelay | Set global withdrawal delay |
| DM-005 | test_DM005_setGlobalWithdrawalDelay_notOwner_reverts | Revert on non-owner setup |
| DM-006 | test_DM006_getDelayBlocks_globalDelay | Query global delay blocks |
| DM-010 | test_DM010_requestWithdrawal_zeroAmount_reverts | Revert on 0 amount withdrawal request |
| DM-011 | testFuzz_DM011_setGlobalWithdrawalDelay | Fuzz: global withdrawal delay |
| DM-012 | test_DM012_getDelayBlocks_layer2Delay | Query Layer2-specific delay blocks |
| DM-013 | test_DM013_setWithdrawalDelayByOwner_lessThanGlobal_reverts | Revert on delay less than global |
| DM-020 | test_DM020_redeposit_emitsBothEvents | RFC-17: emit both events on redeposit |
| DM-021 | test_DM021_redepositMulti_emitsEventsWithAccumulatedAmount | RFC-17: accumulated amount events on multiple redeposits |
| DM-022 | test_DM022_redeposit_eventParameters | RFC-17: verify event parameter accuracy |
| DM-023 | test_DM023_freshDeposit_onlyEmitsDeposited | RFC-17: new deposit emits only Deposited |
| DM-030 | test_DM030_setMinDepositGasLimit | Set minDepositGasLimit |
| DM-031 | test_DM031_setMinDepositGasLimit_notOwner_reverts | Revert on non-admin setup |
| DM-032 | test_DM032_setSeigManager | Set SeigManager address |
| DM-033 | test_DM033_setSeigManager_notOwner_reverts | Revert on non-admin setup |
| DM-034 | test_DM034_setWithdrawalDelay_byOperator | Operator sets withdrawal delay |
| DM-035 | test_DM035_setWithdrawalDelay_notOperator_reverts | Revert on non-operator setup |
| DM-036 | test_DM036_setWithdrawalDelay_exceedsMax_reverts | Revert on exceeding MAX_DELAY_BLOCKS |
| DM-040 | test_DM040_requestWithdrawalAll | Request withdrawal of entire balance |
| DM-041 | test_DM041_processRequests_multiple | Process multiple withdrawals |
| DM-050 | test_DM050_numRequests | Query number of withdrawal requests |
| DM-051 | test_DM051_numPendingRequests | Query number of pending requests |
| DM-052 | test_DM052_pendingUnstakedLayer2 | Query pending withdrawal by Layer2 |
| DM-053 | test_DM053_pendingUnstakedAccount | Query pending withdrawal by account |
| DM-054 | test_DM054_withdrawalRequestIndex | Query withdrawal request index |
| DM-055 | test_DM055_withdrawalRequest | Query withdrawal request details |
| DM-060 | test_DM060_depositBatch | Batch deposit test |
| DM-070 | test_DM070_onApprove_deposit | Deposit via onApprove (WTON callback) |
| DM-071 | test_DM071_onApprove_notWTON_reverts | Revert on non-WTON caller |
| DM-072 | test_DM072_onApprove_invalidDataLength_reverts | Revert on invalid data length |
| DM-082 | test_DM082_getSequencerStaked | Query getSequencerStaked |
| DM-083 | test_DM083_getSequencerStaked_unregistered | Unregistered Layer2 → returns 0 |

### Layer2ManagerV1_2Real.t.sol (27 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| L2M-001 | test_L2M001_layer2Manager_initialized | Verify initialization state |
| L2M-002 | test_L2M002_getBridgedTon_unregisteredRollup | Unregistered rollup → returns 0 |
| L2M-003 | test_L2M003_getBridgedTonByLayer_noOperator | Layer2 with no operator → returns 0 |
| L2M-004 | test_L2M004_getLayer2BySystemConfig_unregistered | Unregistered systemConfig → address(0) |
| L2M-010 | test_L2M010_setOperatorManagerFactory | Set OperatorManagerFactory |
| L2M-011 | test_L2M011_setOperatorManagerFactory_notOwner_reverts | Revert on non-admin setup |
| L2M-012 | test_L2M012_setOperatorManagerFactory_sameValue_reverts | Revert on same value setup |
| L2M-013 | test_L2M013_setMinimumInitialDepositAmount | Set minimum initial deposit amount |
| L2M-014 | test_L2M014_setMinimumInitialDepositAmount_notOwner_reverts | Revert on non-admin setup |
| L2M-015 | test_L2M015_setMinimumInitialDepositAmount_sameValue_reverts | Revert on same value setup |
| L2M-020 | test_L2M020_pauseCandidateAddOn_notL1BridgeRegistry_reverts | Revert on pause by non-L1BridgeRegistry |
| L2M-021 | test_L2M021_unpauseCandidateAddOn_notL1BridgeRegistry_reverts | Revert on unpause by non-L1BridgeRegistry |
| L2M-022 | test_L2M022_pauseCandidateAddOn_notRegistered_reverts | Revert on pause when not registered |
| L2M-023 | test_L2M023_unpauseCandidateAddOn_alreadyActive_reverts | Revert on unpause when already active |
| L2M-030 | test_L2M030_rollupConfigOfOperator | Query operator → rollupConfig |
| L2M-031 | test_L2M031_candidateAddOnOfOperator | Query operator → candidateAddOn |
| L2M-032 | test_L2M032_checkLayer2Tvl | Query Layer2 TVL |
| L2M-033 | test_L2M033_checkL1Bridge | Query L1Bridge information |
| L2M-034 | test_L2M034_availableRegister | Query registration availability |
| L2M-035 | test_L2M035_verifyOperator | Verify operator |
| L2M-036 | test_L2M036_statusLayer2 | Query Layer2 status |
| L2M-037 | test_L2M037_layerInfo | Query Layer2 information |
| L2M-040 | test_L2M040_onApprove_notTonOrWton_reverts | Revert on non-TON/WTON caller |
| L2M-041 | test_L2M041_onApprove_wrongSpender_reverts | Revert on wrong spender |
| L2M-042 | test_L2M042_onApprove_invalidDataLength_reverts | Revert on invalid data length |
| L2M-043 | test_L2M043_onApprove_alreadyRegistered_reverts | Revert on already registered rollupConfig |
| L2M-044 | test_L2M044_checkL1BridgeDetail | Query L1Bridge detailed information |

### L1BridgeRegistryV1_2Real.t.sol (51 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| LBR-001 | test_LBR001_deployment_initialized | Verify deployment initialization |
| LBR-002 | test_LBR002_deployment_rolesSetup | Verify role setup |
| LBR-010~012 | TYPE 1 registration | Manager/Registrant registration, revert on unauthorized |
| LBR-020~022 | TYPE 2 registration | Manager registration, revert on 0 L2TON, revert on duplicate registration |
| LBR-030~032 | TYPE 3 registration | Manager registration, revert if DisputeGameFactory missing, revert on invalid type |
| LBR-040~045 | TypeRegistrant | Setup, permission verification, type-specific registration |
| LBR-050~055 | upgradeToType3 | TYPE 2→3, TYPE 1→3, revert if unregistered, revert if already TYPE 3, revert if DGF missing, revert on unauthorized |
| LBR-060~062 | reject/restore | CandidateAddOn rejection/restoration, permission verification |
| LBR-070~074 | availableForRegistration | Registration availability by type, false after registration, false when Portal used |
| LBR-080~092 | Others | rollupInfo query, revert on duplicate initialization, SeigniorageCommittee setup, event verification |
| **LBR-100** | **test_LBR100_defaultRollupTypes_registered** | **TYPE 1,2,3 기본 등록 확인 (V3 eligible bitmap 검증)** |
| **LBR-101** | **test_LBR101_addRollupType_success** | **새 타입(TYPE 4) 등록 성공, bitmap 업데이트 확인** |
| **LBR-102** | **test_LBR102_addRollupType_revertInvalidType** | **TYPE 0 등록 시 InvalidTypeError** |
| **LBR-103** | **test_LBR103_addRollupType_revertTypeAlreadyExists** | **중복 타입 등록 시 TypeAlreadyExistsError** |
| **LBR-104** | **test_LBR104_addRollupType_revertUnauthorized** | **권한 없는 사용자 addRollupType 호출 시 revert** |
| **LBR-105** | **test_LBR105_updateRollupType_success** | **타입 설정 업데이트 (name, V3 eligibility 변경)** |
| **LBR-106** | **test_LBR106_updateRollupType_revertTypeNotSupported** | **미등록 타입 업데이트 시 TypeNotSupportedError** |
| **LBR-107** | **test_LBR107_updateRollupType_noChangeEarlyReturn** | **변경사항 없으면 early return (가스 절약)** |
| **LBR-108** | **test_LBR108_getBridgePattern_success** | **타입별 bridge pattern 조회 (0=ERC20, 1=NATIVE)** |
| **LBR-109** | **test_LBR109_getTvlContractGetter_success** | **타입별 TVL getter selector 조회** |
| **LBR-110** | **test_LBR110_isValidRollupType_success** | **V3 eligibility 확인 (bitmap 기반)** |

### RAT.t.sol (33 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| RAT-001 | test_RAT001_registerValidator_success | Validator registration success |
| RAT-002 | test_RAT002_registerValidator_insufficientDeposit | Revert on insufficient collateral |
| RAT-003 | test_RAT003_registerValidator_alreadyRegistered | Revert on already registered validator |
| RAT-004 | test_RAT004_deactivateValidator | Deactivate validator |
| RAT-006 | test_RAT006_registerMultipleValidators | Register multiple validators |
| RAT-007a | test_RAT007a_maxValidators_exceeded_reverts | Revert when N_max exceeded |
| RAT-007b | test_RAT007b_maxValidators_zeroNotAllowed | N_max=0 not allowed |
| RAT-007c | test_RAT007c_maxValidators_reregisterAfterDeactivation | Re-register after deactivation |
| RAT-010 | test_RAT010_getDynamicMinimumCollateral | Calculate dynamic minimum collateral |
| RAT-011 | test_RAT011_getDynamicCoff_withFormula | Verify C_off calculation formula |
| RAT-012a | test_RAT012a_getCoffWithRelaxedCheck_relaxedMode | C_off calculation in relaxed mode |
| RAT-012b | test_RAT012b_getMinimumCollateralWithRelaxedCheck_relaxedMode | Minimum collateral in relaxed mode |
| RAT-013a | test_RAT013a_getCoffWithRelaxedCheck_strictMode | C_off calculation in strict mode |
| RAT-013b | test_RAT013b_getMinimumCollateralWithRelaxedCheck_strictMode | Minimum collateral in strict mode |
| RAT-021a | test_RAT021a_probabilisticTrigger_zeroProbability | No trigger when probability is 0 |
| RAT-021b | test_RAT021b_probabilisticTrigger_fullProbability | Always trigger when probability is 100% |
| RAT-022 | test_RAT022_triggerAttentionTest_noValidators | Trigger when no validators |
| RAT-025 | test_RAT025_relaxedValidatorCheck_thresholdIsCoffOnly | Relaxed mode: check only C_off |
| RAT-026 | test_RAT026_strictValidatorCheck_thresholdIsCoffPlusBuffer | Strict mode: check C_off+buffer |
| RAT-027 | test_RAT027_strictMode_validatorStaysWithSufficientStake | Validator stays with sufficient stake |
| RAT-031 | test_RAT031_submitEvidence_afterDeadline_reverts | Revert on evidence submission after deadline |
| RAT-032 | test_RAT032_submitEvidence_notSelected_reverts | Revert on evidence submission by non-selected validator |
| RAT-034 | test_RAT034_resolveClaim_afterChallengePeriod_fails | Claim fails after challenge period |
| RAT-040 | test_RAT040_getAttentionTestStatus_evidencePeriod | Evidence period status |
| RAT-041 | test_RAT041_getAttentionTestStatus_challengePeriod | Challenge period status |
| RAT-042 | test_RAT042_getAttentionTestStatus_slashed | Slashed status |
| RAT-043 | test_RAT043_getAttentionTestStatus_restoredByEvidence | Restored by evidence status |
| RAT-052a | test_RAT052a_treasury_zeroAddress_reverts | Revert on Treasury zero address |
| RAT-052b | test_RAT052b_treasury_setAndWithdraw | Treasury setup and withdrawal |
| EDGE-010 | test_EDGE010_duplicateTrigger_sameBatch_reverts | Revert on duplicate trigger for same batch |
| EDGE-010 | test_EDGE010_differentBatch_allowed | Different batches allowed |
| E2E-014 | test_E2E014_multipleL2_sameValidator | Same validator for multiple L2s |
| E2E-014 | test_E2E014_slashingOneL2_noAffectOther | Slashing one L2 does not affect others |

### RATSeigManagerIntegration.t.sol (15 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| INT-020 | test_INT020_coinagePreDeduction | Coinage deduction before RAT trigger |
| INT-021 | test_INT021_coinageRestoration | Coinage restoration after evidence submission |
| INT-021 | test_INT021_coinageRestorationByChallenge | Coinage restoration after challenge |
| INT-022 | test_INT022_coinageSlashing | Coinage burn on slashing |
| INT-023 | test_INT023_balanceSynchronization | RAT-SeigManager balance synchronization |
| SM-041 | test_SM041_transferCoinageFromRat | Return coinage from RAT→SeigManager |
| SM-042 | test_SM042_transferCoinageFromRatTo | Transfer coinage from RAT→specific address |
| INT-024 | test_INT024_multipleRATTriggers_balanceConsistency | Balance consistency with multiple triggers |
| INT-025 | test_INT025_insufficientCollateral_RATTrigger | Trigger behavior on insufficient collateral |
| GAS-001 | test_GAS001_maxValidators_seigniorageDistribution | Gas measurement for seigniorage distribution with max validators (100) |
| GAS-002 | test_GAS002_registerValidator_gas | Gas measurement for validator registration |
| GAS-003 | test_GAS003_triggerAttentionTest_gas | Gas measurement for RAT trigger (by validator count) |
| GAS-004 | test_GAS004_claimAllRewards_gas | Gas measurement for reward claim |
| GAS-005 | test_GAS005_deposit_gas | Gas measurement for deposit |
| GAS-006 | test_GAS006_fullScenario_gasReport | Comprehensive gas report (100 validators scenario) |

### ValidatorRewardV1.t.sol (37 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| VR-001 | test_VR001_distributeL2Rewards_basic | Basic L2 reward distribution (O(1)) |
| VR-002 | test_VR002_distributeL2Rewards_noValidators_toDAO | Transfer to DAO if no validators |
| VR-003 | test_VR003_distributeL2Rewards_multipleValidators | Equal distribution to multiple validators: v_j = (α·S_i) / \|V_i\| |
| VR-004 | test_VR004_claimAllRewards_success | Reward claim success |
| VR-005 | test_VR005_initialize_success | Initialization success |
| VR-006 | test_VR006_initialize_cannotReinitialize | Cannot reinitialize |
| VR-007 | test_VR007_distributeL2Rewards_excludeInactiveValidators | Exclude inactive validators |
| VR-008 | test_VR008_distributeL2Rewards_multipleL2s | Reward distribution from multiple L2s |
| VR-009 | test_VR009_distributeL2Rewards_zeroAmount | Ignore on 0 amount distribution |
| VR-010 | test_VR010_distributeL2Rewards_onlySeigManager | Only SeigManager can call |
| VR-011 | test_VR011_distributeL2Rewards_accumulation | Reward accumulation |
| VR-012 | test_VR012_distributeL2Rewards_remainder | Remainder handling (truncation) |
| VR-013 | test_VR013_claimAllRewards_noRewards_reverts | Revert if no rewards |
| VR-014 | test_VR014_claimAllRewards_multipleL2s | Claim rewards from multiple L2s at once |
| VR-015 | test_VR015_claimAllRewards_claimDistributeClaim | Claim→distribute→reclaim |
| VR-016 | test_VR016_getPendingRewards_accurate | Accuracy of pending rewards query |
| VR-017 | test_VR017_getPendingRewardsByL2_accurate | Query pending rewards by L2 |
| VR-018 | test_VR018_rewardCalculation_formula | Formula verification: amount / activeCount |
| VR-019 | test_VR019_rewardCalculation_precision | Precision with small amounts |
| VR-020~027 | Governance | RAT/SeigManager/Treasury setup, ownership transfer |
| VR-028~029 | Emergency | Emergency withdrawal, revert on non-owner |
| VR-030~033 | Events | L2RewardDistributed, ValidatorRewardReceived, RewardsClaimed, RewardToDAO |
| VR-034 | test_VR034_reregistration_debtReset | Block rewards during deactivation period on re-registration (debt reset) |
| VR-035 | test_VR035_claimRewardsByL2s_specificL2s | claimRewardsByL2s - claim specific L2s only |
| VR-036 | test_VR036_claimRewardsByL2s_batchThenRemainder | claimRewardsByL2s - claim remainder after batch |
| VR-037 | test_VR037_claimRewardsByL2s_skipsUnregisteredL2 | claimRewardsByL2s - skip unregistered L2 |

### ValidatorWithdrawalRestriction.t.sol (12 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| INT-013 | test_INT013_validatorWithdrawal_aboveMinimum_success | Withdrawal success when above minimum collateral |
| INT-013 | test_INT013_validatorWithdrawal_belowMinimum_reverts | Revert on withdrawal below minimum collateral |
| INT-013 | test_INT013_validatorWithdrawal_exactMinimum_success | Withdrawal success when exactly maintaining minimum collateral |
| INT-013 | test_INT013_inactiveValidator_noRestriction | No withdrawal restriction for inactive validator |
| INT-013 | test_INT013_nonValidator_noRestriction | No withdrawal restriction for non-validator |
| INT-013 | test_INT013_dynamicMinimum_changesWithValidatorCount | Dynamic minimum collateral changes with validator count |
| INT-013 | test_INT013_partialWithdrawal_remainsActive | Remains active after partial withdrawal |
| INT-013 | test_INT013_withdrawAfterRATDeduction | Withdrawal after RAT deduction |
| INT-013 | test_INT013_withdrawBelowMinAfterRATDeduction_reverts | Revert on withdrawal below minimum after RAT deduction |
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_activeValidator | Query minimum collateral for active validator |
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_inactiveValidator | Query minimum collateral for inactive validator |
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_nonValidator | Query minimum collateral for non-validator |

### MultiL2SeigniorageDistribution.t.sol (6 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| E2E-031 | test_E2E031_hyperbolicSaturation_formula | Verify hyperbolic saturation formula |
| SD-012 | test_SD012_sequencerReward_formula | Sequencer reward formula: (1-α) × y |
| SD-001 | test_SD001_v3Migration_state | Verify V3 migration state |
| SD-002 | test_SD002_v3Parameters_verification | Verify V3 parameters |
| SD-017 | test_SD017_claimOnlyInSameBlock | Only claim allowed in same block |
| SD-018 | test_SD018_distributionAllowed_differentBlock | Distribution allowed in different block |

### SeigniorageAccuracy.t.sol (21 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_singleBlock | Single block accuracy |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_multipleBlocks | Multiple block accuracy |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_withEligibleL2 | Include eligible L2 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_cumulative | Cumulative accuracy |
| SM-016 | testFuzz_SM016_v3_updateSeigniorage_exactAmountByBlocks | Fuzz: per-block accuracy |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_largeSpan | Large block span |
| SM-016 | test_SM016_v3_updateSeigniorage_zeroSpan_claimOnly | Only claim when span=0 |
| SM-016 | test_SM016_v3_formulaVerification_daoOnlyCase | Formula for DAO-only case |
| SM-016 | test_SM016_v3_EX1_formulaVerification_withEligibleL2 | Formula verification with eligible L2 |
| SM-016 | test_SM016_v3_EX2_multipleBlocks_withEligibleL2 | Multiple blocks + eligible L2 |
| SM-016 | test_SM016_v3_EX3_halfSaturationPoint_verification | Half saturation point verification |
| SM-016 | test_SM016_v3_EX4_smallBridgedTON_distribution | Small bridgedTON distribution |
| SM-016 | test_SM016_v3_EX5_largeBridgedTON_distribution | Large bridgedTON distribution |
| SM-016 | test_SM016_v3_EX6_exactHalfSaturation | Exact half saturation point |
| SM-016 | test_SM016_v3_EX7_distributionRatios_verification | Distribution ratio verification |
| SM-016 | test_SM016_v3_EX8_cumulativeDistribution_withBridgedTON | Cumulative distribution with bridgedTON |
| SM-016 | test_SM016_v3_EX9_differentBridgedTONRatios | Various bridgedTON ratios |
| SM-016 | test_SM016_v3_MULTI1_twoL2s_differentCallTimes | 2 L2s with different call times |
| SM-016 | test_SM016_v3_MULTI2_totalMintedEqualsExpected | Total minted amount verification |
| SM-016 | test_SM016_v3_MULTI3_fourL2s_staggeredCalls | 4 L2s with staggered calls |
| SM-016 | test_SM016_v3_MULTI4_rewardPerUnitAccumulation | rewardPerUnit accumulation |

### SeigManagerPausable.t.sol (19 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| SM-050 | test_SM050_pause_success | Pauser successfully pauses (V3: pausedBlock = block.number + 1) |
| SM-051 | test_SM051_pause_notPauser_reverts | Revert on call by non-pauser address |
| SM-052 | test_SM052_pause_alreadyPaused_reverts | Revert on call when already paused |
| SM-053 | test_SM053_pause_autoSeigniorageDistribution | V3: consecutive pause possible with auto seigniorage distribution on pause |
| SM-054 | test_SM054_unpause_success | Pauser successfully unpauses |
| SM-055 | test_SM055_unpause_notPauser_reverts | Revert on call by non-pauser address |
| SM-056 | test_SM056_unpause_notPaused_reverts | Revert on call when not paused |
| SM-057 | test_SM057_excludeFromL2Seigniorage_success | Layer2Manager successfully excludes L2 (effectiveBridgedTON=0) |
| SM-058 | test_SM058_excludeFromL2Seigniorage_notLayer2Manager_reverts | Revert on call by non-Layer2Manager address |
| SM-059 | test_SM059_excludeFromL2Seigniorage_alreadyExcluded_reverts | Revert on excluding already excluded L2 |
| SM-060 | test_SM060_includeFromL2Seigniorage_success | Layer2Manager successfully includes L2 |
| SM-061 | test_SM061_includeFromL2Seigniorage_notLayer2Manager_reverts | Revert on call by non-Layer2Manager address |
| SM-062 | test_SM062_includeFromL2Seigniorage_notExcluded_reverts | Revert on including non-excluded L2 |
| SM-063 | test_SM063_updateSeigniorage_whenPaused_earlyReturn | Early return on updateSeigniorage call when paused |
| SM-064 | test_SM064_claimL2Seigniorage_success | claimL2Seigniorage successful claim (prevents duplicate claim) |
| SM-065 | test_SM065_claimL2Seigniorage_whenPaused_success | claimL2Seigniorage possible when paused |
| SM-066 | test_SM066_claimL2Seigniorage_notMigrated_reverts | Check claimL2Seigniorage before V3 migration |
| SM-067 | test_SM067_claimL2Seigniorage_ineligible_returnsZero | Returns 0 on claimL2Seigniorage for ineligible L2 |
| SM-068 | test_SM068_claimL2Seigniorage_excluded_returnsZero | Returns 0 on claimL2Seigniorage for excluded L2 |

### EligibilityTransition.t.sol (13 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| INT-040 | test_INT040_autoClaimBeforeEligibilityLoss | Auto claim unclaimed rewards on eligibility loss |
| INT-041 | test_INT041_separatedRewardPerUnitTracking | Separate tracking of sequencer/validator rewardPerUnit |
| INT-042 | test_INT042_initialDebtResetOnReeligibility | Verify initialDebt reset on re-eligibility |
| INT-043 | test_INT043_fullEligibilityTransitionFlow | Full flow: eligibility gain→reward→loss(auto claim)→re-gain→reward |
| INT-044 | test_INT044_autoClaimEventEmitted | Verify AutoClaimBeforeEligibilityLoss event |
| INT-045 | test_INT045_pausedState_eligibilityLoss_claimUnclaimedRewards | Verify claim of unclaimed rewards on eligibility loss in global paused state |
| INT-046 | test_INT046_pausedState_eligibilityGain_setsEffectiveBridgedTON | Verify effectiveBridgedTON setup on eligibility gain in global paused state |
| INT-047 | test_INT047_eligibilityLoss_triggersSeigDistribution | Trigger seigniorage distribution on eligibility loss |
| INT-048 | test_INT048_eligibilityGain_triggersSeigDistribution | Trigger seigniorage distribution on eligibility gain |
| INT-049 | test_INT049_estimateL2Seigniorage_accuracy | L2 seigniorage estimation accuracy |
| INT-050 | test_INT050_estimateL2Seigniorage_withAccumulatedRewards | Estimation including accumulated rewards |
| INT-051 | test_INT051_claimableL2Seigniorage_returnsSequencerRewardOnly | Returns only sequencer reward |
| INT-052 | test_INT052_claimableL2Seigniorage_includesAccumulatedRewards | Includes accumulated rewards |

### SecurityPermissions.t.sol (25 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| SEC-001 | test_SEC001_onlyOwner_seigManager | SeigManager owner-only functions |
| SEC-001 | test_SEC001_onlyOwner_rat | RAT owner-only functions |
| SEC-001 | test_SEC001_onlyOwner_success | Owner call success |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageToRat | RAT-only: transferCoinageToRat |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageFromRat | RAT-only: transferCoinageFromRat |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageFromRatTo | RAT-only: transferCoinageFromRatTo |
| SEC-002 | test_SEC002_onlyRAT_success | RAT call success |
| SEC-003 | test_SEC003_onlyDepositManager_onDeposit | DepositManager-only: onDeposit |
| SEC-003 | test_SEC003_onlyDepositManager_onWithdraw | DepositManager-only: onWithdraw |
| SEC-003 | test_SEC003_onlyDepositManager_onStakingChange | DepositManager-only: onStakingChange |
| SEC-004 | test_SEC004_onlyValidFactory_triggerAttentionTest | ValidFactory-only: triggerAttentionTest |
| SEC-004 | test_SEC004_validFactory_success | ValidFactory call success |
| SEC-005 | test_SEC005_onlyL1BridgeOrRegistry_onBridgedTonChange | L1Bridge/Registry-only |
| SEC-005 | test_SEC005_onlyL1BridgeOrRegistry_validPortal_success | Valid Portal call success |
| SEC-011 | test_SEC011_CEI_pattern | Checks-Effects-Interactions pattern |
| SEC-020 | test_SEC020_randomness_uses_L1_values | Randomness using L1 values |
| SEC-030 | test_SEC030_zeroAddress_setRatContract | Zero address: setRatContract |
| SEC-030 | test_SEC030_zeroAddress_setValidatorReward | Zero address: setValidatorReward |
| SEC-030 | test_SEC030_zeroAddress_transferOwnership | Zero address: transferOwnership |
| SEC-031 | test_SEC031_parameterRange_daoDistributionRatio | Parameter range: daoDistributionRatio |
| SEC-031 | test_SEC031_parameterRange_validatorDistributionRatio | Parameter range: validatorDistributionRatio |
| SEC-031 | test_SEC031_parameterRange_minStakingRatio | Parameter range: minStakingRatio |
| SEC-031 | test_SEC031_parameterRange_ratTriggerProbability | Parameter range: ratTriggerProbability |
| SEC-032 | test_SEC032_emptyArrayHandling | Empty array handling |
| SEC-032 | test_SEC032_maxValidatorLimit | Maximum validator limit |

---

## scenarios/ (18 tests)

### V3ScenarioReal.t.sol (8 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| E2E-001 | test_E2E001_v3Migration | Full V3 migration flow |
| E2E-002 | test_E2E002_registerCandidateType3 | TYPE 3 candidate registration |
| E2E-003 | test_E2E003_validatorDepositToRAT | Validator deposit to RAT |
| E2E-004 | test_E2E004_multipleValidatorsDeposit | Multiple validator deposits |
| E2E-005 | test_E2E005_updateSeigniorageAfterMigration | Seigniorage update after migration |
| E2E-006 | test_E2E006_updateSeigniorageMultipleTimes | Multiple seigniorage updates |
| E2E-012 | test_E2E012_validatorDeactivateAndReregister | Validator deactivation and re-registration |
| E2E-040 | test_E2E040_fullV3Scenario | Full V3 scenario |

### MigrationScenarios.t.sol (7 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| MIG-001 | test_MIG001_migrateToV3_success | Migration success |
| MIG-002 | test_MIG002_migrateToV3_alreadyMigrated | Revert on duplicate migration |
| MIG-003 | test_MIG003_migrateToV3_recordBlock | Record migration block |
| MIG-010 | test_MIG010_migration_preservesStaking | Preserve existing staking |
| MIG-011 | test_MIG011_migration_parametersPreset | Preset parameters |
| MIG-012 | test_MIG012_migration_firstV3Distribution | First V3 distribution |
| MIG-013 | test_MIG013_migration_eligibilityReevaluation | Eligibility reevaluation |

### SequencerJourney.t.sol (3 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| SCENSEQ-001 | test_SCENSEQ001_newSequencer_fullJourney | New sequencer full journey |
| SCENSEQ-002 | test_SCENSEQ002_sequencer_eligibilityTransition | Sequencer eligibility transition |
| SCENSEQ-003 | test_SCENSEQ003_sequencer_slashingRecovery | Sequencer slashing recovery |

### ValidatorJourney.t.sol (4 tests)

| ID | Test Function | Description |
|----|---------------|-------------|
| SCENVAL-001 | test_SCENVAL001_validator_rewardClaim_fullJourney | Validator reward claim full journey |
| SCENVAL-002 | test_SCENVAL002_validator_slashing_concept | Validator slashing concept |
| SCENVAL-003 | test_SCENVAL003_validator_reactivation_concept | Validator reactivation concept |
| SCENVAL-004 | test_SCENVAL004_validator_multiL2_rewards | Validator multi-L2 rewards |

---

## Total: **555 tests**
