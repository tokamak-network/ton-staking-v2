---
id: 06_bridged_ton_tracking
slug: /06_bridged_ton_tracking
---
# Bridged TON Tracking System

## 1. Tracking Necessity

It is impossible to query all L2s' Bridged TON in real-time on-chain due to prohibitively high gas costs.
Therefore, values must be tracked and cached **whenever eligibility and TVL (Bridged TON) change**.

---

## 2. Timing for Tracking

| Change Event | Trigger | Impact |
|--------------|---------|-------|
| **Staking Change** | `deposit()`, `withdraw()` | S_i changes → Eligibility (S_i ≥ θ·B_i) re-evaluation needed |
| **Slashing** | `slashSequencer()`, `transferStake()` | S_i changes → Eligibility re-evaluation needed |
| **Bridged TON Change** | TON deposit/withdrawal on L1 bridge | B_i changes → Eligibility re-evaluation + totalEffectiveBridgedTON update |

---

## 3. Tracking Interface

```solidity
/// @title ISeigManagerV3
/// @notice V3 Seigniorage Manager's Bridged TON Tracking Interface
interface ISeigManagerV3 {
    /// @notice Called when L2's Bridged TON (TVL) changes
    /// @dev Must be called from L1Bridge when TON is deposited/withdrawn
    /// @param layer2 L2 address (candidate)
    /// @param newBridgedTON New Bridged TON amount
    function onBridgedTONChange(address layer2, uint256 newBridgedTON) external;

    /// @notice Called when L2's staking amount changes
    /// @dev Must be called from DepositManager after deposit/withdraw
    /// @param layer2 L2 address (candidate)
    function onStakingChange(address layer2) external;
}
```

---

## 4. Tracking Function Implementation

### 4.1 When Bridged TON Changes

```solidity
/// @notice Called when L2's Bridged TON changes
/// @dev Called from L1Bridge or L1BridgeRegistry
function onBridgedTONChange(address layer2, uint256 newBridgedTON)
    external
    onlyL1BridgeOrRegistry
{
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    uint256 oldEffective = info.effectiveBridgedTON;

    // Update Bridged TON
    info.currentBridgedTON = newBridgedTON;
    info.lastUpdateTime = block.timestamp;

    // Re-evaluate eligibility: S_i ≥ θ · B_i
    (bool eligible,,) = checkEligibility(layer2);
    info.isEligible = eligible;

    // Calculate effective Bridged TON
    uint256 newEffective = eligible ? newBridgedTON : 0;
    info.effectiveBridgedTON = newEffective;

    // Update global sum
    totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;

    emit BridgedTONChanged(layer2, newBridgedTON, newEffective, eligible);
}
```

### 4.2 When Staking Amount Changes

```solidity
/// @notice Called when L2's staking amount changes
/// @dev Called from DepositManager after deposit/withdraw
function onStakingChange(address layer2) external onlyDepositManager {
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    uint256 oldEffective = info.effectiveBridgedTON;

    // Re-evaluate eligibility: S_i ≥ θ · B_i (Bridged TON remains unchanged)
    (bool eligible,,) = checkEligibility(layer2);
    bool wasEligible = info.isEligible;
    info.isEligible = eligible;

    // Update global sum only if eligibility status changed
    if (wasEligible != eligible) {
        uint256 newEffective = eligible ? info.currentBridgedTON : 0;
        info.effectiveBridgedTON = newEffective;
        totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;

        emit EligibilityChanged(layer2, eligible, info.currentBridgedTON, newEffective);
    }
}
```

---

## 5. Call Responsibility

| Contract | Function to Call | Call Timing |
|----------|-----------------|-------------|
| **L1Bridge** | `onBridgedTONChange(layer2, newAmount)` | After TON deposit/withdrawal completes |
| **L1BridgeRegistry** | `onBridgedTONChange(layer2, newAmount)` | When bridge TVL change is detected |
| **DepositManager** | `onStakingChange(layer2)` | After deposit/withdraw completes |
| **SeigManager** | `onStakingChange(layer2)` | After slashSequencer/transferStake completes |

---

## 6. Events

```solidity
/// @notice Bridged TON change event
event BridgedTONChanged(
    address indexed layer2,
    uint256 bridgedTON,           // B_i: New Bridged TON
    uint256 effectiveBridgedTON,  // B̃_i: Effective Bridged TON (0 if ineligible)
    bool isEligible               // Eligibility status
);

/// @notice Eligibility status change event
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);
```

---

## 7. Eligibility Check Functions

### 7.1 Eligibility Check (Rule 4)

```solidity
/// @notice L2 eligibility check
/// @dev Whitepaper formula (9): 1_i = {1 if S_i ≥ θ·B_i, 0 otherwise}
/// @param layer2 L2 address
/// @return eligible Eligibility status
/// @return requiredStake Required staking (θ·B_i)
/// @return currentStake Current staking (S_i)
function checkEligibility(address layer2)
    public view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake)
{
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    uint256 bridgedTON = info.currentBridgedTON;

    // θ · B_i (RAY operation)
    requiredStake = rmul(bridgedTON, minStakingRatio);

    // S_i: Sequencer staking amount for this L2
    currentStake = _getSequencerStake(layer2);

    // S_i ≥ θ · B_i
    eligible = currentStake >= requiredStake;
}

/// @notice Eligibility indicator function value (1 or 0)
function getIndicator(address layer2) public view returns (uint256) {
    (bool eligible,,) = checkEligibility(layer2);
    return eligible ? RAY : 0;
}
```

### 7.2 Effective Bridged TON Query (Rule 3)

```solidity
/// @notice Query effective Bridged TON (cached value)
/// @dev B̃_i = 1_i · B_i (Bridged TON if eligible, 0 otherwise)
/// @dev Real-time value is maintained by onBridgedTONChange, onStakingChange
function getEffectiveBridgedTON(address layer2) public view returns (uint256) {
    return bridgedTONInfo[layer2].effectiveBridgedTON;
}

/// @notice Query total effective Bridged TON (cached value)
/// @dev x = Σ B̃_i (maintained by onBridgedTONChange, onStakingChange)
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

V3's `updateSeigniorage` function uses `totalEffectiveBridgedTON`, which is maintained in real-time by the tracking system above, as a cached value.

```solidity
function _updateSeigniorage() internal ifFree returns (bool) {
    // ... Staker distribution logic ...

    // ========================================
    // Step 4: Use cached total effective Bridged TON
    // (maintained in real-time by onBridgedTONChange, onStakingChange)
    // ========================================
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
┌─────────────────┐    deposit/withdraw    ┌──────────────────┐
│  DepositManager │ ────────────────────► │   SeigManager    │
└─────────────────┘    onStakingChange()   │                  │
                                           │  ┌────────────┐  │
┌─────────────────┐    slashSequencer()    │  │ bridged    │  │
│  SeigManager    │ ────────────────────► │  │ TONInfo    │  │
│  (Slashing)     │    onStakingChange()   │  │ [layer2]   │  │
└─────────────────┘                        │  └────────────┘  │
                                           │        │         │
┌─────────────────┐    TON deposit/withdraw│        │         │
│    L1Bridge     │ ────────────────────► │  checkEligibility │
└─────────────────┘  onBridgedTONChange()  │  S_i ≥ θ·B_i ?   │
                                           │        │         │
                                           │        ▼         │
                                           │  totalEffective  │
                                           │  BridgedTON (x)  │
                                           │        │         │
                                           │        ▼         │
                                           │  updateSeig()    │
                                           │  → Calculate y(x)│
                                           └──────────────────┘
```
