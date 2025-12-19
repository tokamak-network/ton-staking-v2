# Test Coverage Matrix

## Feature Coverage Status

### V3 Core Features

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| Layer2 Registration | BasicFunctions.t.sol | ✅ Complete | 2 |
| Coinage Deployment | BasicFunctions.t.sol | ✅ Complete | 1 |
| WTON Deposit | BasicFunctions.t.sol | ✅ Complete | 2 |
| TON approveAndCall Deposit | BasicFunctions.t.sol | ✅ Complete | 1 |
| Withdrawal Request | BasicFunctions.t.sol | ✅ Complete | 2 |
| Withdrawal Processing | BasicFunctions.t.sol | ✅ Complete | 2 |
| Withdrawal Delay Enforcement | DepositManagerV1_2Real.t.sol | ✅ Complete | 5 |
| updateSeigniorage (Layer2 callback) | BasicFunctions.t.sol | ✅ Complete | 1 |
| updateSeigniorageLayer | BasicFunctions.t.sol | ✅ Complete | 1 |
| Full Staking Scenario | BasicFunctions.t.sol | ✅ Complete | 1 |

### V3 Seigniorage Distribution

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| V2 Mode (λ=1, r=0.4) | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| V3 Mode (λ=0, r=0) | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| λ Transition (100%→0%) | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| r Transition (40%→0%) | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| Multi-L2 Distribution | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| L2 Eligibility (θ threshold) | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| Slashed L2 Exclusion | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| All L2 Slashed (x=0) → DAO | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| Consecutive Updates | EndToEndSeigniorage.t.sol | ✅ Complete | 1 |
| Hyperbolic Saturation | SeigManagerV1_4Real.t.sol | ✅ Complete | 10+ |
| Half Saturation Point | SeigManagerV1_4Real.t.sol | ✅ Complete | 1 |

### V4 Validator Collateral (RAT)

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| Minimum Collateral Formula | RAT.t.sol | ✅ Complete | 1 |
| Validator Registration | RAT.t.sol | ✅ Complete | 5 |
| Multi-L2 Validator | RAT.t.sol | ✅ Complete | 1 |
| Add Additional Collateral | RAT.t.sol | ✅ Complete | 2 |
| Validator Deactivation | RAT.t.sol | ✅ Complete | 1 |
| RAT Trigger (Pre-deduct) | RAT.t.sol | ✅ Complete | 3 |
| Evidence Submission | RAT.t.sol | ✅ Complete | 3 |
| Lazy Evaluation (No Response) | RAT.t.sol | ✅ Complete | 3 |
| Below Threshold Auto-deactivate | RAT.t.sol | ✅ Complete | 1 |
| Game Resolution (Win) | RAT.t.sol | ✅ Complete | 4 |
| Multi-Game Concurrent | RAT.t.sol | ✅ Complete | 2 |
| Governance Parameters | RAT.t.sol | ✅ Complete | 6 |
| Treasury Withdrawal | RAT.t.sol | ✅ Complete | 1 |
| Validator Recovery | RAT.t.sol | ✅ Complete | 2 |

### V3 Scenario Tests

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| V3 Full Deployment | V3ScenarioReal.t.sol | ✅ Complete | 1 |
| V3 Migration | V3ScenarioReal.t.sol | ✅ Complete | 1 |
| TYPE 3 Rollup Registration | V3ScenarioReal.t.sol | ✅ Complete | 1 |
| Sequencer Collateral Deposit | V3ScenarioReal.t.sol | ✅ Complete | 1 |
| Validator Deposit to RAT | V3ScenarioReal.t.sol | ✅ Complete | 1 |
| V3 Seigniorage Update | V3ScenarioReal.t.sol | ✅ Complete | 1 |
| Validator Slashing | V3ScenarioReal.t.sol | ✅ Complete | 1 |
| Full V3 E2E Scenario | V3ScenarioReal.t.sol | ✅ Complete | 1 |

### Bridge Integration

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| L1BridgeRegistry Connection | Layer2ManagerV1_2Real.t.sol | ✅ Complete | 1 |
| DisputeGameFactory Default | L1BridgeRegistryV1_2Real.t.sol | ✅ Complete | 1 |
| Rollup Config Mapping | L1BridgeRegistryV1_2Real.t.sol | ✅ Complete | 1 |
| Bridged TON Query | Layer2ManagerV1_2Real.t.sol | ⚠️ Basic | 2 |
| Layer2 by SystemConfig | Layer2ManagerV1_2Real.t.sol | ⚠️ Basic | 1 |

### ValidatorReward Distribution

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| Per-L2 Reward Distribution | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Multiple Validators Distribution | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| No Validators → Treasury | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Exclude Inactive Validators | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Multiple L2s Distribution | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Zero Amount Handling | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Only SeigManager Access | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Reward Accumulation | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Remainder Handling | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Claim All Rewards | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Claim No Rewards Revert | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Claim Multiple L2s | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Claim-Distribute-Claim | ValidatorRewardV1.t.sol | ✅ Complete | 1 |
| Pending Rewards Query | ValidatorRewardV1.t.sol | ✅ Complete | 2 |
| Reward Formula Verification | ValidatorRewardV1.t.sol | ✅ Complete | 2 |
| Initialization | ValidatorRewardV1.t.sol | ✅ Complete | 2 |
| Governance Functions | ValidatorRewardV1.t.sol | ✅ Complete | 8 |
| Emergency Withdraw | ValidatorRewardV1.t.sol | ✅ Complete | 2 |
| Event Emissions | ValidatorRewardV1.t.sol | ✅ Complete | 4 |

### Manager Functions

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| DepositManager Initialize | DepositManagerV1_2Real.t.sol | ✅ Complete | 2 |
| Global Withdrawal Delay | DepositManagerV1_2Real.t.sol | ✅ Complete | 3 |
| Layer2 Withdrawal Delay | DepositManagerV1_2Real.t.sol | ✅ Complete | 2 |
| SeigManager Initialize | SeigManagerV1_4Real.t.sol | ✅ Complete | 2 |
| ValidatorReward Connection | SeigManagerV1_4Real.t.sol | ✅ Complete | 1 |
| Slashing Parameters | SeigManagerV1_4Real.t.sol | ✅ Complete | 2 |
| SequencerVault Setting | SeigManagerV1_4Real.t.sol | ✅ Complete | 2 |

### Deployment & Upgrade

| Feature | Test File | Status | Tests |
|---------|-----------|--------|-------|
| Implementation Deploy | DeployV3Fork.t.sol | ✅ Complete | 1 |
| V3 Contract Deploy | DeployV3Fork.t.sol | ✅ Complete | 1 |
| Proxy Upgrade | DeployV3Fork.t.sol | ✅ Complete | 1 |
| Full Deployment Flow | DeployV3Fork.t.sol | ✅ Complete | 1 |
| State Preservation | DeployV3Fork.t.sol | ✅ Complete | 1 |
| Mainnet State Check | DeployV3Fork.t.sol | ✅ Complete | 1 |

## Coverage Summary

### By Category

| Category | Total Tests | Passed | Status |
|----------|-------------|--------|--------|
| Core Staking | 12 | 12 | ✅ 100% |
| Seigniorage Distribution | 50+ | 50+ | ✅ 100% |
| Validator Collateral (RAT) | 40+ | 40+ | ✅ 100% |
| ValidatorReward Distribution | 33 | 33 | ✅ 100% |
| V3 Scenarios | 8 | 8 | ✅ 100% |
| Manager Functions | 24+ | 24+ | ✅ 100% |
| Bridge Integration | 6 | 6 | ⚠️ Basic |
| Deployment | 6 | 6 | ✅ 100% |

### By Contract

| Contract | Tests | Coverage |
|----------|-------|----------|
| SeigManagerV1_4 | 34 | High |
| DepositManagerV1_2 | 14 | High |
| RAT | 40+ | Excellent |
| ValidatorRewardV1 | 33 | ✅ Excellent |
| Layer2Registry | 2 | Good |
| Layer2Manager | 6 | Medium |
| L1BridgeRegistry | 2 | Low |
| SequencerVault | 2 | Low |

## Test Statistics

```
Total Test Files:        12
Total Tests:            175+
Passing Tests:          175+
Failing Tests:          0
Skipped Tests:          1

Fuzz Tests:             3
Unit Tests:            133+
Integration Tests:      30+
E2E Tests:             12+
```

## Command to Verify

```bash
# Run all tests and get count
forge test --match-path "test/v3/*.sol" --summary

# Expected output:
# Ran 176 tests for 12 test suites
# 175 passed, 0 failed, 1 skipped
```
