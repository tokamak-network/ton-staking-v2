// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../src/layer2/Layer2ManagerV1_2.sol";

/// @title Layer2ManagerV1_2RealTest
/// @notice 실제 Layer2ManagerV1_2 컨트랙트의 커버리지 테스트
/// @dev V1_2는 L1BridgeRegistry.layer2TVL을 사용하여 Bridged TON 조회

// ==========================================
// Mock Contracts
// ==========================================

contract MockTONForL2V1_2 {
    mapping(address => uint256) public balanceOf;

    function setBalance(address account, uint256 amount) external {
        balanceOf[account] = amount;
    }
}

contract MockL1BridgeRegistryForL2V1_2 {
    mapping(address => uint256) public layer2TVLValues;

    function setLayer2TVL(address rollupConfig, uint256 amount) external {
        layer2TVLValues[rollupConfig] = amount;
    }

    function layer2TVL(address rollupConfig) external view returns (uint256) {
        return layer2TVLValues[rollupConfig];
    }

    function rollupType(address) external pure returns (uint8) {
        return 1;
    }

    function l2TON(address) external pure returns (address) {
        return address(0x6001);
    }
}

/// @notice Layer2ManagerV1_2 Harness for testing
contract Layer2ManagerV1_2Harness is Layer2ManagerV1_2 {
    function initialize(
        address _l1BridgeRegistry,
        address _ton
    ) external {
        l1BridgeRegistry = _l1BridgeRegistry;
        ton = _ton;
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

    // Grant admin role for testing
    function grantAdminRole(address account) external {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }
}

contract Layer2ManagerV1_2RealTest is Test {
    Layer2ManagerV1_2Harness public layer2Manager;
    MockTONForL2V1_2 public mockTon;
    MockL1BridgeRegistryForL2V1_2 public mockL1BridgeRegistry;

    address public rollupConfig1 = address(0x3001);
    address public rollupConfig2 = address(0x3002);

    address public operator1 = address(0x4001);
    address public layer2_1 = address(0x5001);
    address public owner = address(this);

    function setUp() public {
        mockTon = new MockTONForL2V1_2();
        mockL1BridgeRegistry = new MockL1BridgeRegistryForL2V1_2();

        layer2Manager = new Layer2ManagerV1_2Harness();
        layer2Manager.initialize(
            address(mockL1BridgeRegistry),
            address(mockTon)
        );
        layer2Manager.grantAdminRole(owner);
    }

    // ==========================================
    // getBridgedTON Tests
    // ==========================================

    function test_getBridgedTON_basic() public {
        // Setup L1BridgeRegistry mock with layer2TVL value
        mockL1BridgeRegistry.setLayer2TVL(rollupConfig1, 1000e18);

        uint256 bridgedTON = layer2Manager.getBridgedTON(rollupConfig1);
        assertEq(bridgedTON, 1000e18, "Should return layer2TVL value");
    }

    function test_getBridgedTON_zero() public {
        // No TVL set, should return 0
        uint256 bridgedTON = layer2Manager.getBridgedTON(rollupConfig1);
        assertEq(bridgedTON, 0, "Unset should return 0");
    }

    // ==========================================
    // getBridgedTONByLayer Tests
    // ==========================================

    function test_getBridgedTONByLayer_basic() public {
        // Setup: operator -> rollupConfig mapping
        layer2Manager.setOperatorOfLayer(layer2_1, operator1);
        layer2Manager.setOperatorInfo(operator1, rollupConfig1, layer2_1);

        // Setup L1BridgeRegistry mock
        mockL1BridgeRegistry.setLayer2TVL(rollupConfig1, 1500e18);

        uint256 bridgedTON = layer2Manager.getBridgedTONByLayer(layer2_1);
        assertEq(bridgedTON, 1500e18, "Should return layer2TVL via layer2 -> operator -> rollupConfig path");
    }

    function test_getBridgedTONByLayer_noOperator() public {
        // No operator set for layer2
        uint256 bridgedTON = layer2Manager.getBridgedTONByLayer(layer2_1);
        assertEq(bridgedTON, 0, "No operator should return 0");
    }

    function test_getBridgedTONByLayer_noRollupConfig() public {
        // Operator exists but no rollupConfig
        layer2Manager.setOperatorOfLayer(layer2_1, operator1);
        // operatorInfo not set, so rollupConfig = address(0)

        uint256 bridgedTON = layer2Manager.getBridgedTONByLayer(layer2_1);
        assertEq(bridgedTON, 0, "No rollupConfig should return 0");
    }

    // ==========================================
    // getLayer2BySystemConfig Tests
    // ==========================================

    function test_getLayer2BySystemConfig_basic() public {
        // Setup: rollupConfig -> operatorManager -> layer2
        layer2Manager.setRollupConfigInfo(rollupConfig1, 1, operator1);
        layer2Manager.setOperatorInfo(operator1, rollupConfig1, layer2_1);

        address layer2 = layer2Manager.getLayer2BySystemConfig(rollupConfig1);
        assertEq(layer2, layer2_1, "Should return correct layer2 address");
    }

    function test_getLayer2BySystemConfig_noOperatorManager() public {
        // rollupConfig not registered (no operatorManager)
        address layer2 = layer2Manager.getLayer2BySystemConfig(rollupConfig1);
        assertEq(layer2, address(0), "Unregistered should return address(0)");
    }

    function test_getLayer2BySystemConfig_noCandidateAddOn() public {
        // operatorManager exists but no candidateAddOn (layer2)
        layer2Manager.setRollupConfigInfo(rollupConfig1, 1, operator1);
        // operatorInfo not set for operator1, so candidateAddOn = address(0)

        address layer2 = layer2Manager.getLayer2BySystemConfig(rollupConfig1);
        assertEq(layer2, address(0), "No candidateAddOn should return address(0)");
    }

    // ==========================================
    // Fuzz Tests
    // ==========================================

    function testFuzz_getBridgedTON(uint256 amount) public {
        amount = bound(amount, 0, 1e32);

        mockL1BridgeRegistry.setLayer2TVL(rollupConfig1, amount);

        uint256 bridgedTON = layer2Manager.getBridgedTON(rollupConfig1);
        assertEq(bridgedTON, amount);
    }

    function testFuzz_getBridgedTONByLayer(uint256 amount) public {
        amount = bound(amount, 0, 1e32);

        // Setup mapping
        layer2Manager.setOperatorOfLayer(layer2_1, operator1);
        layer2Manager.setOperatorInfo(operator1, rollupConfig1, layer2_1);

        mockL1BridgeRegistry.setLayer2TVL(rollupConfig1, amount);

        uint256 bridgedTON = layer2Manager.getBridgedTONByLayer(layer2_1);
        assertEq(bridgedTON, amount);
    }
}
