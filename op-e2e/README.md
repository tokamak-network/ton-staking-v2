# TON Staking V3 - E2E Tests

End-to-end tests for TON Staking V3 system using Go tests with isolated Anvil nodes.

## Quick Start

```bash
# 1. Generate genesis file (once)
cd .. && make devnet-allocs-offline

# 2. Run E2E tests
cd op-e2e && make test
```

## What's Here

- **`faultproofs/rat_system_test.go`** - 3 system tests verifying startup, balances, and contract calls
- **`faultproofs/rat_challenge_test.go`** - 4 RAT scenario tests (646 lines)
- **`faultproofs/rat_challenge_helpers.go`** - Reusable test helpers (313 lines, 11 functions)
- **`e2eutils/rat/system.go`** - `StartTONStakingSystem()` helper that starts isolated Anvil nodes with genesis state
- **`bindings/`** - Contract bindings (RAT, FaultDisputeGame, DelayedWETH, etc.)
- **`Makefile`** - Test commands

## Test Architecture

Each test runs in **parallel** with its own **isolated Anvil node**:

```
Test 1 (Port 57340) → Isolated Anvil with genesis
Test 2 (Port 57341) → Isolated Anvil with genesis
Test 3 (Port 57342) → Isolated Anvil with genesis
```

Tests use pre-deployed contracts from genesis file (`.devnet/genesis-l1-staking-v3.json`).

## Tests

**Total: 7 tests (3 system + 4 RAT scenario)**
**Duration: ~21 seconds (parallel)**

### System Tests (3)

1. **TestTONStakingSystemStartup** (~1s) - Verify all contracts deployed with code
2. **TestAccountBalances** (~1s) - Verify test account balances from genesis
3. **TestRATContractCall** (~1s) - Verify RAT contract is callable

### RAT Scenario Tests (4)

4. **TestSimpleRAT_ValidatorRegistration** (~4s) - Validator registration with TON deposit
5. **TestSimpleRAT_GameCreation** (~6s) - DisputeGame creation and RAT trigger
6. **TestSimpleRAT_EvidenceSubmission** (~8s) - Evidence submission flow
7. **TestSimpleRAT_ChallengerWins** (~20s) - Full challenger wins scenario with bond claiming
   - Includes 2-step credit claiming with DelayedWETH (7-day delay)
   - Dynamic withdrawal delay query from contract
   - Comprehensive bond restoration verification

## Running Tests

```bash
# All tests (7 tests, ~21s)
make test

# System tests only (3 tests)
GOWORK=off go test -v -run "TestTONStakingSystemStartup|TestAccountBalances|TestRATContractCall" ./faultproofs

# RAT scenario tests only (4 tests)
GOWORK=off go test -v -run TestSimpleRAT ./faultproofs

# Specific test
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs

# With detailed output
GOWORK=off go test -v ./faultproofs -timeout 300s
```

## Documentation

For detailed documentation, see:
- **[E2E Test Guide](../docs/test/e2e-tests.md)** - Complete guide with architecture details
- **[Test Overview](../docs/test/README.md)** - All test categories

## Prerequisites

- Go 1.22+
- Foundry (for Anvil)
- Genesis file generated: `make devnet-allocs-offline` (from project root)

## Troubleshooting

### Genesis file not found
```bash
cd .. && make devnet-allocs-offline
```

### Port conflicts
Tests use dynamic port allocation. If issues persist:
```bash
pkill anvil
```
