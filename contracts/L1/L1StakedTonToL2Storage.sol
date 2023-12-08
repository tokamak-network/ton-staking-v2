// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import  "../libraries/LibRefactorSync.sol";

/// @title
/// @notice
contract L1StakedTonToL2Storage   {

    address public _manager;
    address public addressManager;
    address public seigManger;
    address public registry;
    address public tot;

    address public l2SeigManager;
    uint32 public minGasLimit;
    bool internal _lock;

    // layer2 - coinage
    mapping(address => address) public coinages;

    // address - layer2 -  sync된 정보 (히스토리의 인덱스 번호, time)
    mapping(address => mapping(address => LibRefactorSync.RefactorCoinage)) public coinageSyncInfo;
    // address - sync time
    mapping(address => uint32) public accountSyncTime;

    // tot sync time
    uint32 public totSyncTime;

    // tot factor
    IRefactor.Factor[] public totFactors;

    modifier onlyManager() {
        require(_manager == msg.sender, "not manager");
        _;
    }

    modifier ifFree {
        require(_lock != true, "in use");
        _lock = true;
        _;
        _lock = false;
    }
}
