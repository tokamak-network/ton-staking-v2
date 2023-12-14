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
    uint256 public lastSnapshotId;
    address public l1StakedTonInL2;
    address public l2CrossDomainMessenger;
    bool internal _lock;

    // layer2 - snapshotIds
    mapping(address => uint256[]) public layerIndexSnapshotIds;

    // layer2 - snapshotId - index
    mapping(address => mapping(uint256 => uint256)) public index;


    // layer2 - snapshotIds
    mapping(address => uint256[]) public layerTlswtonSnapshotIds;

    // layer2 - snapshotId - totalLswton
    mapping(address => mapping(uint256 => uint256)) public totalLswton;

    // layer2 - address - snapshotIds
    mapping(address => mapping(address => uint256[])) public stakedInfoSnapshotIds;

    // layer2 - address - snapshotId-  stakedInfo
    mapping(address => mapping(address => mapping(uint256 => LibL2StakedInfo.StakedInfo))) public stakedInfo;

    mapping (address => bool) internal _l1layer2s;
    address[] public l1layer2s;

    modifier ifFree {
        require(_lock != true, "in use");
        _lock = true;
        _;
        _lock = false;
    }
}
