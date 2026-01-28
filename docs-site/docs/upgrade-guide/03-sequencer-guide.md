---
id: upgrade-sequencer-guide
sidebar_position: 3
---

# Sequencer Perspective

## Seigniorage Distribution Basis Change

### V2 (Current Mainnet Service)
```
Distribution basis: L2 TVL (Total Value Locked)
Distribution method: Linear proportional
```

### V3 (Upgrade)
```
Distribution basis: Bridged TON (Amount of TON bridged to L2)
Distribution method: Hyperbolic saturation function y(x) = L·(x/(k+x))
  - Performance-based distribution
  - Diminishing returns effect (prevents monopolization)
  - Eligibility conditions required
```

## New Eligibility Conditions

### V3 (Upgrade)
```solidity
Condition: T_i ≥ max(D_sequencer, θ · B_i)

Where:
- T_i: Sequencer's staking amount
- D_sequencer = H_max · C_max + Δ_sequencer
  - H_max: Maximum simultaneous challengers
  - C_max: Maximum cost per Fraud Proof
  - Δ_sequencer: Sequencer additional reward
- θ · B_i: 10% of Bridged TON (example)

⚠️ If condition not met: B̃_i = 0, that L2 does not receive seigniorage and is handled as undistributed portion
```

## Collateral System

**V3 Implementation**: Single staking serves both seigniorage receipt eligibility + slashing collateral (no separate collateral deposit needed)

**Collateral Query**:
- `SeigManager.getSequencerStaked(layer2)`: Query sequencer balance in L2 Coinage

## Slashing Policy Change

| Item | V2 (Current) | V3 (Upgrade) |
|------|-------------|--------------|
| **Slashing Target** | - | Full staking amount (`coinage.burnFrom()`) |
| **Seigniorage** | TVL proportional distribution | Cannot receive (eligibility lost) |
| **L2 Operation** | - | **Not stopped** |

In V3, when slashing occurs, the L2 is not physically stopped, only economic sanctions (seigniorage suspension + collateral confiscation) are applied.

## Sequencer Reward Calculation Method

```
Sequencer reward = (1-α) · S_i

Where:
- S_i = That L2's seigniorage = y(x) · (B̃_i / x)
- α = Validator distribution ratio (e.g., 20%)
- (1-α) = Sequencer share (e.g., 80%)
```

See [Technical Details](./05-technical-details.md) for detailed calculation logic.
