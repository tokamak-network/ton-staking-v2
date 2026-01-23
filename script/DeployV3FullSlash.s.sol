 // // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "forge-std/Script.sol";
// import "forge-std/console.sol";

// // Core Infrastructure
// import {CoinageFactory} from "../src/stake/factory/CoinageFactory.sol";
// import {RefactorCoinageSnapshot} from "../src/stake/tokens/RefactorCoinageSnapshot.sol";
// import {RefactorCoinageSnapshotProxy} from "../src/stake/tokens/RefactorCoinageSnapshotProxy.sol";
// import {Layer2Registry} from "../src/stake/Layer2Registry.sol";
// import {Layer2RegistryProxy} from "../src/stake/Layer2RegistryProxy.sol";

// // Manager Implementations - V3
// import {SeigManagerV1_2} from "../src/stake/managers/SeigManagerV1_2.sol";
// import {SeigManagerV3_1} from "../src/stake/managers/SeigManagerV3_1.sol";
// import {SeigManagerV3_2} from "../src/stake/managers/SeigManagerV3_2.sol";
// import {DepositManagerV3} from "../src/stake/managers/DepositManagerV3.sol";
// import {Layer2ManagerV3} from "../src/layer2/Layer2ManagerV3.sol";
// import {L1BridgeRegistryV1_2} from "../src/layer2/L1BridgeRegistryV1_2.sol";

// // Slashing Implementations
// import {Layer2Manager_Slashing} from "../src/layer2/Layer2Manager_Slashing.sol";
// import {SeigManager_Slashing} from "../src/stake/managers/SeigManager_Slashing.sol";
// import {DepositManager_Slashing} from "../src/stake/managers/DepositManager_Slashing.sol";

// // Manager Proxies (ProxySeigManager has setAliveImplementation2, setSelectorImplementations2)
// import {SeigManagerProxy} from "../src/stake/managers/SeigManagerProxy.sol";
// import {DepositManagerProxy} from "../src/stake/managers/DepositManagerProxy.sol";
// import {Layer2ManagerProxy} from "../src/layer2/Layer2ManagerProxy.sol";
// import {L1BridgeRegistryProxy} from "../src/layer2/L1BridgeRegistryProxy.sol";

// // Operator Manager
// import {OperatorManagerFactory} from "../src/layer2/factory/OperatorManagerFactory.sol";
// import {OperatorManagerV1_2} from "../src/layer2/OperatorManagerV1_2.sol";

// // V3 New Contracts
// import {RAT} from "../src/validator/RAT.sol";
// import {RATInitParams, RATConfigParams} from "../src/validator/RATTypes.sol";
// import {RATProxy} from "../src/validator/RATProxy.sol";
// import {ValidatorRewardV1} from "../src/validator/ValidatorRewardV1.sol";
// import {ValidatorRewardProxy} from "../src/validator/ValidatorRewardProxy.sol";

// // Mocks for testing
// import {MockTON} from "../src/mocks/MockTON.sol";
// import {MockWTON} from "../src/mocks/MockWTON.sol";

// // DAO Committee
// import {DAOCommitteeProxy2} from "../src/proxy/DAOCommitteeProxy2.sol";
// import {DAOCommittee_V1} from "../src/dao/DAOCommittee_V1.sol";
// import {DAOCommitteeOwner} from "../src/dao/DAOCommitteeOwner.sol";
// import {Candidate} from "../src/dao/Candidate.sol";
// import {CandidateFactory} from "../src/dao/factory/CandidateFactory.sol";
// import {CandidateFactoryProxy} from "../src/dao/factory/CandidateFactoryProxy.sol";
// import {CandidateAddOnV1_1} from "../src/dao/CandidateAddOnV1_1.sol";
// import {CandidateAddOnFactory} from "../src/dao/factory/CandidateAddOnFactory.sol";
// import {CandidateAddOnFactoryProxy} from "../src/dao/factory/CandidateAddOnFactoryProxy.sol";

// /// @notice Proxy interface
// interface IProxy {
//     function upgradeTo(address impl) external;
//     function implementation() external view returns (address);
// }

// /**
//  * @title DeployV3FullSlash
//  * @notice 새 체인용 전체 배포 스크립트 (아무것도 없는 체인에서 처음부터 모든 것을 배포)
//  * @dev forge script script/DeployV3FullSlash.s.sol:DeployV3FullSlash --rpc-url $RPC_URL --broadcast -vvvv
//  *
//  * 이 스크립트는 TON Staking V3 전체 시스템을 처음부터 배포합니다:
//  * - Mock TON/WTON 토큰
//  * - CoinageFactory 및 RefactorCoinageSnapshot
//  * - Layer2Registry
//  * - SeigManager (프록시 + 구현체)
//  * - DepositManager (프록시 + 구현체)
//  * - Layer2Manager (프록시 + 구현체)
//  * - L1BridgeRegistry (프록시 + 구현체)
//  * - OperatorManagerFactory
//  * - RAT (프록시 + 구현체)
//  * - ValidatorReward (프록시 + 구현체)
//  */
// contract DeployV3FullSlash is Script {
//     // ==========================================
//     // Deployment Parameters
//     // ==========================================

//     // SeigManager parameters
//     uint256 constant SEIG_PER_BLOCK = 3.92e18; // 3.92 TON per block
//     uint256 constant GLOBAL_WITHDRAWAL_DELAY = 93046; // ~2 weeks in blocks (assuming 13s blocks)

//     // RAT parameters
//     uint256 constant RAT_TRIGGER_PROBABILITY = 0.01e27; // 1% (RAY)
//     uint256 constant RAT_SLASHING_PENALTY = 100e27; // 100 WTON (RAY)
//     uint256 constant RAT_VALIDATOR_BUFFER = 100e27; // 100 WTON (RAY)
//     uint256 constant RAT_MINIMUM_THRESHOLD = 1000e27; // 1000 WTON (RAY)
//     uint256 constant RAT_EVIDENCE_PERIOD = 1 hours;
//     uint256 constant RAT_MAX_VALIDATORS_PER_L2 = 100; // Maximum validators per L2
//     uint256 constant RAT_CHALLENGE_GAME_DURATION = 7 days; // Challenge game period
//     uint256 constant RAT_SAFETY_BUFFER = 1 days; // Safety buffer period
//     uint256 constant RAT_ATTENTION_COST = 1e27; // c_m: 1 TON per epoch (RAY unit)
//     bool constant RAT_RELAXED_VALIDATOR_CHECK = true; // V3: 초기에는 C_off 기준으로 완화

//     // ==========================================
//     // Deployed Addresses
//     // ==========================================

//     // Tokens
//     address public ton;
//     address public wton;

//     // Core Infrastructure
//     address public coinageFactory;
//     address public coinageLogic;
//     address public layer2RegistryProxy;
//     address public layer2RegistryImpl;

//     // Managers (Proxies)
//     address public seigManagerProxy;
//     address public depositManagerProxy;
//     address public layer2ManagerProxy;
//     address public l1BridgeRegistryProxy;

//     // SeigManager 다중 구현체 (V3: V1_2 기본 + V3_1, V3_2 추가)
//     address public seigManagerV3_1Impl; // V3_1: V3 메인 기능
//     address public seigManagerV3_2Impl; // V3_2: V2 호환 로직

//     // DepositManager 단일 구현체 (V3)
//     address public depositManagerImpl; // DepositManagerV3 단일 구현체

//     // Layer2Manager 단일 구현체 (V3)
//     address public layer2ManagerImpl; // Layer2ManagerV3 단일 구현체

//     // L1BridgeRegistry 다중 구현체
//     // l1BridgeRegistryV1_1Impl removed - V1_2 has all V1_1 functions
//     address public l1BridgeRegistryImpl; // Index 1: V1_2 (DisputeGame support)

//     // Operator Manager
//     address public operatorManagerFactory;
//     address public operatorManagerImpl;

//     // V3 Contracts
//     address public ratProxy;
//     address public ratImpl;
//     address public validatorPoolProxy;
//     address public validatorPoolImpl;

//     // Slashing Implementations
//     address public seigManagerSlashingImpl;
//     address public depositManagerSlashingImpl;
//     address public layer2ManagerSlashingImpl;

//     // DAO Committee
//     address public daoVault;
//     address public daoAgendaManager;
//     address public daoCommitteeProxy; // ABI deployment
//     DAOCommitteeProxy2 public daoCommitteeProxy2;
//     DAOCommittee_V1 public daoCommitteeImpl;
//     DAOCommitteeOwner public daoCommitteeOwner;
//     Candidate public candidateImpl;
//     CandidateFactory public candidateFactoryLogic;
//     CandidateFactoryProxy public candidateFactoryProxy;
//     CandidateAddOnV1_1 public candidateAddOnImpl;
//     CandidateAddOnFactory public candidateAddOnFactoryLogic;
//     CandidateAddOnFactoryProxy public candidateAddOnFactoryProxy;

//     // Slashing parameters
//     uint256 constant SLASHING_REWARD_RATE = 1000; // 10% = 1000 (basis points)

//     // Proxy Admin for TransparentUpgradeableProxy contracts (RAT, ValidatorReward)
//     // Using a separate admin to avoid "admin cannot fallback to proxy target" issue
//     address public proxyAdmin;

//     /// @notice Returns the proxy admin address
//     /// @dev Override this in tests to use a different admin (e.g., address(1))
//     function _getProxyAdmin(address deployer) internal view virtual returns (address) {
//         return deployer; // Default: deployer is admin (for production)
//     }

//     function run() external virtual {
//         uint256 deployerPrivateKey = vm.envOr(
//             "PRIVATE_KEY",
//             uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
//         );
//         address deployer = vm.addr(deployerPrivateKey);
//         proxyAdmin = _getProxyAdmin(deployer);

//         // console.log("=== TON Staking V3 Full Deployment ===");
//         // console.log("Deployer:", deployer);
//         // console.log("Chain ID:", block.chainid);
//         // console.log("");

//         vm.startBroadcast(deployerPrivateKey);

//         _deployTokens();
//         _deployCoinageInfrastructure(deployer);
//         _deployLayer2Registry(deployer);
//         _deployManagerProxies();
//         _deployManagerImplementations();
//         _initializeManagers(deployer);
//         _setupMinterPermissions(); // Phase 5.5: Minter 권한 설정
//         _deployOperatorManagerFactory(deployer);
//         _deployV3Contracts(deployer);
//         _configureV3Contracts(deployer);
//         _setupCrossReferences(deployer);

//         _deployDAOVault();
//         _deployDAOAgendaManager();
//         _deployDAOCommittee();
//         _addMinterSetting();
//         _addSeigManagerSetting();
//         _setupContractOwner();

//         vm.stopBroadcast();

//         _printSummary();
//         _saveDeployment();
//     }

//     // ==========================================
//     // Step 1: Deploy Tokens
//     // ==========================================
//     function _deployTokens() internal {
//         // console.log("--- Step 1: Deploy Tokens ---");

//         ton = address(new MockTON());
//         // console.log("TON:", ton);

//         MockWTON wtonContract = new MockWTON();
//         wtonContract.setTON(ton);
//         wton = address(wtonContract);
//         // console.log("WTON:", wton);
//         // console.log("");
//     }

//     // ==========================================
//     // Step 2: Deploy Coinage Infrastructure
//     // ==========================================
//     function _deployCoinageInfrastructure(address deployer) internal {
//         // console.log("--- Step 2: Deploy Coinage Infrastructure ---");

//         // Deploy RefactorCoinageSnapshot logic
//         coinageLogic = address(new RefactorCoinageSnapshot());
//         // console.log("RefactorCoinageSnapshot Logic:", coinageLogic);

//         // Deploy CoinageFactory
//         CoinageFactory factory = new CoinageFactory();
//         factory.setAutoCoinageLogic(coinageLogic);
//         coinageFactory = address(factory);
//         // console.log("CoinageFactory:", coinageFactory);
//         // console.log("");
//     }

//     // ==========================================
//     // Step 3: Deploy Layer2Registry
//     // ==========================================
//     function _deployLayer2Registry(address deployer) internal {
//         // console.log("--- Step 3: Deploy Layer2Registry ---");

//         layer2RegistryImpl = address(new Layer2Registry());
//         // console.log("Layer2Registry Impl:", layer2RegistryImpl);

//         Layer2RegistryProxy registryProxy = new Layer2RegistryProxy();
//         IProxy(address(registryProxy)).upgradeTo(layer2RegistryImpl);
//         layer2RegistryProxy = address(registryProxy);
//         // console.log("Layer2Registry Proxy:", layer2RegistryProxy);
//         // console.log("");
//     }

//     // ==========================================
//     // Step 4: Deploy Manager Proxies
//     // ==========================================
//     function _deployManagerProxies() internal {
//         // console.log("--- Step 4: Deploy Manager Proxies ---");

//         seigManagerProxy = address(new SeigManagerProxy());
//         // console.log("SeigManager Proxy:", seigManagerProxy);

//         depositManagerProxy = address(new DepositManagerProxy());
//         // console.log("DepositManager Proxy:", depositManagerProxy);

//         layer2ManagerProxy = address(new Layer2ManagerProxy());
//         // console.log("Layer2Manager Proxy:", layer2ManagerProxy);

//         l1BridgeRegistryProxy = address(new L1BridgeRegistryProxy());
//         // console.log("L1BridgeRegistry Proxy:", l1BridgeRegistryProxy);
//         // console.log("");
//     }

//     // ==========================================
//     // Step 5: Deploy Manager Implementations
//     // ==========================================
//     function _deployManagerImplementations() internal {
//         // console.log("--- Step 5: Deploy Manager Implementations ---");

//         // SeigManager: V1_2를 기본 구현체로 사용
//         // V3_1, V3_2는 selector routing으로 추가 (V3 신규 함수)
//         address seigManagerV1_2Impl = address(new SeigManagerV1_2());
//         // console.log("SeigManagerV1_2 Impl:", seigManagerV1_2Impl);
//         IProxy(seigManagerProxy).upgradeTo(seigManagerV1_2Impl);

//         // V3_1: V3 메인 기능 (pause/unpause, updateSeigniorage V3, RAT 통합 등)
//         seigManagerV3_1Impl = address(new SeigManagerV3_1());
//         // console.log("SeigManagerV3_1 Impl:", seigManagerV3_1Impl);

//         // V3_2: V2 호환 로직 (delegatecall로 호출됨)
//         seigManagerV3_2Impl = address(new SeigManagerV3_2());
//         // console.log("SeigManagerV3_2 Impl:", seigManagerV3_2Impl);

//         // DepositManager: V3 단일 구현체
//         depositManagerImpl = address(new DepositManagerV3());
//         // console.log("DepositManagerV3 Impl:", depositManagerImpl);
//         IProxy(depositManagerProxy).upgradeTo(depositManagerImpl);

//         // Layer2Manager: V3 단일 구현체
//         layer2ManagerImpl = address(new Layer2ManagerV3());
//         // console.log("Layer2ManagerV3 Impl:", layer2ManagerImpl);
//         IProxy(layer2ManagerProxy).upgradeTo(layer2ManagerImpl);

//         // L1BridgeRegistry: V1_2 단일 구현체 (TYPE 3 support)
//         l1BridgeRegistryImpl = address(new L1BridgeRegistryV1_2());
//         // console.log("L1BridgeRegistryV1_2 Impl:", l1BridgeRegistryImpl);
//         IProxy(l1BridgeRegistryProxy).upgradeTo(l1BridgeRegistryImpl);
//         // console.log("");

//         // Slashing Implementations
//         seigManagerSlashingImpl = address(new SeigManager_Slashing());
//         // console.log("SeigManager_Slashing Impl:", seigManagerSlashingImpl);

//         depositManagerSlashingImpl = address(new DepositManager_Slashing());
//         // console.log("DepositManager_Slashing Impl:", depositManagerSlashingImpl);

//         layer2ManagerSlashingImpl = address(new Layer2Manager_Slashing());
//         // console.log("Layer2Manager_Slashing Impl:", layer2ManagerSlashingImpl);

//         // console.log("");
//     }

//     // ==========================================
//     // Step 6: Initialize Managers
//     // ==========================================
//     function _initializeManagers(address deployer) internal {
//         // console.log("--- Step 6: Initialize Managers ---");

//         // Initialize SeigManager (using V1_2 - 메인넷과 동일하게)
//         SeigManagerV1_2(seigManagerProxy).initialize(
//             ton,
//             wton,
//             layer2RegistryProxy,
//             depositManagerProxy,
//             SEIG_PER_BLOCK,
//             coinageFactory,
//             block.number // lastSeigBlock = current block
//         );
//         // console.log("SeigManager initialized");

//         // setData: 시뇨리지 분배 비율 설정 (V1_2 함수)
//         SeigManagerV1_2(seigManagerProxy).setData(
//             address(0), // powerTON (테스트시 address(0))
//             deployer, // dao address (테스트시 deployer)
//             0, // powerTONSeigRate: 0%
//             0.5e27, // daoSeigRate: 50%
//             0.5e27, // relativeSeigRate: 50%
//             93096, // adjustCommissionDelay
//             1000.1e27 // minimumAmount: 1000.1 WTON
//         );
//         // console.log("SeigManager setData done");

//         // =====================================================
//         // SeigManager 다중 구현체 설정 (V3: V1_2 기본 + V3_1, V3_2)
//         // =====================================================
//         _setupSeigManagerV3Routing();

//         // SeigManager Slashing routing
//         SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
//             seigManagerSlashingImpl,
//             true
//         );
//         bytes4[] memory seigSlashingSelectors = new bytes4[](1);
//         seigSlashingSelectors[0] = SeigManager_Slashing.onSlash.selector;
//         SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
//             seigSlashingSelectors,
//             seigManagerSlashingImpl
//         );

//         // 나머지 함수들은 V1_2 (기본 구현체)가 처리

//         // Initialize DepositManager (V3 단일 구현체)
//         DepositManagerV3(depositManagerProxy).initialize(
//             wton,
//             layer2RegistryProxy,
//             seigManagerProxy,
//             GLOBAL_WITHDRAWAL_DELAY,
//             address(0) // no old deposit manager
//         );
//         // console.log("DepositManager initialized");
//         // console.log("");

//         // DepositManager Slashing routing
//         DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
//             depositManagerSlashingImpl,
//             true
//         );
//         bytes4[] memory dmSlashingSelectors = new bytes4[](3);
//         dmSlashingSelectors[0] = DepositManager_Slashing.setSlashingRewardRate.selector;
//         dmSlashingSelectors[1] = DepositManager_Slashing.slash.selector;
//         dmSlashingSelectors[2] = bytes4(keccak256("slashingRewardRate()"));
//         DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(
//             dmSlashingSelectors,
//             depositManagerSlashingImpl
//         );

//         // SlashingRewardRate Setting
//         DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(
//             SLASHING_REWARD_RATE
//         );
//     }

//     // ==========================================
//     // SeigManager V3 Selector Routing (분리하여 stack too deep 회피)
//     // NOTE: selector 배열 크기를 줄이거나, 테스트 시 필요한 함수만 등록
//     // 전체 함수 목록은 별도의 setup 스크립트에서 처리 권장
//     // ==========================================
//     function _setupSeigManagerV3Routing() internal {
//         // V3_1, V3_2를 alive 상태로 설정
//         SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
//             seigManagerV3_1Impl,
//             true
//         );
//         SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
//             seigManagerV3_2Impl,
//             true
//         );

//         // 핵심 함수만 등록 (stack too deep 회피)
//         // 전체 함수 등록은 별도 스크립트 또는 production 프로필 필요
//         _setupSeigManagerV3CoreSelectors();

//         // V3_1에 v2Logic 주소 설정 (V2 호환성을 위해)
//         SeigManagerV3_1(seigManagerProxy).setV2Logic(seigManagerV3_2Impl);
//     }

//     function _setupSeigManagerV3CoreSelectors() internal {
//         // 핵심 함수만 등록 (6개) - 테스트/배포에 필요한 최소 함수
//         bytes4[] memory s = new bytes4[](6);
//         s[0] = SeigManagerV3_1.setValidatorReward.selector;
//         s[1] = SeigManagerV3_1.setV2Logic.selector;
//         s[2] = SeigManagerV3_1.migrateToV3.selector;
//         s[3] = SeigManagerV3_1.updateSeigniorage.selector;
//         s[4] = SeigManagerV3_1.setRatContract.selector;
//         s[5] = bytes4(keccak256("v3Migrated()"));
//         SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
//             s,
//             seigManagerV3_1Impl
//         );
//     }

//     /// @notice Register additional V3 selectors for parameter setters and view functions
//     /// @dev Call this in test setUp() after _deployManagerImplementations() to enable V3 functions
//     function _setupSeigManagerV3ParameterSelectors() internal virtual {
//         // V3 Parameter setter functions (9개)
//         bytes4[] memory setters = new bytes4[](9);
//         setters[0] = SeigManagerV3_1.setDaoDistributionRatio.selector;
//         setters[1] = SeigManagerV3_1.setMinStakingRatio.selector;
//         setters[2] = SeigManagerV3_1.setValidatorDistributionRatio.selector;
//         setters[3] = SeigManagerV3_1.setHalfSaturationPoint.selector;
//         setters[4] = SeigManagerV3_1.setStakedSeigFactor.selector;
//         setters[5] = SeigManagerV3_1.setMaxChallengers.selector;
//         setters[6] = SeigManagerV3_1.setMaxFraudProofCost.selector;
//         setters[7] = SeigManagerV3_1.setSequencerAdditionalReward.selector;
//         setters[8] = SeigManagerV3_1.excludeFromL2Seigniorage.selector;
//         SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
//             setters,
//             seigManagerV3_1Impl
//         );
//     }

//     /// @notice Register V3 view function selectors
//     /// @dev Call this in test setUp() for tests that need V3 view functions
//     function _setupSeigManagerV3ViewSelectors() internal virtual {
//         // V3 View functions (20개)
//         bytes4[] memory views = new bytes4[](20);
//         views[0] = SeigManagerV3_1.getEffectiveBridgedTon.selector;
//         views[1] = SeigManagerV3_1.checkCurrentEligibility.selector;
//         views[2] = SeigManagerV3_1.getSequencerStaked.selector;
//         views[3] = SeigManagerV3_1.hyperbolicSaturation.selector;
//         views[4] = SeigManagerV3_1.calculateL2Seigniorage.selector;
//         views[5] = SeigManagerV3_1.calculateSequencerReward.selector;
//         views[6] = SeigManagerV3_1.estimateL2Seigniorage.selector;
//         views[7] = SeigManagerV3_1.claimableL2Seigniorage.selector;
//         views[8] = bytes4(keccak256("daoDistributionRatio()"));
//         views[9] = bytes4(keccak256("halfSaturationPoint()"));
//         views[10] = bytes4(keccak256("totalEffectiveBridgedTON()"));
//         views[11] = bytes4(keccak256("v3MigrationBlock()"));
//         views[12] = bytes4(keccak256("ratContract()"));
//         views[13] = bytes4(keccak256("validatorReward()"));
//         views[14] = bytes4(keccak256("minStakingRatio()"));
//         views[15] = bytes4(keccak256("validatorDistributionRatio()"));
//         views[16] = bytes4(keccak256("stakedSeigFactor()"));
//         views[17] = bytes4(keccak256("maxChallengers()"));
//         views[18] = bytes4(keccak256("maxFraudProofCost()"));
//         views[19] = bytes4(keccak256("sequencerAdditionalReward()"));
//         SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
//             views,
//             seigManagerV3_1Impl
//         );
//     }

//     /// @notice Register all V3 selectors including callbacks
//     /// @dev Call this in test setUp() for comprehensive V3 functionality
//     function _setupSeigManagerV3AllTestSelectors() internal virtual {
//         _setupSeigManagerV3ParameterSelectors();
//         _setupSeigManagerV3ViewSelectors();

//         // Callback and additional functions (5개)
//         bytes4[] memory callbacks = new bytes4[](5);
//         callbacks[0] = SeigManagerV3_1.onBridgedTonChange.selector;
//         callbacks[1] = SeigManagerV3_1.onStakingChange.selector;
//         callbacks[2] = SeigManagerV3_1.transferCoinageToRat.selector;
//         callbacks[3] = SeigManagerV3_1.transferCoinageFromRat.selector;
//         callbacks[4] = SeigManagerV3_1.transferCoinageFromRatTo.selector;
//         SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
//             callbacks,
//             seigManagerV3_1Impl
//         );
//     }

//     // ==========================================
//     // Step 6.5: Setup Minter Permissions (Phase 5.5)
//     // ==========================================
//     function _setupMinterPermissions() internal {
//         // console.log("--- Step 6.5: Setup Minter Permissions ---");

//         // Layer2Registry.addMinter(seigManagerProxy)
//         // SeigManager가 코이니지 생성 가능하도록
//         Layer2Registry(layer2RegistryProxy).addMinter(seigManagerProxy);
//         // console.log("Layer2Registry.addMinter(seigManagerProxy) done");

//         // WTON.addMinter(seigManagerProxy)
//         // SeigManager가 시뇨리지(WTON) 발행 가능하도록
//         MockWTON(wton).addMinter(seigManagerProxy);
//         // console.log("WTON.addMinter(seigManagerProxy) done");
//         // console.log("");
//     }

//     // ==========================================
//     // Step 7: Deploy OperatorManagerFactory
//     // ==========================================
//     function _deployOperatorManagerFactory(address deployer) internal {
//         // console.log("--- Step 7: Deploy OperatorManagerFactory ---");

//         // OperatorManager V1_2 구현체 배포 (V3 기본 - 모든 TYPE에서 사용)
//         // V1_2를 기본으로 사용하여 향후 TYPE 3 업그레이드 지원
//         operatorManagerImpl = address(new OperatorManagerV1_2());
//         // console.log("OperatorManagerV1_2 Impl:", operatorManagerImpl);

//         // Factory 배포 (V1_2를 기본 구현체로 사용)
//         operatorManagerFactory = address(new OperatorManagerFactory(operatorManagerImpl));
//         // console.log("OperatorManagerFactory:", operatorManagerFactory);
//         // console.log("");
//     }

//     // ==========================================
//     // Step 8: Deploy V3 Contracts (RAT, ValidatorReward)
//     // ==========================================
//     function _deployV3Contracts(address deployer) internal {
//         // console.log("--- Step 8: Deploy V3 Contracts ---");

//         // Deploy RAT implementation
//         ratImpl = address(new RAT());
//         // console.log("RAT Impl:", ratImpl);

//         // RAT 프록시는 별도 배포 (stack too deep 회피)
//         ratProxy = _deployRATProxy(deployer);
//         // console.log("RAT Proxy:", ratProxy);
//         // console.log("RAT initialized");

//         // Deploy ValidatorReward implementation
//         validatorPoolImpl = address(new ValidatorRewardV1());
//         // console.log("ValidatorReward Impl:", validatorPoolImpl);

//         // Prepare ValidatorReward initialization data
//         // NOTE: treasury 파라미터 제거됨 - 검증자 없는 L2의 보상은 SeigManager.dao()로 전송
//         bytes memory validatorRewardInitData = abi.encodeWithSelector(
//             ValidatorRewardV1.initialize.selector,
//             seigManagerProxy,
//             wton,
//             ratProxy, // RAT contract for validator info
//             deployer // owner
//         );

//         // Deploy ValidatorReward proxy with proxyAdmin as admin (not deployer)
//         // This allows deployer to call through the proxy without admin fallback issue
//         validatorPoolProxy = address(
//             new ValidatorRewardProxy(validatorPoolImpl, proxyAdmin, validatorRewardInitData)
//         );
//         // console.log("ValidatorReward Proxy:", validatorPoolProxy);
//         // console.log("ValidatorReward initialized");
//     }

//     // ==========================================
//     // Step 9: Configure V3 Contracts
//     // ==========================================
//     function _configureV3Contracts(address deployer) internal {
//         // RAT configuration is done in _deployRATProxy -> _configureRAT
//         // This function is kept for compatibility but RAT is already configured
//         // console.log("--- Step 9: Configure V3 Parameters ---");
//         // console.log("RAT already configured during deployment");
//         // console.log("ValidatorReward ready");
//         // console.log("");
//     }

//     // ==========================================
//     // RAT 2단계 초기화 (stack too deep 회피)
//     // ==========================================
//     function _deployRATProxy(address deployer) internal returns (address) {
//         // Step 1: 핵심 주소만으로 프록시 배포
//         RATInitParams memory params = RATInitParams({
//             seigManager: seigManagerProxy,
//             wton: wton,
//             ton: ton,
//             layer2Manager: layer2ManagerProxy,
//             l1BridgeRegistry: l1BridgeRegistryProxy,
//             owner: deployer
//         });
//         bytes memory initData = abi.encodeWithSelector(RAT.initialize.selector, params);
//         // Use proxyAdmin instead of deployer to avoid admin fallback issue
//         address proxy = address(new RATProxy(ratImpl, proxyAdmin, initData));

//         // Step 2: 설정 파라미터 설정
//         _configureRAT(proxy, deployer);
//         return proxy;
//     }

//     function _configureRAT(address proxy, address deployer) internal {
//         RATConfigParams memory config = RATConfigParams({
//             ratTriggerProbability: RAT_TRIGGER_PROBABILITY,
//             evidenceSubmissionPeriod: RAT_EVIDENCE_PERIOD,
//             slashingPenalty: RAT_SLASHING_PENALTY,
//             validatorBuffer: RAT_VALIDATOR_BUFFER,
//             minimumThreshold: RAT_MINIMUM_THRESHOLD,
//             maxValidatorsPerL2: RAT_MAX_VALIDATORS_PER_L2,
//             challengeGameDuration: RAT_CHALLENGE_GAME_DURATION,
//             safetyBuffer: RAT_SAFETY_BUFFER,
//             treasury: deployer,
//             attentionCost: RAT_ATTENTION_COST,
//             relaxedValidatorCheck: RAT_RELAXED_VALIDATOR_CHECK
//         });
//         RAT(proxy).setConfig(config);
//     }

//     // ==========================================
//     // Step 10: Setup Cross-References
//     // 분리된 헬퍼 함수로 stack too deep 회피
//     // ==========================================
//     function _setupCrossReferences(address deployer) internal virtual {
//         _setupSeigManagerRefs();
//         _setupLayer2ManagerRefs(deployer);
//         _setupOtherManagerRefs();
//     }

//     function _setupSeigManagerRefs() internal {
//         SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
//         SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);
//     }

//     function _setupLayer2ManagerRefs(address deployer) internal {
//         // 2단계로 분리하여 stack too deep 회피
//         Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
//             l1BridgeRegistryProxy,
//             operatorManagerFactory,
//             ton,
//             wton
//         );
//         Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
//             deployer,
//             depositManagerProxy,
//             seigManagerProxy,
//             address(0)
//         );

//         // Layer2Manager Slashing routing
//         Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(
//             layer2ManagerSlashingImpl,
//             true
//         );
//         bytes4[] memory l2SlashingSelectors = new bytes4[](1);
//         l2SlashingSelectors[0] = Layer2Manager_Slashing.slashingCandidate.selector;
//         Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(
//             l2SlashingSelectors,
//             layer2ManagerSlashingImpl
//         );

//         // Layer2Manager.setSequencerVault (V3 - OperatorManager가 자동 조회)
//         // TODO: SequencerVault 구현 후 활성화
//         // Layer2ManagerV3(layer2ManagerProxy).setSequencerVault(sequencerVaultProxy);
//     }

//     function _setupOtherManagerRefs() internal {
//         L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(
//             layer2ManagerProxy,
//             seigManagerProxy,
//             ton
//         );
//         OperatorManagerFactory(operatorManagerFactory).setAddresses(
//             depositManagerProxy,
//             ton,
//             wton,
//             layer2ManagerProxy
//         );
//         DepositManagerV3(depositManagerProxy).setAddresses(
//             l1BridgeRegistryProxy,
//             layer2ManagerProxy
//         );
//         // SeigManager에 L1BridgeRegistry 설정 (V2 seigniorage에 필요)
//         SeigManagerV1_2(seigManagerProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);
//     }

//     // ==========================================
//     // Step 11: DAOVault Deploy
//     // ==========================================
//     function _deployDAOVault() internal {
//         console.log("--- Step 11: DAOVault Deploy ---");

//         bytes memory daovaultArgs = abi.encode(ton, wton);
//         daoVault = deployCode("abis/DAOVault.json", daovaultArgs);
//         console.log("DAOVault deployed at:", daoVault);
//     }

//     // ==========================================
//     // Step 12: DAOAgendaManager Deploy
//     // ==========================================
//     function _deployDAOAgendaManager() internal {
//         console.log("--- Step 12: DAOAgendaManager Deploy ---");

//         daoAgendaManager = deployCode("abis/DAOAgendaManager.json");
//         console.log("DAOAgendaManager deployed at:", daoAgendaManager);
//     }

//     // ==========================================
//     // Step 13: DAOCommittee Deploy
//     // ==========================================
//     function _deployDAOCommittee() internal {
//         console.log("--- Step 13: DAOCommittee Deploy ---");

//         // Step 2: DAOCommitteeProxy2 배포
//         daoCommitteeProxy2 = new DAOCommitteeProxy2();
//         console.log("DAOCommitteeProxy2 deployed at:", address(daoCommitteeProxy2));

//         // Step 1: DAOCommitteeProxy 배포 (ABI) - 구현체를 처음부터 설정
//         bytes memory daoArgs = abi.encode(
//             ton,
//             address(daoCommitteeProxy2), // impl을 여기서 바로 설정
//             address(seigManagerProxy),
//             address(layer2RegistryProxy),
//             address(daoAgendaManager),
//             address(1), // candidateFactory 배포전, address(0)으로 설정 불가
//             address(daoVault)
//         );
//         daoCommitteeProxy = deployCode("abis/DAOCommitteeProxy.json", daoArgs);
//         console.log("DAOCommitteeProxy deployed at:", daoCommitteeProxy);

//         // Step 3: DAOCommittee_V1 구현체 배포 및 설정
//         daoCommitteeImpl = new DAOCommittee_V1();
//         DAOCommitteeProxy2(payable(daoCommitteeProxy)).upgradeTo2(address(daoCommitteeImpl));
//         console.log("DAOCommitteeProxy2 set implementation to V1");

//         // Step 4: DAOCommitteeOwner 배포 및 Selector Routing
//         daoCommitteeOwner = new DAOCommitteeOwner();
//         DAOCommitteeProxy2(payable(daoCommitteeProxy)).setAliveImplementation2(
//             address(daoCommitteeOwner),
//             true
//         );

//         bytes4[] memory ownerSelectors = new bytes4[](17);
//         ownerSelectors[0] = DAOCommitteeOwner.setCooldownTime.selector;
//         ownerSelectors[1] = DAOCommitteeOwner.setCandidateAddOnFactory.selector;
//         ownerSelectors[2] = DAOCommitteeOwner.setLayer2Manager.selector;
//         ownerSelectors[3] = DAOCommitteeOwner.setSeigManager.selector;
//         ownerSelectors[4] = DAOCommitteeOwner.setDaoVault.selector;
//         ownerSelectors[5] = DAOCommitteeOwner.setLayer2Registry.selector;
//         ownerSelectors[6] = DAOCommitteeOwner.setAgendaManager.selector;
//         ownerSelectors[7] = DAOCommitteeOwner.setCandidateFactory.selector;
//         ownerSelectors[8] = DAOCommitteeOwner.setTon.selector;
//         ownerSelectors[9] = DAOCommitteeOwner.setWton.selector;
//         ownerSelectors[10] = DAOCommitteeOwner.increaseMaxMember.selector;
//         ownerSelectors[11] = DAOCommitteeOwner.setQuorum.selector;
//         ownerSelectors[12] = DAOCommitteeOwner.decreaseMaxMember.selector;
//         ownerSelectors[13] = DAOCommitteeOwner.setActivityRewardPerSecond.selector;
//         ownerSelectors[14] = DAOCommitteeOwner.setCandidatesSeigManager.selector;
//         ownerSelectors[15] = DAOCommitteeOwner.setCandidatesCommittee.selector;
//         ownerSelectors[16] = DAOCommitteeOwner.daoExecuteTransaction.selector;

//         DAOCommitteeProxy2(payable(daoCommitteeProxy)).setSelectorImplementations2(
//             ownerSelectors,
//             address(daoCommitteeOwner)
//         );
//         console.log("DAOCommitteeOwner selectors routed");

//         // Step 5: Candidate 구현체 배포
//         candidateImpl = new Candidate();

//         // Step 6: CandidateFactory 배포 및 설정
//         candidateFactoryLogic = new CandidateFactory();
//         candidateFactoryProxy = new CandidateFactoryProxy();
//         candidateFactoryProxy.upgradeTo(address(candidateFactoryLogic));

//         CandidateFactory(address(candidateFactoryProxy)).setAddress(
//             address(depositManagerProxy),
//             daoCommitteeProxy,
//             address(candidateImpl),
//             ton,
//             wton
//         );
//         console.log("CandidateFactory deployed and configured");

//         // Step 7: CandidateAddOn 배포 및 설정
//         candidateAddOnImpl = new CandidateAddOnV1_1();
//         candidateAddOnFactoryLogic = new CandidateAddOnFactory();
//         candidateAddOnFactoryProxy = new CandidateAddOnFactoryProxy();
//         candidateAddOnFactoryProxy.upgradeTo(address(candidateAddOnFactoryLogic));

//         CandidateAddOnFactory(address(candidateAddOnFactoryProxy)).setAddress(
//             address(depositManagerProxy),
//             daoCommitteeProxy,
//             address(candidateAddOnImpl),
//             ton,
//             wton,
//             address(l1BridgeRegistryProxy)
//         );
//         console.log("CandidateAddOnFactory deployed and configured");

//         // Step 8: DAOCommittee 추가 설정
//         DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(address(candidateFactoryProxy));
//         DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(
//             address(candidateAddOnFactoryProxy)
//         );
//         DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(address(layer2ManagerProxy));
//         DAOCommitteeOwner(daoCommitteeProxy).setWton(wton);
//         console.log("DAOCommittee final configuration complete");

//         Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
//             l1BridgeRegistryProxy,
//             operatorManagerFactory,
//             ton,
//             wton
//         );
//         Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
//             daoCommitteeProxy,
//             depositManagerProxy,
//             seigManagerProxy,
//             address(0) // swapProxy (not used)
//         );
//         console.log("Layer2Manager.setAddresses done");
//     }

//     // ==========================================
//     // Step 14: Add Minter Setting
//     // ==========================================
//     function _addMinterSetting() internal {
//         console.log("--- Step 14: Add Minter Setting ---");
//         // DAOCommittee가 레이어2 등록 대행 가능하도록
//         // ============== 이부분은 추가로 고민해봐야함 ==================
//         Layer2Registry(address(layer2RegistryProxy)).addMinter(daoCommitteeProxy);
//         console.log("DAOCommitteeProxy added as minter to Layer2Registry");
//     }

//     // ==========================================
//     // Step 15: Add SeigManager Setting
//     // ==========================================
//     function _addSeigManagerSetting() internal {
//         console.log("--- Step 15: Add SeigManager Setting ---");
//         // Set SeigManager data
//         // prettier-ignore
//         SeigManagerV1_2(address(seigManagerProxy)).setData(
//             address(0),                 //powerTON
//             address(daoCommitteeProxy), //DAOCommitteeProxy Address
//             0,                          //powerTONSeigRate_
//             0.5e27,                     //daoSeigRate_
//             0.5e27,                     //relativeSeigRate_
//             93096,                      //adjustDelay_
//             1000.1e27                   //minimumAmount_
//         );
//         SeigManagerV1_2(address(seigManagerProxy)).setSeigStartBlock(1);
//         console.log("SeigManagerV1_2 setData complete and seigStartBlock set to 1");
//     }

//     // ==========================================
//     // Step 16: Contract Owner Setting
//     // ==========================================
//     function _setupContractOwner() internal {
//         console.log("--- Step 16: Contract Owner Setting ---");

//         // SeigManagerProxy
//         SeigManagerProxy(payable(seigManagerProxy)).transferAdmin(daoCommitteeProxy);
//         console.log("SeigManagerProxy ownership transferred to DAOCommitteeProxy");

//         // DepositManagerProxy
//         DepositManagerProxy(payable(depositManagerProxy)).transferOwnership(daoCommitteeProxy);
//         console.log("DepositManagerProxy ownership transferred to DAOCommitteeProxy");

//         // Layer2RegistryProxy
//         Layer2RegistryProxy(payable(layer2RegistryProxy)).transferOwnership(daoCommitteeProxy);
//         console.log("Layer2RegistryProxy ownership transferred to DAOCommitteeProxy");

//         // Layer2ManagerProxy
//         Layer2ManagerProxy(payable(layer2ManagerProxy)).transferOwnership(daoCommitteeProxy);
//         console.log("Layer2ManagerProxy ownership transferred to DAOCommitteeProxy");

//         // L1BridgeRegistryProxy
//         L1BridgeRegistryProxy(payable(l1BridgeRegistryProxy)).transferAdmin(daoCommitteeProxy);
//         console.log("L1BridgeRegistryProxy ownership transferred to DAOCommitteeProxy");

//         // CandidateFactoryProxy
//         CandidateFactoryProxy(payable(address(candidateFactoryProxy))).transferOwnership(
//             daoCommitteeProxy
//         );
//         console.log("CandidateFactoryProxy ownership transferred to DAOCommitteeProxy");

//         // CandidateAddOnFactoryProxy
//         CandidateAddOnFactoryProxy(payable(address(candidateAddOnFactoryProxy))).transferOwnership(
//             daoCommitteeProxy
//         );
//         console.log("CandidateAddOnFactoryProxy ownership transferred to DAOCommitteeProxy");
//     }

//     // ==========================================
//     // Output Summary
//     // ==========================================
//     function _printSummary() internal view {
//         console.log("=== Deployment Summary ===");
//         console.log("");
//         console.log("Tokens:");
//         console.log("  TON:", ton);
//         console.log("  WTON:", wton);
//         console.log("");
//         console.log("Core Infrastructure:");
//         console.log("  CoinageFactory:", coinageFactory);
//         console.log("  Layer2Registry Proxy:", layer2RegistryProxy);
//         console.log("");
//         console.log("Managers (Proxies):");
//         console.log("  SeigManager Proxy:", seigManagerProxy);
//         console.log("  DepositManager Proxy:", depositManagerProxy);
//         console.log("  Layer2Manager Proxy:", layer2ManagerProxy);
//         console.log("  L1BridgeRegistry Proxy:", l1BridgeRegistryProxy);
//         console.log("");
//         console.log("V3 Contracts:");
//         console.log("  RAT Proxy:", ratProxy);
//         console.log("  ValidatorReward Proxy:", validatorPoolProxy);
//         console.log("");
//         console.log("Factory:");
//         console.log("  OperatorManagerFactory:", operatorManagerFactory);
//         console.log("");
//         console.log("DAO:");
//         console.log("  DAOVault:", daoVault);
//         console.log("  DAOAgendaManager:", daoAgendaManager);
//         console.log("  DAOCommitteeProxy:", daoCommitteeProxy);
//         console.log("  CandidateFactoryProxy:", address(candidateFactoryProxy));
//         console.log("  CandidateAddOnFactoryProxy:", address(candidateAddOnFactoryProxy));
//     }

//     // prettier-ignore
//     function _saveDeployment() internal {
//         string memory output = string(abi.encodePacked(
//             "{\n",
//             '  "ton": "', vm.toString(ton), '",\n',
//             '  "wton": "', vm.toString(wton), '",\n',
//             '  "coinageFactory": "', vm.toString(coinageFactory), '",\n',
//             '  "layer2RegistryProxy": "', vm.toString(layer2RegistryProxy), '",\n',
//             '  "seigManagerProxy": "', vm.toString(seigManagerProxy), '",\n',
//             '  "depositManagerProxy": "', vm.toString(depositManagerProxy), '",\n',
//             '  "layer2ManagerProxy": "', vm.toString(layer2ManagerProxy), '",\n',
//             '  "l1BridgeRegistryProxy": "', vm.toString(l1BridgeRegistryProxy), '",\n',
//             '  "operatorManagerFactory": "', vm.toString(operatorManagerFactory), '",\n',
//             '  "ratProxy": "', vm.toString(ratProxy), '",\n',
//             '  "validatorPoolProxy": "', vm.toString(validatorPoolProxy), '",\n',
//             '  "daoVault": "', vm.toString(daoVault), '",\n',
//             '  "daoAgendaManager": "', vm.toString(daoAgendaManager), '",\n',
//             '  "daoCommitteeProxy": "', vm.toString(daoCommitteeProxy), '",\n',
//             '  "candidateFactoryProxy": "', vm.toString(address(candidateFactoryProxy)), '",\n',
//             '  "candidateAddOnFactoryProxy": "', vm.toString(address(candidateAddOnFactoryProxy)), '"\n',
//             "}"
//         ));

//         vm.writeFile("deployments/v3-full.json", output);
//         // console.log("\nDeployment saved to deployments/v3-full.json");
//     }
// }

// /**
//  * @title DeployV3FullSlashLocal
//  * @notice 로컬 Anvil 테스트용 간소화된 배포
//  * @dev anvil 실행 후: forge script script/DeployV3Full.s.sol:DeployV3FullSlashLocal --rpc-url http://localhost:8545 --broadcast -vvvv
//  */
// contract DeployV3FullSlashLocal is DeployV3FullSlash {
//     function run() external override {
//         // Anvil default private key
//         uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
//         address deployer = vm.addr(deployerPrivateKey);

//         // console.log("=== V3 Local Deployment ===");
//         // console.log("Deployer:", deployer);
//         // console.log("");

//         vm.startBroadcast(deployerPrivateKey);

//         _deployTokens();
//         _deployCoinageInfrastructure(deployer);
//         _deployLayer2Registry(deployer);
//         _deployManagerProxies();
//         _deployManagerImplementations();
//         _initializeManagers(deployer);
//         _setupMinterPermissions(); // Phase 5.5: Minter 권한 설정
//         _deployOperatorManagerFactory(deployer);
//         _deployV3Contracts(deployer);
//         _configureV3Contracts(deployer);
//         _setupCrossReferences(deployer);
//         _deployDAOVault();
//         _deployDAOAgendaManager();
//         _deployDAOCommittee();
//         _addMinterSetting();
//         _addSeigManagerSetting();
//         _setupContractOwner();

//         vm.stopBroadcast();

//         _printSummary();
//         _saveDeployment();
//     }
// }

// /**
//  * @title DeployV3FullSlashE2E
//  * @notice E2E 테스트용 배포 스크립트 (배포 주소를 반환)
//  * @dev Go 테스트에서 호출하여 사용
//  */
// contract DeployV3FullSlashE2E is DeployV3FullSlash {
//     // Struct to return all deployed addresses
//     struct DeployedAddresses {
//         address ton;
//         address wton;
//         address coinageFactory;
//         address layer2RegistryProxy;
//         address seigManagerProxy;
//         address depositManagerProxy;
//         address layer2ManagerProxy;
//         address l1BridgeRegistryProxy;
//         address operatorManagerFactory;
//         address ratProxy;
//         address validatorPoolProxy;
//         address daoVault;
//         address daoAgendaManager;
//         address daoCommitteeProxy;
//         address candidateFactoryProxy;
//         address candidateAddOnFactoryProxy;
//     }

//     function deployAll(address deployer) external returns (DeployedAddresses memory) {
//         _deployTokens();
//         _deployCoinageInfrastructure(deployer);
//         _deployLayer2Registry(deployer);
//         _deployManagerProxies();
//         _deployManagerImplementations();
//         _initializeManagers(deployer);
//         _setupMinterPermissions(); // Phase 5.5: Minter 권한 설정
//         _deployOperatorManagerFactory(deployer);
//         _deployV3Contracts(deployer);
//         _configureV3Contracts(deployer);
//         _setupCrossReferences(deployer);
//         _deployDAOVault();
//         _deployDAOAgendaManager();
//         _deployDAOCommittee();
//         _addMinterSetting();
//         _addSeigManagerSetting();
//         _setupContractOwner();

//         return
//             DeployedAddresses({
//                 ton: ton,
//                 wton: wton,
//                 coinageFactory: coinageFactory,
//                 layer2RegistryProxy: layer2RegistryProxy,
//                 seigManagerProxy: seigManagerProxy,
//                 depositManagerProxy: depositManagerProxy,
//                 layer2ManagerProxy: layer2ManagerProxy,
//                 l1BridgeRegistryProxy: l1BridgeRegistryProxy,
//                 operatorManagerFactory: operatorManagerFactory,
//                 ratProxy: ratProxy,
//                 validatorPoolProxy: validatorPoolProxy,
//                 daoVault: daoVault,
//                 daoAgendaManager: daoAgendaManager,
//                 daoCommitteeProxy: daoCommitteeProxy,
//                 candidateFactoryProxy: address(candidateFactoryProxy),
//                 candidateAddOnFactoryProxy: address(candidateAddOnFactoryProxy)
//             });
//     }
// }
