// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract DepositManagerV1_1Storage {
    address public ton;
    uint32 public minDepositGasLimit; /// todo. delete
    address public l1BridgeRegistry;
    address public layer2Manager;
    
    /// @notice Percentage of slashed amount given to challenger as reward (in RAY, 1e27 = 100%)
    /// @dev Default 10% = 0.1e27 = 100000000000000000000000000
    uint256 public slashingRewardRate;

    bool internal _lock;

    modifier ifFree {
        require(!_lock, "lock");
        _lock = true;
        _;
        _lock = false;
    }
}
