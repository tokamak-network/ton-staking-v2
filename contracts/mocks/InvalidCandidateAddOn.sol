// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SeigManagerV1_3} from '../stake/managers/SeigManagerV1_3.sol';

contract InvalidCandidateAddOn {
    address public operator1;
    address public operator2;
    address public seigManager;
    address public layer2Registry;
    bool public constant isLayer2 = true;
    uint256 public constant currentFork = 1;

    address public candidate;
    string public memo;
    address public committee;

    constructor(address _operator1, address _layer2Resitry, address _seigManager) {
        operator1 = _operator1;
        operator2 = msg.sender;
        layer2Registry = _layer2Resitry;
        seigManager = _seigManager;

        committee = _layer2Resitry;
        candidate = _operator1;

    }

    function operator() external view returns (address) {
        if (msg.sender == layer2Registry) return operator2;
        return operator1;
    }

    function updateSeigniorage() external {
        SeigManagerV1_3(seigManager).updateSeigniorage();
    }

     /// @notice Checks whether this contract is a candidate contract
    /// @return Whether or not this contract is a candidate contract
    function isCandidateContract() external pure returns (bool) {
        return true;
    }

    function isCandidateFwContract() external pure returns (bool) {
        return true;
    }

    function lastEpoch(uint256 forkNumber) external pure returns (uint256) { return 1; }


}
