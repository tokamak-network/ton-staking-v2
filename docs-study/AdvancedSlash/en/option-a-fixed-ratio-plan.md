# Option A: Fixed Ratio Distribution

## Overview

A fixed percentage of the total reward is paid to the first winner (the person who countered the root claim), and the remainder is distributed equally **only among the other winners**.

---

## Key Concept

```
First Winner: Total Reward × firstWinnerRate%
Other Winners: (100 - firstWinnerRate)% distributed equally
```

### Formula

```
firstWinnerReward = totalReward × firstWinnerRate / 10000
remainingReward = totalReward - firstWinnerReward
otherReward = remainingReward / (challengers.length - 1)
```

---

## Distribution Example (firstWinnerRate = 50%)

| Number of Challengers | Total Reward | First Winner (50%) | Remainder (50%) | Each Other Winner |
|-----------------------|--------------|--------------------|-----------------|-------------------|
| 1 | 1000 | **1000** | 0 | - |
| 2 | 1000 | **500** | 500 | 500 |
| 3 | 1000 | **500** | 500 | 250 |
| 4 | 1000 | **500** | 500 | 166.7 |
| 5 | 1000 | **500** | 500 | 125 |
| 10 | 1000 | **500** | 500 | 55.6 |

---

## Pros

1. **Simplicity**: The calculation logic is clear and easy to understand.
2. **Predictability**: The first winner always receives a fixed ratio (e.g., 50%).
3. **Strong Incentive**: There is a clear motivation to be the first to challenge.
4. **Easy Configuration**: Only `firstWinnerRate` needs to be adjusted.

## Cons

1. **Potential Imbalance**: As the number of challengers increases, the rewards for the other participants decrease sharply.
2. **Reduced Participation Concern**: If a participant is not the first, the potential reward is smaller, which might discourage subsequent participation.
3. **Fixed First Ratio**: The ratio for the first winner remains the same regardless of the number of challengers.

---

## Implementation Code

### DepositManager_Slashing.sol

```solidity
/// @notice First winner reward rate in basis points (e.g., 5000 = 50%)
uint256 public firstWinnerRate = 5000; // Default 50%

/// @notice Set the first winner reward rate
/// @param newRate The new rate in basis points (0-10000)
function setFirstWinnerRate(uint256 newRate) external onlyOwner {
    require(newRate <= 10000, "rate exceeds 100%");
    firstWinnerRate = newRate;
    emit FirstWinnerRateSet(newRate);
}

/// @notice Distribute rewards with fixed ratio for first winner
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    if (challengers.length == 0) return;
    
    // Case of single challenger
    if (challengers.length == 1) {
        IERC20(_wton).safeTransfer(challengers[0], totalReward);
        emit ChallengerRewarded(layer2, challengers[0], totalReward);
        return;
    }
    
    // Calculate reward for the first winner
    uint256 firstWinnerReward = (totalReward * firstWinnerRate) / 10000;
    
    // Distribute remaining rewards equally among other participants
    uint256 remainingReward = totalReward - firstWinnerReward;
    uint256 otherCount = challengers.length - 1;
    uint256 rewardPerOther = remainingReward / otherCount;
    uint256 remainder = remainingReward % otherCount;
    
    // Pay the first winner
    IERC20(_wton).safeTransfer(challengers[0], firstWinnerReward);
    emit ChallengerRewarded(layer2, challengers[0], firstWinnerReward);
    
    // Pay the other winners
    for (uint256 i = 1; i < challengers.length; i++) {
        uint256 amount = rewardPerOther;
        // Distribute remainder to the second challenger
        if (i == 1) {
            amount += remainder;
        }
        IERC20(_wton).safeTransfer(challengers[i], amount);
        emit ChallengerRewarded(layer2, challengers[i], amount);
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

Result:
- Alice: 1000 WTON (100%)
```

→ Identical to previous behavior.

### Scenario 2: 2 Challengers

```
Challengers: [Alice (first), Bob]
Total Reward: 1000 WTON
firstWinnerRate: 50%

Calculation:
- First: 500 WTON
- Remainder: 500 / 1 = 500 WTON

Result:
- Alice: 500 WTON (50%)
- Bob: 500 WTON (50%)
```

→ Equal distribution.

### Scenario 3: 3 Challengers

```
Challengers: [Alice (first), Bob, Charlie]
Total Reward: 1000 WTON
firstWinnerRate: 50%

Calculation:
- First: 500 WTON
- Remainder: 500 / 2 = 250 WTON each

Result:
- Alice: 500 WTON (50%)
- Bob: 250 WTON (25%)
- Charlie: 250 WTON (25%)
```

### Scenario 4: 10 Challengers

```
Challengers: [Alice (first), + 9 others]
Total Reward: 1000 WTON
firstWinnerRate: 50%

Calculation:
- First: 500 WTON
- Remainder: 500 / 9 = 55.6 WTON each

Result:
- Alice: 500 WTON (50%)
- 9 others: 55.6 WTON each (5.6% each)
```

→ Rewards for other participants become significantly smaller.

---

## First Winner Ratio (Fixed)

| Number of Challengers | First Winner Ratio | Each Other Winner Ratio |
|-----------------------|--------------------|-------------------------|
| 1 | 100% | - |
| 2 | 50% | 50% |
| 3 | 50% | 25% |
| 4 | 50% | 16.7% |
| 5 | 50% | 12.5% |
| 10 | 50% | 5.6% |

→ **First winner always gets a fixed 50%** (regardless of the number of challengers).

---

## Configurable Parameters

| Parameter | Description | Default Value | Range |
|-----------|-------------|---------------|-------|
| `firstWinnerRate` | First winner ratio | 5000 (50%) | 0-10000 |
| `slashingRewardRate` | Total slashing reward rate | 1000 (10%) | 0-10000 |

---

## firstWinnerRate Setup Guide

| Rate | Effect | Distribution for 3 Challengers |
|------|--------|--------------------------------|
| 30% | Slight preference for the first | 300 / 350 / 350 |
| 50% | Balanced distribution (Recommended) | 500 / 250 / 250 |
| 70% | Strong preference for the first | 700 / 150 / 150 |

---

## Edge Cases

| Case | Result |
|------|--------|
| 1 challenger | Total reward (same as legacy) |
| 2 challengers | 50% each (when firstWinnerRate=50%) |
| firstWinnerRate = 0 | Remainder distributed equally (First 0%) |
| firstWinnerRate = 10000 (100%) | Only the first winner is rewarded |

---

## Comparison with Legacy Method

| Item | Legacy (Single) | Equal Distribution | Option A (Fixed Ratio) |
|------|-----------------|--------------------|------------------------|
| First Reward | 100% | 1/N | firstWinnerRate% |
| Other Rewards | 0% | 1/N | (100-firstWinnerRate)/(N-1)% |
| Implementation Complexity | Low | Medium | Medium |
| Incentive | First Only | Equal | Preference for First |
