---
id: functions-overview
sidebar_position: 1
---

# Function Specifications Overview

This section provides detailed specifications for all TON Staking V3 contract functions.

## Quick Reference

| Contract | Main Functions | Purpose |
|----------|----------------|---------|
| **SeigManager** | `updateSeigniorage`, `checkCurrentEligibility`, `migrateToV3` | Seigniorage calculation & distribution |
| **DepositManager** | `deposit`, `requestWithdrawal`, `processRequest` | TON/WTON staking management |
| **Layer2Manager** | `getBridgedTon`, `getLayer2BySystemConfig` | L2 registration & Bridged TON queries |
| **L1BridgeRegistry** | `layer2Tvl`, `registerRollupConfig`, `upgradeToType3` | Bridge/portal registration, TVL queries |
| **RAT** | `registerValidator`, `triggerAttentionTest`, `submitEvidence` | Validator registration, RAT tests |
| **ValidatorReward** | `distributeL2Rewards`, `claimAllRewards` | Validator reward distribution |
| **SeigManager (Slashing)** | `slashSequencerByGame` | Sequencer slashing |
| **OperatorManagerFactory** | `createOperatorManager` | Operator manager deployment |

## Governance Parameters

### SeigManager Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `daoDistributionRatio` | `setDaoDistributionRatio(d)` | 0 < d < 1 | RAY |
| `minStakingRatio` | `setMinStakingRatio(θ)` | 0 < θ ≤ 1 | RAY |
| `validatorDistributionRatio` | `setValidatorDistributionRatio(α)` | 0 < α < 1 | RAY |
| `halfSaturationPoint` | `setHalfSaturationPoint(k)` | k > 0 | RAY (TON) |

### RAT Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `slashingPenalty` | `setSlashingPenalty(C_off)` | C_off > 0 | TON |
| `validatorBuffer` | `setValidatorBuffer(Δ)` | Δ ≥ 0 | TON |
| `ratTriggerProbability` | `setRatTriggerProbability(π_a)` | 0 < π_a ≤ 1 | RAY |
| `minimumThreshold` | `setMinimumThreshold(D_min)` | D_min > 0 | TON |
| `evidenceSubmissionPeriod` | `setEvidenceSubmissionPeriod(t)` | t > 0 | seconds |
| `validatorReward` | `setValidatorReward(addr)` | addr != 0 | address |

### ValidatorReward Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `seigManager` | `setSeigManager(addr)` | addr != 0 | address |
| `ratContract` | `setRatContract(addr)` | addr != 0 | address |

### Sequencer Slashing Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | count |

## Related Documents

- [System Overview](../01-system-overview.md)
- [System Architecture](../02-system-architecture.md)
- [Contract Structure](../03-contract-structure.md)
- [Contract Roles](../04-contract-roles.md)
- [Actors](../actors/actors-overview.md)
