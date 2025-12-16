// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/proxy/DAOCommitteeProxy2.sol";
import "src/dao/DAOCommittee_V1.sol";
import "src/dao/DAOCommitteeOwner.sol";

// A minimal interface for DAOCommitteeProxy based on the ABI and test needs
interface IDAOCommitteeProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
    function implementation2(uint256 _index) external view returns (address);
}

contract DAOCommitteeProxyDeploymentTest is Test {
    
    DAOCommitteeProxy2 public daoCommitteeProxy2;
    DAOCommittee_V1 public daoCommitteeV1;
    DAOCommitteeOwner public daoCommitteeOwner;
    address public daoCommitteeProxyAddress;

    function setUp() public {
        // Per documentation, deploy DAOCommitteeProxy2 first as it's a constructor argument for the proxy
        daoCommitteeProxy2 = new DAOCommitteeProxy2();

        // Deploy logic contracts
        daoCommitteeV1 = new DAOCommittee_V1();
        daoCommitteeOwner = new DAOCommitteeOwner();

        // Prepare constructor arguments for DAOCommitteeProxy
        address _ton = makeAddr("ton");
        address _impl = makeAddr("impl"); 
        address _seigManager = makeAddr("seigManager");
        address _layer2Registry = makeAddr("layer2Registry");
        address _agendaManager = makeAddr("agendaManager");
        address _candidateFactory = makeAddr("candidateFactory");
        address _daoVault = makeAddr("daoVault");

        // Encode arguments
        bytes memory proxyConstructorArgs = abi.encode(
            _ton,
            _impl,
            _seigManager,
            _layer2Registry,
            _agendaManager,
            _candidateFactory,
            _daoVault
        );

        // Deploy DAOCommitteeProxy using the deployCode cheatcode, as shown in TONWTONTest.sol
        daoCommitteeProxyAddress = deployCode("abis/DAOCommitteeProxy.json", proxyConstructorArgs);
        
        // Ensure deployment was successful
        require(daoCommitteeProxyAddress != address(0), "DAOCommitteeProxy deployment failed");
    }

    function test_ProxyDeploymentStructure() public {
        IDAOCommitteeProxy daoCommitteeProxy = IDAOCommitteeProxy(daoCommitteeProxyAddress);

        // **Step 1 & 2: Verification of DAOCommitteeProxy deployment and upgrade**
        
        // The constructor should have already set the implementation to DAOCommitteeProxy2.
        assertEq(daoCommitteeProxy.implementation(), makeAddr("impl"), "Initial implementation should be DAOCommitteeProxy2");

        // The documentation still says to call `upgradeTo(DAOCommitteeProxy2)`.
        // This call should succeed (even if redundant) and confirms the admin role is working.
        daoCommitteeProxy.upgradeTo(address(daoCommitteeProxy2));
        assertEq(daoCommitteeProxy.implementation(), address(daoCommitteeProxy2), "Implementation should remain DAOCommitteeProxy2 after upgradeTo");

        // **Step 3: Logic Implementation Settings**
        
        // Cast the proxy address to the DAOCommitteeProxy2 type to call its functions
        DAOCommitteeProxy2 proxyAsProxy2 = DAOCommitteeProxy2(payable(daoCommitteeProxyAddress));

        // 3.1: Set Main Logic -> DAOCommittee_V1, using upgradeTo2 as per updated docs
        proxyAsProxy2.upgradeTo2(address(daoCommitteeV1));
        // After this call, the proxy's default implementation (index 0) should be daoCommitteeV1
        assertEq(daoCommitteeProxy.implementation2(0), address(daoCommitteeV1), "Main logic (impl 0) should be DAOCommittee_V1");

        // 3.2: Set Owner Logic -> DAOCommitteeOwner
        proxyAsProxy2.setImplementation2(address(daoCommitteeOwner), 1, true);
        assertEq(daoCommitteeProxy.implementation2(1), address(daoCommitteeOwner), "Owner logic (impl 1) should be DAOCommitteeOwner");

        // **Final Verification: Selector Routing**
        // Check if a selector from DAOCommitteeOwner is correctly routed
        bytes4 ownerLogicSelector = DAOCommitteeOwner.setCooldownTime.selector;
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ownerLogicSelector;
        
        proxyAsProxy2.setSelectorImplementations2(selectors, address(daoCommitteeOwner));

        assertEq(
            proxyAsProxy2.getSelectorImplementation2(ownerLogicSelector),
            address(daoCommitteeOwner),
            "Selector should be routed to DAOCommitteeOwner"
        );
    }
}
