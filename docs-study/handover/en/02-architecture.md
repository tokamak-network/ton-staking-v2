# 2. System Architecture

## Overall Flow

```text
1) Game Creation
   DisputeGameFactory.create()
   └─> FaultDisputeGame.initialize(rat, winningChallengerTracker)

2) Challenge Execution
   Challengers perform move/attack/defend/step

3) Game Resolution & Winner Recording
   FaultDisputeGame.resolveClaim()
   ├─> _distributeBond(recipient, claim)           ← Bond distribution
   └─> _recordWinningChallenger(recipient)          ← Winner recording
        └─> WinningChallengerTracker.recordWinner(game, winner, gameCreator)

4) Slashing Execution & Reward Distribution
   Layer2Manager_Slashing.slashingCandidate()
   ├─> Verify game status (CHALLENGER_WINS)
   ├─> _getWinningChallengers(disputeGame)
   │    └─> WinningChallengerTracker.getWinningChallengers(game)
   └─> DepositManager_Slashing.slash(layer2, operator, challengers[])
        ├─> SeigManager.onSlash() → totalSlashed
        ├─> rewardAmount = totalSlashed * slashingRewardRate / 10000
        └─> _distributeRewards() → Even WTON distribution to each challenger
```

---

## Overall Structure Diagram

```text
┌───────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                      │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              Optimism Dispute System                   │ │
│  │                                                        │ │
│  │  DisputeGameFactory ──> FaultDisputeGame               │ │
│  │  - create()              - resolveClaim()              │ │
│  │  - setWCT()              - _distributeBond()           │ │
│  │       │                  - _recordWinningChallenger()  │ │
│  │       │                         │                      │ │
│  │       │     WinningChallengerTracker  <────────────┘   │ │
│  │       │     - recordWinner()                           │ │
│  │       │     - getWinningChallengers()                  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              TON Staking V3 System                     │ │
│  │                                                        │ │
│  │  Layer2Manager_Slashing ──> DepositManager_Slashing    │ │
│  │  - slashingCandidate()      - slash()                  │ │
│  │  - _getWinningChallengers() - _distributeRewards()     │ │
│  │       │                          │                     │ │
│  │       │ query                    │ transfer WTON       │ │
│  │       ▼                          ▼                     │ │
│  │  WinningChallenger           Challengers               │ │
│  │  Tracker                     (address[])               │ │
│  └──────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────┘
```

---

## Layer Structure

```text
┌─────────────────────────────────────────────────────┐
│ Layer 4: Application Layer                          │
│ - E2E Tests, Integration Tests, Monitoring          │
└─────────────────────────────────────────────────────┘
                        ▲
┌─────────────────────────────────────────────────────┐
│ Layer 3: Business Logic Layer                       │
│ - Layer2Manager_Slashing                            │
│ - DepositManager_Slashing                           │
│ - SeigManager_Slashing                              │
└─────────────────────────────────────────────────────┘
                        ▲
┌─────────────────────────────────────────────────────┐
│ Layer 2: Tracking Layer                             │
│ - WinningChallengerTracker                          │
│ - FaultDisputeGame (tracking logic)                 │
└─────────────────────────────────────────────────────┘
                        ▲
┌─────────────────────────────────────────────────────┐
│ Layer 1: Dispute Resolution Layer                   │
│ - DisputeGameFactory                                │
│ - FaultDisputeGame (core logic)                     │
│ - AnchorStateRegistry                               │
└─────────────────────────────────────────────────────┘
```

---

## Note on Depth & Bond Costs

Bond costs by Depth of the DisputeGame (increases by approximately 1.44x):

| Depth | Bond (ETH) | Phase |
|-------|------------|-------|
| 0 | 0 | Root Claim |
| 1 | 0.1156 | Output Bisection |
| 7 | 1.05 | Output Bisection |
| 14 (Split Depth) | 13.78 | Split Point → Transition to Execution Trace |
| 18 (Max Depth) | ~60.0 | Execution Trace (Max) |

**Recommended Capital for Challenger Operations**: Minimum 15 ETH (To handle Split Depth), Recommended 65 ETH (To handle Max Depth)

---

Next: [03-contracts.md](./03-contracts.md)
