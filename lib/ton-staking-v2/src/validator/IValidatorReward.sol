// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IValidatorReward
/// @notice TON Staking V3 검증자 보상 인터페이스
/// @dev Tokamak Economics Whitepaper V3 (December 16, 2025) 기준
/// @dev 검증자 등록/담보금은 RAT에서 관리, 이 컨트랙트는 보상 분배만 담당
interface IValidatorReward {
    // ==========================================
    // Events
    // ==========================================

    /// @notice L2별 검증자 보상 분배 이벤트 (요약)
    event L2RewardDistributed(
        address indexed systemConfig,
        uint256 totalAmount,
        uint256 activeValidatorCount,
        uint256 perValidator
    );

    /// @notice 검증자별 보상 분배 이벤트 (개별 추적용)
    /// @dev 이벤트로 어느 L2에서 얼마를 받았는지 추적 가능
    event ValidatorRewardReceived(
        address indexed validator,
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice 검증자 없을 때 DAO(daoVault) 귀속 이벤트
    event RewardToDAO(
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice DEPRECATED - RewardToDAO 사용
    event RewardToTreasury(
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice 검증자 보상 청구 이벤트
    event RewardsClaimed(
        address indexed validator,
        uint256 amount
    );

    // NOTE: ValidatorRewardSynced 제거됨 - ValidatorRewardReceived로 통합

    /// @notice 검증자 L2 등록 이벤트 (V1.1)
    event ValidatorRegisteredToL2(
        address indexed validator,
        address indexed systemConfig,
        uint256 initialDebt
    );

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 검증자의 총 미청구 보상 조회
    /// @param validator 검증자 주소
    /// @return 총 미청구 보상 금액
    function getPendingRewards(address validator) external view returns (uint256);

    /// @notice 검증자의 특정 L2별 미청구 보상 조회
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 해당 L2에서의 미청구 보상 금액
    function getPendingRewardsByL2(address validator, address systemConfig) external view returns (uint256);

    // ==========================================
    // External Functions - Rewards
    // ==========================================

    /// @notice L2별 검증자 보상 분배 (SeigManager에서 호출)
    /// @dev 백서 V3 공식 (13): v_j = (α · S_i) / |V_i|
    /// @dev RAT에서 해당 L2의 검증자 목록을 조회하여 분배
    /// @dev |V_i| = 0이면 DAO(SeigManager.dao())로 귀속
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param amount 분배할 보상 금액 (α · S_i)
    function distributeL2Rewards(address systemConfig, uint256 amount) external;

    /// @notice 모든 L2에서 받은 보상 한 번에 청구
    /// @dev 등록된 L2가 많으면 가스 한도 초과 가능 - claimRewardsByL2s 사용 권장
    function claimAllRewards() external;

    /// @notice 특정 L2들에서 받은 보상 청구
    /// @dev 등록된 L2가 많을 때 가스 최적화를 위해 사용
    /// @param systemConfigs 보상을 청구할 L2 SystemConfig 주소 배열
    function claimRewardsByL2s(address[] calldata systemConfigs) external;

    /// @notice 검증자 L2 등록 (RAT에서 호출)
    /// @dev 검증자가 L2에 등록될 때 초기 debt 설정
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    function registerValidatorToL2(address validator, address systemConfig) external;

    /// @notice 검증자 보상 동기화 (비활성화 전 호출)
    /// @dev 현재까지의 보상을 pendingRewards에 누적
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    function syncValidatorReward(address validator, address systemConfig) external;

    /// @notice 검증자 재활성화 시 debt 리셋 (RAT에서 호출)
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    function resetValidatorDebt(address validator, address systemConfig) external;

    /// @notice 검증자의 청구 가능한 보상 계산 (view)
    /// @param validator 검증자 주소
    /// @return total 총 청구 가능 금액
    function getClaimableRewards(address validator) external view returns (uint256 total);

    // ==========================================
    // External Functions - Governance
    // ==========================================

    /// @notice RAT 컨트랙트 주소 설정
    function setRatContract(address rat) external;

    /// @notice DEPRECATED - treasury는 더 이상 사용되지 않음
    /// @dev 검증자 없는 L2의 보상은 SeigManager.dao()로 전송됨
    function setTreasury(address _treasury) external;

    /// @notice SeigManager 주소 설정
    function setSeigManager(address _seigManager) external;
}
