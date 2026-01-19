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

// Manager Implementations
import {SeigManagerV1_2} from "../src/stake/managers/SeigManagerV1_2.sol";
import {SeigManagerV1_3} from "../src/stake/managers/SeigManagerV1_3.sol";
import {SeigManagerV1_4} from "../src/stake/managers/SeigManagerV1_4.sol";
import {DepositManager} from "../src/stake/managers/DepositManager.sol";
import {DepositManager_setWithdrawalDelay} from "../src/stake/managers/DepositManager_setWithdrawalDelay.sol";
import {DepositManagerV1_1} from "../src/stake/managers/DepositManagerV1_1.sol";
import {DepositManagerV1_2} from "../src/stake/managers/DepositManagerV1_2.sol";
import {Layer2ManagerV1_1} from "../src/layer2/Layer2ManagerV1_1.sol";
import {Layer2ManagerV1_2} from "../src/layer2/Layer2ManagerV1_2.sol";
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
import {RATProxy} from "../src/validator/RATProxy.sol";
import {ValidatorRewardV1} from "../src/validator/ValidatorRewardV1.sol";
import {ValidatorRewardProxy} from "../src/validator/ValidatorRewardProxy.sol";
import {SequencerVault} from "../src/sequencer/SequencerVault.sol";
import {SequencerVaultProxy} from "../src/sequencer/SequencerVaultProxy.sol";

// Mocks for testing
import {MockTON} from "../src/mocks/MockTON.sol";
import {MockWTON} from "../src/mocks/MockWTON.sol";

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
    uint256 constant RAT_SLASHING_PENALTY = 100 * RAY; // 100 WTON
    uint256 constant RAT_VALIDATOR_BUFFER = 100 * RAY; // 100 WTON
    uint256 constant RAT_MINIMUM_THRESHOLD = 200 * RAY; // 200 WTON (D_min)

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

    // Manager Implementations
    address public seigManagerV1_3Impl;
    address public seigManagerImpl;
    address public depositManagerBaseImpl;
    address public depositManagerSetDelayImpl;
    address public depositManagerV1_1Impl;
    address public depositManagerV1_2Impl;
    address public layer2ManagerV1_1Impl;
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
    address public sequencerVaultProxy;
    address public sequencerVaultImpl;

    // Optimism Contracts (read from environment)
    address public disputeGameFactory;
    address public systemConfig;

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
        _setupCrossReferences(deployer);
        _connectToOptimism();
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

        // SeigManager
        address seigManagerV1_2Impl = address(new SeigManagerV1_2());
        console.log("SeigManagerV1_2 Impl:", seigManagerV1_2Impl);
        IProxy(seigManagerProxy).upgradeTo(seigManagerV1_2Impl);

        seigManagerV1_3Impl = address(new SeigManagerV1_3());
        console.log("SeigManagerV1_3 Impl:", seigManagerV1_3Impl);

        seigManagerImpl = address(new SeigManagerV1_4());
        console.log("SeigManagerV1_4 Impl:", seigManagerImpl);

        // DepositManager
        depositManagerBaseImpl = address(new DepositManager());
        console.log("DepositManager Base Impl:", depositManagerBaseImpl);
        IProxy(depositManagerProxy).upgradeTo(depositManagerBaseImpl);

        depositManagerSetDelayImpl = address(new DepositManager_setWithdrawalDelay());
        console.log("DepositManager_setWithdrawalDelay Impl:", depositManagerSetDelayImpl);

        depositManagerV1_1Impl = address(new DepositManagerV1_1());
        console.log("DepositManagerV1_1 Impl:", depositManagerV1_1Impl);

        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        console.log("DepositManagerV1_2 Impl:", depositManagerV1_2Impl);

        // Layer2Manager
        layer2ManagerV1_1Impl = address(new Layer2ManagerV1_1());
        console.log("Layer2ManagerV1_1 Impl:", layer2ManagerV1_1Impl);
        IProxy(layer2ManagerProxy).upgradeTo(layer2ManagerV1_1Impl);

        layer2ManagerImpl = address(new Layer2ManagerV1_2());
        console.log("Layer2ManagerV1_2 Impl:", layer2ManagerImpl);

        // L1BridgeRegistry
        l1BridgeRegistryImpl = address(new L1BridgeRegistryV1_2());
        console.log("L1BridgeRegistryV1_2 Impl:", l1BridgeRegistryImpl);
        IProxy(l1BridgeRegistryProxy).upgradeTo(l1BridgeRegistryImpl);
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

        // Setup SeigManager multi-implementation routing
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(seigManagerV1_3Impl, true);
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(seigManagerImpl, true);

        // V1_3 selectors
        bytes4[] memory v1_3Selectors = new bytes4[](6);
        v1_3Selectors[0] = SeigManagerV1_3.pause.selector;
        v1_3Selectors[1] = SeigManagerV1_3.unpause.selector;
        v1_3Selectors[2] = SeigManagerV1_3.excludeFromL2Seigniorage.selector;
        v1_3Selectors[3] = SeigManagerV1_3.includeFromL2Seigniorage.selector;
        v1_3Selectors[4] = SeigManagerV1_3.claimableL2Seigniorage.selector;
        v1_3Selectors[5] = SeigManagerV1_3.estimatedDistribute.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(v1_3Selectors, seigManagerV1_3Impl);

        // V1_4 selectors
        bytes4[] memory v1_4Selectors = new bytes4[](31);
        v1_4Selectors[0] = SeigManagerV1_4.setValidatorReward.selector;
        v1_4Selectors[1] = SeigManagerV1_4.setDaoDistributionRatio.selector;
        v1_4Selectors[2] = SeigManagerV1_4.setMinStakingRatio.selector;
        v1_4Selectors[3] = SeigManagerV1_4.setValidatorDistributionRatio.selector;
        v1_4Selectors[4] = SeigManagerV1_4.setHalfSaturationPoint.selector;
        v1_4Selectors[5] = SeigManagerV1_4.setStakedSeigFactor.selector;
        v1_4Selectors[6] = SeigManagerV1_4.migrateToV3.selector;
        v1_4Selectors[7] = SeigManagerV1_4.onBridgedTONChange.selector;
        v1_4Selectors[8] = SeigManagerV1_4.setMaxChallengers.selector;
        v1_4Selectors[9] = SeigManagerV1_4.setMaxFraudProofCost.selector;
        v1_4Selectors[10] = SeigManagerV1_4.setSequencerVault.selector;
        v1_4Selectors[11] = SeigManagerV1_4.updateSeigniorage.selector;
        v1_4Selectors[12] = SeigManagerV1_4.updateSeigniorageLayer.selector;
        v1_4Selectors[13] = SeigManagerV1_4.hyperbolicSaturation.selector;
        v1_4Selectors[14] = SeigManagerV1_4.checkCurrentEligibility.selector;
        v1_4Selectors[15] = SeigManagerV1_4.calculateL2Seigniorage.selector;
        v1_4Selectors[16] = SeigManagerV1_4.calculateSequencerReward.selector;
        v1_4Selectors[17] = bytes4(keccak256("daoDistributionRatio()"));
        v1_4Selectors[18] = bytes4(keccak256("minStakingRatio()"));
        v1_4Selectors[19] = bytes4(keccak256("validatorDistributionRatio()"));
        v1_4Selectors[20] = bytes4(keccak256("halfSaturationPoint()"));
        v1_4Selectors[21] = bytes4(keccak256("stakedSeigFactor()"));
        v1_4Selectors[22] = bytes4(keccak256("totalEffectiveBridgedTON()"));
        v1_4Selectors[23] = bytes4(keccak256("bridgedTONInfo(address)"));
        v1_4Selectors[24] = bytes4(keccak256("validatorReward()"));
        v1_4Selectors[25] = bytes4(keccak256("maxChallengers()"));
        v1_4Selectors[26] = bytes4(keccak256("maxFraudProofCost()"));
        v1_4Selectors[27] = bytes4(keccak256("v3Migrated()"));
        v1_4Selectors[28] = bytes4(keccak256("v3MigrationBlock()"));
        v1_4Selectors[29] = bytes4(keccak256("sequencerVault()"));
        v1_4Selectors[30] = SeigManagerV1_4.getEffectiveBridgedTON.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(v1_4Selectors, seigManagerImpl);

        console.log("SeigManager multi-implementation configured");

        // Initialize DepositManager
        DepositManager(depositManagerProxy).initialize(
            wton,
            layer2RegistryProxy,
            seigManagerProxy,
            GLOBAL_WITHDRAWAL_DELAY,
            address(0)
        );
        console.log("DepositManager initialized");

        // Setup DepositManager multi-implementation routing
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(depositManagerSetDelayImpl, true);
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(depositManagerV1_1Impl, true);
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(depositManagerV1_2Impl, true);

        bytes4[] memory dmIndex1Selectors = new bytes4[](2);
        dmIndex1Selectors[0] = DepositManager_setWithdrawalDelay.setWithdrawalDelay.selector;
        dmIndex1Selectors[1] = DepositManager_setWithdrawalDelay.setWithdrawalDelayByOwner.selector;
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(dmIndex1Selectors, depositManagerSetDelayImpl);

        bytes4[] memory dmIndex2Selectors = new bytes4[](3);
        dmIndex2Selectors[0] = DepositManagerV1_1.setMinDepositGasLimit.selector;
        dmIndex2Selectors[1] = DepositManagerV1_1.setAddresses.selector;
        dmIndex2Selectors[2] = DepositManagerV1_1.withdrawAndDepositL2.selector;
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(dmIndex2Selectors, depositManagerV1_1Impl);

        bytes4[] memory dmIndex3Selectors = new bytes4[](2);
        dmIndex3Selectors[0] = DepositManagerV1_2.withdrawAndDepositL2.selector;
        dmIndex3Selectors[1] = DepositManagerV1_2.requestWithdrawal.selector;
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(dmIndex3Selectors, depositManagerV1_2Impl);

        console.log("DepositManager multi-implementation configured");
        console.log("");
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

        bytes memory ratInitData = abi.encodeWithSelector(
            RAT.initialize.selector,
            seigManagerProxy,
            wton,
            ton,
            layer2ManagerProxy,
            deployer,
            RAT_TRIGGER_PROBABILITY
        );

        // Deploy RAT proxy with separate admin (not deployer to avoid TransparentUpgradeableProxy admin restriction)
        ratProxy = address(new RATProxy(ratImpl, PROXY_ADMIN, ratInitData));
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
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, PROXY_ADMIN, validatorRewardInitData));
        console.log("ValidatorReward Proxy:", validatorPoolProxy);

        // Deploy SequencerVault
        sequencerVaultImpl = address(new SequencerVault());
        console.log("SequencerVault Impl:", sequencerVaultImpl);

        SequencerVaultProxy svProxy = new SequencerVaultProxy();
        sequencerVaultProxy = address(svProxy);
        console.log("SequencerVault Proxy:", sequencerVaultProxy);

        IProxy(sequencerVaultProxy).upgradeTo(sequencerVaultImpl);

        SequencerVault(sequencerVaultProxy).initialize(
            seigManagerProxy,
            wton,
            ton,
            layer2ManagerProxy,
            l1BridgeRegistryProxy,
            deployer
        );
        console.log("SequencerVault initialized");
        console.log("");
    }

    // ==========================================
    // Step 9: Configure V3 Contracts
    // ==========================================
    function _configureV3Contracts(address deployer) internal {
        console.log("--- Step 9: Configure V3 Parameters ---");

        // RAT parameters (devnet-optimized)
        RAT(ratProxy).setRatTriggerProbability(RAT_TRIGGER_PROBABILITY);
        RAT(ratProxy).setSlashingPenalty(RAT_SLASHING_PENALTY);
        RAT(ratProxy).setValidatorBuffer(RAT_VALIDATOR_BUFFER);
        RAT(ratProxy).setMinimumThreshold(RAT_MINIMUM_THRESHOLD);
        RAT(ratProxy).setEvidenceSubmissionPeriod(RAT_EVIDENCE_PERIOD);
        RAT(ratProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);
        RAT(ratProxy).setTreasury(deployer);
        RAT(ratProxy).setRelaxedValidatorCheck(true); // V3: 초기에는 C_off 기준으로 완화
        console.log("RAT parameters configured");
        console.log("");
    }

    // ==========================================
    // Step 10: Setup Cross-References
    // ==========================================
    function _setupCrossReferences(address deployer) internal {
        console.log("--- Step 10: Setup Cross-References ---");

        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        console.log("SeigManager.setLayer2Manager done");

        SeigManagerV1_4(seigManagerProxy).setValidatorReward(validatorPoolProxy);
        console.log("SeigManager.setValidatorReward done");

        Layer2ManagerV1_1(layer2ManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton,
            deployer,
            depositManagerProxy,
            seigManagerProxy,
            address(0)
        );
        console.log("Layer2Manager.setAddresses done");

        // Layer2Manager multi-implementation
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(layer2ManagerImpl, true);

        bytes4[] memory l2mV1_2Selectors = new bytes4[](5);
        l2mV1_2Selectors[0] = Layer2ManagerV1_2.getBridgedTONByLayer.selector;
        l2mV1_2Selectors[1] = Layer2ManagerV1_2.getBridgedTON.selector;
        l2mV1_2Selectors[2] = Layer2ManagerV1_2.getLayer2BySystemConfig.selector;
        l2mV1_2Selectors[3] = Layer2ManagerV1_2.setSequencerVault.selector;
        l2mV1_2Selectors[4] = bytes4(keccak256("sequencerVault()"));
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(l2mV1_2Selectors, layer2ManagerImpl);

        Layer2ManagerV1_2(layer2ManagerProxy).setSequencerVault(sequencerVaultProxy);
        console.log("Layer2Manager.setSequencerVault done");

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

        DepositManagerV1_1(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
        console.log("DepositManager.setAddresses done");
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
            console.log("DisputeGameFactory.setRAT(", ratProxy, ") done (called by Optimism deployer)");
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

        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfigByManager(
            systemConfig,
            3, // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
            ton // L2 TON address (using L1 TON as placeholder, not actually used for Optimism)
        );
        console.log("SystemConfig registered in L1BridgeRegistry");
        console.log("  This also registered DisputeGameFactory for RAT trigger");

        console.log("");
    }

    // ==========================================
    // Step 12: Mint Test Tokens
    // ==========================================
    function _mintTestTokens() internal {
        console.log("--- Step 12: Mint Test Tokens ---");

        address[4] memory testAccounts = [DEPLOYER, VALIDATOR, PROPOSER, CHALLENGER];

        for (uint256 i = 0; i < testAccounts.length; i++) {
            // Mint TON (18 decimals)
            MockTON(ton).mint(testAccounts[i], 100000 * 1e18);

            // Mint WTON (27 decimals)
            MockWTON(wton).mint(testAccounts[i], 100000 * RAY);
        }

        console.log("Minted 100,000 TON and 100,000 WTON to each test account:");
        console.log("  - DEPLOYER:", DEPLOYER);
        console.log("  - VALIDATOR:", VALIDATOR);
        console.log("  - PROPOSER:", PROPOSER);
        console.log("  - CHALLENGER:", CHALLENGER);
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
            '  "validatorRewardProxy": "', vm.toString(validatorPoolProxy), '",\n',
            '  "sequencerVaultProxy": "', vm.toString(sequencerVaultProxy), '",\n'
        ));
    }

    function _buildJsonPart4() internal view returns (string memory) {
        return string(abi.encodePacked(
            '  "disputeGameFactory": "', vm.toString(disputeGameFactory), '",\n',
            '  "systemConfig": "', vm.toString(systemConfig), '",\n',
            '  "accounts": {\n',
            '    "optimismDeployer": "', vm.toString(OPTIMISM_DEPLOYER), '",\n',
            '    "tonStakingDeployer": "', vm.toString(DEPLOYER), '",\n',
            '    "validator": "', vm.toString(VALIDATOR), '",\n',
            '    "proposer": "', vm.toString(PROPOSER), '",\n',
            '    "challenger": "', vm.toString(CHALLENGER), '"\n',
            '  }\n',
            "}"
        ));
    }

    function _saveDeployment() internal {
        // Build JSON in parts to avoid stack too deep
        string memory json = string(abi.encodePacked(
            _buildJsonPart1(),
            _buildJsonPart2(),
            _buildJsonPart3(),
            _buildJsonPart4()
        ));

        // Print JSON for bash script to save
        console.log("\n=== DEPLOYMENT_JSON_START ===");
        console.log(json);
        console.log("=== DEPLOYMENT_JSON_END ===");
    }
}
