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

// Slashing Implementations
import {Layer2Manager_Slashing} from "../src/layer2/Layer2Manager_Slashing.sol";
import {SeigManager_Slashing} from "../src/stake/managers/SeigManager_Slashing.sol";
import {DepositManager_Slashing} from "../src/stake/managers/DepositManager_Slashing.sol";

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
// TODO: SequencerVault 파일이 존재하지 않음 - 필요시 구현 후 활성화
// import {SequencerVault} from "../src/sequencer/SequencerVault.sol";
// import {SequencerVaultProxy} from "../src/sequencer/SequencerVaultProxy.sol";

// Mocks for testing
import {MockTON} from "../src/mocks/MockTON.sol";
import {MockWTON} from "../src/mocks/MockWTON.sol";
import {MockSystemConfig} from "../src/mocks/MockSystemConfig.sol";

// DAO Committee
import {DAOCommitteeProxy2} from "../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../src/dao/DAOCommitteeOwner.sol";
import {Candidate} from "../src/dao/Candidate.sol";
import {CandidateFactory} from "../src/dao/factory/CandidateFactory.sol";
import {CandidateFactoryProxy} from "../src/dao/factory/CandidateFactoryProxy.sol";
import {CandidateAddOnV1_1} from "../src/dao/CandidateAddOnV1_1.sol";
import {CandidateAddOnFactory} from "../src/dao/factory/CandidateAddOnFactory.sol";
import {CandidateAddOnFactoryProxy} from "../src/dao/factory/CandidateAddOnFactoryProxy.sol";

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

interface ISystemConfig {
    function owner() external view returns (address);
    function setUnsafeBlockSigner(address _unsafeBlockSigner) external;
    function disputeGameFactory() external view returns (address);
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
contract DeployV3SlashForDevnet is Script {
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
    uint256 constant RAT_SLASHING_PENALTY = 100 * RAY; // 100 WTON
    uint256 constant RAT_VALIDATOR_BUFFER = 100 * RAY; // 100 WTON
    uint256 constant RAT_MINIMUM_THRESHOLD = 0; // 0 for testing (always trigger if any stake exists)
    uint256 constant RAT_MAX_VALIDATORS_PER_L2 = 100; // Maximum validators per L2
    uint256 constant RAT_CHALLENGE_GAME_DURATION = 7 days; // Challenge game period
    uint256 constant RAT_SAFETY_BUFFER = 1 days; // Safety buffer period
    uint256 constant RAT_ATTENTION_COST = 1e27; // c_m: 1 TON per epoch (RAY unit)
    bool constant RAT_RELAXED_VALIDATOR_CHECK = true; // V3: 초기에는 C_off 기준으로 완화

    // DisputeGame parameters
    uint256 constant DISPUTE_GAME_INIT_BOND = 0.08 ether; // Init bond for creating games
    uint256 constant RAT_EVIDENCE_PERIOD = 1 hours;

    // Slashing parameters
    uint256 constant SLASHING_REWARD_RATE = 1000; // 10% = 1000 (basis points)

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

    // Manager Implementations
    // SeigManager 다중 구현체 (V3: V1_2 기본 + V3_1, V3_2 추가)
    address public seigManagerV3_1Impl; // V3_1: V3 메인 기능
    address public seigManagerV3_2Impl; // V3_2: V2 호환 로직

    // DepositManager 단일 구현체 (V3)
    address public depositManagerImpl; // DepositManagerV3 단일 구현체

    // Layer2Manager 단일 구현체 (V3)
    address public layer2ManagerImpl; // Layer2ManagerV3 단일 구현체

    // L1BridgeRegistry 단일 구현체
    address public l1BridgeRegistryImpl; // L1BridgeRegistryV1_2 단일 구현체

    // Slashing Implementations
    address public seigManagerSlashingImpl;
    address public depositManagerSlashingImpl;
    address public layer2ManagerSlashingImpl;

    // Operator Manager
    address public operatorManagerFactory;
    address public operatorManagerImpl;

    // V3 Contracts
    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;
    address public sequencerVaultProxy;
    address public sequencerVaultImpl;

    // Optimism Contracts (read from environment)
    address public disputeGameFactory;
    address public systemConfig;
    address public mockSystemConfig;

    // DAO Committee
    address public daoVault;
    address public daoAgendaManager;
    address public daoCommitteeProxy; // ABI deployment
    DAOCommitteeProxy2 public daoCommitteeProxy2;
    DAOCommittee_V1 public daoCommitteeImpl;
    DAOCommitteeOwner public daoCommitteeOwner;
    Candidate public candidateImpl;
    CandidateFactory public candidateFactoryLogic;
    CandidateFactoryProxy public candidateFactoryProxy;
    CandidateAddOnV1_1 public candidateAddOnImpl;
    CandidateAddOnFactory public candidateAddOnFactoryLogic;
    CandidateAddOnFactoryProxy public candidateAddOnFactoryProxy;

    /// @notice Entry point for generating devnet allocs (without actual broadcast)
    /// @dev This is used to generate genesis allocs file
    function runForDevnetAlloc() external {
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

    function run() public {
        // Read Optimism addresses from environment or use defaults
        _loadOptimismAddresses();

        // Setup L1 Optimism contracts from allocs-l1.json using vm.etch()
        // Note: This is now handled by a separate script (SetupL1Allocs.sol)
        // The bash script should run it separately to avoid contract size issues
        console.log("--- Step 0: Setup Optimism L1 Contracts (vm.etch) ---");
        console.log("Skipping setupAllocs() - should be run separately");
        console.log("");

        // Use startBroadcast() without argument to use CLI --private-key
        vm.startBroadcast();

        // Get deployer address from msg.sender (set by broadcast)
        address deployer = msg.sender;

        console.log("=== TON Staking V3 Devnet Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        _deployTokens();
        _deployCoinageInfrastructure(deployer);
        _deployLayer2Registry(deployer);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(deployer);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(deployer);
        _deployV3Contracts(deployer);
        _configureV3Contracts(deployer);
        _deployDAOVault();
        _deployDAOAgendaManager();
        _deployDAOCommittee();
        _setupCrossReferences(deployer);
        _connectToOptimism();
        _mintTestTokens();
        _addMinterSetting();
        _addSeigManagerSetting();
        _setupContractOwner();

        vm.stopBroadcast();

        _printSummary();
        _saveDeployment();
    }

    // ==========================================
    // Step 0: Load Optimism Addresses
    // ==========================================
    function _loadOptimismAddresses() internal {
        console.log("--- Step 0: Load Optimism Addresses ---");

        // Try to read from environment variables (set by deploy script)
        disputeGameFactory = vm.envOr("DISPUTE_GAME_FACTORY_PROXY", address(0));
        systemConfig = vm.envOr("SYSTEM_CONFIG_PROXY", address(0));

        if (disputeGameFactory == address(0)) {
            // Fallback: try to read from lib/optimism/.devnet/addresses.json
            // This requires the file to exist
            console.log("Warning: DISPUTE_GAME_FACTORY_PROXY not set");
            console.log("DisputeGameFactory will need to be set manually");
        } else {
            console.log("DisputeGameFactory:", disputeGameFactory);
        }

        if (systemConfig == address(0)) {
            console.log("Warning: SYSTEM_CONFIG_PROXY not set");
        } else {
            console.log("SystemConfig:", systemConfig);
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
    function _deployCoinageInfrastructure(address deployer) internal {
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
    function _deployLayer2Registry(address deployer) internal {
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

        // SeigManager: V1_2를 기본 구현체로 사용
        // V3_1, V3_2는 selector routing으로 추가 (V3 신규 함수)
        address seigManagerV1_2Impl = address(new SeigManagerV1_2());
        console.log("SeigManagerV1_2 Impl:", seigManagerV1_2Impl);
        IProxy(seigManagerProxy).upgradeTo(seigManagerV1_2Impl);

        // V3_1: V3 메인 기능 (pause/unpause, updateSeigniorage V3, RAT 통합 등)
        seigManagerV3_1Impl = address(new SeigManagerV3_1());
        console.log("SeigManagerV3_1 Impl:", seigManagerV3_1Impl);

        // V3_2: V2 호환 로직 (delegatecall로 호출됨)
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

        // L1BridgeRegistry
        l1BridgeRegistryImpl = address(new L1BridgeRegistryV1_2());
        console.log("L1BridgeRegistryV1_2 Impl:", l1BridgeRegistryImpl);
        IProxy(l1BridgeRegistryProxy).upgradeTo(l1BridgeRegistryImpl);

        // Slashing Implementations
        seigManagerSlashingImpl = address(new SeigManager_Slashing());
        console.log("SeigManager_Slashing Impl:", seigManagerSlashingImpl);

        depositManagerSlashingImpl = address(new DepositManager_Slashing());
        console.log("DepositManager_Slashing Impl:", depositManagerSlashingImpl);

        layer2ManagerSlashingImpl = address(new Layer2Manager_Slashing());
        console.log("Layer2Manager_Slashing Impl:", layer2ManagerSlashingImpl);

        console.log("");
    }

    // ==========================================
    // Step 6: Initialize Managers
    // ==========================================
    function _initializeManagers(address deployer) internal {
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

        // // Set SeigManager data
        // // prettier-ignore
        // SeigManagerV1_2(seigManagerProxy).setData(
        //     address(0),     // powerTON
        //     deployer,       // dao
        //     0,              // powerTONSeigRate: 0%
        //     0.5e27,         // daoSeigRate: 50%
        //     0.5e27,         // relativeSeigRate: 50%
        //     10,             // adjustCommissionDelay (fast for testing)
        //     1000.1e27       // minimumAmount: 1000.1 WTON
        // );
        // console.log("SeigManager setData done");

        // =====================================================
        // SeigManager 다중 구현체 설정 (V3: V1_2 기본 + V3_1, V3_2)
        // =====================================================
        _setupSeigManagerV3Routing();

        // SeigManager Slashing routing
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
            seigManagerSlashingImpl,
            true
        );
        bytes4[] memory seigSlashingSelectors = new bytes4[](1);
        seigSlashingSelectors[0] = SeigManager_Slashing.onSlash.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
            seigSlashingSelectors,
            seigManagerSlashingImpl
        );

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

        // DepositManager Slashing routing
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
            depositManagerSlashingImpl,
            true
        );
        bytes4[] memory dmSlashingSelectors = new bytes4[](3);
        dmSlashingSelectors[0] = DepositManager_Slashing.setSlashingRewardRate.selector;
        dmSlashingSelectors[1] = DepositManager_Slashing.slash.selector;
        dmSlashingSelectors[2] = bytes4(keccak256("slashingRewardRate()"));
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(
            dmSlashingSelectors,
            depositManagerSlashingImpl
        );

        // SlashingRewardRate Setting
        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(
            SLASHING_REWARD_RATE
        );
        console.log("SlashingRewardRate set to:", SLASHING_REWARD_RATE);
        console.log("");
    }

    // ==========================================
    // SeigManager V3 Selector Routing (분리하여 stack too deep 회피)
    // ==========================================
    function _setupSeigManagerV3Routing() internal {
        // V3_1, V3_2를 alive 상태로 설정
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
            seigManagerV3_1Impl,
            true
        );
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
            seigManagerV3_2Impl,
            true
        );

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
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
            s,
            seigManagerV3_1Impl
        );
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
    function _deployOperatorManagerFactory(address deployer) internal {
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

        // RAT 프록시는 별도 배포 (stack too deep 회피)
        ratProxy = _deployRATProxy(deployer);
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT initialized");
        // RAT proxy는 _deployRATProxy에서 이미 배포됨
        console.log("RAT Proxy:", ratProxy);

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
        validatorPoolProxy = address(
            new ValidatorRewardProxy(validatorPoolImpl, PROXY_ADMIN, validatorRewardInitData)
        );
        console.log("ValidatorReward Proxy:", validatorPoolProxy);

        // TODO: SequencerVault 파일이 존재하지 않음 - 필요시 구현 후 활성화
        // Deploy SequencerVault (Proxy + Implementation 패턴 - RAT/ValidatorReward와 다름)
        // sequencerVaultImpl = address(new SequencerVault());
        // SequencerVaultProxy svProxy = new SequencerVaultProxy();
        // sequencerVaultProxy = address(svProxy);
        // IProxy(sequencerVaultProxy).upgradeTo(sequencerVaultImpl);
        // SequencerVault(sequencerVaultProxy).initialize(
        //     seigManagerProxy,
        //     wton,
        //     ton,
        //     layer2ManagerProxy,
        //     l1BridgeRegistryProxy,
        //     deployer
        // );
        sequencerVaultProxy = address(0); // Placeholder until SequencerVault is implemented
        sequencerVaultImpl = address(0);
        console.log("SequencerVault placeholder set (not implemented yet)");
        console.log("");
    }

    // ==========================================
    // Step 9: Configure V3 Contracts
    // ==========================================
    function _configureV3Contracts(address deployer) internal {
        // RAT configuration is done in _deployRATProxy -> _configureRAT
        // This function is kept for compatibility but RAT is already configured
        console.log("--- Step 9: Configure V3 Parameters ---");
        console.log("RAT already configured during deployment");
        console.log("");
    }

    // ==========================================
    // RAT 2단계 초기화 (stack too deep 회피)
    // ==========================================
    function _deployRATProxy(address deployer) internal returns (address) {
        // Step 1: 핵심 주소만으로 프록시 배포
        RATInitParams memory params = RATInitParams({
            seigManager: seigManagerProxy,
            wton: wton,
            ton: ton,
            layer2Manager: layer2ManagerProxy,
            l1BridgeRegistry: l1BridgeRegistryProxy,
            owner: deployer
        });
        bytes memory initData = abi.encodeWithSelector(RAT.initialize.selector, params);
        // Use PROXY_ADMIN instead of deployer to avoid admin fallback issue
        address proxy = address(new RATProxy(ratImpl, PROXY_ADMIN, initData));

        // Step 2: 설정 파라미터 설정
        _configureRAT(proxy, deployer);
        return proxy;
    }

    function _configureRAT(address proxy, address deployer) internal {
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

    // ==========================================
    // Step 10: Setup Cross-References
    // ==========================================
    function _setupCrossReferences(address deployer) internal {
        console.log("--- Step 10: Setup Cross-References ---");

        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        console.log("SeigManager.setLayer2Manager done");

        // SeigManager -> L1BridgeRegistry (updateSeigniorage에서 layer2TVL 조회 필요)
        SeigManagerV1_2(seigManagerProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);
        console.log("SeigManager.setL1BridgeRegistry done");

        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);
        console.log("SeigManager.setValidatorReward done");

        // Layer2Manager V3: setAddresses1, setAddresses2로 분리
        Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton
        );
        Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
            daoCommitteeProxy, // Use DAO proxy instead of deployer
            depositManagerProxy,
            seigManagerProxy,
            address(0)
        );
        console.log("Layer2Manager.setAddresses done (dao:", daoCommitteeProxy, ")");

        // Set minimumInitialDepositAmount to a very low value for devnet testing
        Layer2ManagerV3(layer2ManagerProxy).setMinimumInitialDepositAmount(1); // 1 wei minimum (very low for testing)
        console.log("Layer2Manager.setMinimumInitialDepositAmount(1 wei) done");

        // Layer2Manager Slashing routing
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(
            layer2ManagerSlashingImpl,
            true
        );
        bytes4[] memory l2SlashingSelectors = new bytes4[](1);
        l2SlashingSelectors[0] = Layer2Manager_Slashing.slashingCandidate.selector;
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(
            l2SlashingSelectors,
            layer2ManagerSlashingImpl
        );

        // TODO: SequencerVault 구현 후 활성화
        // Layer2ManagerV3(layer2ManagerProxy).setSequencerVault(sequencerVaultProxy);
        // console.log("Layer2Manager.setSequencerVault done");

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

        DepositManagerV3(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
        console.log("DepositManager.setAddresses done");

        // Set default slashing reward rate (e.g., 10% = 1000)
        DepositManager_Slashing(depositManagerProxy).setSlashingRewardRate(1000);
        console.log("DepositManager.setSlashingRewardRate(1000) done");

        // Update SeigManager DAO address (was set to deployer in _initializeManagers)
        SeigManagerV1_2(seigManagerProxy).setData(
            address(0), // powerTON
            daoCommitteeProxy, // dao (updated from deployer)
            0, // powerTONSeigRate: 0%
            0.5e27, // daoSeigRate: 50%
            0.5e27, // relativeSeigRate: 50%
            10, // adjustCommissionDelay (fast for testing)
            1000.1e27 // minimumAmount: 1000.1 WTON
        );
        console.log("SeigManager DAO updated to:", daoCommitteeProxy);

        // Set RAT treasury to DAO
        RAT(ratProxy).setTreasury(daoCommitteeProxy);
        console.log("RAT.setTreasury done:", daoCommitteeProxy);

        console.log("");
    }

    // ==========================================
    // Step 11: Connect RAT to Optimism
    // ==========================================
    function _connectToOptimism() internal {
        console.log("--- Step 11: Connect RAT to Optimism DisputeGameFactory ---");

        if (disputeGameFactory == address(0)) {
            console.log("Warning: DisputeGameFactory not set, skipping connection");
            console.log("");
            return;
        }

        // Check if DisputeGameFactory contract exists at the address
        if (disputeGameFactory.code.length == 0) {
            console.log("Warning: DisputeGameFactory not deployed at", disputeGameFactory);
            console.log("Skipping Optimism integration");
            console.log("RAT will work independently without DisputeGameFactory connection");
            console.log("");
            return;
        }

        // IMPORTANT: Use Optimism deployer (Account #0) to call setRAT() (onlyOwner)
        // TON Staking uses Account #1, but DisputeGameFactory owner is Account #0
        vm.stopBroadcast(); // Stop TON Staking deployer broadcast
        vm.startBroadcast(OPTIMISM_DEPLOYER); // Start Optimism deployer broadcast

        // Set RAT on DisputeGameFactory
        try IDisputeGameFactory(disputeGameFactory).setRAT(ratProxy) {
            console.log(
                "DisputeGameFactory.setRAT(",
                ratProxy,
                ") done (called by Optimism deployer)"
            );
        } catch {
            console.log("Warning: DisputeGameFactory.setRAT() failed");
            console.log("Skipping Optimism integration");
            vm.stopBroadcast();
            vm.startBroadcast(); // Resume TON Staking deployer
            console.log("");
            return;
        }
        // Set SystemConfig on DisputeGameFactory
        if (systemConfig != address(0)) {
            try IDisputeGameFactory(disputeGameFactory).setSystemConfig(systemConfig) {
                console.log("DisputeGameFactory.setSystemConfig(", systemConfig, ") done");
            } catch {
                console.log("Warning: DisputeGameFactory.setSystemConfig() failed");
            }
        }

        // Set InitBond for game type 0 (FaultDisputeGame)
        try IDisputeGameFactory(disputeGameFactory).setInitBond(0, DISPUTE_GAME_INIT_BOND) {
            console.log("DisputeGameFactory.setInitBond(0,", DISPUTE_GAME_INIT_BOND, ") done");
        } catch {
            console.log("Warning: DisputeGameFactory.setInitBond() failed");
        }
        vm.stopBroadcast(); // Stop Optimism deployer broadcast
        vm.startBroadcast(); // Resume TON Staking deployer

        // Verify connection
        try IDisputeGameFactory(disputeGameFactory).rat() returns (address ratOnFactory) {
            if (ratOnFactory == ratProxy) {
                console.log("RAT successfully connected to DisputeGameFactory");
            } else {
                console.log("Warning: RAT connection verification failed");
                console.log("  Expected:", ratProxy);
                console.log("  Got:", ratOnFactory);
            }
        } catch {
            console.log("Warning: Could not verify RAT connection");
        }
        // Register SystemConfig in L1BridgeRegistry (this also registers DisputeGameFactory)
        console.log("Registering SystemConfig in L1BridgeRegistry...");
        vm.stopBroadcast(); // Stop Optimism deployer broadcast
        vm.startBroadcast(); // Resume TON Staking deployer

        // First, add deployer as manager (required to call registerRollupConfigByManager)
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).addManager(msg.sender);
        console.log("Added deployer as L1BridgeRegistry manager:", msg.sender);

        // // Deploy and configure MockSystemConfig for E2E tests
        // MockSystemConfig mockInstance = new MockSystemConfig();
        // mockSystemConfig = address(mockInstance);
        // console.log("MockSystemConfig deployed at:", mockSystemConfig);

        // // Configure MockSystemConfig
        // mockInstance.setUnsafeBlockSigner(DEPLOYER);
        // mockInstance.setDisputeGame(disputeGameFactory);
        // console.log("MockSystemConfig configured with DisputeGameFactory:", disputeGameFactory);

        // // Register MockSystemConfig
        // L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfigByManager(
        //     mockSystemConfig,
        //     3, // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
        //     ton // L2 TON address (using L1 TON as placeholder, not actually used for Optimism)
        // );
        // console.log("MockSystemConfig registered in L1BridgeRegistry");
        // console.log("  This provides unsafeBlockSigner, optimismPortal, etc. for E2E tests");

        // Register systemConfig
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfigByManager(
            systemConfig,
            3, // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
            ton // L2 TON address (using L1 TON as placeholder, not actually used for Optimism)
        );
        console.log("SystemConfig registered in L1BridgeRegistry");

        // Configure SystemConfig directly (instead of Mock)
        vm.stopBroadcast(); // Stop TON Staking deployer broadcast

        address sysOwner = ISystemConfig(systemConfig).owner();
        console.log("SystemConfig owner:", sysOwner);

        // Impersonate SystemConfig owner to set UnsafeBlockSigner
        vm.startBroadcast(sysOwner);
        ISystemConfig(systemConfig).setUnsafeBlockSigner(DEPLOYER);
        console.log("SystemConfig.setUnsafeBlockSigner(", DEPLOYER, ") done");

        // Verify DisputeGameFactory in SystemConfig (derived from OptimismPortal)
        address checkDisputeGameFactory = ISystemConfig(systemConfig).disputeGameFactory();
        require(
            checkDisputeGameFactory == disputeGameFactory,
            "DisputeGameFactory mismatch: SystemConfig points to different factory"
        );

        console.log("Verified SystemConfig.disputeGameFactory matches:", checkDisputeGameFactory);

        vm.stopBroadcast();

        vm.startBroadcast(); // Resume TON Staking deployer

        console.log("  Real SystemConfig configured with unsafeBlockSigner for E2E tests");

        console.log("");
    }

    // ==========================================
    // Step 12: Mint Test Tokens
    // ==========================================
    function _mintTestTokens() internal {
        console.log("--- Step 12: Mint Test Tokens ---");

        address[4] memory testAccounts = [DEPLOYER, VALIDATOR, PROPOSER, CHALLENGER];

        for (uint256 i = 0; i < testAccounts.length; i++) {
            // Mint TON (18 decimals) - 100,000,000 TON
            MockTON(ton).mint(testAccounts[i], 100000000 * 1e18);

            // Mint WTON (27 decimals) - 100,000,000 WTON
            MockWTON(wton).mint(testAccounts[i], 100000000 * RAY);
        }

        console.log("Minted 100,000 TON and 100,000 WTON to each test account:");
        console.log("  - DEPLOYER:", DEPLOYER);
        console.log("  - VALIDATOR:", VALIDATOR);
        console.log("  - PROPOSER:", PROPOSER);
        console.log("  - CHALLENGER:", CHALLENGER);
        console.log("");
    }

    // ==========================================
    // Step 13: DAOVault Deploy
    // ==========================================
    function _deployDAOVault() internal {
        console.log("--- Step 13: DAOVault Deploy ---");

        bytes memory daovaultArgs = abi.encode(ton, wton);
        daoVault = deployCode("abis/DAOVault.json", daovaultArgs);
        console.log("DAOVault deployed at:", daoVault);
    }

    // ==========================================
    // Step 14: DAOAgendaManager Deploy
    // ==========================================
    function _deployDAOAgendaManager() internal {
        console.log("--- Step 14: DAOAgendaManager Deploy ---");

        daoAgendaManager = deployCode("abis/DAOAgendaManager.json");
        console.log("DAOAgendaManager deployed at:", daoAgendaManager);
    }

    // ==========================================
    // Step 15: DAOCommittee Deploy
    // ==========================================
    function _deployDAOCommittee() internal {
        console.log("--- Step 15: DAOCommittee Deploy ---");

        // Step 2: DAOCommitteeProxy2 배포
        daoCommitteeProxy2 = new DAOCommitteeProxy2();
        console.log("DAOCommitteeProxy2 deployed at:", address(daoCommitteeProxy2));

        // Step 1: DAOCommitteeProxy 배포 (ABI) - 구현체를 처음부터 설정
        bytes memory daoArgs = abi.encode(
            ton,
            address(daoCommitteeProxy2), // impl을 여기서 바로 설정
            address(seigManagerProxy),
            address(layer2RegistryProxy),
            address(daoAgendaManager),
            address(1), // candidateFactory 배포전, address(0)으로 설정 불가
            address(daoVault)
        );
        daoCommitteeProxy = deployCode("abis/DAOCommitteeProxy.json", daoArgs);
        console.log("DAOCommitteeProxy deployed at:", daoCommitteeProxy);

        // Step 3: DAOCommittee_V1 구현체 배포 및 설정
        daoCommitteeImpl = new DAOCommittee_V1();
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).upgradeTo2(address(daoCommitteeImpl));
        console.log("DAOCommitteeProxy2 set implementation to V1");

        // Step 4: DAOCommitteeOwner 배포 및 Selector Routing
        daoCommitteeOwner = new DAOCommitteeOwner();
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setAliveImplementation2(
            address(daoCommitteeOwner),
            true
        );

        bytes4[] memory ownerSelectors = new bytes4[](17);
        ownerSelectors[0] = DAOCommitteeOwner.setCooldownTime.selector;
        ownerSelectors[1] = DAOCommitteeOwner.setCandidateAddOnFactory.selector;
        ownerSelectors[2] = DAOCommitteeOwner.setLayer2Manager.selector;
        ownerSelectors[3] = DAOCommitteeOwner.setSeigManager.selector;
        ownerSelectors[4] = DAOCommitteeOwner.setDaoVault.selector;
        ownerSelectors[5] = DAOCommitteeOwner.setLayer2Registry.selector;
        ownerSelectors[6] = DAOCommitteeOwner.setAgendaManager.selector;
        ownerSelectors[7] = DAOCommitteeOwner.setCandidateFactory.selector;
        ownerSelectors[8] = DAOCommitteeOwner.setTon.selector;
        ownerSelectors[9] = DAOCommitteeOwner.setWton.selector;
        ownerSelectors[10] = DAOCommitteeOwner.increaseMaxMember.selector;
        ownerSelectors[11] = DAOCommitteeOwner.setQuorum.selector;
        ownerSelectors[12] = DAOCommitteeOwner.decreaseMaxMember.selector;
        ownerSelectors[13] = DAOCommitteeOwner.setActivityRewardPerSecond.selector;
        ownerSelectors[14] = DAOCommitteeOwner.setCandidatesSeigManager.selector;
        ownerSelectors[15] = DAOCommitteeOwner.setCandidatesCommittee.selector;
        ownerSelectors[16] = DAOCommitteeOwner.daoExecuteTransaction.selector;

        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setSelectorImplementations2(
            ownerSelectors,
            address(daoCommitteeOwner)
        );
        console.log("DAOCommitteeOwner selectors routed");

        // Step 5: Candidate 구현체 배포
        candidateImpl = new Candidate();

        // Step 6: CandidateFactory 배포 및 설정
        candidateFactoryLogic = new CandidateFactory();
        candidateFactoryProxy = new CandidateFactoryProxy();
        candidateFactoryProxy.upgradeTo(address(candidateFactoryLogic));

        CandidateFactory(address(candidateFactoryProxy)).setAddress(
            address(depositManagerProxy),
            daoCommitteeProxy,
            address(candidateImpl),
            ton,
            wton
        );
        console.log("CandidateFactory deployed and configured");

        // Step 7: CandidateAddOn 배포 및 설정
        candidateAddOnImpl = new CandidateAddOnV1_1();
        candidateAddOnFactoryLogic = new CandidateAddOnFactory();
        candidateAddOnFactoryProxy = new CandidateAddOnFactoryProxy();
        candidateAddOnFactoryProxy.upgradeTo(address(candidateAddOnFactoryLogic));

        CandidateAddOnFactory(address(candidateAddOnFactoryProxy)).setAddress(
            address(depositManagerProxy),
            daoCommitteeProxy,
            address(candidateAddOnImpl),
            ton,
            wton,
            address(l1BridgeRegistryProxy)
        );
        console.log("CandidateAddOnFactory deployed and configured");

        // Step 8: DAOCommittee 추가 설정
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(address(candidateFactoryProxy));
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(
            address(candidateAddOnFactoryProxy)
        );
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(address(layer2ManagerProxy));
        DAOCommitteeOwner(daoCommitteeProxy).setWton(wton);
        console.log("DAOCommittee final configuration complete");
        // Note: Layer2Manager.setAddresses is called in _setupCrossReferences() after DAO deployment
    }

    // ==========================================
    // Step 16: Add Minter Setting
    // ==========================================
    function _addMinterSetting() internal {
        console.log("--- Step 16: Add Minter Setting ---");
        // DAOCommittee가 레이어2 등록 대행 가능하도록
        // ============== 이부분은 추가로 고민해봐야함 ==================
        Layer2Registry(address(layer2RegistryProxy)).addMinter(daoCommitteeProxy);
        console.log("DAOCommitteeProxy added as minter to Layer2Registry");
    }

    // ==========================================
    // Step 17: Add SeigManager Setting
    // ==========================================
    function _addSeigManagerSetting() internal {
        console.log("--- Step 17: Add SeigManager Setting ---");
        // Note: SeigManager DAO is already set in _setupCrossReferences()
        // Only set seigStartBlock here
        SeigManagerV1_2(address(seigManagerProxy)).setSeigStartBlock(1);
        console.log("SeigManagerV1_2 seigStartBlock set to 1");
    }

    // ==========================================
    // Step 18: Contract Owner Setting
    // ==========================================
    function _setupContractOwner() internal {
        console.log("--- Step 18: Contract Owner Setting ---");

        // SeigManagerProxy
        SeigManagerProxy(payable(seigManagerProxy)).transferAdmin(daoCommitteeProxy);
        console.log("SeigManagerProxy ownership transferred to DAOCommitteeProxy");

        // DepositManagerProxy
        DepositManagerProxy(payable(depositManagerProxy)).transferOwnership(daoCommitteeProxy);
        console.log("DepositManagerProxy ownership transferred to DAOCommitteeProxy");

        // Layer2RegistryProxy
        Layer2RegistryProxy(payable(layer2RegistryProxy)).transferOwnership(daoCommitteeProxy);
        console.log("Layer2RegistryProxy ownership transferred to DAOCommitteeProxy");

        // Set the minimum deposit amount to 0 for E2E tests to avoid decimal mismatch reverts
        // IMPORTANT: Must be done BEFORE transferring ownership to DAOCommittee
        if (Layer2ManagerV3(layer2ManagerProxy).minimumInitialDepositAmount() != 0) {
            Layer2ManagerV3(layer2ManagerProxy).setMinimumInitialDepositAmount(0);
            console.log("Layer2Manager minimumInitialDepositAmount set to 0");
        } else {
            console.log("Layer2Manager minimumInitialDepositAmount is already 0");
        }

        // Layer2ManagerProxy
        Layer2ManagerProxy(payable(layer2ManagerProxy)).transferOwnership(daoCommitteeProxy);
        console.log("Layer2ManagerProxy ownership transferred to DAOCommitteeProxy");
        // L1BridgeRegistryProxy - Setup for E2E tests
        // Grant REGISTRANT_ROLE to deployer for E2E tests
        // (SystemConfig is already registered in Step 11)
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).addRegistrant(msg.sender);
        console.log("Granted REGISTRANT_ROLE to deployer:", msg.sender);

        // Now transfer admin to DAOCommittee
        L1BridgeRegistryProxy(payable(l1BridgeRegistryProxy)).transferAdmin(daoCommitteeProxy);
        console.log("L1BridgeRegistryProxy ownership transferred to DAOCommitteeProxy");

        // CandidateFactoryProxy
        CandidateFactoryProxy(payable(address(candidateFactoryProxy))).transferOwnership(
            daoCommitteeProxy
        );
        console.log("CandidateFactoryProxy ownership transferred to DAOCommitteeProxy");

        // CandidateAddOnFactoryProxy
        CandidateAddOnFactoryProxy(payable(address(candidateAddOnFactoryProxy))).transferOwnership(
            daoCommitteeProxy
        );
        console.log("CandidateAddOnFactoryProxy ownership transferred to DAOCommitteeProxy");
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
        console.log("  SequencerVault Proxy:", sequencerVaultProxy);
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
        console.log("");
        console.log("DAOVault, DAOAgendaManger:");
        console.log("  DAOVault:", daoVault);
        console.log("  DAOAgendaManager:", daoAgendaManager);
        console.log("");
        console.log("DAOCommitteeContract:");
        console.log("  DAOCommitteeProxy:", daoCommitteeProxy);
        console.log("  CandidateFactoryProxy:", address(candidateFactoryProxy));
        console.log("  CandidateAddOnFactoryProxy:", address(candidateAddOnFactoryProxy));
        console.log("");
    }

    // Helper functions to avoid stack too deep
    // prettier-ignore
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

    // prettier-ignore
    function _buildJsonPart2() internal view returns (string memory) {
        return string(abi.encodePacked(
            '  "layer2RegistryProxy": "', vm.toString(layer2RegistryProxy), '",\n',
            '  "seigManagerProxy": "', vm.toString(seigManagerProxy), '",\n',
            '  "depositManagerProxy": "', vm.toString(depositManagerProxy), '",\n',
            '  "layer2ManagerProxy": "', vm.toString(layer2ManagerProxy), '",\n',
            '  "l1BridgeRegistryProxy": "', vm.toString(l1BridgeRegistryProxy), '",\n'
        ));
    }

    // prettier-ignore
    function _buildJsonPart3() internal view returns (string memory) {
        return string(abi.encodePacked(
            '  "operatorManagerFactory": "', vm.toString(operatorManagerFactory), '",\n',
            '  "ratProxy": "', vm.toString(ratProxy), '",\n',
            '  "validatorRewardProxy": "', vm.toString(validatorPoolProxy), '",\n',
            '  "sequencerVaultProxy": "', vm.toString(sequencerVaultProxy), '",\n',
            '  "daoCommitteeProxy": "', vm.toString(daoCommitteeProxy), '",\n'
        ));
    }

    // prettier-ignore
    function _buildJsonPart4() internal view returns (string memory) {
        // Split into smaller parts to avoid stack too deep
        string memory p1 = string.concat(
            '  "disputeGameFactory": "', vm.toString(disputeGameFactory), '",\n',
            '  "systemConfig": "', vm.toString(systemConfig), '",\n'
        );
        string memory p2 = string.concat(
            '  "mockSystemConfig": "', vm.toString(mockSystemConfig), '",\n',
            '  "accounts": {\n'
        );
        string memory p3 = _buildAccountsJson();
        return string.concat(p1, p2, p3);
    }

    function _buildAccountsJson() internal view returns (string memory) {
        string memory a1 = string.concat(
            '    "optimismDeployer": "',
            vm.toString(OPTIMISM_DEPLOYER),
            '",\n'
        );
        string memory a2 = string.concat(
            '    "tonStakingDeployer": "',
            vm.toString(DEPLOYER),
            '",\n'
        );
        string memory a3 = string.concat('    "validator": "', vm.toString(VALIDATOR), '",\n');
        string memory a4 = string.concat('    "proposer": "', vm.toString(PROPOSER), '",\n');
        string memory a5 = string.concat('    "challenger": "', vm.toString(CHALLENGER), '"\n');
        return string.concat(a1, a2, a3, a4, a5, "  }\n", "}");
    }

    function _saveDeployment() internal {
        // Build JSON in parts using string.concat to avoid stack too deep
        string memory json = string.concat(_buildJsonPart1(), _buildJsonPart2());
        json = string.concat(json, _buildJsonPart3());
        json = string.concat(json, _buildJsonPart4());

        // Print JSON for bash script to save
        console.log("\n=== DEPLOYMENT_JSON_START ===");
        console.log(json);
        console.log("=== DEPLOYMENT_JSON_END ===");
    }
}
