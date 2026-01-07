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

- **`faultproofs/rat_system_test.go`** - 3 E2E tests verifying system startup, account balances, and RAT contract calls
- **`e2eutils/rat/system.go`** - `StartTONStakingSystem()` helper that starts isolated Anvil nodes with genesis state
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

1. **TestTONStakingSystemStartup** - Verify all contracts deployed with code
2. **TestAccountBalances** - Verify test account balances from genesis
3. **TestRATContractCall** - Verify RAT contract is callable

## Running Tests

```bash
# All tests
make test

# Specific test
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs

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
