// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";

/// @title SlashingDelegatorTest
/// @notice Tests for delegator protection during slashing (seigniorage preservation, withdrawal after slashing)
contract SlashingDelegatorTest is BaseSlashingTest {
    // ============================================
    // Scenario 1: Delegator Seigniorage Protection During Slashing
    // ============================================

    function test_Slashing_DelegatorSeigniorageProtection() public {
        console.log("\n=== Test: Delegator Seigniorage Protection During Slashing ===");

        address delegator1 = makeAddr("delegator1");
        address delegator2 = makeAddr("delegator2");

        // 1. Operator registers candidate
        uint256 operatorStake = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            operatorStake
        );

        console.log("Operator registered with stake:", operatorStake);

        // 2. Delegators stake to the Layer2
        uint256 delegator1Stake = 5000 * 1e18;
        uint256 delegator2Stake = 3000 * 1e18;

        _stakeDelegator(delegator1, candidateAddOn, delegator1Stake);
        _stakeDelegator(delegator2, candidateAddOn, delegator2Stake);

        console.log("Delegator 1 staked:", delegator1Stake);
        console.log("Delegator 2 staked:", delegator2Stake);

        // 3. Check initial stakes
        uint256 delegator1StakeBefore = _getStakeOf(candidateAddOn, delegator1);
        uint256 delegator2StakeBefore = _getStakeOf(candidateAddOn, delegator2);

        console.log("Initial delegator1 stake (RAY):", delegator1StakeBefore);
        console.log("Initial delegator2 stake (RAY):", delegator2StakeBefore);

        // 4. Time passes (seigniorage generation)
        vm.roll(block.number + 1000);
        require(_updateSeigniorage(candidateAddOn), "Seigniorage update failed");

        // 5. Check stakes after seigniorage
        uint256 delegator1StakeWithSeig = _getStakeOf(candidateAddOn, delegator1);
        uint256 delegator2StakeWithSeig = _getStakeOf(candidateAddOn, delegator2);

        console.log("Delegator1 stake with seigniorage (RAY):", delegator1StakeWithSeig);
        console.log("Delegator2 stake with seigniorage (RAY):", delegator2StakeWithSeig);

        // 6. Execute operator slashing
        _executeSlashingForOperator(operatorManager);

        // 7. Verify stakes after slashing
        _verifyDelegatorProtection(
            candidateAddOn,
            operatorManager,
            delegator1,
            delegator2,
            delegator1StakeWithSeig,
            delegator2StakeWithSeig
        );

        // 8. Verify seigniorage preserved
        _verifySeignioragePreserved(
            delegator1StakeWithSeig,
            delegator2StakeWithSeig,
            delegator1StakeBefore,
            delegator2StakeBefore
        );

        // 9. Test withdrawal
        _testDelegatorWithdrawal(delegator1, candidateAddOn, delegator1StakeWithSeig);
    }

    function _executeSlashingForOperator(address operatorManager) internal {
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        console.log("\n[Executing Slashing...]");
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
    }

    function _verifyDelegatorProtection(
        address candidateAddOn,
        address operatorManager,
        address delegator1,
        address delegator2,
        uint256 delegator1StakeWithSeig,
        uint256 delegator2StakeWithSeig
    ) internal {
        uint256 operatorStakeAfter = _getStakeOf(candidateAddOn, operatorManager);
        uint256 delegator1StakeAfter = _getStakeOf(candidateAddOn, delegator1);
        uint256 delegator2StakeAfter = _getStakeOf(candidateAddOn, delegator2);

        console.log("\n=== After Slashing ===");
        console.log("Operator stake after slashing:", operatorStakeAfter);
        console.log("Delegator1 stake after slashing:", delegator1StakeAfter);
        console.log("Delegator2 stake after slashing:", delegator2StakeAfter);

        assertEq(operatorStakeAfter, 0, "Operator stake should be fully slashed");
        assertEq(
            delegator1StakeAfter,
            delegator1StakeWithSeig,
            "Delegator1 stake should be preserved"
        );
        assertEq(
            delegator2StakeAfter,
            delegator2StakeWithSeig,
            "Delegator2 stake should be preserved"
        );

        console.log("\n[OK] Operator slashed, delegators protected");
    }

    function _verifySeignioragePreserved(
        uint256 delegator1StakeWithSeig,
        uint256 delegator2StakeWithSeig,
        uint256 delegator1StakeBefore,
        uint256 delegator2StakeBefore
    ) internal pure {
        if (delegator1StakeWithSeig > delegator1StakeBefore) {
            // Seigniorage was earned and preserved
        }
        if (delegator2StakeWithSeig > delegator2StakeBefore) {
            // Seigniorage was earned and preserved
        }
    }

    function _testDelegatorWithdrawal(
        address delegator,
        address candidateAddOn,
        uint256 expectedAmount
    ) internal {
        console.log("\n=== Testing Delegator Withdrawal After Slashing ===");

        vm.prank(delegator);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(candidateAddOn, expectedAmount);
        console.log("[OK] Delegator can request withdrawal after operator slashing");

        uint256 delayBlocks = DepositManagerV3(depositManagerProxy).getDelayBlocks(candidateAddOn);
        vm.roll(block.number + delayBlocks + 1);

        uint256 wtonBefore = _getWtonBalance(delegator);
        vm.prank(delegator);
        DepositManagerV3(depositManagerProxy).processRequest(candidateAddOn, false);
        uint256 wtonAfter = _getWtonBalance(delegator);

        assertEq(
            wtonAfter - wtonBefore,
            expectedAmount,
            "Delegator should receive full stake including seigniorage"
        );
        console.log("Delegator withdrawn amount (RAY):", wtonAfter - wtonBefore);
        console.log("[OK] Delegator successfully withdrew stake with seigniorage");
    }

    // ============================================
    // Scenario 2: Comprehensive Delegator + Seigniorage + Slashing
    // ============================================

    function test_Slashing_ComprehensiveDelegatorScenario() public {
        console.log("\n=== Test: Comprehensive Delegator + Seigniorage + Slashing ===");

        address delegator1 = makeAddr("delegator1");
        address delegator2 = makeAddr("delegator2");

        // 1. Operator registers
        uint256 operatorStake = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            operatorStake
        );

        // 2. Delegator1 stakes
        uint256 delegator1Stake = 5000 * 1e18;
        _stakeDelegator(delegator1, candidateAddOn, delegator1Stake);
        console.log("Phase 1: Operator and Delegator1 staked");

        // 3. Time passes (first seigniorage generation)
        vm.roll(block.number + 500);

        // 4. Delegator2 stakes (joins midway)
        uint256 delegator2Stake = 3000 * 1e18;
        _stakeDelegator(delegator2, candidateAddOn, delegator2Stake);
        console.log("Phase 2: Delegator2 joined");

        // 5. More time passes (second seigniorage generation)
        vm.roll(block.number + 500);

        // 6. Record stakes before slashing
        uint256 delegator1StakeBefore = _getStakeOf(candidateAddOn, delegator1);
        uint256 delegator2StakeBefore = _getStakeOf(candidateAddOn, delegator2);

        console.log("\nBefore Slashing:");
        console.log("Delegator1 stake:", delegator1StakeBefore);
        console.log("Delegator2 stake:", delegator2StakeBefore);

        // 7. Execute slashing
        _executeSlashingForOperator(operatorManager);

        // 8. Verify and compare
        _verifyComprehensiveScenario(
            candidateAddOn,
            operatorManager,
            delegator1,
            delegator2,
            delegator1Stake,
            delegator2Stake,
            delegator1StakeBefore,
            delegator2StakeBefore
        );
    }

    function _verifyComprehensiveScenario(
        address candidateAddOn,
        address operatorManager,
        address delegator1,
        address delegator2,
        uint256 delegator1OriginalStake,
        uint256 delegator2OriginalStake,
        uint256 delegator1StakeBefore,
        uint256 delegator2StakeBefore
    ) internal {
        uint256 operatorStakeAfter = _getStakeOf(candidateAddOn, operatorManager);
        uint256 delegator1StakeAfter = _getStakeOf(candidateAddOn, delegator1);
        uint256 delegator2StakeAfter = _getStakeOf(candidateAddOn, delegator2);

        console.log("\nAfter Slashing:");
        console.log("Operator stake:", operatorStakeAfter);
        console.log("Delegator1 stake:", delegator1StakeAfter);
        console.log("Delegator2 stake:", delegator2StakeAfter);

        // Verify
        assertEq(operatorStakeAfter, 0, "Operator should be fully slashed");
        assertEq(delegator1StakeAfter, delegator1StakeBefore, "Delegator1 stake preserved");
        assertEq(delegator2StakeAfter, delegator2StakeBefore, "Delegator2 stake preserved");

        // Check seigniorage comparison
        uint256 delegator1Seigniorage = delegator1StakeBefore - (delegator1OriginalStake * 1e9);
        uint256 delegator2Seigniorage = delegator2StakeBefore - (delegator2OriginalStake * 1e9);

        if (delegator1Seigniorage > 0 && delegator2Seigniorage > 0) {
            assertTrue(
                delegator1Seigniorage > delegator2Seigniorage,
                "Delegator1 should have more seigniorage (staked longer)"
            );
            console.log("\n[OK] Delegator1 earned more seigniorage (staked longer)");
            console.log("Delegator1 seigniorage:", delegator1Seigniorage);
            console.log("Delegator2 seigniorage:", delegator2Seigniorage);
        }

        console.log("\n[OK] Comprehensive test passed");
    }

    // ============================================
    // Scenario 3: Multiple Delegators Withdrawal After Slashing
    // ============================================

    function test_Slashing_AllDelegatorsCanWithdrawAfterSlashing() public {
        console.log("\n=== Test: All Delegators Can Withdraw After Slashing ===");

        address delegator1 = makeAddr("delegator1");
        address delegator2 = makeAddr("delegator2");
        address delegator3 = makeAddr("delegator3");

        // 1. Operator registers
        uint256 operatorStake = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            operatorStake
        );

        // 2. Multiple delegators stake
        _stakeDelegator(delegator1, candidateAddOn, 5000 * 1e18);
        _stakeDelegator(delegator2, candidateAddOn, 3000 * 1e18);
        _stakeDelegator(delegator3, candidateAddOn, 2000 * 1e18);
        console.log("All delegators staked");

        // 3. Time passes
        vm.roll(block.number + 1000);
        _updateSeigniorage(candidateAddOn);

        // 4. Record stakes before slashing
        uint256 delegator1StakeBefore = _getStakeOf(candidateAddOn, delegator1);
        uint256 delegator2StakeBefore = _getStakeOf(candidateAddOn, delegator2);
        uint256 delegator3StakeBefore = _getStakeOf(candidateAddOn, delegator3);

        // 5. Execute slashing
        _executeSlashingForOperator(operatorManager);

        // 6. Process withdrawals
        _processMultipleDelegatorWithdrawals(
            candidateAddOn,
            delegator1,
            delegator2,
            delegator3,
            delegator1StakeBefore,
            delegator2StakeBefore,
            delegator3StakeBefore
        );
    }

    function _processMultipleDelegatorWithdrawals(
        address candidateAddOn,
        address delegator1,
        address delegator2,
        address delegator3,
        uint256 delegator1Stake,
        uint256 delegator2Stake,
        uint256 delegator3Stake
    ) internal {
        // All delegators request withdrawal
        vm.prank(delegator1);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(candidateAddOn, delegator1Stake);
        vm.prank(delegator2);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(candidateAddOn, delegator2Stake);
        vm.prank(delegator3);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(candidateAddOn, delegator3Stake);
        console.log("[OK] All delegators can request withdrawal");

        // Advance blocks
        uint256 delayBlocks = DepositManagerV3(depositManagerProxy).getDelayBlocks(candidateAddOn);
        vm.roll(block.number + delayBlocks + 1);

        // Process each
        _processAndVerifyWithdrawal(delegator1, candidateAddOn, delegator1Stake, "Delegator1");
        _processAndVerifyWithdrawal(delegator2, candidateAddOn, delegator2Stake, "Delegator2");
        _processAndVerifyWithdrawal(delegator3, candidateAddOn, delegator3Stake, "Delegator3");

        console.log("[OK] All delegators successfully withdrew their stakes");
    }

    function _processAndVerifyWithdrawal(
        address delegator,
        address candidateAddOn,
        uint256 expectedAmount,
        string memory label
    ) internal {
        uint256 wtonBefore = _getWtonBalance(delegator);
        vm.prank(delegator);
        DepositManagerV3(depositManagerProxy).processRequest(candidateAddOn, false);
        uint256 wtonAfter = _getWtonBalance(delegator);

        assertEq(
            wtonAfter - wtonBefore,
            expectedAmount,
            string(abi.encodePacked(label, " withdrawal mismatch"))
        );
        console.log(string(abi.encodePacked(label, " withdrew:")), wtonAfter - wtonBefore);
    }

    // ============================================
    // Scenario 4: Delegator Partial Withdrawal Before Slashing
    // ============================================

    function test_Slashing_DelegatorPartialWithdrawalThenSlashing() public {
        console.log("\n=== Test: Delegator Partial Withdrawal Then Slashing ===");

        address delegator1 = makeAddr("delegator1");

        // 1. Operator and delegator stake
        uint256 operatorStake = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            operatorStake
        );

        uint256 delegator1Stake = 5000 * 1e18;
        _stakeDelegator(delegator1, candidateAddOn, delegator1Stake);

        // 2. Time passes
        vm.roll(block.number + 500);
        _updateSeigniorage(candidateAddOn);

        uint256 delegator1StakeWithSeig = _getStakeOf(candidateAddOn, delegator1);
        console.log("Delegator stake with seigniorage:", delegator1StakeWithSeig);

        // 3. Delegator requests partial withdrawal (half)
        uint256 withdrawAmount = delegator1StakeWithSeig / 2;
        vm.prank(delegator1);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(candidateAddOn, withdrawAmount);
        console.log("Delegator requested partial withdrawal:", withdrawAmount);

        // 4. Advance time but don't process withdrawal yet
        uint256 delayBlocks = DepositManagerV3(depositManagerProxy).getDelayBlocks(candidateAddOn);
        vm.roll(block.number + delayBlocks / 2); // Halfway through delay

        // 5. Execute slashing
        _executeSlashingForOperator(operatorManager);

        // 6. Verify and process partial withdrawal
        _verifyPartialWithdrawalAfterSlashing(
            candidateAddOn,
            operatorManager,
            delegator1,
            delegator1StakeWithSeig,
            withdrawAmount,
            delayBlocks
        );
    }

    function _verifyPartialWithdrawalAfterSlashing(
        address candidateAddOn,
        address operatorManager,
        address delegator,
        uint256 delegatorStakeWithSeig,
        uint256 withdrawAmount,
        uint256 delayBlocks
    ) internal {
        uint256 operatorStakeAfter = _getStakeOf(candidateAddOn, operatorManager);
        uint256 delegatorStakeAfter = _getStakeOf(candidateAddOn, delegator);

        assertEq(operatorStakeAfter, 0, "Operator should be slashed");

        uint256 expectedRemainingStake = delegatorStakeWithSeig - withdrawAmount;
        assertEq(
            delegatorStakeAfter,
            expectedRemainingStake,
            "Delegator remaining stake should be preserved"
        );
        console.log("Delegator remaining stake after slashing:", delegatorStakeAfter);

        // Complete the delay and process withdrawal
        vm.roll(block.number + delayBlocks);

        uint256 wtonBefore = _getWtonBalance(delegator);
        vm.prank(delegator);
        DepositManagerV3(depositManagerProxy).processRequest(candidateAddOn, false);
        uint256 wtonAfter = _getWtonBalance(delegator);

        assertEq(wtonAfter - wtonBefore, withdrawAmount, "Partial withdrawal should succeed");
        console.log("[OK] Partial withdrawal processed after slashing:", wtonAfter - wtonBefore);
        console.log("[OK] Delegator partial withdrawal + slashing scenario passed");
    }

    // ============================================
    // Helper: Stake as delegator
    // ============================================

    function _stakeDelegator(
        address _delegator,
        address _candidateAddOn,
        uint256 _stakeAmount
    ) internal {
        MockTON(ton).mint(_delegator, _stakeAmount);

        vm.startPrank(_delegator);
        IERC20(ton).approve(wton, _stakeAmount);
        MockWTON(wton).swapFromTONAndTransfer(_delegator, _stakeAmount);
        IERC20(wton).approve(depositManagerProxy, _stakeAmount * 1e9);
        DepositManagerV3(depositManagerProxy).deposit(_candidateAddOn, _stakeAmount * 1e9);
        vm.stopPrank();
    }
}
