---
id: upgrade-validator-guide
sidebar_position: 4
---

# Validator Perspective (New)

## V2 vs V3: Validator Role

### V2 (Current Mainnet Service)
Validator role: None

### V3 (Upgrade)
Validator role:
  - Participate in RAT (Randomized Attention Test)
  - Receive seigniorage (α · S_i / |V_i|)
  - Monitor L2 network
  - Submit DisputeGame evidence

## Validator Registration Process

```
1. Stake TON in DepositManager
   - Single staking serves both seigniorage receipt eligibility + RAT collateral
   - No separate collateral deposit needed
2. Call RAT.registerValidator(systemConfig)
3. Validator registration complete
```

**Collateral Query**:
- `RAT._getValidatorCollateral()`: Query validator balance in L2 Coinage through SeigManager
  - Returns `(collateral, layer2)` tuple to avoid duplicate queries

## Collateral System

### Purpose of Collateral

Validators have the responsibility to continuously monitor L2 networks and respond to RAT. Collateral is a safety mechanism to ensure this responsibility.

```
Collateral roles:
1. Ensure RAT test response → Slash part of collateral (C_off) if no response
2. Encourage continuous network monitoring → Provide economic incentives
3. Prevent malicious behavior → Deter through risk of collateral loss
```

### How Collateral Works

**V3 uses existing staking as collateral instead of separate deposit**. Key: Validator's L2 Coinage balance = Collateral (no separate deposit needed)

### Seigniorage Receipt Conditions and Collateral Check Criteria

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

### Operational Plan

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

## RAT Mechanism (New)

### Random Selection Algorithm

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

### RAT Process

```
On DisputeGame Creation
  │
  ├─ Trigger RAT with probability π_a (generate random value and check probability)
  │
  ├─ Random selection from that L2's validators
  │
  ├─ Pre-deduction: Transfer validator coinage → RAT coinage (C_off)
  │   ├─ Call SeigManager.transferCoinageToRat()
  │   └─ lockedForRAT += C_off
  │
  ├─ Evidence submission period: evidenceSubmissionPeriod (e.g., 1 hour)
  │
  ├─ ✅ On successful evidence submission (within Evidence Period)
  │   ├─ Call submitEvidence()
  │   ├─ Restore RAT coinage → validator coinage
  │   ├─ Call SeigManager.transferCoinageFromRat()
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

See [Technical Details](./05-technical-details.md) for detailed implementation.

## Validator Reward Calculation

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

See [Technical Details](./05-technical-details.md) for detailed calculation logic.
