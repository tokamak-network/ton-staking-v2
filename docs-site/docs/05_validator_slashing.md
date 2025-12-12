---
id: 05_validator_slashing
slug: /05_validator_slashing
---
# Validator Slashing

## 1. Overview

Validators are slashed if they fail to respond to RAT (Randomized Attention Test). This document covers validator slashing conditions, procedures, and implementation.

> **Note**: For detailed information on validator registration, rewards, and RAT system, refer to [04_validator.md](./04_validator.md).

### Whitepaper Stated Content

Whitepaper **Section 2.1.2. Economic Security for Validators** (PDF Page 10):

| Item | Whitepaper Content |
|------|-------------------|
| **Slashing Condition** | RAT non-response |
| **Slashing Amount** | "full collateral slashing" (entire collateral) |
| **After Slashing** | Immediate deposit replenishment required, removed from active validator set if not met |
| **Repeat Penalty** | None (unlike sequencer, no increasing penalty applied) |

**Whitepaper Original Text:**
> "Slashing for validators is applied solely in the context of RAT. In alignment with the sequencer's collateral model, the protocol adopts full collateral slashing. When an attention test is issued with probability π_a, the selected validator must respond within the required time window. Failure to do so triggers a slashing event in which the full deposit is forfeited."

### Implementation Approach: Pre-deduction-Recovery Mechanism

Adopts Optimism RAT.sol's **pre-deduction-recovery mechanism**, but the deduction amount is **entire collateral** as per the whitepaper.

| Item | Optimism RAT | TON V3 RAT |
|------|-------------|------------|
| **Deduction on Trigger** | perTestBondAmount | **Entire Collateral (depositedAmount)** |
| **On Evidence Submission** | bondAmount recovery | **Entire Collateral Recovery** |
| **On Non-response** | bondAmount loss | **Entire Collateral Forfeited to RAT Contract** |
| **Separate Slashing tx** | Unnecessary | **Completely Unnecessary** |

**Advantages:**
- Since collateral is already transferred to RAT contract on RAT trigger, **separate slashing transaction is completely unnecessary** on non-response
- Gas cost savings and process simplification
- Complies with whitepaper's "full collateral slashing" principle

---

## 2. Slashing Mechanism: Pre-transfer-Recovery Method

### 2.1 Core Principle

At RAT trigger time, **entire collateral is transferred to RAT contract**. Only recovered on successful evidence submission; on non-response, **no action needed** (already forfeited to RAT contract).

```
┌─────────────────────────────────────────────────────────────┐
│  1. RAT Trigger (triggerAttentionTest)                      │
│     - Internal record: depositedAmount = 0 (pre-deduction)   │
│     - attentionTest.bondAmount = entire collateral          │
│     - Validator deactivated (isActive = false)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Response Window (evidenceSubmissionPeriod)              │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │  Evidence Submission Success│             │  Non-response         │
    │  submitEvidence │             │  deadline passed│
    └─────────────────┘             └─────────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │  Collateral Recovery│             │  No Action     │
    │  RAT → Validator │             │  (Already forfeited)│
    │  isActive = true│             │  Forfeited to RAT│
    └─────────────────┘             └─────────────────┘
```

### 2.2 State Changes by Stage

| Stage | Validator Balance | RAT Contract | isActive |
|-------|------------------|-------------|----------|
| **After Registration** | D_validator | - | true |
| **RAT Trigger** | 0 | +D_validator (bondAmount) | false |
| **Evidence Submission Success** | D_validator (recovered) | -D_validator | true |
| **Non-response** | 0 | D_validator (forfeited) | false |

### 2.3 Advantages

1. **Completely unnecessary separate transaction on non-response**: Slashing complete since collateral already in RAT contract
2. **Significant gas cost savings**: `finalizeSlash()` function itself unnecessary
3. **Simple logic**: Only recovery processing on successful evidence submission

### 2.4 Utilization of Slashed Collateral

Collateral forfeited to RAT contract is used for protocol treasury:
- Redistributed to validator reward pool
- Used according to DAO governance decisions
- Or accumulated and stored in contract

> **Note**: The whitepaper only states "the full deposit is forfeited" (entire collateral forfeited) and does not specify the forfeiture destination.

---

## 3. Implementation: Pre-transfer-Recovery Method

### 3.1 On RAT Trigger (Transfer Entire Staking Amount to RAT Contract)

```solidity
/// @notice RAT test trigger - Transfer entire staking amount to RAT contract
function triggerAttentionTest(
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external onlyLayer2Manager {
    // ... Validator random selection logic ...

    address selectedValidator = validators[selectedIndex];
    bytes32 regId = _getRegistrationId(selectedValidator, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    // ★ Pre-deduct entire collateral (whitepaper: full collateral)
    // Actual staking in DepositManager remains in RAT name, only internal record changes
    uint256 bondAmount = reg.depositedAmount;  // Full amount
    reg.depositedAmount = 0;  // Deducted from internal record

    // Deactivate validator
    reg.isActive = false;
    validatorPools[systemConfig].activeValidatorCount--;
    _removeFromActiveValidators(systemConfig, selectedValidator, reg.validatorIndex);

    // Store test information
    bytes32 testId = _getTestId(systemConfig, batchIndex);
    attentionTests[testId] = AttentionTest({
        expectedHash: batchHash,
        bondAmount: uint96(bondAmount),  // Record amount for recovery
        validatorAddress: selectedValidator,
        systemConfig: systemConfig,
        blockNumber: uint64(block.number),
        evidenceSubmitted: false
    });

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit AttentionTriggered(testId, systemConfig, layer2, selectedValidator, batchIndex);
}
```

### 3.2 On Successful Evidence Submission (Collateral Recovery)

```solidity
/// @notice Evidence submission - Collateral recovery
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata proofData
) external {
    bytes32 testId = _getTestId(systemConfig, batchIndex);
    AttentionTest storage test = attentionTests[testId];

    // Validation
    if (test.validatorAddress != msg.sender) revert NotSelectedValidator();
    if (test.evidenceSubmitted) revert EvidenceAlreadySubmitted();

    uint256 deadline = test.blockNumber + evidenceSubmissionPeriod;
    if (block.number > deadline) revert EvidenceSubmissionExpired();

    // Evidence verification
    if (keccak256(proofData) != test.expectedHash) revert ProofVerificationFailed();

    // ★ Recover entire collateral
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];
    reg.depositedAmount = restoredAmount;  // Recover internal record

    // Reactivate validator
    reg.isActive = true;
    reg.validatorIndex = uint32(activeValidators[systemConfig].length);
    activeValidators[systemConfig].push(msg.sender);
    validatorPools[systemConfig].activeValidatorCount++;

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit EvidenceSubmitted(testId, systemConfig, layer2, msg.sender, restoredAmount);
}
```

### 3.3 On Non-response

**No separate function needed** - Since collateral is already transferred to RAT contract at RAT trigger time, slashing is automatically complete on non-response.

```
Non-response state:
- validator.depositedAmount = 0 (already deducted)
- validator.isActive = false (already deactivated)
- Collateral = Forfeited to RAT contract (protocol treasury)
- Additional transaction = None
```

### 3.4 Collateral Recovery on Challenge Victory (resolveClaim)

When a validator discovers the proposer's incorrect evidence and **wins as a challenger in FaultDisputeGame**, the game contract calls `resolveClaim` to recover the collateral.

```
┌─────────────────────────────────────────────────────────────┐
│  RAT Trigger → Validator Collateral Pre-deducted → Deactivated│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Validator Discovers Proposer's Incorrect Output Root        │
│  → Challenge in FaultDisputeGame (as challenger)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Game Resolution - Validator (Challenger) Wins               │
│  FaultDisputeGame.resolveClaim() → RAT.resolveClaim(winner) │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Collateral Recovery + Validator Reactivation                │
│  - depositedAmount recovered (internal record)             │
│  - isActive = true                                          │
└─────────────────────────────────────────────────────────────┘
```

```solidity
/// @notice Called when FaultDisputeGame resolves game (collateral recovery on challenger victory)
/// @param _claimant Address that won the game (challenger)
/// @dev msg.sender = FaultDisputeGame address
function resolveClaim(address _claimant) external {
    // Query test using msg.sender = game address
    bytes32 testId = gameToTestId[msg.sender];
    if (testId == bytes32(0)) return;  // No RAT test for this game

    AttentionTest storage test = attentionTests[testId];

    // Check if selected validator matches game winner
    if (test.validatorAddress != _claimant) return;
    if (test.evidenceSubmitted) return;  // Already processed

    // ★ Recover collateral
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(_claimant, test.systemConfig);
    ValidatorRegistration storage reg = registrations[regId];
    reg.depositedAmount = restoredAmount;  // Recover internal record

    // Reactivate validator
    reg.isActive = true;
    reg.validatorIndex = uint32(activeValidators[test.systemConfig].length);
    activeValidators[test.systemConfig].push(_claimant);
    validatorPools[test.systemConfig].activeValidatorCount++;

    address layer2 = _getLayer2FromSystemConfig(test.systemConfig);
    emit BondRefunded(testId, test.systemConfig, layer2, _claimant, restoredAmount);
}
```

**Key Points:**
- `msg.sender` is FaultDisputeGame address (game contract directly calls)
- `_claimant` is the challenger address that won the game
- Collateral recovery only if RAT-selected validator matches game winner
- Same effect as `submitEvidence`: Collateral recovery + validator reactivation

---

## 4. Slashing Example

### 4.1 Scenario

```
Validator A (Registered on Titan L2):
- depositedAmount = 10,000 WTON
- pendingRewards = 500 WTON
- RAT triggered (batchIndex = 12345)
- evidenceSubmissionPeriod = 7200 blocks (~24 hours)
```

### 4.2 RAT Trigger (Block 1000)

```
triggerAttentionTest(titanSystemConfig, 12345, ...) called

State changes:
- A.depositedAmount: 10,000 → 0 (deducted from internal record)
- attentionTest.bondAmount: 0 → 10,000 (stored in contract)
- A.isActive: true → false
- activeValidatorCount: n → n-1
```

### 4.3 On Successful Evidence Submission

```
submitEvidence(titanSystemConfig, 12345, proofData) called

State changes:
- A.depositedAmount: 0 → 10,000 (internal record recovered)
- A.isActive: false → true
- activeValidatorCount: n-1 → n
```

### 4.4 On Non-response

```
After response window (7200 blocks) passes:

State:
- A.depositedAmount: 0 (no change, already deducted)
- A.isActive: false (no change)
- Collateral 10,000 WTON: Forfeited to RAT contract
- Additional transaction: None
```

### 4.5 Result Comparison

| Scenario | Validator A | RAT Contract | Active Validator Count |
|----------|-------------|--------------|----------------------|
| **Evidence Submission Success** | Collateral 10,000 recovered, activated | No change | Maintained |
| **Non-response** | Collateral 10,000 lost, deactivated | +10,000 forfeited | -1 decreased |

---

## 5. Re-registration

### 5.1 Re-registration After Slashing

Slashed validators can register again:

```solidity
// State after slashing
validatorInfo[validator].isActive = false;
validatorInfo[validator].depositAmount = 0;

// On re-registration
function registerValidator(uint256 depositAmount) external {
    require(!validatorInfo[msg.sender].isActive, "already registered");
    // Re-registration possible since isActive is false
    ...
}
```

### 5.2 Re-registration Notes

- New collateral required (minimum collateral or more)
- Previous slashing records remain (for future reference)
- Unclaimed rewards are not recovered

---

## 6. Events

In the pre-deduction-recovery mechanism, slashing is tracked through RAT trigger and evidence submission events without a separate event.

```solidity
/// @notice RAT test trigger (staking amount pre-deducted)
event AttentionTriggered(
    bytes32 indexed testId,
    address indexed systemConfig,
    address indexed layer2,
    address validator,
    uint32 batchIndex
);

/// @notice Evidence submission success (staking amount recovered)
event EvidenceSubmitted(
    bytes32 indexed testId,
    address indexed systemConfig,
    address indexed layer2,
    address validator,
    uint256 restoredAmount
);
```

**Forfeited Funds Tracking:**
- If `AttentionTriggered` occurs but no `EvidenceSubmitted` → Permanently forfeited
- If `AttentionTriggered` occurs and `EvidenceSubmitted` exists → Recovered

---

## 7. Comparison with Sequencer Slashing

| Item | Sequencer Slashing | Validator Slashing |
|------|-------------------|-------------------|
| **Slashing Condition** | Fraud proof success | RAT non-response |
| **Slashing Amount** | Entire collateral | Entire collateral |
| **Slashing Method** | Post-processing (separate tx) | Pre-deduction-recovery (separate tx unnecessary) |
| **Challenger Reward** | C_max + Δ/n | None |
| **Forfeiture Destination** | DAO | RAT Contract |
| **Collateral Form** | Staking balance | Staking balance |
