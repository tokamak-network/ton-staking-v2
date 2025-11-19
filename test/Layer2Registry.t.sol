// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/stake/Layer2Registry.sol";
import "../src/stake/Layer2RegistryProxy.sol";
import "../src/dao/interfaces/ILayer2.sol";

// Mock Layer2 Contract for testing
contract MockLayer2 is ILayer2 {
    address public _operator;
    bool public _isLayer2;

    constructor(address operator_, bool isLayer2_) {
        _operator = operator_;
        _isLayer2 = isLayer2_;
    }

    function operator() external view override returns (address) {
        return _operator;
    }

    function isLayer2() external view override returns (bool) {
        return _isLayer2;
    }

    function currentFork() external view override returns (uint256) {
        return 0;
    }

    function lastEpoch(uint256) external view override returns (uint256) {
        return 0;
    }

    function changeOperator(address) external override {}
}

contract Layer2RegistryTest is Test {
    Layer2Registry public registryImpl;
    Layer2RegistryProxy public proxy;
    Layer2Registry public registry; // This will be the proxy cast as Layer2Registry

    address public admin;
    address public operator;
    address public user;

    function setUp() public {
        // Setup accounts
        admin = address(this); // Test contract is the admin
        operator = address(0x1);
        user = address(0x2);

        // Deploy Implementation
        registryImpl = new Layer2Registry();

        // Deploy Proxy
        // ProxyCoinage constructor sets msg.sender (this contract) as DEFAULT_ADMIN_ROLE
        proxy = new Layer2RegistryProxy();

        // Upgrade Proxy to Implementation
        proxy.upgradeTo(address(registryImpl));

        // Cast proxy to Layer2Registry interface for easier interaction
        registry = Layer2Registry(address(proxy));
    }

    function testInitialState() public {
        assertTrue(registry.isAdmin(admin));
        assertEq(registry.numLayer2s(), 0);
    }

    function testRegisterLayer2() public {
        // Create a mock Layer2
        MockLayer2 mockL2 = new MockLayer2(operator, true);
        address l2Address = address(mockL2);

        // Grant MINTER_ROLE to admin so we can register (since register requires onlyMinterOrOperator)
        // In Layer2Registry, onlyMinterOrOperator checks:
        // hasRole(MINTER_ROLE, msg.sender) || ILayer2(layer2).operator() == msg.sender

        // Case 1: Register as Admin (who is also Minter)
        // First, grant MINTER_ROLE to admin
        registry.addMinter(admin);
        
        bool success = registry.register(l2Address);
        assertTrue(success);
        assertTrue(registry.layer2s(l2Address));
        assertEq(registry.numLayer2s(), 1);
        assertEq(registry.layer2ByIndex(0), l2Address);
    }

    function testRegisterLayer2AsOperator() public {
        // Create a mock Layer2 where 'operator' is the operator
        MockLayer2 mockL2 = new MockLayer2(operator, true);
        address l2Address = address(mockL2);

        // Prank as operator
        vm.startPrank(operator);
        
        // Should succeed because msg.sender (operator) == ILayer2(l2).operator()
        bool success = registry.register(l2Address);
        assertTrue(success);
        
        vm.stopPrank();
    }

    function testFailRegisterNonLayer2() public {
        // Create a mock that returns isLayer2 = false
        MockLayer2 mockL2 = new MockLayer2(operator, false);
        address l2Address = address(mockL2);

        registry.addMinter(admin);
        
        // Should revert because isLayer2() returns false
        registry.register(l2Address);
    }

    function testUnregister() public {
        MockLayer2 mockL2 = new MockLayer2(operator, true);
        address l2Address = address(mockL2);

        registry.addMinter(admin);
        registry.register(l2Address);
        assertTrue(registry.layer2s(l2Address));

        // Unregister (onlyOwner can do this)
        registry.unregister(l2Address);
        assertFalse(registry.layer2s(l2Address));
    }
}
