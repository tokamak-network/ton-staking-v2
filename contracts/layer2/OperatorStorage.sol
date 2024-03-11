// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract OperatorStorage {
    address public systemConfig;

    address public manager;
    mapping(address => bool) public operator;

    modifier onlyManager() {
        require(msg.sender == manager, "not manager");
        _;
    }

    modifier onlyOperator() {
        require(operator[msg.sender], "not operator");
        _;
    }

    modifier nonZeroAddress(address addr) {
        require(addr != address(0), "zero address");
        _;
    }
}