---
id: 07_rat_implementation
slug: /07_rat_implementation
---
# RAT Implementation Design

## 1. Overview

This document designs a RAT (Randomized Attention Test) system for TON Staking V3, referencing Optimism's RAT implementation.

> **Note**: The original Optimism RAT code is located at `tokamak-network/optimism/packages/contracts-bedrock/src/L1/RAT.sol`.

### 1.1 Optimism RAT vs TON V3 RAT Comparison

| Item | Optimism RAT | TON V3 RAT |
|------|-------------|------------|
| **Staking Asset** | ETH (native) | WTON (ERC20) |
| **Collateral Management** | Directly held in RAT contract | **Delegated staking via DepositManager** |
| **Trigger Timing** | Dispute Game creation | Dispute Game creation |
| **Trigger Entity** | DisputeGameFactory | DisputeGameFactory |
| **Validator Scope** | Global (all games) | **Per-L2 registration** |
| **Evidence Format** | left/right child hash of stateRoot | TBD (needs confirmation) |
| **Slashing Method** | perTestBondAmount pre-deduction | **Full collateral pre-deduction** (whitepaper: full collateral) |
| **Slashing Attribution** | Remains in contract | **Attributed to RAT contract** |
| **Reward System** | None (bond return only) | Seigniorage distribution (α_v/n) |
| **Collateral Seigniorage** | None | **Attributed to RAT contract** (paid to validator upon withdrawal) |

### 1.2 Per-L2 Validator Registration Method

In TON V3, since multiple L2s exist, validators can **register only for specific L2s**.

```
Validator A ──┬──→ Titan SystemConfig registration (collateral 5,000 WTON)
              └──→ Thanos SystemConfig registration (collateral 3,000 WTON)

Validator B ──────→ Titan SystemConfig only (collateral 10,000 WTON)

Validator C ──────→ Thanos SystemConfig only (collateral 2,000 WTON)
```

**Advantages:**
- Validators can choose only L2s they are interested in
- Different collateral amounts can be set per L2
- Per-L2 reward distribution possible

### 1.3 Key Structure: Using SystemConfig

The **SystemConfig contract address** is used as the key to identify L2s.

```solidity
// Optimism SystemConfig: Contract managing L2 network settings
// - Manages batcher, gas limit, fee scalars, etc.
// - Each L2 has a unique SystemConfig address

// Key structure
(validator, systemConfig) → ValidatorRegistration
(systemConfig, batchIndex) → AttentionTest
// Note: AttentionTest occurs when DisputeGame is created in Optimism L2
```

**Reasons for using SystemConfig:**
1. **Uniqueness**: Each L2 has a unique SystemConfig address
2. **Verifiable**: Can verify if SystemConfig is valid via Layer2Manager
3. **Optimism Compatible**: Maintains consistency with Optimism architecture
4. **Extensible**: Can utilize other SystemConfig information (batcher, etc.) in the future

---

## 2. Architecture

### 2.1 Contract Structure

```
contracts/
└── validator/
    ├── RAT.sol                    # Main RAT contract
    ├── RATStorage.sol             # Storage layout
    └── interfaces/
        └── IRAT.sol               # Interface
```

### 2.2 System Integration

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DisputeGameFactory (Optimism L2)                   │
│  (Triggers RAT when DisputeGame is created)                          │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ triggerAttentionTest()
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                              RAT.sol                                 │
│                                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │ Validator   │  │ Attention   │  │ Slashing    │                  │
│  │ Registry    │  │ Tests       │  │ Logic       │                  │
│  └─────────────┘  └─────────────┘  └─────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
        │                   │
        │                   │ (Reward distribution)
        │                   │
        ▼                   ▼
┌───────────────┐  ┌──────────────────────────────────────────────┐
│ DepositManager│  │  SeigManager → Layer2Manager → OperatorManager │
│ (Delegated    │  │  → RAT.distributeReward()                     │
│  Staking)     │  └──────────────────────────────────────────────┘
└───────────────┘
```

### 2.3 RAT Delegated Staking Flow

```
Validator Registration:
┌──────────┐     WTON      ┌──────────┐    deposit()    ┌────────────────┐
│ Validator│ ──────────► │   RAT    │ ──────────────► │ DepositManager │
└──────────┘               └──────────┘                 │ (Deposited in │
                                                          │  RAT's name)  │
                                                          └────────────────┘
                                                                 │
                                                                 │ Staking in RAT's name
                                                                 │ (to protect validator collateral)
                                                                 ▼
RAT Trigger/Recovery/Slashing (Internal records only):
┌──────────────────────────────────────────────────────────────────────┐
│  When RAT is triggered:                                             │
│    - Internal record: depositedAmount = 0                            │
│    - DepositManager: No change (staking in RAT's name maintained)   │
│                                                                      │
│  When evidence is submitted/challenge won:                            │
│    - Internal record: depositedAmount restored                       │
│    - DepositManager: No change                                       │
│                                                                      │
│  When unresponsive (slashing):                                       │
│    - Internal record: depositedAmount = 0 maintained                 │
│    - DepositManager: No change (continues staking in RAT's name)     │
│    - Validator cannot withdraw → Automatically attributed to RAT    │
└──────────────────────────────────────────────────────────────────────┘
```

**Core Design:**
- All RAT operations only change internal records (`depositedAmount`)
- No DepositManager interaction (only during registration/withdrawal)
- When unresponsive: No separate function needed, automatically slashed since validator cannot withdraw

---

## 3. Data Structures

### 3.1 Per-SystemConfig Validator Registration (ValidatorRegistration)

```solidity
/// @notice Per-SystemConfig validator registration information
/// @dev Key: keccak256(abi.encodePacked(validator, systemConfig))
/// @dev depositedAmount: Amount delegated by RAT to DepositManager for staking
struct ValidatorRegistration {
    // Slot 1: 32 bytes
    uint256 depositedAmount;        // Amount deposited by RAT on behalf (staked in DepositManager)

    // Slot 2: 32 bytes
    uint256 slashingPenalties;      // Amount forfeited when RAT is triggered (principal+seigniorage, for recovery upon evidence submission)

    // Slot 3: 32 bytes
    uint256 pendingRewards;         // Unclaimed validator rewards from this SystemConfig(L2)

    // Slot 4: 32 bytes
    uint256 coinageFactorAtDeposit; // Coinage factor at deposit time (for seigniorage calculation)

    // Slot 5: 17 bytes (packed)
    uint64 slashingTriggeredBlock;  // Block where RAT was triggered (for evidence submission period check)
    uint32 validatorIndex;          // Index in activeValidators array
    bool isActive;                  // Active status
}
```

**Reasons for delegated staking design:**
- If validators stake directly, they can unstake arbitrarily → Collateral role lost
- If RAT stakes on behalf, validators cannot withdraw → Collateral protected
- Since staking is in RAT's name, seigniorage is received by RAT → Paid to validator upon withdrawal

> **Note:** Staking in RAT's name does not contribute to L2 eligibility condition (S_i ≥ θ·B_i). S_i only includes staking in sequencer (operator)'s name.

### 3.2 Per-SystemConfig Validator Pool (ValidatorPool)

```solidity
/// @notice Per-SystemConfig validator pool information
/// @dev Key: systemConfig address
struct ValidatorPool {
    // Slot 1: 32 bytes
    uint256 totalPrincipal;         // Total staking principal for this L2

    // Slot 2: 4 bytes
    uint32 activeValidatorCount;    // Active validator count for this L2
}
```

### 3.3 AttentionTest (RAT Test Information)

**Trigger Timing**: Occurs when DisputeGame is created in Optimism L2. When DisputeGameFactory creates a game, RAT.triggerAttentionTest() is called and AttentionTest is created.

```solidity
/// @notice RAT challenge information struct
/// @dev Key: keccak256(abi.encodePacked(systemConfig, batchIndex))
/// @dev Occurs when DisputeGame is created (when DisputeGameFactory.create() is called)
/// @dev Pre-deduction-recovery mechanism: slashed field unnecessary (already deducted when triggered)
struct AttentionTest {
    // Slot 1: 32 bytes
    bytes32 expectedHash;           // Batch hash to verify (TBD: specific format needs confirmation)

    // Slot 2: 32 bytes (packed)
    uint96 bondAmount;              // Amount recorded for recovery (full collateral)
    address validatorAddress;       // Selected validator address (20 bytes)

    // Slot 3: 32 bytes (packed)
    address systemConfig;           // L2 SystemConfig address (20 bytes)
    uint64 blockNumber;             // Block where RAT was issued (8 bytes)
    bool evidenceSubmitted;         // Evidence submission status (1 byte)
    // slashed field removed: separate slashing unnecessary with pre-deduction mechanism
}
```

### 3.4 Storage Layout

```solidity
// ============================================
// Per-SystemConfig Validator Registration
// ============================================

/// @notice (validator, systemConfig) → Registration information
/// @dev registrationId = keccak256(abi.encodePacked(validator, systemConfig))
mapping(bytes32 => ValidatorRegistration) public registrations;

/// @notice systemConfig → Validator pool information
mapping(address => ValidatorPool) public validatorPools;

/// @notice systemConfig → Active validator array (index 0 is dummy)
mapping(address => address[]) public activeValidators;

/// @notice validator → List of registered SystemConfigs
mapping(address => address[]) public validatorSystemConfigs;

/// @notice (validator, systemConfig) → Registration status (prevents duplicates)
mapping(address => mapping(address => bool)) public isRegistered;


// ============================================
// RAT Tests
// ============================================

/// @notice testId → RAT test information
/// @dev testId = keccak256(abi.encodePacked(systemConfig, batchIndex))
mapping(bytes32 => AttentionTest) public attentionTests;

/// @notice game address → testId mapping (used in resolveClaim)
mapping(address => bytes32) public gameToTestId;
```

### 3.5 Optimism vs TON V3 Storage Comparison

| Optimism | TON V3 | Description |
|----------|--------|-------------|
| `challengers[addr]` | `registrations[hash]` | Composite key (validator, systemConfig) |
| `attentionTests[game]` | `attentionTests[testId]` | Composite key (systemConfig, batchIndex) |
| - | `gameToTestId[game]` | Game address → testId mapping (for resolveClaim) |
| `validChallengers[]` | `activeValidators[systemConfig][]` | Per-SystemConfig active validator array |
| - | `validatorPools[systemConfig]` | Per-SystemConfig pool information |
| - | `validatorSystemConfigs[addr]` | List of SystemConfigs registered by validator |
| - | `operatorManagerOf[systemConfig]` | SystemConfig → OperatorManager mapping |

---

## 4. RATStorage.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title RATStorage
/// @notice Storage layout for RAT contract (per-SystemConfig validator registration method)
/// @dev Layer2Manager identifies L2s using SystemConfig (rollup config)
/// @dev Collateral is delegated staking via DepositManager
abstract contract RATStorage {
    // ============================================
    // Struct Definitions
    // ============================================

    /// @notice Per-SystemConfig validator registration information
    /// @dev depositedAmount: Amount delegated by RAT to DepositManager for staking
    struct ValidatorRegistration {
        uint256 depositedAmount;        // Amount deposited by RAT on behalf (staked in DepositManager)
        uint256 slashingPenalties;      // Amount forfeited when RAT is triggered (principal+seigniorage, for recovery upon evidence submission)
        uint256 pendingRewards;         // Unclaimed validator rewards from this SystemConfig(L2)
        uint256 coinageFactorAtDeposit; // Coinage factor at deposit time (for seigniorage calculation)
        uint64 slashingTriggeredBlock;  // Block where RAT was triggered (for evidence submission period check)
        uint32 validatorIndex;          // Index in activeValidators array
        bool isActive;                  // Active status
    }

    /// @notice Per-SystemConfig validator pool information
    struct ValidatorPool {
        uint256 totalPrincipal;         // Total staking principal for this L2
        uint32 activeValidatorCount;    // Active validator count for this L2
    }

    /// @notice RAT test information
    /// @dev Pre-deduction-recovery mechanism: slashed field unnecessary (already deducted when triggered)
    struct AttentionTest {
        bytes32 expectedHash;           // Batch hash to verify
        uint96 bondAmount;              // Amount recorded for recovery (full collateral)
        address validatorAddress;       // Selected validator address
        address systemConfig;           // L2 SystemConfig address
        uint64 blockNumber;             // Block where RAT was issued
        bool evidenceSubmitted;         // Evidence submission status
        // slashed field removed
    }

    /// @notice Accumulated slashing penalty amount
    /// @dev Increases when RAT is triggered, decreases when evidence is submitted/challenge won
    uint256 public totalSlashingPenalties;

    // ============================================
    // Per-SystemConfig Validator Registration
    // ============================================

    /// @notice (validator, systemConfig) → Registration information
    /// @dev registrationId = keccak256(abi.encodePacked(validator, systemConfig))
    mapping(bytes32 => ValidatorRegistration) public registrations;

    /// @notice systemConfig → Validator pool information
    mapping(address => ValidatorPool) public validatorPools;

    /// @notice systemConfig → Active validator array (index 0 is dummy)
    mapping(address => address[]) public activeValidators;

    /// @notice validator → List of registered SystemConfigs
    mapping(address => address[]) public validatorSystemConfigs;

    /// @notice (validator, systemConfig) → Registration status (prevents duplicate registration)
    mapping(address => mapping(address => bool)) public isRegistered;

    /// @notice SystemConfig → OperatorManager mapping
    /// @dev For verification when OperatorManager calls distributeReward
    mapping(address => address) public operatorManagerOf;

    /// @notice L1BridgeRegistry address (for SystemConfig validity verification)
    address public l1BridgeRegistry;

    // ============================================
    // RAT Tests
    // ============================================

    /// @notice testId → RAT test information
    /// @dev testId = keccak256(abi.encodePacked(systemConfig, batchIndex))
    mapping(bytes32 => AttentionTest) public attentionTests;

    /// @notice game address → testId mapping (used in resolveClaim)
    /// @dev Query RAT test for that game using FaultDisputeGame address
    mapping(address => bytes32) public gameToTestId;

    // ============================================
    // Parameters
    // ============================================

    /// @notice Evidence submission period (block count)
    uint256 public evidenceSubmissionPeriod;

    /// @notice Whitepaper formula (5) parameters: D_validator ≥ (c_m · N) / π_a
    uint256 public ratResponseCost;          // c_m: Single RAT response cost
    uint256 public batchCount;               // N: Number of batches to verify

    /// @notice RAT trigger probability (0-100,000)
    /// @dev 100,000 = 100%
    uint256 public ratTriggerProbability;

    /// @notice Maximum probability constant
    uint256 internal constant MAX_PROBABILITY = 100_000;

    // Note: perTestBondAmount removed - uses full collateral in pre-deduction mechanism (whitepaper: full collateral)

    // ============================================
    // External Contract References
    // ============================================

    /// @notice Layer2Manager address (for SystemConfig verification and trigger authorization)
    address public layer2Manager;

    /// @notice WTON token address
    address public wton;

    /// @notice DAO treasury address (slashing attribution)
    address public dao;

    /// @notice SeigManager address (reward distribution)
    address public seigManager;

    /// @notice RAT manager address (parameter adjustment authorization)
    address public ratManager;

    // ============================================
    // Utility Functions
    // ============================================

    /// @notice Calculate registrationId
    function _getRegistrationId(address validator, address systemConfig) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(validator, systemConfig));
    }

    /// @notice Calculate testId
    function _getTestId(address systemConfig, uint32 batchIndex) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(systemConfig, batchIndex));
    }

    /// @notice Query SystemConfig → Layer2 address (used when emitting events)
    /// @dev Query mapping information from Layer2Manager
    function _getLayer2FromSystemConfig(address systemConfig) internal view returns (address) {
        return ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    }

    /// @notice Storage gap (for upgrade compatibility)
    uint256[40] private __gap;
}

/// @notice Layer2Manager interface (for SystemConfig → Layer2 query)
interface ILayer2Manager {
    function getLayer2BySystemConfig(address systemConfig) external view returns (address);
}

/// @notice L1BridgeRegistry interface (for SystemConfig validity verification)
interface IL1BridgeRegistry {
    function checkL1Bridge(address rollupConfig) external view returns (bool valid, address l1Bridge, address portal, address l2Ton);
}

/// @notice SeigManager interface (for coinage factor query)
interface ISeigManager {
    function getCoinage(address layer2) external view returns (RefactorCoinageSnapshotI);
}

/// @notice Coinage interface (for factor query)
interface RefactorCoinageSnapshotI {
    function factor() external view returns (uint256);
}
```

---

## 5. IRAT.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title IRAT
/// @notice RAT (Randomized Attention Test) interface - per-L2 validator registration method
interface IRAT {
    // ============================================
    // Structs
    // ============================================

    /// @notice Per-SystemConfig validator registration information
    struct ValidatorRegistration {
        uint256 depositedAmount;
        uint256 slashingPenalties;
        uint256 pendingRewards;
        uint256 coinageFactorAtDeposit;
        uint64 slashingTriggeredBlock;
        uint32 validatorIndex;
        bool isActive;
    }

    /// @notice Per-SystemConfig validator pool information
    struct ValidatorPool {
        uint256 totalPrincipal;
        uint32 activeValidatorCount;
    }

    /// @notice RAT test information
    /// @dev Pre-deduction-recovery mechanism: slashed field unnecessary
    struct AttentionTest {
        bytes32 expectedHash;
        uint96 bondAmount;          // Amount recorded for recovery (full collateral)
        address validatorAddress;
        address systemConfig;
        uint64 blockNumber;
        bool evidenceSubmitted;
        // slashed field removed
    }

    // ============================================
    // Events
    // ============================================
    // Note: All events include layer2 address (queried from Layer2Manager using systemConfig)

    /// @notice Validator registration event for SystemConfig(L2)
    event ValidatorRegistered(
        address indexed validator,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate address
        uint256 amount
    );

    /// @notice Validator unregistration event from SystemConfig(L2)
    event ValidatorUnregistered(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate address
        uint256 returnedAmount
    );

    /// @notice Additional staking event for SystemConfig(L2)
    event StakeAdded(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate address
        uint256 amount
    );

    /// @notice RAT test trigger event
    event AttentionTriggered(
        bytes32 indexed testId,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate address
        address validator,
        uint32 batchIndex
    );

    /// @notice Evidence submission success event
    event EvidenceSubmitted(
        bytes32 indexed testId,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate address
        address validator,
        uint256 restoredAmount
    );

    /// @notice Bond recovery event upon challenge victory (resolveClaim)
    event BondRefunded(
        bytes32 indexed testId,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate address
        address validator,
        uint256 restoredAmount
    );

    /// @notice Validator slashing event
    event ValidatorSlashed(
        bytes32 indexed testId,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate address
        address validator,
        uint256 slashedAmount
    );

    /// @notice Per-SystemConfig reward distribution event
    event RewardDistributed(
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate address
        uint256 totalAmount
    );

    /// @notice Reward claim event
    event RewardClaimed(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate address
        uint256 amount
    );

    /// @notice Withdrawal request event
    event UnstakeRequested(
        address indexed validator,
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice Withdrawal processing completion event
    event UnstakeProcessed(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate address
        uint256 totalWithdrawn,        // Principal + seigniorage
        uint256 seigniorage            // Seigniorage amount
    );

    // ============================================
    // Errors
    // ============================================

    error NotLayer2Manager();
    error NotSeigManager();
    error NotRatManager();
    error InvalidSystemConfig();
    error AlreadyRegistered();
    error NotRegistered();
    error ValidatorNotActive();
    error InsufficientDepositedAmount();
    error NoActiveValidators();
    error TestNotExists();
    error NotSelectedValidator();
    error EvidenceAlreadySubmitted();
    error EvidenceSubmissionExpired();
    error ProofVerificationFailed();
    error AlreadySlashed();
    error DeadlineNotPassed();
    error NoRewardsToClaim();

    // ============================================
    // Per-SystemConfig Validator Management Functions
    // ============================================

    /// @notice Register validator for SystemConfig(L2)
    /// @param systemConfig SystemConfig address of L2 to register
    /// @param amount WTON amount to stake
    function registerValidator(address systemConfig, uint256 amount) external;

    /// @notice Unregister validator from SystemConfig(L2) (returns collateral + rewards)
    /// @param systemConfig SystemConfig address of L2 to unregister
    function unregisterValidator(address systemConfig) external;

    /// @notice Query per-SystemConfig validator registration information
    /// @param validator Validator address
    /// @param systemConfig SystemConfig address of L2
    function getRegistration(address validator, address systemConfig)
        external view returns (ValidatorRegistration memory);

    /// @notice Query validator pool information for SystemConfig
    /// @param systemConfig SystemConfig address of L2
    function getValidatorPool(address systemConfig)
        external view returns (ValidatorPool memory);

    /// @notice Query active validator count for SystemConfig
    /// @param systemConfig SystemConfig address of L2
    function getActiveValidatorCount(address systemConfig) external view returns (uint256);

    /// @notice Query list of SystemConfigs registered by validator
    /// @param validator Validator address
    function getValidatorSystemConfigs(address validator) external view returns (address[] memory);

    // ============================================
    // RAT Test Functions
    // ============================================

    /// @notice RAT test trigger (Layer2Manager only)
    /// @dev Selects only from validators registered for this SystemConfig
    /// @param systemConfig SystemConfig address of L2
    /// @param batchIndex Batch index
    /// @param batchHash Batch hash
    /// @param blockHash Block hash (for validator random selection)
    function triggerAttentionTest(
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice Submit evidence - recover full collateral
    /// @param systemConfig SystemConfig address of L2
    /// @param batchIndex Batch index
    /// @param proofData Evidence data
    function submitEvidence(
        address systemConfig,
        uint32 batchIndex,
        bytes calldata proofData
    ) external;

    /// @notice Called when FaultDisputeGame resolves (recovers collateral when challenger wins)
    /// @param _claimant Address that won the game (challenger)
    /// @dev msg.sender = FaultDisputeGame address
    function resolveClaim(address _claimant) external;

    /// @notice Query RAT test information
    function getAttentionTest(bytes32 testId) external view returns (AttentionTest memory);

    // ============================================
    // Reward Functions
    // ============================================

    /// @notice Validator reward distribution (OperatorManager only)
    /// @dev Called after OperatorManager.receiveL2Seigniorage() calculates validator share (α_v · Seig_i)
    /// @param systemConfig SystemConfig address of L2
    /// @param amount Validator share (α_v · Seig_i)
    function distributeReward(address systemConfig, uint256 amount) external;

    /// @notice Claim rewards per SystemConfig
    /// @param systemConfig SystemConfig address of L2
    function claimRewards(address systemConfig) external;

    /// @notice Query unclaimed rewards per SystemConfig
    /// @param validator Validator address
    /// @param systemConfig SystemConfig address of L2
    function getPendingRewards(address validator, address systemConfig) external view returns (uint256);

    /// @notice Batch claim rewards from all SystemConfigs for validator
    function claimAllRewards() external;

    // ============================================
    // Parameter Management Functions
    // ============================================

    // setPerTestBondAmount removed: uses full collateral in pre-deduction mechanism

    /// @notice Set evidence submission period
    function setEvidenceSubmissionPeriod(uint256 period) external;

    /// @notice Set RAT response cost (c_m)
    function setRatResponseCost(uint256 cost) external;

    /// @notice Set number of batches to verify (N)
    function setBatchCount(uint256 count) external;

    /// @notice Set RAT trigger probability (π_a)
    function setRatTriggerProbability(uint256 probability) external;

    /// @notice Query minimum collateral (whitepaper formula 5)
    function getMinimumCollateral() external view returns (uint256);
}
```

---

## 6. RAT.sol (Core Functions)

> **Note**: The full implementation code will be written in a separate file. Here, only SystemConfig-based core functions are explained.

### 6.1 Per-SystemConfig Validator Registration

```solidity
/// @notice Register validator for SystemConfig(L2)
/// @dev RAT delegates staking to DepositManager
/// @param systemConfig SystemConfig address of L2 to register
/// @param amount WTON amount to stake
function registerValidator(address systemConfig, uint256 amount) external nonReentrant {
    // Verify SystemConfig validity via L1BridgeRegistry
    (bool valid,,) = IL1BridgeRegistry(l1BridgeRegistry).checkL1Bridge(systemConfig);
    if (!valid) revert InvalidSystemConfig();

    // Check if already registered for this SystemConfig
    if (isRegistered[msg.sender][systemConfig]) {
        // Check if slashing is finalized (slashingPenalties > 0 AND evidence submission period passed)
        bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
        ValidatorRegistration storage existingReg = registrations[regId];

        bool isSlashingFinalized = existingReg.slashingPenalties > 0
            && block.number > existingReg.slashingTriggeredBlock + evidenceSubmissionPeriod;

        if (!isSlashingFinalized) revert AlreadyRegistered();

        // If slashing is finalized, allow re-registration after resetting existing registration
        isRegistered[msg.sender][systemConfig] = false;
    }

    // Check minimum staking amount
    require(amount >= getMinimumCollateral(), "Below minimum");

    // Transfer WTON (approval required beforehand)
    IERC20(wton).transferFrom(msg.sender, address(this), amount);

    // ★ RAT delegates staking to DepositManager
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    IERC20(wton).approve(depositManager, amount);
    IDepositManager(depositManager).deposit(layer2, address(this), amount);

    // Store coinage factor at deposit time (for seigniorage calculation)
    RefactorCoinageSnapshotI coinage = ISeigManager(seigManager).getCoinage(layer2);
    uint256 currentFactor = coinage.factor();

    // Generate registrationId
    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);

    // Store registration information
    registrations[regId] = ValidatorRegistration({
        depositedAmount: amount,        // Amount deposited by RAT on behalf
        pendingRewards: 0,
        coinageFactorAtDeposit: currentFactor,  // Store factor at deposit time
        validatorIndex: uint32(activeValidators[systemConfig].length),
        isActive: true
    });

    // Update mappings
    isRegistered[msg.sender][systemConfig] = true;
    validatorSystemConfigs[msg.sender].push(systemConfig);

    // Add to pool
    if (activeValidators[systemConfig].length == 0) {
        activeValidators[systemConfig].push(address(0)); // Dummy
    }
    activeValidators[systemConfig].push(msg.sender);

    // Update pool information
    validatorPools[systemConfig].totalPrincipal += amount;
    validatorPools[systemConfig].activeValidatorCount++;

    emit ValidatorRegistered(msg.sender, systemConfig, layer2, amount);
}
```

### 6.2 RAT Test Trigger (Pre-deduction Mechanism)

```solidity
/// @notice RAT test trigger - only changes internal records (collateral remains staked in RAT's name)
/// @dev Selects only from validators registered for this SystemConfig
/// @dev Collateral continues to be staked in RAT's name in DepositManager
function triggerAttentionTest(
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external onlyAuthorizedTrigger {
    // Verify SystemConfig validity via L1BridgeRegistry
    (bool valid,,) = IL1BridgeRegistry(l1BridgeRegistry).checkL1Bridge(systemConfig);
    if (!valid) revert InvalidSystemConfig();

    // Probability check
    if (!_shouldTriggerRAT()) return;

    // Check active validators for this SystemConfig
    address[] storage validators = activeValidators[systemConfig];
    uint256 validatorCount = validators.length;
    if (validatorCount <= 1) return; // Return if 0 validators excluding dummy

    // Random validator selection (only from this SystemConfig pool)
    uint256 selectedIndex = validatorCount == 2
        ? 1
        : ((uint256(keccak256(abi.encodePacked(blockHash, block.timestamp))) & 0xFFFF)
            % (validatorCount - 1)) + 1;

    address selectedValidator = validators[selectedIndex];
    bytes32 regId = _getRegistrationId(selectedValidator, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];
    address layer2 = _getLayer2FromSystemConfig(systemConfig);

    // ★ Calculate principal + seigniorage (based on current factor)
    uint256 principal = reg.depositedAmount;
    RefactorCoinageSnapshotI coinage = ISeigManager(seigManager).getCoinage(layer2);
    uint256 currentFactor = coinage.factor();
    uint256 depositFactor = reg.coinageFactorAtDeposit;

    uint256 slashAmount = principal;
    if (currentFactor > depositFactor && depositFactor > 0) {
        // Principal + seigniorage = principal * (current factor / deposit factor)
        slashAmount = (principal * currentFactor) / depositFactor;
    }

    // ★ Change internal records (depositedAmount maintained, withdrawal blocked via slashingPenalties)
    reg.slashingPenalties = slashAmount;  // Store amount for recovery (withdrawal blocked if this value exists)
    reg.slashingTriggeredBlock = uint64(block.number);  // For evidence submission period check

    // Accumulate slashing penalty
    totalSlashingPenalties += slashAmount;

    // Deactivate validator (isRegistered maintained - prevents re-registration during evidence submission period)
    reg.isActive = false;
    validatorPools[systemConfig].activeValidatorCount--;
    validatorPools[systemConfig].totalPrincipal -= principal;
    _removeFromActiveValidators(systemConfig, selectedValidator, reg.validatorIndex);

    // Generate test ID (systemConfig + batchIndex)
    bytes32 testId = _getTestId(systemConfig, batchIndex);

    // Store RAT test
    attentionTests[testId] = AttentionTest({
        expectedHash: batchHash,
        bondAmount: uint96(slashAmount),  // Record amount for recovery (principal+seigniorage)
        validatorAddress: selectedValidator,
        systemConfig: systemConfig,
        blockNumber: uint64(block.number),
        evidenceSubmitted: false
    });

    emit AttentionTriggered(testId, systemConfig, layer2, selectedValidator, batchIndex);
}
```

### 6.3 Evidence Submission (Recovery Mechanism)

```solidity
/// @notice Submit evidence - recover internal records (no DepositManager interaction)
/// @dev Collateral is already staked in RAT's name, so only recover internal records
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata proofData
) external {
    bytes32 testId = _getTestId(systemConfig, batchIndex);
    AttentionTest storage test = attentionTests[testId];

    // Verification
    if (test.validatorAddress == address(0)) revert TestNotExists();
    if (test.validatorAddress != msg.sender) revert NotSelectedValidator();
    if (test.evidenceSubmitted) revert EvidenceAlreadySubmitted();

    uint256 deadline = test.blockNumber + evidenceSubmissionPeriod;
    if (block.number > deadline) revert EvidenceSubmissionExpired();

    // Evidence verification (TBD: specific verification logic needs confirmation)
    // Currently compares hash of proofData with expectedHash, but more sophisticated verification may be needed in actual implementation
    if (keccak256(proofData) != test.expectedHash) revert ProofVerificationFailed();

    // ★ Recover internal records (no DepositManager interaction)
    test.evidenceSubmitted = true;

    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    uint256 restoredAmount = reg.slashingPenalties;

    // Deduct slashing penalty
    totalSlashingPenalties -= restoredAmount;

    // Recover validator records (depositedAmount is maintained)
    reg.slashingPenalties = 0;  // Unblock withdrawal

    // Reset coinageFactorAtDeposit with current factor
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    RefactorCoinageSnapshotI coinage = ISeigManager(seigManager).getCoinage(layer2);
    reg.coinageFactorAtDeposit = coinage.factor();

    // Reactivate validator (isRegistered is maintained)
    reg.isActive = true;
    reg.validatorIndex = uint32(activeValidators[systemConfig].length);
    activeValidators[systemConfig].push(msg.sender);
    validatorPools[systemConfig].activeValidatorCount++;
    validatorPools[systemConfig].totalPrincipal += reg.depositedAmount;

    emit EvidenceSubmitted(testId, systemConfig, layer2, msg.sender, restoredAmount);
}
```

### 6.4 Handling Unresponsiveness

**No separate slashing function needed** - Since staking amount is already pre-deducted at RAT trigger time, slashing is automatically completed when unresponsive.

```
Unresponsive state:
- validator.depositedAmount = 0 (already deducted)
- validator.isActive = false (already deactivated)
- Collateral = attributed to RAT contract
- Additional transaction = none
```

### 6.5 Collateral Recovery upon Challenge Victory (resolveClaim)

When a validator discovers incorrect evidence from the proposer and **wins as a challenger in FaultDisputeGame**, the game contract calls `resolveClaim` to recover the collateral.

> **Note**: Implemented referencing Optimism RAT.sol's `resolveClaim` function (Lines 322-354)

```solidity
/// @notice Called when FaultDisputeGame resolves (recovers collateral when challenger wins)
/// @dev msg.sender = FaultDisputeGame address
/// @dev Collateral is already staked in RAT's name, so only recover internal records
/// @param _claimant Address that won the game (challenger)
function resolveClaim(address _claimant) external {
    // Query test using msg.sender = game address
    bytes32 testId = gameToTestId[msg.sender];
    if (testId == bytes32(0)) return;  // No RAT test for this game

    AttentionTest storage test = attentionTests[testId];

    // Verify that selected validator matches game winner
    if (test.validatorAddress != _claimant) return;
    if (test.evidenceSubmitted) return;  // Already processed

    // ★ Only recover internal records (no DepositManager interaction)
    test.evidenceSubmitted = true;

    bytes32 regId = _getRegistrationId(_claimant, test.systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    uint256 restoredAmount = reg.slashingPenalties;

    // Deduct slashing penalty
    totalSlashingPenalties -= restoredAmount;

    // Recover validator records (depositedAmount is maintained)
    reg.slashingPenalties = 0;  // Unblock withdrawal

    // Reset coinageFactorAtDeposit with current factor
    address layer2 = _getLayer2FromSystemConfig(test.systemConfig);
    RefactorCoinageSnapshotI coinage = ISeigManager(seigManager).getCoinage(layer2);
    reg.coinageFactorAtDeposit = coinage.factor();

    // Reactivate validator (isRegistered is maintained)
    reg.isActive = true;
    reg.validatorIndex = uint32(activeValidators[test.systemConfig].length);
    activeValidators[test.systemConfig].push(_claimant);
    validatorPools[test.systemConfig].activeValidatorCount++;
    validatorPools[test.systemConfig].totalPrincipal += reg.depositedAmount;

    emit BondRefunded(testId, test.systemConfig, layer2, _claimant, restoredAmount);
}
```

**Called from FaultDisputeGame (Optimism pattern):**

```solidity
// FaultDisputeGame.sol (Optimism)
function resolveClaimRat(address claimant) internal {
    if (rat != address(0)) {
        try IRAT(rat).resolveClaim(claimant) { } catch { }
    }
}

// Called after bond distribution in resolveClaim() function
function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) external {
    // ... game resolution logic ...
    _distributeBond(winner, subgameRootClaim);
    resolveClaimRat(winner);  // RAT callback
}
```

**Collateral Recovery Path Comparison:**

| Path | Trigger | Result |
|------|--------|--------|
| **submitEvidence** | Validator directly submits evidence | Collateral recovery + reactivation |
| **resolveClaim** | Challenge victory in FaultDisputeGame | Collateral recovery + reactivation |
| **Unresponsive** | Response window passed | Permanent collateral forfeiture |

**Required Storage Addition:**

```solidity
/// @notice Game address → testId mapping (used in resolveClaim)
mapping(address => bytes32) public gameToTestId;
```

**Mapping Setup in triggerAttentionTest:**

```solidity
function triggerAttentionTest(...) external onlyLayer2Manager {
    // ... existing logic ...

    // Store game address → testId mapping (for resolveClaim query)
    gameToTestId[gameAddress] = testId;

    // ...
}
```

**Forfeited Fund Tracking:**
- If `AttentionTriggered` occurs but no `EvidenceSubmitted` or `BondRefunded` event → Permanent forfeiture
- If `AttentionTriggered` occurs and either of the above events occurs → Recovered

### 6.6 Validator Reward Distribution (OperatorManager → RAT)

**Distribution Flow:**
```
┌─────────────────────────────────────────────────────────────────────┐
│  1. SeigManager.updateSeigniorage()                                 │
│     - Calculate L2 seigniorage: Seig_i = y(x) · (B̃_i / x)         │
│     - Call Layer2Manager.transferL2Seigniorage(layer2, Seig_i)     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  2. Layer2Manager.transferL2Seigniorage(layer2, Seig_i)            │
│     - Transfer WTON to OperatorManager                             │
│     - Call OperatorManager.receiveL2Seigniorage(Seig_i)            │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  3. OperatorManager.receiveL2Seigniorage(Seig_i)                   │
│     - Calculate validator share: α_v · Seig_i                       │
│     - Transfer WTON to RAT contract                                 │
│     - Call RAT.distributeReward(systemConfig, α_v · Seig_i)        │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  4. RAT.distributeReward(systemConfig, amount)                      │
│     - amount = α_v · Seig_i                                         │
│     - Per validator: amount / n (n = active validator count)        │
│     - Accumulate in each validator's pendingRewards                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  5. Validator calls claimRewards(systemConfig)                      │
│     - Transfer pendingRewards as WTON                               │
└─────────────────────────────────────────────────────────────────────┘
```

```solidity
/// @notice Validator reward distribution (called from OperatorManager)
/// @dev Called after OperatorManager.receiveL2Seigniorage() calculates validator share
/// @param systemConfig SystemConfig address of L2
/// @param amount Validator share (α_v · Seig_i)
/// @dev Whitepaper formula (13): v_i = (α_v/n) · Seig_i
///      Here amount = α_v · Seig_i, each validator receives amount / n
function distributeReward(address systemConfig, uint256 amount) external {
    // Only callable from OperatorManager
    require(msg.sender == operatorManagerOf[systemConfig], "not operator manager");

    ValidatorPool storage pool = validatorPools[systemConfig];
    require(pool.activeValidatorCount > 0, "no active validators");

    // Equal distribution per validator: v_i = amount / n
    // amount = α_v · Seig_i (already calculated in OperatorManager)
    uint256 perValidator = amount / pool.activeValidatorCount;

    // Accumulate rewards for each active validator of this SystemConfig
    address[] storage validators = activeValidators[systemConfig];
    for (uint256 i = 1; i < validators.length; i++) {
        address validator = validators[i];
        bytes32 regId = _getRegistrationId(validator, systemConfig);
        if (registrations[regId].isActive) {
            registrations[regId].pendingRewards += perValidator;
        }
    }

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit RewardDistributed(systemConfig, layer2, amount);
}
```

**Distribution Example:**
```
L2 seigniorage: Seig_i = 1000 WTON
Validator distribution ratio: α_v = 20%
Active validator count: n = 5

1. OperatorManager.receiveL2Seigniorage(1000):
   - Validator share = 1000 × 20% = 200 WTON
   - Call RAT.distributeReward(systemConfig, 200)

2. RAT.distributeReward(systemConfig, 200):
   - Per validator = 200 / 5 = 40 WTON
   - Accumulate 40 WTON in each validator's pendingRewards
```

### 6.7 Collateral Withdrawal (Seigniorage Calculation Based on Coinage Factor)

```solidity
/// @notice Per-validator withdrawal request information
struct WithdrawalRequest {
    uint256 amount;             // Withdrawal request amount (principal + seigniorage)
    uint256 principal;          // Principal (for events)
    uint256 requestBlock;       // Request block
    bool pending;               // Pending processing status
}

/// @notice (validator, systemConfig) → Withdrawal request information
mapping(bytes32 => WithdrawalRequest) public withdrawalRequests;

/// @notice Request collateral withdrawal (only possible when inactive, full withdrawal only)
/// @dev RAT requests withdrawal from DepositManager, completed via processUnstake after 2 weeks
/// @dev Partial withdrawal not allowed: always withdraws entire depositedAmount
/// @param systemConfig SystemConfig address of L2
function requestUnstake(address systemConfig) external nonReentrant {
    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    require(!reg.isActive, "still active");
    require(reg.depositedAmount > 0, "no balance to withdraw");

    // Handle slashing state
    if (reg.slashingPenalties > 0) {
        // Cannot withdraw during evidence submission period
        require(
            block.number > reg.slashingTriggeredBlock + evidenceSubmissionPeriod,
            "evidence period not ended"
        );

        // Slashing finalized: forfeit entire collateral, reset state
        reg.slashingPenalties = 0;
        reg.slashingTriggeredBlock = 0;
        reg.depositedAmount = 0;
        isRegistered[msg.sender][systemConfig] = false;

        revert("fully slashed, no balance");
    }

    // Cannot withdraw during evidence submission period (also check if deactivated without slashing)
    if (reg.slashingTriggeredBlock > 0) {
        require(
            block.number > reg.slashingTriggeredBlock + evidenceSubmissionPeriod,
            "evidence period not ended"
        );
        // If period passed but slashingPenalties == 0, evidence submission was successful
        reg.slashingTriggeredBlock = 0;
    }

    WithdrawalRequest storage req = withdrawalRequests[regId];
    require(!req.pending, "withdrawal already pending");

    address layer2 = _getLayer2FromSystemConfig(systemConfig);

    // Calculate withdrawal amount using factor comparison (principal + seigniorage)
    // Coinage automatically calculates seigniorage via factor increase
    // Withdrawal amount = principal * (currentFactor / depositFactor)
    RefactorCoinageSnapshotI coinage = ISeigManager(seigManager).getCoinage(layer2);
    uint256 currentFactor = coinage.factor();
    uint256 depositFactor = reg.coinageFactorAtDeposit;

    uint256 principal = reg.depositedAmount;
    uint256 withdrawAmount = principal;
    if (currentFactor > depositFactor && depositFactor > 0) {
        withdrawAmount = (principal * currentFactor) / depositFactor;
    }

    // Deduct internal records
    reg.depositedAmount = 0;
    reg.coinageFactorAtDeposit = 0;

    // RAT requests withdrawal from DepositManager (includes principal + seigniorage)
    IDepositManager(depositManager).requestWithdrawal(layer2, withdrawAmount);

    // Record withdrawal request
    req.amount = withdrawAmount;
    req.principal = principal;  // Record principal (for events)
    req.requestBlock = block.number;
    req.pending = true;

    emit UnstakeRequested(msg.sender, systemConfig, withdrawAmount);
}

/// @notice Process withdrawal request (after 2-week waiting period, called by validator)
/// @dev Validator calls to actually withdraw from DepositManager and transfer to validator
/// @param systemConfig SystemConfig address of L2
function processUnstake(address systemConfig) external nonReentrant {
    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    WithdrawalRequest storage req = withdrawalRequests[regId];

    require(req.pending, "no pending withdrawal");
    // Note: Waiting period check is performed in DepositManager.processRequest

    address layer2 = _getLayer2FromSystemConfig(systemConfig);

    // Actually process withdrawal from DepositManager
    // requestUnstake already requested principal+seigniorage amount
    uint256 beforeBalance = IERC20(wton).balanceOf(address(this));
    IDepositManager(depositManager).processRequest(layer2, false);
    uint256 afterBalance = IERC20(wton).balanceOf(address(this));

    uint256 withdrawn = afterBalance - beforeBalance;
    require(withdrawn >= req.amount, "insufficient withdrawal");

    // Complete withdrawal request processing
    uint256 principal = req.principal;
    uint256 seigniorage = req.amount - principal;
    req.pending = false;
    req.amount = 0;
    req.principal = 0;

    // Transfer to validator (principal + seigniorage)
    IERC20(wton).transfer(msg.sender, withdrawn);

    emit UnstakeProcessed(msg.sender, systemConfig, layer2, withdrawn, seigniorage);
}
```

**Seigniorage Calculation Example:**
```
Deposit time: factor = 1.0e27, amount = 10,000 WTON
Withdrawal time: factor = 1.1e27 (10% increase)

Seigniorage = 10,000 × (1.1e27 - 1.0e27) / 1.0e27
         = 10,000 × 0.1
         = 1,000 WTON

Total withdrawable amount = 10,000 + 1,000 = 11,000 WTON
```

### 6.8 OperatorManager Management

```solidity
/// @notice Set OperatorManager for SystemConfig (Layer2Manager only)
/// @dev SystemConfig validity verified via L1BridgeRegistry
/// @param systemConfig SystemConfig address of L2
/// @param operatorManager OperatorManager address for this SystemConfig
function setOperatorManager(address systemConfig, address operatorManager) external onlyLayer2Manager {
    // Verify SystemConfig validity via L1BridgeRegistry
    (bool valid,,) = IL1BridgeRegistry(l1BridgeRegistry).checkL1Bridge(systemConfig);
    if (!valid) revert InvalidSystemConfig();

    operatorManagerOf[systemConfig] = operatorManager;

    // Reserve index 0 as dummy element (when first setting)
    if (activeValidators[systemConfig].length == 0) {
        activeValidators[systemConfig].push(address(0));
    }

    emit OperatorManagerSet(systemConfig, operatorManager);
}

/// @notice Remove validator from per-SystemConfig activeValidators array
function _removeFromActiveValidators(
    address systemConfig,
    address validator,
    uint256 index
) internal {
    address[] storage validators = activeValidators[systemConfig];
    if (index > 0 && index < validators.length && validators[index] == validator) {
        uint256 lastIndex = validators.length - 1;
        if (index != lastIndex) {
            address lastValidator = validators[lastIndex];
            validators[index] = lastValidator;
            bytes32 regId = _getRegistrationId(lastValidator, systemConfig);
            registrations[regId].validatorIndex = uint32(index);
        }
        validators.pop();
    }
}
```

---

## 7. Key Differences from Optimism RAT

### 7.1 Validator Scope

| Optimism | TON V3 |
|----------|--------|
| Global validator pool | **Per-SystemConfig validator pool** |
| `challengers[addr]` | `registrations[hash(validator, systemConfig)]` |

```solidity
// Optimism: Global validators
validChallengers[]  // Same pool for all games

// TON V3: Per-SystemConfig validators
activeValidators[systemConfig][]  // Separate pool per L2
```

### 7.2 Asset Type

| Optimism | TON V3 |
|----------|--------|
| ETH (msg.value) | WTON (ERC20 transferFrom) |

### 7.3 Slashing Handling

| Optimism | TON V3 |
|----------|--------|
| perTestBondAmount pre-deduction | **Full collateral pre-deduction** (whitepaper: full collateral) |
| Bond remains in contract | Attributed to RAT contract |
| implicit slashing | **Automatic slashing** (no separate function needed) |

### 7.4 Reward System

| Optimism | TON V3 |
|----------|--------|
| No rewards | Per-SystemConfig seigniorage distribution (α_v/n) |

### 7.5 Trigger Timing

| Optimism | TON V3 |
|----------|--------|
| Dispute Game creation | Dispute Game creation |

---

## 8. Integration Guide

### 8.1 RAT Trigger Timing and Interface

RAT is triggered when the L2 proposer (sequencer) **creates a DisputeGame**.

```
┌─────────────────────────────────────────────────────────────┐
│  L2 Proposer (op-proposer)                                  │
│                                                              │
│  1. Calculate Output Root                                    │
│  2. Call DisputeGameFactory.create()                         │
│     └─→ Call RAT.triggerAttentionTest()                      │
└─────────────────────────────────────────────────────────────┘
```

**RAT Trigger Interface for L2 Proposer:**

```solidity
/// @title IRATTrigger
/// @notice Interface that L2 proposer must call to trigger RAT
interface IRATTrigger {
    /// @notice Trigger RAT test
    /// @dev Called when DisputeGame is created
    /// @param systemConfig SystemConfig address of L2 (L2 identifier)
    /// @param batchIndex Batch/game index
    /// @param batchHash Batch hash or Output Root
    /// @param blockHash Block hash (for validator random selection)
    function triggerAttentionTest(
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;
}
```

### 8.2 DisputeGameFactory Integration

```solidity
// DisputeGameFactory.sol modification example
contract DisputeGameFactory {
    address public rat;  // RAT contract address

    function create(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external returns (IDisputeGame proxy_) {
        // Existing Dispute Game creation logic...
        proxy_ = _createGame(_gameType, _rootClaim, _extraData);

        // Trigger RAT (game creation succeeds even if RAT trigger fails)
        if (rat != address(0)) {
            address systemConfig = _getSystemConfig(); // SystemConfig for this L2
            try IRAT(rat).triggerAttentionTest(
                systemConfig,
                uint32(gameCount),     // batchIndex
                _rootClaim.raw(),      // batchHash (Output Root)
                blockhash(block.number - 1)  // blockHash
            ) {} catch {}
        }
    }
}
```

### 8.3 TRH (Tokamak Rollup Hub) Guidelines

1. **Require RAT Trigger on DisputeGame Creation**
   - All L2 proposers must call RAT.triggerAttentionTest() when creating DisputeGame
   - Use SystemConfig address as key to select from that L2's validator pool

2. **SystemConfig Registration Requirement**
   - Register SystemConfig with Layer2Manager when onboarding L2
   - Only registered SystemConfigs are valid in RAT

3. **Trigger Failure Handling**
   - DisputeGame creation must succeed even if RAT trigger fails (try-catch)
   - RAT does not occur if no validators or probability not met

### 8.4 Layer2Manager Modification

```solidity
// Layer2ManagerV1_2.sol

import { IRAT } from "../validator/interfaces/IRAT.sol";

contract Layer2ManagerV1_2 {
    address public rat;

    function setRAT(address _rat) external onlyOwner {
        rat = _rat;
    }

    /// @notice Set OperatorManager in RAT when registering new L2
    function registerL2(address systemConfig, ...) external {
        // ... existing L2 registration logic ...

        // Set OperatorManager in RAT
        if (rat != address(0)) {
            address operatorManager = operatorInfo[rollupConfigInfo[systemConfig].operatorManager].operatorManager;
            IRAT(rat).setOperatorManager(systemConfig, operatorManager);
        }
    }
}
```

### 8.5 SeigManagerV1_4 Modification

```solidity
// Add to SeigManagerV1_4.sol

function updateSeigniorage() external {
    // ... existing seigniorage calculation logic ...

    // V3 seigniorage distribution (per SystemConfig)
    uint256 validatorPoolAmount = rmul(v3Seigniorage, validatorDistributionRatio);

    if (validatorPoolAmount > 0 && rat != address(0)) {
        // Mint WTON and transfer to RAT contract
        IWTON(wton).mint(rat, validatorPoolAmount);

        // Distribute rewards per SystemConfig
        // (In actual implementation, distribute proportionally to each L2's active validator count)
        IRAT(rat).distributePeriodRewards(systemConfig, currentPeriod, amountForThisL2);
    }
}
```

---

## 9. Deployment Parameters

| Parameter | Whitepaper Specified | Description |
|---------|----------|------|
| `evidenceSubmissionPeriod` | ❌ | Evidence submission period (block count) |
| `ratResponseCost` | ✅ (c_m) | Single RAT response cost |
| `batchCount` | ✅ (N) | Number of batches to verify |
| `ratTriggerProbability` | ✅ (π_a) | RAT occurrence probability |

**Minimum collateral is dynamically calculated using whitepaper formula (5):**
```solidity
/// @notice Calculate minimum collateral (whitepaper formula 5)
/// @dev D_validator ≥ (c_m · N) / π_a
function getMinimumCollateral() public view returns (uint256) {
    return (ratResponseCost * batchCount * MAX_PROBABILITY) / ratTriggerProbability;
}
```

> **Note**: `perTestBondAmount` parameter is removed - uses full collateral in pre-deduction mechanism (whitepaper: full collateral slashing)

---

## 10. Test Checklist

- [ ] Validator staking/unstaking
- [ ] RAT trigger probability verification
- [ ] Validator random selection distribution
- [ ] Verify full staking amount pre-deduction when RAT is triggered
- [ ] Verify collateral recovery upon successful evidence submission
- [ ] Evidence submission failure (period exceeded) - verify slashing completed without separate transaction
- [ ] Verify forfeited funds attributed to RAT contract
- [ ] Reward distribution and claiming
- [ ] Parameter change authorization
- [ ] Upgrade compatibility
- [ ] Event-based fund tracking (AttentionTriggered/EvidenceSubmitted)
