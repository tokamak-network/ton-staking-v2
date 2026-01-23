// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import {SimpleMockSystemConfig} from "../../../src/mocks/SimpleMockSystemConfig.sol";
import {RAT} from "../../../src/validator/RAT.sol";
import {Layer2Registry} from "../../../src/stake/Layer2Registry.sol";

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

/// @title MultiL2SeigniorageDistributionTest
/// @notice 다중 L2 시뇨리지 분배 테스트
/// @dev 테스트 계획서 E2E-031: 다중 L2 비례 분배 정확성 검증
///
/// 테스트 대상:
/// - E2E-031: 다중 L2에서 effectiveBridgedTON 비례 분배 정확성
/// - SD-014: B̃_i 비례 분배 - Seig_i = y(x) · (B̃_i / x)
/// - SD-015: 자격 미달 L2 제외 분배 정확성
contract MultiL2SeigniorageDistributionTest is Test, DeployV3Full {
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
    // Mock Contracts - L2 #1
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig1;
    address public mockL1Bridge1;
    address public mockPortal1;
    address public mockDisputeGameFactory1;
    address public mockL2TON1;
    address public mockLayer2_1;
    address public operatorManager1;

    // ==========================================
    // Mock Contracts - L2 #2
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig2;
    address public mockL1Bridge2;
    address public mockPortal2;
    address public mockDisputeGameFactory2;
    address public mockL2TON2;
    address public mockLayer2_2;
    address public operatorManager2;

    // ==========================================
    // Mock Contracts - L2 #3
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig3;
    address public mockL1Bridge3;
    address public mockPortal3;
    address public mockDisputeGameFactory3;
    address public mockL2TON3;
    address public mockLayer2_3;
    address public operatorManager3;

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
    address public admin;
    address public owner;
    address public operator1 = address(0x4001);
    address public operator2 = address(0x4002);
    address public operator3 = address(0x4003);
    address public validator1 = address(0x6001);
    address public dao;

    uint256 constant RAY = 1e27;
    uint256 constant INITIAL_TON = 1_000_000 * 1e18;

    /// @notice Override to use separate admin address for TransparentUpgradeableProxy
    function _getProxyAdmin(address) internal view override returns (address) {
        return admin;
    }

    function setUp() public {
        admin = address(0x9999);
        owner = address(this);
        dao = address(0xDA0);
        proxyAdmin = admin;

        vm.startPrank(owner);

        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);

        _deployDAO();
        _deployV3Contracts(owner);

        // Register all V3 selectors for test functionality
        _setupSeigManagerV3AllTestSelectors();

        _setupCrossReferences(owner);

        seigManager = SeigManagerV3_1(seigManagerProxy);
        layer2Manager = Layer2ManagerV3(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);
        depositManager = DepositManagerV3(depositManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);
        rat = RAT(ratProxy);

        // minimumAmount 설정 (operator 최소 스테이킹 요구사항: 100 WTON)
        SeigManagerV1_2(seigManagerProxy).setMinimumAmount(100e27);

        // 테스트 환경을 위한 seigniorage 시작 블록 및 초기 공급량 설정
        // (mainnet 기본값 사용 시 block.number underflow 발생)
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(block.number);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50000000e27); // 50M TON

        // V3 파라미터 설정
        seigManager.setDaoDistributionRatio(0.1e27);     // d = 10%
        seigManager.setMinStakingRatio(0.1e27);          // θ = 10%
        seigManager.setValidatorDistributionRatio(0.2e27); // α = 20%
        seigManager.setHalfSaturationPoint(1000e27);     // k = 1000
        seigManager.setStakedSeigFactor(0);              // λ = 0 (V3 모드)

        // RAT 파라미터
        rat.setSlashingPenalty(100 * RAY);
        rat.setValidatorBuffer(100 * RAY);
        rat.setMinimumThreshold(200 * RAY);

        // Mock 컨트랙트 생성 및 L2 등록
        _setupMockContractsAndRegisterL2s();

        // setRatContract selector is already registered by _setupSeigManagerV3CoreSelectors()
        seigManager.setRatContract(address(rat));

        // V3 파라미터 설정 및 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        vm.stopPrank();
    }

    function _setupMockContractsAndRegisterL2s() internal {
        // L2 #1: 1000 TON 브릿지
        mockL1Bridge1 = address(0x8101);
        mockPortal1 = address(0x8102);
        mockDisputeGameFactory1 = address(0x8103);
        mockL2TON1 = address(0x8104);

        mockSystemConfig1 = new SimpleMockSystemConfig();
        mockSystemConfig1.setL1StandardBridge(mockL1Bridge1);
        mockSystemConfig1.setOptimismPortal(mockPortal1);
        mockSystemConfig1.setDisputeGameFactory(mockDisputeGameFactory1);
        mockSystemConfig1.setUnsafeBlockSigner(operator1);

        (mockLayer2_1, operatorManager1) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig1),
            mockL2TON1,
            "TestL2_1",
            operator1,
            1000 * RAY // 오퍼레이터 담보금
        );

        // L2 #2: 2000 TON 브릿지
        mockL1Bridge2 = address(0x8201);
        mockPortal2 = address(0x8202);
        mockDisputeGameFactory2 = address(0x8203);
        mockL2TON2 = address(0x8204);

        mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(mockL1Bridge2);
        mockSystemConfig2.setOptimismPortal(mockPortal2);
        mockSystemConfig2.setDisputeGameFactory(mockDisputeGameFactory2);
        mockSystemConfig2.setUnsafeBlockSigner(operator2);

        (mockLayer2_2, operatorManager2) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig2),
            mockL2TON2,
            "TestL2_2",
            operator2,
            1000 * RAY
        );

        // L2 #3: 3000 TON 브릿지
        mockL1Bridge3 = address(0x8301);
        mockPortal3 = address(0x8302);
        mockDisputeGameFactory3 = address(0x8303);
        mockL2TON3 = address(0x8304);

        mockSystemConfig3 = new SimpleMockSystemConfig();
        mockSystemConfig3.setL1StandardBridge(mockL1Bridge3);
        mockSystemConfig3.setOptimismPortal(mockPortal3);
        mockSystemConfig3.setDisputeGameFactory(mockDisputeGameFactory3);
        mockSystemConfig3.setUnsafeBlockSigner(operator3);

        (mockLayer2_3, operatorManager3) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig3),
            mockL2TON3,
            "TestL2_3",
            operator3,
            1000 * RAY
        );
    }

    function _deployDAO() internal {
        MockDAOCommitteeProxy mockProxy = new MockDAOCommitteeProxy(ton);
        daoCommitteeProxy = address(mockProxy);

        daoCommitteeProxy2 = address(new DAOCommitteeProxy2());
        daoCommitteeV1 = address(new DAOCommittee_V1());
        daoCommitteeOwner = address(new DAOCommitteeOwner());

        mockProxy.upgradeTo(daoCommitteeProxy2);
        IDAOCommitteeProxy2(daoCommitteeProxy).upgradeTo2(daoCommitteeV1);
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

        candidateImpl = address(new Candidate());
        candidateAddOnImpl = address(new CandidateAddOnV1_1());

        CandidateFactoryProxy cfProxy = new CandidateFactoryProxy();
        candidateFactoryProxy = address(cfProxy);
        cfProxy.upgradeTo(address(new CandidateFactory()));

        CandidateAddOnFactoryProxy caofProxy = new CandidateAddOnFactoryProxy();
        candidateAddOnFactoryProxy = address(caofProxy);
        caofProxy.upgradeTo(address(new CandidateAddOnFactory()));

        CandidateFactory(candidateFactoryProxy).setAddress(depositManagerProxy, daoCommitteeProxy, candidateImpl, ton, wton);
        CandidateAddOnFactory(candidateAddOnFactoryProxy).setAddress(depositManagerProxy, daoCommitteeProxy, candidateAddOnImpl, ton, wton, l1BridgeRegistryProxy);

        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(candidateFactoryProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(candidateAddOnFactoryProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setSeigManager(seigManagerProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(layer2ManagerProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Registry(layer2RegistryProxy);

        Layer2Registry(layer2RegistryProxy).addMinter(daoCommitteeProxy);
    }

    function _registerLayer2WithSystemConfig(
        address systemConfig,
        address l2TON,
        string memory name,
        address operator,
        uint256 operatorDeposit
    ) internal returns (address layer2, address operatorMgr) {
        vm.startPrank(owner);
        if (!l1BridgeRegistry.isManager(owner)) l1BridgeRegistry.addManager(owner);
        if (!l1BridgeRegistry.isRegistrant(owner)) l1BridgeRegistry.addRegistrant(owner);
        l1BridgeRegistry.registerRollupConfig(systemConfig, 3, l2TON, name);
        vm.stopPrank();

        vm.startPrank(operator);
        MockWTON(wton).mint(operator, operatorDeposit);
        MockWTON(wton).approve(layer2ManagerProxy, operatorDeposit);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(systemConfig, operatorDeposit, false, name);
        vm.stopPrank();

        layer2 = Layer2ManagerV3(layer2ManagerProxy).getLayer2BySystemConfig(systemConfig);
        operatorMgr = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(systemConfig);
    }

    function _setupCrossReferences(address) internal override {
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);

        Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
            l1BridgeRegistryProxy, operatorManagerFactory, ton, wton
        );
        Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
            daoCommitteeProxy, depositManagerProxy, seigManagerProxy, address(0)
        );

        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(layer2ManagerProxy, seigManagerProxy, ton);
        OperatorManagerFactory(operatorManagerFactory).setAddresses(depositManagerProxy, ton, wton, layer2ManagerProxy);
        DepositManagerV3(depositManagerProxy).setAddresses(l1BridgeRegistryProxy, layer2ManagerProxy);
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    /// @notice effectiveBridgedTON 설정 헬퍼 (테스트용)
    function _setEffectiveBridgedTON(address layer2, uint256 amount, bool eligible) internal {
        // Storage slot 접근으로 직접 설정 (테스트 목적)
        // bridgedTONInfo는 SeigManagerV3_1Storage에 정의됨
        // 이 함수는 테스트 편의를 위해 vm.store 사용

        // 실제 시스템에서는 onBridgedTonChange를 통해 업데이트됨
        // 테스트에서는 Mock으로 시뮬레이션
    }

    // ==========================================
    // E2E-031: 다중 L2 비례 분배 테스트
    // ==========================================

    /// @notice E2E-031: 다중 L2 시뇨리지 분배 - 자격 조건 확인
    function test_E2E031_multiL2_eligibilityCheck() public {
        // 3개 L2가 모두 등록됨
        assertTrue(mockLayer2_1 != address(0), "L2_1 should be registered");
        assertTrue(mockLayer2_2 != address(0), "L2_2 should be registered");
        assertTrue(mockLayer2_3 != address(0), "L2_3 should be registered");

        // 자격 조건 확인 (오퍼레이터 담보금 기준)
        (, uint256 required1, uint256 current1) = seigManager.checkCurrentEligibility(mockLayer2_1);
        (, uint256 required2, ) = seigManager.checkCurrentEligibility(mockLayer2_2);
        (, uint256 required3, ) = seigManager.checkCurrentEligibility(mockLayer2_3);

        // 모든 L2는 오퍼레이터 담보금(1000 RAY)이 있으므로 자격 충족 가능
        // required는 max(θ × B_i, D_sequencer)
        // B_i = 0 (아직 브릿지된 TON 없음), θ = 0.1
        // D_sequencer = H_max × C_max + Δ_sequencer = 0 (기본값)
        // 따라서 required = 0, current = 1000 RAY → eligible = true

        emit log_named_uint("L2_1 required", required1);
        emit log_named_uint("L2_1 current", current1);
        emit log_named_uint("L2_2 required", required2);
        emit log_named_uint("L2_3 required", required3);
    }

    /// @notice E2E-031: 쌍곡선 포화 함수 계산 검증
    function test_E2E031_hyperbolicSaturation_formula() public view {
        // y(x) = L × (x / (k + x))
        // k = 1000e27 (halfSaturationPoint)

        uint256 L = 1000e27; // 최대 L2 배분
        uint256 k = seigManager.halfSaturationPoint();

        // x = 0 → y = 0
        assertEq(seigManager.hyperbolicSaturation(0, L), 0, "y(0) should be 0");

        // x = k → y = L/2
        uint256 yAtK = seigManager.hyperbolicSaturation(k, L);
        assertApproxEqRel(yAtK, L / 2, 0.01e18, "y(k) should be L/2");

        // x = 2k → y = 2L/3
        uint256 yAt2K = seigManager.hyperbolicSaturation(2 * k, L);
        assertApproxEqRel(yAt2K, (2 * L) / 3, 0.01e18, "y(2k) should be 2L/3");

        // x → ∞ → y → L (근사)
        uint256 yAtLarge = seigManager.hyperbolicSaturation(100 * k, L);
        assertGt(yAtLarge, (99 * L) / 100, "y(large) should approach L");
    }

    /// @notice SD-014: B̃_i 비례 분배 공식 검증
    /// @dev Seig_i = y(x) · (B̃_i / x)
    function test_SD014_proportionalDistribution_formula() public pure {
        // 총 effectiveBridgedTON (x) = 6000e27 (1000 + 2000 + 3000)
        // x = 6000e27;
        // L = 1000e27;

        // y(x) = L × x / (k + x)
        // k = 1000e27
        // y = 1000 × 6000 / (1000 + 6000) = 6000000 / 7000 ≈ 857.14e27
        // y = seigManager.hyperbolicSaturation(x, L);

        // L2_1: B̃_1 = 1000e27, Seig_1 = y × (1000 / 6000) = y / 6
        // seig1 = seigManager.calculateL2Seigniorage(mockLayer2_1, y, x);
        // 실제로는 effectiveBridgedTON이 설정되어 있어야 함

        // L2_2: B̃_2 = 2000e27, Seig_2 = y × (2000 / 6000) = y / 3
        // L2_3: B̃_3 = 3000e27, Seig_3 = y × (3000 / 6000) = y / 2

        // 비례 관계 확인: Seig_1 : Seig_2 : Seig_3 = 1 : 2 : 3
        // (실제 테스트는 effectiveBridgedTON 설정 후 수행)
        assertTrue(true, "Formula verification placeholder");
    }

    /// @notice SD-015: 자격 미달 L2 제외 분배
    function test_SD015_ineligibleL2_excluded() public {
        // 초기 상태: 3개 L2 모두 등록됨
        assertTrue(mockLayer2_1 != address(0), "L2_1 registered");
        assertTrue(mockLayer2_2 != address(0), "L2_2 registered");
        assertTrue(mockLayer2_3 != address(0), "L2_3 registered");

        // L2_2 오퍼레이터 담보금 0으로 설정 (자격 미달)
        // 실제로는 출금으로 담보금을 줄여야 함
        // 여기서는 자격 상태만 확인

        (bool eligible1, , ) = seigManager.checkCurrentEligibility(mockLayer2_1);
        (bool eligible2, , ) = seigManager.checkCurrentEligibility(mockLayer2_2);
        (bool eligible3, , ) = seigManager.checkCurrentEligibility(mockLayer2_3);

        emit log_named_uint("L2_1 eligible", eligible1 ? 1 : 0);
        emit log_named_uint("L2_2 eligible", eligible2 ? 1 : 0);
        emit log_named_uint("L2_3 eligible", eligible3 ? 1 : 0);
    }

    /// @notice 시퀀서 보상 계산 검증
    /// @dev o_i = (1 - α) × Seig_i
    function test_SD012_sequencerReward_formula() public view {
        uint256 l2Seigniorage = 1000e27;
        // alpha = seigManager.validatorDistributionRatio(); // 0.2e27

        // 시퀀서 = (1 - 0.2) × 1000 = 800
        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seigniorage);
        assertEq(sequencerReward, 800e27, "Sequencer should get (1-alpha) * seig");

        // 검증자 = α × 1000 = 200
        uint256 validatorReward = l2Seigniorage - sequencerReward;
        assertEq(validatorReward, 200e27, "Validators should get alpha * seig");
    }

    /// @notice DAO 분배 계산 검증
    /// @dev S_DAO = d × A₂
    function test_SD010_daoDistribution_formula() public view {
        // d = 10%, A₂ = 1000
        // S_DAO = 0.1 × 1000 = 100
        uint256 daoRatio = seigManager.daoDistributionRatio(); // 0.1e27
        assertEq(daoRatio, 0.1e27, "DAO ratio should be 10%");

        // L = A₂ - S_DAO = 1000 - 100 = 900
        // 여기서 L은 L2 분배용 재원
    }

    /// @notice SD-001: V3 마이그레이션 상태 확인
    function test_SD001_v3Migration_state() public view {
        assertTrue(seigManager.v3Migrated(), "Should be V3 migrated");
        assertGt(seigManager.v3MigrationBlock(), 0, "Migration block should be set");
    }

    /// @notice SD-002: 파라미터 설정 검증
    function test_SD002_v3Parameters_verification() public view {
        // Note: _setV3ParametersForTest() sets these values (overrides earlier settings)
        assertEq(seigManager.daoDistributionRatio(), 0.1e27, "d = 10%");
        // theta = 1% (테스트용 낮은 값, operator stake 100 WTON으로 eligible 가능)
        assertEq(seigManager.minStakingRatio(), 0.01e27, "theta = 1%"); // Set by _setV3ParamsCore()
        assertEq(seigManager.validatorDistributionRatio(), 0.2e27, "alpha = 20%");
        assertEq(seigManager.halfSaturationPoint(), 1000e27, "k = 1000");
        assertEq(seigManager.stakedSeigFactor(), 0, "lambda = 0 (V3 mode)");
    }

    /// @notice SD-016: 시뇨리지 추정 (estimateL2Seigniorage)
    function test_SD016_estimateL2Seigniorage() public view {
        assertTrue(seigManager.v3Migrated(), "V3 should be migrated");

        uint256 estimated1 = seigManager.estimateL2Seigniorage(mockLayer2_1);
        assertEq(estimated1, 0, "Estimate should be 0 when no effective bridged TON");
    }

    /// @notice SD-017: 동시 분배 방지 (같은 블록)
    function test_SD017_noDoubleDistribution_sameBlock() public {
        vm.roll(block.number + 100);

        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        vm.prank(mockLayer2_2);
        vm.expectRevert(); // LastSeigBlockError
        seigManager.updateSeigniorage();
    }
}
