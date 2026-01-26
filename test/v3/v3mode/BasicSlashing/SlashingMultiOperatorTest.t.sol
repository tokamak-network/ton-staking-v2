// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseSlashingTest.sol";

/// @title SlashingMultiOperatorTest
/// @notice Tests for multiple operators independence and multiple challengers
contract SlashingMultiOperatorTest is BaseSlashingTest {
    address public operator2 = makeAddr("operator2");
    address public rollupConfig2 = makeAddr("mockRollupConfig2");
    MockDisputeGameFactory public mockFactory;

    function setUp() public override {
        super.setUp();

        // Setup second rollup config with UNIQUE addresses
        // Each rollup must have unique l1Bridge, portal, and disputeGameFactory
        mockFactory = new MockDisputeGameFactory();

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
            abi.encode(address(mockFactory))
        );

        // Register second rollup
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
            rollupConfig2,
            2,
            makeAddr("l2TON2"),
            "TestRollup2"
        );

        vm.label(operator2, "Operator2");
    }

    // ============================================
    // Scenario 1: Multiple Operators Slashing Independence
    // ============================================

    function test_Slashing_MultipleOperators_Independence() public {
        console.log("\n=== Test: Multiple Operators Slashing Independence ===");

        // 1. Register Operator 1
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager1, address candidateAddOn1) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Register Operator 2
        (address operatorManager2, address candidateAddOn2) = _registerCandidateAndStake(
            operator2,
            rollupConfig2,
            stakeAmount
        );

        uint256 stake1Before = _getStakeOf(candidateAddOn1, operatorManager1);
        uint256 stake2Before = _getStakeOf(candidateAddOn2, operatorManager2);

        console.log("Operator 1 stake:", stake1Before);
        console.log("Operator 2 stake:", stake2Before);

        // 3. Slash only Operator 1
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        _executeSlashing(operatorManager1, gameType, rootClaim, extraData, address(game));

        // 4. Verify: Operator 1 slashed, Operator 2 unaffected
        uint256 stake1After = _getStakeOf(candidateAddOn1, operatorManager1);
        uint256 stake2After = _getStakeOf(candidateAddOn2, operatorManager2);

        assertEq(stake1After, 0, "Operator 1 should be slashed");
        assertEq(stake2After, stake2Before, "Operator 2 should not be affected");

        console.log("[OK] Operator 1 slashed, Operator 2 unaffected");
    }

    // ============================================
    // Scenario 2: Multiple Challengers - First Wins
    // ============================================

    function test_Slashing_MultipleChallengers_FirstWins() public {
        console.log("\n=== Test: Multiple Challengers - First Wins ===");

        address challenger2 = makeAddr("challenger2");

        // 1. Register candidate
        uint256 stakeAmount = 10000 * 1e18;
        (address operatorManager, ) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            stakeAmount
        );

        // 2. Setup dispute game
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        MockFaultDisputeGame2 game = MockFaultDisputeGame2(
            address(gameFactory.create(gameType, rootClaim, extraData))
        );
        game.initialize();

        // 3. First challenger calls step
        vm.prank(challenger);
        game.step();

        // 4. Second challenger tries step - should fail
        vm.prank(challenger2);
        vm.expectRevert("Already countered");
        game.step();

        game.resolve();

        // 5. Only first challenger succeeds in slashing
        uint256 challenger1BalanceBefore = _getWtonBalance(challenger);
        uint256 challenger2BalanceBefore = _getWtonBalance(challenger2);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));

        uint256 challenger1BalanceAfter = _getWtonBalance(challenger);
        uint256 challenger2BalanceAfter = _getWtonBalance(challenger2);

        // 6. Verify: Only first challenger receives reward
        assertTrue(
            challenger1BalanceAfter > challenger1BalanceBefore,
            "First challenger should receive reward"
        );
        assertEq(
            challenger2BalanceAfter,
            challenger2BalanceBefore,
            "Second challenger should not receive reward"
        );

        console.log("First challenger reward:", challenger1BalanceAfter - challenger1BalanceBefore);
        console.log("[OK] Only first challenger received reward");
    }

    // ============================================
    // Scenario 3: New Delegator After Slashing
    // ============================================

    function test_Slashing_NewDelegatorAfterSlashing() public {
        console.log("\n=== Test: New Delegator Can Join After Operator Slashing ===");

        address newDelegator = makeAddr("newDelegator");

        // 1. Register and slash operator
        uint256 operatorStake = 10000 * 1e18;
        (address operatorManager, address candidateAddOn) = _registerCandidateAndStake(
            operator,
            rollupConfig,
            operatorStake
        );

        // Execute slashing
        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();
        (, MockFaultDisputeGame2 game) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game);

        _executeSlashing(operatorManager, gameType, rootClaim, extraData, address(game));
        console.log("[OK] Operator slashed");

        // 2. New staker tries to stake to slashed operator
        uint256 newDelegatorStake = 2000 * 1e18;
        MockTON(ton).mint(newDelegator, newDelegatorStake);

        vm.startPrank(newDelegator);
        IERC20(ton).approve(wton, newDelegatorStake);
        MockWTON(wton).swapFromTONAndTransfer(newDelegator, newDelegatorStake);
        IERC20(wton).approve(depositManagerProxy, newDelegatorStake * 1e9);

        // Should fail because operator collateral is 0
        vm.expectRevert("OperatorCollateral is insufficient.");
        DepositManagerV3(depositManagerProxy).deposit(candidateAddOn, newDelegatorStake * 1e9);
        vm.stopPrank();

        console.log(
            "[OK] New delegator cannot stake to slashed operator (operator collateral = 0)"
        );
        console.log("[INFO] Operator must re-stake before accepting new delegators");
    }

    // ============================================
    // Scenario 4: Slash Both Operators Sequentially
    // ============================================

    function test_Slashing_BothOperators_Sequential() public {
        console.log("\n=== Test: Slash Both Operators Sequentially ===");

        uint256 stakeAmount = 10000 * 1e18;

        // 1. Register both operators
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

        (GameType gameType, Claim rootClaim, bytes memory extraData) = _getDefaultGameParams();

        // 2. Slash operator 1
        (, MockFaultDisputeGame2 game1) = _setupDisputeGame(
            rollupConfig,
            gameType,
            rootClaim,
            extraData
        );
        _makeChallengerWin(game1);
        _executeSlashing(operatorManager1, gameType, rootClaim, extraData, address(game1));
        console.log("[OK] Operator 1 slashed");

        // 3. Slash operator 2 with different game params
        Claim rootClaim2 = Claim.wrap(bytes32(uint256(2)));
        bytes memory extraData2 = hex"5678";

        MockFaultDisputeGame2 game2 = MockFaultDisputeGame2(
            address(mockFactory.create(gameType, rootClaim2, extraData2))
        );
        game2.initialize();
        _makeChallengerWin(game2);

        Layer2Manager_Slashing(address(layer2ManagerProxy)).slashingCandidate(
            operatorManager2,
            gameType,
            rootClaim2,
            extraData2,
            address(game2)
        );
        console.log("[OK] Operator 2 slashed");

        // 4. Verify both are slashed
        assertEq(_getStakeOf(candidateAddOn1, operatorManager1), 0, "Operator 1 stake should be 0");
        assertEq(_getStakeOf(candidateAddOn2, operatorManager2), 0, "Operator 2 stake should be 0");

        console.log("[OK] Both operators slashed independently");
    }
}
