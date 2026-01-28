---
id: upgrade-technical-details
sidebar_position: 5
---

# Technical Implementation Details

## Contract Version Comparison

| Contract | V2 (Current Mainnet) | V3 (Upgrade) | Status |
|----------|---------------------|--------------|--------|
| **SeigManager** | V1_3 (0xce18...F628) | V1_4 (not deployed) | ✅ Complete |
| **DepositManager** | V1_1 | V1_2 | ✅ Complete |
| **Layer2Manager** | V1_1 | V1_2 | ✅ Complete |
| **L1BridgeRegistry** | V1_1 | V1_2 (single implementation) | ✅ Complete |
| **RAT** | None | New deployment | ✅ Complete |
| **ValidatorReward** | None | New deployment | ✅ Complete |

## Seigniorage Distribution Logic Change

### V2 Implementation (SeigManagerV1_3, Current Mainnet)
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

### V3 Implementation (SeigManagerV3_1, Upgrade)
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

## Collateral Query Method (V3 New)

### Sequencer Collateral

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

### Validator Collateral

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

## RAT Coinage Transfer Implementation (New)

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
