// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Mock SystemConfig for testing
contract MockSystemConfig {
    address public l1StandardBridge;
    address public optimismPortal;
    address public disputeGameFactory;

    function setL1StandardBridge(address _l1StandardBridge) external {
        l1StandardBridge = _l1StandardBridge;
    }

    function setOptimismPortal(address _optimismPortal) external {
        optimismPortal = _optimismPortal;
    }

    function setDisputeGameFactory(address _disputeGameFactory) external {
        disputeGameFactory = _disputeGameFactory;
    }
}
