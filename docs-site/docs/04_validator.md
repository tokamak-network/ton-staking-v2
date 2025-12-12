---
id: 04_validator
slug: /04_validator
---
# Validator

## 1. Overview

In Tokamak Network V3, validators verify the validity of L2 batches and contribute to network security. Validators prove their active status by responding to RAT (Randomized Attention Test) and receive a portion of seigniorage as rewards.

### 1.1 Per-SystemConfig Validator Registration

In TON V3, since multiple L2s exist, validators **register individually for specific L2s (SystemConfigs)**.

```
Validator A ──┬──→ Titan SystemConfig registration (collateral 5,000 WTON)
              └──→ Thanos SystemConfig registration (collateral 3,000 WTON)

Validator B ──────→ Titan SystemConfig only (collateral 10,000 WTON)

Validator C ──────→ Thanos SystemConfig only (collateral 2,000 WTON)
```

**Reasons for using SystemConfig as key:**
- Each L2 has a unique SystemConfig (rollup config) address
- Layer2Manager can identify L2s using SystemConfig
- L2s know their own SystemConfig address

---

## 2. Validator vs Challenger vs Sequencer

### 2.1 Role Comparison

| Category | Sequencer | Validator | Challenger |
|------|-------------------|-------------------|---------------------|
| **Role** | Determines L2 transaction order and submits batches | Verifies L2 batches and responds to RAT | Submits fraud proof |
| **Collateral** | Staking amount (S_i) | Separate deposit (D_validator) | Bond deposited in game |
| **Reward Source** | Seigniorage (1-α_v)·Seig_i | Seigniorage α_v·y(x)/n | Slashed sequencer collateral |
| **Reward Condition** | L2 operation and eligibility condition fulfillment | RAT response and active status maintenance | Fraud proof success |
| **Slashing Condition** | Fraud occurrence | RAT non-response | None |
| **Risk** | Full collateral slashing on fraud | Full collateral slashing on non-response | Gas cost loss/game bond loss on failure |

### 2.2 Core Responsibilities of Validators

1. **L2 Batch Monitoring**: Verify validity of batches submitted by sequencer
2. **RAT Response**: Respond within time limit to random tests issued by protocol (collateral maintenance required)
3. **Challenge on Fraud Discovery**: Submit fraud proof when incorrect batch is discovered

### 2.3 Validator as Challenger

Validators can also act as challengers. In this case, they must **perform both responsibilities**:

```
Sequencer submits incorrect batch
            │
            ▼
┌───────────────────────────────────────────────────────────────┐
│  Validator (also acting as challenger)                        │
│                                                               │
│  1. Submit fraud proof → Receive challenger reward (C_max + Δ/n) │
│                                                               │
│  2. Maintain RAT response → Protect validator collateral     │
│     (Collateral slashed if RAT non-response)                 │
└───────────────────────────────────────────────────────────────┘
```

**RAT Response Methods:**
- **submitEvidence**: Direct evidence submission
- **resolveClaim**: Challenge victory (fraud proof success)

Both methods are recognized as RAT responses and collateral is recovered.

| Situation | Fraud Proof | RAT Response Method | Result |
|------|-------------|--------------|------|
| Normal operation | - | submitEvidence | Receive validator reward |
| Challenge success | ✅ Success | resolveClaim | Challenger reward + validator reward |
| RAT non-response | - | ❌ | Validator collateral slashing |

---

## 3. Validator Registration Conditions

### 3.1 Maximum Validator Count (N_max = H_max)

In **whitepaper formula (1)**, sequencer collateral is calculated based on maximum challenger count (H_max):

```
D_sequencer = H_max · C_max + Δ_sequencer
```

In Tokamak Network V3, **validator = challenger**, so we must prepare for the case where all validators submit fraud proofs:

```
Maximum validator count (N_max) = Maximum challenger count (H_max)
```

| Parameter | Description | Relationship |
|---------|------|------|
| **H_max** | Maximum simultaneous challenger count (whitepaper definition) | Protocol constant |
| **N_max** | Maximum validator registration count | N_max = H_max |

### 3.2 Validator Slot Management

```
┌─────────────────────────────────────────────────────────────┐
│  Validator Registration                                     │
│  - Check activeValidatorCount < maxValidators (= H_max)      │
│  - Secure slot → Registration success                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  RAT Slashing Occurs                                       │
│  - Collateral forfeiture → Deactivation                    │
│  - activeValidatorCount decreases → Slot released          │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐       ┌─────────────────────────┐
│  Re-registration of     │       │  New Validator          │
│  Slashed Validator      │       │  Registration Attempt   │
│                         │       │                         │
│  - Recharge collateral  │       │  - Register if slot     │
│  - Can register if slot │       │    available            │
│    available            │       │  - Fail if no slot      │
└─────────────────────────┘       └─────────────────────────┘
```

### 3.3 Minimum Collateral

Validator collateral according to **whitepaper formulas (4), (5), (6)**:

```
π_a · D_validator > c_m · N             ... (4) Game-theoretic equilibrium condition
D_validator ≥ (c_m · N) / π_a           ... (5) Minimum condition (derived from 4)
D_validator = (c_m · N) / π_a + Δ_validator  ... (6) Actual collateral
```

| Parameter | Whitepaper Specified | Description |
|---------|----------|------|
| **c_m** | ✅ | Single RAT response cost |
| **N** | ✅ | Number of batches to verify |
| **π_a** | ✅ | RAT occurrence probability |
| **Δ_validator** | ✅ | Additional collateral provided by validator (optional) |

### 3.4 Pre-deduction-Recovery Mechanism

TON V3 RAT uses a **pre-deduction-recovery mechanism**:

```
Validator A @ Titan SystemConfig: 10,000 WTON staked
    │
    ├─ RAT test triggered → Full staking amount 10,000 WTON pre-deducted → Balance 0 WTON
    │   └─ Evidence submission success → 10,000 WTON recovered → Balance 10,000 WTON
    │
    ├─ RAT test triggered → Full staking amount 10,000 WTON pre-deducted → Balance 0 WTON
    │   └─ Non-response → No separate transaction → 10,000 WTON attributed to RAT contract
```

**Mechanism Characteristics:**
- **Full collateral** is pre-deducted when RAT is triggered (whitepaper: full collateral slashing)
- Full amount recovered upon successful evidence submission
- No separate slashing transaction needed when unresponsive (already deducted)

### 3.5 Technical Requirements

| Requirement | Description |
|---------|------|
| **Node Operation** | Operate node capable of monitoring batches of registered L2 (SystemConfig) |
| **24/7 Availability** | Must be able to respond within RAT response window (~24 hours) |
| **WTON Holdings** | Need WTON equal to or greater than minimum collateral |
| **Ethereum Address** | EOA or contract for validator registration and reward receipt |

### 3.6 Who Can Be a Validator?

- **No restrictions**: Anyone can register if minimum collateral is met
- **No permission required**: Free participation/withdrawal without protocol approval
- **Multiple L2 registration possible**: One address can **register for multiple L2s (SystemConfigs)**
- **Independent collateral per L2**: Separate collateral deposit via RAT for each L2

---

## 4. Validator Registration Procedure

### 4.1 Registration Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Prepare TON                                             │
│     - Secure TON equal to or greater than minimum collateral│
│     - Approve RAT contract or TON.approveAndCall            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Call registerValidator(systemConfig, amount)            │
│     - systemConfig: SystemConfig address of L2 to register  │
│     - amount >= getMinimumCollateral()                      │
│     - WTON transferred to RAT contract                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. RAT delegates staking to DepositManager                 │
│     - Staking in RAT's name (validator cannot withdraw directly) │
│     - Store coinage factor at deposit time (for seigniorage calculation) │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Validator Activation                                    │
│     - isActive = true (for that SystemConfig)               │
│     - validatorPools[systemConfig].activeValidatorCount increases │
│     - Eligibility to receive rewards from next period       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Start Validation Activities                             │
│     - Monitor batches of that L2 (SystemConfig)            │
│     - Prepare to respond when RAT is issued                 │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Pre-preparation (User Perspective)

```solidity
// 1. Approve WTON
IERC20(wton).approve(ratContractAddress, amount);

// 2. Register validator for specific L2 (SystemConfig)
IRAT(ratContractAddress).registerValidator(titanSystemConfig, amount);

// 3. (Optional) Can also register for other L2s
IRAT(ratContractAddress).registerValidator(thanosSystemConfig, anotherAmount);
```

> **Implementation Details**: See [07_rat_implementation.md](./07_rat_implementation.md) Section 6.1 for `registerValidator` function implementation

---

## 5. Validator Collateral Management

### 5.1 RAT's Delegated Staking Mechanism

Validator collateral is managed through **RAT contract delegating staking to DepositManager**.

**Design Reasons:**
- If validators stake directly, they can unstake arbitrarily → Collateral role lost
- If RAT delegates staking, validators cannot withdraw → Collateral protected
- Since staking is in RAT's name, seigniorage is attributed to RAT contract (paid to validator upon withdrawal)

> **Note:** Staking in RAT's name does not contribute to L2 eligibility condition (S_i ≥ θ·B_i). S_i only includes staking in sequencer (operator)'s name.

```
Validator Registration Flow:
┌─────────────────┐     WTON      ┌─────────────────┐
│    Validator    │ ──────────► │      RAT        │
└─────────────────┘               └─────────────────┘
                                          │
                                          │ deposit(layer2, RAT, amount)
                                          ▼
                                  ┌─────────────────┐
                                  │ DepositManager  │
                                  │ (Deposited in  │
                                  │  RAT's name)   │
                                  └─────────────────┘

Slashing Flow (only internal records change):
┌─────────────────────────────────────────────────────────────┐
│  When RAT is triggered:                                     │
│    - Internal record: slashingPenalties = full amount      │
│    - DepositManager: No change (staking in RAT's name maintained) │
│                                                             │
│  When unresponsive:                                         │
│    - Validator cannot withdraw because slashingPenalties > 0 │
│    - Staking in DepositManager continues in RAT's name      │
│    - That amount automatically attributed to RAT (no separate transaction needed) │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Slashing Penalty Tracking

Amounts forfeited due to RAT non-response are tracked via the `totalSlashingPenalties` variable.

> **Usage**: Use of forfeited amounts confirmed as non-response is TBD (governance decision needed)

---

## 6. Validator Deactivation (Withdrawal)

### 6.1 Deactivation Conditions

- Only validator themselves can deactivate (voluntary withdrawal)
- Must be active in that SystemConfig
- **Can withdraw individually from each SystemConfig**
- Collateral and unclaimed rewards are **processed separately**
- **Cannot withdraw during evidence submission period**

### 6.2 Deactivation Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Call unregisterValidator(systemConfig)                  │
│     - Withdraw only from specific L2 (SystemConfig)         │
│     - Fails if in evidence submission period                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. State Change                                            │
│     - isActive = false (for that SystemConfig)              │
│     - Remove from activeValidators array + reindex          │
│     - validatorPools[systemConfig].activeValidatorCount decreases │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Separate Processing of Collateral/Rewards               │
│     - Collateral: Separate withdrawal request via requestUnstake() │
│     - Unclaimed rewards: Separate claim via claimRewards() │
└─────────────────────────────────────────────────────────────┘
```

### 6.3 Collateral Withdrawal

When validators withdraw, they must go through DepositManager's withdrawal process:
1. `requestUnstake()`: Request full withdrawal (deduct internal records + request to DepositManager)
   - **Partial withdrawal not allowed**: Must always withdraw entire `depositedAmount`
2. **2-week wait** (DepositManager's withdrawal delay period)
3. `processUnstake()`: Validator calls to actually process withdrawal and transfer to validator (principal + seigniorage)

```
┌──────────┐  requestUnstake()   ┌──────────┐  requestWithdrawal  ┌────────────────┐
│ Validator│ ─────────────────► │   RAT    │ ─────────────────► │ DepositManager │
│ (Full    │  (Full withdrawal  │          │                     │                │
│  only)   │   only)            └──────────┘                     └────────────────┘
└──────────┘
                                      │
                                      │  2-week wait
                                      ▼
┌──────────┐  processUnstake()   ┌──────────┐  processRequest    ┌────────────────┐
│ Validator│ ─────────────────► │   RAT    │ ─────────────────► │ DepositManager │
│          │  (Withdrawal       │          │                     │                │
│          │   processing req)  └──────────┘                     └────────────────┘
│          │                              │
│          │                              │ WTON (principal+seigniorage)
│          │◄─────────────────────────────┘
│ (WTON)   │
└──────────┘
```

> **Implementation Details**: See [07_rat_implementation.md](./07_rat_implementation.md) Section 6.7 for `requestUnstake`, `processUnstake` function implementation

---

## 7. Validator Rewards

### 7.1 Reward Formula

Validator rewards according to **whitepaper formula (13)**:

```
v_i = (α_v / n) · y(x)    ... (13) Validator reward
```

| Parameter | Whitepaper Specified | Description |
|---------|----------|------|
| **α_v** | ✅ | Validator distribution ratio (e.g., 20%) |
| **n** | ✅ | Active validator count (within that SystemConfig) |
| **y(x)** | ✅ | Hyperbolic saturation function result |

**Core Characteristics (whitepaper specified):**
- **Per-SystemConfig** active validators receive equal reward distribution (1/n)
- Same reward regardless of collateral size
- Must respond to RAT and maintain active status to be eligible for rewards

### 7.2 Reward Distribution Flow

```
Specific L2 calls updateSeigniorage() (SeigManager)
            │
            ▼
┌───────────────────────────────────────┐
│  Calculate that L2's seigniorage      │
│  Seig_i = y(x) · (B̃_i / x)           │
└───────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────┐
│  Layer2Manager.transferL2Seigniorage  │
│  (layer2, Seig_i)                     │
│  → Transfer WTON to OperatorManager   │
└───────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────┐
│  OperatorManager.receiveL2Seigniorage │
│  - Check validator count (all to sequencer if 0) │
│  - Sequencer share: (1 - α_v) · Seig_i │
│  - Validator share: α_v · Seig_i      │
└───────────────────────────────────────┘
            │
    ┌───────┴───────┐
    ▼               ▼
┌─────────────┐  ┌─────────────────────────┐
│ Sequencer  │  │ Validator Share        │
│ Share      │  │ Transfer to RAT        │
│ Remains in │  │ contract               │
│ Operator   │  │ distributeReward() call │
│ Manager    │  └─────────────────────────┘
│ (claimERC20)│              │
└─────────────┘              ▼
                 ┌─────────────────────────┐
                 │ Equal distribution (1/n)│
                 │ to active validators    │
                 │ of that L2              │
                 └─────────────────────────┘
```

> **Note**: If no validators, `validatorAmount = 0` → All goes to sequencer share

### 7.3 Reward Claiming

```solidity
// Claim rewards per SystemConfig
IRAT(ratContract).claimRewards(systemConfig);

// Batch claim rewards from all SystemConfigs
IRAT(ratContract).claimAllRewards();
```

> **Implementation Details**: See [07_rat_implementation.md](./07_rat_implementation.md) Section 6.6 for `distributeReward`, `claimRewards` function implementation

---

## 8. RAT (Randomized Attention Test)

### 8.1 RAT Overview

RAT is a random test to verify that validators are actually monitoring the network.

**Whitepaper Content (1.3.1 RAT):**
- RAT randomly selects validators and requires them to verify specific L2 batches
- Selected validators must check batches and submit proof (attestation) of accuracy
- Honest response receives validator fee, non-response or dishonesty results in slashing
- Game-theoretically designed so expected cost of skipping verification is higher than short-term savings

| Item | Whitepaper Specified | Implementation Proposal |
|------|----------|----------|
| **Purpose** | ✅ Verify validator active status | - |
| **Issuer** | ✅ Protocol (random) | - |
| **Issue Probability** | ✅ π_a (formulas 4, 5, 6) | 1% |
| **Evidence Submission Period** | ❌ Not specified | ~24 hours (7200 blocks) |
| **On Non-response** | ✅ Collateral slashing | Full collateral slashing |

### 8.2 RAT Trigger Timing

RAT is triggered when L2 proposer (sequencer) **creates a Dispute Game**.

```
┌─────────────────────────────────────────────────────────────┐
│  Optimism L2 Proposer (op-proposer)                         │
│                                                              │
│  1. Calculate Output Root                                    │
│  2. Call DisputeGameFactory.create()                         │
│     └─→ Call RAT.triggerAttentionTest()                      │
└─────────────────────────────────────────────────────────────┘
```

### 8.3 RAT Flow (Pre-deduction-Recovery Mechanism)

```
┌─────────────────────────────────────────────────────────────┐
│  1. L2 Proposer Creates DisputeGame                         │
│     - triggerAttentionTest(systemConfig, batchIndex, ...)   │
│     - Probability: ratTriggerProbability (1%)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Random Selection from Validator Pool of that SystemConfig │
│     - Select from activeValidators[systemConfig]            │
│     - ★ slashingPenalties = full amount (pre-deduction)    │
│     - Deactivate validator (isActive = false)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Wait for Validator Evidence Submission                  │
│     - Submission period: evidenceSubmissionPeriod (~24 hours) │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │  Evidence       │             │  Non-response   │
    │  Submission     │             │  Deadline       │
    │  submitEvidence │             │  Passed         │
    └─────────────────┘             └─────────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │  slashingPenalties│            │  Do nothing     │
    │  = 0 (recovered) │             │  (already       │
    │  Validator        │             │  forfeited)     │
    │  reactivated      │             │  Attributed     │
    │  isActive = true │             │  to RAT         │
    └─────────────────┘             └─────────────────┘
```

### 8.4 Collateral Recovery upon Challenge Victory

When a validator challenges incorrect evidence from proposer and **wins the game**, FaultDisputeGame calls `resolveClaim` to recover collateral.

```
┌─────────────────────────────────────────────────────────────┐
│  1. Proposer Submits Incorrect Output Root                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Validator (Challenger) Challenges in FaultDisputeGame   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Game Resolution - Validator (Challenger) Wins            │
│     - FaultDisputeGame.resolveClaim() called                 │
│     - resolveClaimRat(winner) → RAT.resolveClaim(winner)    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Collateral Recovery in RAT                              │
│     - slashingPenalties = 0 (withdrawal unblocked)          │
│     - Validator reactivated (isActive = true)               │
└─────────────────────────────────────────────────────────────┘
```

> **Implementation Details**: See [07_rat_implementation.md](./07_rat_implementation.md) Sections 6.2~6.5 for RAT trigger, evidence submission, resolveClaim function implementation

---

## 9. Governance Parameters

| Parameter | Whitepaper Specified | Description |
|---------|----------|------|
| **maxValidators** | ✅ (H_max) | Maximum validator count (= maximum challenger count) |
| **ratResponseCost** | ✅ (c_m) | Single RAT response cost |
| **batchCount** | ✅ (N) | Number of batches to verify |
| **ratTriggerProbability** | ✅ (π_a) | RAT occurrence probability |
| **evidenceSubmissionPeriod** | ❌ | Evidence submission period |
| **validatorDistributionRatio** | ✅ (α_v) | Validator distribution ratio |

**Minimum collateral is dynamically calculated using whitepaper formula (5):**
```
D_validator ≥ (c_m · N) / π_a
```

---

## 10. Validator Operation Guide

### 10.1 What Validators Must Do

| Task | Frequency | Description |
|------|------|------|
| **Monitor Batches of Registered L2** | Always | Monitor DisputeGame creation for registered SystemConfig |
| **RAT Evidence Submission** | When RAT triggered | Call submitEvidence() within evidence submission period |
| **Reward Claiming** | When desired | claimRewards(systemConfig) or claimAllRewards() |
| **Collateral Management** | As needed | addStake() or unregisterValidator() |

### 10.2 Precautions

1. **24/7 Availability**: RAT occurs when DisputeGame is created, so monitoring system must always be running
2. **Evidence Submission Period Compliance**: Full collateral slashing if not submitted within ~24 hours
3. **Gas Cost Preparation**: Hold ETH for evidence submission transactions
4. **Event Subscription**: Recommended to subscribe to AttentionTriggered events and set up alerts
5. **Multiple L2 Management**: Need to monitor each if registered for multiple SystemConfigs

### 10.3 Validator Client Implementation Guide

```typescript
// Event listener example
ratContract.on("AttentionTriggered", async (testId, systemConfig, layer2, validator, batchIndex) => {
    if (validator === myAddress) {
        // Query batch data
        const batchData = await fetchBatchData(systemConfig, batchIndex);

        // Submit evidence
        await ratContract.submitEvidence(systemConfig, batchIndex, batchData);
    }
});
```

---

## 11. Reference Documents

- **RAT Implementation Details**: [07_rat_implementation.md](./07_rat_implementation.md)
  - Storage structure (Sections 3, 4)
  - Interface definitions (Section 5)
  - Core function implementation (Section 6)
  - Integration guide (Section 8)
