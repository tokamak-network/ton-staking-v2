// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple Mock SystemConfig for testing (lightweight version)
contract SimpleMockSystemConfig {
    address public l1StandardBridge;
    address public optimismPortal;
    address public disputeGameFactory;
    address public unsafeBlockSigner;

    function setL1StandardBridge(address _l1StandardBridge) external {
        l1StandardBridge = _l1StandardBridge;
    }

    function setOptimismPortal(address _optimismPortal) external {
        optimismPortal = _optimismPortal;
    }

    function setDisputeGameFactory(address _disputeGameFactory) external {
        disputeGameFactory = _disputeGameFactory;
    }

    function setUnsafeBlockSigner(address _unsafeBlockSigner) external {
        unsafeBlockSigner = _unsafeBlockSigner;
    }
}
