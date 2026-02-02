---
id: scenario-tests
title: Scenario Tests
sidebar_position: 4
---

# Scenario Tests (18 tests)

Full workflow and complex scenario tests.

## V3ScenarioReal.t.sol (8 tests)

### V3 Migration and Basic Scenarios

| ID | Test Function | Description |
|----|--------------|-------------|
| E2E-001 | test_E2E001_v3Migration | Full V3 migration flow |
| E2E-002 | test_E2E002_registerCandidateType3 | TYPE 3 candidate registration |
| E2E-003 | test_E2E003_validatorDepositToRAT | Validator deposit to RAT |
| E2E-004 | test_E2E004_multipleValidatorsDeposit | Multiple validator deposits |
| E2E-005 | test_E2E005_updateSeigniorageAfterMigration | Seigniorage update after migration |
| E2E-006 | test_E2E006_updateSeigniorageMultipleTimes | Multiple seigniorage updates |

### Validator Lifecycle Scenarios

| ID | Test Function | Description |
|----|--------------|-------------|
| E2E-012 | test_E2E012_validatorDeactivateAndReregister | Validator deactivation and re-registration |
| E2E-040 | test_E2E040_fullV3Scenario | Full V3 scenario |

---

## MigrationScenarios.t.sol (7 tests)

### Basic Migration Scenarios

| ID | Test Function | Description |
|----|--------------|-------------|
| MIG-001 | test_MIG001_migrateToV3_success | Migration success |
| MIG-002 | test_MIG002_migrateToV3_alreadyMigrated | Duplicate migration reverts |
| MIG-003 | test_MIG003_migrateToV3_recordBlock | Migration block recording |

### Post-Migration State Verification

| ID | Test Function | Description |
|----|--------------|-------------|
| MIG-010 | test_MIG010_migration_preservesStaking | Preserve existing staking |
| MIG-011 | test_MIG011_migration_parametersPreset | Parameter presets |
| MIG-012 | test_MIG012_migration_firstV3Distribution | First V3 distribution |
| MIG-013 | test_MIG013_migration_eligibilityReevaluation | Eligibility re-evaluation |

---

## SequencerJourney.t.sol (3 tests)

### Full Sequencer Journey

| ID | Test Function | Description |
|----|--------------|-------------|
| SCENSEQ-001 | test_SCENSEQ001_newSequencer_fullJourney | New sequencer full journey |
| SCENSEQ-002 | test_SCENSEQ002_sequencer_eligibilityTransition | Sequencer eligibility transition |
| SCENSEQ-003 | test_SCENSEQ003_sequencer_slashingRecovery | Sequencer slashing recovery |

**Coverage:**
- Sequencer registration
- Initial deposit and eligibility gain
- Seigniorage distribution and rewards
- Eligibility loss and regain
- Slashing events and recovery

---

## ValidatorJourney.t.sol (4 tests)

### Full Validator Journey

| ID | Test Function | Description |
|----|--------------|-------------|
| SCENVAL-001 | test_SCENVAL001_validator_rewardClaim_fullJourney | Validator reward claim full journey |
| SCENVAL-002 | test_SCENVAL002_validator_slashing_concept | Validator slashing concept |
| SCENVAL-003 | test_SCENVAL003_validator_reactivation_concept | Validator reactivation concept |
| SCENVAL-004 | test_SCENVAL004_validator_multiL2_rewards | Validator multi-L2 rewards |

**Coverage:**
- Validator registration and collateral deposit
- RAT trigger and evidence submission
- Reward distribution and claiming
- Slashing and recovery processes
- Multi-L2 participation scenarios
- Deactivation and reactivation

---

## Next Steps

- [Go E2E Tests](e2e-tests.md) - op-e2e integration tests
- [RAT Client Unit Tests](rat-client-unit-tests.md) - RAT Client Go tests
- [Back to Overview](overview.md)
