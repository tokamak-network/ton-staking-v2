// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../src/stake/managers/DepositManagerV1_2.sol";

/// @title DepositManagerV1_2RealTest
/// @notice 실제 DepositManagerV1_2 컨트랙트의 커버리지 테스트
/// @dev Harness 패턴을 사용하여 내부 함수 및 스토리지 접근

// ==========================================
// Mock Contracts
// ==========================================

contract MockWTON {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function setBalance(address account, uint256 amount) external {
        balanceOf[account] = amount;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "insufficient balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract MockSeigManager {
    bool public depositResult = true;
    bool public withdrawResult = true;
    mapping(address => mapping(address => uint256)) public stakes;

    function setDepositResult(bool result) external {
        depositResult = result;
    }

    function setWithdrawResult(bool result) external {
        withdrawResult = result;
    }

    function setStake(address layer2, address account, uint256 amount) external {
        stakes[layer2][account] = amount;
    }

    function onDeposit(address, address, uint256) external view returns (bool) {
        return depositResult;
    }

    function onWithdraw(address, address, uint256) external view returns (bool) {
        return withdrawResult;
    }

    function stakeOf(address layer2, address account) external view returns (uint256) {
        return stakes[layer2][account];
    }

    function onStakingChange(address) external {
        // V3 callback - do nothing in mock
    }
}

contract MockLayer2Registry {
    mapping(address => bool) public layer2s;

    function setLayer2(address layer2, bool registered) external {
        layer2s[layer2] = registered;
    }
}

/// @notice DepositManagerV1_2 Harness for testing
contract DepositManagerV1_2Harness is DepositManagerV1_2 {
    function initialize(
        address wton_,
        address registry_,
        address seigManager_
    ) external {
        _wton = wton_;
        _registry = registry_;
        _seigManager = seigManager_;
        globalWithdrawalDelay = 100; // 100 blocks default
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setGlobalWithdrawalDelay(uint256 delay) external {
        globalWithdrawalDelay = delay;
    }

    function setLayer2WithdrawalDelay(address layer2, uint256 delay) external {
        withdrawalDelay[layer2] = delay;
    }

    function getDelayBlocks(address layer2) external view returns (uint256) {
        return _getDelayBlocks(layer2);
    }

    // Direct storage access for testing
    function getAccStaked(address layer2, address account) external view returns (uint256) {
        return _accStaked[layer2][account];
    }

    function getAccStakedLayer2(address layer2) external view returns (uint256) {
        return _accStakedLayer2[layer2];
    }

    function getPendingUnstaked(address layer2, address account) external view returns (uint256) {
        return _pendingUnstaked[layer2][account];
    }

    function getWithdrawalRequestsLength(address layer2, address account) external view returns (uint256) {
        return _withdrawalRequests[layer2][account].length;
    }
}

contract DepositManagerV1_2RealTest is Test {
    DepositManagerV1_2Harness public depositManager;
    MockWTON public wton;
    MockSeigManager public seigManager;
    MockLayer2Registry public registry;

    address public layer2_1 = address(0x1001);
    address public layer2_2 = address(0x1002);
    address public user1 = address(0x2001);
    address public user2 = address(0x2002);
    address public owner = address(this);

    uint256 constant RAY = 1e27;

    function setUp() public {
        wton = new MockWTON();
        seigManager = new MockSeigManager();
        registry = new MockLayer2Registry();

        depositManager = new DepositManagerV1_2Harness();
        depositManager.initialize(
            address(wton),
            address(registry),
            address(seigManager)
        );

        // Register layer2s
        registry.setLayer2(layer2_1, true);
        registry.setLayer2(layer2_2, true);

        // Give users WTON
        wton.setBalance(user1, 10000e27);
        wton.setBalance(user2, 10000e27);

        // Approve
        vm.prank(user1);
        wton.approve(address(depositManager), type(uint256).max);
        vm.prank(user2);
        wton.approve(address(depositManager), type(uint256).max);
    }

    // ==========================================
    // Deposit Tests
    // ==========================================

    function test_deposit_basic() public {
        uint256 amount = 100e27;

        vm.prank(user1);
        bool result = depositManager.deposit(layer2_1, user1, amount);

        assertTrue(result, "Deposit should succeed");
        assertEq(depositManager.getAccStaked(layer2_1, user1), amount, "Staked amount recorded");
        assertEq(depositManager.getAccStakedLayer2(layer2_1), amount, "Layer2 total updated");
    }

    function test_deposit_zeroAmount_reverts() public {
        vm.prank(user1);
        vm.expectRevert("DepositManager: amount must not be zero");
        depositManager.deposit(layer2_1, user1, 0);
    }

    function test_deposit_unregisteredLayer2_reverts() public {
        address unregistered = address(0x9999);

        vm.prank(user1);
        vm.expectRevert();
        depositManager.deposit(unregistered, user1, 100e27);
    }

    function test_deposit_multipleDeposits() public {
        uint256 amount1 = 100e27;
        uint256 amount2 = 200e27;

        vm.startPrank(user1);
        depositManager.deposit(layer2_1, user1, amount1);
        depositManager.deposit(layer2_1, user1, amount2);
        vm.stopPrank();

        assertEq(depositManager.getAccStaked(layer2_1, user1), amount1 + amount2);
    }

    function test_deposit_multipleUsers() public {
        uint256 amount1 = 100e27;
        uint256 amount2 = 200e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, amount1);

        vm.prank(user2);
        depositManager.deposit(layer2_1, user2, amount2);

        assertEq(depositManager.getAccStaked(layer2_1, user1), amount1);
        assertEq(depositManager.getAccStaked(layer2_1, user2), amount2);
        assertEq(depositManager.getAccStakedLayer2(layer2_1), amount1 + amount2);
    }

    function test_deposit_onDepositFails_reverts() public {
        seigManager.setDepositResult(false);

        vm.prank(user1);
        vm.expectRevert("onDeposit failed");
        depositManager.deposit(layer2_1, user1, 100e27);
    }

    // ==========================================
    // Withdrawal Request Tests
    // ==========================================

    function test_requestWithdrawal_basic() public {
        uint256 depositAmount = 100e27;
        uint256 withdrawAmount = 50e27;

        // First deposit
        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);

        // Set stake in SeigManager
        seigManager.setStake(layer2_1, user1, depositAmount);

        // Request withdrawal
        vm.prank(user1);
        bool result = depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        assertTrue(result, "Request should succeed");
        assertEq(depositManager.getPendingUnstaked(layer2_1, user1), withdrawAmount);
        assertEq(depositManager.getWithdrawalRequestsLength(layer2_1, user1), 1);
    }

    function test_requestWithdrawal_zeroAmount_reverts() public {
        vm.prank(user1);
        vm.expectRevert("DepositManager: amount must not be zero");
        depositManager.requestWithdrawal(layer2_1, 0);
    }

    function test_requestWithdrawal_multipleRequests() public {
        uint256 depositAmount = 1000e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        vm.startPrank(user1);
        depositManager.requestWithdrawal(layer2_1, 100e27);
        depositManager.requestWithdrawal(layer2_1, 200e27);
        depositManager.requestWithdrawal(layer2_1, 300e27);
        vm.stopPrank();

        assertEq(depositManager.getWithdrawalRequestsLength(layer2_1, user1), 3);
        assertEq(depositManager.getPendingUnstaked(layer2_1, user1), 600e27);
    }

    // ==========================================
    // Process Request Tests
    // ==========================================

    function test_processRequest_basic() public {
        uint256 depositAmount = 100e27;
        uint256 withdrawAmount = 50e27;

        // Setup: deposit and request withdrawal
        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        // Give depositManager WTON for withdrawal
        wton.setBalance(address(depositManager), withdrawAmount);

        // Advance blocks past delay
        vm.roll(block.number + 150);

        // Process
        uint256 balanceBefore = wton.balanceOf(user1);

        vm.prank(user1);
        bool result = depositManager.processRequest(layer2_1);

        assertTrue(result);
        assertEq(wton.balanceOf(user1), balanceBefore + withdrawAmount);
        assertEq(depositManager.getPendingUnstaked(layer2_1, user1), 0);
    }

    function test_processRequest_beforeDelay_reverts() public {
        uint256 depositAmount = 100e27;
        uint256 withdrawAmount = 50e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        // Don't advance blocks

        vm.prank(user1);
        vm.expectRevert("not yet withdrawable");
        depositManager.processRequest(layer2_1);
    }

    function test_processRequest_noPendingRequest_reverts() public {
        vm.prank(user1);
        vm.expectRevert("no pending request");
        depositManager.processRequest(layer2_1);
    }

    // ==========================================
    // Process Requests (Batch) Tests
    // ==========================================

    function test_processRequests_batch() public {
        uint256 depositAmount = 1000e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        // Multiple withdrawal requests
        vm.startPrank(user1);
        depositManager.requestWithdrawal(layer2_1, 100e27);
        depositManager.requestWithdrawal(layer2_1, 200e27);
        depositManager.requestWithdrawal(layer2_1, 300e27);
        vm.stopPrank();

        // Give depositManager WTON
        wton.setBalance(address(depositManager), 600e27);

        // Advance blocks
        vm.roll(block.number + 150);

        // Process batch
        uint256 balanceBefore = wton.balanceOf(user1);

        vm.prank(user1);
        bool result = depositManager.processRequests(layer2_1, 3);

        assertTrue(result);
        assertEq(wton.balanceOf(user1), balanceBefore + 600e27);
    }

    // ==========================================
    // Delay Configuration Tests
    // ==========================================

    function test_getDelayBlocks_globalDelay() public {
        depositManager.setGlobalWithdrawalDelay(200);
        depositManager.setLayer2WithdrawalDelay(layer2_1, 100);

        uint256 delay = depositManager.getDelayBlocks(layer2_1);
        assertEq(delay, 200, "Should use global delay when higher");
    }

    function test_getDelayBlocks_layer2Delay() public {
        depositManager.setGlobalWithdrawalDelay(100);
        depositManager.setLayer2WithdrawalDelay(layer2_1, 300);

        uint256 delay = depositManager.getDelayBlocks(layer2_1);
        assertEq(delay, 300, "Should use layer2 delay when higher");
    }

    // ==========================================
    // V3 Callback Tests
    // ==========================================

    function test_v3Callback_disabled() public {
        // V3 callback is disabled by default
        assertFalse(depositManager.v3CallbackEnabled());

        // Deposit should still work
        vm.prank(user1);
        bool result = depositManager.deposit(layer2_1, user1, 100e27);
        assertTrue(result);
    }

    function test_v3Callback_enabled() public {
        depositManager.setV3CallbackEnabled(true);
        assertTrue(depositManager.v3CallbackEnabled());

        // Deposit should trigger callback
        vm.prank(user1);
        bool result = depositManager.deposit(layer2_1, user1, 100e27);
        assertTrue(result);
    }

    // ==========================================
    // Owner Functions Tests
    // ==========================================

    function test_setMinDepositGasLimit() public {
        depositManager.setMinDepositGasLimit(300_000);
        assertEq(depositManager.minDepositGasLimit(), 300_000);
    }

    function test_setAddresses() public {
        address newRegistry = address(0x1111);
        address newManager = address(0x2222);

        depositManager.setAddresses(newRegistry, newManager);

        assertEq(depositManager.l1BridgeRegistry(), newRegistry);
        assertEq(depositManager.layer2Manager(), newManager);
    }

    function test_setV3CallbackEnabled() public {
        assertFalse(depositManager.v3CallbackEnabled());

        depositManager.setV3CallbackEnabled(true);
        assertTrue(depositManager.v3CallbackEnabled());

        depositManager.setV3CallbackEnabled(false);
        assertFalse(depositManager.v3CallbackEnabled());
    }

    // ==========================================
    // View Functions Tests
    // ==========================================

    function test_getWithdrawalRequests() public {
        uint256 depositAmount = 100e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, 50e27);

        DepositManagerStorage.WithdrawalReqeust[] memory requests =
            depositManager.getWithdrawalRequests(layer2_1, user1);

        assertEq(requests.length, 1);
        assertEq(requests[0].amount, 50e27);
        assertFalse(requests[0].processed);
    }

    function test_getWithdrawalRequestIndex() public {
        uint256 depositAmount = 100e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, 50e27);

        uint256 index = depositManager.getWithdrawalRequestIndex(layer2_1, user1);
        assertEq(index, 0);
    }

    function test_pendingUnstaked() public {
        uint256 depositAmount = 100e27;
        uint256 withdrawAmount = 30e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        assertEq(depositManager.pendingUnstaked(layer2_1, user1), withdrawAmount);
    }

    function test_accStaked() public {
        uint256 amount = 100e27;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, amount);

        assertEq(depositManager.accStaked(layer2_1, user1), amount);
    }

    function test_accUnstaked() public {
        uint256 depositAmount = 100e27;
        uint256 withdrawAmount = 50e27;

        // Deposit
        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);
        seigManager.setStake(layer2_1, user1, depositAmount);

        // Request withdrawal
        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        // Give depositManager WTON
        wton.setBalance(address(depositManager), withdrawAmount);

        // Advance and process
        vm.roll(block.number + 150);

        vm.prank(user1);
        depositManager.processRequest(layer2_1);

        assertEq(depositManager.accUnstaked(layer2_1, user1), withdrawAmount);
    }

    // ==========================================
    // Fuzz Tests
    // ==========================================

    function testFuzz_deposit(uint256 amount) public {
        amount = bound(amount, 1, 1e32);

        wton.setBalance(user1, amount);
        vm.prank(user1);
        wton.approve(address(depositManager), amount);

        vm.prank(user1);
        bool result = depositManager.deposit(layer2_1, user1, amount);

        assertTrue(result);
        assertEq(depositManager.getAccStaked(layer2_1, user1), amount);
    }

    function testFuzz_requestWithdrawal(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1e18, 1e32);
        withdrawAmount = bound(withdrawAmount, 1, type(uint128).max - 1);

        wton.setBalance(user1, depositAmount);
        vm.prank(user1);
        wton.approve(address(depositManager), depositAmount);

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, depositAmount);

        seigManager.setStake(layer2_1, user1, depositAmount);

        vm.prank(user1);
        bool result = depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        assertTrue(result);
        assertEq(depositManager.getPendingUnstaked(layer2_1, user1), withdrawAmount);
    }
}
