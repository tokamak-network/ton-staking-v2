// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

interface ISeigManager {
    function updateSeigniorage() external returns (bool);
    function seigStartBlock() external view returns (uint256);
    function initialTotalSupply() external view returns (uint256);
    function burntAmountAtDAO() external view returns (uint256);
    function v3Migrated() external view returns (bool);
    function totalEffectiveBridgedTON() external view returns (uint256);
    function getEffectiveBridgedTon(address layer2) external view returns (uint256);
    function lastSeigBlock() external view returns (uint256);
    function pausedBlock() external view returns (uint256);
    function unpausedBlock() external view returns (uint256);
}

interface ICandidateAddOn {
    function updateSeigniorage() external returns (bool);
}

interface IBridgedTONInfo {
    function bridgedTONInfo(address layer2) external view returns (
        uint256 effectiveBridgedTON,
        uint256 currentBridgedTON,
        bool isEligible,
        uint256 startBlock,
        uint256 initialDebt
    );
}

contract SeigniorageDebugTest is Test {
    address constant SEIG_MANAGER = 0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe;
    
    function setUp() public {
        // Fork from local anvil
        string memory rpc = "http://localhost:8545";
        vm.createSelectFork(rpc);
    }
    
    function testCheckSeigManagerState() public view {
        ISeigManager seig = ISeigManager(SEIG_MANAGER);
        
        console.log("=== SeigManager State ===");
        console.log("seigStartBlock:", seig.seigStartBlock());
        console.log("initialTotalSupply:", seig.initialTotalSupply());
        console.log("burntAmountAtDAO:", seig.burntAmountAtDAO());
        console.log("v3Migrated:", seig.v3Migrated());
        console.log("totalEffectiveBridgedTON:", seig.totalEffectiveBridgedTON());
        console.log("lastSeigBlock:", seig.lastSeigBlock());
        console.log("pausedBlock:", seig.pausedBlock());
        console.log("unpausedBlock:", seig.unpausedBlock());
        console.log("current block:", block.number);
    }
}
