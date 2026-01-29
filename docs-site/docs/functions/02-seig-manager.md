---
id: functions-seig-manager
sidebar_position: 2
---

# SeigManager Functions

Core seigniorage calculation and distribution functions.

## updateSeigniorage

The core function that executes seigniorage distribution.

```solidity
function updateSeigniorage() external whenNotPaused returns (bool)
```

| Item | Content |
|------|---------|
| **Caller** | Each L2 calls individually |
| **Access Control** | `whenNotPaused` |
| **Gas Cost** | Fixed (only processes calling L2, independent of L2 count) |

**Operation Flow**:

```
1. Total seigniorage calculation
   A = (block.number - lastSeigBlock) × seigPerBlock

2. v3Migrated check

   V2 mode (v3Migrated = false):
   └─► Execute V1_3 _increaseTot() logic
       - stakedSeig = A × prevTotalSupply / tos
       - l2TotalSeigs = A × tempTotalLayer2TVL / tos
       - totalPseig = unstakedSeig × r
       - Update Coinage factor

   V3 mode (v3Migrated = true):
   └─► _distributeV3Seigniorage(A)
       - DAO distribution: d × A
       - L2 distribution: y(x) = L × (x/(k+x))
       - Validator distribution: α × S_i → ValidatorReward

3. lastSeigBlock = block.number
```

**Events**:
- `SeigGiven2`: Detailed seigniorage distribution information
- `V3SeigniorageDistributed`: V3 distribution information (V3 mode only)

### V2 Seigniorage Distribution Mechanism

The complete flow for sequencers to receive seigniorage in V2 mode.

**Prerequisites**:

```
1. Layer2 registration complete
   - rollupConfig registered in L1BridgeRegistry
   - registerCandidateAddOn() called in Layer2Manager
   - Operator staking minimumAmount or more

2. Bridged TON required (layer2TVL > 0)
   - TON must be in Portal for layer2TVL to be detected
   - layer2TVL = IERC20(ton).balanceOf(portal)
   - No seigniorage distribution if layer2TVL is 0
```

**Note for Newly Registered L2's First updateSeigniorage() Call**:

When a newly registered L2 calls `updateSeigniorage()` for the first time, **it does not receive seigniorage immediately**.

```
┌─────────────────────────────────────────────────────────────────┐
│ New L2's First updateSeigniorage() call                         │
├─────────────────────────────────────────────────────────────────┤
│ • Set startBlock (layer2RewardInfo[layer2].startBlock)          │
│ • No actual seigniorage distribution (only records start point) │
│ • Seigniorage calculation begins from this block                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                     (After block progression)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Subsequent updateSeigniorage() calls                            │
├─────────────────────────────────────────────────────────────────┤
│ • Distribute seigniorage for blocks elapsed since startBlock   │
│ • Accumulate l2RewardPerUint (linear method)                    │
│ • Automatically increase staker balance via Coinage factor       │
└─────────────────────────────────────────────────────────────────┘
```

> **Note**: L2s that have already started receiving seigniorage will receive it normally on every call. The above only applies to the first call from a newly registered L2.

**V2 Distribution Formula**:

```solidity
// 1. Calculate total L2 seigniorage
l2TotalSeigs = rmul(maxSeig, tempTotalLayer2TVL) / tos

// 2. Accumulate reward per unit (linear method)
l2RewardPerUint += (l2TotalSeigs × WEI_UNIT) / totalLayer2TVL

// 3. Calculate individual L2 seigniorage
layer2Seigs = (l2RewardPerUint × layer2Tvl / WEI_UNIT) - initialDebt

// layer2Tvl = L1BridgeRegistry.layer2TVL(rollupConfig)
//           = IERC20(ton).balanceOf(portal)
```

**Sequencer/Staker Seigniorage Receipt Methods**:

In V2, seigniorage is received in two ways:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Layer2 Sequencer Seigniorage (layer2Seigs)                   │
├─────────────────────────────────────────────────────────────────┤
│ • Calculated in SeigManager: layer2Seigs                        │
│ • Calls Layer2Manager.transferL2Seigniorage()                   │
│ • WTON directly transferred to OperatorManager (IERC20.transfer)│
│ • WTON balance increases separately from Coinage staking        │
│                                                                  │
│ Code flow:                                                       │
│ SeigManagerV1_2.updateSeigniorageLayer()                        │
│   → Calculate layer2Seigs                                       │
│   → ILayer2Manager.transferL2Seigniorage(layer2, layer2Seigs)  │
│      → Layer2ManagerV1_1.transferL2Seigniorage()               │
│         → address operator = operatorOfLayer[layer2]           │
│         → IERC20(wton).safeTransfer(operator, amount)          │
│                                                                  │
│ Note: operator address is OperatorManager contract address      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 2. Operator/Staker Staking Seigniorage (Coinage Factor)         │
├─────────────────────────────────────────────────────────────────┤
│ • coinage.factor increases on updateSeigniorage() call          │
│ • Staker balance = deposit amount × factor                      │
│ • factor increase → staker balance auto increase (receive seig) │
│                                                                  │
│ Example:                                                         │
│ - Initial: deposit 100 WTON, factor = 1.0 → balance 100 WTON    │
│ - After seig: factor = 1.05 → balance 105 WTON (+5% seigniorage)│
│                                                                  │
│ Applies to: Both Operator and general Stakers                   │
└─────────────────────────────────────────────────────────────────┘
```

**V2 vs V3 Core Differences**:

| Item | V2 Mode | V3 Mode |
|------|---------|---------|
| **Distribution Basis** | `layer2TVL` (Portal TON balance) | `effectiveBridgedTON` (includes eligibility conditions) |
| **Distribution Function** | Linear accumulation (`l2RewardPerUint`) | Hyperbolic `y(x) = L·x/(k+x)` |
| **Staker Seigniorage** | ✅ Receive (coinage factor) | ❌ Not received |
| **Validator Reward** | ❌ None | ✅ α×S_i / \|V_i\| |
| **Eligibility Condition** | Only check `minimumAmount` | `T_i ≥ max(θ×B_i, D_seq)` |

**V3 Mode Reward Tracking**:

Sequencer and validator rewards are **tracked independently**:

```solidity
bridgedTONRewardPerUint  // For sequencer (reward per Bridged TON unit)
validatorRewardPerUint   // For validator (reward per Bridged TON unit)
```

Update formula:
```
bridgedTONRewardPerUint += (1-α) × S_i / totalEffectiveBridgedTON
validatorRewardPerUint += α × S_i / totalEffectiveBridgedTON

Where:
α = validatorDistributionRatio
S_i = L2-specific seigniorage
```

Ratio relationship:
```
validatorRewardPerUint / bridgedTONRewardPerUint ≈ α / (1-α)

Example: α = 0.2 (20%)
→ Ratio = 0.2 / 0.8 = 0.25
```

---

## checkCurrentEligibility

Checks L2 eligibility conditions.

```solidity
function checkCurrentEligibility(address layer2)
    external view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake)
```

| Item | Content |
|------|---------|
| **Caller** | Anyone |
| **Return Values** | Eligibility status, required collateral, current collateral |

**Eligibility Condition**:
```
eligible = (T_i ≥ max(θ × B_i, D_sequencer))

Where:
- T_i = SeigManager.getSequencerStaked(layer2) [WTON, 27 decimals]
- θ × B_i = Seigniorage eligibility condition
- D_sequencer = H_max × C_max + Δ_sequencer (Fraud Proof cost coverage)

Parameters:
- θ = minStakingRatio [RAY, 27 decimals]
- B_i = Layer2Manager.getBridgedTONByLayer(layer2) [TON, 18 decimals]
- H_max = maxChallengers (maximum simultaneous challengers)
- C_max = maxFraudProofCost (maximum cost per Fraud Proof)
- Δ_sequencer = sequencerAdditionalReward (sequencer additional reward)
```

> **Unit Note**: T_i is WTON (27 decimals), B_i is TON (18 decimals). Unit conversion needed for comparison.

---

## onBridgedTonChange

Re-evaluates eligibility when Bridged TON changes (Type 3 only).

```solidity
function onBridgedTonChange() external whenV3Active
```

| Item | Content |
|------|---------|
| **Caller** | OptimismPortal (Type 3) |
| **Access Control** | `whenV3Active` (V3 mode only) |
| **Behavior** | Early return pattern (does not revert) |

**Operation Flow**:
```
1. L1BridgeRegistry.rollupConfigWithPortal(msg.sender) → query rollupConfig
   ├─ Unregistered portal → early return
   └─ Not Type 3 → early return

2. Layer2Manager.getLayer2BySystemConfig(rollupConfig) → query layer2
   └─ Unregistered L2 → early return

3. _updateEligibilityInternal(layer2)
   ├─ Re-evaluate eligibility (T_i ≥ θ × B_i)
   └─ Update totalEffectiveBridgedTON
```

---

## onStakingChange

Re-evaluates eligibility when staking changes.

```solidity
function onStakingChange(address layer2) external onlyDepositManager
```

| Item | Content |
|------|---------|
| **Caller** | DepositManager |
| **Access Control** | `onlyDepositManager` |

---

## migrateToV3

Switches to V3 mode.

```solidity
function migrateToV3() external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | DAO (Owner) |
| **Access Control** | `onlyOwner` |
| **Reversibility** | Impossible |

**Transition Effects**:
- `v3Migrated = true`
- Staker seigniorage deactivated
- Bridged TON-based distribution activated
- Validator rewards activated

---

## Governance Functions

```solidity
// Set DAO distribution ratio (0 < d < 1)
function setDaoDistributionRatio(uint256 ratio) external onlyOwner

// Set minimum staking ratio (0 < θ ≤ 1)
function setMinStakingRatio(uint256 ratio) external onlyOwner

// Set validator distribution ratio (0 < α < 1)
function setValidatorDistributionRatio(uint256 ratio) external onlyOwner

// Set half saturation point (k > 0)
function setHalfSaturationPoint(uint256 k) external onlyOwner

// Set ValidatorReward contract address
function setValidatorReward(address reward) external onlyOwner

// Set RAT contract address
function setRatContract(address rat) external onlyOwner

// Set V2 logic contract (V2 compatibility)
function setV2Logic(address v2Logic) external onlyOwner

// Set slashing parameters
function setMaxChallengers(uint256 _maxChallengers) external onlyOwner
function setMaxFraudProofCost(uint256 _maxFraudProofCost) external onlyOwner
function setSequencerAdditionalReward(uint256 _sequencerAdditionalReward) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner (DAO) |
| **Access Control** | `onlyOwner` |
| **Boundary Conditions** | All allow 0, no upper limit |

**Slashing Parameter Usage**:

Used in D_sequencer calculation:
```
D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward

Example:
maxChallengers = 3
maxFraudProofCost = 50e27 WTON
sequencerAdditionalReward = 100e27 WTON
→ D_sequencer = 3 × 50e27 + 100e27 = 250e27 WTON
```

---

## RAT Integration Functions (V3 Only)

Handles collateral transfers with RAT.

```solidity
// Transfer Coinage from validator → RAT (slashing pre-deduction)
function transferCoinageToRat(address layer2, address validator, uint256 amount) 
    external onlyRAT

// Return Coinage from RAT → validator (evidence submission or challenge win)
function transferCoinageFromRat(address layer2, address validator, uint256 amount) 
    external onlyRAT

// Transfer Coinage from RAT → specified address (special case)
function transferCoinageFromRatTo(address layer2, address to, uint256 amount) 
    external onlyRAT
```

| Item | Content |
|------|---------|
| **Caller** | RAT contract |
| **Access Control** | `onlyRAT` |
| **Purpose** | Collateral management during RAT tests |

---

## claimL2Seigniorage

Claims only L2 rewards without triggering seigniorage (for gas optimization).

```solidity
function claimL2Seigniorage(address layer2) external whenV3Active whenNotPaused
```

| Item | Content |
|------|---------|
| **Caller** | Anyone |
| **Access Control** | `whenV3Active`, `whenNotPaused` |
| **Purpose** | Claim only L2 rewards without updateSeigniorage |

**Operation Flow**:
```
1. Check V3 mode
2. Transfer if accumulated seigniorage exists per layer2
3. Do not calculate new seigniorage (gas savings)
```

---

## Automatic Claim on Eligibility Loss

When an L2 loses seigniorage eligibility, **unclaimed sequencer rewards are automatically claimed**.

**Trigger Functions**:
- `onStakingChange()` - Called by DepositManager on deposit/withdrawal
- `checkAndUpdateEligibility()` - Internal eligibility status change detection

**Operation Flow**:
```
1. Detect eligibility status change (eligible → ineligible)
   ↓
2. Automatically claim unclaimed rewards
   → Call _claimL2Seigniorage(layer2)
   → Transfer WTON to OperatorManager
   ↓
3. Set effectiveBridgedTON = 0
   ↓
4. Emit event: AutoClaimBeforeEligibilityLoss(layer2, amount)
```

**Event**:
```solidity
event AutoClaimBeforeEligibilityLoss(
    address indexed layer2,
    uint256 claimedAmount
);
```

---

## onWithdraw

Checks minimum collateral requirements on withdrawal request.

```solidity
function onWithdraw(address layer2, address account, uint256 amount) external onlyDepositManager returns (bool)
```

| Item | Content |
|------|---------|
| **Caller** | DepositManager |
| **Access Control** | `onlyDepositManager` |
| **Return Value** | Always true |

**Operation Flow**:

```
1. Check balance
   balance = coinage.balanceOf(account)
   require(balance >= amount)
   newBalance = balance - amount

2. Sequencer (operator) collateral check
   if (account == layer2.operator()):
       V2 mode (v3Migrated = false):
           require(newBalance >= minimumAmount)

       V3 mode (v3Migrated = true):
           (_, requiredStake, _) = checkCurrentEligibility(layer2)
           require(newBalance >= requiredStake)

3. Validator collateral check (V3 only)
   if (v3Migrated && ratContract != address(0)):
       validatorMin = RAT.getValidatorMinCollateralForLayer2(layer2, account)
       if (validatorMin > 0):
           require(newBalance >= validatorMin)

4. Process withdrawal
   - TOT burn
   - Coinage burn
```

**Withdrawal Restrictions**:

```
V2 mode:
- Sequencer: Balance after withdrawal ≥ minimumAmount (fixed value)

V3 mode:
Sequencer:
- Must maintain balance after withdrawal ≥ max(θ × B_i, D_sequencer)
  - θ × B_i = minStakingRatio × getBridgedTONByLayer(layer2) (seigniorage eligibility)
  - D_sequencer = H_max × C_max + Δ_sequencer (Fraud Proof cost)
- Real-time calculation via checkCurrentEligibility()

Validator:
- Active validators must maintain balance after withdrawal ≥ D_min (pure)
- D_min (pure) = C_off(dynamic) + Δ_validator
  - C_off(dynamic) = max(slashingPenalty, (c_m × N × RAY) / π_a)
- Always apply pure D_min regardless of relaxedValidatorCheck (security first)
- Must deactivate validator (deactivateValidator()) to withdraw below minimum collateral
```

---

## onDeposit

Checks minimum collateral requirements on deposit request.

```solidity
function onDeposit(address layer2, address account, uint256 amount) external onlyDepositManager returns (bool)
```

| Item | Content |
|------|---------|
| **Caller** | DepositManager |
| **Access Control** | `onlyDepositManager` |
| **Return Value** | Always true |

**Operation Flow**:

```
1. Check balance
   balance = coinage.balanceOf(account)
   newBalance = balance + amount

2. Sequencer (operator) minimum collateral check
   if (account == layer2.operator()):
       V2 mode (v3Migrated = false):
           require(newBalance >= minimumAmount)

       V3 mode (v3Migrated = true):
           (_, requiredStake, _) = checkCurrentEligibility(layer2)
           require(newBalance >= requiredStake)

3. Process deposit
   - TOT mint
   - Coinage mint

4. Update eligibility status (V3 only)
   if (v3Migrated):
       _updateEligibilityInternal(layer2)
```

**Deposit Restrictions**:

```
V2 mode:
- Sequencer: Balance after deposit ≥ minimumAmount (fixed value)

V3 mode:
- Sequencer: Must maintain balance after deposit ≥ max(θ × B_i, D_sequencer)
- General users/validators: No deposit amount limit (only sequencer checked)
```
