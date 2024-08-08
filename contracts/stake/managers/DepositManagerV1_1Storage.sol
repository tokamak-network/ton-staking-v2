// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract DepositManagerV1_1Storage {
    address public ton;
    uint32 public minDepositGasLimit; /// todo. delete

    bool internal _lock;

    modifier ifFree {
        require(!_lock, "lock");
        _lock = true;
        _;
        _lock = false;
    }
}
