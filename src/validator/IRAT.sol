// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IRAT
/// @notice Randomized Attention Test (RAT) 인터페이스
/// @dev Tokamak Economics Whitepaper V3 (December 16, 2025) 기준
/// @dev RAT은 검증자 등록/담보금/슬래싱만 담당
/// @dev 검증자 보상 분배는 ValidatorReward 컨트랙트에서 처리
interface IRAT {
    // ==========================================
    // Events
    // ==========================================

    /// @notice 검증자 등록 이벤트
    event ValidatorRegistered(
        address indexed validator,
        address indexed systemConfig,
        uint256 depositAmount,
        uint256 registrationId
    );

    /// @notice 검증자 탈퇴 이벤트
    event ValidatorDeactivated(
        address indexed validator,
        address indexed systemConfig,
        uint256 returnedAmount
    );

    /// @notice Attention Test 트리거 이벤트
    event AttentionTestTriggered(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        address gameAddress,
        uint32 batchIndex,
        uint256 deadline
    );

    /// @notice 증거 제출 이벤트
    event EvidenceSubmitted(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint32 batchIndex
    );

    /// @notice 슬래싱 이벤트
    /// @param validator 슬래싱된 검증자
    /// @param systemConfig L2 SystemConfig 주소
    /// @param slashedAmount 슬래싱된 금액 (C_off)
    /// @param removedFromSet D_min 미만으로 활성 세트에서 제거되었는지
    event ValidatorSlashed(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint256 slashedAmount,
        bool removedFromSet
    );

    // V3: RewardsClaimed, RewardsClaimedBatch 이벤트 제거 - ValidatorReward로 이동

    /// @notice 담보금 추가 이벤트
    event DepositAdded(
        address indexed validator,
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice 챌린지 승리로 담보금 복구 이벤트 (resolveClaim)
    event BondRestored(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint256 restoredAmount
    );

    /// @notice 검증자 세트 복구 이벤트 (D_min 미만 제거 후 복구)
    event ValidatorRestored(
        address indexed validator,
        address indexed systemConfig
    );

    // V3: WithdrawalProcessed 이벤트 제거 - deactivateValidator에서 즉시 출금
    // V3: ValidatorRewardToTreasury 이벤트 제거 - ValidatorReward로 이동

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 최소 담보금 계산
    /// @dev 백서 공식 (5): D_validator = C_off + Δ_validator
    function getMinimumCollateral() external view returns (uint256);

    /// @notice 슬래싱 페널티 검증
    /// @dev 백서 공식 (4): C_off ≥ (c_m · n) / π_a
    /// @param n 검증자 수
    function validateSlashingPenalty(uint256 n) external view returns (bool);

    /// @notice 특정 L2의 검증자 수 조회
    function getValidatorCount(address systemConfig) external view returns (uint256);

    /// @notice 특정 L2의 활성 검증자 수 조회
    function getActiveValidatorCount(address systemConfig) external view returns (uint256);

    /// @notice 특정 L2의 검증자 목록 조회
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return validators 해당 L2에 등록된 검증자 주소 목록
    function getL2Validators(address systemConfig) external view returns (address[] memory validators);

    /// @notice 특정 L2의 검증자 활성 상태 확인
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 활성 여부
    function isValidatorActive(address validator, address systemConfig) external view returns (bool);

    /// @notice 검증자 등록 정보 조회
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return depositedAmount 현재 유효 담보금 (원금 - 슬래싱 손실)
    /// @return totalBondForRAT 진행 중인 RAT 테스트에 묶인 금액
    /// @return validatorIndex 검증자 인덱스
    /// @return isActive 활성 상태
    function getValidatorRegistration(address validator, address systemConfig)
        external
        view
        returns (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            uint32 validatorIndex,
            bool isActive
        );

    /// @notice 검증자 담보금 조회 (외부 컨트랙트용 간편 함수)
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 현재 담보금 (슬래싱 반영된 금액)
    function getValidatorDeposit(address validator, address systemConfig) external view returns (uint256);

    // ==========================================
    // External Functions - Validator Management
    // ==========================================

    /// @notice 검증자 등록
    /// @dev V3: TON.approveAndCall(RAT, amount, systemConfig) 사용 권장
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param depositAmount 담보금 (TON)
    function registerValidator(address systemConfig, uint256 depositAmount) external;

    /// @notice 검증자 탈퇴 및 즉시 출금
    /// @dev V3: DepositManager 미사용으로 즉시 출금 가능
    /// @param systemConfig L2의 SystemConfig 주소
    function deactivateValidator(address systemConfig) external;

    /// @notice 담보금 추가 예치
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param amount 추가 금액 (TON)
    function addDeposit(address systemConfig, uint256 amount) external;

    // V3: processWithdrawal 제거 - deactivateValidator에서 즉시 출금

    // ==========================================
    // External Functions - RAT Operations
    // ==========================================

    /// @notice RAT 테스트 트리거
    /// @dev DisputeGameFactory에서만 호출 가능
    /// @param gameAddress 생성된 DisputeGame 주소 (resolveClaim에서 testId 조회용)
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param batchIndex 배치 인덱스
    /// @param batchHash 배치 해시
    /// @param blockHash 블록 해시 (랜덤 시드)
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice RAT 증거 제출
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param batchIndex 배치 인덱스
    /// @param evidence 증거 데이터
    function submitEvidence(
        address systemConfig,
        uint32 batchIndex,
        bytes calldata evidence
    ) external;

    /// @notice FaultDisputeGame에서 게임 해결 시 호출 (챌린저 승리 시 담보금 복구)
    /// @dev msg.sender = FaultDisputeGame 주소
    /// @param _claimant 게임에서 이긴 주소 (챌린저)
    function resolveClaim(address _claimant) external;

    // V3: Rewards 섹션 제거 - ValidatorReward 컨트랙트로 이동
    // - claimRewards(systemConfig) -> ValidatorReward.claimAllRewards()
    // - claimRewardsBatch(systemConfigs) -> ValidatorReward.claimAllRewards()
    // - distributeValidatorReward(systemConfig, amount) -> ValidatorReward.distributeL2Rewards()

    // ==========================================
    // External Functions - Governance
    // ==========================================

    /// @notice Attention Cost 설정 (c_m)
    function setAttentionCost(uint256 cost) external;

    /// @notice 슬래싱 페널티 설정 (C_off)
    function setSlashingPenalty(uint256 penalty) external;

    /// @notice 검증자 버퍼 설정 (Δ_validator)
    function setValidatorBuffer(uint256 buffer) external;

    /// @notice 최소 임계값 설정 (D_min)
    function setMinimumThreshold(uint256 threshold) external;

    /// @notice RAT 트리거 확률 설정 (π_a)
    function setRatTriggerProbability(uint256 probability) external;

    /// @notice 증거 제출 기간 설정
    function setEvidenceSubmissionPeriod(uint256 period) external;
}
