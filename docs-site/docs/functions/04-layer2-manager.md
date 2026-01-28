---
id: functions-layer2-manager
sidebar_position: 4
---

# Layer2Manager Functions

L2 registration and Bridged TON query functions.

## getBridgedTon

Queries Bridged TON.

```solidity
function getBridgedTon(address rollupConfig) public view returns (uint256 bridgedTON)
function getBridgedTonByLayer(address layer2) public view returns (uint256 bridgedTON)
```

| Item | Content |
|------|---------|
| **Caller** | Anyone |
| **Query Method** | Calls L1BridgeRegistry.layer2Tvl() |

---

## Configuration Functions (V3 Only)

Configuration functions added in Layer2ManagerV3.

```solidity
// Address setup 1 (L1BridgeRegistry, DepositManager)
function setAddresses1(address _l1BridgeRegistry, address _depositManager) external onlyOwner

// Address setup 2 (SeigManager, OperatorManagerFactory)
function setAddresses2(address _seigManager, address _operatorManagerFactory) external onlyOwner

// OperatorManagerFactory update
function setOperatorManagerFactory(address _operatorManagerFactory) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner (DAO) |
| **Purpose** | Initial setup and updates after V3 deployment |

---

## getLayer2BySystemConfig

Queries Layer2 address by SystemConfig.

```solidity
function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2)
```
