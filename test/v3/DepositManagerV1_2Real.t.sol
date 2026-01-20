// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../script/DeployV3Full.s.sol";

/// @title DepositManagerV1_2RealTest
/// @notice 실제 컨트랙트를 사용한 DepositManagerV1_2 테스트
/// @dev DeployV3Full을 활용하여 전체 시스템 배포 후 테스트

contract DepositManagerV1_2RealTest is Test, DeployV3Full {
    // 주요 컨트랙트 참조
    DepositManager public depositManager;
    DepositManagerV1_2 public depositManagerV1_2;
    SeigManagerV1_4 public seigManager;
    Layer2ManagerV1_2 public layer2Manager;

    address public admin;  // TransparentUpgradeableProxy의 admin (관리 함수만 호출)
    address public owner;  // 비즈니스 로직 owner (구현체 함수 호출)
    address public user1 = address(0x2001);
    address public user2 = address(0x2002);

    uint256 constant RAY = 1e27;

    function setUp() public {
        // TransparentUpgradeableProxy 패턴:
        // - admin: upgradeTo(), changeAdmin() 같은 관리 함수만 호출 가능
        // - non-admin: 구현체의 비즈니스 로직 함수 호출 가능
        admin = address(0x9999);  // Proxy admin 전용
        owner = address(this);    // 비즈니스 로직 owner (구현체 함수 호출)

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

        // RAT, ValidatorReward를 owner로 배포 (임시로 owner가 proxy admin + contract owner)
        _deployV3Contracts(owner);

        // RAT, ValidatorReward의 proxy admin만 admin으로 변경 (contract owner는 owner 유지)
        RATProxy(payable(ratProxy)).changeAdmin(admin);
        ValidatorRewardProxy(payable(validatorPoolProxy)).changeAdmin(admin);

        // 이제 admin = proxy admin, owner = contract owner로 분리됨
        _configureV3Contracts(owner);
        _setupCrossReferences(owner);

        // 주요 컨트랙트 참조
        depositManager = DepositManager(depositManagerProxy);
        depositManagerV1_2 = DepositManagerV1_2(depositManagerProxy);
        seigManager = SeigManagerV1_4(seigManagerProxy);
        layer2Manager = Layer2ManagerV1_2(layer2ManagerProxy);

        // Give users WTON
        MockWTON(wton).mint(user1, 10000e27);
        MockWTON(wton).mint(user2, 10000e27);

        vm.stopPrank();

        // Approve
        vm.prank(user1);
        MockWTON(wton).approve(depositManagerProxy, type(uint256).max);
        vm.prank(user2);
        MockWTON(wton).approve(depositManagerProxy, type(uint256).max);
    }

    // ==========================================
    // 배포 상태 테스트
    // ==========================================

    function test_deployedContractsConnected() public view {
        // 배포된 컨트랙트들이 서로 연결되어 있는지 확인
        assertTrue(depositManagerProxy != address(0), "DepositManager deployed");
        assertTrue(seigManagerProxy != address(0), "SeigManager deployed");
        assertTrue(layer2ManagerProxy != address(0), "Layer2Manager deployed");
        assertTrue(layer2RegistryProxy != address(0), "Layer2Registry deployed");
    }

    function test_depositManager_initialized() public view {
        // DepositManager 초기화 상태 확인
        assertEq(address(depositManager.wton()), wton, "WTON connected");
        assertEq(address(depositManager.seigManager()), seigManagerProxy, "SeigManager connected");
    }

    // ==========================================
    // Deposit Tests (기본 기능)
    // ==========================================

    function test_deposit_zeroAmount_reverts() public {
        // layer2 필요 없이 테스트 가능 - 0 금액은 즉시 revert
        // 프록시를 통해 호출하면 revert reason이 전달되지 않을 수 있음
        vm.prank(user1);
        vm.expectRevert();
        depositManager.deposit(address(0x1001), user1, 0);
    }

    // ==========================================
    // Withdrawal Delay 설정 테스트
    // ==========================================

    function test_setGlobalWithdrawalDelay() public {
        uint256 newDelay = 1000;

        // owner가 설정
        depositManager.setGlobalWithdrawalDelay(newDelay);

        assertEq(depositManager.globalWithdrawalDelay(), newDelay, "Global delay updated");
    }

    function test_setGlobalWithdrawalDelay_notOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert();
        depositManager.setGlobalWithdrawalDelay(500);
    }

    function test_getDelayBlocks_globalDelay() public {
        address layer2 = address(0x1001);

        // globalWithdrawalDelay 설정
        depositManager.setGlobalWithdrawalDelay(200);

        // layer2 delay가 없으면 global delay 반환
        uint256 delay = depositManager.getDelayBlocks(layer2);
        assertEq(delay, 200, "Should use global delay");
    }

    // ==========================================
    // 스토리지 접근 테스트
    // ==========================================

    function test_accStaked_initialZero() public view {
        address layer2 = address(0x1001);

        // 초기 상태는 0
        assertEq(depositManager.accStaked(layer2, user1), 0, "Initial staked is zero");
        assertEq(depositManager.accStakedLayer2(layer2), 0, "Initial layer2 total is zero");
    }

    function test_pendingUnstaked_initialZero() public view {
        address layer2 = address(0x1001);

        // 초기 상태는 0
        assertEq(depositManager.pendingUnstaked(layer2, user1), 0, "Initial pending is zero");
    }

    function test_numPendingRequests_initialZero() public view {
        address layer2 = address(0x1001);

        // 초기 상태는 0
        assertEq(depositManager.numPendingRequests(layer2, user1), 0, "Initial requests is zero");
    }

    // ==========================================
    // Request Withdrawal Tests (금액 검증)
    // ==========================================

    function test_requestWithdrawal_zeroAmount_reverts() public {
        address layer2 = address(0x1001);

        // 프록시를 통해 호출하면 revert reason이 전달되지 않을 수 있음
        vm.prank(user1);
        vm.expectRevert();
        depositManagerV1_2.requestWithdrawal(layer2, 0);
    }

    // ==========================================
    // Fuzz Tests
    // ==========================================

    function testFuzz_setGlobalWithdrawalDelay(uint256 delay) public {
        delay = bound(delay, 0, 1e18);

        depositManager.setGlobalWithdrawalDelay(delay);
        assertEq(depositManager.globalWithdrawalDelay(), delay);
    }

    function test_getDelayBlocks_layer2Delay() public {
        address layer2 = address(0x1001);
        uint256 globalDelay = 100;
        uint256 layer2Delay = 300;

        depositManager.setGlobalWithdrawalDelay(globalDelay);

        // setWithdrawalDelayByOwner를 통해 layer2 delay 설정
        DepositManager_setWithdrawalDelay(depositManagerProxy).setWithdrawalDelayByOwner(layer2, layer2Delay);

        uint256 delay = depositManager.getDelayBlocks(layer2);

        // max(globalDelay, layer2Delay) = 300
        assertEq(delay, layer2Delay, "Should use layer2 delay when higher");
    }

    function test_getDelayBlocks_withLayer2Delay() public {
        address layer2 = address(0x1001);

        // setWithdrawalDelayByOwner는 withdrawalDelay_ > globalWithdrawalDelay 조건 필요
        depositManager.setGlobalWithdrawalDelay(100);
        DepositManager_setWithdrawalDelay(depositManagerProxy).setWithdrawalDelayByOwner(layer2, 600);

        uint256 delay = depositManager.getDelayBlocks(layer2);
        // max(100, 600) = 600
        assertEq(delay, 600, "Should use layer2 delay when higher");
    }

    function test_setWithdrawalDelayByOwner_lessThanGlobal_reverts() public {
        address layer2 = address(0x1001);

        // global보다 작은 layer2 delay 설정 시도 -> revert
        depositManager.setGlobalWithdrawalDelay(500);

        vm.expectRevert("Not acceptable");
        DepositManager_setWithdrawalDelay(depositManagerProxy).setWithdrawalDelayByOwner(layer2, 200);
    }
}
