# op-e2e

End-to-end tests for TON Staking V3 RAT (Randomized Attention Test) integration.

## Quick Start

```bash
# From project root
make devnet-allocs   # Set up devnet and deploy contracts
make test-e2e        # Run all E2E tests
```

Or run tests individually:

```bash
# Unit tests (no devnet required)
make test-e2e-unit

# Integration tests (requires devnet-allocs)
make test-e2e-integration
```

## Running Tests

### Unit Tests (No Devnet)

```bash
cd op-e2e
go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...
```

### Integration Tests (With Devnet)

```bash
# Step 1: Set up devnet (from project root)
make devnet-allocs

# Step 2: Run tests
make test-e2e
```

The `devnet-allocs` command:
1. Starts Anvil on port 8545
2. Deploys all required contracts
3. Saves addresses to `.devnet/addresses.json`
4. Creates environment file at `.devnet/.env`

### Clean Up

```bash
make devnet-clean   # Stop Anvil and remove .devnet
```

## Directory Structure

```
op-e2e/
├── bindings/           # Go bindings for smart contracts
├── e2eutils/rat/       # RAT helper functions
├── faultproofs/        # Test files
│   ├── devnet_config.go        # Devnet config loader
│   ├── rat_integration_test.go # Integration tests
│   ├── rat_ton_staking_test.go # E2E tests
│   └── util.go
├── go.mod
└── Makefile
```

## Test Categories

| Category | Tests | Devnet Required | Command |
|----------|-------|-----------------|---------|
| Unit | 2 | No | `make test-e2e-unit` |
| Integration | 5 | Local Anvil | `make test-e2e-integration` |
| E2E | 9 | Optimism Devnet | `make test-e2e` |

## Configuration

Tests automatically load configuration from `.devnet/addresses.json`:

```json
{
  "chainId": 31337,
  "rpcUrl": "http://localhost:8545",
  "rat": "0x...",
  "ton": "0x...",
  "wton": "0x...",
  "systemConfig": "0x...",
  "privateKeys": {
    "validator": "..."
  }
}
```

If `.devnet/addresses.json` doesn't exist, tests will fall back to environment variables.

## Environment Variables (Alternative)

```bash
export RAT_ADDRESS="0x..."
export SYSTEM_CONFIG_ADDRESS="0x..."
export E2E_PRIVATE_KEY="..."
export E2E_RPC_URL="http://localhost:8545"
```

## See Also

- [Go E2E Test Guide](../docs/test/go-e2e-test-guide.md)
- [Test Coverage Matrix](../docs/test/coverage-matrix.md)
