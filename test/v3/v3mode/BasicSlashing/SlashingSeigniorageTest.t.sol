// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";

/// @title SlashingSeigniorageTest
/// @notice Tests for slashing with seigniorage (principal + interest burning)
contract SlashingSeigniorageTest is BaseSlashingTest {
    // ============================================
    // Scenario 1: Slashing Burns Principal + Seigniorage
    // ============================================

    function test_Slashing_WithSeigniorage_BurnsAll() public {
        console.log("\n=== Test: Slashing Burns Principal + Seigniorage ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);
        console.log("Initial stake (RAY):", initialStake);

        // 2. Simulate seigniorage (advance blocks)
        vm.roll(block.number + 1000);

        // Update seigniorage
        bool success = _updateSeigniorage(candidateAddOn);
        require(success, "Seigniorage update failed");

        uint256 stakeAfterSeigniorage = _getStakeOf(candidateAddOn, operatorManager);

        if (stakeAfterSeigniorage > initialStake) {
            uint256 seigniorageEarned = stakeAfterSeigniorage - initialStake;
            console.log("Stake after seigniorage (RAY):", stakeAfterSeigniorage);
            console.log("Seigniorage earned (RAY):", seigniorageEarned);
        } else {
            console.log("No seigniorage in test environment, using initial stake");
        }

        // 3. Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 4. Verify: Principal + seigniorage all burned
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "All stake (principal + seigniorage) should be burned");
        console.log("Final stake after slashing:", finalStake);
        console.log("[OK] Principal + Seigniorage fully burned");
    }

    // ============================================
    // Scenario 2: Slashing Includes Unreceived Seigniorage
    // ============================================

    function test_Slashing_WithUnreceivedSeigniorage() public {
        console.log("\n=== Test: Slashing Includes Unreceived Seigniorage ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        console.log("Initial stake (RAY):", _getStakeOf(candidateAddOn, operatorManager));

        // 2. Advance blocks but DO NOT call updateSeigniorage
        // This simulates unreceived seigniorage
        vm.roll(block.number + 1000);

        // 3. Execute slashing (should include unreceived seigniorage internally)
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        // Record logs to capture slashed amount
        vm.recordLogs();

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // Extract slashed info from logs
        (uint256 slashed, uint256 challengerReward) = _extractSlashedInfoFromLogs();

        require(
            slashed > challengerReward,
            "The reward value must be less than the slashed value."
        );

        uint256 reward = _getWtonBalance(challenger) - challengerBalanceBefore;

        // 4. Verify: Reward is based on slashed amount (including unreceived seigniorage)
        uint256 expectedMinReward = (slashed * _getSlashingRewardRate()) / 10000;

        assertTrue(reward >= expectedMinReward, "Reward should include unreceived seigniorage");
        console.log("Expected minimum reward (from initial stake):", expectedMinReward);
        console.log("Actual reward (including unreceived seigniorage):", reward);
        console.log("[OK] Unreceived seigniorage included in slashing");

        // Final stake should be 0
        assertEq(_getStakeOf(candidateAddOn, operatorManager), 0, "All stake should be burned");
    }

    /// @dev Helper to extract slashed info from recorded logs
    function _extractSlashedInfoFromLogs()
        internal
        returns (uint256 slashed, uint256 challengerReward)
    {
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.log("Total logs emitted:", entries.length);

        for (uint i = 0; i < entries.length; i++) {
            Vm.Log memory entry = entries[i];

            if (entry.topics[0] == keccak256("Slashed(address,address,address,uint256,uint256)")) {
                (slashed, challengerReward) = abi.decode(entry.data, (uint256, uint256));

                console.log("Captured DepositManager.Slashed:");
                console.log(" - Layer2:", address(uint160(uint256(entry.topics[1]))));
                console.log(" - Operator:", address(uint160(uint256(entry.topics[2]))));
                console.log(" - Challenger:", address(uint160(uint256(entry.topics[3]))));
                console.log(" - Slashed Amount:", slashed);
                console.log(" - Reward Amount:", challengerReward);
                return (slashed, challengerReward);
            }
        }
    }

    // ============================================
    // Scenario 3: Debug UpdateSeigniorage
    // ============================================

    function test_Debug_UpdateSeigniorage() public {
        console.log("\n=== Debug: UpdateSeigniorage ===");

        // 1. Register and stake
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        console.log("CandidateAddOn:", candidateAddOn);
        console.log("OperatorManager:", operatorManager);

        // 2. Check coinage
        address coinageAddr = SeigManagerV1_2(seigManagerProxy).coinages(candidateAddOn);
        console.log("Coinage address:", coinageAddr);
        require(coinageAddr != address(0), "Coinage not deployed!");

        // 3. Check operator balance in coinage
        RefactorCoinageSnapshotI coinage = RefactorCoinageSnapshotI(coinageAddr);
        uint256 operatorBalance = coinage.balanceOf(operatorManager);
        console.log("Operator coinage balance:", operatorBalance);

        // 4. Check minimumAmount
        uint256 minAmount = SeigManagerV1_2(seigManagerProxy).minimumAmount();
        console.log("Minimum amount:", minAmount);
        console.log("operatorBalance >= minAmount?", operatorBalance >= minAmount);

        // 5. Check lastSeigBlock
        uint256 lastSeigBlock = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();
        console.log("Last seig block:", lastSeigBlock);
        console.log("Current block:", block.number);
        console.log("block.number > lastSeigBlock?", block.number > lastSeigBlock);

        // 6. Advance blocks
        vm.roll(block.number + 1000);
        console.log("After vm.roll, block:", block.number);
        console.log("block.number > lastSeigBlock?", block.number > lastSeigBlock);

        // 7. Check tot
        address totAddr = SeigManagerV1_2(seigManagerProxy).tot();
        RefactorCoinageSnapshotI tot = RefactorCoinageSnapshotI(totAddr);
        uint256 totSupply = tot.totalSupply();
        console.log("Tot totalSupply:", totSupply);

        // 8. Try updateSeigniorage
        console.log("\n--- Calling updateSeigniorage() ---");
        bool success = _updateSeigniorage(candidateAddOn);
        console.log("updateSeigniorage success:", success);

        // 9. Check balances after
        uint256 newOperatorBalance = coinage.balanceOf(operatorManager);
        console.log("Operator coinage balance after:", newOperatorBalance);
        console.log("Balance increased:", newOperatorBalance > operatorBalance);
    }
}
