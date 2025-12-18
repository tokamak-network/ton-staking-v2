// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ValidatorPoolStorage
/// @notice TON Staking V3 검증자 풀 스토리지
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
contract ValidatorPoolStorage {
    // ==========================================
    // Constants
    // ==========================================

    uint256 internal constant RAY = 1e27;
    uint256 internal constant WEI_UNIT = 1e18;

    // ==========================================
    // 검증자 정보
    // ==========================================

    struct ValidatorInfo {
        bool isActive;                  // 활성 상태
        uint256 depositAmount;          // D_validator: 담보금
        uint256 pendingRewards;         // 미청구 보상
        uint256 lastClaimPeriod;        // 마지막 청구 기간
        uint256 lastRATResponse;        // 마지막 RAT 응답 시간
        uint256 registeredAt;           // 등록 시간
        uint256 validatorIndex;         // 검증자 인덱스
    }

    /// @notice 검증자 목록
    address[] public validators;

    /// @notice 검증자 정보 매핑
    mapping(address => ValidatorInfo) public validatorInfo;

    /// @notice 검증자 인덱스 매핑
    mapping(address => uint256) public validatorIndex;

    /// @notice 활성 검증자 수 (n)
    uint256 public activeValidatorCount;

    // ==========================================
    // RAT 관련 (Randomized Attention Test)
    // ==========================================

    struct RATChallenge {
        address validator;              // 대상 검증자
        uint256 batchId;                // 배치 ID
        uint256 deadline;               // 응답 마감
        bool responded;                 // 응답 여부
        bool slashed;                   // 슬래싱 여부
        uint256 createdAt;              // 생성 시간
    }

    /// @notice RAT 챌린지 매핑 (challengeId => RATChallenge)
    mapping(bytes32 => RATChallenge) public ratChallenges;

    /// @notice RAT 발생 확률 (π_a), RAY 단위
    /// @dev 백서 공식 (3): c_m ≤ (π_a / N) · C_off
    uint256 public ratProbability;

    /// @notice RAT 응답 윈도우 (초)
    uint256 public ratResponseWindow;

    // ==========================================
    // 보상 관련
    // ==========================================

    /// @notice 기간별 검증자 풀 총액
    mapping(uint256 => uint256) public periodValidatorPool;

    /// @notice 기간별 검증자당 보상
    mapping(uint256 => uint256) public periodPerValidatorReward;

    /// @notice 현재 기간 ID
    uint256 public currentPeriodId;

    // ==========================================
    // 백서 V2 파라미터
    // ==========================================

    /// @notice C_off: 슬래싱 페널티 (백서 공식 4)
    /// @dev 백서 공식 (4): C_off ≥ (c_m · N) / π_a
    uint256 public slashingPenalty;

    /// @notice D_min: 최소 담보금 임계값
    /// @dev 잔액이 D_min 미만이면 활성 검증자 세트에서 제거
    uint256 public minimumThreshold;

    /// @notice 최소 검증자 담보금 (D_validator)
    /// @dev 백서 공식 (5): D_validator = C_off + Δ_validator
    uint256 public minimumValidatorDeposit;

    /// @notice c_m: 에폭당 attentiveness 유지 비용
    /// @dev 백서 공식 (3): c_m ≤ (π_a / N) · C_off
    uint256 public attentionCost;

    /// @notice Δ_validator: 검증자 추가 버퍼
    uint256 public validatorBuffer;

    // ==========================================
    // 참조 주소
    // ==========================================

    /// @notice SeigManager 주소
    address public seigManager;

    /// @notice WTON 주소
    address public wton;

    /// @notice TON 주소
    address public ton;

    /// @notice RAT 트리거 권한 주소 (DisputeGameFactory 등)
    address public ratIssuer;

    /// @notice Owner 주소
    address public owner;

    // ==========================================
    // Per-L2 분배 관련
    // ==========================================

    /// @notice RAT 컨트랙트 주소 (L2별 검증자 조회용)
    address public ratContract;

    /// @notice Treasury 주소 (검증자 없을 때 보상 귀속)
    address public treasury;

    /// @notice 검증자별 누적 보상 (Per-L2 분배에서 누적)
    /// @dev RAT에 등록된 검증자들의 보상을 여기서 관리
    mapping(address => uint256) public validatorPendingRewards;

    // ==========================================
    // 락 (Note: onlyOwner is in Proxy, others in ValidatorPoolV1 implementation)
    // ==========================================

    bool internal _lock;

    modifier ifFree() {
        require(!_lock, "locked");
        _lock = true;
        _;
        _lock = false;
    }
}
