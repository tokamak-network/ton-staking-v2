// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SequencerVaultStorage} from "./SequencerVaultStorage.sol";
import {ISequencerVault} from "./ISequencerVault.sol";
import {IL1BridgeRegistry} from "../layer2/interfaces/IL1BridgeRegistry.sol";
import {IOptimismSystemConfig} from "../layer2/interfaces/IOptimismSystemConfig.sol";
import {ILayer2Manager} from "../layer2/interfaces/ILayer2Manager.sol";
import {IOnApprove} from "../stake/interfaces/IOnApprove.sol";

// Slashing Errors
error GameNotResolvedError();
error InvalidFactoryError();
error InvalidOperatorError();

/**
 * @title SequencerVault
 * @notice TON Staking V3 시퀀서 담보금 Vault
 * @dev Tokamak Economics Whitepaper V3 (December 2025) 기준
 *
 * 핵심 기능:
 * 1. 시퀀서(OperatorManager) TON 직접 예치
 * 2. Bridged TON 기반 최소 담보금 요구
 * 3. Fraud Proof 기반 슬래싱
 * 4. 즉시 출금 (2주 대기 없음)
 *
 * V3 정책:
 * - 담보금 시뇨리지 없음 (depositedAmount = 원금 - 슬래싱)
 * - L2당 1개의 시퀀서
 * - SystemConfig 기반 L2 식별
 */
contract SequencerVault is SequencerVaultStorage, ISequencerVault, IOnApprove {
    using SafeERC20 for IERC20;

    // ==========================================
    // Modifiers
    // ==========================================

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerError();
        _;
    }

    // ==========================================
    // Constructor / Initializer
    // ==========================================

    function initialize(
        address _seigManager,
        address _wton,
        address _ton,
        address _layer2Manager,
        address _l1BridgeRegistry,
        address _owner
    ) external {
        require(seigManager == address(0), "already initialized");

        seigManager = _seigManager;
        wton = _wton;
        ton = _ton;
        layer2Manager = _layer2Manager;
        l1BridgeRegistry = _l1BridgeRegistry;
        owner = _owner;

        // 기본값 설정 (백서 기준)
        minimumStakingRatio = 0.1e27;        // θ = 10% (Bridged TON 대비 최소 담보금 비율)
        maxFraudProofCost = 1000e18;         // C_max = 1000 TON
        sequencerAdditionalReward = 100e18;  // Δ_sequencer = 100 TON
        maxChallengers = 10;                 // H_max = 10
    }

    // ==========================================
    // View Functions
    // ==========================================

    /// @inheritdoc ISequencerVault
    function getSequencerDeposit(address systemConfig)
        external view returns (uint256)
    {
        return sequencerDeposits[systemConfig].depositedAmount;
    }

    /// @inheritdoc ISequencerVault
    function isSequencerActive(address systemConfig)
        external view returns (bool)
    {
        return sequencerDeposits[systemConfig].isActive;
    }

    /// @inheritdoc ISequencerVault
    function getSequencerInfo(address systemConfig)
        external view returns (
            address operator,
            address layer2,
            uint256 depositedAmount,
            uint256 slashedAmount,
            bool isActive
        )
    {
        SequencerDeposit storage deposit = sequencerDeposits[systemConfig];
        operator = deposit.operator;
        layer2 = deposit.layer2;
        depositedAmount = deposit.depositedAmount;
        slashedAmount = deposit.slashedAmount;
        isActive = deposit.isActive;
    }

    /// @inheritdoc ISequencerVault
    function getOperatorSystemConfigs(address operator)
        external view returns (address[] memory)
    {
        return operatorSystemConfigs[operator];
    }

    /// @inheritdoc ISequencerVault
    /// @dev layer2 → systemConfig → deposit 조회
    function getSequencerDepositByLayer2(address layer2)
        external view returns (uint256)
    {
        address systemConfig = layer2ToSystemConfig[layer2];
        if (systemConfig == address(0)) return 0;
        return sequencerDeposits[systemConfig].depositedAmount;
    }

    /// @inheritdoc ISequencerVault
    /// @dev layer2 → systemConfig → isActive 조회
    function isSequencerActiveByLayer2(address layer2)
        external view returns (bool)
    {
        address systemConfig = layer2ToSystemConfig[layer2];
        if (systemConfig == address(0)) return false;
        return sequencerDeposits[systemConfig].isActive;
    }

    /// @inheritdoc ISequencerVault
    /// @dev 백서 기반 해석: max(θ · B_i, H_max · C_max + Δ_sequencer)
    ///      - θ · B_i: 시뇨리지 자격 조건 (Rule 4, p.15)
    ///      - H_max · C_max + Δ_sequencer: Fraud Proof 비용 커버 (Formula 1, p.10)
    ///      두 조건을 모두 충족해야 하므로 max 사용
    function getMinimumCollateral(uint256 bridgedTON)
        public view returns (uint256)
    {
        // θ · B_i (시뇨리지 자격 조건)
        uint256 minForSeigniorage = (bridgedTON * minimumStakingRatio) / RAY;

        // H_max · C_max + Δ_sequencer (Fraud Proof 비용 커버 - 백서 공식 1)
        uint256 minForFraudProof = maxChallengers * maxFraudProofCost + sequencerAdditionalReward;

        // max(θ · B_i, H_max · C_max + Δ_sequencer)
        return minForSeigniorage > minForFraudProof ? minForSeigniorage : minForFraudProof;
    }

    // ==========================================
    // Sequencer Management
    // ==========================================

    /// @inheritdoc ISequencerVault
    /// @dev 누구나 호출 가능, systemConfig로 operator/layer2 조회
    function registerSequencer(address systemConfig, uint256 depositAmount)
        external
        ifFree
        whenNotPaused
    {
        if (systemConfig == address(0)) revert InvalidSystemConfigError();
        if (depositAmount == 0) revert InsufficientDepositError();

        // Layer2Manager에서 systemConfig의 layer2, operator 조회
        address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
        if (layer2 == address(0)) revert InvalidSystemConfigError();

        (, address operator) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        if (operator == address(0)) revert InvalidOperatorError();

        // TON 직접 전송 받기
        IERC20(ton).safeTransferFrom(msg.sender, address(this), depositAmount);

        // 시퀀서 등록 로직 (operator는 Layer2Manager에서 조회한 값)
        _registerSequencerInternal(operator, systemConfig, layer2, depositAmount);
    }

    /// @inheritdoc ISequencerVault
    /// @dev V3: 즉시 출금, 오퍼레이터만 호출 가능
    function deactivateSequencer(address systemConfig)
        external
        ifFree
    {
        if (systemConfig == address(0)) revert InvalidSystemConfigError();

        SequencerDeposit storage deposit = sequencerDeposits[systemConfig];
        if (deposit.operator != msg.sender) revert NotRegisteredError();
        if (!deposit.isActive) revert NotActiveSequencerError();

        deposit.isActive = false;

        // V3 정책: 담보금 전액 반환 (시뇨리지 없음)
        uint256 withdrawAmount = deposit.depositedAmount;
        deposit.depositedAmount = 0;

        // TON 즉시 전송
        if (withdrawAmount > 0) {
            IERC20(ton).safeTransfer(msg.sender, withdrawAmount);
        }

        emit SequencerDeactivated(msg.sender, systemConfig, withdrawAmount);
    }

    /// @inheritdoc ISequencerVault
    /// @dev 누구나 호출 가능 (제3자 펀딩 가능)
    function addDeposit(address systemConfig, uint256 amount)
        external
        ifFree
    {
        if (systemConfig == address(0)) revert InvalidSystemConfigError();

        SequencerDeposit storage deposit = sequencerDeposits[systemConfig];
        if (deposit.operator == address(0)) revert NotRegisteredError();
        if (!deposit.isActive) revert NotActiveSequencerError();
        if (amount == 0) revert InsufficientDepositError();

        // TON 직접 전송 받기
        IERC20(ton).safeTransferFrom(msg.sender, address(this), amount);

        deposit.depositedAmount += amount;

        emit DepositAdded(msg.sender, systemConfig, amount);
    }

    /// @notice TON에서 호출되는 콜백 (TON.approveAndCall → Vault)
    /// @param _owner TON 전송자
    /// @param spender Vault 컨트랙트 주소 (사용 안함)
    /// @param amount TON 양 (18 decimals)
    /// @param data systemConfig 주소 (32바이트)
    function onApprove(
        address _owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override ifFree whenNotPaused returns (bool) {
        require(msg.sender == ton, "only TON");

        // data에서 systemConfig 추출 (32바이트)
        require(data.length >= 32, "invalid data");
        address systemConfig = address(uint160(uint256(bytes32(data[:32]))));
        if (systemConfig == address(0)) revert InvalidSystemConfigError();

        // Layer2Manager에서 systemConfig의 layer2, operator 조회
        address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
        if (layer2 == address(0)) revert InvalidSystemConfigError();

        (, address operator) = ILayer2Manager(layer2Manager).layerInfo(layer2);
        if (operator == address(0)) revert InvalidOperatorError();

        // TON은 이미 Vault에 전송됨 (TON.onApprove에서 transfer)

        // 시퀀서 등록 로직 (operator는 Layer2Manager에서 조회한 값)
        _registerSequencerInternal(operator, systemConfig, layer2, amount);

        return true;
    }

    /// @notice 내부 시퀀서 등록 로직
    /// @dev V3 정책: 담보금 시뇨리지 없음, L2당 1개의 시퀀서
    function _registerSequencerInternal(
        address operator,
        address systemConfig,
        address layer2,
        uint256 depositAmount
    ) internal {
        SequencerDeposit storage deposit = sequencerDeposits[systemConfig];

        // 이미 다른 오퍼레이터가 등록된 경우
        if (deposit.operator != address(0) && deposit.operator != operator) {
            // 기존 오퍼레이터가 활성 상태면 에러
            if (deposit.isActive) {
                revert AlreadyRegisteredError();
            }
        }

        // 최소 담보금 확인
        uint256 bridgedTON = _getBridgedTON(systemConfig);
        uint256 minCollateral = getMinimumCollateral(bridgedTON);
        uint256 totalDeposit = deposit.depositedAmount + depositAmount;
        if (totalDeposit < minCollateral) revert InsufficientDepositError();

        // 신규 등록인지 재등록인지 확인
        bool isReregistration = deposit.operator == operator && deposit.depositedAmount > 0;

        if (isReregistration) {
            // 재등록: 담보금만 추가
            deposit.depositedAmount = totalDeposit;
            deposit.isActive = true;
        } else {
            // 신규 등록
            deposit.operator = operator;
            deposit.layer2 = layer2;
            deposit.depositedAmount = totalDeposit;
            deposit.slashedAmount = 0;
            deposit.isActive = true;

            operatorSystemConfigs[operator].push(systemConfig);
            layer2ToSystemConfig[layer2] = systemConfig;
        }

        emit SequencerRegistered(operator, systemConfig, layer2, totalDeposit);
    }

    /// @notice Bridged TON 조회
    function _getBridgedTON(address systemConfig) internal view returns (uint256) {
        if (l1BridgeRegistry == address(0)) return 0;
        return IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(systemConfig);
    }

    // ==========================================
    // Slashing
    // ==========================================

    /// @inheritdoc ISequencerVault
    /// @notice 시퀀서 슬래싱 - Permissionless 방식
    /// @dev 누구나 호출 가능, 게임 상태를 온체인에서 검증
    ///      DisputeGameFactory 검증을 통해 가짜 게임 컨트랙트 방지
    ///      챌린저는 claimData(0).counteredBy에서 온체인 조회
    /// @param gameAddress 종료된 FaultDisputeGame 주소
    function slashSequencerByGame(address gameAddress) external whenNotPaused {
        // 1. 이미 슬래싱되었는지 확인
        if (slashedGames[gameAddress]) revert AlreadySlashedGameError();

        // 2. FaultDisputeGame 상태 조회
        // status() returns GameStatus enum: 0=IN_PROGRESS, 1=CHALLENGER_WINS, 2=DEFENDER_WINS
        (bool success, bytes memory data) = gameAddress.staticcall(
            abi.encodeWithSignature("status()")
        );
        if (!success || data.length == 0) revert InvalidGameError();
        uint8 gameStatus = abi.decode(data, (uint8));
        if (gameStatus != 1) revert GameNotResolvedError(); // 1 = CHALLENGER_WINS

        // 3. SystemConfig 조회
        (success, data) = gameAddress.staticcall(
            abi.encodeWithSignature("systemConfig()")
        );
        if (!success || data.length == 0) revert InvalidGameError();
        address systemConfig = abi.decode(data, (address));

        // 4. DisputeGameFactory 검증 - 가짜 게임 컨트랙트 방지
        address factory = IOptimismSystemConfig(systemConfig).disputeGameFactory();
        if (factory == address(0)) revert InvalidFactoryError();

        // 5. L1BridgeRegistry에서 factory가 등록되어 있는지 확인
        address registeredConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithDisputeGameFactory(factory);
        if (registeredConfig != systemConfig) revert InvalidFactoryError();

        // 6. 시퀀서 조회
        SequencerDeposit storage deposit = sequencerDeposits[systemConfig];
        if (deposit.operator == address(0)) revert NotRegisteredError();
        if (!deposit.isActive) revert NotActiveSequencerError();

        // 7. 챌린저 온체인 조회 - claimData(0).counteredBy
        address challenger = _getChallengerFromGame(gameAddress);

        // 8. 슬래싱 처리됨으로 마킹
        slashedGames[gameAddress] = true;

        // 9. 슬래싱 실행
        _executeSlashing(systemConfig, deposit, challenger, gameAddress);
    }

    /// @notice 게임에서 챌린저 주소 조회
    /// @dev claimData(0).counteredBy 조회 - root claim을 counter한 주소
    /// @param gameAddress FaultDisputeGame 주소
    /// @return challenger 챌린저 주소 (없으면 address(0))
    function _getChallengerFromGame(address gameAddress) internal view returns (address challenger) {
        // claimData(0) 조회: (parentIndex, counteredBy, claimant, bond, claim, position, clock)
        (bool success, bytes memory data) = gameAddress.staticcall(
            abi.encodeWithSignature("claimData(uint256)", 0)
        );
        if (success && data.length >= 64) {
            // counteredBy는 두 번째 필드 (32-63 bytes)
            assembly {
                challenger := mload(add(data, 64))
            }
        }
    }

    /// @notice 내부 슬래싱 실행
    function _executeSlashing(
        address systemConfig,
        SequencerDeposit storage deposit,
        address challenger,
        address gameAddress
    ) internal {
        address operator = deposit.operator;

        // 담보금 전액 슬래싱
        uint256 actualSlash = deposit.depositedAmount;

        // 챌린저 보상 계산 (C_max + Δ_sequencer)
        uint256 challengerReward = maxFraudProofCost + sequencerAdditionalReward;
        if (challengerReward > actualSlash) {
            challengerReward = actualSlash;
        }

        // 담보금 차감 (전액 슬래싱)
        deposit.depositedAmount = 0;
        deposit.slashedAmount += actualSlash;

        // Treasury 귀속분 누적 (챌린저 보상 제외)
        uint256 toTreasury = actualSlash - challengerReward;
        accumulatedSlashings += toTreasury;

        // 챌린저 보상 누적 (나중에 claim)
        if (challengerReward > 0 && challenger != address(0)) {
            pendingChallengerRewards[challenger] += challengerReward;
        }

        emit SequencerSlashed(
            operator,
            systemConfig,
            gameAddress,
            actualSlash,
            challenger,
            challengerReward
        );

        // 슬래싱 후 비활성화
        deposit.isActive = false;
        emit SequencerDeactivated(operator, systemConfig, 0);
    }

    /// @inheritdoc ISequencerVault
    function withdrawSlashingsToTreasury() external {
        if (treasury == address(0)) revert ZeroAddressError();

        uint256 amount = accumulatedSlashings;
        accumulatedSlashings = 0;

        IERC20(ton).safeTransfer(treasury, amount);

        emit SlashingsWithdrawnToTreasury(treasury, amount);
    }

    /// @inheritdoc ISequencerVault
    /// @notice 챌린저 보상 청구
    function claimChallengerReward() external ifFree {
        uint256 reward = pendingChallengerRewards[msg.sender];
        if (reward == 0) revert NoRewardError();

        pendingChallengerRewards[msg.sender] = 0;
        IERC20(ton).safeTransfer(msg.sender, reward);

        emit ChallengerRewardClaimed(msg.sender, reward);
    }

    /// @inheritdoc ISequencerVault
    function getPendingChallengerReward(address challenger) external view returns (uint256) {
        return pendingChallengerRewards[challenger];
    }

    // ==========================================
    // Governance Functions
    // ==========================================

    /// @inheritdoc ISequencerVault
    function setMinimumStakingRatio(uint256 ratio) external onlyOwner {
        minimumStakingRatio = ratio;
    }

    /// @inheritdoc ISequencerVault
    function setMaxFraudProofCost(uint256 cost) external onlyOwner {
        maxFraudProofCost = cost;
    }

    /// @inheritdoc ISequencerVault
    function setSequencerAdditionalReward(uint256 reward) external onlyOwner {
        sequencerAdditionalReward = reward;
    }

    /// @inheritdoc ISequencerVault
    function setMaxChallengers(uint256 max) external onlyOwner {
        maxChallengers = max;
    }

    /// @inheritdoc ISequencerVault
    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddressError();
        treasury = _treasury;
    }

    /// @inheritdoc ISequencerVault
    function setL1BridgeRegistry(address _registry) external onlyOwner {
        l1BridgeRegistry = _registry;
    }

    /// @notice Owner 변경
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddressError();
        owner = newOwner;
    }

    /// @inheritdoc ISequencerVault
    function pause() external onlyOwner {
        paused = true;
    }

    /// @inheritdoc ISequencerVault
    function unpause() external onlyOwner {
        paused = false;
    }

    // ==========================================
    // Emergency Functions
    // ==========================================

    /// @notice 비상 출금 (Owner 전용)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner, amount);
    }
}
