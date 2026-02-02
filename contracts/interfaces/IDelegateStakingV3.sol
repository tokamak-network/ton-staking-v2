// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IDelegateStakingV3
 * @notice Interface for V3-integrated delegate staking contract
 * @dev Integrates with Tokamak Network V3 SeigManager and OperatorManager
 */
interface IDelegateStakingV3 {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Information about a registered sequencer
    struct SequencerInfo {
        bool isRegistered;
        address layer2; // L2 contract address (SystemConfig or Layer2 address)
        address operatorManager; // OperatorManager contract for this L2
        uint256 commission; // Commission in basis points (10000 = 100%)
        uint256 totalStaked; // Total TON staked to this sequencer
        uint256 accRewardPerShare; // Accumulated rewards per share (RAY precision)
        uint256 totalCommission; // Accumulated commission for sequencer
        bool autoTriggerEnabled; // Whether auto seigniorage trigger is enabled
    }

    /// @notice Information about a staker's position
    struct StakeInfo {
        uint256 amount; // Staked TON amount
        uint256 rewardDebt; // Reward debt for MasterChef calculation
        uint256 unstakeAmount; // Amount pending unstake
        uint256 unstakeTime; // Timestamp of unstake request
    }

    /// @notice Emergency exit configuration
    struct EmergencyConfig {
        bool isActive; // Whether emergency mode is active
        uint256 activationTime; // When emergency was activated
        uint256 cooldownPeriod; // Time before emergency withdrawals allowed
        address guardian; // Address that can activate emergency
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SequencerRegistered(
        address indexed sequencer,
        address indexed layer2,
        address indexed operatorManager,
        uint256 commission
    );
    event SequencerDeregistered(address indexed sequencer);
    event CommissionUpdated(address indexed sequencer, uint256 oldCommission, uint256 newCommission);
    event AutoTriggerToggled(address indexed sequencer, bool enabled);

    event Staked(address indexed staker, address indexed sequencer, uint256 amount);
    event UnstakeRequested(address indexed staker, address indexed sequencer, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed staker, uint256 amount);
    event Redelegated(address indexed staker, address indexed fromSequencer, address indexed toSequencer, uint256 amount);

    event RewardsReceived(address indexed sequencer, uint256 totalAmount, uint256 commission, uint256 distributed);
    event RewardsClaimed(address indexed staker, address indexed sequencer, uint256 amount);
    event CommissionClaimed(address indexed sequencer, uint256 amount);

    event SeigniorageTriggered(address indexed sequencer, uint256 amount, address indexed triggeredBy);

    event EmergencyActivated(address indexed layer2, address indexed activatedBy, uint256 activationTime);
    event EmergencyDeactivated(address indexed layer2, address indexed deactivatedBy);
    event EmergencyWithdrawn(address indexed staker, address indexed sequencer, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error ZeroAmount();
    error InvalidCommission();
    error SequencerAlreadyRegistered();
    error SequencerNotRegistered();
    error Layer2AlreadyRegistered();
    error InsufficientBalance();
    error NoUnstakeRequest();
    error UnstakingPeriodNotElapsed();
    error NoPendingRewards();
    error Unauthorized();
    error InvalidOperatorManager();
    error Layer2NotEligible();
    error EmergencyNotActive();
    error EmergencyAlreadyActive();
    error EmergencyCooldownNotElapsed();
    error NotGuardian();
    error AutoTriggerDisabled();

    /*//////////////////////////////////////////////////////////////
                         SEQUENCER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register as a sequencer with V3 integration
     * @param layer2 The Layer2 contract address
     * @param operatorManager The OperatorManager contract address for this L2
     * @param commission Commission rate in basis points (max 3000 = 30%)
     */
    function registerSequencer(address layer2, address operatorManager, uint256 commission) external;

    /**
     * @notice Deregister as a sequencer (requires zero staked balance)
     */
    function deregisterSequencer() external;

    /**
     * @notice Update commission rate
     * @param newCommission New commission rate in basis points
     */
    function updateCommission(uint256 newCommission) external;

    /**
     * @notice Toggle auto trigger for seigniorage distribution
     * @param enabled Whether to enable auto trigger
     */
    function setAutoTrigger(bool enabled) external;

    /**
     * @notice Manually receive and distribute rewards (called by sequencer)
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
     * @notice Stake TON to a sequencer
     * @param sequencer The sequencer address
     * @param amount Amount of TON to stake
     */
    function stake(address sequencer, uint256 amount) external;

    /**
     * @notice Request unstake (starts unbonding period)
     * @param sequencer The sequencer address
     * @param amount Amount of TON to unstake
     */
    function unstake(address sequencer, uint256 amount) external;

    /**
     * @notice Withdraw unstaked TON after unbonding period
     * @param sequencer The sequencer address
     */
    function withdraw(address sequencer) external;

    /**
     * @notice Claim pending rewards
     * @param sequencer The sequencer address
     */
    function claimRewards(address sequencer) external;

    /**
     * @notice Move stake from one sequencer to another
     * @param fromSequencer Source sequencer
     * @param toSequencer Destination sequencer
     * @param amount Amount to redelegate
     */
    function redelegate(address fromSequencer, address toSequencer, uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                         TRIGGER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Trigger seigniorage claim from OperatorManager
     * @param sequencer The sequencer address
     * @dev Can be called by anyone if autoTrigger is enabled
     */
    function triggerSeigniorage(address sequencer) external;

    /**
     * @notice Batch trigger seigniorage for multiple sequencers
     * @param sequencerList List of sequencer addresses
     */
    function batchTriggerSeigniorage(address[] calldata sequencerList) external;

    /*//////////////////////////////////////////////////////////////
                         EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Activate emergency mode for a Layer2
     * @param layer2 The Layer2 address
     * @dev Only guardian can call this
     */
    function activateEmergency(address layer2) external;

    /**
     * @notice Deactivate emergency mode
     * @param layer2 The Layer2 address
     * @dev Only guardian or owner can call this
     */
    function deactivateEmergency(address layer2) external;

    /**
     * @notice Emergency withdraw (bypasses unbonding when emergency active)
     * @param sequencer The sequencer address
     */
    function emergencyWithdraw(address sequencer) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get staker's stake info for a sequencer
     */
    function getStakeInfo(address staker, address sequencer) external view returns (StakeInfo memory);

    /**
     * @notice Get sequencer information
     */
    function getSequencerInfo(address sequencer) external view returns (SequencerInfo memory);

    /**
     * @notice Get pending rewards for a staker
     */
    function pendingRewards(address staker, address sequencer) external view returns (uint256);

    /**
     * @notice Get sequencer address by Layer2
     */
    function getSequencerByLayer2(address layer2) external view returns (address);

    /**
     * @notice Get list of active sequencers
     */
    function getSequencerList() external view returns (address[] memory);

    /**
     * @notice Get total staked amount
     */
    function getTotalStaked() external view returns (uint256);

    /**
     * @notice Get emergency config for a Layer2
     */
    function getEmergencyConfig(address layer2) external view returns (EmergencyConfig memory);

    /**
     * @notice Check if Layer2 is eligible for V3 rewards
     */
    function checkLayer2Eligibility(address layer2) external view returns (bool eligible, uint256 requiredStake, uint256 currentStake);

    /**
     * @notice Get estimated seigniorage for a sequencer
     */
    function estimateSeigniorage(address sequencer) external view returns (uint256 sequencerReward, uint256 validatorReward);
}
