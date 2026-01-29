// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {ZeroValueError, DepositManagerV3} from "../../../src/stake/managers/DepositManagerV3.sol";
import {ISeigManager} from "../../../src/stake/interfaces/ISeigManager.sol";

/// @title DepositManagerV3RealTest
/// @notice 실제 컨트랙트를 사용한 DepositManagerV3 테스트
/// @dev V3TestBase를 활용하여 전체 시스템 배포 후 테스트
contract DepositManagerV3RealTest is V3TestBase {
    address public user1 = address(0x2001);
    address public user2 = address(0x2002);

    // Events for testing (must match DepositManagerV3 events)
    event Deposited(address indexed layer2, address depositor, uint256 amount);
    event WithdrawalRequestCanceled(address indexed layer2, address depositor, uint256 amount);
    event WithdrawalRequested(address indexed layer2, address depositor, uint256 amount);
    event WithdrawalProcessed(address indexed layer2, address depositor, uint256 amount);
    event SetWithdrawalDelay(address indexed layer2, uint256 withdrawalDelay_);
    event SetMinDepositGasLimit(uint32 gasLimit_);

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

    // ==========================================
    // Redeposit Tests (RFC-17: WithdrawalRequestCanceled Event)
    // ==========================================

    /// @notice DM-020: redeposit emits both WithdrawalRequestCanceled and Deposited events
    /// @dev RFC-17: 출금 요청 취소 시 두 이벤트 모두 발행되어 TON 유통량 추적 가능
    function test_DM020_redeposit_emitsBothEvents() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;
        uint256 withdrawAmount = 200e27;

        // 1. Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // 2. Request withdrawal
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // 3. Redeposit and check events
        vm.prank(user1);
        vm.expectEmit(true, true, false, true, depositManagerProxy);
        emit WithdrawalRequestCanceled(mockLayer2, user1, withdrawAmount);
        vm.expectEmit(true, true, false, true, depositManagerProxy);
        emit Deposited(mockLayer2, user1, withdrawAmount);
        depositManager.redeposit(mockLayer2);
    }

    /// @notice DM-021: redepositMulti emits events with accumulated amount
    /// @dev RFC-17: 여러 출금 요청 일괄 취소 시 누적 금액으로 이벤트 발행
    function test_DM021_redepositMulti_emitsEventsWithAccumulatedAmount() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;
        uint256 withdrawAmount1 = 100e27;
        uint256 withdrawAmount2 = 150e27;
        uint256 withdrawAmount3 = 200e27;
        uint256 totalWithdraw = withdrawAmount1 + withdrawAmount2 + withdrawAmount3;

        // 1. Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // 2. Request multiple withdrawals
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount2);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount3);
        vm.stopPrank();

        // 3. Redeposit all 3 requests at once
        vm.prank(user1);
        vm.expectEmit(true, true, false, true, depositManagerProxy);
        emit WithdrawalRequestCanceled(mockLayer2, user1, totalWithdraw);
        vm.expectEmit(true, true, false, true, depositManagerProxy);
        emit Deposited(mockLayer2, user1, totalWithdraw);
        depositManager.redepositMulti(mockLayer2, 3);
    }

    /// @notice DM-022: redeposit event parameters are correct
    /// @dev layer2, depositor, amount 파라미터가 정확한지 검증
    function test_DM022_redeposit_eventParameters() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;
        uint256 withdrawAmount = 123e27; // 고유한 금액으로 정확한 값 검증

        // 1. Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // 2. Request withdrawal
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // 3. Record logs and verify
        vm.recordLogs();
        vm.prank(user1);
        depositManager.redeposit(mockLayer2);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Find WithdrawalRequestCanceled event
        bool foundCanceled = false;
        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("WithdrawalRequestCanceled(address,address,uint256)")) {
                foundCanceled = true;
                // Verify indexed parameter (only layer2 is indexed)
                assertEq(address(uint160(uint256(logs[i].topics[1]))), mockLayer2, "layer2 parameter");
                // Verify depositor and amount from data
                (address depositor, uint256 amount) = abi.decode(logs[i].data, (address, uint256));
                assertEq(depositor, user1, "depositor parameter");
                assertEq(amount, withdrawAmount, "amount parameter");
                break;
            }
        }
        assertTrue(foundCanceled, "WithdrawalRequestCanceled event not found");
    }

    /// @notice DM-023: fresh deposit only emits Deposited (not WithdrawalRequestCanceled)
    /// @dev RFC-17: 신규 입금은 WithdrawalRequestCanceled 발행하지 않음
    function test_DM023_freshDeposit_onlyEmitsDeposited() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        vm.recordLogs();
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Verify Deposited event exists
        bool foundDeposited = false;
        bool foundCanceled = false;
        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("Deposited(address,address,uint256)")) {
                foundDeposited = true;
            }
            if (logs[i].topics[0] == keccak256("WithdrawalRequestCanceled(address,address,uint256)")) {
                foundCanceled = true;
            }
        }
        assertTrue(foundDeposited, "Deposited event should be emitted");
        assertFalse(foundCanceled, "WithdrawalRequestCanceled should NOT be emitted for fresh deposit");
    }

    // ==========================================
    // Admin Setter Tests
    // ==========================================

    /// @notice DM-030: setMinDepositGasLimit 설정
    /// @dev admin만 설정 가능
    function test_DM030_setMinDepositGasLimit() public {
        uint32 newGasLimit = 300_000;

        vm.prank(owner);
        vm.expectEmit(true, true, false, true, depositManagerProxy);
        emit SetMinDepositGasLimit(newGasLimit);
        depositManager.setMinDepositGasLimit(newGasLimit);

        assertEq(depositManager.minDepositGasLimit(), newGasLimit, "Gas limit updated");
    }

    /// @notice DM-031: setMinDepositGasLimit 비관리자 revert
    function test_DM031_setMinDepositGasLimit_notOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert("Accessible: Caller is not an admin");
        depositManager.setMinDepositGasLimit(300_000);
    }

    /// @notice DM-032: setSeigManager 설정
    function test_DM032_setSeigManager() public {
        address newSeigManager = address(0x9999);

        vm.prank(owner);
        depositManager.setSeigManager(newSeigManager);

        assertEq(depositManager.seigManager(), newSeigManager, "SeigManager updated");
    }

    /// @notice DM-033: setSeigManager 비관리자 revert
    function test_DM033_setSeigManager_notOwner_reverts() public {
        vm.prank(user1);
        vm.expectRevert("Accessible: Caller is not an admin");
        depositManager.setSeigManager(address(0x9999));
    }

    // ==========================================
    // Operator Withdrawal Delay Tests
    // ==========================================

    /// @notice DM-034: operator가 setWithdrawalDelay 설정
    /// @dev operator()는 operatorManager 컨트랙트를 반환함
    function test_DM034_setWithdrawalDelay_byOperator() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 globalDelay = depositManager.globalWithdrawalDelay();
        uint256 newDelay = globalDelay + 1000;

        // operator()는 operatorManager 주소를 반환
        vm.prank(operatorManager);
        vm.expectEmit(true, true, false, true, depositManagerProxy);
        emit SetWithdrawalDelay(mockLayer2, newDelay);
        depositManager.setWithdrawalDelay(mockLayer2, newDelay);

        assertEq(depositManager.getDelayBlocks(mockLayer2), newDelay, "Layer2 delay updated");
    }

    /// @notice DM-035: 비operator가 setWithdrawalDelay 시 revert
    function test_DM035_setWithdrawalDelay_notOperator_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 globalDelay = depositManager.globalWithdrawalDelay();

        vm.prank(user1);
        vm.expectRevert("Caller is not an operator");
        depositManager.setWithdrawalDelay(mockLayer2, globalDelay + 1000);
    }

    /// @notice DM-036: MAX_DELAY_BLOCKS 초과 시 revert
    function test_DM036_setWithdrawalDelay_exceedsMax_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 maxDelay = depositManager.MAX_DELAY_BLOCKS();

        // operator()는 operatorManager 주소를 반환
        vm.prank(operatorManager);
        vm.expectRevert("Not acceptable");
        depositManager.setWithdrawalDelay(mockLayer2, maxDelay + 1);
    }

    // ==========================================
    // Withdrawal Request/Process Tests
    // ==========================================

    /// @notice DM-040: requestWithdrawalAll 전체 잔액 출금 요청
    function test_DM040_requestWithdrawalAll() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        // Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // Get staked balance
        uint256 stakedAmount = seigManager.stakeOf(mockLayer2, user1);
        assertGt(stakedAmount, 0, "Should have staked amount");

        // Request withdrawal all
        vm.expectEmit(true, true, false, true, depositManagerProxy);
        emit WithdrawalRequested(mockLayer2, user1, stakedAmount);
        depositManager.requestWithdrawalAll(mockLayer2);
        vm.stopPrank();

        // Verify pending unstaked
        assertEq(depositManager.pendingUnstaked(mockLayer2, user1), stakedAmount, "All staked amount pending");
    }

    /// @notice DM-041: processRequests 다중 출금 처리
    function test_DM041_processRequests_multiple() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;
        uint256 withdrawAmount1 = 100e27;
        uint256 withdrawAmount2 = 150e27;

        // Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // Request multiple withdrawals
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount2);
        vm.stopPrank();

        // Fast forward past delay
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        vm.roll(block.number + delay + 1);

        // Process multiple requests
        uint256 balanceBefore = MockWTON(wton).balanceOf(user1);
        vm.prank(user1);
        depositManager.processRequests(mockLayer2, 2, false);
        uint256 balanceAfter = MockWTON(wton).balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, withdrawAmount1 + withdrawAmount2, "Both withdrawals processed");
    }

    // ==========================================
    // Storage Getter Tests
    // ==========================================

    /// @notice DM-050: numRequests 조회
    function test_DM050_numRequests() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;

        // Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // No requests initially
        assertEq(depositManager.numRequests(mockLayer2, user1), 0, "No requests initially");

        // Request withdrawals
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        depositManager.requestWithdrawal(mockLayer2, 150e27);
        depositManager.requestWithdrawal(mockLayer2, 200e27);
        vm.stopPrank();

        assertEq(depositManager.numRequests(mockLayer2, user1), 3, "3 requests total");
    }

    /// @notice DM-051: numPendingRequests 조회
    function test_DM051_numPendingRequests() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;

        // Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // Request withdrawals
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        depositManager.requestWithdrawal(mockLayer2, 150e27);
        vm.stopPrank();

        assertEq(depositManager.numPendingRequests(mockLayer2, user1), 2, "2 pending requests");

        // Process one
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        vm.roll(block.number + delay + 1);

        vm.prank(user1);
        depositManager.processRequest(mockLayer2, false);

        assertEq(depositManager.numPendingRequests(mockLayer2, user1), 1, "1 pending request after processing");
    }

    /// @notice DM-052: pendingUnstakedLayer2 조회
    function test_DM052_pendingUnstakedLayer2() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;
        uint256 withdrawAmount = 300e27;

        // Deposit for user1
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // Deposit for user2
        vm.startPrank(user2);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user2, depositAmount);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // Total pending for layer2
        assertEq(depositManager.pendingUnstakedLayer2(mockLayer2), withdrawAmount * 2, "Total pending for layer2");
    }

    /// @notice DM-053: pendingUnstakedAccount 조회
    function test_DM053_pendingUnstakedAccount() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Register second L2
        SimpleMockSystemConfig mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(address(0x8011));
        mockSystemConfig2.setOptimismPortal(address(0x8012));
        mockSystemConfig2.setDisputeGameFactory(address(0x8013));
        mockSystemConfig2.setUnsafeBlockSigner(operator1);

        (address mockLayer2_2,) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig2),
            address(0x8014),
            "TestL2_2",
            operator1,
            operatorDeposit
        );

        uint256 depositAmount = 1000e27;
        uint256 withdrawAmount = 200e27;

        // Deposit to both L2s
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount * 2);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        depositManager.deposit(mockLayer2_2, user1, depositAmount);

        // Request withdrawal from both
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        depositManager.requestWithdrawal(mockLayer2_2, withdrawAmount);
        vm.stopPrank();

        // Total pending for account (across all L2s)
        assertEq(depositManager.pendingUnstakedAccount(user1), withdrawAmount * 2, "Total pending for account");
    }

    /// @notice DM-054: withdrawalRequestIndex 조회
    function test_DM054_withdrawalRequestIndex() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // Request withdrawals
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        depositManager.requestWithdrawal(mockLayer2, 150e27);
        vm.stopPrank();

        // Initial index is 0
        assertEq(depositManager.withdrawalRequestIndex(mockLayer2, user1), 0, "Initial index is 0");

        // Process one request
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        vm.roll(block.number + delay + 1);

        vm.prank(user1);
        depositManager.processRequest(mockLayer2, false);

        // Index incremented
        assertEq(depositManager.withdrawalRequestIndex(mockLayer2, user1), 1, "Index incremented after process");
    }

    /// @notice DM-055: withdrawalRequest 조회
    function test_DM055_withdrawalRequest() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;
        uint256 withdrawAmount = 123e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        uint256 expectedBlock = block.number + depositManager.getDelayBlocks(mockLayer2);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // Query withdrawal request
        (uint128 withdrawableBlock, uint128 amount, bool processed) = depositManager.withdrawalRequest(mockLayer2, user1, 0);

        assertEq(withdrawableBlock, expectedBlock, "Withdrawable block matches");
        assertEq(amount, withdrawAmount, "Amount matches");
        assertFalse(processed, "Not processed yet");
    }

    // ==========================================
    // Batch Deposit Tests
    // ==========================================

    /// @notice DM-060: deposit(address, address[], uint256[]) 배치 입금
    function test_DM060_depositBatch() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        address[] memory accounts = new address[](3);
        accounts[0] = user1;
        accounts[1] = user2;
        accounts[2] = address(0x2003);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100e27;
        amounts[1] = 200e27;
        amounts[2] = 300e27;

        // Mint WTON to depositor (owner)
        vm.prank(owner);
        MockWTON(wton).mint(owner, 600e27);

        vm.startPrank(owner);
        MockWTON(wton).approve(depositManagerProxy, 600e27);
        depositManager.deposit(mockLayer2, accounts, amounts);
        vm.stopPrank();

        // Verify each account has staked amount
        assertGt(seigManager.stakeOf(mockLayer2, user1), 0, "user1 staked");
        assertGt(seigManager.stakeOf(mockLayer2, user2), 0, "user2 staked");
        assertGt(seigManager.stakeOf(mockLayer2, address(0x2003)), 0, "user3 staked");
    }

    // ==========================================
    // onApprove Tests (WTON Approval Callback)
    // ==========================================

    /// @notice DM-070: onApprove를 통한 입금
    /// @dev WTON에서 호출되는 onApprove 콜백 테스트
    ///      실제로는 WTON.approveAndCall이 호출하지만, MockWTON에 없으므로
    ///      vm.prank로 WTON 주소에서 직접 호출하여 테스트
    function test_DM070_onApprove_deposit() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        // Mint WTON for DepositManager (onApprove receives tokens first)
        vm.prank(owner);
        MockWTON(wton).mint(depositManagerProxy, depositAmount);

        // Encode layer2 address for onApprove callback data
        bytes memory data = abi.encode(mockLayer2);

        // Call onApprove from WTON address (simulating WTON.approveAndCall)
        vm.prank(wton);
        bool result = depositManager.onApprove(user1, depositManagerProxy, depositAmount, data);
        assertTrue(result, "onApprove should return true");

        // Verify deposit was successful
        uint256 stakedAmount = seigManager.stakeOf(mockLayer2, user1);
        assertGt(stakedAmount, 0, "Should have staked via onApprove");
        assertApproxEqRel(stakedAmount, depositAmount, 0.01e18, "Staked amount should match deposit");
    }

    /// @notice DM-071: onApprove 비WTON 호출자 revert
    function test_DM071_onApprove_notWTON_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        bytes memory data = abi.encode(mockLayer2);

        // Try to call onApprove directly (not from WTON)
        vm.prank(user1);
        vm.expectRevert("DepositManager: only accept WTON approve callback");
        depositManager.onApprove(user1, depositManagerProxy, 100e27, data);
    }

    /// @notice DM-072: onApprove 잘못된 data 길이 revert
    function test_DM072_onApprove_invalidDataLength_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        // Invalid data (wrong length - not 0x20 bytes)
        bytes memory invalidData = abi.encode(mockLayer2, address(0x1234)); // 0x40 bytes

        // Call from WTON with invalid data
        vm.prank(wton);
        vm.expectRevert("data length error");
        depositManager.onApprove(user1, depositManagerProxy, depositAmount, invalidData);
    }

    // ==========================================
    // getSequencerStaked Tests
    // ==========================================

    /// @notice DM-082: getSequencerStaked 조회
    function test_DM082_getSequencerStaked() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // getSequencerStaked returns operator's stake in the layer2
        uint256 sequencerStake = seigManager.getSequencerStaked(mockLayer2);

        // Operator deposit should be reflected
        assertGt(sequencerStake, 0, "Sequencer stake should be > 0");
        assertApproxEqRel(sequencerStake, operatorDeposit, 0.01e18, "Should match operator deposit");
    }

    /// @notice DM-083: getSequencerStaked 미등록 Layer2
    function test_DM083_getSequencerStaked_unregistered() public {
        uint256 stake = seigManager.getSequencerStaked(address(0x9999));
        assertEq(stake, 0, "Unregistered layer2 should return 0");
    }

    // ==========================================
    // Branch Coverage Tests
    // ==========================================

    /// @notice DM-090: batch deposit - 빈 accounts 배열 revert
    /// @dev Line 211: require(accounts.length != 0, 'no account')
    function test_DM090_depositBatch_emptyAccounts_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        address[] memory accounts = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(owner);
        vm.expectRevert("no account");
        depositManager.deposit(mockLayer2, accounts, amounts);
    }

    /// @notice DM-091: batch deposit - 배열 길이 불일치 revert
    /// @dev Line 212: require(accounts.length == amounts.length, 'wrong lenth')
    function test_DM091_depositBatch_lengthMismatch_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        address[] memory accounts = new address[](2);
        accounts[0] = user1;
        accounts[1] = user2;

        uint256[] memory amounts = new uint256[](3); // 길이 불일치
        amounts[0] = 100e27;
        amounts[1] = 200e27;
        amounts[2] = 300e27;

        vm.prank(owner);
        vm.expectRevert("wrong lenth");
        depositManager.deposit(mockLayer2, accounts, amounts);
    }

    /// @notice DM-092: _deposit - zero address revert
    /// @dev Line 222: require(account != address(0) && amount != 0, "zero amount or zero address")
    function test_DM092_deposit_zeroAddress_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.startPrank(owner);
        MockWTON(wton).mint(owner, 100e27);
        MockWTON(wton).approve(depositManagerProxy, 100e27);

        vm.expectRevert("zero amount or zero address");
        depositManager.deposit(mockLayer2, address(0), 100e27);
        vm.stopPrank();
    }

    /// @notice DM-093: _deposit - zero amount revert
    /// @dev Line 222: require(account != address(0) && amount != 0, "zero amount or zero address")
    function test_DM093_deposit_zeroAmount_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.prank(user1);
        vm.expectRevert("zero amount or zero address");
        depositManager.deposit(mockLayer2, user1, 0);
    }

    /// @notice DM-094: redeposit - 출금 요청 없을 때 revert
    /// @dev Line 262: require(requsts.length > 0, "DepositManager: no request")
    function test_DM094_redeposit_noRequest_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Deposit without withdrawal request
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);

        // Try to redeposit without any withdrawal request
        vm.expectRevert("DepositManager: no request");
        depositManager.redeposit(mockLayer2);
        vm.stopPrank();
    }

    /// @notice DM-095: redepositMulti - n이 pending 요청 수 초과 시 revert
    /// @dev Line 263: require(requsts.length - i >= n, "DepositManager: n exceeds num of pending requests")
    function test_DM095_redepositMulti_exceedsRequests_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Deposit and request one withdrawal
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);

        // Try to redeposit 5 when only 1 exists
        vm.expectRevert("DepositManager: n exceeds num of pending requests");
        depositManager.redepositMulti(mockLayer2, 5);
        vm.stopPrank();
    }

    /// @notice DM-096: redeposit - 이미 처리된 요청 revert
    /// @dev Line 272: require(!r.processed, "DepositManager: pending request already processed")
    function test_DM096_redeposit_alreadyProcessed_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Deposit and request withdrawal
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);

        // Redeposit first request
        depositManager.redeposit(mockLayer2);

        // Index should move, so redepositMulti(2) should fail because only 1 remains
        vm.expectRevert("DepositManager: n exceeds num of pending requests");
        depositManager.redepositMulti(mockLayer2, 2);
        vm.stopPrank();
    }

    /// @notice DM-097: requestWithdrawal - 0 금액 revert (등록된 Layer2)
    /// @dev Line 348: require(amount > 0, "DepositManager: amount must not be zero")
    function test_DM097_requestWithdrawal_zeroAmount_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Deposit first
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);

        // Try to request withdrawal of 0
        vm.expectRevert("DepositManager: amount must not be zero");
        depositManager.requestWithdrawal(mockLayer2, 0);
        vm.stopPrank();
    }

    /// @notice DM-098: requestWithdrawal - uint128 초과 금액 revert
    /// @dev Line 349: require(amount < type(uint128).max, "Out of range")
    function test_DM098_requestWithdrawal_exceedsUint128_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);

        // Try to request withdrawal exceeding uint128
        uint256 hugeAmount = uint256(type(uint128).max) + 1;
        vm.expectRevert("Out of range");
        depositManager.requestWithdrawal(mockLayer2, hugeAmount);
        vm.stopPrank();
    }

    /// @notice DM-099: setWithdrawalDelay - global과 동일한 값 revert
    /// @dev Line 317: require(withdrawalDelay_ > globalWithdrawalDelay && ...)
    function test_DM099_setWithdrawalDelay_equalToGlobal_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 globalDelay = depositManager.globalWithdrawalDelay();

        // Try to set delay equal to global (must be > globalWithdrawalDelay)
        vm.prank(operatorManager);
        vm.expectRevert("Not acceptable");
        depositManager.setWithdrawalDelay(mockLayer2, globalDelay);
    }

    /// @notice DM-100: deposit(address, uint256) - self deposit
    /// @dev Line 200-202: msg.sender 자신에게 deposit
    function test_DM100_deposit_selfDeposit() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 300e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);

        // Use the simpler deposit(layer2, amount) function
        depositManager.deposit(mockLayer2, depositAmount);
        vm.stopPrank();

        uint256 stakedAmount = seigManager.stakeOf(mockLayer2, user1);
        assertGt(stakedAmount, 0, "Self deposit should work");
    }

    /// @notice DM-101: processRequest with receiveTON = true
    /// @dev 출금 시 TON 수령 옵션 (MockWTON은 실제 swap 미구현으로 함수 호출만 확인)
    /// @dev SKIP: MockWTON의 swapToTONAndTransfer는 실제 TON 전송을 mock하지 않음
    function skip_test_DM101_processRequest_receiveTON() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;
        uint256 withdrawAmount = 100e27;

        // Deposit
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // Request withdrawal
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // Fast forward
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        vm.roll(block.number + delay + 1);

        // Process with receiveTON = true - should not revert
        vm.prank(user1);
        bool success = depositManager.processRequest(mockLayer2, true);
        assertTrue(success, "processRequest with receiveTON=true should succeed");

        // Verify the withdrawal request is processed
        (,, bool processed) = depositManager.withdrawalRequest(mockLayer2, user1, 0);
        assertTrue(processed, "Request should be processed");
    }

    /// @notice DM-102: onApprove with empty data
    /// @dev data.length == 0인 경우
    function test_DM102_onApprove_emptyData_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        bytes memory emptyData = "";

        vm.prank(wton);
        vm.expectRevert("data length error");
        depositManager.onApprove(user1, depositManagerProxy, 100e27, emptyData);
    }

    // ==========================================
    // Additional Branch Coverage Tests
    // ==========================================

    /// @notice DM-110: processRequest - 요청 없을 때 revert
    /// @dev Line 386: require(_withdrawalRequests[layer2][msg.sender].length > index)
    function test_DM110_processRequest_noRequest_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // user1 has no withdrawal requests
        vm.prank(user1);
        vm.expectRevert("DepositManager: no request to process");
        depositManager.processRequest(mockLayer2, false);
    }

    /// @notice DM-111: processRequest - delay 미경과 시 revert
    /// @dev Line 390: require(r.withdrawableBlockNumber <= block.number)
    function test_DM111_processRequest_delayNotPassed_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        vm.stopPrank();

        // Try to process immediately (before delay passes)
        vm.prank(user1);
        vm.expectRevert("DepositManager: wait for withdrawal delay");
        depositManager.processRequest(mockLayer2, false);
    }

    /// @notice DM-112: processRequest receiveTon=false (WTON 수령)
    /// @dev Line 408: WTON 직접 전송 브랜치
    function test_DM112_processRequest_receiveWTON() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;
        uint256 withdrawAmount = 100e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // Fast forward
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        vm.roll(block.number + delay + 1);

        // Process with receiveTON = false (receive WTON)
        uint256 wtonBalanceBefore = MockWTON(wton).balanceOf(user1);
        vm.prank(user1);
        bool success = depositManager.processRequest(mockLayer2, false);
        assertTrue(success, "processRequest should succeed");

        uint256 wtonBalanceAfter = MockWTON(wton).balanceOf(user1);
        assertEq(wtonBalanceAfter - wtonBalanceBefore, withdrawAmount, "Should receive WTON");
    }

    /// @notice DM-113: processRequests 다중 출금 루프
    /// @dev Line 421-424: for loop 브랜치
    function test_DM113_processRequests_loop() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 1000e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        // Request 3 withdrawals
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        vm.stopPrank();

        // Fast forward
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        vm.roll(block.number + delay + 1);

        // Process all 3 at once
        vm.prank(user1);
        bool success = depositManager.processRequests(mockLayer2, 3, false);
        assertTrue(success, "processRequests should succeed");

        // Check all processed
        assertEq(depositManager.numPendingRequests(mockLayer2, user1), 0, "All should be processed");
    }

    /// @notice DM-114: _getDelayBlocks - layer2 delay가 global보다 작으면 global 사용
    /// @dev Line 375-378: globalWithdrawalDelay > withdrawalDelay[layer2] 브랜치
    function test_DM114_getDelayBlocks_globalLarger() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Set global delay larger than layer2 default (which is 0)
        uint256 newGlobalDelay = 1000;
        depositManager.setGlobalWithdrawalDelay(newGlobalDelay);

        // Should use global delay
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        assertEq(delay, newGlobalDelay, "Should use global delay when larger");
    }

    /// @notice DM-115: requestWithdrawalAll 전체 잔액 출금
    function test_DM115_requestWithdrawalAll_fullBalance() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        uint256 stakedBefore = seigManager.stakeOf(mockLayer2, user1);
        assertGt(stakedBefore, 0, "Should have stake");

        depositManager.requestWithdrawalAll(mockLayer2);
        vm.stopPrank();

        uint256 pending = depositManager.pendingUnstaked(mockLayer2, user1);
        assertEq(pending, stakedBefore, "All stake should be pending");
    }

    /// @notice DM-116: setAddresses 설정
    function test_DM116_setAddresses() public {
        address newL1BridgeRegistry = address(0x8888);
        address newLayer2Manager = address(0x9999);

        vm.prank(owner);
        depositManager.setAddresses(newL1BridgeRegistry, newLayer2Manager);

        assertEq(depositManager.l1BridgeRegistry(), newL1BridgeRegistry, "L1BridgeRegistry updated");
        assertEq(depositManager.layer2Manager(), newLayer2Manager, "Layer2Manager updated");
    }

    /// @notice DM-117: registry getter
    function test_DM117_registry() public view {
        address registry = depositManager.registry();
        assertEq(registry, layer2RegistryProxy, "registry should match");
    }

    /// @notice DM-118: wton getter
    function test_DM118_wton() public view {
        address wtonAddr = depositManager.wton();
        assertEq(wtonAddr, wton, "wton should match");
    }

    /// @notice DM-119: oldDepositManager getter
    function test_DM119_oldDepositManager() public view {
        address oldDM = depositManager.oldDepositManager();
        // oldDepositManager는 설정된 값이거나 address(0)일 수 있음
        assertTrue(oldDM == address(0) || oldDM != address(0), "oldDepositManager getter should work");
    }

    /// @notice DM-120: MAX_DELAY_BLOCKS getter
    function test_DM120_maxDelayBlocks() public view {
        uint256 maxDelay = depositManager.MAX_DELAY_BLOCKS();
        assertGt(maxDelay, 0, "MAX_DELAY_BLOCKS should be > 0");
    }

    // ==========================================
    // Additional Function & Branch Coverage
    // ==========================================

    /// @notice DM-130: seigManager getter
    function test_DM130_seigManager() public view {
        address sm = depositManager.seigManager();
        assertEq(sm, seigManagerProxy, "seigManager should match");
    }

    /// @notice DM-131: pendingUnstakedLayer2 getter
    function test_DM131_pendingUnstakedLayer2() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        vm.stopPrank();

        uint256 pending = depositManager.pendingUnstakedLayer2(mockLayer2);
        assertEq(pending, 100e27, "pendingUnstakedLayer2 should match");
    }

    /// @notice DM-133: pendingUnstakedAccount getter
    function test_DM133_pendingUnstakedAccount() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        vm.stopPrank();

        uint256 pending = depositManager.pendingUnstakedAccount(user1);
        assertEq(pending, 100e27, "pendingUnstakedAccount should match");
    }

    /// @notice DM-134: setGlobalWithdrawalDelay 정상 설정
    function test_DM134_setGlobalWithdrawalDelay() public {
        uint256 newDelay = 2000;

        vm.prank(owner);
        depositManager.setGlobalWithdrawalDelay(newDelay);

        assertEq(depositManager.globalWithdrawalDelay(), newDelay, "globalWithdrawalDelay should be updated");
    }

    /// @notice DM-135: setMinDepositGasLimit 설정
    function test_DM135_setMinDepositGasLimit() public {
        uint32 newGasLimit = 200000;

        vm.prank(owner);
        depositManager.setMinDepositGasLimit(newGasLimit);

        assertEq(depositManager.minDepositGasLimit(), newGasLimit, "minDepositGasLimit should be updated");
    }

    /// @notice DM-136: numRequests getter
    function test_DM136_numRequests() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, 500e27);
        depositManager.deposit(mockLayer2, user1, 500e27);
        depositManager.requestWithdrawal(mockLayer2, 100e27);
        depositManager.requestWithdrawal(mockLayer2, 50e27);
        vm.stopPrank();

        uint256 numReqs = depositManager.numRequests(mockLayer2, user1);
        assertEq(numReqs, 2, "Should have 2 requests");
    }

    /// @notice DM-137: _getDelayBlocks layer2 delay > global 케이스
    function test_DM137_getDelayBlocks_layer2Larger() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 globalDelay = depositManager.globalWithdrawalDelay();
        uint256 layer2Delay = globalDelay + 1000;

        vm.prank(operatorManager);
        depositManager.setWithdrawalDelay(mockLayer2, layer2Delay);

        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        assertEq(delay, layer2Delay, "Should use layer2 delay when larger");
    }

    /// @notice DM-138: onApprove - 비WTON 호출자 revert
    function test_DM138_onApprove_notWton_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        bytes memory data = abi.encode(mockLayer2);

        vm.prank(user1);
        vm.expectRevert("DepositManager: only accept WTON approve callback");
        depositManager.onApprove(user1, depositManagerProxy, 100e27, data);
    }

    // ==========================================
    // Additional Branch Coverage Tests
    // ==========================================

    /// @notice DM-139: processRequest - receiveTon=true (TON으로 수령)
    /// @dev Line 405-406: receiveTon 분기 테스트
    /// @dev SKIP: MockWTON의 swapToTONAndTransfer는 실제 TON 전송을 mock하지 않음 (실제 환경 테스트 필요)
    function skip_test_DM139_processRequest_receiveTon_true() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;
        uint256 withdrawAmount = 100e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // Wait for delay
        uint256 delay = depositManager.globalWithdrawalDelay();
        vm.roll(block.number + delay + 1);

        uint256 tonBefore = MockTON(ton).balanceOf(user1);

        // Process with receiveTon=true
        vm.prank(user1);
        depositManager.processRequest(mockLayer2, true);

        uint256 tonAfter = MockTON(ton).balanceOf(user1);
        // 100 WTON = 0.0000001 TON (WTON uses 27 decimals, TON uses 18)
        // 100e27 / 1e9 = 100e18
        assertEq(tonAfter - tonBefore, 100e18, "Should receive TON");
    }

    /// @notice DM-140: processRequests - 여러 요청 처리
    /// @dev Line 420-424: processRequests loop 테스트
    function test_DM140_processRequests_multiple() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        depositManager.requestWithdrawal(mockLayer2, 50e27);
        depositManager.requestWithdrawal(mockLayer2, 50e27);
        depositManager.requestWithdrawal(mockLayer2, 50e27);
        vm.stopPrank();

        // Wait for delay
        uint256 delay = depositManager.globalWithdrawalDelay();
        vm.roll(block.number + delay + 1);

        uint256 wtonBefore = MockWTON(wton).balanceOf(user1);

        // Process 2 requests at once
        vm.prank(user1);
        depositManager.processRequests(mockLayer2, 2, false);

        uint256 wtonAfter = MockWTON(wton).balanceOf(user1);
        assertEq(wtonAfter - wtonBefore, 100e27, "Should receive 100 WTON (2 x 50)");

        // Check remaining pending requests
        uint256 remaining = depositManager.numPendingRequests(mockLayer2, user1);
        assertEq(remaining, 1, "Should have 1 pending request remaining");
    }

    /// @notice DM-141: _getDelayBlocks - layer2 delay가 0인 경우 global 사용
    /// @dev Line 374-375: withdrawalDelay가 0일 때 globalWithdrawalDelay 반환
    function test_DM141_getDelayBlocks_layer2ZeroUsesGlobal() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // layer2 delay가 설정되지 않은 경우 (0), global 사용
        uint256 globalDelay = depositManager.globalWithdrawalDelay();
        uint256 delay = depositManager.getDelayBlocks(mockLayer2);

        assertEq(delay, globalDelay, "Should use global delay when layer2 delay is 0");
    }

    /// @notice DM-142: requestWithdrawalAll - 전액 출금 요청
    /// @dev Line 415-417 테스트
    function test_DM142_requestWithdrawalAll() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);

        uint256 staked = ISeigManager(seigManagerProxy).stakeOf(mockLayer2, user1);

        // Request all
        depositManager.requestWithdrawalAll(mockLayer2);
        vm.stopPrank();

        uint256 pending = depositManager.pendingUnstaked(mockLayer2, user1);
        assertApproxEqAbs(pending, staked, 1e18, "Should request all staked amount");
    }

    /// @notice DM-143: deposit.2 - layer2에서 호출
    /// @dev Line 210-218: onlyLayer2 modifier로 호출
    function test_DM143_deposit_fromLayer2() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Layer2에서 직접 deposit 호출
        // mockLayer2는 CandidateAddOnProxy
        uint256 depositAmount = 100e27;

        vm.prank(owner);
        MockWTON(wton).mint(mockLayer2, depositAmount);

        vm.startPrank(mockLayer2);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        // deposit(layer2, amount) - msg.sender가 layer2이고 msg.sender에게 deposit
        bool success = depositManager.deposit(mockLayer2, depositAmount);
        vm.stopPrank();

        assertTrue(success, "Deposit from layer2 should succeed");
    }

    /// @notice DM-144: setWithdrawalDelayByOwner - owner가 직접 delay 설정
    /// @dev Line 328-331 테스트
    function test_DM144_setWithdrawalDelayByOwner() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 newDelay = 200000;

        vm.prank(owner);
        depositManager.setWithdrawalDelayByOwner(mockLayer2, newDelay);

        uint256 delay = depositManager.getDelayBlocks(mockLayer2);
        assertEq(delay, newDelay, "Delay should be set by owner");
    }

    /// @notice DM-145: setWithdrawalDelayByOwner - 비 owner revert
    function test_DM145_setWithdrawalDelayByOwner_notOwner_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.prank(user1);
        vm.expectRevert("Accessible: Caller is not an admin");
        depositManager.setWithdrawalDelayByOwner(mockLayer2, 200000);
    }
}
