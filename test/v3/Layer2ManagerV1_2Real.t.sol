// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../script/DeployV3Full.s.sol";

/// @title Layer2ManagerV1_2RealTest
/// @notice 실제 컨트랙트를 사용한 Layer2ManagerV1_2 테스트
/// @dev DeployV3Full을 활용하여 전체 시스템 배포 후 테스트

contract Layer2ManagerV1_2RealTest is Test, DeployV3Full {
    // 주요 컨트랙트 참조
    Layer2ManagerV1_2 public layer2Manager;
    L1BridgeRegistryV1_2 public l1BridgeRegistry;

    address public owner;
    address public rollupConfig1 = address(0x3001);
    address public layer2_1 = address(0x5001);
    address public operator1 = address(0x4001);

    function setUp() public {
        owner = address(this);

        // 직접 배포 (this가 owner가 됨)
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

        // 주요 컨트랙트 참조
        layer2Manager = Layer2ManagerV1_2(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);
    }

    // ==========================================
    // 배포 상태 테스트
    // ==========================================

    function test_deployedContractsConnected() public view {
        assertTrue(layer2ManagerProxy != address(0), "Layer2Manager deployed");
        assertTrue(l1BridgeRegistryProxy != address(0), "L1BridgeRegistry deployed");
        assertTrue(seigManagerProxy != address(0), "SeigManager deployed");
    }

    function test_layer2Manager_initialized() public view {
        assertEq(layer2Manager.l1BridgeRegistry(), l1BridgeRegistryProxy, "L1BridgeRegistry connected");
        assertEq(layer2Manager.ton(), ton, "TON connected");
    }

    // ==========================================
    // getBridgedTON Tests
    // ==========================================

    function test_getBridgedTON_unregisteredRollup() public view {
        // 등록되지 않은 rollupConfig는 0 반환
        uint256 bridgedTON = layer2Manager.getBridgedTON(rollupConfig1);
        assertEq(bridgedTON, 0, "Unregistered rollupConfig should return 0");
    }

    // ==========================================
    // getBridgedTONByLayer Tests
    // ==========================================

    function test_getBridgedTONByLayer_noOperator() public view {
        // operator 없는 layer2는 0 반환
        uint256 bridgedTON = layer2Manager.getBridgedTONByLayer(layer2_1);
        assertEq(bridgedTON, 0, "No operator should return 0");
    }

    // ==========================================
    // getLayer2BySystemConfig Tests
    // ==========================================

    function test_getLayer2BySystemConfig_unregistered() public view {
        // 등록되지 않은 systemConfig는 address(0) 반환
        address layer2 = layer2Manager.getLayer2BySystemConfig(rollupConfig1);
        assertEq(layer2, address(0), "Unregistered should return address(0)");
    }

}
