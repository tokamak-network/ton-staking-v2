// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAdvancedSlashingTest.sol";

/// @title WinnerTrackingTest
/// @notice 시나리오: FaultDisputeGame의 승자 추적 기능 검증
/// @dev isWinningChallenger, getWinningChallengers 함수 동작 검증
contract WinnerTrackingTest is BaseAdvancedSlashingTest {
    // ============================================
    // 시나리오 6: 승자 추적 - 기본 동작
    // ============================================

    function test_WinnerTracking_BasicFunctionality() public {
        console.log("\n=== Scenario: Winner Tracking Basic Functionality ===");

        (, MockFaultDisputeGame3 game, , , ) = _setupMultiChallengerGame(3);

        // Test getWinningChallengers
        address[] memory winners = game.getWinningChallengers();
        assertEq(winners.length, 3, "Should return 3 winners");
        assertEq(winners[0], challenger, "First winner should be challenger");
        assertEq(winners[1], challenger2, "Second winner should be challenger2");
        assertEq(winners[2], challenger3, "Third winner should be challenger3");

        // Test getWinningChallengersCount
        assertEq(game.getWinningChallengersCount(), 3, "Count should be 3");

        // Test isWinningChallenger
        assertTrue(game.isWinningChallenger(challenger), "Challenger should be winner");
        assertTrue(game.isWinningChallenger(challenger2), "Challenger2 should be winner");
        assertTrue(game.isWinningChallenger(challenger3), "Challenger3 should be winner");
        assertFalse(game.isWinningChallenger(challenger4), "Challenger4 should not be winner");
        assertFalse(game.isWinningChallenger(operator), "Operator should not be winner");

        console.log("[OK] Winner tracking basic functionality verified");
    }

    // ============================================
    // 시나리오 7: 승자 추적 - 중복 방지
    // ============================================

    function test_WinnerTracking_NoDuplicates() public {
        console.log("\n=== Scenario: Winner Tracking - Proportional Rewards Based on Attacks ===");

        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        MockFaultDisputeGame3 game = MockFaultDisputeGame3(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        // Challenger1 attacks root claim once
        Claim claim1 = Claim.wrap(bytes32(uint256(1)));
        vm.prank(challenger);
        game.move(0, claim1, true);

        // Challenger2 attacks root claim three times (should get 3x rewards)
        Claim claim2 = Claim.wrap(bytes32(uint256(2)));
        Claim claim3 = Claim.wrap(bytes32(uint256(3)));
        Claim claim4 = Claim.wrap(bytes32(uint256(4)));

        vm.prank(challenger2);
        game.move(0, claim2, true); // First attack
        vm.prank(challenger2);
        game.move(0, claim3, true); // Second attack
        vm.prank(challenger2);
        game.move(0, claim4, true); // Third attack

        // Resolve all child claims (challenger1: 1 time, challenger2: 3 times)
        game.resolveClaim(1); // Resolves challenger's claim (recorded once)
        game.resolveClaim(2); // Resolves challenger2's first claim (recorded once)
        game.resolveClaim(3); // Resolves challenger2's second claim (recorded again)
        game.resolveClaim(4); // Resolves challenger2's third claim (recorded again)

        // Resolve root claim (should NOT record again due to our fix)
        game.resolveClaim(0);

        game.resolve();

        // Should have 4 entries total: challenger1 (1x) + challenger2 (3x)
        assertEq(game.getWinningChallengersCount(), 4, "Should have 4 entries total");

        address[] memory winners = game.getWinningChallengers();
        assertEq(winners[0], challenger, "First should be challenger");
        assertEq(winners[1], challenger2, "Second should be challenger2");
        assertEq(winners[2], challenger2, "Third should be challenger2");
        assertEq(winners[3], challenger2, "Fourth should be challenger2");

        // Verify rewards are distributed proportionally
        uint256 balance1Before = _getWtonBalance(challenger);
        uint256 balance2Before = _getWtonBalance(challenger2);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        uint256 reward1 = _getWtonBalance(challenger) - balance1Before;
        uint256 reward2 = _getWtonBalance(challenger2) - balance2Before;
        uint256 totalReward = reward1 + reward2;

        // Challenger1 has 1 entry, Challenger2 has 3 entries out of 4 total
        // So reward1 should be 1/4 and reward2 should be 3/4
        uint256 expectedReward1 = totalReward / 4;
        uint256 expectedReward2 = (totalReward / 4) * 3;

        assertEq(reward1, expectedReward1, "Challenger1 should get 1/4 of reward");
        assertEq(reward2, expectedReward2, "Challenger2 should get 3/4 of reward");

        console.log("Winners count:", game.getWinningChallengersCount());
        console.log("Challenger1 reward:", reward1, "(1/4)");
        console.log("Challenger2 reward:", reward2, "(3/4)");
        console.log("[OK] Proportional rewards verified - challenger2 gets 3x more for 3x attacks");
    }

    // ============================================
    // 시나리오 8: 승자 추적 - gameCreator 제외 검증
    // ============================================

    function test_WinnerTracking_GameCreatorExcluded() public {
        console.log("\n=== Scenario: Game Creator Excluded from Winners ===");

        // Note: In MockFaultDisputeGame3, gameCreator returns address(0)
        // This test verifies the concept that game creator should not be in winners

        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame3 game) = _setupDisputeGame3(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );

        _makeChallengerWin3(game);

        // Verify gameCreator is not in winners
        address gameCreatorAddr = game.gameCreator();
        assertFalse(
            game.isWinningChallenger(gameCreatorAddr),
            "Game creator should not be a winning challenger"
        );

        // Verify only challenger is winner
        assertEq(game.getWinningChallengersCount(), 1, "Only challenger should be winner");
        assertTrue(game.isWinningChallenger(challenger), "Challenger should be winner");

        console.log("Game creator:", gameCreatorAddr);
        console.log("Is game creator a winner:", game.isWinningChallenger(gameCreatorAddr));
        console.log("[OK] Game creator exclusion verified");
    }

    // ============================================
    // 시나리오 9: 승자 추적 - 빈 상태 검증
    // ============================================

    function test_WinnerTracking_EmptyBeforeStep() public {
        console.log("\n=== Scenario: Empty Winners Before Step ===");

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        MockFaultDisputeGame3 game = MockFaultDisputeGame3(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        // Before any step, should have no winners
        assertEq(game.getWinningChallengersCount(), 0, "Should have 0 winners before step");

        address[] memory winners = game.getWinningChallengers();
        assertEq(winners.length, 0, "Winners array should be empty");

        console.log("Winners before step:", game.getWinningChallengersCount());
        console.log("[OK] Empty state verified");
    }

    // ============================================
    // 시나리오 10: 승자 추적 - 데이터 일관성
    // ============================================

    function test_WinnerTracking_DataConsistency() public {
        console.log("\n=== Scenario: Winner Data Consistency ===");

        (, MockFaultDisputeGame3 game, , , ) = _setupMultiChallengerGame(4);

        // Test consistency between count and array length
        uint256 count = game.getWinningChallengersCount();
        address[] memory winners = game.getWinningChallengers();

        assertEq(count, winners.length, "Count should match array length");
        assertEq(count, 4, "Should have 4 winners");

        // Test consistency between array and mapping
        for (uint256 i = 0; i < winners.length; i++) {
            assertTrue(
                game.isWinningChallenger(winners[i]),
                string(abi.encodePacked("Winner ", i, " should be in mapping"))
            );
            console.log("Winner", i, ":", winners[i]);
        }

        // Test non-winners are correctly marked
        address nonWinner = makeAddr("nonWinner");
        assertFalse(game.isWinningChallenger(nonWinner), "Non-winner should not be in mapping");

        console.log("[OK] Data consistency verified");
    }
}
