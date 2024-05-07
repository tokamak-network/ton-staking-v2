//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AuthRoleLayer2Manager {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
}
