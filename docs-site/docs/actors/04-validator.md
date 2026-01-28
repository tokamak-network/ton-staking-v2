---
id: actors-validator
sidebar_position: 4
---

# Validator

## Definition

Participants who verify L2 batch validity and respond to RAT.

## Role

- Monitor L2 batches
- Respond to RAT (Randomized Attention Test)
- Challenge on fraud discovery (also acts as challenger)

## Reward

```
Validator reward = v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|

Where:
- V_i = Set of validators assigned to L2 i
- |V_i| = Number of validators for L2 i
- α = Validator distribution ratio (e.g., 20%)
- S_i = L2 i's seigniorage
```

## Risk

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

## Collateral and Registration Conditions

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

## Active Validator

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

## Interactions

```
┌────────────────────────────────────────────────────────────┐
│                         Validator                           │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Registration (V3: uses existing staking):            │   │
│  │                                                      │   │
│  │ 1. First, stake sufficient TON via DepositManager   │   │
│  │    DepositManager.deposit(layer2, amount)            │   │
│  │    → Must deposit D_min or more                     │   │
│  │                                                      │   │
│  │ 2. Register as validator                            │   │
│  │    RAT.registerValidator(systemConfig)               │   │
│  │    → Check stakeOf(layer2, validator) >= D_min      │   │
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

## Validator Journey Guide

The complete process for validators to participate in the V3 system.

### New Validator Participation Flow

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

### RAT Response

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

### Validator Deactivation and Re-registration

**Voluntary Deactivation**:

```solidity
// 1. Call deactivate
RAT.deactivateValidator(systemConfig);

// 2. Automatic processing:
//    - ValidatorReward.syncValidatorReward() called
//    - Unclaimed rewards synchronized to validatorPendingRewards
//    - isActive = false
//    - Removed from validators array

// 3. Can still claim rewards after deactivation
ValidatorReward.claimAllRewards();
// or
ValidatorReward.claimRewardsByL2s([systemConfig]);
```

**Automatic Removal** (Insufficient Collateral):

```
Automatically removed at triggerAttentionTest():
- After C_off deduction, remaining < threshold
  - threshold = relaxedValidatorCheck ? C_off : D_min
  
→ Removed from validators array
→ isActive = false
→ Rewards until deactivation are synchronized and claimable
```

**Re-registration and Reward Logic**:

```solidity
// 1. Replenish collateral (D_min or more)
DepositManager.deposit(layer2, amount);

// 2. Re-register
RAT.registerValidator(systemConfig);

// 3. Automatic processing:
//    - ValidatorReward.resetValidatorDebt() called
//    - New debt set (current rewardPerValidator)
//    - Previously synchronized rewards still claimable

// 4. Claim rewards
ValidatorReward.claimAllRewards();
//    → Synchronize all L2 rewards and claim at once
//    → Transfer all rewards accumulated in validatorPendingRewards
```

**Reward Timing Summary**:

| Period | Rewards | Claiming Method |
|--------|---------|-----------------|
| Active Period | ✅ Earned | Auto-synced on deactivation/re-registration |
| Inactive Period | ❌ Lost | Shared by other active validators |
| After Re-registration | ✅ Earned | New rewards start accumulating |

**Reward Claiming Methods**:

```solidity
// Method 1: Claim all L2 rewards at once
ValidatorReward.claimAllRewards();
// → Synchronize all registered L2 rewards
// → Transfer all rewards accumulated in validatorPendingRewards
// ⚠️ Caution: High gas cost if many L2s registered

// Method 2: Claim specific L2s only (gas optimization)
ValidatorReward.claimRewardsByL2s([systemConfig1, systemConfig2, systemConfig3]);
// → Synchronize only specified L2 rewards
// → Transfer accumulated rewards in validatorPendingRewards
// ✅ Recommended: Claim in batches if many L2s
```
