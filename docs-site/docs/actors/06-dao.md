---
id: actors-dao
sidebar_position: 6
---

# DAO

## Definition

The governance entity of Tokamak Network (DAOCommittee).

## Role

- Set system parameters
- Upgrade contracts
- Execute V3 migration
- Emergency measures (pause, etc.)
- **Recover RAT forfeited collateral and stake in DAO name** (V3 new)

## Reward

```
DAO reward = d · A + (L - y(x)) + Σ(α·S_i for L2s with no validators) + RAT forfeited collateral
             ─────────────────────────────────────────────────────────   ───────────────────────
             Seigniorage-based rewards                                    Penalty-based income

Where:
- d · A = Fixed distribution (handled by SeigManagerV3_1)
- L - y(x) = Undistributed portion (handled by SeigManagerV3_1)
- α·S_i (|V_i|=0) = Validator share for L2s with no validators (handled by ValidatorRewardV1)
- RAT forfeited collateral = Forfeited C_off when validator fails to respond (recovered from RAT)
  * Source: Validator's staking collateral (penalty unrelated to seigniorage)
  * See section below for detailed process
```

### Implementation Details

| Reward Source | Processing Contract | Target Address | Claim Method | Source Type |
|---------------|---------------------|----------------|--------------|-------------|
| Fixed distribution (d · A) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) | Automatic transfer | Seigniorage (newly minted) |
| Undistributed portion (L - y(x)) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) | Automatic transfer | Seigniorage (newly minted) |
| L2s with no validators (α·S_i) | `ValidatorRewardV1.distributeL2Rewards()` | `SeigManager.dao` (daoVault) | Automatic transfer | Seigniorage (newly minted) |
| RAT forfeited collateral | `RAT.withdrawSlashingsToTreasury()` | RAT.treasury | Manual call required | **Validator staking (penalty)** |

> **Note**: 
> - `SeigManager.dao` stores the daoVault address.
> - **RAT forfeited collateral is a penalty deducted from validator's existing staking collateral (coinage), not seigniorage.** See below for detailed process.

## RAT Forfeited Collateral Recovery (V3 New)

If a validator fails to respond to RAT, the collateral (C_off) is first transferred to staking under the RAT contract's name. After the challenge period expires and forfeiture is confirmed, the DAO can recover it under the Treasury's name.

**Important**: RAT forfeited collateral is **a penalty deducted from validator's existing staking collateral, not seigniorage (newly minted)**.

### 3-Stage Process

**Stage 1: Pre-deduction (on RAT trigger)**
```
Automatically processed when triggerAttentionTest() is called:
- Deduct C_off from validator's coinage
- Transfer to RAT contract's coinage
```

**Stage 2: Recovery or Retention (challenge period)**
```
Upon validator response:
- submitEvidence() success → RAT's → returned to validator's
- No response → retained under RAT's name (during challenge period)
```

**Stage 3: DAO Recovery (after full forfeiture confirmed)**
```solidity
// DAO manually calls
RAT.withdrawSlashingsToTreasury(systemConfig);

// Call conditions:
// - latestDeadlineTest + challengeGameDuration + safetyBuffer elapsed
// - RAT contract's L2 coinage balance > 0

// Processing result:
// - RAT's coinage → transfer to Treasury's coinage
// - Treasury acquires staking share in the L2
// - Treasury can receive seigniorage distribution in the future
// - DAO can unstake via DepositManager.requestWithdrawal()
```

### Timing and Effects

| Stage | Timing | Status | Recovery Possible |
|-------|--------|--------|-------------------|
| Pre-deduction | Immediately on RAT trigger | Validator → RAT's | ✅ Possible (evidence submission or Fraud Proof) |
| Challenge period | `latestDeadlineTest` ~ `+ challengeGameDuration` | Retained under RAT's | ✅ Possible |
| DAO recovery available | After `+ challengeGameDuration + safetyBuffer` | RAT's → Treasury's | ❌ Impossible (fully forfeited) |

**Final Effects**:
- Treasury holds staking share in the L2 → can receive seigniorage
- DAO secures additional income source
- Can withdraw TON/WTON via `DepositManager.requestWithdrawal()` and `processRequest()` at any time

## Permissions

| Function | Description |
|----------|-------------|
| `setDaoDistributionRatio(d)` | Set DAO distribution ratio |
| `setMinStakingRatio(θ)` | Set minimum staking ratio |
| `setValidatorDistributionRatio(α)` | Set validator distribution ratio |
| `setHalfSaturationPoint(k)` | Set half saturation point |
| `setSlashingPenalty(C_off)` | Set slashing penalty |
| `setRatTriggerProbability(π_a)` | Set RAT trigger probability |
| `setEvidenceSubmissionPeriod(period)` | Set evidence submission period |
| `migrateToV3()` | Activate V3 mode |
| `pause()` / `unpause()` | System pause/resume |
| `withdrawSlashingsToTreasury(systemConfig)` | Recover RAT forfeited collateral |
