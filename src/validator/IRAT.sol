// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {RATConfigParams} from "./RATTypes.sol";

/// @title IRAT
/// @notice Randomized Attention Test (RAT) 인터페이스
/// @dev Tokamak Economics Whitepaper V3 (December 16, 2025) 기준
/// @dev V3: 검증자 담보금 = 기존 TON 스테이킹 (coinage)
/// @dev V3: 슬래싱 = validator coinage → RAT coinage 전송 (burn/mint)
/// @dev V3: 복구 = RAT coinage → validator coinage 전송 (burn/mint)
/// @dev 검증자 보상 분배는 ValidatorReward 컨트랙트에서 처리
interface IRAT {
    // ==========================================
    // Events
    // ==========================================

    /// @notice 검증자 등록 이벤트
    event ValidatorRegistered(
        address indexed validator,
        address indexed systemConfig,
        address indexed layer2,
        uint256 depositAmount,
        uint256 registrationId
    );

    /// @notice 검증자 탈퇴 이벤트
    /// @dev V3: 별도 출금 불필요, DepositManager를 통해 직접 출금
    /// @param validator 탈퇴한 검증자
    /// @param systemConfig L2 SystemConfig 주소
    /// @param layer2 Layer2 주소
    event ValidatorDeactivated(
        address indexed validator,
        address indexed systemConfig,
        address indexed layer2
    );

    /// @notice 검증자 재활성화 이벤트
    /// @dev 담보금 복구 후 자동 재활성화 시 발생
    /// @param validator 재활성화된 검증자
    /// @param systemConfig L2 SystemConfig 주소
    /// @param layer2 Layer2 주소
    /// @param collateral 현재 담보금
    event ValidatorReactivated(
        address indexed validator,
        address indexed systemConfig,
        address indexed layer2,
        uint256 collateral
    );

    /// @notice 슬래싱 금액 Treasury 전송 이벤트
    /// @param systemConfig L2 SystemConfig 주소
    /// @param layer2 Layer2 주소
    /// @param treasury Treasury 주소
    /// @param amount 전송 금액
    event SlashingsWithdrawn(
        address indexed systemConfig,
        address indexed layer2,
        address indexed treasury,
        uint256 amount
    );

    /// @notice 누적 슬래싱 추적값 초기화 이벤트
    event AccumulatedSlashingsReset(uint256 amount);

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
    /// @param testId RAT 테스트 ID
    /// @param validator 검증자 주소
    /// @param systemConfig L2 SystemConfig 주소
    /// @param layer2 Layer2 주소
    /// @param batchIndex 배치 인덱스
    event EvidenceSubmitted(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        address layer2,
        uint32 batchIndex
    );

    /// @notice 슬래싱 이벤트
    /// @param testId RAT 테스트 ID (담보금 부족으로 즉시 제거 시 bytes32(0))
    /// @param validator 슬래싱된 검증자
    /// @param systemConfig L2 SystemConfig 주소
    /// @param layer2 Layer2 주소
    /// @param slashedAmount 슬래싱된 금액 (C_off)
    /// @param removedFromSet D_min 미만으로 활성 세트에서 제거되었는지
    event ValidatorSlashed(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        address layer2,
        uint256 slashedAmount,
        bool removedFromSet
    );

    /// @notice L2별 최대 검증자 수 변경 이벤트
    event MaxValidatorsPerL2Updated(uint256 newMaxValidators);

    /// @notice 검증자 유효성 검사 완화 여부 변경 이벤트
    /// @dev V3 회의 결정: 초기에는 true로 설정 (완화)
    event RelaxedValidatorCheckUpdated(bool relaxed);

    // V3: RewardsClaimed, RewardsClaimedBatch 이벤트 제거 - ValidatorReward로 이동

    /// @notice 담보금 추가 이벤트
    event DepositAdded(
        address indexed validator,
        address indexed systemConfig,
        uint256 amount
    );

    /// @notice 챌린지 승리로 담보금 복구 이벤트 (resolveClaim)
    /// @param testId RAT 테스트 ID
    /// @param validator 검증자 주소
    /// @param systemConfig L2 SystemConfig 주소
    /// @param layer2 Layer2 주소
    /// @param restoredAmount 복구된 금액
    event BondRestored(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        address layer2,
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

    /// @notice L2별 동적 최소 담보금 계산
    /// @dev C_off = max(slashingPenalty, (c_m × N) / π_a)
    /// @dev D_min = C_off + Δ_validator
    /// @param systemConfig L2의 SystemConfig 주소
    function getDynamicMinimumCollateral(address systemConfig) external view returns (uint256);

    /// @notice 슬래싱 페널티 검증
    /// @dev 백서 공식 (5): C_off ≥ (c_m · n) / π_a
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
    /// @return collateral 현재 담보금 (coinage 스테이킹 금액)
    /// @return validatorIndex 검증자 인덱스
    /// @return isActive 활성 상태
    function getValidatorRegistration(address validator, address systemConfig)
        external
        view
        returns (
            uint256 collateral,
            uint32 validatorIndex,
            bool isActive
        );

    /// @notice 검증자 담보금 조회 (coinage 스테이킹 금액)
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 현재 담보금 (coinage에서 직접 조회)
    function getValidatorDeposit(address validator, address systemConfig) external view returns (uint256);

    /// @notice 검증자의 사용 가능한 담보금 조회 (총 담보금 - 잠금 금액)
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 사용 가능한 담보금
    function getAvailableCollateral(address validator, address systemConfig) external view returns (uint256);

    /// @notice Layer2 기준으로 검증자의 최소 담보금 요구량 조회
    /// @dev SeigManager.onWithdraw에서 출금 제한 체크에 사용
    /// @dev 출금 제한은 항상 엄격한 기준(pure D_min) 적용: D_min = C_off(dynamic) + Δ_validator
    /// @dev relaxedValidatorCheck와 무관하게 항상 동적 공식 기반 D_min 반환 (보안 우선)
    /// @param layer2 Layer2 주소
    /// @param validator 검증자 주소
    /// @return 해당 L2에서 활성 검증자인 경우 pure D_min, 아니면 0
    function getValidatorMinCollateralForLayer2(address layer2, address validator) external view returns (uint256);

    // ==========================================
    // External Functions - Validator Management
    // ==========================================

    /// @notice 검증자 등록
    /// @dev V3: 별도 예치 불필요, 기존 스테이킹(coinage) 사용
    /// @dev 검증자는 DepositManager를 통해 미리 스테이킹해야 함
    /// @param systemConfig L2의 SystemConfig 주소
    function registerValidator(address systemConfig) external;

    /// @notice 검증자 탈퇴
    /// @dev V3: 별도 출금 불필요, DepositManager를 통해 출금
    /// @dev 진행 중인 RAT 테스트가 있어도 탈퇴 가능
    /// @param systemConfig L2의 SystemConfig 주소
    function deactivateValidator(address systemConfig) external;

    // V3: addDeposit 제거 - 검증자는 DepositManager를 통해 스테이킹 추가
    // V3: processWithdrawal 제거 - 검증자는 DepositManager를 통해 출금

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
    /// @dev V3: 증거 타입별 검증 지원 (FraudProof, StateLeaf)
    /// @param testId RAT 테스트 ID
    /// @param evidenceType 증거 타입 (0: FraudProof, 1: StateLeaf)
    /// @param evidenceData 증거 데이터
    function submitEvidence(
        bytes32 testId,
        uint8 evidenceType,
        bytes calldata evidenceData
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
    //
    // 백서 공식 (이론적 근거, 실시간 동적 업데이트 규칙이 아님):
    //   C_off ≥ (c_m × N) / π_a
    //   D_validator = C_off + Δ_validator
    //
    // 여기서 N = L2별 검증자 수 (|V_i|)
    //
    // 권장 구현 방식:
    // - Δ_validator에 충분한 마진을 설정하여 실질적인 N_max 고려
    // - 검증자는 ValidatorRegistered 이벤트를 모니터링하여 자격 상태 확인
    // - 담보금 부족 시 충분한 유예 기간 제공 또는 소급 적용하지 않는 방식 적용
    // ==========================================

    /// @notice RAT 설정 파라미터 일괄 설정 (owner만 호출 가능)
    /// @param config 설정 파라미터 구조체
    function setConfig(RATConfigParams calldata config) external;

    /// @notice Attention Cost 설정 (c_m) - 모니터링 비용
    function setAttentionCost(uint256 cost) external;

    /// @notice 슬래싱 페널티 설정 (C_off)
    /// @dev 백서 공식 C_off ≥ (c_m × N) / π_a 를 만족하도록 설정
    ///      N은 L2별 예상 최대 검증자 수를 고려하여 충분히 크게 설정
    function setSlashingPenalty(uint256 penalty) external;

    /// @notice 검증자 버퍼 설정 (Δ_validator)
    /// @dev N 증가에 대비하여 충분한 마진 설정 권장
    ///      D_validator = C_off + Δ_validator
    function setValidatorBuffer(uint256 buffer) external;

    /// @notice 최소 임계값 설정 (D_min)
    /// @dev D_min ≥ C_off + Δ_validator 관계 유지 필요
    function setMinimumThreshold(uint256 threshold) external;

    /// @notice L2별 최대 검증자 수 설정 (N_max)
    /// @dev 백서 공식 C_off ≥ (c_m × N) / π_a 에서 N의 상한
    ///      시뇨리지 분배 시 가스 한도 고려 (각 검증자당 ~25K gas)
    ///      0으로 설정하면 제한 없음
    function setMaxValidatorsPerL2(uint256 maxValidators) external;

    /// @notice RAT 트리거 확률 설정 (π_a)
    /// @dev 백서 공식 C_off ≥ (c_m × N) / π_a 참조
    function setRatTriggerProbability(uint256 probability) external;

    /// @notice 증거 제출 기간 설정
    function setEvidenceSubmissionPeriod(uint256 period) external;

    /// @notice 검증자 유효성 검사 완화 여부 설정
    /// @param relaxed true: C_off 기준 (완화), false: D_min 기준 (엄격)
    /// @dev V3 회의 결정: 초기에는 true로 설정하여 검증자 유치 용이하게 함
    function setRelaxedValidatorCheck(bool relaxed) external;
}
