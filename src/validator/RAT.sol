// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RATStorage} from "./RATStorage.sol";
import {IRAT} from "./IRAT.sol";
import {IL1BridgeRegistry} from "../layer2/interfaces/IL1BridgeRegistry.sol";
import {IOnApprove} from "../stake/interfaces/IOnApprove.sol";
import {ILayer2Manager} from "../layer2/interfaces/ILayer2Manager.sol";

// Custom Errors
error AlreadyRegisteredError();
error NotActiveValidatorError();
error InsufficientDepositError();
error InvalidSystemConfigError();
error TestNotFoundError();
error TestAlreadyExistsError();
error NotYourTestError();
error TestAlreadyRespondedError();
error DeadlinePassedError();
error NoRewardsError();
error ZeroAmountError();
error InvalidParameterError();
error NotSelectedValidatorError();
error InvalidFactoryError();
error MaxValidatorsReachedError();

/**
 * @title RAT (Randomized Attention Test)
 * @notice TON Staking V3 검증자 Attention Test 컨트랙트
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 *
 * 핵심 기능:
 * 1. L2별 검증자 등록/탈퇴
 * 2. RAT 트리거 및 검증자 랜덤 선택
 * 3. 증거 제출 및 검증
 * 4. C_off 기반 선차감-복구 슬래싱 메커니즘
 * 5. 검증자 보상 분배
 *
 * 백서 V2 핵심 공식:
 * - (3) c_m ≤ (π_a / n) · C_off - RAT 균형 조건
 * - (4) C_off ≥ (c_m · n) / π_a - 최소 슬래싱 페널티
 * - (5) D_validator = C_off + Δ_validator - 검증자 담보금
 */
contract RAT is RATStorage, IRAT, IOnApprove {
    using SafeERC20 for IERC20;

    // ==========================================
    // Modifiers
    // ==========================================

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlySeigManager() {
        require(msg.sender == seigManager, "not seigManager");
        _;
    }

    modifier onlyAuthorizedTrigger() {
        require(msg.sender == authorizedTrigger, "not authorized");
        _;
    }

    /// @notice L1BridgeRegistry에 등록된 유효한 factory인지 검증
    modifier onlyValidFactory() {
        if (l1BridgeRegistry == address(0)) revert InvalidFactoryError();
        address rollupConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithDisputeGameFactory(msg.sender);
        if (rollupConfig == address(0)) revert InvalidFactoryError();
        _;
    }

    // ==========================================
    // Constructor / Initializer
    // ==========================================

    /// @notice RAT 컨트랙트 초기화
    /// @param _seigManager SeigManager 주소
    /// @param _wton WTON 주소
    /// @param _ton TON 주소
    /// @param _layer2Manager Layer2Manager 주소
    /// @param _owner Owner 주소
    /// @param _ratTriggerProbability RAT 트리거 확률 (RAY 단위, 백서 공식 기반으로 결정)
    /// @dev π_a는 백서 공식 C_off ≥ (c_m · N) / π_a 를 만족하도록 설정해야 함
    function initialize(
        address _seigManager,
        address _wton,
        address _ton,
        address _layer2Manager,
        address _owner,
        uint256 _ratTriggerProbability
    ) external {
        require(seigManager == address(0), "already initialized");
        require(_ratTriggerProbability > 0 && _ratTriggerProbability <= RAY, "invalid probability");

        seigManager = _seigManager;
        wton = _wton;
        ton = _ton;
        layer2Manager = _layer2Manager;
        owner = _owner;

        // 게임 이론 기반 파라미터 (배포 시 지정)
        // 백서 공식: C_off ≥ (c_m × N) / π_a
        // - 공식은 이론적 근거이며, 실시간 동적 업데이트 규칙이 아님
        // - N = L2별 검증자 수 (|V_i|)
        ratTriggerProbability = _ratTriggerProbability;

        // 기본값 설정
        evidenceSubmissionPeriod = 1 hours; // 1시간

        // V3: TON 직접 사용, WEI_UNIT (18 decimals) 단위
        // D_validator = C_off + Δ_validator
        // Δ_validator는 N 증가에 대비하여 충분한 마진 설정 필요
        slashingPenalty = 100 * WEI_UNIT;    // C_off = 100 TON
        validatorBuffer = 100 * WEI_UNIT;    // Δ_validator = 100 TON (N_max 고려한 마진)
        minimumThreshold = 1000 * WEI_UNIT;  // D_min = 1000 TON (≥ C_off + Δ_validator)

        // N_max: L2별 최대 검증자 수
        // - 백서 공식 C_off ≥ (c_m × N) / π_a 에서 N의 상한
        // - 시뇨리지 분배 시 가스 한도 고려 (각 검증자당 ~25K gas)
        maxValidatorsPerL2 = 100;
    }

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 검증자 등록 정보 조회
    /// @dev V3: pendingRewards 제거 - ValidatorReward.getPendingRewards() 사용
    function getValidatorRegistration(address validator, address systemConfig)
        external
        view
        returns (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            uint32 validatorIndex,
            bool isActive
        )
    {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][validator];
        return (
            reg.depositedAmount,
            reg.totalBondForRAT,
            reg.validatorIndex,
            reg.isActive
        );
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
            test.status
        );
    }

    /// @inheritdoc IRAT
    function getMinimumCollateral() public view returns (uint256) {
        // 백서 V2 공식 (5): D_validator = C_off + Δ_validator
        return slashingPenalty + validatorBuffer;
    }

    /// @inheritdoc IRAT
    function validateSlashingPenalty(uint256 n) public view returns (bool) {
        if (ratTriggerProbability == 0 || n == 0) return false;
        // 백서 공식 (4): C_off ≥ (c_m · n) / π_a
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

    /// @notice 검증자 담보금 조회 (외부 컨트랙트용 간편 함수)
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 현재 담보금 (슬래싱 반영된 금액)
    function getValidatorDeposit(address validator, address systemConfig) external view returns (uint256) {
        return validatorRegistrations[systemConfig][validator].depositedAmount;
    }

    /// @notice 검증자가 활성 상태인지 확인
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return 활성 상태 여부
    function isValidatorActive(address validator, address systemConfig) external view returns (bool) {
        return validatorRegistrations[systemConfig][validator].isActive;
    }

    // ==========================================
    // Validator Management
    // ==========================================

    /// @inheritdoc IRAT
    /// @dev TON으로 검증자 등록. TON.approveAndCall(RAT, amount, systemConfig) 사용
    /// @dev V3: RAT에서 TON 직접 보관 (DepositManager/WTON 미사용)
    function registerValidator(address systemConfig, uint256 depositAmount)
        external
        ifFree
        whenNotPaused
    {
        if (systemConfig == address(0)) revert InvalidSystemConfigError();
        if (depositAmount == 0) revert ZeroAmountError();

        // TON 직접 전송 받기
        IERC20(ton).safeTransferFrom(msg.sender, address(this), depositAmount);

        // 검증자 등록 로직
        _registerValidatorInternal(msg.sender, systemConfig, depositAmount);
    }

    /// @inheritdoc IRAT
    /// @notice 검증자 탈퇴 및 즉시 출금
    /// @dev V3: RAT에서 TON 직접 보관하므로 즉시 출금 가능 (2주 대기 불필요)
    /// @dev V3 정책: 담보금 시뇨리지 없음, depositedAmount 전액 반환
    function deactivateValidator(address systemConfig) external ifFree {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (!reg.isActive) revert NotActiveValidatorError();

        // 진행 중인 RAT 테스트가 있으면 대기 (deadline 경과 후에만 출금 가능)
        require(block.timestamp >= reg.latestTestDeadline, "pending RAT tests");

        // 미응답한 RAT 테스트의 totalBondForRAT는 손실 확정 (Lazy Evaluation)
        // accumulatedSlashings에 추가하여 Treasury로 회수
        if (reg.totalBondForRAT > 0) {
            accumulatedSlashings += reg.totalBondForRAT;
            reg.totalBondForRAT = 0;
        }

        reg.isActive = false;

        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        pool.activeCount--;
        pool.totalDeposited -= reg.depositedAmount;

        // V3 정책: 담보금 전액 반환 (시뇨리지 없음)
        uint256 withdrawAmount = reg.depositedAmount;
        reg.depositedAmount = 0;

        // V3: TON 직접 전송 (즉시 출금)
        if (withdrawAmount > 0) {
            IERC20(ton).safeTransfer(msg.sender, withdrawAmount);
        }

        // 미청구 보상은 즉시 지급 (WTON)
        uint256 pendingRewards = reg.pendingRewards;
        reg.pendingRewards = 0;
        if (pendingRewards > 0) {
            IERC20(wton).safeTransfer(msg.sender, pendingRewards);
        }

        emit ValidatorDeactivated(msg.sender, systemConfig, withdrawAmount);
    }

    // V3: processWithdrawal 제거 - deactivateValidator에서 즉시 출금

    /// @inheritdoc IRAT
    /// @dev V3: TON 직접 입금 (DepositManager 미사용)
    function addDeposit(address systemConfig, uint256 amount) external ifFree {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        // 활성 검증자만 추가 입금 가능
        // 비활성 검증자는 registerValidator()로 재등록해야 함
        if (!reg.isActive) revert NotActiveValidatorError();
        if (amount == 0) revert ZeroAmountError();

        // TON 직접 전송 받기
        IERC20(ton).safeTransferFrom(msg.sender, address(this), amount);

        reg.depositedAmount += amount;
        validatorPools[systemConfig].totalDeposited += amount;

        emit DepositAdded(msg.sender, systemConfig, amount);
    }

    /// @notice TON에서 호출되는 콜백 (TON.approveAndCall → RAT)
    /// @param owner TON 전송자 (검증자)
    /// @param spender RAT 컨트랙트 주소 (사용 안함)
    /// @param amount TON 양 (18 decimals)
    /// @param data systemConfig 주소 (32바이트)
    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override ifFree whenNotPaused returns (bool) {
        require(msg.sender == ton, "only TON");

        // data에서 systemConfig 추출 (32바이트)
        require(data.length >= 32, "invalid data");
        address systemConfig = address(uint160(uint256(bytes32(data[:32]))));
        if (systemConfig == address(0)) revert InvalidSystemConfigError();

        // TON은 이미 RAT에 전송됨 (TON.onApprove에서 transfer)

        // 검증자 등록 로직
        _registerValidatorInternal(owner, systemConfig, amount);

        return true;
    }

    /// @notice 내부 검증자 등록 로직
    /// @dev V3 정책: 담보금 시뇨리지 없음, depositedAmount = 원금 - 슬래싱
    /// @dev V3 회의 결정: enforceMinDeposit flag로 최소 담보금 체크 유연화
    function _registerValidatorInternal(address validator, address systemConfig, uint256 depositAmount) internal {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][validator];
        if (reg.isActive) revert AlreadyRegisteredError();

        // 기존 담보금이 있는 경우 (슬래싱 후 재등록)
        uint256 totalDeposit = reg.depositedAmount + depositAmount;

        // V3: 조건부 최소 담보금 체크 (enforceMinDeposit flag)
        if (enforceMinDeposit) {
            uint256 minDeposit = getMinimumCollateral();
            if (totalDeposit < minDeposit) revert InsufficientDepositError();
        }

        ValidatorPoolInfo storage pool = validatorPools[systemConfig];

        // 신규 등록인지 재등록인지 확인
        bool isReregistration = reg.depositedAmount > 0;

        if (isReregistration) {
            // 재등록: 풀에 재활성화
            pool.activeCount++;
            pool.totalDeposited += totalDeposit;

            // 기존 인덱스 유지, 담보금만 업데이트
            reg.depositedAmount = totalDeposit;
            reg.isActive = true;
        } else {
            // 신규 등록
            uint256 index = pool.validators.length;

            // N_max 체크: L2별 최대 검증자 수 제한
            // - 백서 공식 C_off ≥ (c_m × N) / π_a 에서 N의 상한 보장
            // - 시뇨리지 분배 시 가스 한도 문제 방지
            if (maxValidatorsPerL2 > 0 && index >= maxValidatorsPerL2) {
                revert MaxValidatorsReachedError();
            }

            pool.validators.push(validator);
            pool.activeCount++;
            pool.totalDeposited += totalDeposit;

            // 검증자 등록 정보 설정
            reg.depositedAmount = totalDeposit;
            reg.totalBondForRAT = 0;
            reg.pendingRewards = 0;
            reg.validatorIndex = uint32(index);
            reg.isActive = true;

            validatorIndexes[systemConfig][validator] = index;
            validatorSystemConfigs[validator].push(systemConfig);
        }

        emit ValidatorRegistered(validator, systemConfig, totalDeposit, reg.validatorIndex);
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
    ) external onlyValidFactory whenNotPaused {
        // factory 주소 저장 (msg.sender = DisputeGameFactory)
        factoryByGame[gameAddress] = msg.sender;

        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        if (pool.activeCount == 0) return; // 활성 검증자 없으면 무시

        // 기존 테스트 확인
        bytes32 existingTestId = batchToTestId[systemConfig][batchIndex];
        if (existingTestId != bytes32(0)) revert TestAlreadyExistsError();

        // 랜덤 검증자 선택
        address selectedValidator = _selectRandomValidator(systemConfig, blockHash);
        if (selectedValidator == address(0)) return;

        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][selectedValidator];
        if (!reg.isActive) return;

        // C_off 만큼 선차감
        uint256 bondAmount = slashingPenalty;
        if (reg.depositedAmount < bondAmount) {
            bondAmount = reg.depositedAmount;
        }

        reg.depositedAmount -= bondAmount;
        reg.totalBondForRAT += bondAmount;

        // Attention Test 생성
        bytes32 testId = keccak256(abi.encodePacked(systemConfig, batchIndex, selectedValidator, block.timestamp));
        uint256 deadline = block.timestamp + evidenceSubmissionPeriod;

        // 최신 테스트 마감 시간 업데이트 (출금 조건 체크용)
        if (uint64(deadline) > reg.latestTestDeadline) {
            reg.latestTestDeadline = uint64(deadline);
        }

        // D_min 확인 - 잔액이 D_min 미만이면 즉시 검증자 세트에서 제거
        bool removedFromSet = false;
        if (reg.depositedAmount < minimumThreshold) {
            _removeValidator(systemConfig, selectedValidator, reg);
            removedFromSet = true;
        }

        attentionTests[testId] = AttentionTest({
            validatorAddress: selectedValidator,
            systemConfig: systemConfig,
            batchIndex: batchIndex,
            batchHash: batchHash,
            bondAmount: bondAmount,
            createdAt: block.timestamp,
            deadline: deadline,
            status: AttentionTestStatus.Pending
        });

        batchToTestId[systemConfig][batchIndex] = testId;
        activeTestCount[systemConfig]++;

        // 게임 주소 → testId 매핑 저장 (resolveClaim에서 조회용)
        gameToTestId[gameAddress] = testId;

        emit AttentionTestTriggered(testId, selectedValidator, systemConfig, gameAddress, batchIndex, deadline);

        // D_min 미만으로 제거된 경우 슬래싱 이벤트 발생
        if (removedFromSet) {
            emit ValidatorSlashed(testId, selectedValidator, systemConfig, bondAmount, true);
        }
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
        if (test.status != AttentionTestStatus.Pending) revert TestAlreadyRespondedError();
        if (block.timestamp > test.deadline) revert DeadlinePassedError();

        // 증거 검증 (TODO: 실제 증거 검증 로직)
        // 현재는 제출 자체만으로 성공으로 처리
        _verifyEvidence(test.batchHash, evidence);

        // 담보금 복구
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        reg.depositedAmount += test.bondAmount;
        reg.totalBondForRAT -= test.bondAmount;

        test.status = AttentionTestStatus.Responded;
        activeTestCount[systemConfig]--;

        // 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
        if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
            _restoreValidator(systemConfig, msg.sender, reg);
            emit ValidatorRestored(msg.sender, systemConfig);
        }

        emit EvidenceSubmitted(testId, msg.sender, systemConfig, batchIndex);
    }

    /// @inheritdoc IRAT
    function resolveClaim(address _claimant) external {
        // msg.sender = 게임 주소, 유효한 게임인지 확인
        if (factoryByGame[msg.sender] == address(0)) return;  // 유효한 factory에서 생성된 게임이 아님

        // msg.sender = 게임 주소로 테스트 조회
        bytes32 testId = gameToTestId[msg.sender];
        if (testId == bytes32(0)) return;  // 해당 게임의 RAT 테스트가 없음

        AttentionTest storage test = attentionTests[testId];

        // 선택된 검증자가 게임 승자와 같은지 확인
        if (test.validatorAddress != _claimant) return;
        if (test.status != AttentionTestStatus.Pending) return;  // 이미 처리됨

        // 담보금 복구
        test.status = AttentionTestStatus.Responded;
        activeTestCount[test.systemConfig]--;

        ValidatorRegistration storage reg = validatorRegistrations[test.systemConfig][_claimant];

        // 잔액 복구
        uint256 restoredAmount = test.bondAmount;
        reg.depositedAmount += restoredAmount;
        reg.totalBondForRAT -= restoredAmount;

        // 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
        if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
            _restoreValidator(test.systemConfig, _claimant, reg);
            emit ValidatorRestored(_claimant, test.systemConfig);
        }

        emit BondRestored(testId, _claimant, test.systemConfig, restoredAmount);
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /// @notice 랜덤 검증자 선택
    function _selectRandomValidator(address systemConfig, bytes32 seed)
        internal
        view
        returns (address)
    {
        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        uint256 activeCount = pool.activeCount;
        if (activeCount == 0) return address(0);

        // 랜덤 인덱스 생성
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.prevrandao))) % activeCount;

        // 활성 검증자 중 선택
        address[] storage validators = pool.validators;
        uint256 len = validators.length;
        uint256 count = 0;

        for (uint256 i = 0; i < len; i++) {
            if (validatorRegistrations[systemConfig][validators[i]].isActive) {
                if (count == randomIndex) {
                    return validators[i];
                }
                count++;
            }
        }

        return address(0);
    }

    /// @notice 증거 검증
    function _verifyEvidence(bytes32 batchHash, bytes calldata evidence)
        internal
        pure
        returns (bool)
    {
        // TODO: 실제 증거 검증 로직 구현
        // Optimism RAT에서는 stateRoot의 left/right 자식 해시를 검증
        // 현재는 제출 자체만으로 통과
        return evidence.length > 0;
    }

    /// @notice 검증자 제거
    function _removeValidator(
        address systemConfig,
        address validator,
        ValidatorRegistration storage reg
    ) internal {
        reg.isActive = false;

        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        pool.activeCount--;
        pool.totalDeposited -= reg.depositedAmount;

        // 잔액은 검증자가 deactivateValidator()로 출금 가능
    }

    /// @notice 검증자 복구 (resolveClaim에서 사용)
    function _restoreValidator(
        address systemConfig,
        address validator,
        ValidatorRegistration storage reg
    ) internal {
        reg.isActive = true;

        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        pool.activeCount++;
        pool.totalDeposited += reg.depositedAmount;

        // 검증자 인덱스 업데이트
        reg.validatorIndex = uint32(pool.validators.length);
        pool.validators.push(validator);
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

    /// @inheritdoc IRAT
    /// @notice 최소 담보금 강제 여부 설정
    /// @param enforce true: 강제, false: 비강제 (초기 단계)
    /// @dev V3 회의 결정: 초기에는 false로 설정하여 검증자 유치 용이하게 함
    function setEnforceMinDeposit(bool enforce) external onlyOwner {
        enforceMinDeposit = enforce;
        emit EnforceMinDepositUpdated(enforce);
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

    /// @notice Owner 변경
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        owner = newOwner;
    }

    /// @notice Pause 설정
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /// @notice 누적 슬래싱 금액을 Treasury로 전송
    /// @dev V3: 검증자 담보금은 TON으로 예치되므로 TON으로 전송
    function withdrawSlashingsToTreasury() external {
        require(treasury != address(0), "treasury not set");
        uint256 amount = accumulatedSlashings;
        accumulatedSlashings = 0;
        IERC20(ton).safeTransfer(treasury, amount);
    }

    // ==========================================
    // Emergency Functions
    // ==========================================

    /// @notice 비상 출금 (Owner 전용)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
