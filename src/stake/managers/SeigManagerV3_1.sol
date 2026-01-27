// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FullMath} from "../../libraries/FullMath.sol";
import {DSMath} from "../../libraries/DSMath.sol";

import {RefactorCoinageSnapshotI} from "../interfaces/RefactorCoinageSnapshotI.sol";
import {IWTON} from "../../dao/interfaces/IWTON.sol";
import {Layer2I} from "../../dao/interfaces/Layer2I.sol";
import {ICandidate} from "../../dao/interfaces/ICandidate.sol";
import {IL1BridgeRegistry} from "../../layer2/interfaces/IL1BridgeRegistry.sol";
import {ILayer2Manager} from "../../layer2/interfaces/ILayer2Manager.sol";
import {ISeigManagerV3} from "../interfaces/ISeigManagerV3.sol";
import {IValidatorReward} from "../../validator/IValidatorReward.sol";
import {IRAT} from "../../validator/IRAT.sol";
import {ITON} from "../interfaces/ITON.sol";

import {ProxyStorage} from "../../proxy/ProxyStorage.sol";
import {AuthControlSeigManager} from "../../common/AuthControlSeigManager.sol";
import {SeigManagerStorage} from "./SeigManagerStorage.sol";
import {SeigManagerV1_1Storage} from "./SeigManagerV1_1Storage.sol";
import {SeigManagerV1_3Storage} from "./SeigManagerV1_3Storage.sol";
import {SeigManagerV1_4Storage} from "./SeigManagerV1_4Storage.sol";

// Custom Errors
error LastSeigBlockError();
error MinimumAmountError();
error UpdateSeigniorageError();
error IncreaseTotError();
error InvalidCoinageError();
error OnlyLayer2ManagerError();
error OnlyL1BridgeOrRegistryError();
error OnlyDepositManagerError();
error InvalidParameterError();
error AlreadyMigratedError();
error NotMigratedError();
error ZeroAddressError();
error V3ParametersNotSetError();
error PausedError();
error AlreadyExcludedError();
error NotExcludedError();
error NotAllowedError();
error OnlyRatError();
error InsufficientBalanceError();
error OperatorMinAmountError();
error ValidatorMinCollateralError();
error V2DelegatecallFailedError();

/**
 * @title SeigManagerV3_1
 * @notice TON Staking V3 시뇨리지 분배 컨트랙트
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 *      V2 로직은 SeigManagerV3_2로 분리되어 delegatecall로 호출
 */
contract SeigManagerV3_1 is
    ProxyStorage,
    AuthControlSeigManager,
    SeigManagerStorage,
    SeigManagerV1_1Storage,
    DSMath,
    SeigManagerV1_3Storage,
    SeigManagerV1_4Storage,
    ISeigManagerV3
{
    uint256 internal constant WEI_UNIT = 1e18;
    uint256 internal constant GWEI_UNIT = 1e9;
    uint256 internal constant RAY_UNIT = 1e27;

    // ==========================================
    // Modifiers
    // ==========================================

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    function _whenNotPaused() internal view {
        if (paused) revert PausedError();
    }

    modifier onlyL1BridgeOrRegistry() {
        _onlyL1BridgeOrRegistry();
        _;
    }

    function _onlyL1BridgeOrRegistry() internal view {
        if (msg.sender != l1BridgeRegistry) revert OnlyL1BridgeOrRegistryError();
    }

    modifier onlyDepositManager() {
        _onlyDepositManager();
        _;
    }

    function _onlyDepositManager() internal view {
        if (msg.sender != address(_depositManager)) revert OnlyDepositManagerError();
    }

    modifier whenV3Active() {
        _whenV3Active();
        _;
    }

    function _whenV3Active() internal view {
        if (!v3Migrated) revert NotMigratedError();
    }

    modifier whenPaused() {
        _whenPaused();
        _;
    }

    function _whenPaused() internal view {
        require(paused, "Pausable: not paused");
    }

    // ==========================================
    // Events
    // ==========================================

    event Comitted(address indexed layer2);

    event CommitLog1(
        uint256 totalStakedAmount,
        uint256 totalSupplyOfWton,
        uint256 prevTotalSupply,
        uint256 nextTotalSupply
    );

    event SeigGiven2(
        address indexed layer2,
        uint256 totalSeig,
        uint256 stakedSeig,
        uint256 unstakedSeig,
        uint256 powertonSeig,
        uint256 daoSeig,
        uint256 pseig,
        uint256 l2TotalSeigs,
        uint256 layer2Seigs
    );

    event ExcludedFromL2Seigniorage(address layer2);
    event IncludedFromL2Seigniorage(address layer2);
    event UnstakeLog(uint256 coinageBurnAmount, uint256 totBurnAmount);
    event Paused(address account);
    event Unpaused(address account);
    event AutoClaimBeforeEligibilityLoss(address indexed layer2, uint256 sequencerReward, uint256 validatorReward);
    event ClaimL2Seigniorage(address indexed layer2, uint256 sequencerReward, uint256 validatorReward);

    // ==========================================
    // V2 Logic Contract Setup
    // ==========================================

    /// @notice V2 로직 컨트랙트 주소 설정
    /// @param _v2Logic SeigManagerV3_2 컨트랙트 주소
    function setV2Logic(address _v2Logic) external onlyOwner {
        if (_v2Logic == address(0)) revert ZeroAddressError();
        v2Logic = _v2Logic;
    }

    // ==========================================
    // Governance Functions - V3 Parameters
    // ==========================================

    function setDaoDistributionRatio(uint256 ratio) external onlyOwner {
        if (ratio >= RAY) revert InvalidParameterError();
        daoDistributionRatio = ratio;
        emit DaoDistributionRatioUpdated(ratio);
    }

    function setMinStakingRatio(uint256 ratio) external onlyOwner {
        if (ratio > RAY) revert InvalidParameterError();
        minStakingRatio = ratio;
        emit MinStakingRatioUpdated(ratio);
    }

    function setValidatorDistributionRatio(uint256 ratio) external onlyOwner {
        if (ratio >= RAY) revert InvalidParameterError();
        validatorDistributionRatio = ratio;
        emit ValidatorDistributionRatioUpdated(ratio);
    }

    function setHalfSaturationPoint(uint256 k) external onlyOwner {
        if (k == 0) revert InvalidParameterError();
        halfSaturationPoint = k;
        emit HalfSaturationPointUpdated(k);
    }

    function setValidatorReward(address reward) external onlyOwner {
        if (reward == address(0)) revert ZeroAddressError();
        validatorReward = reward;
        emit ValidatorRewardUpdated(reward);
    }

    function setMaxChallengers(uint256 hMax) external onlyOwner {
        maxChallengers = hMax;
    }

    function setMaxFraudProofCost(uint256 cMax) external onlyOwner {
        maxFraudProofCost = cMax;
    }

    function setSequencerAdditionalReward(uint256 delta) external onlyOwner {
        sequencerAdditionalReward = delta;
    }

    // ==========================================
    // Pausable Functions
    // ==========================================

    function pause() external onlyPauser whenNotPaused {
        if (v3Migrated) {
            // V3: pause 블록까지 시뇨리지 자동 발행
            // - _triggerSeigniorageDistribution 내에서 _lastSeigBlock = block.number 설정됨
            _triggerSeigniorageDistribution();
        } else {
            // V2: 수동 updateSeigniorage 필요 (기존 조건 유지)
            require(_pausedBlock < _lastSeigBlock, "updateSeigniorage required");
        }
        // pause 기간은 다음 블록부터 시작 (현재 블록은 시뇨리지 발행됨)
        // - 예: block.number=110에서 pause → _pausedBlock=111
        // - pause 기간 = _unpausedBlock - _pausedBlock = 200 - 111 = 89블록 (111~199)
        _pausedBlock = block.number + 1;
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyPauser whenPaused {
        _unpausedBlock = block.number;
        paused = false;
        emit Unpaused(msg.sender);
    }

    // ==========================================
    // L2 Seigniorage Control Functions
    // ==========================================

    function excludeFromL2Seigniorage(address layer2) external returns (bool) {
        _onlyLayer2Manager();
        _excludeLayer2FromSeigniorage(layer2);
        emit ExcludedFromL2Seigniorage(layer2);
        return true;
    }

    function includeFromL2Seigniorage(address layer2) external returns (bool) {
        _onlyLayer2Manager();
        _includeLayer2ToSeigniorage(layer2);
        require(!_isExcludedFromSeigniorage(layer2), "error includeFromL2Seigniorage");
        emit IncludedFromL2Seigniorage(layer2);
        return true;
    }

    /// @notice pause 상태에서도 미청구 보상을 claim할 수 있는 함수
    /// @dev 시뇨리지 발행 없이 기존 발행분만 claim
    /// @param layer2 claim할 L2 주소
    /// @return layer2Seigs sequencer 보상
    /// @return valReward validator 보상
    function claimL2Seigniorage(address layer2) external ifFree returns (uint256 layer2Seigs, uint256 valReward) {
        if (!v3Migrated) revert NotMigratedError();

        (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(layer2);
        if (!allowed || _isExcludedFromSeigniorage(layer2)) return (0, 0);

        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        if (!info.isEligible || info.effectiveBridgedTON == 0) return (0, 0);

        uint256 _effectiveBridged = info.effectiveBridgedTON;
        uint256 _seqRewardPerUnit = bridgedTONRewardPerUint;
        uint256 _valRewardPerUnit = validatorRewardPerUint;

        // Sequencer 보상
        uint256 seqAccumulated = (_seqRewardPerUnit * _effectiveBridged) / WEI_UNIT;
        layer2Seigs = seqAccumulated - info.initialDebt;

        // Validator 보상
        uint256 valAccumulated = (_valRewardPerUnit * _effectiveBridged) / WEI_UNIT;
        valReward = valAccumulated - info.validatorInitialDebt;

        // Sequencer 보상 transfer
        if (layer2Seigs > 0) {
            ILayer2Manager(layer2Manager).transferL2Seigniorage(layer2, layer2Seigs);
        }

        // Validator 보상 분배
        if (valReward > 0 && validatorReward != address(0)) {
            IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
        }

        // initialDebt 업데이트 (중복 claim 방지)
        info.initialDebt = seqAccumulated;
        info.validatorInitialDebt = valAccumulated;

        emit ClaimL2Seigniorage(layer2, layer2Seigs, valReward);
    }

    function _onlyLayer2Manager() internal view {
        if (msg.sender != layer2Manager) revert OnlyLayer2ManagerError();
    }

    // ==========================================
    // External Functions - Callbacks (V3)
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    function onBridgedTonChange() external {
        if (!v3Migrated) return;

        address rollupConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithPortal(msg.sender);
        if (rollupConfig == address(0)) return;

        address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(rollupConfig);
        if (layer2 == address(0)) return;

        // rollupType 체크는 _checkEligibilityInternal에서 수행
        _updateEligibilityInternal(layer2);
    }

    /// @inheritdoc ISeigManagerV3
    function onStakingChange(address layer2) external onlyDepositManager {
        if (!v3Migrated) return;
        _updateEligibilityInternal(layer2);
    }

    function _updateEligibilityInternal(address layer2) internal {
        // rollupType 3만 V3 eligibility 적용 - 먼저 체크해서 early return
        if (l1BridgeRegistry != address(0) && layer2Manager != address(0)) {
            (address rollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
            if (rollupConfig != address(0)) {
                uint8 rollupType = IL1BridgeRegistry(l1BridgeRegistry).rollupType(rollupConfig);
                if (rollupType != uint8(IL1BridgeRegistry.TYPE_ROLLUPCONFIG.OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)) return;
            }
        }

        SeigManagerV1_4Storage.BridgedTONInfo storage info = bridgedTONInfo[layer2];
        bool oldEligible = info.isEligible;

        // Layer2Manager에서 현재 bridgedTON 한 번만 읽기 (TON → WTON 변환: * GWEI_UNIT)
        uint256 bridgedTon = ILayer2Manager(layer2Manager).getBridgedTonByLayer(layer2);
        uint256 currentBridgedTON = bridgedTon * GWEI_UNIT;

        // 내부 자격 체크 (bridgedTon 재사용, external call 절약)
        bool newEligible = _checkEligibilityInternal(layer2, bridgedTon);

        // Case 1: Eligibility unchanged - storage 변경 없이 return
        // - 시뇨리지 정산 없이 currentBridgedTON을 변경하면 다음 updateSeigniorage에서
        //   _syncEffectiveBridgedTon 호출 시 effectiveBridgedTON이 변경되어 공정하지 않음
        // - effectiveBridgedTON 업데이트는 updateSeigniorage 시점에 _syncEffectiveBridgedTon으로 처리
        if (oldEligible == newEligible) {
            return;
        }

        // Case 2: Eligibility changed
        info.currentBridgedTON = currentBridgedTON;

        // 자격 변경 전 시뇨리지 정산 (rewardPerUnit 최신화)
        _triggerSeigniorageDistribution();

        if (oldEligible && !newEligible) {
            // 자격 상실: 미청구 보상 자동 claim + effectiveBridgedTON 초기화
            _handleEligibilityLoss(layer2);
        } else {
            // 자격 획득: effectiveBridgedTON 설정 + initialDebt 설정
            // (bridgedTON = 0이면 _checkEligibilityInternal에서 eligible = false이므로 여기 도달 불가)
            info.effectiveBridgedTON = currentBridgedTON;
            totalEffectiveBridgedTON += info.effectiveBridgedTON;
            info.initialDebt = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
            info.validatorInitialDebt = (validatorRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
        }

        info.isEligible = newEligible;
        emit EligibilityChanged(layer2, newEligible, currentBridgedTON, info.effectiveBridgedTON);
    }

    // ==========================================
    // View Functions (V3)
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    function getEffectiveBridgedTon(address layer2) external view returns (uint256) {
        return bridgedTONInfo[layer2].effectiveBridgedTON;
    }

    /// @inheritdoc ISeigManagerV3
    function checkCurrentEligibility(address layer2)
        public
        view
        returns (bool eligible, uint256 requiredStake, uint256 currentStake)
    {
        currentStake = getSequencerStaked(layer2);

        if (!v3Migrated) {
            return (false, 0, currentStake);
        }

        // non-Type-3 롤업은 V3 시뇨리지 자격 없음
        if (!_isType3Layer2(layer2)) {
            return (false, 0, currentStake);
        }

        uint256 bridgedTon = ILayer2Manager(layer2Manager).getBridgedTonByLayer(layer2);
        if (bridgedTon == 0) {
            return (false, 0, currentStake);
        }

        requiredStake = _calculateRequiredStake(bridgedTon);
        eligible = currentStake >= requiredStake;
    }

    /// @dev 내부용 자격 체크 (bridgedTon 파라미터로 받아 중복 external call 방지)
    /// @param layer2 L2 주소
    /// @param bridgedTon 이미 조회된 bridgedTon 값 (TON 단위)
    /// @return eligible 자격 여부
    function _checkEligibilityInternal(address layer2, uint256 bridgedTon) internal view returns (bool eligible) {
        // rollupType 체크는 _updateEligibilityInternal에서 먼저 수행됨
        if (bridgedTon == 0) return false;

        uint256 currentStake = getSequencerStaked(layer2);
        uint256 requiredStake = _calculateRequiredStake(bridgedTon);

        eligible = currentStake >= requiredStake;
    }

    /// @dev 필요 스테이킹량 계산 (bridgedTon 기반)
    /// @param bridgedTon bridgedTon 값 (TON 단위)
    /// @return requiredStake 필요 스테이킹량 (WTON 단위)
    function _calculateRequiredStake(uint256 bridgedTon) internal view returns (uint256 requiredStake) {
        if (bridgedTon == 0) return 0;

        uint256 minForSeigniorage = (bridgedTon * GWEI_UNIT * minStakingRatio) / RAY_UNIT;
        uint256 minForFraudProof = maxChallengers * maxFraudProofCost + sequencerAdditionalReward;
        requiredStake = minForSeigniorage > minForFraudProof ? minForSeigniorage : minForFraudProof;
    }

    /// @dev 내부용 필요 스테이킹량 조회 (rollupType 체크 + bridgedTon 조회 포함)
    /// @param layer2 L2 주소
    /// @return requiredStake 필요 스테이킹량 (WTON 단위)
    function _getRequiredStakeInternal(address layer2) internal view returns (uint256 requiredStake) {
        // rollupType 3만 V3 eligibility 적용 (non-Type-3는 0 리턴 → 최소 요구량 없음)
        if (l1BridgeRegistry != address(0) && layer2Manager != address(0)) {
            (address rollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
            if (rollupConfig != address(0)) {
                uint8 rollupType = IL1BridgeRegistry(l1BridgeRegistry).rollupType(rollupConfig);
                if (rollupType != uint8(IL1BridgeRegistry.TYPE_ROLLUPCONFIG.OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)) return 0;
            }
        }

        uint256 bridgedTon = ILayer2Manager(layer2Manager).getBridgedTonByLayer(layer2);
        requiredStake = _calculateRequiredStake(bridgedTon);
    }

    /// @dev Type 3 롤업인지 확인
    function _isType3Layer2(address layer2) internal view returns (bool) {
        if (l1BridgeRegistry == address(0) || layer2Manager == address(0)) return false;
        (address rollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        if (rollupConfig == address(0)) return false;
        uint8 rollupType = IL1BridgeRegistry(l1BridgeRegistry).rollupType(rollupConfig);
        return rollupType == uint8(IL1BridgeRegistry.TYPE_ROLLUPCONFIG.OPTIMISM_BEDROCK_WITH_DISPUTE_GAME);
    }

    /// @inheritdoc ISeigManagerV3
    function getSequencerStaked(address layer2) public view returns (uint256) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        if (address(coinage) == address(0)) return 0;

        address operator = Layer2I(layer2).operator();
        if (operator == address(0)) return 0;

        return coinage.balanceOf(operator);
    }

    /// @inheritdoc ISeigManagerV3
    function hyperbolicSaturation(uint256 x, uint256 maxL2Allocation) public view returns (uint256 y) {
        if (x == 0) return 0;
        uint256 numerator = maxL2Allocation * x;
        uint256 denominator = halfSaturationPoint + x;
        y = numerator / denominator;
    }

    /// @inheritdoc ISeigManagerV3
    function calculateL2Seigniorage(address layer2, uint256 totalY, uint256 totalX) public view returns (uint256 seigniorage) {
        if (totalX == 0) return 0;
        uint256 effectiveBridged = bridgedTONInfo[layer2].effectiveBridgedTON;
        if (effectiveBridged == 0) return 0;
        seigniorage = (totalY * effectiveBridged) / totalX;
    }

    /// @inheritdoc ISeigManagerV3
    function calculateSequencerReward(uint256 l2Seigniorage) public view returns (uint256) {
        return (l2Seigniorage * (RAY_UNIT - validatorDistributionRatio)) / RAY_UNIT;
    }

    /// @inheritdoc ISeigManagerV3
    function estimateL2Seigniorage(address layer2) public view returns (uint256 sequencerReward, uint256 validatorReward) {
        if (!v3Migrated) return (0, 0);

        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        if (!info.isEligible || info.effectiveBridgedTON == 0) return (0, 0);
        if (totalEffectiveBridgedTON == 0) return (0, 0);

        // 1. 이미 누적된 미청구 보상 (rewardPerUnit × effectiveBridgedTON - initialDebt)
        uint256 accumulatedSeq = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.initialDebt;
        uint256 accumulatedVal = (validatorRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.validatorInitialDebt;

        // 2. 새로운 시뇨리지 (_lastSeigBlock 이후 블록분)
        uint256 blockDelta = block.number - _lastSeigBlock;
        if (blockDelta > 0) {
            uint256 A = blockDelta * _seigPerBlock;
            uint256 sDao = (A * daoDistributionRatio) / RAY_UNIT;
            uint256 L = A - sDao;
            uint256 y = hyperbolicSaturation(totalEffectiveBridgedTON, L);

            // 이 L2의 지분
            uint256 l2Share = (y * info.effectiveBridgedTON) / totalEffectiveBridgedTON;

            // sequencer/validator 분배
            uint256 newSeq = (l2Share * (RAY_UNIT - validatorDistributionRatio)) / RAY_UNIT;
            uint256 newVal = l2Share - newSeq;

            accumulatedSeq += newSeq;
            accumulatedVal += newVal;
        }

        return (accumulatedSeq, accumulatedVal);
    }

    /// @notice 시뇨리지 추정 (V2/V3 분기)
    /// @dev V3: 모두 0 반환 (V3는 estimateL2Seigniorage 사용)
    ///      V2: delegatecall로 SeigManagerV3_2.estimatedDistributeV2 호출
    function estimatedDistribute(
        uint256 blockNumber,
        address layer2
    )
        external
        view
        returns (
            uint256 maxSeig,
            uint256 stakedSeig,
            uint256 unstakedSeig,
            uint256 powertonSeig,
            uint256 daoSeig,
            uint256 relativeSeig,
            uint256 l2TotalSeigs,
            uint256 layer2Seigs
        )
    {
        // V3 모드에서는 0 반환 (V3는 estimateL2Seigniorage 사용)
        if (v3Migrated) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }

        // V2 모드: staticcall로 V3_2의 추정 함수 호출
        (bool success, bytes memory result) = v2Logic.staticcall(
            abi.encodeWithSignature("estimatedDistributeV2(uint256,address)", blockNumber, layer2)
        );

        if (!success) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }

        return abi.decode(result, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));
    }

    /// @notice 청구 가능 L2 시뇨리지 (V2/V3 분기)
    /// @dev V3: estimateL2Seigniorage의 시퀀서 보상만 반환 (누적 미청구 + 새 시뇨리지)
    ///      V2: staticcall로 SeigManagerV3_2.claimableL2SeigniorageV2 호출
    function claimableL2Seigniorage(address layer2) external view returns (uint256 amount) {
        // V3 모드: 시퀀서 보상만 반환 (검증자 보상 제외)
        if (v3Migrated) {
            (uint256 seqReward, ) = estimateL2Seigniorage(layer2);
            return seqReward;
        }

        // V2 모드: staticcall로 V3_2의 청구 가능 함수 호출
        (bool success, bytes memory result) = v2Logic.staticcall(
            abi.encodeWithSignature("claimableL2SeigniorageV2(address)", layer2)
        );

        if (!success) {
            return 0;
        }

        return abi.decode(result, (uint256));
    }

    // ==========================================
    // External Functions - Seigniorage
    // ==========================================

    /// @notice 시뇨리지 분배 (V2/V3 분기)
    function updateSeigniorage() external returns (bool) {
        if (v3Migrated) {
            return _updateSeigniorageV3();
        } else {
            return _updateSeigniorageV2Delegatecall();
        }
    }

    /// @notice V2 시뇨리지 분배 (delegatecall로 V3_2 호출)
    function _updateSeigniorageV2Delegatecall() internal ifFree returns (bool) {
        (bool success, bytes memory result) = v2Logic.delegatecall(
            abi.encodeWithSignature("updateSeigniorageV2()")
        );

        if (!success) revert V2DelegatecallFailedError();
        return abi.decode(result, (bool));
    }

    function updateSeigniorageLayer(address layer2) external returns (bool) {
        if (!ICandidate(layer2).updateSeigniorage())
            revert UpdateSeigniorageError();
        return true;
    }

    // ==========================================
    // Migration Functions
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    function migrateToV3() external onlyOwner {
        if (v3Migrated) revert AlreadyMigratedError();

        if (halfSaturationPoint == 0) revert V3ParametersNotSetError();
        if (minStakingRatio == 0) revert V3ParametersNotSetError();
        if (daoDistributionRatio >= RAY_UNIT) revert V3ParametersNotSetError();
        if (minStakingRatio > RAY_UNIT) revert V3ParametersNotSetError();
        if (validatorDistributionRatio >= RAY_UNIT) revert V3ParametersNotSetError();
        if (maxChallengers == 0 || maxFraudProofCost == 0) revert V3ParametersNotSetError();
        if (validatorDistributionRatio > 0 && validatorReward == address(0)) revert V3ParametersNotSetError();

        currentPeriodId = 1;
        periods[1].startBlock = block.number;

        v3Migrated = true;
        v3MigrationBlock = block.number;

        emit V3MigrationCompleted(block.number, 0);
    }

    // ==========================================
    // Internal Functions - V3 Seigniorage
    // ==========================================

    function _updateSeigniorageV3() internal ifFree returns (bool) {
        if (paused) return true;

        RefactorCoinageSnapshotI coinage = _coinages[msg.sender];
        _checkCoinage(address(coinage));

        // 같은 블록에서 이미 seigniorage가 계산됐으면 claim만 수행
        // (다른 L2가 먼저 호출했을 때 이 L2도 자기 몫을 받을 수 있도록)
        if (block.number <= _lastSeigBlock) {
            _claimL2RewardsOnly();
            return true;
        }
        if (!_increaseTotV3()) revert IncreaseTotError();

        _lastCommitBlock[msg.sender] = block.number;

        emit Comitted(msg.sender);
        return true;
    }

    /// @dev 시뇨리지 계산 없이 보상만 claim (같은 블록에서 이미 계산된 경우)
    function _claimL2RewardsOnly() internal {
        _claimL2Rewards();
        _lastCommitBlock[msg.sender] = block.number;
        emit Comitted(msg.sender);
    }

    function _increaseTotV3() internal returns (bool) {
        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock)
            span -= (_unpausedBlock - _pausedBlock);

        uint256 A = span * _seigPerBlock;
        uint256 prevTotalSupply = _tot.totalSupply();
        _lastSeigBlock = block.number;

        emit CommitLog1(_tot.totalSupply(), _totalSupplyOfTon(block.number), prevTotalSupply, prevTotalSupply);

        uint256 l2TotalSeigs = 0;
        uint256 layer2Seigs = 0;

        if (A > 0) {
            (l2TotalSeigs, layer2Seigs) = _distributeV3Seigniorage(A);
        }

        emit SeigGiven2(msg.sender, A, 0, 0, 0, 0, 0, l2TotalSeigs, layer2Seigs);
        return true;
    }

    function _distributeV3Seigniorage(uint256 a2) internal returns (uint256 l2TotalSeigs, uint256 layer2Seigs) {
        uint256 sDao = (a2 * daoDistributionRatio) / RAY_UNIT;
        uint256 L = a2 - sDao;

        // 캐시: totalEffectiveBridgedTON (3회 SLOAD → 1회)
        uint256 _totalEffective = totalEffectiveBridgedTON;

        if (_totalEffective > 0) {
            uint256 y = (L * _totalEffective) / (halfSaturationPoint + _totalEffective);
            l2TotalSeigs = y;

            // Sequencer/Validator 분리
            uint256 totalValReward = (y * validatorDistributionRatio) / RAY_UNIT;
            uint256 totalSeqReward = y - totalValReward;

            // Sequencer 보상: layer2Manager로 mint (전체 L2 합계)
            if (totalSeqReward > 0) {
                IWTON(_wton).mint(layer2Manager, totalSeqReward);
            }

            // Validator 보상: validatorReward로 mint (전체 L2 합계)
            if (totalValReward > 0 && validatorReward != address(0)) {
                IWTON(_wton).mint(validatorReward, totalValReward);
            }

            // rewardPerUint 분리 업데이트: Sequencer와 Validator 각각
            bridgedTONRewardPerUint += (totalSeqReward * WEI_UNIT) / _totalEffective;
            validatorRewardPerUint += (totalValReward * WEI_UNIT) / _totalEffective;

            // 호출한 L2의 보상 claim
            layer2Seigs = _claimL2Rewards();

            _mintDaoReward(sDao, L, y);
            emit V3SeigniorageDistributed(a2, L, y, sDao + (L - y), 0);
        } else {
            _mintDaoReward(sDao, L, 0);
            emit V3SeigniorageDistributed(a2, L, 0, sDao + L, 0);
        }
    }

    /// @dev 호출한 L2의 보상을 debt 공식으로 claim
    /// @return layer2Seigs 호출 L2의 sequencer 보상
    function _claimL2Rewards() internal returns (uint256 layer2Seigs) {
        address rollupConfig;
        bool allowed;
        (rollupConfig, allowed) = _allowIssuanceLayer2Seigs(msg.sender);

        if (!allowed || _isExcludedFromSeigniorage(msg.sender)) return 0;

        _syncEffectiveBridgedTon(msg.sender);

        BridgedTONInfo storage info = bridgedTONInfo[msg.sender];
        if (!info.isEligible || info.effectiveBridgedTON == 0) return 0;

        // 캐시: 스토리지 변수들 (여러 번 SLOAD → 1회)
        uint256 _effectiveBridged = info.effectiveBridgedTON;
        uint256 _seqRewardPerUnit = bridgedTONRewardPerUint;
        uint256 _valRewardPerUnit = validatorRewardPerUint;

        // Sequencer 보상: bridgedTONRewardPerUint 기반 (분리됨)
        uint256 seqAccumulated = (_seqRewardPerUnit * _effectiveBridged) / WEI_UNIT;
        layer2Seigs = seqAccumulated - info.initialDebt;

        // Validator 보상: validatorRewardPerUint 기반 (분리됨)
        uint256 valAccumulated = (_valRewardPerUnit * _effectiveBridged) / WEI_UNIT;
        uint256 valReward = valAccumulated - info.validatorInitialDebt;

        // Sequencer 보상 transfer (이미 layer2Manager에 mint됨)
        if (layer2Seigs > 0) {
            ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
        }

        // Validator 보상 분배 (이미 validatorReward에 mint됨)
        if (valReward > 0 && validatorReward != address(0)) {
            IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
        }

        // initialDebt 업데이트 (다음 claim 시 중복 방지) - 캐시된 accumulated 값 재사용
        info.initialDebt = seqAccumulated;
        info.validatorInitialDebt = valAccumulated;
    }

    /// @dev 자격 상실 처리: 미청구 보상 자동 claim + effectiveBridgedTON 초기화
    /// @param layer2 자격을 상실하는 L2 주소
    function _handleEligibilityLoss(address layer2) internal {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];

        uint256 layer2Seigs = 0;
        uint256 valReward = 0;

        // 캐시: effectiveBridgedTON (여러 번 SLOAD → 1회)
        uint256 _effectiveBridged = info.effectiveBridgedTON;

        // effectiveBridgedTON > 0인 경우에만 처리 (이미 일시정지로 0인 경우 스킵)
        // allowed 체크 불필요:
        // - allowed=false가 되려면 Layer2Manager.statusLayer2() != 1 이어야 함
        // - status=2가 되는 유일한 경로: Layer2Manager.pauseCandidateAddOn()
        // - pauseCandidateAddOn()은 excludeFromL2Seigniorage()를 먼저 호출 → effectiveBridgedTON=0
        // - 따라서 effectiveBridgedTON > 0이면 status=1 (allowed=true) 보장됨
        if (_effectiveBridged > 0) {
            // rollupConfig 조회 (distributeL2Rewards에 필요)
            (address rollupConfig, ) = _allowIssuanceLayer2Seigs(layer2);

            // Sequencer 보상: bridgedTONRewardPerUint 기반
            layer2Seigs = (bridgedTONRewardPerUint * _effectiveBridged) / WEI_UNIT - info.initialDebt;

            // Validator 보상: validatorRewardPerUint 기반
            valReward = (validatorRewardPerUint * _effectiveBridged) / WEI_UNIT - info.validatorInitialDebt;

            // Sequencer 보상 transfer
            if (layer2Seigs > 0) {
                ILayer2Manager(layer2Manager).transferL2Seigniorage(layer2, layer2Seigs);
            }

            // Validator 보상 분배
            if (valReward > 0 && validatorReward != address(0)) {
                IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
            }

            // effectiveBridgedTON 초기화
            totalEffectiveBridgedTON -= _effectiveBridged;
            info.effectiveBridgedTON = 0;
        }

        emit AutoClaimBeforeEligibilityLoss(layer2, layer2Seigs, valReward);
    }

    /// @dev 자격 변경 전 시뇨리지 분배 트리거 (claim 없이 rewardPerUnit만 업데이트)
    /// @notice 새 L2가 분배 비율에 영향을 주기 전에 기존 L2들에게 먼저 분배
    function _triggerSeigniorageDistribution() internal {
        // paused 상태면 스킵
        if (paused) return;

        // 같은 블록이면 이미 분배됨
        if (block.number <= _lastSeigBlock) return;

        // tot가 없으면 스킵
        if (address(_tot) == address(0)) return;
        if (_tot.totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return;
        }

        // 전역 시뇨리지 분배 (claim 없이)
        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock) {
            span -= (_unpausedBlock - _pausedBlock);
        }

        uint256 A = span * _seigPerBlock;
        _lastSeigBlock = block.number;

        // 캐시: totalEffectiveBridgedTON (4회 SLOAD → 1회)
        uint256 _totalEffective = totalEffectiveBridgedTON;

        if (A > 0 && _totalEffective > 0) {
            // rewardPerUnit 업데이트를 위한 y 계산
            uint256 sDao = (A * daoDistributionRatio) / RAY_UNIT;
            uint256 L = A - sDao;
            uint256 y = (L * _totalEffective) / (halfSaturationPoint + _totalEffective);

            // 시퀀서/검증자 분배
            uint256 seqTotal = (y * (RAY_UNIT - validatorDistributionRatio)) / RAY_UNIT;
            uint256 valTotal = y - seqTotal;

            // rewardPerUnit 업데이트
            bridgedTONRewardPerUint += (seqTotal * WEI_UNIT) / _totalEffective;
            validatorRewardPerUint += (valTotal * WEI_UNIT) / _totalEffective;

            // WTON mint (Layer2Manager, ValidatorReward)
            if (seqTotal > 0) {
                IWTON(_wton).mint(layer2Manager, seqTotal);
            }
            if (valTotal > 0 && validatorReward != address(0)) {
                IWTON(_wton).mint(validatorReward, valTotal);
            }

            // DAO 보상 mint
            _mintDaoReward(sDao, L, y);
        }
    }

    function _mintDaoReward(uint256 sDao, uint256 L, uint256 y) internal {
        uint256 totalDao = sDao + (L - y);
        if (totalDao > 0 && dao != address(0)) {
            IWTON(_wton).mint(dao, totalDao);
        }
    }

    function _syncEffectiveBridgedTon(address layer2) internal {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        uint256 oldEffective = info.effectiveBridgedTON;
        uint256 newEffective = info.isEligible ? info.currentBridgedTON : 0;

        if (newEffective != oldEffective) {
            info.effectiveBridgedTON = newEffective;
            totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;
        }
    }

    // ==========================================
    // Internal Helper Functions
    // ==========================================

    function _checkCoinage(address coinage_) internal pure {
        if (coinage_ == address(0)) revert InvalidCoinageError();
    }

    function _totalSupplyOfTon(uint256 blockNumber) internal view returns (uint256 tos) {
        tos = (initialTotalSupply == 0 ? INITIAL_TOTAL_SUPPLY_MAINNET : initialTotalSupply) +
            (_seigPerBlock * (blockNumber - (seigStartBlock == 0 ? SEIG_START_MAINNET : seigStartBlock))) -
            (ITON(_ton).balanceOf(address(1)) * (10 ** 9)) -
            (burntAmountAtDAO == 0 ? BURNT_AMOUNT_MAINNET : burntAmountAtDAO);
    }

    function _isExcludedFromSeigniorage(address layer2) internal view returns (bool) {
        uint256[] memory pauseBlocks = layer2PauseBlocks[layer2];
        uint256 len = pauseBlocks.length;
        if (len == 0) return false;

        uint256 pauseBlock = pauseBlocks[len - 1];
        if (pauseBlock != 0 && layer2UnpauseBlocks[layer2][pauseBlock] == 0) return true;
        return false;
    }

    function _allowIssuanceLayer2Seigs(address layer2) internal view returns (address rollupConfig, bool allowed) {
        address tempRollupConfig;
        (tempRollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        rollupConfig = tempRollupConfig;
        if (ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1) allowed = true;
    }

    function _excludeLayer2FromSeigniorage(address layer2) internal {
        if (_isExcludedFromSeigniorage(layer2)) revert AlreadyExcludedError();

        if (!ICandidate(layer2).updateSeigniorage()) revert UpdateSeigniorageError();

        if (v3Migrated) {
            // V3: bridgedTONInfo만 처리
            SeigManagerV1_4Storage.BridgedTONInfo storage v3Info = bridgedTONInfo[layer2];
            uint256 oldEffective = v3Info.effectiveBridgedTON;
            v3Info.effectiveBridgedTON = 0;
            v3Info.isEligible = false;
            totalEffectiveBridgedTON -= oldEffective;
        } else {
            // V2: layer2RewardInfo만 처리
            Layer2Reward memory v2Info = layer2RewardInfo[layer2];
            totalLayer2TVL -= v2Info.layer2Tvl;
            v2Info.layer2Tvl = 0;
            layer2RewardInfo[layer2] = v2Info;
        }

        layer2PauseBlocks[layer2].push(block.number);
    }

    function _includeLayer2ToSeigniorage(address layer2) internal {
        bool allowed;
        (, allowed) = _allowIssuanceLayer2Seigs(layer2);
        if (!allowed) revert NotAllowedError();
        if (!_isExcludedFromSeigniorage(layer2)) revert NotExcludedError();

        uint256 lastIndex = layer2PauseBlocks[layer2].length - 1;
        layer2UnpauseBlocks[layer2][layer2PauseBlocks[layer2][lastIndex]] = block.number;

        if (v3Migrated) {
            // V3: bridgedTONInfo만 처리, 자격 재평가
            bridgedTONInfo[layer2].startBlock = 0;
            _updateEligibilityInternal(layer2);
        } else {
            // V2: layer2RewardInfo만 처리
            layer2RewardInfo[layer2].startBlock = 0;
        }

        if (!ICandidate(layer2).updateSeigniorage()) revert UpdateSeigniorageError();
    }

    // ==========================================
    // RAT Integration Functions
    // ==========================================

    modifier onlyRat() {
        _onlyRat();
        _;
    }

    function _onlyRat() internal view {
        if (msg.sender != ratContract) revert OnlyRatError();
    }

    function setRatContract(address rat) external onlyOwner {
        if (rat == address(0)) revert ZeroAddressError();
        ratContract = rat;
        emit RATContractUpdated(rat);
    }

    function transferCoinageToRat(address layer2, address validator, uint256 amount) external onlyRat whenV3Active {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));
        coinage.burnFrom(validator, amount);
        coinage.mint(ratContract, amount);
        emit CoinageTransferredForRAT(layer2, validator, ratContract, amount);
    }

    function transferCoinageFromRat(address layer2, address validator, uint256 amount) external onlyRat whenV3Active {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));
        coinage.burnFrom(ratContract, amount);
        coinage.mint(validator, amount);
        emit CoinageTransferredForRAT(layer2, ratContract, validator, amount);
    }

    function transferCoinageFromRatTo(address layer2, address recipient, uint256 amount) external onlyRat {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));
        coinage.burnFrom(ratContract, amount);
        coinage.mint(recipient, amount);
        emit CoinageTransferredForRAT(layer2, ratContract, recipient, amount);
    }

    // ==========================================
    // DepositManager Callbacks
    // ==========================================

    function onDeposit(address layer2, address account, uint256 amount) external onlyDepositManager returns (bool) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));

        if (_isOperator(layer2, account)) {
            uint256 newBalance = coinage.balanceOf(account) + amount;

            if (v3Migrated) {
                uint256 requiredStake = _getRequiredStakeInternal(layer2);
                if (newBalance < requiredStake) revert OperatorMinAmountError();
            } else {
                if (newBalance < minimumAmount) revert MinimumAmountError();
            }
        }

        _tot.mint(layer2, amount);
        coinage.mint(account, amount);

        if (v3Migrated) {
            _updateEligibilityInternal(layer2);
        }

        return true;
    }

    function onWithdraw(address layer2, address account, uint256 amount) external onlyDepositManager returns (bool) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));

        uint256 balance = coinage.balanceOf(account);
        if (balance < amount) revert InsufficientBalanceError();

        uint256 newBalance = balance - amount;

        if (_isOperator(layer2, account)) {
            if (v3Migrated) {
                uint256 requiredStake = _getRequiredStakeInternal(layer2);
                if (newBalance < requiredStake) revert OperatorMinAmountError();
            } else {
                if (newBalance < minimumAmount) revert MinimumAmountError();
            }
        }

        if (v3Migrated && ratContract != address(0)) {
            uint256 validatorMin = IRAT(ratContract).getValidatorMinCollateralForLayer2(layer2, account);
            if (validatorMin > 0) {
                if (newBalance < validatorMin) revert ValidatorMinCollateralError();
            }
        }

        uint256 totAmount = _additionalTotBurnAmount(layer2, account, amount);
        _tot.burnFrom(layer2, amount + totAmount);
        coinage.burnFrom(account, amount);

        emit UnstakeLog(amount, totAmount);

        return true;
    }

    function _additionalTotBurnAmount(address layer2, address, uint256 amount) internal view returns (uint256) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        uint256 coinageTotalSupply = coinage.totalSupply();
        if (coinageTotalSupply == 0) return 0;

        uint256 totBalance = _tot.balanceOf(layer2);
        if (totBalance == 0) return 0;

        uint256 totExcess = totBalance > coinageTotalSupply ? totBalance - coinageTotalSupply : 0;
        return FullMath.mulDiv(totExcess, amount, coinageTotalSupply);
    }

    function _isOperator(address layer2, address account) internal view returns (bool) {
        try Layer2I(layer2).operator() returns (address op) {
            return op == account;
        } catch {
            return false;
        }
    }

    // ==========================================
    // Legacy View Functions (V2 Compatibility)
    // ==========================================

    /// @notice 특정 layer2에 대한 계정의 스테이킹 잔액 조회
    function stakeOf(address layer2, address account) external view returns (uint256) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        if (address(coinage) == address(0)) return 0;
        return coinage.balanceOf(account);
    }

    /// @notice 특정 layer2의 전체 스테이킹 총액 조회 (tot의 잔액)
    function stakeOfTotal(address layer2) external view returns (uint256) {
        return _tot.balanceOf(layer2);
    }

    /// @notice 특정 layer2 오퍼레이터의 스테이킹 금액 조회
    function getOperatorAmount(address layer2) external view returns (uint256) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        if (address(coinage) == address(0)) return 0;

        address operator = Layer2I(layer2).operator();
        if (operator == address(0)) return 0;

        return coinage.balanceOf(operator);
    }

    /// @notice layer2 보상 정보 조회
    function getLayer2RewardInfo(address layer2) external view returns (
        uint256 layer2Tvl,
        uint256 initialDebt,
        uint256 startBlock
    ) {
        Layer2Reward memory info = layer2RewardInfo[layer2];
        return (info.layer2Tvl, info.initialDebt, info.startBlock);
    }

    /// @notice Registry 주소 반환
    function registry() external view returns (address) {
        return _registry;
    }

    /// @notice DepositManager 주소 반환
    function depositManager() external view returns (address) {
        return _depositManager;
    }

    /// @notice TON 토큰 주소 반환
    function ton() external view returns (address) {
        return _ton;
    }

    /// @notice WTON 토큰 주소 반환
    function wton() external view returns (address) {
        return _wton;
    }

    /// @notice PowerTON 주소 반환
    function powerton() external view returns (address) {
        return _powerton;
    }

    /// @notice tot 컨트랙트 반환
    function tot() external view returns (address) {
        return address(_tot);
    }

    /// @notice layer2별 coinage 컨트랙트 반환
    function coinages(address layer2) external view returns (address) {
        return address(_coinages[layer2]);
    }

    /// @notice layer2별 커미션 비율 반환
    function commissionRates(address layer2) external view returns (uint256) {
        return _commissionRates[layer2];
    }

    /// @notice layer2별 커미션 비율 음수 여부 반환
    function isCommissionRateNegative(address layer2) external view returns (bool) {
        return _isCommissionRateNegative[layer2];
    }

    /// @notice layer2별 마지막 커밋 블록 반환
    function lastCommitBlock(address layer2) external view returns (uint256) {
        return _lastCommitBlock[layer2];
    }

    /// @notice 블록당 시뇨리지 양 반환
    function seigPerBlock() external view returns (uint256) {
        return _seigPerBlock;
    }

    /// @notice 마지막 시뇨리지 블록 반환
    function lastSeigBlock() external view returns (uint256) {
        return _lastSeigBlock;
    }

    /// @notice 일시정지 블록 반환
    function pausedBlock() external view returns (uint256) {
        return _pausedBlock;
    }

    /// @notice 재개 블록 반환
    function unpausedBlock() external view returns (uint256) {
        return _unpausedBlock;
    }


    /// @notice TON 총 공급량 조회
    function totalSupplyOfTon() external view returns (uint256) {
        return _totalSupplyOfTon(block.number);
    }
}
