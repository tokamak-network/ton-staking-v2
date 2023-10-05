// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract AutoRefactorCoinageStorage   {

    struct Balance {
        uint256 balance;
        uint256 refactoredCount;
        uint256 remain;
    }

    uint256 public constant REFACTOR_BOUNDARY = 10 ** 28;
    uint256 public constant REFACTOR_DIVIDER = 2;

    uint256 public refactorCount;

    mapping (address => Balance) public balances;

    Balance public _totalSupply;

    uint256 public _factor;

    bool internal _transfersEnabled;

    //=== ERC20
    string public name;
    string public symbol;

    mapping(address => mapping(address => uint256)) public _allowances;

}
