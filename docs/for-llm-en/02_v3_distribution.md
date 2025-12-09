# V3 Seigniorage Distribution Formula

## 1. V3 Seigniorage Distribution Flow (Including Transition Mechanism)

```
When updateSeigniorage() is called - Unified distribution formula:

═══════════════════════════════════════════════════════════════
Sequential distribution from total seigniorage A
═══════════════════════════════════════════════════════════════

A (Total Seigniorage)
│
├─► Step 1: Staker Share Seigniorage (λ applied)
│   S_staked = λ · A · (S / T)
│   - S: Total staking amount
│   - T: TON total supply
│   - S/T: Staking ratio
│   - λ: Share seigniorage ratio (decreases from 1→0 later)
│
│   A₁ = A - S_staked (1st remainder)
│
├─► Step 2: Staker Additional Seigniorage (r applied)
│   S_relative = A₁ · r
│   - r: relativeSeigRate (existing V2 parameter, decreases from 1→0 first)
│
│   A₂ = A₁ - S_relative (2nd remainder = V3 distribution source)
│
└─► Step 3: V3 Distribution (Whitepaper formula applied)
    │
    ├─► DAO Fixed Distribution (Whitepaper formula 7):
    │   S_DAO = d · A₂
    │
    ├─► L2 Distribution Capacity:
    │   L = (1 - d) · A₂
    │
    ├─► Eligibility Condition Check (Whitepaper formula 8):
    │   For each L2_i: S_i ≥ θ · B_i ?
    │
    ├─► Effective Bridged TON (Whitepaper formulas 9, 10):
    │   B̃_i = 1_i · B_i
    │   x = Σ B̃_i
    │
    ├─► Hyperbolic Saturation Function (Whitepaper formula 11):
    │   y(x) = L · (x / (k + x))
    │
    ├─► Per-L2 Seigniorage (Whitepaper formula 12):
    │   Seig_i = y(x) · (B̃_i / x)
    │
    ├─► Sequencer/Validator Distribution (Whitepaper formula 13):
    │   o_i = (1 - α_v) · Seig_i    // Sequencer
    │   v_total = α_v · y(x)        // Validator pool
    │
    └─► Undistributed Portion to DAO:
        Undistributed = L - y(x)
        totalDAO = S_DAO + Undistributed
```

---

## 2. Variable Descriptions

| Variable | Description |
|----------|-------------|
| **A** | Total period seigniorage (total amount to be issued) |
| **A₁** | Remaining amount after distributing staker share seigniorage (S_staked) |
| **A₂** | Remaining amount after distributing staker additional seigniorage (S_relative) → V3 distribution source (DAO + L2 Sequencer + Validators) |
| **S** | Total staking amount (WTON total supply) |
| **T** | TON total supply |
| **λ** | Share seigniorage ratio (stakedSeigFactor, decreases from 1→0) |
| **r** | Additional seigniorage ratio (relativeSeigRate, decreases from 1→0 first) |
| **d** | DAO distribution ratio (daoDistributionRatio) |
| **θ** | Minimum staking ratio (minStakingRatio) |
| **α_v** | Validator distribution ratio (validatorDistributionRatio) |
| **k** | Half-saturation point (halfSaturationPoint) |
| **L** | L2 distribution capacity = (1-d)·A₂ |
| **x** | Total effective Bridged TON = Σ B̃_i |
| **y(x)** | Hyperbolic saturation function result |

---

## 3. Mathematical Expression

```
S_staked   = λ · A · (S / T)
A₁         = A - S_staked
           = A · (1 - λ · S/T)

S_relative = A₁ · r
A₂         = A₁ - S_relative
           = A₁ · (1 - r)
           = A · (1 - λ · S/T) · (1 - r)
```

---

## 4. When V3 Fully Transitioned (λ = 0, r = 0)

```
λ = 0 → S_staked = 0 (no share seigniorage)
r = 0 → S_relative = 0 (no additional seigniorage)

∴ Nothing distributed to stakers

A₂ = A · (1 - 0) · (1 - 0) = A
→ All seigniorage distributed according to V3 formula in whitepaper
```

---

## 5. Distribution Examples by Transition Stage

**Transition Principle**: r (additional seigniorage) decreases first → λ (share seigniorage) decreases later

**Assumption**: S/T = 0.5

| Stage | λ | r | S_staked | S_relative | A₂ (V3) |
|-------|---|---|----------|------------|---------|
| V2   | 1.0 | 0.4 | 0.5A   | 0.2A       | 0.3A    |
| Transition 1 | 1.0 | 0.2 | 0.5A   | 0.1A       | 0.4A    |
| Transition 2 | 1.0 | 0.0 | 0.5A   | 0          | 0.5A    |
| Transition 3 | 0.5 | 0.0 | 0.25A  | 0          | 0.75A   |
| V3   | 0.0 | 0.0 | 0      | 0          | A (100%)|

---

## 6. Key Changes

- ❌ V2: Staking share proportional distribution → ✅ V3: Bridged TON proportional distribution
- ✅ **Gradual Transition**: Gradually move staker seigniorage to V3 distribution using λ, r parameters
- ❌ V2: TVL-based L2 rewards → ✅ V3: Performance (Bridged TON) based + eligibility conditions
- ❌ V2: No validator rewards → ✅ V3: α_v ratio distribution to validators
- ❌ V2: Linear distribution → ✅ V3: Hyperbolic saturation function (diminishing returns)

---

## 7. V2 → V3 Gradual Transition Mechanism

### 7.1 Transition Necessity

A sudden transition from V2 to V3 could cause price shocks in the market. To prevent this, we introduce a transition mechanism that **gradually decreases staker seigniorage**.

### 7.2 Transition Parameters

V2's staker seigniorage consists of two components:

| Category | V2 Formula | Description |
|----------|------------|-------------|
| **Share Seigniorage** | `stakedSeig` | Seigniorage based on staking share ratio |
| **Additional Seigniorage** | `relativeSeig` | Additional reward calculated as `unstakedSeig × relativeSeigRate` |

**Transition Parameters:**

```solidity
/// @notice Share seigniorage ratio (0 ~ RAY)
/// @dev λ = 1.0: Same as V2, λ = 0: No share seigniorage
uint256 public stakedSeigFactor;  // λ (new parameter)

/// @notice Additional seigniorage ratio - Reuse existing V2 parameter
/// @dev r = existing value: Same as V2, r = 0: No additional seigniorage
uint256 public relativeSeigRate;  // r (existing parameter, adjusted from 1→0)
```

### 7.3 Transition Scenarios

**Transition Principle**: Decrease r (additional seigniorage) first, then decrease λ (share seigniorage) later

- **Additional Seigniorage (S_relative)**: "Bonus" nature → Decrease r first
- **Share Seigniorage (S_staked)**: "Reward relative to principal" nature → Decrease λ later

```
Phase 0: V2 State (Before Transition)
─────────────────────────────────────
λ = 1.0 (100%), r = 0.4 (existing value)
→ Stakers: Receive same seigniorage as existing V2
→ V3 distribution: Partial (A₂ = 0.3A)

Phase 1: Additional Seigniorage Decrease Begins
─────────────────────────────────────
λ = 1.0 (100%), r = 0.2
→ Stakers: Maintain share seigniorage, 50% decrease in additional seigniorage
→ V3 distribution increases (A₂ = 0.4A)

Phase 2: Additional Seigniorage Completely Removed
─────────────────────────────────────
λ = 1.0 (100%), r = 0.0
→ Stakers: Only share seigniorage maintained, no additional seigniorage
→ V3 distribution increases (A₂ = 0.5A)

Phase 3: Share Seigniorage Decrease Begins
─────────────────────────────────────
λ = 0.5 (50%), r = 0.0
→ Stakers: 50% decrease in share seigniorage
→ V3 distribution increases (A₂ = 0.75A)

Phase 4: V3 Full Transition
─────────────────────────────────────
λ = 0.0 (0%), r = 0.0
→ Stakers: No seigniorage (used only for eligibility)
→ V3 full distribution (A₂ = A)
```

### 7.4 Transition Condition Decision Guide

Market indicators to consider when governance adjusts λ, r values:

| Indicator | Description | Transition Condition Example |
|-----------|------------|------------------------------|
| **Total Bridged TON** | Value used as V3 distribution basis | Accelerate transition when Bridged TON > 100M TON |
| **L2 Activity** | L2 transaction count, user count | Accelerate transition when active L2s > 10 |
| **Staking Ratio** | Staking ratio out of total TON | Accelerate transition when staking ratio stabilizes |
| **Staker APY** | Staker's annual return rate | Proceed with transition when APY is within target range |
| **TON Price Volatility** | Market stability indicator | Accelerate transition when volatility is low |

---

## 8. V3 Distribution Mechanism Details

### 8.1 V3: L2 Sequencer + Validator Seigniorage (RewardPerUint Method)

```solidity
// V3: Hyperbolic-based accumulated unit reward method
// Target: L2 Sequencers + Validators (excluding stakers)

// 1. Calculate total L2 seigniorage (hyperbolic function)
//    y(x) = L × (x / (k + x))
//    - L = (1-d)·A₂ : Distribution capacity
//    - x = Σ B̃_i  : Total effective Bridged TON
//    - k = Half-saturation point
totalY = rmul(l2MaxAllocation, rdiv(totalX, halfSaturationPoint + totalX))

// 2. Calculate reward per unit (determined by hyperbolic function)
//    rewardPerBridgedTON = y(x) / x = L / (k + x)
//    → As x increases, reward per unit decreases (diminishing returns)
bridgedTONRewardPerUint += (totalY × WEI_UNIT) / totalEffectiveBridgedTON

// 3. Calculate per-L2 reward (same pattern as V2)
layer2Seigs = (bridgedTONRewardPerUint × B̃_i) / WEI_UNIT - initialDebt_i

// 4. Separate sequencer/validator
sequencerReward = layer2Seigs × (1 - α_v)  // Sequencer
validatorPool += layer2Seigs × α_v          // Validator pool

// 5. Update initial debt
initialDebt_i = (bridgedTONRewardPerUint × newB̃_i) / WEI_UNIT
```

**V3 Characteristics:**
- `bridgedTONRewardPerUint`: Accumulated reward per Bridged TON unit
- Uses same `initialDebt` pattern (V2 compatible)
- **Diminishing Returns**: As total x increases, reward per unit `L/(k+x)` decreases

### 8.2 Comparison Diagram

```
V2: Linear Distribution
═══════════════════════════════════════
Reward per unit = Constant (independent of TVL)

Reward
 │        ┌────────────────────
 │       /
 │      /
 │     /
 │    /
 │   /
 │──/──────────────────────────► TVL
   0

V3: Hyperbolic Distribution (Diminishing Returns)
═══════════════════════════════════════
Reward per unit = L / (k + x) → Decreases as x↑

y(x)
 │                    ┌─────── L (Upper limit)
 │                 ╱
 │              ╱
 │           ╱
 │        ╱
 │     ╱
 │──╱──────────────────────────► x (Bridged TON)
   0   k
       └─ y(k) = L/2 (Half-saturation point)
```

### 8.3 Implementation Comparison Summary

| Category | V2 | V3 |
|----------|-----|-----|
| **Distribution Basis** | TVL (layer2Tvl) | Bridged TON (B̃_i) |
| **Reward per Unit** | `l2RewardPerUint` (fixed proportional) | `bridgedTONRewardPerUint` (hyperbolic) |
| **Accumulation Pattern** | ✅ Uses initialDebt | ✅ Uses initialDebt (same) |
| **Total Distribution** | `l2TotalSeigs = constant×TVL` | `y(x) = L×(x/(k+x))` |
| **Per Unit Formula** | `l2TotalSeigs / totalTVL` | `y(x) / x = L / (k+x)` |
| **Characteristic** | Linear (2× TVL = 2× reward) | Diminishing returns (marginal utility decreases) |

---

## 9. Whitepaper Formula vs Implementation Function Mapping

| Whitepaper Formula | Formula | V3 Implementation Function |
|-------------------|---------|---------------------------|
| (7) | `S_DAO = d · A₂` | `rmul(A2, daoDistributionRatio)` |
| (8) | `S_i ≥ θ · B_i` | `checkEligibility()` |
| (9) | `1_i = {1 if eligible, 0 otherwise}` | `getIndicator()` |
| (10) | `x = Σ B̃_i` | `totalEffectiveBridgedTON` (cached) |
| (11) | `y(x) = L · (x/(k+x))` | `hyperbolicSaturation()` |
| (12) | `Seig_i = y(x) · (B̃_i/x)` | `calculateL2Seigniorage()` |
| (13) | `v_i = (α_v/n)·y(x), o_i = (1-α_v)·Seig_i` | `ValidatorPool.distributePeriodRewards()`, `calculateSequencerReward()` |
