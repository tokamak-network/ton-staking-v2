// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

/// @title L1BridgeRegistryV1_2Test
/// @notice L1BridgeRegistryV1_2 컨트랙트 단위 테스트
/// @dev TVL 변경 감지 및 Layer2Manager 알림 기능 테스트

// ==========================================
// Mock Contracts
// ==========================================

contract MockTON {
    mapping(address => uint256) public balanceOf;

    function setBalance(address addr, uint256 amount) external {
        balanceOf[addr] = amount;
    }
}

contract MockSystemConfig {
    address public l1StandardBridge;
    address public optimismPortal;

    constructor(address _bridge, address _portal) {
        l1StandardBridge = _bridge;
        optimismPortal = _portal;
    }
}

contract MockLayer2Manager {
    uint256 public updateCount;
    address public lastRollupConfig;

    function updateBridgedTON(address rollupConfig) external {
        updateCount++;
        lastRollupConfig = rollupConfig;
    }
}

/// @notice 간소화된 L1BridgeRegistryV1_2 (테스트용)
contract SimpleL1BridgeRegistryV1_2 {
    struct ROLLUP_INFO {
        uint8 rollupType;
        address l2TON;
        bool rejectedSeigs;
        bool rejectedL2Deposit;
        string name;
    }

    address public layer2Manager;
    address public ton;

    mapping(address => ROLLUP_INFO) public rollupInfo;
    mapping(address => bool) public l1Bridge;
    mapping(address => bool) public portal;
    mapping(address => uint256) public lastKnownTVL;
    mapping(address => uint256) public lastTVLUpdateBlock;

    event TVLChanged(
        address indexed rollupConfig,
        uint256 oldTVL,
        uint256 newTVL,
        address indexed bridgeOrPortal
    );

    constructor(address _ton, address _layer2Manager) {
        ton = _ton;
        layer2Manager = _layer2Manager;
    }

    function setRollupInfo(
        address rollupConfig,
        uint8 _type,
        address _l2TON
    ) external {
        rollupInfo[rollupConfig] = ROLLUP_INFO({
            rollupType: _type,
            l2TON: _l2TON,
            rejectedSeigs: false,
            rejectedL2Deposit: false,
            name: ""
        });
    }

    function setBridge(address bridge) external {
        l1Bridge[bridge] = true;
    }

    function setPortal(address _portal) external {
        portal[_portal] = true;
    }

    function layer2TVL(address rollupConfig) public returns (uint256 amount) {
        uint8 _type = rollupInfo[rollupConfig].rollupType;
        address targetAddress;

        if (_type == 1) {
            targetAddress = MockSystemConfig(rollupConfig).l1StandardBridge();
            if (l1Bridge[targetAddress]) {
                amount = MockTON(ton).balanceOf(targetAddress);
            }
        } else if (_type == 2) {
            targetAddress = MockSystemConfig(rollupConfig).optimismPortal();
            if (portal[targetAddress]) {
                amount = MockTON(ton).balanceOf(targetAddress);
            }
        }

        if (targetAddress != address(0)) {
            uint256 lastTVL = lastKnownTVL[targetAddress];

            if (amount != lastTVL) {
                lastKnownTVL[targetAddress] = amount;
                lastTVLUpdateBlock[targetAddress] = block.number;

                emit TVLChanged(rollupConfig, lastTVL, amount, targetAddress);

                if (layer2Manager != address(0)) {
                    try MockLayer2Manager(layer2Manager).updateBridgedTON(rollupConfig) {
                    } catch {}
                }
            }
        }
    }

    function layer2TVLView(address rollupConfig) public view returns (uint256 amount) {
        uint8 _type = rollupInfo[rollupConfig].rollupType;

        if (_type == 1) {
            address l1Bridge_ = MockSystemConfig(rollupConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = MockTON(ton).balanceOf(l1Bridge_);
        } else if (_type == 2) {
            address optimismPortal_ = MockSystemConfig(rollupConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = MockTON(ton).balanceOf(optimismPortal_);
        }
    }

    function triggerBridgedTONUpdate(address rollupConfig) external {
        uint8 _type = rollupInfo[rollupConfig].rollupType;
        require(_type != 0, "NotRegistered");
        layer2TVL(rollupConfig);
    }

    function getLastKnownTVL(address rollupConfig) external view returns (uint256 tvl, uint256 updateBlock) {
        uint8 _type = rollupInfo[rollupConfig].rollupType;
        address targetAddress;

        if (_type == 1) {
            targetAddress = MockSystemConfig(rollupConfig).l1StandardBridge();
        } else if (_type == 2) {
            targetAddress = MockSystemConfig(rollupConfig).optimismPortal();
        }

        if (targetAddress != address(0)) {
            tvl = lastKnownTVL[targetAddress];
            updateBlock = lastTVLUpdateBlock[targetAddress];
        }
    }
}

contract L1BridgeRegistryV1_2Test is Test {
    SimpleL1BridgeRegistryV1_2 public registry;
    MockTON public ton;
    MockLayer2Manager public layer2Manager;

    address public bridge1 = address(0x1001);
    address public portal1 = address(0x2001);
    MockSystemConfig public rollupConfig1;
    MockSystemConfig public rollupConfig2;

    function setUp() public {
        ton = new MockTON();
        layer2Manager = new MockLayer2Manager();
        registry = new SimpleL1BridgeRegistryV1_2(address(ton), address(layer2Manager));

        // RollupConfig 설정
        rollupConfig1 = new MockSystemConfig(bridge1, address(0));
        rollupConfig2 = new MockSystemConfig(address(0), portal1);

        // 브리지/포탈 등록
        registry.setBridge(bridge1);
        registry.setPortal(portal1);

        // Rollup 타입 설정
        registry.setRollupInfo(address(rollupConfig1), 1, address(0x3001)); // Legacy
        registry.setRollupInfo(address(rollupConfig2), 2, address(0x3002)); // Bedrock
    }

    // ==========================================
    // TVL 조회 테스트
    // ==========================================

    function test_layer2TVLView_legacy() public {
        ton.setBalance(bridge1, 1000e18);
        uint256 tvl = registry.layer2TVLView(address(rollupConfig1));
        assertEq(tvl, 1000e18, "Legacy TVL should match bridge balance");
    }

    function test_layer2TVLView_bedrock() public {
        ton.setBalance(portal1, 2000e18);
        uint256 tvl = registry.layer2TVLView(address(rollupConfig2));
        assertEq(tvl, 2000e18, "Bedrock TVL should match portal balance");
    }

    function test_layer2TVLView_unregistered() public {
        MockSystemConfig unregistered = new MockSystemConfig(address(0x9999), address(0x9998));
        uint256 tvl = registry.layer2TVLView(address(unregistered));
        assertEq(tvl, 0, "Unregistered rollup should return 0");
    }

    // ==========================================
    // TVL 변경 감지 테스트
    // ==========================================

    function test_layer2TVL_detectsChange() public {
        ton.setBalance(bridge1, 1000e18);

        // 첫 호출 - 변경 감지
        vm.expectEmit(true, true, false, true);
        emit SimpleL1BridgeRegistryV1_2.TVLChanged(address(rollupConfig1), 0, 1000e18, bridge1);
        registry.layer2TVL(address(rollupConfig1));

        assertEq(layer2Manager.updateCount(), 1, "Layer2Manager should be called");
        assertEq(layer2Manager.lastRollupConfig(), address(rollupConfig1));
    }

    function test_layer2TVL_noChangeNoNotification() public {
        ton.setBalance(bridge1, 1000e18);

        // 첫 호출
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 1);

        // 두 번째 호출 - TVL 변경 없음
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 1, "No additional call when TVL unchanged");
    }

    function test_layer2TVL_multipleChanges() public {
        ton.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 1);

        // TVL 증가
        ton.setBalance(bridge1, 2000e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 2);

        // TVL 감소
        ton.setBalance(bridge1, 500e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 3);
    }

    // ==========================================
    // 캐시 테스트
    // ==========================================

    function test_getLastKnownTVL() public {
        ton.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));

        (uint256 tvl, uint256 updateBlock) = registry.getLastKnownTVL(address(rollupConfig1));
        assertEq(tvl, 1000e18);
        assertEq(updateBlock, block.number);
    }

    function test_cacheUpdatesOnChange() public {
        ton.setBalance(bridge1, 1000e18);
        registry.layer2TVL(address(rollupConfig1));

        vm.roll(block.number + 100);

        ton.setBalance(bridge1, 2000e18);
        registry.layer2TVL(address(rollupConfig1));

        (uint256 tvl, uint256 updateBlock) = registry.getLastKnownTVL(address(rollupConfig1));
        assertEq(tvl, 2000e18);
        assertEq(updateBlock, block.number);
    }

    // ==========================================
    // 명시적 업데이트 트리거 테스트
    // ==========================================

    function test_triggerBridgedTONUpdate() public {
        ton.setBalance(bridge1, 1000e18);

        registry.triggerBridgedTONUpdate(address(rollupConfig1));

        assertEq(layer2Manager.updateCount(), 1);
    }

    function test_triggerBridgedTONUpdate_unregistered() public {
        MockSystemConfig unregistered = new MockSystemConfig(address(0), address(0));

        vm.expectRevert("NotRegistered");
        registry.triggerBridgedTONUpdate(address(unregistered));
    }

    // ==========================================
    // 여러 Rollup 테스트
    // ==========================================

    function test_multipleRollups_independentTracking() public {
        ton.setBalance(bridge1, 1000e18);
        ton.setBalance(portal1, 2000e18);

        registry.layer2TVL(address(rollupConfig1));
        registry.layer2TVL(address(rollupConfig2));

        assertEq(layer2Manager.updateCount(), 2);

        // rollupConfig1 변경
        ton.setBalance(bridge1, 1500e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 3);

        // rollupConfig2 변경 없음
        registry.layer2TVL(address(rollupConfig2));
        assertEq(layer2Manager.updateCount(), 3, "No call when rollupConfig2 unchanged");
    }

    // ==========================================
    // 엣지 케이스 테스트
    // ==========================================

    function test_zeroTVL_stillTracked() public {
        ton.setBalance(bridge1, 0);
        registry.layer2TVL(address(rollupConfig1));

        // 0에서 시작하므로 변경 없음
        assertEq(layer2Manager.updateCount(), 0);

        // 0이 아닌 값으로 변경
        ton.setBalance(bridge1, 100e18);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 1);

        // 다시 0으로
        ton.setBalance(bridge1, 0);
        registry.layer2TVL(address(rollupConfig1));
        assertEq(layer2Manager.updateCount(), 2);
    }

    function test_layer2Manager_failureDoesNotRevert() public {
        // Layer2Manager가 없는 registry 생성
        SimpleL1BridgeRegistryV1_2 registryNoManager = new SimpleL1BridgeRegistryV1_2(
            address(ton),
            address(0) // no layer2Manager
        );

        registryNoManager.setBridge(bridge1);
        registryNoManager.setRollupInfo(address(rollupConfig1), 1, address(0x3001));

        ton.setBalance(bridge1, 1000e18);

        // Layer2Manager가 없어도 revert하지 않음
        registryNoManager.layer2TVL(address(rollupConfig1));
    }
}
