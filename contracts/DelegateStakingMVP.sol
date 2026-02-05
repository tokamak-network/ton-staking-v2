// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDelegateStakingMVP} from "./interfaces/IDelegateStakingMVP.sol";

/**
 * @title DelegateStakingMVP
 * @notice MVP implementation of delegate staking for Tokamak Network V3
 * @dev Sequencer Trust Model:
 *      - Users stake TON, delegating to sequencers
 *      - TON is stored in this L1 contract (not bridged)
 *      - Sequencers receive WTON rewards from V3 protocol
 *      - Sequencers manually transfer rewards to this contract
 *      - Rewards distributed using MasterChef pattern
 *
 * Token Units:
 *      - TON: 18 decimals (staking)
 *      - WTON: 27 decimals (rewards) - uses RAY precision
 */
contract DelegateStakingMVP is IDelegateStakingMVP, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum commission in basis points (30%)
    uint256 public constant MAX_COMMISSION = 3000;

    /// @notice Precision for reward calculations (RAY = 1e27 for WTON)
    uint256 private constant RAY = 1e27;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The staking token (TON - 18 decimals)
    IERC20 public immutable ton;

    /// @notice The reward token (WTON - 27 decimals)
    IERC20 public immutable wton;

    /// @notice Unbonding period in seconds
    uint256 public unbondingPeriod;

    /// @notice Mapping of sequencer address to SequencerInfo
    mapping(address => SequencerInfo) public sequencers;

    /// @notice Mapping of Layer2 address to sequencer address
    mapping(address => address) public sequencerOfLayer2;

    /// @notice Mapping of staker => sequencer => StakeInfo
    mapping(address => mapping(address => StakeInfo)) public stakes;

    /// @notice List of registered sequencer addresses
    address[] public sequencerList;

    /// @notice Total staked across all sequencers
    uint256 public totalStaked;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _ton TON token address (18 decimals)
     * @param _wton WTON token address (27 decimals)
     * @param _unbondingPeriod Unbonding period in seconds
     * @param _owner Contract owner address
     */
    constructor(
        address _ton,
        address _wton,
        uint256 _unbondingPeriod,
        address _owner
    ) {
        if (_ton == address(0) || _wton == address(0)) revert ZeroAddress();
        _transferOwnership(_owner);
        ton = IERC20(_ton);
        wton = IERC20(_wton);
        unbondingPeriod = _unbondingPeriod;
    }

    /*//////////////////////////////////////////////////////////////
                         SEQUENCER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingMVP
    function registerSequencer(
        address layer2,
        uint256 commission
    ) external override {
        if (layer2 == address(0)) revert ZeroAddress();
        if (sequencers[msg.sender].isRegistered) revert SequencerAlreadyRegistered();
        if (sequencerOfLayer2[layer2] != address(0)) revert Layer2AlreadyRegistered();
        if (commission > MAX_COMMISSION) revert InvalidCommission();

        sequencers[msg.sender] = SequencerInfo({
            isRegistered: true,
            layer2: layer2,
            commission: commission,
            totalStaked: 0,
            accRewardPerShare: 0,
            totalCommission: 0
        });

        sequencerOfLayer2[layer2] = msg.sender;
        sequencerList.push(msg.sender);

        emit SequencerRegistered(msg.sender, layer2, commission);
    }

    /// @inheritdoc IDelegateStakingMVP
    function deregisterSequencer() external override {
        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();
        if (info.totalStaked > 0) revert InsufficientBalance();

        // Transfer any remaining commission
        if (info.totalCommission > 0) {
            uint256 commission = info.totalCommission;
            info.totalCommission = 0;
            wton.safeTransfer(msg.sender, commission);
        }

        // Clear layer2 mapping
        sequencerOfLayer2[info.layer2] = address(0);
        info.isRegistered = false;

        // Note: We don't remove from sequencerList to avoid index issues
        // isRegistered check handles this

        emit SequencerDeregistered(msg.sender);
    }

    /// @inheritdoc IDelegateStakingMVP
    function updateCommission(uint256 newCommission) external override {
        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();
        if (newCommission > MAX_COMMISSION) revert InvalidCommission();

        uint256 oldCommission = info.commission;
        info.commission = newCommission;

        emit CommissionUpdated(msg.sender, oldCommission, newCommission);
    }

    /// @inheritdoc IDelegateStakingMVP
    function receiveReward(uint256 amount) external override nonReentrant {
        if (amount == 0) revert ZeroAmount();

        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();

        // Transfer WTON from sequencer
        wton.safeTransferFrom(msg.sender, address(this), amount);

        // Calculate commission
        uint256 commission = (amount * info.commission) / 10000;
        uint256 distributed = amount - commission;

        // Accumulate commission for sequencer to claim later
        info.totalCommission += commission;

        // Distribute to stakers if there are any
        if (info.totalStaked > 0) {
            // accRewardPerShare uses RAY precision (1e27)
            // distributed is in WTON (27 decimals)
            // totalStaked is in TON (18 decimals)
            // Result: (WTON * RAY) / TON = (1e27 * 1e27) / 1e18 = 1e36 per TON
            // This maintains precision for small stakes
            info.accRewardPerShare += (distributed * RAY) / info.totalStaked;
        }

        emit RewardsReceived(msg.sender, amount, commission, distributed);
    }

    /// @inheritdoc IDelegateStakingMVP
    function claimCommission() external override nonReentrant {
        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();

        uint256 commission = info.totalCommission;
        if (commission == 0) revert NoPendingRewards();

        info.totalCommission = 0;
        wton.safeTransfer(msg.sender, commission);
    }

    /*//////////////////////////////////////////////////////////////
                          DELEGATOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingMVP
    function stake(
        address sequencer,
        uint256 amount
    ) external override nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (!sequencers[sequencer].isRegistered) revert SequencerNotRegistered();

        StakeInfo storage stakeInfo = stakes[msg.sender][sequencer];
        SequencerInfo storage seqInfo = sequencers[sequencer];

        // Claim pending rewards before updating stake
        _claimRewardsInternal(msg.sender, sequencer);

        // Transfer TON from user
        ton.safeTransferFrom(msg.sender, address(this), amount);

        // Update stake info
        stakeInfo.amount += amount;
        stakeInfo.rewardDebt = (stakeInfo.amount * seqInfo.accRewardPerShare) / RAY;

        // Update totals
        seqInfo.totalStaked += amount;
        totalStaked += amount;

        emit Staked(msg.sender, sequencer, amount);
    }

    /// @inheritdoc IDelegateStakingMVP
    function unstake(
        address sequencer,
        uint256 amount
    ) external override nonReentrant {
        if (amount == 0) revert ZeroAmount();

        StakeInfo storage stakeInfo = stakes[msg.sender][sequencer];
        SequencerInfo storage seqInfo = sequencers[sequencer];

        if (stakeInfo.amount < amount) revert InsufficientBalance();

        // Claim pending rewards before updating stake
        _claimRewardsInternal(msg.sender, sequencer);

        // Update stake info
        stakeInfo.amount -= amount;
        stakeInfo.rewardDebt = (stakeInfo.amount * seqInfo.accRewardPerShare) / RAY;

        // Add to unstake queue
        stakeInfo.unstakeAmount += amount;
        stakeInfo.unstakeTime = block.timestamp;

        // Update totals
        seqInfo.totalStaked -= amount;
        totalStaked -= amount;

        uint256 unlockTime = block.timestamp + unbondingPeriod;
        emit UnstakeRequested(msg.sender, sequencer, amount, unlockTime);
    }

    /// @inheritdoc IDelegateStakingMVP
    function withdraw(address sequencer) external override nonReentrant {
        StakeInfo storage stakeInfo = stakes[msg.sender][sequencer];

        if (stakeInfo.unstakeAmount == 0) revert NoUnstakeRequest();
        if (block.timestamp < stakeInfo.unstakeTime + unbondingPeriod) {
            revert UnstakingPeriodNotElapsed();
        }

        uint256 amount = stakeInfo.unstakeAmount;
        stakeInfo.unstakeAmount = 0;
        stakeInfo.unstakeTime = 0;

        ton.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /// @inheritdoc IDelegateStakingMVP
    function claimRewards(address sequencer) external override nonReentrant {
        _claimRewardsInternal(msg.sender, sequencer);
    }

    /// @inheritdoc IDelegateStakingMVP
    function redelegate(
        address fromSequencer,
        address toSequencer,
        uint256 amount
    ) external override nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (fromSequencer == toSequencer) revert Unauthorized();
        if (!sequencers[toSequencer].isRegistered) revert SequencerNotRegistered();

        StakeInfo storage fromStake = stakes[msg.sender][fromSequencer];
        StakeInfo storage toStake = stakes[msg.sender][toSequencer];
        SequencerInfo storage fromSeq = sequencers[fromSequencer];
        SequencerInfo storage toSeq = sequencers[toSequencer];

        if (fromStake.amount < amount) revert InsufficientBalance();

        // Claim rewards from both sequencers
        _claimRewardsInternal(msg.sender, fromSequencer);
        _claimRewardsInternal(msg.sender, toSequencer);

        // Update from sequencer
        fromStake.amount -= amount;
        fromStake.rewardDebt = (fromStake.amount * fromSeq.accRewardPerShare) / RAY;
        fromSeq.totalStaked -= amount;

        // Update to sequencer
        toStake.amount += amount;
        toStake.rewardDebt = (toStake.amount * toSeq.accRewardPerShare) / RAY;
        toSeq.totalStaked += amount;

        emit Redelegated(msg.sender, fromSequencer, toSequencer, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingMVP
    function getStakeInfo(
        address staker,
        address sequencer
    ) external view override returns (StakeInfo memory) {
        return stakes[staker][sequencer];
    }

    /// @inheritdoc IDelegateStakingMVP
    function getSequencerInfo(
        address sequencer
    ) external view override returns (SequencerInfo memory) {
        return sequencers[sequencer];
    }

    /// @inheritdoc IDelegateStakingMVP
    function pendingRewards(
        address staker,
        address sequencer
    ) external view override returns (uint256) {
        StakeInfo storage stakeInfo = stakes[staker][sequencer];
        SequencerInfo storage seqInfo = sequencers[sequencer];

        if (stakeInfo.amount == 0) return 0;

        uint256 accReward = (stakeInfo.amount * seqInfo.accRewardPerShare) / RAY;
        return accReward > stakeInfo.rewardDebt ? accReward - stakeInfo.rewardDebt : 0;
    }

    /// @inheritdoc IDelegateStakingMVP
    function getSequencerByLayer2(
        address layer2
    ) external view override returns (address) {
        return sequencerOfLayer2[layer2];
    }

    /// @inheritdoc IDelegateStakingMVP
    function getSequencerList() external view override returns (address[] memory) {
        // Count active sequencers
        uint256 activeCount = 0;
        for (uint256 i = 0; i < sequencerList.length; i++) {
            if (sequencers[sequencerList[i]].isRegistered) {
                activeCount++;
            }
        }

        // Build active list
        address[] memory active = new address[](activeCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < sequencerList.length; i++) {
            if (sequencers[sequencerList[i]].isRegistered) {
                active[idx++] = sequencerList[i];
            }
        }

        return active;
    }

    /// @inheritdoc IDelegateStakingMVP
    function getTotalStaked() external view override returns (uint256) {
        return totalStaked;
    }

    /*//////////////////////////////////////////////////////////////
                           ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the unbonding period
     * @param _unbondingPeriod New unbonding period in seconds
     */
    function setUnbondingPeriod(uint256 _unbondingPeriod) external onlyOwner {
        unbondingPeriod = _unbondingPeriod;
    }

    /**
     * @notice Emergency withdraw stuck tokens
     * @param token Token address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        IERC20(token).safeTransfer(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to claim rewards
     * @param staker The staker address
     * @param sequencer The sequencer address
     */
    function _claimRewardsInternal(address staker, address sequencer) internal {
        StakeInfo storage stakeInfo = stakes[staker][sequencer];
        SequencerInfo storage seqInfo = sequencers[sequencer];

        if (stakeInfo.amount == 0) return;

        uint256 accReward = (stakeInfo.amount * seqInfo.accRewardPerShare) / RAY;
        uint256 pending = accReward > stakeInfo.rewardDebt
            ? accReward - stakeInfo.rewardDebt
            : 0;

        if (pending > 0) {
            stakeInfo.rewardDebt = accReward;
            wton.safeTransfer(staker, pending);
            emit RewardsClaimed(staker, sequencer, pending);
        }
    }
}
