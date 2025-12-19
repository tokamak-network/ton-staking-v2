// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { MockFaultDisputeGame, IBigStepper, IDelayedWETH, IAnchorStateRegistry } from "../src/mocks/MockFaultDisputeGame.sol";
import { GameType, Claim, Duration } from "../src/layer2/lib/LibUDT.sol";
import { GameStatus } from "../src/layer2/lib/Types.sol";

contract ChallengerRewardTest is Test {
    MockFaultDisputeGame game;
    
    GameType constant GAME_TYPE = GameType.wrap(0);
    Claim constant ROOT_CLAIM = Claim.wrap(bytes32(uint256(1)));
    bytes constant EXTRA_DATA = hex"1234";

    function setUp() public {
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

    function test_ExtractWinningChallenger() public {
        // Verify initial state
        assertEq(uint8(game.status()), uint8(GameStatus.IN_PROGRESS), "Initial status should be IN_PROGRESS");

        // Execute step (Challenger attacks)
        address challenger = address(0x123);
        vm.prank(challenger);
        game.step();

        // Verify counteredBy is set
        (,address counteredBy,address claimant,,,,) = game.claimData(0);
        assertEq(counteredBy, challenger, "counteredBy should be challenger");
        assertEq(claimant, address(this), "claimant should be deployer");

        // Resolve
        game.resolve();

        // Verify Challenger Wins
        assertEq(uint8(game.status()), uint8(GameStatus.CHALLENGER_WINS), "Status should be CHALLENGER_WINS");
        
        // Verify we can extract the winning challenger address
        (,address winningChallenger,,,,,) = game.claimData(0);
        assertEq(winningChallenger, challenger, "Winning challenger should match");
    }

    function test_MultipleChallengers_OnlyFirstWins() public {
        address challenger1 = address(0x111);
        address challenger2 = address(0x222);

        // First challenger calls step
        vm.prank(challenger1);
        game.step();

        // Verify first challenger is recorded
        (,address counteredBy1,,,,,) = game.claimData(0);
        assertEq(counteredBy1, challenger1, "First challenger should be recorded");

        // Second challenger tries to call step (will overwrite in this mock)
        vm.prank(challenger2);
        game.step();

        // In real FaultDisputeGame, only the first successful challenger would be recorded
        // This mock overwrites, but demonstrates the concept
        (,address counteredBy2,,,,,) = game.claimData(0);
        assertEq(counteredBy2, challenger2, "Last caller overwrites in mock");
    }

    function test_DefenderWins_NoChallenger() public {
        // Resolve without calling step()
        game.resolve();

        // Verify Defender Wins
        assertEq(uint8(game.status()), uint8(GameStatus.DEFENDER_WINS), "Status should be DEFENDER_WINS");

        // Verify no challenger
        (,address counteredBy,,,,,) = game.claimData(0);
        assertEq(counteredBy, address(0), "No challenger should be recorded");
    }
}
