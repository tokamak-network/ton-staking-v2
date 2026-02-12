// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import {SimpleMockSystemConfig} from "../../../src/mocks/SimpleMockSystemConfig.sol";
import {RAT} from "../../../src/validator/RAT.sol";
import {RATProxy} from "../../../src/validator/RATProxy.sol";
import {Layer2Registry} from "../../../src/stake/Layer2Registry.sol";

// Shared Mock contracts
import {MockDAOCommitteeProxy, IDAOCommitteeProxy2} from "./V3TestMocks.sol";

/// @notice 테스트용 RAT - _verifyEvidenceWithType를 override하여 기본 검증만 수행
/// @dev Patricia Merkle Trie proof 없이 증거 제출 흐름 테스트 가능
contract TestRAT is RAT {
    function _verifyEvidenceWithType(
        address,
        bytes32,
        bytes32,
        uint8,
        bytes calldata evidenceData
    ) internal view override returns (bool) {
        return evidenceData.length > 0;
    }
}

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

/// @title V3TestBase
/// @notice V3 테스트의 공통 기반 컨트랙트
/// @dev 중복 코드 제거를 위해 공통 함수 및 변수 제공
///
/// 사용법:
/// 1. 이 컨트랙트를 상속: contract MyTest is V3TestBase
/// 2. setUp()에서 _v3TestSetup() 호출
/// 3. 필요시 추가 설정 수행
abstract contract V3TestBase is Test, DeployV3Full {
    // ==========================================
    // Core Contracts (캐스팅된 참조)
    // ==========================================
    SeigManagerV3_1 public seigManager;
    Layer2ManagerV3 public layer2Manager;
    L1BridgeRegistryV1_2 public l1BridgeRegistry;
    DepositManagerV3 public depositManager;
    Layer2Registry public layer2Registry;
    RAT public rat;

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
    // Mock Contracts (첫 번째 L2)
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig;
    address public mockL1Bridge;
    address public mockPortal;
    address public mockDisputeGameFactory;
    address public mockL2TON;
    address public mockLayer2;
    address public operatorManager;

    // ==========================================
    // Test Addresses
    // ==========================================
    address public admin;
    address public owner;
    address public operator1 = address(0x4001);

    // ==========================================
    // Constants
    // ==========================================
    uint256 internal constant RAY = 1e27;
    uint256 internal constant INITIAL_TON = 100_000 * 1e18;

    /// @notice Override to use separate admin address for TransparentUpgradeableProxy
    function _getProxyAdmin(address) internal view override returns (address) {
        return admin;
    }

    /// @notice 기본 V3 테스트 환경 설정
    /// @dev setUp()에서 호출하여 전체 시스템 배포
    function _v3TestSetup() internal {
        admin = address(0x9999);
        owner = address(this);
        proxyAdmin = admin;

        vm.startPrank(owner);

        // 기본 인프라 배포
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

        // V3 셀렉터 등록
        _setupSeigManagerV3AllTestSelectors();

        // 크로스 레퍼런스 설정
        _setupCrossReferences(owner);

        // 컨트랙트 참조 저장
        seigManager = SeigManagerV3_1(seigManagerProxy);
        layer2Manager = Layer2ManagerV3(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);
        depositManager = DepositManagerV3(depositManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);
        rat = RAT(payable(ratProxy));

        // 롤업 타입 등록 (TYPE 1, 2, 3)
        _registerDefaultRollupTypes();

        // 기본 설정
        SeigManagerV1_2(seigManagerProxy).setMinimumAmount(100e27);
        SeigManagerV1_2(seigManagerProxy).addPauser(owner);

        // Mock 컨트랙트 생성
        _setupMockContracts();

        vm.stopPrank();
    }

    /// @notice 기본 롤업 타입 등록 (TYPE 1, 2, 3)
    function _registerDefaultRollupTypes() internal {
        // Ensure owner has Manager role
        if (!l1BridgeRegistry.isManager(owner)) {
            l1BridgeRegistry.addManager(owner);
        }

        // TYPE 1: Optimism Legacy (Titan 등) - V2 mode only
        // Bridge & TVL both use l1StandardBridge(), no DisputeGameFactory
        l1BridgeRegistry.addRollupType(
            1,                                          // type
            "Optimism Legacy",                          // name
            bytes4(keccak256("l1StandardBridge()")),   // bridgeContractGetter (0x078f29cf)
            bytes4(keccak256("l1StandardBridge()")),   // tvlContractGetter (0x078f29cf)
            bytes4(0),                                  // disputeGameFactoryGetter (none)
            bytes4(0),                                  // seigNotifierGetter (none)
            0,                                          // BRIDGE_PATTERN_ERC20
            false                                       // V3 eligible = false (V2 only)
        );

        // TYPE 2: Optimism Bedrock (Thanos 등) - V2 mode only
        // Bridge uses l1StandardBridge(), TVL uses optimismPortal(), no DisputeGameFactory
        l1BridgeRegistry.addRollupType(
            2,
            "Optimism Bedrock",
            bytes4(keccak256("l1StandardBridge()")),   // bridgeContractGetter (0x078f29cf)
            bytes4(keccak256("optimismPortal()")),     // tvlContractGetter (0x0a49cb03)
            bytes4(0),                                  // disputeGameFactoryGetter (none)
            bytes4(0),                                  // seigNotifierGetter (none)
            1,                                          // BRIDGE_PATTERN_NATIVE
            false                                       // V3 eligible = false (V2 only)
        );

        // TYPE 3: Bedrock with DisputeGame - V3 eligible
        // Bridge uses l1StandardBridge(), TVL uses optimismPortal(), has DisputeGameFactory
        l1BridgeRegistry.addRollupType(
            3,
            "Optimism Bedrock DisputeGame",
            bytes4(keccak256("l1StandardBridge()")),       // bridgeContractGetter (0x078f29cf)
            bytes4(keccak256("optimismPortal()")),         // tvlContractGetter (0x0a49cb03)
            bytes4(keccak256("disputeGameFactory()")),     // disputeGameFactoryGetter (0x0a1e5c7d)
            bytes4(keccak256("optimismPortal()")),         // seigNotifierGetter (0x0a49cb03)
            1,                                              // BRIDGE_PATTERN_NATIVE
            true                                            // V3 eligible = true
        );
    }

    /// @notice Mock 컨트랙트 생성 (첫 번째 L2용)
    function _setupMockContracts() internal virtual {
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

    /// @notice DAO 컨트랙트 배포
    function _deployDAO() internal virtual {
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

    /// @notice Layer2 등록 (SystemConfig 기반)
    /// @param systemConfig SystemConfig 주소
    /// @param l2TON L2 TON 주소
    /// @param name L2 이름
    /// @param operator 오퍼레이터 주소
    /// @param operatorDeposit 오퍼레이터 담보금
    /// @return layer2 등록된 Layer2 주소
    /// @return operatorMgr 오퍼레이터 매니저 주소
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

    /// @notice 크로스 레퍼런스 설정
    function _setupCrossReferences(address) internal virtual override {
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        SeigManagerV1_2(seigManagerProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);
        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);
        // V1.1: RAT에도 ValidatorReward 설정 (O(1) 보상 분배용)
        RAT(payable(ratProxy)).setValidatorReward(validatorPoolProxy);

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

    // ==========================================
    // Helper Functions
    // ==========================================

    /// @notice 검증자 등록 헬퍼
    /// @param validator 검증자 주소
    /// @param depositAmount 예치 금액 (RAY 단위)
    function _registerValidator(address validator, uint256 depositAmount) internal {
        vm.startPrank(validator);
        MockWTON(wton).mint(validator, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, validator, depositAmount);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();
    }

    /// @notice 예치만 수행 (검증자 등록 없이)
    /// @param account 계정 주소
    /// @param depositAmount 예치 금액 (RAY 단위)
    function _depositOnly(address account, uint256 depositAmount) internal {
        vm.startPrank(account);
        MockWTON(wton).mint(account, depositAmount);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, account, depositAmount);
        vm.stopPrank();
    }

    /// @notice 검증자 스테이킹 헬퍼
    /// @param validator 검증자 주소
    /// @param layer2 Layer2 주소
    /// @param amount 스테이킹 금액 (RAY 단위)
    function _stakeForValidator(address validator, address layer2, uint256 amount) internal {
        vm.startPrank(validator);
        MockWTON(wton).mint(validator, amount);
        MockWTON(wton).approve(depositManagerProxy, amount);
        depositManager.deposit(layer2, validator, amount);
        vm.stopPrank();
    }

    /// @notice Coinage 잔액 조회 헬퍼
    /// @param layer2 Layer2 주소
    /// @param account 계정 주소
    /// @return 스테이킹 잔액
    function _getCoinageBalance(address layer2, address account) internal view returns (uint256) {
        return SeigManagerV1_2(seigManagerProxy).stakeOf(layer2, account);
    }

    /// @notice 검증자 스테이크 조회 헬퍼 (alias)
    function _getValidatorStake(address layer2, address validator) internal view returns (uint256) {
        return _getCoinageBalance(layer2, validator);
    }

    /// @notice 첫 번째 L2 등록 (기본 Mock 사용)
    /// @param operatorDeposit 오퍼레이터 담보금
    function _registerFirstL2(uint256 operatorDeposit) internal {
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            operatorDeposit
        );
    }

    /// @notice RAT 기본 파라미터 설정
    function _setupRATParams() internal {
        rat.setSlashingPenalty(100 * RAY);
        rat.setValidatorBuffer(100 * RAY);
        rat.setMinimumThreshold(200 * RAY);
        rat.setRatTriggerProbability(RAY); // 100% for testing
    }

    /// @notice V3 기본 파라미터 설정 및 마이그레이션
    function _setupV3AndMigrate() internal {
        seigManager.setRatContract(address(rat));

        // 테스트 환경을 위한 seigniorage 시작 블록 및 초기 공급량 설정
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(block.number);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50000000e27);

        // V3 파라미터 설정 및 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();
    }
}
