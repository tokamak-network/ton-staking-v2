// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract L2RegistryStorage   {

    uint256 totalTvlL2;

    /// systemConfig - tvl in L2
    mapping (address => uint256) public tvlL2;

    /// systemConfig - type (0:empty, 1: optimism legacy, 2: optimism bedrock )
    mapping (address => uint8) public systemConfigType;

    mapping (address => bool) public l1Bridge;
    mapping (address => bool) public portal;
}