# Option C: Weighted Distribution

## Overview

A higher weight is assigned to the first winner, and rewards are distributed proportionally based on the total sum of weights.

---

## Key Concept

```
First Winner: Weight = firstWinnerWeight (e.g., 2)
Other Winners: Weight = 1
Total Weight = firstWinnerWeight + (challengers.length - 1)
Individual Reward = Total Reward × (Individual Weight / Total Weight)
```

### Example (firstWinnerWeight = 2)

| Challengers | Total Weight | First Winner | Second Winner | Third Winner |
|-------------|--------------|--------------|---------------|--------------|
| 1 | 2 | 100% | - | - |
| 2 | 3 (2+1) | 66.7% | 33.3% | - |
| 3 | 4 (2+1+1) | 50% | 25% | 25% |
| 5 | 6 (2+1+1+1+1) | 33.3% | 16.7% | 16.7% (×3) |

---

## Pros

1. **Flexibility**: Various distribution ratios are possible by adjusting the weight.
2. **Fairness**: The share for the first winner does not decrease as sharply as more participants join.
3. **Scalability**: Can introduce role-based weights (e.g., extra weight for step executors) in the future.
4. **Natural Reduction**: Proportions adjust naturally as the number of challengers increases.

## Cons

1. **Computational Complexity**: Fees, divisions, and weight calculations are required.
2. **Unpredictability**: The reward for the first winner fluctuates depending on the number of challengers.
3. **Single Challenger Case**: The weight is irrelevant (always 100%).

---

## Formula

```
totalWeight = firstWinnerWeight + (challengers.length - 1) * 10000

firstWinnerReward = totalReward × firstWinnerWeight / totalWeight
otherReward = totalReward × 10000 / totalWeight
```

### First Winner Ratio by Weight

| Weight | 2 Challengers | 3 Challengers | 5 Challengers | 10 Challengers |
|--------|---------------|---------------|---------------|----------------|
| 1.5 | 60% | 50% | 37.5% | 25% |
| 2 | 66.7% | 50% | 33.3% | 20% |
| 3 | 75% | 60% | 42.9% | 27.3% |
| 5 | 83.3% | 71.4% | 55.6% | 38.5% |

---

## Implementation Code

### DepositManager_Slashing.sol

```solidity
/// @notice First winner weight multiplier (in basis points, 10000 = 1x)
/// @dev 20000 = 2x weight, 15000 = 1.5x weight
uint256 public firstWinnerWeight = 20000; // Default 2x

/// @notice Set the first winner weight
/// @param newWeight The new weight in basis points (10000 = 1x, 20000 = 2x)
function setFirstWinnerWeight(uint256 newWeight) external onlyOwner {
    require(newWeight >= 10000, "weight must be at least 1x");
    require(newWeight <= 100000, "weight exceeds 10x");
    firstWinnerWeight = newWeight;
    emit FirstWinnerWeightSet(newWeight);
}

/// @notice Distribute rewards based on weight
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
    
    // Calculate total weight (in basis points)
    // firstWinnerWeight + (challengers.length - 1) * 10000
    uint256 otherWeight = 10000; // 1x for others
    uint256 totalWeight = firstWinnerWeight + (challengers.length - 1) * otherWeight;
    
    // Reward for the first winner
    uint256 firstWinnerReward = (totalReward * firstWinnerWeight) / totalWeight;
    IERC20(_wton).safeTransfer(challengers[0], firstWinnerReward);
    emit ChallengerRewarded(layer2, challengers[0], firstWinnerReward);
    
    // Reward for the other winners
    uint256 rewardPerOther = (totalReward * otherWeight) / totalWeight;
    uint256 distributed = firstWinnerReward;
    
    for (uint256 i = 1; i < challengers.length; i++) {
        uint256 amount = rewardPerOther;
        distributed += amount;
        
        // Distribute remainder to the last person (correction for rounding errors)
        if (i == challengers.length - 1) {
            amount = totalReward - distributed + amount;
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
firstWinnerWeight: 2x

Total Weight: 2
Result:
- Alice: 1000 × (2/2) = 1000 WTON (100%)
```

→ Identical to previous behavior.

### Scenario 2: 2 Challengers

```
Challengers: [Alice (first), Bob]
Total Reward: 1000 WTON
firstWinnerWeight: 2x

Total Weight: 2 + 1 = 3
Result:
- Alice: 1000 × (2/3) = 666.67 WTON (66.7%)
- Bob: 1000 × (1/3) = 333.33 WTON (33.3%)
```

→ First winner receives double.

### Scenario 3: 3 Challengers

```
Challengers: [Alice (first), Bob, Charlie]
Total Reward: 1000 WTON
firstWinnerWeight: 2x

Total Weight: 2 + 1 + 1 = 4
Result:
- Alice: 1000 × (2/4) = 500 WTON (50%)
- Bob: 1000 × (1/4) = 250 WTON (25%)
- Charlie: 1000 × (1/4) = 250 WTON (25%)
```

→ Same result as Option A (with 50% fixed setting)!

### Scenario 4: 10 Challengers

```
Challengers: [Alice (first), + 9 others]
Total Reward: 1000 WTON
firstWinnerWeight: 2x

Total Weight: 2 + 9 = 11
Result:
- Alice: 1000 × (2/11) = 181.8 WTON (18.2%)
- 9 others: 1000 × (1/11) = 90.9 WTON each (9.1% each)
```

→ Lower first ratio than Option A (fixed 50%), but others also receive more.

---

## Comparison: Option A vs Option C (5 challengers, 1000 WTON)

| Method | First Winner | Each Other 4 Winners |
|--------|--------------|----------------------|
| Option A (50%) | 500 WTON | 125 WTON |
| Option C (2x) | 333 WTON | 166 WTON |

**Option A**: Strong preference for the first winner.
**Option C**: More balanced distribution.

---

## Configurable Parameters

| Parameter | Description | Default Value | Range |
|-----------|-------------|---------------|-------|
| `firstWinnerWeight` | First winner weight multiplier | 20000 (2x) | 10000-100000 |
| `slashingRewardRate` | Total slashing reward rate | 1000 (10%) | 0-10000 |

---

## Considerations

### 1. Weight Setup Guide

| Weight | Effect |
|--------|--------|
| 1.5x (15000) | Slight preference |
| 2x (20000) | Standard preference (Recommended) |
| 3x (30000) | Strong preference |
| 5x (50000) | Very strong preference |

### 2. Edge Cases

- **1 Challenger**: Receives total reward (same as legacy).
- **firstWinnerWeight = 10000 (1x)**: Equal distribution (same as winning-tracking-plan).
- **Very Many Challengers**: First ratio decreases naturally but remains higher than any other individual.

### 3. Precision Issues

```solidity
// Use basis points (10000 = 1x) to maintain precision
// Remainder after division is paid to the last participant
```

---

## Scalability

### Future introduction of role-based weights

```solidity
// Example: Extra weight for step executor
mapping(address => uint256) public challengerWeight;

function _calculateWeight(address challenger) internal view returns (uint256) {
    if (challenger == firstWinner) return firstWinnerWeight;
    if (stepExecutors[challenger]) return stepperWeight; // e.g., 1.5x
    return 10000; // Default 1x
}
```

---

## Comparison with Legacy Method

| Item | Legacy (Single) | Winning-Tracking (Equal) | Option C (Weighted) |
|------|-----------------|-------------------------|---------------------|
| First Reward | 100% | 1/N | W/(W+N-1) |
| Other Rewards | 0% | 1/N | 1/(W+N-1) |
| Implementation Complexity | Low | Medium | Medium |
| Incentive | First Only | Equal | Preference for First (Flexible) |
| Scalability | Low | Medium | High |

(W = firstWinnerWeight, N = number of challengers)
