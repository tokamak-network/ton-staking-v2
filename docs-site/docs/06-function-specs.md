---
id: 06-function-specs
sidebar_position: 6
---
# TON Staking V3 Detailed Function Specifications

## 1. SeigManager Functions

### 1.1 updateSeigniorage

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
1. 전체 시뇨리지 계산
   A = (block.number - lastSeigBlock) × seigPerBlock

2. v3Migrated 확인

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

#### 1.1.1 V2 Seigniorage Distribution Mechanism (Detailed)

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

**V2 시뇨리지 분배 공식**:

```solidity
// 1. 전체 L2 시뇨리지 계산
l2TotalSeigs = rmul(maxSeig, tempTotalLayer2TVL) / tos

// 2. 단위당 보상 누적 (선형 방식)
l2RewardPerUint += (l2TotalSeigs × WEI_UNIT) / totalLayer2TVL

// 3. 개별 L2 시뇨리지 계산
layer2Seigs = (l2RewardPerUint × layer2Tvl / WEI_UNIT) - initialDebt

// layer2Tvl = L1BridgeRegistry.layer2TVL(rollupConfig)
//           = IERC20(ton).balanceOf(portal)
```

**시퀀서/스테이커 시뇨리지 수령 방식**:

V2에서는 시뇨리지 수령 방식이 두 가지로 나뉩니다:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Layer2 시퀀서 시뇨리지 (layer2Seigs)                          │
├─────────────────────────────────────────────────────────────────┤
│ • SeigManager에서 계산: layer2Seigs                              │
│ • Layer2Manager.transferL2Seigniorage() 호출                    │
│ • OperatorManager 주소로 WTON 직접 전송 (IERC20.transfer)       │
│ • Coinage 스테이킹과 별도로 WTON 잔액 증가                        │
│                                                                  │
│ 코드 흐름:                                                       │
│ SeigManagerV1_2.updateSeigniorageLayer()                        │
│   → layer2Seigs 계산                                            │
│   → ILayer2Manager.transferL2Seigniorage(layer2, layer2Seigs)  │
│      → Layer2ManagerV1_1.transferL2Seigniorage()               │
│         → address operator = operatorOfLayer[layer2]           │
│         → IERC20(wton).safeTransfer(operator, amount)          │
│                                                                  │
│ 주의: operator 주소는 OperatorManager 컨트랙트 주소              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 2. Operator/Staker 스테이킹 시뇨리지 (Coinage Factor)            │
├─────────────────────────────────────────────────────────────────┤
│ • updateSeigniorage() 호출 시 coinage.factor 증가               │
│ • 스테이커 잔액 = 예치량 × factor                                │
│ • factor 증가 → 스테이커 잔액 자동 증가 (시뇨리지 수령)          │
│                                                                  │
│ 예시:                                                            │
│ - 초기: 예치 100 WTON, factor = 1.0 → 잔액 100 WTON              │
│ - 시뇨리지 후: factor = 1.05 → 잔액 105 WTON (+5% 시뇨리지)       │
│                                                                  │
│ 적용 대상: Operator와 일반 Staker 모두                           │
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

### 1.2 checkCurrentEligibility

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

### 1.3 onBridgedTonChange

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

### 1.4 onStakingChange

Re-evaluates eligibility when staking changes.

```solidity
function onStakingChange(address layer2) external onlyDepositManager
```

| Item | Content |
|------|---------|
| **Caller** | DepositManager |
| **Access Control** | `onlyDepositManager` |

---

### 1.5 migrateToV3

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

### 1.6 Governance Functions

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

### 1.7 RAT Integration Functions (V3 Only)

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

### 1.8 claimL2Seigniorage

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

### 1.9 Automatic Claim on Eligibility Loss

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

**Eligibility Reacquisition**:
- On eligibility reacquisition after additional collateral deposit
- Restore `effectiveBridgedTON`
- Accumulate new rewards from now on
- **Rewards during eligibility loss period are not received**

**이벤트**:
```solidity
event AutoClaimBeforeEligibilityLoss(
    address indexed layer2,
    uint256 claimedAmount
);
```

---

### 1.10 onWithdraw

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

### 1.10 onDeposit

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

---

## 2. DepositManager Functions

### 2.1 deposit

Stakes WTON.

```solidity
function deposit(address layer2, address account, uint256 amount)
    external
    onlyLayer2(layer2)
    returns (bool)
```

| Item | Content |
|------|---------|
| **Caller** | Staker |
| **Parameters** | layer2: L2 address, account: beneficiary, amount: WTON amount |

**Operation Flow**:
```
1. WTON.transferFrom(msg.sender, this, amount)
2. Update staking records
   - _accStaked[layer2][account] += amount
   - _accStakedLayer2[layer2] += amount
3. SeigManager.onDeposit(layer2, account, amount)
   - V3: Includes minimum collateral check and eligibility status update
```

---

### 2.2 Configuration Functions (V3 Only)

Configuration functions added in DepositManagerV3.

```solidity
// Initial address setup (L1BridgeRegistry, Layer2Manager)
function setAddresses(address _l1BridgeRegistry, address _layer2Manager) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner (DAO) |
| **Purpose** | Initial setup after V3 deployment |

---

### 2.3 onApprove

TON.approveAndCall callback.

```solidity
function onApprove(
    address owner,
    address spender,
    uint256 amount,
    bytes calldata data
) external returns (bool)
```

| Item | Content |
|------|---------|
| **Caller** | WTON contract (via TON.approveAndCall) |
| **data Format** | layer2 address (32 bytes) |

---

### 2.4 requestWithdrawal

Requests withdrawal.

```solidity
function requestWithdrawal(address layer2, uint256 amount) external
```

| Item | Content |
|------|---------|
| **Caller** | Staker |
| **Waiting Period** | 2 weeks (approximately 100,800 blocks) |
| **Withdrawal Restrictions** | Checked in SeigManager.onWithdraw() (see 1.7) |

---

### 2.5 processRequest

Processes withdrawal.

```solidity
function processRequest(address layer2) external
```

| Item | Content |
|------|---------|
| **Caller** | Staker |
| **Condition** | 2 weeks waiting period elapsed |

---

## 3. Layer2Manager Functions

### 3.1 getBridgedTon

Queries Bridged TON.

```solidity
function getBridgedTon(address rollupConfig) public view returns (uint256 bridgedTON)
function getBridgedTonByLayer(address layer2) public view returns (uint256 bridgedTON)
```

| Item | Content |
|------|---------|
| **Caller** | Anyone |
| **Query Method** | Calls L1BridgeRegistry.layer2Tvl() |

---

### 3.2 Configuration Functions (V3 Only)

Configuration functions added in Layer2ManagerV3.

```solidity
// Address setup 1 (L1BridgeRegistry, DepositManager)
function setAddresses1(address _l1BridgeRegistry, address _depositManager) external onlyOwner

// Address setup 2 (SeigManager, OperatorManagerFactory)
function setAddresses2(address _seigManager, address _operatorManagerFactory) external onlyOwner

// OperatorManagerFactory update
function setOperatorManagerFactory(address _operatorManagerFactory) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner (DAO) |
| **Purpose** | Initial setup and updates after V3 deployment |

---

### 3.3 getLayer2BySystemConfig

Queries Layer2 address by SystemConfig.

```solidity
function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2)
```

---

## 4. L1BridgeRegistry Functions

### 4.1 layer2Tvl

Queries L2 TVL (Bridged TON).

```solidity
function layer2Tvl(address rollupConfig) external view returns (uint256)
```

**Query Method by Rollup Type**:

| Type | Query Target | Query Method |
|------|--------------|--------------|
| Type 1 (Legacy) | L1StandardBridge | Query TON balance |
| Type 2 (Bedrock) | OptimismPortal | Query TON balance |
| Type 3 (Dispute Game) | OptimismPortal | Query TON balance |

---

### 4.2 rollupConfigWithPortal

Reverse queries rollupConfig by Portal address.

```solidity
function rollupConfigWithPortal(address portal) external view returns (address rollupConfig)
```

| Item | Content |
|------|---------|
| **Purpose** | Query rollupConfig from msg.sender(Portal) in onBridgedTonChange |

---

### 4.3 setTypeRegistrant

Sets type-specific registration authority.

```solidity
function setTypeRegistrant(uint8 _type, address _registrant) external onlyManager
```

| Item | Content |
|------|---------|
| **Caller** | Manager |
| **Parameters** | `_type`: Rollup type (1, 2, 3, ...), `_registrant`: Authority address |
| **Special Notes** | When `address(0)` is set, only Manager can register |

---

### 4.4 upgradeToType3

Upgrades from TYPE 1/2 to TYPE 3.

```solidity
function upgradeToType3(address rollupConfig) external onlyManager
```

| Item | Content |
|------|---------|
| **Caller** | Manager |
| **Prerequisites** | Must be registered as TYPE 1 or 2, DisputeGameFactory required |

**Operation Flow**:
```
1. Check current type (only TYPE 1 or 2 allowed)
2. Query and verify DisputeGameFactory address
3. Query and verify Portal address
4. Register Portal:
   - Set portal[portal_] to true if not registered
   - Set rollupConfigWithPortal if not set + emit event
   - Revert if registered to another rollupConfig
5. Check DisputeGameFactory duplicates and register
6. Change rollupType = 3
```

---

### 4.5 registerRollupConfigByType

Rollup registration with type-specific permission check.

```solidity
function registerRollupConfigByType(
    address rollupConfig,
    uint8 _type,
    address _l2TON,
    string calldata _name
) external onlyTypeRegistrant(_type)
```

| Item | Content |
|------|---------|
| **Caller** | Manager or `typeRegistrant[_type]` |
| **Parameters** | `_type`: 1(Legacy), 2(Bedrock), 3(Dispute Game) |

---

### 4.6 setAddresses

Performs initial setup.

```solidity
function setAddresses(
    address _layer2Manager,
    address _seigManager,
    address _ton
) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner |
| **Prerequisites** | ton == address(0) (uninitialized state) |
| **Special Notes** | Can only be called once |

---

### 4.7 setSeigniorageCommittee

Sets SeigniorageCommittee address.

```solidity
function setSeigniorageCommittee(address _seigniorageCommittee) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner |
| **Special Notes** | Cannot set same address as existing |

---

### 4.8 rejectCandidateAddOn

Stops seigniorage issuance for a specific rollupConfig.

```solidity
function rejectCandidateAddOn(address rollupConfig) external onlySeigniorageCommittee
```

| Item | Content |
|------|---------|
| **Caller** | SeigniorageCommittee |
| **Prerequisites** | rollupType != 0 (registered state) |

**Operation Flow**:
```
1. Check registration status
2. rejectedSeigs = true
3. rejectedL2Deposit = true
4. Call Layer2Manager.pauseCandidateAddOn(rollupConfig)
5. Event: RejectedCandidateAddOn
```

---

### 4.9 restoreCandidateAddOn

Restores stopped seigniorage issuance.

```solidity
function restoreCandidateAddOn(
    address rollupConfig,
    bool rejectedL2Deposit
) external onlySeigniorageCommittee
```

| Item | Content |
|------|---------|
| **Caller** | SeigniorageCommittee |
| **Prerequisites** | rejectedSeigs == true (stopped state) |

**Operation Flow**:
```
1. Check stopped status
2. rejectedSeigs = false
3. rejectedL2Deposit = parameter value
4. Call Layer2Manager.unpauseCandidateAddOn(rollupConfig)
5. Event: RestoredCandidateAddOn
```

---

### 4.10 registerRollupConfig

Registers rollup with Registrant authority.

```solidity
function registerRollupConfig(
    address rollupConfig,
    uint8 _type,
    address _l2TON,
    string calldata _name
) external onlyRegistrant
```

| Item | Content |
|------|---------|
| **Caller** | Registrant |
| **Parameters** | `_type`: 1(Legacy), 2(Bedrock), 3(Dispute Game) |
| **Special Notes** | Uses V1_2's `_registerRollupConfig` (includes rollupConfigWithPortal setup) |

---

### 4.11 View Functions

```solidity
// Query rollup type
function rollupType(address rollupConfig) external view returns (uint8)

// Query L2 TON address
function l2TON(address rollupConfig) external view returns (address)

// Query complete rollup information
function getRollupInfo(address rollupConfig) external view returns (
    uint8 type_,
    address l2TON_,
    bool rejectedSeigs_,
    bool rejectedL2Deposit_,
    string memory name_
)

// Check if seigniorage stopped
function isRejectedSeigs(address rollupConfig) external view returns (bool)

// Check if L2 deposit stopped
function isRejectedL2Deposit(address rollupConfig) external view returns (bool)

// Check registration availability
function availableForRegistration(address rollupConfig, uint8 _type) external view returns (bool)
```

---

## 5. RAT Functions

### 5.1 registerValidator

Registers validator (V3: uses existing staking).

```solidity
function registerValidator(address systemConfig) external
```

| Item | Content |
|------|---------|
| **Caller** | Validator |
| **Minimum Collateral** | D_min = C_off + Δ_validator (coinage basis) |

**Operation Flow**:
```
1. Check if already active validator
   └─ If isActive = true, fail (AlreadyRegisteredError)

2. Check current staking amount: stakeOf(layer2, validator)

3. Check staking amount >= D_min
   └─ If insufficient: Registration fails (InsufficientCollateralError)

4. Save registration information
   - Create/update validatorRegistrations[systemConfig][validator]
   - validatorPools[systemConfig].validators.push()

5. Activate: isActive = true
```

**Re-registration (After Automatic Removal)**:

When validator is automatically removed (`isActive = false`) due to insufficient collateral:

```
1. Replenish collateral
   - Deposit D_min or more via DepositManager.deposit()

2. Re-register
   - Call RAT.registerValidator(systemConfig)
   - Can re-register since isActive = false
   - Reactivate if D_min or more

Notes:
- Can re-register even if RAT test in progress
  (Collateral in coinage allows slashing processing)
- V3: Validator rewards managed separately by ValidatorReward contract
```

---

### 5.2 triggerAttentionTest

Triggers RAT test.

```solidity
function triggerAttentionTest(
    address gameAddress,
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external
```

| Item | Content |
|------|---------|
| **Caller** | DisputeGameFactory |
| **Trigger Probability** | π_a (ratTriggerProbability) |

**Operation Flow**:
```
1. Permission verification: Check factory in L1BridgeRegistry
2. Probability check: hash(blockHash) % MAX < π_a
3. Random validator selection
4. C_off pre-deduction: Transfer C_off from validator coinage to RAT contract (staking amount decreases)
5. Set deadline: deadline = block.timestamp + evidenceSubmissionPeriod
6. Deactivate if below C_off or D_min based on relaxedValidatorCheck
7. Event: AttentionTestTriggered
```

---

### 5.4 submitEvidence

Submits RAT evidence.

```solidity
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata evidence
) external
```

| Item | Content |
|------|---------|
| **Caller** | Selected validator |
| **Deadline** | Within evidenceSubmissionPeriod |

**Operation Flow**:
```
1. Verify validator: test.validatorAddress == msg.sender
2. Check status: status == EvidencePeriod
3. Check deadline: block.timestamp <= deadline
4. Verify evidence
5. Restore collateral: Return C_off from RAT contract to validator (staking amount restored)
6. Attempt automatic reactivation:
   - Auto reactivate if isActive=false and collateral >= threshold
   - Threshold: relaxedValidatorCheck ? C_off : D_min
7. Event: EvidenceSubmitted (ValidatorReactivated also emitted on reactivation)
```

---

### 5.5 resolveClaim

Restores collateral on challenge win.

```solidity
function resolveClaim(address _claimant) external
```

| Item | Content |
|------|---------|
| **Caller** | FaultDisputeGame |
| **Purpose** | Restore collateral when challenger (validator) wins game |

**Operation Flow**:
```
1. Query testId by msg.sender (game address)
2. Verify selected validator == _claimant
3. Restore collateral: Return C_off from RAT contract to validator (staking amount restored)
4. Attempt automatic reactivation:
   - Auto reactivate if isActive=false and collateral >= threshold
   - Threshold: relaxedValidatorCheck ? C_off : D_min
5. Event: BondRestored (ValidatorReactivated also emitted on reactivation)
```

---

### 5.6 deactivateValidator

Deactivates validator.

```solidity
function deactivateValidator(address systemConfig) external
```

| Item | Content |
|------|---------|
| **Caller** | Validator themselves |
| **Withdrawal** | Use DepositManager.requestWithdrawal() |

**Operation Flow**:
```
1. Check active status
2. Check RAT test wait: block.timestamp >= latestTestDeadline
3. Process C_off confiscation for unresponded RAT tests
4. Deactivate: isActive = false
5. Event: ValidatorDeactivated

Staking withdrawal done separately via DepositManager.requestWithdrawal()
```

---

### 5.7 Query Functions

```solidity
// Calculate minimum collateral
function getMinimumCollateral() external view returns (uint256)
// Returns: slashingPenalty + validatorBuffer

// Query L2-specific validator list
function getL2Validators(address systemConfig) external view returns (address[] memory)

// Check validator active status
function isValidatorActive(address validator, address systemConfig) external view returns (bool)

// Query active validator count
function getActiveValidatorCount(address systemConfig) external view returns (uint256)

// Query validator registration information
function getValidatorRegistration(address validator, address systemConfig)
    external view returns (uint256 depositedAmount, uint256 totalBondForRAT, uint32 validatorIndex, bool isActive)
```

---

### 5.13 D_min Calculation Formula

Validator minimum collateral D_min is calculated dynamically.

**Basic Formula**:

```
C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)
D_min = C_off + validatorBuffer

Where:
slashingPenalty = Slashing penalty (default value)
c_m = attentionCost (monitoring cost)
N = Number of validators (minimum 1)
π_a = ratTriggerProbability (RAT trigger probability)
validatorBuffer = Validator buffer
```

**Calculation Example**:

```
slashingPenalty = 100e27 WTON
attentionCost = 150e27 WTON
N = 3 (3 validators)
π_a = 1e27 (100%)
validatorBuffer = 100e27 WTON

→ C_off = max(100e27, (150e27 × 3 × 1e27) / 1e27) 
        = max(100e27, 450e27) 
        = 450e27 WTON

→ D_min = 450e27 + 100e27 = 550e27 WTON
```

**Effect of Validator Count Increase**:
- C_off increases as N increases (dynamic)
- More validators → Higher D_min requirement

---

### 5.14 relaxedValidatorCheck Flag

Controls validator validity check mode.

| Mode | relaxedValidatorCheck | C_off Calculation | Purpose |
|------|----------------------|-------------------|---------|
| **Relaxed Mode** | `true` | `C_off = slashingPenalty` (fixed) | Early network, validator attraction |
| **Strict Mode** | `false` | `C_off = max(slashingPenalty, formula)` (dynamic) | Stable network, security first |

**Function Differences**:

1. **getDynamicMinimumCollateral(systemConfig)**
   - **Always** uses dynamic formula (ignores relaxedCheck)
   - Query actual game theory-based minimum value
   - Purpose: Reference for parameter adjustment

2. **getCoffWithRelaxedCheck(systemConfig)**
   - Varies based on relaxedCheck flag
   - `true`: Returns `slashingPenalty` (fixed)
   - `false`: Uses dynamic formula
   - Purpose: Actual validator validity check

**Governance Setup**:

```solidity
// Relaxed mode (early network)
rat.setRelaxedValidatorCheck(true);
rat.setSlashingPenalty(100e27);  // Use fixed value only

// Strict mode (stable network)
rat.setRelaxedValidatorCheck(false);
rat.setAttentionCost(150e27);     // Activate dynamic formula
rat.setRatTriggerProbability(1e27);
```

**Notes**:
- `onWithdraw()` check **always uses pure D_min** (security first)
- `triggerAttentionTest()` removal criteria follows relaxedCheck:
  - `true`: Removal criteria = C_off (relaxed)
  - `false`: Removal criteria = D_min (strict)

---

## 6. ValidatorReward Functions

### 6.1 distributeL2Rewards

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

### 6.2 claimAllRewards

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

### 6.2.1 claimRewardsByL2s

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

### 6.3 registerValidatorToL2

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

### 6.4 syncValidatorReward / resetValidatorDebt

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

### 6.5 Query Functions

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

### 6.6 Validator Re-registration Mechanism

Reward processing mechanism when validators re-register after deactivation.

**6.6.1 On Deactivation**

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

**6.6.2 Deactivation Period**

```
- Excluded from distribution targets on new reward distribution
- Not included in activeValidatorCount since isActive = false
- Distribution amount = totalAmount / activeValidatorCount (inactive validators excluded)
- Inactive validators do not receive, only active validators share
```

**6.6.3 On Re-registration**

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

**6.6.4 After Re-registration**

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

### 6.7 Inactive Validator Exclusion Mechanism

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

### 6.8 DAO Transfer When No Validators

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

---

## 7. SeigManager Sequencer Slashing Functions

### 7.1 slashSequencerByGame

Slashes sequencer (Permissionless). Handled in SeigManager in V3.

```solidity
function slashSequencerByGame(address gameAddress) external whenV3Active whenNotPaused
```

| Item | Content |
|------|---------|
| **Caller** | Anyone |
| **Condition** | Game ended with status != DEFENDER_WINS |

**Operation Flow**:
```
1. Verify DisputeGameFactory (prevent fake games)
2. Check game status: status != DEFENDER_WINS
3. Confiscate sequencer's entire staking amount (coinage.burnFrom)
4. Calculate challenger reward: C_max + Δ/n
5. Pay challenger reward (WTON.mint)
6. Remainder: DAO Treasury
7. Event: SequencerSlashed
```

> **V3 Change**: Sequencer collateral uses existing staking system (coinage).

---

## 8. OperatorManagerFactory Functions

### 8.1 createOperatorManager

Creates operator manager.

```solidity
function createOperatorManager(address rollupConfig) external returns (address operatorManager)
```

| Item | Content |
|------|---------|
| **Caller** | Layer2Manager only |
| **Implementation** | V1_1 (default, manual upgrade to V1_2 for TYPE 3 upgrade) |

**Operation Flow**:
```
1. Verify msg.sender == layer2Manager
2. Query rollupConfig's unsafeBlockSigner() → sManager
3. Create OperatorManagerProxy with CREATE2
4. Call upgradeTo(operatorManagerImp), setAddresses()
5. transferManager(sManager), transferOwnership(sOwner)
```

---

### 8.2 getAddress

Calculates operator manager address.

```solidity
function getAddress(address rollupConfig) public view returns (address)
```

| Item | Content |
|------|---------|
| **Purpose** | CREATE2 address calculation |

---

### 8.3 Configuration Functions

```solidity
// Change implementation
function changeOperatorManagerImp(address newOperatorManagerImp) external onlyOwner

// Set addresses
function setAddresses(address _depositManager, address _ton, address _wton, address _layer2Manager) external onlyOwner
```

---

### 8.4 TYPE 3 Upgrade Procedure

To upgrade TYPE 1/2 rollup to TYPE 3 by introducing DisputeGame:

```
1. L1BridgeRegistry.upgradeToType3(rollupConfig)
   └── Verify and register DisputeGameFactory
   └── Change rollupType = 3

2. OperatorManagerProxy.upgradeTo(V1_2 impl)
   └── Owner calls directly
   └── Activate TYPE 3 features
```

---

## 9. Governance Parameter Summary

### 9.1 SeigManager Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `daoDistributionRatio` | `setDaoDistributionRatio(d)` | 0 < d < 1 | RAY |
| `minStakingRatio` | `setMinStakingRatio(θ)` | 0 < θ ≤ 1 | RAY |
| `validatorDistributionRatio` | `setValidatorDistributionRatio(α)` | 0 < α < 1 | RAY |
| `halfSaturationPoint` | `setHalfSaturationPoint(k)` | k > 0 | RAY (TON) |

### 9.2 RAT Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `slashingPenalty` | `setSlashingPenalty(C_off)` | C_off > 0 | TON |
| `validatorBuffer` | `setValidatorBuffer(Δ)` | Δ ≥ 0 | TON |
| `ratTriggerProbability` | `setRatTriggerProbability(π_a)` | 0 < π_a ≤ 1 | RAY |
| `minimumThreshold` | `setMinimumThreshold(D_min)` | D_min > 0 | TON |
| `evidenceSubmissionPeriod` | `setEvidenceSubmissionPeriod(t)` | t > 0 | seconds |
| `validatorReward` | `setValidatorReward(addr)` | addr != 0 | address |

### 9.3 ValidatorReward Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `seigManager` | `setSeigManager(addr)` | addr != 0 | address |
| `ratContract` | `setRatContract(addr)` | addr != 0 | address |

### 9.4 SeigManager Sequencer Slashing Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | count |

---

## 10. Event List

### 10.1 SeigManager Events

```solidity
event V3SeigniorageDistributed(uint256 totalSeigniorage, uint256 l2MaxAllocation, uint256 totalDistributed, uint256 daoAmount, uint256 validatorPoolAmount);
event EligibilityChanged(address indexed layer2, bool eligible, uint256 bridgedTON, uint256 effectiveBridgedTON);
event V3MigrationCompleted(uint256 blockNumber, uint256 totalMigratedL2s);
event SeigGiven2(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig, uint256 l2TotalSeigs, uint256 layer2Seigs);
```

### 10.2 RAT Events

```solidity
event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId);
event ValidatorDeactivated(address indexed validator, address indexed systemConfig, uint256 returnedAmount);
event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline);
event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex);
event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet);
event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 restoredAmount);
```

### 10.3 ValidatorReward Events

```solidity
// L2-specific validator reward distribution event (summary)
event L2RewardDistributed(
    address indexed systemConfig,
    uint256 totalAmount,           // Total distribution amount
    uint256 activeValidatorCount,  // Active validator count
    uint256 perValidator           // Per-validator distribution amount
);

// Per-validator reward distribution event (occurs at claim time)
event ValidatorRewardReceived(
    address indexed validator,
    address indexed systemConfig,
    uint256 amount
);

// Event when no validators, reward goes to DAO
event RewardToDAO(address indexed systemConfig, uint256 amount);

// Validator reward claim event
event RewardsClaimed(address indexed validator, uint256 amount);

// Validator L2 registration event
event ValidatorRegisteredToL2(
    address indexed validator,
    address indexed systemConfig,
    uint256 initialDebt
);
```

### 10.4 SeigManager Sequencer Slashing Event

```solidity
event SequencerSlashed(address indexed layer2, address indexed gameAddress, uint256 slashedAmount, address challenger, uint256 challengerReward);
```

---

## 11. Related Documents

- [01-system-overview.md](./01-system-overview.md): System Overview
- [02-system-architecture.md](./02-system-architecture.md): System Architecture
- [03-contract-structure.md](./03-contract-structure.md): Contract Structure
- [04-contract-roles.md](./04-contract-roles.md): Contract Roles
- [05-actors.md](./05-actors.md): Actor Definitions
