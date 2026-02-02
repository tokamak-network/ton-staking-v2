---
id: 03-contract-structure
sidebar_position: 3
---
# TON Staking V3 Contract Structure

## 1. Directory Structure

```
src/
├── stake/                              # Staking related
│   ├── managers/
│   │   ├── SeigManagerV1_2.sol                # V1.2 implementation (base proxy impl)
│   │   ├── SeigManagerV3_1.sol                # V3.1 implementation (V3 core) 🆕
│   │   ├── SeigManagerV3_2.sol                # V3.2 implementation (V2 compat layer) 🆕
│   │   ├── SeigManagerStorage.sol             # Base storage
│   │   ├── SeigManagerV1_1Storage.sol         # V1.1 storage
│   │   ├── SeigManagerV1_3Storage.sol         # V1.3 storage
│   │   ├── SeigManagerV1_4Storage.sol         # V1.4 storage (V3) 🆕
│   │   ├── SeigManagerProxy.sol               # Proxy
│   │   │
│   │   ├── DepositManagerV3.sol               # V3 implementation (V3 callbacks) 🆕
│   │   ├── DepositManagerStorage.sol          # Base storage
│   │   ├── DepositManagerV1_1Storage.sol      # V1.1 storage
│   │   └── DepositManagerProxy.sol            # Proxy
│   │
│   ├── tokens/                            # 코이니지 토큰
│   │   ├── RefactorCoinageSnapshot.sol        # 코이니지 구현체
│   │   ├── RefactorCoinageSnapshotProxy.sol   # 프록시
│   │   ├── RefactorCoinageSnapshotStorage.sol # 스토리지
│   │   ├── AutoRefactorCoinage.sol            # 자동 리팩터 코이니지
│   │   ├── AutoRefactorCoinageProxy.sol       # 프록시
│   │   └── AutoRefactorCoinageStorage.sol     # 스토리지
│   │
│   ├── factory/                           # 팩토리
│   │   ├── CoinageFactory.sol                 # 코이니지 생성 팩토리
│   │   └── AutoRefactorCoinageFactory.sol     # 자동 리팩터 코이니지 팩토리
│   │
│   ├── Layer2Registry.sol                 # L2 레지스트리 (레거시)
│   ├── Layer2RegistryProxy.sol            # 프록시
│   ├── Layer2RegistryStorage.sol          # 스토리지
│   │
│   └── interfaces/
│       ├── ISeigManager.sol                   # 기본 인터페이스
│       ├── ISeigManagerV3.sol                 # V3 인터페이스 🆕
│       ├── IDepositManager.sol                # DepositManager 인터페이스
│       ├── ITON.sol                           # TON 인터페이스
│       ├── IWTON.sol                          # WTON 인터페이스
│       ├── IOnApprove.sol                     # approveAndCall 콜백
│       └── IAutoCoinageSnapshot.sol           # 코이니지 스냅샷
│
├── layer2/                             # L2 management
│   ├── Layer2ManagerV3.sol                    # L2 manager (V3) 🆕
│   ├── Layer2ManagerStorage.sol               # Base storage
│   ├── Layer2ManagerV1_2Storage.sol           # V1.2 storage (used in V3) 🆕
│   ├── Layer2ManagerProxy.sol                 # Proxy
│   │
│   ├── L1BridgeRegistryV1_2.sol               # Bridge registry (TYPE 3) 🆕
│   ├── L1BridgeRegistryStorage.sol            # Base storage
│   ├── L1BridgeRegistryV1_2Storage.sol        # V1.2 storage 🆕
│   ├── L1BridgeRegistryProxy.sol              # Proxy
│   │
│   ├── OperatorManagerV1_2.sol                # Operator manager (TYPE 3) 🆕
│   ├── OperatorManagerStorage.sol             # Storage
│   ├── OperatorManagerProxy.sol               # Proxy (ERC1967-based)
│   │
│   ├── LegacySystemConfig.sol                 # 레거시 SystemConfig 래퍼
│   ├── LegacySystemConfigProxy.sol            # 프록시
│   ├── LegacySystemConfigStorage.sol          # 스토리지
│   │
│   ├── factory/
│   │   └── OperatorManagerFactory.sol         # 오퍼레이터 팩토리
│   │
│   └── interfaces/
│       ├── ILayer2Manager.sol                 # Layer2Manager 인터페이스
│       ├── IL1BridgeRegistry.sol              # L1BridgeRegistry 인터페이스
│       ├── IOperatorManagerFactory.sol        # 팩토리 인터페이스
│       ├── IOperator.sol                      # 오퍼레이터 인터페이스
│       ├── IOptimismPortal.sol                # OptimismPortal 인터페이스
│       ├── IOptimismSystemConfig.sol          # SystemConfig 인터페이스
│       ├── IRollupConfig.sol                  # RollupConfig 인터페이스
│       ├── IL1Bridge.sol                      # L1Bridge 인터페이스
│       └── IStandardBridge.sol                # StandardBridge 인터페이스
│
├── validator/                          # Validator system (V3 new) 🆕
│   ├── RAT.sol                                # Validator registration/RAT/slashing
│   ├── RATStorage.sol                         # Storage
│   ├── RATProxy.sol                           # Proxy (TransparentUpgradeableProxy)
│   ├── RATTypes.sol                           # Type definitions 🆕
│   ├── IRAT.sol                               # Interface
│   │
│   ├── ValidatorRewardV1.sol                  # Validator reward distribution
│   ├── ValidatorRewardStorage.sol             # Storage
│   ├── ValidatorRewardProxy.sol               # Proxy (TransparentUpgradeableProxy)
│   └── IValidatorReward.sol                   # Interface
│
│
├── dao/                                # DAO/거버넌스
│   ├── DAOCommittee_V1.sol                    # DAO 커미티 구현체
│   ├── DAOCommitteeOwner.sol                  # Owner 권한 관리
│   ├── StorageStateCommittee.sol              # 스토리지
│   ├── StorageStateCommitteeV2.sol            # V2 스토리지
│   │
│   ├── Candidate.sol                          # 후보자 컨트랙트
│   ├── CandidateProxy.sol                     # 프록시
│   ├── CandidateStorage.sol                   # 스토리지
│   │
│   ├── CandidateAddOnV1_1.sol                 # 후보자 애드온 (V1.1)
│   ├── CandidateAddOnProxy.sol                # 프록시
│   ├── CandidateAddOnStorage.sol              # 스토리지
│   ├── CandidateAddOnStorage1.sol             # 추가 스토리지
│   │
│   ├── factory/
│   │   ├── CandidateFactory.sol               # 후보자 팩토리
│   │   ├── CandidateFactoryProxy.sol          # 프록시
│   │   ├── CandidateFactoryStorage.sol        # 스토리지
│   │   ├── CandidateAddOnFactory.sol          # 애드온 팩토리
│   │   ├── CandidateAddOnFactoryProxy.sol     # 프록시
│   │   └── CandidateAddOnFactoryStorage.sol   # 스토리지
│   │
│   ├── lib/
│   │   ├── Agenda.sol                         # 의제 라이브러리
│   │   └── BytesLib.sol                       # 바이트 유틸리티
│   │
│   └── interfaces/
│       ├── ICoinage.sol                       # 코이니지 인터페이스
│       └── ICandidateAddOn.sol                # 애드온 인터페이스
│
├── proxy/                              # 프록시 관련
│   ├── Proxy.sol                              # 기본 프록시 (Selector Routing)
│   ├── ProxyStorage.sol                       # 프록시 스토리지
│   ├── ProxyStorage2.sol                      # 프록시 스토리지 V2
│   ├── ProxySeigManager.sol                   # SeigManager 전용 프록시
│   ├── ProxyLayer2Manager.sol                 # Layer2Manager 전용 프록시
│   ├── ProxyL1BridgeRegistry.sol              # L1BridgeRegistry 전용 프록시
│   ├── ProxyCoinage.sol                       # 코이니지 전용 프록시
│   └── DAOCommitteeProxy2.sol                 # DAO 커미티 프록시
│
├── common/                             # 공통 유틸리티
│   ├── AccessibleCommon.sol                   # 기본 접근 제어
│   ├── AuthRole.sol                           # 역할 정의
│   ├── AuthControlSeigManager.sol             # SeigManager 권한 관리
│   ├── AuthControlCoinage.sol                 # 코이니지 권한 관리
│   ├── AuthControlLayer2Manager.sol           # Layer2Manager 권한 관리
│   └── AuthControlL1BridgeRegistry.sol        # L1BridgeRegistry 권한 관리
│
├── accessControl/                      # OpenZeppelin 접근 제어 (로컬 복사본)
│   ├── AccessControl.sol                      # 접근 제어
│   ├── Context.sol                            # 컨텍스트
│   ├── Address.sol                            # 주소 유틸리티
│   ├── EnumerableSet.sol                      # 열거 가능 집합
│   ├── ERC165A.sol                            # ERC165 인터페이스 감지
│   └── IERC165.sol                            # 인터페이스
│
└── mocks/                              # 테스트용 목업
    ├── MockSystemConfig.sol                   # SystemConfig 목업
    ├── MockSystemConfigFactory.sol            # 팩토리 목업
    └── InvalidCandidateAddOn.sol              # 잘못된 애드온 (테스트용)
```

---

## 2. Core Contract Details

### 2.1 SeigManagerV3_1

The core contract for seigniorage calculation and distribution.

```solidity
contract SeigManagerV3_1 is
    ProxyStorage,              // 프록시 기본 스토리지
    AuthControlSeigManager,    // 권한 관리
    SeigManagerStorage,        // V1 스토리지
    SeigManagerV1_1Storage,    // V1.1 스토리지
    DSMath,                    // RAY 수학 라이브러리
    SeigManagerV1_3Storage,    // V1.3 스토리지
    SeigManagerV1_4Storage,    // V3 스토리지
    ISeigManagerV3             // V3 인터페이스
{
    // ...
}
```

**V3 Core Features**:
- Hyperbolic saturation function (`hyperbolicSaturation`)
- Bridged TON-based seigniorage calculation
- Eligibility condition check (`checkCurrentEligibility`)
- Validator reward distribution

### 2.2 DepositManagerV3

Manages TON/WTON staking.

```solidity
contract DepositManagerV3 is
    ProxyStorage,
    AccessibleCommon,
    DepositManagerStorage,
    DepositManagerV1_1Storage
{
    // ...
}
```

**Core Features**:
- `deposit()`: WTON staking
- `requestWithdrawal()`: Withdrawal request
- `processRequest()`: Withdrawal processing
- `onApprove()`: TON.approveAndCall callback

### 2.3 Layer2ManagerV3

Handles L2 registration and management.

```solidity
contract Layer2ManagerV3 is
    ProxyStorage,
    AccessibleCommon,
    Layer2ManagerStorage,
    Layer2ManagerV1_2Storage
{
    // ...
}
```

**Core Features**:
- `getBridgedTon()`: Query Bridged TON
- `getLayer2BySystemConfig()`: SystemConfig → Layer2 query
- `transferL2Seigniorage(layer2, amount)`: Transfer L2 seigniorage to Operator
  - Caller: SeigManager (`onlySeigManger`)
  - Transfer WTON to L2's Operator (OperatorManager)

### 2.4 L1BridgeRegistryV1_2

Handles bridge/portal registration and TVL queries. **V1_2 includes all functions from V1_1** and provides TYPE 3 (DisputeGame) support and type-specific permission management system.

```solidity
contract L1BridgeRegistryV1_2 is
    ProxyStorage,
    AuthControlL1BridgeRegistry,
    L1BridgeRegistryStorage,
    L1BridgeRegistryV1_2Storage
{
    // V1_1 + V1_2 모든 함수 포함
}
```

**Rollup Types**:
- TYPE 1: Legacy (L1StandardBridge)
- TYPE 2: Optimism Bedrock (OptimismPortal)
- TYPE 3: Optimism Bedrock + DisputeGame (OptimismPortal + DisputeGameFactory) 🆕

**Permission Hierarchy**:
```
Owner (Admin, DEFAULT_ADMIN_ROLE)
├── setAddresses, setSeigniorageCommittee
├── addAdmin, removeAdmin
├── addManager, removeManager
└── Highest authority (system initial setup)

Manager (MANAGER_ROLE, granted by Owner)
├── Can register/upgrade all types
├── setTypeRegistrant (set type-specific registrant)
├── upgradeToType3 (TYPE 1/2 → TYPE 3 upgrade)
├── addRegistrant, removeRegistrant
└── Super authority for L2 registration

SeigniorageCommittee (designated by Owner)
├── rejectCandidateAddOn (stop seigniorage)
└── restoreCandidateAddOn (restore seigniorage)

Registrant (REGISTRANT_ROLE, granted by Manager)
└── registerRollupConfig (TYPE 1, 2, 3 all)

typeRegistrant[n] (designated by Manager, type-specific delegation)
└── registerRollupConfigByType (TYPE n only)
```

**onlyOwner functions**:
- `setAddresses(layer2Manager, seigManager, ton)`: Initial setup
- `setSeigniorageCommittee(addr)`: Set SeigniorageCommittee

**onlySeigniorageCommittee functions**:
- `rejectCandidateAddOn(rollupConfig)`: Stop seigniorage issuance
- `restoreCandidateAddOn(rollupConfig, rejectedL2Deposit)`: Restore seigniorage issuance

**onlyRegistrant functions**:
- `registerRollupConfig(rollupConfig, type, l2TON, name)`: Register rollup

**onlyManager functions**:
- `setTypeRegistrant(type, addr)`: Set type-specific registration authority
- `upgradeToType3(rollupConfig)`: TYPE 1/2 → TYPE 3 upgrade

**onlyTypeRegistrant functions**:
- `registerRollupConfigByType(rollupConfig, type, l2TON, name)`: Type-specific permission check registration

**View functions**:
- `rollupType(rollupConfig)`: Query rollup type
- `l2TON(rollupConfig)`: Query L2 TON address
- `getRollupInfo(rollupConfig)`: Query rollup info
- `isRejectedSeigs(rollupConfig)`: Check if seigniorage stopped
- `isRejectedL2Deposit(rollupConfig)`: Check if L2 deposit stopped
- `layer2Tvl(rollupConfig)`: Query L2 TVL
- `availableForRegistration(rollupConfig, type)`: Check registration availability

**Storage queries**:
- `disputeGameFactory(rollupConfig)`: Check DisputeGameFactory registration
- `rollupConfigWithDisputeGameFactory(factory)`: Reverse query factory → rollupConfig
- `rollupConfigWithPortal(portal)`: Reverse query portal → rollupConfig
- `typeRegistrant(type)`: Query type-specific registration authority

### 2.5 RAT (Randomized Attention Test)

Manages validator registration, RAT tests, and C_off penalties.

```solidity
contract RAT is
    ProxyStorage,
    RATStorage,
    IRAT
{
    // ...
}
```

**Core Features**:
- `registerValidator()`: Register validator
- `triggerAttentionTest()`: Trigger RAT
- `submitEvidence()`: Submit evidence
- `resolveClaim()`: Restore collateral on challenge win
- `deactivateValidator()`: Deactivate validator

### 2.6 ValidatorRewardV1

Handles validator reward distribution. Uses O(1) complexity RewardPerValidator pattern.

```solidity
contract ValidatorRewardV1 is
    ValidatorRewardStorage,
    IValidatorReward
{
    // ...
}
```

**Core Features**:
- `distributeL2Rewards(systemConfig, amount)`: L2-specific validator reward distribution (O(1))
  - Caller: SeigManager (`onlySeigManager`)
  - Call timing: When `updateSeigniorage()` executes, validator distribution ratio (α · S_i) amount
  - Role: Accumulate per-validator reward in `rewardPerValidator[systemConfig]`
  - Distribution formula: `v_j = (α · S_i) / |V_i|` (per-validator reward)
  - No validators: Send reward to `seigManager.dao()`
- `claimAllRewards()`: Synchronize all L2 rewards then claim
- `claimRewardsByL2s(address[])`: Synchronize and claim only specific L2s (gas optimization)
- `registerValidatorToL2()`: Register validator to L2 (called from RAT)
- `syncValidatorReward()`: Synchronize reward before validator deactivation
- `resetValidatorDebt()`: Reset debt on validator reactivation
- `getClaimableRewards()`: Query total claimable rewards (including unsynchronized)

---

## 3. Storage Structure

### 3.1 SeigManagerV1_4Storage

```solidity
contract SeigManagerV1_4Storage {
    // V3 core parameters
    uint256 public daoDistributionRatio;      // d: DAO distribution ratio (RAY)
    uint256 public minStakingRatio;           // θ: Minimum staking ratio (RAY)
    uint256 public validatorDistributionRatio; // α: Validator distribution ratio (RAY)
    uint256 public halfSaturationPoint;       // k: Half saturation point (RAY)

    // V3 state
    bool public v3Migrated;                   // V3 mode activation flag
    uint256 public v3MigrationBlock;          // Migration block

    // V3 reference addresses
    address public validatorReward;           // ValidatorReward contract
    address public ratContract;               // RAT contract

    // Bridged TON tracking
    mapping(address => BridgedTONInfo) public bridgedTONInfo;
    uint256 public totalEffectiveBridgedTON;  // x: Total effective Bridged TON

    struct BridgedTONInfo {
        uint256 currentBridgedTON;    // B_i: Current Bridged TON
        uint256 effectiveBridgedTON;  // B̃_i: Effective Bridged TON (0 if not eligible)
        uint256 initialDebt;          // Initial debt (same as V2 pattern)
        uint256 startBlock;           // Participation start block
        uint256 lastUpdateTime;       // Last update timestamp
        bool isEligible;              // Eligibility status (T_i ≥ θ·B_i)
    }
}
```

### 3.2 RATStorage

```solidity
contract RATStorage {
    // Whitepaper V2 parameters
    uint256 public slashingPenalty;           // C_off: Slashing penalty
    uint256 public validatorBuffer;           // Δ_validator: Additional buffer
    uint256 public ratTriggerProbability;     // π_a: RAT trigger probability (RAY)
    uint256 public minimumThreshold;          // D_min: Minimum collateral threshold
    uint256 public evidenceSubmissionPeriod;  // Evidence submission period (seconds)

    // V3 validator collateral check flexibility
    bool public relaxedValidatorCheck;        // Validator validity check relaxation
                                              // true: C_off based (relaxed), false: D_min based (strict)
                                              // Always need D_min or more for registration

    // ValidatorReward contract address (for O(1) reward distribution)
    address public validatorReward;

    // Validator registration
    mapping(address => mapping(address => ValidatorRegistration))
        public validatorRegistrations;        // systemConfig => validator => registration info
    mapping(address => ValidatorPoolInfo) internal validatorPools;

    // RAT tests
    mapping(bytes32 => AttentionTest) public attentionTests;
    mapping(address => bytes32) public gameToTestId;

    struct ValidatorRegistration {
        uint256 depositedAmount;      // Current valid collateral
        uint256 totalBondForRAT;      // Amount locked for RAT
        uint64 latestTestDeadline;    // Latest test deadline
        uint32 validatorIndex;        // Index
        bool isActive;                // Active status
    }

    struct ValidatorPoolInfo {
        address[] validators;
        uint256 activeCount;
        uint256 totalDeposited;
    }

    struct AttentionTest {
        address validatorAddress;
        address systemConfig;
        uint32 batchIndex;
        bytes32 batchHash;
        uint256 bondAmount;           // C_off
        uint256 createdAt;
        uint256 deadline;
        AttentionTestStatus status;
    }

    enum AttentionTestStatus {
        Pending,
        Responded,
        Slashed,
        Expired
    }
}
```

### 3.3 ValidatorRewardStorage

```solidity
contract ValidatorRewardStorage {
    // ==========================================
    // Reward related
    // ==========================================

    /// @notice Total unclaimed rewards per validator (used in claimAllRewards)
    mapping(address => uint256) public validatorPendingRewards;

    /// @notice L2-specific rewards tracked via ValidatorRewardReceived event
    mapping(address => mapping(address => uint256)) public validatorL2PendingRewards;

    mapping(address => uint256) public l2TotalDistributed;

    // ==========================================
    // RewardPerValidator pattern (O(1) distribution)
    // ==========================================

    /// @notice Accumulated reward per validator per L2 (systemConfig => accumulated)
    /// @dev Updated in O(1) in distributeL2Rewards
    mapping(address => uint256) public rewardPerValidator;

    /// @notice Reward debt per validator per L2 (validator => systemConfig => debt)
    /// @dev Set to current rewardPerValidator on validator registration
    mapping(address => mapping(address => uint256)) public validatorRewardDebt;

    /// @notice List of L2s where validator is registered (validator => systemConfig[])
    /// @dev Used to iterate all L2s in claimAllRewards
    mapping(address => address[]) public validatorL2List;

    /// @notice Validator's L2 registration status (validator => systemConfig => bool)
    /// @dev Prevents duplicate registration
    mapping(address => mapping(address => bool)) public isValidatorInL2;

    // ==========================================
    // Reference addresses
    // ==========================================

    address public seigManager;
    address public wton;
    address public ratContract;
    address public treasury;  // Uses seigManager.dao()
    address public owner;
}
```

**RewardPerValidator Pattern**:

```
Distribution time (distributeL2Rewards):
┌─────────────────────────────────────────────────────────────────┐
│ perValidator = amount / activeCount                              │
│ rewardPerValidator[systemConfig] += perValidator   ← O(1) operation│
└─────────────────────────────────────────────────────────────────┘

Claim time (claimAllRewards):
┌─────────────────────────────────────────────────────────────────┐
│ For each L2:                                                     │
│   earned = rewardPerValidator[systemConfig]                     │
│          - validatorRewardDebt[validator][systemConfig]         │
│   if (active validator):                                         │
│       validatorPendingRewards[validator] += earned              │
│   validatorRewardDebt[validator][systemConfig] = current        │
└─────────────────────────────────────────────────────────────────┘
```

**Gas Cost**:
- `updateSeigniorage`: O(1) complexity (independent of validator count)
- `claimAllRewards`: O(L) complexity (proportional to number of L2s validator is registered to)

---

## 4. Interface Definitions

### 4.1 ISeigManagerV3

```solidity
interface ISeigManagerV3 {
    // V3 query functions
    function checkCurrentEligibility(address layer2)
        external view returns (bool eligible, uint256 requiredStake, uint256 currentStake);
    function getEffectiveBridgedTON(address layer2) external view returns (uint256);
    function getTotalEffectiveBridgedTON() external view returns (uint256);

    // V3 callbacks
    function onBridgedTonChange() external;
    function onStakingChange(address layer2) external;

    // V3 governance
    function migrateToV3() external;

    // Events
    event V3SeigniorageDistributed(
        uint256 totalSeigniorage,
        uint256 l2MaxAllocation,
        uint256 totalDistributed,
        uint256 daoAmount,
        uint256 validatorPoolAmount
    );
    event EligibilityChanged(address indexed layer2, bool eligible, uint256 bridgedTON, uint256 effectiveBridgedTON);
    event V3MigrationCompleted(uint256 blockNumber, uint256 totalMigratedL2s);
}

### 4.2 IRAT

```solidity
interface IRAT {
    // Validator management
    function registerValidator(address systemConfig, uint256 depositAmount) external;
    function deactivateValidator(address systemConfig) external;
    function addDeposit(address systemConfig, uint256 amount) external;

    // RAT operations
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;
    function submitEvidence(address systemConfig, uint32 batchIndex, bytes calldata evidence) external;
    function resolveClaim(address _claimant) external;

    // Queries
    function getL2Validators(address systemConfig) external view returns (address[] memory);
    function isValidatorActive(address validator, address systemConfig) external view returns (bool);
    function getActiveValidatorCount(address systemConfig) external view returns (uint256);
    function getMinimumCollateral() external view returns (uint256);
    function getValidatorMinCollateralForLayer2(address layer2, address validator) external view returns (uint256);

    // Events
    event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId);
    event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline);
    event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex);
    event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet);
}
```

### 4.3 IValidatorReward

```solidity
interface IValidatorReward {
    // ==========================================
    // View Functions
    // ==========================================

    /// @notice Query total unclaimed rewards (synchronized only)
    function getPendingRewards(address validator) external view returns (uint256);

    /// @notice Query unclaimed rewards by L2 (event usage recommended)
    function getPendingRewardsByL2(address validator, address systemConfig) external view returns (uint256);

    /// @notice Calculate total claimable rewards (including unsynchronized rewards)
    function getClaimableRewards(address validator) external view returns (uint256 total);

    // ==========================================
    // External Functions - Rewards
    // ==========================================

    /// @notice Distribute validator rewards by L2 (called from SeigManager)
    function distributeL2Rewards(address systemConfig, uint256 amount) external;

    /// @notice Claim all rewards from all L2s at once
    /// @dev May exceed gas limit if registered to many L2s - use claimRewardsByL2s recommended
    function claimAllRewards() external;

    /// @notice Claim rewards from specific L2s (gas optimization)
    /// @dev Use when registered to many L2s to claim in batches
    function claimRewardsByL2s(address[] calldata systemConfigs) external;

    /// @notice Register validator to L2 (called from RAT)
    function registerValidatorToL2(address validator, address systemConfig) external;

    /// @notice Synchronize validator reward (called before deactivation)
    function syncValidatorReward(address validator, address systemConfig) external;

    /// @notice Reset validator debt on reactivation (called from RAT)
    function resetValidatorDebt(address validator, address systemConfig) external;

    // ==========================================
    // Events
    // ==========================================

    event L2RewardDistributed(
        address indexed systemConfig,
        uint256 totalAmount,
        uint256 activeValidatorCount,
        uint256 perValidator
    );
    event ValidatorRewardReceived(address indexed validator, address indexed systemConfig, uint256 amount);
    event RewardToDAO(address indexed systemConfig, uint256 amount);
    event RewardsClaimed(address indexed validator, uint256 amount);
    event ValidatorRegisteredToL2(address indexed validator, address indexed systemConfig, uint256 initialDebt);
}
```

---

## 5. Inheritance Relationships

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            Inheritance Hierarchy                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  SeigManagerV3_1:                                                               │
│  ┌────────────────┐                                                             │
│  │  ProxyStorage  │                                                             │
│  └───────┬────────┘                                                             │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ AuthControlSeigManager  │                                                    │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴────────────────┐                                                     │
│  │  SeigManagerStorage    │  (V1 fields)                                        │
│  └───────┬────────────────┘                                                     │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ SeigManagerV1_1Storage  │  (V1.1 fields)                                     │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴────────┐                                                             │
│  │    DSMath      │  (RAY math)                                                 │
│  └───────┬────────┘                                                             │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ SeigManagerV1_3Storage  │  (V1.3 fields)                                     │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ SeigManagerV1_4Storage  │  (V3 fields: d, θ, α, k, ...)                      │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴───────────┐                                                          │
│  │  ISeigManagerV3   │  (V3 interface)                                          │
│  └───────────────────┘                                                          │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Related Documents

- [01-system-overview.md](./01-system-overview.md): System Overview
- [02-system-architecture.md](./02-system-architecture.md): System Architecture
- [04-contract-roles.md](./04-contract-roles.md): Contract Roles
- [05-actors.md](./05-actors.md): Actor Definitions
- [06-function-specs.md](./06-function-specs.md): Detailed Function Descriptions
