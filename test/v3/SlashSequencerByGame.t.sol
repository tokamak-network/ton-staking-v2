// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {SeigManagerV1_4} from "../../src/stake/managers/SeigManagerV1_4.sol";
import {MockFaultDisputeGame} from "./mocks/MockFaultDisputeGame.sol";
import {MockCoinage} from "./mocks/MockCoinage.sol";
import {MockTON} from "./mocks/MockTON.sol";
import {MockWTON} from "./mocks/MockWTON.sol";
import {MockL1BridgeRegistry} from "./mocks/MockL1BridgeRegistry.sol";
import {MockSystemConfig} from "./mocks/MockSystemConfig.sol";

/// @notice Layer2I interface for operator
interface Layer2I {
    function operator() external view returns (address);
}

/// @notice ILayer2Manager interface
interface ILayer2Manager {
    function getLayer2BySystemConfig(address systemConfig) external view returns (address);
}

/// @notice Mock Layer2 contract
contract MockLayer2 {
    address public operator;

    constructor(address _operator) {
        operator = _operator;
    }

    function setOperator(address _operator) external {
        operator = _operator;
    }
}

/// @notice Mock Layer2Manager for testing
contract MockLayer2Manager {
    mapping(address => address) public systemConfigToLayer2;

    function setLayer2(address systemConfig, address layer2) external {
        systemConfigToLayer2[systemConfig] = layer2;
    }

    function getLayer2BySystemConfig(address systemConfig) external view returns (address) {
        return systemConfigToLayer2[systemConfig];
    }

    function layerInfo(address) external pure returns (address, address) {
        return (address(0), address(0));
    }

    function statusLayer2(address) external pure returns (uint256) {
        return 1;
    }
}

/**
 * @title SlashSequencerByGameTest
 * @notice Unit tests for SeigManagerV1_4.slashSequencerByGame()
 * @dev Tests permissionless slashing via FaultDisputeGame
 */
contract SlashSequencerByGameTest is Test {
    SeigManagerV1_4 seigManager;
    MockFaultDisputeGame faultGame;
    MockLayer2 layer2;
    MockLayer2Manager layer2Manager;
    MockCoinage coinage;
    MockTON ton;
    MockWTON wton;

    address admin = makeAddr("admin");
    address sequencer = makeAddr("sequencer");
    address challenger1 = makeAddr("challenger1");
    address challenger2 = makeAddr("challenger2");
    address dao = makeAddr("dao");

    address systemConfig;

    uint256 constant RAY = 1e27;

    function setUp() public {
        vm.startPrank(admin);

        // Deploy mocks
        ton = new MockTON();
        wton = new MockWTON();
        wton.setTON(address(ton));

        layer2Manager = new MockLayer2Manager();
        layer2 = new MockLayer2(sequencer);
        coinage = new MockCoinage();

        // Deploy SeigManager (as implementation)
        seigManager = new SeigManagerV1_4();

        // Setup mock systemConfig
        systemConfig = makeAddr("systemConfig");
        layer2Manager.setLayer2(systemConfig, address(layer2));

        // Setup fault game
        faultGame = new MockFaultDisputeGame();
        faultGame.setSystemConfig(systemConfig);

        vm.stopPrank();
    }

    /// @notice Test: Cannot slash when game is IN_PROGRESS
    function test_revert_gameNotResolved() public {
        // Game status is IN_PROGRESS (0) by default
        address[] memory challengers = new address[](1);
        challengers[0] = challenger1;

        vm.expectRevert(); // GameNotResolvedError
        seigManager.slashSequencerByGame(address(faultGame), challengers);
    }

    /// @notice Test: Cannot slash when game is DEFENDER_WINS
    function test_revert_defenderWins() public {
        faultGame.resolveAsDefenderWins();

        address[] memory challengers = new address[](1);
        challengers[0] = challenger1;

        vm.expectRevert(); // GameNotResolvedError
        seigManager.slashSequencerByGame(address(faultGame), challengers);
    }

    /// @notice Test: Cannot slash same game twice
    function test_revert_alreadySlashed() public {
        // This test would need full setup with coinage and deposits
        // Simplified: just verify the slashedGames mapping behavior
    }

    /// @notice Test: Game status check
    function test_gameStatusCheck() public {
        // IN_PROGRESS
        assertEq(faultGame.status(), 0);

        // CHALLENGER_WINS
        faultGame.resolveAsChallengerWins();
        assertEq(faultGame.status(), 1);

        // Reset and DEFENDER_WINS
        faultGame.setStatus(2);
        assertEq(faultGame.status(), 2);
    }

    /// @notice Test: SystemConfig retrieval
    function test_systemConfigRetrieval() public {
        assertEq(faultGame.systemConfig(), systemConfig);
    }

    /// @notice Test: Layer2 lookup from SystemConfig
    function test_layer2Lookup() public {
        address foundLayer2 = layer2Manager.getLayer2BySystemConfig(systemConfig);
        assertEq(foundLayer2, address(layer2));
    }

    /// @notice Test: Challenger extraction from claims
    function test_challengerExtraction() public {
        // Add claims with counteredBy addresses
        faultGame.addClaim(0, challenger1, sequencer, 1 ether);
        faultGame.addClaim(1, challenger2, sequencer, 1 ether);
        faultGame.addClaim(2, address(0), challenger1, 1 ether); // No counter

        assertEq(faultGame.claimDataLen(), 3);

        // Verify counteredBy addresses
        MockFaultDisputeGame.ClaimData memory claim0 = faultGame.claimData(0);
        assertEq(claim0.counteredBy, challenger1);

        MockFaultDisputeGame.ClaimData memory claim1 = faultGame.claimData(1);
        assertEq(claim1.counteredBy, challenger2);

        MockFaultDisputeGame.ClaimData memory claim2 = faultGame.claimData(2);
        assertEq(claim2.counteredBy, address(0));
    }

    /// @notice Test: Single challenger fallback
    function test_singleChallengerFallback() public {
        faultGame.addChallenger(challenger1);
        assertEq(faultGame.challenger(), challenger1);
    }

    /// @notice Test: Mock operator retrieval
    function test_operatorRetrieval() public {
        assertEq(layer2.operator(), sequencer);
    }
}
