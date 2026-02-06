// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseAdvancedSlashingTest.sol";

/// @title RemainderDistributionTest
/// @notice 시나리오: 나머지(remainder) 분배 엣지 케이스 검증
/// @dev 균등 분배 시 나누어 떨어지지 않는 경우 첫 번째 챌린저에게 나머지 지급
contract RemainderDistributionTest is BaseAdvancedSlashingTest {
    // ============================================
    // 시나리오 11: 나머지 분배 - 3명 (나머지 1)
    // ============================================

    function test_Remainder_ThreeChallengers() public {
        console.log("\n=== Scenario: Remainder with 3 Challengers ===");

        uint256 stakeAmount = 10000 * 1e18;
        (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        ) = _setupMultiChallengerGame(3);

        uint256[] memory balancesBefore = new uint256[](3);
        balancesBefore[0] = _getWtonBalance(challenger);
        balancesBefore[1] = _getWtonBalance(challenger2);
        balancesBefore[2] = _getWtonBalance(challenger3);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 baseShare = totalReward / 3;
        uint256 remainder = totalReward % 3;

        uint256 reward1 = _getWtonBalance(challenger) - balancesBefore[0];
        uint256 reward2 = _getWtonBalance(challenger2) - balancesBefore[1];
        uint256 reward3 = _getWtonBalance(challenger3) - balancesBefore[2];

        console.log("Total reward:", totalReward);
        console.log("Base share:", baseShare);
        console.log("Remainder:", remainder);
        console.log("---");
        console.log("Challenger 1 (base + remainder):", reward1);
        console.log("Challenger 2 (base only):", reward2);
        console.log("Challenger 3 (base only):", reward3);

        assertEq(reward1, baseShare + remainder, "First gets base + remainder");
        assertEq(reward2, baseShare, "Second gets base only");
        assertEq(reward3, baseShare, "Third gets base only");

        // Verify no tokens lost
        assertEq(reward1 + reward2 + reward3, totalReward, "No tokens lost");

        console.log("[OK] Remainder correctly distributed");
    }

    // ============================================
    // 시나리오 12: 나머지 분배 - 4명 (나머지 0 가능)
    // ============================================

    function test_Remainder_FourChallengers() public {
        console.log("\n=== Scenario: Four Challengers Distribution ===");

        uint256 stakeAmount = 10000 * 1e18;
        (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        ) = _setupMultiChallengerGame(4);

        address[] memory challengers = _getChallengersByCount(4);
        uint256[] memory balancesBefore = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            balancesBefore[i] = _getWtonBalance(challengers[i]);
        }

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 baseShare = totalReward / 4;
        uint256 remainder = totalReward % 4;

        console.log("Total reward:", totalReward);
        console.log("Base share:", baseShare);
        console.log("Remainder:", remainder);
        console.log("---");

        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < 4; i++) {
            uint256 reward = _getWtonBalance(challengers[i]) - balancesBefore[i];
            totalDistributed += reward;

            if (i == 0) {
                assertEq(reward, baseShare + remainder, "First gets base + remainder");
                console.log("Challenger", i + 1, "(base + remainder):", reward);
            } else {
                assertEq(reward, baseShare, "Others get base only");
                console.log("Challenger", i + 1, "(base only):", reward);
            }
        }

        assertEq(totalDistributed, totalReward, "Total distributed equals total reward");
        console.log("[OK] Four-way distribution verified");
    }

    // ============================================
    // 시나리오 13: 매우 작은 보상금 분배
    // ============================================

    function test_Remainder_SmallReward() public {
        console.log("\n=== Scenario: Small Reward Distribution ===");

        // Minimum stake amount
        uint256 stakeAmount = 1001 * 1e18; // >1000 TON minimum
        (
            address opMgr,
            MockFaultDisputeGame3 game,
            GameType gt,
            Claim rc,
            bytes memory ed
        ) = _setupSmallRewardGame(stakeAmount);

        uint256 bal1Before = _getWtonBalance(challenger);
        uint256 bal2Before = _getWtonBalance(challenger2);
        uint256 bal3Before = _getWtonBalance(challenger3);

        _executeSlashing(opMgr, gt, rc, ed, address(game));

        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 distributed = (_getWtonBalance(challenger) - bal1Before) +
            (_getWtonBalance(challenger2) - bal2Before) +
            (_getWtonBalance(challenger3) - bal3Before);

        assertEq(distributed, totalReward, "No tokens lost with small reward");
        console.log("Total reward:", totalReward);
        console.log("[OK] Small reward distribution verified");
    }

    function _setupSmallRewardGame(
        uint256 stakeAmount
    )
        internal
        returns (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        )
    {
        // Use the existing rollupConfig from base setup
        address testOperator = makeAddr("smallOperator");
        (operatorManager, ) = _registerCandidateAndStake(testOperator, rollupConfig, stakeAmount);

        (gameType, rootClaim, extraData) = _getDefaultGameParams();
        MockDisputeGameFactory gf = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gf))
        );

        game = MockFaultDisputeGame3(address(gf.create(gameType, rootClaim, extraData)));
        game.initialize();

        vm.prank(challenger);
        game.step();
        game.addWinningChallenger(challenger2);
        game.addWinningChallenger(challenger3);
        game.resolve();
    }

    // ============================================
    // 시나리오 14: 큰 나머지 케이스 (5명, 나머지 최대 4)
    // ============================================

    function test_Remainder_LargeRemainder() public {
        console.log("\n=== Scenario: Large Remainder with 5 Challengers ===");

        uint256 stakeAmount = 10001 * 1e18;
        (
            address opMgr,
            MockFaultDisputeGame3 game,
            GameType gt,
            Claim rc,
            bytes memory ed
        ) = _setupLargeRemainderGame(stakeAmount);

        address[] memory challs = _getChallengersByCount(5);
        uint256[] memory balsBefore = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            balsBefore[i] = _getWtonBalance(challs[i]);
        }

        _executeSlashing(opMgr, gt, rc, ed, address(game));

        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 baseShare = totalReward / 5;
        uint256 remainder = totalReward % 5;

        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < 5; i++) {
            totalDistributed += _getWtonBalance(challs[i]) - balsBefore[i];
        }

        uint256 firstReward = _getWtonBalance(challs[0]) - balsBefore[0];
        assertEq(firstReward, baseShare + remainder, "First gets base + remainder");
        assertEq(totalDistributed, totalReward, "Total distributed equals total reward");

        console.log("Total reward:", totalReward);
        console.log("Remainder:", remainder);
        console.log("[OK] Large remainder distribution verified");
    }

    function _setupLargeRemainderGame(
        uint256 stakeAmount
    )
        internal
        returns (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        )
    {
        // Use the existing rollupConfig from base setup
        address testOperator = makeAddr("largeOperator");
        (operatorManager, ) = _registerCandidateAndStake(testOperator, rollupConfig, stakeAmount);

        (gameType, rootClaim, extraData) = _getDefaultGameParams();
        MockDisputeGameFactory gf = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gf))
        );

        game = MockFaultDisputeGame3(address(gf.create(gameType, rootClaim, extraData)));
        game.initialize();

        address[] memory challs = _getChallengersByCount(5);
        vm.prank(challs[0]);
        game.step();
        for (uint256 i = 1; i < 5; i++) {
            game.addWinningChallenger(challs[i]);
        }
        game.resolve();
    }

    // ============================================
    // 시나리오 15: 2명으로 정확히 나누어 떨어지는 경우
    // ============================================

    function test_Remainder_ExactDivision() public {
        console.log("\n=== Scenario: Exact Division (No Remainder) ===");

        // 10000 TON stake * 1e9 = 10000e27 WTON
        // 10% reward = 1000e27 WTON
        // Divided by 2 = 500e27 each (no remainder)
        uint256 stakeAmount = 10000 * 1e18;
        (
            address operatorManager,
            MockFaultDisputeGame3 game,
            GameType gameType,
            Claim rootClaim,
            bytes memory extraData
        ) = _setupMultiChallengerGame(2);

        uint256 balance1Before = _getWtonBalance(challenger);
        uint256 balance2Before = _getWtonBalance(challenger2);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        uint256 totalReward = _calculateExpectedReward(stakeAmount);
        uint256 expectedEach = totalReward / 2;
        uint256 remainder = totalReward % 2;

        uint256 reward1 = _getWtonBalance(challenger) - balance1Before;
        uint256 reward2 = _getWtonBalance(challenger2) - balance2Before;

        console.log("Total reward:", totalReward);
        console.log("Expected each:", expectedEach);
        console.log("Remainder:", remainder);
        console.log("---");
        console.log("Challenger 1:", reward1);
        console.log("Challenger 2:", reward2);

        // With exact division, both should be equal
        if (remainder == 0) {
            assertEq(reward1, reward2, "Both should be equal when no remainder");
        } else {
            assertEq(reward1, expectedEach + remainder, "First gets remainder");
            assertEq(reward2, expectedEach, "Second gets base");
        }

        console.log("[OK] Exact division verified");
    }
}
