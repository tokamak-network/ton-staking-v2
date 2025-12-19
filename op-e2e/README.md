# TON Staking V3 E2E Tests

This directory contains End-to-End (E2E) tests for TON Staking V3 RAT (Randomized Attention Test) integration with Optimism.

## Directory Structure

```
op-e2e/
├── bindings/           # Go bindings for smart contracts
│   └── rat_generated.go    # Auto-generated RAT contract binding
├── e2eutils/           # E2E test utilities
│   └── rat/
│       ├── helper.go         # RAT helper functions
│       ├── factory_helper.go # RAT factory helper
│       ├── devnet.go         # Devnet configuration
│       └── deploy.go         # Contract deployment helpers
├── faultproofs/        # Fault proof related E2E tests
│   ├── rat_ton_staking_test.go     # RAT E2E test cases
│   ├── rat_integration_test.go     # Integration tests for devnet
│   └── util.go                      # Test utilities
├── go.mod              # Go module definition
├── Makefile            # Test commands
└── README.md           # This file
```

## Prerequisites

- Go 1.22+
- Foundry (for contract compilation and local testnet)
- Anvil (for local devnet testing)

## Quick Start

### 1. Run Unit Tests (No Devnet Required)

```bash
# Run RAT helper function tests
make test-rat-unit

# Or directly with go test
cd op-e2e
go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...
```

### 2. Run Integration Tests with Local Devnet

#### Step 1: Start Anvil
```bash
# Start local Anvil instance
anvil --chain-id 31337
```

#### Step 2: Deploy Contracts
```bash
# From project root
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Deploy RAT and required contracts
forge script script/DeployRATForE2E.s.sol --rpc-url http://localhost:8545 --broadcast
```

#### Step 3: Run Integration Tests
```bash
# Set environment variables (use addresses from deployment output)
export RAT_ADDRESS=<deployed RAT address>
export SYSTEM_CONFIG_ADDRESS=<deployed SystemConfig address>
export E2E_PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export E2E_RPC_URL=http://localhost:8545

# Run integration tests
cd op-e2e
go test -v -run "TestRATIntegration" ./faultproofs/...
```

### 3. Run All E2E Tests

```bash
# Requires Optimism devnet with RAT contracts deployed
make test-rat

# Or directly with go test
go test -v ./faultproofs/...
```

## Test Scenarios

### Unit Tests (Always Run)

| Test | Description |
|------|-------------|
| TestRATHelperFunctions | Tests RAT helper utility functions |
| TestRATConstants | Verifies RAT constants are correctly defined |

### Integration Tests (Requires Devnet)

| Test | Description |
|------|-------------|
| TestRATIntegration_ValidatorRegistration | Tests validator registration flow |
| TestRATIntegration_GetContractParameters | Reads and verifies contract parameters |
| TestRATIntegration_ValidatorCount | Tests validator counting functions |
| TestRATIntegration_GetL2Validators | Tests getting validator list |
| TestRATIntegration_FullFlow | Tests complete validator lifecycle |

### E2E Tests (Requires Full Optimism Devnet)

| Test | Description |
|------|-------------|
| TestRATTriggerOnGameCreation | RAT trigger when DisputeGame created |
| TestRATEvidenceSubmission | Validator evidence submission |
| TestRATResolveClaimBondRefund | Bond refund on challenger win |
| TestRATEvidenceSubmissionExpiry | Slashing on evidence timeout |
| TestRATMultiL2Identification | Multi-L2 chain identification |
| TestRATValidatorStaking | Validator staking management |
| TestRATValidOutputRootDefense | Valid output root defense |
| TestRATUnsafeProposal | Unsafe proposal handling |
| TestRATFutureBlockProposal | Future block proposal handling |

## Configuration

### RAT Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| SlashingPenalty (C_off) | 100 WTON | Amount deducted on RAT trigger |
| ValidatorBuffer (Δ) | 100 WTON | Extra buffer for validators |
| MinimumThreshold (D_min) | 200 WTON | Minimum deposit to be active |
| EvidenceSubmissionPeriod | 1 hour | Time to submit evidence |
| RatTriggerProbability (π_a) | 1% | Probability of RAT trigger |

### Environment Variables

```bash
# Required for integration tests
export RAT_ADDRESS="0x..."           # Deployed RAT contract address
export SYSTEM_CONFIG_ADDRESS="0x..." # SystemConfig address
export E2E_PRIVATE_KEY="..."         # Test account private key (without 0x)
export E2E_RPC_URL="http://..."      # RPC endpoint (default: http://localhost:8545)

# Optional
export TON_ADDRESS="0x..."           # TON token address
export WTON_ADDRESS="0x..."          # WTON token address
```

## Regenerating Go Bindings

If the RAT contract changes, regenerate the Go bindings:

```bash
# Build contracts first
forge build

# Extract ABI and generate bindings
python3 -c "
import json
with open('out/RAT.sol/RAT.json') as f:
    d = json.load(f)
abi = [item for item in d['abi'] if item.get('type') != 'error']
with open('/tmp/rat_abi.json', 'w') as f:
    json.dump(abi, f)
"

# Generate Go bindings
abigen --abi=/tmp/rat_abi.json --pkg=bindings --type=RAT --out=op-e2e/bindings/rat_generated.go
```

## Event Flow Diagram

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│     User/       │      │ DisputeGame     │      │   TON Staking   │
│   Sequencer     │      │    Factory      │      │    V3 RAT       │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │ create(...)            │                        │
         │───────────────────────►│                        │
         │                        │                        │
         │                        │ triggerAttentionTest() │
         │                        │───────────────────────►│
         │                        │                        │
         │                        │                        │ Select validator
         │                        │                        │ Lock bond (C_off)
         │                        │                        │
         │                        │◄──────────────────────│
         │                        │                        │
         │◄───────────────────────│                        │ emit AttentionTestTriggered
         │                        │                        │
┌────────┴────────┐      ┌────────┴────────┐      ┌────────┴────────┐
│    Validator    │      │ FaultDispute    │      │   TON Staking   │
│                 │      │     Game        │      │    V3 RAT       │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │ submitEvidence()       │                        │
         │────────────────────────────────────────────────►│
         │                        │                        │
         │                        │                        │ Verify evidence
         │                        │                        │ Restore bond
         │                        │                        │
         │◄───────────────────────────────────────────────│
         │                        │                        │ emit EvidenceSubmitted
```

## Next Steps

1. **Full Optimism Devnet**: Implement complete devnet setup with DisputeGameFactory integration
2. **Evidence Generation**: Implement actual evidence generation logic from batch data
3. **Multi-L2 Support**: Add support for testing across multiple L2 chains
4. **CI/CD Integration**: Add to GitHub Actions workflow

## Related Documentation

- [E2E Test Design Document](../docs/e2e-test-design.md)
- [RAT Contract Source](../src/validator/RAT.sol)
- [IRAT Interface](../src/validator/IRAT.sol)
- [Test Coverage Matrix](../docs/test/coverage-matrix.md)
