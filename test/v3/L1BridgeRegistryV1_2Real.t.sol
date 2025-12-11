// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../src/layer2/L1BridgeRegistryV1_2.sol";

/// @title L1BridgeRegistryV1_2RealTest
/// @notice 실제 L1BridgeRegistryV1_2 컨트랙트의 커버리지 테스트
/// @dev Harness 패턴을 사용하여 내부 함수 및 스토리지 접근

// ==========================================
// Mock Contracts
// ==========================================

contract MockTONForRegistry {
    mapping(address => uint256) public balanceOf;

    function setBalance(address account, uint256 amount) external {
        balanceOf[account] = amount;
    }
}

contract MockSystemConfigForRegistry {
    address public l1StandardBridge;
    address public optimismPortal;

    constructor(address _bridge, address _portal) {
        l1StandardBridge = _bridge;
        optimismPortal = _portal;
    }
}

contract MockLayer2ManagerForRegistry {
    uint256 public updateCount;
    address public lastUpdatedRollupConfig;

    function updateBridgedTON(address rollupConfig) external {
        updateCount++;
        lastUpdatedRollupConfig = rollupConfig;
    }
}

/// @notice L1BridgeRegistryV1_2 Harness for testing
contract L1BridgeRegistryV1_2Harness is L1BridgeRegistryV1_2 {
    function initialize(address _ton, address _layer2Manager) external {
        ton = _ton;
        layer2Manager = _layer2Manager;
    }

    function setRollupInfo(
        address rollupConfig,
        uint8 _type,
        address _l2TON,
        bool _rejectedSeigs,
        bool _rejectedL2Deposit
    ) external {
        rollupInfo[rollupConfig] = ROLLUP_INFO({
            rollupType: _type,
            l2TON: _l2TON,
            rejectedSeigs: _rejectedSeigs,
            rejectedL2Deposit: _rejectedL2Deposit,
            name: ""
        });
    }

    function setBridge(address bridge, bool registered) external {
        l1Bridge[bridge] = registered;
    }

    function setPortal(address _portal, bool registered) external {
        portal[_portal] = registered;
    }

    function setLastKnownTVL(address target, uint256 tvl) external {
        lastKnownTVL[target] = tvl;
    }

    function setLastTVLUpdateBlock(address target, uint256 blockNum) external {
        lastTVLUpdateBlock[target] = blockNum;
    }
}

contract L1BridgeRegistryV1_2RealTest is Test {
    L1BridgeRegistryV1_2Harness public registry;
    MockTONForRegistry public mockTon;
    MockLayer2ManagerForRegistry public mockLayer2Manager;

    address public bridge1 = address(0x1001);
    address public bridge2 = address(0x1002);
    address public portal1 = address(0x2001);
    address public portal2 = address(0x2002);

    MockSystemConfigForRegistry public rollupConfig1;
    MockSystemConfigForRegistry public rollupConfig2;
    MockSystemConfigForRegistry public rollupConfig3;

    address public owner = address(this);

    function setUp() public {
        mockTon = new MockTONForRegistry();
        mockLayer2Manager = new MockLayer2ManagerForRegistry();

        registry = new L1BridgeRegistryV1_2Harness();
        registry.initialize(address(mockTon), address(mockLayer2Manager));

        // Setup rollup configs
        rollupConfig1 = new MockSystemConfigForRegistry(bridge1, address(0)); // Legacy
        rollupConfig2 = new MockSystemConfigForRegistry(address(0), portal1); // Bedrock
        rollupConfig3 = new MockSystemConfigForRegistry(bridge2, portal2);    // Both

        // Register bridges and portals
        registry.setBridge(bridge1, true);
        registry.setBridge(bridge2, true);
        registry.setPortal(portal1, true);
        registry.setPortal(portal2, true);

        // Setup rollup info
        registry.setRollupInfo(address(rollupConfig1), 1, address(0x3001), false, false); // Legacy
        registry.setRollupInfo(address(rollupConfig2), 2, address(0x3002), false, false); // Bedrock
        registry.setRollupInfo(address(rollupConfig3), 2, address(0x3003), false, false); // Bedrock with both
    }

    // ==========================================
    // layer2TVL Tests (State-changing)
    // ==========================================

    function test_layer2TVL_legacy_firstCall() public {
        mockTon.setBalance(bridge1, 1000e18);

        uint256 tvl = registry.layer2TVL(address(rollupConfig1));

        assertEq(tvl, 1000e18, "TVL should match bridge balance");
        assertEq(registry.lastKnownTVL(bridge1), 1000e18, "Cache should be updated");
        assertEq(registry.lastTVLUpdateBlock(bridge1), block.number, "Block should be recorded");
        assertEq(mockLayer2Manager.updateCount(), 1, "Layer2Manager should be notified");
    }

    function test_layer2TVL_bedrock_firstCall() public {
        mockTon.setBalance(portal1, 2000e18);

        uint256 tvl = registry.layer2TVL(address(rollupConfig2));

        assertEq(tvl, 2000e18, "TVL should match portal balance");
        assertEq(registry.lastKnownTVL(portal1), 2000e18, "Cache should be updated");
        assertEq(mockLayer2Manager.updateCount(), 1, "Layer2Manager should be notified");
    }

    function test_layer2TVL_noChange_noNotification() public {
        mockTon.setBalance(bridge1, 1000e18);

        // First call
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 1);

        // Second call with same TVL
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 1, "No additional notification when TVL unchanged");
    }

    function test_layer2TVL_change_notification() public {
        mockTon.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 1);

        // Change TVL
        mockTon.setBalance(bridge1, 2000e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 2, "Should notify on TVL change");
    }

    function test_layer2TVL_decrease_notification() public {
        mockTon.setBalance(bridge1, 2000e18);
        registry.layer2TVL(address(rollupConfig1));

        // Decrease TVL
        mockTon.setBalance(bridge1, 500e18);
        registry.layer2TVL(address(rollupConfig1));

        assertEq(mockLayer2Manager.updateCount(), 2);
        assertEq(registry.lastKnownTVL(bridge1), 500e18);
    }

    function test_layer2TVL_unregisteredBridge() public {
        // Unregister bridge
        registry.setBridge(bridge1, false);
        mockTon.setBalance(bridge1, 1000e18);

        uint256 tvl = registry.layer2TVL(address(rollupConfig1));

        assertEq(tvl, 0, "Unregistered bridge should return 0");
    }

    function test_layer2TVL_unregisteredPortal() public {
        // Unregister portal
        registry.setPortal(portal1, false);
        mockTon.setBalance(portal1, 1000e18);

        uint256 tvl = registry.layer2TVL(address(rollupConfig2));

        assertEq(tvl, 0, "Unregistered portal should return 0");
    }

    function test_layer2TVL_unknownType() public {
        MockSystemConfigForRegistry unknownConfig = new MockSystemConfigForRegistry(bridge1, portal1);
        registry.setRollupInfo(address(unknownConfig), 0, address(0), false, false); // Type 0

        uint256 tvl = registry.layer2TVL(address(unknownConfig));

        assertEq(tvl, 0, "Unknown type should return 0");
    }

    // ==========================================
    // layer2TVLView Tests (Pure view)
    // ==========================================

    function test_layer2TVLView_legacy() public {
        mockTon.setBalance(bridge1, 1000e18);

        uint256 tvl = registry.layer2TVLView(address(rollupConfig1));

        assertEq(tvl, 1000e18);
        // Should NOT update cache or notify
        assertEq(registry.lastKnownTVL(bridge1), 0);
        assertEq(mockLayer2Manager.updateCount(), 0);
    }

    function test_layer2TVLView_bedrock() public {
        mockTon.setBalance(portal1, 2000e18);

        uint256 tvl = registry.layer2TVLView(address(rollupConfig2));

        assertEq(tvl, 2000e18);
    }

    function test_layer2TVLView_unregisteredBridge() public {
        registry.setBridge(bridge1, false);
        mockTon.setBalance(bridge1, 1000e18);

        uint256 tvl = registry.layer2TVLView(address(rollupConfig1));

        assertEq(tvl, 0);
    }

    // ==========================================
    // getLastKnownTVL Tests
    // ==========================================

    function test_getLastKnownTVL_afterUpdate() public {
        mockTon.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));

        (uint256 tvl, uint256 updateBlock) = registry.getLastKnownTVL(address(rollupConfig1));

        assertEq(tvl, 1000e18);
        assertEq(updateBlock, block.number);
    }

    function test_getLastKnownTVL_noUpdate() public {
        (uint256 tvl, uint256 updateBlock) = registry.getLastKnownTVL(address(rollupConfig1));

        assertEq(tvl, 0);
        assertEq(updateBlock, 0);
    }

    function test_getLastKnownTVL_multipleUpdates() public {
        mockTon.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));

        vm.roll(block.number + 100);

        mockTon.setBalance(bridge1, 2000e18);
        registry.layer2TVL(address(rollupConfig1));

        (uint256 tvl, uint256 updateBlock) = registry.getLastKnownTVL(address(rollupConfig1));

        assertEq(tvl, 2000e18);
        assertEq(updateBlock, block.number);
    }

    // ==========================================
    // triggerBridgedTONUpdate Tests
    // ==========================================

    function test_triggerBridgedTONUpdate_basic() public {
        mockTon.setBalance(bridge1, 1000e18);

        registry.triggerBridgedTONUpdate(address(rollupConfig1));

        assertEq(mockLayer2Manager.updateCount(), 1);
        assertEq(registry.lastKnownTVL(bridge1), 1000e18);
    }

    function test_triggerBridgedTONUpdate_unregistered_reverts() public {
        MockSystemConfigForRegistry unregistered = new MockSystemConfigForRegistry(address(0), address(0));
        registry.setRollupInfo(address(unregistered), 0, address(0), false, false); // Type 0 = not registered

        vm.expectRevert("NotRegistered");
        registry.triggerBridgedTONUpdate(address(unregistered));
    }

    function test_triggerBridgedTONUpdate_multipleCallsSameBlock() public {
        mockTon.setBalance(bridge1, 1000e18);

        registry.triggerBridgedTONUpdate(address(rollupConfig1));
        registry.triggerBridgedTONUpdate(address(rollupConfig1));
        registry.triggerBridgedTONUpdate(address(rollupConfig1));

        // Only first call should trigger notification (TVL unchanged after first)
        assertEq(mockLayer2Manager.updateCount(), 1);
    }

    // ==========================================
    // batchUpdateBridgedTON Tests
    // ==========================================

    function test_batchUpdateBridgedTON_basic() public {
        mockTon.setBalance(bridge1, 1000e18);
        mockTon.setBalance(portal1, 2000e18);

        address[] memory rollupConfigs = new address[](2);
        rollupConfigs[0] = address(rollupConfig1);
        rollupConfigs[1] = address(rollupConfig2);

        registry.batchUpdateBridgedTON(rollupConfigs);

        assertEq(mockLayer2Manager.updateCount(), 2);
    }

    function test_batchUpdateBridgedTON_skipUnregistered() public {
        mockTon.setBalance(bridge1, 1000e18);

        MockSystemConfigForRegistry unregistered = new MockSystemConfigForRegistry(address(0), address(0));
        registry.setRollupInfo(address(unregistered), 0, address(0), false, false);

        address[] memory rollupConfigs = new address[](2);
        rollupConfigs[0] = address(rollupConfig1);
        rollupConfigs[1] = address(unregistered);

        registry.batchUpdateBridgedTON(rollupConfigs);

        // Only registered one should be processed
        assertEq(mockLayer2Manager.updateCount(), 1);
    }

    function test_batchUpdateBridgedTON_empty() public {
        address[] memory rollupConfigs = new address[](0);

        registry.batchUpdateBridgedTON(rollupConfigs);

        assertEq(mockLayer2Manager.updateCount(), 0);
    }

    function test_batchUpdateBridgedTON_singleElement() public {
        mockTon.setBalance(bridge1, 1000e18);

        address[] memory rollupConfigs = new address[](1);
        rollupConfigs[0] = address(rollupConfig1);

        registry.batchUpdateBridgedTON(rollupConfigs);

        assertEq(mockLayer2Manager.updateCount(), 1);
    }

    // ==========================================
    // Event Tests
    // ==========================================

    function test_TVLChanged_event_emitted() public {
        mockTon.setBalance(bridge1, 1000e18);

        vm.expectEmit(true, true, false, true);
        emit L1BridgeRegistryV1_2.TVLChanged(address(rollupConfig1), 0, 1000e18, bridge1);

        registry.layer2TVL(address(rollupConfig1));
    }

    function test_TVLChanged_event_onIncrease() public {
        mockTon.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));

        mockTon.setBalance(bridge1, 2000e18);

        vm.expectEmit(true, true, false, true);
        emit L1BridgeRegistryV1_2.TVLChanged(address(rollupConfig1), 1000e18, 2000e18, bridge1);

        registry.layer2TVL(address(rollupConfig1));
    }

    // ==========================================
    // Edge Cases
    // ==========================================

    function test_layer2TVL_zeroToNonZero() public {
        // Initially 0
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 0); // 0 to 0 = no change

        // Set to non-zero
        mockTon.setBalance(bridge1, 100e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 1); // 0 to 100 = change
    }

    function test_layer2TVL_nonZeroToZero() public {
        mockTon.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 1);

        // Set to zero
        mockTon.setBalance(bridge1, 0);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(mockLayer2Manager.updateCount(), 2); // 1000 to 0 = change
    }

    function test_layer2TVL_noLayer2Manager() public {
        // Create registry without layer2Manager
        L1BridgeRegistryV1_2Harness registryNoManager = new L1BridgeRegistryV1_2Harness();
        registryNoManager.initialize(address(mockTon), address(0));
        registryNoManager.setBridge(bridge1, true);
        registryNoManager.setRollupInfo(address(rollupConfig1), 1, address(0x3001), false, false);

        mockTon.setBalance(bridge1, 1000e18);

        // Should not revert even without layer2Manager
        uint256 tvl = registryNoManager.layer2TVL(address(rollupConfig1));
        assertEq(tvl, 1000e18);
    }

    // ==========================================
    // Fuzz Tests
    // ==========================================

    function testFuzz_layer2TVL(uint256 amount) public {
        amount = bound(amount, 0, 1e32);

        mockTon.setBalance(bridge1, amount);

        uint256 tvl = registry.layer2TVL(address(rollupConfig1));

        assertEq(tvl, amount);
    }

    function testFuzz_layer2TVLView(uint256 amount) public {
        amount = bound(amount, 0, 1e32);

        mockTon.setBalance(bridge1, amount);

        uint256 tvl = registry.layer2TVLView(address(rollupConfig1));

        assertEq(tvl, amount);
    }

    function testFuzz_tvlChanges(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, 0, 1e32);
        amount2 = bound(amount2, 0, 1e32);

        mockTon.setBalance(bridge1, amount1);
        registry.layer2TVL(address(rollupConfig1));

        uint256 countAfterFirst = mockLayer2Manager.updateCount();

        mockTon.setBalance(bridge1, amount2);
        registry.layer2TVL(address(rollupConfig1));

        uint256 countAfterSecond = mockLayer2Manager.updateCount();

        if (amount1 != amount2) {
            assertEq(countAfterSecond, countAfterFirst + 1, "Should notify on change");
        } else {
            assertEq(countAfterSecond, countAfterFirst, "Should not notify when unchanged");
        }
    }
}
