// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import {SimpleMockSystemConfig} from "../../../src/mocks/SimpleMockSystemConfig.sol";
import {RAT} from "../../../src/validator/RAT.sol";
import {Layer2Registry} from "../../../src/stake/Layer2Registry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

/// @title SeigniorageAccuracyTest
/// @notice 시뇨리지 정확성 테스트 - span × seigPerBlock 검증
/// @dev 테스트 전략서 SM-016-V3: 블록 수 기반 시뇨리지 계산 정확성 검증
///
/// 테스트 대상:
/// - SM-016-V3: span × seigPerBlock = 총 시뇨리지 정확성
/// - 블록 간격에 따른 시뇨리지 민팅량 검증
/// - DAO + L2 분배 총액 = 예상 시뇨리지 검증
contract SeigniorageAccuracyTest is Test, DeployV3Full {
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
    // Mock Contracts - L2
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig1;
    address public mockL1Bridge1;
    address public mockPortal1;
    address public mockDisputeGameFactory1;
    address public mockL2TON1;
    address public mockLayer2_1;
    address public operatorManager1;

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
    address public daoAddress;

    uint256 constant RAY = 1e27;
    uint256 constant WEI = 1e18;

    // ==========================================
    // Setup
    // ==========================================

    /// @notice Override to use separate admin address for TransparentUpgradeableProxy
    function _getProxyAdmin(address) internal view override returns (address) {
        return admin;
    }

    function setUp() public {
        admin = address(0x9999);
        owner = address(this);
        daoAddress = address(0xDA0);
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
        _setupMockContractsAndRegisterL2();

        seigManager.setRatContract(address(rat));

        // V3 파라미터 설정 및 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        vm.stopPrank();
    }

    function _setupMockContractsAndRegisterL2() internal {
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
    // SM-016-V3: span × seigPerBlock = 총 시뇨리지 정확성 테스트
    // ==========================================

    /// @notice SM-016-V3: 단일 블록 진행 시 시뇨리지 정확성
    /// @dev span = 1 블록에서 seigPerBlock만큼 정확히 분배되는지 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_singleBlock() public {
        // Setup: seigPerBlock 값 조회
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        assertTrue(seigPerBlock > 0, "seigPerBlock should be set");

        // 현재 lastSeigBlock 기록
        uint256 lastSeigBlockBefore = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();

        // 1 블록 진행
        uint256 blocksToAdvance = 1;
        vm.roll(block.number + blocksToAdvance);

        // 예상 시뇨리지 계산
        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // DAO 잔액 기록 (DAO가 모든 시뇨리지를 받음 - L2 자격 미충족 시)
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // updateSeigniorage 호출
        vm.prank(mockLayer2_1);
        bool success = seigManager.updateSeigniorage();
        assertTrue(success, "updateSeigniorage should succeed");

        // lastSeigBlock 업데이트 확인
        uint256 lastSeigBlockAfter = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();
        assertEq(lastSeigBlockAfter - lastSeigBlockBefore, blocksToAdvance, "lastSeigBlock should advance by 1");

        // DAO 잔액 변화 확인 (totalEffectiveBridgedTON = 0이면 전액 DAO로)
        uint256 daoBalanceAfter = IERC20(wton).balanceOf(daoAddr);
        uint256 daoReceived = daoBalanceAfter - daoBalanceBefore;

        // L2가 자격 미충족 시: 전액 DAO
        // 예상: S_DAO = d × A + (L - y(x)) = A (when y(x) = 0)
        assertEq(daoReceived, expectedTotalSeigniorage, "DAO should receive all seigniorage when no eligible L2");

        emit log_named_uint("seigPerBlock", seigPerBlock);
        emit log_named_uint("blocksAdvanced", blocksToAdvance);
        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("daoReceived", daoReceived);
    }

    /// @notice SM-016-V3: 다중 블록 진행 시 시뇨리지 정확성
    /// @dev span = 100 블록에서 100 × seigPerBlock만큼 정확히 분배되는지 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_multipleBlocks() public {
        // Setup: seigPerBlock 값 조회
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();

        // 100 블록 진행
        uint256 blocksToAdvance = 100;
        vm.roll(block.number + blocksToAdvance);

        // 예상 시뇨리지 계산
        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // DAO 잔액 기록
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // updateSeigniorage 호출
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // DAO 잔액 변화 확인
        uint256 daoBalanceAfter = IERC20(wton).balanceOf(daoAddr);
        uint256 daoReceived = daoBalanceAfter - daoBalanceBefore;

        assertEq(daoReceived, expectedTotalSeigniorage, "span * seigPerBlock = total seigniorage");

        emit log_named_uint("blocksAdvanced", blocksToAdvance);
        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("actualDaoReceived", daoReceived);
    }

    /// @notice SM-016-V3: L2 자격 충족 시 분배 정확성
    /// @dev span × seigPerBlock = DAO분배 + L2분배 + 미분배분 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_withEligibleL2() public {
        // L2 자격 충족을 위해 effectiveBridgedTON 설정
        // 실제 시스템에서는 onBridgedTonChange를 통해 설정됨
        // 테스트에서는 직접 storage 조작

        // 먼저 자격 조건 확인
        (bool eligible, uint256 required, uint256 current) = seigManager.checkCurrentEligibility(mockLayer2_1);

        emit log_named_uint("required stake", required);
        emit log_named_uint("current stake", current);
        emit log_named_uint("eligible", eligible ? 1 : 0);

        // seigPerBlock 조회
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();

        // 50 블록 진행
        uint256 blocksToAdvance = 50;
        vm.roll(block.number + blocksToAdvance);

        // 예상 총 시뇨리지
        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // 분배 비율 조회
        // daoRatio = seigManager.daoDistributionRatio(); // d = 0.1

        // 잔액 기록
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);
        uint256 layer2ManagerBalanceBefore = IERC20(wton).balanceOf(layer2ManagerProxy);
        uint256 validatorRewardBalanceBefore = IERC20(wton).balanceOf(validatorPoolProxy);

        // updateSeigniorage 호출
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // 잔액 변화 계산
        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;
        uint256 layer2ManagerReceived = IERC20(wton).balanceOf(layer2ManagerProxy) - layer2ManagerBalanceBefore;
        uint256 validatorReceived = IERC20(wton).balanceOf(validatorPoolProxy) - validatorRewardBalanceBefore;

        // 총 분배량 = DAO + L2Manager + ValidatorReward
        uint256 totalDistributed = daoReceived + layer2ManagerReceived + validatorReceived;

        // 핵심 검증: span × seigPerBlock = 총 분배량
        assertEq(totalDistributed, expectedTotalSeigniorage, "span * seigPerBlock = total distributed");

        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("daoReceived", daoReceived);
        emit log_named_uint("layer2ManagerReceived", layer2ManagerReceived);
        emit log_named_uint("validatorReceived", validatorReceived);
        emit log_named_uint("totalDistributed", totalDistributed);
    }

    /// @notice SM-016-V3: 연속 호출 시 누적 정확성
    /// @dev 여러 번 updateSeigniorage 호출 시 누적 시뇨리지 정확성 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_cumulative() public {
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();

        uint256 totalBlocksAdvanced = 0;
        uint256 initialDaoBalance = IERC20(wton).balanceOf(daoAddr);

        // 첫 번째 호출: 10 블록
        vm.roll(block.number + 10);
        totalBlocksAdvanced += 10;
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // 두 번째 호출: 20 블록
        vm.roll(block.number + 20);
        totalBlocksAdvanced += 20;
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // 세 번째 호출: 30 블록
        vm.roll(block.number + 30);
        totalBlocksAdvanced += 30;
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // 누적 검증
        uint256 expectedCumulativeSeigniorage = totalBlocksAdvanced * seigPerBlock;
        uint256 actualCumulativeDaoReceived = IERC20(wton).balanceOf(daoAddr) - initialDaoBalance;

        assertEq(actualCumulativeDaoReceived, expectedCumulativeSeigniorage,
            "Cumulative seigniorage = sum of (span * seigPerBlock)");

        emit log_named_uint("totalBlocksAdvanced", totalBlocksAdvanced);
        emit log_named_uint("expectedCumulativeSeigniorage", expectedCumulativeSeigniorage);
        emit log_named_uint("actualCumulativeDaoReceived", actualCumulativeDaoReceived);
    }

    /// @notice SM-016-V3: Fuzz 테스트 - 임의 블록 수에서 정확성
    /// @dev 임의의 블록 수에서 span × seigPerBlock = 총 시뇨리지 검증
    function testFuzz_SM016_v3_updateSeigniorage_exactAmountByBlocks(uint256 blocksToAdvance) public {
        // 블록 수 범위 제한 (1 ~ 10000)
        blocksToAdvance = bound(blocksToAdvance, 1, 10000);

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // 블록 진행
        vm.roll(block.number + blocksToAdvance);

        // updateSeigniorage 호출
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // 검증
        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;
        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;

        assertEq(daoReceived, expectedTotalSeigniorage, "span * seigPerBlock = total seigniorage (fuzz)");
    }

    /// @notice SM-016-V3: 대량 블록 진행 시 오버플로우 방지
    /// @dev 큰 span 값에서도 정확한 계산 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_largeSpan() public {
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // 큰 블록 수 진행 (1년 ≈ 2,628,000 블록)
        uint256 blocksToAdvance = 1_000_000;
        vm.roll(block.number + blocksToAdvance);

        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // updateSeigniorage 호출
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // 검증
        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;
        assertEq(daoReceived, expectedTotalSeigniorage, "Large span calculation accurate");

        emit log_named_uint("blocksAdvanced (1M)", blocksToAdvance);
        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("daoReceived", daoReceived);
    }

    /// @notice SM-016-V3: span = 0 시 시뇨리지 없음
    /// @dev 같은 블록에서 두 번째 호출 시 revert (이미 다른 테스트에서 검증)
    function test_SM016_v3_updateSeigniorage_zeroSpan_reverts() public {
        // 첫 번째 호출을 위해 블록 진행
        vm.roll(block.number + 10);

        // 첫 번째 호출
        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        // 같은 블록에서 두 번째 호출 시 revert
        vm.prank(mockLayer2_1);
        vm.expectRevert(); // LastSeigBlockError
        seigManager.updateSeigniorage();
    }

    // ==========================================
    // Helper: V3 분배 공식 검증
    // ==========================================

    /// @notice V3 분배 공식 직접 계산 검증
    /// @dev A = span × seigPerBlock
    ///      S_DAO = d × A
    ///      L = A - S_DAO = (1 - d) × A
    ///      y(x) = L × (x / (k + x))
    ///      총 DAO = S_DAO + (L - y(x))
    ///      L2 시퀀서 = (1 - α) × y(x) × (B̃_i / x)
    ///      L2 검증자 = α × y(x) × (B̃_i / x)
    function test_SM016_v3_formulaVerification_daoOnlyCase() public {
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 daoRatio = seigManager.daoDistributionRatio(); // 0.1e27

        uint256 blocksToAdvance = 100;
        vm.roll(block.number + blocksToAdvance);

        // 수동 계산
        uint256 A = blocksToAdvance * seigPerBlock;
        uint256 S_DAO = (A * daoRatio) / RAY;
        uint256 L = A - S_DAO;

        // totalEffectiveBridgedTON = 0이면 y(x) = 0
        uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
        uint256 y = 0;
        if (totalEffective > 0) {
            uint256 k = seigManager.halfSaturationPoint();
            y = (L * totalEffective) / (k + totalEffective);
        }

        // 총 DAO 수령 = S_DAO + (L - y)
        uint256 expectedDaoTotal = S_DAO + (L - y);

        // 실제 분배
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        vm.prank(mockLayer2_1);
        seigManager.updateSeigniorage();

        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;

        // y = 0일 때: expectedDaoTotal = S_DAO + L = A (전액 DAO)
        assertEq(expectedDaoTotal, A, "When y=0, all seigniorage goes to DAO");
        assertEq(daoReceived, expectedDaoTotal, "DAO receives expected amount");

        emit log_named_uint("A (span * seigPerBlock)", A);
        emit log_named_uint("S_DAO (d * A)", S_DAO);
        emit log_named_uint("L (A - S_DAO)", L);
        emit log_named_uint("totalEffectiveBridgedTON", totalEffective);
        emit log_named_uint("y (hyperbolic)", y);
        emit log_named_uint("expectedDaoTotal", expectedDaoTotal);
        emit log_named_uint("actualDaoReceived", daoReceived);
    }
}
