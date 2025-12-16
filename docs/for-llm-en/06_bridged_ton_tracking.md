# Bridged TON Tracking System

## 1. Tracking Necessity

It is impossible to query all L2s' Bridged TON in real-time on-chain due to prohibitively high gas costs.
Therefore, values must be tracked and cached **whenever eligibility and TVL (Bridged TON) change**.

---

## 2. Timing for Tracking

| Change Event | Trigger | Impact |
|--------------|---------|-------|
| **Staking Change** | `deposit()`, `withdraw()` | S_i changes → Eligibility (S_i ≥ θ·B_i) re-evaluation needed |
| **Slashing** | `slashSequencerByGame()` | S_i changes → Eligibility re-evaluation needed |
| **Bridged TON Change** | TON deposit/withdrawal on L1 bridge | B_i changes → Eligibility re-evaluation + totalEffectiveBridgedTON update |

---

## 3. Tracking Interface


### 3.1 SeigManager Interface

```solidity
/// @title ISeigManagerV3
/// @notice Interface called by OptimismPortal and DepositManager
interface ISeigManagerV3 {
    /// @notice Called when L2's Bridged TON (TVL) changes (Type 3 only)
    /// @dev Called directly from OptimismPortal on TON deposit/withdraw
    ///      Looks up rollupConfig automatically from msg.sender (OptimismPortal)
    ///      Trigger function - uses early return instead of revert
    function onBridgedTONChange() external;

    /// @notice Called when TON staking changes (for eligibility re-evaluation)
    /// @dev Called from DepositManager after deposit/withdraw
    /// @param layer2 L2 address
    function onStakingChange(address layer2) external;
}
```

> **Call Flow**:
> - Bridged TON change: OptimismPortal → `SeigManager.onBridgedTONChange()` (direct call, looks up rollupConfig via msg.sender, Type 3 only)
> - Staking change: DepositManager → `SeigManager.onStakingChange(layer2)`

---

## 4. Tracking Function Implementation


### 4.1 SeigManager.onBridgedTONChange (Called directly from OptimismPortal, Type 3 only)

```solidity
/// @notice Called when L2's Bridged TON changes (Type 3 only)
/// @dev Called directly from OptimismPortal on TON deposit/withdraw
///      Trigger function - uses early return instead of revert on condition failure
function onBridgedTONChange()
    external
    onlyMigrated
{
    // 1. Reverse lookup rollupConfig from caller (portal)
    address rollupConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithPortal(msg.sender);
    if (rollupConfig == address(0)) return;

    // 2. Verify type 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)
    uint8 rollupType = IL1BridgeRegistry(l1BridgeRegistry).rollupType(rollupConfig);
    if (rollupType != 3) return;

    // 3. Convert rollupConfig → layer2
    address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(rollupConfig);
    if (layer2 == address(0)) return;

    // 4. Re-evaluate eligibility and sync effectiveBridgedTON
    _updateEligibilityInternal(layer2);
}
```

> **Note**: `onBridgedTONChange` is only called from type 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) rollups.
> **Important**: As a trigger function, it uses early return instead of revert on condition failure. This prevents OptimismPortal deposit/withdrawal transactions from failing.

### 4.2 SeigManager.onStakingChange (Staking Change Callback)

```solidity
/// @notice Called when TON staking changes (for eligibility re-evaluation)
/// @dev Called from DepositManager after deposit/withdraw
/// @param layer2 L2 address
function onStakingChange(address layer2)
    external
    onlyDepositManager
    onlyMigrated
{
    _updateEligibilityInternal(layer2);
}
```

> **Note**: Iterating all L2s on-chain to re-evaluate eligibility is impossible due to prohibitively high gas costs. Therefore, only the affected L2's eligibility is re-evaluated in real-time when staking changes.

---

## 5. Call Responsibility

| Contract | Function to Call | Call Timing |
|----------|-----------------|-------------|
| **OptimismPortal** | `SeigManager.onBridgedTONChange()` | After TON deposit/withdrawal completes (Type 3 only) |
| **DepositManager** | `SeigManager.onStakingChange(layer2)` | After deposit/withdraw completes |

> **Note**: OptimismPortal calls SeigManager directly. SeigManager looks up rollupConfig from `msg.sender` via `L1BridgeRegistry.rollupConfigWithPortal`.

---

## 6. Events

```solidity
/// @notice Eligibility status change event
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);
```

> **Note**: BridgedTONChanged event was removed to save gas costs. Eligibility changes are tracked via EligibilityChanged event.

---

## 7. Eligibility Check Functions

### 7.1 Eligibility Check (Rule 4)

```solidity
/// @notice L2 eligibility check (real-time from L1 bridge)
/// @dev Whitepaper formula (9): 1_i = {1 if S_i ≥ θ·B_i, 0 otherwise}
/// @param layer2 L2 address
/// @return eligible Eligibility status
/// @return requiredStake Required staking (θ·B_i)
/// @return currentStake Current staking (S_i)
function checkCurrentEligibility(address layer2)
    public view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake)
{
    // B_i: Query from L1 bridge (real-time)
    uint256 bridgedTON = ILayer2Manager(layer2Manager).getBridgedTONByLayer(layer2);

    // θ · B_i (RAY operation)
    requiredStake = rmul(bridgedTON, minStakingRatio);

    // S_i: Sequencer staking amount for this L2
    currentStake = _getSequencerStake(layer2);

    // S_i ≥ θ · B_i
    eligible = currentStake >= requiredStake;
}

/// @notice Eligibility indicator function value (1 or 0)
function getIndicator(address layer2) public view returns (uint256) {
    (bool eligible,,) = checkCurrentEligibility(layer2);
    return eligible ? RAY : 0;
}
```

### 7.2 Effective Bridged TON Query (Rule 3)

```solidity
/// @notice Query effective Bridged TON (cached value)
/// @dev B̃_i = 1_i · B_i (Bridged TON if eligible, 0 otherwise)
/// @dev Synchronized via _syncEffectiveBridgedTON at updateSeigniorage time
function getEffectiveBridgedTON(address layer2) public view returns (uint256) {
    return bridgedTONInfo[layer2].effectiveBridgedTON;
}

/// @notice Query total effective Bridged TON (cached value)
/// @dev x = Σ B̃_i (synchronized at updateSeigniorage time)
function getTotalEffectiveBridgedTON() public view returns (uint256) {
    return totalEffectiveBridgedTON;
}

/// @notice Query all Bridged TON information for L2
function getBridgedTONInfo(address layer2) public view returns (
    uint256 currentBridgedTON,
    uint256 effectiveBridgedTON,
    bool isEligible,
    uint256 lastUpdateTime
) {
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    return (
        info.currentBridgedTON,
        info.effectiveBridgedTON,
        info.isEligible,
        info.lastUpdateTime
    );
}
```

### 7.3 Direct Bridged TON Query (from L1 Bridge)

```solidity
/// @notice Direct Bridged TON query (from L1 bridge) - Internal helper
/// @dev Can be used for validation when calling onBridgedTONChange
function _getBridgedTONFromBridge(address layer2) internal view returns (uint256) {
    // Query rollupConfig for this L2 via Layer2Manager
    address rollupConfig = ILayer2Manager(layer2Manager).getRollupConfig(layer2);

    // Query bridge address via L1BridgeRegistry
    (bool valid, address l1Bridge,,) = IL1BridgeRegistry(l1BridgeRegistry)
        .checkL1Bridge(rollupConfig);

    if (!valid) return 0;

    // TON balance locked in bridge = Bridged TON
    return IERC20(_ton).balanceOf(l1Bridge);
}
```

---

## 8. Using Cached Values in updateSeigniorage

V3's `updateSeigniorage` function uses `totalEffectiveBridgedTON` after re-evaluating eligibility via `_syncEffectiveBridgedTON`.

```solidity
function _updateSeigniorage() internal ifFree returns (bool) {
    // ... Staker distribution logic ...

    // ========================================
    // Step 4: Re-evaluate eligibility and sync effective Bridged TON for all L2s
    // ========================================
    _syncAllEffectiveBridgedTON();  // Includes eligibility re-evaluation for staking changes

    uint256 totalX = totalEffectiveBridgedTON;  // x = Σ B̃_i

    if (totalX > 0) {
        // y(x) = L · (x / (k + x))
        uint256 totalY = hyperbolicSaturation(totalX, l2MaxAllocation);

        // ... Distribution logic ...
    }
}
```

---

## 9. Data Flow Diagram

```
┌──────────────────────┐  onBridgedTONChange()    ┌──────────────────────┐
│   OptimismPortal     │ ──────────────────────► │     SeigManager      │
│  (TON deposit/       │  (newBalance)            │  ┌────────────────┐  │
│   withdraw)          │                          │  │ bridgedTONInfo │  │
└──────────────────────┘  msg.sender lookup       │  │ [layer2]       │  │
         │                for rollupConfig        │  └────────────────┘  │
         │                      │                 │         │            │
         ▼                      ▼                 │         │            │
┌──────────────────────┐  rollupConfigWithPortal  │         │            │
│  L1BridgeRegistry    │ ◄────────────────────── │         │            │
│  (reverse mapping)   │                          │         │            │
└──────────────────────┘                          │         │            │
                                                  │         │            │
┌─────────────────┐                               │         │            │
│  DepositManager │  deposit/                     │         │            │
│                 │  withdraw                     │         │            │
│                 │ ───────────────────────────► │  _updateEligibility  │
│                 │  onStakingChange()            │  (eligibility check) │
└─────────────────┘                               │         │            │
                                                  │         ▼            │
                                                  │  totalEffective      │
                                                  │  BridgedTON (x)      │
                                                  │         │            │
                                                  │         ▼            │
                                                  │  Calculate y(x)      │
                                                  └──────────────────────┘
```

> **Key Point**: OptimismPortal calls SeigManager directly. SeigManager looks up rollupConfig from `msg.sender` via `L1BridgeRegistry.rollupConfigWithPortal`, then converts it to the layer2 address.

