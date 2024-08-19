// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract OperatorStorage {
    address public rollupConfig;
    address public layer2Manager;
    address public depositManager;
    address public ton;
    address public wton;

    address public manager;
    string public explorer;

    modifier onlyManager() {
        require(msg.sender == manager, "not manager");
        _;
    }

    modifier nonZeroAddress(address addr) {
        require(addr != address(0), "zero address");
        _;
    }
}