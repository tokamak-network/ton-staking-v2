// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITON {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approveAndCall(address spender, uint256 amount, bytes memory data) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

}