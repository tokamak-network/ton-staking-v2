---
id: functions-operator-manager-factory
sidebar_position: 9
---

# OperatorManagerFactory Functions

Functions for creating and managing operator managers.

## createOperatorManager

Creates operator manager.

```solidity
function createOperatorManager(address rollupConfig) external returns (address operatorManager)
```

| Item | Content |
|------|---------|
| **Caller** | Layer2Manager only |
| **Implementation** | V1_1 (default, manual upgrade to V1_2 for TYPE 3 upgrade) |

**Operation Flow**:
```
1. Verify msg.sender == layer2Manager
2. Query rollupConfig's unsafeBlockSigner() → sManager
3. Create OperatorManagerProxy with CREATE2
4. Call upgradeTo(operatorManagerImp), setAddresses()
5. transferManager(sManager), transferOwnership(sOwner)
```

---

## getAddress

Calculates operator manager address.

```solidity
function getAddress(address rollupConfig) public view returns (address)
```

| Item | Content |
|------|---------|
| **Purpose** | CREATE2 address calculation |

---

## Configuration Functions

```solidity
// Change implementation
function changeOperatorManagerImp(address newOperatorManagerImp) external onlyOwner

// Set addresses
function setAddresses(address _depositManager, address _ton, address _wton, address _layer2Manager) external onlyOwner
```

---

## TYPE 3 Upgrade Procedure

To upgrade TYPE 1/2 rollup to TYPE 3 by introducing DisputeGame:

```
1. L1BridgeRegistry.upgradeToType3(rollupConfig)
   └── Verify and register DisputeGameFactory
   └── Change rollupType = 3

2. OperatorManagerProxy.upgradeTo(V1_2 impl)
   └── Owner calls directly
   └── Activate TYPE 3 features
```
