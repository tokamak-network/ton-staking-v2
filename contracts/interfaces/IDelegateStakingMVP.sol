// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IDelegateStakingMVP
 * @notice Interface for MVP delegate staking functionality
 * @dev MVP version using Sequencer Trust Model:
 *      - TON is stored in L1 contract (not bridged to L2)
 *      - Sequencer manually transfers WTON rewards
 *      - Uses MasterChef pattern for reward distribution
 */
interface IDelegateStakingMVP {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new sequencer is registered
    event SequencerRegistered(
        address indexed sequencer,
        address indexed layer2,
        uint256 commission
    );

    /// @notice Emitted when a sequencer is deregistered
    event SequencerDeregistered(address indexed sequencer);

    /// @notice Emitted when a sequencer updates their commission
    event CommissionUpdated(
        address indexed sequencer,
        uint256 oldCommission,
        uint256 newCommission
    );

    /// @notice Emitted when a user stakes TON
    event Staked(
        address indexed staker,
        address indexed sequencer,
        uint256 amount
    );

    /// @notice Emitted when a user requests unstaking
    event UnstakeRequested(
        address indexed staker,
        address indexed sequencer,
        uint256 amount,
        uint256 unlockTime
    );

    /// @notice Emitted when a user withdraws unstaked TON
    event Withdrawn(address indexed staker, uint256 amount);

    /// @notice Emitted when rewards are received from sequencer
    event RewardsReceived(
        address indexed sequencer,
        uint256 amount,
        uint256 commission,
        uint256 distributed
    );

    /// @notice Emitted when a user claims rewards
    event RewardsClaimed(
        address indexed staker,
        address indexed sequencer,
        uint256 amount
    );

    /// @notice Emitted when stake is redelegated
    event Redelegated(
        address indexed staker,
        address indexed fromSequencer,
        address indexed toSequencer,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();
    error SequencerNotRegistered();
    error SequencerAlreadyRegistered();
    error Layer2AlreadyRegistered();
    error UnstakingPeriodNotElapsed();
    error InvalidCommission();
    error Unauthorized();
    error NoUnstakeRequest();
    error NoPendingRewards();

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Information about a delegator's stake with a sequencer
    struct StakeInfo {
        uint256 amount;           // Staked TON amount
        uint256 rewardDebt;       // Reward debt for MasterChef calculation
        uint256 unstakeAmount;    // Amount pending unstake
        uint256 unstakeTime;      // Timestamp when unstake was requested
    }

    /// @notice Information about a registered sequencer
    struct SequencerInfo {
        bool isRegistered;          // Whether sequencer is active
        address layer2;             // Associated Layer2 address
        uint256 commission;         // Commission in basis points (100 = 1%)
        uint256 totalStaked;        // Total TON delegated to this sequencer
        uint256 accRewardPerShare;  // Accumulated rewards per share (scaled by 1e27)
        uint256 totalCommission;    // Total commission earned (claimable by sequencer)
    }

    /*//////////////////////////////////////////////////////////////
                         SEQUENCER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register as a sequencer
     * @param layer2 The Layer2 address this sequencer operates
     * @param commission Commission rate in basis points (max 3000 = 30%)
     */
    function registerSequencer(address layer2, uint256 commission) external;

    /**
     * @notice Deregister as a sequencer (only when no stakes)
     */
    function deregisterSequencer() external;

    /**
     * @notice Update commission rate
     * @param newCommission New commission in basis points
     */
    function updateCommission(uint256 newCommission) external;

    /**
     * @notice Receive WTON rewards and distribute to delegators
     * @dev Called by sequencer after claiming from OperatorManager
     * @param amount Amount of WTON to distribute
     */
    function receiveReward(uint256 amount) external;

    /**
     * @notice Claim accumulated commission
     */
    function claimCommission() external;

    /*//////////////////////////////////////////////////////////////
                          DELEGATOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stake TON and delegate to a sequencer
     * @param sequencer The sequencer address to delegate to
     * @param amount Amount of TON to stake
     */
    function stake(address sequencer, uint256 amount) external;

    /**
     * @notice Request to unstake TON from a sequencer
     * @param sequencer The sequencer to unstake from
     * @param amount Amount of TON to unstake
     */
    function unstake(address sequencer, uint256 amount) external;

    /**
     * @notice Withdraw unstaked TON after unbonding period
     * @param sequencer The sequencer to withdraw from
     */
    function withdraw(address sequencer) external;

    /**
     * @notice Claim accumulated WTON rewards
     * @param sequencer The sequencer to claim rewards from
     */
    function claimRewards(address sequencer) external;

    /**
     * @notice Redelegate stake from one sequencer to another
     * @param fromSequencer Current sequencer
     * @param toSequencer New sequencer
     * @param amount Amount to redelegate
     */
    function redelegate(
        address fromSequencer,
        address toSequencer,
        uint256 amount
    ) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get stake info for a delegator with a sequencer
     * @param staker The delegator address
     * @param sequencer The sequencer address
     * @return StakeInfo struct
     */
    function getStakeInfo(
        address staker,
        address sequencer
    ) external view returns (StakeInfo memory);

    /**
     * @notice Get sequencer information
     * @param sequencer The sequencer address
     * @return SequencerInfo struct
     */
    function getSequencerInfo(
        address sequencer
    ) external view returns (SequencerInfo memory);

    /**
     * @notice Get pending WTON rewards for a delegator
     * @param staker The delegator address
     * @param sequencer The sequencer address
     * @return Pending reward amount in WTON
     */
    function pendingRewards(
        address staker,
        address sequencer
    ) external view returns (uint256);

    /**
     * @notice Get sequencer by Layer2 address
     * @param layer2 The Layer2 address
     * @return sequencer The sequencer address (address(0) if not found)
     */
    function getSequencerByLayer2(
        address layer2
    ) external view returns (address sequencer);

    /**
     * @notice Get list of all registered sequencers
     * @return Array of sequencer addresses
     */
    function getSequencerList() external view returns (address[] memory);

    /**
     * @notice Get total staked amount across all sequencers
     * @return Total staked TON
     */
    function getTotalStaked() external view returns (uint256);
}
