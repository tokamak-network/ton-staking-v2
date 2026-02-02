// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DelegateStakingV3} from "../contracts/DelegateStakingV3.sol";
import {DelegateTrigger} from "../contracts/DelegateTrigger.sol";
import {IDelegateStakingV3} from "../contracts/interfaces/IDelegateStakingV3.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSeigManagerV3} from "./mocks/MockSeigManagerV3.sol";
import {MockOperatorManagerV3} from "./mocks/MockOperatorManagerV3.sol";

/**
 * @title DelegateStakingE2E
 * @notice End-to-end test suite for the complete DelegateStaking system
 * @dev Tests full user journeys, multi-actor scenarios, and system integration
 */
contract DelegateStakingE2E is Test {
    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/

    DelegateStakingV3 public staking;
    DelegateTrigger public trigger;
    ERC20Mock public ton;
    ERC20Mock public wton;
    MockSeigManagerV3 public seigManager;
    MockOperatorManagerV3 public operatorManager1;
    MockOperatorManagerV3 public operatorManager2;
    MockOperatorManagerV3 public operatorManager3;

    /*//////////////////////////////////////////////////////////////
                              ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public owner = makeAddr("owner");
    address public guardian = makeAddr("guardian");
    address public keeper = makeAddr("keeper");

    // Sequencers
    address public sequencer1 = makeAddr("sequencer1");
    address public sequencer2 = makeAddr("sequencer2");
    address public sequencer3 = makeAddr("sequencer3");

    // Layer2s
    address public layer2_1 = makeAddr("layer2_1");
    address public layer2_2 = makeAddr("layer2_2");
    address public layer2_3 = makeAddr("layer2_3");

    // Stakers
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public david = makeAddr("david");

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant INITIAL_TON_BALANCE = 100_000 ether;
    uint256 public constant INITIAL_WTON_BALANCE = 100_000 * 1e27; // RAY units
    uint256 public constant UNBONDING_PERIOD = 14 days;
    uint256 public constant EMERGENCY_COOLDOWN = 3 days;
    uint256 public constant RAY = 1e27;

    // Commission rates
    uint256 public constant COMMISSION_5_PERCENT = 500;
    uint256 public constant COMMISSION_10_PERCENT = 1000;
    uint256 public constant COMMISSION_20_PERCENT = 2000;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Deploy tokens
        ton = new ERC20Mock("TON", "TON");
        wton = new ERC20Mock("WTON", "WTON");

        // Deploy V3 mocks
        seigManager = new MockSeigManagerV3(address(ton), address(wton));

        // Deploy operator managers for each sequencer
        operatorManager1 = new MockOperatorManagerV3(
            sequencer1,
            address(wton),
            address(0),
            layer2_1
        );
        operatorManager2 = new MockOperatorManagerV3(
            sequencer2,
            address(wton),
            address(0),
            layer2_2
        );
        operatorManager3 = new MockOperatorManagerV3(
            sequencer3,
            address(wton),
            address(0),
            layer2_3
        );

        // Deploy main staking contract
        vm.prank(owner);
        staking = new DelegateStakingV3(
            address(ton),
            address(wton),
            address(seigManager),
            address(0),
            UNBONDING_PERIOD,
            owner
        );

        // Deploy trigger contract
        vm.prank(owner);
        trigger = new DelegateTrigger(address(wton), owner);

        // Set guardian
        vm.prank(owner);
        staking.setDefaultGuardian(guardian);

        // Mint tokens to users
        _mintTokensToUsers();

        // Setup approvals
        _setupApprovals();

        // Authorize staking contract in operator managers
        _authorizeStakingContract();
    }

    function _mintTokensToUsers() internal {
        // Stakers get TON
        ton.mint(alice, INITIAL_TON_BALANCE);
        ton.mint(bob, INITIAL_TON_BALANCE);
        ton.mint(charlie, INITIAL_TON_BALANCE);
        ton.mint(david, INITIAL_TON_BALANCE);

        // Sequencers get WTON for rewards
        wton.mint(sequencer1, INITIAL_WTON_BALANCE);
        wton.mint(sequencer2, INITIAL_WTON_BALANCE);
        wton.mint(sequencer3, INITIAL_WTON_BALANCE);

        // Operator managers get WTON
        wton.mint(address(operatorManager1), INITIAL_WTON_BALANCE);
        wton.mint(address(operatorManager2), INITIAL_WTON_BALANCE);
        wton.mint(address(operatorManager3), INITIAL_WTON_BALANCE);

        // Owner for trigger reward pool
        wton.mint(owner, INITIAL_WTON_BALANCE);
    }

    function _setupApprovals() internal {
        // Stakers approve staking contract
        vm.prank(alice);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(bob);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(charlie);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(david);
        ton.approve(address(staking), type(uint256).max);

        // Sequencers approve staking contract for WTON
        vm.prank(sequencer1);
        wton.approve(address(staking), type(uint256).max);
        vm.prank(sequencer2);
        wton.approve(address(staking), type(uint256).max);
        vm.prank(sequencer3);
        wton.approve(address(staking), type(uint256).max);

        // Owner approve trigger for reward pool
        vm.prank(owner);
        wton.approve(address(trigger), type(uint256).max);
    }

    function _authorizeStakingContract() internal {
        vm.prank(sequencer1);
        operatorManager1.authorizeClaimer(address(staking));
        vm.prank(sequencer2);
        operatorManager2.authorizeClaimer(address(staking));
        vm.prank(sequencer3);
        operatorManager3.authorizeClaimer(address(staking));
    }

    /*//////////////////////////////////////////////////////////////
                    E2E TEST: FULL STAKER LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests complete staker journey from start to finish
     * Journey: stake → receive rewards → claim → partial unstake →
     *          receive more rewards → full unstake → withdraw
     */
    function test_E2E_FullStakerLifecycle() public {
        // === Setup: Register sequencer ===
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        // === Step 1: Alice stakes ===
        uint256 stakeAmount = 10_000 ether;
        vm.prank(alice);
        staking.stake(sequencer1, stakeAmount);

        IDelegateStakingV3.StakeInfo memory aliceStake = staking.getStakeInfo(alice, sequencer1);
        assertEq(aliceStake.amount, stakeAmount, "Stake amount mismatch");

        // === Step 2: Sequencer receives and distributes reward ===
        uint256 rewardAmount = 1000 * RAY / 1e18; // 1000 WTON
        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        // === Step 3: Alice claims rewards ===
        uint256 alicePending = staking.pendingRewards(alice, sequencer1);
        assertGt(alicePending, 0, "Should have pending rewards");

        uint256 aliceWtonBefore = wton.balanceOf(alice);
        vm.prank(alice);
        staking.claimRewards(sequencer1);
        uint256 aliceWtonAfter = wton.balanceOf(alice);

        // 90% of 1000 = 900 WTON (10% commission)
        assertEq(aliceWtonAfter - aliceWtonBefore, 900 * RAY / 1e18, "Reward amount mismatch");

        // === Step 4: Alice partially unstakes ===
        uint256 unstakeAmount = 5000 ether;
        vm.prank(alice);
        staking.unstake(sequencer1, unstakeAmount);

        aliceStake = staking.getStakeInfo(alice, sequencer1);
        assertEq(aliceStake.amount, 5000 ether, "Remaining stake mismatch");
        assertEq(aliceStake.unstakeAmount, unstakeAmount, "Unstake amount mismatch");

        // === Step 5: More rewards come in ===
        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        // === Step 6: Alice unstakes remaining ===
        vm.prank(alice);
        staking.unstake(sequencer1, 5000 ether);

        // === Step 7: Wait for unbonding period ===
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        // === Step 8: Alice withdraws ===
        uint256 aliceTonBefore = ton.balanceOf(alice);
        vm.prank(alice);
        staking.withdraw(sequencer1);
        uint256 aliceTonAfter = ton.balanceOf(alice);

        assertEq(aliceTonAfter - aliceTonBefore, stakeAmount, "Withdraw amount mismatch");

        // === Verify final state ===
        aliceStake = staking.getStakeInfo(alice, sequencer1);
        assertEq(aliceStake.amount, 0, "Should have no remaining stake");
        assertEq(aliceStake.unstakeAmount, 0, "Should have no pending unstake");
    }

    /*//////////////////////////////////////////////////////////////
                E2E TEST: MULTI-STAKER REWARD DISTRIBUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests reward distribution among multiple stakers
     * Verifies proportional distribution based on stake amounts
     */
    function test_E2E_MultiStakerRewardDistribution() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        // Alice stakes 10,000 TON (50%)
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        // Bob stakes 6,000 TON (30%)
        vm.prank(bob);
        staking.stake(sequencer1, 6_000 ether);

        // Charlie stakes 4,000 TON (20%)
        vm.prank(charlie);
        staking.stake(sequencer1, 4_000 ether);

        // Total: 20,000 TON

        // Sequencer distributes 1000 WTON
        uint256 totalReward = 1000 * RAY / 1e18;
        vm.prank(sequencer1);
        staking.receiveReward(totalReward);

        // After 10% commission: 900 WTON distributed
        // Expected: Alice 450, Bob 270, Charlie 180

        uint256 alicePending = staking.pendingRewards(alice, sequencer1);
        uint256 bobPending = staking.pendingRewards(bob, sequencer1);
        uint256 charliePending = staking.pendingRewards(charlie, sequencer1);

        // Allow 1 wei tolerance for rounding
        assertApproxEqAbs(alicePending, 450 * RAY / 1e18, 1, "Alice reward mismatch");
        assertApproxEqAbs(bobPending, 270 * RAY / 1e18, 1, "Bob reward mismatch");
        assertApproxEqAbs(charliePending, 180 * RAY / 1e18, 1, "Charlie reward mismatch");

        // === All stakers claim ===
        vm.prank(alice);
        staking.claimRewards(sequencer1);
        vm.prank(bob);
        staking.claimRewards(sequencer1);
        vm.prank(charlie);
        staking.claimRewards(sequencer1);

        // Verify pending is now 0
        assertEq(staking.pendingRewards(alice, sequencer1), 0);
        assertEq(staking.pendingRewards(bob, sequencer1), 0);
        assertEq(staking.pendingRewards(charlie, sequencer1), 0);
    }

    /*//////////////////////////////////////////////////////////////
                  E2E TEST: SEQUENCER COMMISSION LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests sequencer commission accumulation and claiming
     */
    function test_E2E_SequencerCommissionLifecycle() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_20_PERCENT);

        // Stakers stake
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);
        vm.prank(bob);
        staking.stake(sequencer1, 10_000 ether);

        // Multiple reward distributions
        uint256 rewardPerRound = 500 * RAY / 1e18;

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(sequencer1);
            staking.receiveReward(rewardPerRound);
        }

        // Total rewards: 2500 WTON
        // Commission (20%): 500 WTON

        IDelegateStakingV3.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalCommission, 500 * RAY / 1e18, "Commission mismatch");

        // Sequencer claims commission
        uint256 seqWtonBefore = wton.balanceOf(sequencer1);
        vm.prank(sequencer1);
        staking.claimCommission();
        uint256 seqWtonAfter = wton.balanceOf(sequencer1);

        assertEq(seqWtonAfter - seqWtonBefore, 500 * RAY / 1e18, "Claimed commission mismatch");

        // Verify commission is now 0
        seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalCommission, 0, "Commission should be 0");
    }

    /*//////////////////////////////////////////////////////////////
                     E2E TEST: REDELEGATION FLOW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests redelegation from one sequencer to another
     */
    function test_E2E_RedelegationFlow() public {
        // Register two sequencers
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);
        _registerSequencer(sequencer2, layer2_2, address(operatorManager2), COMMISSION_5_PERCENT);

        // Alice stakes with sequencer1
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        // Sequencer1 distributes reward
        vm.prank(sequencer1);
        staking.receiveReward(100 * RAY / 1e18);

        // Alice redelegates half to sequencer2
        uint256 aliceWtonBefore = wton.balanceOf(alice);
        vm.prank(alice);
        staking.redelegate(sequencer1, sequencer2, 5000 ether);
        uint256 aliceWtonAfter = wton.balanceOf(alice);

        // Should have claimed rewards during redelegation
        assertGt(aliceWtonAfter, aliceWtonBefore, "Should claim on redelegate");

        // Verify stake distribution
        IDelegateStakingV3.StakeInfo memory stake1 = staking.getStakeInfo(alice, sequencer1);
        IDelegateStakingV3.StakeInfo memory stake2 = staking.getStakeInfo(alice, sequencer2);

        assertEq(stake1.amount, 5000 ether, "Seq1 stake mismatch");
        assertEq(stake2.amount, 5000 ether, "Seq2 stake mismatch");

        // Verify sequencer totals
        IDelegateStakingV3.SequencerInfo memory seq1Info = staking.getSequencerInfo(sequencer1);
        IDelegateStakingV3.SequencerInfo memory seq2Info = staking.getSequencerInfo(sequencer2);

        assertEq(seq1Info.totalStaked, 5000 ether);
        assertEq(seq2Info.totalStaked, 5000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                   E2E TEST: AUTO-TRIGGER MECHANISM
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests auto-trigger functionality for seigniorage distribution
     */
    function test_E2E_AutoTriggerMechanism() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        // Stake tokens
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        // Enable auto-trigger
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        // Simulate seigniorage in operator manager
        uint256 seigniorageAmount = 500 * RAY / 1e18;
        operatorManager1.mockSetPendingRewards(seigniorageAmount);

        // Keeper triggers seigniorage
        vm.prank(keeper);
        staking.triggerSeigniorage(sequencer1);

        // Verify rewards were distributed
        uint256 alicePending = staking.pendingRewards(alice, sequencer1);
        assertGt(alicePending, 0, "Should have pending rewards after trigger");
    }

    /*//////////////////////////////////////////////////////////////
                   E2E TEST: BATCH TRIGGER WITH KEEPER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests batch triggering multiple sequencers
     */
    function test_E2E_BatchTriggerWithKeeper() public {
        // Setup all sequencers
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);
        _registerSequencer(sequencer2, layer2_2, address(operatorManager2), COMMISSION_10_PERCENT);
        _registerSequencer(sequencer3, layer2_3, address(operatorManager3), COMMISSION_10_PERCENT);

        // Enable auto-trigger for all
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);
        vm.prank(sequencer2);
        staking.setAutoTrigger(true);
        vm.prank(sequencer3);
        staking.setAutoTrigger(true);

        // Stake with all sequencers
        vm.prank(alice);
        staking.stake(sequencer1, 5000 ether);
        vm.prank(bob);
        staking.stake(sequencer2, 5000 ether);
        vm.prank(charlie);
        staking.stake(sequencer3, 5000 ether);

        // Add seigniorage to all operator managers
        operatorManager1.mockSetPendingRewards(100 * RAY / 1e18);
        operatorManager2.mockSetPendingRewards(200 * RAY / 1e18);
        operatorManager3.mockSetPendingRewards(300 * RAY / 1e18);

        // Batch trigger
        address[] memory seqList = new address[](3);
        seqList[0] = sequencer1;
        seqList[1] = sequencer2;
        seqList[2] = sequencer3;

        vm.prank(keeper);
        staking.batchTriggerSeigniorage(seqList);

        // Verify all have pending rewards
        assertGt(staking.pendingRewards(alice, sequencer1), 0);
        assertGt(staking.pendingRewards(bob, sequencer2), 0);
        assertGt(staking.pendingRewards(charlie, sequencer3), 0);
    }

    /*//////////////////////////////////////////////////////////////
                  E2E TEST: DELEGATE TRIGGER CONTRACT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests DelegateTrigger contract with keeper rewards
     */
    function test_E2E_DelegateTriggerWithKeeperRewards() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        // Register trigger
        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            1 hours // min interval
        );

        // Set keeper reward
        uint256 keeperRewardAmount = 10 * RAY / 1e18;
        vm.prank(owner);
        trigger.setKeeperReward(keeperRewardAmount);

        // Fund reward pool
        vm.prank(owner);
        trigger.fundKeeperRewardPool(1000 * RAY / 1e18);

        // Simulate seigniorage
        operatorManager1.mockSetPendingRewards(500 * RAY / 1e18);

        // Warp time past min interval
        vm.warp(block.timestamp + 2 hours);

        // Keeper triggers
        uint256 keeperWtonBefore = wton.balanceOf(keeper);
        vm.prank(keeper);
        trigger.trigger(triggerId);
        uint256 keeperWtonAfter = wton.balanceOf(keeper);

        // Verify keeper received reward
        assertEq(keeperWtonAfter - keeperWtonBefore, keeperRewardAmount, "Keeper reward mismatch");
    }

    /*//////////////////////////////////////////////////////////////
                    E2E TEST: EMERGENCY MODE FLOW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests complete emergency mode activation and withdrawal
     */
    function test_E2E_EmergencyModeFlow() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        // Multiple stakers
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);
        vm.prank(bob);
        staking.stake(sequencer1, 20_000 ether);

        // Some rewards distributed
        vm.prank(sequencer1);
        staking.receiveReward(500 * RAY / 1e18);

        // Alice starts unstaking (partial)
        vm.prank(alice);
        staking.unstake(sequencer1, 5000 ether);

        // === Emergency activated by guardian ===
        vm.prank(guardian);
        staking.activateEmergency(layer2_1);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertTrue(config.isActive, "Emergency should be active");

        // Try withdraw before cooldown - should fail
        vm.prank(alice);
        vm.expectRevert(IDelegateStakingV3.EmergencyCooldownNotElapsed.selector);
        staking.emergencyWithdraw(sequencer1);

        // Wait for cooldown
        vm.warp(block.timestamp + EMERGENCY_COOLDOWN + 1);

        // Alice emergency withdraws (gets both staked and unstaking amounts)
        uint256 aliceTonBefore = ton.balanceOf(alice);
        vm.prank(alice);
        staking.emergencyWithdraw(sequencer1);
        uint256 aliceTonAfter = ton.balanceOf(alice);

        // Alice should get: 5000 (remaining stake) + 5000 (unstaking) = 10000
        assertEq(aliceTonAfter - aliceTonBefore, 10_000 ether, "Emergency withdraw amount mismatch");

        // Bob emergency withdraws
        uint256 bobTonBefore = ton.balanceOf(bob);
        vm.prank(bob);
        staking.emergencyWithdraw(sequencer1);
        uint256 bobTonAfter = ton.balanceOf(bob);

        assertEq(bobTonAfter - bobTonBefore, 20_000 ether, "Bob emergency withdraw mismatch");

        // Verify all stakes cleared
        assertEq(staking.getTotalStaked(), 0, "Total staked should be 0");
    }

    /*//////////////////////////////////////////////////////////////
                 E2E TEST: COMPETING SEQUENCERS SCENARIO
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests scenario with multiple sequencers competing for delegators
     */
    function test_E2E_CompetingSequencers() public {
        // Sequencer1: High commission (20%), but consistent rewards
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_20_PERCENT);

        // Sequencer2: Low commission (5%), moderate rewards
        _registerSequencer(sequencer2, layer2_2, address(operatorManager2), COMMISSION_5_PERCENT);

        // Sequencer3: Medium commission (10%), high rewards
        _registerSequencer(sequencer3, layer2_3, address(operatorManager3), COMMISSION_10_PERCENT);

        // Stakers choose different sequencers
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        vm.prank(bob);
        staking.stake(sequencer2, 10_000 ether);

        vm.prank(charlie);
        staking.stake(sequencer3, 10_000 ether);

        // Each sequencer distributes different amounts
        vm.prank(sequencer1);
        staking.receiveReward(200 * RAY / 1e18); // Alice gets 160 (80%)

        vm.prank(sequencer2);
        staking.receiveReward(100 * RAY / 1e18); // Bob gets 95 (95%)

        vm.prank(sequencer3);
        staking.receiveReward(300 * RAY / 1e18); // Charlie gets 270 (90%)

        // Check effective returns
        uint256 alicePending = staking.pendingRewards(alice, sequencer1);
        uint256 bobPending = staking.pendingRewards(bob, sequencer2);
        uint256 charliePending = staking.pendingRewards(charlie, sequencer3);

        assertEq(alicePending, 160 * RAY / 1e18, "Alice pending mismatch");
        assertEq(bobPending, 95 * RAY / 1e18, "Bob pending mismatch");
        assertEq(charliePending, 270 * RAY / 1e18, "Charlie pending mismatch");

        // Bob realizes sequencer3 is better, redelegates
        vm.prank(bob);
        staking.redelegate(sequencer2, sequencer3, 10_000 ether);

        // Verify redistribution
        IDelegateStakingV3.SequencerInfo memory seq2Info = staking.getSequencerInfo(sequencer2);
        IDelegateStakingV3.SequencerInfo memory seq3Info = staking.getSequencerInfo(sequencer3);

        assertEq(seq2Info.totalStaked, 0, "Seq2 should have no stakers");
        assertEq(seq3Info.totalStaked, 20_000 ether, "Seq3 should have both");
    }

    /*//////////////////////////////////////////////////////////////
                E2E TEST: LATE STAKER REWARD FAIRNESS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that late stakers don't steal early stakers' rewards
     */
    function test_E2E_LateStakerFairness() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        // Alice stakes first
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        // Rewards distributed (only Alice should get these)
        vm.prank(sequencer1);
        staking.receiveReward(1000 * RAY / 1e18);

        uint256 alicePendingBefore = staking.pendingRewards(alice, sequencer1);
        assertEq(alicePendingBefore, 900 * RAY / 1e18, "Alice should get all rewards");

        // Bob stakes later
        vm.prank(bob);
        staking.stake(sequencer1, 10_000 ether);

        // Alice's pending should be unchanged
        uint256 alicePendingAfter = staking.pendingRewards(alice, sequencer1);
        assertEq(alicePendingAfter, alicePendingBefore, "Alice rewards should be unchanged");

        // Bob should have 0 pending
        uint256 bobPending = staking.pendingRewards(bob, sequencer1);
        assertEq(bobPending, 0, "Bob should have no pending rewards");

        // New rewards - split 50/50
        vm.prank(sequencer1);
        staking.receiveReward(1000 * RAY / 1e18);

        uint256 aliceNew = staking.pendingRewards(alice, sequencer1);
        uint256 bobNew = staking.pendingRewards(bob, sequencer1);

        // Alice: 900 (old) + 450 (new) = 1350
        // Bob: 450 (new)
        assertEq(aliceNew, 1350 * RAY / 1e18, "Alice total mismatch");
        assertEq(bobNew, 450 * RAY / 1e18, "Bob new mismatch");
    }

    /*//////////////////////////////////////////////////////////////
                 E2E TEST: SEQUENCER DEREGISTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests sequencer deregistration with proper cleanup
     */
    function test_E2E_SequencerDeregistration() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        // Staker stakes
        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        // Rewards distributed
        vm.prank(sequencer1);
        staking.receiveReward(500 * RAY / 1e18);

        // Sequencer cannot deregister with stakes
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.deregisterSequencer();

        // Alice unstakes everything
        vm.prank(alice);
        staking.unstake(sequencer1, 10_000 ether);

        // Wait and withdraw
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        vm.prank(alice);
        staking.withdraw(sequencer1);

        // Sequencer claims commission first
        vm.prank(sequencer1);
        staking.claimCommission();

        // Now sequencer can deregister
        vm.prank(sequencer1);
        staking.deregisterSequencer();

        // Verify deregistration
        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertFalse(info.isRegistered, "Should be deregistered");

        // Layer2 mapping cleared
        assertEq(staking.getSequencerByLayer2(layer2_1), address(0), "Layer2 mapping should be cleared");
    }

    /*//////////////////////////////////////////////////////////////
                   E2E TEST: STRESS - MANY STAKERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stress test with many stakers
     */
    function test_E2E_ManyStakers() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        // Create 20 stakers
        uint256 numStakers = 20;
        address[] memory stakers = new address[](numStakers);
        uint256 totalStaked = 0;

        for (uint256 i = 0; i < numStakers; i++) {
            stakers[i] = makeAddr(string(abi.encodePacked("staker", i)));
            uint256 amount = (i + 1) * 1000 ether;

            ton.mint(stakers[i], amount);
            vm.prank(stakers[i]);
            ton.approve(address(staking), amount);

            vm.prank(stakers[i]);
            staking.stake(sequencer1, amount);

            totalStaked += amount;
        }

        // Total should be: 1000 + 2000 + ... + 20000 = 210,000 TON
        assertEq(staking.getTotalStaked(), totalStaked);
        assertEq(totalStaked, 210_000 ether);

        // Distribute rewards
        uint256 rewardAmount = 21_000 * RAY / 1e18; // 21,000 WTON
        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        // After 10% commission: 18,900 WTON distributed
        // Each staker should get proportional share

        uint256 totalPending = 0;
        for (uint256 i = 0; i < numStakers; i++) {
            totalPending += staking.pendingRewards(stakers[i], sequencer1);
        }

        // Should be close to 18,900 WTON (allow small rounding error)
        assertApproxEqAbs(totalPending, 18_900 * RAY / 1e18, numStakers, "Total pending mismatch");
    }

    /*//////////////////////////////////////////////////////////////
                    E2E TEST: MIXED OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests complex scenario with mixed operations
     */
    function test_E2E_MixedOperations() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);
        _registerSequencer(sequencer2, layer2_2, address(operatorManager2), COMMISSION_10_PERCENT);

        // === Block 1: Initial stakes ===
        vm.prank(alice);
        staking.stake(sequencer1, 5000 ether);
        vm.prank(bob);
        staking.stake(sequencer1, 5000 ether);

        // === Block 2: Rewards + more stakes ===
        vm.prank(sequencer1);
        staking.receiveReward(100 * RAY / 1e18);

        vm.prank(charlie);
        staking.stake(sequencer1, 10_000 ether);

        // === Block 3: Unstake + redelegate ===
        vm.prank(alice);
        staking.unstake(sequencer1, 2500 ether);

        vm.prank(bob);
        staking.redelegate(sequencer1, sequencer2, 2500 ether);

        // === Block 4: More rewards to both sequencers ===
        vm.prank(sequencer1);
        staking.receiveReward(200 * RAY / 1e18);

        vm.prank(sequencer2);
        staking.receiveReward(50 * RAY / 1e18);

        // === Verify complex state ===
        IDelegateStakingV3.StakeInfo memory aliceStake = staking.getStakeInfo(alice, sequencer1);
        assertEq(aliceStake.amount, 2500 ether, "Alice remaining stake");
        assertEq(aliceStake.unstakeAmount, 2500 ether, "Alice unstaking");

        IDelegateStakingV3.StakeInfo memory bobStake1 = staking.getStakeInfo(bob, sequencer1);
        IDelegateStakingV3.StakeInfo memory bobStake2 = staking.getStakeInfo(bob, sequencer2);
        assertEq(bobStake1.amount, 2500 ether, "Bob seq1 stake");
        assertEq(bobStake2.amount, 2500 ether, "Bob seq2 stake");

        // === Everyone claims ===
        vm.prank(alice);
        staking.claimRewards(sequencer1);
        vm.prank(bob);
        staking.claimRewards(sequencer1);
        vm.prank(bob);
        staking.claimRewards(sequencer2);
        vm.prank(charlie);
        staking.claimRewards(sequencer1);

        // Verify all pending is 0
        assertEq(staking.pendingRewards(alice, sequencer1), 0);
        assertEq(staking.pendingRewards(bob, sequencer1), 0);
        assertEq(staking.pendingRewards(bob, sequencer2), 0);
        assertEq(staking.pendingRewards(charlie, sequencer1), 0);
    }

    /*//////////////////////////////////////////////////////////////
                  E2E TEST: COMMISSION UPDATE IMPACT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that commission changes apply to new rewards only
     */
    function test_E2E_CommissionUpdateImpact() public {
        _registerSequencer(sequencer1, layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);

        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        // First reward with 10% commission
        vm.prank(sequencer1);
        staking.receiveReward(100 * RAY / 1e18);

        IDelegateStakingV3.SequencerInfo memory info1 = staking.getSequencerInfo(sequencer1);
        assertEq(info1.totalCommission, 10 * RAY / 1e18, "10% commission");

        // Update to 20%
        vm.prank(sequencer1);
        staking.updateCommission(COMMISSION_20_PERCENT);

        // Second reward with 20% commission
        vm.prank(sequencer1);
        staking.receiveReward(100 * RAY / 1e18);

        IDelegateStakingV3.SequencerInfo memory info2 = staking.getSequencerInfo(sequencer1);
        // Total: 10 (first) + 20 (second) = 30
        assertEq(info2.totalCommission, 30 * RAY / 1e18, "Total commission");

        // Alice's pending: 90 (first) + 80 (second) = 170
        uint256 alicePending = staking.pendingRewards(alice, sequencer1);
        assertEq(alicePending, 170 * RAY / 1e18, "Alice pending");
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _registerSequencer(
        address sequencer,
        address layer2,
        address operatorManager,
        uint256 commission
    ) internal {
        vm.prank(sequencer);
        staking.registerSequencer(layer2, operatorManager, commission);
    }
}

/**
 * @title MockOperatorManager
 * @notice Simple mock for operator validation in tests
 */
contract MockOperatorManager {
    address public operator;
    address public wton;

    constructor(address _operator, address _wton) {
        operator = _operator;
        wton = _wton;
    }

    function isOperator(address addr) external view returns (bool) {
        return addr == operator;
    }

    function manager() external view returns (address) {
        return operator;
    }

    function claimERC20(address token, uint256 amount) external {
        uint256 balance = IERC20Mock(token).balanceOf(address(this));
        uint256 transferAmount = amount > balance ? balance : amount;
        if (transferAmount > 0) {
            IERC20Mock(token).transfer(msg.sender, transferAmount);
        }
    }
}

interface IERC20Mock {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}
