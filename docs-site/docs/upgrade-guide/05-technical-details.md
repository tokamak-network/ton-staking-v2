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
        // Use V2 logic (delegatecall to SeigManagerV3_2)
        return _updateSeigniorageV2Delegatecall();
    }

    // V3 logic
    return _updateSeigniorageV3();
}

// V3 seigniorage distribution implementation
function _distributeV3Seigniorage(uint256 A) internal returns (uint256 l2TotalSeigs, uint256 layer2Seigs) {
    // 1. DAO fixed distribution
    uint256 sDao = (A * daoDistributionRatio) / RAY_UNIT;
    
    // 2. L2 distribution pool
    uint256 L = A - sDao;

    // 3. Total effective Bridged TON (cached)
    uint256 _totalEffective = totalEffectiveBridgedTON;

    if (_totalEffective > 0) {
        // 4. Hyperbolic saturation function: y(x) = L · (x / (k + x))
        uint256 y = (L * _totalEffective) / (halfSaturationPoint + _totalEffective);
        l2TotalSeigs = y;

        // 5. Sequencer/Validator split
        uint256 totalValReward = (y * validatorDistributionRatio) / RAY_UNIT;
        uint256 totalSeqReward = y - totalValReward;

        // 6. Mint total rewards once (gas optimization)
        // Sequencer rewards: mint to layer2Manager (total for all L2s)
        if (totalSeqReward > 0) {
            IWTON(_wton).mint(layer2Manager, totalSeqReward);
        }

        // Validator rewards: mint to validatorReward (total for all L2s)
        if (totalValReward > 0 && validatorReward != address(0)) {
            IWTON(_wton).mint(validatorReward, totalValReward);
        }

        // 7. Update rewardPerUnit (debt-based distribution management per L2)
        bridgedTONRewardPerUint += (totalSeqReward * WEI_UNIT) / _totalEffective;
        validatorRewardPerUint += (totalValReward * WEI_UNIT) / _totalEffective;

        // 8. Claim rewards for calling L2
        layer2Seigs = _claimL2Rewards();

        // 9. Mint DAO rewards (fixed + undistributed)
        _mintDaoReward(sDao, L, y);
    } else {
        // No eligible L2s: DAO receives all
        _mintDaoReward(sDao, L, 0);
    }
}

// Claim rewards per L2 (debt formula)
function _claimL2Rewards() internal returns (uint256 layer2Seigs) {
    address rollupConfig;
    bool allowed;
    (rollupConfig, allowed) = _allowIssuanceLayer2Seigs(msg.sender);
    if (!allowed || _isExcludedFromSeigniorage(msg.sender)) return 0;

    _syncEffectiveBridgedTon(msg.sender);

    BridgedTONInfo storage info = bridgedTONInfo[msg.sender];
    if (!info.isEligible || info.effectiveBridgedTON == 0) return 0;

    // Sequencer rewards: rewardPerUnit * effectiveBridged - initialDebt
    uint256 seqAccumulated = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
    layer2Seigs = seqAccumulated - info.initialDebt;

    // Validator rewards: rewardPerUnit * effectiveBridged - validatorInitialDebt
    uint256 valAccumulated = (validatorRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
    uint256 valReward = valAccumulated - info.validatorInitialDebt;

    // Transfer sequencer rewards (already minted to layer2Manager)
    if (layer2Seigs > 0) {
        ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
    }

    // Distribute validator rewards (already minted to validatorReward)
    if (valReward > 0 && validatorReward != address(0)) {
        IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
    }

    // Update initialDebt (prevent duplicate claims)
    info.initialDebt = seqAccumulated;
    info.validatorInitialDebt = valAccumulated;
}
```

**Key Differences:**
1. **V2 Logic Separation**: V2 logic executed via delegatecall to SeigManagerV3_2
2. **Gas Optimization**: Mint total rewards once instead of per-L2
3. **Debt System**: Track each L2's rewards with `rewardPerUnit`, settle individually at claim time
4. **Accurate Function Name**: `distributeL2Rewards(rollupConfig, valReward)` (uses systemConfig)

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

**Key Concepts:**
- **Legacy Layer2 (Candidate)**: `operator()` → returns `candidate()`
  - Collateral staked to sequencer's personal address
- **OP Stack Layer2 (OperatorManager)**: `operator()` → returns `manager()`
  - Collateral staked to OperatorManager contract address
  - Actual sequencer queried via OperatorManager's `candidate()` function

**For OP Stack Layer2:**
```solidity
// OperatorManager structure
address operatorManagerAddress = Layer2I(layer2).operator();  // OperatorManager address
address actualSequencer = ICandidate(operatorManagerAddress).candidate();  // Actual sequencer address

// Collateral staked to OperatorManager address
uint256 collateral = coinage.balanceOf(operatorManagerAddress);
```

### Validator Collateral

```solidity
// RAT.sol
function _getValidatorCollateral(address validator, address systemConfig)
    internal view returns (uint256 collateral, address layer2)
{
    layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    if (layer2 == address(0)) return (0, address(0));

    // Query coinage through SeigManager
    collateral = ISeigManagerForRAT(seigManager).stakeOf(layer2, validator);
}
```

**Note**: Actual implementation returns `(collateral, layer2)` tuple to avoid duplicate queries.

## RAT Coinage Transfer Implementation (New)

**SeigManagerV3_1.sol** - RAT Integration Functions
```solidity
// Transfer coinage from validator → RAT (slashing pre-deduction)
function transferCoinageToRat(address layer2, address validator, uint256 amount)
    external onlyRat whenV3Active
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    _checkCoinage(address(coinage));
    coinage.burnFrom(validator, amount);  // Burn from validator
    coinage.mint(ratContract, amount);     // Mint to RAT

    emit CoinageTransferredForRAT(layer2, validator, ratContract, amount);
}

// Transfer coinage from RAT → validator (restoration)
function transferCoinageFromRat(address layer2, address validator, uint256 amount)
    external onlyRat whenV3Active
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    _checkCoinage(address(coinage));
    coinage.burnFrom(ratContract, amount);  // Burn from RAT
    coinage.mint(validator, amount);        // Mint to validator

    emit CoinageTransferredForRAT(layer2, ratContract, validator, amount);
}

// Transfer coinage from RAT → arbitrary address (for Treasury withdrawal)
function transferCoinageFromRatTo(address layer2, address recipient, uint256 amount)
    external onlyRat
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    _checkCoinage(address(coinage));
    coinage.burnFrom(ratContract, amount);  // Burn from RAT
    coinage.mint(recipient, amount);        // Mint to recipient

    emit CoinageTransferredForRAT(layer2, ratContract, recipient, amount);
}
```

> **⚠️ Important**: 
> - RAT does not have permission to directly manipulate coinage, so it must go through SeigManager
> - Function name is `transferCoinageToRat` (not uppercase RAT)
> - Modifier is `onlyRat whenV3Active` (only available after V3 migration)
> - Event is `CoinageTransferredForRAT` (includes 3 parameters: from, to, amount)

**RAT.sol** - SeigManager Calls
```solidity
// Transfer validator → RAT coinage
function _transferCoinageToRAT(address layer2, address validator, uint256 amount) internal {
    ISeigManagerForRAT(seigManager).transferCoinageToRat(layer2, validator, amount);
}

// Transfer RAT → validator coinage (restoration)
function _transferCoinageFromRAT(address layer2, address validator, uint256 amount) internal {
    ISeigManagerForRAT(seigManager).transferCoinageFromRat(layer2, validator, amount);
}
```
