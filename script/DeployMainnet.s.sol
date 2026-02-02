// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DelegateStakingV3Upgradeable} from "../contracts/DelegateStakingV3Upgradeable.sol";
import {DelegateTrigger} from "../contracts/DelegateTrigger.sol";

/**
 * @title DeployMainnet
 * @notice Deploys DelegateStakingV3Upgradeable and DelegateTrigger to mainnet
 * @dev Run with: forge script script/DeployMainnet.s.sol --rpc-url mainnet --broadcast --verify
 *
 * Required environment variables:
 * - PRIVATE_KEY: Deployer private key
 * - ETHERSCAN_API_KEY: For contract verification
 *
 * Optional environment variables:
 * - OWNER_ADDRESS: Owner address (defaults to deployer)
 * - SEIG_MANAGER: SeigManager V3 address (required)
 * - LAYER2_MANAGER: Layer2Manager address (required)
 */
contract DeployMainnetScript is Script {
    // Mainnet token addresses
    address constant TON_MAINNET = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON_MAINNET = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;

    // Deployed contracts
    DelegateStakingV3Upgradeable public implementation;
    ERC1967Proxy public proxy;
    DelegateStakingV3Upgradeable public staking;
    DelegateTrigger public trigger;

    function setUp() public {}

    function run() public {
        // Get deployer from private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get owner address (defaults to deployer)
        address owner = vm.envOr("OWNER_ADDRESS", deployer);

        // Get V3 contract addresses
        address seigManager = vm.envAddress("SEIG_MANAGER");
        address layer2Manager = vm.envAddress("LAYER2_MANAGER");

        // Validate addresses
        require(seigManager != address(0), "SEIG_MANAGER not set");
        require(layer2Manager != address(0), "LAYER2_MANAGER not set");

        console2.log("========== MAINNET DEPLOYMENT ==========");
        console2.log("Deployer:", deployer);
        console2.log("Owner:", owner);
        console2.log("TON:", TON_MAINNET);
        console2.log("WTON:", WTON_MAINNET);
        console2.log("SeigManager:", seigManager);
        console2.log("Layer2Manager:", layer2Manager);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Implementation
        console2.log("1. Deploying Implementation...");
        implementation = new DelegateStakingV3Upgradeable();
        console2.log("   Implementation:", address(implementation));

        // 2. Prepare initialization data
        uint256 unbondingPeriod = 7 days;
        bytes memory initData = abi.encodeCall(
            DelegateStakingV3Upgradeable.initialize,
            (TON_MAINNET, WTON_MAINNET, seigManager, layer2Manager, unbondingPeriod, owner)
        );

        // 3. Deploy Proxy
        console2.log("2. Deploying Proxy...");
        proxy = new ERC1967Proxy(address(implementation), initData);
        staking = DelegateStakingV3Upgradeable(address(proxy));
        console2.log("   Proxy:", address(proxy));

        // 4. Deploy DelegateTrigger
        console2.log("3. Deploying DelegateTrigger...");
        trigger = new DelegateTrigger(WTON_MAINNET, owner);
        console2.log("   DelegateTrigger:", address(trigger));

        vm.stopBroadcast();

        // Print summary
        _printSummary(owner, seigManager, layer2Manager);

        // Print verification commands
        _printVerificationCommands();
    }

    function _printSummary(address owner, address seigManager, address layer2Manager) internal view {
        console2.log("");
        console2.log("========== DEPLOYMENT SUMMARY ==========");
        console2.log("");
        console2.log("CONTRACTS:");
        console2.log("  Implementation:      ", address(implementation));
        console2.log("  Proxy (Staking):     ", address(proxy));
        console2.log("  DelegateTrigger:     ", address(trigger));
        console2.log("");
        console2.log("CONFIGURATION:");
        console2.log("  Owner:               ", owner);
        console2.log("  TON:                 ", TON_MAINNET);
        console2.log("  WTON:                ", WTON_MAINNET);
        console2.log("  SeigManager:         ", seigManager);
        console2.log("  Layer2Manager:       ", layer2Manager);
        console2.log("  Unbonding Period:    7 days");
        console2.log("  Version:             ", staking.version());
        console2.log("");
        console2.log("NEXT STEPS:");
        console2.log("1. Verify contracts on Etherscan");
        console2.log("2. Transfer ownership to multisig (if needed)");
        console2.log("3. Configure Chainlink Keepers for DelegateTrigger");
        console2.log("=========================================");
    }

    function _printVerificationCommands() internal view {
        console2.log("");
        console2.log("========== VERIFICATION COMMANDS ==========");
        console2.log("");
        console2.log("# Verify Implementation");
        console2.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(implementation)),
                " contracts/DelegateStakingV3Upgradeable.sol:DelegateStakingV3Upgradeable --chain mainnet"
            )
        );
        console2.log("");
        console2.log("# Verify Proxy");
        console2.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(proxy)),
                " @openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy --chain mainnet"
            )
        );
        console2.log("");
        console2.log("# Verify Trigger");
        console2.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(trigger)),
                " contracts/DelegateTrigger.sol:DelegateTrigger --chain mainnet"
            )
        );
        console2.log("============================================");
    }
}

/**
 * @title DeploySepolia
 * @notice Deploys contracts to Sepolia testnet
 * @dev Run with: forge script script/DeployMainnet.s.sol:DeploySepoliaScript --rpc-url sepolia --broadcast --verify
 */
contract DeploySepoliaScript is Script {
    // Sepolia test token addresses (deploy your own or use existing)
    address public tonSepolia;
    address public wtonSepolia;

    // Deployed contracts
    DelegateStakingV3Upgradeable public implementation;
    ERC1967Proxy public proxy;
    DelegateStakingV3Upgradeable public staking;
    DelegateTrigger public trigger;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address owner = vm.envOr("OWNER_ADDRESS", deployer);

        // Get test token addresses from env (must be deployed separately)
        tonSepolia = vm.envAddress("TON_SEPOLIA");
        wtonSepolia = vm.envAddress("WTON_SEPOLIA");

        // SeigManager and Layer2Manager can be mock or real addresses
        address seigManager = vm.envOr("SEIG_MANAGER", address(0));
        address layer2Manager = vm.envOr("LAYER2_MANAGER", address(0));

        console2.log("========== SEPOLIA DEPLOYMENT ==========");
        console2.log("Deployer:", deployer);
        console2.log("Owner:", owner);
        console2.log("TON:", tonSepolia);
        console2.log("WTON:", wtonSepolia);
        console2.log("SeigManager:", seigManager);
        console2.log("Layer2Manager:", layer2Manager);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Implementation
        implementation = new DelegateStakingV3Upgradeable();
        console2.log("Implementation:", address(implementation));

        // 2. Deploy Proxy
        uint256 unbondingPeriod = 1 days; // Shorter for testnet
        bytes memory initData = abi.encodeCall(
            DelegateStakingV3Upgradeable.initialize,
            (tonSepolia, wtonSepolia, seigManager, layer2Manager, unbondingPeriod, owner)
        );

        proxy = new ERC1967Proxy(address(implementation), initData);
        staking = DelegateStakingV3Upgradeable(address(proxy));
        console2.log("Proxy:", address(proxy));

        // 3. Deploy DelegateTrigger
        trigger = new DelegateTrigger(wtonSepolia, owner);
        console2.log("DelegateTrigger:", address(trigger));

        vm.stopBroadcast();

        console2.log("");
        console2.log("========== SEPOLIA DEPLOYMENT COMPLETE ==========");
        console2.log("Proxy (Staking): ", address(proxy));
        console2.log("DelegateTrigger: ", address(trigger));
        console2.log("Version:         ", staking.version());
    }
}

/**
 * @title UpgradeMainnet
 * @notice Upgrades DelegateStakingV3Upgradeable on mainnet
 * @dev Run with: forge script script/DeployMainnet.s.sol:UpgradeMainnetScript --rpc-url mainnet --broadcast
 */
contract UpgradeMainnetScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get existing proxy address
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        require(proxyAddress != address(0), "PROXY_ADDRESS not set");

        console2.log("========== MAINNET UPGRADE ==========");
        console2.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new implementation
        DelegateStakingV3Upgradeable newImplementation = new DelegateStakingV3Upgradeable();
        console2.log("New Implementation:", address(newImplementation));

        // 2. Upgrade proxy
        DelegateStakingV3Upgradeable stakingProxy = DelegateStakingV3Upgradeable(proxyAddress);
        stakingProxy.upgradeToAndCall(address(newImplementation), "");

        console2.log("Upgrade complete!");
        console2.log("New Version:", stakingProxy.version());

        vm.stopBroadcast();
    }
}
