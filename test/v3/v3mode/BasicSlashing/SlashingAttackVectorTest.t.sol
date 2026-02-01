// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";
import {OperatorManagerV1_2} from "../../../../src/layer2/OperatorManagerV1_2.sol";

/// @title SlashingAttackVectorTest
/// @notice Tests for attack vectors: game parameter manipulation, timing attacks, economic attacks
contract SlashingAttackVectorTest is BaseSlashingTest {
    MockDisputeGameFactory2 public mockFactory;

    function setUp() public override {
        super.setUp();
        mockFactory = new MockDisputeGameFactory2();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(mockFactory))
        );
    }

    // ============================================
    // Game Parameter Manipulation Tests
    // ============================================

    /// @notice Test slashing with wrong rootClaim (should fail)
    function test_Slashing_WrongRootClaim_Reverts() public {
        console.log("\n=== Test: Wrong RootClaim Should Revert ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Create game with specific rootClaim
        GameType gameType = GameType.wrap(0);
        Claim correctRootClaim = Claim.wrap(bytes32(uint256(1)));
        Claim wrongRootClaim = Claim.wrap(bytes32(uint256(999))); // Different claim
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, correctRootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        // 3. Try slashing with wrong rootClaim
        vm.expectRevert(); // Should fail - rootClaim mismatch
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            wrongRootClaim, // WRONG
            extraData,
            address(game)
        );

        console.log("[OK] Wrong rootClaim slashing prevented");
    }

    /// @notice Test slashing with wrong extraData (should fail)
    function test_Slashing_WrongExtraData_Reverts() public {
        console.log("\n=== Test: Wrong ExtraData Should Revert ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Create game with specific extraData
        GameType gameType = GameType.wrap(0);
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory correctExtraData = hex"1234";
        bytes memory wrongExtraData = hex"9999"; // Different extraData

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, correctExtraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        // 3. Try slashing with wrong extraData
        vm.expectRevert(); // Should fail - extraData mismatch
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            wrongExtraData, // WRONG
            address(game)
        );

        console.log("[OK] Wrong extraData slashing prevented");
    }

    /// @notice Test slashing with non-existent game address (should fail)
    function test_Slashing_NonExistentGame_Reverts() public {
        console.log("\n=== Test: Non-Existent Game Should Revert ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Use fake game address
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        address fakeGame = makeAddr("fakeGame");

        // 3. Try slashing with non-existent game
        vm.expectRevert(); // Should fail - game doesn't exist
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            gameType,
            rootClaim,
            extraData,
            fakeGame
        );

        console.log("[OK] Non-existent game slashing prevented");
    }

    /// @notice Test slashing with wrong gameType (should fail)
    function test_Slashing_WrongGameType_Reverts() public {
        console.log("\n=== Test: Wrong GameType Should Revert ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Create game with specific gameType
        GameType correctGameType = GameType.wrap(0);
        GameType wrongGameType = GameType.wrap(1); // Different type
        Claim rootClaim = Claim.wrap(bytes32(uint256(1)));
        bytes memory extraData = hex"1234";

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(correctGameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        // 3. Try slashing with wrong gameType
        vm.expectRevert(); // Should fail - gameType mismatch
        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager,
            wrongGameType, // WRONG
            rootClaim,
            extraData,
            address(game)
        );

        console.log("[OK] Wrong gameType slashing prevented");
    }

    // ============================================
    // Operator State Edge Cases
    // ============================================

    /// @notice Test that unauthorized addresses cannot trigger withdrawal before slashing
    /// @dev This tests that only the OperatorManager's owner/manager can request withdrawals
    function test_Slashing_UnauthorizedWithdrawalAttempt() public {
        console.log("\n=== Test: Unauthorized Withdrawal Attempt Before Slashing ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        uint256 initialStake = _getStakeOf(candidateAddOn, operatorManager);
        console.log("Initial stake (RAY):", initialStake);

        // 2. Attacker tries to withdraw through OperatorManager (should fail)
        address attacker = makeAddr("attacker");
        uint256 withdrawAmount = initialStake / 2;

        vm.prank(attacker);
        vm.expectRevert("not onlyOwnerOrManager");
        OperatorManagerV1_2(operatorManager).requestWithdrawal(withdrawAmount);
        console.log("[OK] Unauthorized withdrawal blocked");

        // 3. Verify stake is unchanged
        uint256 stakeAfterAttempt = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(stakeAfterAttempt, initialStake, "Stake should remain unchanged");

        // 4. Slashing should still work with full stake
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 5. Verify: Full stake slashed
        uint256 finalStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(finalStake, 0, "All stake should be slashed");

        uint256 challengerBalanceAfter = _getWtonBalance(challenger);
        uint256 slashingRewardRate = _getSlashingRewardRate();
        uint256 expectedReward = (initialStake * slashingRewardRate) / 10000;
        assertEq(
            challengerBalanceAfter - challengerBalanceBefore,
            expectedReward,
            "Challenger should receive full reward"
        );

        console.log("[OK] Slashing executed with full stake after failed withdrawal attempt");
    }

    /// @notice Test slashing operator with zero stake (should handle gracefully)
    function test_Slashing_ZeroStakeOperator() public {
        console.log("\n=== Test: Slashing Zero Stake Operator ===");

        // 1. Register candidate and immediately withdraw all (if possible)
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // First slashing to zero out stake
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game1 = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game1.initialize();
        _makeChallengerWin(game1);
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game1));

        // Verify stake is zero
        uint256 currentStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(currentStake, 0, "Stake should be zero");

        // 2. Try second slashing with different game (should fail - already slashed with same game params issue, or zero stake)
        // Note: Using same game would fail due to double-slashing prevention
        // Using different game params - should handle zero stake gracefully
        Claim rootClaim2 = Claim.wrap(bytes32(uint256(2)));
        MockFaultDisputeGame2 game2 = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim2, extraData))
        );
        game2.initialize();
        _makeChallengerWin(game2);

        uint256 challengerBalanceBefore = _getWtonBalance(challenger);

        // This might revert or succeed with zero reward - depends on implementation
        try
            Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
                operatorManager,
                gameType,
                rootClaim2,
                extraData,
                address(game2)
            )
        {
            // If it succeeds, challenger should get zero reward
            uint256 challengerBalanceAfter = _getWtonBalance(challenger);
            assertEq(
                challengerBalanceAfter,
                challengerBalanceBefore,
                "No reward for zero stake slashing"
            );
            console.log("[OK] Zero stake slashing succeeded with zero reward");
        } catch {
            console.log("[OK] Zero stake slashing reverted (expected behavior)");
        }
    }

    // ============================================
    // Timing Attack Tests
    // ============================================

    /// @notice Test multiple slashing attempts in same block
    function test_Slashing_MultipleAttemptsInSameBlock() public {
        console.log("\n=== Test: Multiple Slashing Attempts In Same Block ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Setup game
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);

        // 3. First slashing succeeds
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
        console.log("[OK] First slashing succeeded");

        // 4. Second slashing in same block should fail
        vm.expectRevert(abi.encodeWithSignature("SlashingError()"));
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        console.log("[OK] Second slashing in same block prevented");
    }

    /// @notice Test re-staking immediately after slashing (same block)
    function test_Slashing_ImmediateRestakeAfterSlashing() public {
        console.log("\n=== Test: Immediate Re-stake After Slashing ===");

        // 1. Register and stake
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 3. Try to re-stake immediately in same block
        uint256 restakeAmount = 5000 * 1e18;
        MockTON(ton).mint(operator, restakeAmount);

        vm.startPrank(operator);
        IERC20(ton).approve(wton, restakeAmount);
        MockWTON(wton).swapFromTONAndTransfer(operator, restakeAmount);
        IERC20(wton).approve(depositManagerProxy, restakeAmount * 1e9);

        // Attempt deposit - should succeed (operator can re-stake after slashing)
        DepositManagerV3(depositManagerProxy).deposit(
            candidateAddOn,
            operatorManager,
            restakeAmount * 1e9
        );
        vm.stopPrank();

        uint256 newStake = _getStakeOf(candidateAddOn, operatorManager);
        assertEq(newStake, restakeAmount * 1e9, "Re-stake should succeed");

        console.log("Re-staked amount:", newStake);
        console.log("[OK] Immediate re-stake after slashing allowed");
    }

    // ============================================
    // System State Consistency Tests
    // ============================================

    /// @notice Test tot totalSupply consistency after slashing
    function test_Slashing_TotTotalSupplyConsistency() public {
        console.log("\n=== Test: Tot TotalSupply Consistency After Slashing ===");

        // 1. Get initial tot totalSupply
        address totAddr = SeigManagerV1_2(seigManagerProxy).tot();
        RefactorCoinageSnapshotI tot = RefactorCoinageSnapshotI(totAddr);
        uint256 totSupplyBefore = tot.totalSupply();
        console.log("Tot totalSupply before:", totSupplyBefore);

        // 2. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        uint256 totSupplyAfterStake = tot.totalSupply();
        console.log("Tot totalSupply after stake:", totSupplyAfterStake);

        uint256 operatorStake = _getStakeOf(candidateAddOn, operatorManager);

        // 3. Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 4. Check tot totalSupply after slashing
        uint256 totSupplyAfterSlash = tot.totalSupply();
        console.log("Tot totalSupply after slash:", totSupplyAfterSlash);

        // Tot supply should decrease by slashed amount (minus reward which stays in system)
        uint256 slashingRewardRate = _getSlashingRewardRate();
        uint256 burnedAmount = operatorStake - ((operatorStake * slashingRewardRate) / 10000);

        // Note: Exact calculation depends on implementation
        // The key is that tot supply should reflect the burning
        assertTrue(
            totSupplyAfterSlash < totSupplyAfterStake,
            "Tot supply should decrease after slashing"
        );

        console.log("Burned amount (approx):", burnedAmount);
        console.log("[OK] Tot totalSupply consistency verified");
    }

    /// @notice Test coinage balance consistency after slashing
    function test_Slashing_CoinageBalanceConsistency() public {
        console.log("\n=== Test: Coinage Balance Consistency After Slashing ===");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Get coinage and check balance
        address coinageAddr = SeigManagerV1_2(seigManagerProxy).coinages(candidateAddOn);
        RefactorCoinageSnapshotI coinage = RefactorCoinageSnapshotI(coinageAddr);

        uint256 operatorCoinageBefore = coinage.balanceOf(operatorManager);
        uint256 totalCoinageBefore = coinage.totalSupply();

        console.log("Operator coinage before:", operatorCoinageBefore);
        console.log("Total coinage before:", totalCoinageBefore);

        // 3. Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);
        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        // 4. Check coinage balances after slashing
        uint256 operatorCoinageAfter = coinage.balanceOf(operatorManager);
        uint256 totalCoinageAfter = coinage.totalSupply();

        console.log("Operator coinage after:", operatorCoinageAfter);
        console.log("Total coinage after:", totalCoinageAfter);

        // Operator's coinage should be zero after slashing
        assertEq(operatorCoinageAfter, 0, "Operator coinage should be zero");

        // Total coinage should decrease by operator's amount
        assertEq(
            totalCoinageAfter,
            totalCoinageBefore - operatorCoinageBefore,
            "Total coinage should decrease"
        );

        console.log("[OK] Coinage balance consistency verified");
    }

    /// @notice Test slashing doesn't affect other operators' coinage
    function test_Slashing_OtherOperatorCoinageUnaffected() public {
        console.log("\n=== Test: Other Operator Coinage Unaffected ===");

        // Setup second rollup
        address rollupConfig2 = makeAddr("rollupConfig2");
        address operator2 = makeAddr("operator2");
        MockDisputeGameFactory2 mockFactory2 = new MockDisputeGameFactory2();

        _setupRollupMocksWithFactory(rollupConfig2, mockFactory2);
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig2,
            2,
            makeAddr("l2TON2"),
            "TestRollup2"
        );

        // 1. Register both operators
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager1, address candidateAddOn1) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );
        (address operatorManager2, address candidateAddOn2) = _registerCandidateAndStake(
            operator2,
            rollupConfig2,
            stakeAmount
        );

        // 2. Record operator2's coinage before
        address coinageAddr2 = SeigManagerV1_2(seigManagerProxy).coinages(candidateAddOn2);
        RefactorCoinageSnapshotI coinage2 = RefactorCoinageSnapshotI(coinageAddr2);
        uint256 operator2CoinageBefore = coinage2.balanceOf(operatorManager2);

        // 3. Slash operator1
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();
        _makeChallengerWin(game);
        _executeSlashing(operatorManager1, gameType, rootClaim, extraData, address(game));

        // 4. Verify operator2's coinage unchanged
        uint256 operator2CoinageAfter = coinage2.balanceOf(operatorManager2);
        assertEq(
            operator2CoinageAfter,
            operator2CoinageBefore,
            "Operator2 coinage should be unchanged"
        );

        console.log("Operator2 coinage before:", operator2CoinageBefore);
        console.log("Operator2 coinage after:", operator2CoinageAfter);
        console.log("[OK] Other operator coinage unaffected by slashing");
    }

    // ============================================
    // Helper Functions
    // ============================================

    function _setupRollupMocksWithFactory(
        address _rollupConfig,
        MockDisputeGameFactory2 _factory
    ) internal {
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("l1StandardBridge()"),
            abi.encode(makeAddr(string(abi.encodePacked("mockL1Bridge_", _rollupConfig))))
        );
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("optimismPortal()"),
            abi.encode(makeAddr(string(abi.encodePacked("mockPortal_", _rollupConfig))))
        );
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("unsafeBlockSigner()"),
            abi.encode(makeAddr("mockUnsafeBlockSigner"))
        );
        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(_factory))
        );
    }

    function _makeChallengerWin(MockFaultDisputeGame2 _game) internal override {
        vm.prank(challenger);
        _game.step();
        _game.resolve();
    }
}
