# Quick Test Commands Cheat Sheet

> 📋 Copy-paste commands for quick testing

## 🚀 Run Everything

```bash
# From project root
cd /Users/zena/tokamak-projects/ton-staking-v2

# All tests (Unit + Integration + E2E)
forge test && make devnet-allocs-offline && make test-e2e
```

---

## 🔬 Unit Tests (Solidity)

### All Unit Tests
```bash
forge test
```

### Specific Contract Tests
```bash
# RAT tests
forge test --match-contract RATTest

# SeigManager tests  
forge test --match-contract SeigManagerV1_4Real

# ValidatorReward tests
forge test --match-contract ValidatorRewardV1Test

# Deposit/Withdrawal tests
forge test --match-contract DepositManagerV1_2Real
```

### By Test Name Pattern
```bash
# All seigniorage tests
forge test --match-test seigniorage

# All validator tests
forge test --match-test validator

# All registration tests
forge test --match-test register
```

### With Verbosity
```bash
# Show results only
forge test -v

# Show console.log
forge test -vv

# Show execution traces
forge test -vvv

# Show full traces with stack
forge test -vvvv
```

### With Gas Report
```bash
forge test --gas-report
```

---

## 🔗 Integration Tests (Solidity)

### All Integration Tests
```bash
forge test --match-path "test/v3/scenarios/*.t.sol"
```

### Specific Scenario
```bash
# V3 full scenario
forge test --match-contract V3ScenarioRealTest

# Validator journey
forge test --match-contract ValidatorJourneyTest

# Sequencer journey
forge test --match-contract SequencerJourneyTest

# Migration scenarios
forge test --match-contract MigrationScenariosTest
```

---

## 🧪 E2E Tests (Go)

### First Time Setup
```bash
# Generate genesis (only once)
make devnet-allocs-offline
```

### Run All E2E Tests
```bash
# From project root
make test-e2e

# Or from op-e2e directory
cd op-e2e && make test
```

### Individual E2E Tests
```bash
cd op-e2e

# System startup
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs

# Account balances
GOWORK=off go test -v -run TestAccountBalances ./faultproofs

# RAT contract calls
GOWORK=off go test -v -run TestRATContractCall ./faultproofs

# Validator registration
GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs

# Game creation
GOWORK=off go test -v -run TestSimpleRAT_GameCreation ./faultproofs

# RAT Client E2E (real L2 + evidence submission)
GOWORK=off go test -v -run TestRATClient_EvidenceSubmission_E2E ./faultproofs

# Challenger wins (full flow)
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs
```

### E2E Test Groups
```bash
cd op-e2e

# System tests only
GOWORK=off go test -v -run "TestTONStakingSystemStartup|TestAccountBalances|TestRATContractCall" ./faultproofs

# RAT scenario tests only
GOWORK=off go test -v -run TestSimpleRAT ./faultproofs
```

### E2E with Logs
```bash
cd op-e2e

# Save to file
GOWORK=off go test -v ./faultproofs 2>&1 | tee test.log

# Show only success markers
GOWORK=off go test -v ./faultproofs 2>&1 | grep "✓"

# Show only errors
GOWORK=off go test -v ./faultproofs 2>&1 | grep -i error
```

---

## 🎯 Test by Feature

### RAT (Randomized Attention Test)
```bash
# Solidity RAT tests
forge test --match-contract RATTest

# E2E RAT tests
cd op-e2e && make test-rat-simple
```

### Seigniorage Distribution
```bash
# Unit tests
forge test --match-contract SeigniorageAccuracyTest

# Multi-L2 distribution
forge test --match-contract MultiL2SeigniorageDistributionTest

# Eligibility transitions
forge test --match-contract EligibilityTransitionTest
```

### Validator Rewards
```bash
# Unit tests
forge test --match-contract ValidatorRewardV1Test

# Integration
forge test --match-contract ValidatorJourneyTest
```

### Deposits & Withdrawals
```bash
forge test --match-contract DepositManagerV1_2Real
forge test --match-contract ValidatorWithdrawalRestrictionTest
```

---

## 🐛 Debugging Commands

### Forge Debug Mode
```bash
# Run specific test with full traces
forge test --match-test test_RAT001_registerValidator_success -vvvv

# With gas report
forge test --match-test test_SM016_v3_updateSeigniorage -vvv --gas-report
```

### E2E Debug Mode
```bash
cd op-e2e

# Sequential execution (no parallel)
GOWORK=off go test -v -p 1 ./faultproofs

# With extended timeout
GOWORK=off go test -v ./faultproofs -timeout 300s

# Single test with full output
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs 2>&1 | tee debug.log
```

---

## 🧹 Cleanup Commands

### Clear Forge Cache
```bash
forge clean
```

### Clear Go Test Cache
```bash
cd op-e2e && make clean
```

### Kill Anvil Processes
```bash
pkill anvil
```

### Full Reset
```bash
forge clean
cd op-e2e && make clean
pkill anvil
```

---

## 📊 Coverage & Reports

### Forge Coverage
```bash
# Generate coverage report
forge coverage

# Detailed coverage with lcov
forge coverage --report lcov
```

### Go Coverage
```bash
cd op-e2e
make coverage
open coverage/cover.html
```

### Gas Report
```bash
forge test --gas-report
```

---

## 🔄 CI/CD Commands

```bash
# Same commands as GitHub Actions
forge test --gas-report
make devnet-allocs-offline
make test-e2e
```

---

## 📦 Component-Specific Commands

### RAT Component
```bash
# Solidity RAT tests
forge test --match-contract RAT

# E2E RAT tests
cd op-e2e && GOWORK=off go test -v -run TestSimpleRAT ./faultproofs

# Specific RAT test
forge test --match-test test_RAT001_registerValidator_success -vvv
```

### SeigManager Component
```bash
forge test --match-contract SeigManager
forge test --match-test test_SM016_v3_updateSeigniorage -vvv
```

### ValidatorReward Component
```bash
forge test --match-contract ValidatorReward
forge test --match-test test_VR001_distributeL2Rewards_basic -vvv
```

### Layer2Manager Component
```bash
forge test --match-contract Layer2ManagerV1_2Real
```

### DepositManager Component
```bash
forge test --match-contract DepositManagerV1_2Real
```

---

## 🎓 Examples

### Example 1: Test RAT Registration
```bash
# Unit test
forge test --match-test test_RAT001_registerValidator_success -vvv

# E2E test
cd op-e2e
GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs
```

### Example 2: Test Seigniorage Distribution
```bash
# Accuracy test
forge test --match-test test_SM016_v3_updateSeigniorage -vvv

# Multi-L2 test
forge test --match-contract MultiL2SeigniorageDistributionTest -vv
```

### Example 3: Full E2E Challenge Flow
```bash
cd op-e2e
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs -timeout 60s 2>&1 | tee challenge-test.log
```

---

## 💡 Pro Tips

### Run Tests in Watch Mode
```bash
# Install forge-watch (cargo install forge-watch)
forge-watch test
```

### Filter by Gas Usage
```bash
forge test --gas-report | grep "high"
```

### Run Failed Tests Only
```bash
# Forge automatically shows failed tests
forge test --match-test <failed_test_name> -vvvv
```

### Parallel E2E Tests
```bash
# Default behavior (parallel)
cd op-e2e && make test

# Force sequential
cd op-e2e && GOWORK=off go test -v -p 1 ./faultproofs
```

---

## 🆘 Quick Troubleshooting

### Genesis File Missing
```bash
make devnet-allocs-offline
```

### Port Conflicts
```bash
pkill anvil
```

### Forge Cache Issues
```bash
forge clean
forge build
```

### Go Module Issues
```bash
cd op-e2e
go mod tidy
go clean -testcache
```

---

## 📚 Documentation Links

- [README.md](./README.md) - Test overview and quick start
- [QUICK-COMMANDS.md](./QUICK-COMMANDS.md) - This file (command reference)
- [op-e2e/README.md](../../op-e2e/README.md) - E2E tests guide
- [coverage-matrix.md](../coverage-matrix.md) - Test coverage analysis

---

## 🎯 Most Common Commands (Top 5)

```bash
# 1. All tests
forge test && make test-e2e

# 2. RAT tests only
forge test --match-contract RAT

# 3. E2E validator registration
cd op-e2e && GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs

# 4. Debug specific test
forge test --match-test test_RAT001 -vvvv

# 5. E2E challenger wins
cd op-e2e && GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs
```
