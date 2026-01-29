---
id: 07-economics-whitepaper-summary
sidebar_position: 7
---
# Tokamak Economics Whitepaper V2 Summary

## Overview

This whitepaper explains Tokamak Network's economic model and introduces **TON Staking V3**, a new performance-based reward distribution model.

---

## 1. Verification Economics

### 1.1 Blockchain Scalability Problem
- Ethereum prioritizes decentralization and security, but this limits throughput
- **Layer 2 rollups** have been adopted as the standard scaling solution
- Rollup types:
  - **Optimistic Rollup**: Assumes validity by default, verified through fraud proof
  - **ZK Rollup**: Requires validity proof for each batch

### 1.2 Tokamak Network Ecosystem Components

| Component | Role |
|-----------|------|
| **Sequencer** | Collects, orders, executes transactions and submits state commits to L1 |
| **Validator** | Monitors L2 activity, can submit fraud proofs |
| **TON DAO** | Sets protocol parameters, manages finances, governance |

### 1.3 Risk Mitigation Mechanisms

**RAT (Randomized Attention Test)**
- Randomly selects validators to require verification of specific L2 batches
- Validators who don't respond or act dishonestly are slashed
- Designed so that avoiding verification is not a dominant strategy

**Fast Withdrawal**
- Users can receive L1 assets immediately without waiting for challenge period
- Liquidity providers pre-fund assets and collect fees

---

## 2. TON Utility

### 2.1 L2 Security (3-Tier Structure)

| Tier | Name | Description |
|------|------|-------------|
| **Tier 1** | Public Challenge (Fraud Proof) | Anyone can submit fraud proof. Disputes sequencer's incorrect state transitions |
| **Tier 2** | Dedicated Validators | Dedicated validators monitor sequencer state transitions and raise disputes |
| **Tier 3** | RAT (Randomized Attention Test) | Randomly selects validators to require L2 batch verification and proof submission |

> - Tier 1+2: Economic security mechanism for sequencers
> - Tier 3: Security model for validators (verifies validators are actually monitoring)

**Sequencer Collateral Condition:**
```
T_i ≥ max(H_max × C_max + Δ_sequencer, θ × B_i)

Where:
- T_i = Sequencer staking amount
- H_max × C_max + Δ_sequencer = Covers challenger reward on Fraud Proof slashing
- θ × B_i = Seigniorage eligibility (proportional to TVL)
```

**Validator Collateral Formula:**
```
D_validator = C_off + Δ_validator

Where:
- C_off = Slashing penalty on RAT non-response
- Δ_validator = Additional buffer
```

### 2.2 L2 Gas
- TON is the **native gas token** for transaction execution on L2
- L2 transaction volume increase → TON demand increase

### 2.3 DAO Governance
- TON is the **sole governance asset** of Tokamak Network
- Governance influence determined by amount of staked TON

---

## 3. Seigniorage

### 3.1 Seigniorage Generation
- Fixed issuance of **3.92 TON per block**
- Annual issuance: approximately **10,301,760 TON** (post-Merge)
- Initial inflation rate: ~19%, ~7.3% after 10 years, ~1.9% after 50 years

### 3.2 TON Staking V3 Core Rules

| Rule | Content |
|------|---------|
| **Rule 1** | Annual seigniorage issuance A is fixed |
| **Rule 2** | Fixed ratio allocation to DAO: `S_DAO = d × A` |
| **Rule 3** | L2 performance measured by **Bridged TON** amount |
| **Rule 4** | Minimum staking requirement: `T_i ≥ max(H_max × C_max + Δ_sequencer, θ × B_i)` |

### 3.3 Seigniorage Distribution Formula

**Total L2 Seigniorage (Hyperbolic Saturation Function):**
```
y(x) = L × (x / (k + x))
```
- L: Upper limit of seigniorage allocated to L2s `(1-d) × A`
- k: Half saturation point (x = k when y = L/2)
- **Diminishing returns** applied as performance increases

**Individual L2 Seigniorage:**
```
S_i = y(x) × (B̃_i / x)
```

**Validator/Sequencer Distribution:**
```
Validator j reward: v_j = Σ (α × S_i / |V_i|)
Sequencer i reward: o_i = (1 - α) × S_i
```

---

## Key Summary

1. **TON is a multi-purpose asset**: Security collateral, gas token, governance asset
2. **V3 is performance-based distribution**: Reward distribution based on Bridged TON (not simple staking amount)
3. **Diminishing returns structure**: Prevents excessive reward concentration in large L2s
4. **RAT mechanism**: Encourages continuous monitoring by validators
5. **Sustainable economic structure**: L2 growth → TON demand increase → virtuous cycle of ecosystem expansion
