// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract L1BridgeRegistryStorage   {

    address public layer2Manager;
    address public seigManager;
    address public ton;

    /// rollupConfig - type (0:empty, 1: optimism legacy, 2: optimism bedrock native TON)
    mapping (address => uint8) public rollupType;

    /// For registered bridges, set to true.
    mapping (address => bool) public l1Bridge;

    /// For registered portals, set to true.
    mapping (address => bool) public portal;

    /// Set the layer where seigniorage issuance has been suspended to true.
    mapping (address => bool) public rejectRollupConfig;

    address public seigniorageCommittee;
}