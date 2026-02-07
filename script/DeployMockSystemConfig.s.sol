// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract MockSystemConfig {
    address public unsafeBlockSigner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public batcherHash = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint64 public gasLimit = 30000000;
    uint256 public overhead = 2100;
    uint256 public scalar = 1000000;
}

contract DeployMockSystemConfig is Script {
    function run() external {
        uint256 deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerKey);
        MockSystemConfig config = new MockSystemConfig();
        console.log("MockSystemConfig deployed at:", address(config));
        vm.stopBroadcast();
    }
}
