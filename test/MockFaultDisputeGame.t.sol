// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { MockFaultDisputeGame, IBigStepper, IDelayedWETH, IAnchorStateRegistry } from "../src/mocks/MockFaultDisputeGame.sol";
import { MockDisputeGameFactory } from "../src/mocks/MockDisputeGameFactory.sol";
import { GameType, Claim, Duration } from "../src/layer2/lib/LibUDT.sol";
import { GameStatus } from "../src/layer2/lib/Types.sol";

contract MockFaultDisputeGameTest is Test {
    MockDisputeGameFactory factory;
    MockFaultDisputeGame game;
    
    GameType constant GAME_TYPE = GameType.wrap(0);
    Claim constant ROOT_CLAIM = Claim.wrap(bytes32(uint256(1)));
    bytes constant EXTRA_DATA = hex"1234";

    function setUp() public {
        factory = new MockDisputeGameFactory();
        
        // Create game parameters
        MockFaultDisputeGame.GameConstructorParams memory params = MockFaultDisputeGame.GameConstructorParams({
            gameType: GAME_TYPE,
            absolutePrestate: Claim.wrap(bytes32(0)),
            maxGameDepth: 10,
            splitDepth: 5,
            clockExtension: Duration.wrap(0),
            maxClockDuration: Duration.wrap(0),
            vm: IBigStepper(address(0)),
            weth: IDelayedWETH(address(0)),
            anchorStateRegistry: IAnchorStateRegistry(address(0)),
            l2ChainId: 1
        });

        // Create game directly
        game = new MockFaultDisputeGame(params, ROOT_CLAIM, EXTRA_DATA);
        
        // Initialize the game
        game.initialize();
    }

    function test_DefenderWins_WhenNoStep() public {
        // Verify initial state
        assertEq(uint8(game.status()), uint8(GameStatus.IN_PROGRESS), "Initial status should be IN_PROGRESS");

        // Resolve without calling step()
        game.resolve();

        // Verify Defender Wins
        assertEq(uint8(game.status()), uint8(GameStatus.DEFENDER_WINS), "Status should be DEFENDER_WINS when no step is executed");
    }

    function test_ChallengerWins_WhenStepExecuted() public {
        // Verify initial state
        assertEq(uint8(game.status()), uint8(GameStatus.IN_PROGRESS), "Initial status should be IN_PROGRESS");

        // Execute step (Challenger attacks)
        address challenger = address(0x123);
        vm.prank(challenger);
        game.step();

        // Resolve
        game.resolve();

        // Verify Challenger Wins
        assertEq(uint8(game.status()), uint8(GameStatus.CHALLENGER_WINS), "Status should be CHALLENGER_WINS when step is executed");

        // Verify Challenger Address
        (,address counteredBy,address claimant,,,,) = game.claimData(0);
        assertEq(claimant, address(this), "claimant address mismatch");
        assertEq(counteredBy, challenger, "counteredBy address mismatch");
    }
}
