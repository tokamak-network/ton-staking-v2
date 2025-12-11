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
 * 5. 점진적 V2→V3 전환 메커니즘
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

    modifier onlyMigrated() {
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

    /// @notice 스테이킹 잔액 이전 이벤트
    event StakeTransferred(
        address indexed layer2,
        address indexed from,
        address indexed to,
        uint256 amount
    );

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

    /// @notice 지분 시뇨리지 비율 설정 (V2→V3 전환)
    /// @param lambda 새로운 비율 (RAY 단위, 0 ≤ lambda ≤ 1)
    function setStakedSeigFactor(uint256 lambda) external onlyOwner {
        if (lambda > RAY) revert InvalidParameterError();
        stakedSeigFactor = lambda;
        emit StakedSeigFactorUpdated(lambda);
    }

    /// @notice 추가 시뇨리지 비율 설정
    /// @param newRate 새로운 비율 (RAY 단위)
    function setRelativeSeigRate(uint256 newRate) external onlyOwner {
        if (newRate > RAY) revert InvalidParameterError();
        relativeSeigRate = newRate;
        emit RelativeSeigRateUpdated(newRate);
    }

    /// @notice 검증자 풀 주소 설정
    function setValidatorPool(address pool) external onlyOwner {
        if (pool == address(0)) revert ZeroAddressError();
        validatorPool = pool;
        emit ValidatorPoolUpdated(pool);
    }

    /// @notice 최대 챌린저 수 설정
    function setMaxChallengers(uint256 hMax) external onlyOwner {
        if (hMax == 0) revert InvalidParameterError();
        maxChallengers = hMax;
    }

    /// @notice 최대 fraud proof 비용 설정
    function setMaxFraudProofCost(uint256 cMax) external onlyOwner {
        maxFraudProofCost = cMax;
    }

    /// @notice RAT 컨트랙트 주소 설정
    function setRATContract(address rat) external onlyOwner {
        if (rat == address(0)) revert ZeroAddressError();
        ratContract = rat;
    }

    /// @notice DisputeContract 주소 설정
    function setDisputeContract(address dispute) external onlyOwner {
        if (dispute == address(0)) revert ZeroAddressError();
        disputeContract = dispute;
    }

    /// @notice 시퀀서 추가 보상 설정 (Δ_sequencer)
    function setSequencerAdditionalReward(address layer2, uint256 additionalReward) external onlyOwner {
        sequencerAdditionalReward[layer2] = additionalReward;
    }

    /// @notice Layer2Manager 주소 설정
    function setLayer2Manager(address layer2Manager_) external onlyOwner {
        layer2Manager = layer2Manager_;
    }

    /// @notice L1BridgeRegistry 주소 설정
    function setL1BridgeRegistry(address l1BridgeRegistry_) external onlyOwner {
        l1BridgeRegistry = l1BridgeRegistry_;
    }

    /// @notice L2 시뇨리지 시작 블록 설정
    function setLayer2StartBlock(uint256 startBlock_) external onlyOwner {
        layer2StartBlock = startBlock_;
    }

    function pause() public onlyPauser whenNotPaused {
        require(_pausedBlock < _lastSeigBlock, "updateSeigniorage required");
        _pausedBlock = block.number;
        paused = true;
        emit Paused(msg.sender);
    }

    // ==========================================
    // External Functions - Callbacks (V3 신규)
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    function onBridgedTONChange(address layer2, uint256 newBridgedTON)
        external
        onlyL1BridgeOrRegistry
        onlyMigrated
    {
        SeigManagerV1_4Storage.BridgedTONInfo storage info = bridgedTONInfo[layer2];
        uint256 oldEffective = info.effectiveBridgedTON;

        info.currentBridgedTON = newBridgedTON;
        info.lastUpdateTime = block.timestamp;

        // 자격 재평가
        _updateEligibility(layer2);

        uint256 newEffective = info.effectiveBridgedTON;

        // 전역 합계 갱신
        if (newEffective != oldEffective) {
            totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;
        }

        emit BridgedTONChanged(layer2, newBridgedTON, newEffective, info.isEligible);
    }

    /// @inheritdoc ISeigManagerV3
    function onStakingChange(address layer2)
        external
        onlyMigrated
    {
        // DepositManager 또는 내부에서 호출 가능
        require(
            msg.sender == address(_depositManager) || msg.sender == address(this),
            "not authorized"
        );

        SeigManagerV1_4Storage.BridgedTONInfo storage info = bridgedTONInfo[layer2];
        uint256 oldEffective = info.effectiveBridgedTON;
        bool oldEligible = info.isEligible;

        // 자격 재평가
        _updateEligibility(layer2);

        uint256 newEffective = info.effectiveBridgedTON;

        // 전역 합계 갱신
        if (newEffective != oldEffective) {
            totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;
        }

        if (oldEligible != info.isEligible) {
            emit EligibilityChanged(layer2, info.isEligible, info.currentBridgedTON, newEffective);
        }
    }

    /// @inheritdoc ISeigManagerV3
    function initializeBridgedTON(address layer2, uint256 initialBridgedTON)
        external
        onlyMigrated
    {
        require(msg.sender == layer2Manager, "only layer2Manager");

        SeigManagerV1_4Storage.BridgedTONInfo storage info = bridgedTONInfo[layer2];

        info.currentBridgedTON = initialBridgedTON;
        info.startBlock = block.number;
        info.lastUpdateTime = block.timestamp;
        info.initialDebt = (bridgedTONRewardPerUint * initialBridgedTON) / WEI_UNIT;

        // 초기 자격 평가
        _updateEligibility(layer2);

        if (info.isEligible) {
            totalEffectiveBridgedTON += info.effectiveBridgedTON;
        }

        emit BridgedTONChanged(layer2, initialBridgedTON, info.effectiveBridgedTON, info.isEligible);
    }

    // ==========================================
    // View Functions (V3 신규)
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    function getEffectiveBridgedTON(address layer2) external view returns (uint256) {
        return bridgedTONInfo[layer2].effectiveBridgedTON;
    }

    /// @inheritdoc ISeigManagerV3
    function checkEligibility(address layer2)
        public
        view
        returns (bool eligible, uint256 requiredStake, uint256 currentStake)
    {
        SeigManagerV1_4Storage.BridgedTONInfo storage info = bridgedTONInfo[layer2];
        uint256 bridgedTON = info.currentBridgedTON;

        // θ·B_i 계산
        requiredStake = rmul(bridgedTON, minStakingRatio);

        // 현재 스테이킹 금액 조회
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        currentStake = address(coinage) != address(0) ? coinage.totalSupply() : 0;

        // S_i ≥ θ·B_i
        eligible = currentStake >= requiredStake;
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
    function estimateL2Seigniorage(address layer2) external view returns (uint256 seigniorage) {
        if (!bridgedTONInfo[layer2].isEligible) return 0;
        if (totalEffectiveBridgedTON == 0) return 0;

        // 현재 블록까지의 예상 시뇨리지 계산
        uint256 blockDelta = block.number - _lastSeigBlock;
        if (blockDelta == 0) return 0;

        uint256 A = blockDelta * _seigPerBlock;
        uint256 T = ITON(_ton).totalSupply();
        uint256 S = IERC20(_wton).totalSupply();

        // S_staked = λ · A · (S / T)
        uint256 S_staked = rmul(rmul(A, stakedSeigFactor), rdiv(S, T));
        uint256 A1 = A - S_staked;

        // S_relative = A₁ · r
        uint256 S_relative = rmul(A1, relativeSeigRate);
        uint256 A2 = A1 - S_relative;

        // L = (1 - d) · A₂
        uint256 L = rmul(A2, RAY - daoDistributionRatio);

        // y(x) = L · (x / (k + x))
        uint256 x = totalEffectiveBridgedTON;
        uint256 y = hyperbolicSaturation(x, L);

        // Seig_i = y(x) · (B̃_i / x)
        seigniorage = calculateL2Seigniorage(layer2, y, x);
    }

    // ==========================================
    // External Functions - Layer2Manager
    // ==========================================

    function excludeFromL2Seigniorage(address layer2) external returns (bool) {
        _onlyLayer2Manager();
        _pauseLayer2Tvl(layer2);
        emit ExcludedFromL2Seigniorage(layer2);
        return true;
    }

    function includeFromL2Seigniorage(address layer2) external returns (bool) {
        _onlyLayer2Manager();
        _unpauseLayer2Tvl(layer2);
        require(!isPauseL2Seigniorage(layer2), "error includeFromL2Seigniorage");
        emit IncludedFromL2Seigniorage(layer2);
        return true;
    }

    // ==========================================
    // External Functions - Sequencer Slashing
    // ==========================================

    /// @notice 시퀀서 슬래싱 (fraud proof 성공 시)
    /// @dev 백서: "the entire bond (D_sequencer) is slashed"
    /// @param layer2 슬래싱 대상 L2 주소
    /// @param challengers 성공한 챌린저 목록
    function slashSequencer(address layer2, address[] calldata challengers)
        external
        onlyMigrated
    {
        require(msg.sender == disputeContract, "only dispute contract");
        uint256 n = challengers.length;
        require(n > 0 && n <= maxChallengers, "invalid challenger count");

        // 시퀀서(오퍼레이터) 주소 조회
        address sequencer = Layer2I(layer2).operator();
        require(sequencer != address(0), "no operator");

        // 담보금 = 해당 L2에 스테이킹된 시퀀서의 금액
        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        uint256 deposit = coinage.balanceOf(sequencer);
        require(deposit > 0, "no deposit to slash");

        uint256 additionalReward = sequencerAdditionalReward[layer2];

        // 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
        uint256 perChallengerReward = maxFraudProofCost + (additionalReward / n);

        // 총 챌린저 보상이 담보금을 초과하지 않도록
        uint256 totalChallengerRewards = perChallengerReward * n;
        if (totalChallengerRewards > deposit) {
            perChallengerReward = deposit / n;
            totalChallengerRewards = perChallengerReward * n;
        }

        // 각 챌린저에게 스테이킹 잔액으로 이전 (coinage 잔액 변경)
        for (uint256 i = 0; i < n; i++) {
            coinage.burnFrom(sequencer, perChallengerReward);
            coinage.mint(challengers[i], perChallengerReward);
            emit ChallengerRewarded(challengers[i], layer2, perChallengerReward);
        }

        // 나머지는 DAO의 스테이킹 잔액으로 이전
        uint256 remainder = deposit - totalChallengerRewards;
        if (remainder > 0) {
            coinage.burnFrom(sequencer, remainder);
            coinage.mint(dao, remainder);
        }

        // L2 시뇨리지 분배에서 제외
        _pauseLayer2Tvl(layer2);

        // 슬래싱 기록 저장
        sequencerSlashTimestamps[layer2].push(block.timestamp);

        emit SequencerSlashed(layer2, sequencer, deposit, n);
    }

    /// @notice 스테이킹 잔액 이전 (슬래싱 컨트랙트 전용)
    /// @param layer2 L2 주소
    /// @param from 출발 계정 (슬래싱 대상)
    /// @param to 도착 계정 (챌린저 또는 DAO)
    /// @param amount 이전 금액
    function transferStake(
        address layer2,
        address from,
        address to,
        uint256 amount
    ) external onlyMigrated {
        require(msg.sender == disputeContract, "only dispute contract");

        RefactorCoinageSnapshotI coinage = _coinages[layer2];
        require(coinage.balanceOf(from) >= amount, "insufficient balance");

        coinage.burnFrom(from, amount);
        coinage.mint(to, amount);

        emit StakeTransferred(layer2, from, to, amount);
    }

    // ==========================================
    // External Functions - Seigniorage
    // ==========================================

    /// @notice V3 시뇨리지 분배
    function updateSeigniorage() external returns (bool) {
        return _updateSeigniorageV3();
    }

    function updateSeigniorageLayer(address layer2) external returns (bool) {
        if (!ICandidate(layer2).updateSeigniorage())
            revert UpdateSeigniorageError();
        return true;
    }

    // ==========================================
    // View Functions - Existing
    // ==========================================

    function getOperatorAmount(address layer2) external view returns (uint256) {
        address operator = Layer2I(layer2).operator();
        return _coinages[layer2].balanceOf(operator);
    }

    function allowIssuanceLayer2Seigs(address layer2)
        public
        view
        returns (address rollupConfig, bool allowed)
    {
        (rollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        if (ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1)
            allowed = true;
    }

    function unSettledReward(address layer2) public view returns (uint256 amount) {
        SeigManagerV1_4Storage.BridgedTONInfo memory info = bridgedTONInfo[layer2];
        if (info.effectiveBridgedTON != 0) {
            amount = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.initialDebt;
        }
    }

    function unallocatedSeigniorage() external view returns (uint256 amount) {
        amount = _tot.totalSupply() - stakeOfAllLayers();
    }

    function stakeOfAllLayers() public view returns (uint256 amount) {
        uint256 num = ILayer2Registry(_registry).numLayer2s();
        for (uint256 i = 0; i < num; i++) {
            address layer2 = ILayer2Registry(_registry).layer2ByIndex(i);
            address coin = address(_coinages[layer2]);
            if (coin != address(0)) amount += _coinages[layer2].totalSupply();
        }
    }

    function isPauseL2Seigniorage(address layer2) public view returns (bool) {
        uint256[] memory pauseBlocks = layer2PauseBlocks[layer2];
        uint256 len = pauseBlocks.length;
        if (len == 0) return false;

        uint256 pauseBlock = pauseBlocks[len - 1];

        if (pauseBlock != 0 && layer2UnpauseBlocks[layer2][pauseBlock] == 0)
            return true;
        else return false;
    }

    // ==========================================
    // Migration Functions
    // ==========================================

    /// @inheritdoc ISeigManagerV3
    function migrateToV3() external onlyOwner {
        if (v3Migrated) revert AlreadyMigratedError();

        uint256 numLayer2s = ILayer2Registry(_registry).numLayer2s();
        uint256 migratedCount = 0;

        for (uint256 i = 0; i < numLayer2s; i++) {
            address layer2 = ILayer2Registry(_registry).layer2ByIndex(i);

            // V2의 TVL 데이터를 V3의 초기 Bridged TON으로 설정
            Layer2Reward memory oldInfo = layer2RewardInfo[layer2];
            uint256 currentTvl = oldInfo.layer2Tvl;

            if (currentTvl > 0 || oldInfo.startBlock > 0) {
                bridgedTONInfo[layer2] = BridgedTONInfo({
                    currentBridgedTON: currentTvl,
                    effectiveBridgedTON: currentTvl, // 초기에는 모두 유효
                    initialDebt: 0,
                    startBlock: block.number,
                    lastUpdateTime: block.timestamp,
                    isEligible: true // 초기에는 모두 자격 있음
                });

                totalEffectiveBridgedTON += currentTvl;
                migratedCount++;
            }
        }

        // 첫 기간 초기화
        currentPeriodId = 1;
        periods[1].startBlock = block.number;

        v3Migrated = true;
        v3MigrationBlock = block.number;

        emit V3MigrationCompleted(block.number, migratedCount);
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /// @notice V3 시뇨리지 분배 (순차적 분배)
    function _updateSeigniorageV3() internal ifFree returns (bool) {
        if (paused) return true;

        RefactorCoinageSnapshotI coinage = _coinages[msg.sender];
        _checkCoinage(address(coinage));

        if (block.number <= _lastSeigBlock) revert LastSeigBlockError();

        address operator = Layer2I(msg.sender).operator();
        uint256 operatorAmount = coinage.balanceOf(operator);

        if (operatorAmount < minimumAmount) revert MinimumAmountError();
        if (!_increaseTotV3()) revert IncreaseTotError();

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
    function _increaseTotV3() internal returns (bool result) {
        if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
            _lastSeigBlock = block.number;
            return false;
        }

        uint256 prevTotalSupply = _tot.totalSupply();
        uint256 span = block.number - _lastSeigBlock;
        if (_unpausedBlock > _lastSeigBlock)
            span -= (_unpausedBlock - _pausedBlock);

        // ========================================
        // A = 전체 기간 시뇨리지
        // ========================================
        uint256 A = span * _seigPerBlock;

        // ========================================
        // Step 1: 스테이커 지분 시뇨리지 (λ 적용)
        // S_staked = λ · A · (S / T)
        // ========================================
        uint256 T = ITON(_ton).totalSupply();
        uint256 tos = _totalSupplyOfTon(block.number);
        uint256 S = IERC20(_wton).totalSupply();

        // λ가 설정되지 않았으면 1 (V2 호환)
        uint256 lambda = stakedSeigFactor > 0 ? stakedSeigFactor : RAY;

        uint256 S_staked = rmul(
            rmul(A, lambda),
            rdiv(prevTotalSupply, tos)
        );

        // A₁ = A - S_staked
        uint256 A1 = A - S_staked;

        // ========================================
        // Step 2: 스테이커 추가 시뇨리지 (r 적용)
        // S_relative = A₁ · r
        // ========================================
        uint256 S_relative = rmul(A1, relativeSeigRate);

        // A₂ = A₁ - S_relative (V3 분배 재원)
        uint256 A2 = A1 - S_relative;

        // ========================================
        // 스테이커 분배 (Coinage factor 업데이트)
        // ========================================
        uint256 totalStakerSeig = S_staked + S_relative;
        uint256 nextTotalSupply = prevTotalSupply + totalStakerSeig;

        _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));
        _lastSeigBlock = block.number;

        emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, nextTotalSupply);

        // PowerTON, DAO 분배 (V2 호환)
        address wton_ = _wton;
        uint256 unstakedSeig = A - S_staked - S_relative;
        uint256 powertonSeig;
        uint256 daoSeig;

        if (_powerton != address(0)) {
            powertonSeig = rmul(unstakedSeig, powerTONSeigRate);
            IWTON(wton_).mint(_powerton, powertonSeig);
        }

        if (dao != address(0) && daoSeigRate > 0) {
            daoSeig = rmul(unstakedSeig, daoSeigRate);
            IWTON(wton_).mint(dao, daoSeig);
        }

        if (relativeSeigRate != 0) {
            accRelativeSeig += S_relative;
        }

        // ========================================
        // Step 3: V3 분배 (A₂ 기준, 백서 공식 적용)
        // ========================================
        uint256 l2TotalSeigs = 0;
        uint256 layer2Seigs = 0;

        if (v3Migrated && A2 > 0) {
            (l2TotalSeigs, layer2Seigs) = _distributeV3Seigniorage(A2);
        } else if (!v3Migrated && layer2Manager != address(0)) {
            // V3 마이그레이션 전: 기존 V2 로직 사용
            (l2TotalSeigs, layer2Seigs) = _distributeV2Seigniorage(A, tos, prevTotalSupply);
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
        uint256 validatorPoolAmount = 0;

        if (x > 0) {
            // y(x) = L · (x / (k + x))
            y = hyperbolicSaturation(x, L);
            l2TotalSeigs = y;

            // 검증자 풀: α · y(x) (백서 공식 13)
            validatorPoolAmount = rmul(y, validatorDistributionRatio);

            // 단위당 보상 누적 (시퀀서용)
            uint256 sequencerTotal = y - validatorPoolAmount;
            bridgedTONRewardPerUint += (sequencerTotal * WEI_UNIT) / x;

            // Layer2Manager로 민트 (시퀀서 보상용)
            if (sequencerTotal > 0) {
                IWTON(_wton).mint(layer2Manager, sequencerTotal);
            }

            // 개별 L2 보상 정산
            (, bool allowed) = allowIssuanceLayer2Seigs(msg.sender);
            if (allowed && !isPauseL2Seigniorage(msg.sender)) {
                BridgedTONInfo storage info = bridgedTONInfo[msg.sender];
                if (info.isEligible && info.effectiveBridgedTON > 0) {
                    layer2Seigs = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.initialDebt;

                    if (layer2Seigs > 0) {
                        ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
                    }

                    info.initialDebt = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
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

        // 검증자 풀 분배
        if (validatorPoolAmount > 0 && validatorPool != address(0)) {
            IWTON(_wton).mint(validatorPool, validatorPoolAmount);
        }

        emit V3SeigniorageDistributed(A2, L, y, totalDAO, validatorPoolAmount);
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

        (address rollupConfig, bool allowed) = allowIssuanceLayer2Seigs(msg.sender);
        if (allowed && !isPauseL2Seigniorage(msg.sender)) {
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

    /// @notice L2 자격 업데이트
    function _updateEligibility(address layer2) internal {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];

        (bool eligible, , ) = checkEligibility(layer2);

        info.isEligible = eligible;
        info.effectiveBridgedTON = eligible ? info.currentBridgedTON : 0;
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
        require(!isPauseL2Seigniorage(layer2), "already paused");

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
        (, bool allowed) = allowIssuanceLayer2Seigs(layer2);
        require(allowed, "not allowed");
        require(isPauseL2Seigniorage(layer2), "not paused");

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
}
