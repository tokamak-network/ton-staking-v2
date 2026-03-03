# 1. Project Overview

## Purpose

The Advanced Slash system integrates the **Optimism Fault Proof Mechanism** with **TON Staking V3** to slash Operators who submit invalid L2 Output Proposals, and **distribute rewards evenly** among all participants who successfully challenge it.

### Core Objectives

1. **Fairness**: Provide equal rewards to all winning Challengers.
2. **Transparency**: Enable tracking of all winners on-chain.
3. **Efficiency**: Reward multiple participants with minimal Gas costs.
4. **Scalability**: Extensible to a weight-based reward system in the future.

---

## Issues with the Existing System

```text
Existing Structure (Single Challenger):

Layer2Manager_Slashing.slashingCandidate()
    ↓
_getWinningChallenger() → claimData(0).counteredBy  ← Records only the first counter
    ↓
DepositManager.slash(challenger) → Single reward

Problems:
- Only the first counter is recorded.
- The remaining Challengers do not receive rewards.
- Unfair incentive structure.
```

---

## Solution

Introducing an external `WinningChallengerTracker` contract to:

- Record the bond recipient (= winner) at the time of `resolveClaim()`.
- Automatically filter out the `gameCreator` (Proposer).
- Establish a mechanism to prevent duplicates.
- Distribute WTON evenly among all recorded winners upon slashing.

**EVM 24KB Limit Response**: Incorporating the tracking logic directly into the FaultDisputeGame exceeds the 24KB limit, so it was resolved by separating it into an external contract (`WinningChallengerTracker`).

---

## Implementation Status

| Phase | Content | Status |
|-------|---------|--------|
| **Phase 1**: Tracking Layer | Implementation of WinningChallengerTracker contract | ✅ Completed |
| **Phase 2**: Integration Layer | Integration of DisputeGameFactory, FaultDisputeGame | ✅ Completed |
| **Phase 3**: Slashing Layer | Support for multiple challengers in Layer2Manager, DepositManager | ✅ Completed |
| **Phase 4**: Foundry Unit Tests | 24 AdvancedSlashing + 38 BasicSlashing | ✅ All Passed |
| **Phase 5**: E2E Tests (Mock) | 41 Slashing logic tests (Anvil-based) | ✅ All Passed |
| **Phase 6**: E2E Tests (Real) | 11 Real FaultDisputeGame + op-challenger tests | ✅ All Passed |

---

## Future Extensibility (Not Implemented)

| Extension | Description |
|-----------|-------------|
| **Weight-based Rewards** | Differentiated distribution based on bond amount, number of moves, and participation time |
| **Time-based Incentives** | Bonus for early participants (+20% within 1 hour, +10% within 6 hours) |
| **Multi-chain Support** | Cross-chain challenger tracking |
| **Analytics** | Game statistics query function (`getGameStatistics`) |

For the reward distribution alternative option review document, refer to: `docs-study/AdvancedSlash/anotherOption/`
- Option A: Fixed ratio (50% for the first, the rest distributed evenly)
- Option B: Bonus + Even distribution (Bonus for the first + the rest distributed evenly)
- Option C: Weight-based (Weights based on bond size)

---

Next: [02-architecture.md](./02-architecture.md)
