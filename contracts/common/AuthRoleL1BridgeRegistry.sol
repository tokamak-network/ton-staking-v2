//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AuthRoleL1BridgeRegistry {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant REGISTRANT_ROLE = keccak256("REGISTRANT");
}
