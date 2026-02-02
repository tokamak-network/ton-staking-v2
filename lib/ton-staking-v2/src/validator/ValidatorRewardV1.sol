// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ValidatorRewardStorage} from "./ValidatorRewardStorage.sol";
import {IValidatorReward} from "./IValidatorReward.sol";
import {IRAT} from "./IRAT.sol";

/// @notice SeigManager의 dao 주소 조회용 인터페이스
interface ISeigManagerDAO {
    function dao() external view returns (address);
}

// Custom Errors
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
 * 권한 관리는 AccessibleCommon(onlyOwner)을 통해 처리
 */
contract ValidatorRewardV1 is ValidatorRewardStorage, IValidatorReward {
    using SafeERC20 for IERC20;

    // ==========================================
    // Modifiers
    // ==========================================

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlySeigManager() {
        if (msg.sender != seigManager) revert NotSeigManagerError();
        _;
    }

    // ==========================================
    // Initializer
    // ==========================================

    /// @notice 초기화 (V1.1: treasury 파라미터 제거 - seigManager.dao() 사용)
    /// @param _seigManager SeigManager 주소 (dao 주소 조회용)
    /// @param _wton WTON 주소
    /// @param _ratContract RAT 컨트랙트 주소
    /// @param _owner Owner 주소
    function initialize(
        address _seigManager,
        address _wton,
        address _ratContract,
        address _owner
    ) external {
        require(seigManager == address(0), "already initialized");

        seigManager = _seigManager;
        wton = _wton;
        ratContract = _ratContract;
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
    /// @dev DEPRECATED: 가스 최적화로 더 이상 업데이트되지 않음
    /// @dev L2별 보상은 ValidatorRewardReceived 이벤트로 추적
    function getPendingRewardsByL2(address, address) external pure returns (uint256) {
        return 0; // deprecated - use events
    }

    /// @inheritdoc IValidatorReward
    /// @dev 동기화되지 않은 보상도 포함하여 계산
    /// @dev 가스 최적화: 배열 길이 캐싱, unchecked 연산
    function getClaimableRewards(address validator) external view returns (uint256 total) {
        total = validatorPendingRewards[validator];

        // 등록된 모든 L2에서 미동기화 보상 계산
        address[] memory l2List = validatorL2List[validator];
        uint256 len = l2List.length;
        for (uint256 i = 0; i < len; ) {
            address systemConfig = l2List[i];
            uint256 currentRewardPerValidator = rewardPerValidator[systemConfig];
            uint256 debt = validatorRewardDebt[validator][systemConfig];

            if (currentRewardPerValidator > debt) {
                // 활성 검증자만 보상 받을 수 있음
                if (IRAT(ratContract).isValidatorActive(validator, systemConfig)) {
                    unchecked {
                        total += (currentRewardPerValidator - debt);
                    }
                }
            }
            unchecked { ++i; }
        }
    }

    // ==========================================
    // Rewards Distribution (V1.1: O(1) 분배)
    // ==========================================

    /// @inheritdoc IValidatorReward
    /// @dev V1.1: O(1) 복잡도로 변경 - 검증자 수와 무관
    /// @dev 백서 V3 공식 (13): v_j = (α · S_i) / |V_i|
    function distributeL2Rewards(address systemConfig, uint256 amount)
        external
        onlySeigManager
    {
        if (amount == 0) return;
        if (ratContract == address(0)) revert ZeroAddressError();

        // RAT에서 해당 L2의 활성 검증자 수 조회
        uint256 activeCount = IRAT(ratContract).getActiveValidatorCount(systemConfig);

        // |V_i| = 0이면 DAO(daoVault)로 귀속 (백서 V3)
        if (activeCount == 0) {
            address daoAddr = ISeigManagerDAO(seigManager).dao();
            if (daoAddr != address(0)) {
                IERC20(wton).safeTransfer(daoAddr, amount);
                emit RewardToDAO(systemConfig, amount);
            }
            return;
        }

        // v_j = amount / |V_i| - O(1) 누적
        uint256 perValidator = amount / activeCount;
        if (perValidator == 0) return;

        // 전역 누적 (검증자별 순회 없음)
        rewardPerValidator[systemConfig] += perValidator;

        // NOTE: l2TotalDistributed 업데이트 제거 (가스 최적화)
        // 필요시 rewardPerValidator * activeCount로 계산 가능

        emit L2RewardDistributed(systemConfig, amount, activeCount, perValidator);
    }

    /// @inheritdoc IValidatorReward
    /// @dev 청구 전 모든 L2 보상 동기화
    /// @dev 등록된 L2가 많으면 가스 한도 초과 가능 - claimRewardsByL2s 사용 권장
    function claimAllRewards() external ifFree {
        address validator = msg.sender;

        // 먼저 모든 L2 보상 동기화
        _syncAllRewards(validator);

        uint256 rewards = validatorPendingRewards[validator];
        if (rewards == 0) revert NoRewardsError();

        validatorPendingRewards[validator] = 0;

        IERC20(wton).safeTransfer(validator, rewards);

        emit RewardsClaimed(validator, rewards);
    }

    /// @inheritdoc IValidatorReward
    /// @dev 특정 L2들만 동기화 후 청구
    /// @dev 등록된 L2가 많을 때 가스 최적화를 위해 사용
    function claimRewardsByL2s(address[] calldata systemConfigs) external ifFree {
        address validator = msg.sender;

        // 지정된 L2들만 보상 동기화
        uint256 len = systemConfigs.length;
        for (uint256 i = 0; i < len; ) {
            address systemConfig = systemConfigs[i];
            // 등록된 L2만 동기화
            if (isValidatorInL2[validator][systemConfig]) {
                _syncReward(validator, systemConfig);
            }
            unchecked { ++i; }
        }

        uint256 rewards = validatorPendingRewards[validator];
        if (rewards == 0) revert NoRewardsError();

        validatorPendingRewards[validator] = 0;

        IERC20(wton).safeTransfer(validator, rewards);

        emit RewardsClaimed(validator, rewards);
    }

    // ==========================================
    // Validator Registration (V1.1)
    // ==========================================

    /// @inheritdoc IValidatorReward
    /// @dev RAT.registerValidator에서 호출
    function registerValidatorToL2(address validator, address systemConfig) external {
        require(msg.sender == ratContract, "only RAT");

        uint256 currentReward = rewardPerValidator[systemConfig];

        // 이미 등록된 경우 (재등록): debt만 리셋
        // 비활성화 기간 동안의 보상을 받지 않도록 함
        if (isValidatorInL2[validator][systemConfig]) {
            validatorRewardDebt[validator][systemConfig] = currentReward;
            return;
        }

        // 신규 등록: L2 목록에 추가
        validatorL2List[validator].push(systemConfig);
        isValidatorInL2[validator][systemConfig] = true;

        // 현재 rewardPerValidator를 초기 debt로 설정
        validatorRewardDebt[validator][systemConfig] = currentReward;

        emit ValidatorRegisteredToL2(validator, systemConfig, currentReward);
    }

    /// @inheritdoc IValidatorReward
    /// @dev RAT에서 검증자 비활성화 전 호출
    function syncValidatorReward(address validator, address systemConfig) external {
        require(msg.sender == ratContract, "only RAT");
        _syncReward(validator, systemConfig);
    }

    /// @inheritdoc IValidatorReward
    /// @dev RAT에서 검증자 재활성화 시 호출
    function resetValidatorDebt(address validator, address systemConfig) external {
        require(msg.sender == ratContract, "only RAT");

        // 현재 rewardPerValidator를 새 debt로 설정
        validatorRewardDebt[validator][systemConfig] = rewardPerValidator[systemConfig];
    }

    // ==========================================
    // Internal Functions (V1.1)
    // ==========================================

    /// @notice 단일 L2 보상 동기화
    /// @dev 가스 최적화: unchecked 블록 사용 (이미 조건 검증됨)
    /// @dev validatorL2PendingRewards 업데이트 제거 - 이벤트로 추적
    function _syncReward(address validator, address systemConfig) internal {
        uint256 currentRewardPerValidator = rewardPerValidator[systemConfig];
        uint256 debt = validatorRewardDebt[validator][systemConfig];

        if (currentRewardPerValidator > debt) {
            uint256 earned;
            unchecked {
                earned = currentRewardPerValidator - debt;
            }

            // 활성 검증자만 보상 누적
            if (IRAT(ratContract).isValidatorActive(validator, systemConfig)) {
                unchecked {
                    validatorPendingRewards[validator] += earned;
                }

                // L2별 보상은 이벤트로 추적 (validatorL2PendingRewards 제거됨)
                emit ValidatorRewardReceived(validator, systemConfig, earned);
            }

            // debt 업데이트
            validatorRewardDebt[validator][systemConfig] = currentRewardPerValidator;
        }
    }

    /// @notice 모든 L2 보상 동기화
    /// @dev 가스 최적화: 배열 길이 캐싱 및 unchecked 인덱스 증가
    function _syncAllRewards(address validator) internal {
        address[] memory l2List = validatorL2List[validator];
        uint256 len = l2List.length;
        for (uint256 i = 0; i < len; ) {
            _syncReward(validator, l2List[i]);
            unchecked { ++i; }
        }
    }

    // ==========================================
    // Governance Functions
    // ==========================================

    /// @inheritdoc IValidatorReward
    function setRatContract(address rat) external onlyOwner {
        if (rat == address(0)) revert ZeroAddressError();
        ratContract = rat;
    }

    /// @notice DEPRECATED - treasury는 더 이상 사용되지 않음
    /// @dev 검증자 없는 L2의 보상은 SeigManager.dao()로 전송됨
    function setTreasury(address) external pure {
        revert("deprecated: use SeigManager.dao()");
    }

    /// @inheritdoc IValidatorReward
    function setSeigManager(address _seigManager) external onlyOwner {
        if (_seigManager == address(0)) revert ZeroAddressError();
        seigManager = _seigManager;
    }

    /// @notice Owner 변경
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        owner = newOwner;
    }

    // ==========================================
    // Emergency Functions
    // ==========================================

    /// @notice 비상 출금 (Owner 전용)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
