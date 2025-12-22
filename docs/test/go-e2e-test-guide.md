# Go E2E Test Guide

Go E2E tests for RAT (Randomized Attention Test) integration with Optimism fault proofs.

## Prerequisites

```bash
# Go 1.22+
go version

# Anvil (for local devnet)
anvil --version

# abigen (for regenerating bindings)
abigen --version
```

## Quick Start

```bash
cd op-e2e

# Unit tests (no devnet required)
make test-rat-unit

# All tests
make test
```

## Test Categories

| Category | Tests | Devnet Required |
|----------|-------|-----------------|
| Unit | 2 | No |
| Integration | 5 | Local Anvil |
| E2E | 9 | Optimism Devnet |

## Running Tests

### Unit Tests

```bash
cd op-e2e
make test-rat-unit

# Or directly
go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...
```

### Integration Tests

```bash
# Terminal 1: Start Anvil
anvil --chain-id 31337

# Terminal 2: Deploy & Test
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/DeployRATForE2E.s.sol --rpc-url http://localhost:8545 --broadcast

export RAT_ADDRESS=<deployed address>
export SYSTEM_CONFIG_ADDRESS=<deployed address>
export E2E_PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

cd op-e2e && make test-rat-integration
```

### Full E2E Tests

```bash
# Requires Optimism devnet with RAT contracts
cd op-e2e && make test-rat-e2e
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

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `RAT_ADDRESS` | Integration/E2E | RAT contract address |
| `SYSTEM_CONFIG_ADDRESS` | Integration/E2E | SystemConfig address |
| `E2E_PRIVATE_KEY` | Integration/E2E | Test account key |
| `E2E_RPC_URL` | Optional | RPC endpoint |

## Regenerating Bindings

```bash
cd op-e2e
make bindings
```

## Directory Structure

```
op-e2e/
├── bindings/rat_generated.go
├── e2eutils/rat/
│   ├── helper.go
│   ├── factory_helper.go
│   ├── devnet.go
│   └── deploy.go
├── faultproofs/
│   ├── rat_ton_staking_test.go
│   ├── rat_integration_test.go
│   └── util.go
├── go.mod
└── Makefile
```

## See Also

- [op-e2e/README.md](../../op-e2e/README.md)
- [E2E Test Design](../e2e-test-design.md)
