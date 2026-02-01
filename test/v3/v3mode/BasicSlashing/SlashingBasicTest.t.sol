// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";

/// @title SlashingBasicTest
/// @notice Tests for basic candidate registration, staking, and slashing functionality
contract SlashingBasicTest is BaseSlashingTest {
    // ============================================
    // Scenario 1: Candidate Registration and Staking
    // ============================================

    function test_CandidateRegistrationAndStaking() public {
        uint256 stakeAmount = 10000 * 1e18; // 10,000 TON

        console.log("Step 1: Minting TON to operator");
        MockTON(ton).mint(operator, stakeAmount);
        console.log("Operator TON balance:", IERC20(ton).balanceOf(operator));

        console.log("Step 2: Starting prank as operator");
        vm.startPrank(operator);

        console.log("Step 3: Approving Layer2Manager");
        IERC20(ton).approve(layer2ManagerProxy, stakeAmount);
        console.log("Approval successful");

        console.log("Step 4: Registering candidate");
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig,
            stakeAmount,
            true, // Use TON
            "MyOperator"
        );
        console.log("Registration successful");
        vm.stopPrank();

        console.log("Step 5: Verifying registration");
        address operatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig
        );
        address candidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            operatorManager
        );

        assertTrue(candidateAddOn != address(0), "Candidate registration failed");

        uint256 stakedAmount = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(stakedAmount, stakeAmount * 1e9, "Staked amount mismatch (RAY)");

        console.log("Candidate Registered at:", candidateAddOn);
        console.log("Operator Manager at:", operatorManager);
    }

    // ============================================
    // Scenario 2: Basic Slashing and Reward
    // ============================================

    function test_SlashingAndReward() public {
        // 1. Register and stake
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(initialStake, stakeAmount * 1e9, "Initial stake mismatch");

        // 2. Setup dispute game
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (MockDisputeGameFactory2 gameFactory, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );

        // 3. Challenger wins
        _makeChallengerWin(game);

        // 4. Execute slashing
        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 5. Verify results
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "Stake should be zeroed");

        // Verify reward (default 10% reward)
        uint256 slashingRewardRate = _getSlashingRewardRate();
        uint256 rewardAmount = (initialStake * slashingRewardRate) / 10000;
        uint256 challengerBalanceAfter = _getWtonBalance(challenger);

        assertEq(
            challengerBalanceAfter - challengerBalanceBefore,
            rewardAmount,
            "Challenger reward mismatch"
        );

        console.log("Slashing Successful!");
        console.log("Slashed Amount (RAY):", initialStake);
        console.log("Challenger Reward (RAY):", rewardAmount);
    }

    // ============================================
    // Scenario 3: Slashing Event Emission
    // ============================================

    function test_SlashingEventEmission() public {
        console.log("\n=== Test: Slashing Event Emission ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);

        // 2. Setup dispute game
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        // 3. Record logs and execute slashing
        vm.recordLogs();

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.log("Total logs emitted:", entries.length);

        bool slashedEventFound = false;
        for (uint i = 0; i < entries.length; i++) {
            Vm.Log memory entry = entries[i];

            // Slashed(address indexed layer2, address indexed operator, address indexed challenger, uint256 slashed, uint256 reward)
            if (entry.topics[0] == keccak256("Slashed(address,address,address,uint256,uint256)")) {
                slashedEventFound = true;
                address l2 = address(uint160(uint256(entry.topics[1])));
                address op = address(uint160(uint256(entry.topics[2])));
                address chal = address(uint160(uint256(entry.topics[3])));
                (uint256 slashed, uint256 reward) = abi.decode(entry.data, (uint256, uint256));

                console.log("Captured DepositManager.Slashed:");
                console.log(" - Layer2:", l2);
                console.log(" - Operator:", op);
                console.log(" - Challenger:", chal);
                console.log(" - Slashed Amount:", slashed);
                console.log(" - Reward Amount:", reward);
            }
        }

        assertTrue(slashedEventFound, "Slashed event should be emitted");

        // 4. Verify slashing result
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "Stake should be zero after slashing");

        console.log("[OK] Slashing completed - events emitted");
    }
}
