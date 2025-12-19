# TON Staking V3 Test Documentation

## Overview

This directory contains documentation for the TON Staking V3 test suite. The tests cover the complete V3/V4 upgrade including seigniorage distribution, validator collateral (RAT), and Layer2 bridge integration.

## Quick Start

```bash
# Run all V3 tests
forge test --match-path "test/v3/*.sol"

# Run specific test file
forge test --match-path test/v3/BasicFunctions.t.sol

# Run with verbose output
forge test --match-path "test/v3/*.sol" -vvv

# Run specific test function
forge test --match-test test_updateSeigniorage -vvv
```

## Test Files Summary

| File | Description | Tests |
|------|-------------|-------|
| `BasicFunctions.t.sol` | Core staking: deposit, withdrawal, seigniorage | 12 |
| `RAT.t.sol` | Validator collateral & Randomized Attention Test | 40+ |
| `EndToEndSeigniorage.t.sol` | V2→V3 seigniorage transition | 15+ |
| `SeigManagerV1_4Real.t.sol` | Hyperbolic saturation formulas | 24 |
| `DepositManagerV1_2Real.t.sol` | Deposit/withdrawal mechanics | 14 |
| `V3ScenarioReal.t.sol` | Full V3 scenario with SequencerVault | 8 |
| `SeigniorageDistribution.t.sol` | Seigniorage formula validation | 50+ |
| `DeployV3Fork.t.sol` | Mainnet fork deployment verification | 6 |

**Total: 142+ tests**

## Documentation Files

- [Test Execution Guide](./test-execution-guide.md) - How to run tests
- [Coverage Matrix](./coverage-matrix.md) - Feature coverage status
- [Gap Analysis](./gap-analysis.md) - Missing tests and improvements

## V3/V4 Features Tested

### V3 Core Features (Fully Tested)
- Layer2 Registration with Coinage deployment
- WTON/TON Deposit & Withdrawal
- Withdrawal delay enforcement
- Seigniorage distribution (V2 and V3 modes)
- Hyperbolic saturation formula
- V2→V3 transition (λ, r parameter changes)

### V4 Features (Validator Collateral - Fully Tested)
- Validator registration with collateral
- RAT (Randomized Attention Test) trigger mechanism
- Lazy evaluation for slashing
- Evidence submission & verification
- Per-game bond tracking
- Multi-game concurrent support
- Validator recovery after slashing

### Bridge Integration (Partially Tested)
- L1BridgeRegistry DisputeGameFactory support
- Layer2Manager bridge queries
- SequencerVault integration

## Test Architecture

```
test/v3/
├── BasicFunctions.t.sol      # Integration: Full staking cycle
├── RAT.t.sol                 # Unit: Validator collateral mechanics
├── EndToEndSeigniorage.t.sol # Integration: Seigniorage distribution
├── SeigManagerV1_4Real.t.sol # Unit: V1.4 specific functions
├── DepositManagerV1_2Real.t.sol
├── Layer2ManagerV1_2Real.t.sol
├── L1BridgeRegistryV1_2Real.t.sol
├── V3ScenarioReal.t.sol      # E2E: Complete V3 scenario
├── SeigniorageDistribution.t.sol
├── DeployV3Fork.t.sol        # Mainnet fork testing
└── mocks/
    ├── MockTON.sol
    ├── MockWTON.sol
    ├── MockCoinage.sol
    ├── MockFaultDisputeGame.sol
    ├── MockL1BridgeRegistry.sol
    └── MockSystemConfig.sol
```

## Key Test Scenarios

### 1. Basic Staking Flow
```
Register Layer2 → Deposit WTON → Update Seigniorage → Request Withdrawal → Process Withdrawal
```

### 2. V3 Seigniorage Distribution
```
V2 Mode (λ=1, r=0.4) → Transition → V3 Mode (λ=0, r=0)
```

### 3. Validator Collateral (RAT)
```
Register Validator → Trigger RAT → Submit Evidence → Claim Rewards
                  ↘ No Response → Slashing → Recovery
```

## Running Tests

See [Test Execution Guide](./test-execution-guide.md) for detailed instructions.
