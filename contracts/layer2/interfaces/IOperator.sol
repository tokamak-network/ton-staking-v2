// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IOperator {
    function isOperator(address addr) external view returns (bool);
    function checkL1Bridge() external view returns (bool,address,address,address,uint8,uint8,bool,bool);
}