---
id: upgrade-overview
sidebar_position: 1
---

# V2 → V3 Core Changes at a Glance

> **This document summarizes what actually changes when upgrading from TON Staking (V2) currently running on mainnet to V3, for easy understanding at a glance.**

## Current Service vs Upgrade Version

| Category | V2 (Current Mainnet Service) | V3 (Upgrade) |
|----------|------------------------------|--------------|
| **Contract Version** | SeigManagerV1_3 | SeigManagerV3_1 + RAT + ValidatorReward |
| **Seigniorage Recipients** | **DAO + Sequencer + General Stakers** | **DAO + Sequencer + Validators** |
| **Distribution Basis** | D/T ratio split between sequencer/stakers | Bridged TON based (performance-focused) |
| **Distribution Function** | Linear distribution | Hyperbolic saturation function `y(x) = L·(x/(k+x))` |
| **Validator Role** | None | RAT + seigniorage distribution |
| **DAO Allocation** | Fixed ratio (d·A) | Fixed ratio + undistributed portion |

## Core Change: Seigniorage Distribution Target Change

**V3 Direction**: Focus seigniorage on participants who directly operate and verify L2 networks

```
V2 (Current Mainnet Service):
  Seigniorage A
    ├─► DAO: d · A (fixed)
    │
    └─► Remaining (1-d) · A distributed by D/T ratio
        ├─► (D/T) × (1-d) · A → L2 Sequencers
        └─► (1 - D/T) × (1-d) · A → General Stakers

V3 (Upgrade):
  Seigniorage A
    ├─► DAO: d · A (fixed) + undistributed portion
    └─► Performance-based distribution to L2 operators and validators:
        ├─► Sequencer (L2 operator): (1-α) · S_i
        └─► Validator (L2 validator): α · S_i / |V_i|
```

General stakers can also receive seigniorage by participating as validators.
