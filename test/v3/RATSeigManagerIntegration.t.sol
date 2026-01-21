// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../script/DeployV3Full.s.sol";
import {SimpleMockSystemConfig} from "../../src/mocks/SimpleMockSystemConfig.sol";
import {RAT} from "../../src/validator/RAT.sol";
import {Layer2Registry} from "../../src/stake/Layer2Registry.sol";
import {RefactorCoinageSnapshotI} from "../../src/stake/interfaces/RefactorCoinageSnapshotI.sol";

// DAO Contracts
import {DAOCommitteeProxy2} from "../../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../../src/dao/DAOCommitteeOwner.sol";
import {Candidate} from "../../src/dao/Candidate.sol";
import {CandidateAddOnV1_1} from "../../src/dao/CandidateAddOnV1_1.sol";
import {CandidateFactory} from "../../src/dao/factory/CandidateFactory.sol";
import {CandidateFactoryProxy} from "../../src/dao/factory/CandidateFactoryProxy.sol";
import {CandidateAddOnFactory} from "../../src/dao/factory/CandidateAddOnFactory.sol";
import {CandidateAddOnFactoryProxy} from "../../src/dao/factory/CandidateAddOnFactoryProxy.sol";

// Storage and AccessControl for MockDAOCommitteeProxy
import {StorageStateCommittee} from "../../src/dao/StorageStateCommittee.sol";
import {AccessControl} from "../../src/accessControl/AccessControl.sol";

/// @title MockDAOCommitteeProxyForRAT
/// @notice Mock DAO Proxy for RAT Integration Testing
contract MockDAOCommitteeProxyForRAT is StorageStateCommittee, AccessControl {
    address internal _implementation;
    bool public pauseProxy;

    event Upgraded(address indexed implementation);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _;
    }

    constructor(address _ton) {
        ton = _ton;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function upgradeTo(address impl) external onlyAdmin {
        require(impl != address(0), "zero address");
        _implementation = impl;
        emit Upgraded(impl);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    fallback() external payable {
        address _impl = _implementation;
        require(_impl != address(0) && !pauseProxy, "proxy disabled");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

interface IDAOCommitteeProxy2ForRAT {
    function upgradeTo2(address impl) external;
    function setAliveImplementation2(address impl, bool alive) external;
    function setSelectorImplementations2(bytes4[] calldata selectors, address impl) external;
}

/// @title RATSeigManagerIntegrationTest
/// @notice RAT ↔ SeigManager 실제 Coinage 전송 통합 테스트
/// @dev 테스트 계획서 INT-020~023, SM-040~043 구현
///
/// 테스트 대상:
/// - INT-020: Coinage 선차감 (validator → RAT 전송)
/// - INT-021: Coinage 복구 (RAT → validator 전송)
/// - INT-022: Coinage 슬래싱 (RAT → Treasury 전송)
/// - INT-023: 잔액 동기화 검증
/// - SM-040: transferCoinageToRAT()
/// - SM-041: transferCoinageFromRAT()
/// - SM-042: transferCoinageFromRATTo()
/// - SM-043: onlyRAT 권한 검증
contract RATSeigManagerIntegrationTest is Test, DeployV3Full {
    // ==========================================
    // Contracts
    // ==========================================
    SeigManagerV1_4 public seigManager;
    Layer2ManagerV1_2 public layer2Manager;
    L1BridgeRegistryV1_2 public l1BridgeRegistry;
    DepositManager public depositManager;
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
    address public treasury = address(0x9001);

    uint256 constant RAY = 1e27;
    uint256 constant INITIAL_TON = 100_000 * 1e18;

    function setUp() public {
        admin = address(0x9999);
        owner = address(this);

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

        RATProxy(payable(ratProxy)).changeAdmin(admin);
        ValidatorRewardProxy(payable(validatorPoolProxy)).changeAdmin(admin);

        _configureV3Contracts(owner);
        _setupCrossReferences(owner);

        // 컨트랙트 참조
        seigManager = SeigManagerV1_4(seigManagerProxy);
        layer2Manager = Layer2ManagerV1_2(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);
        depositManager = DepositManager(depositManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);
        rat = RAT(ratProxy);

        // minimumAmount를 0으로 설정
        SeigManagerV1_2(seigManagerProxy).setMinimumAmount(0);

        // RAT 파라미터 조정
        rat.setSlashingPenalty(100 * RAY);     // C_off = 100 WTON
        rat.setValidatorBuffer(100 * RAY);      // Δ_validator = 100 WTON
        rat.setMinimumThreshold(200 * RAY);     // D_min = 200 WTON
        rat.setRatTriggerProbability(RAY);      // 100% 트리거
        rat.setTreasury(treasury);

        // Mock 컨트랙트 생성
        _setupMockContracts();

        // Layer2 등록
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY
        );

        // SeigManager에 RAT 컨트랙트 주소 설정
        // Register setRATContract selector to V1_4 implementation
        bytes4[] memory ratSelectors = new bytes4[](4);
        ratSelectors[0] = SeigManagerV1_4.setRATContract.selector;
        ratSelectors[1] = SeigManagerV1_4.transferCoinageToRAT.selector;
        ratSelectors[2] = SeigManagerV1_4.transferCoinageFromRAT.selector;
        ratSelectors[3] = SeigManagerV1_4.transferCoinageFromRATTo.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(ratSelectors, seigManagerImpl);

        seigManager.setRATContract(address(rat));

        // 테스트 계정에 TON 지급
        MockTON(ton).mint(validator1, INITIAL_TON);
        MockTON(ton).mint(validator2, INITIAL_TON);

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
        MockDAOCommitteeProxyForRAT mockProxy = new MockDAOCommitteeProxyForRAT(ton);
        daoCommitteeProxy = address(mockProxy);

        daoCommitteeProxy2 = address(new DAOCommitteeProxy2());
        daoCommitteeV1 = address(new DAOCommittee_V1());
        daoCommitteeOwner = address(new DAOCommitteeOwner());

        mockProxy.upgradeTo(daoCommitteeProxy2);
        IDAOCommitteeProxy2ForRAT(daoCommitteeProxy).upgradeTo2(daoCommitteeV1);
        IDAOCommitteeProxy2ForRAT(daoCommitteeProxy).setAliveImplementation2(daoCommitteeOwner, true);

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

        IDAOCommitteeProxy2ForRAT(daoCommitteeProxy).setSelectorImplementations2(ownerSelectors, daoCommitteeOwner);

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

        Layer2ManagerV1_1(layer2ManagerProxy).registerCandidateAddOn(
            systemConfig,
            operatorDeposit,
            false,
            name
        );
        vm.stopPrank();

        layer2 = Layer2ManagerV1_2(layer2ManagerProxy).getLayer2BySystemConfig(systemConfig);
        operatorMgr = Layer2ManagerV1_1(layer2ManagerProxy).operatorOfRollupConfig(systemConfig);
    }

    function _setupCrossReferences(address deployer) internal override {
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        SeigManagerV1_4(seigManagerProxy).setValidatorReward(validatorPoolProxy);

        Layer2ManagerV1_1(layer2ManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton,
            daoCommitteeProxy,
            depositManagerProxy,
            seigManagerProxy,
            address(0)
        );

        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(layer2ManagerImpl, true);

        bytes4[] memory l2mV1_2Selectors = new bytes4[](3);
        l2mV1_2Selectors[0] = Layer2ManagerV1_2.getBridgedTONByLayer.selector;
        l2mV1_2Selectors[1] = Layer2ManagerV1_2.getBridgedTON.selector;
        l2mV1_2Selectors[2] = Layer2ManagerV1_2.getLayer2BySystemConfig.selector;
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(l2mV1_2Selectors, layer2ManagerImpl);

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

        DepositManagerV1_1(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    /// @notice 검증자 등록 헬퍼
    function _registerValidator(address validator, uint256 depositAmount) internal {
        vm.startPrank(validator);
        MockWTON(wton).mint(validator, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator, depositAmount);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();
    }

    /// @notice Coinage 잔액 조회 헬퍼
    function _getCoinageBalance(address layer2, address account) internal view returns (uint256) {
        return SeigManagerV1_2(seigManagerProxy).stakeOf(layer2, account);
    }

    // ==========================================
    // INT-020: Coinage 선차감 테스트 (validator → RAT)
    // ==========================================

    /// @notice INT-020: triggerAttentionTest 호출 시 validator → RAT coinage 전송 검증
    function test_INT020_coinagePreDeduction() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 초기 잔액 확인
        uint256 validatorBalanceBefore = _getCoinageBalance(mockLayer2, validator1);
        uint256 ratBalanceBefore = _getCoinageBalance(mockLayer2, address(rat));

        assertEq(validatorBalanceBefore, depositAmount, "Initial validator balance");
        assertEq(ratBalanceBefore, 0, "Initial RAT balance");

        // RAT 트리거 (DisputeGameFactory에서 호출)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234), // game address
            address(mockSystemConfig),
            1, // batchIndex
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후 잔액 확인
        uint256 validatorBalanceAfter = _getCoinageBalance(mockLayer2, validator1);
        uint256 ratBalanceAfter = _getCoinageBalance(mockLayer2, address(rat));
        uint256 slashingPenalty = rat.slashingPenalty();

        assertEq(validatorBalanceAfter, depositAmount - slashingPenalty, "Validator balance after pre-deduction");
        assertEq(ratBalanceAfter, slashingPenalty, "RAT balance after pre-deduction");
    }

    // ==========================================
    // INT-021: Coinage 복구 테스트 (RAT → validator)
    // ==========================================

    /// @notice INT-021: submitEvidence 호출 시 RAT → validator coinage 복구 검증
    function test_INT021_coinageRestoration() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 확인
        uint256 slashingPenalty = rat.slashingPenalty();
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount - slashingPenalty, "After pre-deduction");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), slashingPenalty, "RAT holds penalty");

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(address(mockSystemConfig), 1, "evidence_data");

        // 복구 후 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount, "Validator balance restored");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
    }

    /// @notice INT-021: resolveClaim 호출 시 RAT → validator coinage 복구 검증 (챌린지 승리)
    function test_INT021_coinageRestorationByChallenge() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        address gameAddress = address(0x1234);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            gameAddress,
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 확인
        uint256 slashingPenalty = rat.slashingPenalty();
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount - slashingPenalty, "After pre-deduction");

        // deadline 경과 후 ChallengePeriod로 진입
        vm.warp(block.timestamp + rat.evidenceSubmissionPeriod() + 1);

        // 챌린지 승리로 복구 (game 주소에서 호출)
        vm.prank(gameAddress);
        rat.resolveClaim(validator1);

        // 복구 후 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount, "Validator balance restored by challenge");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
    }

    // ==========================================
    // INT-022: Coinage 슬래싱 테스트 (RAT → Treasury)
    // ==========================================

    /// @notice INT-022: withdrawSlashingsToTreasury 호출 시 RAT → Treasury coinage 전송 검증
    function test_INT022_coinageSlashing() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        uint256 slashingPenalty = rat.slashingPenalty();

        // 선차감 확인
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), slashingPenalty, "RAT holds penalty");

        // 전체 대기 시간 경과 (evidenceSubmissionPeriod + challengeGameDuration + safetyBuffer)
        vm.warp(block.timestamp + rat.evidenceSubmissionPeriod() + rat.challengeGameDuration() + rat.safetyBuffer() + 1);

        // Treasury로 출금
        rat.withdrawSlashingsToTreasury(address(mockSystemConfig));

        // 슬래싱 후 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
        assertEq(_getCoinageBalance(mockLayer2, treasury), slashingPenalty, "Treasury received slashing");
    }

    // ==========================================
    // INT-023: 잔액 동기화 검증
    // ==========================================

    /// @notice INT-023: 전체 플로우에서 잔액 동기화 검증
    function test_INT023_balanceSynchronization() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);
        _registerValidator(validator2, depositAmount);

        uint256 slashingPenalty = rat.slashingPenalty();

        // 초기 상태: 총 잔액 = validator1 + validator2 + operator
        uint256 totalBefore = _getCoinageBalance(mockLayer2, validator1)
            + _getCoinageBalance(mockLayer2, validator2)
            + _getCoinageBalance(mockLayer2, address(rat));

        // RAT 트리거 for validator1
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후: 총 잔액 유지 (validator → RAT 이동)
        uint256 totalAfterTrigger = _getCoinageBalance(mockLayer2, validator1)
            + _getCoinageBalance(mockLayer2, validator2)
            + _getCoinageBalance(mockLayer2, address(rat));

        assertEq(totalAfterTrigger, totalBefore, "Total balance preserved after trigger");

        // 증거 제출 후: 총 잔액 유지 (RAT → validator 복구)
        // Note: RAT selects validator2 based on registration order, so validator2 must submit evidence
        vm.prank(validator2);
        rat.submitEvidence(address(mockSystemConfig), 1, "evidence_data");

        uint256 totalAfterEvidence = _getCoinageBalance(mockLayer2, validator1)
            + _getCoinageBalance(mockLayer2, validator2)
            + _getCoinageBalance(mockLayer2, address(rat));

        assertEq(totalAfterEvidence, totalBefore, "Total balance preserved after evidence");
    }

    // ==========================================
    // SM-040: transferCoinageToRAT 테스트
    // ==========================================

    /// @notice SM-040: transferCoinageToRAT 함수 테스트
    function test_SM040_transferCoinageToRAT() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 transferAmount = 100 * RAY;

        // RAT에서 직접 호출 시뮬레이션 (RAT 컨트랙트로 가장)
        vm.prank(address(rat));
        seigManager.transferCoinageToRAT(mockLayer2, validator1, transferAmount);

        // 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount - transferAmount, "Validator balance reduced");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), transferAmount, "RAT balance increased");
    }

    // ==========================================
    // SM-041: transferCoinageFromRAT 테스트
    // ==========================================

    /// @notice SM-041: transferCoinageFromRAT 함수 테스트
    function test_SM041_transferCoinageFromRAT() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 transferAmount = 100 * RAY;

        // 먼저 RAT로 전송
        vm.prank(address(rat));
        seigManager.transferCoinageToRAT(mockLayer2, validator1, transferAmount);

        assertEq(_getCoinageBalance(mockLayer2, address(rat)), transferAmount, "RAT has balance");

        // RAT에서 validator로 복구
        vm.prank(address(rat));
        seigManager.transferCoinageFromRAT(mockLayer2, validator1, transferAmount);

        // 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount, "Validator balance restored");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
    }

    // ==========================================
    // SM-042: transferCoinageFromRATTo 테스트
    // ==========================================

    /// @notice SM-042: transferCoinageFromRATTo 함수 테스트
    function test_SM042_transferCoinageFromRATTo() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 transferAmount = 100 * RAY;

        // 먼저 RAT로 전송
        vm.prank(address(rat));
        seigManager.transferCoinageToRAT(mockLayer2, validator1, transferAmount);

        // RAT에서 treasury로 전송
        vm.prank(address(rat));
        seigManager.transferCoinageFromRATTo(mockLayer2, treasury, transferAmount);

        // 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
        assertEq(_getCoinageBalance(mockLayer2, treasury), transferAmount, "Treasury received");
    }

    // ==========================================
    // SM-043: onlyRAT 권한 검증
    // ==========================================

    /// @notice SM-043: onlyRAT 권한 없이 호출 시 revert
    function test_SM043_onlyRAT_revert() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 일반 사용자가 호출 시 revert
        vm.prank(validator1);
        vm.expectRevert("only RAT");
        seigManager.transferCoinageToRAT(mockLayer2, validator1, 100 * RAY);

        vm.prank(validator1);
        vm.expectRevert("only RAT");
        seigManager.transferCoinageFromRAT(mockLayer2, validator1, 100 * RAY);

        vm.prank(validator1);
        vm.expectRevert("only RAT");
        seigManager.transferCoinageFromRATTo(mockLayer2, treasury, 100 * RAY);

        // owner가 호출 시에도 revert
        vm.prank(owner);
        vm.expectRevert("only RAT");
        seigManager.transferCoinageToRAT(mockLayer2, validator1, 100 * RAY);
    }

    // ==========================================
    // 추가: 다중 RAT 트리거 시나리오
    // ==========================================

    /// @notice 다중 검증자, 다중 RAT 트리거 시 잔액 일관성 검증
    function test_multipleRATTriggers_balanceConsistency() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);
        _registerValidator(validator2, depositAmount);

        // 첫 번째 RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 두 번째 RAT 트리거 (다른 batchIndex)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x5678),
            address(mockSystemConfig),
            2,
            keccak256("batch2"),
            keccak256("block2")
        );

        // RAT 잔액은 선차감된 금액들의 합
        uint256 ratBalance = _getCoinageBalance(mockLayer2, address(rat));
        uint256 slashingPenalty = rat.slashingPenalty();

        // 두 번 트리거되었으므로 최대 2 * slashingPenalty까지 가능
        // (단, 동일 검증자가 선택될 수도 있음)
        assertTrue(ratBalance <= 2 * slashingPenalty, "RAT balance within expected range");
        assertTrue(ratBalance >= slashingPenalty, "RAT balance at least one penalty");
    }

    // ==========================================
    // 추가: 담보금 부족 시나리오
    // ==========================================

    /// @notice 담보금 부족 시 RAT 트리거 동작 검증
    function test_insufficientCollateral_RATTrigger() public {
        // D_min = 200 WTON, slashingPenalty = 100 WTON
        // 정확히 D_min만 예치 (200 WTON)
        uint256 depositAmount = 200 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후: 200 - 100 = 100 WTON (D_min 미만)
        // relaxedValidatorCheck = true (기본값)이므로 C_off(100) 기준
        // remaining = 100 >= C_off(100), 검증자 유지

        // 잔액 확인
        uint256 slashingPenalty = rat.slashingPenalty();
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount - slashingPenalty, "Validator balance reduced");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), slashingPenalty, "RAT holds penalty");

        // 검증자 상태 확인 (여전히 활성 - relaxed 모드이므로)
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator should still be active in relaxed mode");
    }
}
