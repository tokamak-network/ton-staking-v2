# TON Staking V3

V3 staking smart contracts for Tokamak Network. Implemented based on Tokamak Economics Whitepaper V2 (December 2025).

## System Overview

TON Staking V3 operates on Ethereum L1 and interacts with multiple L2 rollups (Titan, Thanos, etc.) to provide network security and economic incentives.

### Core Objectives

- **L2 Network Security**: Incentivize L2 operators (sequencers) to act honestly through seigniorage rewards
- **Validator Participation**: Motivate validators to continuously monitor the network via RAT (Randomized Attention Test)
- **Fair Reward Distribution**: Distribute rewards based on actual network contribution using Bridged TON
- **DAO Governance**: Manage system parameter adjustments and upgrades through DAO

## V3 Key Changes

| Category | V2 | V3 |
|----------|-----|-----|
| **Seigniorage Distribution Basis** | L2 TVL (simple proportion) | Bridged TON (performance-based) |
| **Distribution Function** | Linear | Hyperbolic saturation `y(x) = L·(x/(k+x))` |
| **Eligibility Condition** | Minimum deposit only | S_i ≥ θ·B_i (staking ratio requirement) |
| **Validator Rewards** | None | α·y(x) / n (validator pool distribution) |
| **DAO Allocation** | Fixed ratio | Fixed ratio + undistributed portion |
| **Staker Seigniorage** | Provided | **Not provided** (deprecated in V3) |

## Core Contracts

| Contract | Role |
|----------|------|
| **SeigManagerV1_4** | Seigniorage calculation and distribution (V3 core) |
| **DepositManagerV1_2** | TON/WTON staking management |
| **Layer2ManagerV1_2** | L2 registration and Bridged TON queries |
| **L1BridgeRegistryV1_2** | Bridge/portal registration, TVL queries |
| **RAT** | Validator registration, RAT tests, slashing |
| **ValidatorRewardV1** | Validator reward distribution |

## V3 Core Parameters

| Parameter | Symbol | Description |
|-----------|--------|-------------|
| `daoDistributionRatio` | d | DAO distribution ratio |
| `minStakingRatio` | θ | Minimum staking ratio |
| `validatorDistributionRatio` | α | Validator distribution ratio |
| `halfSaturationPoint` | k | Half-saturation point |
| `ratTriggerProbability` | π_a | RAT trigger probability |
| `slashingPenalty` | C_off | Validator slashing penalty |
| `evidenceSubmissionPeriod` | - | Evidence submission period |

> **RAY Units**: All ratio parameters are expressed in RAY (10^27) units.

## Installation

### Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Clone and Build

```bash
# Clone with submodules
git clone --recursive https://github.com/tokamak-network/ton-staking-v2.git
cd ton-staking-v2

# Build
forge build
```

### If Already Cloned (Initialize Submodules)

```bash
git submodule update --init --recursive
forge build
```

### Update Submodules

```bash
# Update optimism library to latest
git submodule update --remote lib/optimism
```

### lib/optimism Submodule Caution

When changing commits in the `lib/optimism` submodule, you **must explicitly specify GIT_DIR**. Otherwise, the parent repository (ton-staking-v2) HEAD may be changed.

**Safe submodule commit change method:**

```bash
# Use explicit GIT_DIR (recommended)
GIT_DIR=.git/modules/lib/optimism GIT_WORK_TREE=lib/optimism git fetch origin feature/ton-staking-v3
GIT_DIR=.git/modules/lib/optimism GIT_WORK_TREE=lib/optimism git checkout <commit-hash>
```

**Current lib/optimism settings:**
- Repository: `tokamak-network/optimism`
- Branch: `feature/ton-staking-v3`
- Commit: `039c2878b` (feat: add devnet-allocs tool for e2e testing)

## Project Structure

```
src/
├── stake/                              # Staking system
│   ├── managers/
│   │   ├── SeigManager.sol                    # Seigniorage (base)
│   │   ├── SeigManagerV1_2.sol                # Multi-impl index 0
│   │   ├── SeigManagerV1_3.sol                # Multi-impl index 1 (pause)
│   │   ├── SeigManagerV1_4.sol                # Multi-impl index 2 (V3 core)
│   │   ├── DepositManager.sol                 # Staking (base)
│   │   ├── DepositManagerV1_1.sol             # L2 deposit
│   │   └── DepositManagerV1_2.sol             # V3 callback
│   ├── tokens/
│   │   ├── RefactorCoinageSnapshot.sol        # Coinage logic
│   │   └── AutoRefactorCoinage.sol            # Auto-refactor coinage
│   ├── factory/
│   │   └── CoinageFactory.sol                 # Coinage factory
│   ├── Layer2Registry.sol                     # L2 registration
│   └── interfaces/
│
├── layer2/                             # L2 management
│   ├── Layer2ManagerV1_1.sol                  # L2 manager (base)
│   ├── Layer2ManagerV1_2.sol                  # V3 Bridged TON
│   ├── L1BridgeRegistryV1_1.sol               # Bridge registry (base)
│   ├── L1BridgeRegistryV1_2.sol               # V3 DisputeGame support
│   ├── OperatorManagerV1_1.sol                # Operator manager
│   ├── OperatorManagerV1_2.sol                # V3 operator
│   ├── factory/
│   │   └── OperatorManagerFactory.sol         # Operator factory
│   └── interfaces/
│
├── validator/                          # Validator system (V3 new)
│   ├── RAT.sol                                # Randomized Attention Test
│   ├── RATProxy.sol
│   ├── ValidatorRewardV1.sol                  # Validator rewards
│   ├── ValidatorRewardProxy.sol
│   └── interfaces/
│
├── dao/                                # DAO governance
│   ├── DAOCommittee_V1.sol                    # DAO committee logic
│   ├── DAOCommitteeOwner.sol                  # Owner functions
│   ├── Candidate.sol                          # DAO candidate
│   ├── CandidateAddOnV1_1.sol                 # Candidate add-on
│   ├── factory/
│   │   ├── CandidateFactory.sol               # Candidate factory
│   │   └── CandidateAddOnFactory.sol          # Add-on factory
│   └── interfaces/
│
├── proxy/                              # Proxy contracts
│   ├── ProxyStorage.sol                       # Base proxy storage
│   ├── DAOCommitteeProxy2.sol                 # DAO multi-impl router
│   └── Proxy.sol
│
├── common/                             # Common utilities
│   ├── AccessibleCommon.sol
│   ├── AuthControlSeigManager.sol
│   ├── AuthControlLayer2Manager.sol
│   └── AuthControlL1BridgeRegistry.sol
│
└── accessControl/                      # Access control
    └── AccessControl.sol

lib/
├── optimism/               # tokamak-network/optimism (branch: feature/ton-staking-v3)
├── tokamak-dao-contracts/  # tokamak-network/tokamak-dao-contracts (DAO governance)
├── openzeppelin-contracts/
└── forge-std/
```

## Testing

```bash
# Run all tests
forge test

# V3 tests only
forge test --match-path "test/v3/*"

# Specific test
forge test --match-test testUpdateSeigniorageV3
```

## External Libraries

| Library | Purpose |
|---------|---------|
| `@optimism/` | Optimism L1/L2 interfaces (SystemConfig, L1StandardBridge, OptimismPortal, etc.) |
| `@openzeppelin/contracts/` | ERC20, SafeERC20, Math, etc. |
| `@tokamak-dao/` | DAO governance contracts (DAOCommitteeProxy, DAOAgendaManager, etc.) |

### Optimism Interface Usage Example

```solidity
import { ISystemConfig } from "@optimism/interfaces/L1/ISystemConfig.sol";
import { IL1StandardBridge } from "@optimism/interfaces/L1/IL1StandardBridge.sol";
import { IOptimismPortal2 } from "@optimism/interfaces/L1/IOptimismPortal2.sol";
```

## Tokens

| Token | Role |
|-------|------|
| **TON** | Native token (18 decimals) |
| **WTON** | Wrapped TON (27 decimals, 1 TON = 1e9 WTON) |
| **Coinage** | Staking receipt token (created per L2) |

## External Systems

| System | Role |
|--------|------|
| **Optimism L2** | L2 rollups (Titan, Thanos, etc.) |
| **DisputeGameFactory** | Dispute Game creation (RAT trigger) |
| **OptimismPortal** | L1↔L2 bridge |
| **DAO** | Governance (DAOCommittee) |

## Documentation

| Document | Description |
|----------|-------------|
| [specs-kr/](./docs/specs-kr/) | V3 system specification (Korean) |
| [specs-kr/01-system-overview.md](./docs/specs-kr/01-system-overview.md) | System introduction, V3 changes, core concepts |
| [specs-kr/02-system-architecture.md](./docs/specs-kr/02-system-architecture.md) | Overall architecture, contract dependencies, proxy patterns |
| [specs-kr/03-contract-structure.md](./docs/specs-kr/03-contract-structure.md) | Directory structure, contract details, storage structure |
| [specs-kr/04-contract-roles.md](./docs/specs-kr/04-contract-roles.md) | Contract roles, responsibilities, interactions |
| [specs-kr/05-actors.md](./docs/specs-kr/05-actors.md) | Actor definitions (staker, sequencer, validator, challenger, DAO) |
| [specs-kr/06-function-specs.md](./docs/specs-kr/06-function-specs.md) | Function specifications, parameters, operation flows |

## License

MIT
