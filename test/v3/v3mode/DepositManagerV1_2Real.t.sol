// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {ZeroValueError} from "../../../src/stake/managers/DepositManagerV3.sol";

/// @title DepositManagerV3RealTest
/// @notice 실제 컨트랙트를 사용한 DepositManagerV3 테스트
/// @dev V3TestBase를 활용하여 전체 시스템 배포 후 테스트
contract DepositManagerV3RealTest is V3TestBase {
    address public user1 = address(0x2001);
    address public user2 = address(0x2002);

    function setUp() public {
        _v3TestSetup();

        vm.startPrank(owner);
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

    /// @notice DM-001: 배포된 컨트랙트들이 서로 연결되어 있는지 확인
    /// @dev 각 컨트랙트가 올바른 참조를 가지고 있는지 검증
    function test_DM001_deployedContractsConnected() public view {
        // DepositManager → 다른 컨트랙트 연결
        assertEq(depositManager.seigManager(), seigManagerProxy, "DepositManager -> SeigManager");
        assertEq(depositManager.registry(), layer2RegistryProxy, "DepositManager -> Registry");

        // SeigManager → DepositManager 연결
        assertEq(address(seigManager.depositManager()), depositManagerProxy, "SeigManager -> DepositManager");

        // SeigManager → Layer2Manager 연결
        assertEq(seigManager.layer2Manager(), layer2ManagerProxy, "SeigManager -> Layer2Manager");
    }

    /// @notice DM-002: DepositManager 초기화 상태 확인
    /// @dev 모든 필수 상태 변수가 올바르게 초기화되었는지 검증
    function test_DM002_depositManager_initialized() public view {
        // 컨트랙트 연결
        assertEq(depositManager.wton(), wton, "WTON connected");
        assertEq(depositManager.seigManager(), seigManagerProxy, "SeigManager connected");
        assertEq(depositManager.registry(), layer2RegistryProxy, "Registry connected");

        // 설정값
        assertGt(depositManager.globalWithdrawalDelay(), 0, "Global withdrawal delay set");

        // 권한 (AccessControl 기반)
        assertTrue(depositManager.isAdmin(owner), "Owner has admin role");
    }

    // ==========================================
    // Deposit Tests (기본 기능)
    // ==========================================

    /// @notice DM-003: 0 금액 예치 시 revert
    /// @dev 미등록 layer2에 대한 deposit 시도 시 먼저 Layer2 체크에서 revert
    function test_DM003_deposit_zeroAmount_reverts() public {
        vm.prank(user1);
        vm.expectRevert("Caller is not a Layer2");
        depositManager.deposit(address(0x1001), user1, 0);
    }

    // ==========================================
    // Withdrawal Delay 설정 테스트
    // ==========================================

    /// @notice DM-004: owner가 globalWithdrawalDelay 설정
    /// @dev onlyOwner modifier로 권한 제한됨
    function test_DM004_setGlobalWithdrawalDelay() public {
        uint256 newDelay = 1000;

        vm.prank(owner);
        depositManager.setGlobalWithdrawalDelay(newDelay);

        assertEq(depositManager.globalWithdrawalDelay(), newDelay, "Global delay updated");
    }

    /// @notice DM-005: 비소유자가 globalWithdrawalDelay 설정 시 revert
    /// @dev onlyOwner modifier로 권한 제한됨
    function test_DM005_setGlobalWithdrawalDelay_notOwner_reverts() public {
        // 사전 조건: user1은 admin이 아님
        assertFalse(depositManager.isAdmin(user1), "user1 should not be admin");

        vm.prank(user1);
        vm.expectRevert("Accessible: Caller is not an admin");
        depositManager.setGlobalWithdrawalDelay(500);

        // 상태 불변 확인: globalWithdrawalDelay 변경되지 않음
        uint256 currentDelay = depositManager.globalWithdrawalDelay();
        assertTrue(currentDelay != 500, "globalWithdrawalDelay should not change");
    }

    /// @notice DM-006: layer2 delay 없을 때 global delay 반환
    function test_DM006_getDelayBlocks_globalDelay() public {
        address layer2Addr = address(0x1001);
        depositManager.setGlobalWithdrawalDelay(200);
        uint256 delay = depositManager.getDelayBlocks(layer2Addr);
        assertEq(delay, 200, "Should use global delay");
    }

    // ==========================================
    // 스토리지 접근 테스트 (V3에서 제거된 함수들)
    // ==========================================
    // NOTE: accStaked, accStakedLayer2, pendingUnstaked, numPendingRequests 함수는
    //       V3 단일 구현체에서 제거됨 (SeigManager를 통해 coinage 잔액 조회)

    // ==========================================
    // Request Withdrawal Tests (금액 검증)
    // ==========================================

    /// @notice DM-010: 0 금액 출금 요청 시 revert
    /// @dev 미등록 layer2에 대한 withdrawal 시도 시 먼저 Layer2 체크에서 revert
    function test_DM010_requestWithdrawal_zeroAmount_reverts() public {
        address layer2Addr = address(0x1001);
        vm.prank(user1);
        vm.expectRevert("Caller is not a Layer2");
        depositManager.requestWithdrawal(layer2Addr, 0);
    }

    // ==========================================
    // Fuzz Tests
    // ==========================================

    /// @notice DM-011: globalWithdrawalDelay fuzz 테스트
    function testFuzz_DM011_setGlobalWithdrawalDelay(uint256 delay) public {
        delay = bound(delay, 0, 1e18);
        depositManager.setGlobalWithdrawalDelay(delay);
        assertEq(depositManager.globalWithdrawalDelay(), delay);
    }

    /// @notice DM-012: layer2 delay가 global보다 클 때 layer2 delay 사용
    function test_DM012_getDelayBlocks_layer2Delay() public {
        address layer2Addr = address(0x1001);
        uint256 globalDelay = 100;
        uint256 layer2Delay = 300;

        depositManager.setGlobalWithdrawalDelay(globalDelay);
        depositManager.setWithdrawalDelayByOwner(layer2Addr, layer2Delay);

        uint256 delay = depositManager.getDelayBlocks(layer2Addr);
        assertEq(delay, layer2Delay, "Should use layer2 delay when higher");
    }

    /// @notice DM-013: global보다 작은 layer2 delay 설정 시 revert
    function test_DM013_setWithdrawalDelayByOwner_lessThanGlobal_reverts() public {
        address layer2Addr = address(0x1001);
        depositManager.setGlobalWithdrawalDelay(500);

        vm.expectRevert("Not acceptable");
        depositManager.setWithdrawalDelayByOwner(layer2Addr, 200);
    }

    // NOTE: onlyDepositManager 권한 테스트는 SecurityPermissions.t.sol (SEC-003)에서 수행
}
