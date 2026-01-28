---
id: functions-l1-bridge-registry
sidebar_position: 5
---

# L1BridgeRegistry Functions

Bridge/portal registration and TVL query functions.

## layer2Tvl

Queries L2 TVL (Bridged TON).

```solidity
function layer2Tvl(address rollupConfig) external view returns (uint256)
```

**Query Method by Rollup Type**:

| Type | Query Target | Query Method |
|------|--------------|--------------|
| Type 1 (Legacy) | L1StandardBridge | Query TON balance |
| Type 2 (Bedrock) | OptimismPortal | Query TON balance |
| Type 3 (Dispute Game) | OptimismPortal | Query TON balance |

---

## rollupConfigWithPortal

Reverse queries rollupConfig by Portal address.

```solidity
function rollupConfigWithPortal(address portal) external view returns (address rollupConfig)
```

| Item | Content |
|------|---------|
| **Purpose** | Query rollupConfig from msg.sender(Portal) in onBridgedTonChange |

---

## setTypeRegistrant

Sets type-specific registration authority.

```solidity
function setTypeRegistrant(uint8 _type, address _registrant) external onlyManager
```

| Item | Content |
|------|---------|
| **Caller** | Manager |
| **Parameters** | `_type`: Rollup type (1, 2, 3, ...), `_registrant`: Authority address |
| **Special Notes** | When `address(0)` is set, only Manager can register |

---

## upgradeToType3

Upgrades from TYPE 1/2 to TYPE 3.

```solidity
function upgradeToType3(address rollupConfig) external onlyManager
```

| Item | Content |
|------|---------|
| **Caller** | Manager |
| **Prerequisites** | Must be registered as TYPE 1 or 2, DisputeGameFactory required |

**Operation Flow**:
```
1. Check current type (only TYPE 1 or 2 allowed)
2. Query and verify DisputeGameFactory address
3. Query and verify Portal address
4. Register Portal:
   - Set portal[portal_] to true if not registered
   - Set rollupConfigWithPortal if not set + emit event
   - Revert if registered to another rollupConfig
5. Check DisputeGameFactory duplicates and register
6. Change rollupType = 3
```

---

## registerRollupConfigByType

Rollup registration with type-specific permission check.

```solidity
function registerRollupConfigByType(
    address rollupConfig,
    uint8 _type,
    address _l2TON,
    string calldata _name
) external onlyTypeRegistrant(_type)
```

| Item | Content |
|------|---------|
| **Caller** | Manager or `typeRegistrant[_type]` |
| **Parameters** | `_type`: 1(Legacy), 2(Bedrock), 3(Dispute Game) |

---

## setAddresses

Performs initial setup.

```solidity
function setAddresses(
    address _layer2Manager,
    address _seigManager,
    address _ton
) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner |
| **Prerequisites** | ton == address(0) (uninitialized state) |
| **Special Notes** | Can only be called once |

---

## setSeigniorageCommittee

Sets SeigniorageCommittee address.

```solidity
function setSeigniorageCommittee(address _seigniorageCommittee) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner |
| **Special Notes** | Cannot set same address as existing |

---

## rejectCandidateAddOn

Stops seigniorage issuance for a specific rollupConfig.

```solidity
function rejectCandidateAddOn(address rollupConfig) external onlySeigniorageCommittee
```

| Item | Content |
|------|---------|
| **Caller** | SeigniorageCommittee |
| **Prerequisites** | rollupType != 0 (registered state) |

**Operation Flow**:
```
1. Check registration status
2. rejectedSeigs = true
3. rejectedL2Deposit = true
4. Call Layer2Manager.pauseCandidateAddOn(rollupConfig)
5. Event: RejectedCandidateAddOn
```

---

## restoreCandidateAddOn

Restores stopped seigniorage issuance.

```solidity
function restoreCandidateAddOn(
    address rollupConfig,
    bool rejectedL2Deposit
) external onlySeigniorageCommittee
```

| Item | Content |
|------|---------|
| **Caller** | SeigniorageCommittee |
| **Prerequisites** | rejectedSeigs == true (stopped state) |

**Operation Flow**:
```
1. Check stopped status
2. rejectedSeigs = false
3. rejectedL2Deposit = parameter value
4. Call Layer2Manager.unpauseCandidateAddOn(rollupConfig)
5. Event: RestoredCandidateAddOn
```

---

## registerRollupConfig

Registers rollup with Registrant authority.

```solidity
function registerRollupConfig(
    address rollupConfig,
    uint8 _type,
    address _l2TON,
    string calldata _name
) external onlyRegistrant
```

| Item | Content |
|------|---------|
| **Caller** | Registrant |
| **Parameters** | `_type`: 1(Legacy), 2(Bedrock), 3(Dispute Game) |
| **Special Notes** | Uses V1_2's `_registerRollupConfig` (includes rollupConfigWithPortal setup) |

---

## View Functions

```solidity
// Query rollup type
function rollupType(address rollupConfig) external view returns (uint8)

// Query L2 TON address
function l2TON(address rollupConfig) external view returns (address)

// Query complete rollup information
function getRollupInfo(address rollupConfig) external view returns (
    uint8 type_,
    address l2TON_,
    bool rejectedSeigs_,
    bool rejectedL2Deposit_,
    string memory name_
)

// Check if seigniorage stopped
function isRejectedSeigs(address rollupConfig) external view returns (bool)

// Check if L2 deposit stopped
function isRejectedL2Deposit(address rollupConfig) external view returns (bool)

// Check registration availability
function availableForRegistration(address rollupConfig, uint8 _type) external view returns (bool)
```
