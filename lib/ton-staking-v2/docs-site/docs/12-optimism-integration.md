---
id: 12-optimism-integration
sidebar_position: 12
---
# TON Staking V3 Optimism Integration

This document explains the integration implementation between Optimism L2 and TON Staking V3 system (RAT, SeigManager).

---

## Optimism Fork Repository

**Repository:** https://github.com/tokamak-network/optimism
**Branch:** `feature/ton-staking-v3`

This branch is based on Optimism Bedrock and includes modifications to the following contracts for TON Staking V3 integration:
- `DisputeGameFactory.sol` - Added RAT trigger
- `FaultDisputeGame.sol` - Added RAT callback
- `OptimismPortal2.sol` - Added Bridged TON change notification
- Interfaces: `IRAT.sol`, `ISeigManager.sol`

**Integration Testing:**
- E2E tests are run with contracts from this forked Optimism repository.
- Test location: `op-e2e/faultproofs/` directory

---

## Modified/Created Files (Optimism Side)

### New Interfaces

| File | Description |
|------|-------------|
| `interfaces/L1/IRAT.sol` | TON Staking V3 RAT interface |
| `interfaces/L1/ISeigManager.sol` | TON Staking V3 SeigManager interface |

### Modified Files

| File | Changes |
|------|---------|
| `src/dispute/DisputeGameFactory.sol` | Added RAT trigger call |
| `src/dispute/FaultDisputeGame.sol` | Added RAT callback call |
| `src/L1/OptimismPortal2.sol` | Added Bridged TON change notification |

---

## 1. IRAT Interface

```solidity
// interfaces/L1/IRAT.sol
interface IRAT {
    /// @notice RAT test trigger (called by DisputeGameFactory)
    /// @param gameAddress Newly created FaultDisputeGame address
    /// @param systemConfig L2's SystemConfig address (L2 identifier)
    /// @param batchIndex Batch/game index
    /// @param batchHash Batch hash or Output Root
    /// @param blockHash Block hash (for random validator selection)
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice Called when claim is resolved (called by FaultDisputeGame)
    /// @param claimant Address that won the game
    function resolveClaim(address claimant) external;
}
```

---

## 2. DisputeGameFactory - RAT Trigger

### Added State Variables

```solidity
/// @notice RAT contract address (TON Staking V3 RAT)
address public rat;

/// @notice SystemConfig address for RAT L2 identification
address public systemConfig;
```

### Added Functions

```solidity
/// @notice Set RAT contract address
/// @dev Only owner can call
/// @param _rat RAT contract address
function setRAT(address _rat) external onlyOwner;

/// @notice Set SystemConfig address
/// @dev Only owner can call
/// @param _systemConfig This L2's SystemConfig address
function setSystemConfig(address _systemConfig) external onlyOwner;
```

### RAT Trigger in create() Function

```solidity
// Trigger RAT after game creation
// RAT stores gameAddress for authentication check in resolveClaim()
if (rat != address(0) && _gameType.raw() == GameTypes.CANNON.raw()) {
    try IRAT(rat).triggerAttentionTest(
        address(proxy_),                     // gameAddress
        systemConfig,                        // L2 identifier
        uint32(_disputeGameList.length - 1), // batchIndex
        Claim.unwrap(_rootClaim),            // batchHash
        parentHash                           // blockHash
    ) { } catch { }
}
```

**Location**: `DisputeGameFactory.sol` Line 203-211

**Features**:
- Only triggers for CANNON game type
- Wrapped in try-catch (game creation succeeds even if RAT fails)
- Skips if RAT not set

---

## 3. FaultDisputeGame - RAT Callback

### Added State Variable

```solidity
/// @notice RAT contract address
address public rat;
```

### Initialization

```solidity
/// @notice Initialize with RAT address
/// @param _rat RAT contract address
function initialize(address _rat) public payable virtual {
    _initialize(_rat);
}

/// @notice Initialize without RAT (backward compatibility)
function initialize() public payable virtual {
    _initialize(address(0));
}

/// @notice Internal initialization function
function _initialize(address _rat) internal virtual {
    // ... existing logic ...
    
    // Set RAT address
    if (_rat != address(0)) rat = _rat;
}
```

**Location**: `FaultDisputeGame.sol` Line 290-376

**calldata length**:
- Without RAT: 122 bytes
- With RAT: 154 bytes (32 bytes RAT address added)

### RAT Callback

```solidity
/// @notice Safely call RAT resolveClaim function
/// @param claimant Claim winner
function resolveClaimRat(address claimant) internal {
    if (rat != address(0)) {
        try IRAT(rat).resolveClaim(claimant) { } catch { }
    }
}
```

**Location**: `FaultDisputeGame.sol` Line 943-947

**Call timing**:
- On uncontested claim resolution (Line 794)
- On successful L2 block number challenge (Line 855)
| On general claim resolution (Line 862)

---

## 4. ISeigManager Interface

```solidity
// interfaces/L1/ISeigManager.sol
interface ISeigManager {
    /// @notice Called when Bridged TON balance changes
    /// @dev Called by OptimismPortal2
    ///      Reverse lookup rollupConfig from msg.sender
    function onBridgedTonChange() external;
}
```

**Important**: 
- No parameters (different from documentation!)
- SeigManager queries rollupConfig from `msg.sender` (OptimismPortal)
- L2 identification via `rollupConfigWithPortal[msg.sender]`

---

## 5. OptimismPortal2 - Bridged TON Notification

### Added State Variable

```solidity
/// @notice SeigManager contract address (TON Staking V3)
address public seigManager;
```

### Added Function

```solidity
/// @notice Set SeigManager address
/// @dev Only ProxyAdmin owner can call
/// @param _seigManager SeigManager contract address
function setSeigManager(address _seigManager) external {
    require(msg.sender == address(proxyAdmin.owner()));
    seigManager = _seigManager;
}
```

**Location**: `OptimismPortal2.sol` Line 391-394

### Bridged TON Change Notification

```solidity
/// @notice Notify SeigManager of Bridged TON balance change
/// @dev Called after TON deposit/withdrawal completion
///      Transaction continues even if SeigManager missing or function reverts
function _notifySeigManager() internal {
    if (seigManager != address(0)) {
        // Prevent revert with low-level call
        try ISeigManager(seigManager).onBridgedTonChange() {} catch {}
    }
}
```

**Location**: `OptimismPortal2.sol` Line 400-406

### Call Timing

| Event | Location | Description |
|-------|----------|-------------|
| TON deposit (L1→L2) | Line 714 | After `depositTransaction` completion |
| TON withdrawal (L2→L1) | Line 817 | After `finalizeWithdrawalTransaction` completion |

**Operation Flow**:
```
1. User deposits/withdraws TON via OptimismPortal2
   ↓
2. Transaction processing complete
   ↓
3. _notifySeigManager() called
   ↓
4. SeigManager.onBridgedTonChange() called
   ↓
5. SeigManager identifies L2 from msg.sender (Portal)
   - rollupConfig = rollupConfigWithPortal[msg.sender]
   - layer2 = getLayer2BySystemConfig(rollupConfig)
   ↓
6. _updateEligibilityInternal(layer2) called
   - Re-evaluate eligibility based on Bridged TON change
```

---

## 6. Verification Flow

### RAT Game Verification

```
On triggerAttentionTest(gameAddress, systemConfig, ...) call:
├── msg.sender = DisputeGameFactory
├── Verify trustedFactories[systemConfig] == msg.sender
└── Store gameToTestId[gameAddress] = testId

On resolveClaim(claimant) call:
├── msg.sender = FaultDisputeGame
└── Check gameToTestId[msg.sender] exists
```

**Verification Location**: `RAT.sol`
- `onlyValidFactory` modifier: Verify DisputeGameFactory
- `factoryByGame[msg.sender]`: Verify FaultDisputeGame

### Bridged TON Verification

```
On onBridgedTonChange() call:
├── msg.sender = OptimismPortal2
├── rollupConfig = rollupConfigWithPortal[msg.sender]
└── layer2 = getLayer2BySystemConfig(rollupConfig)
```

**Verification Location**: `SeigManagerV3_1.sol` Line 309-313

---

## 7. Deployment Configuration

### DisputeGameFactory Configuration

```solidity
// Called by owner
disputeGameFactory.setRAT(ratAddress);
disputeGameFactory.setSystemConfig(systemConfigAddress);
```

### OptimismPortal2 Configuration

```solidity
// Called by ProxyAdmin owner
optimismPortal2.setSeigManager(seigManagerAddress);
```

### L1BridgeRegistry Configuration

```solidity
// Register mappings for reverse lookup from SeigManager, Layer2Manager, etc.
l1BridgeRegistry.rollupConfigWithPortal[optimismPortal2] = systemConfig;
l1BridgeRegistry.rollupConfigWithDisputeGameFactory[disputeGameFactory] = systemConfig;
```

**Note**: L1BridgeRegistry mappings are automatically set on L2 registration

---

## 8. Safety

All external calls do not affect original transaction failure:

| Function | Safety Mechanism | Location |
|----------|------------------|----------|
| `triggerAttentionTest` | try-catch | DisputeGameFactory.sol:203 |
| `resolveClaim` | try-catch | FaultDisputeGame.sol:945 |
| `onBridgedTonChange` | try-catch | OptimismPortal2.sol:404 |

**Design Principles**:
- Skip call if RAT/SeigManager not set (zero address)
- Original transaction continues even if call fails
- Optimism core functionality operates independently of TON Staking V3

---

## 9. Differences Between Implementation and Documentation

### Previous Design (Documentation)

```solidity
// L1StandardBridge calls SeigManager
function onBridgedTonChange(address rollupConfig, uint256 totalTONTVL) external;
```

### Actual Implementation (Code)

```solidity
// OptimismPortal2 calls SeigManager
function onBridgedTonChange() external;  // No parameters
```

**Reasons for Change**:
1. **OptimismPortal2 is the actual entry point for TON deposits/withdrawals**
   - L1StandardBridge is ERC20-only
   - OptimismPortal2 handles Native TON

2. **L2 identification based on msg.sender**
   - Passing as parameter allows forgery
   - Verify Portal via msg.sender → reverse lookup rollupConfig
   - More secure structure

3. **TVL calculation is SeigManager's responsibility**
   - SeigManager queries TVL via L1BridgeRegistry
   - Portal only handles notification (separation of concerns)

---

## 10. Related Code Locations

### Optimism (packages/contracts-bedrock)

| File | Main Changes | Lines |
|------|--------------|-------|
| `src/dispute/DisputeGameFactory.sol` | RAT trigger | 74-78, 203-211, 309-318 |
| `src/dispute/FaultDisputeGame.sol` | RAT callback | 234, 290-376, 794, 855, 862, 943-947 |
| `src/L1/OptimismPortal2.sol` | SeigManager notification | 129-131, 391-406, 714, 817 |
| `interfaces/L1/IRAT.sol` | RAT interface | - |
| `interfaces/L1/ISeigManager.sol` | SeigManager interface | - |

### TON Staking V3

| File | Main Logic | Lines |
|------|-----------|-------|
| `src/validator/RAT.sol` | triggerAttentionTest | 554-577 |
| `src/validator/RAT.sol` | resolveClaim | 680-730 |
| `src/stake/managers/SeigManagerV3_1.sol` | onBridgedTonChange | 306-317 |
| `src/layer2/L1BridgeRegistryV1_2.sol` | Portal/Factory mapping | - |

---

## 11. Tests

### Optimism Side Integration Tests

```solidity
// DisputeGameFactory tests
- RAT trigger normal operation
- Normal operation when RAT missing
- try-catch normal operation

// FaultDisputeGame tests
- RAT callback normal operation
- Normal operation when RAT missing
- calldata length verification

// OptimismPortal2 tests
- SeigManager notification normal operation
- Normal operation when SeigManager missing
- try-catch normal operation
```

### TON Staking V3 Side Integration Tests

```solidity
// RAT tests
- Block invalid Factory calls
- Verify normal game
- Random validator selection

// SeigManager tests
- Ignore invalid Portal calls
- Normal eligibility update
- Detect Bridged TON changes
```

Test files:
- `test/v3/v3mode/RAT.t.sol`
- `test/v3/v3mode/EligibilityTransition.t.sol`
