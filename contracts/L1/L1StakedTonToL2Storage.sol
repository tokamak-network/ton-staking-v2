// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";

/// @title
/// @notice
contract L1StakedTonToL2Storage   {

    address public manager;
    address public addressManager;
    address public seigManager;
    address public registry;

    address public l1StakedTonInL2;
    uint32 public minGasLimit;
    uint32 public minGasLimit2;
    bool internal _lock;

    mapping(address => mapping(address => uint256)) public lastRegisterTime;


    modifier onlyManager() {
        require(manager == msg.sender, "not manager");
        _;
    }

    modifier ifFree {
        require(_lock != true, "in use");
        _lock = true;
        _;
        _lock = false;
    }
}
