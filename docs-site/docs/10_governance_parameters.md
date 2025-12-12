---
id: 10_governance_parameters
slug: /10_governance_parameters
---
# Governance Decision Parameters Integration

## 1. Overview

This document consolidates all parameters that **governance must decide** in the TON Staking V3 system. Each parameter significantly impacts protocol operation and is adjusted through DAO governance.

---

## 2. Complete Parameter List

### 2.1 V3 Seigniorage Distribution Parameters

| Parameter | Symbol | Description | Recommended Value | Unit |
|-----------|--------|-------------|-------------------|------|
| **daoDistributionRatio** | d | DAO fixed distribution ratio | 0.2e27 (20%) | RAY |
| **minStakingRatio** | θ | Minimum staking ratio (eligibility condition) | 0.1e27 (10%) | RAY |
| **validatorDistributionRatio** | α_v | Validator distribution ratio | 0.2e27 (20%) | RAY |
| **halfSaturationPoint** | k | Hyperbolic half-saturation point | 10,000,000e27 | RAY (TON) |

**Related Formulas:**
- Whitepaper (7): `S_DAO = d · A₂`
- Whitepaper (8): `S_i ≥ θ · B_i`
- Whitepaper (11): `y(k) = L/2`
- Whitepaper (13): `v_i = (α_v/n) · y(x)`

---

### 2.2 V2→V3 Transition Parameters

| Parameter | Symbol | Description | Initial Value | When V3 Fully Transitioned |
|-----------|--------|-------------|---------------|----------------------------|
| **stakedSeigFactor** | λ | Share seigniorage ratio | 1e27 (100%) | 0 |
| **relativeSeigRate** | r | Additional seigniorage ratio | 0.4e27 (40%) | 0 |

**Transition Principle:**
- Decrease r (additional seigniorage) to 0 first
- Decrease λ (share seigniorage) later
- On full transition, A₂ = A (all seigniorage distributed according to V3 formula)

---

### 2.3 Slashing Parameters

| Parameter | Symbol | Description | Recommended Value | Notes |
|-----------|--------|-------------|-------------------|-------|
| **maxChallengers** | H_max | Maximum simultaneous challengers | 10 | Protocol level |
| **maxFraudProofCost** | C_max | Maximum on-chain cost for single fraud proof | 10e27 (10 TON) | RAY unit |
| **penaltyFactor** | γ | Repeat violation penalty factor | TBD (γ > 1) | - |
| **slashingWindow** | - | Slashing window period | TBD | seconds |
| **minimumInitialDepositAmount** | - | V2 minimum collateral (backward compatibility) | 1000.1e27 | RAY unit |

**Related Formulas:**
- Whitepaper (1): `D_sequencer = H_max · C_max + Δ_sequencer`
- Whitepaper (2): `R_challenger = C_max + (Δ_sequencer / n)`
- Whitepaper (3): `D^(n) = γ^(n-1) · D^(1)`

---

### 2.4 Validator Pool Parameters

| Parameter | Description | Recommended Value | Notes |
|-----------|-------------|-------------------|-------|
| **minimumValidatorDeposit** | Minimum validator collateral | 10,000e27 (10K WTON) | RAY unit |
| **ratProbability** | RAT occurrence probability (π_a) | 0.01e27 (1%) | RAY unit |
| **ratResponseWindow** | RAT response window | 1 hours | seconds |

**Related Formulas:**
- Whitepaper (5): `D_validator ≥ (c_m · N) / π_a`
- Whitepaper (6): `D_validator = (c_m · N) / π_a + Δ_validator`

---

## 3. Parameter Classification

### 3.1 Protocol Level (Same for All)

Parameters applied system-wide:

```solidity
// Seigniorage distribution
uint256 public daoDistributionRatio;       // d
uint256 public minStakingRatio;            // θ
uint256 public validatorDistributionRatio; // α_v
uint256 public halfSaturationPoint;        // k

// Transition
uint256 public stakedSeigFactor;           // λ
uint256 public relativeSeigRate;           // r

// Slashing
uint256 public maxChallengers;             // H_max
uint256 public maxFraudProofCost;          // C_max
uint256 public penaltyFactor;              // γ
uint256 public slashingWindow;

// Validator
uint256 public minimumValidatorDeposit;
uint256 public ratProbability;             // π_a
uint256 public ratResponseWindow;
```

### 3.2 Individually Configurable

Parameters that sequencers/validators can set individually:

```solidity
// Per-sequencer additional reward (Δ_sequencer)
mapping(address => uint256) public sequencerAdditionalReward;

// Per-validator additional collateral (Δ_validator)
// Calculated as ValidatorInfo.depositAmount - minimumValidatorDeposit
```

---

## 4. Recommended Initial Settings

### 4.1 Initial Values at Deployment

```solidity
// ========================================
// V3 Seigniorage Distribution (RAY unit: 1e27)
// ========================================
daoDistributionRatio = 0.2e27;        // d = 20%
minStakingRatio = 0.1e27;             // θ = 10%
validatorDistributionRatio = 0.2e27; // α_v = 20%
halfSaturationPoint = 10_000_000e27; // k = 10M TON

// ========================================
// Transition Parameters (Start same as V2)
// ========================================
stakedSeigFactor = 1e27;              // λ = 100%
relativeSeigRate = 0.4e27;            // r = 40%

// ========================================
// Slashing Parameters
// ========================================
maxChallengers = 10;                   // H_max = 10
maxFraudProofCost = 10e27;             // C_max = 10 TON
minimumInitialDepositAmount = 1000.1e27; // Maintain V2 existing value
penaltyFactor = TBD;                   // γ: Governance decision needed
slashingWindow = TBD;                  // Governance decision needed

// ========================================
// Validator Pool Parameters
// ========================================
minimumValidatorDeposit = 10_000e27;  // Minimum 10K WTON
ratProbability = 0.01e27;             // π_a = 1%
ratResponseWindow = 1 hours;
```

---

## 5. Parameter Adjustment Guide

### 5.1 Seigniorage Distribution Adjustment

| Parameter | Effect When Increased | Effect When Decreased |
|-----------|----------------------|----------------------|
| **d (DAO Ratio)** | DAO revenue increases, L2 incentives decrease | DAO revenue decreases, L2 incentives increase |
| **θ (Minimum Staking)** | Eligibility conditions strengthen, participating L2s decrease | Eligibility conditions relax, participating L2s increase |
| **α_v (Validator Ratio)** | Validator revenue increases, sequencer revenue decreases | Validator revenue decreases, sequencer revenue increases |
| **k (Half-saturation Point)** | Saturation speed decreases, favors large L2s | Saturation speed increases, favors small L2s |

### 5.2 Transition Parameter Adjustment

Market indicators to consider when governance adjusts λ, r values:

| Indicator | Description | Transition Condition Example |
|-----------|-------------|------------------------------|
| **Total Bridged TON** | Value used as V3 distribution basis | Accelerate transition when Bridged TON > 100M TON |
| **L2 Activity** | L2 transaction count, user count | Accelerate transition when active L2s > 10 |
| **Staking Ratio** | Staking ratio out of total TON | Accelerate transition when staking ratio stabilizes |
| **Staker APY** | Staker's annual return rate | Proceed with transition when APY is within target range |
| **TON Price Volatility** | Market stability indicator | Accelerate transition when volatility is low |

### 5.3 Slashing Parameter Adjustment

| Parameter | Effect When Increased | Effect When Decreased |
|-----------|----------------------|----------------------|
| **H_max** | More challengers can participate | Challenger participation limited |
| **C_max** | Challenger rewards increase, sequencer collateral increases | Challenger rewards decrease |
| **γ (Penalty Factor)** | Repeat violation deterrence strengthens | Repeat violation deterrence weakens |
| **slashingWindow** | Violations accumulate over longer period | Violations accumulate only over shorter period |

---

## 6. Gradual Transition Schedule Example

| Phase | Timing | λ | r | Notes |
|-------|--------|---|---|-------|
| Phase 0 | At deployment | 1.0 | 0.4 | Same as V2 |
| Phase 1 | +1 month | 1.0 | 0.2 | Additional seigniorage 50% decrease |
| Phase 2 | +2 months | 1.0 | 0.0 | Additional seigniorage completely removed |
| Phase 3 | +3 months | 0.7 | 0.0 | Share seigniorage 30% decrease |
| Phase 4 | +4 months | 0.4 | 0.0 | Share seigniorage 60% decrease |
| Phase 5 | +5 months | 0.0 | 0.0 | V3 full transition |

---

## 7. Undecided Parameters (TBD)

Parameters requiring governance decisions:

| Parameter | Description | Considerations When Deciding |
|-----------|-------------|------------------------------|
| **penaltyFactor (γ)** | Repeat violation penalty factor | 1.5~2.0 recommended, balance between deterrence and fairness |
| **slashingWindow** | Slashing window period | 1 week~1 month recommended, consider sequencer recovery opportunity |

---

## 8. Configuration Function List

### 8.1 SeigManagerV1_4

```solidity
function setDaoDistributionRatio(uint256 ratio) external onlyOwner;
function setMinStakingRatio(uint256 ratio) external onlyOwner;
function setValidatorDistributionRatio(uint256 ratio) external onlyOwner;
function setHalfSaturationPoint(uint256 k) external onlyOwner;
function setStakedSeigFactor(uint256 lambda) external onlyOwner;
function setRelativeSeigRate(uint256 rate) external onlyOwner;
function setValidatorPool(address pool) external onlyOwner;
```

### 8.2 Slashing Contract

```solidity
function setMaxChallengers(uint256 hMax) external onlyOwner;
function setMaxFraudProofCost(uint256 cMax) external onlyOwner;
function setPenaltyFactor(uint256 gamma) external onlyOwner;
function setSlashingWindow(uint256 window) external onlyOwner;
function setMinimumInitialDepositAmount(uint256 amount) external onlyOwner;
```

### 8.3 ValidatorPoolV1

```solidity
function setMinimumValidatorDeposit(uint256 amount) external onlyOwner;
function setRatProbability(uint256 probability) external onlyOwner;
function setRatResponseWindow(uint256 window) external onlyOwner;
```

---

## 9. References

- **Tokamak Economics Whitepaper V2**
- **[02_v3_distribution.md](./02_v3_distribution.md)**: V3 distribution formula details
- **[03_sequencer_slashing.md](./03_sequencer_slashing.md)**: Slashing system details
- **[08_implementation.md](./08_implementation.md)**: Implementation code
- **[09_migration.md](./09_migration.md)**: Migration guide
