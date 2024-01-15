// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../libraries/LibDividend.sol";

/**
 * @title L2DividendPoolForTonStorage
 * @dev
 */
contract L2DividendPoolForTonStorage {

    address public l2SeigManager;

    // token - Distribution
    mapping(address => LibDividend.Distribution) public distributions;

    // token - snapshot id - distributed amount
    mapping (address => mapping(uint256 => uint256)) tokensPerSnapshotId;

    // token - account - snapshot id
    mapping (address => mapping (address => uint256)) claimStartSnapshotId;

    // token - snapshotIds
    mapping (address => uint256[]) public snapshotIds;

    // tokens
    address[] public distributedTokens;
    bool internal free;
}