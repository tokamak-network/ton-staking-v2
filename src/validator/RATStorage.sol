// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title RATStorage
/// @notice Randomized Attention Test (RAT) 스토리지
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
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

    enum AttentionTestStatus {
        Pending,        // 대기 중 (증거 제출 기간)
        Responded,      // 증거 제출됨
        Slashed,        // 슬래싱됨 (미응답)
        Expired         // 만료됨 (처리 완료)
    }

    // ==========================================
    // Structs
    // ==========================================

    /// @notice 검증자 등록 정보
    /// @dev 백서 V2 공식 (5) 기반: D_validator = C_off + Δ_validator
    /// @dev V3 정책: 담보금 시뇨리지 없음, 출금 시 원금 반환
    struct ValidatorRegistration {
        uint256 depositedAmount;        // 현재 유효 담보금 (선차감 후 금액)
        uint256 depositedPrincipal;     // 원금 (V3: 시뇨리지 없으므로 출금 시 이 값 반환)
        uint256 totalBondForRAT;        // 진행 중인 RAT 테스트들에 묶인 총 금액
        uint256 pendingRewards;         // 미청구 검증자 보상
        uint64 latestTestDeadline;      // 가장 최근 RAT 테스트 마감 시간 (출금 조건)
        uint32 validatorIndex;          // 검증자 인덱스
        bool isActive;                  // 활성 상태
    }

    /// @notice Attention Test 정보
    struct AttentionTest {
        address validatorAddress;       // 선택된 검증자
        address systemConfig;           // L2 SystemConfig 주소
        uint32 batchIndex;              // 배치 인덱스
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
        uint256 rewardPerValidator;     // 검증자당 보상 (누적)
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

    /// @notice 증거 제출 기간 (초)
    uint256 public evidenceSubmissionPeriod;

    // ==========================================
    // 참조 주소
    // ==========================================

    /// @notice SeigManager 주소
    address public seigManager;

    /// @notice WTON 주소
    address public wton;

    /// @notice TON 주소
    address public ton;

    /// @notice DepositManager 주소
    address public depositManager;

    /// @notice Layer2Manager 주소
    address public layer2Manager;

    /// @notice RAT 트리거 권한 주소 (DisputeGameFactory 등)
    address public authorizedTrigger;

    /// @notice Owner 주소
    address public owner;

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

    /// @notice 출금 대기 중인 금액 (systemConfig => validator => amount)
    /// @dev deactivateValidator 후 2주 대기 후 processWithdrawal로 수령
    mapping(address => mapping(address => uint256)) public pendingWithdrawals;

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
