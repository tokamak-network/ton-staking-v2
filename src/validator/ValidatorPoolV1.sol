// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ValidatorPoolStorage} from "./ValidatorPoolStorage.sol";
import {IValidatorPool} from "./IValidatorPool.sol";

// Custom Errors
error AlreadyRegisteredError();
error NotActiveValidatorError();
error InsufficientDepositError();
error NotYourChallengeError();
error AlreadyRespondedError();
error DeadlineNotPassedError();
error DeadlinePassedError();
error AlreadySlashedError();
error InvalidChallengeError();
error NoRewardsError();
error NoActiveValidatorsError();
error ZeroAmountError();
error InvalidParameterError();

/**
 * @title ValidatorPoolV1
 * @notice TON Staking V3 검증자 풀 컨트랙트
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 *
 * 핵심 기능:
 * 1. 검증자 등록/탈퇴
 * 2. RAT (Randomized Attention Test) 처리
 * 3. 검증자 보상 분배
 * 4. C_off 기반 슬래싱
 */
contract ValidatorPoolV1 is ValidatorPoolStorage, IValidatorPool {
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

    modifier onlyRATIssuer() {
        require(msg.sender == ratIssuer, "not ratIssuer");
        _;
    }

    // ==========================================
    // Constructor / Initializer
    // ==========================================

    function initialize(
        address _seigManager,
        address _wton,
        address _ton,
        address _owner
    ) external {
        require(seigManager == address(0), "already initialized");

        seigManager = _seigManager;
        wton = _wton;
        ton = _ton;
        owner = _owner;

        // 기본값 설정
        ratProbability = 0.01e27;       // π_a = 1%
        ratResponseWindow = 1 hours;    // 1시간
        minimumThreshold = 1000e27;     // D_min = 1000 WTON
        slashingPenalty = 100e27;       // C_off = 100 WTON
        minimumValidatorDeposit = 1100e27; // C_off + 버퍼
    }

    // ==========================================
    // View Functions
    // ==========================================

    /// @inheritdoc IValidatorPool
    function getValidators() external view returns (address[] memory) {
        return validators;
    }

    /// @notice 검증자 정보 조회
    function getValidatorInfo(address validator)
        external
        view
        returns (
            bool isActive,
            uint256 depositAmount,
            uint256 pendingRewards,
            uint256 lastClaimPeriod,
            uint256 lastRATResponse
        )
    {
        ValidatorInfo storage info = validatorInfo[validator];
        return (
            info.isActive,
            info.depositAmount,
            info.pendingRewards,
            info.lastClaimPeriod,
            info.lastRATResponse
        );
    }

    /// @inheritdoc IValidatorPool
    function getMinimumDeposit() public view returns (uint256) {
        // 백서 V2 공식 (5): D_validator = C_off + Δ_validator
        return slashingPenalty + validatorBuffer;
    }

    /// @notice C_off가 백서 공식 (4)를 만족하는지 검증
    /// @dev C_off ≥ (c_m · n) / π_a
    /// @param n 검증자 수
    function validateSlashingPenalty(uint256 n) public view returns (bool) {
        if (ratProbability == 0) return false;
        // C_off ≥ (c_m · n) / π_a
        // → C_off · π_a ≥ c_m · n
        return slashingPenalty * ratProbability >= attentionCost * n * RAY;
    }

    // ==========================================
    // Validator Management
    // ==========================================

    /// @inheritdoc IValidatorPool
    function registerValidator(uint256 depositAmount) external ifFree {
        if (validatorInfo[msg.sender].isActive) revert AlreadyRegisteredError();
        if (depositAmount < getMinimumDeposit()) revert InsufficientDepositError();

        // WTON 전송
        IERC20(wton).safeTransferFrom(msg.sender, address(this), depositAmount);

        // 검증자 등록
        validators.push(msg.sender);
        uint256 index = validators.length - 1;
        validatorIndex[msg.sender] = index;

        validatorInfo[msg.sender] = ValidatorInfo({
            isActive: true,
            depositAmount: depositAmount,
            pendingRewards: 0,
            lastClaimPeriod: currentPeriodId,
            lastRATResponse: block.timestamp,
            registeredAt: block.timestamp,
            validatorIndex: index
        });

        activeValidatorCount++;

        emit ValidatorRegistered(msg.sender, depositAmount);
    }

    /// @inheritdoc IValidatorPool
    function addDeposit(uint256 amount) external ifFree {
        ValidatorInfo storage info = validatorInfo[msg.sender];
        if (!info.isActive) revert NotActiveValidatorError();
        if (amount == 0) revert ZeroAmountError();

        IERC20(wton).safeTransferFrom(msg.sender, address(this), amount);
        info.depositAmount += amount;

        emit DepositAdded(msg.sender, amount);
    }

    /// @inheritdoc IValidatorPool
    function deactivateValidator() external ifFree {
        ValidatorInfo storage info = validatorInfo[msg.sender];
        if (!info.isActive) revert NotActiveValidatorError();

        info.isActive = false;
        activeValidatorCount--;

        // 미청구 보상 포함하여 반환
        uint256 totalReturn = info.depositAmount + info.pendingRewards;
        info.depositAmount = 0;
        info.pendingRewards = 0;

        if (totalReturn > 0) {
            IERC20(wton).safeTransfer(msg.sender, totalReturn);
        }

        emit ValidatorDeactivated(msg.sender);
    }

    // ==========================================
    // RAT (Randomized Attention Test)
    // ==========================================

    /// @inheritdoc IValidatorPool
    function issueRAT(address validator, uint256 batchId)
        external
        onlyRATIssuer
    {
        ValidatorInfo storage info = validatorInfo[validator];
        if (!info.isActive) revert NotActiveValidatorError();

        bytes32 challengeId = keccak256(abi.encodePacked(validator, batchId));
        if (ratChallenges[challengeId].validator != address(0)) revert AlreadyRespondedError();

        uint256 deadline = block.timestamp + ratResponseWindow;

        ratChallenges[challengeId] = RATChallenge({
            validator: validator,
            batchId: batchId,
            deadline: deadline,
            responded: false,
            slashed: false,
            createdAt: block.timestamp
        });

        emit RATIssued(validator, batchId, deadline);
    }

    /// @inheritdoc IValidatorPool
    function respondToRAT(uint256 batchId, bool attestation) external {
        bytes32 challengeId = keccak256(abi.encodePacked(msg.sender, batchId));
        RATChallenge storage challenge = ratChallenges[challengeId];

        if (challenge.validator != msg.sender) revert NotYourChallengeError();
        if (challenge.responded) revert AlreadyRespondedError();
        if (block.timestamp > challenge.deadline) revert DeadlinePassedError();

        challenge.responded = true;
        validatorInfo[msg.sender].lastRATResponse = block.timestamp;

        emit RATResponded(msg.sender, batchId, attestation);
    }

    /// @inheritdoc IValidatorPool
    /// @dev 백서 V2: C_off 기반 슬래싱 (전체 담보금이 아닌 페널티 금액만)
    function slashUnresponsiveValidator(address validator, uint256 batchId)
        external
        ifFree
    {
        bytes32 challengeId = keccak256(abi.encodePacked(validator, batchId));
        RATChallenge storage challenge = ratChallenges[challengeId];

        if (challenge.validator != validator) revert InvalidChallengeError();
        if (challenge.responded) revert AlreadyRespondedError();
        if (block.timestamp <= challenge.deadline) revert DeadlineNotPassedError();
        if (challenge.slashed) revert AlreadySlashedError();

        challenge.slashed = true;

        ValidatorInfo storage info = validatorInfo[validator];

        // 백서 V2: C_off만 슬래싱 (전체 담보금이 아님)
        uint256 slashedAmount = slashingPenalty;
        if (info.depositAmount < slashedAmount) {
            slashedAmount = info.depositAmount; // 잔액이 C_off 미만이면 전액
        }
        info.depositAmount -= slashedAmount;

        // 백서 V2: D_min 미만이면 즉시 활성 검증자 세트에서 제거
        bool removedFromSet = false;
        if (info.depositAmount < minimumThreshold) {
            info.isActive = false;
            activeValidatorCount--;
            removedFromSet = true;
            // 잔액은 검증자가 deactivateValidator()로 출금 가능
        }

        // 슬래싱된 금액은 DAO 또는 프로토콜 재무로 (TBD)
        // 현재는 컨트랙트에 보관

        emit ValidatorSlashed(validator, slashedAmount, removedFromSet);
    }

    // ==========================================
    // Rewards
    // ==========================================

    /// @inheritdoc IValidatorPool
    /// @dev 백서 공식 (13): v_i = (α/n) · y(x)
    function distributePeriodRewards(uint256 periodId, uint256 totalAmount)
        external
        onlySeigManager
    {
        if (activeValidatorCount == 0) revert NoActiveValidatorsError();

        periodValidatorPool[periodId] = totalAmount;

        // v_i = totalAmount / n
        uint256 perValidator = totalAmount / activeValidatorCount;
        periodPerValidatorReward[periodId] = perValidator;

        // 각 활성 검증자에게 보상 누적
        uint256 len = validators.length;
        for (uint256 i = 0; i < len; i++) {
            address validator = validators[i];
            if (validatorInfo[validator].isActive) {
                validatorInfo[validator].pendingRewards += perValidator;
            }
        }

        currentPeriodId = periodId;

        emit ValidatorRewardDistributed(periodId, totalAmount, perValidator);
    }

    /// @inheritdoc IValidatorPool
    function claimRewards() external ifFree {
        ValidatorInfo storage info = validatorInfo[msg.sender];
        if (info.pendingRewards == 0) revert NoRewardsError();

        uint256 rewards = info.pendingRewards;
        info.pendingRewards = 0;
        info.lastClaimPeriod = currentPeriodId;

        IERC20(wton).safeTransfer(msg.sender, rewards);

        emit ValidatorRewardClaimed(msg.sender, rewards);
    }

    // ==========================================
    // Governance Functions
    // ==========================================

    /// @inheritdoc IValidatorPool
    function setSlashingPenalty(uint256 penalty) external onlyOwner {
        slashingPenalty = penalty;
    }

    /// @inheritdoc IValidatorPool
    function setMinimumThreshold(uint256 threshold) external onlyOwner {
        minimumThreshold = threshold;
    }

    /// @inheritdoc IValidatorPool
    function setRatProbability(uint256 probability) external onlyOwner {
        if (probability > RAY) revert InvalidParameterError();
        ratProbability = probability;
    }

    /// @inheritdoc IValidatorPool
    function setRatResponseWindow(uint256 window) external onlyOwner {
        ratResponseWindow = window;
    }

    /// @inheritdoc IValidatorPool
    function setMinimumValidatorDeposit(uint256 amount) external onlyOwner {
        minimumValidatorDeposit = amount;
    }

    /// @notice RAT 발행자 설정
    function setRatIssuer(address issuer) external onlyOwner {
        ratIssuer = issuer;
    }

    /// @notice Attention Cost 설정 (c_m)
    function setAttentionCost(uint256 cost) external onlyOwner {
        attentionCost = cost;
    }

    /// @notice 검증자 버퍼 설정 (Δ_validator)
    function setValidatorBuffer(uint256 buffer) external onlyOwner {
        validatorBuffer = buffer;
    }

    /// @notice Owner 변경
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        owner = newOwner;
    }

    /// @notice SeigManager 설정
    function setSeigManager(address _seigManager) external onlyOwner {
        seigManager = _seigManager;
    }

    // ==========================================
    // Emergency Functions
    // ==========================================

    /// @notice 비상 출금 (Owner 전용)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner, amount);
    }
}
