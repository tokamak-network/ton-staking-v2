---
id: actors-overview
sidebar_position: 1
---

# Actor Overview

Defines the main actors that interact in the TON Staking V3 system.

| Actor | Role | Reward | Risk |
|-------|------|--------|------|
| **Staker** | TON staking | None in V3 | None |
| **Sequencer** | L2 operation, batch submission | (1-α)·S_i | Collateral slashing |
| **Validator** | L2 batch verification, RAT response | α·S_i/\|V_i\| | C_off slashing |
| **Challenger** | Fraud Proof submission | C_max + Δ/n | Gas cost loss |
| **DAO** | Governance, parameter settings | d·A + undistributed portion | None |
| **L2 Proposer** | Output Root submission | - | - |

## Actor Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Actor Relationship Diagram                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│                                ┌─────────────┐                                  │
│                                │     DAO     │                                  │
│                                │ (Governance)│                                  │
│                                └──────┬──────┘                                  │
│                                       │                                          │
│              ┌────────────────────────┼────────────────────────┐                │
│              │ Parameter Settings     │ Reward Receipt          │                │
│              ▼                        ▼                        ▼                │
│  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐      │
│  │    Sequencer     │      │    Validator     │      │     Staker       │      │
│  │                  │      │                  │      │                  │      │
│  │ Collateral: T_i  │      │ Collateral: D_valid│      │ Staking: -      │      │
│  │ Reward: (1-α)·S_i│      │ Reward: α·S_i/|V| │      │ Reward: None (V3)│      │
│  │ Risk: Full Slashing│      │ Risk: C_off      │      │ Risk: None      │      │
│  └────────┬─────────┘      └────────┬─────────┘      └──────────────────┘      │
│           │                         │                                           │
│           │ Invalid Batch          │ Challenge Role                             │
│           ▼                         ▼                                           │
│  ┌────────────────────────────────────────────────────────────────┐             │
│  │                      Challenger                                 │             │
│  │  Reward: C_max + Δ/n (on Fraud Proof success)                   │             │
│  │  Risk: Gas cost loss                                            │             │
│  └────────────────────────────────────────────────────────────────┘             │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Requirements per Actor

### Technical Requirements

| Actor | Node Operation | 24/7 Availability | Capital | Technical Capability |
|-------|----------------|-------------------|---------|---------------------|
| Staker | X | X | TON | Low |
| Sequencer | O (L2) | O | High | High |
| Validator | O (L2 monitoring) | O | Medium | Medium |
| Challenger | O (L2 verification) | X | Gas cost | High |

### Economic Requirements

| Actor | Minimum Collateral | Expected Reward | ROI |
|-------|-------------------|-----------------|-----|
| Sequencer | max(θ·B_i, H_max·C_max + Δ) | (1-α)·S_i | Variable |
| Validator | C_off + Δ_val | α·S_i/\|V_i\| | Variable |
| Challenger | Gas cost | C_max + Δ/n | Variable |
