// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestLayer2 {

    bool public constant isLayer2 = true;
    address public operator;

    constructor () {}

    function setOperator() external {
        operator = msg.sender;
    }
}