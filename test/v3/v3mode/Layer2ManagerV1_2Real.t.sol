// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";

/// @title Layer2ManagerV3RealTest
/// @notice 실제 컨트랙트를 사용한 Layer2ManagerV3 테스트
/// @dev DeployV3Full을 활용하여 전체 시스템 배포 후 테스트

contract Layer2ManagerV3RealTest is Test, DeployV3Full {
    // 주요 컨트랙트 참조
    Layer2ManagerV3 public layer2Manager;
    L1BridgeRegistryV1_2 public l1BridgeRegistry;

    address public admin;  // TransparentUpgradeableProxy의 admin (관리 함수만 호출)
    address public owner;  // 비즈니스 로직 owner (구현체 함수 호출)
    address public rollupConfig1 = address(0x3001);
    address public layer2_1 = address(0x5001);
    address public operator1 = address(0x4001);

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

        // 주요 컨트랙트 참조
        layer2Manager = Layer2ManagerV3(layer2ManagerProxy);
        l1BridgeRegistry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);

        vm.stopPrank();
    }

    // ==========================================
    // 배포 상태 테스트
    // ==========================================

    /// @notice L2M-001: Layer2Manager 초기화 상태 확인
    function test_L2M001_layer2Manager_initialized() public view {
        // 필수 컨트랙트 연결 확인
        assertEq(layer2Manager.l1BridgeRegistry(), l1BridgeRegistryProxy, "L1BridgeRegistry connected");
        assertEq(layer2Manager.ton(), ton, "TON connected");
        assertEq(layer2Manager.wton(), wton, "WTON connected");
        assertEq(layer2Manager.depositManager(), depositManagerProxy, "DepositManager connected");
        assertEq(layer2Manager.seigManager(), seigManagerProxy, "SeigManager connected");
        assertEq(layer2Manager.operatorManagerFactory(), operatorManagerFactory, "OperatorManagerFactory connected");
    }

    // ==========================================
    // getBridgedTon Tests
    // ==========================================

    /// @notice L2M-002: 미등록 rollupConfig의 getBridgedTon은 0 반환
    function test_L2M002_getBridgedTon_unregisteredRollup() public view {
        uint256 bridgedTON = layer2Manager.getBridgedTon(rollupConfig1);
        assertEq(bridgedTON, 0, "Unregistered rollupConfig should return 0");
    }

    // ==========================================
    // getBridgedTonByLayer Tests
    // ==========================================

    /// @notice L2M-003: operator 없는 layer2의 getBridgedTonByLayer는 0 반환
    function test_L2M003_getBridgedTonByLayer_noOperator() public view {
        uint256 bridgedTON = layer2Manager.getBridgedTonByLayer(layer2_1);
        assertEq(bridgedTON, 0, "No operator should return 0");
    }

    // ==========================================
    // getLayer2BySystemConfig Tests
    // ==========================================

    /// @notice L2M-004: 미등록 systemConfig의 getLayer2BySystemConfig는 address(0) 반환
    function test_L2M004_getLayer2BySystemConfig_unregistered() public view {
        address layer2 = layer2Manager.getLayer2BySystemConfig(rollupConfig1);
        assertEq(layer2, address(0), "Unregistered should return address(0)");
    }
}
