// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IOperator {
    function isOperator(address addr) external view returns (bool);
    function checkL1Bridge() external view returns (
        bool result,
        address l1Bridge,
        address portal,
        address l2Ton,
        uint8 _type,
        uint8 status,
        bool rejectedSeigs,
        bool rejectedL2Deposit
    );
}