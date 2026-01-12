// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract DepositManagerV1_1Storage {
    address public ton;
    uint32 public minDepositGasLimit; /// todo. delete
    address public l1BridgeRegistry;
    address public layer2Manager;

    bool internal _lock;

    modifier ifFree() {
        require(!_lock, 'lock');
        _lock = true;
        _;
        _lock = false;
    }

    /// @notice Percentage of slashed amount given to challenger as reward (100% = 10000)
    /// @dev Example 10% = 1000
    uint256 public slashingRewardRate;
}
