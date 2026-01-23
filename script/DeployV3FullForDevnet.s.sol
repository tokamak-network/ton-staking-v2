// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Core Infrastructure
import {CoinageFactory} from "../src/stake/factory/CoinageFactory.sol";
import {RefactorCoinageSnapshot} from "../src/stake/tokens/RefactorCoinageSnapshot.sol";
import {RefactorCoinageSnapshotProxy} from "../src/stake/tokens/RefactorCoinageSnapshotProxy.sol";
import {Layer2Registry} from "../src/stake/Layer2Registry.sol";
import {Layer2RegistryProxy} from "../src/stake/Layer2RegistryProxy.sol";

// Manager Implementations - V3
import {SeigManagerV1_2} from "../src/stake/managers/SeigManagerV1_2.sol";
import {SeigManagerV3_1} from "../src/stake/managers/SeigManagerV3_1.sol";
import {SeigManagerV3_2} from "../src/stake/managers/SeigManagerV3_2.sol";
import {DepositManagerV3} from "../src/stake/managers/DepositManagerV3.sol";
import {Layer2ManagerV3} from "../src/layer2/Layer2ManagerV3.sol";
import {L1BridgeRegistryV1_2} from "../src/layer2/L1BridgeRegistryV1_2.sol";

// Manager Proxies
import {SeigManagerProxy} from "../src/stake/managers/SeigManagerProxy.sol";
import {DepositManagerProxy} from "../src/stake/managers/DepositManagerProxy.sol";
import {Layer2ManagerProxy} from "../src/layer2/Layer2ManagerProxy.sol";
import {L1BridgeRegistryProxy} from "../src/layer2/L1BridgeRegistryProxy.sol";

// Operator Manager
import {OperatorManagerFactory} from "../src/layer2/factory/OperatorManagerFactory.sol";
import {OperatorManagerV1_2} from "../src/layer2/OperatorManagerV1_2.sol";

// V3 New Contracts
import {RAT} from "../src/validator/RAT.sol";
import {RATInitParams, RATConfigParams} from "../src/validator/RATTypes.sol";
import {RATProxy} from "../src/validator/RATProxy.sol";
import {ValidatorRewardV1} from "../src/validator/ValidatorRewardV1.sol";
import {ValidatorRewardProxy} from "../src/validator/ValidatorRewardProxy.sol";
import {MockAnchorStateRegistry} from "../src/mocks/MockAnchorStateRegistry.sol";

// DAO Contracts
import {DAOCommitteeProxy2} from "../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../src/dao/DAOCommitteeOwner.sol";
import {Candidate} from "../src/dao/Candidate.sol";
import {CandidateAddOnV1_1} from "../src/dao/CandidateAddOnV1_1.sol";
import {CandidateFactory} from "../src/dao/factory/CandidateFactory.sol";
import {CandidateFactoryProxy} from "../src/dao/factory/CandidateFactoryProxy.sol";
import {CandidateAddOnFactory} from "../src/dao/factory/CandidateAddOnFactory.sol";
import {CandidateAddOnFactoryProxy} from "../src/dao/factory/CandidateAddOnFactoryProxy.sol";

// DAO Storage and AccessControl
import {StorageStateCommittee} from "../src/dao/StorageStateCommittee.sol";
import {AccessControl} from "../src/accessControl/AccessControl.sol";

// Mocks for testing
import {MockTON} from "../src/mocks/MockTON.sol";
import {MockWTON} from "../src/mocks/MockWTON.sol";

// Note: We don't deploy AnchorStateRegistry due to solc version conflict
// Instead, we set OptimismPortal storage directly

/// @notice Proxy interface
interface IProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
}

/// @notice DisputeGameFactory interface for RAT integration
interface IDisputeGameFactory {
    function setRAT(address rat) external;
    function setSystemConfig(address systemConfig) external;
    function setImplementation(uint32 gameType, address impl) external;
    function setInitBond(uint32 gameType, uint256 bond) external;
    function rat() external view returns (address);
}

/// @notice AnchorStateRegistry interface
interface IAnchorStateRegistry {
    function initialize(
        uint256 _disputeGameFinalityDelaySeconds,
        address _disputeGameFactory
    ) external;
    function disputeGameFactory() external view returns (address);
}

/// @notice OptimismPortal2 interface
interface IOptimismPortal2 {
    function initialize(
        address _systemConfig,
        address _anchorStateRegistry,
        address _ethLockbox
    ) external;
    function anchorStateRegistry() external view returns (address);
    function systemConfig() external view returns (address);
}

/// @notice DAOCommitteeProxy2 interface
interface IDAOCommitteeProxy2 {
    function upgradeTo2(address impl) external;
    function setAliveImplementation2(address impl, bool alive) external;
    function setSelectorImplementations2(bytes4[] calldata selectors, address impl) external;
}

/// @notice DAOCommitteeOwner interface
interface IDAOCommitteeOwner {
    function setCandidateFactory(address _candidateFactory) external;
    function setCandidateAddOnFactory(address _candidateAddOnFactory) external;
    function setSeigManager(address _seigManager) external;
    function setLayer2Manager(address _layer2Manager) external;
    function setLayer2Registry(address _layer2Registry) external;
}

/// @notice SeigManager interface for minimum amount
interface ISeigManager {
    function minimumAmount() external view returns (uint256);
}

/// @notice DAOCommittee_V1 interface for creating candidates
interface IDAOCommittee_V1 {
    function createCandidateAddOn(
        address rollupConfig,
        address l2TON,
        string memory name,
        uint256 amount
    ) external returns (address layer2, address operatorMgr);
}

/// @title MockDAOCommitteeProxy
/// @notice Mock DAO Proxy for Devnet Testing
/// @dev Simplified DAO proxy that mimics real DAOCommitteeProxy behavior
contract MockDAOCommitteeProxy is StorageStateCommittee, AccessControl {
    address internal _implementation;
    bool public pauseProxy;

    event Upgraded(address indexed implementation);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _;
    }

    constructor(address _ton) {
        ton = _ton;

        // Grant DEFAULT_ADMIN_ROLE to deployer and proxy itself
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function upgradeTo(address impl) external onlyAdmin {
        require(impl != address(0), "zero address");
        _implementation = impl;
        emit Upgraded(impl);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    fallback() external payable {
        address _impl = _implementation;
        require(_impl != address(0) && !pauseProxy, "proxy disabled");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/**
 * @title DeployV3FullForDevnet
 * @notice Deploys complete TON Staking V3 system for E2E testing with Optimism devnet
 * @dev This script deploys:
 *   - Full TON Staking V3 infrastructure (not mocks)
 *   - RAT with real SeigManager/DepositManager/ValidatorReward
 *   - Connects RAT to Optimism DisputeGameFactory
 *
 * Usage:
 *   forge script script/DeployV3FullForDevnet.s.sol:DeployV3FullForDevnet \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast \
 *     --private-key $DEPLOYER_PRIVATE_KEY
 */
contract DeployV3FullForDevnet is Script {
    // ==========================================
    // Devnet Configuration
    // ==========================================

    // Anvil default accounts
    // NOTE: TON Staking uses DIFFERENT deployer from Optimism
    // - Optimism deployer: Account #0 (0xf39Fd...)
    // - TON Staking deployer: Account #1 (0x70997...)
    // This separation avoids nonce collision between deployments
    address constant OPTIMISM_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Anvil account #0
    address constant DEPLOYER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Anvil account #1
    address constant PROXY_ADMIN = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Anvil account #2
    address constant VALIDATOR = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // Anvil account #3
    address constant PROPOSER = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // Anvil account #4
    address constant CHALLENGER = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc; // Anvil account #5

    // RAY constant (27 decimals)
    uint256 constant RAY = 1e27;

    // ==========================================
    // Deployment Parameters (Devnet-optimized)
    // ==========================================

    // SeigManager parameters
    uint256 constant SEIG_PER_BLOCK = 3.92e18; // 3.92 TON per block
    uint256 constant GLOBAL_WITHDRAWAL_DELAY = 10; // 10 blocks for fast testing

    // RAT parameters (Testing-optimized)
    uint256 constant RAT_TRIGGER_PROBABILITY = RAY; // 100% for testing (always trigger)
    uint256 constant RAT_SLASHING_PENALTY = 10 * RAY; // 10 WTON (slashing penalty)
    uint256 constant RAT_VALIDATOR_BUFFER = 50 * RAY; // 50 WTON (validator buffer)
    uint256 constant RAT_MINIMUM_THRESHOLD = 60 * RAY; // 60 WTON (D_min = slashingPenalty + validatorBuffer)
    uint256 constant RAT_MAX_VALIDATORS_PER_L2 = 100; // Maximum validators per L2
    uint256 constant RAT_CHALLENGE_GAME_DURATION = 7 days; // Challenge game period
    uint256 constant RAT_SAFETY_BUFFER = 1 days; // Safety buffer period
    uint256 constant RAT_ATTENTION_COST = 1e27; // c_m: 1 TON per epoch (RAY unit)
    bool constant RAT_RELAXED_VALIDATOR_CHECK = true; // V3: 초기에는 C_off 기준으로 완화

    // V3 Seigniorage Distribution Parameters
    uint256 constant DAO_DISTRIBUTION_RATIO = 0.2e27; // d: 20% to DAO
    uint256 constant MIN_STAKING_RATIO = 0.1e27; // θ: 10% of Bridged TON
    uint256 constant VALIDATOR_DISTRIBUTION_RATIO = 0.2e27; // α: 20% to validators
    uint256 constant HALF_SATURATION_POINT = 10_000_000e27; // k: 10M TON

    // V3 Sequencer Parameters
    uint256 constant MAX_CHALLENGERS = 10; // H_max: Maximum concurrent challengers
    uint256 constant MAX_FRAUD_PROOF_COST = 1000 * RAY; // C_max: 1000 WTON
    uint256 constant SEQUENCER_ADDITIONAL_REWARD = 100 * RAY; // Δ_sequencer: 100 WTON

    // DisputeGame parameters
    uint256 constant DISPUTE_GAME_INIT_BOND = 0.08 ether; // Init bond for creating games
    uint256 constant RAT_EVIDENCE_PERIOD = 1 hours;

    // ==========================================
    // Deployed Addresses
    // ==========================================

    // Tokens
    address public ton;
    address public wton;

    // Core Infrastructure
    address public coinageFactory;
    address public coinageLogic;
    address public layer2RegistryProxy;
    address public layer2RegistryImpl;

    // Managers (Proxies)
    address public seigManagerProxy;
    address public depositManagerProxy;
    address public layer2ManagerProxy;
    address public l1BridgeRegistryProxy;

    // Manager Implementations - V3
    address public seigManagerV3_1Impl;
    address public seigManagerV3_2Impl;
    address public depositManagerImpl;
    address public layer2ManagerImpl;
    address public l1BridgeRegistryImpl;

    // Operator Manager
    address public operatorManagerFactory;
    address public operatorManagerImpl;

    // V3 Contracts
    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;

    // DAO Contracts
    address public daoCommitteeProxy;
    address public daoCommitteeProxy2;
    address public daoCommitteeV1;
    address public daoCommitteeOwner;
    address public candidateImpl;
    address public candidateAddOnImpl;
    address public candidateFactoryProxy;
    address public candidateAddOnFactoryProxy;
    address public mockLayer2;  // Created Layer2 (CandidateAddOn)
    address public operatorManager; // Created OperatorManager for mockLayer2

    // Optimism Contracts (read from environment)
    address public disputeGameFactory;
    address public systemConfig;
    address public anchorStateRegistry;
    address public optimismPortal;
    address public ethLockbox;

    /// @notice Entry point for generating devnet allocs (without actual broadcast)
    /// @dev This is used to generate genesis allocs file
    function runForDevnetAlloc() external virtual {
        // Load existing L1 allocs (Optimism contracts)
        string memory allocsPath = vm.envOr(
            "TARGET_L1_ALLOC",
            string.concat(vm.projectRoot(), "/.devnet/allocs-l1.json")
        );
        console.log("Loading existing L1 allocs from:", allocsPath);
        vm.loadAllocs(allocsPath);

        // No nonce manipulation needed - different deployers
        console.log("Optimism deployer:", OPTIMISM_DEPLOYER);
        console.log("TON Staking deployer:", DEPLOYER);

        // Run deployment (will modify state in memory, no actual broadcast)
        run();

        // Dump final state to file
        string memory outputPath = vm.envOr(
            "STATE_DUMP_PATH",
            string.concat(vm.projectRoot(), "/.devnet/allocs-l1-staking-v3.json")
        );
        console.log("Dumping state to:", outputPath);
        vm.dumpState(outputPath);
    }

    function run() public virtual {
        _loadOptimismAddresses();
        vm.startBroadcast();
        address deployer = msg.sender;
        _deployTokens();
        _deployCoinageInfrastructure(deployer);
        _deployLayer2Registry(deployer);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(deployer);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(deployer);
        _deployV3Contracts(deployer);
        _deployDAO();
        _setupCrossReferences(deployer);
        _initializeOptimismPortal();
        _connectToOptimism();
        _registerLayer2();
        _mintTestTokens();
        vm.stopBroadcast();
        _printSummary();
        _saveDeployment();
    }

    // ==========================================
    // Step 0: Load Optimism Addresses
    // ==========================================
    function _loadOptimismAddresses() internal {
        console.log("--- Step 0: Load Optimism Addresses ---");

        // Read devnetL1.json using FFI (vm.readFile has permission issues with .devnet folder)
        string[] memory inputs = new string[](2);
        inputs[0] = "cat";
        inputs[1] = ".devnet/devnetL1.json";

        bytes memory result = vm.ffi(inputs);
        string memory json = string(result);
        console.log("Loaded devnetL1.json via FFI");

        // Parse systemConfigProxy address
        systemConfig = vm.parseJsonAddress(json, ".systemConfigProxy");
        console.log("SystemConfig:", systemConfig);

        // Read optimism-addresses.json for DisputeGameFactory and other contracts
        inputs[1] = ".devnet/optimism-addresses.json";
        result = vm.ffi(inputs);
        string memory addressesJson = string(result);

        // Parse DisputeGameFactory address
        try vm.parseJsonAddress(addressesJson, ".DisputeGameFactoryProxy") returns (address _dgf) {
            disputeGameFactory = _dgf;
            console.log("DisputeGameFactory:", disputeGameFactory);
        } catch {
            console.log("Note: DisputeGameFactory not found (optional)");
        }

        // Parse AnchorStateRegistry address
        try vm.parseJsonAddress(addressesJson, ".AnchorStateRegistryProxy") returns (address _asr) {
            anchorStateRegistry = _asr;
            console.log("AnchorStateRegistry:", anchorStateRegistry);
        } catch {
            console.log("Note: AnchorStateRegistry not found (will deploy)");
        }

        // Parse OptimismPortal address
        try vm.parseJsonAddress(addressesJson, ".OptimismPortalProxy") returns (address _op) {
            optimismPortal = _op;
            console.log("OptimismPortal:", optimismPortal);
        } catch {
            console.log("Note: OptimismPortal not found");
        }

        // Parse ETHLockbox address
        try vm.parseJsonAddress(addressesJson, ".ETHLockboxProxy") returns (address _el) {
            ethLockbox = _el;
            console.log("ETHLockbox:", ethLockbox);
        } catch {
            console.log("Note: ETHLockbox not found");
        }

        console.log("");
    }

    // ==========================================
    // Step 1: Deploy Tokens
    // ==========================================
    function _deployTokens() internal {
        console.log("--- Step 1: Deploy Tokens ---");

        // Deploy tokens with CREATE (not CREATE2) to avoid nonce issues
        // Environment variables can override if specific addresses are needed
        address TON_ADDRESS = vm.envOr("TON_ADDRESS", address(0));
        address WTON_ADDRESS = vm.envOr("WTON_ADDRESS", address(0));

        // Check if TON already exists at known address
        if (TON_ADDRESS != address(0) && TON_ADDRESS.code.length > 0) {
            ton = TON_ADDRESS;
            console.log("Using existing TON:", ton);
        } else {
            // Deploy TON using CREATE2 to avoid address collision
            bytes32 salt = bytes32(uint256(1));
            ton = address(new MockTON{salt: salt}());
            console.log("TON deployed at:", ton);
        }

        // Check if WTON already exists
        if (WTON_ADDRESS != address(0) && WTON_ADDRESS.code.length > 0) {
            wton = WTON_ADDRESS;
            console.log("Using existing WTON:", wton);
        } else {
            // Deploy WTON using CREATE2 to avoid address collision
            bytes32 salt = bytes32(uint256(2));
            MockWTON wtonContract = new MockWTON{salt: salt}();
            wtonContract.setTON(ton);
            wton = address(wtonContract);
            console.log("WTON deployed at:", wton);
        }

        console.log("");
    }

    // ==========================================
    // Step 2: Deploy Coinage Infrastructure
    // ==========================================
    function _deployCoinageInfrastructure(address /* deployer */) internal {
        console.log("--- Step 2: Deploy Coinage Infrastructure ---");

        // Use regular CREATE (different deployer = no collision)
        coinageLogic = address(new RefactorCoinageSnapshot());
        console.log("RefactorCoinageSnapshot Logic:", coinageLogic);

        CoinageFactory factory = new CoinageFactory();
        factory.setAutoCoinageLogic(coinageLogic);
        coinageFactory = address(factory);
        console.log("CoinageFactory:", coinageFactory);
        console.log("");
    }

    // ==========================================
    // Step 3: Deploy Layer2Registry
    // ==========================================
    function _deployLayer2Registry(address /* deployer */) internal {
        console.log("--- Step 3: Deploy Layer2Registry ---");

        layer2RegistryImpl = address(new Layer2Registry());
        console.log("Layer2Registry Impl:", layer2RegistryImpl);

        Layer2RegistryProxy registryProxy = new Layer2RegistryProxy();
        IProxy(address(registryProxy)).upgradeTo(layer2RegistryImpl);
        layer2RegistryProxy = address(registryProxy);
        console.log("Layer2Registry Proxy:", layer2RegistryProxy);
        console.log("");
    }

    // ==========================================
    // Step 4: Deploy Manager Proxies
    // ==========================================
    function _deployManagerProxies() internal {
        console.log("--- Step 4: Deploy Manager Proxies ---");

        seigManagerProxy = address(new SeigManagerProxy());
        console.log("SeigManager Proxy:", seigManagerProxy);

        depositManagerProxy = address(new DepositManagerProxy());
        console.log("DepositManager Proxy:", depositManagerProxy);

        layer2ManagerProxy = address(new Layer2ManagerProxy());
        console.log("Layer2Manager Proxy:", layer2ManagerProxy);

        l1BridgeRegistryProxy = address(new L1BridgeRegistryProxy());
        console.log("L1BridgeRegistry Proxy:", l1BridgeRegistryProxy);
        console.log("");
    }

    // ==========================================
    // Step 5: Deploy Manager Implementations
    // ==========================================
    function _deployManagerImplementations() internal {
        console.log("--- Step 5: Deploy Manager Implementations ---");

        // SeigManager: V1_2 기본 + V3_1, V3_2 selector routing
        address seigManagerV1_2Impl = address(new SeigManagerV1_2());
        console.log("SeigManagerV1_2 Impl:", seigManagerV1_2Impl);
        IProxy(seigManagerProxy).upgradeTo(seigManagerV1_2Impl);

        seigManagerV3_1Impl = address(new SeigManagerV3_1());
        console.log("SeigManagerV3_1 Impl:", seigManagerV3_1Impl);

        seigManagerV3_2Impl = address(new SeigManagerV3_2());
        console.log("SeigManagerV3_2 Impl:", seigManagerV3_2Impl);

        // DepositManager: V3 단일 구현체
        depositManagerImpl = address(new DepositManagerV3());
        console.log("DepositManagerV3 Impl:", depositManagerImpl);
        IProxy(depositManagerProxy).upgradeTo(depositManagerImpl);

        // Layer2Manager: V3 단일 구현체
        layer2ManagerImpl = address(new Layer2ManagerV3());
        console.log("Layer2ManagerV3 Impl:", layer2ManagerImpl);
        IProxy(layer2ManagerProxy).upgradeTo(layer2ManagerImpl);

        // L1BridgeRegistry: V1_2 단일 구현체
        l1BridgeRegistryImpl = address(new L1BridgeRegistryV1_2());
        console.log("L1BridgeRegistryV1_2 Impl:", l1BridgeRegistryImpl);
        IProxy(l1BridgeRegistryProxy).upgradeTo(l1BridgeRegistryImpl);
        console.log("");
    }

    // ==========================================
    // Step 6: Initialize Managers
    // ==========================================
    function _initializeManagers(address deployer) internal virtual {
        console.log("--- Step 6: Initialize Managers ---");

        // Initialize SeigManager
        SeigManagerV1_2(seigManagerProxy).initialize(
            ton,
            wton,
            layer2RegistryProxy,
            depositManagerProxy,
            SEIG_PER_BLOCK,
            coinageFactory,
            block.number
        );
        console.log("SeigManager initialized");

        // Set SeigManager data
        SeigManagerV1_2(seigManagerProxy).setData(
            address(0),     // powerTON
            deployer,       // dao
            0,              // powerTONSeigRate: 0%
            0.5e27,         // daoSeigRate: 50%
            0.5e27,         // relativeSeigRate: 50%
            10,             // adjustCommissionDelay (fast for testing)
            1000.1e27       // minimumAmount: 1000.1 WTON
        );
        console.log("SeigManager setData done");

        // Setup SeigManager multi-implementation routing (V3: V1_2 기본 + V3_1, V3_2)
        _setupSeigManagerV3Routing();

        console.log("SeigManager multi-implementation configured");

        // Initialize DepositManager (V3 단일 구현체)
        DepositManagerV3(depositManagerProxy).initialize(
            wton,
            layer2RegistryProxy,
            seigManagerProxy,
            GLOBAL_WITHDRAWAL_DELAY,
            address(0)
        );
        console.log("DepositManager initialized");
        console.log("");
    }

    // ==========================================
    // SeigManager V3 Selector Routing (분리하여 stack too deep 회피)
    // NOTE: 핵심 함수만 등록. 전체 함수 등록은 production 프로필 필요
    // ==========================================
    function _setupSeigManagerV3Routing() internal {
        // V3_1, V3_2를 alive 상태로 설정
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(seigManagerV3_1Impl, true);
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(seigManagerV3_2Impl, true);

        // 핵심 함수만 등록 (stack too deep 회피)
        _setupSeigManagerV3CoreSelectors();

        // V3_1에 v2Logic 주소 설정 (V2 호환성을 위해)
        SeigManagerV3_1(seigManagerProxy).setV2Logic(seigManagerV3_2Impl);
    }

    function _setupSeigManagerV3CoreSelectors() internal {
        // 핵심 함수만 등록 (6개) - 테스트/배포에 필요한 최소 함수
        bytes4[] memory s = new bytes4[](6);
        s[0] = SeigManagerV3_1.setValidatorReward.selector;
        s[1] = SeigManagerV3_1.setV2Logic.selector;
        s[2] = SeigManagerV3_1.migrateToV3.selector;
        s[3] = SeigManagerV3_1.updateSeigniorage.selector;
        s[4] = SeigManagerV3_1.setRatContract.selector;
        s[5] = bytes4(keccak256("v3Migrated()"));
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(s, seigManagerV3_1Impl);
    }

    // ==========================================
    // Step 6.5: Setup Minter Permissions
    // ==========================================
    function _setupMinterPermissions() internal {
        console.log("--- Step 6.5: Setup Minter Permissions ---");

        Layer2Registry(layer2RegistryProxy).addMinter(seigManagerProxy);
        console.log("Layer2Registry.addMinter(seigManagerProxy) done");

        MockWTON(wton).addMinter(seigManagerProxy);
        console.log("WTON.addMinter(seigManagerProxy) done");

        // Add DepositManager as WTON minter (for withdrawal processing)
        MockWTON(wton).addMinter(depositManagerProxy);
        console.log("WTON.addMinter(depositManagerProxy) done");
        console.log("");
    }

    // ==========================================
    // Step 7: Deploy OperatorManagerFactory
    // ==========================================
    function _deployOperatorManagerFactory(address /* deployer */) internal {
        console.log("--- Step 7: Deploy OperatorManagerFactory ---");

        operatorManagerImpl = address(new OperatorManagerV1_2());
        console.log("OperatorManagerV1_2 Impl:", operatorManagerImpl);

        operatorManagerFactory = address(new OperatorManagerFactory(operatorManagerImpl));
        console.log("OperatorManagerFactory:", operatorManagerFactory);
        console.log("");
    }

    // ==========================================
    // Step 8: Deploy V3 Contracts
    // ==========================================
    function _deployV3Contracts(address deployer) internal {
        console.log("--- Step 8: Deploy V3 Contracts ---");

        // Deploy RAT
        ratImpl = address(new RAT());
        console.log("RAT Impl:", ratImpl);

        // Prepare RAT initialization data using RATInitParams struct
        bytes memory ratInitData = _buildRATInitData(deployer);

        // Deploy RAT proxy with separate admin (not deployer to avoid TransparentUpgradeableProxy admin restriction)
        ratProxy = address(new RATProxy(ratImpl, PROXY_ADMIN, ratInitData));
        console.log("RAT Proxy:", ratProxy);

        // Step 2: RAT 설정 파라미터 설정
        _configureRAT(ratProxy, deployer);
        console.log("RAT config set");

        // Deploy ValidatorReward
        validatorPoolImpl = address(new ValidatorRewardV1());
        console.log("ValidatorReward Impl:", validatorPoolImpl);

        bytes memory validatorRewardInitData = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            seigManagerProxy,
            wton,
            ratProxy,
            deployer
        );

        // Deploy ValidatorReward proxy with deployer as admin
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, PROXY_ADMIN, validatorRewardInitData));
        console.log("ValidatorReward Proxy:", validatorPoolProxy);

    }

    // ==========================================
    // Step 9: Setup Cross-References
    // ==========================================
    function _setupCrossReferences(address /* deployer */) internal virtual {
        console.log("--- Step 10: Setup Cross-References ---");

        // Update SeigManager DAO address (was set to deployer in _initializeManagers)
        SeigManagerV1_2(seigManagerProxy).setData(
            address(0),     // powerTON
            daoCommitteeProxy,  // dao (updated from deployer)
            0,              // powerTONSeigRate: 0%
            0.5e27,         // daoSeigRate: 50%
            0.5e27,         // relativeSeigRate: 50%
            10,             // adjustCommissionDelay (fast for testing)
            1000.1e27       // minimumAmount: 1000.1 WTON
        );
        console.log("SeigManager DAO updated to:", daoCommitteeProxy);

        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        console.log("SeigManager.setLayer2Manager done");

        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);
        console.log("SeigManager.setValidatorReward done");

        // Layer2Manager.setAddresses (V3 - 2단계로 분리하여 stack too deep 회피)
        Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton
        );
        Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
            daoCommitteeProxy,  // Use DAO proxy instead of deployer
            depositManagerProxy,
            seigManagerProxy,
            address(0)
        );
        console.log("Layer2Manager.setAddresses done (dao:", daoCommitteeProxy, ")");

        // Set minimumInitialDepositAmount to a very low value for devnet testing
        Layer2ManagerV3(layer2ManagerProxy).setMinimumInitialDepositAmount(1); // 1 wei minimum (very low for testing)
        console.log("Layer2Manager.setMinimumInitialDepositAmount(1 wei) done");

        // L1BridgeRegistry.setAddresses (V1_2 단일 구현체)
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(
            layer2ManagerProxy,
            seigManagerProxy,
            ton
        );
        console.log("L1BridgeRegistry.setAddresses done");

        OperatorManagerFactory(operatorManagerFactory).setAddresses(
            depositManagerProxy,
            ton,
            wton,
            layer2ManagerProxy
        );
        console.log("OperatorManagerFactory.setAddresses done");

        // DepositManager.setAddresses (V3 단일 구현체)
        DepositManagerV3(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
        console.log("DepositManager.setAddresses done");

        // Set RAT treasury to DAO (l1BridgeRegistry는 initialize에서 이미 설정됨)
        RAT(ratProxy).setTreasury(daoCommitteeProxy);
        console.log("RAT.setTreasury done:", daoCommitteeProxy);
        console.log("");
    }

    // ==========================================
    // Step 10.5: Deploy MockAnchorStateRegistry (bytecode only)
    // ==========================================
    function _initializeOptimismPortal() internal {
        console.log("--- Step 10.5: Deploy MockAnchorStateRegistry ---");

        // Validate required addresses
        require(disputeGameFactory != address(0), "DisputeGameFactory address required");
        require(systemConfig != address(0), "SystemConfig address required");

        // Deploy MockAnchorStateRegistry (bytecode only)
        console.log("Deploying MockAnchorStateRegistry...");
        MockAnchorStateRegistry mockASR = new MockAnchorStateRegistry();
        anchorStateRegistry = address(mockASR);
        console.log("MockAnchorStateRegistry deployed:", anchorStateRegistry);

        // NOTE: All Optimism contract initialization is done at test runtime via transactions:
        // - MockAnchorStateRegistry.initialize()
        // - OptimismPortal.initialize()
        // - DisputeGameFactory.setRAT(), setInitBond()
        console.log("Optimism contracts will be initialized at test runtime");
        console.log("");
    }

    // ==========================================
    // Step 11: Log Optimism Integration Info (no vm.store)
    // ==========================================
    function _connectToOptimism() internal view {
        console.log("--- Step 11: Optimism Integration (Runtime Setup Required) ---");

        // NOTE: All Optimism integration is done at test runtime via transactions:
        // - DisputeGameFactory.setRAT(ratProxy)
        // - DisputeGameFactory.setSystemConfig(systemConfig)
        // - DisputeGameFactory.setInitBond(gameType, bond)
        // - L1BridgeRegistry.registerRollupConfigByManager()

        console.log("DisputeGameFactory:", disputeGameFactory);
        console.log("SystemConfig:", systemConfig);
        console.log("RAT Proxy:", ratProxy);
        console.log("");
        console.log("These will be connected at test runtime via transactions");
        console.log("");
    }

    // ==========================================
    // Deploy DAO Infrastructure
    // ==========================================
    function _deployDAO() internal {
        console.log("--- Deploy DAO Infrastructure ---");

        // 1. Deploy MockDAOCommitteeProxy (simplified proxy for devnet)
        daoCommitteeProxy = address(new MockDAOCommitteeProxy(ton));
        console.log("MockDAOCommitteeProxy deployed:", daoCommitteeProxy);

        // 2. Deploy DAO implementations
        daoCommitteeProxy2 = address(new DAOCommitteeProxy2());
        daoCommitteeV1 = address(new DAOCommittee_V1());
        daoCommitteeOwner = address(new DAOCommitteeOwner());
        console.log("DAOCommitteeProxy2:", daoCommitteeProxy2);
        console.log("DAOCommittee_V1:", daoCommitteeV1);
        console.log("DAOCommitteeOwner:", daoCommitteeOwner);

        // 3. Setup proxy routing
        IProxy(daoCommitteeProxy).upgradeTo(daoCommitteeProxy2);
        IDAOCommitteeProxy2(daoCommitteeProxy).upgradeTo2(daoCommitteeV1);
        console.log("Proxy routing configured");

        // 4. Setup DAOCommitteeOwner selector routing
        IDAOCommitteeProxy2(daoCommitteeProxy).setAliveImplementation2(daoCommitteeOwner, true);

        bytes4[] memory ownerSelectors = new bytes4[](5);
        ownerSelectors[0] = IDAOCommitteeOwner.setCandidateFactory.selector;
        ownerSelectors[1] = IDAOCommitteeOwner.setCandidateAddOnFactory.selector;
        ownerSelectors[2] = IDAOCommitteeOwner.setSeigManager.selector;
        ownerSelectors[3] = IDAOCommitteeOwner.setLayer2Manager.selector;
        ownerSelectors[4] = IDAOCommitteeOwner.setLayer2Registry.selector;

        IDAOCommitteeProxy2(daoCommitteeProxy).setSelectorImplementations2(ownerSelectors, daoCommitteeOwner);
        console.log("Owner selectors configured");

        // 5. Deploy Candidate implementations
        candidateImpl = address(new Candidate());
        candidateAddOnImpl = address(new CandidateAddOnV1_1());
        console.log("Candidate implementations:");
        console.log("  Candidate:", candidateImpl);
        console.log("  CandidateAddOnV1_1:", candidateAddOnImpl);

        // 6. Deploy factories with proxies
        CandidateFactoryProxy cfProxy = new CandidateFactoryProxy();
        candidateFactoryProxy = address(cfProxy);
        cfProxy.upgradeTo(address(new CandidateFactory()));
        console.log("CandidateFactoryProxy:", candidateFactoryProxy);

        CandidateAddOnFactoryProxy caofProxy = new CandidateAddOnFactoryProxy();
        candidateAddOnFactoryProxy = address(caofProxy);
        caofProxy.upgradeTo(address(new CandidateAddOnFactory()));
        console.log("CandidateAddOnFactoryProxy:", candidateAddOnFactoryProxy);

        // 7. Configure factories
        CandidateFactory(candidateFactoryProxy).setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            candidateImpl,
            ton,
            wton
        );

        CandidateAddOnFactory(candidateAddOnFactoryProxy).setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            candidateAddOnImpl,
            ton,
            wton,
            l1BridgeRegistryProxy
        );
        console.log("Factories configured");

        // 8. Configure DAO
        IDAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(candidateFactoryProxy);
        IDAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(candidateAddOnFactoryProxy);
        IDAOCommitteeOwner(daoCommitteeProxy).setSeigManager(seigManagerProxy);
        IDAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(layer2ManagerProxy);
        IDAOCommitteeOwner(daoCommitteeProxy).setLayer2Registry(layer2RegistryProxy);
        console.log("DAO configured with manager contracts");

        // 9. Grant MINTER_ROLE to DAO
        Layer2Registry(layer2RegistryProxy).addMinter(daoCommitteeProxy);
        console.log("DAO granted MINTER_ROLE for Layer2Registry");

        console.log("");
    }

    // ==========================================
    // Register Layer2 - Skipped (done at test runtime)
    // ==========================================
    function _registerLayer2() internal pure {
        console.log("--- Register Layer2 (Skipped - Runtime Setup Required) ---");

        // NOTE: Layer2 registration is done at test runtime via transactions:
        // - createMockLayer2() in rat_challenge_helpers.go
        // - WTON.mint(), WTON.approve()
        // - Layer2Manager.registerCandidateAddOn()

        console.log("Layer2 will be created at test runtime via createMockLayer2()");
        console.log("");
    }

    // ==========================================
    // Step 12: Mint Test Tokens (Pure TON Staking - Genesis)
    // ==========================================
    function _mintTestTokens() internal {
        console.log("--- Step 12: Mint Test Tokens ---");

        // Mint tokens to test accounts (100,000 TON and 100,000 WTON each)
        uint256 tonAmount = 100_000 * 1e18;  // TON uses 18 decimals
        uint256 wtonAmount = 100_000 * 1e27; // WTON uses 27 decimals (RAY)

        address[5] memory accounts = [OPTIMISM_DEPLOYER, DEPLOYER, VALIDATOR, PROPOSER, CHALLENGER];
        string[5] memory names = ["OPTIMISM_DEPLOYER", "DEPLOYER", "VALIDATOR", "PROPOSER", "CHALLENGER"];

        for (uint256 i = 0; i < accounts.length; i++) {
            MockTON(ton).mint(accounts[i], tonAmount);
            MockWTON(wton).mint(accounts[i], wtonAmount);
            console.log("Minted to", names[i], accounts[i]);
        }

        console.log("Token amounts: 100,000 TON + 100,000 WTON per account");
        console.log("");
    }

    // ==========================================
    // Output Summary
    // ==========================================
    function _printSummary() internal view {
        console.log("=== Deployment Summary ===");
        console.log("");
        console.log("Tokens:");
        console.log("  TON:", ton);
        console.log("  WTON:", wton);
        console.log("");
        console.log("Core Infrastructure:");
        console.log("  CoinageFactory:", coinageFactory);
        console.log("  Layer2Registry Proxy:", layer2RegistryProxy);
        console.log("");
        console.log("Managers (Proxies):");
        console.log("  SeigManager Proxy:", seigManagerProxy);
        console.log("  DepositManager Proxy:", depositManagerProxy);
        console.log("  Layer2Manager Proxy:", layer2ManagerProxy);
        console.log("  L1BridgeRegistry Proxy:", l1BridgeRegistryProxy);
        console.log("");
        console.log("V3 Contracts:");
        console.log("  RAT Proxy:", ratProxy);
        console.log("  ValidatorReward Proxy:", validatorPoolProxy);
        console.log("");
        console.log("Factory:");
        console.log("  OperatorManagerFactory:", operatorManagerFactory);
        console.log("");
        console.log("Optimism Integration:");
        console.log("  DisputeGameFactory:", disputeGameFactory);
        console.log("  SystemConfig:", systemConfig);
        console.log("");
        console.log("Deployers:");
        console.log("  Optimism Deployer:", OPTIMISM_DEPLOYER, "(Anvil #0)");
        console.log("  TON Staking Deployer:", DEPLOYER, "(Anvil #1)");
        console.log("");
        console.log("Test Accounts (each has 100k TON + 100k WTON):");
        console.log("  VALIDATOR:", VALIDATOR);
        console.log("  PROPOSER:", PROPOSER);
        console.log("  CHALLENGER:", CHALLENGER);
    }

    // ==========================================
    // RAT 2단계 초기화 (stack too deep 회피)
    // ==========================================
    function _buildRATInitData(address deployer) internal view returns (bytes memory) {
        // Step 1: 핵심 주소만으로 초기화 (6개 필드)
        RATInitParams memory params = RATInitParams({
            seigManager: seigManagerProxy,
            wton: wton,
            ton: ton,
            layer2Manager: layer2ManagerProxy,
            l1BridgeRegistry: l1BridgeRegistryProxy,
            owner: deployer
        });
        return abi.encodeWithSelector(RAT.initialize.selector, params);
    }

    function _configureRAT(address proxy, address deployer) internal {
        // Step 2: 설정 파라미터 설정
        RATConfigParams memory config = RATConfigParams({
            ratTriggerProbability: RAT_TRIGGER_PROBABILITY,
            evidenceSubmissionPeriod: RAT_EVIDENCE_PERIOD,
            slashingPenalty: RAT_SLASHING_PENALTY,
            validatorBuffer: RAT_VALIDATOR_BUFFER,
            minimumThreshold: RAT_MINIMUM_THRESHOLD,
            maxValidatorsPerL2: RAT_MAX_VALIDATORS_PER_L2,
            challengeGameDuration: RAT_CHALLENGE_GAME_DURATION,
            safetyBuffer: RAT_SAFETY_BUFFER,
            treasury: deployer,
            attentionCost: RAT_ATTENTION_COST,
            relaxedValidatorCheck: RAT_RELAXED_VALIDATOR_CHECK
        });
        RAT(proxy).setConfig(config);
    }

    // Helper functions to avoid stack too deep
    function _buildJsonPart1() internal view returns (string memory) {
        return string(abi.encodePacked(
            "{\n",
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "rpcUrl": "http://localhost:8545",\n',
            '  "ton": "', vm.toString(ton), '",\n',
            '  "wton": "', vm.toString(wton), '",\n',
            '  "coinageFactory": "', vm.toString(coinageFactory), '",\n'
        ));
    }

    function _buildJsonPart2() internal view returns (string memory) {
        return string(abi.encodePacked(
            '  "layer2RegistryProxy": "', vm.toString(layer2RegistryProxy), '",\n',
            '  "seigManagerProxy": "', vm.toString(seigManagerProxy), '",\n',
            '  "depositManagerProxy": "', vm.toString(depositManagerProxy), '",\n',
            '  "layer2ManagerProxy": "', vm.toString(layer2ManagerProxy), '",\n',
            '  "l1BridgeRegistryProxy": "', vm.toString(l1BridgeRegistryProxy), '",\n'
        ));
    }

    function _buildJsonPart3() internal view returns (string memory) {
        return string(abi.encodePacked(
            '  "operatorManagerFactory": "', vm.toString(operatorManagerFactory), '",\n',
            '  "ratProxy": "', vm.toString(ratProxy), '",\n',
            '  "validatorRewardProxy": "', vm.toString(validatorPoolProxy), '",\n'
        ));
    }

    function _buildJsonPart4() internal view returns (string memory) {
        return string(abi.encodePacked(
            '  "disputeGameFactory": "', vm.toString(disputeGameFactory), '",\n',
            '  "systemConfig": "', vm.toString(systemConfig), '",\n',
            '  "anchorStateRegistry": "', vm.toString(anchorStateRegistry), '",\n',
            '  "daoCommitteeProxy": "', vm.toString(daoCommitteeProxy), '",\n',
            '  "daoCommitteeProxy2": "', vm.toString(daoCommitteeProxy2), '",\n',
            '  "daoCommitteeV1": "', vm.toString(daoCommitteeV1), '",\n'
        ));
    }

    function _buildJsonPart5() internal view returns (string memory) {
        return string(abi.encodePacked(
            '  "daoCommitteeOwner": "', vm.toString(daoCommitteeOwner), '",\n',
            '  "candidateImpl": "', vm.toString(candidateImpl), '",\n',
            '  "candidateAddOnImpl": "', vm.toString(candidateAddOnImpl), '",\n',
            '  "candidateFactoryProxy": "', vm.toString(candidateFactoryProxy), '",\n',
            '  "candidateAddOnFactoryProxy": "', vm.toString(candidateAddOnFactoryProxy), '",\n',
            '  "mockLayer2": "', vm.toString(mockLayer2), '",\n'
        ));
    }

    function _buildJsonPart6() internal view returns (string memory) {
        string memory accounts = string(abi.encodePacked(
            '    "optimismDeployer": "', vm.toString(OPTIMISM_DEPLOYER), '",\n',
            '    "tonStakingDeployer": "', vm.toString(DEPLOYER), '",\n',
            '    "validator": "', vm.toString(VALIDATOR), '",\n',
            '    "proposer": "', vm.toString(PROPOSER), '",\n',
            '    "challenger": "', vm.toString(CHALLENGER), '"\n'
        ));
        return string(abi.encodePacked(
            '  "operatorManager": "', vm.toString(operatorManager), '",\n',
            '  "accounts": {\n',
            accounts,
            '  }\n',
            "}"
        ));
    }

    function _saveDeployment() internal view {
        // Build JSON in parts to avoid stack too deep
        string memory p1 = string(abi.encodePacked(_buildJsonPart1(), _buildJsonPart2()));
        string memory p2 = string(abi.encodePacked(_buildJsonPart3(), _buildJsonPart4()));
        string memory p3 = string(abi.encodePacked(_buildJsonPart5(), _buildJsonPart6()));
        string memory json = string(abi.encodePacked(p1, p2, p3));

        // Print JSON for bash script to save
        console.log("\n=== DEPLOYMENT_JSON_START ===");
        console.log(json);
        console.log("=== DEPLOYMENT_JSON_END ===");
    }
}