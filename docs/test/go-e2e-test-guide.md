# Go E2E Test Guide

Go E2E tests for RAT (Randomized Attention Test) integration with Optimism fault proofs.

## Prerequisites

```bash
# Go 1.22+
go version

# Anvil (for local devnet)
anvil --version

# Foundry
forge --version
```

## Quick Start

```bash
# From project root
make devnet-allocs   # Set up devnet
make test-e2e        # Run all E2E tests
```

## Test Categories

| Category | Tests | Devnet Required |
|----------|-------|-----------------|
| Unit | 2 | No |
| Integration | 5 | Local Anvil |
| E2E | 9 | Optimism Devnet |

## Running Tests

### Unit Tests (No Devnet)

```bash
make test-e2e-unit

# Or directly
cd op-e2e
go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...
```

### Integration Tests (With Devnet)

```bash
# Step 1: Set up devnet (one command)
make devnet-allocs

# Step 2: Run tests
make test-e2e-integration

# Or all E2E tests
make test-e2e
```

### Cleanup

```bash
make devnet-clean
```

## What `devnet-allocs` Does

1. Starts Anvil on port 8545 (chain ID 31337)
2. Deploys contracts via `DeployRATForE2E.s.sol`:
   - MockTON, MockWTON
   - MockSeigManager, MockLayer2Manager
   - MockL1BridgeRegistry, MockSystemConfig
   - RAT (with proxy)
3. Saves addresses to `.devnet/addresses.json`
4. Creates `.devnet/.env` for shell sourcing

## Configuration

Tests automatically load from `.devnet/addresses.json`:

```json
{
  "chainId": 31337,
  "rpcUrl": "http://localhost:8545",
  "rat": "0x...",
  "ton": "0x...",
  "wton": "0x...",
  "systemConfig": "0x...",
  "accounts": {
    "deployer": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "validator": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
  },
  "privateKeys": {
    "deployer": "ac0974...",
    "validator": "59c699..."
  }
}
```

## Test List

| Test | Category | Description |
|------|----------|-------------|
| `TestRATHelperFunctions` | Unit | Helper utility functions |
| `TestRATConstants` | Unit | Constants verification |
| `TestRATIntegration_ValidatorRegistration` | Integration | Validator registration |
| `TestRATIntegration_GetContractParameters` | Integration | Parameter reading |
| `TestRATIntegration_ValidatorCount` | Integration | Validator counting |
| `TestRATIntegration_GetL2Validators` | Integration | Get validator list |
| `TestRATIntegration_FullFlow` | Integration | Complete lifecycle |
| `TestRATTriggerOnGameCreation` | E2E | RAT trigger |
| `TestRATEvidenceSubmission` | E2E | Evidence submission |
| `TestRATResolveClaimBondRefund` | E2E | Bond refund |
| `TestRATEvidenceSubmissionExpiry` | E2E | Slashing timeout |
| `TestRATMultiL2Identification` | E2E | Multi-L2 identification |
| `TestRATValidatorStaking` | E2E | Staking management |
| `TestRATValidOutputRootDefense` | E2E | Valid output defense |
| `TestRATUnsafeProposal` | E2E | Unsafe proposal |
| `TestRATFutureBlockProposal` | E2E | Future block |

## Makefile Commands

```bash
make help              # Show all commands
make devnet-allocs     # Set up devnet and deploy contracts
make devnet-clean      # Stop Anvil and clean .devnet
make devnet-up         # Start Anvil only
make devnet-down       # Stop Anvil only
make test-e2e          # Run all E2E tests
make test-e2e-unit     # Run unit tests only
make test-e2e-integration  # Run integration tests
```

## Directory Structure

```
ton-staking-v2/
├── Makefile              # Main Makefile with devnet commands
├── scripts/
│   └── devnet-allocs.sh  # Devnet setup script
├── .devnet/              # Created by devnet-allocs
│   ├── addresses.json    # Deployed contract addresses
│   ├── .env              # Environment variables
│   ├── anvil.log         # Anvil logs
│   └── anvil.pid         # Anvil process ID
└── op-e2e/
    ├── bindings/
    ├── e2eutils/rat/
    ├── faultproofs/
    │   ├── devnet_config.go
    │   ├── rat_integration_test.go
    │   ├── rat_ton_staking_test.go
    │   └── util.go
    └── Makefile
```

## Troubleshooting

### Anvil already running

```bash
make devnet-clean
make devnet-allocs
```

### Tests skip with "devnet not configured"

```bash
# Ensure devnet is set up
make devnet-allocs

# Check .devnet/addresses.json exists
cat .devnet/addresses.json
```

### Connection refused

```bash
# Check Anvil is running
curl http://localhost:8545

# If not, restart devnet
make devnet-clean
make devnet-allocs
```

## See Also

- [op-e2e/README.md](../../op-e2e/README.md)
- [Test Coverage Matrix](coverage-matrix.md)
- [Gap Analysis](gap-analysis.md)
