---
id: 09-layer2-registration-guide
sidebar_position: 9
---
# Layer2 Registration Guide

## Overview

This guide explains the complete flow for registering Layer2 and validators in TON Staking V3.

## Prerequisites

**Optimism SystemConfig Deployment**
- L1 Standard Bridge
- Optimism Portal
- Dispute Game Factory (for TYPE 3)
- Unsafe Block Signer (sequencer address)

## Registration Procedure Overview

**Permission Model**:
- **L1BridgeRegistry**: Only authorized users (Manager + Registrant) can register
- **Layer2Manager**: Anyone can register (permissionless)

### Step 1: Register SystemConfig in L1BridgeRegistry

**Caller**: Address with Manager + Registrant permissions (DAO or administrator)
**Contract to Call**: `L1BridgeRegistry`
**Function to Call**: `registerRollupConfig()`

#### 1-1. Grant Permissions (Prerequisite)

```solidity
// Grant permissions to L1BridgeRegistry (executed by DAO or administrator)
l1BridgeRegistry.addManager(owner);      // Grant Manager permission
l1BridgeRegistry.addRegistrant(owner);   // Grant Registrant permission
```

#### 1-2. Call registerRollupConfig

```solidity
// Call L1BridgeRegistry.registerRollupConfig()
l1BridgeRegistry.registerRollupConfig(
    address(systemConfig),  // Parameter 1: Optimism SystemConfig contract address
    3,                      // Parameter 2: rollupType (TYPE_3 = bedrock + DisputeGame + nativeTON)
    l2TONAddress,          // Parameter 3: L2 native TON contract address
    "Layer2Name"           // Parameter 4: Layer2 name (string)
);
```

**Result**:
- SystemConfig registered in L1BridgeRegistry
- Mapping created: `rollupInfo[systemConfig] = {rollupType: 3, l2TON: l2TONAddress, ...}`

**Important**: Step 2's registerCandidateAddOn internally checks L1BridgeRegistry, so this step must be completed first.

### Step 2: Register Layer2 Candidate

**Caller**: Anyone (permissionless)
**Contract to Call**: `Layer2Manager`
**Function to Call**: `registerCandidateAddOn()`

#### 2-1. Prepare WTON

```solidity
uint256 operatorDeposit = 1000 * RAY; // 1000 WTON (determine deposit amount)

// Mint WTON and approve Layer2Manager
wton.mint(msg.sender, operatorDeposit);
wton.approve(layer2ManagerProxy, operatorDeposit);
```

#### 2-2. Call registerCandidateAddOn

```solidity
// Call Layer2Manager.registerCandidateAddOn()
layer2Manager.registerCandidateAddOn(
    address(systemConfig),  // Parameter 1: Optimism SystemConfig address (registered in Step 1)
    operatorDeposit,        // Parameter 2: Deposit amount (WTON in RAY units, 1e27)
    false,                  // Parameter 3: flagTON (false=WTON, true=TON)
    "Layer2 Memo"           // Parameter 4: Memo (used by DAO when creating CandidateAddOn)
);
```

#### 2-3. Internal Automatic Processing Flow

When `registerCandidateAddOn()` is called, the following processes are **automatically** executed sequentially:

1. **OperatorManager Creation**
   ```
   Call OperatorManagerFactory.createOperatorManager(systemConfig)
   → Create OperatorManager using SystemConfig's unsafeBlockSigner as operator
   ```

2. **CandidateAddOn Creation and Automatic Layer2Registry Registration**
   ```
   Call DAO.createCandidateAddOn(memo, operatorManager)
   → Create new CandidateAddOn contract
   → Automatically call Layer2Registry.registerAndDeployCoinage(candidateAddOn) internally
   → Create Coinage contract
   ```

3. **Mapping Creation**
   ```
   rollupConfigInfo[systemConfig] = {status: 1, operatorManager: operatorManagerAddress}
   operatorInfo[operatorManager] = {rollupConfig: systemConfig, candidateAddOn: candidateAddOn}
   ```

4. **Operator Deposit**
   ```
   Automatically call DepositManager.deposit(candidateAddOn, operatorManager, operatorDeposit)
   → Operator's WTON is deposited to that Layer2's Coinage
   ```

**Result**:
- `systemConfig → layer2 (candidateAddOn)` mapping completed
- candidateAddOn registered in Layer2Registry (Coinage created)
- Operator deposit completed
- Layer2 registration completed: Can query layer2 via `Layer2Manager.getLayer2BySystemConfig(systemConfig)`

## Test Environment Setup

### SimpleMockSystemConfig Setup

```solidity
SimpleMockSystemConfig mockSystemConfig = new SimpleMockSystemConfig();
mockSystemConfig.setL1StandardBridge(mockL1Bridge);
mockSystemConfig.setOptimismPortal(mockPortal);
mockSystemConfig.setDisputeGameFactory(mockDisputeGameFactory);
mockSystemConfig.setUnsafeBlockSigner(sequencer); // Set sequencer address (important!)
```

**Note**: unsafeBlockSigner must be the sequencer address. Distinction from operator is needed.

## References

- Actual implementation: `test/v3/V3ScenarioReal.t.sol`
- Unit tests: `test/v3/BasicFunctions.t.sol`
- Layer2Manager: `src/layer2/Layer2ManagerV1_1.sol`
- RAT: `src/validator/RAT.sol`
