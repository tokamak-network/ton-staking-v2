// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { LibL2StakedInfo } from "../libraries/LibL2StakedInfo.sol";

/// @title
/// @notice
contract L2SeigManagerStorage   {

    //////////////////////////////
    // Constants
    //////////////////////////////
    uint256 constant public DEFAULT_FACTOR = 10 ** 27;

    // layer2 - index
    mapping(address => uint256) public index;
    mapping(address => uint256) public totalLswton;

    // address - layer2 - lswton
    mapping(address => mapping(address => LibL2StakedInfo.StakedInfo)) public stakedInfo;

    uint256 public lastSnapshotId;
    address public l1StakedTonInL2;
    address public l2CrossDomainMessenger;
    bool internal _lock;

    mapping (address => bool) internal _l1layer2s;
    address[] public l1layer2s;

    modifier ifFree {
        require(_lock != true, "in use");
        _lock = true;
        _;
        _lock = false;
    }
}
