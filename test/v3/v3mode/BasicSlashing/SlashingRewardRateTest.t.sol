// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";

/// @title SlashingRewardRateTest
/// @notice Tests for different slashing reward rates (0%, 50%, 100%)
contract SlashingRewardRateTest is BaseSlashingTest {
    // ============================================
    // Scenario 1: 50% Reward Rate
    // ============================================

    function test_Slashing_CustomRewardRate_50Percent() public {
        console.log("\n=== Test: Slashing with 50% Reward Rate ===");

        // 1. Set reward rate to 50% (5000 basis points)
        _setSlashingRewardRate(5000);

        uint256 newRate = _getSlashingRewardRate();
        assertEq(newRate, 5000, "Reward rate should be 50%");
        console.log("Slashing reward rate set to:", newRate, "basis points (50%)");

        // 2. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);
        console.log("Initial stake (RAY):", initialStake);

        // 3. Setup dispute game and slash
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 4. Verify 50% reward
        uint256 expectedReward = (initialStake * 5000) / 10000; // 50%
        uint256 challengerBalanceAfter = _getWtonBalance(challenger);
        uint256 actualReward = challengerBalanceAfter - challengerBalanceBefore;

        assertEq(actualReward, expectedReward, "Challenger should receive 50% reward");
        console.log("Expected reward (50%):", expectedReward);
        console.log("Actual reward:", actualReward);
        console.log("[OK] 50% reward rate verified");
    }

    // ============================================
    // Scenario 2: 0% Reward Rate (All Burned)
    // ============================================

    function test_Slashing_ZeroRewardRate_AllBurned() public {
        console.log("\n=== Test: Zero Reward Rate - All Burned ===");

        // 1. Set reward rate to 0%
        _setSlashingRewardRate(0);

        // 2. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 3. Setup and execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 4. Verify: Challenger receives no reward (all burned)
        uint256 challengerBalanceAfter = _getWtonBalance(challenger);
        assertEq(
            challengerBalanceAfter,
            challengerBalanceBefore,
            "Challenger should receive no reward"
        );

        // Verify stake is zeroed
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "Stake should be zeroed");

        console.log("[OK] All slashed amount burned, no reward to challenger");
    }

    // ============================================
    // Scenario 3: 100% Reward Rate
    // ============================================

    function test_Slashing_FullRewardRate_100Percent() public {
        console.log("\n=== Test: Slashing with 100% Reward Rate ===");

        // 1. Set reward rate to 100% (10000 basis points)
        _setSlashingRewardRate(10000);

        uint256 newRate = _getSlashingRewardRate();
        assertEq(newRate, 10000, "Reward rate should be 100%");

        // 2. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);

        // 3. Setup and execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 4. Verify 100% reward
        uint256 challengerBalanceAfter = _getWtonBalance(challenger);
        uint256 actualReward = challengerBalanceAfter - challengerBalanceBefore;

        assertEq(actualReward, initialStake, "Challenger should receive 100% of slashed amount");
        console.log("Initial stake:", initialStake);
        console.log("Challenger reward (100%):", actualReward);
        console.log("[OK] 100% reward rate verified");
    }

    // ============================================
    // Scenario 4: Reward Rate Boundary Test (10%)
    // ============================================

    function test_Slashing_DefaultRewardRate_10Percent() public {
        console.log("\n=== Test: Default Slashing with 10% Reward Rate ===");

        // Default rate should be 10% (1000 basis points)
        uint256 defaultRate = _getSlashingRewardRate();
        console.log("Default slashing reward rate:", defaultRate, "basis points");

        // Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);

        // Setup and execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // Verify reward matches default rate
        uint256 expectedReward = (initialStake * defaultRate) / 10000;
        uint256 challengerBalanceAfter = _getWtonBalance(challenger);
        uint256 actualReward = challengerBalanceAfter - challengerBalanceBefore;

        assertEq(actualReward, expectedReward, "Challenger reward should match default rate");
        console.log("Expected reward:", expectedReward);
        console.log("Actual reward:", actualReward);
        console.log("[OK] Default 10% reward rate verified");
    }
}
