---
id: upgrade-staker-guide
sidebar_position: 2
---

# General Staker Perspective

## Seigniorage Distribution Target Change

```
V2 (Current): TON staking → Receive seigniorage according to staking ratio
V3 (Upgrade): TON staking → Receive seigniorage when participating in L2 operation/verification
```

**Why the change?**
- V3 focuses on **strengthening L2 network security**
- Concentrate seigniorage distribution to **actual network operation/verification participants**
- Incentive redesign for L2 ecosystem activation

## What Doesn't Change

- Existing TON staking method **remains the same**
- Deposit/withdrawal process through DepositManager **identical**
- Staking itself continues to be possible

## New Participation Methods

**Participate as Validator**: Contribute to L2 network security while receiving seigniorage ([See Validator Guide](./04-validator-guide.md))
- Can register as validator while maintaining existing staking
- Can receive seigniorage without additional funds

## DAO Governance

### Existing Permissions Maintained
- Receive DAO fixed distribution ratio (d·A)

### New Permissions
- **Execute V3 Migration** (`migrateToV3()`)
- **Control Validator Entry Policy**
  - Set `relaxedValidatorCheck` flag
  - `true`: Lower validator entry barrier (recommended initially)
  - `false`: Strengthen validator security standards (after growth)
- **V3 Parameter Settings**
  - `daoDistributionRatio` (d): DAO distribution ratio
  - `minStakingRatio` (θ): Minimum staking ratio relative to sequencer's Bridged TON (e.g., 10%)
  - `validatorDistributionRatio` (α): Validator distribution ratio
  - `halfSaturationPoint` (k): Hyperbolic function half saturation point

### Additional Revenue
- Undistributed seigniorage automatically goes to DAO
  - Ineligible L2s excluded from y(x) calculation, handled as undistributed portion (L - y)
