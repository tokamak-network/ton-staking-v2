// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDepositManager {
    function deposit(address layer2, uint256 amount) external returns (bool);
    function deposit(address layer2, address to, uint256 amount) external returns (bool);
    function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
    function processRequest(address layer2, bool receiveTON) external returns (bool);
    function processRequests(address layer2, uint256 n, bool receiveTON) external returns (bool);
}