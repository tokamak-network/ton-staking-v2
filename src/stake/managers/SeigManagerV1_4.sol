// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    /// @notice 챌린저 보상 지급 이벤트
    event ChallengerRewarded(
        address indexed challenger,
        address indexed layer2,
        uint256 reward
    );

    /// @notice SequencerVault 주소 변경 이벤트
    event SequencerVaultUpdated(address indexed vault);

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
    /// @dev V3: 시퀀서 자격 조건(S_i ≥ θ·B_i)을 SequencerVault 담보금으로 확인
    function setSequencerVault(address vault) external onlyOwner {
        if (vault == address(0)) revert ZeroAddressError();
        sequencerVault = vault;
        emit SequencerVaultUpdated(vault);
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

        // 새로운 자격 상태 확인
        (bool newEligible, , ) = checkCurrentEligibility(layer2);

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
    /// @dev 백서 공식 (9): 1_i = {1 if S_i ≥ θ·B_i, 0 otherwise}
    /// @dev S_i는 시퀀서의 SequencerVault 담보금
    /// @dev B_i는 L1 브리지에서 직접 조회 (가스비 높지만 정확함)
    /// @param layer2 L2 주소
    /// @return eligible 시뇨리지 수령 자격 여부
    /// @return requiredStake 필요 담보금 (θ·B_i)
    /// @return currentStake 현재 시퀀서 담보금 (S_i)
    function checkCurrentEligibility(address layer2)
        public
        view
        returns (bool eligible, uint256 requiredStake, uint256 currentStake)
    {
        // B_i: L1 브리지에서 직접 조회 (실시간)
        uint256 bridgedTON = ILayer2Manager(layer2Manager).getBridgedTONByLayer(layer2);

        // θ·B_i 계산
         // Todo. 브릿지된 톤은 톤기준, 필요한 스테이킹양은 WTON 이므로, 고려해서 변환해줘야한다.
        requiredStake = rmul(bridgedTON, minStakingRatio);

        // S_i: 시퀀서의 현재 담보금 (SequencerVault에서 조회)
        currentStake = _getSequencerCollateral(layer2);

        // S_i ≥ θ·B_i
        eligible = currentStake >= requiredStake;
    }

    /// @notice 시퀀서 담보금 조회
    /// @dev V3: SequencerVault에서 담보금 조회 (L1 스테이킹 아님)
    /// @dev Layer2의 오퍼레이터(OperatorManager)가 SequencerVault에 담보금 예치
    /// @param layer2 L2 주소
    /// @return 시퀀서의 담보금 (TON, 18 decimals)
    function _getSequencerCollateral(address layer2) internal view returns (uint256) {
        if (sequencerVault == address(0)) return 0;

        return ISequencerVault(sequencerVault).getSequencerDepositByLayer2(layer2);
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
        y = rdiv(rmul(maxL2Allocation, x), halfSaturationPoint + x);
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
        seigniorage = rmul(totalY, rdiv(effectiveBridged, totalX));
    }

    /// @inheritdoc ISeigManagerV3
    function calculateSequencerReward(uint256 l2Seigniorage)
        public
        view
        returns (uint256)
    {
        // o_i = (1 - α) · Seig_i
        return rmul(l2Seigniorage, RAY - validatorDistributionRatio);
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
        uint256 L = rmul(A, RAY - daoDistributionRatio);

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
        if (paused) return true;

        RefactorCoinageSnapshotI coinage = _coinages[msg.sender];
        _checkCoinage(address(coinage));

        if (block.number <= _lastSeigBlock) revert LastSeigBlockError();

        address operator = Layer2I(msg.sender).operator();

        if (!_increaseTotV2()) revert IncreaseTotError();

        _lastCommitBlock[msg.sender] = block.number;

        uint256 prevTotalSupply = coinage.totalSupply();
        uint256 nextTotalSupply = _tot.balanceOf(msg.sender);

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

        require(
            coinage.setFactor(
                _calcNewFactor(prevTotalSupply, nextTotalSupply, coinage.factor())
            ),
            "fail setFactor"
        );

        if (operatorSeigs != 0) {
            if (isCommissionRateNegative_) {
                coinage.burnFrom(operator, operatorSeigs);
            } else {
                coinage.mint(operator, operatorSeigs);
            }
        }

        IWTON(_wton).mint(address(_depositManager), seigs);

        emit Comitted(msg.sender);
        emit AddedSeigAtLayer(msg.sender, seigs, operatorSeigs, nextTotalSupply, prevTotalSupply);

        return true;
    }

    /// @notice V3 증가 로직 (백서 공식 적용)
    /// @dev V3: 스테이커 시뇨리지 없음, 시퀀서/검증자/DAO만 분배
    function _increaseTotV3() internal returns (bool result) {
        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        uint256 prevTotalSupply = _tot.totalSupply();
        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock)
            span -= (_unpausedBlock - _pausedBlock);

        uint256 A = span * _seigPerBlock;
        uint256 tos = _totalSupplyOfTon(block.number);
        uint256 l2TotalSeigs = 0;
        uint256 layer2Seigs = 0;

        _lastSeigBlock = block.number;

        // V3: 스테이커 시뇨리지 없음
        // A₂ = A (전체 시뇨리지가 V3 분배 재원)
        emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, prevTotalSupply);

        if (A > 0) {
            (l2TotalSeigs, layer2Seigs) = _distributeV3Seigniorage(A);
        }

        emit SeigGiven2(msg.sender, A, 0, 0, 0, 0, 0, l2TotalSeigs, layer2Seigs);

        result = true;
    }

    /// @notice V2 증가 로직 (V1_3과 동일)
    /// @dev V2: 스테이커 시뇨리지 포함
    function _increaseTotV2() internal returns (bool result) {
        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        uint256 prevTotalSupply = _tot.totalSupply();
        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock)
            span -= (_unpausedBlock - _pausedBlock);

        uint256 A = span * _seigPerBlock;
        uint256 tos = _totalSupplyOfTon(block.number);
        uint256 l2TotalSeigs = 0;
        uint256 layer2Seigs = 0;
        uint256 S_staked = 0;
        uint256 S_relative = 0;
        uint256 unstakedSeig = 0;
        uint256 powertonSeig = 0;
        uint256 daoSeig = 0;
        address wton_ = _wton;

        _lastSeigBlock = block.number;

        // 1. stakedSeig 계산
        S_staked = rdiv(rmul(A, prevTotalSupply), tos);

        // 2. Layer2 TVL 시뇨리지 계산
        if (layer2StartBlock == 0) layer2StartBlock = block.number - 1;

        if (layer2Manager != address(0) && layer2StartBlock != 1) {
            if (layer2StartBlock <= block.number && totalLayer2TVL > 0) {
                uint256 tempTotalLayer2TVL = Math.min(totalLayer2TVL * GWEI_UNIT, tos - prevTotalSupply);
                if (tempTotalLayer2TVL < RAY_UNIT) tempTotalLayer2TVL = 0;
                l2TotalSeigs = rdiv(rmul(A, tempTotalLayer2TVL), tos);
                l2RewardPerUint += (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
                if (l2TotalSeigs != 0) IWTON(wton_).mint(layer2Manager, l2TotalSeigs);
            }

            (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(msg.sender);

            if (allowed && !_isPauseL2Seigniorage(msg.sender)) {
                uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
                Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];
                Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

                if (oldLayer2Info.layer2Tvl != curLayer2Tvl) {
                    newLayer2Info.layer2Tvl = curLayer2Tvl;
                    totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
                }

                if (oldLayer2Info.startBlock == 0) {
                    newLayer2Info.startBlock = block.number;
                } else {
                    if (oldLayer2Info.layer2Tvl > 0) {
                        layer2Seigs = ((l2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UNIT) - oldLayer2Info.initialDebt;
                        if (layer2Seigs != 0) ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
                    }
                }
                newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UNIT;
            }
        }

        // 3. unstakedSeig, totalPseig 계산
        unstakedSeig = A - S_staked - l2TotalSeigs;
        uint256 totalPseig = rmul(unstakedSeig, relativeSeigRate);
        uint256 nextTotalSupply = prevTotalSupply + S_staked + totalPseig;

        // 4. Coinage factor 업데이트
        _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

        emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, nextTotalSupply);

        // 5. PowerTON, DAO 분배
        if (_powerton != address(0)) {
            powertonSeig = rmul(unstakedSeig, powerTONSeigRate);
            if (powertonSeig != 0) IWTON(wton_).mint(_powerton, powertonSeig);
        }

        if (dao != address(0)) {
            daoSeig = rmul(unstakedSeig, daoSeigRate);
            if (daoSeig != 0) IWTON(wton_).mint(dao, daoSeig);
        }

        // 6. relativeSeig 누적
        if (relativeSeigRate != 0) {
            S_relative = totalPseig;
            accRelativeSeig += S_relative;
        }

        emit SeigGiven2(
            msg.sender,
            A,
            S_staked,
            unstakedSeig,
            powertonSeig,
            daoSeig,
            S_relative,
            l2TotalSeigs,
            layer2Seigs
        );

        result = true;
    }

    /// @notice V3 시뇨리지 분배 (백서 공식 적용)
    /// @param A2 V3 분배 재원 (스테이커 분배 후 잔여)
    function _distributeV3Seigniorage(uint256 A2) internal returns (uint256 l2TotalSeigs, uint256 layer2Seigs) {
        // ========================================
        // DAO 고정 분배 (백서 공식 7)
        // S_DAO = d · A₂
        // ========================================
        uint256 S_DAO = rmul(A2, daoDistributionRatio);

        // ========================================
        // L2 분배 가능량
        // L = (1 - d) · A₂
        // ========================================
        uint256 L = A2 - S_DAO;

        // ========================================
        // 쌍곡선 포화 함수 (백서 공식 11)
        // y(x) = L · (x / (k + x))
        // ========================================
        uint256 x = totalEffectiveBridgedTON;
        uint256 y = 0;
        uint256 totalValidatorReward = 0;

        if (x > 0) {
            // y(x) = L · (x / (k + x))
            y = hyperbolicSaturation(x, L);
            l2TotalSeigs = y;

            // 개별 L2 보상 정산
            (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(msg.sender);
            if (allowed && !_isPauseL2Seigniorage(msg.sender)) {
                // 호출자의 effectiveBridgedTON 동기화 (isEligible 기반)
                _syncEffectiveBridgedTON(msg.sender);

                BridgedTONInfo storage info = bridgedTONInfo[msg.sender];
                if (info.isEligible && info.effectiveBridgedTON > 0) {
                    // ========================================
                    // Per-L2 시뇨리지 계산 (백서 V3 공식)
                    // S_i = y(x) · (B̃_i / x)
                    // ========================================
                    uint256 l2TotalSeigniorage = rmul(y, rdiv(info.effectiveBridgedTON, x));

                    // 검증자 몫: α · S_i (백서 공식 13)
                    uint256 l2ValidatorReward = rmul(l2TotalSeigniorage, validatorDistributionRatio);

                    // 시퀀서 몫: (1 - α) · S_i (백서 공식 14)
                    layer2Seigs = l2TotalSeigniorage - l2ValidatorReward;

                    // 시퀀서 보상 전송
                    if (layer2Seigs > 0) {
                        IWTON(_wton).mint(layer2Manager, layer2Seigs);
                        ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
                    }

                    // 검증자 보상 분배 (Per-L2)
                    if (l2ValidatorReward > 0 && validatorReward != address(0)) {
                        IWTON(_wton).mint(validatorReward, l2ValidatorReward);
                        IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, l2ValidatorReward);
                        totalValidatorReward += l2ValidatorReward;
                    }
                }
            }
        }

        // ========================================
        // 미분배분 DAO 귀속
        // totalDAO = S_DAO + (L - y(x))
        // ========================================
        uint256 undistributed = L - y;
        uint256 totalDAO = S_DAO + undistributed;

        if (totalDAO > 0 && dao != address(0)) {
            IWTON(_wton).mint(dao, totalDAO);
        }

        emit V3SeigniorageDistributed(A2, L, y, totalDAO, totalValidatorReward);
    }

    /// @notice V2 시뇨리지 분배 (마이그레이션 전 호환)
    function _distributeV2Seigniorage(uint256 maxSeig, uint256 tos, uint256 prevTotalSupply)
        internal
        returns (uint256 l2TotalSeigs, uint256 layer2Seigs)
    {
        if (layer2StartBlock == 0) layer2StartBlock = block.number - 1;

        if (layer2StartBlock <= block.number && totalLayer2TVL > 0) {
            uint256 tempTotalLayer2TVL = Math.min(
                totalLayer2TVL * 1e9,
                tos - prevTotalSupply
            );
            l2TotalSeigs = rdiv(rmul(maxSeig, tempTotalLayer2TVL), tos);
            l2RewardPerUint += (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
            IWTON(_wton).mint(layer2Manager, l2TotalSeigs);
        }

        (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(msg.sender);
        if (allowed && !_isPauseL2Seigniorage(msg.sender)) {
            uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
            Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];
            Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

            if (oldLayer2Info.layer2Tvl != curLayer2Tvl) {
                newLayer2Info.layer2Tvl = curLayer2Tvl;
                totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
            }

            if (oldLayer2Info.startBlock == 0) {
                newLayer2Info.startBlock = block.number;
            } else {
                if (oldLayer2Info.layer2Tvl > 0) {
                    layer2Seigs = ((l2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UNIT) - oldLayer2Info.initialDebt;
                    if (layer2Seigs != 0) {
                        ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
                    }
                }
            }
            newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UNIT;
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
        uint256 _delayedCommissionBlock = delayedCommissionBlock[layer2];

        if (_delayedCommissionBlock != 0 && block.number >= _delayedCommissionBlock) {
            _commissionRates[layer2] = delayedCommissionRate[layer2];
            _isCommissionRateNegative[layer2] = delayedCommissionRateNegative[layer2];
            delayedCommissionBlock[layer2] = 0;
        }

        isCommissionRateNegative_ = _isCommissionRateNegative[layer2];
        uint256 commissionRate = _commissionRates[layer2];

        nextTotalSupply = prevTotalSupply + seigs;

        if (commissionRate == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        if (!isCommissionRateNegative_) {
            operatorSeigs = rmul(seigs, commissionRate);
            nextTotalSupply -= operatorSeigs;
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);
        }

        if (prevTotalSupply == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        uint256 operatorBalance = coinage.balanceOf(operator);

        if (operatorBalance == 0)
            return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);

        uint256 operatorRate = rdiv(operatorBalance, prevTotalSupply);

        operatorSeigs = rmul(rmul(seigs, operatorRate), commissionRate);

        uint256 delegatorSeigs = operatorRate == RAY
            ? operatorSeigs
            : rdiv(operatorSeigs, RAY - operatorRate);

        operatorSeigs = delegatorSeigs;
        nextTotalSupply += delegatorSeigs;

        return (nextTotalSupply, operatorSeigs, isCommissionRateNegative_);
    }

    function _calcNewFactor(
        uint256 source,
        uint256 target,
        uint256 oldFactor
    ) internal pure returns (uint256) {
        return rdiv(rmul(target, oldFactor), source);
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
        (, bool allowed) = _allowIssuanceLayer2Seigs(layer2);
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
        uint256 startBlock = (seigStartBlock == 0 ? SEIG_START_MAINNET : seigStartBlock);
        uint256 initial = (initialTotalSupply == 0 ? INITIAL_TOTAL_SUPPLY_MAINNET : initialTotalSupply);
        uint256 burntAmount = (burntAmountAtDAO == 0 ? BURNT_AMOUNT_MAINNET : burntAmountAtDAO);

        tos = initial +
            (_seigPerBlock * (blockNumber - startBlock)) -
            (ITON(_ton).balanceOf(address(1)) * (10 ** 9)) -
            burntAmount;
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
        (rollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        if (ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1) allowed = true;
    }
}
