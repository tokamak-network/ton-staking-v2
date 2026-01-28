---
id: 05-actors
sidebar_position: 5
---
# TON Staking V3 Actor Definitions

## 1. Actor Overview

Defines the main actors that interact in the TON Staking V3 system.

| Actor | Role | Reward | Risk |
|-------|------|--------|------|
| **Staker** | TON staking | None in V3 | None |
| **Sequencer** | L2 operation, batch submission | (1-α)·S_i | Collateral slashing |
| **Validator** | L2 batch verification, RAT response | α·S_i/\|V_i\| | C_off slashing |
| **Challenger** | Fraud Proof submission | C_max + Δ/n | Gas cost loss |
| **DAO** | Governance, parameter settings | d·A + undistributed portion | None |
| **L2 Proposer** | Output Root submission | - | - |

---

## 2. Staker

### 2.1 Definition

Users who stake TON on L2.

### 2.2 Role

- Stake TON/WTON on L2 through DepositManager
- Request and process withdrawals

### 2.3 V3 Changes

**Important**: Stakers do not receive seigniorage in V3.

| Item | V2 | V3 |
|------|-----|-----|
| Seigniorage receipt | O | **X** |
| Staking purpose | Seigniorage receipt | Sequencer/validator collateral conditions |
| Withdrawal restrictions | None | Sequencers/validators must maintain minimum collateral |

### 2.4 Interactions

```
┌────────────────────────────────────────────────────────────┐
│                        Staker                               │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Staking:                                             │   │
│  │   TON.approve(DepositManager, amount)                │   │
│  │   DepositManager.deposit(layer2, amount)             │   │
│  │                                                      │   │
│  │ Or:                                                  │   │
│  │   TON.approveAndCall(wton, amount, layer2)           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Withdrawal:                                          │   │
│  │   DepositManager.requestWithdrawal(layer2, amount)   │   │
│  │   (2 weeks wait)                                     │   │
│  │   DepositManager.processRequest(layer2)              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 3. Sequencer

### 3.1 Definition

Operators who determine transaction order for L2 rollups and submit batches.

### 3.2 Role

- Determine L2 transaction order
- Submit batch data to L1
- Submit Output Root (create DisputeGame)
- Deposit collateral in existing staking system (coinage)

### 3.3 Reward

```
Sequencer reward = o_i = (1 - α) · S_i

Where:
- S_i = L2 i's seigniorage = y(x) · (B̃_i / x)
- α = Validator distribution ratio (e.g., 20%)
```

### 3.4 Risk

**Full collateral slashing on Fraud**

```
Sequencer collateral = D_sequencer = H_max · C_max + Δ_sequencer

On slashing:
- Challenger reward: C_max + Δ/n (to each challenger)
- Remainder: DAO Treasury
```

### 3.5 Eligibility Condition

```
T_i ≥ max(θ · B_i, H_max · C_max + Δ_sequencer)

Where:
- T_i = Sequencer staking amount (SeigManager.getSequencerStaked(layer2))
- θ · B_i = Seigniorage eligibility condition (Whitepaper Rule 4)
- H_max · C_max + Δ_sequencer = Fraud Proof cost coverage (Whitepaper Formula 1)

Parameters:
- θ = Minimum staking ratio (e.g., 10%)
- B_i = Bridged TON
- H_max = Maximum simultaneous challengers
- C_max = Maximum cost per Fraud Proof
- Δ_sequencer = Sequencer additional reward
```

### 3.6 Interactions

```
┌────────────────────────────────────────────────────────────┐
│                         Sequencer                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Collateral Deposit (uses existing staking):          │   │
│  │   DepositManager.deposit(layer2, amount)             │   │
│  │   → Query collateral via SeigManager.getSequencerStaked(layer2)│
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Operations:                                          │   │
│  │   1. Collect L2 transactions and determine order     │   │
│  │   2. Submit batch data to L1                         │   │
│  │   3. Submit Output Root (DisputeGameFactory.create)  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Seigniorage Distribution (V3):                       │   │
│  │   When SeigManager.updateSeigniorage() is called     │   │
│  │   → When eligibility met (T_i ≥ max(θ·B_i, D_seq))  │   │
│  │   → Sequencer reward: o_i = (1-α) · S_i             │   │
│  │   → WTON mint → Layer2Manager → OperatorManager     │   │
│  │   ※ V3: No seigniorage for general stakers          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Reward Receipt:                                      │   │
│  │   OperatorManager.claimERC20(wton, amount)           │   │
│  │   → Receive accumulated WTON from OperatorManager     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Staking Amount Withdrawal:                            │   │
│  │   DepositManager.requestWithdrawal(layer2, amount)   │   │
│  │   (processRequest after 2 weeks wait)                │   │
│  │   ※ Cannot withdraw below collateral (max(θ·B_i, D_seq))│
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 4. Validator

### 4.1 Definition

Participants who verify L2 batch validity and respond to RAT.

### 4.2 Role

- Monitor L2 batches
- Respond to RAT (Randomized Attention Test)
- Challenge on fraud discovery (also acts as challenger)

### 4.3 Reward

```
Validator reward = v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|

Where:
- V_i = Set of validators assigned to L2 i
- |V_i| = Number of validators for L2 i
- α = Validator distribution ratio (e.g., 20%)
- S_i = L2 i's seigniorage
```

### 4.4 Risk

**C_off penalty on RAT no response**

```
Collateral = D_validator = C_off + Δ_validator (coinage basis)

Penalty conditions:
- No response within evidenceSubmissionPeriod after RAT trigger
- Penalty amount: C_off (transferred from coinage to RAT)

Deactivation conditions (depending on relaxedValidatorCheck flag):
- relaxedValidatorCheck = true: Immediate deactivation when collateral < C_off (relaxed)
- relaxedValidatorCheck = false: Immediate deactivation when collateral < D_min (strict)

Penalty processing:
- Pre-deduction: Transfer C_off from coinage to RAT contract (staking amount decreases)
- Restoration: Return C_off from RAT to validator on evidence submission (staking amount restored)
- Confiscation: C_off confiscated by RAT contract on no response
```

### 4.5 Collateral and Registration Conditions

```
Minimum collateral = D_min = C_off + Δ_validator

Registration requirements:
- stakeOf(layer2, validator) >= D_min (required for registration)

relaxedValidatorCheck flag:
- Only applies to validity checks and deactivation conditions after registration
- true: Validity judged by C_off standard (initial stage, relaxed)
- false: Validity judged by D_min standard (strict)

Parameters:
- C_off = Penalty amount
- Δ_validator = Additional buffer
- relaxedValidatorCheck = Whether validator validity check is relaxed (DAO setting)
```

### 4.6 Active Validator

```
Active validator conditions (depending on relaxedValidatorCheck flag):
- Registered in RAT (isActive = true)
- relaxedValidatorCheck = true: stakeOf(layer2, validator) >= C_off (relaxed)
- relaxedValidatorCheck = false: stakeOf(layer2, validator) >= D_min (strict)

Status changes:
- Active → Inactive:
  · relaxedValidatorCheck = true: Deactivate when collateral < C_off
  · relaxedValidatorCheck = false: Deactivate when collateral < D_min
- Inactive → Active: Automatic reactivation when conditions met after collateral restoration

Validator count limit:
- N_max = Maximum validators per L2
- Validator reward: v_j = (α · S_i) / |V_i| (distributed only to active validators)
```

### 4.7 Interactions

```
┌────────────────────────────────────────────────────────────┐
│                         Validator                           │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Registration (V3: uses existing staking):            │   │
│  │                                                      │   │
│  │ Method 1: When staking amount >= D_min                │   │
│  │   RAT.registerValidator(systemConfig)                 │   │
│  │   → Check stakeOf(layer2, validator) >= D_min        │   │
│  │                                                      │   │
│  │ Method 2: When staking amount insufficient           │   │
│  │   TON.approveAndCall(RAT, amount, systemConfig)      │   │
│  │   → RAT stakes through DepositManager               │   │
│  │   → RAT.registerValidator(systemConfig) auto-executes│   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ RAT Response:                                        │   │
│  │   1. Subscribe to AttentionTestTriggered event       │   │
│  │   2. If selected, verify batch                       │   │
│  │   3. RAT.submitEvidence(systemConfig, batchIndex, .) │   │
│  │   (Period: within evidenceSubmissionPeriod)          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Reward Receipt:                                      │   │
│  │   ValidatorReward.claimAllRewards()                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Deactivation:                                        │   │
│  │   RAT.deactivateValidator(systemConfig)              │   │
│  │   (After deadline if RAT test in progress)           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 5. Challenger

### 5.1 Definition

Participants who submit Fraud Proofs against sequencer's incorrect state roots.

### 5.2 Role

- Monitor L2 state
- Challenge in FaultDisputeGame when incorrect Output Root discovered
- Submit Fraud Proof

### 5.3 Reward

```
Challenger reward = C_max + Δ_sequencer / n

Where:
- C_max = Maximum Fraud Proof cost
- Δ_sequencer = Sequencer additional collateral
- n = Number of challengers participating in challenge
```

### 5.4 Validator as Challenger

In V3, validators can also act as challengers.

```
┌────────────────────────────────────────────────────────────┐
│                    Validator as Challenger                 │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  On Fraud Discovery:                                        │
│  1. Challenge in FaultDisputeGame                          │
│  2. On game win:                                           │
│     - Challenger reward: C_max + Δ/n                       │
│     - RAT collateral restoration: RAT.resolveClaim()        │
│                                                             │
│  RAT Response Methods (one of two):                        │
│  - submitEvidence: Direct evidence submission              │
│  - resolveClaim: Challenge win (fraud proof success)       │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### 5.5 Interactions

```
┌────────────────────────────────────────────────────────────┐
│                         Challenger                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Challenge:                                          │   │
│  │   1. Discover incorrect Output Root                 │   │
│  │   2. FaultDisputeGame.attack() or defend()          │   │
│  │   3. Submit Fraud Proof                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ After Win:                                          │   │
│  │   Anyone: SeigManager.slashSequencerByGame(game)    │   │
│  │   → Pay challenger reward                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 6. DAO

### 6.1 Definition

The governance entity of Tokamak Network (DAOCommittee).

### 6.2 Role

- Set system parameters
- Upgrade contracts
- Execute V3 migration
- Emergency measures (pause, etc.)

### 6.3 Reward

```
DAO reward = d · A + (L - y(x)) + Σ(α·S_i for L2s with no validators)

Where:
- d · A = Fixed distribution (handled by SeigManagerV3_1)
- L - y(x) = Undistributed portion (handled by SeigManagerV3_1)
- α·S_i (|V_i|=0) = Validator share for L2s with no validators (handled by ValidatorRewardV1)
```

#### Implementation Details

| Reward Source | Processing Contract | Target Address |
|---------------|---------------------|----------------|
| Fixed distribution (d · A) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) |
| Undistributed portion (L - y(x)) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) |
| L2s with no validators (α·S_i) | `ValidatorRewardV1.distributeL2Rewards()` | `SeigManager.dao` (daoVault) |

> **Note**: `SeigManager.dao` stores the daoVault address. ValidatorRewardV1 calls `seigManager.dao()` to send rewards to the same address.

### 6.4 Permissions

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

---

## 7. L2 Proposer

### 7.1 Definition

The operating entity that submits L2 state (Output Root) to L1. Usually operated by the sequencer.

### 7.2 Role

- Calculate Output Root
- Call DisputeGameFactory.create()
- Trigger RAT (indirectly)

### 7.3 Interactions

```
┌────────────────────────────────────────────────────────────┐
│                       L2 Proposer                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Output Root Submission:                              │   │
│  │   1. Calculate Output Root from L2 state              │   │
│  │   2. DisputeGameFactory.create(gameType, claim, .)   │   │
│  │   3. Internally calls RAT.triggerAttentionTest()      │   │
│  │      (Probability: π_a)                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 8. Actor Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Actor Relationship Diagram                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│                                ┌─────────────┐                                  │
│                                │     DAO     │                                  │
│                                │ (Governance)│                                  │
│                                └──────┬──────┘                                  │
│                                       │                                          │
│              ┌────────────────────────┼────────────────────────┐                │
│              │ Parameter Settings     │ Reward Receipt          │                │
│              ▼                        ▼                        ▼                │
│  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐      │
│  │    Sequencer     │      │    Validator     │      │     Staker       │      │
│  │                  │      │                  │      │                  │      │
│  │ Collateral: T_i  │      │ Collateral: D_valid│      │ Staking: -      │      │
│  │ Reward: (1-α)·S_i│      │ Reward: α·S_i/|V| │      │ Reward: None (V3)│      │
│  │ Risk: Full Slashing│      │ Risk: C_off      │      │ Risk: None      │      │
│  └────────┬─────────┘      └────────┬─────────┘      └──────────────────┘      │
│           │                         │                                           │
│           │ Invalid Batch          │ Challenge Role                             │
│           ▼                         ▼                                           │
│  ┌────────────────────────────────────────────────────────┐                     │
│  │                      Challenger                        │                     │
│  │                                                        │                     │
│  │  Reward: C_max + Δ/n (on Fraud Proof success)          │                     │
│  │  Risk: Gas cost loss                                   │                     │
│  └────────────────────────────────────────────────────────┘                     │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Requirements per Actor

### 9.1 Technical Requirements

| Actor | Node Operation | 24/7 Availability | Capital | Technical Capability |
|-------|----------------|-------------------|---------|---------------------|
| Staker | X | X | TON | Low |
| Sequencer | O (L2) | O | High | High |
| Validator | O (L2 monitoring) | O | Medium | Medium |
| Challenger | O (L2 verification) | X | Gas cost | High |

### 9.2 Economic Requirements

| Actor | Minimum Collateral | Expected Reward | ROI |
|-------|-------------------|-----------------|-----|
| Sequencer | max(θ·B_i, H_max·C_max + Δ) | (1-α)·S_i | Variable |
| Validator | C_off + Δ_val | α·S_i/\|V_i\| | Variable |
| Challenger | Gas cost | C_max + Δ/n | Variable |

---

## 10. Sequencer Journey Guide

The complete process for new sequencers to participate in the V3 system.

### 10.1 New Sequencer Participation Flow

**Step 1: L2 Registration**

```solidity
// Register L2 through Layer2Manager
Layer2Manager.registerLayer2(
    layer2Address,
    operatorManager,
    "L2 Name"
);

// Initial collateral deposit (minimumAmount or more)
DepositManager.deposit(layer2, operator, initialAmount);
```

**Step 2: V3 Eligibility Check**

```solidity
// Check eligibility conditions
(bool eligible, uint256 required, uint256 current) = 
    SeigManager.checkCurrentEligibility(layer2);

// required = max(θ × B_i, D_sequencer)
// θ = minStakingRatio
// B_i = getBridgedTonByLayer(layer2)
// D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward
```

**Step 3: Additional Deposit if Eligibility Not Met**

```
if (!eligible) {
    // Calculate shortage
    uint256 shortage = required - current;
    
    // Additional deposit
    DepositManager.deposit(layer2, operator, shortage);
    
    // onStakingChange() automatically called → eligibility re-evaluation
}
```

**Step 4: Receive Seigniorage**

```
// Call updateSeigniorage() (anyone can call)
SeigManager.updateSeigniorage();

// When eligibility met:
// - Included in effectiveBridgedTON
// - Seigniorage automatically calculated and distributed
// - WTON transferred to OperatorManager
```

### 10.2 Eligibility Maintenance and Monitoring

**Monitoring Targets**:

1. **EligibilityChanged Event**
   ```solidity
   event EligibilityChanged(
       address indexed layer2,
       bool eligible,
       uint256 requiredStake,
       uint256 currentStake
   );
   ```

2. **Bridged TON Increase Detection**
   - L2 users bridge TON → B_i increases
   - θ × B_i increases → required collateral increases
   - Eligibility loss possible

3. **Parameter Change Detection**
   - DAO increases θ → required collateral increases
   - DAO changes D_sequencer parameters

**Eligibility Maintenance Strategy**:

```
Recommendation: T_i ≥ 1.2 × max(θ × B_i, D_sequencer)
     (Maintain 20% buffer)

Reasons:
- Prepare for sudden Bridged TON increase
- Prepare for parameter changes
- Prevent eligibility loss → automatic claim prevention
```

### 10.3 Eligibility Loss and Recovery

**Eligibility Loss Causes**:

1. Bridged TON increase → θ × B_i increases
2. Collateral withdrawal → T_i decreases
3. Parameter changes (θ or D_sequencer increase)

**Automatic Processing on Eligibility Loss**:

```
1. onStakingChange() called
   ↓
2. checkAndUpdateEligibility() detects
   ↓
3. Unclaimed rewards automatically claimed
   → _claimL2Seigniorage(layer2)
   → WTON transferred to OperatorManager
   ↓
4. effectiveBridgedTON = 0
   ↓
5. Event: AutoClaimBeforeEligibilityLoss
```

**Recovery Process**:

```solidity
// 1. Additional collateral deposit
DepositManager.deposit(layer2, operator, additionalAmount);

// 2. onStakingChange() automatically called

// 3. Check eligibility reacquisition
(bool eligible, , ) = SeigManager.checkCurrentEligibility(layer2);
// If eligible = true, recovery complete

// 4. effectiveBridgedTON restored
// 5. Receive new rewards from now on
```

**Important**: Rewards during eligibility loss period are not received (goes to DAO as undistributed portion)

### 10.4 Slashing and Recovery

**Slashing Occurrence**:

```
1. Submit incorrect Output Root
   ↓
2. Challenger submits Fraud Proof
   ↓
3. DisputeGame resolved (status not DEFENDER_WINS)
   ↓
4. Anyone calls slashSequencerByGame(gameAddress)
   ↓
5. Full collateral confiscated (coinage.burnFrom)
   - Challenger reward: C_max + Δ/n
   - Remainder: DAO Treasury
   ↓
6. Event: SequencerSlashed
```

**Recovery Impossible**:
- Full collateral loss on slashing
- L2 re-registration required
- Start from scratch as new sequencer

---

## 11. Validator Journey Guide

The complete process for validators to participate in the V3 system.

### 11.1 New Validator Participation Flow

**Step 1: Prepare Collateral**

```solidity
// Check required collateral
uint256 dMin = RAT.getDynamicMinimumCollateral(systemConfig);

// Method 1: Use existing staking (if sufficient)
uint256 currentStake = SeigManager.stakeOf(layer2, validator);
require(currentStake >= dMin, "Insufficient collateral");

// Method 2: Additional staking (if insufficient)
DepositManager.deposit(layer2, validator, additionalAmount);
```

**Step 2: Validator Registration**

```solidity
// Register
RAT.registerValidator(systemConfig);

// Automatic processing:
// - Registered to RAT
// - Registered to ValidatorReward (registerValidatorToL2)
// - debt[validator][systemConfig] = rewardPerValidator[systemConfig]
// - isActive = true
```

**Step 3: Receive Rewards**

```
// When seigniorage distributed (on updateSeigniorage call):
// - ValidatorReward.distributeL2Rewards(systemConfig, amount)
// - rewardPerValidator[systemConfig] increases
// - earned = rewardPerValidator - debt

// Claim rewards:
ValidatorReward.claimAllRewards()
or
ValidatorReward.claimRewardsByL2s([systemConfig1, systemConfig2, ...])
```

### 11.2 RAT Response

**RAT Trigger**:

```
1. L2 proposer creates DisputeGame
   ↓
2. DisputeGameFactory → RAT.triggerAttentionTest()
   ↓
3. π_a probability check (random)
   ↓
4. Random validator selection
   ↓
5. C_off pre-deduction (from coinage to RAT contract)
   - Collateral < threshold → validator automatically removed
```

**Response**:

```solidity
// Respond within evidenceSubmissionPeriod
RAT.submitEvidence(gameAddress);

// On success:
// - C_off returned (RAT → validator coinage)
// - Collateral restored
```

**No Response**:

```
// After evidenceSubmissionPeriod expires
// → C_off confiscated (held by RAT contract)
// → Collateral loss
```

### 11.3 Validator Deactivation and Re-registration

**Voluntary Deactivation**:

```solidity
// Deactivate
RAT.deactivateValidator(systemConfig);

// Automatic processing:
// - ValidatorReward.syncValidatorReward() called
// - validatorPendingRewards[validator] += earned
// - isActive = false
// - Removed from validators array
```

**Automatic Removal** (Insufficient Collateral):

```
At triggerAttentionTest():
- After C_off deduction, remaining < threshold
  - threshold = relaxedValidatorCheck ? C_off : D_min
  
→ Removed from validators array
→ isActive = false
```

**Re-registration**:

```solidity
// 1. Replenish collateral
DepositManager.deposit(layer2, validator, amount);

// 2. Re-register
RAT.registerValidator(systemConfig);

// Automatic processing:
// - ValidatorReward.resetValidatorDebt() called
// - debt = reset to current rewardPerValidator
// - Only previously synchronized rewards claimable
// - Rewards during deactivation period lost
```

**Rewards After Re-registration**:

```
Existing rewards (synchronized): claimable
Deactivation period rewards: Excluded from distribution (active validators share)
New rewards after re-registration: Receive again
```

### 11.4 Optimization Tips

**1. Maintain Collateral Buffer**

```
Recommendation: Actual collateral ≥ 1.5 × D_min

Reasons:
- Prepare for RAT pre-deduction (C_off deduction)
- Prepare for validator count increase → D_min increase
- Prevent automatic removal
```

**2. Multi-L2 Diversification Strategy**

```
// Distribute registration across multiple L2s → risk diversification
RAT.registerValidator(systemConfig1);
RAT.registerValidator(systemConfig2);
RAT.registerValidator(systemConfig3);

// Claim rewards in batches too
ValidatorReward.claimRewardsByL2s([config1, config2, config3]);
```

**3. RAT Monitoring**

```
// Subscribe to AttentionTestTriggered event
event AttentionTestTriggered(
    address indexed gameAddress,
    address indexed validator,
    uint256 deadline
);

// Immediately call submitEvidence()
// → Receive C_off return
```

---

## 12. Related Documents

- [01-system-overview.md](./01-system-overview.md): System Overview
- [02-system-architecture.md](./02-system-architecture.md): System Architecture
- [03-contract-structure.md](./03-contract-structure.md): Contract Structure
- [04-contract-roles.md](./04-contract-roles.md): Contract Roles
- [06-function-specs.md](./06-function-specs.md): Detailed Function Descriptions
