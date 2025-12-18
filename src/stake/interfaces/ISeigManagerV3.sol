// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ISeigManagerV3
/// @notice TON Staking V3 SeigManager 인터페이스
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
interface ISeigManagerV3 {
    // ==========================================
    // Events
    // ==========================================

    /// @notice V3 시뇨리지 분배 이벤트
    event SeigGivenV3(
        address indexed layer2,
        uint256 totalSeigniorage,       // A: 기간 시뇨리지
        uint256 daoAllocation,          // d·A₂: DAO 고정분
        uint256 l2MaxAllocation,        // L = (1-d)·A₂: 분배 가능량
        uint256 totalEffectiveBridgedTON, // x: 전체 유효 Bridged TON
        uint256 totalDistributed,       // y(x): 쌍곡선 결과
        uint256 l2Seigniorage,          // Seig_i: 해당 L2 분배량
        uint256 sequencerReward,        // o_i: 시퀀서 보상
        uint256 validatorPoolAmount,    // α·y(x): 검증자 풀
        uint256 undistributed           // L - y(x): DAO 추가분
    );

    /// @notice V3 시뇨리지 전체 분배 이벤트
    event V3SeigniorageDistributed(
        uint256 totalSeigniorage,       // A₂
        uint256 l2MaxAllocation,        // L
        uint256 totalDistributed,       // y(x)
        uint256 daoAmount,              // S_DAO + undistributed
        uint256 validatorPoolAmount     // α · y(x)
    );

    /// @notice Bridged TON 변경 이벤트
    event BridgedTONChanged(
        address indexed layer2,
        uint256 bridgedTON,
        uint256 effectiveBridgedTON,
        bool isEligible
    );

    /// @notice L2 자격 상태 변경 이벤트
    event EligibilityChanged(
        address indexed layer2,
        bool eligible,
        uint256 bridgedTON,
        uint256 effectiveBridgedTON
    );

    /// @notice 지분 시뇨리지 비율 변경 이벤트
    event StakedSeigFactorUpdated(uint256 newLambda);

    /// @notice 추가 시뇨리지 비율 변경 이벤트
    event RelativeSeigRateUpdated(uint256 newRate);

    /// @notice DAO 분배 비율 변경 이벤트
    event DaoDistributionRatioUpdated(uint256 newRatio);

    /// @notice 최소 스테이킹 비율 변경 이벤트
    event MinStakingRatioUpdated(uint256 newRatio);

    /// @notice 검증자 분배 비율 변경 이벤트
    event ValidatorDistributionRatioUpdated(uint256 newRatio);

    /// @notice 반포화점 변경 이벤트
    event HalfSaturationPointUpdated(uint256 newK);

    /// @notice 검증자 보상 컨트랙트 설정 이벤트
    event ValidatorRewardUpdated(address newReward);

    /// @notice V3 마이그레이션 완료 이벤트
    event V3MigrationCompleted(uint256 blockNumber, uint256 totalMigratedL2s);

    // ==========================================
    // View Functions - L2 Information
    // ==========================================

    /// @notice 유효 Bridged TON 조회 (자격 없으면 0)
    function getEffectiveBridgedTON(address layer2) external view returns (uint256);

    /// @notice L2 자격 실시간 확인 (L1 브리지에서 직접 조회)
    /// @dev B_i는 L1 브리지에서 동적으로 조회, S_i는 coinage에서 동적으로 조회
    /// @param layer2 L2 주소
    /// @return eligible 자격 여부
    /// @return requiredStake 필요 스테이킹 (θ·B_i)
    /// @return currentStake 현재 스테이킹 (S_i)
    function checkCurrentEligibility(address layer2)
        external
        view
        returns (bool eligible, uint256 requiredStake, uint256 currentStake);

    /// @notice 쌍곡선 포화 함수 계산
    /// @dev 백서 공식 (11): y(x) = L · (x / (k + x))
    /// @param x 전체 유효 Bridged TON
    /// @param maxL2Allocation L2 분배 가능량 (L)
    /// @return y 분배 가능 시뇨리지
    function hyperbolicSaturation(uint256 x, uint256 maxL2Allocation)
        external
        view
        returns (uint256 y);

    /// @notice 개별 L2 시뇨리지 계산
    /// @dev 백서 공식 (12): Seig_i = y(x) · (B̃_i / x)
    function calculateL2Seigniorage(
        address layer2,
        uint256 totalY,
        uint256 totalX
    ) external view returns (uint256 seigniorage);

    /// @notice 시퀀서 보상 계산
    /// @dev 백서 공식 (13): o_i = (1 - α) · Seig_i
    function calculateSequencerReward(uint256 l2Seigniorage)
        external
        view
        returns (uint256);

    /// @notice L2별 시뇨리지 예측
    function estimateL2Seigniorage(address layer2) external view returns (uint256 seigniorage);

    // ==========================================
    // External Functions - Callbacks
    // ==========================================

    /// @notice L2의 Bridged TON 변경 시 호출 (타입 3 전용)
    /// @dev OptimismPortal에서 TON 입금/출금 시 SeigManager를 직접 호출
    ///      호출자(msg.sender)로부터 L1BridgeRegistry.rollupConfigWithPortal로 rollupConfig 조회
    ///      트리거 함수이므로 revert 대신 early return 사용
    function onBridgedTONChange() external;

    /// @notice L2의 스테이킹 금액 변경 시 호출
    /// @dev DepositManager에서 deposit/withdraw 시 호출
    /// @param layer2 L2 주소 (candidate)
    function onStakingChange(address layer2) external;

    // ==========================================
    // External Functions - Governance
    // ==========================================

    /// @notice DAO 분배 비율 설정
    function setDaoDistributionRatio(uint256 ratio) external;

    /// @notice 최소 스테이킹 비율 설정
    function setMinStakingRatio(uint256 ratio) external;

    /// @notice 검증자 분배 비율 설정
    function setValidatorDistributionRatio(uint256 ratio) external;

    /// @notice 반포화점 설정
    function setHalfSaturationPoint(uint256 k) external;

    /// @notice 지분 시뇨리지 비율 설정 (V2→V3 전환)
    function setStakedSeigFactor(uint256 lambda) external;

    /// @notice 검증자 보상 컨트랙트 주소 설정
    function setValidatorReward(address reward) external;

    /// @notice 최대 챌린저 수 설정
    function setMaxChallengers(uint256 hMax) external;

    /// @notice 최대 fraud proof 비용 설정
    function setMaxFraudProofCost(uint256 cMax) external;

    // ==========================================
    // External Functions - Migration
    // ==========================================

    /// @notice V2 → V3 데이터 마이그레이션
    function migrateToV3() external;
}
