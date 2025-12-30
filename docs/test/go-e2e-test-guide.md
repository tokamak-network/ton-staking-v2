# Go E2E Test Guide

Go E2E tests for RAT (Randomized Attention Test) integration with Optimism fault proofs.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        ton-staking-v2                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   RAT.sol   │  │  TON/WTON   │  │     E2E Tests (Go)      │  │
│  │ (Validator) │  │   Tokens    │  │  op-e2e/faultproofs/    │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                     │                │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          │                │                     │
          ▼                ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    L1 Devnet (Anvil :8545)                      │
│  ┌───────────────────┐  ┌───────────────────┐                   │
│  │ DisputeGameFactory│  │  OptimismPortal2  │                   │
│  │  (calls RAT)      │  │                   │                   │
│  └─────────┬─────────┘  └───────────────────┘                   │
│            │                                                    │
│            ▼                                                    │
│  ┌───────────────────┐                                          │
│  │ FaultDisputeGame  │  ← Created when dispute starts           │
│  │ (calls RAT on     │                                          │
│  │  resolve)         │                                          │
│  └───────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
          ▲
          │ lib/optimism devnet-allocs
          │
┌─────────────────────────────────────────────────────────────────┐
│                  lib/optimism (submodule)                       │
│  - IRAT interface                                               │
│  - DisputeGameFactory with RAT integration                      │
│  - FaultDisputeGame with RAT.resolveClaim()                     │
│  - devnet-allocs tool                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

```bash
# Go 1.22+
go version

# Foundry (anvil, forge, cast)
forge --version
anvil --version
cast --version

# just (command runner)
just --version

# If just is not installed:
# macOS
brew install just
# Linux
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
```

## Quick Start (Single Terminal - like Asterisc)

```bash
# Set up devnet (build lib/optimism + start L1 + deploy RAT)
make devnet-allocs

# Run E2E tests
make test-e2e

# Stop L1 when done
make devnet-down
```

### Full Cleanup

```bash
make devnet-clean   # Stop L1 + clean all devnet state
```

### Rebuild After Code Changes

```bash
# If RAT contract changed:
make devnet-down
make devnet-allocs   # Rebuilds everything

# If only tests changed:
make test-e2e        # Just re-run tests (L1 stays running)
```

## Detailed Setup

### Step 1: Build lib/optimism Contracts

```bash
cd lib/optimism
just forge-build
```

This compiles Optimism contracts including:
- DisputeGameFactory (with RAT integration)
- FaultDisputeGame
- OptimismPortal2
- SystemConfig

### Step 2: Generate Devnet Allocs

```bash
cd lib/optimism
just devnet-allocs
```

This creates `.devnet/` with:

| File | Description |
|------|-------------|
| `addresses.json` | Optimism contract addresses |
| `allocs-l1.json` | L1 genesis state |
| `allocs-l2.json` | L2 genesis state |
| `devnetL1.json` | Deploy configuration |

### Step 3: Start L1 Devnet

```bash
cd lib/optimism
just devnet-l1
```

This starts Anvil with:
- **RPC**: `http://localhost:8545`
- **Chain ID**: 900
- **Block Time**: 2 seconds
- Optimism contracts pre-deployed

### Step 4: Deploy RAT Contract

```bash
cd /path/to/ton-staking-v2

# Deploy RAT and connect to DisputeGameFactory
make deploy-rat-devnet
```

This script:
1. Deploys TON, WTON tokens (mock)
2. Deploys RAT contract with proxy
3. Calls `DisputeGameFactory.setRAT(ratAddress)`
4. Saves addresses to `.devnet/addresses.json`

### Step 5: Run E2E Tests

```bash
make test-e2e
```

## Environment Configuration

### lib/optimism addresses.json

Located at `lib/optimism/.devnet/addresses.json`:

```json
{
  "DisputeGameFactoryProxy": "0x22b82825a3d88cabf27fc4d21a859306b22324fa",
  "OptimismPortalProxy": "0xa5fc72052dfdf9b733f70c44d737571a765eda81",
  "SystemConfigProxy": "0xaeff771968785e279632dd6ed0af1f6c1bfedced",
  "L1StandardBridgeProxy": "0xd2de008b1545b69cb5dcacf1a083f92b5604aa8f",
  ...
}
```

### ton-staking-v2 addresses.json

Located at `.devnet/addresses.json`:

```json
{
  "chainId": 900,
  "rpcUrl": "http://localhost:8545",
  "rat": "0x...",
  "ton": "0x...",
  "wton": "0x...",
  "disputeGameFactory": "0x22b82825a3d88cabf27fc4d21a859306b22324fa",
  "systemConfig": "0xaeff771968785e279632dd6ed0af1f6c1bfedced",
  "accounts": {
    "deployer": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "validator": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
  }
}
```

## Test Categories

| Category | Tests | Devnet Required | Command |
|----------|-------|-----------------|---------|
| Unit | 2 | No | `make test-e2e-unit` |
| Integration | 5 | L1 + RAT | `make test-e2e-integration` |
| E2E | 9 | Full Optimism | `make test-e2e` |

### Unit Tests (No Devnet)

```bash
cd op-e2e
go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...
```

### Integration Tests

Requires L1 devnet with RAT deployed:

```bash
make test-e2e-integration
```

### Full E2E Tests

Requires full Optimism devnet with DisputeGameFactory:

```bash
make test-e2e
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
| `TestRATTriggerOnGameCreation` | E2E | RAT trigger on DisputeGame creation |
| `TestRATEvidenceSubmission` | E2E | Evidence submission flow |
| `TestRATResolveClaimBondRefund` | E2E | Bond refund on game resolution |
| `TestRATEvidenceSubmissionExpiry` | E2E | Slashing on timeout |
| `TestRATMultiL2Identification` | E2E | Multi-L2 chain identification |
| `TestRATValidatorStaking` | E2E | Staking and validity management |
| `TestRATValidOutputRootDefense` | E2E | Valid output root defense |
| `TestRATUnsafeProposal` | E2E | Unsafe proposal handling |
| `TestRATFutureBlockProposal` | E2E | Future block proposal |

## RAT Integration Flow

```
1. DisputeGameFactory.create()
   │
   ▼
2. IRAT.triggerAttentionTest(gameAddress, systemConfig, batchIndex, batchHash, blockHash)
   │
   ▼
3. RAT selects random validator, locks bond
   │
   ▼
4. Validator submits evidence OR timeout expires
   │
   ├─► Evidence correct: Bond restored
   │
   └─► Timeout/Wrong: Bond slashed

5. FaultDisputeGame.resolve()
   │
   ▼
6. IRAT.resolveClaim(claimant)
   │
   ▼
7. RAT refunds bond to game winner
```

## Directory Structure

```
ton-staking-v2/
├── lib/optimism/                 # Optimism submodule
│   ├── .devnet/                  # Generated by just devnet-allocs
│   │   ├── addresses.json        # Optimism contract addresses
│   │   ├── allocs-l1.json        # L1 genesis allocs
│   │   └── devnetL1.json         # Deploy config
│   ├── justfile                  # just commands
│   └── packages/contracts-bedrock/
│       ├── src/dispute/
│       │   ├── DisputeGameFactory.sol  # Calls RAT
│       │   └── FaultDisputeGame.sol    # Calls RAT.resolveClaim
│       └── interfaces/L1/
│           └── IRAT.sol          # RAT interface
│
├── src/validator/
│   ├── RAT.sol                   # RAT implementation
│   └── RATProxy.sol
│
├── script/
│   └── DeployRATForDevnet.s.sol  # RAT deployment script
│
├── .devnet/                      # Local devnet state
│   ├── addresses.json            # RAT + Optimism addresses
│   └── .env                      # Environment variables
│
└── op-e2e/
    ├── bindings/                 # Go contract bindings
    ├── e2eutils/rat/             # RAT helper functions
    └── faultproofs/
        ├── devnet_config.go      # Config loader
        ├── rat_integration_test.go
        └── rat_ton_staking_test.go
```

## Makefile Commands

```bash
# Devnet management
make devnet-up              # Start lib/optimism L1
make devnet-down            # Stop L1
make devnet-clean           # Clean all devnet files
make deploy-rat-devnet      # Deploy RAT to devnet

# Testing
make test-e2e               # Run all E2E tests
make test-e2e-unit          # Run unit tests only
make test-e2e-integration   # Run integration tests
```

## Troubleshooting

### "just: command not found"

Install just:

```bash
# macOS
brew install just

# Linux
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
```

### "forge-artifacts not found"

Build contracts first:

```bash
cd lib/optimism
just forge-build
```

### Connection refused to localhost:8545

Ensure L1 is running:

```bash
cd lib/optimism
just devnet-l1
```

### "RAT address not set"

Deploy RAT contract:

```bash
make deploy-rat-devnet
```

### Tests skip with "devnet not configured"

1. Ensure lib/optimism L1 is running
2. Ensure RAT is deployed
3. Check `.devnet/addresses.json` exists

### DisputeGameFactory.setRAT fails

Ensure you're using the deployer account (owner):

```bash
# Deployer private key (Anvil account 0)
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## Network Configuration

| Parameter | L1 Devnet | L2 Devnet |
|-----------|-----------|-----------|
| Chain ID | 900 | 901 |
| RPC URL | http://localhost:8545 | http://localhost:9545 |
| Block Time | 2s | 1s |

## Test Accounts (Anvil Default)

| Role | Address | Private Key |
|------|---------|-------------|
| Deployer | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` |
| Validator | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` |
| Proposer | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` |
| Challenger | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | `0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a` |

## See Also

- [lib/optimism devnet-allocs docs](../../lib/optimism/docs/devnet-allocs.md)
- [op-e2e/README.md](../../op-e2e/README.md)
- [Test Coverage Matrix](coverage-matrix.md)
