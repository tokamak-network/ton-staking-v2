// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../src/layer2/L1BridgeRegistryV1_2.sol";

/// @title L1BridgeRegistryV1_2Test
/// @notice L1BridgeRegistryV1_2의 DisputeGameFactory 기능 테스트

contract L1BridgeRegistryV1_2Test is Test {
    L1BridgeRegistryV1_2 public registry;

    address public factory1 = address(0x3001);
    address public rollupConfig1 = address(0x1001);

    function setUp() public {
        registry = new L1BridgeRegistryV1_2();
    }

    // ==========================================
    // View Functions Tests
    // ==========================================

    function test_disputeGameFactory_defaultFalse() public view {
        assertFalse(
            registry.disputeGameFactory(rollupConfig1),
            "Default factory should be false"
        );
    }

    function test_rollupConfigWithDisputeGameFactory_defaultZero() public view {
        assertEq(
            registry.rollupConfigWithDisputeGameFactory(factory1),
            address(0),
            "Default rollupConfig should be zero"
        );
    }
}
