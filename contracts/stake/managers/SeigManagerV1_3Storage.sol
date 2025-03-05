// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract SeigManagerV1_3Storage  {

    struct Layer2Tvl {
        uint256 l2UpdateBlockIndexes; // l2UpdateBlock's index
        uint256 layer2Tvl;
    }

    struct Layer2Reward {
        uint256 layer2Tvl;
        uint256 startBlock;
        uint256 claimedLastIndex;
        uint256 claimedBlockNumber;
        uint256 claimedReward;
    }

    struct Layer2PauseBlock {
        uint256 pauseIndex; // pause l2UpdateBlock index, 포함 인덱스부터 발급안함
        uint256 unpauseIndex; // unpause l2UpdateBlock index, 포함 인덱스까지 발급안함
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

    /// When claiming L2 seigniorage, only maxCommitCountForClaim can be claimed at a time.
    uint256 public maxCommitCountForClaim;

    // L2 update seigniorage commit block
    uint256[] public l2UpdateBlock; // index 0 - unused, it's a dummy

    /// layer2 reward information for each layer2(candidate).
    mapping (address => Layer2Reward) public layer2RewardInfo;

    // Calculate seigniorage per liquidity for L2 update seigniorage commit block.
    mapping (uint256 => uint256) public l2RewardAtBlock;

    // layer2 - Index array of l2UpdateBlock
    mapping (address => uint256[]) public layer2L2UpdateBlockIndexes;

    // layer2 - commit block number - commitLayer2Tvl
    mapping (address => mapping (uint256 => uint256)) public commitLayer2Tvl;

    // layer2 - pause block index
    mapping (address => uint256[]) public layer2PauseBlockIndex;


    //layer2 - pause block index - unpause block index
    mapping (address => mapping (uint256 => uint256)) public layer2UnpauseBlockIndex;


    bool internal _lock;

    modifier ifFree {
        require(!_lock, "lock");
        _lock = true;
        _;
        _lock = false;
    }
}
