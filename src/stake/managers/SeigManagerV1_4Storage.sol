// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title SeigManagerV1_4Storage
/// @notice V3 핵심 파라미터 및 Bridged TON 기반 분배 스토리지
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
contract SeigManagerV1_4Storage {
    // ==========================================
    // V3 핵심 파라미터 (백서 기준)
    // ==========================================

    /// @notice d: DAO 분배 비율 (0 < d < 1), RAY 단위
    /// @dev 백서 공식 (7): S_DAO = d · A₂
    uint256 public daoDistributionRatio;

    /// @notice θ: 최소 스테이킹 비율 (0 < θ ≤ 1), RAY 단위
    /// @dev 백서 공식 (8): S_i ≥ θ · B_i
    uint256 public minStakingRatio;

    /// @notice α: 검증자 분배 비율 (0 < α < 1), RAY 단위
    /// @dev 백서 공식 (13): v_i = (α/n) · y(x)
    uint256 public validatorDistributionRatio;

    /// @notice k: 반포화점 (half-saturation point), RAY 단위
    /// @dev 백서 공식 (11): y(k) = L/2
    uint256 public halfSaturationPoint;

    /// @notice λ: 지분 시뇨리지 비율 (V2→V3 전환용), RAY 단위
    /// @dev λ = 1.0: V2와 동일, λ = 0: 지분 시뇨리지 없음
    uint256 public stakedSeigFactor;

    // ==========================================
    // Bridged TON 관련 스토리지
    // ==========================================

    /// @notice 전체 유효 Bridged TON 합계: x = Σ B̃_i
    uint256 public totalEffectiveBridgedTON;

    /// @notice Bridged TON 1단위당 누적 보상 (V2의 l2RewardPerUint 대응)
    /// @dev bridgedTONRewardPerUint = Σ(y(x) / x) 누적값
    uint256 public bridgedTONRewardPerUint;

    /// @notice L2별 Bridged TON 정보
    struct BridgedTONInfo {
        uint256 currentBridgedTON;      // B_i: 현재 Bridged TON
        uint256 effectiveBridgedTON;    // B̃_i: 유효 Bridged TON (자격 없으면 0)
        uint256 initialDebt;            // 초기부채 (V2 패턴 동일)
        uint256 startBlock;             // 참여 시작 블록
        uint256 lastUpdateTime;         // 마지막 업데이트 타임스탬프
        bool isEligible;                // 자격 여부 (S_i ≥ θ·B_i)
    }

    /// @notice layer2 => BridgedTONInfo
    mapping(address => BridgedTONInfo) public bridgedTONInfo;

    // ==========================================
    // 검증자 보상 관련
    // ==========================================

    /// @notice ValidatorReward 컨트랙트 주소
    /// @dev Per-L2 검증자 보상 분배용
    address public validatorReward;

    /// @notice 기간(Period) 정보
    struct PeriodInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalSeigniorage;
        uint256 totalDistributed;       // y(x)
        uint256 validatorPoolAmount;    // α · y(x)
        bool finalized;
    }

    /// @notice 현재 기간 ID
    uint256 public currentPeriodId;

    /// @notice 기간 정보 매핑
    mapping(uint256 => PeriodInfo) public periods;

    // ==========================================
    // 시퀀서 슬래싱 관련 파라미터 (백서 공식 1, 2)
    // ==========================================

    /// @notice H_max: 최대 동시 챌린저 수
    /// @dev 백서 공식 (1): D_sequencer = H_max · C_max + Δ_sequencer
    uint256 public maxChallengers;

    /// @notice C_max: 단일 fraud proof 예상 온체인 비용
    /// @dev 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
    uint256 public maxFraudProofCost;

    // ==========================================
    // V3 마이그레이션 상태
    // ==========================================

    /// @notice V3 마이그레이션 완료 여부
    bool public v3Migrated;

    /// @notice V3 마이그레이션 블록
    uint256 public v3MigrationBlock;

    // ==========================================
    // SequencerVault 참조
    // ==========================================

    /// @notice SequencerVault 컨트랙트 주소
    /// @dev V3: 시퀀서 자격 조건(S_i ≥ θ·B_i)을 SequencerVault 담보금으로 확인
    address public sequencerVault;


}
