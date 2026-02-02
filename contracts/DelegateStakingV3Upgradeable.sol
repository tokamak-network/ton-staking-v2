// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IDelegateStakingV3} from "./interfaces/IDelegateStakingV3.sol";

/**
 * @title DelegateStakingV3Upgradeable
 * @notice V3-integrated delegate staking for Tokamak Network (Upgradeable version)
 * @dev Key Features:
 *      1. UUPS Upgradeable pattern for contract upgrades
 *      2. Pausable for emergency stops
 *      3. Integration with SeigManager V3 for eligibility checks
 *      4. Integration with OperatorManager for seigniorage claiming
 *      5. Auto-trigger mechanism for seigniorage distribution
 *      6. Emergency exit mechanism for L2 failure scenarios
 *      7. MasterChef-style reward distribution
 *
 * Architecture:
 *      - Users stake TON, delegating to sequencers
 *      - Sequencers receive WTON seigniorage from V3 protocol
 *      - Seigniorage can be auto-triggered or manually distributed
 *      - Emergency mode allows instant withdrawal when L2 fails
 *
 * Token Units:
 *      - TON: 18 decimals (staking)
 *      - WTON: 27 decimals (rewards) - uses RAY precision
 */
contract DelegateStakingV3Upgradeable is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable,
    IDelegateStakingV3
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum commission in basis points (30%)
    uint256 public constant MAX_COMMISSION = 3000;

    /// @notice Precision for reward calculations (RAY = 1e27 for WTON)
    uint256 private constant RAY = 1e27;

    /// @notice Conversion factor from TON to WTON (1e9)
    uint256 private constant WTON_FACTOR = 1e9;

    /// @notice Default emergency cooldown period (3 days)
    uint256 public constant DEFAULT_EMERGENCY_COOLDOWN = 3 days;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The staking token (TON - 18 decimals)
    IERC20 public ton;

    /// @notice The reward token (WTON - 27 decimals)
    IERC20 public wton;

    /// @notice SeigManager V3 contract address
    address public seigManager;

    /// @notice Layer2Manager contract address
    address public layer2Manager;

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

    /// @notice Emergency configurations per Layer2
    mapping(address => EmergencyConfig) public emergencyConfigs;

    /// @notice Default guardian address for emergency activation
    address public defaultGuardian;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to rescue TON or WTON
    error CannotRescueStakingTokens();

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    /// @dev Reserved storage space to allow for layout changes in future upgrades
    uint256[50] private __gap;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                             INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the contract (replaces constructor)
     * @param _ton TON token address (18 decimals)
     * @param _wton WTON token address (27 decimals)
     * @param _seigManager SeigManager V3 address
     * @param _layer2Manager Layer2Manager address
     * @param _unbondingPeriod Unbonding period in seconds
     * @param _owner Contract owner address
     */
    function initialize(
        address _ton,
        address _wton,
        address _seigManager,
        address _layer2Manager,
        uint256 _unbondingPeriod,
        address _owner
    ) external initializer {
        if (_ton == address(0) || _wton == address(0)) revert ZeroAddress();

        __Ownable_init(_owner);
        __Pausable_init();

        ton = IERC20(_ton);
        wton = IERC20(_wton);
        seigManager = _seigManager;
        layer2Manager = _layer2Manager;
        unbondingPeriod = _unbondingPeriod;
        defaultGuardian = _owner;
    }

    /*//////////////////////////////////////////////////////////////
                         SEQUENCER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingV3
    function registerSequencer(
        address layer2,
        address operatorManager,
        uint256 commission
    ) external override whenNotPaused {
        if (layer2 == address(0)) revert ZeroAddress();
        if (operatorManager == address(0)) revert ZeroAddress();
        if (sequencers[msg.sender].isRegistered) revert SequencerAlreadyRegistered();
        if (sequencerOfLayer2[layer2] != address(0)) revert Layer2AlreadyRegistered();
        if (commission > MAX_COMMISSION) revert InvalidCommission();

        // Verify caller is the operator of the OperatorManager
        if (!_isOperator(operatorManager, msg.sender)) revert InvalidOperatorManager();

        sequencers[msg.sender] = SequencerInfo({
            isRegistered: true,
            layer2: layer2,
            operatorManager: operatorManager,
            commission: commission,
            totalStaked: 0,
            accRewardPerShare: 0,
            totalCommission: 0,
            autoTriggerEnabled: false
        });

        sequencerOfLayer2[layer2] = msg.sender;
        sequencerList.push(msg.sender);

        // Initialize emergency config
        emergencyConfigs[layer2] = EmergencyConfig({
            isActive: false,
            activationTime: 0,
            cooldownPeriod: DEFAULT_EMERGENCY_COOLDOWN,
            guardian: defaultGuardian
        });

        emit SequencerRegistered(msg.sender, layer2, operatorManager, commission);
    }

    /// @inheritdoc IDelegateStakingV3
    function deregisterSequencer() external override whenNotPaused {
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

        emit SequencerDeregistered(msg.sender);
    }

    /// @inheritdoc IDelegateStakingV3
    function updateCommission(uint256 newCommission) external override whenNotPaused {
        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();
        if (newCommission > MAX_COMMISSION) revert InvalidCommission();

        uint256 oldCommission = info.commission;
        info.commission = newCommission;

        emit CommissionUpdated(msg.sender, oldCommission, newCommission);
    }

    /// @inheritdoc IDelegateStakingV3
    function setAutoTrigger(bool enabled) external override whenNotPaused {
        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();

        info.autoTriggerEnabled = enabled;

        emit AutoTriggerToggled(msg.sender, enabled);
    }

    /// @inheritdoc IDelegateStakingV3
    function receiveReward(uint256 amount) external override nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();

        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();

        // Transfer WTON from sequencer
        wton.safeTransferFrom(msg.sender, address(this), amount);

        _distributeReward(msg.sender, amount);
    }

    /// @inheritdoc IDelegateStakingV3
    function claimCommission() external override nonReentrant whenNotPaused {
        SequencerInfo storage info = sequencers[msg.sender];
        if (!info.isRegistered) revert SequencerNotRegistered();

        uint256 commission = info.totalCommission;
        if (commission == 0) revert NoPendingRewards();

        info.totalCommission = 0;
        wton.safeTransfer(msg.sender, commission);

        emit CommissionClaimed(msg.sender, commission);
    }

    /*//////////////////////////////////////////////////////////////
                          DELEGATOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingV3
    function stake(address sequencer, uint256 amount) external override nonReentrant whenNotPaused {
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

    /// @inheritdoc IDelegateStakingV3
    function unstake(address sequencer, uint256 amount) external override nonReentrant whenNotPaused {
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

    /// @inheritdoc IDelegateStakingV3
    function withdraw(address sequencer) external override nonReentrant whenNotPaused {
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

    /// @inheritdoc IDelegateStakingV3
    function claimRewards(address sequencer) external override nonReentrant whenNotPaused {
        _claimRewardsInternal(msg.sender, sequencer);
    }

    /// @inheritdoc IDelegateStakingV3
    function redelegate(
        address fromSequencer,
        address toSequencer,
        uint256 amount
    ) external override nonReentrant whenNotPaused {
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
                         TRIGGER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingV3
    function triggerSeigniorage(address sequencer) external override nonReentrant whenNotPaused {
        SequencerInfo storage info = sequencers[sequencer];
        if (!info.isRegistered) revert SequencerNotRegistered();

        // Only allow if auto-trigger is enabled or caller is the sequencer
        if (!info.autoTriggerEnabled && msg.sender != sequencer) {
            revert AutoTriggerDisabled();
        }

        uint256 amount = _claimFromOperatorManager(info.operatorManager);

        if (amount > 0) {
            _distributeReward(sequencer, amount);
            emit SeigniorageTriggered(sequencer, amount, msg.sender);
        }
    }

    /// @inheritdoc IDelegateStakingV3
    function batchTriggerSeigniorage(address[] calldata _sequencerList) external override nonReentrant whenNotPaused {
        for (uint256 i = 0; i < _sequencerList.length; i++) {
            address sequencer = _sequencerList[i];
            SequencerInfo storage info = sequencers[sequencer];

            if (!info.isRegistered) continue;
            if (!info.autoTriggerEnabled) continue;

            uint256 amount = _claimFromOperatorManager(info.operatorManager);

            if (amount > 0) {
                _distributeReward(sequencer, amount);
                emit SeigniorageTriggered(sequencer, amount, msg.sender);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                         EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingV3
    function activateEmergency(address layer2) external override {
        EmergencyConfig storage config = emergencyConfigs[layer2];

        if (msg.sender != config.guardian && msg.sender != owner()) {
            revert NotGuardian();
        }
        if (config.isActive) revert EmergencyAlreadyActive();

        config.isActive = true;
        config.activationTime = block.timestamp;

        emit EmergencyActivated(layer2, msg.sender, block.timestamp);
    }

    /// @inheritdoc IDelegateStakingV3
    function deactivateEmergency(address layer2) external override {
        EmergencyConfig storage config = emergencyConfigs[layer2];

        if (msg.sender != config.guardian && msg.sender != owner()) {
            revert NotGuardian();
        }
        if (!config.isActive) revert EmergencyNotActive();

        config.isActive = false;
        config.activationTime = 0;

        emit EmergencyDeactivated(layer2, msg.sender);
    }

    /// @inheritdoc IDelegateStakingV3
    function emergencyWithdraw(address sequencer) external override nonReentrant {
        SequencerInfo storage seqInfo = sequencers[sequencer];
        EmergencyConfig storage config = emergencyConfigs[seqInfo.layer2];

        if (!config.isActive) revert EmergencyNotActive();
        if (block.timestamp < config.activationTime + config.cooldownPeriod) {
            revert EmergencyCooldownNotElapsed();
        }

        StakeInfo storage stakeInfo = stakes[msg.sender][sequencer];
        uint256 totalAmount = stakeInfo.amount + stakeInfo.unstakeAmount;

        if (totalAmount == 0) revert InsufficientBalance();

        // Update totals
        seqInfo.totalStaked -= stakeInfo.amount;
        totalStaked -= stakeInfo.amount;

        // Clear stake info
        stakeInfo.amount = 0;
        stakeInfo.rewardDebt = 0;
        stakeInfo.unstakeAmount = 0;
        stakeInfo.unstakeTime = 0;

        // Transfer all tokens
        ton.safeTransfer(msg.sender, totalAmount);

        emit EmergencyWithdrawn(msg.sender, sequencer, totalAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IDelegateStakingV3
    function getStakeInfo(address staker, address sequencer) external view override returns (StakeInfo memory) {
        return stakes[staker][sequencer];
    }

    /// @inheritdoc IDelegateStakingV3
    function getSequencerInfo(address sequencer) external view override returns (SequencerInfo memory) {
        return sequencers[sequencer];
    }

    /// @inheritdoc IDelegateStakingV3
    function pendingRewards(address staker, address sequencer) external view override returns (uint256) {
        StakeInfo storage stakeInfo = stakes[staker][sequencer];
        SequencerInfo storage seqInfo = sequencers[sequencer];

        if (stakeInfo.amount == 0) return 0;

        uint256 accReward = (stakeInfo.amount * seqInfo.accRewardPerShare) / RAY;
        return accReward > stakeInfo.rewardDebt ? accReward - stakeInfo.rewardDebt : 0;
    }

    /// @inheritdoc IDelegateStakingV3
    function getSequencerByLayer2(address layer2) external view override returns (address) {
        return sequencerOfLayer2[layer2];
    }

    /// @inheritdoc IDelegateStakingV3
    function getSequencerList() external view override returns (address[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < sequencerList.length; i++) {
            if (sequencers[sequencerList[i]].isRegistered) {
                activeCount++;
            }
        }

        address[] memory active = new address[](activeCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < sequencerList.length; i++) {
            if (sequencers[sequencerList[i]].isRegistered) {
                active[idx++] = sequencerList[i];
            }
        }

        return active;
    }

    /// @inheritdoc IDelegateStakingV3
    function getTotalStaked() external view override returns (uint256) {
        return totalStaked;
    }

    /// @inheritdoc IDelegateStakingV3
    function getEmergencyConfig(address layer2) external view override returns (EmergencyConfig memory) {
        return emergencyConfigs[layer2];
    }

    /// @inheritdoc IDelegateStakingV3
    function checkLayer2Eligibility(
        address layer2
    ) external view override returns (bool eligible, uint256 requiredStake, uint256 currentStake) {
        if (seigManager == address(0)) {
            return (true, 0, 0);
        }

        // Call SeigManager.checkCurrentEligibility(layer2)
        (bool success, bytes memory data) = seigManager.staticcall(
            abi.encodeWithSignature("checkCurrentEligibility(address)", layer2)
        );

        if (success && data.length >= 96) {
            (eligible, requiredStake, currentStake) = abi.decode(data, (bool, uint256, uint256));
        }
    }

    /// @inheritdoc IDelegateStakingV3
    function estimateSeigniorage(
        address sequencer
    ) external view override returns (uint256 sequencerReward, uint256 validatorReward) {
        SequencerInfo storage info = sequencers[sequencer];
        if (!info.isRegistered || seigManager == address(0)) {
            return (0, 0);
        }

        // Call SeigManager.estimateL2Seigniorage(layer2)
        (bool success, bytes memory data) = seigManager.staticcall(
            abi.encodeWithSignature("estimateL2Seigniorage(address)", info.layer2)
        );

        if (success && data.length >= 64) {
            (sequencerReward, validatorReward) = abi.decode(data, (uint256, uint256));
        }
    }

    /*//////////////////////////////////////////////////////////////
                           ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pause the contract
     * @dev Only owner can pause
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Only owner can unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Set the unbonding period
     * @param _unbondingPeriod New unbonding period in seconds
     */
    function setUnbondingPeriod(uint256 _unbondingPeriod) external onlyOwner {
        uint256 oldPeriod = unbondingPeriod;
        unbondingPeriod = _unbondingPeriod;
        emit UnbondingPeriodUpdated(oldPeriod, _unbondingPeriod);
    }

    /**
     * @notice Set SeigManager address
     * @param _seigManager New SeigManager address
     */
    function setSeigManager(address _seigManager) external onlyOwner {
        address oldManager = seigManager;
        seigManager = _seigManager;
        emit SeigManagerUpdated(oldManager, _seigManager);
    }

    /**
     * @notice Set Layer2Manager address
     * @param _layer2Manager New Layer2Manager address
     */
    function setLayer2Manager(address _layer2Manager) external onlyOwner {
        address oldManager = layer2Manager;
        layer2Manager = _layer2Manager;
        emit Layer2ManagerUpdated(oldManager, _layer2Manager);
    }

    /**
     * @notice Set default guardian for new sequencers
     * @param _guardian New default guardian address
     */
    function setDefaultGuardian(address _guardian) external onlyOwner {
        if (_guardian == address(0)) revert ZeroAddress();
        defaultGuardian = _guardian;
    }

    /**
     * @notice Set guardian for a specific Layer2
     * @param layer2 The Layer2 address
     * @param guardian New guardian address
     */
    function setLayer2Guardian(address layer2, address guardian) external onlyOwner {
        if (guardian == address(0)) revert ZeroAddress();
        emergencyConfigs[layer2].guardian = guardian;
    }

    /**
     * @notice Set emergency cooldown period for a Layer2
     * @param layer2 The Layer2 address
     * @param cooldownPeriod New cooldown period in seconds
     */
    function setEmergencyCooldown(address layer2, uint256 cooldownPeriod) external onlyOwner {
        emergencyConfigs[layer2].cooldownPeriod = cooldownPeriod;
    }

    /**
     * @notice Emergency withdraw stuck tokens (owner only)
     * @dev Cannot rescue TON or WTON to prevent rug-pulls
     * @param token Token address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function rescueTokens(address token, address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (token == address(ton) || token == address(wton)) {
            revert CannotRescueStakingTokens();
        }
        IERC20(token).safeTransfer(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          UUPS UPGRADE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Authorize upgrade to new implementation
     * @dev Only owner can authorize upgrades
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Get the current implementation version
     * @return Version string
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to distribute rewards
     * @param sequencer The sequencer address
     * @param amount Total WTON amount to distribute
     */
    function _distributeReward(address sequencer, uint256 amount) internal {
        SequencerInfo storage info = sequencers[sequencer];

        // Calculate commission
        uint256 commission = (amount * info.commission) / 10000;
        uint256 distributed = amount - commission;

        // Accumulate commission for sequencer
        info.totalCommission += commission;

        // Distribute to stakers if there are any
        if (info.totalStaked > 0) {
            info.accRewardPerShare += (distributed * RAY) / info.totalStaked;
        }

        emit RewardsReceived(sequencer, amount, commission, distributed);
    }

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
        uint256 pending = accReward > stakeInfo.rewardDebt ? accReward - stakeInfo.rewardDebt : 0;

        if (pending > 0) {
            stakeInfo.rewardDebt = accReward;
            wton.safeTransfer(staker, pending);
            emit RewardsClaimed(staker, sequencer, pending);
        }
    }

    /**
     * @notice Check if address is operator of OperatorManager
     * @param operatorManager The OperatorManager address
     * @param operator The address to check
     */
    function _isOperator(address operatorManager, address operator) internal view returns (bool) {
        if (operatorManager == address(0)) return false;

        (bool success, bytes memory data) = operatorManager.staticcall(
            abi.encodeWithSignature("isOperator(address)", operator)
        );

        if (success && data.length >= 32) {
            return abi.decode(data, (bool));
        }
        return false;
    }

    /**
     * @notice Claim WTON from OperatorManager
     * @param operatorManager The OperatorManager address
     * @return amount The claimed WTON amount
     */
    function _claimFromOperatorManager(address operatorManager) internal returns (uint256 amount) {
        if (operatorManager == address(0)) return 0;

        uint256 balanceBefore = wton.balanceOf(address(this));

        // Try to claim ERC20 (WTON) from OperatorManager
        // Note: The actual implementation depends on OperatorManager interface
        (bool success,) =
            operatorManager.call(abi.encodeWithSignature("claimERC20(address,uint256)", address(wton), type(uint256).max));

        if (success) {
            amount = wton.balanceOf(address(this)) - balanceBefore;
        }
    }

    /*//////////////////////////////////////////////////////////////
                          NEW EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when unbonding period is updated
    event UnbondingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);

    /// @notice Emitted when SeigManager is updated
    event SeigManagerUpdated(address oldManager, address newManager);

    /// @notice Emitted when Layer2Manager is updated
    event Layer2ManagerUpdated(address oldManager, address newManager);
}
