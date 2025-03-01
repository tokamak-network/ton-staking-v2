// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IStandardBridge {
    function deposits(address, address) external view returns (uint256);
}