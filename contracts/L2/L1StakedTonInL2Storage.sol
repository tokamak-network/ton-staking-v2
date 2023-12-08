// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract L1StakedTonInL2Storage  {
    address public _manager;
    address public l2SeigManager;
    address public l2CrossDomainMessenger;
    address public l1Register;

    modifier onlyManager() {
        require(_manager == msg.sender, "not manager");
        _;
    }

}