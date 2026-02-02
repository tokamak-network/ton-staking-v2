---
id: v2-mode-tests
title: V2 Mode Tests
sidebar_position: 2
---

# V2 Mode Tests (44 tests)

Tests covering V2 mode basic functionality and V2↔V3 mode switching.

## V2Functions.t.sol (16 tests)

### Seigniorage Distribution Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-001 | test_SM001_v2_updateSeigniorage_linearDistribution | V2 linear distribution: 2x blocks → 2x seigniorage |
| SM-002 | test_SM002_v2_updateSeigniorage_coinageStakingSeigniorage | Operator/Staker coinage factor increase auto-increases balance |
| SM-003 | test_SM003_v2_updateSeigniorage_layer2SequencerSeigniorage | Direct WTON transfer to OperatorManager verification |
| SM-004 | test_SM004_v2_updateSeigniorage_ignoresV3Parameters | V3 parameters (θ,α,k,d) don't affect V2 distribution |
| SM-010 | test_SM010_v2_seigniorage_onlyMinimumAmount | Distribute seigniorage when only minimumAmount is met |
| SM-011 | test_SM011_v2_seigniorage_ignoresMinStakingRatio | Ignore θ(minStakingRatio) verification |
| SM-012 | test_SM012_v2_seigniorage_noEffectiveBridgedTON | effectiveBridgedTON not used (V3 only) |

### V2 View Function Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-020-V2 | test_SM020_v2_estimatedDistributeV2 | Query V2 estimated seigniorage distribution |
| SM-021-V2 | test_SM021_v2_claimableL2SeigniorageV2 | Query V2 claimable seigniorage |
| SM-022-V2 | test_SM022_v2_estimatedDistributeV2_unregisteredLayer2 | Unregistered Layer2 → layer2Seigs=0 |
| SM-023-V2 | test_SM023_v2_estimatedDistributeV2_blockCondition | Below lastSeigBlock → return 0 |
| SM-024-V2 | test_SM024_v2_negativeCommissionRate_concept | Negative commission rate concept test |

### V2 Deposit/Withdrawal Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| DM-001 | test_DM001_v2_deposit_basicFlow | V2 basic deposit operation |
| DM-002 | test_DM002_v2_deposit_noV3Callback | No onStakingChange callback in V2 |
| DM-003 | test_DM003_v2_withdraw_basicFlow | V2 basic withdrawal operation |
| DM-004 | test_DM004_v2_withdraw_operatorVsValidator | Operator: minimumAmount limit / Validator: no limit |

---

## V2V3ModeSwitching.t.sol (28 tests)

### V2 Mode Function Call Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-020 | test_SM020_v2_hyperbolicSaturation_notUsed | Hyperbolic function callable in V2 but not used in distribution |
| SM-021 | test_SM021_v2_onBridgedTonChange_succeeds | Early return when called in V2 (no revert) |
| SM-022 | test_SM022_v2_transferCoinageToRat_revertInV2 | RAT transfer function reverts in V2 |
| RAT-V2-001 | test_RAT_v2_registerValidator_revertInV2 | NotMigratedError when registering validator in V2 |
| SM-023 | test_SM023_v2_onStakingChange_succeeds | Early return when called in V2 (no revert) |

### V2/V3 ValidatorReward Distribution Difference

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-024-V2 | test_SM024_v2_validatorReward_shouldNotDistribute | No ValidatorReward distribution in V2 |
| SM-024-V3-NoVal | test_SM024_v3_noValidators_goesToDAO | V3 with 0 validators: ValidatorReward → DAO |
| SM-024-V3-WithVal | test_SM024_v3_withValidators_staysInValidatorReward | V3 with 1+ validators: seigniorage stays in ValidatorReward |

### V2 Mode Parameter/Contract Settings

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-025 | test_SM025_v2_canSetV3Parameters | Can set V3 parameters in V2 (no effect on distribution) |
| SM-026 | test_SM026_v2_canSetV3Contracts | Can set V3 contracts in V2 (not used) |
| SM-027 | test_SM027_v2_checkCurrentEligibility_returnsZero | checkCurrentEligibility always returns false, 0 in V2 |
| SM-028 | test_SM028_v2_getEffectiveBridgedTon_returnsZero | effectiveBridgedTON always 0 in V2 |

### V2 Mode exclude/include Functions

| ID | Test Function | Description |
|----|--------------|-------------|
| SM-033 | test_SM033_v2_excludeFromL2Seigniorage_shouldRevertOrIgnore | excludeFromL2Seigniorage callable in V2 (no effect) |
| SM-034 | test_SM034_v2_includeFromL2Seigniorage_shouldRevertOrIgnore | includeFromL2Seigniorage reverts in V2 |
| SM-035 | test_SM035_afterMigration_pause_shouldWork | pause/unpause works after V2→V3 migration |
| SM-036 | test_SM036_afterMigration_excludeFromL2Seigniorage_shouldWork | excludeFromL2Seigniorage works after V2→V3 migration |
| SM-037 | test_SM037_afterMigration_includeFromL2Seigniorage_shouldWork | includeFromL2Seigniorage works after V2→V3 migration |
| SM-038 | test_SM038_v2_excludeThenInclude_shouldWork | V2 mode exclude→include full flow (verify seigniorage before/after) |
| SM-039 | test_SM039_v2ExcludeThenMigrateThenV3Include_shouldWork | V2 exclude → V3 migration → V3 include transition |

### Migration Tests

| ID | Test Function | Description |
|----|--------------|-------------|
| MIG-001 | test_MIG001_migration_stateChange | v3Migrated state change before/after migration |
| MIG-002 | test_MIG002_migration_duplicateReverts | AlreadyMigratedError on duplicate migration |
| MIG-003-Type3 | test_MIG003_type3_getEffectiveBridgedTon_shouldUpdate | Type 3: Portal call updates effectiveBridgedTON, eligible=true |
| MIG-003-Type2 | test_MIG003_type2_getEffectiveBridgedTon_shouldUpdate | Type 2: onBridgedTonChange not supported, eligible=false, requiredStake=0 |
| MIG-004-Type3 | test_MIG004_type3_afterMigration_v3Functions_shouldActivate | Type 3: checkCurrentEligibility eligible=true after V3 migration |
| MIG-004-Type2 | test_MIG004_type2_afterMigration_v3Functions_shouldActivate | Type 2: checkCurrentEligibility eligible=false after V3 migration |
| MIG-005-Type3 | test_MIG005_type3_afterMigration_onStakingChange_shouldWork | Type 3: deposit increases currentStake, eligible false→true |
| MIG-005-Type2 | test_MIG005_type2_afterMigration_onStakingChange_shouldWork | Type 2: deposit increases currentStake but eligible stays false |
| MIG-006 | test_MIG006_v3ToV2_downgradeNotPossible | V3→V2 downgrade not possible (permanent V3 mode) |

---

## Next Steps

- [V3 Mode Tests](v3-mode-tests.md) - V3 mode exclusive functionality tests
- [Scenario Tests](scenario-tests.md) - Full workflow tests
- [Back to Overview](overview.md)
