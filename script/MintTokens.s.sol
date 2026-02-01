// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";

/**
 * @title MintTokens
 * @notice Mints mock tokens to specified addresses for testing
 * @dev Run with: forge script script/MintTokens.s.sol --rpc-url local --broadcast
 *
 * Environment variables:
 *   MINT_TO: Address to mint to (default: deployer)
 *   MINT_AMOUNT: Amount in TON units (default: 100000)
 *   TON_ADDRESS: TON mock contract address
 *   WTON_ADDRESS: WTON mock contract address
 */
contract MintTokensScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        address tonAddress = vm.envAddress("TON_ADDRESS");
        address wtonAddress = vm.envAddress("WTON_ADDRESS");
        address mintTo = vm.envOr("MINT_TO", vm.addr(deployerPrivateKey));
        uint256 mintAmount = vm.envOr("MINT_AMOUNT", uint256(100_000)) * 1e18;

        console2.log("Minting to:", mintTo);
        console2.log("Amount (TON):", mintAmount / 1e18);

        vm.startBroadcast(deployerPrivateKey);

        ERC20Mock ton = ERC20Mock(tonAddress);
        ERC20Mock wton = ERC20Mock(wtonAddress);

        ton.mint(mintTo, mintAmount);
        wton.mint(mintTo, mintAmount * 1e9); // WTON has 27 decimals

        console2.log("TON balance:", ton.balanceOf(mintTo) / 1e18);
        console2.log("WTON balance:", wton.balanceOf(mintTo) / 1e27);

        vm.stopBroadcast();
    }
}
