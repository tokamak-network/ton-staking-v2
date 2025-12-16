// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

/// @notice Mock WTON for testing
contract MockWTON {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "insufficient allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

/// @notice Mock Layer2Registry for testing
contract MockLayer2Registry {
    mapping(address => bool) public layer2s;

    function registerLayer2(address layer2) external {
        layer2s[layer2] = true;
    }

    function deregisterLayer2(address layer2) external {
        layer2s[layer2] = false;
    }
}

/// @notice Mock SeigManager for testing
contract MockSeigManagerForDeposit {
    mapping(address => mapping(address => uint256)) public stakeOf;
    mapping(address => uint256) public stakingAmountOf;

    // V3 콜백 추적
    uint256 public stakingChangeCallCount;
    address public lastStakingChangeLayer2;

    function onDeposit(address layer2, address account, uint256 amount) external returns (bool) {
        stakeOf[layer2][account] += amount;
        stakingAmountOf[layer2] += amount;
        return true;
    }

    function onWithdraw(address layer2, address account, uint256 amount) external returns (bool) {
        require(stakeOf[layer2][account] >= amount, "insufficient stake");
        stakeOf[layer2][account] -= amount;
        stakingAmountOf[layer2] -= amount;
        return true;
    }

    function onStakingChange(address layer2) external {
        stakingChangeCallCount++;
        lastStakingChangeLayer2 = layer2;
    }

    function getStakeOf(address layer2, address account) external view returns (uint256) {
        return stakeOf[layer2][account];
    }
}

/// @notice Minimal DepositManager for testing
contract TestableDepositManager {
    // Storage
    address public wton;
    address public registry;
    address public seigManager;

    // 누적 스테이킹
    mapping(address => mapping(address => uint256)) public accStaked;
    mapping(address => uint256) public accStakedLayer2;
    mapping(address => uint256) public accStakedAccount;

    // 대기 중 언스테이킹
    mapping(address => mapping(address => uint256)) public pendingUnstaked;
    mapping(address => uint256) public pendingUnstakedLayer2;
    mapping(address => uint256) public pendingUnstakedAccount;

    // 완료된 언스테이킹
    mapping(address => mapping(address => uint256)) public accUnstaked;
    mapping(address => uint256) public accUnstakedLayer2;
    mapping(address => uint256) public accUnstakedAccount;

    // 출금 요청
    struct WithdrawalRequest {
        uint128 withdrawableBlockNumber;
        uint128 amount;
        bool processed;
    }

    mapping(address => mapping(address => WithdrawalRequest[])) public withdrawalRequests;
    mapping(address => mapping(address => uint256)) public withdrawalRequestIndex;

    // 출금 지연
    uint256 public globalWithdrawalDelay;
    mapping(address => uint256) public withdrawalDelay;

    // Reentrancy guard
    bool private _locked;

    // Events
    event Deposited(address indexed layer2, address indexed account, uint256 amount);
    event WithdrawalRequested(address indexed layer2, address indexed depositor, uint256 amount);
    event WithdrawalProcessed(address indexed layer2, address indexed depositor, uint256 amount);
    event WithdrawalsCancelled(address indexed layer2, address indexed depositor, uint256 count);

    modifier onlyLayer2(address layer2) {
        require(MockLayer2Registry(registry).layer2s(layer2), "not registered layer2");
        _;
    }

    modifier ifFree() {
        require(!_locked, "reentrancy");
        _locked = true;
        _;
        _locked = false;
    }

    constructor(address _wton, address _registry, address _seigManager) {
        wton = _wton;
        registry = _registry;
        seigManager = _seigManager;
        globalWithdrawalDelay = 100; // 기본 100 블록 지연
    }

    // ==========================================
    // 설정 함수
    // ==========================================

    function setGlobalWithdrawalDelay(uint256 delay) external {
        globalWithdrawalDelay = delay;
    }

    function setWithdrawalDelay(address layer2, uint256 delay) external {
        withdrawalDelay[layer2] = delay;
    }

    // ==========================================
    // 스테이킹 함수
    // ==========================================

    function deposit(address layer2, address account, uint256 amount)
        external
        onlyLayer2(layer2)
        returns (bool)
    {
        require(amount > 0, "amount must be > 0");

        // WTON 전송
        MockWTON(wton).transferFrom(msg.sender, address(this), amount);

        // 스테이킹 기록
        accStaked[layer2][account] += amount;
        accStakedLayer2[layer2] += amount;
        accStakedAccount[account] += amount;

        // SeigManager 콜백
        require(
            MockSeigManagerForDeposit(seigManager).onDeposit(layer2, account, amount),
            "onDeposit failed"
        );

        emit Deposited(layer2, account, amount);
        return true;
    }

    // ==========================================
    // 언스테이킹 요청 함수
    // ==========================================

    function requestWithdrawal(address layer2, uint256 amount)
        external
        onlyLayer2(layer2)
        returns (bool)
    {
        return _requestWithdrawal(layer2, amount, _getDelayBlocks(layer2));
    }

    function _requestWithdrawal(address layer2, uint256 amount, uint256 delay)
        internal
        returns (bool)
    {
        require(amount > 0, "amount must be > 0");

        // SeigManager에서 스테이킹 감소
        require(
            MockSeigManagerForDeposit(seigManager).onWithdraw(layer2, msg.sender, amount),
            "onWithdraw failed"
        );

        // 출금 요청 추가
        withdrawalRequests[layer2][msg.sender].push(
            WithdrawalRequest({
                withdrawableBlockNumber: uint128(block.number + delay),
                amount: uint128(amount),
                processed: false
            })
        );

        // 대기 중 언스테이킹 추가
        pendingUnstaked[layer2][msg.sender] += amount;
        pendingUnstakedLayer2[layer2] += amount;
        pendingUnstakedAccount[msg.sender] += amount;

        emit WithdrawalRequested(layer2, msg.sender, amount);
        return true;
    }

    // ==========================================
    // 언스테이킹 취소 함수
    // ==========================================

    function cancelWithdrawal(address layer2, uint256 index)
        external
        onlyLayer2(layer2)
        returns (bool)
    {
        WithdrawalRequest[] storage requests = withdrawalRequests[layer2][msg.sender];
        require(index < requests.length, "invalid index");

        WithdrawalRequest storage request = requests[index];
        require(!request.processed, "already processed");

        uint256 amount = request.amount;
        request.processed = true; // 처리 완료로 표시 (취소)

        // 대기 중 언스테이킹 감소
        pendingUnstaked[layer2][msg.sender] -= amount;
        pendingUnstakedLayer2[layer2] -= amount;
        pendingUnstakedAccount[msg.sender] -= amount;

        // SeigManager에 다시 스테이킹 추가
        require(
            MockSeigManagerForDeposit(seigManager).onDeposit(layer2, msg.sender, amount),
            "onDeposit failed"
        );

        emit WithdrawalsCancelled(layer2, msg.sender, 1);
        return true;
    }

    // ==========================================
    // 언스테이킹 실행 함수
    // ==========================================

    function processRequest(address layer2)
        external
        onlyLayer2(layer2)
        ifFree
        returns (bool)
    {
        WithdrawalRequest[] storage requests = withdrawalRequests[layer2][msg.sender];
        uint256 index = withdrawalRequestIndex[layer2][msg.sender];

        require(index < requests.length, "no pending request");

        WithdrawalRequest storage request = requests[index];
        require(!request.processed, "already processed");
        require(block.number >= request.withdrawableBlockNumber, "not yet withdrawable");

        uint256 amount = request.amount;
        request.processed = true;
        withdrawalRequestIndex[layer2][msg.sender] = index + 1;

        // 대기 중 -> 완료 전환
        pendingUnstaked[layer2][msg.sender] -= amount;
        pendingUnstakedLayer2[layer2] -= amount;
        pendingUnstakedAccount[msg.sender] -= amount;

        accUnstaked[layer2][msg.sender] += amount;
        accUnstakedLayer2[layer2] += amount;
        accUnstakedAccount[msg.sender] += amount;

        // WTON 전송
        MockWTON(wton).transfer(msg.sender, amount);

        emit WithdrawalProcessed(layer2, msg.sender, amount);
        return true;
    }

    function processRequests(address layer2, uint256 count)
        external
        onlyLayer2(layer2)
        ifFree
        returns (bool)
    {
        WithdrawalRequest[] storage requests = withdrawalRequests[layer2][msg.sender];
        uint256 index = withdrawalRequestIndex[layer2][msg.sender];

        require(index < requests.length, "no pending request");

        uint256 totalAmount = 0;
        uint256 processed = 0;

        for (uint256 i = 0; i < count && (index + i) < requests.length; i++) {
            WithdrawalRequest storage request = requests[index + i];
            if (request.processed) continue;
            if (block.number < request.withdrawableBlockNumber) continue;

            totalAmount += request.amount;
            request.processed = true;
            processed++;
        }

        require(processed > 0, "no processable request");

        withdrawalRequestIndex[layer2][msg.sender] = index + processed;

        // 대기 중 -> 완료 전환
        pendingUnstaked[layer2][msg.sender] -= totalAmount;
        pendingUnstakedLayer2[layer2] -= totalAmount;
        pendingUnstakedAccount[msg.sender] -= totalAmount;

        accUnstaked[layer2][msg.sender] += totalAmount;
        accUnstakedLayer2[layer2] += totalAmount;
        accUnstakedAccount[msg.sender] += totalAmount;

        // WTON 전송
        MockWTON(wton).transfer(msg.sender, totalAmount);

        emit WithdrawalProcessed(layer2, msg.sender, totalAmount);
        return true;
    }

    // ==========================================
    // 내부 함수
    // ==========================================

    function _getDelayBlocks(address layer2) internal view returns (uint256) {
        uint256 layerDelay = withdrawalDelay[layer2];
        return globalWithdrawalDelay > layerDelay ? globalWithdrawalDelay : layerDelay;
    }

    // ==========================================
    // 조회 함수
    // ==========================================

    function getWithdrawalRequests(address layer2, address account)
        external
        view
        returns (WithdrawalRequest[] memory)
    {
        return withdrawalRequests[layer2][account];
    }

    function getWithdrawalRequestIndex(address layer2, address account)
        external
        view
        returns (uint256)
    {
        return withdrawalRequestIndex[layer2][account];
    }

    function getPendingWithdrawalCount(address layer2, address account)
        external
        view
        returns (uint256)
    {
        WithdrawalRequest[] storage requests = withdrawalRequests[layer2][account];
        uint256 index = withdrawalRequestIndex[layer2][account];
        uint256 count = 0;

        for (uint256 i = index; i < requests.length; i++) {
            if (!requests[i].processed) count++;
        }

        return count;
    }
}

/// @title DepositManagerV1_2Test
/// @notice 스테이킹/언스테이킹 기능 테스트
contract DepositManagerV1_2Test is Test {
    TestableDepositManager public depositManager;
    MockWTON public wton;
    MockLayer2Registry public registry;
    MockSeigManagerForDeposit public seigManager;

    address public layer2_1 = address(0x1001);
    address public layer2_2 = address(0x1002);
    address public user1 = address(0x2001);
    address public user2 = address(0x2002);

    uint256 constant RAY = 1e27;
    uint256 constant INITIAL_BALANCE = 10000 * RAY;

    function setUp() public {
        // Mock 컨트랙트 배포
        wton = new MockWTON();
        registry = new MockLayer2Registry();
        seigManager = new MockSeigManagerForDeposit();

        // DepositManager 배포
        depositManager = new TestableDepositManager(
            address(wton),
            address(registry),
            address(seigManager)
        );

        // Layer2 등록
        registry.registerLayer2(layer2_1);
        registry.registerLayer2(layer2_2);

        // 사용자에게 WTON 민트 및 승인
        wton.mint(user1, INITIAL_BALANCE);
        wton.mint(user2, INITIAL_BALANCE);

        vm.prank(user1);
        wton.approve(address(depositManager), type(uint256).max);

        vm.prank(user2);
        wton.approve(address(depositManager), type(uint256).max);
    }

    // ==========================================
    // 1. 스테이킹 테스트
    // ==========================================

    /// @notice 기본 스테이킹 테스트
    function test_deposit_basic() public {
        uint256 amount = 100 * RAY;

        vm.prank(user1);
        bool success = depositManager.deposit(layer2_1, user1, amount);

        assertTrue(success, "deposit should succeed");
        assertEq(depositManager.accStaked(layer2_1, user1), amount, "accStaked mismatch");
        assertEq(depositManager.accStakedLayer2(layer2_1), amount, "accStakedLayer2 mismatch");
        assertEq(depositManager.accStakedAccount(user1), amount, "accStakedAccount mismatch");
        assertEq(seigManager.stakeOf(layer2_1, user1), amount, "seigManager stake mismatch");
    }

    /// @notice 여러 번 스테이킹 테스트
    function test_deposit_multiple() public {
        uint256 amount1 = 100 * RAY;
        uint256 amount2 = 200 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, amount1);

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, amount2);

        assertEq(depositManager.accStaked(layer2_1, user1), amount1 + amount2);
        assertEq(seigManager.stakeOf(layer2_1, user1), amount1 + amount2);
    }

    /// @notice 다른 L2에 스테이킹 테스트
    function test_deposit_differentLayers() public {
        uint256 amount1 = 100 * RAY;
        uint256 amount2 = 200 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, amount1);

        vm.prank(user1);
        depositManager.deposit(layer2_2, user1, amount2);

        assertEq(depositManager.accStaked(layer2_1, user1), amount1);
        assertEq(depositManager.accStaked(layer2_2, user1), amount2);
        assertEq(depositManager.accStakedAccount(user1), amount1 + amount2);
    }

    /// @notice 0 금액 스테이킹 실패 테스트
    function test_deposit_zeroAmount_reverts() public {
        vm.prank(user1);
        vm.expectRevert("amount must be > 0");
        depositManager.deposit(layer2_1, user1, 0);
    }

    /// @notice 미등록 L2 스테이킹 실패 테스트
    function test_deposit_unregisteredLayer2_reverts() public {
        address unregistered = address(0x9999);

        vm.prank(user1);
        vm.expectRevert("not registered layer2");
        depositManager.deposit(unregistered, user1, 100 * RAY);
    }

    // ==========================================
    // 2. 언스테이킹 요청 테스트
    // ==========================================

    /// @notice 기본 언스테이킹 요청 테스트
    function test_requestWithdrawal_basic() public {
        uint256 stakeAmount = 100 * RAY;
        uint256 withdrawAmount = 50 * RAY;

        // 먼저 스테이킹
        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        // 언스테이킹 요청
        vm.prank(user1);
        bool success = depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        assertTrue(success, "requestWithdrawal should succeed");
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), withdrawAmount);
        assertEq(seigManager.stakeOf(layer2_1, user1), stakeAmount - withdrawAmount);
    }

    /// @notice 전액 언스테이킹 요청 테스트
    function test_requestWithdrawal_fullAmount() public {
        uint256 amount = 100 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, amount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, amount);

        assertEq(depositManager.pendingUnstaked(layer2_1, user1), amount);
        assertEq(seigManager.stakeOf(layer2_1, user1), 0);
    }

    /// @notice 여러 번 언스테이킹 요청 테스트
    function test_requestWithdrawal_multiple() public {
        uint256 stakeAmount = 300 * RAY;
        uint256 withdraw1 = 50 * RAY;
        uint256 withdraw2 = 100 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdraw1);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdraw2);

        assertEq(depositManager.pendingUnstaked(layer2_1, user1), withdraw1 + withdraw2);
        assertEq(depositManager.getPendingWithdrawalCount(layer2_1, user1), 2);
    }

    /// @notice 잔액 초과 언스테이킹 실패 테스트
    function test_requestWithdrawal_exceedsBalance_reverts() public {
        uint256 stakeAmount = 100 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        vm.prank(user1);
        vm.expectRevert("insufficient stake");
        depositManager.requestWithdrawal(layer2_1, stakeAmount + 1);
    }

    // ==========================================
    // 3. 언스테이킹 취소 테스트
    // ==========================================

    /// @notice 언스테이킹 취소 테스트
    function test_cancelWithdrawal_basic() public {
        uint256 stakeAmount = 100 * RAY;
        uint256 withdrawAmount = 50 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        // 취소
        vm.prank(user1);
        bool success = depositManager.cancelWithdrawal(layer2_1, 0);

        assertTrue(success, "cancelWithdrawal should succeed");
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), 0, "pending should be 0");
        assertEq(seigManager.stakeOf(layer2_1, user1), stakeAmount, "stake should be restored");
    }

    /// @notice 이미 처리된 요청 취소 실패 테스트
    function test_cancelWithdrawal_alreadyProcessed_reverts() public {
        uint256 stakeAmount = 100 * RAY;
        uint256 withdrawAmount = 50 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        // 시간 진행 후 처리
        vm.roll(block.number + 200);

        vm.prank(user1);
        depositManager.processRequest(layer2_1);

        // 취소 시도 (실패해야 함)
        vm.prank(user1);
        vm.expectRevert("already processed");
        depositManager.cancelWithdrawal(layer2_1, 0);
    }

    // ==========================================
    // 4. 언스테이킹 실행 테스트
    // ==========================================

    /// @notice 기본 언스테이킹 실행 테스트
    function test_processRequest_basic() public {
        uint256 stakeAmount = 100 * RAY;
        uint256 withdrawAmount = 50 * RAY;
        uint256 delay = depositManager.globalWithdrawalDelay();

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        uint256 balanceBefore = wton.balanceOf(user1);

        // 대기 기간 진행
        vm.roll(block.number + delay + 1);

        vm.prank(user1);
        bool success = depositManager.processRequest(layer2_1);

        assertTrue(success, "processRequest should succeed");
        assertEq(wton.balanceOf(user1), balanceBefore + withdrawAmount, "WTON balance mismatch");
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), 0, "pending should be 0");
        assertEq(depositManager.accUnstaked(layer2_1, user1), withdrawAmount, "accUnstaked mismatch");
    }

    /// @notice 대기 기간 전 실행 실패 테스트
    function test_processRequest_beforeDelay_reverts() public {
        uint256 stakeAmount = 100 * RAY;
        uint256 withdrawAmount = 50 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdrawAmount);

        // 대기 기간 미경과
        vm.prank(user1);
        vm.expectRevert("not yet withdrawable");
        depositManager.processRequest(layer2_1);
    }

    /// @notice 일괄 실행 테스트
    function test_processRequests_batch() public {
        uint256 stakeAmount = 500 * RAY;
        uint256 withdraw1 = 100 * RAY;
        uint256 withdraw2 = 150 * RAY;
        uint256 withdraw3 = 200 * RAY;

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        // 여러 출금 요청
        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdraw1);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdraw2);

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdraw3);

        // 대기 기간 진행
        vm.roll(block.number + 200);

        uint256 balanceBefore = wton.balanceOf(user1);

        // 일괄 처리 (3개)
        vm.prank(user1);
        depositManager.processRequests(layer2_1, 3);

        assertEq(
            wton.balanceOf(user1),
            balanceBefore + withdraw1 + withdraw2 + withdraw3,
            "batch withdrawal amount mismatch"
        );
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), 0);
    }

    /// @notice 부분 일괄 실행 테스트 (일부만 출금 가능한 경우)
    function test_processRequests_partial() public {
        uint256 stakeAmount = 500 * RAY;
        uint256 withdraw1 = 100 * RAY;
        uint256 withdraw2 = 150 * RAY;

        // 서로 다른 지연 설정
        depositManager.setWithdrawalDelay(layer2_1, 200);
        depositManager.setGlobalWithdrawalDelay(100);

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, stakeAmount);

        // 첫 번째 요청 (200 블록 지연)
        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdraw1);

        // 150 블록 진행 (첫 번째는 아직 못 출금)
        vm.roll(block.number + 150);

        // 두 번째 요청 (여기서부터 200 블록 지연)
        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, withdraw2);

        // 추가 100 블록 진행 (첫 번째만 출금 가능)
        vm.roll(block.number + 100);

        uint256 balanceBefore = wton.balanceOf(user1);

        // 일괄 처리 시도 (2개 요청했지만 1개만 처리 가능)
        vm.prank(user1);
        depositManager.processRequests(layer2_1, 2);

        // 첫 번째만 처리됨
        assertEq(wton.balanceOf(user1), balanceBefore + withdraw1);
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), withdraw2);
    }

    // ==========================================
    // 5. V3 콜백 테스트
    // ==========================================

    // ==========================================
    // 6. 출금 지연 테스트
    // ==========================================

    /// @notice 글로벌 지연 적용 테스트
    function test_withdrawalDelay_global() public {
        uint256 globalDelay = 500;
        depositManager.setGlobalWithdrawalDelay(globalDelay);

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, 100 * RAY);

        uint256 startBlock = block.number;

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, 50 * RAY);

        TestableDepositManager.WithdrawalRequest[] memory requests =
            depositManager.getWithdrawalRequests(layer2_1, user1);

        assertEq(requests[0].withdrawableBlockNumber, startBlock + globalDelay);
    }

    /// @notice L2별 지연 적용 테스트 (글로벌보다 큰 경우)
    function test_withdrawalDelay_layer2Specific() public {
        uint256 globalDelay = 100;
        uint256 layer2Delay = 300;

        depositManager.setGlobalWithdrawalDelay(globalDelay);
        depositManager.setWithdrawalDelay(layer2_1, layer2Delay);

        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, 100 * RAY);

        uint256 startBlock = block.number;

        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, 50 * RAY);

        TestableDepositManager.WithdrawalRequest[] memory requests =
            depositManager.getWithdrawalRequests(layer2_1, user1);

        // L2 지연이 더 크므로 L2 지연 적용
        assertEq(requests[0].withdrawableBlockNumber, startBlock + layer2Delay);
    }

    // ==========================================
    // 7. 통합 시나리오 테스트
    // ==========================================

    /// @notice 전체 플로우 테스트: 스테이킹 -> 부분 언스테이킹 -> 추가 스테이킹 -> 완전 언스테이킹
    function test_fullScenario() public {
        // 1. 초기 스테이킹
        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, 500 * RAY);
        assertEq(seigManager.stakeOf(layer2_1, user1), 500 * RAY);

        // 2. 부분 언스테이킹 요청
        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, 200 * RAY);
        assertEq(seigManager.stakeOf(layer2_1, user1), 300 * RAY);
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), 200 * RAY);

        // 3. 추가 스테이킹
        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, 100 * RAY);
        assertEq(seigManager.stakeOf(layer2_1, user1), 400 * RAY);

        // 4. 대기 기간 후 출금 처리
        vm.roll(block.number + 200);

        uint256 balanceBefore = wton.balanceOf(user1);
        vm.prank(user1);
        depositManager.processRequest(layer2_1);

        assertEq(wton.balanceOf(user1), balanceBefore + 200 * RAY);
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), 0);
        assertEq(depositManager.accUnstaked(layer2_1, user1), 200 * RAY);

        // 5. 남은 전액 언스테이킹 요청
        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, 400 * RAY);
        assertEq(seigManager.stakeOf(layer2_1, user1), 0);

        // 6. 대기 후 출금
        vm.roll(block.number + 200);

        vm.prank(user1);
        depositManager.processRequest(layer2_1);

        assertEq(depositManager.accUnstaked(layer2_1, user1), 600 * RAY);
        assertEq(seigManager.stakeOf(layer2_1, user1), 0);

        // V3 콜백이 적절히 호출되었는지 확인
        assertTrue(seigManager.stakingChangeCallCount() >= 5, "V3 callbacks should have been called");
    }

    /// @notice 다중 사용자 시나리오 테스트
    function test_multiUser_scenario() public {
        // user1 스테이킹
        vm.prank(user1);
        depositManager.deposit(layer2_1, user1, 300 * RAY);

        // user2 스테이킹
        vm.prank(user2);
        depositManager.deposit(layer2_1, user2, 200 * RAY);

        // 둘 다 언스테이킹 요청
        vm.prank(user1);
        depositManager.requestWithdrawal(layer2_1, 100 * RAY);

        vm.prank(user2);
        depositManager.requestWithdrawal(layer2_1, 50 * RAY);

        // 상태 확인
        assertEq(depositManager.pendingUnstakedLayer2(layer2_1), 150 * RAY);
        assertEq(depositManager.pendingUnstaked(layer2_1, user1), 100 * RAY);
        assertEq(depositManager.pendingUnstaked(layer2_1, user2), 50 * RAY);

        // 대기 후 출금
        vm.roll(block.number + 200);

        vm.prank(user1);
        depositManager.processRequest(layer2_1);

        vm.prank(user2);
        depositManager.processRequest(layer2_1);

        assertEq(depositManager.accUnstakedLayer2(layer2_1), 150 * RAY);
    }
}
