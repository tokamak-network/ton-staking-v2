// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract FakeSeigManager {
    function coinages(address layer2) external view returns (address) {
        return address(this);
    }
    function totalSupply() external pure returns (uint256) {
        return type(uint256).max;
    }
}