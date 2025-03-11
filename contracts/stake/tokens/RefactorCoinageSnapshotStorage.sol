// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import { IRefactor } from "../interfaces/IRefactor.sol";

/// @title
/// @notice
contract RefactorCoinageSnapshotStorage   {

    uint256 public constant REFACTOR_BOUNDARY = 10 ** 28;
    uint256 public constant REFACTOR_DIVIDER = 2;

    address public seigManager;

    //=== ERC20
    string public name;
    string public symbol;

    mapping(address => mapping(address => uint256)) public _allowances;

    //---------------
    uint256[] public totalSupplySnapshotIds;
    mapping (uint256 => IRefactor.Balance) public totalSupplySnapshots;

    uint256[] public factorSnapshotIds;
    mapping (uint256 => IRefactor.Factor) public factorSnapshots;

    mapping (address => uint256[]) public accountBalanceIds;
    mapping (address => mapping (uint256 => IRefactor.Balance)) public accountBalanceSnapshots;

    uint256 public lastSnapshotId;
}
