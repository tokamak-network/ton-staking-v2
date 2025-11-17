// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOperatorManagerFactory {
    function createOperatorManager(address _rollupConfig) external returns (address);
}