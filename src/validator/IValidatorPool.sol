// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IValidatorPool
/// @notice TON Staking V3 검증자 풀 인터페이스
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
interface IValidatorPool {
    // ==========================================
    // Events
    // ==========================================

    /// @notice 검증자 등록 이벤트
    event ValidatorRegistered(
        address indexed validator,
        uint256 depositAmount
    );

    /// @notice 검증자 비활성화 이벤트
    event ValidatorDeactivated(address indexed validator);

    /// @notice 검증자 슬래싱 이벤트 (백서 V2)
    /// @param validator 슬래싱된 검증자
    /// @param slashedAmount 슬래싱된 금액 (C_off 또는 잔액 전액)
    /// @param removedFromSet D_min 미만으로 활성 세트에서 제거되었는지
    event ValidatorSlashed(
        address indexed validator,
        uint256 slashedAmount,
        bool removedFromSet
    );

    /// @notice RAT 발행 이벤트
    event RATIssued(
        address indexed validator,
        uint256 indexed batchId,
        uint256 deadline
    );

    /// @notice RAT 응답 이벤트
    event RATResponded(
        address indexed validator,
        uint256 indexed batchId,
        bool attestation
    );

    /// @notice 검증자 보상 분배 이벤트
    event ValidatorRewardDistributed(
        uint256 indexed periodId,
        uint256 totalAmount,
        uint256 perValidator
    );

    /// @notice 검증자 보상 청구 이벤트
    event ValidatorRewardClaimed(
        address indexed validator,
        uint256 amount
    );

    /// @notice 담보금 추가 이벤트
    event DepositAdded(
        address indexed validator,
        uint256 amount
    );

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 검증자 목록 조회
    function getValidators() external view returns (address[] memory);

    /// @notice 최소 담보금 계산
    /// @dev 백서 V2 공식 (5): D_validator = C_off + Δ_validator
    function getMinimumDeposit() external view returns (uint256);

    // ==========================================
    // External Functions - Validator Management
    // ==========================================

    /// @notice 검증자 등록
    /// @dev 백서 공식 (5): D_validator = C_off + Δ_validator
    /// @param depositAmount 담보금 (WTON)
    function registerValidator(uint256 depositAmount) external;

    /// @notice 담보금 추가
    /// @param amount 추가 금액 (WTON)
    function addDeposit(uint256 amount) external;

    /// @notice 검증자 비활성화 (탈퇴)
    function deactivateValidator() external;

    // ==========================================
    // External Functions - RAT (Randomized Attention Test)
    // ==========================================

    /// @notice RAT 발행 (프로토콜 전용)
    /// @param validator 대상 검증자
    /// @param batchId 배치 ID
    function issueRAT(address validator, uint256 batchId) external;

    /// @notice RAT 응답
    /// @param batchId 배치 ID
    /// @param attestation 증명 결과
    function respondToRAT(uint256 batchId, bool attestation) external;

    /// @notice RAT 미응답 슬래싱
    /// @dev 백서 V2: C_off 기반 슬래싱
    /// @param validator 대상 검증자
    /// @param batchId 배치 ID
    function slashUnresponsiveValidator(address validator, uint256 batchId) external;

    // ==========================================
    // External Functions - Rewards
    // ==========================================

    /// @notice 기간 보상 분배 (SeigManager에서 호출) - 전역 분배
    /// @dev 백서 공식 (13): v_i = (α/n) · y(x)
    /// @param periodId 기간 ID
    /// @param totalAmount 총 보상 금액
    function distributePeriodRewards(uint256 periodId, uint256 totalAmount) external;

    /// @notice L2별 검증자 보상 분배 (SeigManager에서 호출) - Per-L2 분배
    /// @dev 백서 V3 공식 (13): v_j = (α · S_i) / |V_i|
    /// @dev RAT에서 해당 L2의 검증자 목록을 조회하여 분배
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param amount 분배할 보상 금액 (α · S_i)
    function distributeL2Rewards(address systemConfig, uint256 amount) external;

    /// @notice Per-L2 분배에서 쌓인 검증자 보상 청구
    function claimL2Rewards() external;

    /// @notice 검증자 보상 청구 (전역 풀)
    function claimRewards() external;

    // ==========================================
    // External Functions - Governance
    // ==========================================

    /// @notice 슬래싱 페널티 설정 (C_off)
    function setSlashingPenalty(uint256 penalty) external;

    /// @notice 최소 임계값 설정 (D_min)
    function setMinimumThreshold(uint256 threshold) external;

    /// @notice RAT 트리거 확률 설정 (π_a)
    function setRatProbability(uint256 probability) external;

    /// @notice RAT 응답 윈도우 설정
    function setRatResponseWindow(uint256 window) external;

    /// @notice 최소 검증자 담보금 설정
    function setMinimumValidatorDeposit(uint256 amount) external;
}
