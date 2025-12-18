// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ISequencerVault
/// @notice 시퀀서 담보금 Vault 인터페이스
/// @dev V3: 시퀀서가 TON을 Vault에 직접 예치, 시뇨리지 없음
interface ISequencerVault {
    // ==========================================
    // Events
    // ==========================================

    /// @notice 시퀀서 등록 이벤트
    event SequencerRegistered(
        address indexed operator,
        address indexed systemConfig,
        address layer2,
        uint256 depositAmount
    );

    /// @notice 시퀀서 탈퇴 이벤트
    event SequencerDeactivated(
        address indexed sequencer,
        address indexed systemConfig,
        uint256 returnedAmount
    );

    /// @notice 담보금 추가 이벤트
    event DepositAdded(
        address indexed sequencer,
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice 시퀀서 슬래싱 이벤트
    /// @dev Fraud proof 게임에서 챌린저 승리 시
    event SequencerSlashed(
        address indexed sequencer,
        address indexed systemConfig,
        address indexed gameAddress,
        uint256 slashedAmount,
        address challenger,
        uint256 challengerReward
    );

    /// @notice 슬래싱 금액 Treasury 전송 이벤트
    event SlashingsWithdrawnToTreasury(
        address indexed treasury,
        uint256 amount
    );

    /// @notice 챌린저 보상 청구 이벤트
    event ChallengerRewardClaimed(
        address indexed challenger,
        uint256 amount
    );

    // ==========================================
    // Errors
    // ==========================================

    error NotOwnerError();
    error NotSeigManagerError();
    error InvalidSystemConfigError();
    error AlreadyRegisteredError();
    error NotRegisteredError();
    error NotActiveSequencerError();
    error InsufficientDepositError();
    error AlreadySlashedGameError();
    error InvalidGameError();
    error ZeroAddressError();
    error NoRewardError();
    error InvalidOperatorError();

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 시퀀서 담보금 조회 (systemConfig 기준)
    function getSequencerDeposit(address systemConfig)
        external view returns (uint256);

    /// @notice 시퀀서 활성 상태 확인 (systemConfig 기준)
    function isSequencerActive(address systemConfig)
        external view returns (bool);

    /// @notice 시퀀서 담보금 조회 (layer2 기준)
    /// @dev SeigManager에서 layer2 기준 조회 시 사용
    function getSequencerDepositByLayer2(address layer2)
        external view returns (uint256);

    /// @notice 시퀀서 활성 상태 확인 (layer2 기준)
    function isSequencerActiveByLayer2(address layer2)
        external view returns (bool);

    /// @notice 시퀀서 등록 정보 조회
    function getSequencerInfo(address systemConfig)
        external view returns (
            address operator,
            address layer2,
            uint256 depositedAmount,
            uint256 slashedAmount,
            bool isActive
        );

    /// @notice 오퍼레이터가 등록한 systemConfig 목록 조회
    function getOperatorSystemConfigs(address operator)
        external view returns (address[] memory);

    /// @notice 최소 담보금 계산 (Bridged TON 기반)
    /// @param bridgedTON 해당 L2의 Bridged TON 수량
    function getMinimumCollateral(uint256 bridgedTON)
        external view returns (uint256);

    // ==========================================
    // External Functions - Sequencer Management
    // ==========================================

    /// @notice 시퀀서 등록 (TON 직접 예치)
    /// @dev 누구나 호출 가능, systemConfig로 operator/layer2 자동 조회
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param depositAmount 예치할 TON 양
    function registerSequencer(address systemConfig, uint256 depositAmount) external;

    /// @notice 시퀀서 탈퇴 및 즉시 출금
    /// @dev V3: DepositManager 미사용으로 즉시 출금 가능, 오퍼레이터만 호출 가능
    /// @param systemConfig L2의 SystemConfig 주소
    function deactivateSequencer(address systemConfig) external;

    /// @notice 담보금 추가 예치
    /// @dev 누구나 호출 가능 (제3자 펀딩 가능)
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param amount 추가 예치할 TON 양
    function addDeposit(address systemConfig, uint256 amount) external;

    // ==========================================
    // External Functions - Slashing
    // ==========================================

    /// @notice 시퀀서 슬래싱 - Permissionless 방식
    /// @dev 누구나 호출 가능, 게임 상태를 온체인에서 검증
    ///      DisputeGameFactory 검증을 통해 가짜 게임 컨트랙트 방지
    ///      챌린저는 claimData(0).counteredBy에서 온체인 조회
    /// @param gameAddress 종료된 FaultDisputeGame 주소
    function slashSequencerByGame(address gameAddress) external;

    /// @notice 누적 슬래싱 금액을 Treasury로 전송
    function withdrawSlashingsToTreasury() external;

    /// @notice 챌린저 보상 청구
    /// @dev 챌린저가 직접 호출하여 보상 수령
    function claimChallengerReward() external;

    /// @notice 챌린저 미청구 보상 조회
    /// @param challenger 챌린저 주소
    function getPendingChallengerReward(address challenger) external view returns (uint256);

    // ==========================================
    // External Functions - Governance
    // ==========================================

    function setMinimumStakingRatio(uint256 ratio) external;
    function setMaxFraudProofCost(uint256 cost) external;
    function setSequencerAdditionalReward(uint256 reward) external;
    function setMaxChallengers(uint256 max) external;
    function setTreasury(address _treasury) external;
    function setL1BridgeRegistry(address _registry) external;
    function pause() external;
    function unpause() external;
}
