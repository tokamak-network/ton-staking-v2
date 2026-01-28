---
id: functions-validator-reward
sidebar_position: 7
---

# ValidatorReward Functions

Validator reward distribution and claim functions.

## distributeL2Rewards

Distributes validator rewards per L2.

```solidity
function distributeL2Rewards(address systemConfig, uint256 amount) external onlySeigManager
```

| Item | Content |
|------|---------|
| **Caller** | SeigManager |
| **Access Control** | `onlySeigManager` |
| **Gas Complexity** | O(1) - Independent of validator count |

**Operation Flow**:
```
1. Query RAT.getActiveValidatorCount(systemConfig)
2. If |V_i| = 0:
   └─► WTON.transfer(seigManager.dao(), amount)
       └─► Event: RewardToDAO

3. If |V_i| > 0:
   └─► perValidator = amount / activeCount
   └─► rewardPerValidator[systemConfig] += perValidator (O(1) accumulation)
   └─► Event: L2RewardDistributed
```

**RewardPerValidator Pattern**:
- O(1) complexity: Update only global accumulated value without iterating validators
- L2-specific reward tracking done via events (`ValidatorRewardReceived`)
- Send to `seigManager.dao()` when no validators

---

## claimAllRewards

Claims rewards received from all L2s.

```solidity
function claimAllRewards() external ifFree
```

| Item | Content |
|------|---------|
| **Caller** | Validator |
| **Gas Complexity** | O(L) - Proportional to number of L2s validator is registered to |
| **Note** | May exceed gas limit if registered to many L2s → Use `claimRewardsByL2s` recommended |

**Operation Flow**:
```
1. _syncAllRewards(validator): Synchronize all L2 rewards
   └─► For each L2:
       - earned = rewardPerValidator[systemConfig] - validatorRewardDebt[validator][systemConfig]
       - Only if active validator: validatorPendingRewards[validator] += earned
       - validatorRewardDebt[validator][systemConfig] = rewardPerValidator[systemConfig]
       - Event: ValidatorRewardReceived (per L2)

2. total = validatorPendingRewards[msg.sender]
3. validatorPendingRewards[msg.sender] = 0
4. WTON.transfer(msg.sender, total)
5. Event: RewardsClaimed
```

---

## claimRewardsByL2s

Claims rewards from specific L2s (for gas optimization).

```solidity
function claimRewardsByL2s(address[] calldata systemConfigs) external ifFree
```

| Item | Content |
|------|---------|
| **Caller** | Validator |
| **Gas Complexity** | O(N) - Proportional to number of specified L2s |
| **Purpose** | Batch claim when registered to many L2s |

**Operation Flow**:
```
1. Synchronize rewards only for specified L2s
   └─► For each systemConfig:
       - Check isValidatorInL2[validator][systemConfig]
       - Call _syncReward only for registered L2s

2. total = validatorPendingRewards[msg.sender]
3. validatorPendingRewards[msg.sender] = 0
4. WTON.transfer(msg.sender, total)
5. Event: RewardsClaimed
```

**Usage Example** (when registered to 100 L2s):
```solidity
// Batch 1: Claim first 50 L2s
address[] memory batch1 = new address[](50);
// ... set batch1 array
validatorReward.claimRewardsByL2s(batch1);

// Batch 2: Claim remaining 50 L2s
address[] memory batch2 = new address[](50);
// ... set batch2 array
validatorReward.claimRewardsByL2s(batch2);
```

**Lazy Evaluation**:
- Rewards calculated at claim time, not distribution time
- Deactivated validators do not receive rewards

---

## registerValidatorToL2

Registers validator to L2 (called from RAT).

```solidity
function registerValidatorToL2(address validator, address systemConfig) external
```

| Item | Content |
|------|---------|
| **Caller** | RAT contract |
| **Access Control** | `msg.sender == ratContract` |

**Operation Flow**:
```
1. Skip if already registered
2. validatorL2List[validator].push(systemConfig)
3. isValidatorInL2[validator][systemConfig] = true
4. validatorRewardDebt[validator][systemConfig] = rewardPerValidator[systemConfig]
5. Event: ValidatorRegisteredToL2
```

---

## syncValidatorReward / resetValidatorDebt

Handles reward synchronization on validator deactivation/reactivation.

```solidity
function syncValidatorReward(address validator, address systemConfig) external
function resetValidatorDebt(address validator, address systemConfig) external
```

| Item | Content |
|------|---------|
| **Caller** | RAT contract |
| **Access Control** | `msg.sender == ratContract` |

**syncValidatorReward** (before deactivation):
- Accumulate rewards up to now in `validatorPendingRewards`
- Accumulated rewards claimable even after deactivation

**resetValidatorDebt** (on reactivation):
- Reset `validatorRewardDebt` to current `rewardPerValidator`
- Prevent receiving rewards during deactivation period

---

## Query Functions

```solidity
// Query total claimable rewards (including unsynchronized rewards)
function getClaimableRewards(address validator) external view returns (uint256 total)

// Query total unclaimed rewards (synchronized only)
function getPendingRewards(address validator) external view returns (uint256)

// Query unclaimed rewards by L2 (event usage recommended)
function getPendingRewardsByL2(address validator, address systemConfig)
    external pure returns (uint256)  // Always returns 0
```

**Recommended Usage**:
- Total reward query: `getClaimableRewards(validator)`
- L2-specific reward tracking: Subscribe to `ValidatorRewardReceived` event

---

## Validator Re-registration Mechanism

Reward processing mechanism when validators re-register after deactivation.

### On Deactivation

```
1. Call RAT.deactivateValidator() (voluntary withdrawal)
   or
   RAT.triggerAttentionTest() automatic removal (insufficient collateral)
   ↓
2. RAT → ValidatorReward.syncValidatorReward(validator, systemConfig)
   ↓
3. Save accumulated rewards up to now:
   validatorPendingRewards[validator] += (earned - debt)
   ↓
4. Set isActive = false
```

### Deactivation Period

```
- Excluded from distribution targets on new reward distribution
- Not included in activeValidatorCount since isActive = false
- Distribution amount = totalAmount / activeValidatorCount (inactive validators excluded)
- Inactive validators do not receive, only active validators share
```

### On Re-registration

```
1. Replenish collateral: Deposit D_min or more via DepositManager.deposit()
   ↓
2. Call RAT.registerValidator(systemConfig) (re-registration)
   ↓
3. RAT → ValidatorReward.resetValidatorDebt(validator, systemConfig)
   ↓
4. debt[validator][systemConfig] = rewardPerValidator[systemConfig]
   (Reset debt to current point)
   ↓
5. Set isActive = true
```

### After Re-registration

```
- Only previously synchronized rewards (step 3 saved portion) claimable
- During deactivation period, excluded from distribution, not received (active validators share)
- Receive new rewards from re-registration point onwards
```

**Example**:

```solidity
// 1. Validator registration → 1000 reward distributed → Claimable: 1000

// 2. Validator deactivation (syncValidatorReward called)
//    → validatorPendingRewards[validator] = 1000

// 3. Deactivation period → 2000 reward distributed
//    → Excluded from distribution since inactive (active validators share)
//    → validator1 claimable: 1000 (unchanged)

// 4. Validator re-registration (resetValidatorDebt called)
//    → debt = reset to current rewardPerValidator(3000)
//    → Claimable: 1000 (unchanged)

// 5. After re-registration, 500 reward distributed
//    → rewardPerValidator = 3500
//    → earned = 3500 - 3000 = 500
//    → Claimable: 1000 + 500 = 1500
```

**Note**: Rewards during deactivation period (2000) were not distributed to validator1, but shared by active validators.

---

## Inactive Validator Exclusion Mechanism

Inactive validators are automatically excluded during reward distribution.

```solidity
// Inside distributeL2Rewards()
activeValidatorCount = RAT.getActiveValidatorCount(systemConfig)
perValidator = totalAmount / activeValidatorCount  // Inactive excluded

// Example:
// Total validators: 5
// Active validators: 3 (2 inactive)
// Reward: 1000 WTON
// → perValidator = 1000 / 3 = 333.33 WTON (active validators only)
```

**Effects**:
- Inactive validators receive 0 reward
- Active validators receive more reward
- Strengthens validator participation incentives

---

## DAO Transfer When No Validators

When there are 0 validators, the entire validator reward is sent to DAO Treasury.

```solidity
if (activeValidatorCount == 0) {
    address daoVault = ISeigManager(seigManager).dao();
    WTON.transfer(daoVault, amount);
    emit RewardToDAO(systemConfig, amount);
    return;
}
```

**Event**:
```solidity
event RewardToDAO(
    address indexed systemConfig,
    uint256 amount
);
```
