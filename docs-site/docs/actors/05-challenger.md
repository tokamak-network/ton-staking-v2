---
id: actors-challenger
sidebar_position: 5
---

# Challenger

## Definition

Participants who submit Fraud Proofs against sequencer's incorrect state roots.

## Role

- Monitor L2 state
- Challenge in FaultDisputeGame when incorrect Output Root discovered
- Submit Fraud Proof

## Reward

```
Challenger reward = C_max + Δ_sequencer / n

Where:
- C_max = Maximum Fraud Proof cost
- Δ_sequencer = Sequencer additional collateral
- n = Number of challengers participating in challenge
```

## Validator as Challenger

In V3, validators can also act as challengers.

```
┌────────────────────────────────────────────────────────────┐
│                    Validator as Challenger                 │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  On Fraud Discovery:                                        │
│  1. Challenge in FaultDisputeGame                          │
│  2. On game win:                                           │
│     - Challenger reward: C_max + Δ/n                       │
│     - RAT collateral restoration: RAT.resolveClaim()        │
│                                                             │
│  RAT Response Methods (one of two):                        │
│  - submitEvidence: Direct evidence submission              │
│  - resolveClaim: Challenge win (fraud proof success)       │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## Interactions

```
┌────────────────────────────────────────────────────────────┐
│                         Challenger                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Challenge:                                          │   │
│  │   1. Discover incorrect Output Root                 │   │
│  │   2. FaultDisputeGame.attack() or defend()          │   │
│  │   3. Submit Fraud Proof                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ After Win:                                          │   │
│  │   Anyone: SeigManager.slashSequencerByGame(game)    │   │
│  │   → Pay challenger reward                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```
