// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import {SimpleMockSystemConfig} from "../../../src/mocks/SimpleMockSystemConfig.sol";
import {ICandidate} from "../../../src/dao/interfaces/ICandidate.sol";
import {ILayer2} from "../../../src/dao/interfaces/ILayer2.sol";
import {Layer2I} from "../../../src/dao/interfaces/Layer2I.sol";
import {IValidatorReward} from "../../../src/validator/IValidatorReward.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

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

/// @title V2ModeTestBase
/// @notice V2 모드 테스트를 위한 공통 베이스 컨트랙트
/// @dev V2Functions.t.sol과 V2V3ModeSwitching.t.sol에서 상속하여 사용
///      공통 기능:
///      - 전체 시스템 배포 (토큰, 매니저, DAO 등)
///      - Mock Optimism 인프라 설정
///      - Layer2 등록 헬퍼 함수
///      - 시뇨리지 분배 헬퍼 함수
abstract contract V2ModeTestBase is Test, DeployV3Full {
    // ==========================================
    // 주요 컨트랙트 참조
    // ==========================================
    SeigManagerV3_1 public seigManager;
    DepositManagerV3 public depositManager;
    Layer2Registry public layer2Registry;
    Layer2ManagerV3 public layer2Manager;
    L1BridgeRegistryV1_2 public l1BridgeRegistry;

    // ==========================================
    // 테스트용 Layer2 및 인프라
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig;
    address public mockLayer2;  // Layer2Manager에서 생성된 CandidateAddOn 주소
    address public mockBridge;
    address public mockPortal;
    address public mockDisputeGameFactory;
    address public mockL2TON;
    address public operatorManager;

    // ==========================================
    // DAO 관련 변수
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
    // 테스트 계정
    // ==========================================
    address public admin;
    address public owner;
    address public operator1 = address(0x1001);
    address public user1 = address(0x2001);
    address public validator1 = address(0x3001);

    // ==========================================
    // 상수
    // ==========================================
    uint256 constant RAY = 1e27;
    uint256 constant WTON_UNIT = 1e27;
    uint256 constant TON_UNIT = 1e18;
    uint256 constant INITIAL_WTON = 10000 * RAY;
    uint256 constant BRIDGED_TON_AMOUNT = 10000 * 1e18; // 브릿지에 예치할 TON 양

    // ==========================================
    // Custom Errors
    // ==========================================
    error NotMigratedError();
    error AlreadyMigratedError();

    // ==========================================
    // Proxy Admin Override
    // ==========================================

    /// @notice Override to use separate admin address for TransparentUpgradeableProxy
    /// @dev This prevents "admin cannot fallback to proxy target" error in tests
    function _getProxyAdmin(address) internal view override returns (address) {
        return admin; // Use admin (0x9999) instead of deployer
    }

    // ==========================================
    // Setup Functions
    // ==========================================

    /// @notice 기본 setUp - 전체 시스템 배포
    function _baseSetUp() internal {
        admin = address(0x9999);
        owner = address(this);
        proxyAdmin = admin; // Set proxyAdmin before deployment

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

        // DAO 배포 (Layer2Manager.setAddresses에 필요)
        _deployDAO();

        _deployV3Contracts(owner);

        // Register all V3 selectors for test functionality
        _setupSeigManagerV3AllTestSelectors();

        // Register V2 view selectors (estimatedDistributeV2, claimableL2SeigniorageV2)
        _setupSeigManagerV2ViewSelectors();

        _setupCrossReferences(owner);

        // 컨트랙트 참조
        seigManager = SeigManagerV3_1(seigManagerProxy);
        depositManager = DepositManagerV3(depositManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);
        layer2Manager = Layer2ManagerV3(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);

        // 롤업 타입 등록 (TYPE 1, 2, 3)
        _registerDefaultRollupTypes();

        // Mock Optimism 인프라 배포
        _setupMockSystemConfig();

        // minimumAmount 설정 (V2 operator 최소 스테이킹 요구사항: 100 WTON)
        SeigManagerV1_2(seigManagerProxy).setMinimumAmount(100e27);

        // 테스트용 시뇨리지 파라미터 설정
        vm.roll(10);
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(1);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50_000_000 * RAY);
        SeigManagerV1_2(seigManagerProxy).setBurntAmountAtDAO(1);

        // 사용자에게 WTON 지급
        MockWTON(wton).mint(user1, INITIAL_WTON);
        MockWTON(wton).mint(operator1, INITIAL_WTON);
        MockWTON(wton).mint(validator1, INITIAL_WTON);

        vm.stopPrank();

        // V2 모드 확인 (v3Migrated = false)
        assertFalse(seigManager.v3Migrated(), "Should start in V2 mode");
    }

    /// @notice V2 view function selectors 등록
    /// @dev estimatedDistributeV2, claimableL2SeigniorageV2 등 V2 전용 view 함수
    function _setupSeigManagerV2ViewSelectors() internal {
        bytes4[] memory v2Views = new bytes4[](2);
        v2Views[0] = SeigManagerV3_2.estimatedDistributeV2.selector;
        v2Views[1] = SeigManagerV3_2.claimableL2SeigniorageV2.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(v2Views, seigManagerV3_2Impl);
    }

    /// @notice Cross References 설정 (DeployV3Full override - DAO 설정 추가)
    function _setupCrossReferences(address) internal override {
        // SeigManager -> Layer2Manager
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);

        // SeigManager -> L1BridgeRegistry (V2 seigniorage에 필요)
        SeigManagerV1_2(seigManagerProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);

        // SeigManager -> ValidatorReward
        SeigManagerV3_1(seigManagerProxy).setValidatorReward(validatorPoolProxy);

        // V1.1: RAT에도 ValidatorReward 설정 (O(1) 보상 분배용)
        RAT(payable(ratProxy)).setValidatorReward(validatorPoolProxy);

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
            address(0) // swapProxy
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

        // DepositManager V3 단일 구현체
        DepositManagerV3(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );

        // DAO 설정
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(candidateFactoryProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(candidateAddOnFactoryProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setSeigManager(seigManagerProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(layer2ManagerProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Registry(layer2RegistryProxy);

        // Layer2Registry에 DAO MINTER_ROLE 부여
        Layer2Registry(layer2RegistryProxy).addMinter(daoCommitteeProxy);
    }

    /// @notice DAO 컨트랙트 배포
    function _deployDAO() internal {
        // 1. Deploy MockDAOCommitteeProxy
        MockDAOCommitteeProxy mockProxy = new MockDAOCommitteeProxy(ton);
        daoCommitteeProxy = address(mockProxy);

        // 2. Deploy DAO implementations
        daoCommitteeProxy2 = address(new DAOCommitteeProxy2());
        daoCommitteeV1 = address(new DAOCommittee_V1());
        daoCommitteeOwner = address(new DAOCommitteeOwner());

        // 3. Setup proxy routing
        mockProxy.upgradeTo(daoCommitteeProxy2);
        IDAOCommitteeProxy2(daoCommitteeProxy).upgradeTo2(daoCommitteeV1);

        // 4. Setup DAOCommitteeOwner selector routing
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
    }

    // ==========================================
    // Mock Infrastructure Setup
    // ==========================================

    /// @notice Mock Optimism SystemConfig 설정
    function _setupMockSystemConfig() internal {
        // Mock 주소 생성
        mockBridge = address(0x8001);
        mockPortal = address(0x8002);
        mockDisputeGameFactory = address(0x8003);
        mockL2TON = address(0x8004);

        // SimpleMockSystemConfig 배포 및 설정
        mockSystemConfig = new SimpleMockSystemConfig();
        mockSystemConfig.setL1StandardBridge(mockBridge);
        mockSystemConfig.setOptimismPortal(mockPortal);
        mockSystemConfig.setDisputeGameFactory(mockDisputeGameFactory);
        mockSystemConfig.setUnsafeBlockSigner(operator1); // operator1이 시퀀서
    }

    /// @notice Portal에 TON 전송하여 브릿지된 TON 시뮬레이션
    /// @dev L1BridgeRegistry.layer2TVL()에서 IERC20(ton).balanceOf(portal) 조회
    function _depositTONToPortal(uint256 amount) internal {
        vm.prank(owner);
        MockTON(ton).mint(mockPortal, amount);
    }

    // ==========================================
    // Layer2 Registration Helpers
    // ==========================================

    /// @notice Layer2 등록 (L1BridgeRegistry + Layer2Manager)
    /// @dev 실제 등록 흐름:
    ///      1. L1BridgeRegistry에 rollupConfig(SystemConfig) 등록
    ///      2. Portal에 TON 전송 (브릿지된 TON)
    ///      3. Layer2Manager에 registerCandidateAddOn 호출
    ///      4. mockLayer2 주소 저장
    function _registerMockLayer2() internal {
        // V3 모드에서는 requiredStake가 더 높으므로 충분한 deposit 필요
        // V2: minimumAmount(100 RAY), V3: max(D_sequencer, θ×B_i) ≈ 250+ RAY
        uint256 operatorDeposit = seigManager.v3Migrated()
            ? 1000 * RAY  // V3 모드: requiredStake 충족을 위해 충분한 금액
            : 100 * RAY + 1e10; // V2 모드: minimumAmount + buffer

        vm.startPrank(owner);

        // 1. L1BridgeRegistry에 rollupConfig 등록 (TYPE 3: bedrock with nativeTON + validator)
        if (!l1BridgeRegistry.isManager(owner)) {
            l1BridgeRegistry.addManager(owner);
        }
        if (!l1BridgeRegistry.isRegistrant(owner)) {
            l1BridgeRegistry.addRegistrant(owner);
        }

        // registerRollupConfig에서 Portal을 자동으로 등록함 (L1BridgeRegistryV1_2.sol:517-519)
        l1BridgeRegistry.registerRollupConfig(
            address(mockSystemConfig),
            3, // TYPE_3: bedrock with nativeTON + validator (V3 eligibility 적용)
            mockL2TON,
            "TestL2"
        );

        // 2. Portal에 TON 전송 (브릿지된 TON 시뮬레이션)
        MockTON(ton).mint(mockPortal, BRIDGED_TON_AMOUNT);

        vm.stopPrank();

        // 3. operator1이 Layer2Manager에 등록
        vm.startPrank(operator1);
        MockWTON(wton).approve(layer2ManagerProxy, operatorDeposit);

        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            address(mockSystemConfig),
            operatorDeposit,
            false, // WTON
            "TestL2"
        );
        vm.stopPrank();

        // 4. 생성된 Layer2 주소 가져오기
        mockLayer2 = Layer2ManagerV3(layer2ManagerProxy).getLayer2BySystemConfig(address(mockSystemConfig));
        operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(address(mockSystemConfig));
    }

    /// @notice Layer2 등록 (operator 스테이킹 포함)
    /// @dev _registerMockLayer2()에서 이미 operator 스테이킹 수행
    function _registerMockLayer2WithOperatorStake() internal {
        _registerMockLayer2();
        // operator 스테이킹은 _registerMockLayer2()에서 이미 수행됨
    }

    /// @notice Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage
    /// @dev 이 함수를 호출하면 다음 updateSeigniorage부터 시뇨리지 분배됨
    function _registerMockLayer2WithOperatorStakeAndInit() internal {
        _registerMockLayer2WithOperatorStake();
        _initializeLayer2Seigniorage();
    }

    /// @notice Type 2 Rollup 등록 (DisputeGameFactory 없음)
    /// @dev Type 2: bedrock with nativeTON (RAT 불가, V3 eligibility는 적용)
    ///      Type 3과 차이: DisputeGameFactory 없음 → RAT 트리거 불가
    function _registerMockLayer2Type2() internal {
        uint256 operatorDeposit = 100 * RAY + 1e10;

        vm.startPrank(owner);

        if (!l1BridgeRegistry.isManager(owner)) {
            l1BridgeRegistry.addManager(owner);
        }
        if (!l1BridgeRegistry.isRegistrant(owner)) {
            l1BridgeRegistry.addRegistrant(owner);
        }

        // TYPE 2: bedrock with nativeTON (DisputeGameFactory 없음)
        l1BridgeRegistry.registerRollupConfig(
            address(mockSystemConfig),
            2, // TYPE_2
            mockL2TON,
            "TestL2-Type2"
        );

        // Portal에 TON 전송 (브릿지된 TON)
        MockTON(ton).mint(mockPortal, BRIDGED_TON_AMOUNT);

        vm.stopPrank();

        // operator 등록
        vm.startPrank(operator1);
        MockWTON(wton).approve(layer2ManagerProxy, operatorDeposit);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            address(mockSystemConfig),
            operatorDeposit,
            false,
            "TestL2-Type2"
        );
        vm.stopPrank();

        mockLayer2 = Layer2ManagerV3(layer2ManagerProxy).getLayer2BySystemConfig(address(mockSystemConfig));
        operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(address(mockSystemConfig));
    }

    /// @notice Type 2 Layer2 등록 + operator 스테이킹
    function _registerMockLayer2Type2WithOperatorStake() internal {
        _registerMockLayer2Type2();
        // operator 스테이킹은 _registerMockLayer2Type2()에서 이미 수행됨
    }

    /// @notice Type 2 Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage
    function _registerMockLayer2Type2WithOperatorStakeAndInit() internal {
        _registerMockLayer2Type2WithOperatorStake();
        _initializeLayer2Seigniorage();
    }

    // ==========================================
    // Seigniorage Helpers
    // ==========================================

    /// @notice 첫 번째 updateSeigniorage 호출하여 startBlock 설정
    /// @dev V2에서는 첫 번째 호출 시 시뇨리지 분배 없이 startBlock만 설정됨
    ///      두 번째 호출부터 실제 시뇨리지 분배
    function _initializeLayer2Seigniorage() internal {
        vm.roll(block.number + 1);
        ICandidate(mockLayer2).updateSeigniorage();

        // startBlock 설정 확인
        (, , uint256 startBlock) = seigManager.layer2RewardInfo(mockLayer2);
        require(startBlock > 0, "startBlock should be set after first update");
    }

    /// @notice updateSeigniorage 호출 헬퍼
    function _updateSeigniorage() internal returns (bool) {
        return ICandidate(mockLayer2).updateSeigniorage();
    }

    // ==========================================
    // Staking Query Helpers
    // ==========================================
    // _getStake()는 DeployV3Full에서 상속받아 사용

    /// @notice Operator의 스테이킹 잔액 조회
    /// @dev Layer2(Candidate)의 operator()로 OperatorManager 주소를 조회한 후 stakeOf 호출
    function _getOperatorStake(address layer2) internal view returns (uint256) {
        address operatorAddr = ILayer2(layer2).operator();
        return _getStake(layer2, operatorAddr);
    }

    /// @notice 스테이킹 잔액 검증 (factor 오차 허용, Test의 assertApproxEqAbs 사용)
    function _assertStakeEq(address layer2, address account, uint256 expected, string memory message) internal view override {
        uint256 actual = _getStake(layer2, account);
        // factor로 인한 오차 허용 (0.01%)
        uint256 tolerance = expected / 10000;
        assertApproxEqAbs(actual, expected, tolerance, message);
    }

    // ==========================================
    // Rollup Type Registration
    // ==========================================

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
            1,                                              // BRIDGE_PATTERN_NATIVE
            true                                            // V3 eligible = true
        );
    }

    // ==========================================
    // V3 Eligibility Helpers
    // ==========================================

    /// @notice V3 자격 조건을 충족시키기 위해 OperatorManager에 deposit
    /// @dev checkCurrentEligibility를 확인하고 필요한 경우 추가 deposit 수행
    ///      OperatorManager는 Layer2I(layer2).operator()로 조회
    /// @param layer2 자격을 충족시킬 Layer2 주소
    function _ensureV3Eligibility(address layer2) internal {
        (bool eligible, uint256 required, uint256 actual) = seigManager.checkCurrentEligibility(layer2);

        if (!eligible) {
            address operatorManagerAddr = Layer2I(layer2).operator();
            uint256 additionalStake = required - actual + 100e27; // 100 WTON 여유

            vm.startPrank(owner);
            MockWTON(wton).mint(owner, additionalStake);
            MockWTON(wton).approve(depositManagerProxy, additionalStake);
            DepositManagerV3(depositManagerProxy).deposit(layer2, operatorManagerAddr, additionalStake);
            vm.stopPrank();
        }
    }

    /// @notice Bridged TON을 증가시켜 V3 자격 조건을 잃게 만듦
    /// @dev Portal에 TON을 mint한 후 onBridgedTonChange를 호출하여
    ///      required stake(θ×B_i)를 증가시켜 eligibility를 상실시킴
    /// @param amount 추가할 Bridged TON 양
    function _increaseBridgedTONForIneligibility(uint256 amount) internal {
        vm.prank(owner);
        MockTON(ton).mint(mockPortal, amount);

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();
    }
}
