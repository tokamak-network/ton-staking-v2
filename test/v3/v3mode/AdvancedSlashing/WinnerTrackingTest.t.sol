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
        console.log("\n=== Scenario: Winner Tracking - No Duplicates ===");

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
        game.initialize(address(winningChallengerTracker));

        // Challenger calls step
        vm.prank(challenger);
        game.step();

        // Try to add same challenger multiple times
        game.addWinningChallenger(challenger);
        game.addWinningChallenger(challenger);
        game.addWinningChallenger(challenger);

        // Add another challenger
        game.addWinningChallenger(challenger2);
        game.addWinningChallenger(challenger2); // Duplicate

        game.resolve();

        // Should only have 2 unique winners
        assertEq(game.getWinningChallengersCount(), 2, "Should have only 2 unique winners");

        address[] memory winners = game.getWinningChallengers();
        assertEq(winners[0], challenger, "First should be challenger");
        assertEq(winners[1], challenger2, "Second should be challenger2");

        console.log("Winners count:", game.getWinningChallengersCount());
        console.log("[OK] Duplicate prevention verified");
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
        game.initialize(address(winningChallengerTracker));

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
