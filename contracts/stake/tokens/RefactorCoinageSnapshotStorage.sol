// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract RefactorCoinageSnapshotStorage   {

    struct Balance {
        uint256 balance;
        uint256 refactoredCount;
    }

    struct Factor {
        uint256 factor;
        uint256 refactorCount;
    }

    uint256 public constant REFACTOR_BOUNDARY = 10 ** 28;
    uint256 public constant REFACTOR_DIVIDER = 2;

    address public seigManager;

    //=== ERC20
    string public name;
    string public symbol;

    mapping(address => mapping(address => uint256)) public _allowances;

    //---------------
    uint256[] public totalSupplySnapshotIds;
    mapping (uint256 => Balance) public totalSupplySnapshots;

    uint256[] public factorSnapshotIds;
    mapping (uint256 => Factor) public factorSnapshots;

    mapping (address => uint256[]) public accountBalanceIds;
    mapping (address => mapping (uint256 => Balance)) public accountBalanceSnapshots;

    uint256 public lastSnapshotId;
}
