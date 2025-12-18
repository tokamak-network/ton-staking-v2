// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ValidatorRewardStorage} from "./ValidatorRewardStorage.sol";
import {IValidatorReward} from "./IValidatorReward.sol";
import {IRAT} from "./IRAT.sol";

// Custom Errors
error NotOwnerError();
error NotSeigManagerError();
error NoRewardsError();
error ZeroAddressError();
error ZeroAmountError();

/**
 * @title ValidatorRewardV1
 * @notice TON Staking V3 검증자 보상 컨트랙트
 * @dev Tokamak Economics Whitepaper V3 (December 16, 2025) 기준
 *
 * 핵심 기능:
 * 1. L2별 검증자 보상 분배 (RAT에서 검증자 목록 조회)
 * 2. 검증자 보상 청구
 *
 * 검증자 등록/담보금/슬래싱은 RAT에서 관리
 */
contract ValidatorRewardV1 is ValidatorRewardStorage, IValidatorReward {
    using SafeERC20 for IERC20;

    // ==========================================
    // Modifiers
    // ==========================================

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerError();
        _;
    }

    modifier onlySeigManager() {
        if (msg.sender != seigManager) revert NotSeigManagerError();
        _;
    }

    // ==========================================
    // Initializer
    // ==========================================

    function initialize(
        address _seigManager,
        address _wton,
        address _ratContract,
        address _treasury,
        address _owner
    ) external {
        require(seigManager == address(0), "already initialized");

        seigManager = _seigManager;
        wton = _wton;
        ratContract = _ratContract;
        treasury = _treasury;
        owner = _owner;
    }

    // ==========================================
    // View Functions
    // ==========================================

    /// @inheritdoc IValidatorReward
    function getPendingRewards(address validator) external view returns (uint256) {
        return validatorPendingRewards[validator];
    }

    /// @inheritdoc IValidatorReward
    function getPendingRewardsByL2(address validator, address systemConfig) external view returns (uint256) {
        return validatorL2PendingRewards[validator][systemConfig];
    }

    // ==========================================
    // Rewards Distribution
    // ==========================================

    /// @inheritdoc IValidatorReward
    /// @dev 백서 V3 공식 (13): v_j = (α · S_i) / |V_i|
    function distributeL2Rewards(address systemConfig, uint256 amount)
        external
        onlySeigManager
    {
        if (amount == 0) return;
        if (ratContract == address(0)) revert ZeroAddressError();

        // RAT에서 해당 L2의 활성 검증자 수 조회
        uint256 activeCount = IRAT(ratContract).getActiveValidatorCount(systemConfig);

        // |V_i| = 0이면 Treasury로 귀속 (백서 V3)
        if (activeCount == 0) {
            if (treasury != address(0)) {
                IERC20(wton).safeTransfer(treasury, amount);
                emit RewardToTreasury(systemConfig, amount);
            }
            return;
        }

        // v_j = amount / |V_i|
        uint256 perValidator = amount / activeCount;
        if (perValidator == 0) return;

        // RAT에서 검증자 목록 조회
        address[] memory validators = IRAT(ratContract).getL2Validators(systemConfig);
        uint256 len = validators.length;

        // 각 활성 검증자에게 보상 누적
        uint256 distributed = 0;
        for (uint256 i = 0; i < len; i++) {
            address validator = validators[i];
            if (IRAT(ratContract).isValidatorActive(validator, systemConfig)) {
                // 총 보상 누적 (claimAllRewards용)
                validatorPendingRewards[validator] += perValidator;
                // Per-L2 보상 누적 (조회/통계용)
                validatorL2PendingRewards[validator][systemConfig] += perValidator;
                distributed += perValidator;

                // 개별 검증자 이벤트 (추적용)
                emit ValidatorRewardReceived(validator, systemConfig, perValidator);
            }
        }

        // 통계 업데이트
        l2TotalDistributed[systemConfig] += distributed;

        emit L2RewardDistributed(systemConfig, amount, activeCount, perValidator);
    }

    /// @inheritdoc IValidatorReward
    function claimAllRewards() external ifFree {
        uint256 rewards = validatorPendingRewards[msg.sender];
        if (rewards == 0) revert NoRewardsError();

        validatorPendingRewards[msg.sender] = 0;

        IERC20(wton).safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    // ==========================================
    // Governance Functions
    // ==========================================

    /// @inheritdoc IValidatorReward
    function setRatContract(address rat) external onlyOwner {
        if (rat == address(0)) revert ZeroAddressError();
        ratContract = rat;
    }

    /// @inheritdoc IValidatorReward
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /// @inheritdoc IValidatorReward
    function setSeigManager(address _seigManager) external onlyOwner {
        if (_seigManager == address(0)) revert ZeroAddressError();
        seigManager = _seigManager;
    }

    /// @notice Owner 변경
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddressError();
        owner = newOwner;
    }

    // ==========================================
    // Emergency Functions
    // ==========================================

    /// @notice 비상 출금 (Owner 전용)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner, amount);
    }
}
