---
id: 00-intro
slug: /intro
sidebar_position: 0
---

# TON Staking V3 System Specification

> Based on Tokamak Economics Whitepaper V2 (December 2025)

## Document List

| Document | Description |
|----------|-------------|
| [System Overview](./01-system-overview.md) | System introduction, V3 changes, core concepts, main flows, parameters |
| [System Architecture](./02-system-architecture.md) | Overall architecture, contract dependencies, proxy patterns, rollup types, data flows |
| [Contract Structure](./03-contract-structure.md) | Directory structure, contract details, storage structure, interfaces, inheritance relationships |
| [Contract Roles](./04-contract-roles.md) | Roles, responsibilities, and interactions per contract (SeigManager, DepositManager, RAT, etc.) |
| [Actors](./05-actors.md) | Actor definitions, sequencer/validator journey guides, interactions |
| [Function Specifications](./06-function-specs.md) | Detailed function descriptions, parameters, operation flows, events |
| [Whitepaper Summary](./07-economics-whitepaper-summary.md) | Tokamak Economics Whitepaper V2 summary |
| [Upgrade Guide](./08-v2-to-v3-upgrade-guide.md) | V2 to V3 upgrade guide |
| [L2 Registration Guide](./09-layer2-registration-guide.md) | Layer2 registration guide |
| [Test List](./10-v3-test-lists.md) | V3 test list |
| [Seigniorage Cases](./11-seigniorage-update-cases.md) | Detailed analysis of seigniorage update cases |
| [Optimism Integration](./12-optimism-integration.md) | Optimism L2 integration (RAT, SeigManager linkage) |

## Core Contracts

| Contract | Role |
|----------|------|
| **SeigManagerV3_1** | Seigniorage calculation and distribution (V3 core) |
| **DepositManagerV3** | TON/WTON staking management |
| **Layer2ManagerV3** | L2 registration and Bridged TON queries |
| **L1BridgeRegistryV1_2** | Bridge/portal registration, TVL queries |
| **RAT** | Validator registration, RAT tests, C_off penalty |
| **ValidatorRewardV1** | Validator reward distribution |

## V3 Core Changes

| Item | V2 | V3 |
|------|-----|-----|
| Seigniorage distribution basis | L2 TVL | Bridged TON |
| Distribution function | Linear | Hyperbolic `y(x) = L·(x/(k+x))` |
| Eligibility condition | Minimum deposit | `T_i ≥ max(θ·B_i, D_seq)` |
| Staker seigniorage | Provided | Not provided |
| Validator reward | None | `α·S_i / |V_i|` |

## Core Parameters

| Parameter | Symbol | Description |
|-----------|--------|-------------|
| `daoDistributionRatio` | d | DAO distribution ratio |
| `minStakingRatio` | θ | Minimum staking ratio |
| `validatorDistributionRatio` | α | Validator distribution ratio |
| `halfSaturationPoint` | k | Half saturation point |
| `ratTriggerProbability` | π_a | RAT trigger probability |
| `slashingPenalty` | C_off | Validator slashing penalty |
| `evidenceSubmissionPeriod` | - | Evidence submission period |
