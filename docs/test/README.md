# TON Staking V3 Test Documentation

> 📚 Complete testing guide for TON Staking V3 system

## 🚀 Quick Start (Copy & Paste)

### Option 1: Run Everything
```bash
# From project root
cd /Users/zena/tokamak-projects/ton-staking-v2

# One command - all tests
forge test && make devnet-allocs-offline && make test-e2e
```

### Option 2: Step by Step
```bash
# 1️⃣ Unit & Integration Tests (Solidity - ~2 min)
forge test

# 2️⃣ E2E Tests (Go - ~30 sec)
make devnet-allocs-offline  # First time only
make test-e2e
```

---

## 📊 Test Categories Overview

| Category | Tests | Duration | Language | Purpose |
|----------|-------|----------|----------|---------|
| **Unit Tests** | 150+ | ~2 min | Solidity | Individual contract functions |
| **Integration Tests** | 8 | ~30 sec | Solidity | Cross-contract workflows |
| **E2E Tests** | 7 | ~21 sec | Go | Complete system with real nodes |
| **Total** | **165+** | **~3 min** | - | Full coverage |

---

## 📖 Detailed Guides

### 🔹 Unit Tests (Solidity)
**What:** Test individual contract functions (RAT, SeigManager, ValidatorReward, etc.)

**Run:**
```bash
# All tests
forge test

# Specific contract
forge test --match-contract RATTest

# With gas report
forge test --gas-report
```

📄 **Full Guide:** [unit-tests.md](./unit-tests.md)

---

### 🔹 Integration Tests (Solidity)
**What:** Test cross-contract workflows (V3 migration, L2 registration, full scenarios)

**Run:**
```bash
# All integration tests
forge test --match-path "test/v3/scenarios/*.t.sol"

# Specific scenario
forge test --match-contract V3ScenarioRealTest
```

📄 **Full Guide:** [integration-tests.md](./integration-tests.md)

---

### 🔹 E2E Tests (Go)
**What:** Test complete system with real Anvil nodes (RAT triggers, DisputeGame, evidence submission)

**Run:**
```bash
# First time setup
make devnet-allocs-offline

# Run all E2E tests
make test-e2e

# Or from op-e2e directory
cd op-e2e && make test
```

📄 **Full Guide:** [e2e-tests.md](./e2e-tests.md)

---

## 🎯 Quick Commands Cheat Sheet

### Test Specific Components
```bash
# RAT tests only
forge test --match-contract RAT

# SeigManager tests only
forge test --match-contract SeigManager

# ValidatorReward tests only
forge test --match-contract ValidatorReward

# E2E RAT scenarios only
cd op-e2e && make test-rat-simple
```

### Individual E2E Tests
```bash
cd op-e2e

# System checks
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs

# Validator registration
GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs

# Evidence submission
GOWORK=off go test -v -run TestSimpleRAT_EvidenceSubmission ./faultproofs

# Challenger wins (full flow)
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs
```

### Debugging
```bash
# Verbose output
forge test -vvv

# Very verbose (with traces)
forge test -vvvv

# E2E with logs
cd op-e2e && GOWORK=off go test -v ./faultproofs 2>&1 | tee test.log
```

---

## 🔧 Troubleshooting

### Genesis file not found
```bash
# Error: Genesis file not found at .devnet/genesis-l1-staking-v3.json
make devnet-allocs-offline
```

### Port conflicts (E2E tests)
```bash
# Kill existing Anvil processes
pkill anvil

# Or run tests sequentially
cd op-e2e && GOWORK=off go test -v -p 1 ./faultproofs
```

### Clear test cache
```bash
# Forge cache
forge clean

# Go test cache
cd op-e2e && make clean
```

---

## 📚 Documentation Index

| Document | Description | When to Read |
|----------|-------------|--------------|
| [unit-tests.md](./unit-tests.md) | Solidity unit tests guide | Testing individual contracts |
| [integration-tests.md](./integration-tests.md) | Solidity integration guide | Testing workflows |
| [e2e-tests.md](./e2e-tests.md) | Go E2E tests guide | Testing complete system |
| [op-e2e-genesis-setup.md](./op-e2e-genesis-setup.md) | Genesis file generation | Setting up E2E tests |
| [gap-analysis.md](./gap-analysis.md) | Test coverage gaps | Understanding test priorities |

---

## ✅ CI/CD Quick Check

```bash
# Same commands as CI runs
forge test --gas-report
make devnet-allocs-offline
make test-e2e
```

---

## 📞 Need Help?

- **Unit/Integration Tests Issues:** Check contract error messages with `forge test -vvvv`
- **E2E Tests Issues:** Check Anvil logs and genesis file
- **Genesis Issues:** Re-run `make devnet-allocs-offline`
- **Port Conflicts:** Run `pkill anvil`

---

## 🎓 Test Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    TON Staking V3 Tests                │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌──────────────┐
│  Unit Tests   │   │ Integration   │   │  E2E Tests   │
│  (Solidity)   │   │   (Solidity)  │   │    (Go)      │
└───────────────┘   └───────────────┘   └──────────────┘
        │                   │                   │
        │                   │                   │
  forge test          forge test         make test-e2e
        │                   │                   │
        ▼                   ▼                   ▼
  150+ tests           8 tests             7 tests
   ~2 min              ~30 sec             ~21 sec
```
