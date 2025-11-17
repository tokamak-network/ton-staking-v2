// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IOperator {
    function isOperator(address addr) external view returns (bool);
}