// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITON {
    function approveAndCall(address spender, uint256 amount, bytes memory data) external returns (bool);
}