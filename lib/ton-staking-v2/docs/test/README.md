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
| **Unit Tests** | 515+ | ~2 min | Solidity | Individual contract functions |
| **Integration Tests** | 11 | ~30 sec | Solidity | Cross-contract workflows |
| **E2E Tests** | 7 | ~80 sec | Go | Complete system with real nodes |
| **Total** | **533+** | **~4 min** | - | Full coverage |

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

**Run:**
```bash
# All tests
forge test

# Specific contract
forge test --match-contract RATTest

# With gas report
forge test --gas-report
```

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

📄 **Full Guide:** See [op-e2e/README.md](../../op-e2e/README.md) for detailed E2E test documentation

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
cd op-e2e && GOWORK=off go test -v -run TestSimpleRAT ./faultproofs
```

### Individual E2E Tests
```bash
cd op-e2e

# System checks
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs

# Validator registration
GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs

# RAT Client E2E (with real L2 + evidence submission)
GOWORK=off go test -v -run TestRATClient_EvidenceSubmission_E2E ./faultproofs

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
| [README.md](./README.md) | Test overview and quick start | Start here |
| [QUICK-COMMANDS.md](./QUICK-COMMANDS.md) | Command reference cheat sheet | Quick command lookup |
| [op-e2e/README.md](../../op-e2e/README.md) | E2E tests guide (Go) | Testing complete system with real nodes |
| [coverage-matrix.md](../coverage-matrix.md) | Test coverage analysis | Understanding test coverage |

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
