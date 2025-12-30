// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, console} from "forge-std/Script.sol";
import {RAT} from "../src/validator/RAT.sol";
import {RATProxy} from "../src/validator/RATProxy.sol";
import {MockTON} from "../test/v3/mocks/MockTON.sol";
import {MockWTON} from "../test/v3/mocks/MockWTON.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/// @notice Mock SeigManager for E2E testing
contract MockSeigManager {
    address public ton;
    address public wton;

    constructor(address _ton, address _wton) {
        ton = _ton;
        wton = _wton;
    }

    function stakeOf(address, address) external pure returns (uint256) {
        return 0;
    }
}

/// @notice Mock Layer2Manager for E2E testing
contract MockLayer2Manager {
    mapping(address => bool) public registeredL2s;

    function registerL2(address systemConfig) external {
        registeredL2s[systemConfig] = true;
    }

    function isRegistered(address systemConfig) external view returns (bool) {
        return registeredL2s[systemConfig];
    }
}

/// @notice Mock L1BridgeRegistry for E2E testing
contract MockL1BridgeRegistry {
    mapping(address => address) public disputeGameFactoryForSystemConfig;
    mapping(address => address) public rollupConfigByFactory;

    function setDisputeGameFactory(address systemConfig, address factory) external {
        disputeGameFactoryForSystemConfig[systemConfig] = factory;
        rollupConfigByFactory[factory] = systemConfig;
    }

    function getDisputeGameFactory(address systemConfig) external view returns (address) {
        return disputeGameFactoryForSystemConfig[systemConfig];
    }

    /// @notice Required by RAT.onlyValidFactory modifier
    function rollupConfigWithDisputeGameFactory(address factory) external view returns (address) {
        return rollupConfigByFactory[factory];
    }
}

/// @notice Mock DisputeGameFactory for E2E testing
/// @dev Allows triggering RAT attention tests without full Optimism stack
interface IRAT {
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;
}

contract MockDisputeGameFactory {
    address public rat;
    address public systemConfig;
    uint256 public gameCount;

    event GameCreated(address indexed gameAddress, uint32 batchIndex, bytes32 batchHash);

    constructor(address _rat, address _systemConfig) {
        rat = _rat;
        systemConfig = _systemConfig;
    }

    /// @notice Creates a mock dispute game and triggers RAT attention test
    function createGame(uint32 batchIndex, bytes32 batchHash, bytes32 blockHash) external returns (address) {
        gameCount++;
        // Use a deterministic address based on gameCount
        address gameAddress = address(uint160(uint256(keccak256(abi.encodePacked(address(this), gameCount)))));

        // Trigger RAT attention test
        IRAT(rat).triggerAttentionTest(gameAddress, systemConfig, batchIndex, batchHash, blockHash);

        emit GameCreated(gameAddress, batchIndex, batchHash);
        return gameAddress;
    }
}

/// @notice Mock SystemConfig for E2E testing
contract MockSystemConfig {
    uint256 public chainId;

    constructor(uint256 _chainId) {
        chainId = _chainId;
    }
}

/// @title DeployRATForE2E
/// @notice Complete E2E deployment script for RAT testing with Anvil
/// @dev Deploys all necessary mock contracts and RAT
contract DeployRATForE2E is Script {
    // Anvil default accounts
    uint256 constant DEPLOYER_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // Second account for testing
    uint256 constant VALIDATOR_PRIVATE_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    address constant VALIDATOR = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // RAY constant
    uint256 constant RAY = 1e27;

    // Deployed addresses
    address public ton;
    address public wton;
    address public seigManager;
    address public layer2Manager;
    address public l1BridgeRegistry;
    address public systemConfig;
    address public systemConfig2;  // Second L2 for multi-L2 tests
    address public ratProxy;
    address public ratImpl;
    address public proxyAdmin;
    address public disputeGameFactory;
    address public disputeGameFactory2;  // For second L2

    function run() external {
        console.log("=== RAT E2E Deployment ===");
        console.log("Deployer:", DEPLOYER);
        console.log("Validator:", VALIDATOR);

        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        // 1. Deploy mock tokens
        MockTON mockTon = new MockTON();
        ton = address(mockTon);
        console.log("TON deployed:", ton);

        MockWTON mockWton = new MockWTON();
        wton = address(mockWton);
        mockWton.setTON(ton);
        console.log("WTON deployed:", wton);

        // 2. Deploy mock infrastructure
        MockSeigManager mockSeig = new MockSeigManager(ton, wton);
        seigManager = address(mockSeig);
        console.log("SeigManager deployed:", seigManager);

        MockLayer2Manager mockL2Manager = new MockLayer2Manager();
        layer2Manager = address(mockL2Manager);
        console.log("Layer2Manager deployed:", layer2Manager);

        MockL1BridgeRegistry mockBridgeReg = new MockL1BridgeRegistry();
        l1BridgeRegistry = address(mockBridgeReg);
        console.log("L1BridgeRegistry deployed:", l1BridgeRegistry);

        // 3. Deploy mock SystemConfigs for test L2s
        MockSystemConfig mockSysConfig = new MockSystemConfig(901); // Test chain ID
        systemConfig = address(mockSysConfig);
        mockL2Manager.registerL2(systemConfig);
        console.log("SystemConfig deployed:", systemConfig);

        // Second L2 for multi-L2 tests
        MockSystemConfig mockSysConfig2 = new MockSystemConfig(902);
        systemConfig2 = address(mockSysConfig2);
        mockL2Manager.registerL2(systemConfig2);
        console.log("SystemConfig2 deployed:", systemConfig2);

        // 4. Deploy RAT with proxy
        ratImpl = address(new RAT());
        console.log("RAT Implementation deployed:", ratImpl);

        proxyAdmin = address(new ProxyAdmin());
        console.log("ProxyAdmin deployed:", proxyAdmin);

        // NOTE: ratTriggerProbability should be determined based on game theory formula:
        // C_off ≥ (c_m · N) / π_a
        uint256 ratTriggerProbability = 0.01e27; // 1% - adjust based on expected N, c_m, C_off
        bytes memory initData = abi.encodeWithSelector(
            RAT.initialize.selector,
            seigManager,
            wton,
            ton,
            layer2Manager,
            DEPLOYER,
            ratTriggerProbability
        );

        ratProxy = address(new RATProxy(ratImpl, proxyAdmin, initData));
        console.log("RAT Proxy deployed:", ratProxy);

        // 5. Configure RAT
        // Note: RAT uses TON for deposits, so parameters should be in TON units (18 decimals)
        RAT rat = RAT(ratProxy);
        rat.setSlashingPenalty(100 * 1e18);      // 100 TON
        rat.setValidatorBuffer(100 * 1e18);       // 100 TON
        rat.setMinimumThreshold(200 * 1e18);      // 200 TON (D_min)
        rat.setRatTriggerProbability(RAY);       // 100% for testing (always trigger)
        rat.setEvidenceSubmissionPeriod(1 hours);
        rat.setL1BridgeRegistry(l1BridgeRegistry);
        rat.setTreasury(DEPLOYER);
        console.log("RAT configured with TON units");

        // 6. Mint TON to validator for testing (RAT uses TON for deposits)
        mockTon.mint(VALIDATOR, 1000 * 1e18); // 1000 TON (18 decimals)
        console.log("Minted 1000 TON to validator");

        // 7. Mint TON to deployer for testing
        mockTon.mint(DEPLOYER, 1000 * 1e18); // 1000 TON (18 decimals)
        console.log("Minted 1000 TON to deployer");

        // Also mint WTON for other tests
        mockWton.mint(VALIDATOR, 1000 * RAY); // 1000 WTON
        mockWton.mint(DEPLOYER, 1000 * RAY);
        console.log("Minted 1000 WTON to validator and deployer");

        vm.stopBroadcast();

        // Output deployment summary
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("TON:", ton);
        console.log("WTON:", wton);
        console.log("SeigManager:", seigManager);
        console.log("Layer2Manager:", layer2Manager);
        console.log("L1BridgeRegistry:", l1BridgeRegistry);
        console.log("SystemConfig:", systemConfig);
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT Implementation:", ratImpl);
        console.log("ProxyAdmin:", proxyAdmin);
        console.log("");
        console.log("=== Environment Variables ===");
        console.log("export RAT_ADDRESS=", ratProxy);
        console.log("export TON_ADDRESS=", ton);
        console.log("export WTON_ADDRESS=", wton);
        console.log("export SYSTEM_CONFIG_ADDRESS=", systemConfig);
        console.log("export E2E_RPC_URL=http://localhost:8545");
        console.log("export E2E_PRIVATE_KEY=59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");
    }
}
