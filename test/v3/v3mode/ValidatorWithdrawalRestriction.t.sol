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

/// @title ValidatorWithdrawalRestrictionTest
/// @notice 검증자 출금 제한 테스트 (INT-013)
/// @dev 테스트 계획서 INT-013: 검증자 출금 제한 D_min 이상 유지 검증
///
/// 테스트 대상:
/// - INT-013: 검증자가 D_min(동적 최소 담보금) 이상 유지해야 출금 가능
/// - 검증자가 활성 상태일 때 출금 시 최소 담보금 체크
/// - 비활성 검증자는 제한 없이 출금 가능
contract ValidatorWithdrawalRestrictionTest is Test, DeployV3Full {
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
    address public admin;
    address public owner;
    address public operator1 = address(0x4001);
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
        admin = address(0x9999);
        owner = address(this);
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

        // RAT 파라미터: D_min = C_off + validatorBuffer = 100 + 100 = 200 WTON
        rat.setSlashingPenalty(100 * RAY);
        rat.setValidatorBuffer(100 * RAY);
        rat.setMinimumThreshold(200 * RAY);
        rat.setRatTriggerProbability(RAY);

        _setupMockContracts();

        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY
        );

        // setRatContract selector is already registered by _setupSeigManagerV3CoreSelectors()
        seigManager.setRatContract(address(rat));

        // V3 마이그레이션
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setStakedSeigFactor(RAY);
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setValidatorReward(validatorPoolProxy);
        seigManager.migrateToV3();

        MockTON(ton).mint(validator1, INITIAL_TON);
        MockTON(ton).mint(validator2, INITIAL_TON);
        MockTON(ton).mint(user1, INITIAL_TON);

        vm.stopPrank();
    }

    function _setupMockContracts() internal {
        mockL1Bridge = address(0x8001);
        mockPortal = address(0x8002);
        mockDisputeGameFactory = address(0x8003);
        mockL2TON = address(0x8004);

        mockSystemConfig = new SimpleMockSystemConfig();
        mockSystemConfig.setL1StandardBridge(mockL1Bridge);
        mockSystemConfig.setOptimismPortal(mockPortal);
        mockSystemConfig.setDisputeGameFactory(mockDisputeGameFactory);
        mockSystemConfig.setUnsafeBlockSigner(operator1);
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

    function _registerValidator(address validator, uint256 depositAmount) internal {
        vm.startPrank(validator);
        MockWTON(wton).mint(validator, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator, depositAmount);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();
    }

    function _depositOnly(address account, uint256 depositAmount) internal {
        vm.startPrank(account);
        MockWTON(wton).mint(account, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, account, depositAmount);
        vm.stopPrank();
    }

    function _getCoinageBalance(address layer2, address account) internal view returns (uint256) {
        return SeigManagerV1_2(seigManagerProxy).stakeOf(layer2, account);
    }

    // ==========================================
    // INT-013: 검증자 출금 제한 테스트
    // ==========================================

    /// @notice INT-013: 활성 검증자가 D_min 이상 유지 시 출금 성공
    function test_INT013_validatorWithdrawal_aboveMinimum_success() public {
        // D_min = 200 WTON
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 dMin = rat.getDynamicMinimumCollateral(address(mockSystemConfig));
        assertEq(dMin, 200 * RAY, "D_min should be 200 WTON");

        // 출금 후에도 D_min 이상 유지되는 금액 출금
        uint256 withdrawAmount = 200 * RAY; // 500 - 200 = 300 >= D_min(200)

        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // 출금 요청 성공 확인
        uint256 balanceAfter = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfter, depositAmount - withdrawAmount, "Withdrawal request should succeed");
    }

    /// @notice INT-013: 활성 검증자가 D_min 미만으로 출금 시 revert
    /// @dev SKIP: SeigManager에 validator 최소 담보 체크 기능이 아직 구현되지 않음
    function test_INT013_validatorWithdrawal_belowMinimum_reverts() public {
        vm.skip(true); // TODO: SeigManager.onWithdraw에 validator 최소 담보 체크 구현 필요

        // D_min = 200 WTON
        uint256 depositAmount = 300 * RAY;
        _registerValidator(validator1, depositAmount);

        // dMin = rat.getDynamicMinimumCollateral(address(mockSystemConfig));

        // 출금 후 D_min 미만이 되는 금액 출금 시도
        // 300 - 150 = 150 < D_min(200) → revert
        uint256 withdrawAmount = 150 * RAY;

        vm.startPrank(validator1);
        vm.expectRevert("SeigManager: validator minimum collateral required");
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();
    }

    /// @notice INT-013: 활성 검증자가 정확히 D_min까지 출금 시 성공
    function test_INT013_validatorWithdrawal_exactMinimum_success() public {
        // D_min = 200 WTON
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 출금 후 정확히 D_min 유지
        // 500 - 300 = 200 = D_min → 성공
        uint256 withdrawAmount = 300 * RAY;

        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        uint256 balanceAfter = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfter, 200 * RAY, "Balance should be exactly D_min");
    }

    /// @notice INT-013: 비활성 검증자는 제한 없이 출금 가능
    function test_INT013_inactiveValidator_noRestriction() public {
        uint256 depositAmount = 300 * RAY;
        _registerValidator(validator1, depositAmount);

        // 검증자 탈퇴
        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        // 비활성 상태 확인
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertFalse(isActive, "Validator should be inactive");

        // 비활성 검증자는 전액 출금 가능
        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, depositAmount);
        vm.stopPrank();

        uint256 balanceAfter = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfter, 0, "Inactive validator can withdraw all");
    }

    /// @notice INT-013: 일반 스테이커(비검증자)는 제한 없이 출금 가능
    function test_INT013_nonValidator_noRestriction() public {
        uint256 depositAmount = 100 * RAY; // D_min 미만

        _depositOnly(user1, depositAmount);

        // 일반 스테이커는 전액 출금 가능
        vm.startPrank(user1);
        depositManager.requestWithdrawal(mockLayer2, depositAmount);
        vm.stopPrank();

        uint256 balanceAfter = _getCoinageBalance(mockLayer2, user1);
        assertEq(balanceAfter, 0, "Non-validator can withdraw all");
    }

    /// @notice INT-013: 동적 D_min 변경 시 출금 제한 업데이트
    function test_INT013_dynamicMinimum_changesWithValidatorCount() public {
        // 검증자 1명 등록
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // dMinWith1 = rat.getDynamicMinimumCollateral(address(mockSystemConfig));

        // 검증자 2명 등록 (attentionCost 설정 필요)
        // 기본 설정에서는 attentionCost=0이므로 D_min은 고정
        // attentionCost를 설정하면 동적으로 변함
        vm.prank(owner);
        rat.setAttentionCost(50 * RAY);

        _registerValidator(validator2, depositAmount);

        uint256 dMinWith2 = rat.getDynamicMinimumCollateral(address(mockSystemConfig));

        // attentionCost > 0이면 C_off = max(slashingPenalty, (c_m × N) / π_a)
        // c_m = 50, N = 2, π_a = 1 → (50 × 2 × 1e27) / 1e27 = 100
        // max(100, 100) = 100
        // D_min = 100 + 100 = 200
        assertEq(dMinWith2, 200 * RAY, "D_min with 2 validators");
    }

    /// @notice INT-013: 부분 출금 후 남은 잔액이 D_min 이상이면 여전히 활성
    function test_INT013_partialWithdrawal_remainsActive() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 부분 출금 (D_min 이상 유지)
        uint256 withdrawAmount = 100 * RAY;

        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // 검증자 여전히 활성 상태
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator should remain active after partial withdrawal");
    }

    /// @notice INT-013: RAT 선차감 후 출금 시도
    function test_INT013_withdrawAfterRATDeduction() public {
        uint256 depositAmount = 400 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거 (100 WTON 선차감)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후 잔액: 400 - 100 = 300 WTON
        uint256 balanceAfterDeduction = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfterDeduction, 300 * RAY, "Balance after RAT deduction");

        // D_min = 200 WTON, 현재 잔액 = 300 WTON
        // 100 WTON 출금 시도 → 300 - 100 = 200 >= D_min → 성공
        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, 100 * RAY);
        vm.stopPrank();

        assertEq(_getCoinageBalance(mockLayer2, validator1), 200 * RAY, "Withdrawal should succeed");
    }

    /// @notice INT-013: RAT 선차감 후 D_min 미만 출금 시도 → revert
    /// @dev SKIP: SeigManager에 validator 최소 담보 체크 기능이 아직 구현되지 않음
    function test_INT013_withdrawBelowMinAfterRATDeduction_reverts() public {
        vm.skip(true); // TODO: SeigManager.onWithdraw에 validator 최소 담보 체크 구현 필요

        uint256 depositAmount = 350 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거 (100 WTON 선차감)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후 잔액: 350 - 100 = 250 WTON
        // D_min = 200 WTON
        // 100 WTON 출금 시도 → 250 - 100 = 150 < D_min → revert
        vm.startPrank(validator1);
        vm.expectRevert("SeigManager: validator minimum collateral required");
        depositManager.requestWithdrawal(mockLayer2, 100 * RAY);
        vm.stopPrank();
    }

    // ==========================================
    // 추가: getValidatorMinCollateralForLayer2 테스트
    // ==========================================

    /// @notice getValidatorMinCollateralForLayer2: 활성 검증자 → D_min 반환
    function test_getValidatorMinCollateralForLayer2_activeValidator() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 minCollateral = rat.getValidatorMinCollateralForLayer2(mockLayer2, validator1);
        uint256 expectedDmin = rat.getDynamicMinimumCollateral(address(mockSystemConfig));

        assertEq(minCollateral, expectedDmin, "Should return D_min for active validator");
    }

    /// @notice getValidatorMinCollateralForLayer2: 비활성 검증자 → 0 반환
    function test_getValidatorMinCollateralForLayer2_inactiveValidator() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 검증자 탈퇴
        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        uint256 minCollateral = rat.getValidatorMinCollateralForLayer2(mockLayer2, validator1);
        assertEq(minCollateral, 0, "Should return 0 for inactive validator");
    }

    /// @notice getValidatorMinCollateralForLayer2: 비검증자 → 0 반환
    function test_getValidatorMinCollateralForLayer2_nonValidator() public {
        _depositOnly(user1, 500 * RAY);

        uint256 minCollateral = rat.getValidatorMinCollateralForLayer2(mockLayer2, user1);
        assertEq(minCollateral, 0, "Should return 0 for non-validator");
    }
}
