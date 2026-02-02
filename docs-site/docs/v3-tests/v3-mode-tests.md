---
id: v3-mode-tests
title: V3 Mode Tests
sidebar_position: 3
---

# V3 Mode Tests (493 tests)

V3 mode exclusive functionality, calculation formulas, and integration tests.

## SeigManagerV1_4Real.t.sol (61 tests)

### SeigManagerV3_1RealTest (40 tests)

#### Hyperbolic Saturation Function Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-001 | test_SM001_hyperbolicSaturation_zero | y=0 when x=0 |
| SM-002 | test_SM002_hyperbolicSaturation_halfPoint | y=L/2 when x=k |
| SM-003 | test_SM003_hyperbolicSaturation_large | y→L when x→∞ |
| SM-004 | test_SM004_hyperbolicSaturation_monotonic | y monotonically increases as x increases |
| SM-005 | testFuzz_SM005_hyperbolicSaturation_bounded | Fuzz: y≤L for arbitrary x,L |

#### V3 Parameters and State Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-006 | test_SM006_v3Parameters | V3 parameter setting and retrieval |
| SM-007 | test_SM007_v3MigrationState | v3Migrated state before and after migration |
| SM-008 | test_SM008_slashingParameters | maxChallengers, maxFraudProofCost setting |

#### Sequencer Reward Calculation Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-010 | test_SM010_calculateSequencerReward_basic | Sequencer reward = (1-α) × seig |
| SM-011 | test_SM011_calculateSequencerReward_zeroAlpha | 100% to sequencer when α=0 |
| SM-012 | testFuzz_SM012_calculateSequencerReward | Fuzz: Sequencer reward calculation |

#### Parameter Setting Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-015 | test_SM015_setMaxChallengers_basic | Set maxChallengers |
| SM-016 | test_SM016_setMaxFraudProofCost_basic | Set maxFraudProofCost |
| SM-017 | test_SM017_setValidatorReward_basic | Set ValidatorReward address |
| SM-018 | test_SM018_setValidatorReward_zeroAddress_reverts | Revert on zero address |

#### Eligibility Verification Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-020 | test_SM020_checkCurrentEligibility_qualified | Qualified case: T_i ≥ max(θ×B_i, D_seq) |
| SM-021 | test_SM021_checkCurrentEligibility_unqualified | Unqualified case: T_i < required |

#### D_seq Calculation Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-022 | test_SM022_DSequencer_calculation | D_seq = H_max × C_max + Δ_seq |
| SM-022 | test_SM022_DSequencer_allZero | D_seq when all parameters are 0 |
| SM-022 | test_SM022_DSequencer_largeValues | D_seq with large values |
| SM-022 | testFuzz_SM022_DSequencer | Fuzz: D_seq calculation |

#### θ×B_i Calculation Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-023 | test_SM023_thetaBi_calculation | Basic θ×B_i calculation (TON→WTON unit conversion) |
| SM-023 | test_SM023_thetaBi_unitConversion | Verify 1:1 conversion when θ=1 |
| SM-023 | test_SM023_thetaBi_zeroTheta | θ×B_i=0 when θ=0 |
| SM-023 | test_SM023_thetaBi_zeroBridgedTON | θ×B_i=0 when B_i=0 |
| SM-023 | testFuzz_SM023_thetaBi | Fuzz: θ×B_i calculation |

#### Permission and Initialization Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-024 | test_SM024_setMaxChallengers_notOwner_reverts | Revert when non-owner sets |
| SM-025 | test_SM025_setMaxFraudProofCost_notOwner_reverts | Revert when non-owner sets |
| SM-030 | test_SM030_deployedContractsConnected | Verify deployed contract connections |
| SM-031 | test_SM031_validatorRewardConnected | Verify ValidatorReward connection |

#### Integration Tests (requiredStake)

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-012 | test_INT012_requiredStake_DSequencerDominant | max() formula: D_seq > θ×B_i |
| INT-012 | test_INT012_requiredStake_ThetaBiDominant | max() formula: θ×B_i > D_seq |
| INT-012 | test_INT012_requiredStake_bothZero | max() formula: both are 0 |
| INT-012 | test_INT012_requiredStake_equal | max() formula: when equal |
| INT-012 | testFuzz_INT012_requiredStake | Fuzz: max(θ×B_i, D_seq) |

#### onBridgedTonChange Integration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-030 | test_INT030_onBridgedTonChange_callerValidation | Revert when unregistered portal calls |
| INT-030 | test_INT030_onBridgedTonChange_v2Mode_silentReturn | Silent return in V2 mode |
| INT-031 | test_INT031_effectiveBridgedTON_update | Verify effectiveBridgedTON update |
| INT-032 | test_INT032_totalEffectiveBridgedTON_sync | Verify total sum synchronization |
| INT-031/032 | test_INT031_032_eligibilityLoss_removesEffective | effectiveBridgedTON=0 on eligibility loss |

---

### SeigManagerV3ViewFunctionsTest (21 tests)

#### Staking Query Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-040 | test_SM040_stakeOf | Query stakeOf (registered L2, after staking) |
| SM-042 | test_SM042_stakeOf_noStake | Return 0 for account with no stake |
| SM-045 | test_SM045_getSequencerStaked | Query getSequencerStaked |
| SM-046 | test_SM046_getSequencerStaked_unregisteredLayer2 | Return 0 for unregistered Layer2 |
| SM-047 | test_SM047_getSequencerStaked_noOperator | Return 0 when no operator |
| SM-050 | test_SM050_getOperatorAmount | Query getOperatorAmount |

#### Seigniorage Calculation Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-060 | test_SM060_calculateL2Seigniorage | Basic calculateL2Seigniorage calculation |
| SM-061 | test_SM061_calculateL2Seigniorage_zeroTotalX | Return 0 when totalX=0 |
| SM-063 | test_SM063_getLayer2RewardInfo | Query getLayer2RewardInfo |
| SM-064 | test_SM064_getLayer2RewardInfo_unregistered | Return 0 for unregistered Layer2 |

#### State Query Functions

| ID | Test Function | Description |
|----|--------------|-------------|
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

---

## DepositManagerV1_2Real.t.sol (35 tests)

### Initialization and Settings Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-001 | test_DM001_deployedContractsConnected | Verify contract deployment and connections |
| DM-002 | test_DM002_depositManager_initialized | Verify initialization state |
| DM-003 | test_DM003_deposit_zeroAmount_reverts | Revert on zero amount deposit |

### Withdrawal Delay Management

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-004 | test_DM004_setGlobalWithdrawalDelay | Set global withdrawal delay |
| DM-005 | test_DM005_setGlobalWithdrawalDelay_notOwner_reverts | Revert when non-owner sets |
| DM-006 | test_DM006_getDelayBlocks_globalDelay | Query global delay blocks |
| DM-011 | testFuzz_DM011_setGlobalWithdrawalDelay | Fuzz: Global withdrawal delay |
| DM-012 | test_DM012_getDelayBlocks_layer2Delay | Query Layer2-specific delay blocks |
| DM-013 | test_DM013_setWithdrawalDelayByOwner_lessThanGlobal_reverts | Revert when delay less than global |
| DM-034 | test_DM034_setWithdrawalDelay_byOperator | Operator sets withdrawal delay |
| DM-035 | test_DM035_setWithdrawalDelay_notOperator_reverts | Revert when non-operator sets |
| DM-036 | test_DM036_setWithdrawalDelay_exceedsMax_reverts | Revert when exceeds MAX_DELAY_BLOCKS |

### Withdrawal Request Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-010 | test_DM010_requestWithdrawal_zeroAmount_reverts | Revert on zero amount withdrawal request |
| DM-040 | test_DM040_requestWithdrawalAll | Request withdrawal of entire balance |
| DM-041 | test_DM041_processRequests_multiple | Process multiple withdrawal requests |

### RFC-17 Redeposit Event Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-020 | test_DM020_redeposit_emitsBothEvents | RFC-17: Emit both events on redeposit |
| DM-021 | test_DM021_redepositMulti_emitsEventsWithAccumulatedAmount | RFC-17: Multiple redeposits emit accumulated amount events |
| DM-022 | test_DM022_redeposit_eventParameters | RFC-17: Verify event parameter accuracy |
| DM-023 | test_DM023_freshDeposit_onlyEmitsDeposited | RFC-17: Fresh deposit only emits Deposited |

### Parameter Setting Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-030 | test_DM030_setMinDepositGasLimit | Set minDepositGasLimit |
| DM-031 | test_DM031_setMinDepositGasLimit_notOwner_reverts | Revert when non-admin sets |
| DM-032 | test_DM032_setSeigManager | Set SeigManager address |
| DM-033 | test_DM033_setSeigManager_notOwner_reverts | Revert when non-admin sets |

### Query Function Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-050 | test_DM050_numRequests | Query number of withdrawal requests |
| DM-051 | test_DM051_numPendingRequests | Query number of pending requests |
| DM-052 | test_DM052_pendingUnstakedLayer2 | Query pending withdrawals by Layer2 |
| DM-053 | test_DM053_pendingUnstakedAccount | Query pending withdrawals by account |
| DM-054 | test_DM054_withdrawalRequestIndex | Query withdrawal request index |
| DM-055 | test_DM055_withdrawalRequest | Query withdrawal request details |
| DM-082 | test_DM082_getSequencerStaked | Query getSequencerStaked |
| DM-083 | test_DM083_getSequencerStaked_unregistered | Return 0 for unregistered Layer2 |

### Batch and Callback Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-060 | test_DM060_depositBatch | Batch deposit test |
| DM-070 | test_DM070_onApprove_deposit | Deposit via onApprove (WTON callback) |
| DM-071 | test_DM071_onApprove_notWTON_reverts | Revert on non-WTON caller |
| DM-072 | test_DM072_onApprove_invalidDataLength_reverts | Revert on invalid data length |

---

## Layer2ManagerV1_2Real.t.sol (27 tests)

### Initialization and Query Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| L2M-001 | test_L2M001_layer2Manager_initialized | Verify initialization state |
| L2M-002 | test_L2M002_getBridgedTon_unregisteredRollup | Return 0 for unregistered rollup |
| L2M-003 | test_L2M003_getBridgedTonByLayer_noOperator | Return 0 for layer2 with no operator |
| L2M-004 | test_L2M004_getLayer2BySystemConfig_unregistered | Return address(0) for unregistered systemConfig |

### Parameter Setting Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| L2M-010 | test_L2M010_setOperatorManagerFactory | Set OperatorManagerFactory |
| L2M-011 | test_L2M011_setOperatorManagerFactory_notOwner_reverts | Revert when non-admin sets |
| L2M-012 | test_L2M012_setOperatorManagerFactory_sameValue_reverts | Revert when setting same value |
| L2M-013 | test_L2M013_setMinimumInitialDepositAmount | Set minimum initial deposit amount |
| L2M-014 | test_L2M014_setMinimumInitialDepositAmount_notOwner_reverts | Revert when non-admin sets |
| L2M-015 | test_L2M015_setMinimumInitialDepositAmount_sameValue_reverts | Revert when setting same value |

### Pause/Unpause Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| L2M-020 | test_L2M020_pauseCandidateAddOn_notL1BridgeRegistry_reverts | Revert when non-L1BridgeRegistry pauses |
| L2M-021 | test_L2M021_unpauseCandidateAddOn_notL1BridgeRegistry_reverts | Revert when non-L1BridgeRegistry unpauses |
| L2M-022 | test_L2M022_pauseCandidateAddOn_notRegistered_reverts | Revert when pausing unregistered state |
| L2M-023 | test_L2M023_unpauseCandidateAddOn_alreadyActive_reverts | Revert when unpausing already active state |

### Query Function Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| L2M-030 | test_L2M030_rollupConfigOfOperator | Query operator → rollupConfig |
| L2M-031 | test_L2M031_candidateAddOnOfOperator | Query operator → candidateAddOn |
| L2M-032 | test_L2M032_checkLayer2Tvl | Query Layer2 TVL |
| L2M-033 | test_L2M033_checkL1Bridge | Query L1Bridge information |
| L2M-034 | test_L2M034_availableRegister | Query registration availability |
| L2M-035 | test_L2M035_verifyOperator | Verify Operator |
| L2M-036 | test_L2M036_statusLayer2 | Query Layer2 status |
| L2M-037 | test_L2M037_layerInfo | Query Layer2 information |
| L2M-044 | test_L2M044_checkL1BridgeDetail | Query L1Bridge detailed information |

### onApprove Callback Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| L2M-040 | test_L2M040_onApprove_notTonOrWton_reverts | Revert on non-TON/WTON caller |
| L2M-041 | test_L2M041_onApprove_wrongSpender_reverts | Revert on wrong spender |
| L2M-042 | test_L2M042_onApprove_invalidDataLength_reverts | Revert on invalid data length |
| L2M-043 | test_L2M043_onApprove_alreadyRegistered_reverts | Revert on already registered rollupConfig |

---

## L1BridgeRegistryV1_2Real.t.sol (51 tests)

### Initialization and Role Setup

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-001 | test_LBR001_deployment_initialized | Verify deployment initialization |
| LBR-002 | test_LBR002_deployment_rolesSetup | Verify role setup |

### TYPE 1 Registration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-010 | test_LBR010_registerType1_byManager | Manager registers TYPE 1 |
| LBR-011 | test_LBR011_registerType1_byRegistrant | Registrant registers TYPE 1 |
| LBR-012 | test_LBR012_registerType1_notAuthorized_reverts | Revert when unauthorized registers TYPE 1 |

### TYPE 2 Registration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-020 | test_LBR020_registerType2_byManager | Manager registers TYPE 2 |
| LBR-021 | test_LBR021_registerType2_zeroL2TON_reverts | Revert when L2TON address is 0 |
| LBR-022 | test_LBR022_registerType2_duplicateL2TON_reverts | Revert on duplicate L2TON registration |

### TYPE 3 Registration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-030 | test_LBR030_registerType3_byManager | Manager registers TYPE 3 |
| LBR-031 | test_LBR031_registerType3_noDisputeGameFactory_reverts | Revert when no DisputeGameFactory |
| LBR-032 | test_LBR032_registerType3_wrongGameType_reverts | Revert on wrong game type |

### TypeRegistrant Management

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-040 | test_LBR040_setTypeRegistrant_byOwner | Owner sets TypeRegistrant |
| LBR-041 | test_LBR041_setTypeRegistrant_notOwner_reverts | Revert when non-Owner sets |
| LBR-042 | test_LBR042_typeRegistrant_canRegisterType1 | TypeRegistrant can register TYPE 1 |
| LBR-043 | test_LBR043_typeRegistrant_canRegisterType2 | TypeRegistrant can register TYPE 2 |
| LBR-044 | test_LBR044_typeRegistrant_canRegisterType3 | TypeRegistrant can register TYPE 3 |
| LBR-045 | test_LBR045_typeRegistrant_notOtherRoles | TypeRegistrant has no other roles |

### upgradeToType3 Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-050 | test_LBR050_upgradeToType3_fromType2 | Upgrade from TYPE 2 to TYPE 3 |
| LBR-051 | test_LBR051_upgradeToType3_fromType1 | Upgrade from TYPE 1 to TYPE 3 |
| LBR-052 | test_LBR052_upgradeToType3_notRegistered_reverts | Revert when upgrading unregistered state |
| LBR-053 | test_LBR053_upgradeToType3_alreadyType3_reverts | Revert when already TYPE 3 |
| LBR-054 | test_LBR054_upgradeToType3_noDisputeGameFactory_reverts | Revert when no DisputeGameFactory |
| LBR-055 | test_LBR055_upgradeToType3_notAuthorized_reverts | Revert when unauthorized upgrades |

### reject/restore Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-060 | test_LBR060_rejectCandidateAddOn | Reject CandidateAddOn |
| LBR-061 | test_LBR061_restoreCandidateAddOn | Restore CandidateAddOn |
| LBR-062 | test_LBR062_reject_restore_notAuthorized_reverts | Revert when unauthorized calls |

### availableForRegistration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-070 | test_LBR070_availableForRegistration_type1 | Check TYPE 1 registration availability |
| LBR-071 | test_LBR071_availableForRegistration_type2 | Check TYPE 2 registration availability |
| LBR-072 | test_LBR072_availableForRegistration_type3 | Check TYPE 3 registration availability |
| LBR-073 | test_LBR073_availableForRegistration_afterRegistration | Return false after registration |
| LBR-074 | test_LBR074_availableForRegistration_portalInUse | Return false when Portal in use |

### Other Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| LBR-080 | test_LBR080_rollupInfo_returns_correct_data | Query rollupInfo |
| LBR-081 | test_LBR081_initialize_cannot_reinitialize | Revert on duplicate initialization |
| LBR-090 | test_LBR090_setSeigniorageCommittee | Set SeigniorageCommittee |
| LBR-091 | test_LBR091_setSeigniorageCommittee_notOwner_reverts | Revert when non-Owner sets |
| LBR-092 | test_LBR092_rollupTypeChanged_event | Verify RollupTypeChanged event |

### RollupType Management (RFC-18)

| ID | Test Function | Description |
|----|--------------|-------------|
| **LBR-100** | **test_LBR100_defaultRollupTypes_registered** | **Verify default TYPE 1,2,3 registration (V3 eligible bitmap verification)** |
| **LBR-101** | **test_LBR101_addRollupType_success** | **Successfully register new type (TYPE 4), verify bitmap update** |
| **LBR-102** | **test_LBR102_addRollupType_revertInvalidType** | **InvalidTypeError when registering TYPE 0** |
| **LBR-103** | **test_LBR103_addRollupType_revertTypeAlreadyExists** | **TypeAlreadyExistsError on duplicate type registration** |
| **LBR-104** | **test_LBR104_addRollupType_revertUnauthorized** | **Revert when unauthorized user calls addRollupType** |
| **LBR-105** | **test_LBR105_updateRollupType_success** | **Update type settings (name, V3 eligibility change)** |
| **LBR-106** | **test_LBR106_updateRollupType_revertTypeNotSupported** | **TypeNotSupportedError when updating unregistered type** |
| **LBR-107** | **test_LBR107_updateRollupType_noChangeEarlyReturn** | **Early return when no changes (gas savings)** |
| **LBR-108** | **test_LBR108_getBridgePattern_success** | **Query bridge pattern by type (0=ERC20, 1=NATIVE)** |
| **LBR-109** | **test_LBR109_getTvlContractGetter_success** | **Query TVL getter selector by type** |
| **LBR-110** | **test_LBR110_isValidRollupType_success** | **Check V3 eligibility (bitmap-based)** |

---

## RAT.t.sol (33 tests)

### Validator Registration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-001 | test_RAT001_registerValidator_success | Validator registration success |
| RAT-002 | test_RAT002_registerValidator_insufficientDeposit | Revert on insufficient collateral |
| RAT-003 | test_RAT003_registerValidator_alreadyRegistered | Revert on already registered validator |
| RAT-004 | test_RAT004_deactivateValidator | Deactivate validator |
| RAT-006 | test_RAT006_registerMultipleValidators | Register multiple validators |

### Maximum Validators Management

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-007a | test_RAT007a_maxValidators_exceeded_reverts | Revert when exceeding N_max |
| RAT-007b | test_RAT007b_maxValidators_zeroNotAllowed | N_max=0 not allowed |
| RAT-007c | test_RAT007c_maxValidators_reregisterAfterDeactivation | Re-register after deactivation |

### Collateral Calculation Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-010 | test_RAT010_getDynamicMinimumCollateral | Calculate dynamic minimum collateral |
| RAT-011 | test_RAT011_getDynamicCoff_withFormula | Verify C_off calculation formula |
| RAT-012a | test_RAT012a_getCoffWithRelaxedCheck_relaxedMode | Calculate C_off in relaxed mode |
| RAT-012b | test_RAT012b_getMinimumCollateralWithRelaxedCheck_relaxedMode | Minimum collateral in relaxed mode |
| RAT-013a | test_RAT013a_getCoffWithRelaxedCheck_strictMode | Calculate C_off in strict mode |
| RAT-013b | test_RAT013b_getMinimumCollateralWithRelaxedCheck_strictMode | Minimum collateral in strict mode |

### Probabilistic Trigger Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-021a | test_RAT021a_probabilisticTrigger_zeroProbability | No trigger when probability is 0 |
| RAT-021b | test_RAT021b_probabilisticTrigger_fullProbability | Always trigger when probability is 100% |
| RAT-022 | test_RAT022_triggerAttentionTest_noValidators | Trigger when no validators |

### Validator Check Mode Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-025 | test_RAT025_relaxedValidatorCheck_thresholdIsCoffOnly | Relaxed mode: Check C_off only |
| RAT-026 | test_RAT026_strictValidatorCheck_thresholdIsCoffPlusBuffer | Strict mode: Check C_off+buffer |
| RAT-027 | test_RAT027_strictMode_validatorStaysWithSufficientStake | Stay with sufficient stake |

### Evidence Submission and Claim Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-031 | test_RAT031_submitEvidence_afterDeadline_reverts | Revert when submitting evidence after deadline |
| RAT-032 | test_RAT032_submitEvidence_notSelected_reverts | Revert when non-selected validator submits evidence |
| RAT-034 | test_RAT034_resolveClaim_afterChallengePeriod_fails | Claim fails after challenge period |

### Attention Test Status Query

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-040 | test_RAT040_getAttentionTestStatus_evidencePeriod | Evidence period status |
| RAT-041 | test_RAT041_getAttentionTestStatus_challengePeriod | Challenge period status |
| RAT-042 | test_RAT042_getAttentionTestStatus_slashed | Slashed status |
| RAT-043 | test_RAT043_getAttentionTestStatus_restoredByEvidence | Restored by evidence status |

### Treasury Management

| ID | Test Function | Description |
|----|--------------|-------------|
| RAT-052a | test_RAT052a_treasury_zeroAddress_reverts | Revert on Treasury zero address |
| RAT-052b | test_RAT052b_treasury_setAndWithdraw | Set Treasury and withdraw |

### Edge Cases

| ID | Test Function | Description |
|----|--------------|-------------|
| EDGE-010 | test_EDGE010_duplicateTrigger_sameBatch_reverts | Revert on duplicate trigger in same batch |
| EDGE-010 | test_EDGE010_differentBatch_allowed | Different batch allowed |

### Multi-L2 Slashing

| ID | Test Function | Description |
|----|--------------|-------------|
| E2E-014 | test_E2E014_multipleL2_sameValidator | Same validator on multiple L2s |
| E2E-014 | test_E2E014_slashingOneL2_noAffectOther | Slashing on one L2 doesn't affect other L2 |

---

## RATSeigManagerIntegration.t.sol (15 tests)

### Coinage Management Integration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-020 | test_INT020_coinagePreDeduction | Coinage deduction before RAT trigger |
| INT-021 | test_INT021_coinageRestoration | Coinage restoration after evidence submission |
| INT-021 | test_INT021_coinageRestorationByChallenge | Coinage restoration after challenge |
| INT-022 | test_INT022_coinageSlashing | Coinage burning on slashing |
| INT-023 | test_INT023_balanceSynchronization | RAT-SeigManager balance synchronization |

### Coinage Transfer Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-041 | test_SM041_transferCoinageFromRat | Return coinage from RAT→SeigManager |
| SM-042 | test_SM042_transferCoinageFromRatTo | Transfer coinage from RAT→specific address |

### Multiple Triggers and Edge Cases

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-024 | test_INT024_multipleRATTriggers_balanceConsistency | Balance consistency on multiple triggers |
| INT-025 | test_INT025_insufficientCollateral_RATTrigger | Trigger behavior on insufficient collateral |

### Gas Measurement Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| GAS-001 | test_GAS001_maxValidators_seigniorageDistribution | Measure seigniorage distribution gas with max validators (100) |
| GAS-002 | test_GAS002_registerValidator_gas | Measure validator registration gas |
| GAS-003 | test_GAS003_triggerAttentionTest_gas | Measure RAT trigger gas (by validator count) |
| GAS-004 | test_GAS004_claimAllRewards_gas | Measure reward claim gas |
| GAS-005 | test_GAS005_deposit_gas | Measure deposit gas |
| GAS-006 | test_GAS006_fullScenario_gasReport | Comprehensive gas report (100 validators scenario) |

---

## ValidatorRewardV1.t.sol (37 tests)

### Reward Distribution Basic Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-001 | test_VR001_distributeL2Rewards_basic | Basic L2 reward distribution (O(1)) |
| VR-002 | test_VR002_distributeL2Rewards_noValidators_toDAO | Transfer to DAO when no validators |
| VR-003 | test_VR003_distributeL2Rewards_multipleValidators | Equal distribution to multiple validators: v_j = (α·S_i) / \|V_i\| |
| VR-007 | test_VR007_distributeL2Rewards_excludeInactiveValidators | Exclude inactive validators |
| VR-008 | test_VR008_distributeL2Rewards_multipleL2s | Distribute rewards from multiple L2s |
| VR-009 | test_VR009_distributeL2Rewards_zeroAmount | Ignore zero amount distribution |
| VR-010 | test_VR010_distributeL2Rewards_onlySeigManager | Only SeigManager can call |
| VR-011 | test_VR011_distributeL2Rewards_accumulation | Reward accumulation |
| VR-012 | test_VR012_distributeL2Rewards_remainder | Remainder handling (truncate) |

### Reward Claim Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-004 | test_VR004_claimAllRewards_success | Successful reward claim |
| VR-013 | test_VR013_claimAllRewards_noRewards_reverts | Revert when no rewards |
| VR-014 | test_VR014_claimAllRewards_multipleL2s | Claim rewards from multiple L2s at once |
| VR-015 | test_VR015_claimAllRewards_claimDistributeClaim | Claim→distribute→reclaim |
| VR-035 | test_VR035_claimRewardsByL2s_specificL2s | claimRewardsByL2s - Claim specific L2s only |
| VR-036 | test_VR036_claimRewardsByL2s_batchThenRemainder | claimRewardsByL2s - Batch claim then remainder |
| VR-037 | test_VR037_claimRewardsByL2s_skipsUnregisteredL2 | claimRewardsByL2s - Skip unregistered L2 |

### Query Function Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-016 | test_VR016_getPendingRewards_accurate | Accurate unclaimed rewards query |
| VR-017 | test_VR017_getPendingRewardsByL2_accurate | Query unclaimed rewards by L2 |

### Formula Verification Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-018 | test_VR018_rewardCalculation_formula | Verify formula: amount / activeCount |
| VR-019 | test_VR019_rewardCalculation_precision | Small amount precision |

### Initialization Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-005 | test_VR005_initialize_success | Initialization success |
| VR-006 | test_VR006_initialize_cannotReinitialize | Cannot re-initialize |

### Governance Function Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-020 | test_VR020_setRat | Set RAT address |
| VR-021 | test_VR021_setRat_notOwner_reverts | Revert when non-owner sets |
| VR-022 | test_VR022_setSeigManager | Set SeigManager address |
| VR-023 | test_VR023_setSeigManager_notOwner_reverts | Revert when non-owner sets |
| VR-024 | test_VR024_setTreasury | Set Treasury address |
| VR-025 | test_VR025_setTreasury_notOwner_reverts | Revert when non-owner sets |
| VR-026 | test_VR026_transferOwnership | Transfer ownership |
| VR-027 | test_VR027_transferOwnership_notOwner_reverts | Revert when non-owner transfers |

### Emergency Withdrawal Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-028 | test_VR028_emergencyWithdraw | Emergency withdrawal |
| VR-029 | test_VR029_emergencyWithdraw_notOwner_reverts | Revert when non-owner withdraws |

### Event Verification Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-030 | test_VR030_event_L2RewardDistributed | L2RewardDistributed event |
| VR-031 | test_VR031_event_ValidatorRewardReceived | ValidatorRewardReceived event |
| VR-032 | test_VR032_event_RewardsClaimed | RewardsClaimed event |
| VR-033 | test_VR033_event_RewardToDAO | RewardToDAO event |

### Re-registration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| VR-034 | test_VR034_reregistration_debtReset | Block rewards during inactive period on re-registration (debt reset) |

---

## ValidatorWithdrawalRestriction.t.sol (12 tests)

### Validator Withdrawal Restriction Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-013 | test_INT013_validatorWithdrawal_aboveMinimum_success | Successful withdrawal above minimum collateral |
| INT-013 | test_INT013_validatorWithdrawal_belowMinimum_reverts | Revert on withdrawal below minimum collateral |
| INT-013 | test_INT013_validatorWithdrawal_exactMinimum_success | Successful withdrawal maintaining exact minimum collateral |
| INT-013 | test_INT013_inactiveValidator_noRestriction | No restriction for inactive validator withdrawal |
| INT-013 | test_INT013_nonValidator_noRestriction | No restriction for non-validator withdrawal |
| INT-013 | test_INT013_dynamicMinimum_changesWithValidatorCount | Dynamic minimum collateral changes with validator count |
| INT-013 | test_INT013_partialWithdrawal_remainsActive | Remain active after partial withdrawal |

### Withdrawal After RAT Deduction Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-013 | test_INT013_withdrawAfterRATDeduction | Withdrawal after RAT deduction |
| INT-013 | test_INT013_withdrawBelowMinAfterRATDeduction_reverts | Revert on withdrawal below minimum after RAT deduction |

### Minimum Collateral Query Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_activeValidator | Query minimum collateral for active validator |
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_inactiveValidator | Query minimum collateral for inactive validator |
| INT-014 | test_INT014_getValidatorMinCollateralForLayer2_nonValidator | Query minimum collateral for non-validator |

---

## MultiL2SeigniorageDistribution.t.sol (6 tests)

### Distribution Formula Verification

| ID | Test Function | Description |
|----|--------------|-------------|
| E2E-031 | test_E2E031_hyperbolicSaturation_formula | Verify hyperbolic saturation formula |
| SD-012 | test_SD012_sequencerReward_formula | Sequencer reward formula: (1-α) × y |
| SD-001 | test_SD001_v3Migration_state | Verify V3 migration state |
| SD-002 | test_SD002_v3Parameters_verification | Verify V3 parameters |

### Claim Constraint Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SD-017 | test_SD017_claimOnlyInSameBlock | Can only claim in the same block |
| SD-018 | test_SD018_distributionAllowed_differentBlock | Distribution allowed in different block |

---

## SeigniorageAccuracy.t.sol (21 tests)

### Block-by-Block Accuracy Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_singleBlock | Single block accuracy |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_multipleBlocks | Multiple block accuracy |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_withEligibleL2 | Include eligible L2 |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_cumulative | Cumulative accuracy |
| SM-016 | testFuzz_SM016_v3_updateSeigniorage_exactAmountByBlocks | Fuzz: Block-by-block accuracy |
| SM-016 | test_SM016_v3_updateSeigniorage_exactAmountByBlocks_largeSpan | Large block span |
| SM-016 | test_SM016_v3_updateSeigniorage_zeroSpan_claimOnly | Claim only when span=0 |

### Formula Verification Examples

| ID | Test Function | Description |
|----|--------------|-------------|
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

### Multi-L2 Scenarios

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-016 | test_SM016_v3_MULTI1_twoL2s_differentCallTimes | Two L2s with different call times |
| SM-016 | test_SM016_v3_MULTI2_totalMintedEqualsExpected | Verify total minted amount |
| SM-016 | test_SM016_v3_MULTI3_fourL2s_staggeredCalls | Four L2s with staggered calls |
| SM-016 | test_SM016_v3_MULTI4_rewardPerUnitAccumulation | rewardPerUnit accumulation |

---

## SeigManagerPausable.t.sol (19 tests)

### Pause/Unpause Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-050 | test_SM050_pause_success | Pauser successfully pauses (V3: pausedBlock = block.number + 1) |
| SM-051 | test_SM051_pause_notPauser_reverts | Revert when non-pauser calls |
| SM-052 | test_SM052_pause_alreadyPaused_reverts | Revert when calling on already paused state |
| SM-053 | test_SM053_pause_autoSeigniorageDistribution | V3: Automatic seigniorage issuance on pause allows consecutive pauses |
| SM-054 | test_SM054_unpause_success | Pauser successfully unpauses |
| SM-055 | test_SM055_unpause_notPauser_reverts | Revert when non-pauser calls |
| SM-056 | test_SM056_unpause_notPaused_reverts | Revert when calling on non-paused state |

### Exclude/Include L2 Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-057 | test_SM057_excludeFromL2Seigniorage_success | Layer2Manager successfully excludes L2 (effectiveBridgedTON=0) |
| SM-058 | test_SM058_excludeFromL2Seigniorage_notLayer2Manager_reverts | Revert when non-Layer2Manager calls |
| SM-059 | test_SM059_excludeFromL2Seigniorage_alreadyExcluded_reverts | Revert when excluding already excluded L2 |
| SM-060 | test_SM060_includeFromL2Seigniorage_success | Layer2Manager successfully includes L2 |
| SM-061 | test_SM061_includeFromL2Seigniorage_notLayer2Manager_reverts | Revert when non-Layer2Manager calls |
| SM-062 | test_SM062_includeFromL2Seigniorage_notExcluded_reverts | Revert when including non-excluded L2 |

### Distribution and Claim Tests in Paused State

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-063 | test_SM063_updateSeigniorage_whenPaused_earlyReturn | Early return when calling updateSeigniorage in paused state |
| SM-064 | test_SM064_claimL2Seigniorage_success | Successful claimL2Seigniorage (prevent duplicate claims) |
| SM-065 | test_SM065_claimL2Seigniorage_whenPaused_success | claimL2Seigniorage possible in paused state |
| SM-066 | test_SM066_claimL2Seigniorage_notMigrated_reverts | Check claimL2Seigniorage before V3 migration |
| SM-067 | test_SM067_claimL2Seigniorage_ineligible_returnsZero | Return 0 when ineligible L2 claims |
| SM-068 | test_SM068_claimL2Seigniorage_excluded_returnsZero | Return 0 when excluded L2 claims |

---

## EligibilityTransition.t.sol (13 tests)

### Eligibility Transition Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-040 | test_INT040_autoClaimBeforeEligibilityLoss | Auto-claim unclaimed rewards on eligibility loss |
| INT-041 | test_INT041_separatedRewardPerUnitTracking | Separate tracking of sequencer/validator rewardPerUnit |
| INT-042 | test_INT042_initialDebtResetOnReeligibility | Verify initialDebt reset on re-eligibility |
| INT-043 | test_INT043_fullEligibilityTransitionFlow | Full flow: gain eligibility→rewards→loss(auto-claim)→regain→rewards |
| INT-044 | test_INT044_autoClaimEventEmitted | Verify AutoClaimBeforeEligibilityLoss event |

### Eligibility Transition in Paused State

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-045 | test_INT045_pausedState_eligibilityLoss_claimUnclaimedRewards | Verify unclaimed rewards claim on eligibility loss in global paused state |
| INT-046 | test_INT046_pausedState_eligibilityGain_setsEffectiveBridgedTON | Verify effectiveBridgedTON setting on eligibility gain in global paused state |

### Seigniorage Distribution on Eligibility Transition

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-047 | test_INT047_eligibilityLoss_triggersSeigDistribution | Trigger seigniorage distribution on eligibility loss |
| INT-048 | test_INT048_eligibilityGain_triggersSeigDistribution | Trigger seigniorage distribution on eligibility gain |

### Seigniorage Estimation and Claimable Query

| ID | Test Function | Description |
|----|--------------|-------------|
| INT-049 | test_INT049_estimateL2Seigniorage_accuracy | L2 seigniorage estimation accuracy |
| INT-050 | test_INT050_estimateL2Seigniorage_withAccumulatedRewards | Estimation including accumulated rewards |
| INT-051 | test_INT051_claimableL2Seigniorage_returnsSequencerRewardOnly | Return sequencer reward only |
| INT-052 | test_INT052_claimableL2Seigniorage_includesAccumulatedRewards | Include accumulated rewards |

---

## SecurityPermissions.t.sol (25 tests)

### Owner-only Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-001 | test_SEC001_onlyOwner_seigManager | SeigManager owner-only functions |
| SEC-001 | test_SEC001_onlyOwner_rat | RAT owner-only functions |
| SEC-001 | test_SEC001_onlyOwner_success | Owner call success |

### RAT-only Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-002 | test_SEC002_onlyRAT_transferCoinageToRat | RAT-only: transferCoinageToRat |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageFromRat | RAT-only: transferCoinageFromRat |
| SEC-002 | test_SEC002_onlyRAT_transferCoinageFromRatTo | RAT-only: transferCoinageFromRatTo |
| SEC-002 | test_SEC002_onlyRAT_success | RAT call success |

### DepositManager-only Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-003 | test_SEC003_onlyDepositManager_onDeposit | DepositManager-only: onDeposit |
| SEC-003 | test_SEC003_onlyDepositManager_onWithdraw | DepositManager-only: onWithdraw |
| SEC-003 | test_SEC003_onlyDepositManager_onStakingChange | DepositManager-only: onStakingChange |

### ValidFactory-only Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-004 | test_SEC004_onlyValidFactory_triggerAttentionTest | ValidFactory-only: triggerAttentionTest |
| SEC-004 | test_SEC004_validFactory_success | ValidFactory call success |

### L1Bridge/Registry-only Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-005 | test_SEC005_onlyL1BridgeOrRegistry_onBridgedTonChange | L1Bridge/Registry-only |
| SEC-005 | test_SEC005_onlyL1BridgeOrRegistry_validPortal_success | Valid Portal call success |

### Security Pattern Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-011 | test_SEC011_CEI_pattern | Checks-Effects-Interactions pattern |
| SEC-020 | test_SEC020_randomness_uses_L1_values | Randomness using L1 values |

### Zero Address Validation

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-030 | test_SEC030_zeroAddress_setRatContract | Zero address: setRatContract |
| SEC-030 | test_SEC030_zeroAddress_setValidatorReward | Zero address: setValidatorReward |
| SEC-030 | test_SEC030_zeroAddress_transferOwnership | Zero address: transferOwnership |

### Parameter Range Validation

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-031 | test_SEC031_parameterRange_daoDistributionRatio | Parameter range: daoDistributionRatio |
| SEC-031 | test_SEC031_parameterRange_validatorDistributionRatio | Parameter range: validatorDistributionRatio |
| SEC-031 | test_SEC031_parameterRange_minStakingRatio | Parameter range: minStakingRatio |
| SEC-031 | test_SEC031_parameterRange_ratTriggerProbability | Parameter range: ratTriggerProbability |

### Edge Case Handling

| ID | Test Function | Description |
|----|--------------|-------------|
| SEC-032 | test_SEC032_emptyArrayHandling | Empty array handling |
| SEC-032 | test_SEC032_maxValidatorLimit | Maximum validator limit |

---

## Next Steps

- [V2 Mode Tests](v2-mode-tests.md) - V2 mode basic functionality tests
- [Scenario Tests](scenario-tests.md) - Full workflow tests
- [Back to Overview](overview.md)
