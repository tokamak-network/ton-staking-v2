---
id: 09_migration
slug: /09_migration
---
# Migration Guide

## 1. Upgrade Order

```
1. Deploy SeigManagerV1_4Storage
2. Deploy SeigManagerV1_4 logic
3. Deploy ValidatorPoolStorage
4. Deploy ValidatorPoolV1
5. Deploy Layer2ManagerV1_2 logic
6. Deploy L1BridgeRegistryV1_2 logic

7. Proxy upgrades:
   - ProxySeigManager.upgradeTo(SeigManagerV1_4)
   - ProxyLayer2Manager.upgradeTo(Layer2ManagerV1_2)
   - ProxyL1BridgeRegistry.upgradeTo(L1BridgeRegistryV1_2)

8. Initial parameter setup:
   - setDaoDistributionRatio(0.2e27)     // d = 20%
   - setMinStakingRatio(0.1e27)          // θ = 10%
   - setValidatorDistributionRatio(0.2e27) // α_v = 20%
   - setHalfSaturationPoint(10_000_000e27) // k = 10M TON
   - setStakedSeigFactor(1e27)           // λ = 100% (initial: same as V2)

9. ValidatorPool connection:
   - SeigManager.setValidatorPool(ValidatorPoolV1)
```

---

## 2. Data Migration

```solidity
/// @notice V2 → V3 data migration
function migrateToV3() external onlyOwner {
    // 1. Migrate TVL data from existing layer2RewardInfo
    uint256 numLayer2s = ILayer2Registry(layer2Registry).numLayer2s();

    for (uint256 i = 0; i < numLayer2s; i++) {
        address layer2 = ILayer2Registry(layer2Registry).layer2ByIndex(i);

        // Set V2's TVL data as V3's initial Bridged TON
        uint256 currentTvl = layer2RewardInfo[layer2].layer2Tvl;

        bridgedTONInfo[layer2] = BridgedTONInfo({
            currentBridgedTON: currentTvl,
            effectiveBridgedTON: currentTvl,  // All valid initially
            initialDebt: 0,
            startBlock: block.number,
            lastUpdateTime: block.timestamp,
            isEligible: true  // Set all as eligible initially
        });

        // Update global sum
        totalEffectiveBridgedTON += currentTvl;
    }

    // 2. Initialize first period
    currentPeriodId = 1;
    periods[1].startBlock = block.number;
}
```

---

## 3. Backward Compatibility

```solidity
/// @notice V2 compatible updateSeigniorage (deprecated, V3 automatically called)
function updateSeigniorage() external returns (bool) {
    // Redirect to V3 logic
    return updateSeigniorageV3();
}

/// @notice V2 compatible estimatedDistribute
function estimatedDistribute(uint256 blockNumber, address layer2)
    external view
    returns (
        uint256 maxSeig,
        uint256 stakedSeig,
        uint256 unstakedSeig,
        uint256 powertonSeig,
        uint256 daoSeig,
        uint256 relativeSeig,
        uint256 l2TotalSeigs,
        uint256 layer2Seigs
    )
{
    // Replace with V3 calculation
    (maxSeig, stakedSeig, unstakedSeig, powertonSeig, daoSeig, relativeSeig) =
        _calculateBaseDistribution();

    uint256 totalX = calculateTotalEffectiveBridgedTON();
    uint256 l2MaxAllocation = _calculateL2MaxAllocation(maxSeig, stakedSeig, unstakedSeig);
    l2TotalSeigs = hyperbolicSaturation(totalX, l2MaxAllocation);
    layer2Seigs = calculateL2Seigniorage(layer2, l2TotalSeigs, totalX);
}
```

---

## 4. Test Checklist

### 4.1 Unit Tests

- [ ] `checkEligibility()`: Verify S_i ≥ θ·B_i condition
- [ ] `getEffectiveBridgedTON()`: Returns 0 if ineligible
- [ ] `getTotalEffectiveBridgedTON()`: Total sum accuracy
- [ ] `hyperbolicSaturation()`: Verify y(k) = L/2, monotonic increase, upper limit L
- [ ] `calculateL2Seigniorage()`: Proportional distribution accuracy
- [ ] `onBridgedTONChange()`: Cache update on Bridged TON change
- [ ] `onStakingChange()`: Eligibility re-evaluation on staking change

### 4.2 Transition Mechanism Tests

- [ ] λ = 1, r = 0.4 (V2 state): Staker seigniorage 100%
- [ ] λ = 1, r = 0: No additional seigniorage
- [ ] λ = 0.5, r = 0: Share seigniorage 50%
- [ ] λ = 0, r = 0 (V3 state): Staker seigniorage 0%, A₂ = A

### 4.3 Integration Tests

- [ ] V2 → V3 migration scenario
- [ ] updateSeigniorageV3() full flow
- [ ] ValidatorPool reward distribution
- [ ] Seigniorage redistribution on eligibility loss
- [ ] DepositManager → SeigManager callback test
- [ ] L1Bridge → SeigManager callback test

### 4.4 Boundary Condition Tests

- [ ] y(x) = 0 when x = 0
- [ ] When only single L2 is eligible
- [ ] When all L2s are ineligible
- [ ] When validator count is 0
- [ ] Verify A₂ = A when λ = 0, r = 0

---

## 5. Deployment Parameters (Recommended Values)

```solidity
// V3 core parameters (RAY unit: 1e27)
daoDistributionRatio = 0.2e27;        // d = 20%
minStakingRatio = 0.1e27;             // θ = 10%
validatorDistributionRatio = 0.2e27; // α_v = 20%
halfSaturationPoint = 10_000_000e27; // k = 10M TON

// Transition parameters (initial values)
stakedSeigFactor = 1e27;              // λ = 100% (same as V2)
relativeSeigRate = 0.4e27;            // r = 40% (maintain V2 existing value)

// Validator pool parameters
minimumValidatorDeposit = 10_000e27; // Minimum 10K WTON
ratProbability = 0.01e27;            // π_a = 1%
ratResponseWindow = 1 hours;
```

---

## 6. Gradual Transition Schedule Example

| Phase | Timing | λ | r | Notes |
|-------|--------|---|---|-------|
| Phase 0 | At deployment | 1.0 | 0.4 | Same as V2 |
| Phase 1 | +1 month | 1.0 | 0.2 | Additional seigniorage 50% decrease |
| Phase 2 | +2 months | 1.0 | 0.0 | Additional seigniorage completely removed |
| Phase 3 | +3 months | 0.7 | 0.0 | Share seigniorage 30% decrease |
| Phase 4 | +4 months | 0.4 | 0.0 | Share seigniorage 60% decrease |
| Phase 5 | +5 months | 0.0 | 0.0 | V3 full transition |

---

## 7. New/Changed Contract Summary

| Contract | Change Type | Major Changes |
|----------|------------|---------------|
| **SeigManagerV1_4** | Upgrade | Bridged TON-based distribution, hyperbolic function, eligibility conditions, gradual transition |
| **SeigManagerV1_4Storage** | New | V3 parameter storage, transition parameters |
| **Layer2ManagerV1_2** | Upgrade | Bridged TON query/update, eligibility check |
| **L1BridgeRegistryV1_2** | Upgrade | Bridged TON query function added |
| **DepositManagerV1_3** | Upgrade | onStakingChange callback call |
| **ValidatorPoolV1** | New | RAT validator reward management |
| **ValidatorPoolStorage** | New | Validator data storage |

---

## 8. References

- **Tokamak Economics Whitepaper V2**
- **TON Staking V2 Documentation**: `/Users/zena/tonv2/ton-staking-v2/docs/kr/ton-staking-v2.md`
- **V2 Codebase**: `/Users/zena/tonv2/ton-staking-v2/contracts/`
