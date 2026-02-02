// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DelegateTrigger
 * @notice Automated seigniorage trigger for DelegateStaking
 * @dev Features:
 *      1. Keeper-compatible batch triggering
 *      2. Gas-efficient batch operations
 *      3. Incentivized triggering (optional rewards for keepers)
 *
 * This contract monitors OperatorManagers for pending seigniorage
 * and triggers distribution to DelegateStaking contracts.
 */
contract DelegateTrigger is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct TriggerConfig {
        address delegateStaking; // DelegateStaking contract
        address operatorManager; // OperatorManager for this L2
        address sequencer; // Sequencer address
        bool isActive; // Whether this trigger is active
        uint256 lastTriggerTime; // Last trigger timestamp
        uint256 minInterval; // Minimum interval between triggers
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TriggerRegistered(
        bytes32 indexed triggerId,
        address indexed delegateStaking,
        address indexed sequencer
    );
    event TriggerDeactivated(bytes32 indexed triggerId);
    event TriggerActivated(bytes32 indexed triggerId);
    event SeigniorageTriggered(
        bytes32 indexed triggerId,
        address indexed triggeredBy,
        uint256 amount
    );
    event KeeperRewardPaid(address indexed keeper, uint256 amount);
    event KeeperRewardUpdated(uint256 oldReward, uint256 newReward);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error TriggerNotFound();
    error TriggerNotActive();
    error TriggerAlreadyExists();
    error IntervalNotElapsed();
    error InsufficientRewardBalance();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice WTON token for rewards
    IERC20 public immutable wton;

    /// @notice Mapping of trigger ID to config
    mapping(bytes32 => TriggerConfig) public triggers;

    /// @notice List of all trigger IDs
    bytes32[] public triggerIds;

    /// @notice Reward per trigger for keepers (in WTON)
    uint256 public keeperReward;

    /// @notice Total accumulated rewards for keepers
    uint256 public keeperRewardPool;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _wton, address _owner) Ownable(_owner) {
        if (_wton == address(0)) revert ZeroAddress();
        wton = IERC20(_wton);
    }

    /*//////////////////////////////////////////////////////////////
                         REGISTRATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register a new trigger configuration
     * @param delegateStaking DelegateStaking contract address
     * @param operatorManager OperatorManager contract address
     * @param sequencer Sequencer address
     * @param minInterval Minimum interval between triggers
     */
    function registerTrigger(
        address delegateStaking,
        address operatorManager,
        address sequencer,
        uint256 minInterval
    ) external onlyOwner returns (bytes32 triggerId) {
        if (delegateStaking == address(0)) revert ZeroAddress();
        if (operatorManager == address(0)) revert ZeroAddress();
        if (sequencer == address(0)) revert ZeroAddress();

        triggerId = keccak256(abi.encodePacked(delegateStaking, operatorManager, sequencer));

        if (triggers[triggerId].delegateStaking != address(0)) {
            revert TriggerAlreadyExists();
        }

        triggers[triggerId] = TriggerConfig({
            delegateStaking: delegateStaking,
            operatorManager: operatorManager,
            sequencer: sequencer,
            isActive: true,
            lastTriggerTime: 0,
            minInterval: minInterval
        });

        triggerIds.push(triggerId);

        emit TriggerRegistered(triggerId, delegateStaking, sequencer);
    }

    /**
     * @notice Deactivate a trigger
     * @param triggerId The trigger ID
     */
    function deactivateTrigger(bytes32 triggerId) external onlyOwner {
        TriggerConfig storage config = triggers[triggerId];
        if (config.delegateStaking == address(0)) revert TriggerNotFound();

        config.isActive = false;
        emit TriggerDeactivated(triggerId);
    }

    /**
     * @notice Reactivate a trigger
     * @param triggerId The trigger ID
     */
    function activateTrigger(bytes32 triggerId) external onlyOwner {
        TriggerConfig storage config = triggers[triggerId];
        if (config.delegateStaking == address(0)) revert TriggerNotFound();

        config.isActive = true;
        emit TriggerActivated(triggerId);
    }

    /**
     * @notice Update minimum interval for a trigger
     * @param triggerId The trigger ID
     * @param newInterval New minimum interval
     */
    function updateMinInterval(bytes32 triggerId, uint256 newInterval) external onlyOwner {
        TriggerConfig storage config = triggers[triggerId];
        if (config.delegateStaking == address(0)) revert TriggerNotFound();

        config.minInterval = newInterval;
    }

    /*//////////////////////////////////////////////////////////////
                          TRIGGER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Trigger seigniorage for a specific trigger
     * @param triggerId The trigger ID
     */
    function trigger(bytes32 triggerId) external nonReentrant {
        TriggerConfig storage config = triggers[triggerId];

        if (config.delegateStaking == address(0)) revert TriggerNotFound();
        if (!config.isActive) revert TriggerNotActive();
        if (block.timestamp < config.lastTriggerTime + config.minInterval) {
            revert IntervalNotElapsed();
        }

        config.lastTriggerTime = block.timestamp;

        // Call triggerSeigniorage on DelegateStaking
        uint256 amount = _executeTrigger(config);

        // Pay keeper reward if applicable
        _payKeeperReward(msg.sender);

        emit SeigniorageTriggered(triggerId, msg.sender, amount);
    }

    /**
     * @notice Batch trigger multiple sequencers
     * @param _triggerIds Array of trigger IDs
     */
    function batchTrigger(bytes32[] calldata _triggerIds) external nonReentrant {
        uint256 successCount = 0;

        for (uint256 i = 0; i < _triggerIds.length; i++) {
            TriggerConfig storage config = triggers[_triggerIds[i]];

            if (config.delegateStaking == address(0)) continue;
            if (!config.isActive) continue;
            if (block.timestamp < config.lastTriggerTime + config.minInterval) continue;

            config.lastTriggerTime = block.timestamp;

            uint256 amount = _executeTrigger(config);

            if (amount > 0) {
                successCount++;
                emit SeigniorageTriggered(_triggerIds[i], msg.sender, amount);
            }
        }

        // Pay keeper reward for successful triggers
        if (successCount > 0 && keeperReward > 0) {
            uint256 totalReward = keeperReward * successCount;
            if (totalReward <= keeperRewardPool) {
                keeperRewardPool -= totalReward;
                wton.safeTransfer(msg.sender, totalReward);
                emit KeeperRewardPaid(msg.sender, totalReward);
            }
        }
    }

    /**
     * @notice Get all ready-to-trigger IDs
     * @return readyTriggers Array of trigger IDs that are ready
     */
    function getReadyTriggers() external view returns (bytes32[] memory readyTriggers) {
        uint256 count = 0;

        // First pass: count ready triggers
        for (uint256 i = 0; i < triggerIds.length; i++) {
            TriggerConfig storage config = triggers[triggerIds[i]];
            if (config.isActive && block.timestamp >= config.lastTriggerTime + config.minInterval) {
                count++;
            }
        }

        // Second pass: collect ready triggers
        readyTriggers = new bytes32[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < triggerIds.length; i++) {
            TriggerConfig storage config = triggers[triggerIds[i]];
            if (config.isActive && block.timestamp >= config.lastTriggerTime + config.minInterval) {
                readyTriggers[idx++] = triggerIds[i];
            }
        }
    }

    /**
     * @notice Check if a trigger is ready
     * @param triggerId The trigger ID
     */
    function isReady(bytes32 triggerId) external view returns (bool) {
        TriggerConfig storage config = triggers[triggerId];
        return config.isActive && block.timestamp >= config.lastTriggerTime + config.minInterval;
    }

    /*//////////////////////////////////////////////////////////////
                           KEEPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set keeper reward amount
     * @param _keeperReward Reward per successful trigger in WTON
     */
    function setKeeperReward(uint256 _keeperReward) external onlyOwner {
        uint256 oldReward = keeperReward;
        keeperReward = _keeperReward;
        emit KeeperRewardUpdated(oldReward, _keeperReward);
    }

    /**
     * @notice Fund keeper reward pool
     * @param amount Amount of WTON to add
     */
    function fundKeeperRewardPool(uint256 amount) external {
        wton.safeTransferFrom(msg.sender, address(this), amount);
        keeperRewardPool += amount;
    }

    /**
     * @notice Withdraw from keeper reward pool (owner only)
     * @param amount Amount to withdraw
     */
    function withdrawKeeperRewardPool(uint256 amount) external onlyOwner {
        if (amount > keeperRewardPool) revert InsufficientRewardBalance();
        keeperRewardPool -= amount;
        wton.safeTransfer(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get all trigger IDs
     */
    function getAllTriggerIds() external view returns (bytes32[] memory) {
        return triggerIds;
    }

    /**
     * @notice Get trigger config
     * @param triggerId The trigger ID
     */
    function getTriggerConfig(bytes32 triggerId) external view returns (TriggerConfig memory) {
        return triggers[triggerId];
    }

    /**
     * @notice Get active trigger count
     */
    function getActiveTriggerCount() external view returns (uint256 count) {
        for (uint256 i = 0; i < triggerIds.length; i++) {
            if (triggers[triggerIds[i]].isActive) {
                count++;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Execute trigger on DelegateStaking
     * @param config The trigger configuration
     * @return amount Amount triggered
     */
    function _executeTrigger(TriggerConfig storage config) internal returns (uint256 amount) {
        uint256 balanceBefore = wton.balanceOf(config.delegateStaking);

        // Call triggerSeigniorage on DelegateStaking
        (bool success, ) = config.delegateStaking.call(
            abi.encodeWithSignature("triggerSeigniorage(address)", config.sequencer)
        );

        if (success) {
            amount = wton.balanceOf(config.delegateStaking) - balanceBefore;
        }
    }

    /**
     * @notice Pay keeper reward
     * @param keeper The keeper address
     */
    function _payKeeperReward(address keeper) internal {
        if (keeperReward > 0 && keeperRewardPool >= keeperReward) {
            keeperRewardPool -= keeperReward;
            wton.safeTransfer(keeper, keeperReward);
            emit KeeperRewardPaid(keeper, keeperReward);
        }
    }
}
