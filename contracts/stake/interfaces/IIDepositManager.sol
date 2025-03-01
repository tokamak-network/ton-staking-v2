// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IIDepositManager {
    function deposit(address layer2, address account, uint256 amount) external returns (bool);
}