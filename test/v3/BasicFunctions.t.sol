// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../script/DeployV3Full.s.sol";

interface ISeigManagerForMock {
    function updateSeigniorage() external returns (bool);
}

/// @title MockLayer2 for testing
/// @notice ILayer2 + ICandidate 인터페이스를 구현한 테스트용 Mock
contract MockLayer2ForTest {
    address public operator;
    address public seigManager;
    bool public _isLayer2 = true;
    uint256 public currentFork = 1;

    constructor(address _operator) {
        operator = _operator;
    }

    function setSeigManager(address _seigManager) external {
        seigManager = _seigManager;
    }

    function isLayer2() external view returns (bool) {
        return _isLayer2;
    }

    function lastEpoch(uint256) external pure returns (uint256) {
        return 0;
    }

    function changeOperator(address _operator) external {
        operator = _operator;
    }

    /// @notice ICandidate.updateSeigniorage - SeigManager에 콜백
    function updateSeigniorage() external returns (bool) {
        require(seigManager != address(0), "SeigManager not set");
        return ISeigManagerForMock(seigManager).updateSeigniorage();
    }
}

/// @title BasicFunctionsTest
/// @notice TON Staking V3 Basic Functions Unit Tests
/// @dev Uses DeployV3Full to deploy the entire system, then tests individual component functionality
///      Test coverage:
///      - DepositManager: WTON/TON deposit, withdrawal request, withdrawal processing
///      - Layer2Registry: Layer2 registration and Coinage deployment
///      - SeigManager: Basic updateSeigniorage operations
///      Uses MockLayer2 directly to test independently from the actual Layer2Manager registration flow
contract BasicFunctionsTest is Test, DeployV3Full {
    // 컨트랙트 참조
    DepositManager public depositManager;
    Layer2Registry public layer2Registry;

    // 테스트용 layer2
    MockLayer2ForTest public mockLayer2;

    address public admin;  // TransparentUpgradeableProxy의 admin (관리 함수만 호출)
    address public owner;  // 비즈니스 로직 owner (구현체 함수 호출)
    address public operator1 = address(0x1001);
    address public user1 = address(0x2001);
    address public user2 = address(0x2002);

    uint256 constant RAY = 1e27;
    uint256 constant INITIAL_TON = 10000 * 1e18;  // TON은 18 decimals
    uint256 constant INITIAL_WTON = 10000 * RAY;  // WTON은 27 decimals

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

        // 컨트랙트 참조
        depositManager = DepositManager(depositManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);

        // MockLayer2 배포 및 SeigManager 설정
        mockLayer2 = new MockLayer2ForTest(operator1);
        mockLayer2.setSeigManager(seigManagerProxy);

        // minimumAmount를 0으로 설정 (operator 요구사항 비활성화)
        SeigManagerV1_2(seigManagerProxy).setMinimumAmount(0);

        // 테스트용 시뇨리지 파라미터 설정 (mainnet 기본값 대신 테스트용 값 사용)
        // seigStartBlock이 0이면 mainnet 기본값(10837698)을 사용하는데, 테스트에서는 block.number가 작아서 underflow 발생
        // 따라서 현재 block.number보다 작은 값으로 설정
        vm.roll(10);  // block.number를 10으로 설정
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(1);  // seigStartBlock을 1로 설정
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50_000_000 * RAY);  // 50M TON in WTON
        SeigManagerV1_2(seigManagerProxy).setBurntAmountAtDAO(1);  // 0이 아닌 값으로 설정 (기본값과 구분)

        // 사용자에게 TON/WTON 지급
        MockTON(ton).mint(user1, INITIAL_TON);
        MockTON(ton).mint(user2, INITIAL_TON);
        MockWTON(wton).mint(user1, INITIAL_WTON);
        MockWTON(wton).mint(user2, INITIAL_WTON);

        vm.stopPrank();
    }

    // ==========================================
    // Layer2 등록 테스트
    // ==========================================

    function test_registerLayer2() public {
        // Layer2Registry에 MINTER_ROLE 부여 (operator1이 등록할 수 있도록)
        // 또는 SeigManager가 minter이므로 SeigManager를 통해 등록

        // operator1이 자신의 layer2를 등록
        vm.prank(operator1);
        bool success = layer2Registry.registerAndDeployCoinage(
            address(mockLayer2),
            seigManagerProxy
        );
        assertTrue(success, "Layer2 registration should succeed");

        // 등록 확인
        assertTrue(layer2Registry.layer2s(address(mockLayer2)), "Layer2 should be registered");
        assertEq(layer2Registry.numLayer2s(), 1, "Should have 1 layer2");
    }

    function test_registerLayer2_notOperator_reverts() public {
        // operator가 아닌 사용자가 등록 시도
        vm.prank(user1);
        vm.expectRevert();
        layer2Registry.registerAndDeployCoinage(
            address(mockLayer2),
            seigManagerProxy
        );
    }

    // ==========================================
    // WTON Deposit 테스트
    // ==========================================

    function test_deposit_wton() public {
        // 1. Layer2 등록
        _registerMockLayer2();

        uint256 depositAmount = 100 * RAY;

        // 2. WTON approve
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);

        // 3. Deposit
        bool success = DepositManager(depositManagerProxy).deposit(
            address(mockLayer2),
            user1,
            depositAmount
        );
        vm.stopPrank();

        assertTrue(success, "Deposit should succeed");

        // 4. 잔액 확인
        assertEq(depositManager.accStaked(address(mockLayer2), user1), depositAmount, "Staked amount mismatch");
        assertEq(depositManager.accStakedLayer2(address(mockLayer2)), depositAmount, "Layer2 total mismatch");
    }

    function test_deposit_wton_multiple() public {
        _registerMockLayer2();

        uint256 amount1 = 100 * RAY;
        uint256 amount2 = 200 * RAY;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, amount1 + amount2);

        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, amount1);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, amount2);
        vm.stopPrank();

        assertEq(depositManager.accStaked(address(mockLayer2), user1), amount1 + amount2);
    }

    // ==========================================
    // TON approveAndCall 스테이킹 테스트
    // ==========================================

    function test_deposit_ton_approveAndCall() public {
        _registerMockLayer2();

        uint256 tonAmount = 100 * 1e18;  // 100 TON

        // TON approveAndCall로 스테이킹
        // data = abi.encode(depositManagerProxy, layer2)
        bytes memory data = abi.encode(depositManagerProxy, address(mockLayer2));

        vm.prank(user1);
        bool success = MockTON(ton).approveAndCall(
            wton,  // WTON 컨트랙트로 전송
            tonAmount,
            data
        );

        assertTrue(success, "approveAndCall should succeed");

        // WTON으로 변환되어 스테이킹됨 (100 TON = 100 * 1e27 WTON)
        uint256 expectedWton = tonAmount * 1e9;
        assertEq(depositManager.accStaked(address(mockLayer2), user1), expectedWton, "Staked amount mismatch");
    }

    // ==========================================
    // 출금 요청 테스트
    // ==========================================

    function test_requestWithdrawal() public {
        _registerMockLayer2();

        uint256 depositAmount = 100 * RAY;
        uint256 withdrawAmount = 50 * RAY;

        // 스테이킹
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, depositAmount);

        // 출금 요청
        bool success = DepositManagerV1_2(depositManagerProxy).requestWithdrawal(
            address(mockLayer2),
            withdrawAmount
        );
        vm.stopPrank();

        assertTrue(success, "Request withdrawal should succeed");
        assertEq(depositManager.pendingUnstaked(address(mockLayer2), user1), withdrawAmount, "Pending amount mismatch");
    }

    function test_requestWithdrawal_full() public {
        _registerMockLayer2();

        uint256 depositAmount = 100 * RAY;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, depositAmount);

        // 전액 출금 요청
        DepositManagerV1_2(depositManagerProxy).requestWithdrawal(address(mockLayer2), depositAmount);
        vm.stopPrank();

        assertEq(depositManager.pendingUnstaked(address(mockLayer2), user1), depositAmount);
    }

    // ==========================================
    // 출금 처리 테스트
    // ==========================================

    function test_processRequest() public {
        _registerMockLayer2();

        uint256 depositAmount = 100 * RAY;
        uint256 withdrawAmount = 50 * RAY;

        // 스테이킹 및 출금 요청
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, depositAmount);
        DepositManagerV1_2(depositManagerProxy).requestWithdrawal(address(mockLayer2), withdrawAmount);
        vm.stopPrank();

        // 출금 대기 기간 경과
        uint256 delay = depositManager.globalWithdrawalDelay();
        vm.roll(block.number + delay + 1);

        // 출금 처리
        uint256 balanceBefore = MockWTON(wton).balanceOf(user1);

        vm.prank(user1);
        bool success = depositManager.processRequest(address(mockLayer2), false);

        assertTrue(success, "Process request should succeed");
        assertEq(MockWTON(wton).balanceOf(user1), balanceBefore + withdrawAmount, "WTON balance mismatch");
        assertEq(depositManager.pendingUnstaked(address(mockLayer2), user1), 0, "Pending should be 0");
    }

    function test_processRequest_beforeDelay_reverts() public {
        _registerMockLayer2();

        uint256 depositAmount = 100 * RAY;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, depositAmount);
        DepositManagerV1_2(depositManagerProxy).requestWithdrawal(address(mockLayer2), depositAmount);
        vm.stopPrank();

        // 대기 기간 경과 없이 바로 출금 시도
        vm.prank(user1);
        vm.expectRevert();
        depositManager.processRequest(address(mockLayer2), false);
    }

    // ==========================================
    // UpdateSeigniorage 테스트
    // ==========================================

    /// @notice updateSeigniorage 테스트
    /// @dev Layer2가 직접 SeigManager.updateSeigniorage()를 호출해야 함
    function test_updateSeigniorage() public {
        _registerMockLayer2();

        uint256 depositAmount = 100 * RAY;

        // 스테이킹
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, depositAmount);
        vm.stopPrank();

        // 블록 진행
        vm.roll(block.number + 100);

        // updateSeigniorage는 Layer2가 직접 호출해야 함 (msg.sender == layer2)
        bool success = mockLayer2.updateSeigniorage();
        assertTrue(success, "updateSeigniorage should succeed");
    }

    /// @notice updateSeigniorageLayer 테스트
    /// @dev SeigManager.updateSeigniorageLayer(layer2)가 layer2.updateSeigniorage()를 호출
    function test_updateSeigniorageLayer() public {
        _registerMockLayer2();

        uint256 depositAmount = 100 * RAY;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, depositAmount);
        vm.stopPrank();

        vm.roll(block.number + 100);

        // updateSeigniorageLayer는 layer2.updateSeigniorage()를 호출
        // layer2.updateSeigniorage()가 SeigManager.updateSeigniorage()를 콜백
        bool success = SeigManagerV1_4(seigManagerProxy).updateSeigniorageLayer(address(mockLayer2));
        assertTrue(success, "updateSeigniorageLayer should succeed");
    }

    // ==========================================
    // 통합 시나리오 테스트
    // ==========================================

    /// @notice 전체 시나리오 테스트: Layer2 등록 → 스테이킹 → 시뇨리지 업데이트 → 출금
    function test_fullScenario() public {
        // 1. Layer2 등록 (coinage 배포 포함)
        _registerMockLayer2();

        uint256 depositAmount = 500 * RAY;

        // 2. 스테이킹
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManager(depositManagerProxy).deposit(address(mockLayer2), user1, depositAmount);
        vm.stopPrank();

        assertEq(depositManager.accStaked(address(mockLayer2), user1), depositAmount);

        // 3. 블록 진행 및 시뇨리지 업데이트 (Layer2가 직접 호출)
        vm.roll(block.number + 100);
        bool success = mockLayer2.updateSeigniorage();
        assertTrue(success, "updateSeigniorage should succeed");

        // 4. 부분 출금 요청
        uint256 withdrawAmount = 200 * RAY;
        vm.prank(user1);
        DepositManagerV1_2(depositManagerProxy).requestWithdrawal(address(mockLayer2), withdrawAmount);

        assertEq(depositManager.pendingUnstaked(address(mockLayer2), user1), withdrawAmount);

        // 5. 대기 기간 후 출금 처리
        vm.roll(block.number + depositManager.globalWithdrawalDelay() + 1);

        vm.prank(user1);
        depositManager.processRequest(address(mockLayer2), false);

        assertEq(depositManager.pendingUnstaked(address(mockLayer2), user1), 0);
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    function _registerMockLayer2() internal {
        vm.prank(operator1);
        layer2Registry.registerAndDeployCoinage(
            address(mockLayer2),
            seigManagerProxy
        );
    }
}
