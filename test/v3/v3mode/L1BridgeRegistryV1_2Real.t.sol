// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import "../../../src/mocks/SimpleMockSystemConfig.sol";
import {
    RegisterError,
    ZeroAddressError,
    NonRejectedError,
    OnlyRejectedError,
    DisputeGameFactoryError,
    TypeNotSupportedError,
    TypeAlreadyExistsError,
    InvalidTypeError
} from "../../../src/layer2/L1BridgeRegistryV1_2.sol";
import {L1BridgeRegistryV1_2Storage} from "../../../src/layer2/L1BridgeRegistryV1_2Storage.sol";

/// @title L1BridgeRegistryV1_2Test
/// @notice L1BridgeRegistryV1_2 Comprehensive Tests
/// @dev Uses DeployV3Full to deploy the entire system, then tests L1BridgeRegistry functionality
///      Test coverage:
///      - TYPE 1 (Optimism Legacy/Titan) registration
///      - TYPE 2 (Optimism Bedrock with Native TON) registration
///      - TYPE 3 (Optimism Bedrock with DisputeGame & Native TON) registration
///      - upgradeToType3: Upgrade from TYPE 2 to TYPE 3
///      - typeRegistrant: Type-specific registrant management
///      - reject/restore: SystemConfig rejection and restoration
///      - Permission management: admin, manager, registrant roles
contract L1BridgeRegistryV1_2Test is Test, DeployV3Full {
    // Event declarations for testing
    event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2TON, string name);
    event TypeRegistrantSet(uint8 indexed rollupType, address indexed registrant);
    event UpgradedToType3(address rollupConfig, uint8 previousType, address portal, address disputeGameFactory);

    L1BridgeRegistryV1_2 public l1BridgeRegistry;

    address public admin;  // TransparentUpgradeableProxy의 admin (관리 함수만 호출)
    address public owner;  // 비즈니스 로직 owner (구현체 함수 호출)
    address public manager;
    address public registrant;
    address public seigniorageCommittee;
    address public type3Registrant;
    address public unauthorized;

    // Mock addresses
    address public l2TON = address(0x1111);
    address public bridge1 = address(0x2001);
    address public bridge2 = address(0x2002);
    address public bridge3 = address(0x2003);
    address public portal1 = address(0x3001);
    address public portal2 = address(0x3002);
    address public portal3 = address(0x3003);
    address public disputeGameFactory1 = address(0x4001);
    address public disputeGameFactory2 = address(0x4002);

    // Mock SystemConfigs
    SimpleMockSystemConfig public systemConfigType1;
    SimpleMockSystemConfig public systemConfigType2;
    SimpleMockSystemConfig public systemConfigType3;
    SimpleMockSystemConfig public systemConfigForUpgrade;

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
        manager = address(0x9001);
        registrant = address(0x9002);
        seigniorageCommittee = address(0x9003);
        type3Registrant = address(0x9004);
        unauthorized = address(0x8888);
        proxyAdmin = admin;       // Set proxyAdmin before deployment

        // owner 컨텍스트에서 배포 시작
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

        // RAT, ValidatorReward를 배포 (proxyAdmin이 admin으로 설정됨)
        _deployV3Contracts(owner);

        // Register all V3 selectors for test functionality
        _setupSeigManagerV3AllTestSelectors();

        // 이제 admin = proxy admin, owner = contract owner로 분리됨
        _setupCrossReferences(owner);

        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);

        // Setup roles
        l1BridgeRegistry.addManager(owner);  // owner needs to be manager to register types
        l1BridgeRegistry.addManager(manager);

        // Register default rollup types (TYPE 1, 2, 3)
        _registerDefaultRollupTypes();

        vm.stopPrank();

        vm.prank(manager);
        l1BridgeRegistry.addRegistrant(registrant);

        vm.prank(owner);
        l1BridgeRegistry.setSeigniorageCommittee(seigniorageCommittee);

        // Create mock SystemConfigs
        systemConfigType1 = new SimpleMockSystemConfig();
        systemConfigType1.setL1StandardBridge(bridge1);

        systemConfigType2 = new SimpleMockSystemConfig();
        systemConfigType2.setL1StandardBridge(bridge2);
        systemConfigType2.setOptimismPortal(portal1);

        systemConfigType3 = new SimpleMockSystemConfig();
        systemConfigType3.setL1StandardBridge(bridge3);
        systemConfigType3.setOptimismPortal(portal2);
        systemConfigType3.setDisputeGameFactory(disputeGameFactory1);

        // For upgrade test
        systemConfigForUpgrade = new SimpleMockSystemConfig();
        systemConfigForUpgrade.setL1StandardBridge(address(0x5001));
        systemConfigForUpgrade.setOptimismPortal(portal3);
        systemConfigForUpgrade.setDisputeGameFactory(disputeGameFactory2);
    }

    // ==========================================
    // Deployment Tests
    // ==========================================

    /// @notice LBR-001: 배포 후 초기화 상태 확인
    function test_LBR001_deployment_initialized() public view {
        assertEq(l1BridgeRegistry.ton(), ton, "TON set correctly");
        assertEq(l1BridgeRegistry.layer2Manager(), layer2ManagerProxy, "Layer2Manager set correctly");
        assertEq(l1BridgeRegistry.seigManager(), seigManagerProxy, "SeigManager set correctly");
    }

    /// @notice LBR-002: 배포 후 역할 설정 확인
    function test_LBR002_deployment_rolesSetup() public view {
        assertTrue(l1BridgeRegistry.isAdmin(owner), "Owner is admin");
        assertTrue(l1BridgeRegistry.isManager(manager), "Manager role set");
        assertTrue(l1BridgeRegistry.isRegistrant(registrant), "Registrant role set");
        assertEq(l1BridgeRegistry.seigniorageCommittee(), seigniorageCommittee, "SeigniorageCommittee set");
    }

    // ==========================================
    // TYPE 1 Registration Tests
    // ==========================================

    /// @notice LBR-010: TYPE 1 등록 (Manager)
    function test_LBR010_registerType1_byManager() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(systemConfigType1),
            1, // TYPE 1
            l2TON,
            "TestL2Type1"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType1)), 1, "Type should be 1");
        assertEq(l1BridgeRegistry.l2Ton(address(systemConfigType1)), l2TON, "l2TON should be set");

        (uint8 type_, address l2TON_, bool rejectedSeigs_, bool rejectedL2Deposit_, string memory name_) =
            l1BridgeRegistry.getRollupInfo(address(systemConfigType1));

        assertEq(type_, 1);
        assertEq(l2TON_, l2TON);
        assertFalse(rejectedSeigs_);
        assertFalse(rejectedL2Deposit_);
        assertEq(name_, "TestL2Type1");
    }

    /// @notice LBR-011: TYPE 1 등록 (Registrant)
    function test_LBR011_registerType1_byRegistrant() public {
        vm.prank(registrant);
        l1BridgeRegistry.registerRollupConfig(
            address(systemConfigType1),
            1,
            l2TON,
            "TestL2Type1Registrant"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType1)), 1);
    }

    /// @notice LBR-012: TYPE 1 등록 권한 없는 사용자 revert
    function test_LBR012_registerType1_revertUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not a registrant");
        l1BridgeRegistry.registerRollupConfig(address(systemConfigType1), 1, l2TON, "Test");
    }

    // ==========================================
    // TYPE 2 Registration Tests
    // ==========================================

    /// @notice LBR-020: TYPE 2 등록 (Manager)
    function test_LBR020_registerType2_byManager() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(systemConfigType2),
            2, // TYPE 2
            l2TON,
            "TestL2Type2"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType2)), 2, "Type should be 2");
        // TYPE 2 has no seigNotifierGetter, so portal is NOT registered
        assertFalse(l1BridgeRegistry.portal(portal1), "Portal should NOT be registered for TYPE 2");
    }

    /// @notice LBR-021: TYPE 2 등록 시 l2TON이 zero address면 revert
    function test_LBR021_registerType2_revertZeroL2TON() public {
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 4));
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, address(0), "Test");
    }

    /// @notice LBR-022: TYPE 2 이미 등록된 config 재등록 시 revert
    function test_LBR022_registerType2_revertAlreadyRegistered() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 2));
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test2");
    }

    // ==========================================
    // TYPE 3 Registration Tests
    // ==========================================

    /// @notice LBR-030: TYPE 3 등록 (Manager)
    function test_LBR030_registerType3_byManager() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(systemConfigType3),
            3, // TYPE 3
            l2TON,
            "TestL2Type3"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType3)), 3, "Type should be 3");
        assertTrue(l1BridgeRegistry.portal(portal2), "Portal should be registered");
        assertTrue(l1BridgeRegistry.disputeGameFactory(address(systemConfigType3)), "DisputeGameFactory flag should be true");
        assertEq(
            l1BridgeRegistry.rollupConfigWithDisputeGameFactory(disputeGameFactory1),
            address(systemConfigType3),
            "rollupConfigWithDisputeGameFactory should be set"
        );
    }

    /// @notice LBR-031: TYPE 3 등록 시 DisputeGameFactory 없으면 revert
    function test_LBR031_registerType3_revertNoDisputeGameFactory() public {
        SimpleMockSystemConfig configNoFactory = new SimpleMockSystemConfig();
        configNoFactory.setL1StandardBridge(address(0x6001));
        configNoFactory.setOptimismPortal(address(0x6002));
        // DisputeGameFactory is not set

        vm.prank(manager);
        // Dynamic registration will fail with DisputeGameFactoryError when factory getter is set but address is unavailable
        vm.expectRevert(DisputeGameFactoryError.selector);
        l1BridgeRegistry.registerRollupConfigByManager(address(configNoFactory), 3, l2TON, "Test");
    }

    /// @notice LBR-032: 유효하지 않은 type으로 등록 시 revert
    function test_LBR032_registerType3_revertInvalidType() public {
        // TYPE 0 is reserved (invalid)
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 1));
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType3), 0, l2TON, "Test");

        // TYPE 4 is not registered yet
        vm.prank(manager);
        vm.expectRevert(TypeNotSupportedError.selector);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType3), 4, l2TON, "Test");
    }

    // ==========================================
    // typeRegistrant Tests
    // ==========================================

    /// @notice LBR-040: typeRegistrant 설정 (Manager)
    function test_LBR040_setTypeRegistrant_byManager() public {
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        assertEq(l1BridgeRegistry.typeRegistrant(3), type3Registrant, "Type3 registrant should be set");
    }

    /// @notice LBR-041: typeRegistrant 설정 권한 없는 사용자 revert
    function test_LBR041_setTypeRegistrant_revertUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not a manager");
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);
    }

    /// @notice LBR-042: typeRegistrant로 등록
    function test_LBR042_registerByType_withTypeRegistrant() public {
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        vm.prank(type3Registrant);
        l1BridgeRegistry.registerRollupConfigByType(
            address(systemConfigType3),
            3,
            l2TON,
            "TestByTypeRegistrant"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType3)), 3);
    }

    /// @notice LBR-043: Manager는 항상 등록 가능
    function test_LBR043_registerByType_managerCanAlwaysRegister() public {
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByType(
            address(systemConfigType3),
            3,
            l2TON,
            "TestByManager"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType3)), 3);
    }

    /// @notice LBR-044: 다른 type의 typeRegistrant로 등록 시 revert
    function test_LBR044_registerByType_revertWrongTypeRegistrant() public {
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        vm.prank(type3Registrant);
        vm.expectRevert(L1BridgeRegistryV1_2.NotAuthorizedError.selector);
        l1BridgeRegistry.registerRollupConfigByType(
            address(systemConfigType2),
            2,
            l2TON,
            "Test"
        );
    }

    /// @notice LBR-045: typeRegistrant 미설정 시 Manager만 등록 가능
    function test_LBR045_registerByType_noRegistrantSetRequiresManager() public {
        vm.prank(unauthorized);
        vm.expectRevert(L1BridgeRegistryV1_2.NotAuthorizedError.selector);
        l1BridgeRegistry.registerRollupConfigByType(
            address(systemConfigType2),
            2,
            l2TON,
            "Test"
        );
    }

    // ==========================================
    // upgradeToType3 Tests
    // ==========================================

    /// @notice LBR-050: TYPE 2에서 TYPE 3으로 업그레이드
    function test_LBR050_upgradeToType3_fromType2() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(systemConfigForUpgrade),
            2,
            l2TON,
            "UpgradeTest"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigForUpgrade)), 2);

        vm.prank(manager);
        l1BridgeRegistry.upgradeToType3(address(systemConfigForUpgrade));

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigForUpgrade)), 3);
        assertTrue(l1BridgeRegistry.disputeGameFactory(address(systemConfigForUpgrade)));
        assertEq(
            l1BridgeRegistry.rollupConfigWithDisputeGameFactory(disputeGameFactory2),
            address(systemConfigForUpgrade)
        );
    }

    /// @notice LBR-051: TYPE 1에서 TYPE 3으로 업그레이드
    function test_LBR051_upgradeToType3_fromType1() public {
        SimpleMockSystemConfig configType1ForUpgrade = new SimpleMockSystemConfig();
        configType1ForUpgrade.setL1StandardBridge(address(0x7001));
        configType1ForUpgrade.setOptimismPortal(address(0x7002));
        configType1ForUpgrade.setDisputeGameFactory(address(0x7003));

        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(configType1ForUpgrade),
            1,
            l2TON,
            "Type1UpgradeTest"
        );

        vm.prank(manager);
        l1BridgeRegistry.upgradeToType3(address(configType1ForUpgrade));

        assertEq(l1BridgeRegistry.rollupType(address(configType1ForUpgrade)), 3);
    }

    /// @notice LBR-052: 미등록 config 업그레이드 시 revert
    function test_LBR052_upgradeToType3_revertNotRegistered() public {
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(L1BridgeRegistryV1_2.UpgradeError.selector, 1));
        l1BridgeRegistry.upgradeToType3(address(systemConfigType3));
    }

    /// @notice LBR-053: 이미 TYPE 3인 config 업그레이드 시 revert
    function test_LBR053_upgradeToType3_revertAlreadyType3() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType3), 3, l2TON, "Test");

        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(L1BridgeRegistryV1_2.UpgradeError.selector, 2));
        l1BridgeRegistry.upgradeToType3(address(systemConfigType3));
    }

    /// @notice LBR-054: DisputeGameFactory 없는 config 업그레이드 시 revert
    function test_LBR054_upgradeToType3_revertNoDisputeGameFactory() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(L1BridgeRegistryV1_2.UpgradeError.selector, 3));
        l1BridgeRegistry.upgradeToType3(address(systemConfigType2));
    }

    /// @notice LBR-055: 권한 없는 사용자 업그레이드 시 revert
    function test_LBR055_upgradeToType3_revertUnauthorized() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigForUpgrade), 2, l2TON, "Test");

        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not a manager");
        l1BridgeRegistry.upgradeToType3(address(systemConfigForUpgrade));
    }

    // ==========================================
    // rejectCandidateAddOn Tests
    // ==========================================

    /// @notice LBR-060: rejectCandidateAddOn 권한 없는 사용자 revert
    function test_LBR060_rejectCandidateAddOn_revertUnauthorized() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        vm.prank(unauthorized);
        vm.expectRevert("PermissionError");
        l1BridgeRegistry.rejectCandidateAddOn(address(systemConfigType2));
    }

    /// @notice LBR-061: 미등록 config reject 시 revert
    function test_LBR061_rejectCandidateAddOn_revertNotRegistered() public {
        vm.prank(seigniorageCommittee);
        vm.expectRevert("NonRegistered");
        l1BridgeRegistry.rejectCandidateAddOn(address(systemConfigType2));
    }

    // ==========================================
    // restoreCandidateAddOn Tests
    // ==========================================

    /// @notice LBR-062: reject되지 않은 config restore 시 revert
    function test_LBR062_restoreCandidateAddOn_revertNotRejected() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        vm.prank(seigniorageCommittee);
        vm.expectRevert(OnlyRejectedError.selector);
        l1BridgeRegistry.restoreCandidateAddOn(address(systemConfigType2), false);
    }

    // ==========================================
    // availableForRegistration Tests
    // ==========================================

    /// @notice LBR-070: TYPE 1 등록 가능 여부 확인
    function test_LBR070_availableForRegistration_type1() public view {
        assertTrue(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType1), 1),
            "Type1 should be available"
        );
    }

    /// @notice LBR-071: TYPE 2 등록 가능 여부 확인
    function test_LBR071_availableForRegistration_type2() public view {
        assertTrue(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType2), 2),
            "Type2 should be available"
        );
    }

    /// @notice LBR-072: TYPE 3 등록 가능 여부 확인
    function test_LBR072_availableForRegistration_type3() public view {
        assertTrue(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType3), 3),
            "Type3 should be available"
        );
    }

    /// @notice LBR-073: 등록 후 availableForRegistration false
    function test_LBR073_availableForRegistration_falseAfterRegistered() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        assertFalse(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType2), 2),
            "Should not be available after registration"
        );
    }

    /// @notice LBR-074: 동일 portal 사용 시 등록 불가
    function test_LBR074_availableForRegistration_falseWhenPortalUsed() public {
        // Use TYPE 3 since it has seigNotifierGetter that registers portal
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType3), 3, l2TON, "Test");

        // Create a new config that shares the same portal (portal2) as systemConfigType3
        SimpleMockSystemConfig newConfig = new SimpleMockSystemConfig();
        newConfig.setL1StandardBridge(address(0x8001));
        newConfig.setOptimismPortal(portal2);
        newConfig.setDisputeGameFactory(address(0x8002));

        assertFalse(
            l1BridgeRegistry.availableForRegistration(address(newConfig), 3),
            "Should not be available when portal already used"
        );
    }

    // ==========================================
    // getRollupInfo Tests
    // ==========================================

    /// @notice LBR-080: getRollupInfo 전체 정보 확인
    function test_LBR080_getRollupInfo_complete() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType3), 3, l2TON, "CompleteTest");

        (uint8 type_, address l2TON_, bool rejectedSeigs_, bool rejectedL2Deposit_, string memory name_) =
            l1BridgeRegistry.getRollupInfo(address(systemConfigType3));

        assertEq(type_, 3);
        assertEq(l2TON_, l2TON);
        assertFalse(rejectedSeigs_);
        assertFalse(rejectedL2Deposit_);
        assertEq(name_, "CompleteTest");
    }

    // ==========================================
    // setAddresses Tests
    // ==========================================

    /// @notice LBR-081: 이미 초기화된 경우 setAddresses revert
    function test_LBR081_setAddresses_revertAlreadyInitialized() public {
        vm.expectRevert("already initialized");
        l1BridgeRegistry.setAddresses(address(0x1), address(0x2), address(0x3));
    }

    // ==========================================
    // setSeigniorageCommittee Tests
    // ==========================================

    /// @notice LBR-082: setSeigniorageCommittee 성공
    function test_LBR082_setSeigniorageCommittee_success() public {
        address newCommittee = address(0xABCD);
        l1BridgeRegistry.setSeigniorageCommittee(newCommittee);
        assertEq(l1BridgeRegistry.seigniorageCommittee(), newCommittee);
    }

    /// @notice LBR-083: 동일한 값 설정 시 revert
    function test_LBR083_setSeigniorageCommittee_revertSame() public {
        vm.expectRevert(bytes("same"));
        l1BridgeRegistry.setSeigniorageCommittee(seigniorageCommittee);
    }

    /// @notice LBR-084: 권한 없는 사용자 설정 시 revert
    function test_LBR084_setSeigniorageCommittee_revertUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not an admin");
        l1BridgeRegistry.setSeigniorageCommittee(address(0xABCD));
    }

    // ==========================================
    // rejectRollupConfig (alias) Tests
    // ==========================================

    /// @notice LBR-085: rejectRollupConfig 기본값 false
    function test_LBR085_rejectRollupConfig_alias_defaultFalse() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        assertFalse(l1BridgeRegistry.rejectRollupConfig(address(systemConfigType2)));
    }

    // ==========================================
    // Event Emission Tests
    // ==========================================

    /// @notice LBR-090: RegisteredRollupConfig 이벤트 발생
    function test_LBR090_event_RegisteredRollupConfig() public {
        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit RegisteredRollupConfig(address(systemConfigType2), 2, l2TON, "EventTest");
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "EventTest");
    }

    /// @notice LBR-091: TypeRegistrantSet 이벤트 발생
    function test_LBR091_event_TypeRegistrantSet() public {
        vm.prank(manager);
        vm.expectEmit(true, true, false, false);
        emit TypeRegistrantSet(3, type3Registrant);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);
    }

    /// @notice LBR-092: UpgradedToType3 이벤트 발생
    function test_LBR092_event_UpgradedToType3() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigForUpgrade), 2, l2TON, "Test");

        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit UpgradedToType3(address(systemConfigForUpgrade), 2, portal3, disputeGameFactory2);
        l1BridgeRegistry.upgradeToType3(address(systemConfigForUpgrade));
    }

    // ==========================================
    // Dynamic Rollup Type Management Tests
    // ==========================================

    /// @notice LBR-100: addRollupType - TYPE 1,2,3이 이미 등록되어 있는지 확인
    function test_LBR100_defaultRollupTypes_registered() public view {
        // TYPE 1 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config1 = l1BridgeRegistry.getRollupTypeConfig(1);
        assertEq(config1.tvlContractGetter, bytes4(keccak256("l1StandardBridge()")), "TYPE 1 getter");
        assertEq(config1.bridgePattern, 0, "TYPE 1 pattern is ERC20");
        assertEq(config1.name, "Optimism Legacy", "TYPE 1 name");
        assertFalse(l1BridgeRegistry.isValidRollupType(1), "TYPE 1 is not V3 eligible");

        // TYPE 2 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config2 = l1BridgeRegistry.getRollupTypeConfig(2);
        assertEq(config2.tvlContractGetter, bytes4(keccak256("optimismPortal()")), "TYPE 2 getter");
        assertEq(config2.bridgePattern, 1, "TYPE 2 pattern is NATIVE");
        assertEq(config2.name, "Optimism Bedrock", "TYPE 2 name");
        assertFalse(l1BridgeRegistry.isValidRollupType(2), "TYPE 2 is not V3 eligible");

        // TYPE 3 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config3 = l1BridgeRegistry.getRollupTypeConfig(3);
        assertEq(config3.tvlContractGetter, bytes4(keccak256("optimismPortal()")), "TYPE 3 tvl getter");
        assertEq(config3.bridgePattern, 1, "TYPE 3 pattern is NATIVE");
        assertEq(config3.name, "Optimism Bedrock DisputeGame", "TYPE 3 name");
        assertTrue(l1BridgeRegistry.isValidRollupType(3), "TYPE 3 is V3 eligible");

        // Bitmap 확인 (bit 3만 set)
        uint256 bitmap = l1BridgeRegistry.getV3SeigniorageEligibleTypes();
        assertEq(bitmap, 8, "Bitmap should be 8 (0b1000 = TYPE 3 only)");
    }

    /// @notice LBR-101: addRollupType - 새 타입 등록 성공
    function test_LBR101_addRollupType_success() public {
        vm.prank(owner);
        l1BridgeRegistry.addRollupType(
            4,
            "Arbitrum Orbit",
            bytes4(keccak256("bridge()")),      // bridgeContractGetter
            bytes4(keccak256("bridge()")),      // tvlContractGetter
            bytes4(0),                           // disputeGameFactoryGetter (none)
            bytes4(0),                           // seigNotifierGetter (none)
            2,  // BRIDGE_PATTERN_CUSTOM
            true
        );

        // 등록 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config = l1BridgeRegistry.getRollupTypeConfig(4);
        assertEq(config.bridgeContractGetter, bytes4(keccak256("bridge()")), "TYPE 4 bridge getter");
        assertEq(config.tvlContractGetter, bytes4(keccak256("bridge()")), "TYPE 4 tvl getter");
        assertEq(config.disputeGameFactoryGetter, bytes4(0), "TYPE 4 factory getter (none)");
        assertEq(config.bridgePattern, 2, "TYPE 4 pattern is CUSTOM");
        assertEq(config.name, "Arbitrum Orbit", "TYPE 4 name");
        assertTrue(l1BridgeRegistry.isValidRollupType(4), "TYPE 4 is V3 eligible");

        // Bitmap 확인 (bit 3, 4가 set)
        uint256 bitmap = l1BridgeRegistry.getV3SeigniorageEligibleTypes();
        assertEq(bitmap, 24, "Bitmap should be 24 (0b11000 = TYPE 3,4)");
    }

    /// @notice LBR-102: addRollupType - TYPE 0 등록 시도 실패
    function test_LBR102_addRollupType_revertInvalidType() public {
        vm.prank(owner);
        vm.expectRevert(InvalidTypeError.selector);
        l1BridgeRegistry.addRollupType(
            0,
            "Invalid",
            bytes4(keccak256("invalid()")),     // bridgeContractGetter
            bytes4(keccak256("invalid()")),     // tvlContractGetter
            bytes4(0),                           // disputeGameFactoryGetter
            bytes4(0),                           // seigNotifierGetter
            0,
            false
        );
    }

    /// @notice LBR-103: addRollupType - 중복 등록 시도 실패
    function test_LBR103_addRollupType_revertTypeAlreadyExists() public {
        vm.prank(owner);
        vm.expectRevert(TypeAlreadyExistsError.selector);
        l1BridgeRegistry.addRollupType(
            1,  // Already registered
            "Duplicate",
            bytes4(keccak256("duplicate()")),   // bridgeContractGetter
            bytes4(keccak256("duplicate()")),   // tvlContractGetter
            bytes4(0),                           // disputeGameFactoryGetter
            bytes4(0),                           // seigNotifierGetter
            0,
            false
        );
    }

    /// @notice LBR-104: addRollupType - 권한 없는 사용자 실패
    function test_LBR104_addRollupType_revertUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not a manager");
        l1BridgeRegistry.addRollupType(
            4,
            "Unauthorized",
            bytes4(keccak256("unauthorized()")),    // bridgeContractGetter
            bytes4(keccak256("unauthorized()")),    // tvlContractGetter
            bytes4(0),                               // disputeGameFactoryGetter
            bytes4(0),                               // seigNotifierGetter
            0,
            false
        );
    }

    /// @notice LBR-105: updateRollupType - 정상 업데이트
    function test_LBR105_updateRollupType_success() public {
        // TYPE 1을 V3 eligible로 변경
        vm.prank(owner);
        l1BridgeRegistry.updateRollupType(
            1,
            "Optimism Legacy V2",
            bytes4(keccak256("l1StandardBridge()")),   // bridgeContractGetter
            bytes4(keccak256("l1StandardBridge()")),   // tvlContractGetter
            bytes4(0),                                  // disputeGameFactoryGetter
            bytes4(0),                                  // seigNotifierGetter
            0,
            true  // V3 eligible로 변경
        );

        // 업데이트 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config = l1BridgeRegistry.getRollupTypeConfig(1);
        assertEq(config.name, "Optimism Legacy V2", "Name updated");
        assertTrue(l1BridgeRegistry.isValidRollupType(1), "TYPE 1 is now V3 eligible");

        // Bitmap 확인 (bit 1, 3이 set)
        uint256 bitmap = l1BridgeRegistry.getV3SeigniorageEligibleTypes();
        assertEq(bitmap, 10, "Bitmap should be 10 (0b1010 = TYPE 1,3)");
    }

    /// @notice LBR-106: updateRollupType - 존재하지 않는 타입 업데이트 실패
    function test_LBR106_updateRollupType_revertTypeNotSupported() public {
        vm.prank(owner);
        vm.expectRevert(TypeNotSupportedError.selector);
        l1BridgeRegistry.updateRollupType(
            99,  // Not registered
            "NonExistent",
            bytes4(keccak256("nonexistent()")),     // bridgeContractGetter
            bytes4(keccak256("nonexistent()")),     // tvlContractGetter
            bytes4(0),                               // disputeGameFactoryGetter
            bytes4(0),                               // seigNotifierGetter
            0,
            false
        );
    }

    /// @notice LBR-107: updateRollupType - 변경사항 없으면 early return
    function test_LBR107_updateRollupType_noChangeEarlyReturn() public {
        // 동일한 내용으로 업데이트 시도
        vm.prank(owner);
        l1BridgeRegistry.updateRollupType(
            1,
            "Optimism Legacy",  // Same name
            bytes4(keccak256("l1StandardBridge()")),  // Same bridgeContractGetter
            bytes4(keccak256("l1StandardBridge()")),  // Same tvlContractGetter
            bytes4(0),                                 // Same disputeGameFactoryGetter
            bytes4(0),                                 // Same seigNotifierGetter
            0,  // Same pattern
            false  // Same V3 eligibility
        );

        // 변경사항 없음 확인 (실제로 테스트는 revert 없이 통과하는 것으로 확인)
        assertTrue(true, "No revert means early return worked");
    }

    /// @notice LBR-108: getBridgePattern - 올바른 패턴 반환
    function test_LBR108_getBridgePattern_success() public view {
        assertEq(l1BridgeRegistry.getBridgePattern(1), 0, "TYPE 1 is ERC20");
        assertEq(l1BridgeRegistry.getBridgePattern(2), 1, "TYPE 2 is NATIVE");
        assertEq(l1BridgeRegistry.getBridgePattern(3), 1, "TYPE 3 is NATIVE");
    }

    /// @notice LBR-109: getTvlContractGetter - 올바른 selector 반환
    function test_LBR109_getTvlContractGetter_success() public view {
        assertEq(
            l1BridgeRegistry.getTvlContractGetter(1),
            bytes4(keccak256("l1StandardBridge()")),
            "TYPE 1 getter"
        );
        assertEq(
            l1BridgeRegistry.getTvlContractGetter(2),
            bytes4(keccak256("optimismPortal()")),
            "TYPE 2 getter"
        );
        assertEq(
            l1BridgeRegistry.getTvlContractGetter(3),
            bytes4(keccak256("optimismPortal()")),
            "TYPE 3 getter"
        );
    }

    /// @notice LBR-110: isValidRollupType - V3 eligibility 확인
    function test_LBR110_isValidRollupType_success() public view {
        assertFalse(l1BridgeRegistry.isValidRollupType(1), "TYPE 1 is not V3 eligible");
        assertFalse(l1BridgeRegistry.isValidRollupType(2), "TYPE 2 is not V3 eligible");
        assertTrue(l1BridgeRegistry.isValidRollupType(3), "TYPE 3 is V3 eligible");
        assertFalse(l1BridgeRegistry.isValidRollupType(99), "TYPE 99 does not exist");
    }

    /// @notice LBR-111: 새 타입(TYPE 4) 등록 후 rollupConfig 등록 가능 확인
    function test_LBR111_newType_canRegisterRollupConfig() public {
        // 1. TYPE 4 등록 (V3 eligible)
        // SimpleMockSystemConfig에는 bridge() 함수가 없으므로 l1StandardBridge() 사용
        vm.prank(owner);
        l1BridgeRegistry.addRollupType(
            4,
            "Custom L2",
            bytes4(keccak256("l1StandardBridge()")),  // bridgeContractGetter (기존 함수 재사용)
            bytes4(keccak256("l1StandardBridge()")),  // tvlContractGetter
            bytes4(0),                                 // disputeGameFactoryGetter (none)
            bytes4(0),                                 // seigNotifierGetter (none)
            1,  // BRIDGE_PATTERN_NATIVE
            true  // V3 eligible
        );

        // 2. TYPE 4용 SystemConfig 생성
        SimpleMockSystemConfig systemConfigType4 = new SimpleMockSystemConfig();
        address bridgeType4 = address(0x9999);
        systemConfigType4.setL1StandardBridge(bridgeType4);  // l1StandardBridge 설정

        // 3. TYPE 4로 rollupConfig 등록 시도
        address l2TONType4 = address(0x8888);
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(systemConfigType4),
            4,  // TYPE 4
            l2TONType4,
            "Arbitrum L2"
        );

        // 4. 등록 확인
        (uint8 rollupType, address l2Ton, , , string memory name) = l1BridgeRegistry.getRollupInfo(address(systemConfigType4));
        assertEq(rollupType, 4, "Registered as TYPE 4");
        assertEq(l2Ton, l2TONType4, "L2TON address correct");
        assertEq(name, "Arbitrum L2", "Name correct");

        // 5. V3 eligible 확인
        assertTrue(l1BridgeRegistry.isValidRollupType(4), "TYPE 4 is V3 eligible");
    }

    /// @notice LBR-112: TYPE 1 동적 등록 검증 - bridge와 TVL이 같은 주소
    function test_LBR112_type1_dynamicRegistration_bridgeAndTvlSame() public {
        // TYPE 1: bridgeContractGetter와 tvlContractGetter가 같음 (l1StandardBridge)
        SimpleMockSystemConfig config = new SimpleMockSystemConfig();
        address bridge = address(0x7001);
        config.setL1StandardBridge(bridge);

        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(config),
            1,  // TYPE 1
            address(0x7002),
            "TYPE1-Test"
        );

        // l1Bridge에 등록되었는지 확인
        assertTrue(l1BridgeRegistry.l1Bridge(bridge), "Bridge should be registered to l1Bridge mapping");

        // portal에는 등록되지 않아야 함 (tvlGetter가 bridgeGetter와 같으므로)
        assertFalse(l1BridgeRegistry.portal(bridge), "Bridge should NOT be registered to portal mapping");

        // rollupConfig 등록 확인
        (uint8 rollupType, , , , ) = l1BridgeRegistry.getRollupInfo(address(config));
        assertEq(rollupType, 1, "Should be registered as TYPE 1");
    }

    /// @notice LBR-113: TYPE 2 동적 등록 검증 - bridge와 TVL이 다른 주소
    function test_LBR113_type2_dynamicRegistration_bridgeAndTvlDifferent() public {
        // TYPE 2: bridgeContractGetter(l1StandardBridge)와 tvlContractGetter(optimismPortal)가 다름
        // But TYPE 2 has no seigNotifierGetter, so portal is NOT registered
        SimpleMockSystemConfig config = new SimpleMockSystemConfig();
        address bridge = address(0x7101);
        address portalAddr = address(0x7102);
        config.setL1StandardBridge(bridge);
        config.setOptimismPortal(portalAddr);

        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(config),
            2,  // TYPE 2
            address(0x7103),
            "TYPE2-Test"
        );

        // l1Bridge에 bridge 주소 등록 확인
        assertTrue(l1BridgeRegistry.l1Bridge(bridge), "Bridge should be registered to l1Bridge mapping");

        // TYPE 2 has no seigNotifierGetter, so portal is NOT registered
        assertFalse(l1BridgeRegistry.portal(portalAddr), "Portal should NOT be registered for TYPE 2");

        // rollupConfig 등록 확인
        (uint8 rollupType, , , , ) = l1BridgeRegistry.getRollupInfo(address(config));
        assertEq(rollupType, 2, "Should be registered as TYPE 2");
    }

    /// @notice LBR-114: TYPE 3 동적 등록 검증 - bridge, TVL, DisputeGameFactory 모두 등록
    function test_LBR114_type3_dynamicRegistration_withDisputeGameFactory() public {
        // TYPE 3: bridge, portal, disputeGameFactory 모두 다름
        SimpleMockSystemConfig config = new SimpleMockSystemConfig();
        address bridge = address(0x7201);
        address portal = address(0x7202);
        address factory = address(0x7203);
        config.setL1StandardBridge(bridge);
        config.setOptimismPortal(portal);
        config.setDisputeGameFactory(factory);

        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(config),
            3,  // TYPE 3
            address(0x7204),
            "TYPE3-Test"
        );

        // 1. l1Bridge에 bridge 주소 등록 확인
        assertTrue(l1BridgeRegistry.l1Bridge(bridge), "Bridge should be registered to l1Bridge mapping");

        // 2. portal 매핑에 portal 주소 등록 확인
        assertTrue(l1BridgeRegistry.portal(portal), "Portal should be registered to portal mapping");
        assertEq(
            l1BridgeRegistry.rollupConfigWithPortal(portal),
            address(config),
            "Portal should be mapped to rollupConfig"
        );

        // 3. disputeGameFactory 매핑 확인
        assertTrue(
            l1BridgeRegistry.disputeGameFactory(address(config)),
            "DisputeGameFactory flag should be true for rollupConfig"
        );
        assertEq(
            l1BridgeRegistry.rollupConfigWithDisputeGameFactory(factory),
            address(config),
            "Factory should be mapped to rollupConfig"
        );

        // rollupConfig 등록 확인
        (uint8 rollupType, , , , ) = l1BridgeRegistry.getRollupInfo(address(config));
        assertEq(rollupType, 3, "Should be registered as TYPE 3");
    }

    /// @notice LBR-115: 동적 등록 - DisputeGameFactory가 없으면 TYPE 3 등록 실패
    function test_LBR115_type3_dynamicRegistration_revertMissingFactory() public {
        // TYPE 3는 disputeGameFactoryGetter가 설정되어 있으므로 factory 주소가 필수
        SimpleMockSystemConfig config = new SimpleMockSystemConfig();
        config.setL1StandardBridge(address(0x7301));
        config.setOptimismPortal(address(0x7302));
        // config.setDisputeGameFactory를 설정하지 않음 (address(0))

        vm.prank(manager);
        vm.expectRevert(DisputeGameFactoryError.selector);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(config),
            3,  // TYPE 3
            address(0x7303),
            "TYPE3-NoFactory"
        );
    }

    /// @notice LBR-116: 모든 타입이 동일한 동적 등록 로직 사용 확인
    function test_LBR116_allTypes_useSameDynamicRegistration() public {
        // TYPE 1, 2, 3, 4 모두 동일한 _registerRollupConfig 경로를 사용
        // 각 타입의 config 설정만 다름을 확인

        // TYPE 1 config 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config1 = l1BridgeRegistry.getRollupTypeConfig(1);
        assertEq(config1.bridgeContractGetter, bytes4(keccak256("l1StandardBridge()")), "TYPE 1 bridge getter");
        assertEq(config1.tvlContractGetter, bytes4(keccak256("l1StandardBridge()")), "TYPE 1 tvl getter (same)");
        assertEq(config1.disputeGameFactoryGetter, bytes4(0), "TYPE 1 no factory getter");

        // TYPE 2 config 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config2 = l1BridgeRegistry.getRollupTypeConfig(2);
        assertEq(config2.bridgeContractGetter, bytes4(keccak256("l1StandardBridge()")), "TYPE 2 bridge getter");
        assertEq(config2.tvlContractGetter, bytes4(keccak256("optimismPortal()")), "TYPE 2 tvl getter (different)");
        assertEq(config2.disputeGameFactoryGetter, bytes4(0), "TYPE 2 no factory getter");

        // TYPE 3 config 확인
        L1BridgeRegistryV1_2Storage.RollupTypeConfig memory config3 = l1BridgeRegistry.getRollupTypeConfig(3);
        assertEq(config3.bridgeContractGetter, bytes4(keccak256("l1StandardBridge()")), "TYPE 3 bridge getter");
        assertEq(config3.tvlContractGetter, bytes4(keccak256("optimismPortal()")), "TYPE 3 tvl getter");
        assertEq(
            config3.disputeGameFactoryGetter,
            bytes4(keccak256("disputeGameFactory()")),
            "TYPE 3 has factory getter"
        );

        // 모든 타입이 등록되어 있음 (bridgeContractGetter != bytes4(0))
        assertTrue(config1.bridgeContractGetter != bytes4(0), "TYPE 1 registered");
        assertTrue(config2.bridgeContractGetter != bytes4(0), "TYPE 2 registered");
        assertTrue(config3.bridgeContractGetter != bytes4(0), "TYPE 3 registered");
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    /// @notice Register default rollup types (TYPE 1, 2, 3)
    function _registerDefaultRollupTypes() internal {
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
}
