# 6. Testing Guide

## Testing Summary

| Category | Framework | Number of Tests | Execution Time | Environment |
|----------|-----------|-----------------|----------------|-------------|
| Foundry AdvancedSlashing | Solidity (forge) | 24 | A few seconds | Local |
| Foundry BasicSlashing | Solidity (forge) | 38 | A few seconds | Local |
| E2E Slashing (Mock) | Go test | 41 | ~2 minutes | Anvil (L1 only) |
| E2E Real Challenger | Go test | 11 | ~90s / test | Full Optimism devnet |

---

## 1. Foundry Unit Tests (Solidity)

### How to Run

```bash
# From the project root

# AdvancedSlashing tests (24)
forge test --match-path "test/v3/v3mode/AdvancedSlashing/*.t.sol" -v

# BasicSlashing tests (38)
forge test --match-path "test/v3/v3mode/BasicSlashing/*.t.sol" -v

# Specific test file
forge test --match-contract SingleChallengerTest -vvv

# Specific test function
forge test --match-test test_TwoChallengers_50_50_Split -vvv
```

### AdvancedSlashing Test Structure

```text
test/v3/v3mode/AdvancedSlashing/
├── BaseAdvancedSlashingTest.sol              # Base test (common helpers)
├── SingleChallengerTest.t.sol                # Single challenger (4)
├── MultiChallengerEqualDistributionTest.t.sol # Equal distribution (5)
├── WinnerTrackingTest.t.sol                  # Winner tracking (5)
├── RemainderDistributionTest.t.sol           # Remainder distribution (5)
└── RealisticGameFlowTest.t.sol               # Realistic game flow (5)
```

### Main Test Cases

| File | Test | Verification Scope |
|------|------|--------------------|
| SingleChallenger | `test_SingleChallenger_ReceivesFullReward` | Single challenger receives 100% |
| MultiChallenger | `test_TwoChallengers_50_50_Split` | 50:50 distribution across 2 people |
| MultiChallenger | `test_ThreeChallengers_EqualSplit` | Equal distribution across 3 + remainder |
| WinnerTracking | `test_WinnerTracking_GameCreatorExcluded` | Exclude Proposer from winner list |
| WinnerTracking | `test_WinnerTracking_NoDuplicates` | Prevent duplicate registration |
| Remainder | `test_Remainder_ExactDivision` | Case with 0 remainder |
| RealisticGame | `test_MultipleBranches_TwoWinningChallengers` | 2 winners on independent attacks |
| RealisticGame | `test_GameWithStep_ProveWrongClaim` | Defender wins through step proof |

### BasicSlashing Tests (38)

| File | Number of Tests |
|------|-----------------|
| SlashingBasicTest.t.sol | 3 |
| SlashingSecurityTest.t.sol | 4 |
| SlashingDelegatorTest.t.sol | 4 |
| SlashingEdgeCaseTest.t.sol | 5 |
| SlashingAttackVectorTest.t.sol | 11 |
| SlashingRewardRateTest.t.sol | 4 |
| SlashingSeigniorageTest.t.sol | 3 |
| SlashingMultiOperatorTest.t.sol | 4 |

---

## 2. E2E Slashing Tests (Go, Anvil-based, 41)

### Prerequisites

```bash
cd /path/to/ton-staking-v2
make devnet-allocs-offline   # Generate Genesis file (initial once)
```

### How to Run

```bash
cd op-e2e

# Run all (Recommended)
make test-slashing-all

# Execute by category
make test-slashing-integration   # Slashing Integration (4)
make test-reward-distribution    # Reward Distribution (6)
make test-edge-cases             # Edge Cases (6)
make test-delegator-protection   # Delegator Protection (4)
make test-complex-scenarios      # Complex Scenarios (5)
make test-permission-security    # Permission/Security (7)
make test-real-challenger        # Real Challenger (3)
make test-multi-challenger       # Multi-Challenger (6)
```

### Test File Structure

```text
op-e2e/slashing/
├── slashing_helpers.go              # Common helpers
├── real_game_helpers.go             # Full Optimism + TON helpers
├── slashing_test.go                 # Basic slashing (3)
├── slashing_challenger_test.go      # Real Challenger (5)
├── multi_challenger_test.go         # Multi-Challenger (6)
├── slashing_integration_test.go     # Slashing integration (4)
├── reward_distribution_test.go      # Reward distribution (6)
├── edge_cases_test.go               # Edge Cases (6)
├── delegator_protection_test.go     # Delegator protection (4)
├── complex_scenarios_test.go        # Complex Scenarios (5)
└── permission_security_test.go      # Permission/Security (7)
```

### Key Tests (By Category)

**Slashing Integration**:
- `TestSlashingIntegration_MultiChallengerWithRealSlashing` - Full integration of multiple challengers
- `TestSlashingIntegration_CannotSlashTwice` - Prevent duplicate slashing

**Reward Distribution**:
- `TestRewardDistribution_ThreeChallengersEqualSplit` - Equal distribution across 3 + remainder
- `TestRewardDistribution_RemainderHandling` - First person receives remainder

**Edge Cases**:
- `TestEdgeCase_DefenderWinsCannotSlash` - Cannot slash if DEFENDER_WINS
- `TestEdgeCase_InvalidGameAddress` - Non-existent game address

**Delegator Protection**:
- `TestDelegatorProtection_StakeNotSlashed` - Protect Delegator upon Operator slashing

**Permission/Security**:
- `TestSecurity_DoubleSlashingSameGame` - Prevent duplicate slashing in the same game
- `TestSecurity_GameAddressManipulation` - Prevent rootClaim/gameAddress mismatch manipulation

---

## 3. Real op-challenger Integration Tests (Go, Full Devnet, 11)

### Prerequisites

```bash
cd /path/to/ton-staking-v2
make devnet-allocs-offline

# Kona prestate (Alphabet tests work with a dummy file)
mkdir -p lib/optimism/kona/bin
echo '{"pre": "0x0", "post": "0x0"}' > lib/optimism/kona/bin/prestate.json

# Docker Desktop needs to be running
docker ps
```

### How to Run

```bash
cd lib/optimism

# All Alphabet tests
go test -v -timeout 15m -run "TestOutputAlphabetGame_" ./op-e2e/faultproofs/...

# Specific test
go test -v -timeout 10m -run "TestOutputAlphabetGame_ChallengerWins" ./op-e2e/faultproofs/...

# Exhaustive test (Up to Max Depth)
go test -v -timeout 30m -run "TestChallengerCompleteExhaustiveDisputeGame" ./op-e2e/faultproofs/...
```

### Test List

| Test | Description | Time |
|------|-------------|------|
| `TestOutputAlphabetGame_ChallengerWins` | Challenger wins | ~95s |
| `TestOutputAlphabetGame_ReclaimBond` | Bond recovery | ~41s |
| `TestOutputAlphabetGame_ValidOutputRoot` | Defender wins | ~89s |
| `TestOutputAlphabetGame_FreeloaderEarnsNothing` | Freeloader earns no reward | ~105s |
| `TestChallengerCompleteExhaustiveDisputeGame` | Max Depth complete | ~180s |

### Mock vs Real Comparison

| Criterion | test-slashing-all (Mock) | test-real-challenger (Real) |
|-----------|--------------------------|-----------------------------|
| Contracts | Real FaultDisputeGame.sol | Real FaultDisputeGame.sol |
| Infrastructure | Anvil (L1 only) | Full Optimism devnet |
| Challenger | Manual execution | Real op-challenger service |
| Test Count | 41 | 11 |
| Execution Time | ~2 mins for all | ~90s / test |
| Usage | CI/CD, fast feedback | Operating environment validation |

---

## Go Workspace Issues

- Tests relying on the `lib/optimism` package within E2E tests require `op-e2e/go.work`
- Mock-based tests should be executed with `GOWORK=off`
- Skip prestate builds via the `DISABLE_OP_E2E_LEGACY=true` environment variable

---

Next: [07-issues.md](./07-issues.md)
