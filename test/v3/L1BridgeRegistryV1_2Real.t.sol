// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../script/DeployV3Full.s.sol";
import "./mocks/MockSystemConfig.sol";
import {
    RegisterError,
    ZeroAddressError,
    NonRejectedError,
    OnlyRejectedError,
    DisputeGameFactoryError
} from "../../src/layer2/L1BridgeRegistryV1_2.sol";

/// @title L1BridgeRegistryV1_2Test
/// @notice L1BridgeRegistryV1_2 comprehensive tests
/// @dev Tests for TYPE 1/2/3 registration, upgradeToType3, typeRegistrant, reject/restore

contract L1BridgeRegistryV1_2Test is Test, DeployV3Full {
    // Event declarations for testing
    event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2TON, string name);
    event TypeRegistrantSet(uint8 indexed rollupType, address indexed registrant);
    event UpgradedToType3(address rollupConfig, uint8 previousType, address portal, address disputeGameFactory);

    L1BridgeRegistryV1_2 public l1BridgeRegistry;

    address public owner;
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
    MockSystemConfig public systemConfigType1;
    MockSystemConfig public systemConfigType2;
    MockSystemConfig public systemConfigType3;
    MockSystemConfig public systemConfigForUpgrade;

    function setUp() public {
        owner = address(this);
        manager = address(0x9001);
        registrant = address(0x9002);
        seigniorageCommittee = address(0x9003);
        type3Registrant = address(0x9004);
        unauthorized = address(0x9999);

        // Deploy full system
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);
        _deployV3Contracts(owner);
        _configureV3Contracts(owner);
        _setupCrossReferences(owner);

        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);

        // Setup roles
        l1BridgeRegistry.addManager(manager);
        vm.prank(manager);
        l1BridgeRegistry.addRegistrant(registrant);
        l1BridgeRegistry.setSeigniorageCommittee(seigniorageCommittee);

        // Create mock SystemConfigs
        systemConfigType1 = new MockSystemConfig();
        systemConfigType1.setL1StandardBridge(bridge1);

        systemConfigType2 = new MockSystemConfig();
        systemConfigType2.setL1StandardBridge(bridge2);
        systemConfigType2.setOptimismPortal(portal1);

        systemConfigType3 = new MockSystemConfig();
        systemConfigType3.setL1StandardBridge(bridge3);
        systemConfigType3.setOptimismPortal(portal2);
        systemConfigType3.setDisputeGameFactory(disputeGameFactory1);

        // For upgrade test
        systemConfigForUpgrade = new MockSystemConfig();
        systemConfigForUpgrade.setL1StandardBridge(address(0x5001));
        systemConfigForUpgrade.setOptimismPortal(portal3);
        systemConfigForUpgrade.setDisputeGameFactory(disputeGameFactory2);
    }

    // ==========================================
    // Deployment Tests
    // ==========================================

    function test_deployment_initialized() public view {
        assertEq(l1BridgeRegistry.ton(), ton, "TON set correctly");
        assertEq(l1BridgeRegistry.layer2Manager(), layer2ManagerProxy, "Layer2Manager set correctly");
        assertEq(l1BridgeRegistry.seigManager(), seigManagerProxy, "SeigManager set correctly");
    }

    function test_deployment_rolesSetup() public view {
        assertTrue(l1BridgeRegistry.isAdmin(owner), "Owner is admin");
        assertTrue(l1BridgeRegistry.isManager(manager), "Manager role set");
        assertTrue(l1BridgeRegistry.isRegistrant(registrant), "Registrant role set");
        assertEq(l1BridgeRegistry.seigniorageCommittee(), seigniorageCommittee, "SeigniorageCommittee set");
    }

    // ==========================================
    // View Functions - Default Values
    // ==========================================

    function test_rollupType_defaultZero() public view {
        assertEq(l1BridgeRegistry.rollupType(address(0x1234)), 0, "Default type is 0");
    }

    function test_l2TON_defaultZero() public view {
        assertEq(l1BridgeRegistry.l2TON(address(0x1234)), address(0), "Default l2TON is zero");
    }

    function test_isRejectedSeigs_defaultFalse() public view {
        assertFalse(l1BridgeRegistry.isRejectedSeigs(address(0x1234)), "Default rejectedSeigs is false");
    }

    function test_isRejectedL2Deposit_defaultFalse() public view {
        assertFalse(l1BridgeRegistry.isRejectedL2Deposit(address(0x1234)), "Default rejectedL2Deposit is false");
    }

    function test_disputeGameFactory_defaultFalse() public view {
        assertFalse(l1BridgeRegistry.disputeGameFactory(address(0x1234)), "Default factory is false");
    }

    function test_rollupConfigWithDisputeGameFactory_defaultZero() public view {
        assertEq(
            l1BridgeRegistry.rollupConfigWithDisputeGameFactory(address(0x1234)),
            address(0),
            "Default rollupConfig is zero"
        );
    }

    // ==========================================
    // TYPE 1 Registration Tests
    // ==========================================

    function test_registerType1_byManager() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(systemConfigType1),
            1, // TYPE 1
            l2TON,
            "TestL2Type1"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType1)), 1, "Type should be 1");
        assertEq(l1BridgeRegistry.l2TON(address(systemConfigType1)), l2TON, "l2TON should be set");

        (uint8 type_, address l2TON_, bool rejectedSeigs_, bool rejectedL2Deposit_, string memory name_) =
            l1BridgeRegistry.getRollupInfo(address(systemConfigType1));

        assertEq(type_, 1);
        assertEq(l2TON_, l2TON);
        assertFalse(rejectedSeigs_);
        assertFalse(rejectedL2Deposit_);
        assertEq(name_, "TestL2Type1");
    }

    function test_registerType1_byRegistrant() public {
        vm.prank(registrant);
        l1BridgeRegistry.registerRollupConfig(
            address(systemConfigType1),
            1,
            l2TON,
            "TestL2Type1Registrant"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType1)), 1);
    }

    function test_registerType1_revertUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not a registrant");
        l1BridgeRegistry.registerRollupConfig(address(systemConfigType1), 1, l2TON, "Test");
    }

    // ==========================================
    // TYPE 2 Registration Tests
    // ==========================================

    function test_registerType2_byManager() public {
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

    function test_registerType2_revertZeroL2TON() public {
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 4));
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, address(0), "Test");
    }

    function test_registerType2_revertAlreadyRegistered() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 2));
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test2");
    }

    // ==========================================
    // TYPE 3 Registration Tests
    // ==========================================

    function test_registerType3_byManager() public {
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

    function test_registerType3_revertNoDisputeGameFactory() public {
        // SystemConfig without DisputeGameFactory
        MockSystemConfig configNoFactory = new MockSystemConfig();
        configNoFactory.setL1StandardBridge(address(0x6001));
        configNoFactory.setOptimismPortal(address(0x6002));
        // No disputeGameFactory set

        // _availableForRegistration checks first, so RegisterError(3) is returned
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(RegisterError.selector, 3));
        l1BridgeRegistry.registerRollupConfigByManager(address(configNoFactory), 3, l2TON, "Test");
    }

    function test_registerType3_revertInvalidType() public {
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

    function test_setTypeRegistrant_byManager() public {
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        assertEq(l1BridgeRegistry.typeRegistrant(3), type3Registrant, "Type3 registrant should be set");
    }

    function test_setTypeRegistrant_revertUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not a manager");
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);
    }

    function test_registerByType_withTypeRegistrant() public {
        // Set type3Registrant for TYPE 3
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        // type3Registrant can register TYPE 3
        vm.prank(type3Registrant);
        l1BridgeRegistry.registerRollupConfigByType(
            address(systemConfigType3),
            3,
            l2TON,
            "TestByTypeRegistrant"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType3)), 3);
    }

    function test_registerByType_managerCanAlwaysRegister() public {
        // Set type3Registrant for TYPE 3
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        // Manager can still register TYPE 3 even with typeRegistrant set
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByType(
            address(systemConfigType3),
            3,
            l2TON,
            "TestByManager"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigType3)), 3);
    }

    function test_registerByType_revertWrongTypeRegistrant() public {
        // Set type3Registrant for TYPE 3
        vm.prank(manager);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);

        // type3Registrant cannot register TYPE 2
        vm.prank(type3Registrant);
        vm.expectRevert(L1BridgeRegistryV1_2.NotAuthorizedError.selector);
        l1BridgeRegistry.registerRollupConfigByType(
            address(systemConfigType2),
            2,
            l2TON,
            "Test"
        );
    }

    function test_registerByType_noRegistrantSetRequiresManager() public {
        // No typeRegistrant set for TYPE 2 - only manager can register
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

    function test_upgradeToType3_fromType2() public {
        // First register as TYPE 2
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(systemConfigForUpgrade),
            2,
            l2TON,
            "UpgradeTest"
        );

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigForUpgrade)), 2);

        // Upgrade to TYPE 3
        vm.prank(manager);
        l1BridgeRegistry.upgradeToType3(address(systemConfigForUpgrade));

        assertEq(l1BridgeRegistry.rollupType(address(systemConfigForUpgrade)), 3);
        assertTrue(l1BridgeRegistry.disputeGameFactory(address(systemConfigForUpgrade)));
        assertEq(
            l1BridgeRegistry.rollupConfigWithDisputeGameFactory(disputeGameFactory2),
            address(systemConfigForUpgrade)
        );
    }

    function test_upgradeToType3_fromType1() public {
        // Create TYPE 1 config with all necessary fields for upgrade
        MockSystemConfig configType1ForUpgrade = new MockSystemConfig();
        configType1ForUpgrade.setL1StandardBridge(address(0x7001));
        configType1ForUpgrade.setOptimismPortal(address(0x7002));
        configType1ForUpgrade.setDisputeGameFactory(address(0x7003));

        // Register as TYPE 1
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(
            address(configType1ForUpgrade),
            1,
            l2TON,
            "Type1UpgradeTest"
        );

        // Upgrade to TYPE 3
        vm.prank(manager);
        l1BridgeRegistry.upgradeToType3(address(configType1ForUpgrade));

        assertEq(l1BridgeRegistry.rollupType(address(configType1ForUpgrade)), 3);
    }

    function test_upgradeToType3_revertNotRegistered() public {
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(L1BridgeRegistryV1_2.UpgradeError.selector, 1));
        l1BridgeRegistry.upgradeToType3(address(systemConfigType3));
    }

    function test_upgradeToType3_revertAlreadyType3() public {
        // Register as TYPE 3
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType3), 3, l2TON, "Test");

        // Try to upgrade again
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(L1BridgeRegistryV1_2.UpgradeError.selector, 2));
        l1BridgeRegistry.upgradeToType3(address(systemConfigType3));
    }

    function test_upgradeToType3_revertNoDisputeGameFactory() public {
        // Register TYPE 2 (has portal but no disputeGameFactory)
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        // Try to upgrade - should fail because no disputeGameFactory
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(L1BridgeRegistryV1_2.UpgradeError.selector, 3));
        l1BridgeRegistry.upgradeToType3(address(systemConfigType2));
    }

    function test_upgradeToType3_revertUnauthorized() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigForUpgrade), 2, l2TON, "Test");

        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not a manager");
        l1BridgeRegistry.upgradeToType3(address(systemConfigForUpgrade));
    }

    // ==========================================
    // rejectCandidateAddOn Tests
    // Note: Full reject/restore tests require Layer2 registration with Layer2Manager
    // These tests are simplified to test permission checks only
    // ==========================================

    function test_rejectCandidateAddOn_revertUnauthorized() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        vm.prank(unauthorized);
        vm.expectRevert("PermissionError");
        l1BridgeRegistry.rejectCandidateAddOn(address(systemConfigType2));
    }

    function test_rejectCandidateAddOn_revertNotRegistered() public {
        vm.prank(seigniorageCommittee);
        vm.expectRevert("NonRegistered");
        l1BridgeRegistry.rejectCandidateAddOn(address(systemConfigType2));
    }

    // ==========================================
    // restoreCandidateAddOn Tests
    // ==========================================

    function test_restoreCandidateAddOn_revertNotRejected() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        vm.prank(seigniorageCommittee);
        vm.expectRevert(OnlyRejectedError.selector);
        l1BridgeRegistry.restoreCandidateAddOn(address(systemConfigType2), false);
    }

    // ==========================================
    // availableForRegistration Tests
    // ==========================================

    function test_availableForRegistration_type1() public view {
        assertTrue(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType1), 1),
            "Type1 should be available"
        );
    }

    function test_availableForRegistration_type2() public view {
        assertTrue(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType2), 2),
            "Type2 should be available"
        );
    }

    function test_availableForRegistration_type3() public view {
        assertTrue(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType3), 3),
            "Type3 should be available"
        );
    }

    function test_availableForRegistration_falseAfterRegistered() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        assertFalse(
            l1BridgeRegistry.availableForRegistration(address(systemConfigType2), 2),
            "Should not be available after registration"
        );
    }

    function test_availableForRegistration_falseWhenPortalUsed() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        // New config using same portal should not be available
        MockSystemConfig newConfig = new MockSystemConfig();
        newConfig.setL1StandardBridge(address(0x8001));
        newConfig.setOptimismPortal(portal1); // Same portal as systemConfigType2

        assertFalse(
            l1BridgeRegistry.availableForRegistration(address(newConfig), 2),
            "Should not be available when portal already used"
        );
    }

    // ==========================================
    // getRollupInfo Tests
    // ==========================================

    function test_getRollupInfo_complete() public {
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

    function test_setAddresses_revertAlreadyInitialized() public {
        // Already initialized in setUp
        vm.expectRevert("already initialized");
        l1BridgeRegistry.setAddresses(address(0x1), address(0x2), address(0x3));
    }

    // ==========================================
    // setSeigniorageCommittee Tests
    // ==========================================

    function test_setSeigniorageCommittee_success() public {
        address newCommittee = address(0xABCD);
        l1BridgeRegistry.setSeigniorageCommittee(newCommittee);
        assertEq(l1BridgeRegistry.seigniorageCommittee(), newCommittee);
    }

    function test_setSeigniorageCommittee_revertSame() public {
        vm.expectRevert(bytes("same"));
        l1BridgeRegistry.setSeigniorageCommittee(seigniorageCommittee);
    }

    function test_setSeigniorageCommittee_revertUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert("AuthControl: Caller is not an admin");
        l1BridgeRegistry.setSeigniorageCommittee(address(0xABCD));
    }

    // ==========================================
    // rejectRollupConfig (alias) Tests
    // ==========================================

    function test_rejectRollupConfig_alias_defaultFalse() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "Test");

        // Default should be false
        assertFalse(l1BridgeRegistry.rejectRollupConfig(address(systemConfigType2)));
    }

    // ==========================================
    // Event Emission Tests
    // ==========================================

    function test_event_RegisteredRollupConfig() public {
        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit L1BridgeRegistryV1_2.RegisteredRollupConfig(address(systemConfigType2), 2, l2TON, "EventTest");
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigType2), 2, l2TON, "EventTest");
    }

    function test_event_TypeRegistrantSet() public {
        vm.prank(manager);
        vm.expectEmit(true, true, false, false);
        emit L1BridgeRegistryV1_2.TypeRegistrantSet(3, type3Registrant);
        l1BridgeRegistry.setTypeRegistrant(3, type3Registrant);
    }

    function test_event_UpgradedToType3() public {
        vm.prank(manager);
        l1BridgeRegistry.registerRollupConfigByManager(address(systemConfigForUpgrade), 2, l2TON, "Test");

        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit L1BridgeRegistryV1_2.UpgradedToType3(address(systemConfigForUpgrade), 2, portal3, disputeGameFactory2);
        l1BridgeRegistry.upgradeToType3(address(systemConfigForUpgrade));
    }

    // Note: RejectedCandidateAddOn and RestoredCandidateAddOn event tests require
    // Layer2 to be registered with Layer2Manager - tested in E2E tests
}
