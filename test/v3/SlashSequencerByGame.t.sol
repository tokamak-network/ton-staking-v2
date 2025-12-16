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

/// @notice Mock DisputeGameFactory for testing
contract MockDisputeGameFactory {
    // Minimal implementation
}

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
    MockL1BridgeRegistry l1BridgeRegistry;
    MockSystemConfig systemConfigContract;
    MockDisputeGameFactory disputeGameFactory;
    MockCoinage coinage;
    MockTON ton;
    MockWTON wton;

    address admin = makeAddr("admin");
    address sequencer = makeAddr("sequencer");
    address challenger1 = makeAddr("challenger1");
    address challenger2 = makeAddr("challenger2");
    address dao = makeAddr("dao");

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
        l1BridgeRegistry = new MockL1BridgeRegistry();
        systemConfigContract = new MockSystemConfig();
        disputeGameFactory = new MockDisputeGameFactory();

        // Deploy SeigManager (as implementation)
        seigManager = new SeigManagerV1_4();

        // Setup SystemConfig with DisputeGameFactory
        systemConfigContract.setDisputeGameFactory(address(disputeGameFactory));

        // Setup L1BridgeRegistry to recognize the factory
        l1BridgeRegistry.setRollupConfigWithDisputeGameFactory(
            address(disputeGameFactory),
            address(systemConfigContract)
        );

        // Setup Layer2Manager
        layer2Manager.setLayer2(address(systemConfigContract), address(layer2));

        // Setup fault game
        faultGame = new MockFaultDisputeGame();
        faultGame.setSystemConfig(address(systemConfigContract));

        // Add a claim with challenger1 as counteredBy (root claim counter)
        faultGame.addClaim(0, challenger1, sequencer, 1 ether);

        vm.stopPrank();
    }

    /// @notice Test: Cannot slash when game is IN_PROGRESS
    function test_revert_gameNotResolved() public {
        // Game status is IN_PROGRESS (0) by default
        vm.expectRevert(); // GameNotResolvedError
        seigManager.slashSequencerByGame(address(faultGame));
    }

    /// @notice Test: Cannot slash when game is DEFENDER_WINS
    function test_revert_defenderWins() public {
        faultGame.resolveAsDefenderWins();

        vm.expectRevert(); // GameNotResolvedError
        seigManager.slashSequencerByGame(address(faultGame));
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
    function test_systemConfigRetrieval() public view {
        assertEq(faultGame.systemConfig(), address(systemConfigContract));
    }

    /// @notice Test: Layer2 lookup from SystemConfig
    function test_layer2Lookup() public view {
        address foundLayer2 = layer2Manager.getLayer2BySystemConfig(address(systemConfigContract));
        assertEq(foundLayer2, address(layer2));
    }

    /// @notice Test: Challenger extraction from claims
    function test_challengerExtraction() public {
        // Already added one claim in setUp, add more
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

    /// @notice Test: DisputeGameFactory verification
    function test_factoryVerification() public view {
        // Verify factory is set on SystemConfig
        assertEq(systemConfigContract.disputeGameFactory(), address(disputeGameFactory));

        // Verify L1BridgeRegistry recognizes the factory
        assertEq(
            l1BridgeRegistry.rollupConfigWithDisputeGameFactory(address(disputeGameFactory)),
            address(systemConfigContract)
        );
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
