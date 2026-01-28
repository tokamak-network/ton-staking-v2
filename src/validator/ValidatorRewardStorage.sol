// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ValidatorRewardStorage
/// @notice TON Staking V3 검증자 보상 스토리지
/// @dev Tokamak Economics Whitepaper V3 (December 16, 2025) 기준
/// @dev 검증자 등록/담보금은 RAT에서 관리, 이 컨트랙트는 보상 분배만 담당
/// @dev OpenZeppelin TransparentUpgradeableProxy 사용으로 ERC1967 slot 기반 프록시와 충돌 없음
contract ValidatorRewardStorage {
    // ==========================================
    // Constants
    // ==========================================

    uint256 internal constant RAY = 1e27;
    uint256 internal constant WEI_UNIT = 1e18;

    // ==========================================
    // 보상 관련
    // ==========================================

    /// @notice 검증자별 총 미청구 보상 (claimAllRewards에서 사용)
    /// @dev RAT에 등록된 검증자들의 보상을 여기서 관리
    mapping(address => uint256) public validatorPendingRewards;

    /// @notice 검증자별 L2별 미청구 보상 (DEPRECATED - 가스 최적화로 업데이트 안함)
    /// @dev 프록시 스토리지 호환성을 위해 슬롯 유지
    /// @dev L2별 보상은 ValidatorRewardReceived 이벤트로 추적
    mapping(address => mapping(address => uint256)) public validatorL2PendingRewards;

    /// @notice L2별 총 분배 금액 (DEPRECATED - 가스 최적화로 업데이트 안함)
    /// @dev 프록시 스토리지 호환성을 위해 슬롯 유지
    mapping(address => uint256) public l2TotalDistributed;

    // ==========================================
    // V1.1: RewardPerValidator 패턴 (O(1) 분배)
    // ==========================================

    /// @notice L2별 검증자당 누적 보상 (systemConfig => accumulated)
    /// @dev distributeL2Rewards에서 O(1)로 업데이트
    mapping(address => uint256) public rewardPerValidator;

    /// @notice 검증자별 L2별 보상 debt (validator => systemConfig => debt)
    /// @dev 검증자 등록 시 현재 rewardPerValidator로 설정
    mapping(address => mapping(address => uint256)) public validatorRewardDebt;

    /// @notice 검증자가 등록된 L2 목록 (validator => systemConfig[])
    /// @dev claimAllRewards에서 모든 L2 순회용
    mapping(address => address[]) public validatorL2List;

    /// @notice 검증자의 L2 등록 여부 (validator => systemConfig => bool)
    /// @dev 중복 등록 방지
    mapping(address => mapping(address => bool)) public isValidatorInL2;

    // ==========================================
    // 참조 주소
    // ==========================================

    /// @notice SeigManager 주소
    address public seigManager;

    /// @notice WTON 주소
    address public wton;

    /// @notice RAT 컨트랙트 주소 (L2별 검증자 조회용)
    address public ratContract;

    /// @notice Treasury 주소 (DEPRECATED - seigManager.dao() 사용)
    /// @dev 프록시 스토리지 호환성을 위해 슬롯 유지, 실제로는 사용하지 않음
    address public treasury;

    /// @notice Owner 주소
    address public owner;

    // ==========================================
    // 락
    // ==========================================

    bool internal _lock;

    modifier ifFree() {
        _ifFreeBefore();
        _;
        _ifFreeAfter();
    }

    function _ifFreeBefore() internal {
        require(!_lock, "locked");
        _lock = true;
    }

    function _ifFreeAfter() internal {
        _lock = false;
    }
}
