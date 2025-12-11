// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../src/layer2/Layer2ManagerV1_2.sol";

/// @title Layer2ManagerV1_2RealTest
/// @notice 실제 Layer2ManagerV1_2 컨트랙트의 커버리지 테스트
/// @dev Harness 패턴을 사용하여 내부 함수 및 스토리지 접근

// ==========================================
// Mock Contracts
// ==========================================

contract MockTONForL2 {
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

contract MockWTONForL2 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public tonAddress;

    constructor(address _ton) {
        tonAddress = _ton;
    }

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

    function swapFromTON(uint256 amount) external returns (bool) {
        // Convert TON to WTON (1 TON = 1e9 WTON)
        balanceOf[msg.sender] += amount * 1e9;
        return true;
    }
}

contract MockL1BridgeRegistryForL2 {
    struct RollupInfo {
        uint8 rollupType;
        address l2TON;
        bool rejectedSeigs;
        bool rejectedL2Deposit;
        string name;
    }

    mapping(address => RollupInfo) public rollups;
    mapping(address => bool) public l1Bridge;
    mapping(address => bool) public portal;

    function setRollupInfo(
        address rollupConfig,
        uint8 _type,
        address _l2TON,
        bool _rejectedSeigs,
        bool _rejectedL2Deposit
    ) external {
        rollups[rollupConfig] = RollupInfo({
            rollupType: _type,
            l2TON: _l2TON,
            rejectedSeigs: _rejectedSeigs,
            rejectedL2Deposit: _rejectedL2Deposit,
            name: ""
        });
    }

    function setBridge(address bridge) external {
        l1Bridge[bridge] = true;
    }

    function setPortal(address _portal) external {
        portal[_portal] = true;
    }

    function getRollupInfo(address rollupConfig) external view returns (
        uint8 _rollupType,
        address _l2TON,
        bool _rejectedSeigs,
        bool _rejectedL2Deposit,
        string memory _name
    ) {
        RollupInfo memory info = rollups[rollupConfig];
        return (info.rollupType, info.l2TON, info.rejectedSeigs, info.rejectedL2Deposit, info.name);
    }

    function rollupType(address rollupConfig) external view returns (uint8) {
        return rollups[rollupConfig].rollupType;
    }

    function l2TON(address rollupConfig) external view returns (address) {
        return rollups[rollupConfig].l2TON;
    }
}

contract MockSystemConfigForL2 {
    address public l1StandardBridge;
    address public optimismPortal;

    constructor(address _bridge, address _portal) {
        l1StandardBridge = _bridge;
        optimismPortal = _portal;
    }
}

contract MockSeigManagerForL2 {
    bool public excludeResult = true;
    bool public includeResult = true;

    mapping(address => uint256) public bridgedTON;

    function setExcludeResult(bool result) external {
        excludeResult = result;
    }

    function setIncludeResult(bool result) external {
        includeResult = result;
    }

    function excludeFromL2Seigniorage(address) external view returns (bool) {
        return excludeResult;
    }

    function includeFromL2Seigniorage(address) external view returns (bool) {
        return includeResult;
    }

    function initializeBridgedTON(address layer2, uint256 amount) external {
        bridgedTON[layer2] = amount;
    }

    function onBridgedTONChange(address layer2, uint256 newAmount) external {
        bridgedTON[layer2] = newAmount;
    }
}

contract MockOperatorManagerFactory {
    address public lastCreatedOperator;
    uint256 public operatorCount;

    function createOperatorManager(address) external returns (address) {
        operatorCount++;
        lastCreatedOperator = address(uint160(0x8000 + operatorCount));
        return lastCreatedOperator;
    }
}

contract MockDAOCommittee {
    address public lastCandidateAddOn;
    uint256 public candidateCount;

    function createCandidateAddOn(string calldata, address) external returns (address) {
        candidateCount++;
        lastCandidateAddOn = address(uint160(0x9000 + candidateCount));
        return lastCandidateAddOn;
    }
}

contract MockDepositManagerForL2 {
    bool public depositResult = true;

    function deposit(address, address, uint256) external view returns (bool) {
        return depositResult;
    }
}

/// @notice Layer2ManagerV1_2 Harness for testing
contract Layer2ManagerV1_2Harness is Layer2ManagerV1_2 {
    function initialize(
        address _l1BridgeRegistry,
        address _operatorManagerFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _seigManager
    ) external {
        l1BridgeRegistry = _l1BridgeRegistry;
        operatorManagerFactory = _operatorManagerFactory;
        ton = _ton;
        wton = _wton;
        dao = _dao;
        depositManager = _depositManager;
        seigManager = _seigManager;
        minimumInitialDepositAmount = 1000e18; // 1000 TON minimum
    }

    function setRollupConfigInfo(address rollupConfig, uint8 status, address operatorManager) external {
        rollupConfigInfo[rollupConfig] = SeqSeigStatus({
            status: status,
            operatorManager: operatorManager
        });
    }

    function setOperatorInfo(address operator, address rollupConfig, address candidateAddOn) external {
        operatorInfo[operator] = CandidateAddOnInfo({
            rollupConfig: rollupConfig,
            candidateAddOn: candidateAddOn
        });
    }

    function setOperatorOfLayer(address layer2, address operator) external {
        operatorOfLayer[layer2] = operator;
    }

    function setCachedBridgedTON(address rollupConfig, uint256 amount) external {
        cachedBridgedTON[rollupConfig] = amount;
    }

    // Grant admin role for testing
    function grantAdminRole(address account) external {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }
}

contract Layer2ManagerV1_2RealTest is Test {
    Layer2ManagerV1_2Harness public layer2Manager;
    MockTONForL2 public mockTon;
    MockWTONForL2 public mockWton;
    MockL1BridgeRegistryForL2 public mockL1BridgeRegistry;
    MockSeigManagerForL2 public mockSeigManager;
    MockOperatorManagerFactory public mockOperatorFactory;
    MockDAOCommittee public mockDAO;
    MockDepositManagerForL2 public mockDepositManager;

    address public bridge1 = address(0x1001);
    address public portal1 = address(0x2001);
    MockSystemConfigForL2 public rollupConfig1;
    MockSystemConfigForL2 public rollupConfig2;

    address public operator1 = address(0x3001);
    address public layer2_1 = address(0x4001);
    address public owner = address(this);

    function setUp() public {
        mockTon = new MockTONForL2();
        mockWton = new MockWTONForL2(address(mockTon));
        mockL1BridgeRegistry = new MockL1BridgeRegistryForL2();
        mockSeigManager = new MockSeigManagerForL2();
        mockOperatorFactory = new MockOperatorManagerFactory();
        mockDAO = new MockDAOCommittee();
        mockDepositManager = new MockDepositManagerForL2();

        layer2Manager = new Layer2ManagerV1_2Harness();
        layer2Manager.initialize(
            address(mockL1BridgeRegistry),
            address(mockOperatorFactory),
            address(mockTon),
            address(mockWton),
            address(mockDAO),
            address(mockDepositManager),
            address(mockSeigManager)
        );
        layer2Manager.grantAdminRole(owner);

        // Setup rollup configs
        rollupConfig1 = new MockSystemConfigForL2(bridge1, address(0));
        rollupConfig2 = new MockSystemConfigForL2(address(0), portal1);

        // Setup L1BridgeRegistry mock
        mockL1BridgeRegistry.setRollupInfo(address(rollupConfig1), 1, address(0x5001), false, false);
        mockL1BridgeRegistry.setRollupInfo(address(rollupConfig2), 2, address(0x5002), false, false);
        mockL1BridgeRegistry.setBridge(bridge1);
        mockL1BridgeRegistry.setPortal(portal1);
    }

    // ==========================================
    // getBridgedTON Tests
    // ==========================================

    function test_getBridgedTON_legacyType() public {
        // Type 1 - Legacy Optimism
        // Need to register the rollup first for _checkL1BridgeDetail to work
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);

        mockTon.setBalance(bridge1, 1000e18);

        uint256 bridgedTON = layer2Manager.getBridgedTON(address(rollupConfig1));
        assertEq(bridgedTON, 1000e18, "Should return TON balance of bridge");
    }

    function test_getBridgedTON_bedrockType() public {
        // Type 2 - Bedrock
        // Need to create a proper config with both bridge and portal
        address bedrockBridge = address(0x1234);
        MockSystemConfigForL2 bedrockConfig = new MockSystemConfigForL2(bedrockBridge, portal1);
        mockL1BridgeRegistry.setRollupInfo(address(bedrockConfig), 2, address(0x5002), false, false);

        // Register the rollup
        layer2Manager.setRollupConfigInfo(address(bedrockConfig), 1, operator1);

        mockTon.setBalance(portal1, 2000e18);

        uint256 bridgedTON = layer2Manager.getBridgedTON(address(bedrockConfig));
        assertEq(bridgedTON, 2000e18, "Should return TON balance of portal");
    }

    function test_getBridgedTON_unregistered() public {
        MockSystemConfigForL2 unregistered = new MockSystemConfigForL2(address(0x9999), address(0));

        uint256 bridgedTON = layer2Manager.getBridgedTON(address(unregistered));
        assertEq(bridgedTON, 0, "Unregistered should return 0");
    }

    // ==========================================
    // updateBridgedTON Tests
    // ==========================================

    function test_updateBridgedTON_basic() public {
        // Setup: register rollup first
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);
        layer2Manager.setOperatorInfo(operator1, address(rollupConfig1), layer2_1);

        mockTon.setBalance(bridge1, 1000e18);

        // Call from L1BridgeRegistry
        vm.prank(address(mockL1BridgeRegistry));
        layer2Manager.updateBridgedTON(address(rollupConfig1));

        assertEq(layer2Manager.getCachedBridgedTON(address(rollupConfig1)), 1000e18);
    }

    function test_updateBridgedTON_notL1BridgeRegistry_reverts() public {
        vm.prank(address(0x9999));
        vm.expectRevert("sender is not a L1BridgeRegistry");
        layer2Manager.updateBridgedTON(address(rollupConfig1));
    }

    function test_updateBridgedTON_unregistered() public {
        // Status = 0 (unregistered)
        vm.prank(address(mockL1BridgeRegistry));
        layer2Manager.updateBridgedTON(address(rollupConfig1));

        // Should not revert, just return early
        assertEq(layer2Manager.getCachedBridgedTON(address(rollupConfig1)), 0);
    }

    // ==========================================
    // getCachedBridgedTON Tests
    // ==========================================

    function test_getCachedBridgedTON() public {
        layer2Manager.setCachedBridgedTON(address(rollupConfig1), 500e18);

        uint256 cached = layer2Manager.getCachedBridgedTON(address(rollupConfig1));
        assertEq(cached, 500e18);
    }

    // ==========================================
    // pauseCandidateAddOn Tests
    // ==========================================

    function test_pauseCandidateAddOn_basic() public {
        // Setup
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);
        layer2Manager.setOperatorInfo(operator1, address(rollupConfig1), layer2_1);

        vm.prank(address(mockL1BridgeRegistry));
        layer2Manager.pauseCandidateAddOn(address(rollupConfig1));

        assertEq(layer2Manager.statusLayer2(address(rollupConfig1)), 2);
    }

    function test_pauseCandidateAddOn_wrongStatus_reverts() public {
        // Status is 0 (not 1)
        vm.prank(address(mockL1BridgeRegistry));
        vm.expectRevert(StatusError.selector);
        layer2Manager.pauseCandidateAddOn(address(rollupConfig1));
    }

    function test_pauseCandidateAddOn_notL1BridgeRegistry_reverts() public {
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);

        vm.prank(address(0x9999));
        vm.expectRevert("sender is not a L1BridgeRegistry");
        layer2Manager.pauseCandidateAddOn(address(rollupConfig1));
    }

    // ==========================================
    // unpauseCandidateAddOn Tests
    // ==========================================

    function test_unpauseCandidateAddOn_basic() public {
        // Setup - status = 2 (paused)
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 2, operator1);
        layer2Manager.setOperatorInfo(operator1, address(rollupConfig1), layer2_1);

        vm.prank(address(mockL1BridgeRegistry));
        layer2Manager.unpauseCandidateAddOn(address(rollupConfig1));

        assertEq(layer2Manager.statusLayer2(address(rollupConfig1)), 1);
    }

    function test_unpauseCandidateAddOn_wrongStatus_reverts() public {
        // Status is 1 (not 2)
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);

        vm.prank(address(mockL1BridgeRegistry));
        vm.expectRevert(StatusError.selector);
        layer2Manager.unpauseCandidateAddOn(address(rollupConfig1));
    }

    // ==========================================
    // transferL2Seigniorage Tests
    // ==========================================

    function test_transferL2Seigniorage_basic() public {
        // Setup
        layer2Manager.setOperatorOfLayer(layer2_1, operator1);
        mockWton.setBalance(address(layer2Manager), 1000e27);

        vm.prank(address(mockSeigManager));
        layer2Manager.transferL2Seigniorage(layer2_1, 500e27);

        assertEq(mockWton.balanceOf(operator1), 500e27);
    }

    function test_transferL2Seigniorage_notSeigManager_reverts() public {
        layer2Manager.setOperatorOfLayer(layer2_1, operator1);

        vm.prank(address(0x9999));
        vm.expectRevert("sender is not a SeigManager");
        layer2Manager.transferL2Seigniorage(layer2_1, 500e27);
    }

    function test_transferL2Seigniorage_wrongOperator_reverts() public {
        // No operator set for layer2_1

        vm.prank(address(mockSeigManager));
        vm.expectRevert("wrong operator");
        layer2Manager.transferL2Seigniorage(layer2_1, 500e27);
    }

    // ==========================================
    // Owner Functions Tests
    // ==========================================

    function test_setAddresses() public {
        address newRegistry = address(0x1111);
        address newFactory = address(0x2222);
        address newTon = address(0x3333);
        address newWton = address(0x4444);
        address newDao = address(0x5555);
        address newDeposit = address(0x6666);
        address newSeig = address(0x7777);
        address newSwap = address(0x8888);

        layer2Manager.setAddresses(
            newRegistry,
            newFactory,
            newTon,
            newWton,
            newDao,
            newDeposit,
            newSeig,
            newSwap
        );

        assertEq(layer2Manager.l1BridgeRegistry(), newRegistry);
        assertEq(layer2Manager.operatorManagerFactory(), newFactory);
        assertEq(layer2Manager.ton(), newTon);
        assertEq(layer2Manager.wton(), newWton);
        assertEq(layer2Manager.dao(), newDao);
        assertEq(layer2Manager.depositManager(), newDeposit);
        assertEq(layer2Manager.seigManager(), newSeig);
        assertEq(layer2Manager.swapProxy(), newSwap);
    }

    function test_setOperatorManagerFactory() public {
        address newFactory = address(0x1234);

        layer2Manager.setOperatorManagerFactory(newFactory);

        assertEq(layer2Manager.operatorManagerFactory(), newFactory);
    }

    function test_setMinimumInitialDepositAmount() public {
        uint256 newAmount = 5000e18;

        layer2Manager.setMinimumInitialDepositAmount(newAmount);

        assertEq(layer2Manager.minimumInitialDepositAmount(), newAmount);
    }

    function test_setMinimumInitialDepositAmount_sameValue_reverts() public {
        uint256 currentAmount = layer2Manager.minimumInitialDepositAmount();

        vm.expectRevert(bytes("same"));
        layer2Manager.setMinimumInitialDepositAmount(currentAmount);
    }

    // ==========================================
    // View Functions Tests
    // ==========================================

    function test_rollupConfigOfOperator() public {
        layer2Manager.setOperatorInfo(operator1, address(rollupConfig1), layer2_1);

        address rollupConfig = layer2Manager.rollupConfigOfOperator(operator1);
        assertEq(rollupConfig, address(rollupConfig1));
    }

    function test_operatorOfRollupConfig() public {
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);

        address operator = layer2Manager.operatorOfRollupConfig(address(rollupConfig1));
        assertEq(operator, operator1);
    }

    function test_candidateAddOnOfOperator() public {
        layer2Manager.setOperatorInfo(operator1, address(rollupConfig1), layer2_1);

        address candidate = layer2Manager.candidateAddOnOfOperator(operator1);
        assertEq(candidate, layer2_1);
    }

    function test_statusLayer2() public {
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);

        uint8 status = layer2Manager.statusLayer2(address(rollupConfig1));
        assertEq(status, 1);
    }

    function test_checkLayer2TVL_legacy() public {
        mockTon.setBalance(bridge1, 1000e18);

        (bool result, uint256 amount) = layer2Manager.checkLayer2TVL(address(rollupConfig1));

        assertTrue(result);
        assertEq(amount, 1000e18);
    }

    function test_checkLayer2TVL_bedrock() public {
        mockTon.setBalance(portal1, 2000e18);

        (bool result, uint256 amount) = layer2Manager.checkLayer2TVL(address(rollupConfig2));

        assertTrue(result);
        assertEq(amount, 2000e18);
    }

    function test_checkL1Bridge() public {
        (bool result, address l1Bridge, address portal, address l2Ton) =
            layer2Manager.checkL1Bridge(address(rollupConfig1));

        // Not registered yet, so result should be false
        assertFalse(result);
    }

    function test_availableRegister_legacy() public {
        mockTon.setBalance(bridge1, 1000e18);

        (bool result, uint256 amount) = layer2Manager.availableRegister(address(rollupConfig1));

        assertTrue(result);
        assertEq(amount, 1000e18);
    }

    function test_availableRegister_bedrock() public {
        // For bedrock, we need both l1StandardBridge and optimismPortal set in the SystemConfig
        address bridge2 = address(0x1111);
        MockSystemConfigForL2 bedrockConfig = new MockSystemConfigForL2(bridge2, portal1);
        mockL1BridgeRegistry.setRollupInfo(address(bedrockConfig), 2, address(0x5002), false, false);

        mockTon.setBalance(portal1, 2000e18);

        (bool result, uint256 amount) = layer2Manager.availableRegister(address(bedrockConfig));

        assertTrue(result);
        assertEq(amount, 2000e18);
    }

    function test_layerInfo() public {
        layer2Manager.setOperatorOfLayer(layer2_1, operator1);
        layer2Manager.setOperatorInfo(operator1, address(rollupConfig1), layer2_1);

        (address rollupConfig, address operator) = layer2Manager.layerInfo(layer2_1);

        assertEq(rollupConfig, address(rollupConfig1));
        assertEq(operator, operator1);
    }

    // ==========================================
    // Fuzz Tests
    // ==========================================

    function testFuzz_getBridgedTON(uint256 amount) public {
        amount = bound(amount, 0, 1e32);

        // Register the rollup first
        layer2Manager.setRollupConfigInfo(address(rollupConfig1), 1, operator1);

        mockTon.setBalance(bridge1, amount);

        uint256 bridgedTON = layer2Manager.getBridgedTON(address(rollupConfig1));
        assertEq(bridgedTON, amount);
    }

    function testFuzz_cachedBridgedTON(uint256 amount) public {
        amount = bound(amount, 0, 1e32);

        layer2Manager.setCachedBridgedTON(address(rollupConfig1), amount);

        assertEq(layer2Manager.getCachedBridgedTON(address(rollupConfig1)), amount);
    }
}
