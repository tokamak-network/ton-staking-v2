# TON Staking V3 Genesis Setup (Offline Mode)

## Overview

This document describes how TON Staking V3 contracts are initialized in genesis (offline mode) for devnet testing.

## Genesis Generation Process

### 1. Load Optimism Contracts

From `.devnet/devnetL1.json` and `.devnet/optimism-addresses.json`:
- **SystemConfig**: Optimism's system configuration contract
- **DisputeGameFactory**: Factory for creating fault dispute games
- **OptimismPortal**: L1 bridge portal contract
- **AnchorStateRegistry**: Stores anchor states for dispute games

### 2. Deploy TON Staking V2 Contracts

Core staking infrastructure:
- **TON**: ERC20 token (18 decimals)
- **WTON**: Wrapped TON (27 decimals, RAY scale: 1 TON = 1e9 WTON)
- **CoinageFactory**: Factory for creating per-layer2 coinage tokens
- **Layer2Registry**: Registry of valid Layer2 contracts
- **SeigManager**: Seigniorage distribution manager
- **DepositManager**: Handles deposits and withdrawals
- **Layer2Manager**: Manages Layer2 registrations

### 3. Deploy TON Staking V3 Contracts

V3-specific contracts:
- **RAT (Random Attention Test)**: Probabilistic validator attention mechanism
- **ValidatorReward**: Distributes rewards to validators
- **L1BridgeRegistry**: Maps rollup configs to bridge types

### 4. Deploy DAO and Candidate Contracts

- **DAOCommittee**: Governance contract
- **CandidateFactory**: Factory for creating candidate contracts
- **CandidateAddOnFactory**: Factory for creating CandidateAddOn (Layer2) contracts

### 5. Initialize Contracts Using vm.store()

Since offline mode prevents function calls, we use `vm.store()` to directly write storage:

#### DisputeGameFactory Initialization
```solidity
// Slot 52: RAT address
vm.store(disputeGameFactory, bytes32(uint256(52)), bytes32(uint256(uint160(ratProxy))));

// Slot 103: SystemConfig address
vm.store(disputeGameFactory, bytes32(uint256(103)), bytes32(uint256(uint160(systemConfig))));

// InitBond for game type 0
bytes32 initBondSlot = keccak256(abi.encode(uint32(0), uint256(1)));
vm.store(disputeGameFactory, initBondSlot, bytes32(DISPUTE_GAME_INIT_BOND));
```

#### RAT Initialization
```solidity
// Slot 356: ratTriggerProbability (1e27 = 100%)
vm.store(ratProxy, bytes32(uint256(356)), bytes32(RAT_TRIGGER_PROBABILITY));

// Slot 357: minimumCollateral
vm.store(ratProxy, bytes32(uint256(357)), bytes32(minimumCollateral));

// Slot 358: minimumThreshold
vm.store(ratProxy, bytes32(uint256(358)), bytes32(RAT_MINIMUM_THRESHOLD));

// Slot 359: evidenceSubmissionPeriod
vm.store(ratProxy, bytes32(uint256(359)), bytes32(RAT_EVIDENCE_PERIOD));

// Slot 360: l1BridgeRegistry
vm.store(ratProxy, bytes32(uint256(360)), bytes32(uint256(uint160(l1BridgeRegistryProxy))));

// Slot 361: relaxedValidatorCheck (true)
vm.store(ratProxy, bytes32(uint256(361)), bytes32(uint256(1)));

// Slot 363: treasury
vm.store(ratProxy, bytes32(uint256(363)), bytes32(uint256(uint160(deployer))));
```

#### L1BridgeRegistry Initialization
```solidity
// Slot 9: rollupConfigWithDisputeGameFactory[disputeGameFactory] = systemConfig
bytes32 dgfMappingSlot = keccak256(abi.encode(disputeGameFactory, uint256(9)));
vm.store(l1BridgeRegistryProxy, dgfMappingSlot, bytes32(uint256(uint160(systemConfig))));

// Slot 8: disputeGameFactory[systemConfig] = true
bytes32 disputeGameFactoryMappingSlot = keccak256(abi.encode(systemConfig, uint256(8)));
vm.store(l1BridgeRegistryProxy, disputeGameFactoryMappingSlot, bytes32(uint256(1)));

// Slot 4: rollupInfo[systemConfig]
bytes32 rollupInfoBase = keccak256(abi.encode(systemConfig, uint256(4)));
vm.store(l1BridgeRegistryProxy, rollupInfoBase, bytes32(uint256(3))); // TYPE 3
vm.store(l1BridgeRegistryProxy, bytes32(uint256(rollupInfoBase) + 1), bytes32(uint256(uint160(ton))));
```

### 6. Layer2 Registration (Using Actual Function Calls)

**Approach**: Call actual contract functions instead of vm.store()

#### L1BridgeRegistry Registration

```solidity
function _registerSystemConfigInL1BridgeRegistry() internal {
    // Step 1: Grant deployer manager role (deployer is already admin)
    L1BridgeRegistryV1_2(l1BridgeRegistryProxy).addManager(msg.sender);

    // Step 2: Call registerRollupConfigByManager (requires manager role)
    L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfigByManager(
        systemConfig,     // rollupConfig (SystemConfig)
        3,                // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
        ton,              // l2TON address
        "DevnetOptimism"  // name
    );
}
```

#### Layer2 (CandidateAddOn) Registration

```solidity
function _registerLayer2() internal {
    // Step 1: Calculate operator deposit amount
    uint256 D_sequencer = MAX_CHALLENGERS * MAX_FRAUD_PROOF_COST + SEQUENCER_ADDITIONAL_REWARD;
    uint256 operatorDeposit = max(D_sequencer, seigManagerMinimum) + 0.1e27;

    // Step 2: Mint and approve WTON
    MockWTON(wton).mint(msg.sender, operatorDeposit);
    MockWTON(wton).approve(layer2ManagerProxy, operatorDeposit);

    // Step 3: Call registerCandidateAddOn to create Layer2 and OperatorManager
    Layer2ManagerV1_1(layer2ManagerProxy).registerCandidateAddOn(
        systemConfig,     // rollupConfig (SystemConfig)
        operatorDeposit,  // operator deposit amount
        false,            // flagTon (false = use WTON)
        "DevnetOptimism"  // name
    );

    // This creates:
    // - OperatorManager contract (via OperatorManagerFactory)
    // - CandidateAddOn (Layer2) contract (via DAO)
    // - Initial operator deposit to Layer2
}
```

**Benefits**:
- Creates actual CandidateAddOn contracts
- Operators have real deposits
- Layer2Registry and Layer2Manager mappings are properly set
- Validators can deposit to the Layer2

### 7. Mint Test Tokens

For each test account (DEPLOYER, VALIDATOR, PROPOSER, CHALLENGER):
```solidity
MockTON(ton).mint(account, 100000 * 1e18);  // 100,000 TON
MockWTON(wton).mint(account, 100000 * RAY); // 100,000 WTON
```

## Test Flow

### With Genesis-Created Layer2

Genesis now creates actual Layer2 contracts, so tests can use them directly:

1. **Start system**: `StartTONStakingSystem()` loads genesis
   - L1BridgeRegistry already has SystemConfig registered (via `registerRollupConfigByManager()`)
   - Layer2 (CandidateAddOn) already created (via `registerCandidateAddOn()`)
   - Operator already has initial deposit

2. **Get Layer2 address**: Call `Layer2Manager.getLayer2BySystemConfig(systemConfig)`

3. **Mint WTON to validator**: `WTON.mint(validator, amount)`

4. **Approve WTON**: `WTON.approve(depositManager, amount)`

5. **Deposit to Layer2**: `DepositManager.deposit(layer2, amount)`

6. **Register validator with RAT**: `RAT.registerValidator(systemConfig)`

7. **Create DisputeGame**: Triggers RAT attention test

### Key Considerations

- **WTON uses 27 decimals**: 1 TON = 1e9 WTON in RAY scale
- **Coinage rounding**: When depositing, actual staked amount may be slightly less due to share calculation. Add 1% buffer.
- **Minimum collateral**: RAT requires minimum collateral = slashingPenalty + validatorBuffer (default: ~200,000 WTON RAY)

## File Outputs

- **Genesis file**: `.devnet/genesis-l1-staking-v3.json`
- **Addresses file**: `.devnet/addresses.json`
- **Allocs file**: `.devnet/allocs-l1-staking-v3.json`

## Resolved Issues

1. ✅ **Layer2 Creation**: Now calls actual `registerCandidateAddOn()` to create real CandidateAddOn contracts
2. ✅ **Validator deposits**: With real Layer2, validators can deposit and register
3. ✅ **L1BridgeRegistry**: Uses `registerRollupConfigByManager()` with proper manager role
4. ✅ **RAT triggering**: Validators now have valid collateral from Layer2 deposits

## Implementation Notes

The current approach uses actual function calls in offline mode:

1. **L1BridgeRegistry Registration**: Calls `addManager()` and `registerRollupConfigByManager()` directly
2. **Layer2 Creation**: Calls `registerCandidateAddOn()` which:
   - Creates OperatorManager contract via OperatorManagerFactory
   - Creates CandidateAddOn (Layer2) contract via DAO
   - Registers in Layer2Manager and Layer2Registry
   - Makes initial operator deposit

This provides a complete setup where:
- All contracts are properly initialized
- Layer2 is real and functional
- Validators can deposit and participate in RAT
- Tests can immediately start using the system

## References

- Deployment Script: `script/DeployV3FullForDevnet.s.sol`
- Test Helpers: `op-e2e/faultproofs/rat_challenge_helpers.go`
- RAT Contract: `src/validator/RAT.sol`
- Layer2Manager: `src/layer2/Layer2ManagerV1_1.sol`
