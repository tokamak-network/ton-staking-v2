// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import { RefactorCoinageSnapshotI } from "../stake/interfaces/RefactorCoinageSnapshotI.sol";

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

    address public _registry;

    // contract factory
    address public factory;

    // track total deposits of each layer2.
    RefactorCoinageSnapshotI internal _tot;

    // coinage token for each layer2.
    mapping (address => RefactorCoinageSnapshotI) internal _coinages;

    uint256 public lastSnapshotId;

}
