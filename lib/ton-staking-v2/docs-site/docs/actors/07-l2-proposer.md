---
id: actors-l2-proposer
sidebar_position: 7
---

# L2 Proposer

## Definition

The operating entity that submits L2 state (Output Root) to L1. Usually operated by the sequencer.

## Role

- Calculate Output Root
- Call DisputeGameFactory.create()
- Trigger RAT (indirectly)

## Interactions

```
┌────────────────────────────────────────────────────────────┐
│                       L2 Proposer                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Output Root Submission:                              │   │
│  │   1. Calculate Output Root from L2 state              │   │
│  │   2. DisputeGameFactory.create(gameType, claim, .)   │   │
│  │   3. Internally calls RAT.triggerAttentionTest()      │   │
│  │      (Probability: π_a)                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```
