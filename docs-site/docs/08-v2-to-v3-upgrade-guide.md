---
id: 08-v2-to-v3-upgrade-guide
sidebar_position: 8
---
# TON Staking Service V2 → V3 Upgrade Guide

> **This document summarizes what actually changes when upgrading from TON Staking (V2) currently running on mainnet to V3, for easy understanding at a glance.**

---

## 📋 Quick Table of Contents

- [1. V2 → V3 Core Changes at a Glance](#1-v2--v3-core-changes-at-a-glance)
- [2. General Staker Perspective](#2-general-staker-perspective)
- [3. Sequencer Perspective](#3-sequencer-perspective)
- [4. Validator Perspective (New)](#4-validator-perspective-new)
- [5. Technical Implementation Details](#5-technical-implementation-details)
- [6. Migration Checklist](#6-migration-checklist)
- [7. FAQ](#7-faq)

---

## 1. V2 → V3 Core Changes at a Glance

### 1.1 Current Service vs Upgrade Version

| Category | V2 (Current Mainnet Service) | V3 (Upgrade) |
|----------|------------------------------|--------------|
| **Contract Version** | SeigManagerV1_3 | SeigManagerV3_1 + RAT + ValidatorReward |
| **Seigniorage Recipients** | **DAO + Sequencer + General Stakers** | **DAO + Sequencer + Validators** |
| **Distribution Basis** | D/T ratio split between sequencer/stakers | Bridged TON based (performance-focused) |
| **Distribution Function** | Linear distribution | Hyperbolic saturation function `y(x) = L·(x/(k+x))` |
| **Validator Role** | None | RAT + seigniorage distribution |
| **DAO Allocation** | Fixed ratio (d·A) | Fixed ratio + undistributed portion |

### 1.2 Core Change: Seigniorage Distribution Target Change

**V3 Direction**: Focus seigniorage on participants who directly operate and verify L2 networks

```
V2 (Current Mainnet Service):
  Seigniorage A
    ├─► DAO: d · A (fixed)
    │
    └─► Remaining (1-d) · A distributed by D/T ratio
        ├─► (D/T) × (1-d) · A → L2 Sequencers
        └─► (1 - D/T) × (1-d) · A → General Stakers

V3 (Upgrade):
  Seigniorage A
    ├─► DAO: d · A (fixed) + undistributed portion
    └─► Performance-based distribution to L2 operators and validators:
        ├─► Sequencer (L2 operator): (1-α) · S_i
        └─► Validator (L2 validator): α · S_i / |V_i|
```

General stakers can also receive seigniorage by participating as validators.

---

## 2. General Staker Perspective

### 2.1 Seigniorage Distribution Target Change

```
V2 (Current): TON staking → Receive seigniorage according to staking ratio
V3 (Upgrade): TON staking → Receive seigniorage when participating in L2 operation/verification
```

**Why the change?**
- V3 focuses on **strengthening L2 network security**
- Concentrate seigniorage distribution to **actual network operation/verification participants**
- Incentive redesign for L2 ecosystem activation

### 2.2 What Doesn't Change

- Existing TON staking method **remains the same**
- Deposit/withdrawal process through DepositManager **identical**
- Staking itself continues to be possible

### 2.3 New Participation Methods

**Participate as Validator**: Contribute to L2 network security while receiving seigniorage ([See Section 4](#4-validator-perspective-new))
- Can register as validator while maintaining existing staking
- Can receive seigniorage without additional funds

### 2.4 DAO Governance

#### Existing Permissions Maintained
- Receive DAO fixed distribution ratio (d·A)

#### New Permissions
- **Execute V3 Migration** (`migrateToV3()`)
- **Control Validator Entry Policy**
  - Set `relaxedValidatorCheck` flag
  - `true`: Lower validator entry barrier (recommended initially)
  - `false`: Strengthen validator security standards (after growth)
- **V3 Parameter Settings**
  - `daoDistributionRatio` (d): DAO distribution ratio
  - `minStakingRatio` (θ): Minimum staking ratio relative to sequencer's Bridged TON (e.g., 10%)
  - `validatorDistributionRatio` (α): Validator distribution ratio
  - `halfSaturationPoint` (k): Hyperbolic function half saturation point

#### Additional Revenue
- Undistributed seigniorage automatically goes to DAO
  - Ineligible L2s excluded from y(x) calculation, handled as undistributed portion (L - y)

---

## 3. Sequencer Perspective

### 3.1 Seigniorage Distribution Basis Change

#### V2 (Current Mainnet Service)
```
Distribution basis: L2 TVL (Total Value Locked)
Distribution method: Linear proportional
```

#### V3 (Upgrade)
```
Distribution basis: Bridged TON (Amount of TON bridged to L2)
Distribution method: Hyperbolic saturation function y(x) = L·(x/(k+x))
  - Performance-based distribution
  - Diminishing returns effect (prevents monopolization)
  - Eligibility conditions required
```

### 3.2 New Eligibility Conditions

#### V3 (Upgrade)
```solidity
Condition: T_i ≥ max(D_sequencer, θ · B_i)

Where:
- T_i: Sequencer's staking amount
- D_sequencer = H_max · C_max + Δ_sequencer
  - H_max: Maximum simultaneous challengers
  - C_max: Maximum cost per Fraud Proof
  - Δ_sequencer: Sequencer additional reward
- θ · B_i: 10% of Bridged TON (example)

⚠️ If condition not met: B̃_i = 0, that L2 does not receive seigniorage and is handled as undistributed portion
```

### 3.3 Collateral System

**V3 Implementation**: Single staking serves both seigniorage receipt eligibility + slashing collateral (no separate collateral deposit needed)

**Collateral Query**:
- `SeigManager.getSequencerStaked(layer2)`: Query sequencer balance in L2 Coinage

### 3.4 Slashing Policy Change

| Item | V2 (Current) | V3 (Upgrade) |
|------|-------------|--------------|
| **Slashing Target** | - | Full staking amount (`coinage.burnFrom()`) |
| **Seigniorage** | TVL proportional distribution | Cannot receive (eligibility lost) |
| **L2 Operation** | - | **Not stopped** |

In V3, when slashing occurs, the L2 is not physically stopped, only economic sanctions (seigniorage suspension + collateral confiscation) are applied.

### 3.5 Sequencer Reward Calculation Method

```
Sequencer reward = (1-α) · S_i

Where:
- S_i = That L2's seigniorage = y(x) · (B̃_i / x)
- α = Validator distribution ratio (e.g., 20%)
- (1-α) = Sequencer share (e.g., 80%)
```

See [Section 5.2](#52-seigniorage-distribution-logic-change) for detailed calculation logic

---

## 4. Validator Perspective (New)

### 4.1 V2 vs V3: Validator Role

#### V2 (Current Mainnet Service)
Validator role: None

#### V3 (Upgrade)
Validator role:
  - Participate in RAT (Randomized Attention Test)
  - Receive seigniorage (α · S_i / |V_i|)
  - Monitor L2 network
  - Submit DisputeGame evidence

### 4.2 Validator Registration Process

```
1. Stake TON in DepositManager
   - Single staking serves both seigniorage receipt eligibility + RAT collateral
   - No separate collateral deposit needed
2. Call RAT.registerValidator(systemConfig)
3. Validator registration complete
```

**Collateral Query**:
- `RAT._getValidatorCollateral()`: Query validator balance in L2 Coinage through SeigManager

### 4.3 Collateral System

#### 4.3.1 Purpose of Collateral

Validators have the responsibility to continuously monitor L2 networks and respond to RAT. Collateral is a safety mechanism to ensure this responsibility.

```
Collateral roles:
1. Ensure RAT test response → Slash part of collateral (C_off) if no response
2. Encourage continuous network monitoring → Provide economic incentives
3. Prevent malicious behavior → Deter through risk of collateral loss
```

#### 4.3.2 How Collateral Works

**V3 uses existing staking as collateral instead of separate deposit**. Key: Validator's L2 Coinage balance = Collateral (no separate deposit needed)

#### 4.3.3 Seigniorage Receipt Conditions and Collateral Check Criteria

**Condition 1: Affiliated L2's Seigniorage Eligibility**
```solidity
T_i ≥ max(D_sequencer, θ · B_i)
- Sequencer must meet this for L2 to receive seigniorage
- Validators share this seigniorage
```

**Condition 2: Validator Personal Collateral - 3 Check Criteria**

> **Important**: The `relaxedValidatorCheck` flag applies at different times and doesn't apply at others.

```solidity
1️⃣ At Validator Registration
   - Always need D_validator or more (regardless of relaxedValidatorCheck)
   - Minimum requirement: D_validator = C_off + Δ_validator

2️⃣ Staking Withdrawal Restriction
   - Always need to maintain D_validator or more (regardless of relaxedValidatorCheck)
   - Cannot withdraw collateral below D_validator while registered as validator
   - Can freely withdraw only after validator deactivation

3️⃣ Collateral Verification During RAT Test
   - Varies based on relaxedValidatorCheck (operational policy)

   // Early operation (relaxedValidatorCheck = true)
   Minimum collateral = C_off  (low entry barrier)
   - Valid if only C_off available during RAT test
   - Example: Can receive seigniorage with only 100 WTON

   // After growth (relaxedValidatorCheck = false)
   Minimum collateral = D_validator  (strict criteria)
   - Need D_validator during RAT test
   - Example: Need 1,000 WTON (security strengthened)

Where:
- C_off: Slashing penalty (e.g., 100 WTON)
- D_validator: C_off + Δ_validator (e.g., 1,000 WTON)
- Δ_validator: Additional safety buffer (e.g., 900 WTON)
```

**Summary:**
| Scenario | relaxedValidatorCheck | Minimum Collateral Requirement |
|----------|----------------------|-------------------------------|
| At validator registration | N/A (always checked) | D_validator |
| Staking withdrawal restriction | N/A (always checked) | D_validator |
| Verification during RAT test | Applied | C_off (true) / D_validator (false) |

#### 4.3.4 Operational Plan

| Stage | `relaxedValidatorCheck` | Validator Minimum Collateral | Purpose |
|-------|------------------------|------------------------------|---------|
| Stage 1 (Early) | `true` | C_off | Attract validators (low entry barrier) |
| Stage 2 (Growth) | `false` | D_validator | Strengthen security (high safety) |

**Example:**
- C_off = 100 WTON
- Δ_validator = 900 WTON
- D_validator = 1,000 WTON

Early: Can maintain validator with only 100 WTON
After growth: Need 1,000 WTON (DAO governance decision)

### 4.4 RAT Mechanism (New)

#### 4.4.1 Random Selection Algorithm

**Probabilistic Trigger:**
```solidity
// 1. Generate random value (L1 blockHash + timestamp combination)
uint256 randomValue = uint256(
    keccak256(abi.encodePacked(blockHash, block.timestamp))
) % RAY;

// 2. Trigger probability check
if (randomValue >= ratTriggerProbability) return;  // Only trigger with π_a probability
```

**Random Validator Selection:**
```solidity
// 1. Generate random index (use blockHash as seed)
uint256 randomIndex = uint256(
    keccak256(abi.encodePacked(blockHash, block.timestamp))
) % validatorCount;

// 2. O(1) access from active validator array
address selectedValidator = pool.validators[randomIndex];
```

**Random Source:**
- `blockHash`: L1 previous block hash passed by DisputeGameFactory (`blockhash(block.number - 1)`)
  - Value guaranteed by L1 consensus
  - Cannot be manipulated by L2 sequencer
  - Sufficiently unpredictable entropy
- `block.timestamp`: L1 timestamp (additional entropy)

**Security Considerations:**
- L2 sequencer cannot manipulate by using L1 block hash
- Unique random value at each DisputeGame creation time

#### 4.4.2 RAT Process

```
On DisputeGame Creation
  │
  ├─ Trigger RAT with probability π_a (generate random value and check probability)
  │
  ├─ Random selection from that L2's validators
  │
  ├─ Pre-deduction: Transfer validator coinage → RAT coinage (C_off)
  │   ├─ Call SeigManager.transferCoinageToRAT()
  │   └─ lockedForRAT += C_off
  │
  ├─ Evidence submission period: evidenceSubmissionPeriod (e.g., 1 hour)
  │
  ├─ ✅ On successful evidence submission (within Evidence Period)
  │   ├─ Call submitEvidence()
  │   ├─ Restore RAT coinage → validator coinage
  │   ├─ Call SeigManager.transferCoinageFromRAT()
  │   └─ lockedForRAT -= C_off
  │
  ├─ ⏳ When evidence submission period expires (Challenge Period)
  │   ├─ Challenge game period: challengeGameDuration
  │   ├─ Can restore on challenge game win (resolveClaim())
  │   └─ Restore RAT coinage → validator coinage
  │
  └─ ❌ When challenge period ends
      ├─ C_off permanently confiscated
      ├─ RAT holds coinage
      ├─ lockedForRAT -= C_off
      └─ Can transfer to Treasury via withdrawSlashingsToTreasury()
```

See [Section 5.4](#54-rat-coinage-transfer-implementation-new) for detailed implementation

### 4.5 Validator Reward Calculation

```
Individual validator reward = (α · S_i) / |V_i|

Where:
- S_i = That L2's seigniorage
- α = Validator distribution ratio (e.g., 20%)
- |V_i| = Number of validators for that L2

Example:
- L2 seigniorage S_i = 100 TON
- Validator distribution ratio α = 20%
- Validator pool = 20 TON
- Number of validators |V_i| = 4
- Per validator = 5 TON

💡 If no validators: DAO receives full α · S_i
```

See [Section 5.2](#52-seigniorage-distribution-logic-change) for detailed calculation logic

---

## 5. Technical Implementation Details

### 5.1 Contract Version Comparison

| Contract | V2 (Current Mainnet) | V3 (Upgrade) | Status |
|----------|---------------------|--------------|--------|
| **SeigManager** | V1_3 (0xce18...F628) | V1_4 (not deployed) | ✅ Complete |
| **DepositManager** | V1_1 | V1_2 | ✅ Complete |
| **Layer2Manager** | V1_1 | V1_2 | ✅ Complete |
| **L1BridgeRegistry** | V1_1 | V1_2 (single implementation) | ✅ Complete |
| **RAT** | None | New deployment | ✅ Complete |
| **ValidatorReward** | None | New deployment | ✅ Complete |

### 5.2 Seigniorage Distribution Logic Change

#### V2 Implementation (SeigManagerV1_3, Current Mainnet)
```solidity
// Distribute to DAO + Sequencer + General Stakers
function updateSeigniorage() {
    // 1. Calculate total seigniorage
    uint256 A = (block.number - lastSeigBlock) * seigPerBlock;

    // 2. DAO fixed distribution
    uint256 daoAmount = A * daoCommissionRate / RAY;  // d · A

    // 3. Calculate remainder
    uint256 remaining = A - daoAmount;  // (1-d) · A

    // 4. Distribute to sequencer and stakers by D/T ratio
    // - (D/T) × remaining → L2 Sequencers (proportional to L2 TVL)
    // - (1 - D/T) × remaining → General Stakers (proportional to staking)

    for (each L2) {
        uint256 l2Share = remaining * l2TVL / totalTVL;
        distributeToStakersInL2(layer2, l2Share);
        // Sequencer and stakers share proportionally by staking ratio
    }
}
```

#### V3 Implementation (SeigManagerV3_1, Upgrade)
```solidity
// Hyperbolic distribution to Sequencer + Validators based on Bridged TON
function updateSeigniorage() {
    // Check v3Migrated flag
    if (!v3Migrated) {
        // Use V2 logic (existing V1_3 logic)
        return _updateSeigniorageV2();
    }

    // 1. Calculate total seigniorage
    uint256 A = (block.number - lastSeigBlock) * seigPerBlock;

    // 2. DAO fixed distribution
    uint256 daoFixed = A * daoDistributionRatio / RAY;

    // 3. L2 distribution pool
    uint256 L = A - daoFixed;

    // 4. Check eligibility and sum effective Bridged TON
    uint256 x = 0;  // Σ B̃_i
    for (each L2) {
        uint256 B_i = l1BridgeRegistry.getBridgedTON(layer2);
        uint256 T_i = getSequencerStaked(layer2);
        uint256 D_seq = calculateDSequencer();
        uint256 minRequired = max(D_seq, minStakingRatio * B_i / RAY);

        if (T_i >= minRequired) {
            x += B_i;  // Include only if eligible
        }
    }

    // 5. Hyperbolic saturation function: y(x) = L · (x / (k + x))
    uint256 k = halfSaturationPoint;
    uint256 y = L * x / (k + x);

    // 6. Distribution per L2
    for (each eligible L2) {
        // S_i = y(x) · (B̃_i / x)
        uint256 S_i = y * B_i / x;

        // Sequencer reward: (1-α) · S_i
        uint256 sequencerReward = S_i * (RAY - validatorDistributionRatio) / RAY;
        coinageOfL2.mint(operator, sequencerReward);

        // Validator reward: α · S_i
        uint256 validatorReward = S_i * validatorDistributionRatio / RAY;
        validatorRewardContract.distribute(layer2, validatorReward);
    }

    // 7. Undistributed portion goes to DAO
    uint256 unallocated = L - y;
    daoTreasury += daoFixed + unallocated;
}
```

### 5.3 Collateral Query Method (V3 New)

#### Sequencer Collateral

```solidity
// SeigManagerV3_1.sol
function getSequencerStaked(address layer2) public view returns (uint256) {
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    if (address(coinage) == address(0)) return 0;

    address operator = Layer2I(layer2).operator();
    if (operator == address(0)) return 0;

    return coinage.balanceOf(operator);  // Direct query from Coinage
}
```

#### Validator Collateral

```solidity
// RAT.sol
function _getValidatorCollateral(address validator, address systemConfig)
    internal view returns (uint256)
{
    address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    if (layer2 == address(0)) return 0;

    // Query coinage through SeigManager
    return ISeigManagerForRAT(seigManager).stakeOf(layer2, validator);
}
```

### 5.4 RAT Coinage Transfer Implementation (New)

**SeigManagerV3_1.sol** - RAT Integration Functions
```solidity
// Transfer coinage from validator → RAT (slashing pre-deduction)
function transferCoinageToRAT(address layer2, address validator, uint256 amount)
    external onlyRAT
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    coinage.burnFrom(validator, amount);  // Burn from validator
    coinage.mint(ratContract, amount);     // Mint to RAT

    emit CoinageTransferredToRAT(layer2, validator, amount);
}

// Transfer coinage from RAT → validator (restoration)
function transferCoinageFromRAT(address layer2, address validator, uint256 amount)
    external onlyRAT
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    coinage.burnFrom(ratContract, amount);  // Burn from RAT
    coinage.mint(validator, amount);        // Mint to validator

    emit CoinageTransferredFromRAT(layer2, validator, amount);
}
```

> **⚠️ Important**: RAT does not have permission to directly manipulate coinage, so it must go through SeigManager.

**RAT.sol** - SeigManager Calls
```solidity
function _transferCoinageToRAT(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    ISeigManagerForRAT(seigManager).transferCoinageToRAT(layer2, validator, amount);
    lockedForRAT[testId] = amount;
}

function _transferCoinageFromRAT(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    ISeigManagerForRAT(seigManager).transferCoinageFromRAT(layer2, validator, amount);
    lockedForRAT[testId] = 0;
}
```

---

## 6. Migration Checklist

### 6.1 User Response

#### General Stakers
- [ ] Announce V3 seigniorage distribution target change (announcement required)
- [ ] Guide validator participation methods and benefits
- [ ] Create and distribute FAQ

#### Sequencers
- [ ] Guide new eligibility conditions
- [ ] Guide Bridged TON-based distribution
- [ ] Guide capital efficiency improvement from collateral integration
- [ ] Guide seigniorage calculation method change
- [ ] Guide slashing policy change

#### Validators (New)
- [ ] Guide validator registration procedures
- [ ] Explain RAT mechanism
- [ ] Guide reward calculation method
- [ ] Guide `relaxedValidatorCheck` policy
- [ ] Create validator guide document

### 6.2 Pre-Deployment Preparation

#### Contract Deployment
- [ ] Deploy SeigManagerV3_1
- [ ] Deploy SeigManagerV3_2 (V2 compatibility layer)
- [ ] Deploy RAT
- [ ] Deploy ValidatorRewardV1
- [ ] Deploy DepositManagerV3
- [ ] Deploy Layer2ManagerV3
- [ ] Deploy L1BridgeRegistryV1_2

#### Selector Routing Setup (SeigManagerProxy)
- [ ] Register SeigManagerV3_1 selectors
  - [ ] `setValidatorReward(address)`
  - [ ] `setDaoDistributionRatio(uint256)`
  - [ ] `setMinStakingRatio(uint256)`
  - [ ] `setValidatorDistributionRatio(uint256)`
  - [ ] `setHalfSaturationPoint(uint256)`
  - [ ] `migrateToV3()`
  - [ ] `onBridgedTonChange()`
  - [ ] `updateSeigniorage()` (override)
  - [ ] `updateSeigniorageLayer(address)` (override)

#### Address and Permission Setup
- [ ] Set RAT address in SeigManager (`setRATContract`)
- [ ] Set ValidatorReward address in SeigManager (`setValidatorReward`)
- [ ] Set Layer2Manager address in SeigManager
- [ ] Set L1BridgeRegistry address in SeigManager
- [ ] Set RAT permissions (verify `onlyRAT` modifier works)
- [ ] Set ValidatorReward permissions

#### Parameter Setup
- [ ] Set `daoDistributionRatio` (d) (e.g., 0.2e27 = 20%)
- [ ] Set `minStakingRatio` (θ) (e.g., 0.1e27 = 10%)
- [ ] Set `validatorDistributionRatio` (α) (e.g., 0.2e27 = 20%)
- [ ] Set `halfSaturationPoint` (k) (e.g., 10,000,000e27 TON)
- [ ] Set `relaxedValidatorCheck = true` (initial value)
- [ ] Set RAT parameters
  - [ ] `ratTriggerProbability` (π_a)
  - [ ] `slashingPenalty` (C_off)
  - [ ] `minimumThreshold` (D_min)
  - [ ] `evidenceSubmissionPeriod`

#### V3 Migration Execution
- [ ] Call `migrateToV3()` (DAO governance)
- [ ] Verify `v3Migrated = true`

### 6.3 Post-Deployment Verification

#### Function Verification
- [ ] Verify sequencer staking query works normally
- [ ] Verify validator collateral query works normally
- [ ] Verify RAT coinage transfer works normally
- [ ] Verify seigniorage eligibility check works normally
- [ ] Verify `relaxedValidatorCheck` flag works
- [ ] **Verify seigniorage distribution target change** (distribute only to L2 operators/validators)
- [ ] Verify sequencer seigniorage receipt
- [ ] Verify validator seigniorage distribution
- [ ] Verify undistributed portion (L - y) goes to DAO

#### Security Verification
- [ ] Verify RAT permission check works (`onlyRAT`)
- [ ] Verify Coinage burn/mint permissions
- [ ] Test slashing logic (testnet)
- [ ] Verify DAO governance permissions
- [ ] Verify V3 migration permissions
- [ ] Verify selector routing works normally

#### Scenario Testing
- [ ] V2 → V3 transition scenario
- [ ] Validator registration scenario
- [ ] RAT trigger and response scenario
- [ ] RAT timeout scenario
- [ ] Sequencer slashing scenario
- [ ] Ineligible L2 scenario
- [ ] L2 with no validators scenario

### 6.4 Operational Plan

#### Stage 1: Early Operation (Validator Attraction)
- `relaxedValidatorCheck = true` (relaxed criteria)
- Minimum collateral: C_off (low entry barrier)
- Monitoring: Validator count, network security metrics, RAT response rate

#### Stage 2: Growth Period (Security Strengthening)
- Transition to `relaxedValidatorCheck = false` via DAO governance
- Minimum collateral: D_validator = C_off + Δ_validator

---

## 7. FAQ

### Q1. What is the role of general stakers in V3?
**A**: In V3, seigniorage is distributed to participants who directly operate or verify L2 networks. General stakers can receive seigniorage by registering as validators and participating in L2 network verification. They can register as validators while maintaining existing staking, allowing seigniorage receipt without additional funds.

### Q2. Can existing stakers convert to validators?
**A**: Yes. By calling `RAT.registerValidator()` while maintaining existing staking, they can register as validators and receive seigniorage.

### Q3. What additional tasks do sequencers need to do after V3 upgrade?
**A**: Since collateral is integrated with existing staking, no separate work is needed - just maintain existing staking. However, eligibility conditions (`T_i ≥ max(D_seq, θ·B_i)`) must be met to receive seigniorage.

### Q4. Is there a security problem if L2 is not stopped on slashing?
**A**: Economic sanctions (seigniorage suspension + collateral confiscation) provide sufficient deterrent. Rather, user service continuity is guaranteed, making it more stable.

### Q5. Who changes `relaxedValidatorCheck` and when?
**A**: It can be changed through DAO governance. When sufficient validators are secured, it can be switched to `false` for security strengthening.

### Q6. When does V2 → V3 transition occur?
**A**: When DAO governance calls `migrateToV3()`, it immediately switches to V3 mode. All subsequent seigniorage distributions follow V3 logic.

### Q7. Can we revert to V2 after V3 transition?
**A**: No. After `migrateToV3()` execution, rollback to V2 is not possible. The contract has no function to change `v3Migrated = false`, and this is intentional design.

---

## Appendix: Major Changes Summary

### Network Value
1. **L2 Security Strengthening**: Clear economic incentives for sequencers, continuous monitoring through validator network, guaranteed validator participation through RAT
2. **Performance-Based Rewards**: Reflect actual contribution based on Bridged TON, prevent monopolization with hyperbolic function, create fair competitive environment
3. **Service Stability Improvement**: Guarantee L2 service continuity even on slashing, improve user experience

### Economic Value
1. **Capital Efficiency Improvement**: No duplicate deposits needed with collateral and staking integration, lower entry barriers for sequencers/validators
2. **Flexible Policy Operation**: Gradual security strengthening with `relaxedValidatorCheck`, parameter adjustment through DAO governance

### Technical Value
1. **Structure Simplification**: Reduced contract complexity, reduced management points by removing RAT direct deposits, integrated design based on Coinage
2. **Governance Strengthening**: DAO-centric decision-making structure, transparent parameter management, support for gradual upgrades
3. **Scalability Improvement**: Preparation for Multi-Sequencer support, easy future feature addition, modularized architecture

### Precautions
1. **Seigniorage Distribution Target Change**: Clear communication essential, secure sufficient advance notice period, need to guide validator participation methods and benefits
2. **Validator Network Building**: Need initial validator attraction strategy, establish `relaxedValidatorCheck` operational policy, build RAT response rate monitoring system
3. **Sequencer Eligibility Management**: Monitor Bridged TON-based eligibility conditions, establish response plan for ineligible L2s, provide seigniorage prediction tools
