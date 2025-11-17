//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AuthRole {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant REGISTRANT_ROLE = keccak256("REGISTRANT");
    bytes32 public constant CHALLENGER_ROLE = keccak256("CHALLENGER");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE");
}
