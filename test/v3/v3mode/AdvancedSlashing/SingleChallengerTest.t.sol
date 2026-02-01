// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAdvancedSlashingTest.sol";

/// @title SingleChallengerTest
/// @notice 시나리오: 단일 챌린저가 DisputeGame에서 승리한 경우
/// @dev 단일 챌린저 시나리오에서 전체 보상금을 받는지 검증
contract SingleChallengerTest is BaseAdvancedSlashingTest {
    
    // ============================================
    // 시나리오 1: 단일 챌린저 - 전체 보상 수령
    // ============================================

    function test_SingleChallenger_ReceivesFullReward() public {
        console.log("\n=== Scenario: Single Challenger Receives Full Reward ===");

        // Setup
        uint256 stakeAmount = 10000 * 1e18;
        (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        ) = _setupMultiChallengerGame(1);

        // Verify single challenger
        assertEq(game.getWinningChallengersCount(), 1, "Should have exactly 1 winner");
        
        // Record balance before
        uint256 balanceBefore = _getWtonBalance(challenger);

        // Execute slashing
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // Verify full reward
        uint256 expectedReward = _calculateExpectedReward(stakeAmount);
        uint256 balanceAfter = _getWtonBalance(challenger);
        
        assertEq(
            balanceAfter - balanceBefore,
            expectedReward,
            "Single challenger should receive 100% of reward"
        );

        console.log("Stake amount (TON):", stakeAmount / 1e18);
        console.log("Expected reward (WTON):", expectedReward);
        console.log("Actual reward (WTON):", balanceAfter - balanceBefore);
        console.log("[OK] Single challenger received full reward");
    }

    function test_SingleChallenger_CompatibilityWithOldSystem() public {
        console.log("\n=== Scenario: Backward Compatibility Check ===");

        // 이전 시스템과의 호환성 검증
        // 단일 챌린저인 경우 이전 로직과 동일하게 동작해야 함

        uint256 stakeAmount = 5000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(operator, rollupConfig, stakeAmount);

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame3 game) = _setupDisputeGame3(rollupConfig, gameType, rootClaim, extraData);

        // Original flow: challenger wins
        _makeChallengerWin3(game);

        uint256 balanceBefore = _getWtonBalance(challenger);
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
        uint256 balanceAfter = _getWtonBalance(challenger);

        uint256 expectedReward = _calculateExpectedReward(stakeAmount);
        
        assertEq(
            balanceAfter - balanceBefore,
            expectedReward,
            "Old flow should work identically"
        );

        console.log("[OK] Backward compatibility verified");
    }

    function test_SingleChallenger_SmallStake() public {
        console.log("\n=== Scenario: Small Stake Amount ===");

        uint256 stakeAmount = 1001 * 1e18; // Minimum stake (>1000 TON)
        address testOperator = makeAddr("smallStakeOperator");
        (address operatorManager, ) = _registerCandidateAndStake(testOperator, rollupConfig, stakeAmount);

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame3 game) = _setupDisputeGame3(rollupConfig, gameType, rootClaim, extraData);
        _makeChallengerWin3(game);

        uint256 balanceBefore = _getWtonBalance(challenger);
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
        uint256 balanceAfter = _getWtonBalance(challenger);

        uint256 expectedReward = _calculateExpectedReward(stakeAmount);
        assertEq(balanceAfter - balanceBefore, expectedReward, "Small stake reward mismatch");

        console.log("Stake (TON):", stakeAmount / 1e18);
        console.log("Reward (WTON):", expectedReward);
        console.log("[OK] Small stake processed correctly");
    }

    function test_SingleChallenger_LargeStake() public {
        console.log("\n=== Scenario: Large Stake Amount ===");

        uint256 stakeAmount = 1000000 * 1e18; // Large stake
        address testOperator = makeAddr("largeStakeOperator");
        (address operatorManager, ) = _registerCandidateAndStake(testOperator, rollupConfig, stakeAmount);

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame3 game) = _setupDisputeGame3(rollupConfig, gameType, rootClaim, extraData);
        _makeChallengerWin3(game);

        uint256 balanceBefore = _getWtonBalance(challenger);
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
        uint256 balanceAfter = _getWtonBalance(challenger);

        uint256 expectedReward = _calculateExpectedReward(stakeAmount);
        assertEq(balanceAfter - balanceBefore, expectedReward, "Large stake reward mismatch");

        console.log("Stake (TON):", stakeAmount / 1e18);
        console.log("Reward (WTON):", expectedReward);
        console.log("[OK] Large stake processed correctly");
    }
}
