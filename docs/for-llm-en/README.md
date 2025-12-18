# TON Staking V3 Smart Contract Implementation Specification

> **Reference Document**: [Tokamak_Economics_Whitepaper.pdf](../Tokamak_Economics_Whitepaper.pdf)

## Overview

This document is a specification for implementing the V3 system by upgrading the existing TON Staking V2 contracts, based on the **Tokamak Economics Whitepaper V2**.

### Key Changes in V3

| Category | V2 | V3 |
|----------|-----|-----|
| **Seigniorage Distribution Basis** | L2 TVL (Simple Proportional) | Bridged TON (Performance-Based) |
| **Distribution Function** | Linear Distribution | Hyperbolic Saturation Function y(x) = L·(x/(k+x)) |
| **Eligibility Condition** | Minimum Deposit Only | S_i ≥ θ·B_i (SequencerVault Collateral Based) |
| **Validator Rewards** | None | α_v·y(x) / n (RAT-Based) |
| **DAO Allocation** | Fixed Ratio | Fixed Ratio + Undistributed Portion |

---

## Document Structure

This specification is organized as follows:

| Document | Content |
|----------|---------|
| **[01_v2_architecture.md](./01_v2_architecture.md)** | V2 Architecture Analysis, Coinage/RewardPerUint Mechanisms, Storage Structure |
| **[02_v3_distribution.md](./02_v3_distribution.md)** | V3 Distribution Formulas, V2→V3 Gradual Transition Mechanism, Hyperbolic Function |
| **[03_sequencer_slashing.md](./03_sequencer_slashing.md)** | Sequencer Slashing, Challenger Rewards, Repeat Violation Penalties |
| **[04_validator.md](./04_validator.md)** | Validator Registration/Withdrawal, Collateral, RAT System, Validator Rewards |
| **[05_validator_slashing.md](./05_validator_slashing.md)** | Validator Slashing, RAT Non-Response Handling, Pre-deduction-Recovery Mechanism |
| **[06_bridged_ton_tracking.md](./06_bridged_ton_tracking.md)** | Bridged TON Tracking System, Callback Interface |
| **[07_rat_implementation.md](./07_rat_implementation.md)** | RAT Implementation Design (Optimism Reference), IRAT/RATStorage/RAT.sol |
| **[08_implementation.md](./08_implementation.md)** | SeigManagerV1_4, ValidatorPoolV1, Layer2ManagerV1_2 Implementation Code |
| **[09_migration.md](./09_migration.md)** | Migration Guide, Test Checklist, Deployment Parameters |
| **[10_governance_parameters.md](./10_governance_parameters.md)** | Governance Decision Parameters Integration, Adjustment Guide, Undecided Items |

---

## Core Formula Summary

### Variable Definitions

| Variable | Description |
|----------|-------------|
| **A** | Total Period Seigniorage (Total Amount to be Issued) |
| **A₁** | Remaining Amount After Distributing Staker Share Seigniorage (S_staked) |
| **A₂** | Remaining Amount After Distributing Staker Additional Seigniorage (S_relative) → V3 Distribution Source |
| **S** | Total Staking Amount (WTON Total Supply) |
| **T** | TON Total Supply |
| **λ** | Share Seigniorage Ratio (stakedSeigFactor, decreases from 1→0) |
| **r** | Additional Seigniorage Ratio (relativeSeigRate, decreases from 1→0 first) |

### V2→V3 Gradual Transition Formula

```
S_staked   = λ · A · (S / T)
A₁         = A - S_staked
           = A · (1 - λ · S/T)

S_relative = A₁ · r
A₂         = A₁ - S_relative
           = A₁ · (1 - r)
           = A · (1 - λ · S/T) · (1 - r)

When V3 Fully Transitioned (λ = 0, r = 0):
A₂ = A · (1 - 0) · (1 - 0) = A
→ All seigniorage is distributed according to V3 formula in the whitepaper
```

### Whitepaper Core Formulas

| Formula No. | Formula | Description |
|-------------|---------|-------------|
| (7) | `S_DAO = d · A₂` | DAO Fixed Distribution |
| (8) | `S_i ≥ θ · B_i` | L2 Eligibility Condition |
| (9) | `1_i = {1 if eligible, 0 otherwise}` | Eligibility Indicator Function |
| (10) | `x = Σ B̃_i` | Total Effective Bridged TON |
| (11) | `y(x) = L · (x/(k+x))` | Hyperbolic Saturation Function |
| (12) | `Seig_i = y(x) · (B̃_i/x)` | L2 Seigniorage |
| (13) | `o_i = (1-α_v)·Seig_i`, `v_i = (α_v/n)·y(x)` | Sequencer/Validator Distribution |

---

## Contract Structure

### Upgrade Targets

```
contracts/
├── stake/
│   ├── managers/
│   │   ├── SeigManagerV1_3.sol       → SeigManagerV1_4.sol (upgrade)
│   │   ├── DepositManagerV1_2.sol    → DepositManagerV1_3.sol (upgrade)
│   │   └── SeigManagerV1_4Storage.sol (new)
├── layer2/
│   ├── Layer2ManagerV1_1.sol         → Layer2ManagerV1_2.sol (upgrade)
│   └── L1BridgeRegistryV1_1.sol      → L1BridgeRegistryV1_2.sol (upgrade)
└── [V3 New]
    └── validator/
        ├── RAT.sol                   (new) - Optimism reference
        ├── RATStorage.sol            (new)
        └── interfaces/
            └── IRAT.sol              (new)
```

### V3 Core Parameters

```solidity
// Whitepaper-based parameters (RAY unit: 1e27)
uint256 public daoDistributionRatio;      // d: DAO fixed ratio (0.2e27 = 20%)
uint256 public minStakingRatio;           // θ: Minimum staking ratio (0.1e27 = 10%)
uint256 public validatorDistributionRatio; // α_v: Validator distribution ratio (0.2e27 = 20%)
uint256 public halfSaturationPoint;       // k: Half-saturation point (10_000_000e27 TON)
uint256 public stakedSeigFactor;          // λ: Share seigniorage ratio (for transition)
```

---

## References

- **Tokamak Economics Whitepaper V2**
- **TON Staking V2 Documentation**: `tokamak-network/ton-staking-v2/docs/kr/ton-staking-v2.md`
- **V2 Codebase**: `tokamak-network/ton-staking-v2/contracts/`

