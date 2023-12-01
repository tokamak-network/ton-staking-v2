// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import { L2RefactorCoinageSnapshotI } from "../stake/interfaces/L2RefactorCoinageSnapshotI.sol";

/// @title
/// @notice
contract L2SeigManagerStorage   {

    //////////////////////////////
    // Constants
    //////////////////////////////

    uint256 constant public RAY = 10 ** 27; // 1 RAY
    uint256 constant public _DEFAULT_FACTOR = RAY;

    uint256 constant public MAX_VALID_COMMISSION = RAY; // 1 RAY
    uint256 constant public MIN_VALID_COMMISSION = 10 ** 25; // 0.01 RAY


    // coinage factory
    address public factory;

    // track total deposits of each layer2.
    L2RefactorCoinageSnapshotI internal _tot;

    // coinage token for each layer2.
    mapping (address => L2RefactorCoinageSnapshotI) internal _coinages;

    uint256 public lastSnapshotId;

    address public l1StakedTonInL2;

    mapping (address => bool) internal _l1layer2s;
    uint256 internal _numLayer2s;
    mapping (uint256 => address) internal _l1layer2ByIndex;

}
