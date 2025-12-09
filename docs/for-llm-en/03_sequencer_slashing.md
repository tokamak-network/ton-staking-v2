# Sequencer Slashing

## 1. Overview

This is a slashing system to deter sequencer fraud in Tokamak Network V3. It adopts a Multi-Challenger Fraud Proof approach to reward all valid challengers.

---

## 2. Multi-Challenger Fraud Proof

According to the whitepaper, in a single-winner challenge system, malicious L1 proposers/builders can manipulate transaction ordering to exclude honest challengers. Tokamak Network adopts a **multi-winner approach** where all valid fraud proofs submitted within the dispute period are recognized and rewarded.

---

## 3. Sequencer Collateral

### 3.1 Collateral Formula

Sequencer collateral according to whitepaper formula (1):

```
D_sequencer = H_max · C_max + Δ_sequencer
```

| Parameter | Description | Scope |
|-----------|-------------|-------|
| **H_max** | Maximum simultaneous challengers | Protocol level (same for all) |
| **C_max** | Maximum on-chain cost for single fraud proof execution | Protocol level (same for all) |
| **Δ_sequencer** | Additional reward provided by sequencer | Configurable per sequencer |

V3 uses the **larger value** between the whitepaper formula and the existing V2 minimum collateral as the minimum collateral.

```solidity
/// @notice Whitepaper formula (1): D_sequencer = H_max · C_max + Δ_sequencer
function calculateSequencerDepositByFormula(uint256 additionalReward)
    public view
    returns (uint256)
{
    return (maxChallengers * maxFraudProofCost) + additionalReward;
}

/// @notice V3 minimum collateral calculation
/// @dev max(whitepaper formula, V2 minimum collateral)
/// @param additionalReward Δ_sequencer: Additional reward set by sequencer
function getMinimumSequencerDeposit(uint256 additionalReward)
    public view
    returns (uint256)
{
    uint256 formulaDeposit = calculateSequencerDepositByFormula(additionalReward);

    // Use larger value between V2 minimum collateral and whitepaper formula
    return formulaDeposit > minimumInitialDepositAmount
        ? formulaDeposit
        : minimumInitialDepositAmount;
}
```

### 3.2 Collateral = L2 Staking Amount

The sequencer's collateral is **not stored separately**; it is queried from the staking amount (S_i) on that L2. This reuses the existing V2 structure.

```solidity
/// @notice Query sequencer collateral (= staking amount on that L2)
/// @dev Queried via SeigManager.stakedOf()
/// @param layer2 L2 address (candidate)
function getSequencerDeposit(address layer2) public view returns (uint256) {
    // Query staking balance of sequencer (operator) for that L2
    address sequencer = ILayer2Manager(layer2Manager).getOperator(layer2);
    return ISeigManager(seigManager).stakedOf(layer2, sequencer);
}
```

### 3.3 Storage

```solidity
// ============================================
// Protocol-level parameters (same for all)
// ============================================

/// @notice H_max: Maximum simultaneous challengers
/// @dev Defined by protocol, changeable by governance
uint256 public maxChallengers;

/// @notice C_max: Maximum on-chain cost for single fraud proof execution
/// @dev Defined by protocol, changeable by governance
uint256 public maxFraudProofCost;

/// @notice V2 minimum collateral (existing, for backward compatibility)
uint256 public minimumInitialDepositAmount;  // e.g., 1000.1 TON

// ============================================
// Per-sequencer parameters
// ============================================

/// @notice Per-sequencer additional reward (Δ_sequencer)
/// @dev Set individually by sequencer, default 0
mapping(address => uint256) public sequencerAdditionalReward;

// NOTE: Sequencer collateral is not stored separately
// → Queried via SeigManager.stakedOf(layer2, sequencer)
```

---

## 4. Slashing Mechanism

### 4.1 Slashing Condition

When fraud proof succeeds, the sequencer's **entire collateral (D_sequencer) is slashed**.

### 4.2 Slashing Flow

```
Sequencer Collateral (D_sequencer) Fully Slashed
            │
            ▼
    ┌───────────────────────┐
    │  Distribute to Challengers│
    │  R = C_max + (Δ/n)    │
    │  × n challengers      │
    └───────────────────────┘
            │
            ▼
    ┌───────────────────────┐
    │  Remainder → DAO Treasury│
    └───────────────────────┘
            │
            ▼
    ┌───────────────────────┐
    │  L2 Eligibility Re-evaluation│
    │  onStakingChange()    │
    └───────────────────────┘
```

### 4.3 Challenger Reward Formula

Challenger reward according to whitepaper formula (2):

```
R_challenger = C_max + (Δ_sequencer / n)
```

| Parameter | Description |
|-----------|-------------|
| **C_max** | Fraud proof cost reimbursement (minimum guarantee) |
| **Δ_sequencer** | Additional reward set by sequencer |
| **n** | Number of successful challengers |

### 4.4 Slashing Example

- `D_sequencer = 100 WTON` (H_max=5, C_max=10, Δ_sequencer=50)
- 3 challengers succeed with fraud proof
- Per challenger reward: `R = 10 + (50/3) = 26.67 WTON`
- Total challenger rewards: `26.67 × 3 = 80 WTON`
- Transferred to DAO: `100 - 80 = 20 WTON`

Challengers are guaranteed at least `C_max` (fraud proof cost) and additionally gain `Δ_sequencer/n` profit.

**Important**: Since slashed amounts are staked WTON, they cannot be transferred immediately without a withdrawal waiting period. Therefore, they are **transferred to challengers' staking balances** (coinage balance change). Challengers must go through the normal withdrawal process to receive actual WTON.

### 4.5 Slashing and L2 Eligibility

When slashing occurs, the sequencer's collateral becomes 0, so the L2's staking condition `S_i ≥ θ · B_i` is no longer met. Therefore, after slashing, `onStakingChange()` must be called to re-evaluate L2 eligibility.

- Before slashing: `S_i = 100 WTON`, `B_i = 500 TON`, `θ = 0.1` → `100 ≥ 50` ✅ Eligible
- After slashing: `S_i = 0 WTON` → `0 ≥ 50` ❌ Ineligible → Excluded from seigniorage distribution

---

## 5. Slashing Implementation

```solidity
/// @notice Sequencer slashing (when fraud proof succeeds)
/// @dev Whitepaper: "the entire bond (D_sequencer) is slashed"
/// @param layer2 L2 address to slash
/// @param challengers List of successful challengers
function slashSequencer(address layer2, address[] calldata challengers)
    external
    onlyDisputeContract
{
    uint256 n = challengers.length;
    require(n > 0 && n <= maxChallengers, "invalid challenger count");

    // Query sequencer (operator) address
    address sequencer = ILayer2Manager(layer2Manager).getOperator(layer2);

    // Collateral = Sequencer's staking amount on that L2
    uint256 deposit = ISeigManager(seigManager).stakedOf(layer2, sequencer);
    require(deposit > 0, "no deposit to slash");

    uint256 additionalReward = sequencerAdditionalReward[layer2];

    // Calculate challenger reward: R_challenger = C_max + (Δ_sequencer / n)
    uint256 perChallengerReward = maxFraudProofCost + (additionalReward / n);

    // Transfer to each challenger's staking balance (coinage balance change)
    // Cannot transfer immediately without withdrawal waiting period, so maintain staking status
    for (uint256 i = 0; i < n; i++) {
        ISeigManager(seigManager).transferStake(
            layer2,
            sequencer,           // from: sequencer
            challengers[i],      // to: challenger
            perChallengerReward
        );
    }

    // Transfer remainder to DAO's staking balance
    uint256 totalChallengerRewards = perChallengerReward * n;
    uint256 remainder = deposit - totalChallengerRewards;
    if (remainder > 0) {
        ISeigManager(seigManager).transferStake(
            layer2,
            sequencer,  // from: sequencer
            dao,        // to: DAO
            remainder
        );
    }

    // Re-evaluate L2 eligibility (S_i = 0, so S_i ≥ θ·B_i not met)
    // → This L2 is excluded from seigniorage distribution
    ISeigManager(seigManager).onStakingChange(layer2);

    // Store slashing record (for repeat violation penalty)
    sequencerSlashTimestamps[layer2].push(block.timestamp);

    emit SequencerSlashed(layer2, sequencer, deposit, n);
}
```

### 5.1 SeigManager.transferStake Function (New)

Function to transfer staking balance during slashing:

```solidity
/// @notice Transfer staking balance (slashing contract only)
/// @dev Transfer coinage balance from to, maintain staking status without withdrawal
/// @param layer2 L2 address
/// @param from Source account (slashing target)
/// @param to Destination account (challenger or DAO)
/// @param amount Transfer amount
function transferStake(
    address layer2,
    address from,
    address to,
    uint256 amount
) external onlySlashingContract {
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    require(coinage.balanceOf(from) >= amount, "insufficient balance");

    // Decrease from's balance, increase to's balance
    coinage.burn(from, amount);
    coinage.mint(to, amount);

    emit StakeTransferred(layer2, from, to, amount);
}
```

---

## 6. Repeat Violation Penalty

### 6.1 Penalty Formula

According to whitepaper formula (3), if a sequencer commits fraud multiple times within a **slashing window**, the required collateral increases:

```
D_sequencer^(n) = γ^(n-1) · D_sequencer^(1)
```

| Parameter | Description |
|-----------|-------------|
| **γ** | Penalty factor (γ > 1, determined by governance) |
| **n** | Number of violations within slashing window |
| **D^(1)** | Base collateral |

**Slashing Window Operation:**
- Slashing window starts **from when slashing occurs**
- If additional slashing occurs within the window, violation count (n) increases and required collateral increases by γ times
- When the window ends (after a certain period passes since last slashing), violation count resets
- Specific window period is determined by governance

### 6.2 Penalty Storage

```solidity
/// @notice Penalty factor (γ > 1)
/// @dev Determined by governance
uint256 public penaltyFactor;

/// @notice Slashing window (penalty increases for repeat violations within this period)
/// @dev Specific period determined by governance
uint256 public slashingWindow;

/// @notice Per-L2 slashing records (layer2 => timestamps)
mapping(address => uint256[]) public sequencerSlashTimestamps;
```

### 6.3 Penalty Calculation Implementation

```solidity
/// @notice Query recent violation count
/// @param layer2 L2 address
function getRecentViolationCount(address layer2)
    public view
    returns (uint256 count)
{
    uint256[] storage timestamps = sequencerSlashTimestamps[layer2];
    uint256 windowStart = block.timestamp - slashingWindow;

    for (uint256 i = timestamps.length; i > 0; i--) {
        if (timestamps[i - 1] >= windowStart) {
            count++;
        } else {
            break;  // No need to check further since sorted chronologically
        }
    }
}

/// @notice Calculate required collateral with repeat violation penalty
/// @dev Whitepaper formula (3): D^(n) = γ^(n-1) · D^(1)
/// @param layer2 L2 address
/// @param baseDeposit Base collateral
function getRequiredDepositWithPenalty(address layer2, uint256 baseDeposit)
    public view
    returns (uint256)
{
    uint256 violations = getRecentViolationCount(layer2);
    if (violations == 0) return baseDeposit;

    // γ^(n-1) · D^(1)
    uint256 multiplier = RAY;
    for (uint256 i = 0; i < violations; i++) {
        multiplier = FullMath.rmul(multiplier, penaltyFactor);
    }
    return FullMath.rmul(baseDeposit, multiplier);
}
```

### 6.4 Penalty Example

When γ = 1.5, base collateral = 100 WTON:

| Violations | Required Collateral | Calculation |
|------------|-------------------|-------------|
| 1st | 100 WTON | 1.5^0 × 100 |
| 2nd | 150 WTON | 1.5^1 × 100 |
| 3rd | 225 WTON | 1.5^2 × 100 |
| 4th | 337.5 WTON | 1.5^3 × 100 |

---

## 7. Events

```solidity
/// @notice Sequencer slashing event
event SequencerSlashed(
    address indexed layer2,
    address indexed sequencer,
    uint256 slashedAmount,
    uint256 challengerCount
);

/// @notice Challenger reward payment event
event ChallengerRewarded(
    address indexed challenger,
    address indexed layer2,
    uint256 reward
);

/// @notice Staking balance transfer event
event StakeTransferred(
    address indexed layer2,
    address indexed from,
    address indexed to,
    uint256 amount
);

/// @notice Repeat violation penalty applied event
event PenaltyApplied(
    address indexed layer2,
    uint256 violationCount,
    uint256 requiredDeposit
);
```

---

## 8. Governance Parameters

Parameters that governance must decide for the sequencer slashing system:

| Parameter | Description | Recommended Value |
|-----------|-------------|-------------------|
| **H_max** | Maximum simultaneous challengers | 10 |
| **C_max** | Maximum on-chain cost for single fraud proof | 10e27 (10 TON) |
| **γ (penaltyFactor)** | Repeat violation penalty factor (γ > 1) | TBD |
| **slashingWindow** | Slashing window period | TBD |
| **minimumInitialDepositAmount** | V2 minimum collateral | 1000.1e27 |
