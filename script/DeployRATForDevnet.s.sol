// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, console} from "forge-std/Script.sol";
import {RAT} from "../src/validator/RAT.sol";
import {RATProxy} from "../src/validator/RATProxy.sol";
import {MockTON} from "../test/v3/mocks/MockTON.sol";
import {MockWTON} from "../test/v3/mocks/MockWTON.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/// @notice Mock SeigManager for devnet testing
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

/// @notice Mock Layer2Manager for devnet testing
contract MockLayer2Manager {
    mapping(address => bool) public registeredL2s;

    function registerL2(address systemConfig) external {
        registeredL2s[systemConfig] = true;
    }

    function isRegistered(address systemConfig) external view returns (bool) {
        return registeredL2s[systemConfig];
    }
}

/// @notice Mock L1BridgeRegistry for devnet testing
/// @dev Used to validate DisputeGameFactory calls
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

/// @title DeployRATForDevnet
/// @notice Deploys RAT contract for use with lib/optimism devnet
/// @dev This script only deploys RAT and mock dependencies.
///      Optimism contracts (DisputeGameFactory, SystemConfig, etc.) are
///      already deployed by lib/optimism devnet-allocs.
///      After deployment, deploy-rat-devnet.sh connects RAT to DisputeGameFactory.
contract DeployRATForDevnet is Script {
    // Anvil default accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant VALIDATOR = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant PROPOSER = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant CHALLENGER = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    // RAY constant (27 decimals)
    uint256 constant RAY = 1e27;

    function run() external {
        console.log("=== RAT Devnet Deployment ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", DEPLOYER);

        vm.startBroadcast();

        // 1. Deploy mock tokens
        MockTON mockTon = new MockTON();
        address ton = address(mockTon);
        console.log("TON deployed:", ton);

        MockWTON mockWton = new MockWTON();
        address wton = address(mockWton);
        mockWton.setTON(ton);
        console.log("WTON deployed:", wton);

        // 2. Deploy mock infrastructure (required by RAT)
        MockSeigManager mockSeig = new MockSeigManager(ton, wton);
        address seigManager = address(mockSeig);
        console.log("SeigManager (mock) deployed:", seigManager);

        MockLayer2Manager mockL2Manager = new MockLayer2Manager();
        address layer2Manager = address(mockL2Manager);
        console.log("Layer2Manager (mock) deployed:", layer2Manager);

        MockL1BridgeRegistry mockBridgeReg = new MockL1BridgeRegistry();
        address l1BridgeRegistry = address(mockBridgeReg);
        console.log("L1BridgeRegistry (mock) deployed:", l1BridgeRegistry);

        // 3. Deploy RAT with proxy
        address ratImpl = address(new RAT());
        console.log("RAT Implementation deployed:", ratImpl);

        address proxyAdmin = address(new ProxyAdmin());
        console.log("ProxyAdmin deployed:", proxyAdmin);

        // RAT initialization parameters
        // ratTriggerProbability = 100% for testing (always trigger)
        uint256 ratTriggerProbability = RAY; // 100%

        bytes memory initData = abi.encodeWithSelector(
            RAT.initialize.selector,
            seigManager,
            wton,
            ton,
            layer2Manager,
            DEPLOYER,  // owner
            ratTriggerProbability
        );

        address ratProxy = address(new RATProxy(ratImpl, proxyAdmin, initData));
        console.log("RAT Proxy deployed:", ratProxy);

        // 4. Configure RAT
        RAT rat = RAT(ratProxy);

        // Set RAT parameters (TON uses 18 decimals)
        rat.setSlashingPenalty(100 * 1e18);      // 100 TON (C_off)
        rat.setValidatorBuffer(100 * 1e18);       // 100 TON
        rat.setMinimumThreshold(200 * 1e18);      // 200 TON (D_min)
        rat.setEvidenceSubmissionPeriod(1 hours);
        rat.setL1BridgeRegistry(l1BridgeRegistry);
        rat.setTreasury(DEPLOYER);

        console.log("RAT configured");

        // 5. Mint tokens to test accounts
        // Mint TON (18 decimals)
        mockTon.mint(VALIDATOR, 10000 * 1e18);    // 10,000 TON
        mockTon.mint(DEPLOYER, 10000 * 1e18);
        mockTon.mint(PROPOSER, 10000 * 1e18);
        mockTon.mint(CHALLENGER, 10000 * 1e18);
        console.log("Minted 10,000 TON to each test account");

        // Mint WTON (27 decimals)
        mockWton.mint(VALIDATOR, 10000 * RAY);
        mockWton.mint(DEPLOYER, 10000 * RAY);
        mockWton.mint(PROPOSER, 10000 * RAY);
        mockWton.mint(CHALLENGER, 10000 * RAY);
        console.log("Minted 10,000 WTON to each test account");

        vm.stopBroadcast();

        // Output deployment summary
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("TON:", ton);
        console.log("WTON:", wton);
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT Implementation:", ratImpl);
        console.log("ProxyAdmin:", proxyAdmin);
        console.log("");
        console.log("Mock contracts (for RAT internal use):");
        console.log("  SeigManager:", seigManager);
        console.log("  Layer2Manager:", layer2Manager);
        console.log("  L1BridgeRegistry:", l1BridgeRegistry);
        console.log("");
        console.log("NOTE: RAT must be connected to DisputeGameFactory separately.");
        console.log("      The deploy-rat-devnet.sh script handles this automatically.");
    }
}
