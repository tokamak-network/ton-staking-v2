// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ILayer2 } from "../dao/interfaces/ILayer2.sol";

contract MockLayer2 is ILayer2 {
    address public operatorAddr;

    constructor(address _operator) {
        operatorAddr = _operator;
    }

    function operator() external view override returns (address) {
        return operatorAddr;
    }

    function isLayer2() external view override returns (bool) {
        return true;
    }

    function currentFork() external view override returns (uint256) {
        return 0;
    }

    function lastEpoch(uint256 forkNumber) external view override returns (uint256) {
        return 0;
    }

    function changeOperator(address _operator) external override {
        operatorAddr = _operator;
    }
}
