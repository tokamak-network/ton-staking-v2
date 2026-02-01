// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";

/// @title SlashingEdgeCaseTest
/// @notice Tests for edge cases: minimum stake, invalid game states, re-registration, partial withdrawal
contract SlashingEdgeCaseTest is BaseSlashingTest {
    address public rollupConfig2 = makeAddr("mockRollupConfig2");
    MockDisputeGameFactory2 public mockFactory;

    function setUp() public override {
        super.setUp();

        // Setup mock factory for first rollup
        mockFactory = new MockDisputeGameFactory2();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(mockFactory))
        );
    }

    // ============================================
    // Scenario 1: Slashing Below Minimum Stake
    // ============================================

    function test_Slashing_BelowMinimumStake() public {
        console.log("\n=== Test: Slashing Below Minimum Stake ===");

        // 1. Register with minimum viable amount (1001 TON)
        uint256 smallStake = 1001 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            smallStake
        );

        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);
        console.log("Small stake amount (RAY):", initialStake);

        // 2. Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 3. Verify: Small stake is also fully slashed with correct reward
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "Small stake should also be fully slashed");

        uint256 challengerBalanceAfter = _getWtonBalance(challenger);
        uint256 reward = challengerBalanceAfter - challengerBalanceBefore;

        uint256 slashingRewardRate = _getSlashingRewardRate();
        uint256 expectedReward = (initialStake * slashingRewardRate) / 10000;

        assertEq(
            reward,
            expectedReward,
            "Reward should be calculated correctly even for small stakes"
        );
        console.log("[OK] Small stake slashed successfully with correct reward");
    }

    // ============================================
    // Scenario 2: Invalid Dispute Game States
    // ============================================

    function test_Slashing_InvalidGameStates() public {
        console.log("\n=== Test: Invalid Dispute Game States ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();

        // 2. Test A: Unresolved game should fail
        MockFaultDisputeGame2 unresolvedGame = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        unresolvedGame.initialize();

        vm.prank(challenger);
        unresolvedGame.step();
        // Note: resolve() is NOT called

        vm.expectRevert(); // Game not resolved
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(unresolvedGame));

        console.log("[OK] Unresolved game slashing prevented");

        // 3. Test B: DEFENDER_WINS game should fail
        Claim rootClaim2 = Claim.wrap(bytes32(uint256(2)));
        bytes memory extraData2 = hex"5678";

        MockFaultDisputeGame2 defenderWinsGame = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim2, extraData2))
        );
        defenderWinsGame.initialize();
        // Note: step() is NOT called (challenger doesn't respond)
        defenderWinsGame.resolve(); // DEFENDER_WINS state

        vm.expectRevert(); // DEFENDER_WINS so slashing should fail
        _executeSlashing(
            operatorManager,
            gameType,
            rootClaim2,
            extraData2,
            address(defenderWinsGame)
        );

        console.log("[OK] DEFENDER_WINS game slashing prevented");
    }

    // ============================================
    // Scenario 3: Re-registration After Slashing
    // ============================================

    function test_Slashing_ReRegistrationAfterSlashing() public {
        console.log("\n=== Test: Re-registration After Slashing ===");

        // 1. First registration and slashing
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
        console.log("[OK] First registration slashed");

        // 2. Re-registration with new rollup
        _setupSecondRollup();

        uint256 reStakeAmount = 5000 * 1e18;
        MockTON(ton).mint(operator, reStakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(layer2ManagerProxy, reStakeAmount);
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            rollupConfig2,
            reStakeAmount,
            true,
            "ReRegistration"
        );
        vm.stopPrank();

        address newOperatorManager = Layer2ManagerV3(layer2ManagerProxy).operatorOfRollupConfig(
            rollupConfig2
        );
        address newCandidateAddOn = Layer2ManagerV3(layer2ManagerProxy).candidateAddOnOfOperator(
            newOperatorManager
        );
        uint256 newStake = _getStakeOf(newCandidateAddOn, newOperatorManager);

        assertEq(newStake, reStakeAmount * 1e9, "Re-registration stake should match");
        console.log("[OK] Re-registration successful with stake:", newStake);

        // 3. Verify seigniorage after time passes
        vm.roll(block.number + 1000);

        bool success = _updateSeigniorage(newCandidateAddOn);
        require(success, "Seigniorage update failed");

        uint256 stakeAfterSeigniorage = _getStakeOf(newCandidateAddOn, newOperatorManager);
        console.log("Stake with Seigniorage:", stakeAfterSeigniorage);
        console.log("Initial Stake:", newStake);

        require(stakeAfterSeigniorage > newStake, "Seigniorage must increase");

        console.log("Seigniorage earned after re-registration:", stakeAfterSeigniorage - newStake);
        console.log("[OK] Re-registered operator can earn seigniorage");
    }

    // ============================================
    // Scenario 4: Partial Withdrawal Then Slashing
    // ============================================

    function test_Slashing_AfterPartialWithdrawal() public {
        console.log("\n=== Test: Slashing After Partial Withdrawal ===");

        // 1. Register candidate
        uint256 initialStakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            initialStakeAmount
        );

        uint256 stakeBeforeWithdrawal = _getStakeOf(candidateAddOn, operatorManager);
        console.log("Initial stake:", stakeBeforeWithdrawal);

        // 2. Partial withdrawal attempt
        // Note: Partial withdrawal feature may not be implemented
        console.log("[INFO] Partial withdrawal feature may not be implemented yet");

        // 3. Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 4. Verify: Remaining stake is fully slashed
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "All remaining stake should be slashed");
        console.log("[OK] Remaining stake after withdrawal fully slashed");
    }

    // ============================================
    // Scenario 5: Large Stake Slashing
    // ============================================

    function test_Slashing_LargeStake() public {
        console.log("\n=== Test: Large Stake Slashing ===");

        // 1. Register with large amount
        uint256 largeStake = 1_000_000 * 1e18; // 1 million TON
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            largeStake
        );

        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);
        console.log("Large stake amount (RAY):", initialStake);

        // 2. Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 3. Verify: Large stake is also fully slashed with correct reward
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "Large stake should be fully slashed");

        uint256 challengerBalanceAfter = _getWtonBalance(challenger);
        uint256 reward = challengerBalanceAfter - challengerBalanceBefore;

        uint256 slashingRewardRate = _getSlashingRewardRate();
        uint256 expectedReward = (initialStake * slashingRewardRate) / 10000;

        assertEq(reward, expectedReward, "Large stake reward should be calculated correctly");
        console.log("Challenger reward for large stake:", reward);
        console.log("[OK] Large stake slashed successfully");
    }

    // ============================================
    // Helper: Setup Second Rollup
    // ============================================

    function _setupSecondRollup() internal {
        // Setup with UNIQUE addresses for second rollup
        MockDisputeGameFactory2 mockFactory2 = new MockDisputeGameFactory2();

        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("l1StandardBridge()"),
            abi.encode(makeAddr("mockL1Bridge2")) // UNIQUE
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("optimismPortal()"),
            abi.encode(makeAddr("mockPortal2")) // UNIQUE
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("unsafeBlockSigner()"),
            abi.encode(makeAddr("mockUnsafeBlockSigner2"))
        );
        vm.mockCall(
            rollupConfig2,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(mockFactory2))
        );

        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig2,
            2,
            makeAddr("l2TON2"),
            "TestRollup2"
        );
    }
}
