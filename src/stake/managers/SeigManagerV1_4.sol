// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FullMath} from "../../libraries/FullMath.sol";
import {DSMath} from "../../libraries/DSMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RefactorCoinageSnapshotI} from "../interfaces/RefactorCoinageSnapshotI.sol";
import {IWTON} from "../../dao/interfaces/IWTON.sol";
import {Layer2I} from "../../dao/interfaces/Layer2I.sol";
import {ICandidate} from "../../dao/interfaces/ICandidate.sol";
import {ILayer2Registry} from "../../dao/interfaces/ILayer2Registry.sol";
import {ITON} from "../interfaces/ITON.sol";
import {IL1BridgeRegistry} from "../../layer2/interfaces/IL1BridgeRegistry.sol";
import {ILayer2Manager} from "../../layer2/interfaces/ILayer2Manager.sol";
import {ISeigManagerV3} from "../interfaces/ISeigManagerV3.sol";
import {IOptimismSystemConfig} from "../../layer2/interfaces/IOptimismSystemConfig.sol";
import {ISequencerVault} from "../../sequencer/ISequencerVault.sol";
import {IValidatorReward} from "../../validator/IValidatorReward.sol";
import {IRAT} from "../../validator/IRAT.sol";

import "../../proxy/ProxyStorage.sol";
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
error Layer2TvlError();
error OnlyL1BridgeOrRegistryError();
error OnlyDepositManagerError();
error InvalidParameterError();
error AlreadyMigratedError();
error NotMigratedError();
error ZeroAddressError();

/**
 * @title SeigManagerV1_4
 * @notice TON Staking V3 시뇨리지 분배 컨트랙트
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 *
 * V3 주요 변경사항:
 * 1. Bridged TON 기반 시뇨리지 분배
 * 2. 쌍곡선 포화 함수 적용
 * 3. 검증자 풀 분배
 * 4. 최소 스테이킹 조건
 */
contract SeigManagerV1_4 is
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
        require(!paused, "Pausable: paused");
        _;
    }

    modifier onlyL1BridgeOrRegistry() {
        if (msg.sender != l1BridgeRegistry) revert OnlyL1BridgeOrRegistryError();
        _;
    }

    modifier onlyDepositManager() {
        if (msg.sender != address(_depositManager)) revert OnlyDepositManagerError();
        _;
    }

    modifier whenV3Active() {
        if (!v3Migrated) revert NotMigratedError();
        _;
    }

    // ==========================================
    // Events (V3 신규)
    // ==========================================

    event SeigGiven(
        address indexed layer2,
        uint256 totalSeig,
        uint256 stakedSeig,
        uint256 unstakedSeig,
        uint256 powertonSeig,
        uint256 daoSeig,
        uint256 pseig
    );

    event Comitted(address indexed layer2);

    event AddedSeigAtLayer(
        address layer2,
        uint256 seigs,
        uint256 operatorSeigs,
        uint256 nextTotalSupply,
        uint256 prevTotalSupply
    );

    event CommitLog1(
        uint256 totalStakedAmount,
        uint256 totalSupplyOfWTON,
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
    event Paused(address account);

    /// @notice 시퀀서 슬래싱 이벤트
    event SequencerSlashed(
        address indexed layer2,
        address indexed sequencer,
        uint256 slashedAmount,
        uint256 challengerCount
    );

    /// @notice 언스테이크 이벤트
    event UnstakeLog(uint256 coinageBurnAmount, uint256 totBurnAmount);

    /// @notice 챌린저 보상 지급 이벤트
    event ChallengerRewarded(
        address indexed challenger,
        address indexed layer2,
        uint256 reward
    );

    /// @notice SequencerVault 주소 변경 이벤트
    /// @dev DEPRECATED: V3에서는 사용되지 않음
    event SequencerVaultUpdated(address indexed vault);

    /// @notice 시퀀서 추가 보상 변경 이벤트
    event SequencerAdditionalRewardUpdated(uint256 delta);

    // ==========================================
    // Governance Functions - V3 Parameters
    // ==========================================

    /// @notice DAO 분배 비율 설정
    /// @param ratio 새로운 비율 (RAY 단위, 0 < ratio < 1)
    function setDaoDistributionRatio(uint256 ratio) external onlyOwner {
        if (ratio >= RAY) revert InvalidParameterError();
        daoDistributionRatio = ratio;
        emit DaoDistributionRatioUpdated(ratio);
    }

    /// @notice 최소 스테이킹 비율 설정
    /// @param ratio 새로운 비율 (RAY 단위, 0 < ratio ≤ 1)
    function setMinStakingRatio(uint256 ratio) external onlyOwner {
        if (ratio > RAY) revert InvalidParameterError();
        minStakingRatio = ratio;
        emit MinStakingRatioUpdated(ratio);
    }

    /// @notice 검증자 분배 비율 설정
    /// @param ratio 새로운 비율 (RAY 단위, 0 < ratio < 1)
    function setValidatorDistributionRatio(uint256 ratio) external onlyOwner {
        if (ratio >= RAY) revert InvalidParameterError();
        validatorDistributionRatio = ratio;
        emit ValidatorDistributionRatioUpdated(ratio);
    }

    /// @notice 반포화점 설정
    /// @param k 새로운 반포화점 (RAY 단위)
    function setHalfSaturationPoint(uint256 k) external onlyOwner {
        if (k == 0) revert InvalidParameterError();
        halfSaturationPoint = k;
        emit HalfSaturationPointUpdated(k);
    }


    /// @notice 검증자 보상 컨트랙트 주소 설정
    function setValidatorReward(address reward) external onlyOwner {
        if (reward == address(0)) revert ZeroAddressError();
        validatorReward = reward;
        emit ValidatorRewardUpdated(reward);
    }

    /// @notice 지분 시뇨리지 비율 설정 (V2→V3 전환)
    /// @param lambda 새로운 비율 (RAY 단위, 0 ≤ lambda ≤ 1)
    /// @dev λ = 1.0: V2와 동일, λ = 0: 지분 시뇨리지 없음
    function setStakedSeigFactor(uint256 lambda) external onlyOwner {
        if (lambda > RAY) revert InvalidParameterError();
        stakedSeigFactor = lambda;
        emit StakedSeigFactorUpdated(lambda);
    }

    /// @notice 최대 챌린저 수 설정
    /// @param hMax 최대 동시 챌린저 수
    /// @dev 백서 공식 (1): D_sequencer = H_max · C_max + Δ_sequencer
    function setMaxChallengers(uint256 hMax) external onlyOwner {
        maxChallengers = hMax;
    }

    /// @notice 최대 fraud proof 비용 설정
    /// @param cMax 단일 fraud proof 예상 온체인 비용
    /// @dev 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
    function setMaxFraudProofCost(uint256 cMax) external onlyOwner {
        maxFraudProofCost = cMax;
    }

    /// @notice SequencerVault 컨트랙트 주소 설정
    /// @dev DEPRECATED: V3에서는 기존 스테이킹 시스템(coinage) 사용
    /// @dev 이 함수는 호환성을 위해 유지됨, V3에서는 사용되지 않음
    function setSequencerVault(address vault) external onlyOwner {
        if (vault == address(0)) revert ZeroAddressError();
        sequencerVault = vault;
        emit SequencerVaultUpdated(vault);
    }

    /// @notice 시퀀서 추가 보상 설정
    /// @param delta 추가 보상 (WTON 단위, 27 decimals)
    /// @dev 백서 공식 (1): D_sequencer = H_max · C_max + Δ_sequencer
    function setSequencerAdditionalReward(uint256 delta) external onlyOwner {
        sequencerAdditionalReward = delta;
        emit SequencerAdditionalRewardUpdated(delta);
    }


    // ==========================================
    // External Functions - Callbacks (V3 신규)
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    /// @notice L2의 Bridged TON 변경 시 호출 (타입 3 전용)
    /// @dev OptimismPortal에서 TON 입금/출금 시 SeigManager를 직접 호출
    ///      트리거 함수이므로 조건 불충족 시 revert 대신 early return
    function onBridgedTONChange()
        external
        whenV3Active
    {
        // 1. 호출자(포탈)로부터 rollupConfig 역방향 조회
        address rollupConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithPortal(msg.sender);
        if (rollupConfig == address(0)) return;

        // 2. 타입 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) 검증
        uint8 rollupType = IL1BridgeRegistry(l1BridgeRegistry).rollupType(rollupConfig);
        if (rollupType != 3) return;

        // 3. rollupConfig → layer2 변환
        address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(rollupConfig);
        if (layer2 == address(0)) return;

        // 4. 자격평가 및 effectiveBridgedTON 동기화
        _updateEligibilityInternal(layer2);
    }

    /// @inheritdoc ISeigManagerV3
    /// @notice 스테이킹 변경 시 L2 유효성 재평가
    /// @dev DepositManager에서 deposit/withdraw 후 호출
    function onStakingChange(address layer2)
        external
        onlyDepositManager
        whenV3Active
    {
        _updateEligibilityInternal(layer2);
    }

    /// @notice 자격 상태 업데이트 (내부 함수)
    /// @dev 외부 호출자는 이미 검증된 상태에서 호출
    function _updateEligibilityInternal(address layer2) internal {
        SeigManagerV1_4Storage.BridgedTONInfo storage info = bridgedTONInfo[layer2];
        bool oldEligible = info.isEligible;

        // 새로운 자격 상태 확인 (스택 깊이 문제 해결: 튜플 할당을 단계별로 분리)
        bool newEligible;
        (newEligible, , ) = checkCurrentEligibility(layer2);

        // 상태 변경 없으면 리턴
        if (oldEligible == newEligible) return;

        if (oldEligible && !newEligible) {
            // true → false: 자격 상실
            // effectiveBridgedTON 제거
            totalEffectiveBridgedTON -= info.effectiveBridgedTON;
            info.effectiveBridgedTON = 0;

        } else {
            // false → true: 자격 획득
            // 1. effectiveBridgedTON 설정
            info.effectiveBridgedTON = info.currentBridgedTON;
            totalEffectiveBridgedTON += info.effectiveBridgedTON;

            // 2. initialDebt 설정 (이 시점부터 수익 시작, 과거 소급 방지)
            info.initialDebt = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
        }

        info.isEligible = newEligible;
        emit EligibilityChanged(layer2, newEligible, info.currentBridgedTON, info.effectiveBridgedTON);
    }

    // ==========================================
    // View Functions (V3 신규)
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    function getEffectiveBridgedTON(address layer2) external view returns (uint256) {
        return bridgedTONInfo[layer2].effectiveBridgedTON;
    }

    /// @inheritdoc ISeigManagerV3
    /// @notice L2 시퀀서의 시뇨리지 수령 자격 실시간 확인
    /// @dev V3 백서 공식: S_i ≥ max(D_sequencer, θ·B_i)
    ///      - D_sequencer = H_max · C_max + Δ_sequencer (Fraud Proof 비용 커버)
    ///      - θ·B_i (시뇨리지 자격 조건)
    /// @dev S_i는 operator의 coinage 잔액 (기존 스테이킹)
    /// @param layer2 L2 주소
    /// @return eligible 시뇨리지 수령 자격 여부
    /// @return requiredStake 필요 담보금 (WTON, 27 decimals)
    /// @return currentStake 현재 시퀀서 담보금 (WTON, 27 decimals)
    function checkCurrentEligibility(address layer2)
        public
        view
        returns (bool eligible, uint256 requiredStake, uint256 currentStake)
    {
        // 1. B_i: L1 브리지에서 직접 조회 (TON 단위, 18 decimals)
        uint256 bridgedTON = ILayer2Manager(layer2Manager).getBridgedTONByLayer(layer2);

        // 2. θ·B_i 계산 (TON → WTON 변환: 9 decimals 추가)
        // bridgedTON은 18 decimals, minStakingRatio는 RAY(27 decimals)
        // 결과를 WTON(27 decimals)로 변환: bridgedTON * 1e9 * minStakingRatio / 1e27
        uint256 minForSeigniorage = (bridgedTON * GWEI_UNIT * minStakingRatio) / RAY_UNIT;

        // 3. D_sequencer = H_max · C_max + Δ_sequencer (Fraud Proof 비용 커버)
        // maxFraudProofCost, sequencerAdditionalReward는 WTON 단위(27 decimals)
        uint256 minForFraudProof = maxChallengers * maxFraudProofCost + sequencerAdditionalReward;

        // 4. requiredStake = max(θ·B_i, D_sequencer)
        requiredStake = minForSeigniorage > minForFraudProof ? minForSeigniorage : minForFraudProof;

        // 5. S_i: 시퀀서의 현재 담보금 (coinage에서 조회, WTON 27 decimals)
        currentStake = getSequencerStaked(layer2);

        // 6. S_i ≥ max(θ·B_i, D_sequencer)
        eligible = currentStake >= requiredStake;
    }

    /// @inheritdoc ISeigManagerV3
    /// @notice 시퀀서 담보금 조회
    /// @dev V3: 기존 스테이킹 시스템(coinage) 사용 - SequencerVault 미사용
    /// @dev operator의 해당 layer2 coinage 잔액을 담보금으로 사용
    /// @param layer2 L2 주소
    /// @return 시퀀서의 담보금 (WTON, 27 decimals - RAY 단위)
    function getSequencerStaked(address layer2) public view returns (uint256) {
        // 1. coinage 조회
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        if (address(coinage) == address(0)) return 0;

        // 2. operator 주소 조회
        address operator = Layer2I(layer2).operator();
        if (operator == address(0)) return 0;

        // 3. operator의 coinage 잔액 반환 (WTON, 27 decimals)
        return coinage.balanceOf(operator);
    }


    /// @inheritdoc ISeigManagerV3
    function hyperbolicSaturation(uint256 x, uint256 maxL2Allocation)
        public
        view
        returns (uint256 y)
    {
        if (x == 0) return 0;

        // y(x) = L · (x / (k + x))
        // = (L * x) / (k + x)
        // DSMath 제거: rmul과 rdiv가 약분되어 직접 계산
        uint256 numerator = maxL2Allocation * x;
        uint256 denominator = halfSaturationPoint + x;
        y = numerator / denominator;
    }

    /// @inheritdoc ISeigManagerV3
    function calculateL2Seigniorage(
        address layer2,
        uint256 totalY,
        uint256 totalX
    ) public view returns (uint256 seigniorage) {
        if (totalX == 0) return 0;

        uint256 effectiveBridged = bridgedTONInfo[layer2].effectiveBridgedTON;
        if (effectiveBridged == 0) return 0;

        // Seig_i = y(x) · (B̃_i / x)
        // DSMath 제거: rmul(totalY, rdiv(effectiveBridged, totalX)) = (totalY * effectiveBridged) / totalX
        seigniorage = (totalY * effectiveBridged) / totalX;
    }

    /// @inheritdoc ISeigManagerV3
    function calculateSequencerReward(uint256 l2Seigniorage)
        public
        view
        returns (uint256)
    {
        // o_i = (1 - α) · Seig_i
        // rmul(x, y) = (x * y) / RAY
        return (l2Seigniorage * (RAY_UNIT - validatorDistributionRatio)) / RAY_UNIT;
    }

    /// @inheritdoc ISeigManagerV3
    /// @notice V3 전용 - bridgedTON 기반 L2 시뇨리지 추정
    /// @dev V2 모드에서는 0 반환 (V2는 layer2TVL 기반, V1_3의 _estimatedDistribute 사용)
    function estimateL2Seigniorage(address layer2) external view returns (uint256 seigniorage) {
        // V3 전용 함수 - V2 모드에서는 0 반환
        if (!v3Migrated) return 0;
        if (!bridgedTONInfo[layer2].isEligible) return 0;
        if (totalEffectiveBridgedTON == 0) return 0;

        // 현재 블록까지의 예상 시뇨리지 계산
        uint256 blockDelta = block.number - _lastSeigBlock;
        if (blockDelta == 0) return 0;

        // V3: 스테이커 시뇨리지 없음, A₂ = A
        uint256 A = blockDelta * _seigPerBlock;

        // L = (1 - d) · A
        // rmul(x, y) = (x * y) / RAY
        uint256 L = (A * (RAY_UNIT - daoDistributionRatio)) / RAY_UNIT;

        // y(x) = L · (x / (k + x))
        uint256 x = totalEffectiveBridgedTON;
        uint256 y = hyperbolicSaturation(x, L);

        // Seig_i = y(x) · (B̃_i / x)
        seigniorage = calculateL2Seigniorage(layer2, y, x);
    }

    // ==========================================
    // External Functions - Seigniorage
    // ==========================================

    /// @notice 시뇨리지 분배 (V2/V3 분기)
    function updateSeigniorage() external returns (bool) {
        if (v3Migrated) {
            return _updateSeigniorageV3();
        } else {
            return _updateSeigniorageV2();
            // return false;
        }
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
    /// @dev V3 마이그레이션: 플래그만 변경
    ///      기존 L2들의 bridgedTONInfo는 시퀀서가 담보금을 예치할 때 초기화됨
    ///      (onBridgedTONChange 호출 시 L1 브리지에서 실시간 조회)
    function migrateToV3() external onlyOwner {
        if (v3Migrated) revert AlreadyMigratedError();

        // 첫 기간 초기화
        currentPeriodId = 1;
        periods[1].startBlock = block.number;

        v3Migrated = true;
        v3MigrationBlock = block.number;

        emit V3MigrationCompleted(block.number, 0);
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /// @notice V3 시뇨리지 분배
    /// @dev V3: 스테이커 시뇨리지 없음, 시퀀서/검증자/DAO만 분배
    function _updateSeigniorageV3() internal ifFree returns (bool) {
        if (paused) return true;

        RefactorCoinageSnapshotI coinage = _coinages[msg.sender];
        _checkCoinage(address(coinage));

        if (block.number <= _lastSeigBlock) revert LastSeigBlockError();

        if (!_increaseTotV3()) revert IncreaseTotError();

        _lastCommitBlock[msg.sender] = block.number;

        emit Comitted(msg.sender);
        return true;
    }


    /// @notice V2 시뇨리지 분배 (스테이커 시뇨리지 포함)
    /// @dev V2: 기존 V1_3 로직 유지
    function _updateSeigniorageV2() internal ifFree returns (bool) {
        // short circuit if paused
        if (paused) {
            return true;
        }

        RefactorCoinageSnapshotI coinage = _coinages[msg.sender];
        _checkCoinage(address(coinage));

        // require(block.number > _lastSeigBlock, "last seig block is not past");
        if (block.number <= _lastSeigBlock) revert LastSeigBlockError();

        address operator = Layer2I(msg.sender).operator();
        uint256 operatorAmount = coinage.balanceOf(operator);

        if (operatorAmount < minimumAmount) revert MinimumAmountError();
        if (!_increaseTot()) revert IncreaseTotError();

        _lastCommitBlock[msg.sender] = block.number;

        // 2. increase total supply of {coinages[layer2]}
        uint256 prevTotalSupply = coinage.totalSupply();
        uint256 nextTotalSupply = _tot.balanceOf(msg.sender);

        // short circuit if there is no seigs for the layer2
        if (prevTotalSupply >= nextTotalSupply) {
            emit Comitted(msg.sender);
            return true;
        }

        uint256 seigs = nextTotalSupply - prevTotalSupply;
        uint256 operatorSeigs;
        bool isCommissionRateNegative_;

        (nextTotalSupply, operatorSeigs, isCommissionRateNegative_) = _calcSeigsDistribution(
            msg.sender,
            coinage,
            prevTotalSupply,
            seigs,
            operator
        );

        // gives seigniorages to the layer2 as coinage
        require(
            coinage.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, coinage.factor())),
            'fail setFactor'
        );

        // give commission to operator or delegators
        if (operatorSeigs != 0) {
            if (isCommissionRateNegative_) {
                // TODO: adjust arithmetic error
                // burn by 𝜸
                coinage.burnFrom(operator, operatorSeigs);
            } else {
                coinage.mint(operator, operatorSeigs);
            }
        }

        if (seigs != 0) IWTON(_wton).mint(address(_depositManager), seigs);

        emit Comitted(msg.sender);
        emit AddedSeigAtLayer(msg.sender, seigs, operatorSeigs, nextTotalSupply, prevTotalSupply);

        return true;
    }
    function _increaseTot() internal returns (bool result) {
        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        // 1. increase total supply of {tot} by maximum seigniorages * staked rate
        //    staked rate = total staked amount / total supply of (W)TON
        uint256 prevTotalSupply = _tot.totalSupply();

        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock) span -= (_unpausedBlock - _pausedBlock);

        // maximum seigniorages
        uint256 maxSeig = span * _seigPerBlock;

        // total supply of (W)TON , https://github.com/tokamak-network/TON-total-supply
        uint256 tos = _totalSupplyOfTon(block.number);

        // maximum seigniorages * staked rate
        uint256 stakedSeig = FullMath.rdiv(
            FullMath.rmul(
                maxSeig,
                // total staked amount
                prevTotalSupply
            ),
            tos
        );
        // uint256 stakedSeig = maxSeig.mulDivRoundingUp(prevTotalSupply, RAY).mulDivRoundingUp(RAY, tos);

        // If layer2StartBlock is not set, set it to the previous block so that the signiorge will be accumulated to layer2 immediately.
        if (layer2StartBlock == 0) layer2StartBlock = block.number - 1;

        address wton_ = _wton;
        uint256 l2TotalSeigs;
        uint256 layer2Seigs;

        if (layer2Manager != address(0) && layer2StartBlock != 1) {
            if (layer2StartBlock <= block.number && totalLayer2TVL > 0) {
                uint256 tempTotalLayer2TVL = Math.min(totalLayer2TVL * GWEI_UNIT, tos-prevTotalSupply);
                if (tempTotalLayer2TVL < RAY_UNIT) tempTotalLayer2TVL = 0;
                l2TotalSeigs = FullMath.rdiv(FullMath.rmul(maxSeig, tempTotalLayer2TVL), tos);
                l2RewardPerUint += (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
                if (l2TotalSeigs != 0) IWTON(wton_).mint(layer2Manager, l2TotalSeigs);
            }

            (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(msg.sender);

            if (allowed && !_isPauseL2Seigniorage(msg.sender)) {
                uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
                Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];
                Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

                // update layer2 tvl if it has changed
                // Because the previous information(oldLayer2Info) was loaded into memory, the storage immediately reflects the latest information.
                if (oldLayer2Info.layer2Tvl != curLayer2Tvl) {
                    newLayer2Info.layer2Tvl = curLayer2Tvl;
                    totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
                }

                // If this the first commit, set up an initial debt
                if (oldLayer2Info.startBlock == 0) {
                    newLayer2Info.startBlock = block.number;
                } else {
                    // distribute seigniorage to layer2 based on previous layer2 tvl
                    // layer2Tvl would be 0 when layer2 has been paused
                    if (oldLayer2Info.layer2Tvl > 0) {
                        layer2Seigs =
                            ((l2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UNIT) -
                            oldLayer2Info.initialDebt;
                        // rewards just increase higher than layer2Debt because it is calculated based on previous layer2 tvl
                        if (layer2Seigs != 0) ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
                    }
                }
                newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UNIT;
            }
        }

        uint256 unstakedSeig = maxSeig - stakedSeig - l2TotalSeigs;
        uint256 totalPseig = FullMath.rmul(unstakedSeig, relativeSeigRate);
        uint256 nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
        _lastSeigBlock = block.number;

        _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

        emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, nextTotalSupply);

        uint256 powertonSeig;
        uint256 daoSeig;
        uint256 relativeSeig;

        if (_powerton != address(0)) {
            powertonSeig = FullMath.rmul(unstakedSeig, powerTONSeigRate);
            if (powertonSeig != 0) IWTON(wton_).mint(_powerton, powertonSeig);
        }

        if (dao != address(0)) {
            daoSeig = FullMath.rmul(unstakedSeig, daoSeigRate);
            if (daoSeig != 0) IWTON(wton_).mint(dao, daoSeig);
        }

        if (relativeSeigRate != 0) {
            relativeSeig = totalPseig;
            accRelativeSeig += relativeSeig;
        }

        emit SeigGiven2(
            msg.sender,
            maxSeig,
            stakedSeig,
            unstakedSeig,
            powertonSeig,
            daoSeig,
            relativeSeig,
            l2TotalSeigs,
            layer2Seigs
        );

        result = true;
    }


    /// @notice V3 증가 로직 (백서 공식 적용)
    /// @dev V3: 스테이커 시뇨리지 없음, 시퀀서/검증자/DAO만 분배
    function _increaseTotV3() internal returns (bool) {
        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        // 시뇨리지 계산
        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock)
            span -= (_unpausedBlock - _pausedBlock);

        uint256 A = span * _seigPerBlock;

        // 상태 업데이트
        uint256 prevTotalSupply = _tot.totalSupply();
        _lastSeigBlock = block.number;

        // 이벤트
        emit CommitLog1(_tot.totalSupply(), _totalSupplyOfTon(block.number), prevTotalSupply, prevTotalSupply);

        // 분배 실행
        uint256 l2TotalSeigs = 0;
        uint256 layer2Seigs = 0;

        if (A > 0) {
            (l2TotalSeigs, layer2Seigs) = _distributeV3SeigniorageCompletely(A);
        }

        emit SeigGiven2(msg.sender, A, 0, 0, 0, 0, 0, l2TotalSeigs, layer2Seigs);
        return true;
    }

    /// @notice V3 시뇨리지 분배 완전 분리 버전
    /// @param A2 V3 분배 재원
    /// @return l2TotalSeigs 총 L2 시뇨리지
    /// @return layer2Seigs 개별 L2 시퀀서 보상
    function _distributeV3SeigniorageCompletely(uint256 A2) internal returns (uint256 l2TotalSeigs, uint256 layer2Seigs) {
        // DAO 분배 계산
        uint256 S_DAO = (A2 * daoDistributionRatio) / RAY_UNIT;
        uint256 L = A2 - S_DAO;

        if (totalEffectiveBridgedTON > 0) {
            // 쌍곡선 포화 함수 인라인 계산: y = L * x / (k + x)
            uint256 y = (L * totalEffectiveBridgedTON) / (halfSaturationPoint + totalEffectiveBridgedTON);
            l2TotalSeigs = y;

            // L2 보상 분배
            layer2Seigs = _distributeL2RewardsSimpleSafe(y, totalEffectiveBridgedTON);

            // DAO 보상 전송
            _mintDAOReward(S_DAO, L, y);
            emit V3SeigniorageDistributed(A2, L, y, S_DAO + (L - y), 0);
        } else {
            _mintDAOReward(S_DAO, L, 0);
            emit V3SeigniorageDistributed(A2, L, 0, S_DAO + L, 0);
        }
    }

    /// @notice 쌍곡선 포화 함수 계산 (스택 깊이 문제 해결)
    function _calculateHyperbolicSaturationSafe(uint256 L) internal view returns (uint256 y) {
        uint256 x = totalEffectiveBridgedTON;
        if (x == 0) return 0;

        uint256 k = halfSaturationPoint;
        // DSMath 제거: rmul과 rdiv가 약분되어 직접 계산
        uint256 numerator = L * x;
        uint256 denominator = k + x;
        y = numerator / denominator;
    }

    /// @notice V3 시뇨리지 분배 (백서 공식 적용) - 스택 깊이 문제 해결을 위해 배열 반환
    /// @param A2 V3 분배 재원 (스테이커 분배 후 잔여)
    /// @return rewards [0] = l2TotalSeigs, [1] = layer2Seigs
    function _distributeV3SeigniorageSplit(uint256 A2) internal returns (uint256[2] memory rewards) {
        // DAO 분배 계산을 별도로 분리
        uint256 daoRatio = daoDistributionRatio;
        // rmul(x, y) = (x * y) / RAY
        uint256 S_DAO = (A2 * daoRatio) / RAY_UNIT;
        uint256 L = A2 - S_DAO;

        // L2 분배 계산을 별도로 분리
        uint256 l2TotalSeigs = 0;
        uint256 layer2Seigs = 0;

        if (totalEffectiveBridgedTON > 0) {
            uint256 y = hyperbolicSaturation(totalEffectiveBridgedTON, L);
            l2TotalSeigs = y;

            uint256[2] memory l2Rewards = _distributeL2RewardsSplit(y, totalEffectiveBridgedTON);
            layer2Seigs = l2Rewards[0];
            uint256 totalValidatorReward = l2Rewards[1];

            _mintDAOReward(S_DAO, L, y);
            emit V3SeigniorageDistributed(A2, L, y, S_DAO + (L - y), totalValidatorReward);
        } else {
            _mintDAOReward(S_DAO, L, 0);
            emit V3SeigniorageDistributed(A2, L, 0, S_DAO + L, 0);
        }

        rewards[0] = l2TotalSeigs;
        rewards[1] = layer2Seigs;
    }

    /// @notice L2 보상 분배 안전 버전
    /// @param y 총 L2 시뇨리지
    /// @param totalEffective 총 유효 브릿지 TON
    /// @return layer2Seigs 개별 L2 시퀀서 보상
    function _distributeL2RewardsSimpleSafe(uint256 y, uint256 totalEffective) internal returns (uint256 layer2Seigs) {
        // 조건 체크
        address rollupConfig;
        bool allowed;
        (rollupConfig, allowed) = _allowIssuanceLayer2Seigs(msg.sender);

        if (!allowed || _isPauseL2Seigniorage(msg.sender)) {
            return 0;
        }

        // 유효 브릿지 TON 동기화
        _syncEffectiveBridgedTON(msg.sender);

        // BridgedTONInfo 접근
        BridgedTONInfo storage info = bridgedTONInfo[msg.sender];
        if (!info.isEligible || info.effectiveBridgedTON == 0) {
            return 0;
        }

        // 직접 계산
        uint256 l2Total = (y * info.effectiveBridgedTON) / totalEffective;
        uint256 totalValReward = (l2Total * validatorDistributionRatio) / RAY_UNIT;
        layer2Seigs = l2Total - totalValReward;

        // 보상 전송
        _transferL2RewardsSafe(layer2Seigs, totalValReward, rollupConfig);
    }

    /// @notice L2 보상 전송 (스택 깊이 문제 해결)
    function _transferL2RewardsSafe(uint256 layer2Seigs, uint256 totalValReward, address rollupConfig) internal {
        if (layer2Seigs > 0) {
            IWTON(_wton).mint(layer2Manager, layer2Seigs);
            ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
        }

        if (totalValReward > 0 && validatorReward != address(0)) {
            IWTON(_wton).mint(validatorReward, totalValReward);
            IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, totalValReward);
        }
    }

    /// @notice V3 시뇨리지 분배 (백서 공식 적용) - 기존 함수 (호환성 유지)
    /// @param A2 V3 분배 재원 (스테이커 분배 후 잔여)
    function _distributeV3Seigniorage(uint256 A2) internal returns (uint256 l2TotalSeigs, uint256 layer2Seigs) {
        uint256[2] memory rewards = _distributeV3SeigniorageSplit(A2);
        l2TotalSeigs = rewards[0];
        layer2Seigs = rewards[1];
    }

    /// @notice L2 보상 분배 - 스택 깊이 문제 해결을 위해 배열 반환
    /// @param y 총 L2 시뇨리지
    /// @param totalEffective 총 유효 브릿지 TON
    /// @return rewards [0] = layer2Seigs, [1] = totalValReward
    function _distributeL2RewardsSplit(uint256 y, uint256 totalEffective)
        internal
        returns (uint256[2] memory rewards)
    {
        // 스택 깊이 문제 해결: 스코프 블록으로 변수 격리
        {
            address rollupConfig;
            bool allowed;
            (rollupConfig, allowed) = _allowIssuanceLayer2Seigs(msg.sender);
            if (!allowed || _isPauseL2Seigniorage(msg.sender)) {
                return rewards; // [0, 0]
            }

            _syncEffectiveBridgedTON(msg.sender);

            uint256 effectiveBridged = bridgedTONInfo[msg.sender].effectiveBridgedTON;
            if (!bridgedTONInfo[msg.sender].isEligible || effectiveBridged == 0) {
                return rewards; // [0, 0]
            }

            // 인라인 계산으로 변수 줄이기 - DSMath 제거
            // rmul(y, rdiv(a, b)) = (y * a) / b (RAY 약분)
            uint256 l2Total = (y * effectiveBridged) / totalEffective;
            // rmul(x, y) = (x * y) / RAY
            uint256 totalValReward = (l2Total * validatorDistributionRatio) / RAY_UNIT;
            uint256 layer2Seigs = l2Total - totalValReward;

            if (layer2Seigs > 0) {
                IWTON(_wton).mint(layer2Manager, layer2Seigs);
                ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
            }

            if (totalValReward > 0 && validatorReward != address(0)) {
                IWTON(_wton).mint(validatorReward, totalValReward);
                IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, totalValReward);
            }

            rewards[0] = layer2Seigs;
            rewards[1] = totalValReward;
        }
    }

    /// @notice L2 보상 분배 - 기존 함수 (호환성 유지)
    function _distributeL2Rewards(uint256 y, uint256 totalEffective)
        internal
        returns (uint256 layer2Seigs, uint256 totalValReward)
    {
        uint256[2] memory rewards = _distributeL2RewardsSplit(y, totalEffective);
        layer2Seigs = rewards[0];
        totalValReward = rewards[1];
    }

    function _mintDAOReward(uint256 S_DAO, uint256 L, uint256 y) internal {
        uint256 totalDAO = S_DAO + (L - y);
        if (totalDAO > 0 && dao != address(0)) {
            IWTON(_wton).mint(dao, totalDAO);
        }
    }


    /// @notice effectiveBridgedTON 동기화 (시뇨리지 계산 전 호출)
    function _syncEffectiveBridgedTON(address layer2) internal {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        uint256 oldEffective = info.effectiveBridgedTON;
        uint256 newEffective = info.isEligible ? info.currentBridgedTON : 0;

        if (newEffective != oldEffective) {
            info.effectiveBridgedTON = newEffective;
            totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;
        }
    }

    function _onlyLayer2Manager() internal view {
        if (msg.sender != layer2Manager) revert OnlyLayer2ManagerError();
    }

    function _checkCoinage(address coinage_) internal pure {
        if (coinage_ == address(0)) revert InvalidCoinageError();
    }

    function _calcSeigsDistribution(
        address layer2,
        RefactorCoinageSnapshotI coinage,
        uint256 prevTotalSupply,
        uint256 seigs,
        address operator
    )
        internal
        returns (
            uint256 nextTotalSupply,
            uint256 operatorSeigs,
            bool isCommissionRateNegative_
        )
    {
        // 스택 깊이 문제 해결: 스코프 블록으로 변수 격리
        {
            uint256 _delayedCommissionBlock = delayedCommissionBlock[layer2];

            if (_delayedCommissionBlock != 0 && block.number >= _delayedCommissionBlock) {
                _commissionRates[layer2] = delayedCommissionRate[layer2];
                _isCommissionRateNegative[layer2] = delayedCommissionRateNegative[layer2];
                delayedCommissionBlock[layer2] = 0;
            }
        }

        isCommissionRateNegative_ = _isCommissionRateNegative[layer2];
        uint256 commissionRate = _commissionRates[layer2];

        nextTotalSupply = prevTotalSupply + seigs;

        if (commissionRate == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        if (!isCommissionRateNegative_) {
            // rmul(x, y) = (x * y) / RAY
            operatorSeigs = (seigs * commissionRate) / RAY_UNIT;
            nextTotalSupply -= operatorSeigs;
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);
        }

        if (prevTotalSupply == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        uint256 operatorBalance = coinage.balanceOf(operator);

        if (operatorBalance == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        // 네거티브 커미션 계산 (별도 함수로 분리하여 스택 깊이 줄이기)
        (operatorSeigs, nextTotalSupply) = _calcNegativeCommission(
            seigs,
            operatorBalance,
            prevTotalSupply,
            commissionRate,
            nextTotalSupply
        );

        return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);
    }

    /// @notice 네거티브 커미션 계산 (스택 깊이 문제 해결)
    function _calcNegativeCommission(
        uint256 seigs,
        uint256 operatorBalance,
        uint256 prevTotalSupply,
        uint256 commissionRate,
        uint256 nextTotalSupply
    ) internal pure returns (uint256 operatorSeigs, uint256 newNextTotalSupply) {
        // rdiv(x, y) = (x * RAY) / y
        uint256 operatorRate = (operatorBalance * RAY_UNIT) / prevTotalSupply;
        // rmul(rmul(x, y), z) = (x * y * z) / (RAY * RAY)
        operatorSeigs = (seigs * operatorRate * commissionRate) / (RAY_UNIT * RAY_UNIT);

        // rdiv(x, y) = (x * RAY) / y
        uint256 delegatorSeigs = (operatorRate == RAY_UNIT)
            ? operatorSeigs
            : (operatorSeigs * RAY_UNIT) / (RAY_UNIT - operatorRate);

        operatorSeigs = delegatorSeigs;
        newNextTotalSupply = nextTotalSupply + delegatorSeigs;
    }

    function _calcNewFactor(
        uint256 source,
        uint256 target,
        uint256 oldFactor
    ) internal pure returns (uint256) {
        // rdiv(rmul(target, oldFactor), source) = (target * oldFactor) / source (RAY 약분)
        return (target * oldFactor) / source;
    }

    function _pauseLayer2Tvl(address layer2) internal {
        require(!_isPauseL2Seigniorage(layer2), "already paused");

        if (!ICandidate(layer2).updateSeigniorage())
            revert UpdateSeigniorageError();

        // V3 처리
        if (v3Migrated) {
            SeigManagerV1_4Storage.BridgedTONInfo storage v3Info = bridgedTONInfo[layer2];
            uint256 oldEffective = v3Info.effectiveBridgedTON;
            v3Info.effectiveBridgedTON = 0;
            v3Info.isEligible = false;
            totalEffectiveBridgedTON -= oldEffective;
        }

        // V2 호환
        Layer2Reward memory v2Info = layer2RewardInfo[layer2];
        totalLayer2TVL -= v2Info.layer2Tvl;
        v2Info.layer2Tvl = 0;
        layer2RewardInfo[layer2] = v2Info;

        layer2PauseBlocks[layer2].push(block.number);
    }

    function _unpauseLayer2Tvl(address layer2) internal {
        // 스택 깊이 문제 해결: 튜플 할당을 단계별로 분리
        bool allowed;
        (, allowed) = _allowIssuanceLayer2Seigs(layer2);
        require(allowed, "not allowed");
        require(_isPauseL2Seigniorage(layer2), "not paused");

        uint256 lastIndex = layer2PauseBlocks[layer2].length - 1;
        layer2UnpauseBlocks[layer2][layer2PauseBlocks[layer2][lastIndex]] = block.number;
        layer2RewardInfo[layer2].startBlock = 0;

        // V3 처리
        if (v3Migrated) {
            bridgedTONInfo[layer2].startBlock = 0;
        }

        if (!ICandidate(layer2).updateSeigniorage())
            revert UpdateSeigniorageError();
    }

    function _totalSupplyOfTon(uint256 blockNumber) internal view returns (uint256 tos) {
        // 인라인 계산으로 로컬 변수 제거
        tos = (initialTotalSupply == 0 ? INITIAL_TOTAL_SUPPLY_MAINNET : initialTotalSupply) +
            (_seigPerBlock * (blockNumber - (seigStartBlock == 0 ? SEIG_START_MAINNET : seigStartBlock))) -
            (ITON(_ton).balanceOf(address(1)) * (10 ** 9)) -
            (burntAmountAtDAO == 0 ? BURNT_AMOUNT_MAINNET : burntAmountAtDAO);
    }

    function _isPauseL2Seigniorage(address layer2) internal view returns (bool) {
        uint256[] memory pauseBlocks = layer2PauseBlocks[layer2];
        uint256 len = pauseBlocks.length;
        if (len == 0) return false;

        uint256 pauseBlock = pauseBlocks[len - 1];

        if (pauseBlock != 0 && layer2UnpauseBlocks[layer2][pauseBlock] == 0) return true;
        else return false;
    }
    function _allowIssuanceLayer2Seigs(
        address layer2
    ) internal view returns (address rollupConfig, bool allowed) {
        // 스택 깊이 문제 해결: 튜플 할당을 단계별로 분리
        address tempRollupConfig;
        (tempRollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        rollupConfig = tempRollupConfig;
        if (ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1) allowed = true;
    }

    // ==========================================
    // RAT Integration Functions
    // ==========================================

    /// @notice RAT 컨트랙트에서만 호출 가능
    modifier onlyRAT() {
        require(msg.sender == ratContract, "only RAT");
        _;
    }

    /// @notice RAT 컨트랙트 주소 설정
    /// @param rat RAT 컨트랙트 주소
    function setRATContract(address rat) external onlyOwner {
        if (rat == address(0)) revert ZeroAddressError();
        ratContract = rat;
        emit RATContractUpdated(rat);
    }

    /// @notice RAT 선차감: validator coinage → RAT coinage 전송
    /// @dev RAT 컨트랙트에서만 호출 가능
    /// @param layer2 L2 주소
    /// @param validator 검증자 주소
    /// @param amount 전송 금액 (WTON 단위, 27 decimals)
    function transferCoinageToRAT(address layer2, address validator, uint256 amount) external onlyRAT {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));

        // validator에서 burn, RAT에 mint
        coinage.burnFrom(validator, amount);
        coinage.mint(ratContract, amount);

        emit CoinageTransferredForRAT(layer2, validator, ratContract, amount);
    }

    /// @notice RAT 복구: RAT coinage → validator coinage 전송
    /// @dev RAT 컨트랙트에서만 호출 가능
    /// @param layer2 L2 주소
    /// @param validator 검증자 주소
    /// @param amount 전송 금액 (WTON 단위, 27 decimals)
    function transferCoinageFromRAT(address layer2, address validator, uint256 amount) external onlyRAT {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));

        // RAT에서 burn, validator에 mint
        coinage.burnFrom(ratContract, amount);
        coinage.mint(validator, amount);

        emit CoinageTransferredForRAT(layer2, ratContract, validator, amount);
    }

    /// @notice RAT 슬래싱 확정: RAT coinage → recipient coinage 전송
    /// @dev RAT 컨트랙트에서만 호출 가능 (treasury로 전송용)
    /// @param layer2 L2 주소
    /// @param recipient 수신자 주소 (treasury)
    /// @param amount 전송 금액 (WTON 단위, 27 decimals)
    function transferCoinageFromRATTo(address layer2, address recipient, uint256 amount) external onlyRAT {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));

        // RAT에서 burn, recipient에 mint
        coinage.burnFrom(ratContract, amount);
        coinage.mint(recipient, amount);

        emit CoinageTransferredForRAT(layer2, ratContract, recipient, amount);
    }

    // ==========================================
    // DepositManager 콜백 함수
    // ==========================================

    /// @notice 스테이킹 시 호출되는 콜백
    /// @dev V2: minimumAmount 체크, V3: checkCurrentEligibility() 체크
    /// @param layer2 L2 주소
    /// @param account 스테이킹 계정
    /// @param amount 스테이킹 금액
    function onDeposit(
        address layer2,
        address account,
        uint256 amount
    ) external onlyDepositManager returns (bool) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));

        // 시퀀서(오퍼레이터) 최소 담보금 체크
        if (_isOperator(layer2, account)) {
            uint256 newBalance = coinage.balanceOf(account) + amount;

            if (v3Migrated) {
                // V3: max(θ × B_i, D_sequencer) 이상 유지 필요
                (, uint256 requiredStake, ) = checkCurrentEligibility(layer2);
                require(newBalance >= requiredStake, "SeigManager: operator minimum amount required");
            } else {
                // V2: minimumAmount 이상 유지 필요
                require(newBalance >= minimumAmount, "SeigManager: minimum amount is required");
            }
        }

        // tot 민트
        _tot.mint(layer2, amount);

        // coinage 민트
        coinage.mint(account, amount);

        // V3: 스테이킹 변경 시 자격 상태 업데이트
        if (v3Migrated) {
            _updateEligibilityInternal(layer2);
        }

        return true;
    }

    /// @notice 출금 요청 시 호출되는 콜백
    /// @dev V2: minimumAmount 체크, V3: checkCurrentEligibility() 및 검증자 체크
    /// @param layer2 L2 주소
    /// @param account 출금 계정
    /// @param amount 출금 금액
    function onWithdraw(
        address layer2,
        address account,
        uint256 amount
    ) external onlyDepositManager returns (bool) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        _checkCoinage(address(coinage));

        uint256 balance = coinage.balanceOf(account);
        require(balance >= amount, "SeigManager: insufficient balance to unstake");

        uint256 newBalance = balance - amount;

        // 시퀀서(오퍼레이터) 담보금 체크
        if (_isOperator(layer2, account)) {
            if (v3Migrated) {
                // V3: max(θ × B_i, D_sequencer) 이상 유지 필요
                (, uint256 requiredStake, ) = checkCurrentEligibility(layer2);
                require(newBalance >= requiredStake, "SeigManager: operator minimum amount required");
            } else {
                // V2: minimumAmount 이상 유지 필요
                require(newBalance >= minimumAmount, "SeigManager: minimum amount is required");
            }
        }

        // V3: 검증자 담보금 체크
        // D_min (pure) = C_off(dynamic) + Δ_validator 이상 유지 필요
        if (v3Migrated && ratContract != address(0)) {
            uint256 validatorMin = IRAT(ratContract).getValidatorMinCollateralForLayer2(layer2, account);
            if (validatorMin > 0) {
                require(newBalance >= validatorMin, "SeigManager: validator minimum collateral required");
            }
        }

        // tot burn
        uint256 totAmount = _additionalTotBurnAmount(layer2, account, amount);
        _tot.burnFrom(layer2, amount + totAmount);

        // coinage burn
        coinage.burnFrom(account, amount);

        emit UnstakeLog(amount, totAmount);

        return true;
    }

    /// @notice 추가 tot burn 금액 계산
    /// @dev 출금 비율에 따른 추가 burn 금액
    function _additionalTotBurnAmount(
        address layer2,
        address,
        uint256 amount
    ) internal view returns (uint256) {
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        uint256 coinageTotalSupply = coinage.totalSupply();
        if (coinageTotalSupply == 0) return 0;

        uint256 totBalance = _tot.balanceOf(layer2);
        if (totBalance == 0) return 0;

        // 출금 비율 = amount / coinageTotalSupply
        // 추가 burn = (totBalance - coinageTotalSupply) * 출금 비율
        uint256 totExcess = totBalance > coinageTotalSupply ? totBalance - coinageTotalSupply : 0;
        return FullMath.mulDiv(totExcess, amount, coinageTotalSupply);
    }

    /// @notice 오퍼레이터 여부 확인
    function _isOperator(address layer2, address account) internal view returns (bool) {
        try Layer2I(layer2).operator() returns (address op) {
            return op == account;
        } catch {
            return false;
        }
    }
}
