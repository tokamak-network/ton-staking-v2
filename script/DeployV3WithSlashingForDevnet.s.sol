// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DeployV3FullForDevnet.s.sol";

// Slashing Implementations
import {Layer2Manager_Slashing} from "../src/layer2/Layer2Manager_Slashing.sol";
import {SeigManager_Slashing} from "../src/stake/managers/SeigManager_Slashing.sol";
import {DepositManager_Slashing} from "../src/stake/managers/DepositManager_Slashing.sol";

/**
 * @title DeployV3WithSlashingForDevnet
 * @notice DeployV3FullForDevnet를 상속받아 Slashing 기능을 추가하는 Devnet 배포 스크립트
 * @dev Stack too deep 문제 해결을 위해 함수를 작게 분리
 *
 * Usage:
 *   forge script script/DeployV3WithSlashingForDevnet.s.sol:DeployV3WithSlashingForDevnet \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast \
 *     --private-key $DEPLOYER_PRIVATE_KEY
 */
contract DeployV3WithSlashingForDevnet is DeployV3FullForDevnet {
    // ==========================================
    // Slashing Implementations
    // ==========================================
    address public seigManagerSlashingImpl;
    address public depositManagerSlashingImpl;
    address public layer2ManagerSlashingImpl;

    // Slashing parameters
    uint256 constant SLASHING_REWARD_RATE = 1000; // 10% = 1000 (basis points)

    function run() public override {
        _loadOptimismAddresses();
        vm.startBroadcast();
        address deployer = msg.sender;

        _deployTokens();
        _deployCoinageInfrastructure(deployer);
        _deployLayer2Registry(deployer);
        _deployManagerProxies();
        _deployManagerImplementations();

        // Slashing 구현체 배포 (초기화 전에)
        _deploySlashingImplementations();

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

        // V3 Migration (after all setup is complete)
        _setupV3ParameterSelectors();
        _setV3Parameters();
        _migrateToV3();

        vm.stopBroadcast();

        _printSummaryWithSlashing();
        _saveDeploymentWithSlashing();
    }

    /// @notice Entry point for generating devnet allocs with slashing support
    function runForDevnetAlloc() external override {
        string memory allocsPath = vm.envOr(
            "TARGET_L1_ALLOC",
            string.concat(vm.projectRoot(), "/.devnet/allocs-l1.json")
        );
        console.log("Loading existing L1 allocs from:", allocsPath);
        vm.loadAllocs(allocsPath);

        console.log("Optimism deployer:", OPTIMISM_DEPLOYER);
        console.log("TON Staking deployer:", DEPLOYER);

        run();

        string memory outputPath = vm.envOr(
            "STATE_DUMP_PATH",
            string.concat(vm.projectRoot(), "/.devnet/allocs-l1-staking-v3-slashing.json")
        );
        console.log("Dumping state to:", outputPath);
        vm.dumpState(outputPath);
    }

    // ==========================================
    // Slashing 구현체 배포
    // ==========================================
    function _deploySlashingImplementations() internal {
        console.log("--- Deploying Slashing Implementations ---");

        seigManagerSlashingImpl = address(new SeigManager_Slashing());
        console.log("SeigManager_Slashing Impl:", seigManagerSlashingImpl);

        depositManagerSlashingImpl = address(new DepositManager_Slashing());
        console.log("DepositManager_Slashing Impl:", depositManagerSlashingImpl);

        layer2ManagerSlashingImpl = address(new Layer2Manager_Slashing());
        console.log("Layer2Manager_Slashing Impl:", layer2ManagerSlashingImpl);

        console.log("");
    }

    // ==========================================
    // Override: Initialize Managers with Slashing
    // ==========================================
    function _initializeManagers(address deployer) internal override {
        // 부모의 기본 초기화 호출
        super._initializeManagers(deployer);

        // Slashing routing 추가
        _setupSeigManagerSlashing();
        _setupDepositManagerSlashing();
    }

    function _setupSeigManagerSlashing() internal {
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
            seigManagerSlashingImpl,
            true
        );
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = SeigManager_Slashing.onSlash.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
            selectors,
            seigManagerSlashingImpl
        );
        console.log("SeigManager Slashing routing configured");
    }

    function _setupDepositManagerSlashing() internal {
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
            depositManagerSlashingImpl,
            true
        );
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = DepositManager_Slashing.setSlashingRewardRate.selector;
        selectors[1] = DepositManager_Slashing.slash.selector;
        selectors[2] = bytes4(keccak256("slashingRewardRate()"));
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(
            selectors,
            depositManagerSlashingImpl
        );

        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(
            SLASHING_REWARD_RATE
        );
        console.log("DepositManager Slashing routing configured, rate:", SLASHING_REWARD_RATE);
    }

    // ==========================================
    // Override: Cross References with Slashing
    // ==========================================
    function _setupCrossReferences(address deployer) internal override {
        super._setupCrossReferences(deployer);
        _setupLayer2ManagerSlashing();
        _registerSystemConfigInBridgeRegistry();
    }

    /// @notice Register SystemConfig in L1BridgeRegistry for E2E tests
    /// This is required for Layer2Manager.registerCandidateAddOn() to work
    function _registerSystemConfigInBridgeRegistry() internal {
        console.log("--- Registering SystemConfig in L1BridgeRegistry ---");
        
        // Add deployer as manager (required to call registerRollupConfigByManager)
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).addManager(msg.sender);
        console.log("Added deployer as L1BridgeRegistry manager:", msg.sender);
        
        // Register SystemConfig with TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfigByManager(
            systemConfig,
            3, // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
            ton // L2 TON address placeholder
        );
        console.log("SystemConfig registered in L1BridgeRegistry:", systemConfig);
        console.log("  Type: 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)");
        console.log("");
    }

    function _setupLayer2ManagerSlashing() internal {
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(
            layer2ManagerSlashingImpl,
            true
        );
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = Layer2Manager_Slashing.slashingCandidate.selector;
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(
            selectors,
            layer2ManagerSlashingImpl
        );
        console.log("Layer2Manager Slashing routing configured");
    }

    // ==========================================
    // V3 Migration
    // ==========================================

    /// @notice Register V3 parameter setter selectors in SeigManagerProxy
    /// @dev These selectors must be registered before calling the setter functions
    function _setupV3ParameterSelectors() internal {
        console.log("--- Registering V3 Parameter Selectors ---");

        bytes4[] memory s = new bytes4[](7);
        s[0] = SeigManagerV3_1.setHalfSaturationPoint.selector;
        s[1] = SeigManagerV3_1.setMinStakingRatio.selector;
        s[2] = SeigManagerV3_1.setDaoDistributionRatio.selector;
        s[3] = SeigManagerV3_1.setValidatorDistributionRatio.selector;
        s[4] = SeigManagerV3_1.setMaxChallengers.selector;
        s[5] = SeigManagerV3_1.setMaxFraudProofCost.selector;
        s[6] = SeigManagerV3_1.setSequencerAdditionalReward.selector;

        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(s, seigManagerV3_1Impl);
        console.log("  7 V3 parameter setters registered");
        console.log("");
    }

    /// @notice Set V3 seigniorage distribution parameters
    /// @dev These must be set before calling migrateToV3()
    function _setV3Parameters() internal {
        console.log("--- Setting V3 Parameters ---");

        SeigManagerV3_1 seig = SeigManagerV3_1(seigManagerProxy);

        // k: Half saturation point for hyperbolic distribution
        seig.setHalfSaturationPoint(HALF_SATURATION_POINT);
        console.log("  halfSaturationPoint: 10M TON");

        // theta: Minimum staking ratio requirement
        seig.setMinStakingRatio(MIN_STAKING_RATIO);
        console.log("  minStakingRatio: 10%");

        // d: DAO distribution ratio
        seig.setDaoDistributionRatio(DAO_DISTRIBUTION_RATIO);
        console.log("  daoDistributionRatio: 20%");

        // alpha: Validator distribution ratio
        seig.setValidatorDistributionRatio(VALIDATOR_DISTRIBUTION_RATIO);
        console.log("  validatorDistributionRatio: 20%");

        // hMax: Maximum challengers per game
        seig.setMaxChallengers(MAX_CHALLENGERS);
        console.log("  maxChallengers: 10");

        // cMax: Maximum fraud proof cost
        seig.setMaxFraudProofCost(MAX_FRAUD_PROOF_COST);
        console.log("  maxFraudProofCost: 1000 WTON");

        // delta: Sequencer additional reward
        seig.setSequencerAdditionalReward(SEQUENCER_ADDITIONAL_REWARD);
        console.log("  sequencerAdditionalReward: 100 WTON");

        console.log("");
    }

    /// @notice Execute V3 migration
    /// @dev This activates V3 seigniorage distribution logic
    function _migrateToV3() internal {
        console.log("--- Migrating to V3 ---");

        SeigManagerV3_1(seigManagerProxy).migrateToV3();

        console.log("V3 Migration completed!");
        console.log("  v3Migrated: true");
        console.log("  V3 seigniorage distribution now active");
        console.log("");
    }

    // ==========================================
    // Summary & Save (stack-safe version)
    // ==========================================
    function _printSummaryWithSlashing() internal view {
        console.log("=== Deployment Summary (With Slashing for Devnet) ===");
        console.log("");
        console.log("Tokens:");
        console.log("  TON:", ton);
        console.log("  WTON:", wton);
        console.log("");
        console.log("Managers:");
        console.log("  SeigManager Proxy:", seigManagerProxy);
        console.log("  DepositManager Proxy:", depositManagerProxy);
        console.log("  Layer2Manager Proxy:", layer2ManagerProxy);
        console.log("");
        console.log("Slashing Implementations:");
        console.log("  SeigManager_Slashing:", seigManagerSlashingImpl);
        console.log("  DepositManager_Slashing:", depositManagerSlashingImpl);
        console.log("  Layer2Manager_Slashing:", layer2ManagerSlashingImpl);
        console.log("");
        console.log("V3 Contracts:");
        console.log("  RAT Proxy:", ratProxy);
        console.log("  ValidatorReward Proxy:", validatorPoolProxy);
        console.log("");
        console.log("DAO:");
        console.log("  DAOCommittee Proxy:", daoCommitteeProxy);
        console.log("");
        console.log("Optimism:");
        console.log("  DisputeGameFactory:", disputeGameFactory);
        console.log("  SystemConfig:", systemConfig);
    }

    function _saveDeploymentWithSlashing() internal {
        string memory json = _jsonStart();
        json = string.concat(json, _jsonTokens());
        json = string.concat(json, _jsonCore());
        json = string.concat(json, _jsonManagers());
        json = string.concat(json, _jsonSlashing());
        json = string.concat(json, _jsonV3());
        json = string.concat(json, _jsonDAO());
        json = string.concat(json, _jsonOptimism());
        json = string.concat(json, _jsonEnd());

        vm.writeFile("deployments/v3-devnet-slashing.json", json);
        console.log("Deployment saved to deployments/v3-devnet-slashing.json");
    }

    function _jsonStart() internal pure returns (string memory) {
        return "{\n";
    }

    function _jsonTokens() internal view returns (string memory) {
        return
            string.concat(
                '  "ton": "',
                vm.toString(ton),
                '",\n',
                '  "wton": "',
                vm.toString(wton),
                '",\n'
            );
    }

    function _jsonCore() internal view returns (string memory) {
        return
            string.concat(
                '  "coinageFactory": "',
                vm.toString(coinageFactory),
                '",\n',
                '  "layer2RegistryProxy": "',
                vm.toString(layer2RegistryProxy),
                '",\n'
            );
    }

    function _jsonManagers() internal view returns (string memory) {
        string memory p1 = string.concat(
            '  "seigManagerProxy": "',
            vm.toString(seigManagerProxy),
            '",\n'
        );
        string memory p2 = string.concat(
            '  "depositManagerProxy": "',
            vm.toString(depositManagerProxy),
            '",\n'
        );
        string memory p3 = string.concat(
            '  "layer2ManagerProxy": "',
            vm.toString(layer2ManagerProxy),
            '",\n'
        );
        string memory p4 = string.concat(
            '  "l1BridgeRegistryProxy": "',
            vm.toString(l1BridgeRegistryProxy),
            '",\n'
        );
        string memory p5 = string.concat(
            '  "operatorManagerFactory": "',
            vm.toString(operatorManagerFactory),
            '",\n'
        );
        return string.concat(p1, p2, p3, p4, p5);
    }

    function _jsonSlashing() internal view returns (string memory) {
        string memory p1 = string.concat(
            '  "seigManagerSlashingImpl": "',
            vm.toString(seigManagerSlashingImpl),
            '",\n'
        );
        string memory p2 = string.concat(
            '  "depositManagerSlashingImpl": "',
            vm.toString(depositManagerSlashingImpl),
            '",\n'
        );
        string memory p3 = string.concat(
            '  "layer2ManagerSlashingImpl": "',
            vm.toString(layer2ManagerSlashingImpl),
            '",\n'
        );
        return string.concat(p1, p2, p3);
    }

    function _jsonV3() internal view returns (string memory) {
        return
            string.concat(
                '  "ratProxy": "',
                vm.toString(ratProxy),
                '",\n',
                '  "validatorPoolProxy": "',
                vm.toString(validatorPoolProxy),
                '",\n'
            );
    }

    function _jsonDAO() internal view returns (string memory) {
        string memory p1 = string.concat(
            '  "daoCommitteeProxy": "',
            vm.toString(daoCommitteeProxy),
            '",\n'
        );
        string memory p2 = string.concat(
            '  "candidateFactoryProxy": "',
            vm.toString(candidateFactoryProxy),
            '",\n'
        );
        string memory p3 = string.concat(
            '  "candidateAddOnFactoryProxy": "',
            vm.toString(candidateAddOnFactoryProxy),
            '",\n'
        );
        return string.concat(p1, p2, p3);
    }

    function _jsonOptimism() internal view returns (string memory) {
        string memory p1 = string.concat(
            '  "disputeGameFactory": "',
            vm.toString(disputeGameFactory),
            '",\n'
        );
        string memory p2 = string.concat('  "systemConfig": "', vm.toString(systemConfig), '",\n');
        string memory p3 = string.concat(
            '  "anchorStateRegistry": "',
            vm.toString(anchorStateRegistry),
            '",\n'
        );
        string memory p4 = string.concat('  "mockLayer2": "', vm.toString(mockLayer2), '",\n');
        string memory p5 = string.concat(
            '  "operatorManager": "',
            vm.toString(operatorManager),
            '"\n'
        );
        return string.concat(p1, p2, p3, p4, p5);
    }

    function _jsonEnd() internal pure returns (string memory) {
        return "}";
    }
}
