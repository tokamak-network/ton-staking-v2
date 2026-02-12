// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ProxyStorage} from "../proxy/ProxyStorage.sol";
import {AccessibleCommon} from "../common/AccessibleCommon.sol";
import {RATStorage} from "./RATStorage.sol";
import {IRAT} from "./IRAT.sol";
import {RATInitParams, RATConfigParams} from "./RATTypes.sol";
import {IL1BridgeRegistry} from "../layer2/interfaces/IL1BridgeRegistry.sol";
import {ILayer2Manager} from "../layer2/interfaces/ILayer2Manager.sol";
import {IValidatorReward} from "./IValidatorReward.sol";
import {Type3EvidenceVerifier} from "./libraries/Type3EvidenceVerifier.sol";
import {IDisputeGame} from "./interfaces/IDisputeGame.sol";

// V3: SeigManager 연동을 위한 인터페이스
interface ISeigManagerForRAT {
    function coinages(address layer2) external view returns (address);
    function stakeOf(address layer2, address account) external view returns (uint256);
    function v3Migrated() external view returns (bool);
    // RAT용 coinage 전송 함수
    function transferCoinageToRat(address layer2, address validator, uint256 amount) external;
    function transferCoinageFromRat(address layer2, address validator, uint256 amount) external;
    function transferCoinageFromRatTo(address layer2, address recipient, uint256 amount) external;
}

// ERC20 interface for TON token transfers
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// Custom Errors
error AlreadyRegisteredError();
error NotActiveValidatorError();
error InsufficientCollateralError();
error InvalidSystemConfigError();
error TestNotFoundError();
error TestAlreadyExistsError();
error TestAlreadyRespondedError();
error DeadlinePassedError();
error InvalidParameterError();
error NotSelectedValidatorError();
error InvalidFactoryError();
error MaxValidatorsReachedError();
error Layer2NotFoundError();
error NotMigratedError();
error AlreadyInitializedError();
error InvalidProbabilityError();
error InvalidEvidencePeriodError();
error InvalidSlashingPenaltyError();
error InvalidMinimumThresholdError();
error InvalidMaxValidatorsError();
error EmptyEvidenceError();
error RollupTypeNotSupportedError();
error UnsupportedEvidenceTypeError();
error TreasuryNotSetError();
error PendingTestsNotExpiredError();
error NoSlashingsToWithdrawError();
error NotSeigManagerError();
error NotAuthorizedTriggerError();

// Rollup Type Constants
uint8 constant ROLLUP_TYPE_LEGACY = 1;
uint8 constant ROLLUP_TYPE_OPTIMISM_BEDROCK = 2;
uint8 constant ROLLUP_TYPE_OPTIMISM_BEDROCK_WITH_DISPUTE_GAME = 3;

// RATInitParams, RATConfigParams는 RATTypes.sol에서 정의됨 (순환 참조 방지)

/**
 * @title RAT (Randomized Attention Test)
 * @notice TON Staking V3 검증자 Attention Test 컨트랙트
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 *
 * V3 핵심 변경: 검증자 담보금 = 기존 TON 스테이킹 (coinage)
 * - 별도 예치 불필요, DepositManager를 통한 기존 스테이킹 사용
 * - 슬래싱: 선차감(lock) → 응답 시 unlock, 미응답 시 coinage.burnFrom()
 *
 * 핵심 기능:
 * 1. L2별 검증자 등록/탈퇴
 * 2. RAT 트리거 및 검증자 랜덤 선택
 * 3. 증거 제출 및 검증
 * 4. 선차감-복구 슬래싱 메커니즘 (lock/unlock + burn on timeout)
 * 5. 검증자 보상 분배 (ValidatorReward 연동)
 *
 * 백서 V2 핵심 공식:
 * - (3) c_m ≤ (π_a / n) · C_off - RAT 균형 조건
 * - (4) C_off ≥ (c_m · n) / π_a - 최소 슬래싱 페널티
 * - (5) D_validator = C_off + Δ_validator - 검증자 담보금
 */
contract RAT is ProxyStorage, AccessibleCommon, RATStorage, IRAT {
    // ==========================================
    // Modifiers
    // ==========================================

    // onlyOwner는 AccessibleCommon에서 상속 (AccessControl 기반)

    modifier onlySeigManager() {
        if (msg.sender != seigManager) revert NotSeigManagerError();
        _;
    }

    modifier onlyAuthorizedTrigger() {
        if (msg.sender != authorizedTrigger) revert NotAuthorizedTriggerError();
        _;
    }

    /// @notice L1BridgeRegistry에 등록된 유효한 factory인지 검증
    /// @dev systemConfig는 함수 파라미터에서 가져와 비교 (triggerAttentionTest 참조)
    modifier onlyValidFactory(address systemConfig) {
        if (l1BridgeRegistry == address(0)) revert InvalidFactoryError();
        address rollupConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithDisputeGameFactory(msg.sender);
        if (rollupConfig == address(0)) revert InvalidFactoryError();
        if (rollupConfig != systemConfig) revert InvalidFactoryError();
        _;
    }

    // ==========================================
    // Constructor / Initializer
    // ==========================================

    /// @notice RAT 컨트랙트 초기화 (핵심 주소만 설정)
    /// @param params 초기화 파라미터 구조체
    /// @dev 초기화 후 반드시 setConfig()를 호출하여 설정 파라미터 설정 필요
    function initialize(RATInitParams calldata params) external {
        if (seigManager != address(0)) revert AlreadyInitializedError();

        seigManager = params.seigManager;
        wton = params.wton;
        ton = params.ton;
        layer2Manager = params.layer2Manager;
        l1BridgeRegistry = params.l1BridgeRegistry;
        _grantRole(DEFAULT_ADMIN_ROLE, params.owner);
    }

    /// @notice RAT 설정 파라미터 설정 (owner만 호출 가능)
    /// @param config 설정 파라미터 구조체
    function setConfig(RATConfigParams calldata config) external onlyOwner {
        if (config.ratTriggerProbability == 0 || config.ratTriggerProbability > RAY) {
            revert InvalidProbabilityError();
        }
        if (config.evidenceSubmissionPeriod == 0) revert InvalidEvidencePeriodError();
        if (config.slashingPenalty == 0) revert InvalidSlashingPenaltyError();
        if (config.minimumThreshold < config.slashingPenalty + config.validatorBuffer) {
            revert InvalidMinimumThresholdError();
        }
        if (config.maxValidatorsPerL2 == 0) revert InvalidMaxValidatorsError();

        ratTriggerProbability = config.ratTriggerProbability;
        evidenceSubmissionPeriod = config.evidenceSubmissionPeriod;
        slashingPenalty = config.slashingPenalty;
        validatorBuffer = config.validatorBuffer;
        minimumThreshold = config.minimumThreshold;
        maxValidatorsPerL2 = config.maxValidatorsPerL2;
        challengeGameDuration = config.challengeGameDuration;
        safetyBuffer = config.safetyBuffer;
        treasury = config.treasury;
        attentionCost = config.attentionCost;
        relaxedValidatorCheck = config.relaxedValidatorCheck;
    }

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 검증자 등록 정보 조회
    /// @dev V3: depositedAmount 제거 - coinage에서 직접 조회
    function getValidatorRegistration(address validator, address systemConfig)
        external
        view
        returns (
            uint256 collateral,
            uint32 validatorIndex,
            bool isActive
        )
    {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][validator];
        (collateral,) = _getValidatorCollateral(validator, systemConfig);
        validatorIndex = reg.validatorIndex;
        isActive = reg.isActive;
    }

    /// @notice Attention Test 정보 조회
    function getAttentionTest(bytes32 testId)
        external
        view
        returns (
            address validatorAddress,
            address systemConfig,
            uint32 batchIndex,
            bytes32 batchHash,
            uint256 bondAmount,
            uint256 createdAt,
            uint256 deadline,
            AttentionTestStatus status
        )
    {
        AttentionTest storage test = attentionTests[testId];
        return (
            test.validatorAddress,
            test.systemConfig,
            test.batchIndex,
            test.batchHash,
            test.bondAmount,
            test.createdAt,
            test.deadline,
            _getCalculatedStatus(test)
        );
    }

    /// @notice Attention Test 상태 조회 (시간 기반 계산)
    /// @dev V3: 별도 트랜잭션 없이 시간으로 상태 계산
    /// @param testId 조회할 테스트 ID
    /// @return 계산된 상태값
    function getAttentionTestStatus(bytes32 testId) external view returns (AttentionTestStatus) {
        AttentionTest storage test = attentionTests[testId];
        return _getCalculatedStatus(test);
    }

    /// @notice 테스트 상태 계산 (내부 함수)
    /// @dev V3: 시간 기반 상태 계산
    /// - EvidencePeriod + deadline 전: EvidencePeriod (증거 제출 가능)
    /// - EvidencePeriod + deadline 후 + 챌린지 기간 내: ChallengePeriod (챌린지 게임으로만 복구 가능)
    /// - EvidencePeriod/ChallengePeriod + deadline + challengeGameDuration 후: Slashed (최종 슬래싱)
    function _getCalculatedStatus(AttentionTest storage test) internal view returns (AttentionTestStatus) {
        // 이미 최종 상태면 그대로 반환
        if (test.status == AttentionTestStatus.RestoredByEvidence ||
            test.status == AttentionTestStatus.RestoredByChallenge ||
            test.status == AttentionTestStatus.Slashed) {
            return test.status;
        }

        // EvidencePeriod 상태에서 시간 기반 계산
        if (test.status == AttentionTestStatus.EvidencePeriod) {
            // deadline + challengeGameDuration 이후 → Slashed
            if (block.timestamp > test.deadline + challengeGameDuration) {
                return AttentionTestStatus.Slashed;
            }
            // deadline 이후 → ChallengePeriod
            if (block.timestamp > test.deadline) {
                return AttentionTestStatus.ChallengePeriod;
            }
        }

        return test.status;
    }

    /// @inheritdoc IRAT
    /// @notice L2별 동적 최소 담보금 계산
    /// @dev C_off = max(slashingPenalty, (c_m × N) / π_a)
    /// @dev D_min = C_off + Δ_validator
    /// @param systemConfig L2의 SystemConfig 주소
    function getDynamicMinimumCollateral(address systemConfig) public view returns (uint256) {
        uint256 n = validatorPools[systemConfig].activeCount; // 직접 SLOAD로 최적화
        if (n == 0) n = 1; // 최소 1명 기준
        return _calculateMinimumCollateral(n);
    }

    /// @notice 백서 공식 기반 동적 C_off 계산 (relaxedValidatorCheck 무시)
    /// @dev 백서 공식 (5): C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)
    /// @dev _calculateCoffWithRelaxedCheck 내부에서 호출됨
    function _calculateDynamicCoff(uint256 n) internal view returns (uint256) {
        // Storage 변수 캐싱 (중복 SLOAD 방지)
        uint256 _slashingPenalty = slashingPenalty;
        uint256 _attentionCost = attentionCost;
        uint256 _ratTriggerProb = ratTriggerProbability;

        // attentionCost > 0 이고 ratTriggerProbability > 0 이면 공식 적용
        if (_attentionCost > 0 && _ratTriggerProb > 0) {
            // C_off = (c_m × N × RAY) / π_a
            uint256 formulaCoff = (_attentionCost * n * RAY) / _ratTriggerProb;
            // max(slashingPenalty, formulaCoff)
            if (formulaCoff > _slashingPenalty) {
                return formulaCoff;
            }
        }

        return _slashingPenalty;
    }

    /// @notice relaxedValidatorCheck를 반영한 C_off 계산 (내부용)
    /// @dev relaxedValidatorCheck = true: 고정 slashingPenalty (완화)
    /// @dev relaxedValidatorCheck = false: 동적 C_off (엄격)
    /// @dev bondAmount, removalThreshold 계산 시 사용
    function _calculateCoffWithRelaxedCheck(uint256 n) internal view returns (uint256) {
        if (relaxedValidatorCheck) {
            return slashingPenalty;  // 완화 모드: 고정값
        }
        return _calculateDynamicCoff(n);  // 엄격 모드: 동적 계산
    }

    /// @notice relaxed를 반영한 C_off 계산 (public)
    /// @dev relaxed = true: slashingPenalty (완화)
    /// @dev relaxed = false: 동적 C_off (엄격)
    /// @param systemConfig L2의 SystemConfig 주소
    function getCoffWithRelaxedCheck(address systemConfig) public view returns (uint256) {
        uint256 n = validatorPools[systemConfig].activeCount; // 직접 SLOAD로 최적화
        if (n == 0) n = 1;
        return _calculateCoffWithRelaxedCheck(n);
    }

    /// @notice 순수 동적 C_off 계산 (public, relaxed 무시)
    /// @dev 항상 백서 공식대로 계산
    /// @param systemConfig L2의 SystemConfig 주소
    function getDynamicCoff(address systemConfig) public view returns (uint256) {
        uint256 n = validatorPools[systemConfig].activeCount; // 직접 SLOAD로 최적화
        if (n == 0) n = 1;
        return _calculateDynamicCoff(n);
    }

    /// @notice 검증자 수 기반 D_min 계산 (순수 동적, relaxed 체크 없음)
    /// @dev D_min = C_off(동적) + Δ_validator
    /// @dev getDynamicMinimumCollateral 내부에서 호출
    function _calculateMinimumCollateral(uint256 n) internal view returns (uint256) {
        return _calculateDynamicCoff(n) + validatorBuffer;
    }

    /// @notice relaxed를 반영한 D_min 계산 (내부용)
    /// @dev relaxed = true: D_min = slashingPenalty + validatorBuffer (완화)
    /// @dev relaxed = false: D_min = _calculateDynamicCoff(n) + validatorBuffer (엄격)
    function _calculateDminWithRelaxedCheck(uint256 n) internal view returns (uint256) {
        return _calculateCoffWithRelaxedCheck(n) + validatorBuffer;
    }

    /// @notice relaxed를 반영한 D_min 계산 (public)
    /// @dev relaxed = true: C_off + validatorBuffer (완화)
    /// @dev relaxed = false: 동적 C_off + validatorBuffer (엄격)
    /// @param systemConfig L2의 SystemConfig 주소
    function getMinimumCollateralWithRelaxedCheck(address systemConfig) public view returns (uint256) {
        uint256 n = validatorPools[systemConfig].activeCount; // 직접 SLOAD로 최적화
        if (n == 0) n = 1;
        return _calculateDminWithRelaxedCheck(n);
    }

    /// @notice Backward compatibility wrapper for getMinimumCollateral
    /// @dev Returns C_off + validatorBuffer (assumes n=1 for simplicity)
    /// @return Minimum collateral amount
    function getMinimumCollateral() public view returns (uint256) {
        return _calculateDminWithRelaxedCheck(1);
    }

    /// @inheritdoc IRAT
    function validateSlashingPenalty(uint256 n) public view returns (bool) {
        if (ratTriggerProbability == 0 || n == 0) return false;
        // 백서 공식 (5): C_off ≥ (c_m · n) / π_a
        // → C_off · π_a ≥ c_m · n
        return slashingPenalty * ratTriggerProbability >= attentionCost * n * RAY;
    }

    /// @inheritdoc IRAT
    function getValidatorCount(address systemConfig) public view returns (uint256) {
        return validatorPools[systemConfig].validators.length;
    }

    /// @inheritdoc IRAT
    function getActiveValidatorCount(address systemConfig) public view returns (uint256) {
        return validatorPools[systemConfig].activeCount;
    }

    /// @inheritdoc IRAT
    function getL2Validators(address systemConfig) external view returns (address[] memory) {
        return validatorPools[systemConfig].validators;
    }

    /// @notice 검증자 담보금 조회 (coinage에서 직접 조회)
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 현재 담보금 (coinage 스테이킹 금액)
    function getValidatorDeposit(address validator, address systemConfig) external view returns (uint256) {
        (uint256 collateral,) = _getValidatorCollateral(validator, systemConfig);
        return collateral;
    }

    /// @notice 검증자의 담보금 조회 (coinage 잔액)
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 담보금
    function getAvailableCollateral(address validator, address systemConfig) external view returns (uint256) {
        (uint256 collateral,) = _getValidatorCollateral(validator, systemConfig);
        return collateral;
    }

    /// @notice 검증자가 활성 상태인지 확인
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 활성 상태 여부
    function isValidatorActive(address validator, address systemConfig) external view returns (bool) {
        return validatorRegistrations[systemConfig][validator].isActive;
    }

    /// @inheritdoc IRAT
    /// @dev layerInfo로 layer2에서 systemConfig 직접 조회
    /// @dev 출금 제한은 항상 엄격한 기준(pure D_min) 적용 (보안 우선)
    /// @dev D_min = C_off(dynamic) + Δ_validator, C_off = max(slashingPenalty, (c_m × N) / π_a)
    /// @dev relaxedValidatorCheck와 무관하게 항상 getDynamicMinimumCollateral 반환
    function getValidatorMinCollateralForLayer2(address layer2, address validator) external view returns (uint256) {
        (address systemConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        if (systemConfig == address(0)) return 0;

        if (validatorRegistrations[systemConfig][validator].isActive) {
            return getDynamicMinimumCollateral(systemConfig); // Pure D_min (항상 엄격)
        }

        return 0;
    }

    // ==========================================
    // V3: Coinage 연동 내부 함수
    // ==========================================

    /// @notice SystemConfig에서 Layer2 주소 조회
    /// @dev Layer2Manager.getLayer2BySystemConfig() 사용
    function _getLayer2FromSystemConfig(address systemConfig) internal view returns (address) {
        address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
        if (layer2 == address(0)) revert Layer2NotFoundError();
        return layer2;
    }

    /// @notice 검증자 담보금 조회 (coinage 스테이킹 금액)
    /// @dev V3: SeigManager.stakeOf(layer2, validator) 사용
    /// @return collateral 담보금
    /// @return layer2 Layer2 주소
    function _getValidatorCollateral(address validator, address systemConfig) internal view returns (uint256 collateral, address layer2) {
        layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
        if (layer2 == address(0)) return (0, address(0));
        collateral = ISeigManagerForRAT(seigManager).stakeOf(layer2, validator);
    }

    /// @notice 검증자 coinage → RAT coinage 전송 (선차감)
    /// @dev SeigManager를 통해 coinage 전송 수행
    /// @param layer2 Layer2 주소
    /// @param validator 검증자 주소
    /// @param amount 전송 금액 (WTON 단위, 27 decimals)
    function _transferCoinageToRAT(address layer2, address validator, uint256 amount) internal {
        ISeigManagerForRAT(seigManager).transferCoinageToRat(layer2, validator, amount);
    }

    /// @notice RAT coinage → 검증자 coinage 전송 (복구)
    /// @dev SeigManager를 통해 coinage 전송 수행
    /// @param layer2 Layer2 주소
    /// @param validator 검증자 주소
    /// @param amount 전송 금액 (WTON 단위, 27 decimals)
    function _transferCoinageFromRAT(address layer2, address validator, uint256 amount) internal {
        ISeigManagerForRAT(seigManager).transferCoinageFromRat(layer2, validator, amount);
    }

    /// @notice RAT의 coinage 잔액 조회 (특정 L2)
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return RAT이 해당 L2에서 보유한 coinage 잔액
    function getRATCoinageBalance(address systemConfig) external view returns (uint256) {
        address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
        if (layer2 == address(0)) return 0;
        return ISeigManagerForRAT(seigManager).stakeOf(layer2, address(this));
    }

    // ==========================================
    // Validator Management
    // ==========================================

    /// @inheritdoc IRAT
    /// @notice 검증자 등록 (V3: 별도 예치 불필요, 기존 스테이킹 사용)
    /// @dev 검증자는 DepositManager를 통해 미리 스테이킹해야 함
    /// @dev D_min 이상의 coinage 잔액 필요
    function registerValidator(address systemConfig)
        external
        ifFree
        whenNotPaused
    {
        // V3 마이그레이션 후에만 검증자 등록 가능
        if (!ISeigManagerForRAT(seigManager).v3Migrated()) revert NotMigratedError();
        if (systemConfig == address(0)) revert InvalidSystemConfigError();

        // 이미 등록된 검증자인지 먼저 확인 (빠른 실패)
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (reg.isActive) revert AlreadyRegisteredError();

        // V3: coinage에서 담보금 확인
        (uint256 collateral, address layer2) = _getValidatorCollateral(msg.sender, systemConfig);
        uint256 minDeposit = getDynamicMinimumCollateral(systemConfig);
        if (collateral < minDeposit) revert InsufficientCollateralError();

        // 검증자 등록 로직 (reg, collateral, layer2 전달하여 중복 조회 방지)
        _registerValidatorInternal(msg.sender, systemConfig, reg, collateral, layer2);
    }

    /// @inheritdoc IRAT
    /// @notice 검증자 탈퇴
    /// @dev V3: 별도 출금 불필요, DepositManager를 통해 출금
    /// @dev 진행 중인 RAT 테스트가 있어도 탈퇴 가능 (bondAmount 이미 선차감됨)
    /// @dev 탈퇴 시 validators 배열에서 완전히 제거 (탈퇴자가 가스비 부담)
    function deactivateValidator(address systemConfig) external ifFree {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (!reg.isActive) revert NotActiveValidatorError();

        // V1.1: 탈퇴 전 보상 동기화 (O(1) 보상 분배용)
        if (validatorReward != address(0)) {
            IValidatorReward(validatorReward).syncValidatorReward(msg.sender, systemConfig);
        }

        // 배열에서 제거 (O(n) - 탈퇴자가 가스비 부담)
        _removeValidatorFromArray(systemConfig, msg.sender);

        // 등록 정보 초기화
        reg.isActive = false;
        reg.validatorIndex = 0;

        // SystemConfig에서 Layer2 주소 조회
        address layer2 = _getLayer2FromSystemConfig(systemConfig);

        emit ValidatorDeactivated(msg.sender, systemConfig, layer2);
    }

    /// @notice validators 배열에서 검증자 제거
    /// @dev swap-and-pop 방식으로 제거 (마지막 요소와 교체 후 pop)
    function _removeValidatorFromArray(address systemConfig, address validator) internal {
        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        uint256 index = validatorIndexes[systemConfig][validator];
        uint256 lastIndex = pool.validators.length - 1;

        if (index != lastIndex) {
            // 마지막 요소와 교체
            address lastValidator = pool.validators[lastIndex];
            pool.validators[index] = lastValidator;
            validatorIndexes[systemConfig][lastValidator] = index;
            validatorRegistrations[systemConfig][lastValidator].validatorIndex = uint32(index);
        }

        // 마지막 요소 제거
        pool.validators.pop();
        pool.activeCount--;
        delete validatorIndexes[systemConfig][validator];
    }

    /// @notice 내부 검증자 등록 로직
    /// @dev V3: 별도 예치 없이 등록만 수행, 담보금은 coinage에서 조회
    /// @dev 탈퇴 시 배열에서 완전히 제거되므로 재등록 로직 불필요
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param reg 이미 조회된 storage pointer (중복 조회 방지)
    /// @param collateral 이미 조회된 담보금 (중복 조회 방지)
    /// @param layer2 Layer2 주소 (이벤트용)
    function _registerValidatorInternal(
        address validator,
        address systemConfig,
        ValidatorRegistration storage reg,
        uint256 collateral,
        address layer2
    ) internal {
        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        uint256 index = pool.validators.length;

        // N_max 체크: L2별 최대 검증자 수 제한
        if (index >= maxValidatorsPerL2) {
            revert MaxValidatorsReachedError();
        }

        pool.validators.push(validator);
        pool.activeCount++;

        // 검증자 등록 정보 설정
        reg.validatorIndex = uint32(index);
        reg.isActive = true;

        validatorIndexes[systemConfig][validator] = index;
        validatorSystemConfigs[validator].push(systemConfig);

        // V1.1: ValidatorReward에 등록 알림 (O(1) 보상 분배용)
        if (validatorReward != address(0)) {
            IValidatorReward(validatorReward).registerValidatorToL2(validator, systemConfig);
        }

        emit ValidatorRegistered(validator, systemConfig, layer2, collateral, index);
    }

    // ==========================================
    // RAT Operations
    // ==========================================

    /// @inheritdoc IRAT
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external onlyValidFactory(systemConfig) whenNotPaused {
        // 확률적 트리거 체크 (π_a: RAT 트리거 확률)
        uint256 randomValue = uint256(keccak256(abi.encodePacked(blockHash, block.timestamp))) % RAY;
        if (randomValue >= ratTriggerProbability) return;

        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        if (pool.activeCount == 0) return; // 활성 검증자 없으면 무시

        // 기존 테스트 확인
        bytes32 existingTestId = batchToTestId[systemConfig][batchIndex];
        if (existingTestId != bytes32(0)) revert TestAlreadyExistsError();

        // 랜덤 검증자 선택
        address selectedValidator = _selectRandomValidator(systemConfig, blockHash);
        if (selectedValidator == address(0)) return;

        _processAttentionTest(gameAddress, systemConfig, batchIndex, batchHash, selectedValidator);
    }

    function _processAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        address selectedValidator
    ) internal {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][selectedValidator];

        // V3: 사용 가능한 담보금 확인
        (uint256 available, address layer2) = _getValidatorCollateral(selectedValidator, systemConfig);

        // 동적 C_off 계산 (현재 L2의 검증자 수 기준)
        uint256 n = getActiveValidatorCount(systemConfig);
        if (n == 0) n = 1;
        uint256 bondAmount = _calculateCoffWithRelaxedCheck(n);

        // 담보금이 0이면 테스트 없이 종료
        if (available == 0) {
            _removeValidator(systemConfig, selectedValidator, reg, layer2);
            return;
        }

        // 본드 사용 후 남은 담보금이 removalThreshold 미만이면 검증자 제거
        // bondAmount는 이미 _calculateCoffWithRelaxedCheck(n)로 계산됨
        uint256 removalThreshold = bondAmount + (relaxedValidatorCheck ? 0 : validatorBuffer);

        // bondAmount 조정 (available보다 클 수 없음)
        if (available < bondAmount) bondAmount = available;

        if (available - bondAmount < removalThreshold) {
            _removeValidator(systemConfig, selectedValidator, reg, layer2);
        }

        _createAttentionTest(gameAddress, systemConfig, batchIndex, batchHash, selectedValidator, bondAmount, reg, layer2);
    }

    function _createAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        address selectedValidator,
        uint256 bondAmount,
        ValidatorRegistration storage reg,
        address layer2
    ) internal {
        bytes32 testId = keccak256(abi.encodePacked(systemConfig, batchIndex, selectedValidator, block.timestamp));
        uint256 deadline = block.timestamp + evidenceSubmissionPeriod;

        // factory 주소 저장 (msg.sender = DisputeGameFactory)
        factoryByGame[gameAddress] = msg.sender;

        // 검증자별 최신 테스트 마감 시간 업데이트
        if (uint64(deadline) > reg.latestTestDeadline) {
            reg.latestTestDeadline = uint64(deadline);
        }

        attentionTests[testId] = AttentionTest({
            validatorAddress: selectedValidator,
            systemConfig: systemConfig,
            batchIndex: batchIndex,
            gameAddress: gameAddress,
            batchHash: batchHash,
            bondAmount: bondAmount,
            createdAt: block.timestamp,
            deadline: deadline,
            status: AttentionTestStatus.EvidencePeriod
        });

        batchToTestId[systemConfig][batchIndex] = testId;

        if (deadline > latestDeadlineTest[systemConfig]) {
            latestDeadlineTest[systemConfig] = deadline;
        }

        gameToTestId[gameAddress] = testId;

        // V3: 선차감 = validator coinage → RAT coinage 전송
        _transferCoinageToRAT(layer2, selectedValidator, bondAmount);

        emit AttentionTestTriggered(testId, selectedValidator, systemConfig, gameAddress, batchIndex, deadline);
    }

    /// @inheritdoc IRAT
    function submitEvidence(
        address systemConfig,
        uint32 batchIndex,
        bytes calldata evidence
    ) external ifFree whenNotPaused {
        bytes32 testId = batchToTestId[systemConfig][batchIndex];
        if (testId == bytes32(0)) revert TestNotFoundError();

        AttentionTest storage test = attentionTests[testId];

        if (test.validatorAddress != msg.sender) revert NotSelectedValidatorError();
        if (test.status != AttentionTestStatus.EvidencePeriod) revert TestAlreadyRespondedError();
        if (block.timestamp > test.deadline) revert DeadlinePassedError();

        // 증거 검증 (롤업 타입별 라이브러리 사용, evidenceType = 1: StateLeaf 고정)
        if (!_verifyEvidenceWithType(systemConfig, testId, test.batchHash, 1, evidence)) {
            revert EmptyEvidenceError();
        }

        // === Effects: 상태 업데이트 ===
        test.status = AttentionTestStatus.RestoredByEvidence;

        // === Interactions: 외부 호출 ===
        // V3: 복구 = RAT coinage → validator coinage 전송
        // (RAT에서 burn, validator에 mint)
        address layer2 = _getLayer2FromSystemConfig(systemConfig);
        _transferCoinageFromRAT(layer2, msg.sender, test.bondAmount);

        // 비활성 상태였다면 재활성화 시도
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        _reactivateValidator(systemConfig, msg.sender, reg, layer2);

        emit EvidenceSubmitted(testId, msg.sender, systemConfig, layer2, batchIndex);
    }

    /// @inheritdoc IRAT
    /// @dev 챌린지 게임 승리 시 호출 - EvidencePeriod 또는 ChallengePeriod 중에 복구 가능
    function resolveClaim(address _claimant) external {
        // msg.sender = 게임 주소, 유효한 게임인지 확인
        if (factoryByGame[msg.sender] == address(0)) return;

        // msg.sender = 게임 주소로 테스트 조회
        bytes32 testId = gameToTestId[msg.sender];
        if (testId == bytes32(0)) return;

        AttentionTest storage test = attentionTests[testId];

        // 선택된 검증자가 게임 승자와 같은지 확인
        if (test.validatorAddress != _claimant) return;

        // EvidencePeriod 상태에서만 복구 가능 (저장된 상태 기준)
        // ChallengePeriod는 계산된 상태이며, 저장된 상태는 여전히 EvidencePeriod
        if (test.status != AttentionTestStatus.EvidencePeriod) return;

        // deadline + challengeGameDuration 이후에는 복구 불가
        uint256 challengeEndTime = test.deadline + challengeGameDuration;
        if (block.timestamp > challengeEndTime) return;

        // === Effects: 상태 업데이트 ===
        test.status = AttentionTestStatus.RestoredByChallenge;

        // === Interactions: 외부 호출 ===
        // V3: 복구 = RAT coinage → validator coinage 전송 (챌린지 승리)
        // (RAT에서 burn, validator에 mint)
        address layer2 = _getLayer2FromSystemConfig(test.systemConfig);
        _transferCoinageFromRAT(layer2, _claimant, test.bondAmount);

        // 비활성 상태였다면 재활성화 시도
        ValidatorRegistration storage reg = validatorRegistrations[test.systemConfig][_claimant];
        _reactivateValidator(test.systemConfig, _claimant, reg, layer2);

        emit BondRestored(testId, _claimant, test.systemConfig, layer2, test.bondAmount);
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /// @notice 랜덤 검증자 선택
    /// @dev 배열에는 활성 검증자만 있으므로 O(1)로 직접 접근
    function _selectRandomValidator(address systemConfig, bytes32 seed)
        internal
        view
        returns (address)
    {
        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        uint256 validatorCount = pool.validators.length;
        if (validatorCount == 0) return address(0);

        // 랜덤 인덱스 생성 후 직접 접근 (O(1))
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % validatorCount;

        return pool.validators[randomIndex];
    }

    /// @notice 증거 검증 (롤업 타입별 + 증거 타입별 라이브러리 사용)
    /// @dev systemConfig의 롤업 타입과 evidenceType에 따라 적절한 검증 라이브러리를 호출
    /// @param systemConfig SystemConfig 주소 (롤업 타입 확인용)
    /// @param testId RAT 테스트 ID
    /// @param batchHash 예상 output root (FraudProof 검증용)
    /// @param evidenceType 증거 타입 (0: FraudProof, 1: StateLeaf)
    /// @param evidenceData 증거 데이터 (타입별로 다른 구조)
    /// @return 검증 성공 여부
    function _verifyEvidenceWithType(
        address systemConfig,
        bytes32 testId,
        bytes32 batchHash,
        uint8 evidenceType,
        bytes calldata evidenceData
    ) internal view virtual returns (bool) {
        // Evidence 데이터가 비어있으면 실패
        if (evidenceData.length == 0) {
            return false;
        }

        // SystemConfig의 롤업 타입 조회
        uint8 rollupType = _getRollupType(systemConfig);

        // Type 1 (LEGACY), Type 2 (OPTIMISM_BEDROCK): RAT 미사용
        if (rollupType == ROLLUP_TYPE_LEGACY || rollupType == ROLLUP_TYPE_OPTIMISM_BEDROCK) {
            revert RollupTypeNotSupportedError();
        }

        // Type 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)
        if (rollupType == ROLLUP_TYPE_OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) {
            // Evidence type 0: FraudProof (batch derivation)
            if (evidenceType == 0) {
                return Type3EvidenceVerifier.verify(batchHash, evidenceData);
            }
            // Evidence type 1: StateLeaf (adjacent leaves)
            if (evidenceType == 1) {
                // DisputeGame에서 rootClaim 조회
                AttentionTest storage test = attentionTests[testId];
                bytes32 rootClaim = IDisputeGame(test.gameAddress).rootClaim();

                // rootClaim과 함께 검증 (State Root as Target)
                return Type3EvidenceVerifier.verifyStateLeaf(rootClaim, evidenceData);
            }
            revert UnsupportedEvidenceTypeError();
        }

        // 지원하지 않는 타입
        revert RollupTypeNotSupportedError();
    }

    /// @notice SystemConfig의 롤업 타입 조회
    /// @dev L1BridgeRegistry에서 SystemConfig의 롤업 타입을 조회
    /// @param systemConfig SystemConfig 주소 (rollupConfig)
    /// @return 롤업 타입 (1: LEGACY, 2: OPTIMISM_BEDROCK, 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME, ...)
    function _getRollupType(address systemConfig) internal view returns (uint8) {
        // L1BridgeRegistry에서 rollupType 조회
        IL1BridgeRegistry registry = IL1BridgeRegistry(l1BridgeRegistry);
        return registry.rollupType(systemConfig);
    }

    /// @notice 검증자 제거 (담보금 부족 등으로 강제 제거)
    /// @dev 배열에서 완전히 제거
    function _removeValidator(
        address systemConfig,
        address validator,
        ValidatorRegistration storage reg,
        address layer2
    ) internal {
        // V1.1: 제거 전 보상 동기화 (O(1) 보상 분배용)
        if (validatorReward != address(0)) {
            IValidatorReward(validatorReward).syncValidatorReward(validator, systemConfig);
        }

        // 배열에서 제거
        _removeValidatorFromArray(systemConfig, validator);

        // 등록 정보 초기화
        reg.isActive = false;
        reg.validatorIndex = 0;

        emit ValidatorDeactivated(validator, systemConfig, layer2);
    }

    /// @notice 비활성 검증자 재활성화
    /// @dev 담보금 복구 후 자동 재활성화에 사용
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param validator 검증자 주소
    /// @param reg 검증자 등록 정보 storage pointer
    /// @param layer2 Layer2 주소
    function _reactivateValidator(
        address systemConfig,
        address validator,
        ValidatorRegistration storage reg,
        address layer2
    ) internal {
        // 이미 활성 상태면 스킵
        if (reg.isActive) return;

        // 현재 담보금 확인
        (uint256 collateral, ) = _getValidatorCollateral(validator, systemConfig);

        // relaxedValidatorCheck에 따른 임계값 계산
        uint256 n = getActiveValidatorCount(systemConfig);
        if (n == 0) n = 1;
        uint256 threshold = _calculateCoffWithRelaxedCheck(n)
            + (relaxedValidatorCheck ? 0 : validatorBuffer);

        // 임계값 이상이면 재활성화
        if (collateral >= threshold) {
            ValidatorPoolInfo storage pool = validatorPools[systemConfig];
            uint256 index = pool.validators.length;

            pool.validators.push(validator);
            pool.activeCount++;

            reg.validatorIndex = uint32(index);
            reg.isActive = true;

            validatorIndexes[systemConfig][validator] = index;

            // V1.1: 재활성화 시 보상 debt 리셋 (O(1) 보상 분배용)
            if (validatorReward != address(0)) {
                IValidatorReward(validatorReward).resetValidatorDebt(validator, systemConfig);
            }

            emit ValidatorReactivated(validator, systemConfig, layer2, collateral);
        }
    }

    // ==========================================
    // Governance Functions
    // ==========================================

    /// @inheritdoc IRAT
    function setAttentionCost(uint256 cost) external onlyOwner {
        attentionCost = cost;
    }

    /// @inheritdoc IRAT
    function setSlashingPenalty(uint256 penalty) external onlyOwner {
        slashingPenalty = penalty;
    }

    /// @inheritdoc IRAT
    function setValidatorBuffer(uint256 buffer) external onlyOwner {
        validatorBuffer = buffer;
    }

    /// @inheritdoc IRAT
    function setMinimumThreshold(uint256 threshold) external onlyOwner {
        minimumThreshold = threshold;
    }

    /// @inheritdoc IRAT
    function setMaxValidatorsPerL2(uint256 maxValidators) external onlyOwner {
        if (maxValidators == 0) revert InvalidMaxValidatorsError();
        maxValidatorsPerL2 = maxValidators;
        emit MaxValidatorsPerL2Updated(maxValidators);
    }

    /// @inheritdoc IRAT
    function setRatTriggerProbability(uint256 probability) external onlyOwner {
        if (probability > RAY) revert InvalidParameterError();
        ratTriggerProbability = probability;
    }

    /// @inheritdoc IRAT
    function setEvidenceSubmissionPeriod(uint256 period) external onlyOwner {
        evidenceSubmissionPeriod = period;
    }

    /// @notice 챌린지 게임 기간 설정
    /// @param duration 새로운 챌린지 게임 기간 (초)
    function setChallengeGameDuration(uint256 duration) external onlyOwner {
        challengeGameDuration = duration;
    }

    /// @notice 안전 버퍼 시간 설정
    /// @param buffer 새로운 안전 버퍼 시간 (초)
    function setSafetyBuffer(uint256 buffer) external onlyOwner {
        safetyBuffer = buffer;
    }

    /// @inheritdoc IRAT
    /// @notice 검증자 유효성 검사 완화 여부 설정
    /// @param relaxed true: C_off 기준 (완화), false: D_min 기준 (엄격)
    /// @dev V3 회의 결정: 초기에는 true로 설정하여 검증자 유치 용이하게 함
    function setRelaxedValidatorCheck(bool relaxed) external onlyOwner {
        relaxedValidatorCheck = relaxed;
        emit RelaxedValidatorCheckUpdated(relaxed);
    }

    /// @notice RAT 트리거 권한 주소 설정 (deprecated - use L1BridgeRegistry instead)
    function setAuthorizedTrigger(address trigger) external onlyOwner {
        authorizedTrigger = trigger;
    }

    /// @notice L1BridgeRegistry 주소 설정 (factory 검증용)
    function setL1BridgeRegistry(address _l1BridgeRegistry) external onlyOwner {
        l1BridgeRegistry = _l1BridgeRegistry;
    }

    /// @notice Treasury 주소 설정
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /// @notice ValidatorReward 컨트랙트 주소 설정 (V1.1)
    /// @param _validatorReward ValidatorReward 컨트랙트 주소
    function setValidatorReward(address _validatorReward) external onlyOwner {
        validatorReward = _validatorReward;
    }

    // transferOwnership은 AccessibleCommon에서 상속 (AccessControl 기반)

    /// @notice Pause 설정
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /// @notice 슬래싱된 coinage를 Treasury로 전송
    /// @dev V3: SeigManager를 통해 RAT coinage → Treasury coinage 전송
    /// @dev 모든 테스트의 deadline + 챌린지 게임 기간 + 안전 버퍼 이후에만 호출 가능
    /// @param systemConfig 슬래싱 금액을 전송할 L2의 SystemConfig 주소
    function withdrawSlashingsToTreasury(address systemConfig) external ifFree {
        if (treasury == address(0)) revert TreasuryNotSetError();

        // latestDeadlineTest: RAT 테스트 마감 시간
        // + challengeGameDuration: 챌린지 게임으로 복구 가능한 기간
        // + safetyBuffer: 안전 여유 시간 (기본 1일)
        uint256 withdrawableAfter = latestDeadlineTest[systemConfig] + challengeGameDuration + safetyBuffer;
        if (block.timestamp <= withdrawableAfter) revert PendingTestsNotExpiredError();

        address layer2 = _getLayer2FromSystemConfig(systemConfig);

        // RAT의 해당 L2 coinage 잔액 조회
        uint256 ratBalance = ISeigManagerForRAT(seigManager).stakeOf(layer2, address(this));
        if (ratBalance == 0) revert NoSlashingsToWithdrawError();

        // SeigManager를 통해 RAT coinage → Treasury coinage 전송
        ISeigManagerForRAT(seigManager).transferCoinageFromRatTo(layer2, treasury, ratBalance);

        emit SlashingsWithdrawn(systemConfig, layer2, treasury, ratBalance);
    }
}
