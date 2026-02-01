// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {DelegateStakingMVP} from "../contracts/DelegateStakingMVP.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        address tonToken = vm.envAddress("TON_TOKEN_ADDRESS");
        address wtonToken = vm.envAddress("WTON_TOKEN_ADDRESS");
        uint256 unbondingPeriod = vm.envOr("UNBONDING_PERIOD", uint256(14 days));
        address owner = vm.envOr("OWNER_ADDRESS", msg.sender);

        vm.startBroadcast();

        DelegateStakingMVP staking = new DelegateStakingMVP(
            tonToken,
            wtonToken,
            unbondingPeriod,
            owner
        );

        console2.log("DelegateStakingMVP deployed at:", address(staking));
        console2.log("TON token:", tonToken);
        console2.log("WTON token:", wtonToken);
        console2.log("Unbonding period:", unbondingPeriod);
        console2.log("Owner:", owner);

        vm.stopBroadcast();
    }
}
