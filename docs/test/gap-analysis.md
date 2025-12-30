# Test Gap Analysis

## Executive Summary

The V3/V4 test suite provides comprehensive coverage for core staking, seigniorage distribution, and validator collateral (RAT) functionality. However, several areas require additional testing.

## Current Coverage Status

| Area | Status | Priority |
|------|--------|----------|
| Core Staking | ✅ Complete | - |
| Seigniorage Distribution | ✅ Complete | - |
| Validator Collateral (RAT) | ✅ Complete | - |
| V3 Scenarios | ✅ Complete | - |
| ValidatorReward Distribution | ✅ Complete | - |
| Bridge Integration | ⚠️ Basic | Medium |
| Emergency Scenarios | ⚠️ Partial | Medium |
| Access Control | ⚠️ Basic | Low |

## Identified Gaps

### 1. ValidatorReward Distribution (Priority: ~~High~~ Complete)

**Current Status**: ✅ **COMPLETED** - 33 unit tests added in `test/v3/ValidatorRewardV1.t.sol`

**Implemented Tests**:
- `test_distributeL2Rewards_basic` - Per-L2 reward distribution
- `test_distributeL2Rewards_multipleValidators` - Fair distribution among validators
- `test_distributeL2Rewards_noValidators_toTreasury` - Treasury fallback
- `test_distributeL2Rewards_excludeInactiveValidators` - Active validator filtering
- `test_distributeL2Rewards_multipleL2s` - Multiple L2 support
- `test_claimAllRewards_success` - Validator claims accumulated rewards
- `test_claimAllRewards_multipleL2s` - Batch claiming across L2s
- `test_getPendingRewards_accurate` - Query pending rewards
- `test_getPendingRewardsByL2_accurate` - Per-L2 pending rewards
- `test_rewardCalculation_formula` - Verify formula: v_j = (α·S_i) / |V_i|
- `test_rewardCalculation_precision` - Small amount precision
- Governance tests (setRatContract, setTreasury, setSeigManager, transferOwnership)
- Emergency withdraw tests
- Event emission tests (L2RewardDistributed, ValidatorRewardReceived, RewardsClaimed)

### 2. L1BridgeRegistry V1_2 (Priority: Medium)

**Current Status**: Only 2 basic tests exist. L1BridgeRegistryV1_2 now contains all functions (V1_1 + TYPE 3 support).

**Missing Tests**:
- TYPE 1, 2, 3 registration via `registerRollupConfigType1/2/3`
- `upgradeToType3` function (TYPE 2 → TYPE 3 upgrade)
- `setTypeRegistrant` permission delegation
- `rejectCandidateAddOn` / `restoreCandidateAddOn`
- `availableForRegistration` validation
- View functions: `rollupType`, `l2TON`, `getRollupInfo`, `isRejectedSeigs`, `isRejectedL2Deposit`
- Permission checks (onlyOwner, onlyRegistrant, onlySeigniorageCommittee, typeRegistrant)

**Recommendation**: Expand `L1BridgeRegistryV1_2Real.t.sol`.

### 3. Bridge Integration (Priority: Medium)

**Current Status**: Only 6 basic connectivity tests exist.

**Missing Tests**:
- L1Bridge deposit/withdrawal flow
- SystemConfig integration
- Cross-chain message handling
- Bridge pause/unpause scenarios

**Recommendation**: Expand `Layer2ManagerV1_2Real.t.sol`.

### 4. Emergency Scenarios (Priority: Medium)

**Current Status**: Partial - Emergency tests require complex coinage/tot setup in test environment.

**Challenge**: SeigManager pause requires:
- PAUSE_ROLE granted to caller
- `_pausedBlock < _lastSeigBlock` (updateSeigniorage must be called first)
- Tot coinage initialization

**Missing Tests**:
- `test_pauseSeigManager` - Pause seigniorage
- `test_unpauseSeigManager` - Resume after pause
- `test_pauseDuringDistribution` - Mid-distribution pause
- `test_emergencyWithdrawal` - User funds during emergency
- `test_pauseRAT` - Pause validator operations

**Recommendation**: Create `test/v3/EmergencyScenarios.t.sol` using mainnet fork to inherit coinage setup.

### 5. Access Control (Priority: Low)

**Current Status**: Basic owner checks exist, but comprehensive RBAC testing is missing.

**Missing Tests**:
- Role-based function access
- Multi-sig scenarios
- Permission delegation
- Access revocation

## Feature Combinations Not Tested

### High Priority

| Scenario | Components | Risk |
|----------|------------|------|
| Validator + Sequencer | RAT + SequencerVault | Medium |
| Multi-L2 RAT | RAT across 5+ L2s | Medium |
| Concurrent Games | 10+ games simultaneously | Low |

### Medium Priority

| Scenario | Components | Risk |
|----------|------------|------|
| Recovery After Slashing | RAT → Slash → Recovery → Rewards | Medium |
| Parameter Change Live | Change λ/r during distribution | Low |
| Large Validator Count | 100+ validators | Low |

## Stress Test Gaps

Currently no stress/load tests exist for:

1. **High Volume**
   - 1000+ deposits in sequence
   - 100+ validators per L2
   - 50+ concurrent RAT games

2. **Edge Cases**
   - Maximum uint256 values
   - Zero-value transactions
   - Boundary conditions

3. **Gas Optimization**
   - Gas usage regression tests
   - Batch operation gas limits

## Recommended Test Files to Create

### Priority 1 (Required) - ✅ COMPLETED

```
test/v3/ValidatorRewardV1.t.sol       # 33 tests ✅
```

### Priority 2 (Recommended)

```
test/v3/EmergencyScenarios.t.sol      # 10+ tests (requires fork)
test/v3/BridgeIntegration.t.sol       # 15+ tests
```

### Priority 3 (Nice to Have)

```
test/v3/StressTests.t.sol             # 10+ tests
test/v3/AccessControl.t.sol           # 10+ tests
test/v3/EdgeCases.t.sol               # 15+ tests
```

## Test Implementation Checklist

### ValidatorReward Tests (✅ COMPLETED)

- [x] `test_distributeL2Rewards_basic`
- [x] `test_distributeL2Rewards_multipleValidators`
- [x] `test_distributeL2Rewards_noValidators_toTreasury`
- [x] `test_distributeL2Rewards_excludeInactiveValidators`
- [x] `test_distributeL2Rewards_multipleL2s`
- [x] `test_distributeL2Rewards_zeroAmount`
- [x] `test_distributeL2Rewards_onlySeigManager`
- [x] `test_distributeL2Rewards_accumulation`
- [x] `test_distributeL2Rewards_remainder`
- [x] `test_claimAllRewards_success`
- [x] `test_claimAllRewards_noRewards_reverts`
- [x] `test_claimAllRewards_multipleL2s`
- [x] `test_claimAllRewards_claimDistributeClaim`
- [x] `test_getPendingRewards_accurate`
- [x] `test_getPendingRewardsByL2_accurate`
- [x] `test_rewardCalculation_formula`
- [x] `test_rewardCalculation_precision`
- [x] `test_initialize_success`
- [x] `test_initialize_cannotReinitialize`
- [x] `test_setRatContract` / `test_setRatContract_zeroAddress_reverts`
- [x] `test_setTreasury`
- [x] `test_setSeigManager` / `test_setSeigManager_zeroAddress_reverts`
- [x] `test_transferOwnership` / `test_transferOwnership_zeroAddress_reverts`
- [x] `test_governance_onlyOwner`
- [x] `test_emergencyWithdraw` / `test_emergencyWithdraw_onlyOwner`
- [x] `test_event_L2RewardDistributed`
- [x] `test_event_ValidatorRewardReceived`
- [x] `test_event_RewardsClaimed`
- [x] `test_event_RewardToTreasury`

### Emergency Tests (TODO)

- [ ] `test_pause_stopsDeposits`
- [ ] `test_pause_stopsWithdrawals`
- [ ] `test_pause_stopsSeigniorage`
- [ ] `test_unpause_resumesOperations`
- [ ] `test_pause_onlyOwner`
- [ ] `test_emergencyWithdraw_duringPause`
- [ ] `test_pause_preservesState`
- [ ] `test_pause_RATOperations`

## Conclusion

The current test suite provides **solid coverage** for V3/V4 core functionality:

- ✅ 175+ tests passing (142 existing + 33 new ValidatorReward tests)
- ✅ Core staking fully tested
- ✅ RAT validator collateral fully tested
- ✅ Seigniorage distribution fully tested
- ✅ ValidatorReward distribution fully tested

**Completed**:
1. ~~Create ValidatorReward unit tests (Priority 1)~~ ✅ Done - 33 tests

**Next Steps**:
1. Add emergency scenario tests using mainnet fork (Priority 2)
2. Expand bridge integration tests (Priority 2)

---

## Go E2E Tests (op-e2e)

### Current Status

Go 기반 E2E 테스트가 `op-e2e/` 디렉토리에 추가되었습니다.

| Category | Tests | Status |
|----------|-------|--------|
| Unit Tests | 2 | ✅ Pass |
| Integration Tests | 5 | ⏸️ Skip (requires devnet) |
| E2E Tests | 9 | ⏸️ Skip (requires Optimism devnet) |

### Test Coverage

- RAT helper utility functions
- RAT constants verification
- Validator registration flow
- DisputeGame creation → RAT trigger
- Evidence submission and slashing
- Multi-L2 chain identification

### Running Tests

```bash
cd op-e2e && make test-rat-unit        # Unit tests
cd op-e2e && make test-rat-integration # Integration tests
cd op-e2e && make test                 # All tests
```
