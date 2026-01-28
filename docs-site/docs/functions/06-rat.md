---
id: functions-rat
sidebar_position: 6
---

# RAT Functions

Randomized Attention Test (RAT) functions for validator registration and testing.

## registerValidator

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

## triggerAttentionTest

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

## submitEvidence

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

## resolveClaim

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

## deactivateValidator

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

## Query Functions

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

## D_min Calculation Formula

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

## relaxedValidatorCheck Flag

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
