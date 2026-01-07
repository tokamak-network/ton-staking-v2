// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Core Infrastructure
import {CoinageFactory} from "../src/stake/factory/CoinageFactory.sol";
import {RefactorCoinageSnapshot} from "../src/stake/tokens/RefactorCoinageSnapshot.sol";
import {RefactorCoinageSnapshotProxy} from "../src/stake/tokens/RefactorCoinageSnapshotProxy.sol";
import {Layer2Registry} from "../src/stake/Layer2Registry.sol";
import {Layer2RegistryProxy} from "../src/stake/Layer2RegistryProxy.sol";

// Manager Implementations
import {SeigManagerV1_2} from "../src/stake/managers/SeigManagerV1_2.sol";
import {SeigManagerV1_3} from "../src/stake/managers/SeigManagerV1_3.sol";
import {SeigManagerV1_4} from "../src/stake/managers/SeigManagerV1_4.sol";
import {DepositManager} from "../src/stake/managers/DepositManager.sol";
import {DepositManager_setWithdrawalDelay} from "../src/stake/managers/DepositManager_setWithdrawalDelay.sol";
import {DepositManagerV1_1} from "../src/stake/managers/DepositManagerV1_1.sol";
import {DepositManagerV1_2} from "../src/stake/managers/DepositManagerV1_2.sol";
import {Layer2ManagerV1_1} from "../src/layer2/Layer2ManagerV1_1.sol";
import {Layer2ManagerV1_2} from "../src/layer2/Layer2ManagerV1_2.sol";
// L1BridgeRegistryV1_1 import removed - V1_2 has all V1_1 functions
import {L1BridgeRegistryV1_2} from "../src/layer2/L1BridgeRegistryV1_2.sol";

// Manager Proxies (ProxySeigManager has setAliveImplementation2, setSelectorImplementations2)
import {SeigManagerProxy} from "../src/stake/managers/SeigManagerProxy.sol";
import {DepositManagerProxy} from "../src/stake/managers/DepositManagerProxy.sol";
import {Layer2ManagerProxy} from "../src/layer2/Layer2ManagerProxy.sol";
import {L1BridgeRegistryProxy} from "../src/layer2/L1BridgeRegistryProxy.sol";

// Operator Manager
import {OperatorManagerFactory} from "../src/layer2/factory/OperatorManagerFactory.sol";
import {OperatorManagerV1_2} from "../src/layer2/OperatorManagerV1_2.sol";

// V3 New Contracts
import {RAT} from "../src/validator/RAT.sol";
import {RATProxy} from "../src/validator/RATProxy.sol";
import {ValidatorRewardV1} from "../src/validator/ValidatorRewardV1.sol";
import {ValidatorRewardProxy} from "../src/validator/ValidatorRewardProxy.sol";
import {SequencerVault} from "../src/sequencer/SequencerVault.sol";
import {SequencerVaultProxy} from "../src/sequencer/SequencerVaultProxy.sol";

// Mocks for testing
import {MockTON} from "../src/mocks/MockTON.sol";
import {MockWTON} from "../src/mocks/MockWTON.sol";

/// @notice Proxy interface
interface IProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
}

/**
 * @title DeployV3Full
 * @notice 새 체인용 전체 배포 스크립트 (아무것도 없는 체인에서 처음부터 모든 것을 배포)
 * @dev forge script script/DeployV3Full.s.sol:DeployV3Full --rpc-url $RPC_URL --broadcast -vvvv
 *
 * 이 스크립트는 TON Staking V3 전체 시스템을 처음부터 배포합니다:
 * - Mock TON/WTON 토큰
 * - CoinageFactory 및 RefactorCoinageSnapshot
 * - Layer2Registry
 * - SeigManager (프록시 + 구현체)
 * - DepositManager (프록시 + 구현체)
 * - Layer2Manager (프록시 + 구현체)
 * - L1BridgeRegistry (프록시 + 구현체)
 * - OperatorManagerFactory
 * - RAT (프록시 + 구현체)
 * - ValidatorReward (프록시 + 구현체)
 */
contract DeployV3Full is Script {
    // ==========================================
    // Deployment Parameters
    // ==========================================

    // SeigManager parameters
    uint256 constant SEIG_PER_BLOCK = 3.92e18; // 3.92 TON per block
    uint256 constant GLOBAL_WITHDRAWAL_DELAY = 93046; // ~2 weeks in blocks (assuming 13s blocks)

    // RAT parameters
    uint256 constant RAT_TRIGGER_PROBABILITY = 0.01e27; // 1% (RAY)
    uint256 constant RAT_SLASHING_PENALTY = 100e27; // 100 WTON (RAY)
    uint256 constant RAT_VALIDATOR_BUFFER = 100e27; // 100 WTON (RAY)
    uint256 constant RAT_MINIMUM_THRESHOLD = 1000e27; // 1000 WTON (RAY)
    uint256 constant RAT_EVIDENCE_PERIOD = 1 hours;

    // ==========================================
    // Deployed Addresses
    // ==========================================

    // Tokens
    address public ton;
    address public wton;

    // Core Infrastructure
    address public coinageFactory;
    address public coinageLogic;
    address public layer2RegistryProxy;
    address public layer2RegistryImpl;

    // Managers (Proxies)
    address public seigManagerProxy;
    address public depositManagerProxy;
    address public layer2ManagerProxy;
    address public l1BridgeRegistryProxy;

    // SeigManager 다중 구현체
    address public seigManagerV1_3Impl;  // Index 1: V1_3 (pause/unpause)
    address public seigManagerImpl;       // Index 2: V1_4 (V3 functions)

    // DepositManager 다중 구현체
    address public depositManagerBaseImpl;        // Index 0 (Base)
    address public depositManagerSetDelayImpl;    // Index 1 (setWithdrawalDelay)
    address public depositManagerV1_1Impl;        // Index 2 (V1_1)
    address public depositManagerV1_2Impl;        // Index 3 (V1_2)

    // Layer2Manager 다중 구현체
    address public layer2ManagerV1_1Impl;         // Index 0: V1_1 (base - setAddresses with guard)
    address public layer2ManagerImpl;             // Index 1: V1_2 (V3 functions)

    // L1BridgeRegistry 다중 구현체
    // l1BridgeRegistryV1_1Impl removed - V1_2 has all V1_1 functions
    address public l1BridgeRegistryImpl;          // Index 1: V1_2 (DisputeGame support)

    // Operator Manager
    address public operatorManagerFactory;
    address public operatorManagerImpl;

    // V3 Contracts
    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;
    address public sequencerVaultProxy;
    address public sequencerVaultImpl;

    function run() external virtual {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        // console.log("=== TON Staking V3 Full Deployment ===");
        // console.log("Deployer:", deployer);
        // console.log("Chain ID:", block.chainid);
        // console.log("");

        vm.startBroadcast(deployerPrivateKey);

        _deployTokens();
        _deployCoinageInfrastructure(deployer);
        _deployLayer2Registry(deployer);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(deployer);
        _setupMinterPermissions();  // Phase 5.5: Minter 권한 설정
        _deployOperatorManagerFactory(deployer);
        _deployV3Contracts(deployer);
        _configureV3Contracts(deployer);
        _setupCrossReferences(deployer);

        vm.stopBroadcast();

        _printSummary();
        _saveDeployment();
    }

    // ==========================================
    // Step 1: Deploy Tokens
    // ==========================================
    function _deployTokens() internal {
        // console.log("--- Step 1: Deploy Tokens ---");

        ton = address(new MockTON());
        // console.log("TON:", ton);

        MockWTON wtonContract = new MockWTON();
        wtonContract.setTON(ton);
        wton = address(wtonContract);
        // console.log("WTON:", wton);
        // console.log("");
    }

    // ==========================================
    // Step 2: Deploy Coinage Infrastructure
    // ==========================================
    function _deployCoinageInfrastructure(address deployer) internal {
        // console.log("--- Step 2: Deploy Coinage Infrastructure ---");

        // Deploy RefactorCoinageSnapshot logic
        coinageLogic = address(new RefactorCoinageSnapshot());
        // console.log("RefactorCoinageSnapshot Logic:", coinageLogic);

        // Deploy CoinageFactory
        CoinageFactory factory = new CoinageFactory();
        factory.setAutoCoinageLogic(coinageLogic);
        coinageFactory = address(factory);
        // console.log("CoinageFactory:", coinageFactory);
        // console.log("");
    }

    // ==========================================
    // Step 3: Deploy Layer2Registry
    // ==========================================
    function _deployLayer2Registry(address deployer) internal {
        // console.log("--- Step 3: Deploy Layer2Registry ---");

        layer2RegistryImpl = address(new Layer2Registry());
        // console.log("Layer2Registry Impl:", layer2RegistryImpl);

        Layer2RegistryProxy registryProxy = new Layer2RegistryProxy();
        IProxy(address(registryProxy)).upgradeTo(layer2RegistryImpl);
        layer2RegistryProxy = address(registryProxy);
        // console.log("Layer2Registry Proxy:", layer2RegistryProxy);
        // console.log("");
    }

    // ==========================================
    // Step 4: Deploy Manager Proxies
    // ==========================================
    function _deployManagerProxies() internal {
        // console.log("--- Step 4: Deploy Manager Proxies ---");

        seigManagerProxy = address(new SeigManagerProxy());
        // console.log("SeigManager Proxy:", seigManagerProxy);

        depositManagerProxy = address(new DepositManagerProxy());
        // console.log("DepositManager Proxy:", depositManagerProxy);

        layer2ManagerProxy = address(new Layer2ManagerProxy());
        // console.log("Layer2Manager Proxy:", layer2ManagerProxy);

        l1BridgeRegistryProxy = address(new L1BridgeRegistryProxy());
        // console.log("L1BridgeRegistry Proxy:", l1BridgeRegistryProxy);
        // console.log("");
    }

    // ==========================================
    // Step 5: Deploy Manager Implementations
    // ==========================================
    function _deployManagerImplementations() internal {
        // console.log("--- Step 5: Deploy Manager Implementations ---");

        // SeigManager: 메인넷처럼 V1_2를 기본 구현체로 사용
        // Index 0: SeigManagerV1_2 (base - initialize, setData 포함)
        // Index 1: SeigManagerV1_3 (pause/unpause)
        // Index 2: SeigManagerV1_4 (V3 신규 함수)
        address seigManagerV1_2Impl = address(new SeigManagerV1_2());
        // console.log("SeigManagerV1_2 Impl:", seigManagerV1_2Impl);
        IProxy(seigManagerProxy).upgradeTo(seigManagerV1_2Impl);

        // V1_3, V1_4는 selector routing으로 추가 예정
        seigManagerV1_3Impl = address(new SeigManagerV1_3());
        // console.log("SeigManagerV1_3 Impl:", seigManagerV1_3Impl);

        seigManagerImpl = address(new SeigManagerV1_4());
        // console.log("SeigManagerV1_4 Impl:", seigManagerImpl);

        // DepositManager: 다중 구현체 패턴 (SeigManager와 동일)
        // Index 0: DepositManager (Base)
        // Index 1: DepositManager_setWithdrawalDelay
        // Index 2: DepositManagerV1_1
        // Index 3: DepositManagerV1_2
        depositManagerBaseImpl = address(new DepositManager());
        // console.log("DepositManager Base Impl (Index 0):", depositManagerBaseImpl);
        IProxy(depositManagerProxy).upgradeTo(depositManagerBaseImpl);

        depositManagerSetDelayImpl = address(new DepositManager_setWithdrawalDelay());
        // console.log("DepositManager_setWithdrawalDelay Impl (Index 1):", depositManagerSetDelayImpl);

        depositManagerV1_1Impl = address(new DepositManagerV1_1());
        // console.log("DepositManagerV1_1 Impl (Index 2):", depositManagerV1_1Impl);

        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        // console.log("DepositManagerV1_2 Impl (Index 3):", depositManagerV1_2Impl);

        // Layer2Manager: 다중 구현체 패턴
        // Index 0: Layer2ManagerV1_1 (base - setAddresses with guard)
        // Index 1: Layer2ManagerV1_2 (V3 functions - BridgedTON)
        layer2ManagerV1_1Impl = address(new Layer2ManagerV1_1());
        // console.log("Layer2ManagerV1_1 Impl (Index 0):", layer2ManagerV1_1Impl);
        IProxy(layer2ManagerProxy).upgradeTo(layer2ManagerV1_1Impl);

        layer2ManagerImpl = address(new Layer2ManagerV1_2());
        // console.log("Layer2ManagerV1_2 Impl (Index 1):", layer2ManagerImpl);

        // L1BridgeRegistry: V1_2 only (V1_2 has all V1_1 functions + TYPE 3 support)
        l1BridgeRegistryImpl = address(new L1BridgeRegistryV1_2());
        // console.log("L1BridgeRegistryV1_2 Impl:", l1BridgeRegistryImpl);
        IProxy(l1BridgeRegistryProxy).upgradeTo(l1BridgeRegistryImpl);
        // console.log("");
    }

    // ==========================================
    // Step 6: Initialize Managers
    // ==========================================
    function _initializeManagers(address deployer) internal {
        // console.log("--- Step 6: Initialize Managers ---");

        // Initialize SeigManager (using V1_2 - 메인넷과 동일하게)
        SeigManagerV1_2(seigManagerProxy).initialize(
            ton,
            wton,
            layer2RegistryProxy,
            depositManagerProxy,
            SEIG_PER_BLOCK,
            coinageFactory,
            block.number // lastSeigBlock = current block
        );
        // console.log("SeigManager initialized");

        // setData: 시뇨리지 분배 비율 설정 (V1_2 함수)
        SeigManagerV1_2(seigManagerProxy).setData(
            address(0),     // powerTON (테스트시 address(0))
            deployer,       // dao address (테스트시 deployer)
            0,              // powerTONSeigRate: 0%
            0.5e27,         // daoSeigRate: 50%
            0.5e27,         // relativeSeigRate: 50%
            93096,          // adjustCommissionDelay
            1000.1e27       // minimumAmount: 1000.1 WTON
        );
        // console.log("SeigManager setData done");

        // =====================================================
        // SeigManager 다중 구현체 설정 (메인넷과 동일한 패턴)
        // =====================================================
        // 옵션 A: 단순 업그레이드 (테스트용 - V1_4가 모든 함수 포함)
        // IProxy(seigManagerProxy).upgradeTo(seigManagerImpl);

        // 옵션 B: Selector Routing (메인넷 패턴)
        // V1_2는 이미 기본 구현체로 설정됨 (Index 0)
        // V1_3, V1_4 함수들을 개별 라우팅

        // 먼저 V1_3, V1_4를 alive 상태로 설정
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(seigManagerV1_3Impl, true);
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(seigManagerImpl, true);
        // console.log("SeigManager V1_3, V1_4 implementations set alive");

        // V1_3 함수 selectors 등록 (6개)
        // pause/unpause, excludeFromL2Seigniorage, includeFromL2Seigniorage, claimableL2Seigniorage, estimatedDistribute
        bytes4[] memory v1_3Selectors = new bytes4[](6);
        v1_3Selectors[0] = SeigManagerV1_3.pause.selector;
        v1_3Selectors[1] = SeigManagerV1_3.unpause.selector;
        v1_3Selectors[2] = SeigManagerV1_3.excludeFromL2Seigniorage.selector;
        v1_3Selectors[3] = SeigManagerV1_3.includeFromL2Seigniorage.selector;
        v1_3Selectors[4] = SeigManagerV1_3.claimableL2Seigniorage.selector;
        v1_3Selectors[5] = SeigManagerV1_3.estimatedDistribute.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(v1_3Selectors, seigManagerV1_3Impl);
        // console.log("SeigManager V1_3 selectors registered (6 functions)");

        // V1_4 함수 selectors 등록 (31개)
        bytes4[] memory v1_4Selectors = new bytes4[](31);
        // V1_4에만 있는 함수들 (V1_2에 없음) - Setters
        v1_4Selectors[0] = SeigManagerV1_4.setValidatorReward.selector;
        v1_4Selectors[1] = SeigManagerV1_4.setDaoDistributionRatio.selector;
        v1_4Selectors[2] = SeigManagerV1_4.setMinStakingRatio.selector;
        v1_4Selectors[3] = SeigManagerV1_4.setValidatorDistributionRatio.selector;
        v1_4Selectors[4] = SeigManagerV1_4.setHalfSaturationPoint.selector;
        v1_4Selectors[5] = SeigManagerV1_4.setStakedSeigFactor.selector;
        v1_4Selectors[6] = SeigManagerV1_4.migrateToV3.selector;
        v1_4Selectors[7] = SeigManagerV1_4.onBridgedTONChange.selector;
        v1_4Selectors[8] = SeigManagerV1_4.setMaxChallengers.selector;
        v1_4Selectors[9] = SeigManagerV1_4.setMaxFraudProofCost.selector;
        v1_4Selectors[10] = SeigManagerV1_4.setSequencerVault.selector;
        // 로직 수정으로 V1_4로 오버라이드 (V1_2에도 있지만 V3 로직 적용)
        v1_4Selectors[11] = SeigManagerV1_4.updateSeigniorage.selector;
        v1_4Selectors[12] = SeigManagerV1_4.updateSeigniorageLayer.selector;
        // V1_4 view/pure 함수들
        v1_4Selectors[13] = SeigManagerV1_4.hyperbolicSaturation.selector;
        v1_4Selectors[14] = SeigManagerV1_4.checkCurrentEligibility.selector;
        v1_4Selectors[15] = SeigManagerV1_4.calculateL2Seigniorage.selector;
        v1_4Selectors[16] = SeigManagerV1_4.calculateSequencerReward.selector;
        // V1_4 Storage getters (V1_4Storage에서 정의된 public 변수들)
        v1_4Selectors[17] = bytes4(keccak256("daoDistributionRatio()"));
        v1_4Selectors[18] = bytes4(keccak256("minStakingRatio()"));
        v1_4Selectors[19] = bytes4(keccak256("validatorDistributionRatio()"));
        v1_4Selectors[20] = bytes4(keccak256("halfSaturationPoint()"));
        v1_4Selectors[21] = bytes4(keccak256("stakedSeigFactor()"));
        v1_4Selectors[22] = bytes4(keccak256("totalEffectiveBridgedTON()"));
        v1_4Selectors[23] = bytes4(keccak256("bridgedTONInfo(address)"));
        v1_4Selectors[24] = bytes4(keccak256("validatorReward()"));
        v1_4Selectors[25] = bytes4(keccak256("maxChallengers()"));
        v1_4Selectors[26] = bytes4(keccak256("maxFraudProofCost()"));
        v1_4Selectors[27] = bytes4(keccak256("v3Migrated()"));
        v1_4Selectors[28] = bytes4(keccak256("v3MigrationBlock()"));
        v1_4Selectors[29] = bytes4(keccak256("sequencerVault()"));
        v1_4Selectors[30] = SeigManagerV1_4.getEffectiveBridgedTON.selector;

        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(v1_4Selectors, seigManagerImpl);
        // console.log("SeigManager V1_4 selectors registered (31 functions)");

        // 나머지 함수들은 V1_2 (기본 구현체)가 처리

        // Initialize DepositManager (using Base implementation - Index 0)
        DepositManager(depositManagerProxy).initialize(
            wton,
            layer2RegistryProxy,
            seigManagerProxy,
            GLOBAL_WITHDRAWAL_DELAY,
            address(0) // no old deposit manager
        );
        // console.log("DepositManager initialized");

        // =====================================================
        // DepositManager 다중 구현체 설정 (메인넷과 동일한 패턴)
        // =====================================================
        // Index 1, 2, 3 구현체 활성화
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(depositManagerSetDelayImpl, true);
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(depositManagerV1_1Impl, true);
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(depositManagerV1_2Impl, true);
        // console.log("DepositManager Index 1,2,3 implementations set alive");

        // Index 1: setWithdrawalDelay 함수 라우팅
        bytes4[] memory dmIndex1Selectors = new bytes4[](2);
        dmIndex1Selectors[0] = DepositManager_setWithdrawalDelay.setWithdrawalDelay.selector;
        dmIndex1Selectors[1] = DepositManager_setWithdrawalDelay.setWithdrawalDelayByOwner.selector;
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(dmIndex1Selectors, depositManagerSetDelayImpl);
        // console.log("DepositManager Index 1 selectors registered");

        // Index 2: V1_1 함수 라우팅
        bytes4[] memory dmIndex2Selectors = new bytes4[](3);
        dmIndex2Selectors[0] = DepositManagerV1_1.setMinDepositGasLimit.selector;
        dmIndex2Selectors[1] = DepositManagerV1_1.setAddresses.selector;
        dmIndex2Selectors[2] = DepositManagerV1_1.withdrawAndDepositL2.selector;
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(dmIndex2Selectors, depositManagerV1_1Impl);
        // console.log("DepositManager Index 2 (V1_1) selectors registered");

        // Index 3: V1_2 함수 라우팅 (V3 콜백 포함, V1_1 오버라이드)
        // V1_2에 정의된 함수만 라우팅: deposit, withdrawAndDepositL2, requestWithdrawal
        // processRequest, processRequests, view 함수들은 기본 구현체(Index 0)에 있음
        bytes4[] memory dmIndex3Selectors = new bytes4[](3);
        dmIndex3Selectors[0] = DepositManagerV1_2.deposit.selector;
        dmIndex3Selectors[1] = DepositManagerV1_2.withdrawAndDepositL2.selector;  // V1_1 오버라이드
        dmIndex3Selectors[2] = DepositManagerV1_2.requestWithdrawal.selector;
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(dmIndex3Selectors, depositManagerV1_2Impl);
        // console.log("DepositManager Index 3 (V1_2) selectors registered (3 functions)");
        // console.log("");
    }

    // ==========================================
    // Step 6.5: Setup Minter Permissions (Phase 5.5)
    // ==========================================
    function _setupMinterPermissions() internal {
        // console.log("--- Step 6.5: Setup Minter Permissions ---");

        // Layer2Registry.addMinter(seigManagerProxy)
        // SeigManager가 코이니지 생성 가능하도록
        Layer2Registry(layer2RegistryProxy).addMinter(seigManagerProxy);
        // console.log("Layer2Registry.addMinter(seigManagerProxy) done");

        // WTON.addMinter(seigManagerProxy)
        // SeigManager가 시뇨리지(WTON) 발행 가능하도록
        MockWTON(wton).addMinter(seigManagerProxy);
        // console.log("WTON.addMinter(seigManagerProxy) done");
        // console.log("");
    }

    // ==========================================
    // Step 7: Deploy OperatorManagerFactory
    // ==========================================
    function _deployOperatorManagerFactory(address deployer) internal {
        // console.log("--- Step 7: Deploy OperatorManagerFactory ---");

        // OperatorManager V1_2 구현체 배포 (V3 기본 - 모든 TYPE에서 사용)
        // V1_2를 기본으로 사용하여 향후 TYPE 3 업그레이드 지원
        operatorManagerImpl = address(new OperatorManagerV1_2());
        // console.log("OperatorManagerV1_2 Impl:", operatorManagerImpl);

        // Factory 배포 (V1_2를 기본 구현체로 사용)
        operatorManagerFactory = address(new OperatorManagerFactory(operatorManagerImpl));
        // console.log("OperatorManagerFactory:", operatorManagerFactory);
        // console.log("");
    }

    // ==========================================
    // Step 8: Deploy V3 Contracts (RAT, ValidatorReward)
    // ==========================================
    function _deployV3Contracts(address deployer) internal {
        // console.log("--- Step 8: Deploy V3 Contracts ---");

        // Deploy RAT implementation
        ratImpl = address(new RAT());
        // console.log("RAT Impl:", ratImpl);

        // Prepare RAT initialization data
        // NOTE: ratTriggerProbability should be determined based on game theory formula:
        // C_off ≥ (c_m · N) / π_a
        uint256 ratTriggerProbability = 0.01e27; // 1% - adjust based on expected N, c_m, C_off
        bytes memory ratInitData = abi.encodeWithSelector(
            RAT.initialize.selector,
            seigManagerProxy,
            wton,
            ton,
            layer2ManagerProxy,
            deployer,
            ratTriggerProbability
        );

        // Deploy RAT proxy with deployer as admin
        ratProxy = address(new RATProxy(ratImpl, deployer, ratInitData));
        // console.log("RAT Proxy:", ratProxy);
        // console.log("RAT initialized");

        // Deploy ValidatorReward implementation
        validatorPoolImpl = address(new ValidatorRewardV1());
        // console.log("ValidatorReward Impl:", validatorPoolImpl);

        // Prepare ValidatorReward initialization data
        // NOTE: treasury 파라미터 제거됨 - 검증자 없는 L2의 보상은 SeigManager.dao()로 전송
        bytes memory validatorRewardInitData = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            seigManagerProxy,
            wton,
            ratProxy,   // RAT contract for validator info
            deployer    // owner
        );

        // Deploy ValidatorReward proxy with deployer as admin
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, deployer, validatorRewardInitData));
        // console.log("ValidatorReward Proxy:", validatorPoolProxy);
        // console.log("ValidatorReward initialized");

        // Deploy SequencerVault (Proxy + Implementation 패턴 - RAT/ValidatorReward와 다름)
        // SequencerVaultProxy는 Proxy 상속으로 upgradeTo() 후 initialize() 호출
        sequencerVaultImpl = address(new SequencerVault());
        // console.log("SequencerVault Impl:", sequencerVaultImpl);

        SequencerVaultProxy svProxy = new SequencerVaultProxy();
        sequencerVaultProxy = address(svProxy);
        // console.log("SequencerVault Proxy:", sequencerVaultProxy);

        // upgradeTo (Proxy 패턴)
        IProxy(sequencerVaultProxy).upgradeTo(sequencerVaultImpl);

        // initialize
        SequencerVault(sequencerVaultProxy).initialize(
            seigManagerProxy,
            wton,
            ton,
            layer2ManagerProxy,
            l1BridgeRegistryProxy,
            deployer
        );
        // console.log("SequencerVault initialized");
        // console.log("");
    }

    // ==========================================
    // Step 9: Configure V3 Contracts
    // ==========================================
    function _configureV3Contracts(address deployer) internal {
        // console.log("--- Step 9: Configure V3 Parameters ---");

        // RAT parameters
        RAT(ratProxy).setRatTriggerProbability(RAT_TRIGGER_PROBABILITY);
        RAT(ratProxy).setSlashingPenalty(RAT_SLASHING_PENALTY);
        RAT(ratProxy).setValidatorBuffer(RAT_VALIDATOR_BUFFER);
        RAT(ratProxy).setMinimumThreshold(RAT_MINIMUM_THRESHOLD);
        RAT(ratProxy).setEvidenceSubmissionPeriod(RAT_EVIDENCE_PERIOD);
        RAT(ratProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);
        RAT(ratProxy).setTreasury(deployer);
        // console.log("RAT parameters configured");

        // ValidatorReward는 별도 파라미터 설정 불필요
        // (RAT에서 검증자 정보를 조회하고 SeigManager에서 호출)
        // console.log("ValidatorReward ready");
        // console.log("");
    }

    // ==========================================
    // Step 10: Setup Cross-References
    // ==========================================
    function _setupCrossReferences(address deployer) internal {
        // console.log("--- Step 10: Setup Cross-References ---");

        // SeigManager -> Layer2Manager (V1_2에 정의됨)
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        // console.log("SeigManager.setLayer2Manager done");

        // SeigManager -> ValidatorReward
        SeigManagerV1_4(seigManagerProxy).setValidatorReward(validatorPoolProxy);
        // console.log("SeigManager.setValidatorReward done");

        // Layer2Manager.setAddresses (using V1_1 interface - Index 0)
        Layer2ManagerV1_1(layer2ManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton,
            deployer, // dao (use deployer for testing)
            depositManagerProxy,
            seigManagerProxy,
            address(0) // swapProxy (not needed for testing)
        );
        // console.log("Layer2Manager.setAddresses done");

        // =====================================================
        // Layer2Manager 다중 구현체 설정 (메인넷과 동일한 패턴)
        // =====================================================
        // Index 0: V1_1 (이미 기본으로 설정됨 - setAddresses 포함)
        // Index 1: V1_2 (V3 BridgedTON 함수)

        // V1_2를 alive 상태로 설정
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(layer2ManagerImpl, true);
        // console.log("Layer2Manager V1_2 implementation set alive");

        // V1_2 함수 selectors 등록 (V3 신규 함수들)
        bytes4[] memory l2mV1_2Selectors = new bytes4[](5);
        l2mV1_2Selectors[0] = Layer2ManagerV1_2.getBridgedTONByLayer.selector;
        l2mV1_2Selectors[1] = Layer2ManagerV1_2.getBridgedTON.selector;
        l2mV1_2Selectors[2] = Layer2ManagerV1_2.getLayer2BySystemConfig.selector;
        l2mV1_2Selectors[3] = Layer2ManagerV1_2.setSequencerVault.selector;
        l2mV1_2Selectors[4] = bytes4(keccak256("sequencerVault()"));
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(l2mV1_2Selectors, layer2ManagerImpl);
        // console.log("Layer2Manager V1_2 selectors registered (5 functions)");

        // Layer2Manager.setSequencerVault (V3 - OperatorManager가 자동 조회)
        Layer2ManagerV1_2(layer2ManagerProxy).setSequencerVault(sequencerVaultProxy);
        // console.log("Layer2Manager.setSequencerVault done");

        // L1BridgeRegistry.setAddresses (using V1_1 interface - Index 0)
        // L1BridgeRegistry uses V1_2 only (has all V1_1 functions + TYPE 3 support)
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(
            layer2ManagerProxy,
            seigManagerProxy,
            ton
        );
        // console.log("L1BridgeRegistry.setAddresses done");

        // OperatorManagerFactory.setAddresses
        OperatorManagerFactory(operatorManagerFactory).setAddresses(
            depositManagerProxy,
            ton,
            wton,
            layer2ManagerProxy
        );
        // console.log("OperatorManagerFactory.setAddresses done");

        // DepositManager.setAddresses (V1_1 - Index 2로 라우팅됨)
        DepositManagerV1_1(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
        // console.log("DepositManager.setAddresses done");
        // console.log("");
    }

    // ==========================================
    // Output Summary
    // ==========================================
    function _printSummary() internal view {
        console.log("=== Deployment Summary ===");
        console.log("");
        console.log("Tokens:");
        console.log("  TON:", ton);
        console.log("  WTON:", wton);
        console.log("");
        console.log("Core Infrastructure:");
        console.log("  CoinageFactory:", coinageFactory);
        console.log("  Layer2Registry Proxy:", layer2RegistryProxy);
        console.log("");
        console.log("Managers (Proxies):");
        console.log("  SeigManager Proxy:", seigManagerProxy);
        console.log("  DepositManager Proxy:", depositManagerProxy);
        console.log("  Layer2Manager Proxy:", layer2ManagerProxy);
        console.log("  L1BridgeRegistry Proxy:", l1BridgeRegistryProxy);
        console.log("");
        console.log("V3 Contracts:");
        console.log("  RAT Proxy:", ratProxy);
        console.log("  ValidatorReward Proxy:", validatorPoolProxy);
        console.log("  SequencerVault Proxy:", sequencerVaultProxy);
        console.log("");
        console.log("Factory:");
        console.log("  OperatorManagerFactory:", operatorManagerFactory);
    }

    function _saveDeployment() internal {
        string memory output = string(abi.encodePacked(
            "{\n",
            '  "ton": "', vm.toString(ton), '",\n',
            '  "wton": "', vm.toString(wton), '",\n',
            '  "coinageFactory": "', vm.toString(coinageFactory), '",\n',
            '  "layer2RegistryProxy": "', vm.toString(layer2RegistryProxy), '",\n',
            '  "seigManagerProxy": "', vm.toString(seigManagerProxy), '",\n',
            '  "depositManagerProxy": "', vm.toString(depositManagerProxy), '",\n',
            '  "layer2ManagerProxy": "', vm.toString(layer2ManagerProxy), '",\n',
            '  "l1BridgeRegistryProxy": "', vm.toString(l1BridgeRegistryProxy), '",\n',
            '  "operatorManagerFactory": "', vm.toString(operatorManagerFactory), '",\n',
            '  "ratProxy": "', vm.toString(ratProxy), '",\n',
            '  "validatorPoolProxy": "', vm.toString(validatorPoolProxy), '",\n',
            '  "sequencerVaultProxy": "', vm.toString(sequencerVaultProxy), '"\n',
            "}"
        ));

        vm.writeFile("deployments/v3-full.json", output);
        // console.log("\nDeployment saved to deployments/v3-full.json");
    }
}

/**
 * @title DeployV3FullLocal
 * @notice 로컬 Anvil 테스트용 간소화된 배포
 * @dev anvil 실행 후: forge script script/DeployV3Full.s.sol:DeployV3FullLocal --rpc-url http://localhost:8545 --broadcast -vvvv
 */
contract DeployV3FullLocal is DeployV3Full {
    function run() external override {
        // Anvil default private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        // console.log("=== V3 Local Deployment ===");
        // console.log("Deployer:", deployer);
        // console.log("");

        vm.startBroadcast(deployerPrivateKey);

        _deployTokens();
        _deployCoinageInfrastructure(deployer);
        _deployLayer2Registry(deployer);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(deployer);
        _setupMinterPermissions();  // Phase 5.5: Minter 권한 설정
        _deployOperatorManagerFactory(deployer);
        _deployV3Contracts(deployer);
        _configureV3Contracts(deployer);
        _setupCrossReferences(deployer);

        vm.stopBroadcast();

        _printSummary();
        _saveDeployment();
    }
}

/**
 * @title DeployV3FullE2E
 * @notice E2E 테스트용 배포 스크립트 (배포 주소를 반환)
 * @dev Go 테스트에서 호출하여 사용
 */
contract DeployV3FullE2E is DeployV3Full {
    // Struct to return all deployed addresses
    struct DeployedAddresses {
        address ton;
        address wton;
        address coinageFactory;
        address layer2RegistryProxy;
        address seigManagerProxy;
        address depositManagerProxy;
        address layer2ManagerProxy;
        address l1BridgeRegistryProxy;
        address operatorManagerFactory;
        address ratProxy;
        address validatorPoolProxy;
        address sequencerVaultProxy;
    }

    function deployAll(address deployer) external returns (DeployedAddresses memory) {
        _deployTokens();
        _deployCoinageInfrastructure(deployer);
        _deployLayer2Registry(deployer);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(deployer);
        _setupMinterPermissions();  // Phase 5.5: Minter 권한 설정
        _deployOperatorManagerFactory(deployer);
        _deployV3Contracts(deployer);
        _configureV3Contracts(deployer);
        _setupCrossReferences(deployer);

        return DeployedAddresses({
            ton: ton,
            wton: wton,
            coinageFactory: coinageFactory,
            layer2RegistryProxy: layer2RegistryProxy,
            seigManagerProxy: seigManagerProxy,
            depositManagerProxy: depositManagerProxy,
            layer2ManagerProxy: layer2ManagerProxy,
            l1BridgeRegistryProxy: l1BridgeRegistryProxy,
            operatorManagerFactory: operatorManagerFactory,
            ratProxy: ratProxy,
            validatorPoolProxy: validatorPoolProxy,
            sequencerVaultProxy: sequencerVaultProxy
        });
    }
}
