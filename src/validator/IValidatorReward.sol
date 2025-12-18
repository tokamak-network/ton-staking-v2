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

    /// @notice 검증자 없을 때 Treasury 귀속 이벤트
    event RewardToTreasury(
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice 검증자 보상 청구 이벤트
    event RewardsClaimed(
        address indexed validator,
        uint256 amount
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
    /// @dev |V_i| = 0이면 Treasury로 귀속
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param amount 분배할 보상 금액 (α · S_i)
    function distributeL2Rewards(address systemConfig, uint256 amount) external;

    /// @notice 모든 L2에서 받은 보상 한 번에 청구
    function claimAllRewards() external;

    // ==========================================
    // External Functions - Governance
    // ==========================================

    /// @notice RAT 컨트랙트 주소 설정
    function setRatContract(address rat) external;

    /// @notice Treasury 주소 설정
    function setTreasury(address _treasury) external;

    /// @notice SeigManager 주소 설정
    function setSeigManager(address _seigManager) external;
}
