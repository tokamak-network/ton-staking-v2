// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../BasicSlashing/BaseSlashingTest.sol";
import {console} from "forge-std/console.sol";
import {MockFaultDisputeGame3} from "../../../../src/mocks/MockFaultDisputeGame3.sol";
import {MockDisputeGameFactory} from "../../../../src/mocks/MockDisputeGameFactory.sol";
import {MockWinningChallengerTracker} from "../../../../src/mocks/MockWinningChallengerTracker.sol";

/// @title BaseAdvancedSlashingTest
/// @notice Base test contract for advanced slashing tests with multi-challenger support
abstract contract BaseAdvancedSlashingTest is BaseSlashingTest {
    // Additional challengers for multi-challenger scenarios
    address public challenger2;
    address public challenger3;
    address public challenger4;
    address public challenger5;

    // Winning challenger tracker for external tracking (for MockFaultDisputeGame3)
    MockWinningChallengerTracker public winningChallengerTracker;

    function setUp() public virtual override {
        super.setUp();

        // Setup additional challengers
        challenger2 = makeAddr("challenger2");
        challenger3 = makeAddr("challenger3");
        challenger4 = makeAddr("challenger4");
        challenger5 = makeAddr("challenger5");

        vm.label(challenger2, "Challenger2");
        vm.label(challenger3, "Challenger3");
        vm.label(challenger4, "Challenger4");
        vm.label(challenger5, "Challenger5");

        // Deploy winning challenger tracker for MockFaultDisputeGame3
        winningChallengerTracker = new MockWinningChallengerTracker();
    }

    /// @notice Setup dispute game with multiple winning challengers
    /// @param numChallengers Number of challengers to add (1-5)
    function _setupMultiChallengerGame(
        uint256 numChallengers
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
        require(numChallengers >= 1 && numChallengers <= 5, "Invalid challenger count");

        // 1. Register candidate and stake
        uint256 stakeAmount = 10000 * 1e18;
        (operatorManager, ) = _registerCandidateAndStake(operator, rollupConfig, stakeAmount);

        // 2. Setup dispute game
        (gameType, rootClaim, extraData) = _getDefaultGameParams();
        MockDisputeGameFactory gameFactory = new MockDisputeGameFactory();
        vm.mockCall(
            rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        game = MockFaultDisputeGame3(address(gameFactory.create(gameType, rootClaim, extraData)));
        // Initialize with external tracker address
        game.initialize(address(winningChallengerTracker));

        // 3. Add challengers
        address[] memory challengers = _getChallengersByCount(numChallengers);

        // First challenger calls step
        vm.prank(challengers[0]);
        game.step();

        // Additional challengers are added via mock function
        for (uint256 i = 1; i < numChallengers; i++) {
            game.addWinningChallenger(challengers[i]);
        }

        game.resolve();
    }

    /// @notice Get challenger addresses by count
    function _getChallengersByCount(uint256 count) internal view returns (address[] memory) {
        address[] memory challengers = new address[](count);
        if (count >= 1) challengers[0] = challenger;
        if (count >= 2) challengers[1] = challenger2;
        if (count >= 3) challengers[2] = challenger3;
        if (count >= 4) challengers[3] = challenger4;
        if (count >= 5) challengers[4] = challenger5;
        return challengers;
    }

    /// @notice Calculate expected reward in WTON
    /// @param stakeAmountTon Stake amount in TON (1e18)
    /// @return totalRewardWton Total reward in WTON (1e27)
    function _calculateExpectedReward(
        uint256 stakeAmountTon
    ) internal view returns (uint256 totalRewardWton) {
        uint256 stakeInWton = stakeAmountTon * 1e9;
        uint256 rewardRate = _getSlashingRewardRate();
        totalRewardWton = (stakeInWton * rewardRate) / 10000;
    }

    /// @notice Setup dispute game factory and create a MockFaultDisputeGame3
    /// @dev Used for AdvancedSlashing tests that need multi-challenger tracking
    function _setupDisputeGame3(
        address _rollupConfig,
        GameType _gameType,
        Claim _rootClaim,
        bytes memory _extraData
    ) internal returns (MockDisputeGameFactory gameFactory, MockFaultDisputeGame3 game) {
        gameFactory = new MockDisputeGameFactory();

        vm.mockCall(
            _rollupConfig,
            abi.encodeWithSignature("disputeGameFactory()"),
            abi.encode(address(gameFactory))
        );

        game = MockFaultDisputeGame3(
            address(gameFactory.create(_gameType, _rootClaim, _extraData))
        );
        // Initialize with external tracker address
        game.initialize(address(winningChallengerTracker));
    }

    /// @notice Make challenger win the MockFaultDisputeGame3
    function _makeChallengerWin3(MockFaultDisputeGame3 _game) internal virtual {
        vm.prank(challenger);
        _game.step();
        _game.resolve();
    }
}
