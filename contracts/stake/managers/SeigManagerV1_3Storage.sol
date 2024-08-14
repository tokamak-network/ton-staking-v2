// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract SeigManagerV1_3Storage  {

    struct Layer2Reward {
        uint256 layer2Tvl;
        uint256 initialDebt;
    }

    /// L1BridgeRegistry address
    address public l1BridgeRegistry;
    /// Layer2Manager address
    address public layer2Manager;

    /// layer2 seigs start block
    uint256 public layer2StartBlock;

    uint256 public l2RewardPerUint;  // ray unit .1e27

    /// total layer2 TON TVL
    uint256 public totalLayer2TVL;

    /// layer2 reward information for each layer2.
    mapping (address => Layer2Reward) public layer2RewardInfo;

    bool internal _lock;

    modifier ifFree {
        require(!_lock, "lock");
        _lock = true;
        _;
        _lock = false;
    }
}
