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
    DisputeGameFactoryError
} from "../../../src/layer2/L1BridgeRegistryV1_2.sol";

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
        l1BridgeRegistry.addManager(manager);
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
        assertTrue(l1BridgeRegistry.portal(portal1), "Portal should be registered");
        assertEq(
            l1BridgeRegistry.rollupConfigWithPortal(portal1),
            address(systemConfigType2),
            "rollupConfigWithPortal should be set"
        );
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

        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 3));
        l1BridgeRegistry.registerRollupConfigByManager(address(configNoFactory), 3, l2TON, "Test");
    }

    /// @notice LBR-032: 유효하지 않은 type으로 등록 시 revert
    function test_LBR032_registerType3_revertInvalidType() public {
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 1));
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType3), 0, l2TON, "Test");

        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 1));
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
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        SimpleMockSystemConfig newConfig = new SimpleMockSystemConfig();
        newConfig.setL1StandardBridge(address(0x8001));
        newConfig.setOptimismPortal(portal1);

        assertFalse(
            l1BridgeRegistry.availableForRegistration(address(newConfig), 2),
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
}
