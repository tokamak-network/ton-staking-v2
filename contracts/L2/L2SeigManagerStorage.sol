// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import { L2RefactorCoinageSnapshotI } from "../stake/interfaces/L2RefactorCoinageSnapshotI.sol";

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
    mapping(address => mapping(address => uint256)) public lswton;

    uint256 public lastSnapshotId;
    address public l1StakedTonToL2;
    address public l2CrossDomainMessenger;

    mapping (address => bool) internal _l1layer2s;
    uint256 internal _numLayer2s;
    mapping (uint256 => address) internal _l1layer2ByIndex;

}
