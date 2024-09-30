// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract L1BridgeRegistryStorage   {

    struct ROLLUP_INFO {
        uint8   rollupType;  ///  type (0:empty, 1: optimism legacy, 2: optimism bedrock native TON)
        address l2TON;
        bool    rejectedSeigs;
        bool    rejectedL2Deposit;
        string  name;
    }

    address public layer2Manager;
    address public seigManager;
    address public ton;
    address public seigniorageCommittee;

    mapping (address => ROLLUP_INFO) public rollupInfo;

    /// For registered bridges, set to true.
    mapping (address => bool) public l1Bridge;

    /// For registered portals, set to true.
    mapping (address => bool) public portal;

    //  bytes32(bytes(name))
    mapping (bytes32 => bool) public registeredNames;
}