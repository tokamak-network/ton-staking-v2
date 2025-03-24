// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface ISeigManager {
    function updateSeigniorage() external returns (bool);
}

contract MockLayer2 is Ownable {

    address public operator;
    address public seigManager;
    bool public isLayer2 = true;
    uint256 public currentFork = 1;

    constructor(address _seigManager) {
        operator = msg.sender;
        seigManager = _seigManager;
    }

    receive() external payable {
        revert("cannot receive Ether");
    }

    function lastEpoch(uint256 forkNumber) external view returns (uint256) {
        return currentFork;
    }

    function changeOperator(address _operator) external {
        revert("changeOperator not implemented yet");
    }

    function updateSeigniorage() external returns (bool) {
        return ISeigManager(seigManager).updateSeigniorage();
        // return true;
    }

}
