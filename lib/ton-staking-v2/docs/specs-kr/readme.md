# TON Staking V3 System Specification

> Based on Tokamak Economics Whitepaper V2 (December 2025)

## Document List

| Document | Description |
|----------|-------------|
| [01-system-overview.md](./01-system-overview.md) | System introduction, V3 changes, core concepts, main flows, parameters |
| [02-system-architecture.md](./02-system-architecture.md) | Overall architecture, contract dependencies, proxy patterns, rollup types, data flow |
| [03-contract-structure.md](./03-contract-structure.md) | Directory structure, contract details, storage structure, interfaces, inheritance |
| [04-contract-roles.md](./04-contract-roles.md) | Contract roles, responsibilities, interactions (SeigManager, DepositManager, RAT, etc.) |
| [05-actors.md](./05-actors.md) | Actor definitions, sequencer/validator journey guides, interactions |
| [06-function-specs.md](./06-function-specs.md) | Function specifications, parameters, operation flows, events |
| [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md) | Tokamak Economics Whitepaper V2 summary |
| [08-v2-to-v3-upgrade-guide.md](./08-v2-to-v3-upgrade-guide.md) | V2 to V3 upgrade guide |
| [09-layer2-registration-guide.md](./09-layer2-registration-guide.md) | Layer2 registration guide |
| [10-v3-test-lists.md](./10-v3-test-lists.md) | V3 test lists |
| [11-seigniorage-update-cases.md](./11-seigniorage-update-cases.md) | Detailed seigniorage update cases analysis |
| [12-optimism-integration.md](./12-optimism-integration.md) | Optimism L2 integration (RAT, SeigManager hooks) |
| [13-rat-client-specification.md](./13-rat-client-specification.md) | RAT Client implementation and operations specification (Integrated: overview, implementation, deployment, operations) |

## Core Contracts

| Contract | Role |
|----------|------|
| **SeigManagerV3_1** | Seigniorage calculation and distribution (V3 core) |
| **DepositManagerV3** | TON/WTON staking management |
| **Layer2ManagerV3** | L2 registration and Bridged TON queries |
| **L1BridgeRegistryV1_2** | Bridge/portal registration, TVL queries |
| **RAT** | Validator registration, RAT tests, slashing |
| **ValidatorRewardV1** | Validator reward distribution |

## V3 Key Changes

| Category | V2 | V3 |
|----------|-----|-----|
| Seigniorage distribution basis | L2 TVL | Bridged TON |
| Distribution function | Linear | Hyperbolic `y(x) = L·(x/(k+x))` |
| Eligibility condition | Minimum deposit | `T_i ≥ max(θ·B_i, D_seq)` |
| Staker seigniorage | Provided | Not provided |
| Validator rewards | None | `α·S_i / |V_i|` |

## Core Parameters

| Parameter | Symbol | Description |
|-----------|--------|-------------|
| `daoDistributionRatio` | d | DAO distribution ratio |
| `minStakingRatio` | θ | Minimum staking ratio |
| `validatorDistributionRatio` | α | Validator distribution ratio |
| `halfSaturationPoint` | k | Half-saturation point |
| `ratTriggerProbability` | π_a | RAT trigger probability |
| `slashingPenalty` | C_off | Validator slashing penalty |
| `evidenceSubmissionPeriod` | - | Evidence submission period |

## Related Documents

- [deployment-guide.md](../deployment-guide.md): Deployment guide
- [for-llm-kr/](../for-llm-kr/): Detailed specifications for LLM
