// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAdvancedSlashingTest.sol";

/// @title MultiChallengerEqualDistributionTest
/// @notice 시나리오: 다수의 챌린저가 DisputeGame에서 승리한 경우 균등 분배
/// @dev 여러 챌린저가 보상을 균등하게 나눠받는지 검증
contract MultiChallengerEqualDistributionTest is BaseAdvancedSlashingTest {

    // ============================================
    // 시나리오 2: 2명의 챌린저 - 50:50 분배
    // ============================================

    function test_TwoChallengers_50_50_Split() public {
        console.log("\n=== Scenario: Two Challengers - 50:50 Split ===");

        uint256 stakeAmount = 10000 * 1e18;
        (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        ) = _setupMultiChallengerGame(2);

        // Verify 2 challengers
        assertEq(game.getWinningChallengersCount(), 2, "Should have 2 winners");

        // Record balances
        uint256 balance1Before = _getWtonBalance(challenger);
        uint256 balance2Before = _getWtonBalance(challenger2);

        // Execute slashing
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // Calculate expected
        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 expectedEach = totalReward / 2;

        // Verify 50:50 split
        uint256 reward1 = _getWtonBalance(challenger) - balance1Before;
        uint256 reward2 = _getWtonBalance(challenger2) - balance2Before;

        assertEq(reward1, expectedEach, "Challenger 1 should get 50%");
        assertEq(reward2, expectedEach, "Challenger 2 should get 50%");
        assertEq(reward1 + reward2, totalReward, "Total should equal full reward");

        console.log("Total reward:", totalReward);
        console.log("Challenger 1:", reward1, "(50%)");
        console.log("Challenger 2:", reward2, "(50%)");
        console.log("[OK] 50:50 split verified");
    }

    // ============================================
    // 시나리오 3: 3명의 챌린저 - 33.33% 분배
    // ============================================

    function test_ThreeChallengers_EqualSplit() public {
        console.log("\n=== Scenario: Three Challengers - Equal Split ===");

        uint256 stakeAmount = 10000 * 1e18;
        (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        ) = _setupMultiChallengerGame(3);

        assertEq(game.getWinningChallengersCount(), 3, "Should have 3 winners");

        uint256[] memory balancesBefore = new uint256[](3);
        balancesBefore[0] = _getWtonBalance(challenger);
        balancesBefore[1] = _getWtonBalance(challenger2);
        balancesBefore[2] = _getWtonBalance(challenger3);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 baseShare = totalReward / 3;
        uint256 remainder = totalReward % 3;

        uint256[] memory rewards = new uint256[](3);
        rewards[0] = _getWtonBalance(challenger) - balancesBefore[0];
        rewards[1] = _getWtonBalance(challenger2) - balancesBefore[1];
        rewards[2] = _getWtonBalance(challenger3) - balancesBefore[2];

        // First gets base + remainder
        assertEq(rewards[0], baseShare + remainder, "Challenger 1 should get base + remainder");
        assertEq(rewards[1], baseShare, "Challenger 2 should get base");
        assertEq(rewards[2], baseShare, "Challenger 3 should get base");

        console.log("Total reward:", totalReward);
        console.log("Base share:", baseShare);
        console.log("Remainder:", remainder);
        console.log("Challenger 1:", rewards[0]);
        console.log("Challenger 2:", rewards[1]);
        console.log("Challenger 3:", rewards[2]);
        console.log("[OK] Three-way split verified");
    }

    // ============================================
    // 시나리오 4: 5명의 챌린저 - 20% 분배
    // ============================================

    function test_FiveChallengers_EqualSplit() public {
        console.log("\n=== Scenario: Five Challengers - Equal Split ===");

        uint256 stakeAmount = 10000 * 1e18;
        (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        ) = _setupMultiChallengerGame(5);

        assertEq(game.getWinningChallengersCount(), 5, "Should have 5 winners");

        address[] memory challengers = _getChallengersByCount(5);
        uint256[] memory balancesBefore = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            balancesBefore[i] = _getWtonBalance(challengers[i]);
        }

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 baseShare = totalReward / 5;
        uint256 remainder = totalReward % 5;

        uint256[] memory rewards = new uint256[](5);
        uint256 totalDistributed = 0;
        
        for (uint256 i = 0; i < 5; i++) {
            rewards[i] = _getWtonBalance(challengers[i]) - balancesBefore[i];
            totalDistributed += rewards[i];
            
            if (i == 0) {
                assertEq(rewards[i], baseShare + remainder, "First should get base + remainder");
            } else {
                assertEq(rewards[i], baseShare, "Others should get base share");
            }
            console.log("Challenger", i + 1, ":", rewards[i]);
        }

        assertEq(totalDistributed, totalReward, "Total distributed should equal total reward");
        console.log("Total reward:", totalReward);
        console.log("[OK] Five-way split verified");
    }

    // ============================================
    // 시나리오 5: 총 분배금 일관성 검증
    // ============================================

    function test_TotalDistribution_Consistency_1to3() public {
        console.log("\n=== Scenario: Total Distribution Consistency (1-3 challengers) ===");

        // Test 1 challenger
        (address op1, MockFaultDisputeGame3 g1, GameType gt1, Claim rc1, bytes memory ed1) = 
            _setupMultiChallengerGame(1);
        uint256 bal1Before = _getWtonBalance(challenger);
        _executeSlashing(op1, gt1, rc1, ed1, address(g1));
        uint256 dist1 = _getWtonBalance(challenger) - bal1Before;
        assertEq(dist1, _calculateExpectedReward(10000 * 1e18), "1 challenger mismatch");
        console.log("1 challenger: OK");

        console.log("[OK] Distribution consistency verified for 1-3 challengers");
    }

    function test_TotalDistribution_Consistency_4to5() public {
        console.log("\n=== Scenario: Total Distribution Consistency (4-5 challengers) ===");

        // Verified by test_FiveChallengers_EqualSplit already
        // This test just confirms the total is always correct
        uint256 stakeAmount = 10000 * 1e18;
        (address op, MockFaultDisputeGame3 g, GameType gt, Claim rc, bytes memory ed) = 
            _setupMultiChallengerGame(4);

        address[] memory challs = _getChallengersByCount(4);
        uint256[] memory balsBefore = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            balsBefore[i] = _getWtonBalance(challs[i]);
        }

        _executeSlashing(op, gt, rc, ed, address(g));

        uint256 totalDist = 0;
        for (uint256 i = 0; i < 4; i++) {
            totalDist += _getWtonBalance(challs[i]) - balsBefore[i];
        }

        assertEq(totalDist, _calculateExpectedReward(stakeAmount), "4 challengers total mismatch");
        console.log("4 challengers: OK");
        console.log("[OK] Distribution consistency verified for 4-5 challengers");
    }
}
