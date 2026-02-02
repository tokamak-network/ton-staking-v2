---
id: 01-system-overview
sidebar_position: 1
---
# TON Staking V3 System Overview

## 1. System Introduction

TON Staking V3 is Tokamak Network's staking and seigniorage distribution system. It operates on Ethereum L1 and interacts with multiple L2 rollups (Titan, Thanos, etc.) to provide network security and economic incentives.

### 1.1 Major V3 Changes

| Category | V2 | V3 |
|----------|-----|-----|
| **Seigniorage distribution basis** | L2 TVL (simple proportional) | Bridged TON (performance-based) |
| **Distribution function** | Linear distribution | Hyperbolic saturation function `y(x) = L·(x/(k+x))` |
| **Eligibility condition** | Minimum deposit only | T_i ≥ max(θ·B_i, D_seq) |
| **Validator reward** | None | α·y(x) / n (validator pool distribution) |
| **DAO allocation** | Fixed ratio | Fixed ratio + undistributed portion |
| **Staker seigniorage** | Provided | **Not provided** (removed in V3) |

---

## 2. System Purpose

### 2.1 Core Objectives

1. **L2 Network Security**: Incentivize L2 operators (sequencers) to act honestly through seigniorage incentives
2. **Validator Participation**: Motivate validators to continuously monitor the network through RAT (Randomized Attention Test)
3. **Fair Reward Distribution**: Distribute rewards based on actual network contribution using Bridged TON
4. **DAO Governance**: Manage system parameter adjustments and upgrades through DAO

### 2.2 Economic Mechanism

```
Total Seigniorage A
    │
    ├─► DAO Fixed Distribution: S_DAO = d · A
    │
    └─► L2 Distribution Pool: L = (1-d) · A
        │
        ├─► Hyperbolic Function: y(x) = L · (x / (k + x))
        │   │
        │   ├─► L2 Seigniorage: S_i = y(x) · (B̃_i / x)
        │   │   │
        │   │   ├─► Sequencer Reward: o_i = (1-α) · S_i
        │   │   │
        │   │   └─► Validator Reward: v_j = (α · S_i) / |V_i|
        │   │
        │   └─► x = Σ B̃_i (Total Effective Bridged TON)
        │
        └─► Undistributed: L - y(x) → DAO Treasury

Where:
  A = Total seigniorage issuance
  d = DAO distribution ratio
  L = (1-d) · A = L2 distribution pool
  x = Σ B̃_i = Total effective Bridged TON sum
  k = Half saturation point (halfSaturationPoint)
  y(x) = Hyperbolic saturation function result (total amount distributed to L2s)
  S_i = Seigniorage distributed to L2 i
  B̃_i = Effective Bridged TON of L2 i (B_i if eligible, 0 if not)
  α = Validator distribution ratio
  |V_i| = Number of validators for L2 i

※ When no eligible L2s exist (x = 0):
  - y(0) = 0 (No L2 distribution)
  - Total seigniorage A goes to DAO (S_DAO + L = A)
```

---

## 3. Core Concepts

### 3.1 Bridged TON (B_i)

The total amount of TON bridged to each L2. It is a key metric for measuring L2 performance and determines seigniorage distribution amounts.

- **Measurement method**: Query OptimismPortal or L1StandardBridge balance for each L2 from L1BridgeRegistry
- **Role**: Determines seigniorage distribution ratio

### 3.2 Effective Bridged TON (B̃_i)

Bridged TON of L2s that meet eligibility conditions.

```
B̃_i = 1_i · B_i

Where:
1_i = 1 (if eligible)
1_i = 0 (if not eligible)
```

### 3.3 Eligibility Condition

L2s must meet minimum collateral requirements to receive seigniorage:

```
T_i ≥ max(θ · B_i, D_sequencer)

Where:
T_i = L2 sequencer's staking amount (SeigManager.getSequencerStaked(layer2))
θ · B_i = Seigniorage eligibility condition (Whitepaper Rule 4)
D_sequencer = H_max · C_max + Δ_sequencer = Fraud Proof cost coverage (Whitepaper Formula 1)

Parameters:
θ = Minimum staking ratio (e.g., 10%)
B_i = L2's Bridged TON
H_max = maxChallengers (maximum simultaneous challengers)
C_max = maxFraudProofCost (maximum cost per Fraud Proof)
Δ_sequencer = sequencerAdditionalReward (sequencer additional reward)

Calculation example:
H_max = 3, C_max = 50e27 WTON, Δ_sequencer = 100e27 WTON
→ D_sequencer = 3 × 50e27 + 100e27 = 250e27 WTON
```

> **V3 Change**: Sequencer collateral uses the existing TON staking system (coinage) instead of a separate Vault.

### 3.4 Hyperbolic Saturation Function

Applies diminishing returns to seigniorage distribution to prevent monopolization by a few L2s:

```
y(x) = L · (x / (k + x))

Where:
L = (1-d) · A (L2 distribution pool)
x = Σ B̃_i (Total effective Bridged TON)
k = Half saturation point (halfSaturationPoint)
```

#### Mathematical Properties

| x value | y(x) value | Meaning |
|---------|------------|---------|
| x = 0 | y(0) = 0 | No distribution if no eligible L2s |
| x = k | y(k) = L/2 | Exactly half at half saturation point |
| x → ∞ | y(∞) → L | Approaches L as x increases (saturation) |

**Properties**:
- **Monotonic increase**: x₁ < x₂ ⇒ y(x₁) < y(x₂)
- **Upper bound**: Always 0 ≤ y(x) ≤ L
- **Diminishing returns**: dy/dx = L·k/(k+x)² → slope decreases as x increases

### 3.5 RAT (Randomized Attention Test)

A random test to verify that validators are actually monitoring the network.

- **Trigger timing**: Probabilistically occurs when DisputeGame is created (π_a)
- **Response method**: Validator Software (RAT Client) automatically generates and submits evidence from L2 node
- **Evidence content**: Adjacent Leaves (two adjacent state leaves) + OutputRootProof
- **Response period**: `evidenceSubmissionPeriod`
- **No response**: C_off slashing (partial collateral confiscation)

**Validator Software Requirements**:
- Operate L2 Full Archive Node (op-geth with debug API)
- Run Validator Software (RAT Client)

---

## 4. System Components

### 4.1 Core Contracts

| Contract | Role |
|----------|------|
| **SeigManager** | Core of seigniorage calculation and distribution |
| **DepositManager** | TON/WTON staking management |
| **Layer2Manager** | L2 registration and management |
| **L1BridgeRegistry** | Bridge/portal registration and TVL queries |
| **RAT** | Validator registration, RAT tests, C_off penalty |
| **ValidatorReward** | Validator reward distribution |

### 4.2 Tokens

| Token | Role |
|-------|------|
| **TON** | Tokamak Network token (18 decimals) |
| **WTON** | Wrapped TON (27 decimals, 1 TON(wei) = 1e9 WTON(ray)) |
| **Coinage** | Staking receipt token (created per L2) |

### 4.3 External Systems

| System | Role |
|--------|------|
| **Optimism L2** | L2 rollups (Titan, Thanos, etc.) |
| **DisputeGameFactory** | Dispute Game creation (RAT trigger) |
| **OptimismPortal** | L1↔L2 bridge |
| **DAO** | Governance (DAOCommittee) |

---

## 5. Main Flows

### 5.1 Seigniorage Distribution Flow

```
1. updateSeigniorage() call
   │
2. Calculate total seigniorage A
   │ A = (currentBlock - lastSeigBlock) × seigPerBlock
   │
3. Check v3Migrated flag
   │
   ├─ V2 mode: Existing V1_3 logic
   │
   └─ V3 mode:
      │
      ├─ DAO distribution: d · A
      │
      ├─ L2 distribution pool: L = (1-d) · A
      │
      ├─ Check eligibility for each L2 (T_i ≥ max(θ·B_i, D_sequencer))
      │
      ├─ Sum of effective Bridged TON: x = Σ B̃_i
      │
      ├─ Hyperbolic function: y(x) = L · (x/(k+x))
      │
      ├─ L2 seigniorage: S_i = y(x) · (B̃_i / x)
      │
      ├─ Sequencer reward: o_i = (1-α) · S_i
      │
      └─ Validator reward: α · S_i → ValidatorReward
```

### 5.2 Validator RAT Flow

```
1. L2 proposer creates DisputeGame
   │
2. RAT.triggerAttentionTest() call
   │
3. Probability check (π_a)
   │
4. Random validator selection
   │
5. C_off pre-deduction: Transfer C_off from validator coinage to RAT contract (staking amount decreases)
   │   └─ Remove validator if below D_min
   │
6. Wait for validator response (evidenceSubmissionPeriod)
   │
   ├─ Evidence submitted (within Evidence Period):
   │   ├─ Validator Software generates evidence from L2 node
   │   │   - Search Adjacent Leaves (debug_accountRange)
   │   │   - Generate OutputRootProof and Merkle Proofs
   │   ├─ Auto-call submitEvidence()
   │   ├─ Return C_off from RAT contract to validator (staking amount restored)
   │   └─ Attempt auto-reactivation after checking collateral threshold
   │
   ├─ Evidence submission period expired (Challenge Period):
   │   ├─ Challenger can challenge in DisputeGame
   │   └─ On challenge success:
   │       ├─ FaultDisputeGame.resolveClaim() call
   │       ├─ RAT.resolveClaim(claimant) call
   │       ├─ Return C_off from RAT contract to validator (staking amount restored)
   │       └─ Attempt auto-reactivation after checking collateral threshold
   │
   └─ No response + Challenge period ended:
       └─ C_off permanently confiscated by RAT contract
```

### 5.3 Sequencer Slashing Flow

```
1. Sequencer submits incorrect Output Root
   │
2. Challenger submits Fraud Proof
   │
3. DisputeGame resolved
   │
4. slashSequencerByGame() call (Permissionless)
   │
5. Sequencer collateral slashed (entire staking amount confiscated → cannot receive seigniorage)
   │
   ├─ Challenger reward: C_max + Δ/n
   │
   └─ Remainder: DAO Treasury
```

---

## 6. V3 Core Parameters

| Parameter | Symbol | Description | Recommended Value When Testing |
|-----------|--------|-------------|-------------------|
| `seigPerBlock` | A/block | Seigniorage issuance per block | 3.92e18 (3.92 TON) |
| `daoDistributionRatio` | d | DAO fixed distribution ratio | 0.2e27 (20%) |
| `minStakingRatio` | θ | Minimum staking ratio | 0.1e27 (10%) |
| `validatorDistributionRatio` | α | Validator distribution ratio | 0.2e27 (20%) |
| `halfSaturationPoint` | k | Half saturation point | 10,000,000e27 TON |
| `ratTriggerProbability` | π_a | RAT trigger probability | Game theory based decision * |
| `slashingPenalty` | C_off | Slashing penalty | 100e27 WTON |
| `minimumThreshold` | D_min | Minimum collateral threshold | 1,000e27 WTON |
| `maxValidatorsPerL2` | N_max | Maximum validators per L2 | 100 |
| `evidenceSubmissionPeriod` | T_response | RAT response submission period | 1 hours |

> **RAY Unit**: All ratio parameters are expressed in RAY (10^27) units.
>
> **\* Game theory based decision**: π_a, C_off, c_m (monitoring cost), N (number of validators) must be determined together to satisfy the whitepaper formula `C_off ≥ (c_m · N) / π_a`.
>
> - N = Number of validators per L2 (|V_i|), not the entire system
> - N_max default: To be determined

---

## 7. System Invariants

Properties that the system must always maintain.

### 7.1 INV-001: Seigniorage Total Conservation

**V3 mode**:
```
DAO fixed distribution + DAO undistributed + Sequencer rewards + Validator rewards = Total seigniorage

d·A + (L - y(x)) + Σ(sequencer_i) + Σ(validator_j) = A
```

**Verification**:
- Total issuance = `seigPerBlock × blockSpan`
- Sum of all distributions = Total issuance
- No loss or excess issuance

### 7.2 INV-002: effectiveBridgedTON Consistency

```
∀ L2_i: eligible_i = true ⇔ effectiveBridgedTON_i = bridgedTON_i
∀ L2_i: eligible_i = false ⇔ effectiveBridgedTON_i = 0
```

Eligibility status and effective Bridged TON must always match.

### 7.3 INV-003: Claimable Reward Amount

```
0 ≤ claimableRewards ≤ totalDistributed
```

Claimable rewards cannot be negative and cannot exceed total distributed amount.

---

## 8. Related Documents

- [02-system-architecture.md](./02-system-architecture.md): System Architecture
- [03-contract-structure.md](./03-contract-structure.md): Contract Structure
- [04-contract-roles.md](./04-contract-roles.md): Contract Roles
- [Actors](./actors/01-overview.md): Actor Definitions
- [06-function-specs.md](./06-function-specs.md): Detailed Function Descriptions
