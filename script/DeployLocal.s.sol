// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {DelegateStakingMVP} from "../contracts/DelegateStakingMVP.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";

/**
 * @title DeployLocal
 * @notice Deploys DelegateStakingMVP with mock tokens for local testing
 * @dev Run with: forge script script/DeployLocal.s.sol --rpc-url local --broadcast
 */
contract DeployLocalScript is Script {
    function setUp() public {}

    function run() public {
        // Use Anvil's default account #0
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer:", deployer);
        console2.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Mock TON (18 decimals)
        ERC20Mock ton = new ERC20Mock("Tokamak Network", "TON");
        console2.log("TON Mock deployed at:", address(ton));

        // Deploy Mock WTON (27 decimals - same contract, different usage)
        ERC20Mock wton = new ERC20Mock("Wrapped TON", "WTON");
        console2.log("WTON Mock deployed at:", address(wton));

        // Deploy DelegateStakingMVP
        uint256 unbondingPeriod = 7 days;
        DelegateStakingMVP staking = new DelegateStakingMVP(
            address(ton),
            address(wton),
            unbondingPeriod,
            deployer
        );
        console2.log("DelegateStakingMVP deployed at:", address(staking));

        // Mint some tokens to deployer for testing
        uint256 mintAmount = 1_000_000 ether; // 1M tokens
        ton.mint(deployer, mintAmount);
        wton.mint(deployer, mintAmount * 1e9); // WTON has 27 decimals (18 + 9)
        console2.log("Minted", mintAmount / 1e18, "TON to deployer");
        console2.log("Minted", mintAmount / 1e18, "WTON (in TON equivalent) to deployer");

        vm.stopBroadcast();

        // Print summary for UI configuration
        console2.log("\n========== DEPLOYMENT SUMMARY ==========");
        console2.log("Network: localhost (Anvil)");
        console2.log("Chain ID: 31337");
        console2.log("");
        console2.log("Contract Addresses:");
        console2.log("  TON:                  ", address(ton));
        console2.log("  WTON:                 ", address(wton));
        console2.log("  DelegateStakingMVP:   ", address(staking));
        console2.log("");
        console2.log("Deployer Account:");
        console2.log("  Address:              ", deployer);
        console2.log("  TON Balance:          ", ton.balanceOf(deployer) / 1e18);
        console2.log("==========================================\n");
    }
}
