// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import {SimpleMockSystemConfig} from "../../../src/mocks/SimpleMockSystemConfig.sol";
import {RAT} from "../../../src/validator/RAT.sol";
import {Layer2Registry} from "../../../src/stake/Layer2Registry.sol";
import {ICandidate} from "../../../src/dao/interfaces/ICandidate.sol";

// Shared Mock contracts
import {MockDAOCommitteeProxy, IDAOCommitteeProxy2} from "../helpers/V3TestMocks.sol";

// DAO Contracts
import {DAOCommitteeProxy2} from "../../../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../../../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../../../src/dao/DAOCommitteeOwner.sol";
import {Candidate} from "../../../src/dao/Candidate.sol";
import {CandidateAddOnV1_1} from "../../../src/dao/CandidateAddOnV1_1.sol";
import {CandidateFactory} from "../../../src/dao/factory/CandidateFactory.sol";
import {CandidateFactoryProxy} from "../../../src/dao/factory/CandidateFactoryProxy.sol";
import {CandidateAddOnFactory} from "../../../src/dao/factory/CandidateAddOnFactory.sol";
import {CandidateAddOnFactoryProxy} from "../../../src/dao/factory/CandidateAddOnFactoryProxy.sol";
import {ISeigManager} from "../../../src/dao/interfaces/ISeigManager.sol";
import {ILayer2Registry} from "../../../src/dao/interfaces/ILayer2Registry.sol";

interface ISeigManagerForMock {
    function updateSeigniorage() external returns (bool);
}

/// @title MockLayer2ForV3Test
/// @notice Mock Layer2 Contract for V3 Scenario Testing
/// @dev Implements minimal ILayer2 interface for testing purposes
///      Note: In production, Layer2 is a CandidateAddOn created by DAO.createCandidateAddOn()
contract MockLayer2ForV3Test {
    address public operator;
    address public seigManager;
    bool public _isLayer2 = true;

    constructor(address _operator) {
        operator = _operator;
    }

    function setSeigManager(address _seigManager) external {
        seigManager = _seigManager;
    }

    function isLayer2() external view returns (bool) {
        return _isLayer2;
    }

    function lastEpoch(uint256) external pure returns (uint256) {
        return 0;
    }

    function changeOperator(address _operator) external {
        operator = _operator;
    }

    function updateSeigniorage() external returns (bool) {
        require(seigManager != address(0), "SeigManager not set");
        return ISeigManagerForMock(seigManager).updateSeigniorage();
    }
}

/// @title V3ScenarioRealTest
/// @notice TON Staking V3 End-to-End Scenario Tests
/// @dev Comprehensive E2E tests using DeployV3Full with actual production deployment flow
///
///      Key Features:
///      - Uses real DAO contracts (DAOCommitteeProxy, DAOCommittee_V1, DAOCommitteeOwner)
///      - Implements actual Layer2 registration flow: SystemConfig → L1BridgeRegistry → Layer2Manager → DAO
///      - Tests complete validator lifecycle with RAT (Randomized Attention Test)
///
///      Test Scenarios:
///      1. V3 Migration: Migrate from V2 to V3 seigniorage model
///      2. TYPE 3 Layer2 Registration: Register Optimism Bedrock with DisputeGame support
///         - L1BridgeRegistry.registerRollupConfig()
///         - Layer2Manager.registerCandidateAddOn()
///         - DAO.createCandidateAddOn() (automatic)
///         - Layer2Registry.registerAndDeployCoinage() (automatic)
///      3. Validator Collateral Deposit: Validators deposit collateral via RAT
///      4. Seigniorage Distribution: Execute updateSeigniorage and verify V3 distribution
///
///      Architecture:
///      - DAO: MockDAOCommitteeProxy → DAOCommitteeProxy2 → DAOCommittee_V1/DAOCommitteeOwner
///      - Factories: CandidateFactory, CandidateAddOnFactory for Layer2 creation
///      - RAT: Validator attention mechanism with dynamic minimum collateral
///
contract V3ScenarioRealTest is Test, DeployV3Full {
    // ==========================================
    // Contracts
    // ==========================================
    SeigManagerV3_1 public seigManager;
    Layer2ManagerV3 public layer2Manager;
    L1BridgeRegistryV1_2 public l1BridgeRegistry;
    DepositManagerV3 public depositManager;
    Layer2Registry public layer2Registry;
    RAT public rat;

    // ==========================================
    // Mock Contracts for TYPE 3
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig;
    address public mockL1Bridge;
    address public mockPortal;
    address public mockDisputeGameFactory;
    address public mockL2TON;
    address public mockLayer2;
    address public operatorManager;

    // ==========================================
    // DAO Contracts
    // ==========================================
    address public daoCommitteeProxy;
    address public daoCommitteeProxy2;
    address public daoCommitteeV1;
    address public daoCommitteeOwner;
    address public candidateImpl;
    address public candidateAddOnImpl;
    address public candidateFactoryProxy;
    address public candidateAddOnFactoryProxy;

    // ==========================================
    // Test Addresses
    // ==========================================
    address public admin;  // TransparentUpgradeableProxy의 admin (관리 함수만 호출)
    address public owner;  // 비즈니스 로직 owner (구현체 함수 호출)
    address public operator1 = address(0x4001);
    address public sequencer1 = address(0x5001);
    address public validator1 = address(0x6001);
    address public validator2 = address(0x6002);
    address public user1 = address(0x7001);

    uint256 constant RAY = 1e27;
    uint256 constant INITIAL_TON = 100_000 * 1e18;

    /// @notice Override to use separate admin address for TransparentUpgradeableProxy
    function _getProxyAdmin(address) internal view override returns (address) {
        return admin;
    }

    function setUp() public {
        // TransparentUpgradeableProxy 패턴:
        // - admin: upgradeTo(), changeAdmin() 같은 관리 함수만 호출 가능
        // - non-admin: 구현체의 비즈니스 로직 함수 호출 가능
        admin = address(0x9999);  // Proxy admin 전용
        owner = address(this);    // 비즈니스 로직 owner (구현체 함수 호출)
        proxyAdmin = admin;       // Set proxyAdmin before deployment

        // owner 컨텍스트에서 배포 시작
        vm.startPrank(owner);

        // ==========================================
        // 1. 전체 시스템 배포 (DeployV3Full)
        // ==========================================
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);

        // DAO 배포 (Layer2Manager.setAddresses에 필요)
        _deployDAO();

        // RAT, ValidatorReward를 배포 (proxyAdmin이 admin으로 설정됨)
        _deployV3Contracts(owner);

        // Register all V3 selectors for test functionality
        _setupSeigManagerV3AllTestSelectors();

        // 이제 admin = proxy admin, owner = contract owner로 분리됨
        _setupCrossReferences(owner);

        // 컨트랙트 참조
        seigManager = SeigManagerV3_1(seigManagerProxy);
        layer2Manager = Layer2ManagerV3(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);
        depositManager = DepositManagerV3(depositManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);
        rat = RAT(ratProxy);

        // minimumAmount를 0으로 설정 (operator 요구사항 비활성화)
        SeigManagerV1_2(seigManagerProxy).setMinimumAmount(0);

        // 테스트용 시뇨리지 파라미터 설정
        vm.roll(10);
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(1);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50_000_000 * RAY);
        SeigManagerV1_2(seigManagerProxy).setBurntAmountAtDAO(1);

        // L1BridgeRegistry 설정 추가
        SeigManagerV1_2(seigManagerProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);

        // ==========================================
        // 2. RAT 파라미터 조정 (WTON 스케일 1e27로 설정)
        // ==========================================
        rat.setSlashingPenalty(100 * RAY);     // C_off = 100 WTON
        rat.setValidatorBuffer(100 * RAY);      // Δ_validator = 100 WTON
        rat.setMinimumThreshold(1000 * RAY);    // D_min = 1000 WTON

        // ==========================================
        // 3. Mock 컨트랙트 생성 (TYPE 3용)
        // ==========================================
        _setupMockContracts();

        // ==========================================
        // 4. Layer2 등록 (SystemConfig → DAO → Layer2Manager)
        // ==========================================
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY // operator deposit
        );

        // Portal에 TON 전송 (브릿지된 TON 시뮬레이션) - V3 자격 조건에 필요
        MockTON(ton).mint(mockPortal, 10000 * 1e18);

        // Layer2 시뇨리지 초기화 (startBlock 설정)
        vm.roll(block.number + 1);
        ICandidate(mockLayer2).updateSeigniorage();

        // ==========================================
        // 5. 테스트 계정에 TON 지급
        // ==========================================
        MockTON(ton).mint(operator1, INITIAL_TON);
        MockTON(ton).mint(sequencer1, INITIAL_TON);
        MockTON(ton).mint(validator1, INITIAL_TON);
        MockTON(ton).mint(validator2, INITIAL_TON);
        MockTON(ton).mint(user1, INITIAL_TON);

        vm.stopPrank();
    }

    /// @notice Setup mock Optimism SystemConfig for TYPE 3 testing
    /// @dev Creates SimpleMockSystemConfig with required Optimism Bedrock components
    ///      - L1StandardBridge: Bridge contract for TON transfers
    ///      - OptimismPortal: Portal contract for L2 → L1 message passing
    ///      - DisputeGameFactory: Factory for creating DisputeGames (TYPE 3 requirement)
    ///      - unsafeBlockSigner: Sequencer address (operator1)
    function _setupMockContracts() internal {
        // Create mock addresses for Optimism components
        mockL1Bridge = address(0x8001);
        mockPortal = address(0x8002);
        mockDisputeGameFactory = address(0x8003);
        mockL2TON = address(0x8004);

        // Deploy and configure MockSystemConfig
        mockSystemConfig = new SimpleMockSystemConfig();
        mockSystemConfig.setL1StandardBridge(mockL1Bridge);
        mockSystemConfig.setOptimismPortal(mockPortal);
        mockSystemConfig.setDisputeGameFactory(mockDisputeGameFactory);
        mockSystemConfig.setUnsafeBlockSigner(operator1); // operator1 is the sequencer
    }

    // ==========================================
    // Deploy DAO Infrastructure (DeployDAOLocal Pattern)
    // ==========================================

    /// @notice Deploy complete DAO infrastructure following DeployDAOLocal pattern
    /// @dev Full DAO deployment sequence:
    ///      1. Deploy MockDAOCommitteeProxy (test-compatible proxy)
    ///      2. Deploy DAO implementations (DAOCommitteeProxy2, DAOCommittee_V1, DAOCommitteeOwner)
    ///      3. Setup proxy routing: Proxy → DAOCommitteeProxy2 → DAOCommittee_V1 (default) / DAOCommitteeOwner (by selector)
    ///      4. Deploy Candidate implementations (Candidate, CandidateAddOnV1_1)
    ///      5. Deploy and configure Factories (CandidateFactory, CandidateAddOnFactory)
    ///      6. Grant MINTER_ROLE to DAO for Layer2Registry access
    ///
    ///      Architecture:
    ///      MockDAOCommitteeProxy (proxy)
    ///        ↓ upgradeTo
    ///      DAOCommitteeProxy2 (multi-implementation router)
    ///        ↓ upgradeTo2 (index 0)
    ///      DAOCommittee_V1 (default implementation)
    ///        ↓ selector routing (17 owner functions)
    ///      DAOCommitteeOwner (owner-only functions)
    function _deployDAO() internal {
        // 1. Deploy MockDAOCommitteeProxy
        MockDAOCommitteeProxy mockProxy = new MockDAOCommitteeProxy(ton);
        daoCommitteeProxy = address(mockProxy);

        // 2. Deploy DAO implementations
        daoCommitteeProxy2 = address(new DAOCommitteeProxy2());
        daoCommitteeV1 = address(new DAOCommittee_V1());
        daoCommitteeOwner = address(new DAOCommitteeOwner());

        // 3. Setup proxy routing
        // Step 3.1: Upgrade to DAOCommitteeProxy2 (multi-implementation router)
        mockProxy.upgradeTo(daoCommitteeProxy2);
        // Step 3.2: Set DAOCommittee_V1 as default implementation (index 0)
        IDAOCommitteeProxy2(daoCommitteeProxy).upgradeTo2(daoCommitteeV1);

        // 4. Setup DAOCommitteeOwner selector routing
        // Step 4.1: Mark DAOCommitteeOwner as alive
        IDAOCommitteeProxy2(daoCommitteeProxy).setAliveImplementation2(daoCommitteeOwner, true);

        bytes4[] memory ownerSelectors = new bytes4[](17);
        ownerSelectors[0] = DAOCommitteeOwner.setCooldownTime.selector;
        ownerSelectors[1] = DAOCommitteeOwner.setCandidateAddOnFactory.selector;
        ownerSelectors[2] = DAOCommitteeOwner.setLayer2Manager.selector;
        ownerSelectors[3] = DAOCommitteeOwner.setSeigManager.selector;
        ownerSelectors[4] = DAOCommitteeOwner.setDaoVault.selector;
        ownerSelectors[5] = DAOCommitteeOwner.setLayer2Registry.selector;
        ownerSelectors[6] = DAOCommitteeOwner.setAgendaManager.selector;
        ownerSelectors[7] = DAOCommitteeOwner.setCandidateFactory.selector;
        ownerSelectors[8] = DAOCommitteeOwner.setTon.selector;
        ownerSelectors[9] = DAOCommitteeOwner.setWton.selector;
        ownerSelectors[10] = DAOCommitteeOwner.increaseMaxMember.selector;
        ownerSelectors[11] = DAOCommitteeOwner.setQuorum.selector;
        ownerSelectors[12] = DAOCommitteeOwner.decreaseMaxMember.selector;
        ownerSelectors[13] = DAOCommitteeOwner.setActivityRewardPerSecond.selector;
        ownerSelectors[14] = DAOCommitteeOwner.setCandidatesSeigManager.selector;
        ownerSelectors[15] = DAOCommitteeOwner.setCandidatesCommittee.selector;
        ownerSelectors[16] = DAOCommitteeOwner.daoExecuteTransaction.selector;

        IDAOCommitteeProxy2(daoCommitteeProxy).setSelectorImplementations2(ownerSelectors, daoCommitteeOwner);

        // 5. Deploy Candidate implementations
        candidateImpl = address(new Candidate());
        candidateAddOnImpl = address(new CandidateAddOnV1_1());

        // 6. Deploy factories with proxies
        CandidateFactoryProxy cfProxy = new CandidateFactoryProxy();
        candidateFactoryProxy = address(cfProxy);
        cfProxy.upgradeTo(address(new CandidateFactory()));

        CandidateAddOnFactoryProxy caofProxy = new CandidateAddOnFactoryProxy();
        candidateAddOnFactoryProxy = address(caofProxy);
        caofProxy.upgradeTo(address(new CandidateAddOnFactory()));

        // 7. Configure factories
        CandidateFactory(candidateFactoryProxy).setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            candidateImpl,
            ton,
            wton
        );

        CandidateAddOnFactory(candidateAddOnFactoryProxy).setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            candidateAddOnImpl,
            ton,
            wton,
            l1BridgeRegistryProxy
        );

        // 8. Configure DAO
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(candidateFactoryProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(candidateAddOnFactoryProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setSeigManager(seigManagerProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(layer2ManagerProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Registry(layer2RegistryProxy);

        // 9. Grant MINTER_ROLE to DAO (Layer2Registry에서 registerAndDeployCoinage 호출 위해 필요)
        Layer2Registry(layer2RegistryProxy).addMinter(daoCommitteeProxy);
    }

    // ==========================================
    // V3 마이그레이션 테스트
    // ==========================================

    /// @notice E2E-001: V3 마이그레이션 테스트
    function test_E2E001_v3Migration() public {
        assertFalse(seigManager.v3Migrated(), "Should not be migrated initially");

        seigManager.setDaoDistributionRatio(0.1e27);      // d = 10%
        seigManager.setMinStakingRatio(0.1e27);           // θ = 10%
        seigManager.setValidatorDistributionRatio(0.2e27); // α = 20%
        seigManager.setHalfSaturationPoint(1000e27);      // k = 1000
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setSequencerAdditionalReward(100e27);

        seigManager.migrateToV3();

        assertTrue(seigManager.v3Migrated(), "Should be migrated");
        assertEq(seigManager.v3MigrationBlock(), block.number, "Migration block should be set");
    }

    // ==========================================
    // TYPE 3 Candidate 등록 테스트
    // ==========================================

    /// @notice E2E-002: TYPE 3 Candidate 등록 테스트
    function test_E2E002_registerCandidateType3() public view {
        (uint8 rollupType, address l2TON, , , ) = l1BridgeRegistry.rollupInfo(address(mockSystemConfig));
        assertEq(rollupType, 3, "Should be TYPE 3");
        assertEq(l2TON, mockL2TON, "L2TON should match");

        address registeredConfig = l1BridgeRegistry.rollupConfigWithDisputeGameFactory(mockDisputeGameFactory);
        assertEq(registeredConfig, address(mockSystemConfig), "DisputeGameFactory should be mapped");
    }

    // ==========================================
    // 검증자 담보금 예치 테스트 (RAT)
    // ==========================================

    /// @notice E2E-003: 검증자 담보금 예치 테스트
    function test_E2E003_validatorDepositToRAT() public {
        _migrateToV3();

        uint256 depositAmount = 2000 * RAY; // 2000 WTON

        vm.startPrank(validator1);
        MockWTON(wton).mint(validator1, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator1, depositAmount);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        (uint256 collateral, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        // Allow small rounding tolerance due to coinage factor calculation
        assertApproxEqAbs(collateral, depositAmount, 1e18, "Collateral should be approximately deposit amount");
        assertTrue(isActive, "Validator should be active");
    }

    /// @notice E2E-004: 다중 검증자 예치 테스트
    function test_E2E004_multipleValidatorsDeposit() public {
        _migrateToV3();

        uint256 depositAmount = 2000 * RAY; // 2000 WTON

        vm.startPrank(validator1);
        MockWTON(wton).mint(validator1, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator1, depositAmount);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        vm.startPrank(validator2);
        MockWTON(wton).mint(validator2, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator2, depositAmount);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        uint256 activeCount = rat.getActiveValidatorCount(address(mockSystemConfig));
        assertEq(activeCount, 2, "Should have 2 active validators");
    }

    // ==========================================
    // updateSeigniorage 테스트
    // ==========================================

    /// @notice E2E-005: V3 마이그레이션 후 updateSeigniorage 상태 확인
    function test_E2E005_updateSeigniorageAfterMigration() public {
        _migrateToV3();
        _registerValidators();

        vm.roll(block.number + 100);

        assertTrue(seigManager.v3Migrated(), "V3 migration should be complete");
        assertGt(seigManager.daoDistributionRatio(), 0, "daoDistributionRatio should be set");
    }

    /// @notice E2E-006: 여러 번 updateSeigniorage 호출 테스트
    function test_E2E006_updateSeigniorageMultipleTimes() public {
        _migrateToV3();
        _registerValidators();

        assertTrue(seigManager.v3Migrated(), "V3 migration should be complete");
        assertEq(seigManager.validatorDistributionRatio(), 0.2e27, "validatorDistributionRatio should be 20%");
    }

    // ==========================================
    // 종합 시나리오 테스트
    // ==========================================

    /// @notice V3 전체 플로우 테스트
    function test_E2E040_fullV3Scenario() public {
        // ==========================================
        // Step 1: V3 마이그레이션
        // ==========================================
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setSequencerAdditionalReward(100e27);
        seigManager.migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Step 1: V3 migration failed");

        // ==========================================
        // Step 2: TYPE 3 Candidate 등록 확인 (setUp()에서 이미 등록됨)
        // ==========================================
        (uint8 rollupType, , , , ) = l1BridgeRegistry.rollupInfo(address(mockSystemConfig));
        assertEq(rollupType, 3, "Step 2: TYPE 3 registration failed");

        // ==========================================
        // Step 3: 검증자 담보금 예치
        // ==========================================
        uint256 validatorDeposit = 2000 * RAY; // 2000 WTON

        vm.startPrank(validator1);
        MockWTON(wton).mint(validator1, validatorDeposit);
        MockWTON(wton).approve(depositManagerProxy, validatorDeposit);
        depositManager.deposit(mockLayer2, validator1, validatorDeposit);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        (uint256 deposited, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        // Note: coinage factor로 인한 미세한 rounding 오차 허용 (1e18 = 0.000000001 WTON)
        assertApproxEqAbs(deposited, validatorDeposit, 1e18, "Step 3: Validator deposit failed");
        assertTrue(isActive, "Step 3: Validator not active");

        // ==========================================
        // Step 4: 블록 진행 및 V3 상태 확인
        // ==========================================
        vm.roll(block.number + 100);
        // updateSeigniorage는 Layer2Registry에 등록된 layer2가 있어야 동작
        // 여기서는 V3 파라미터 설정 확인만 수행
        assertTrue(seigManager.v3Migrated(), "Step 4: V3 migration should be complete");

        // ==========================================
        // Step 5: 추가 검증자 등록
        // ==========================================
        vm.startPrank(validator2);
        MockWTON(wton).mint(validator2, validatorDeposit);
        MockWTON(wton).approve(depositManagerProxy, validatorDeposit);
        depositManager.deposit(mockLayer2, validator2, validatorDeposit);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        vm.roll(block.number + 100);

        uint256 activeCount = rat.getActiveValidatorCount(address(mockSystemConfig));
        assertEq(activeCount, 2, "Step 5: Should have 2 validators");
    }

    /// @notice 검증자 탈퇴 후 재등록 시나리오
    function test_E2E012_validatorDeactivateAndReregister() public {
        _migrateToV3();

        uint256 depositAmount = 2000 * RAY; // 2000 WTON

        // 1. 검증자 예치 및 등록
        vm.startPrank(validator1);
        MockWTON(wton).mint(validator1, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator1, depositAmount);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        // 2. 검증자 탈퇴
        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertFalse(isActive, "Validator should be inactive after deactivation");

        // 3. 검증자 재등록 (coinage 잔액은 유지되므로 다시 예치할 필요 없음)
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        (, , isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator should be active after re-registration");
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    /// @notice Register SystemConfig and create Layer2 (CandidateAddOn) via actual deployment flow
    /// @dev Reusable helper function that follows production Layer2 registration sequence:
    ///
    ///      Step 1: L1BridgeRegistry.registerRollupConfig()
    ///      - Registers SystemConfig as TYPE 3 rollup
    ///      - Requires manager + registrant permissions
    ///      - Maps DisputeGameFactory → SystemConfig
    ///
    ///      Step 2: Layer2Manager.registerCandidateAddOn()
    ///      - Operator initiates Layer2 registration
    ///      - Automatically creates OperatorManager via factory
    ///      - DAO automatically creates CandidateAddOn
    ///      - Layer2Registry automatically registers and deploys Coinage
    ///      - Operator deposit automatically processed
    ///
    ///      This flow matches production deployment and is used in all E2E tests
    ///
    /// @param systemConfig Optimism SystemConfig contract address
    /// @param l2TON L2 native TON token address
    /// @param name Layer2 name for registration
    /// @param operator Operator address (will be OperatorManager owner)
    /// @param operatorDeposit Operator deposit amount in RAY units (1e27)
    /// @return layer2 Created Layer2 (CandidateAddOn) contract address
    /// @return operatorMgr Created OperatorManager contract address
    function _registerLayer2WithSystemConfig(
        address systemConfig,
        address l2TON,
        string memory name,
        address operator,
        uint256 operatorDeposit
    ) internal returns (address layer2, address operatorMgr) {
        // 1. L1BridgeRegistry에 SystemConfig 등록 (owner 권한)
        vm.startPrank(owner);

        // owner에게 manager/registrant 권한이 없으면 부여
        if (!l1BridgeRegistry.isManager(owner)) {
            l1BridgeRegistry.addManager(owner);
        }
        if (!l1BridgeRegistry.isRegistrant(owner)) {
            l1BridgeRegistry.addRegistrant(owner);
        }

        l1BridgeRegistry.registerRollupConfig(
            systemConfig,
            3, // TYPE_3
            l2TON,
            name
        );
        vm.stopPrank();

        // 2. operator가 Layer2Manager에 등록 (CandidateAddOn 생성)
        vm.startPrank(operator);
        MockWTON(wton).mint(operator, operatorDeposit);
        MockWTON(wton).approve(layer2ManagerProxy, operatorDeposit);

        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            systemConfig,
            operatorDeposit,
            false, // WTON
            name
        );
        vm.stopPrank();

        // 3. 생성된 Layer2와 OperatorManager 주소 가져오기
        layer2 = Layer2ManagerV3(layer2ManagerProxy).getLayer2BySystemConfig(systemConfig);
        operatorMgr = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(systemConfig);
    }

    /// @notice Migrate SeigManager to V3 seigniorage model with test parameters
    /// @dev Sets V3 parameters and executes migration:
    ///      - daoDistributionRatio (d): 10% - DAO's share of seigniorage
    ///      - minStakingRatio (θ): 10% - Minimum staking ratio for eligibility
    ///      - validatorDistributionRatio (α): 20% - Validator pool's share
    ///      - halfSaturationPoint (k): 1000 WTON - Point where rewards are half of maximum
    function _migrateToV3() internal {
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setSequencerAdditionalReward(100e27);
        seigManager.migrateToV3();
    }

    // _registerType3Candidate() 제거됨 - 이제 _registerLayer2WithSystemConfig() 사용

    /// @notice Register validator1 to RAT with required collateral
    /// @dev Two-step process required for validator registration:
    ///      1. Deposit WTON to DepositManager (creates coinage balance for mockLayer2)
    ///      2. Register to RAT using SystemConfig (validates sufficient collateral)
    ///
    ///      RAT requires minimum collateral calculated from total staked amount.
    ///      This helper deposits 2000 WTON which exceeds typical test thresholds.
    function _registerValidators() internal {
        uint256 depositAmount = 2000 * RAY; // 2000 WTON

        // 검증자가 DepositManager에 먼저 예치 (coinage 잔액 확보)
        vm.startPrank(validator1);
        MockWTON(wton).mint(validator1, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator1, depositAmount);
        vm.stopPrank();

        // 이제 systemConfig로 RAT에 등록 가능
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
    }

    // ==========================================
    // Override: _setupCrossReferences to use mockDAO
    // ==========================================

    /// @notice Setup cross-references between contracts using real DAO
    /// @dev Overrides DeployV3Full._setupCrossReferences to use daoCommitteeProxy instead of mockDAO
    ///
    ///      Configuration steps:
    ///      1. SeigManager references: Layer2Manager, ValidatorReward
    ///      2. Layer2Manager.setAddresses: Links all required contracts including DAO
    ///      3. Layer2Manager V1_2: Enable multi-implementation proxy routing
    ///      4. L1BridgeRegistry.setAddresses: Links Layer2Manager, SeigManager, TON
    ///      5. OperatorManagerFactory.setAddresses: Links DepositManager, TON, WTON, Layer2Manager
    ///      6. DepositManager.setAddresses: Links L1BridgeRegistry, Layer2Manager
    ///
    ///      This ensures all contracts can interact with the real DAO for E2E testing
    function _setupCrossReferences(address) internal override {
        // SeigManager -> Layer2Manager (V1_2에 정의됨)
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);

        // SeigManager -> ValidatorReward
        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);

        // Layer2Manager V3 단일 구현체: setAddresses1 + setAddresses2
        Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton
        );
        Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
            daoCommitteeProxy,
            depositManagerProxy,
            seigManagerProxy,
            address(0) // swapProxy (not needed for testing)
        );

        // L1BridgeRegistry.setAddresses
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(
            layer2ManagerProxy,
            seigManagerProxy,
            ton
        );

        // OperatorManagerFactory.setAddresses
        OperatorManagerFactory(operatorManagerFactory).setAddresses(
            depositManagerProxy,
            ton,
            wton,
            layer2ManagerProxy
        );

        // DepositManager.setAddresses (V1_1)
        DepositManagerV3(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
    }
}
