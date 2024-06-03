// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract L2RegistryV1_1Storage   {

    mapping (address => bool) public rejectSystemConfig;
    address public seigniorageCommittee;
}