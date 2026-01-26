// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";

/// @title SlashingSecurityTest
/// @notice Tests for slashing security: double slashing prevention and authorization
contract SlashingSecurityTest is BaseSlashingTest {
    // ============================================
    // Scenario 1: Prevent Double Slashing
    // ============================================

    function test_Slashing_PreventDoubleSlashing() public {
        console.log("\n=== Test: Prevent Double Slashing ===");

        // 1. Register, stake, and perform first slashing
        uint256 totalAmount = 100000 * 1e18;
        uint256 stakeAmount = 10000 * 1e18;
        MockTON(ton).mint(operator, totalAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true,
            "MyOperator"
        );
        vm.stopPrank();

        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        // First slashing
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
        console.log("[OK] First slashing successful");

        // 2. Operator re-stakes (simulating fund recovery via direct deposit)
        vm.startPrank(operator);

        IERC20(ton).approve(address(wton), stakeAmount);
        IWTON(wton).swapFromTON(stakeAmount);

        address myCandidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );
        uint256 wtonBalance = IERC20(wton).balanceOf(operator);

        IERC20(wton).approve(depositManagerProxy, wtonBalance);

        console.log("Attempting to deposit WTON (RAY):", wtonBalance);

        try
            DepositManagerV3(depositManagerProxy).deposit(
                myCandidateAddOn,
                operatorManager,
                wtonBalance
            )
        {
            console.log("Deposit successful");
        } catch Error(string memory reason) {
            console.log("Deposit failed with reason:", reason);
            revert(reason);
        } catch (bytes memory) {
            console.log("Deposit failed with low-level error");
            revert("Deposit failed low-level");
        }
        vm.stopPrank();

        // Verify stake recovery
        uint256 currentStake = _getStakeOf(myCandidateAddOn, operatorManager);
        console.log("Restaked amount (RAY):", currentStake);
        require(currentStake > 0, "Stake should be restored");

        // 3. Attempt second slashing (Replay Attack) - should fail even with funds!
        vm.expectRevert(abi.encodeWithSignature("SlashingError()"));
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        console.log("[OK] Double slashing prevented (even with funds)");
    }

    // ============================================
    // Scenario 2: Unauthorized DepositManager.slash Access
    // ============================================

    function test_Slashing_UnauthorizedDepositManagerAccess() public {
        console.log("\n=== Test: Unauthorized DepositManager.slash Access ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Attacker tries to directly call DepositManager.slash
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(); // "not layer2Manager" or similar error expected
        DepositManager_Slashing(address(depositManagerProxy)).slash(
            candidateAddOn,
            operatorManager,
            challenger
        );

        console.log("[OK] Unauthorized DepositManager.slash call prevented");

        // 3. Verify stake unchanged
        uint256 stakeAfterAttack = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(stakeAfterAttack, stakeAmount * 1e9, "Stake should remain unchanged");
        console.log("[OK] Stake unchanged after unauthorized attempt");
    }

    // ============================================
    // Scenario 3: Unauthorized SeigManager.onSlash Access
    // ============================================

    function test_Slashing_UnauthorizedSeigManagerAccess() public {
        console.log("\n=== Test: Unauthorized SeigManager.onSlash Access ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Attacker tries to directly call SeigManager.onSlash
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(); // "not onlyDepositManager" or similar error expected
        SeigManager_Slashing(address(seigManagerProxy)).onSlash(candidateAddOn, operatorManager);

        console.log("[OK] Unauthorized SeigManager.onSlash call prevented");

        // 3. Verify stake unchanged
        uint256 stakeAfterAttack = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(stakeAfterAttack, stakeAmount * 1e9, "Stake should remain unchanged");
        console.log("[OK] Stake unchanged after unauthorized SeigManager access attempt");
    }

    // ============================================
    // Scenario 4: Only Challenger as Winner Gets Reward
    // ============================================

    function test_Slashing_OnlyWinnerGetsReward() public {
        console.log("\n=== Test: Only Winner Gets Reward ===");

        address fakeChallenger = makeAddr("fakeChallenger");

        // Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // Setup and execute slashing with real challenger
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game); // Real challenger wins

        uint256 realChallengerBalanceBefore = _getWtonBalance(challenger);
        uint256 fakeChallengerBalanceBefore = _getWtonBalance(fakeChallenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // Verify: Real challenger gets reward, fake challenger gets nothing
        uint256 realChallengerBalanceAfter = _getWtonBalance(challenger);
        uint256 fakeChallengerBalanceAfter = _getWtonBalance(fakeChallenger);

        assertTrue(
            realChallengerBalanceAfter > realChallengerBalanceBefore,
            "Real challenger should receive reward"
        );
        assertEq(
            fakeChallengerBalanceAfter,
            fakeChallengerBalanceBefore,
            "Fake challenger should receive nothing"
        );

        console.log(
            "Real challenger reward:",
            realChallengerBalanceAfter - realChallengerBalanceBefore
        );
        console.log("[OK] Only real challenger received reward");
    }
}
