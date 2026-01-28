# Option B: Bonus + Equal Distribution

## Overview

A fixed percentage of the total reward is paid to the first winner (the person who countered the root claim) as a **bonus**, and the remaining amount is distributed equally among **all winners, including the first one**.

---

## Key Concept

```
First Winner: (Total Reward × firstWinnerRate%) + (Remainder / Total Count)
Other Winners: Remainder / Total Count
```

### Formula

```
firstWinnerBonus = totalReward × firstWinnerRate / 10000
remainingReward = totalReward - firstWinnerBonus
equalShare = remainingReward / challengers.length

First Winner = firstWinnerBonus + equalShare
Other Winners = equalShare
```

---

## Distribution Example (firstWinnerRate = 50%)

| Challengers | Total Reward | Bonus (50%) | Remainder | Equal Share | First Winner | Each Other Winner |
|-------------|--------------|-------------|-----------|-------------|--------------|-------------------|
| 1 | 1000 | 500 | 500 | 500 | **1000** | - |
| 2 | 1000 | 500 | 500 | 250 | **750** | 250 |
| 3 | 1000 | 500 | 500 | 166.7 | **666.7** | 166.7 |
| 4 | 1000 | 500 | 500 | 125 | **625** | 125 |
| 5 | 1000 | 500 | 500 | 100 | **600** | 100 |
| 10 | 1000 | 500 | 500 | 50 | **550** | 50 |

---

## Pros

1. **Strong Incentive for the First**: Receives both the bonus and an equal share.
2. **Fairness for Subsequent Participants**: The first winner also participates in the equal distribution, ensuring fairness.
3. **Encouragement of Participation**: Guarantees a certain reward even if not first.
4. **Minimum Guarantee**: The first winner is always guaranteed at least `firstWinnerRate%`.
5. **Predictability**: The bonus ratio is fixed.

## Cons

1. **Large Share for the First**: If set to 50%, the first winner always takes more than half. (Setting it between 10-20% might be more appropriate.)
2. **If Many Challengers**: Individual rewards for others become very small.
3. **More Complex than Option A**: The first winner is included in the equal distribution.

---

## Implementation Code

### DepositManager_Slashing.sol

```solidity
/// @notice First winner bonus rate in basis points (e.g., 5000 = 50%)
uint256 public firstWinnerRate = 5000; // Default 50%

/// @notice Set the first winner bonus rate
/// @param newRate The new rate in basis points (0-10000)
function setFirstWinnerRate(uint256 newRate) external onlyOwner {
    require(newRate <= 10000, "rate exceeds 100%");
    firstWinnerRate = newRate;
    emit FirstWinnerRateSet(newRate);
}

/// @notice Distribute rewards: first winner gets bonus + equal share
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    if (challengers.length == 0) return;
    
    // Case of single challenger - Total Reward
    if (challengers.length == 1) {
        IERC20(_wton).safeTransfer(challengers[0], totalReward);
        emit ChallengerRewarded(layer2, challengers[0], totalReward);
        return;
    }
    
    // Calculate first winner bonus
    uint256 firstWinnerBonus = (totalReward * firstWinnerRate) / 10000;
    
    // Distribute remaining amount equally among all participants (including the first)
    uint256 remainingReward = totalReward - firstWinnerBonus;
    uint256 equalShare = remainingReward / challengers.length;
    uint256 remainder = remainingReward % challengers.length;
    
    // First winner: Bonus + Equal share + Remainder
    uint256 firstWinnerTotal = firstWinnerBonus + equalShare + remainder;
    IERC20(_wton).safeTransfer(challengers[0], firstWinnerTotal);
    emit ChallengerRewarded(layer2, challengers[0], firstWinnerTotal);
    
    // Other winners: Equal share only
    for (uint256 i = 1; i < challengers.length; i++) {
        IERC20(_wton).safeTransfer(challengers[i], equalShare);
        emit ChallengerRewarded(layer2, challengers[i], equalShare);
    }
}
```

---

## Scenario Analysis

### Scenario 1: Single Challenger

```
Challenger: Alice
Total Reward: 1000 WTON
firstWinnerRate: 50%

Calculation:
- Bonus: 500 WTON
- Remainder: 500 WTON
- Equal Share: 500 / 1 = 500 WTON

Result:
- Alice: 500 + 500 = 1000 WTON (100%)
```

### Scenario 2: 2 Challengers

```
Challengers: [Alice (first), Bob]
Total Reward: 1000 WTON
firstWinnerRate: 50%

Calculation:
- Bonus: 500 WTON
- Remainder: 500 WTON
- Equal Share: 500 / 2 = 250 WTON

Result:
- Alice: 500 + 250 = 750 WTON (75%)
- Bob: 250 WTON (25%)
```

### Scenario 3: 4 Challengers

```
Challengers: [Alice (first), Bob, Charlie, David]
Total Reward: 1000 WTON
firstWinnerRate: 50%

Calculation:
- Bonus: 500 WTON
- Remainder: 500 WTON
- Equal Share: 500 / 4 = 125 WTON

Result:
- Alice: 500 + 125 = 625 WTON (62.5%)
- Bob: 125 WTON (12.5%)
- Charlie: 125 WTON (12.5%)
- David: 125 WTON (12.5%)
```

### Scenario 4: 10 Challengers

```
Challengers: [Alice (first), + 9 others]
Total Reward: 1000 WTON
firstWinnerRate: 50%

Calculation:
- Bonus: 500 WTON
- Remainder: 500 WTON
- Equal Share: 500 / 10 = 50 WTON

Result:
- Alice: 500 + 50 = 550 WTON (55%)
- 9 others: 50 WTON each (5% each)
```

---

## First Winner Ratio Variation

| Challengers | First Winner Ratio (50% bonus) |
|-------------|--------------------------------|
| 1 | 100% |
| 2 | 75% |
| 3 | 66.7% |
| 4 | 62.5% |
| 5 | 60% |
| 10 | 55% |
| 100 | 50.5% |

→ **Regardless of the number of challengers, the first winner is guaranteed at least 50%.**

---

## Configurable Parameters

| Parameter | Description | Default Value | Range |
|-----------|-------------|---------------|-------|
| `firstWinnerRate` | First winner bonus ratio | 5000 (50%) | 0-10000 |
| `slashingRewardRate` | Total slashing reward rate | 1000 (10%) | 0-10000 |

---

## firstWinnerRate Setup Guide

| Rate | First for 2 Challengers | First for 4 Challengers | Characteristics |
|------|-------------------------|-------------------------|-----------------|
| 30% | 65% | 47.5% | Weak preference |
| 50% | 75% | 62.5% | Medium preference (Recommended) |
| 70% | 85% | 77.5% | Strong preference |

---

## Edge Cases

| Case | Result |
|------|--------|
| 1 challenger | Total reward (same as legacy) |
| firstWinnerRate = 0 | Completely equal distribution |
| firstWinnerRate = 10000 (100%) | Only the first winner rewarded (others 0) |

---

## Comparison: Option A vs Option B (1000 WTON, 50% setting)

| Challengers | Option A First | Option A Others | Option B First | Option B Others |
|-------------|----------------|-----------------|----------------|-----------------|
| 2 | 500 | 500 | **750** | 250 |
| 3 | 500 | 250 | **666.7** | 166.7 |
| 4 | 500 | 166.7 | **625** | 125 |
| 5 | 500 | 125 | **600** | 100 |

**Differences:**
- **Option A**: First winner fixed at 500, remainder distributed among others.
- **Option B**: First winner gets 500 + equal share, others get equal share only.
