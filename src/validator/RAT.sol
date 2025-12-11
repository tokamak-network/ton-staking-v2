// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RATStorage} from "./RATStorage.sol";
import {IRAT} from "./IRAT.sol";

// Custom Errors
error AlreadyRegisteredError();
error NotActiveValidatorError();
error InsufficientDepositError();
error InvalidSystemConfigError();
error TestNotFoundError();
error TestAlreadyExistsError();
error NotYourTestError();
error TestAlreadyRespondedError();
error DeadlineNotPassedError();
error DeadlinePassedError();
error TestAlreadyFinalizedError();
error NoRewardsError();
error ZeroAmountError();
error InvalidParameterError();
error NotSelectedValidatorError();

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
contract RAT is RATStorage, IRAT {
    using SafeERC20 for IERC20;

    // ==========================================
    // Constructor / Initializer
    // ==========================================

    function initialize(
        address _seigManager,
        address _wton,
        address _ton,
        address _depositManager,
        address _owner
    ) external {
        require(seigManager == address(0), "already initialized");

        seigManager = _seigManager;
        wton = _wton;
        ton = _ton;
        depositManager = _depositManager;
        owner = _owner;

        // 기본값 설정
        ratTriggerProbability = 0.01e27;    // π_a = 1%
        evidenceSubmissionPeriod = 1 hours; // 1시간
        minimumThreshold = 1000e27;         // D_min = 1000 WTON
        slashingPenalty = 100e27;           // C_off = 100 WTON
        validatorBuffer = 100e27;           // Δ_validator = 100 WTON
    }

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 검증자 등록 정보 조회
    function getValidatorRegistration(address validator, address systemConfig)
        external
        view
        returns (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            uint256 pendingRewards,
            uint256 coinageFactorAtDeposit,
            uint32 validatorIndex,
            bool isActive
        )
    {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][validator];
        return (
            reg.depositedAmount,
            reg.totalBondForRAT,
            reg.pendingRewards,
            reg.coinageFactorAtDeposit,
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
    function getTotalPendingRewards(address validator) external view returns (uint256 total) {
        address[] storage configs = validatorSystemConfigs[validator];
        uint256 len = configs.length;
        for (uint256 i = 0; i < len; i++) {
            total += validatorRegistrations[configs[i]][validator].pendingRewards;
        }
    }

    /// @inheritdoc IRAT
    function getPendingRewards(address validator, address systemConfig)
        external
        view
        returns (uint256)
    {
        return validatorRegistrations[systemConfig][validator].pendingRewards;
    }

    // ==========================================
    // Validator Management
    // ==========================================

    /// @inheritdoc IRAT
    function registerValidator(address systemConfig, uint256 depositAmount)
        external
        ifFree
        whenNotPaused
    {
        if (systemConfig == address(0)) revert InvalidSystemConfigError();

        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (reg.isActive) revert AlreadyRegisteredError();

        uint256 minDeposit = getMinimumCollateral();
        if (depositAmount < minDeposit) revert InsufficientDepositError();

        // WTON 전송
        IERC20(wton).safeTransferFrom(msg.sender, address(this), depositAmount);

        // 검증자 풀에 추가
        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        uint256 index = pool.validators.length;
        pool.validators.push(msg.sender);
        pool.activeCount++;
        pool.totalDeposited += depositAmount;

        // 검증자 등록 정보 설정
        reg.depositedAmount = depositAmount;
        reg.totalBondForRAT = 0;
        reg.pendingRewards = 0;
        reg.coinageFactorAtDeposit = 0; // TODO: coinage factor 연동
        reg.validatorIndex = uint32(index);
        reg.isActive = true;

        validatorIndexes[systemConfig][msg.sender] = index;
        validatorSystemConfigs[msg.sender].push(systemConfig);

        emit ValidatorRegistered(msg.sender, systemConfig, depositAmount, index);
    }

    /// @inheritdoc IRAT
    function deactivateValidator(address systemConfig) external ifFree {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (!reg.isActive) revert NotActiveValidatorError();

        // 진행 중인 RAT가 있으면 대기
        require(reg.totalBondForRAT == 0, "pending RAT tests");

        reg.isActive = false;

        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        pool.activeCount--;
        pool.totalDeposited -= reg.depositedAmount;

        // 담보금 + 미청구 보상 반환
        uint256 totalReturn = reg.depositedAmount + reg.pendingRewards;
        reg.depositedAmount = 0;
        reg.pendingRewards = 0;

        if (totalReturn > 0) {
            IERC20(wton).safeTransfer(msg.sender, totalReturn);
        }

        emit ValidatorDeactivated(msg.sender, systemConfig, totalReturn);
    }

    /// @inheritdoc IRAT
    function addDeposit(address systemConfig, uint256 amount) external ifFree {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (!reg.isActive) revert NotActiveValidatorError();
        if (amount == 0) revert ZeroAmountError();

        IERC20(wton).safeTransferFrom(msg.sender, address(this), amount);

        reg.depositedAmount += amount;
        validatorPools[systemConfig].totalDeposited += amount;

        emit DepositAdded(msg.sender, systemConfig, amount);
    }

    // ==========================================
    // RAT Operations
    // ==========================================

    /// @inheritdoc IRAT
    function triggerAttentionTest(
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external onlyAuthorizedTrigger whenNotPaused {
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

        emit AttentionTestTriggered(testId, selectedValidator, systemConfig, batchIndex, deadline);
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

        emit EvidenceSubmitted(testId, msg.sender, systemConfig, batchIndex);
    }

    /// @inheritdoc IRAT
    function finalizeSlash(bytes32 testId) external ifFree {
        AttentionTest storage test = attentionTests[testId];

        if (test.validatorAddress == address(0)) revert TestNotFoundError();
        if (test.status != AttentionTestStatus.Pending) revert TestAlreadyFinalizedError();
        if (block.timestamp <= test.deadline) revert DeadlineNotPassedError();

        // 슬래싱 확정
        test.status = AttentionTestStatus.Slashed;
        activeTestCount[test.systemConfig]--;

        ValidatorRegistration storage reg = validatorRegistrations[test.systemConfig][test.validatorAddress];

        // 묶인 담보금에서 슬래싱 처리 (이미 선차감됨)
        reg.totalBondForRAT -= test.bondAmount;
        accumulatedSlashings += test.bondAmount;

        // D_min 미만이면 활성 검증자 세트에서 제거
        bool removedFromSet = false;
        if (reg.depositedAmount < minimumThreshold) {
            _removeValidator(test.systemConfig, test.validatorAddress, reg);
            removedFromSet = true;
        }

        emit ValidatorSlashed(testId, test.validatorAddress, test.systemConfig, test.bondAmount, removedFromSet);
    }

    // ==========================================
    // Rewards
    // ==========================================

    /// @inheritdoc IRAT
    function claimRewards(address systemConfig) external ifFree {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
        if (reg.pendingRewards == 0) revert NoRewardsError();

        uint256 rewards = reg.pendingRewards;
        reg.pendingRewards = 0;

        IERC20(wton).safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, systemConfig, rewards);
    }

    /// @inheritdoc IRAT
    function claimRewardsBatch(address[] calldata systemConfigs) external ifFree {
        uint256 totalRewards = 0;
        uint256 len = systemConfigs.length;

        for (uint256 i = 0; i < len; i++) {
            ValidatorRegistration storage reg = validatorRegistrations[systemConfigs[i]][msg.sender];
            if (reg.pendingRewards > 0) {
                totalRewards += reg.pendingRewards;
                reg.pendingRewards = 0;
            }
        }

        if (totalRewards == 0) revert NoRewardsError();

        IERC20(wton).safeTransfer(msg.sender, totalRewards);

        emit RewardsClaimedBatch(msg.sender, totalRewards, len);
    }

    /// @inheritdoc IRAT
    function distributeValidatorReward(address systemConfig, uint256 amount)
        external
        onlySeigManager
    {
        ValidatorPoolInfo storage pool = validatorPools[systemConfig];
        if (pool.activeCount == 0) return;

        // v_i = amount / n
        uint256 perValidator = amount / pool.activeCount;
        pool.rewardPerValidator += perValidator;

        // 각 활성 검증자에게 보상 누적
        address[] storage validators = pool.validators;
        uint256 len = validators.length;
        for (uint256 i = 0; i < len; i++) {
            ValidatorRegistration storage reg = validatorRegistrations[systemConfig][validators[i]];
            if (reg.isActive) {
                reg.pendingRewards += perValidator;
            }
        }
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
    function setRatTriggerProbability(uint256 probability) external onlyOwner {
        if (probability > RAY) revert InvalidParameterError();
        ratTriggerProbability = probability;
    }

    /// @inheritdoc IRAT
    function setEvidenceSubmissionPeriod(uint256 period) external onlyOwner {
        evidenceSubmissionPeriod = period;
    }

    /// @notice RAT 트리거 권한 주소 설정
    function setAuthorizedTrigger(address trigger) external onlyOwner {
        authorizedTrigger = trigger;
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
    function withdrawSlashingsToTreasury() external {
        require(treasury != address(0), "treasury not set");
        uint256 amount = accumulatedSlashings;
        accumulatedSlashings = 0;
        IERC20(wton).safeTransfer(treasury, amount);
    }

    // ==========================================
    // Emergency Functions
    // ==========================================

    /// @notice 비상 출금 (Owner 전용)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner, amount);
    }
}
