// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title RATStorage
/// @notice Randomized Attention Test (RAT) 스토리지
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
/// @dev ProxyStorage, AccessibleCommon은 로직 컨트랙트(RAT.sol, RATFastWithdrawal.sol)에서 상속
/// @dev Storage slot 순서: ProxyStorage → AccessibleCommon → RATStorage (Proxy.sol과 동일)
contract RATStorage {
    // ==========================================
    // Constants
    // ==========================================

    uint256 internal constant RAY = 1e27;
    uint256 internal constant WEI_UNIT = 1e18;
    uint256 internal constant MAX_PROBABILITY = 1e27; // 100% in RAY

    // ==========================================
    // Enums
    // ==========================================

    /// @notice RAT 테스트 상태
    /// @dev 시간 기반으로 계산되는 상태 (EvidencePeriod → ChallengePeriod → Slashed)
    enum AttentionTestStatus {
        None,                   // 존재하지 않음
        EvidencePeriod,         // 증거 제출 기간 (deadline 전)
        ChallengePeriod,        // 챌린지 기간 (deadline 후 ~ +challengeGameDuration)
        RestoredByEvidence,     // 증거 제출로 복구됨
        RestoredByChallenge,    // 챌린지 승리로 복구됨
        Slashed                 // 슬래싱 확정 (deadline + challengeGameDuration 후)
    }

    // ==========================================
    // Structs
    // ==========================================

    /// @notice 검증자 등록 정보
    /// @dev 백서 V2 공식 (5) 기반: D_validator = C_off + Δ_validator
    /// @dev V3: 담보금은 coinage에서 직접 조회 (SeigManager.stakeOf)
    /// @dev V3: 슬래싱은 SeigManager를 통해 처리 (선차감 시 validator→RAT, 복구 시 RAT→validator)
    struct ValidatorRegistration {
        uint256 lockedForRAT;           // DEPRECATED: coinage 잔액으로 직접 확인 가능
        uint256 pendingRewards;         // DEPRECATED: V3에서 ValidatorReward 컨트랙트로 이동
        uint64 latestTestDeadline;      // 가장 최근 RAT 테스트 마감 시간 (기록용)
        uint32 validatorIndex;          // 검증자 인덱스
        bool isActive;                  // 활성 상태
        bytes blsPublicKey;             // BLS12-381 공개키 (48 bytes, G1 point) - Fast Withdrawal용
    }

    /// @notice Attention Test 정보
    struct AttentionTest {
        address validatorAddress;       // 선택된 검증자
        address systemConfig;           // L2 SystemConfig 주소
        uint32 batchIndex;              // 배치 인덱스
        address gameAddress;            // DisputeGame 주소 (rootClaim 조회용)
        bytes32 batchHash;              // 배치 해시
        uint256 bondAmount;             // 선차감된 담보금 (C_off)
        uint256 createdAt;              // 생성 시간
        uint256 deadline;               // 응답 마감 시간
        AttentionTestStatus status;     // 상태
    }

    /// @notice SystemConfig별 검증자 풀 정보
    struct ValidatorPoolInfo {
        address[] validators;           // 검증자 목록
        uint256 activeCount;            // 활성 검증자 수
        uint256 totalDeposited;         // 총 예치 금액
    }

    // ==========================================
    // 검증자 관련 스토리지
    // ==========================================

    /// @notice systemConfig => validator => ValidatorRegistration
    mapping(address => mapping(address => ValidatorRegistration)) public validatorRegistrations;

    /// @notice systemConfig => ValidatorPoolInfo
    mapping(address => ValidatorPoolInfo) internal validatorPools;

    /// @notice systemConfig => validator => 검증자 인덱스
    mapping(address => mapping(address => uint256)) public validatorIndexes;

    /// @notice validator => 등록된 systemConfig 목록
    mapping(address => address[]) public validatorSystemConfigs;

    // ==========================================
    // Attention Test 관련 스토리지
    // ==========================================

    /// @notice testId => AttentionTest
    mapping(bytes32 => AttentionTest) public attentionTests;

    /// @notice systemConfig => batchIndex => testId
    mapping(address => mapping(uint32 => bytes32)) public batchToTestId;

    /// @notice systemConfig => 활성 테스트 수
    mapping(address => uint256) public activeTestCount;

    /// @notice systemConfig => 가장 늦은 테스트 마감 시간
    /// @dev 이 시간이 지나면 RAT coinage 잔액을 DAO로 전송 가능
    mapping(address => uint256) public latestDeadlineTest;

    /// @notice game address => testId 매핑 (resolveClaim에서 사용)
    mapping(address => bytes32) public gameToTestId;

    // ==========================================
    // 백서 V2 파라미터 (Page 11)
    // ==========================================

    /// @notice c_m: 에폭당 attentiveness 유지 비용
    /// @dev 백서 공식 (3): c_m ≤ (π_a / n) · C_off
    uint256 public attentionCost;

    /// @notice C_off: 슬래싱 페널티
    /// @dev 백서 공식 (4): C_off ≥ (c_m · n) / π_a
    uint256 public slashingPenalty;

    /// @notice Δ_validator: 검증자 추가 버퍼
    uint256 public validatorBuffer;

    /// @notice π_a: RAT 트리거 확률 (RAY 단위)
    uint256 public ratTriggerProbability;

    /// @notice D_min: 최소 담보금 임계값
    /// @dev 잔액이 D_min 미만이면 활성 검증자 세트에서 제거
    uint256 public minimumThreshold;

    /// @notice N_max: L2별 최대 검증자 수
    /// @dev 백서 공식 C_off ≥ (c_m × N) / π_a 에서 N의 상한
    ///      Δ_validator는 이 값을 기준으로 충분한 마진 설정 필요
    uint256 public maxValidatorsPerL2;

    /// @notice 증거 제출 기간 (초)
    uint256 public evidenceSubmissionPeriod;

    /// @notice 챌린지 게임 기간 (초)
    /// @dev withdrawSlashingsToTreasury에서 사용: latestDeadlineTest + challengeGameDuration + safetyBuffer 이후에만 전송 가능
    uint256 public challengeGameDuration;

    /// @notice 안전 버퍼 시간 (초)
    /// @dev 기본값: 1일 (86400초)
    uint256 public safetyBuffer;

    // ==========================================
    // 참조 주소
    // ==========================================

    /// @notice SeigManager 주소
    address public seigManager;

    /// @notice WTON 주소
    address public wton;

    /// @notice TON 주소
    address public ton;

    // V3: depositManager 제거 - 검증자 담보금은 기존 스테이킹 시스템(coinage) 사용
    // address public depositManager;  // DEPRECATED

    /// @notice Layer2Manager 주소
    address public layer2Manager;

    /// @notice RAT 트리거 권한 주소 (DisputeGameFactory 등)
    address public authorizedTrigger;

    // owner 변수 삭제 - AccessibleCommon (AccessControl) 사용

    // ==========================================
    // 슬래싱 금액 처리
    // ==========================================

    /// @notice 누적 슬래싱 금액 (DAO 귀속 대기)
    uint256 public accumulatedSlashings;

    /// @notice DAO/Treasury 주소
    address public treasury;

    // ==========================================
    // 락 및 상태
    // ==========================================

    bool internal _lock;
    bool public paused;

    // ==========================================
    // Factory 검증 관련
    // ==========================================

    /// @notice L1BridgeRegistry 주소 (factory 검증용)
    address public l1BridgeRegistry;

    /// @notice 게임주소 => 팩토리주소 매핑
    /// @dev triggerAttentionTest 호출 시 msg.sender(factory)를 저장
    mapping(address => address) public factoryByGame;

    // V3: pendingWithdrawals 제거 - 검증자 출금은 DepositManager를 통해 직접 수행
    // mapping(address => mapping(address => uint256)) public pendingWithdrawals;  // DEPRECATED

    // ==========================================
    // V3 검증자 담보금 체크 유연화
    // ==========================================

    /// @notice 검증자 유효성 검사 완화 여부
    /// @dev 등록 후 유효성 검사 기준:
    ///      true: C_off 기준 (완화) - 초기 단계에서 진입 장벽 최소화
    ///      false: D_min 기준 (엄격)
    /// @dev V3 회의 결정: 초기값 true로 설정하여 검증자 유치 용이하게 함
    /// @dev 참고: 등록 시에는 항상 D_min 이상 필요
    bool public relaxedValidatorCheck;

    /// @notice ValidatorReward 컨트랙트 주소 (V1.1: O(1) 보상 분배)
    /// @dev 검증자 등록/탈퇴/재활성화 시 ValidatorReward에 알림
    address public validatorReward;

    // ==========================================
    // Fast Withdrawal Storage
    // ==========================================

    /// @notice 처리된 출금 해시 (재실행 방지)
    mapping(bytes32 => bool) public processedWithdrawals;

    /// @notice 집계자 수수료율 (RAY 단위, 기본: 10% = 1e26)
    uint256 public aggregatorFeeRate;

    /// @notice DEPRECATED: minValidatorsForFastWithdrawal이 0이면 비활성화
    bool public fastWithdrawalEnabled;

    /// @notice Fast Withdrawal을 위한 최소 검증자 수
    /// @dev 0이면 Fast Withdrawal 비활성화
    /// @dev 1 이상이면 해당 값 이상의 검증자가 서명해야 Fast Withdrawal 가능
    uint256 public minValidatorsForFastWithdrawal;

    /// @notice Fast Withdrawal 고정 수수료 (TON 단위, 10 TON = 10e18)
    uint256 public fastWithdrawalFee;

    /// @notice 대기 중인 수수료 정보
    struct PendingFee {
        uint256 amount;      // 수수료 금액
        address user;        // 수수료 납부자
        uint256 deadline;    // 빠른 출금 응답 기한
    }
    mapping(bytes32 => PendingFee) public pendingFees;

    // ==========================================
    // Modifiers (Note: onlyOwner is in Proxy, others in RAT implementation)
    // ==========================================

    modifier ifFree() {
        require(!_lock, "locked");
        _lock = true;
        _;
        _lock = false;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }
}
