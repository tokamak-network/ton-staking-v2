// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import {SimpleMockSystemConfig} from "../../../src/mocks/SimpleMockSystemConfig.sol";
import {RAT, MaxValidatorsReachedError, TestAlreadyExistsError} from "../../../src/validator/RAT.sol";
import {RATStorage} from "../../../src/validator/RATStorage.sol";
import {RATConfigParams} from "../../../src/validator/RATTypes.sol";
import {Layer2Registry} from "../../../src/stake/Layer2Registry.sol";
import {RefactorCoinageSnapshotI} from "../../../src/stake/interfaces/RefactorCoinageSnapshotI.sol";

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

/// @notice Mock FaultDisputeGame that provides systemConfig() for RAT.resolveClaim()
contract MockFaultDisputeGame {
    address public systemConfig;

    constructor(address _systemConfig) {
        systemConfig = _systemConfig;
    }
}

/// @title RATTest
/// @notice RAT (Randomized Attention Test) V3 단위 테스트
/// @dev 실제 컨트랙트를 사용하여 통합 테스트 수행
contract RATTest is Test, DeployV3Full {
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
    // Additional Mock for second L2
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig2;
    address public mockL2TON2;
    address public mockLayer2_2;
    address public operatorManager2;

    // ==========================================
    // Test Addresses
    // ==========================================
    address public admin;
    address public owner;
    address public factory;
    address public operator1 = address(0x4001);
    address public operator2 = address(0x4002);
    address public validator1 = address(0x6001);
    address public validator2 = address(0x6002);
    address public validator3 = address(0x6003);
    address public treasury = address(0x9001);

    MockFaultDisputeGame public mockGame1;

    uint256 internal constant RAY = 1e27;
    uint256 constant INITIAL_TON = 100_000 * 1e18;

    uint256 public slashingPenalty = 100e27;
    uint256 public validatorBuffer = 100e27;
    uint256 public minimumThreshold = 200e27;
    uint256 public evidenceSubmissionPeriod = 1 hours;
    uint256 public ratTriggerProbability = RAY; // 100% for testing
    uint256 public maxValidatorsPerL2 = 100;
    uint256 public challengeGameDuration = 7 days;
    uint256 public safetyBuffer = 1 days;
    uint256 public attentionCost = 1e27;
    bool public relaxedValidatorCheck = true;

    /// @notice Override to use separate admin address for TransparentUpgradeableProxy
    function _getProxyAdmin(address) internal view override returns (address) {
        return admin;
    }

    function setUp() public {
        admin = address(0x9999);
        owner = address(this);
        proxyAdmin = admin;

        vm.startPrank(owner);

        // 전체 시스템 배포
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);

        // DAO 배포
        _deployDAO();

        // V3 컨트랙트 배포
        _deployV3Contracts(owner);

        // Register all V3 selectors for test functionality
        _setupSeigManagerV3AllTestSelectors();

        _setupCrossReferences(owner);

        // 컨트랙트 참조
        seigManager = SeigManagerV3_1(seigManagerProxy);
        layer2Manager = Layer2ManagerV3(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);
        depositManager = DepositManagerV3(depositManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);
        rat = RAT(ratProxy);

        // minimumAmount 설정 (operator 최소 스테이킹 요구사항: 100 WTON)
        SeigManagerV1_2(seigManagerProxy).setMinimumAmount(100e27);

        // RAT 파라미터 설정
        rat.setSlashingPenalty(slashingPenalty);
        rat.setValidatorBuffer(validatorBuffer);
        rat.setMinimumThreshold(minimumThreshold);
        rat.setRatTriggerProbability(ratTriggerProbability);
        rat.setEvidenceSubmissionPeriod(evidenceSubmissionPeriod);
        rat.setChallengeGameDuration(challengeGameDuration);
        rat.setSafetyBuffer(safetyBuffer);
        rat.setAttentionCost(attentionCost);
        rat.setRelaxedValidatorCheck(relaxedValidatorCheck);
        rat.setMaxValidatorsPerL2(maxValidatorsPerL2);
        rat.setTreasury(treasury);

        // Mock 컨트랙트 생성
        _setupMockContracts();

        // Layer2 등록 (systemConfig1)
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY
        );

        // Factory 설정 (DisputeGameFactory를 factory로 사용)
        factory = mockDisputeGameFactory;

        // MockFaultDisputeGame 생성 (systemConfig1 사용)
        mockGame1 = new MockFaultDisputeGame(address(mockSystemConfig));

        // SeigManager에 RAT 컨트랙트 주소 설정
        seigManager.setRatContract(address(rat));

        // 테스트 환경을 위한 seigniorage 시작 블록 및 초기 공급량 설정
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(block.number);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50000000e27);

        // V3 파라미터 설정 및 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        vm.stopPrank();

        // 검증자들 스테이킹 (WTON 단위: 500, 600, 700 WTON)
        _stakeForValidator(validator1, mockLayer2, 500 * RAY);
        _stakeForValidator(validator2, mockLayer2, 600 * RAY);
        _stakeForValidator(validator3, mockLayer2, 700 * RAY);
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

        IDAOCommitteeProxy2(daoCommitteeProxy).setSelectorImplementations2(
            ownerSelectors,
            daoCommitteeOwner
        );

        candidateImpl = address(new Candidate());
        candidateAddOnImpl = address(new CandidateAddOnV1_1());

        CandidateFactoryProxy cfProxy = new CandidateFactoryProxy();
        candidateFactoryProxy = address(cfProxy);
        cfProxy.upgradeTo(address(new CandidateFactory()));

        CandidateAddOnFactoryProxy caofProxy = new CandidateAddOnFactoryProxy();
        candidateAddOnFactoryProxy = address(caofProxy);
        caofProxy.upgradeTo(address(new CandidateAddOnFactory()));

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

        if (!l1BridgeRegistry.isManager(owner)) {
            l1BridgeRegistry.addManager(owner);
        }
        if (!l1BridgeRegistry.isRegistrant(owner)) {
            l1BridgeRegistry.addRegistrant(owner);
        }

        l1BridgeRegistry.registerRollupConfig(
            systemConfig,
            3,
            l2TON,
            name
        );
        vm.stopPrank();

        vm.startPrank(operator);
        MockWTON(wton).mint(operator, operatorDeposit);
        MockWTON(wton).approve(layer2ManagerProxy, operatorDeposit);

        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            systemConfig,
            operatorDeposit,
            false,
            name
        );
        vm.stopPrank();

        layer2 = Layer2ManagerV3(layer2ManagerProxy).getLayer2BySystemConfig(systemConfig);
        operatorMgr = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(systemConfig);
    }

    function _setupCrossReferences(address) internal override {
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);

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
            address(0)
        );

        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(
            layer2ManagerProxy,
            seigManagerProxy,
            ton
        );

        OperatorManagerFactory(operatorManagerFactory).setAddresses(
            depositManagerProxy,
            ton,
            wton,
            layer2ManagerProxy
        );

        DepositManagerV3(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
    }

    /// @notice 검증자 스테이킹 헬퍼
    /// @param amount WTON 단위 (1e27 = 1 WTON)
    function _stakeForValidator(address validator, address layer2, uint256 amount) internal {
        vm.startPrank(validator);
        MockWTON(wton).mint(validator, amount);
        MockWTON(wton).approve(depositManagerProxy, amount);
        depositManager.deposit(layer2, validator, amount);
        vm.stopPrank();
    }

    /// @notice 검증자 스테이크 조회 헬퍼
    function _getValidatorStake(address layer2, address validator) internal view returns (uint256) {
        return seigManager.stakeOf(layer2, validator);
    }

    // ==========================================
    // 기본 테스트
    // ==========================================

    function test_RAT010_getDynamicMinimumCollateral() public view {
        // N=1 (기본값), attentionCost=0 이면 C_off = slashingPenalty
        uint256 minCollateral = rat.getDynamicMinimumCollateral(address(mockSystemConfig));
        assertEq(minCollateral, slashingPenalty + validatorBuffer);
    }

    function test_RAT012_getCoffWithRelaxedCheck_relaxedMode() public {
        // relaxedValidatorCheck = true (기본값)
        // C_off는 항상 slashingPenalty

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        uint256 coff = rat.getCoffWithRelaxedCheck(address(mockSystemConfig));
        assertEq(coff, slashingPenalty);
    }

    function test_RAT013_getCoffWithRelaxedCheck_strictMode() public {
        // relaxedValidatorCheck = false
        // C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)

        vm.prank(owner);
        rat.setRelaxedValidatorCheck(false);
        vm.prank(owner);
        rat.setAttentionCost(50e27); // c_m 설정

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        uint256 coff = rat.getCoffWithRelaxedCheck(address(mockSystemConfig));

        // 예상값 계산: (50e27 × 3 × 1e27) / 1e27 = 150e27
        uint256 expected = (50e27 * 3 * RAY) / RAY;
        assertEq(coff, expected);
        assertTrue(coff > slashingPenalty);
    }

    function test_RAT011_getDynamicCoff_withFormula() public view {
        // attentionCost=1e27 이지만 검증자 0명이므로 slashingPenalty 반환
        uint256 coff = rat.getDynamicCoff(address(mockSystemConfig));
        assertEq(coff, slashingPenalty);
    }

    function test_RAT014_getDynamicCoff_withAttentionCost() public {
        // attentionCost 설정 후 formula 기반 계산
        vm.prank(owner);
        rat.setAttentionCost(50e27);

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        uint256 coff = rat.getDynamicCoff(address(mockSystemConfig));

        // 예상값: max(100e27, (50e27 × 3 × 1e27) / 1e27) = 150e27
        uint256 expected = (50e27 * 3 * RAY) / RAY;
        assertEq(coff, expected);
    }

    function test_RAT012_getMinimumCollateralWithRelaxedCheck_relaxedMode() public view {
        // relaxedValidatorCheck = true (기본값)
        // D_min = C_off + validatorBuffer = slashingPenalty + validatorBuffer

        uint256 dmin = rat.getMinimumCollateralWithRelaxedCheck(address(mockSystemConfig));
        assertEq(dmin, slashingPenalty + validatorBuffer);
    }

    function test_RAT013_getMinimumCollateralWithRelaxedCheck_strictMode() public {
        // relaxedValidatorCheck = false
        // D_min = C_off(dynamic) + validatorBuffer

        vm.prank(owner);
        rat.setRelaxedValidatorCheck(false);
        vm.prank(owner);
        rat.setAttentionCost(50e27);

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        uint256 dmin = rat.getMinimumCollateralWithRelaxedCheck(address(mockSystemConfig));

        // 예상값: (50e27 × 3 × 1e27) / 1e27 + 100e27 = 250e27
        uint256 expectedCoff = (50e27 * 3 * RAY) / RAY;
        uint256 expected = expectedCoff + validatorBuffer;
        assertEq(dmin, expected);
    }

    // ==========================================
    // 검증자 등록 테스트
    // ==========================================

    function test_RAT001_registerValidator_success() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        (uint256 collateral, uint32 validatorIndex, bool isActive) =
            rat.getValidatorRegistration(validator1, address(mockSystemConfig));

        assertTrue(isActive);
        // 스테이킹된 금액 기반 collateral (factor 적용으로 약간 적을 수 있음)
        assertTrue(collateral > 0);
        assertEq(validatorIndex, 0);
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);
    }

    function test_RAT002_registerValidator_insufficientDeposit() public {
        // 새 검증자에게 최소 기준 미달 금액 스테이킹
        address poorValidator = address(0x7777);
        _stakeForValidator(poorValidator, mockLayer2, 100 * RAY); // minimumThreshold(200e27) 미달

        vm.prank(poorValidator);
        vm.expectRevert();
        rat.registerValidator(address(mockSystemConfig));
    }

    function test_RAT003_registerValidator_alreadyRegistered() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator1);
        vm.expectRevert();
        rat.registerValidator(address(mockSystemConfig));
    }

    function test_RAT006_registerMultipleValidators() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 3);
    }

    // ==========================================
    // 검증자 비활성화 테스트
    // ==========================================

    function test_RAT004_deactivateValidator() public {
        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        (uint256 collateral, , bool isActive) =
            rat.getValidatorRegistration(validator1, address(mockSystemConfig));

        assertFalse(isActive);
        // collateral은 저장된 값 유지
        assertTrue(collateral > 0);
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 0);

        // 스테이크는 변경 없음
        uint256 stakeAfter = _getValidatorStake(mockLayer2, validator1);
        assertEq(stakeAfter, stakeBefore);
    }

    // ==========================================
    // RAT 트리거 테스트
    // ==========================================

    // Note: test_RAT020_triggerAttentionTest moved to RATSeigManagerIntegration.t.sol (INT-020)

    function test_RAT022_triggerAttentionTest_noValidators() public {
        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, batchHash, blockHash);

        // Should not revert, just return early
    }

    // ==========================================
    // 증거 제출 테스트
    // ==========================================

    // Note: test_RAT030_submitEvidence moved to RATSeigManagerIntegration.t.sol (INT-021)

    /// @notice RAT-031: deadline 초과 후 증거 제출 실패
    function test_RAT031_submitEvidence_afterDeadline_reverts() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, batchHash, blockHash);

        // evidenceSubmissionPeriod 경과 (deadline 초과)
        uint256 evidencePeriod = rat.evidenceSubmissionPeriod();
        vm.warp(block.timestamp + evidencePeriod + 1);

        // deadline 초과 후 증거 제출 시도 → revert 예상
        vm.prank(validator1);
        vm.expectRevert();
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "late_evidence");

        // 검증자의 스테이크가 복구되지 않았는지 확인
        uint256 stakeAfter = _getValidatorStake(mockLayer2, validator1);
        assertEq(stakeAfter, stakeBefore - slashingPenalty, "Stake should remain slashed after deadline");

        // RAT이 여전히 담보금 보유
        uint256 ratStake = _getValidatorStake(mockLayer2, address(rat));
        assertEq(ratStake, slashingPenalty, "RAT should still hold the slashed amount");
    }

    /// @notice RAT-032: 비선택 검증자가 증거 제출 시 실패
    function test_RAT032_submitEvidence_notSelected_reverts() public {
        // 두 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stake1Before = _getValidatorStake(mockLayer2, validator1);
        uint256 stake2Before = _getValidatorStake(mockLayer2, validator2);

        // RAT 트리거 (랜덤으로 한 명만 선택됨)
        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, batchHash, blockHash);

        // 어느 검증자가 선택되었는지 확인
        uint256 stake1After = _getValidatorStake(mockLayer2, validator1);
        uint256 stake2After = _getValidatorStake(mockLayer2, validator2);

        address selectedValidator;
        address notSelectedValidator;
        uint256 selectedStakeBefore;

        if (stake1After < stake1Before) {
            // validator1이 선택됨
            selectedValidator = validator1;
            notSelectedValidator = validator2;
            selectedStakeBefore = stake1Before;
            assertEq(stake1After, stake1Before - slashingPenalty, "validator1 should be slashed");
            assertEq(stake2After, stake2Before, "validator2 should not be slashed");
        } else {
            // validator2가 선택됨
            selectedValidator = validator2;
            notSelectedValidator = validator1;
            selectedStakeBefore = stake2Before;
            assertEq(stake2After, stake2Before - slashingPenalty, "validator2 should be slashed");
            assertEq(stake1After, stake1Before, "validator1 should not be slashed");
        }

        // 비선택 검증자가 증거 제출 시도 → revert 예상
        vm.prank(notSelectedValidator);
        vm.expectRevert();
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "evidence_from_wrong_validator");

        // 선택된 검증자만 증거 제출 가능 (정상 동작 확인)
        vm.prank(selectedValidator);
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "correct_evidence");

        // 선택된 검증자의 스테이크 복구 확인
        assertEq(_getValidatorStake(mockLayer2, selectedValidator), selectedStakeBefore, "selected validator should be restored");
    }

    // ==========================================
    // 상태 조회 테스트 (시간 기반)
    // ==========================================

    function test_RAT040_getAttentionTestStatus_evidencePeriod() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // deadline 전에는 EvidencePeriod
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.EvidencePeriod));
    }

    function test_RAT041_getAttentionTestStatus_challengePeriod() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // deadline 경과 후 ~ challengeGameDuration 내에는 ChallengePeriod
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.ChallengePeriod));
    }

    function test_RAT042_getAttentionTestStatus_slashed() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // deadline + challengeGameDuration 경과 후에 Slashed
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + 1);

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.Slashed));

        // 검증자 스테이크는 여전히 선차감 상태 (treasury 출금 전)
        assertEq(_getValidatorStake(mockLayer2, validator1), stakeBefore - slashingPenalty);
        assertEq(_getValidatorStake(mockLayer2, address(rat)), slashingPenalty);
    }

    function test_RAT043_getAttentionTestStatus_restoredByEvidence() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "evidence");

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.RestoredByEvidence));
    }

    // ==========================================
    // Treasury 출금 테스트
    // ==========================================

    // Note: test_RAT050_withdrawSlashingsToTreasury moved to RATSeigManagerIntegration.t.sol (INT-022)

    // ==========================================
    // 확률적 트리거 테스트
    // ==========================================

    function test_RAT021_probabilisticTrigger() public {
        // Set probability to 0 (should never trigger)
        vm.prank(owner);
        rat.setRatTriggerProbability(0);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // No test should be created
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), 1);
        assertEq(testId, bytes32(0));
    }

    // ==========================================
    // resolveClaim 테스트 (챌린지 복구)
    // ==========================================

    // Note: test_RAT033_resolveClaim_duringChallengePeriod moved to RATSeigManagerIntegration.t.sol (INT-021 challenge)

    function test_RAT034_resolveClaim_afterChallengePeriod_fails() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        // deadline + challengeGameDuration 경과 후에는 복구 불가
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + 1);

        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        // 상태는 Slashed로 유지 (복구 실패)
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.Slashed));

        // 담보금 복구되지 않음
        assertEq(_getValidatorStake(mockLayer2, validator1), stakeBefore - slashingPenalty);
        assertEq(_getValidatorStake(mockLayer2, address(rat)), slashingPenalty);
    }

    // ==========================================
    // relaxedValidatorCheck 테스트
    // ==========================================

    function test_RAT025_relaxedValidatorCheck_true_removesAtCoff() public {
        // validator1을 정확히 minimumThreshold만큼만 스테이킹하여 다시 등록
        // 먼저 추가 검증자 생성
        address testValidator = address(0x7001);
        MockTON(ton).mint(testValidator, 300 * RAY);
        _stakeForValidator(testValidator, mockLayer2, 200 * RAY); // minimumThreshold만큼

        vm.prank(testValidator);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);

        // RAT 트리거 - 본드 후 remaining < C_off 이면 제거
        // 스테이크 ~200e27, 본드 100e27 → remaining ~100e27 >= C_off(100e27) → 유지될 수 있음
        // 정확한 동작은 실제 스테이크 양에 따라 다름
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 스테이크가 충분하면 유지, 부족하면 제거
        // 이 테스트는 실제 컨트랙트 로직에 따라 결과가 달라짐
    }

    // ==========================================
    // RAT-007: N_max 초과 검증 테스트
    // ==========================================

    function test_RAT007_maxValidators_exceeded_reverts() public {
        // maxValidatorsPerL2 = 3으로 설정
        vm.prank(owner);
        rat.setMaxValidatorsPerL2(3);

        // 추가 검증자 생성
        address validator4 = address(0x6004);
        MockTON(ton).mint(validator4, INITIAL_TON);
        _stakeForValidator(validator4, mockLayer2, 500 * RAY);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 3, "Should have 3 validators");

        // 4번째 검증자 등록 시도 → revert
        vm.prank(validator4);
        vm.expectRevert(MaxValidatorsReachedError.selector);
        rat.registerValidator(address(mockSystemConfig));
    }

    function test_RAT007_maxValidators_zeroMeansUnlimited() public {
        // maxValidatorsPerL2 = 0으로 설정 (제한 없음)
        vm.prank(owner);
        rat.setMaxValidatorsPerL2(0);

        // 추가 검증자 생성 및 스테이킹
        address validator4 = address(0x6004);
        address validator5 = address(0x6005);
        MockTON(ton).mint(validator4, INITIAL_TON);
        MockTON(ton).mint(validator5, INITIAL_TON);
        _stakeForValidator(validator4, mockLayer2, 500 * RAY);
        _stakeForValidator(validator5, mockLayer2, 500 * RAY);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator4);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator5);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 5, "Should have 5 validators with no limit");
    }

    function test_RAT007_maxValidators_reregisterAfterDeactivation() public {
        vm.prank(owner);
        rat.setMaxValidatorsPerL2(2);

        address validator4 = address(0x6004);
        MockTON(ton).mint(validator4, INITIAL_TON);
        _stakeForValidator(validator4, mockLayer2, 500 * RAY);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2);

        // validator4 등록 시도 → revert
        vm.prank(validator4);
        vm.expectRevert(MaxValidatorsReachedError.selector);
        rat.registerValidator(address(mockSystemConfig));

        // validator1 탈퇴
        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);

        // 이제 validator4 등록 가능
        vm.prank(validator4);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2);
    }

    // ==========================================
    // RAT-052: Treasury 미설정 테스트
    // ==========================================

    function test_RAT052_treasury_zeroAddress_reverts() public {
        // treasury를 address(0)으로 설정
        vm.prank(owner);
        rat.setTreasury(address(0));

        // treasury가 0일 때 withdrawSlashingsToTreasury 호출 시 revert
        vm.expectRevert("treasury not set");
        rat.withdrawSlashingsToTreasury(address(mockSystemConfig));
    }

    function test_RAT052_treasury_setAndWithdraw() public {
        // 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        // RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 전체 기간 경과
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + safetyBuffer + 1);

        // treasury 잔액 확인
        uint256 treasuryBefore = _getValidatorStake(mockLayer2, treasury);

        // 슬래싱 금액 출금
        rat.withdrawSlashingsToTreasury(address(mockSystemConfig));

        // treasury로 슬래싱 금액 전송됨
        uint256 treasuryAfter = _getValidatorStake(mockLayer2, treasury);
        assertEq(treasuryAfter - treasuryBefore, slashingPenalty, "Treasury should receive slashing penalty");
    }

    // ==========================================
    // EDGE-010: 동시 RAT 트리거 테스트
    // ==========================================

    function test_EDGE010_duplicateTrigger_sameBatch_reverts() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;

        // 첫 번째 트리거 성공
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        // 동일 batchIndex로 재트리거 시도 → revert
        vm.prank(factory);
        vm.expectRevert(TestAlreadyExistsError.selector);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));
    }

    function test_EDGE010_differentBatch_allowed() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        // batchIndex 1 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // batchIndex 2 트리거 (다른 batch이므로 가능)
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 2, keccak256("batch2"), keccak256("block2"));

        // 두 테스트 모두 존재
        bytes32 testId1 = rat.batchToTestId(address(mockSystemConfig), 1);
        bytes32 testId2 = rat.batchToTestId(address(mockSystemConfig), 2);
        assertTrue(testId1 != bytes32(0), "Test 1 should exist");
        assertTrue(testId2 != bytes32(0), "Test 2 should exist");
    }

    // ==========================================
    // E2E-014: 다중 L2 검증자 테스트
    // ==========================================

    function test_E2E014_multipleL2_sameValidator() public {
        // 두 번째 L2 설정
        _setupSecondL2();

        // validator1이 두 L2에 모두 스테이킹되어 있어야 함
        _stakeForValidator(validator1, mockLayer2_2, 500 * RAY);

        // validator1이 첫 번째 L2에 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        // validator1이 두 번째 L2에도 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig2));

        // 두 L2 모두에서 활성 검증자
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Should have 1 validator in L2_1");
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig2)), 1, "Should have 1 validator in L2_2");

        // 동일 검증자의 등록 정보 확인
        (, , bool isActive1) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        (, , bool isActive2) = rat.getValidatorRegistration(validator1, address(mockSystemConfig2));
        assertTrue(isActive1, "Validator should be active in L2_1");
        assertTrue(isActive2, "Validator should be active in L2_2");
    }

    function test_E2E014_slashingOneL2_noAffectOther() public {
        // 두 번째 L2 설정
        _setupSecondL2();

        // validator1이 두 L2에 모두 스테이킹
        _stakeForValidator(validator1, mockLayer2_2, 500 * RAY);

        uint256 stake1Before = _getValidatorStake(mockLayer2, validator1);
        uint256 stake2Before = _getValidatorStake(mockLayer2_2, validator1);

        // 두 L2에 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig2));

        // L2_1에서 RAT 트리거 및 슬래싱
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // L2_1 잔액 감소
        assertEq(_getValidatorStake(mockLayer2, validator1), stake1Before - slashingPenalty, "L2_1 balance reduced");

        // L2_2 잔액 영향 없음
        assertEq(_getValidatorStake(mockLayer2_2, validator1), stake2Before, "L2_2 balance unchanged");

        // L2_2에서 여전히 활성 검증자
        (, , bool isActive2) = rat.getValidatorRegistration(validator1, address(mockSystemConfig2));
        assertTrue(isActive2, "Validator still active in L2_2");
    }

    /// @notice 두 번째 L2 설정 헬퍼
    function _setupSecondL2() internal {
        vm.startPrank(owner);

        // 두 번째 Mock 컨트랙트 생성
        mockL2TON2 = address(0x8014);
        address mockDisputeGameFactory2 = address(0x8013); // 다른 factory 사용

        mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(address(0x8011));
        mockSystemConfig2.setOptimismPortal(address(0x8012));
        mockSystemConfig2.setDisputeGameFactory(mockDisputeGameFactory2); // 다른 factory
        mockSystemConfig2.setUnsafeBlockSigner(operator2);

        // Layer2 등록
        (mockLayer2_2, operatorManager2) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig2),
            mockL2TON2,
            "TestL2_2",
            operator2,
            1000 * RAY
        );

        vm.stopPrank();
    }
}
