// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title SequencerVaultStorage
/// @notice 시퀀서 담보금 Vault 스토리지
/// @dev V3: 시퀀서가 TON을 Vault에 직접 예치, 시뇨리지 없음
contract SequencerVaultStorage {
    // ==========================================
    // Constants
    // ==========================================

    uint256 internal constant RAY = 1e27;

    // ==========================================
    // Structs
    // ==========================================

    /// @notice 시퀀서 담보금 정보
    /// @dev V3 정책: L2당 1개의 시퀀서, 담보금 시뇨리지 없음
    struct SequencerDeposit {
        address operator;               // OperatorManager 주소 (담보금 예치자)
        address layer2;                 // Layer2 (CandidateAddOn) 주소
        uint256 depositedAmount;        // 현재 유효 담보금 (원금 - 슬래싱 손실)
        uint256 slashedAmount;          // 누적 슬래싱 금액
        bool isActive;                  // 활성 상태
    }

    // ==========================================
    // 시퀀서 관련 스토리지
    // ==========================================

    /// @notice systemConfig => SequencerDeposit
    /// @dev V3: L2당 1개의 시퀀서, systemConfig로 조회
    mapping(address => SequencerDeposit) public sequencerDeposits;

    /// @notice operator => 등록된 systemConfig 목록
    mapping(address => address[]) public operatorSystemConfigs;

    /// @notice layer2 => systemConfig (역방향 조회용)
    /// @dev SeigManager에서 layer2 기준으로 담보금 조회 시 사용
    mapping(address => address) public layer2ToSystemConfig;

    // ==========================================
    // 슬래싱 관련
    // ==========================================

    /// @notice 누적 슬래싱 금액 (Treasury 귀속 대기)
    uint256 public accumulatedSlashings;

    /// @notice 슬래싱된 게임 주소 추적 (중복 슬래싱 방지)
    mapping(address => bool) public slashedGames;

    /// @notice 챌린저별 미청구 보상 (challenger => amount)
    mapping(address => uint256) public pendingChallengerRewards;

    // ==========================================
    // 파라미터
    // ==========================================

    /// @notice 최소 담보금 요구량
    /// @dev 백서: S_i >= θ · B_i (Bridged TON 대비 비율)
    uint256 public minimumStakingRatio;

    /// @notice C_max: 단일 fraud proof 최대 비용
    uint256 public maxFraudProofCost;

    /// @notice Δ_sequencer: 시퀀서 추가 보상 (슬래싱 시 챌린저에게)
    uint256 public sequencerAdditionalReward;

    /// @notice H_max: 최대 동시 챌린저 수
    uint256 public maxChallengers;

    // ==========================================
    // 참조 주소
    // ==========================================

    address public seigManager;
    address public wton;
    address public ton;
    address public layer2Manager;
    address public l1BridgeRegistry;
    address public owner;
    address public treasury;

    // ==========================================
    // 상태
    // ==========================================

    bool internal _lock;
    bool public paused;

    // ==========================================
    // Modifiers
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
