// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import  "../libraries/LibRefactorSync.sol";

/// @title
/// @notice
contract L1StakedTonToL2Storage   {

    address public _manager;
    address public addressManager;
    address public seigManger;
    address public l2SeigManager;
    uint32 minGasLimit;
    bool internal _lock;

    // address - layer2 -  sync된 정보 (히스토리의 인덱스 번호, time)
    mapping(address => mapping(address => LibRefactorSync.CoinageSyncInfo)) public syncInfo;

    LibRefactorSync.FactorSyncInfo[] public totFactors;

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
