// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestSetDealy {

    constructor () {}

    function setWithdrawalDelay(address _address,uint256 _time) external pure {
        require(_address == address(0) && _time == 0, "not use function");
    }
}