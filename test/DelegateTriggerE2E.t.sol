// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DelegateStakingV3} from "../contracts/DelegateStakingV3.sol";
import {DelegateTrigger} from "../contracts/DelegateTrigger.sol";
import {IDelegateStakingV3} from "../contracts/interfaces/IDelegateStakingV3.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockOperatorManagerV3} from "./mocks/MockOperatorManagerV3.sol";

/**
 * @title DelegateTriggerE2E
 * @notice Comprehensive E2E tests for DelegateTrigger contract
 */
contract DelegateTriggerE2E is Test {
    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/

    DelegateStakingV3 public staking;
    DelegateTrigger public trigger;
    ERC20Mock public ton;
    ERC20Mock public wton;
    MockOperatorManagerV3 public operatorManager1;
    MockOperatorManagerV3 public operatorManager2;
    MockOperatorManagerV3 public operatorManager3;

    /*//////////////////////////////////////////////////////////////
                              ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public owner = makeAddr("owner");
    address public keeper1 = makeAddr("keeper1");
    address public keeper2 = makeAddr("keeper2");

    address public sequencer1 = makeAddr("sequencer1");
    address public sequencer2 = makeAddr("sequencer2");
    address public sequencer3 = makeAddr("sequencer3");

    address public layer2_1 = makeAddr("layer2_1");
    address public layer2_2 = makeAddr("layer2_2");
    address public layer2_3 = makeAddr("layer2_3");

    address public alice = makeAddr("alice");

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant RAY = 1e27;
    uint256 public constant INITIAL_BALANCE = 100_000 ether;
    uint256 public constant INITIAL_WTON = 100_000 * RAY;
    uint256 public constant UNBONDING_PERIOD = 14 days;
    uint256 public constant MIN_TRIGGER_INTERVAL = 1 hours;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Deploy tokens
        ton = new ERC20Mock("TON", "TON");
        wton = new ERC20Mock("WTON", "WTON");

        // Deploy operator managers
        operatorManager1 = new MockOperatorManagerV3(sequencer1, address(wton), address(0), layer2_1);
        operatorManager2 = new MockOperatorManagerV3(sequencer2, address(wton), address(0), layer2_2);
        operatorManager3 = new MockOperatorManagerV3(sequencer3, address(wton), address(0), layer2_3);

        // Deploy staking contract
        vm.prank(owner);
        staking = new DelegateStakingV3(
            address(ton),
            address(wton),
            address(0),
            address(0),
            UNBONDING_PERIOD,
            owner
        );

        // Deploy trigger contract
        vm.prank(owner);
        trigger = new DelegateTrigger(address(wton), owner);

        // Mint tokens
        ton.mint(alice, INITIAL_BALANCE);
        wton.mint(address(operatorManager1), INITIAL_WTON);
        wton.mint(address(operatorManager2), INITIAL_WTON);
        wton.mint(address(operatorManager3), INITIAL_WTON);
        wton.mint(owner, INITIAL_WTON);
        wton.mint(sequencer1, INITIAL_WTON);
        wton.mint(sequencer2, INITIAL_WTON);
        wton.mint(sequencer3, INITIAL_WTON);

        // Approvals
        vm.prank(alice);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(owner);
        wton.approve(address(trigger), type(uint256).max);
        vm.prank(sequencer1);
        wton.approve(address(staking), type(uint256).max);
        vm.prank(sequencer2);
        wton.approve(address(staking), type(uint256).max);
        vm.prank(sequencer3);
        wton.approve(address(staking), type(uint256).max);

        // Authorize staking contract in operator managers
        vm.prank(sequencer1);
        operatorManager1.authorizeClaimer(address(staking));
        vm.prank(sequencer2);
        operatorManager2.authorizeClaimer(address(staking));
        vm.prank(sequencer3);
        operatorManager3.authorizeClaimer(address(staking));
    }

    /*//////////////////////////////////////////////////////////////
                       TRIGGER REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RegisterTrigger() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        DelegateTrigger.TriggerConfig memory config = trigger.getTriggerConfig(triggerId);
        assertEq(config.delegateStaking, address(staking));
        assertEq(config.operatorManager, address(operatorManager1));
        assertEq(config.sequencer, sequencer1);
        assertTrue(config.isActive);
        assertEq(config.minInterval, MIN_TRIGGER_INTERVAL);
    }

    function test_RegisterTrigger_RevertIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
    }

    function test_RegisterTrigger_RevertIfZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(DelegateTrigger.ZeroAddress.selector);
        trigger.registerTrigger(address(0), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
    }

    function test_RegisterTrigger_RevertIfAlreadyExists() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);

        vm.prank(owner);
        vm.expectRevert(DelegateTrigger.TriggerAlreadyExists.selector);
        trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
    }

    /*//////////////////////////////////////////////////////////////
                    TRIGGER ACTIVATION/DEACTIVATION
    //////////////////////////////////////////////////////////////*/

    function test_DeactivateTrigger() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        vm.prank(owner);
        trigger.deactivateTrigger(triggerId);

        DelegateTrigger.TriggerConfig memory config = trigger.getTriggerConfig(triggerId);
        assertFalse(config.isActive);
    }

    function test_ActivateTrigger() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        vm.prank(owner);
        trigger.deactivateTrigger(triggerId);

        vm.prank(owner);
        trigger.activateTrigger(triggerId);

        DelegateTrigger.TriggerConfig memory config = trigger.getTriggerConfig(triggerId);
        assertTrue(config.isActive);
    }

    function test_DeactivateTrigger_RevertIfNotFound() public {
        bytes32 fakeTrigger = keccak256("fake");

        vm.prank(owner);
        vm.expectRevert(DelegateTrigger.TriggerNotFound.selector);
        trigger.deactivateTrigger(fakeTrigger);
    }

    function test_UpdateMinInterval() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        uint256 newInterval = 2 hours;
        vm.prank(owner);
        trigger.updateMinInterval(triggerId, newInterval);

        DelegateTrigger.TriggerConfig memory config = trigger.getTriggerConfig(triggerId);
        assertEq(config.minInterval, newInterval);
    }

    /*//////////////////////////////////////////////////////////////
                         SINGLE TRIGGER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Trigger() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        // Add seigniorage
        operatorManager1.mockSetPendingRewards(500 * RAY / 1e18);

        // Warp past interval
        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);

        // Trigger
        vm.prank(keeper1);
        trigger.trigger(triggerId);

        // Verify rewards distributed
        uint256 pending = staking.pendingRewards(alice, sequencer1);
        assertGt(pending, 0, "Should have pending rewards");
    }

    function test_Trigger_RevertIfNotActive() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        vm.prank(owner);
        trigger.deactivateTrigger(triggerId);

        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);

        vm.prank(keeper1);
        vm.expectRevert(DelegateTrigger.TriggerNotActive.selector);
        trigger.trigger(triggerId);
    }

    function test_Trigger_RevertIfIntervalNotElapsed() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        vm.prank(keeper1);
        vm.expectRevert(DelegateTrigger.IntervalNotElapsed.selector);
        trigger.trigger(triggerId);
    }

    /*//////////////////////////////////////////////////////////////
                         BATCH TRIGGER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchTrigger() public {
        // Setup all sequencers
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        _setupSequencer(sequencer2, layer2_2, address(operatorManager2));
        _setupSequencer(sequencer3, layer2_3, address(operatorManager3));

        // Enable auto-trigger
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);
        vm.prank(sequencer2);
        staking.setAutoTrigger(true);
        vm.prank(sequencer3);
        staking.setAutoTrigger(true);

        // Stake with each
        vm.startPrank(alice);
        staking.stake(sequencer1, 3000 ether);
        staking.stake(sequencer2, 3000 ether);
        staking.stake(sequencer3, 3000 ether);
        vm.stopPrank();

        // Register triggers
        vm.startPrank(owner);
        bytes32 t1 = trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
        bytes32 t2 = trigger.registerTrigger(address(staking), address(operatorManager2), sequencer2, MIN_TRIGGER_INTERVAL);
        bytes32 t3 = trigger.registerTrigger(address(staking), address(operatorManager3), sequencer3, MIN_TRIGGER_INTERVAL);
        vm.stopPrank();

        // Add seigniorage
        operatorManager1.mockSetPendingRewards(100 * RAY / 1e18);
        operatorManager2.mockSetPendingRewards(200 * RAY / 1e18);
        operatorManager3.mockSetPendingRewards(300 * RAY / 1e18);

        // Warp and batch trigger
        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);

        bytes32[] memory triggerIds = new bytes32[](3);
        triggerIds[0] = t1;
        triggerIds[1] = t2;
        triggerIds[2] = t3;

        vm.prank(keeper1);
        trigger.batchTrigger(triggerIds);

        // Verify all have rewards
        assertGt(staking.pendingRewards(alice, sequencer1), 0);
        assertGt(staking.pendingRewards(alice, sequencer2), 0);
        assertGt(staking.pendingRewards(alice, sequencer3), 0);
    }

    function test_BatchTrigger_SkipsInactive() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        _setupSequencer(sequencer2, layer2_2, address(operatorManager2));

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);
        vm.prank(sequencer2);
        staking.setAutoTrigger(true);

        vm.startPrank(owner);
        bytes32 t1 = trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
        bytes32 t2 = trigger.registerTrigger(address(staking), address(operatorManager2), sequencer2, MIN_TRIGGER_INTERVAL);
        trigger.deactivateTrigger(t1); // Deactivate t1
        vm.stopPrank();

        operatorManager1.mockSetPendingRewards(100 * RAY / 1e18);
        operatorManager2.mockSetPendingRewards(100 * RAY / 1e18);

        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);

        bytes32[] memory triggerIds = new bytes32[](2);
        triggerIds[0] = t1;
        triggerIds[1] = t2;

        // Should not revert, just skip t1
        vm.prank(keeper1);
        trigger.batchTrigger(triggerIds);
    }

    /*//////////////////////////////////////////////////////////////
                       KEEPER REWARD TESTS
    //////////////////////////////////////////////////////////////*/

    function test_KeeperRewards_SingleTrigger() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.prank(alice);
        staking.stake(sequencer1, 10_000 ether);

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        // Setup keeper rewards
        uint256 keeperReward = 5 * RAY / 1e18;
        vm.prank(owner);
        trigger.setKeeperReward(keeperReward);
        vm.prank(owner);
        trigger.fundKeeperRewardPool(1000 * RAY / 1e18);

        operatorManager1.mockSetPendingRewards(500 * RAY / 1e18);

        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);

        uint256 keeperBefore = wton.balanceOf(keeper1);
        vm.prank(keeper1);
        trigger.trigger(triggerId);
        uint256 keeperAfter = wton.balanceOf(keeper1);

        assertEq(keeperAfter - keeperBefore, keeperReward, "Keeper reward mismatch");
    }

    function test_KeeperRewards_BatchTrigger() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        _setupSequencer(sequencer2, layer2_2, address(operatorManager2));

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);
        vm.prank(sequencer2);
        staking.setAutoTrigger(true);

        vm.startPrank(alice);
        staking.stake(sequencer1, 5000 ether);
        staking.stake(sequencer2, 5000 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        bytes32 t1 = trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
        bytes32 t2 = trigger.registerTrigger(address(staking), address(operatorManager2), sequencer2, MIN_TRIGGER_INTERVAL);

        uint256 keeperReward = 5 * RAY / 1e18;
        trigger.setKeeperReward(keeperReward);
        trigger.fundKeeperRewardPool(1000 * RAY / 1e18);
        vm.stopPrank();

        operatorManager1.mockSetPendingRewards(100 * RAY / 1e18);
        operatorManager2.mockSetPendingRewards(100 * RAY / 1e18);

        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);

        bytes32[] memory triggerIds = new bytes32[](2);
        triggerIds[0] = t1;
        triggerIds[1] = t2;

        uint256 keeperBefore = wton.balanceOf(keeper1);
        vm.prank(keeper1);
        trigger.batchTrigger(triggerIds);
        uint256 keeperAfter = wton.balanceOf(keeper1);

        // Should get reward for 2 successful triggers
        assertEq(keeperAfter - keeperBefore, keeperReward * 2, "Batch keeper reward mismatch");
    }

    function test_FundKeeperRewardPool() public {
        uint256 fundAmount = 100 * RAY / 1e18;

        uint256 poolBefore = trigger.keeperRewardPool();
        vm.prank(owner);
        trigger.fundKeeperRewardPool(fundAmount);
        uint256 poolAfter = trigger.keeperRewardPool();

        assertEq(poolAfter - poolBefore, fundAmount);
    }

    function test_WithdrawKeeperRewardPool() public {
        vm.prank(owner);
        trigger.fundKeeperRewardPool(100 * RAY / 1e18);

        uint256 withdrawAmount = 50 * RAY / 1e18;
        uint256 ownerBefore = wton.balanceOf(owner);

        vm.prank(owner);
        trigger.withdrawKeeperRewardPool(withdrawAmount);

        uint256 ownerAfter = wton.balanceOf(owner);
        assertEq(ownerAfter - ownerBefore, withdrawAmount);
        assertEq(trigger.keeperRewardPool(), 50 * RAY / 1e18);
    }

    function test_WithdrawKeeperRewardPool_RevertIfInsufficient() public {
        vm.prank(owner);
        trigger.fundKeeperRewardPool(50 * RAY / 1e18);

        vm.prank(owner);
        vm.expectRevert(DelegateTrigger.InsufficientRewardBalance.selector);
        trigger.withdrawKeeperRewardPool(100 * RAY / 1e18);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_GetReadyTriggers() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        _setupSequencer(sequencer2, layer2_2, address(operatorManager2));

        vm.startPrank(owner);
        bytes32 t1 = trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
        bytes32 t2 = trigger.registerTrigger(address(staking), address(operatorManager2), sequencer2, 2 hours);
        vm.stopPrank();

        // Initially not ready (lastTriggerTime=0, so need to wait for minInterval)
        bytes32[] memory ready = trigger.getReadyTriggers();
        assertEq(ready.length, 0, "None should be ready initially");

        // Wait for t1's interval (1 hour)
        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);

        ready = trigger.getReadyTriggers();
        assertEq(ready.length, 1, "Only t1 should be ready after 1 hour");
        assertEq(ready[0], t1);

        // Wait for t2's interval (2 hours total)
        vm.warp(block.timestamp + 1 hours);

        ready = trigger.getReadyTriggers();
        assertEq(ready.length, 2, "Both should be ready after 2 hours");

        // Trigger t1
        vm.prank(keeper1);
        trigger.trigger(t1);

        // Only t2 should be ready (t1 needs to wait again)
        ready = trigger.getReadyTriggers();
        assertEq(ready.length, 1);
        assertEq(ready[0], t2);
    }

    function test_IsReady() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));

        vm.prank(owner);
        bytes32 triggerId = trigger.registerTrigger(
            address(staking),
            address(operatorManager1),
            sequencer1,
            MIN_TRIGGER_INTERVAL
        );

        // Initially not ready (lastTriggerTime=0, so block.timestamp < 0 + minInterval)
        assertFalse(trigger.isReady(triggerId), "Should not be ready initially");

        // Wait for min interval
        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);
        assertTrue(trigger.isReady(triggerId), "Should be ready after interval");

        vm.prank(keeper1);
        trigger.trigger(triggerId);

        assertFalse(trigger.isReady(triggerId), "Should not be ready after trigger");

        // Wait again
        vm.warp(block.timestamp + MIN_TRIGGER_INTERVAL + 1);
        assertTrue(trigger.isReady(triggerId), "Should be ready again after interval");
    }

    function test_GetAllTriggerIds() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        _setupSequencer(sequencer2, layer2_2, address(operatorManager2));

        vm.startPrank(owner);
        trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
        trigger.registerTrigger(address(staking), address(operatorManager2), sequencer2, MIN_TRIGGER_INTERVAL);
        vm.stopPrank();

        bytes32[] memory ids = trigger.getAllTriggerIds();
        assertEq(ids.length, 2);
    }

    function test_GetActiveTriggerCount() public {
        _setupSequencer(sequencer1, layer2_1, address(operatorManager1));
        _setupSequencer(sequencer2, layer2_2, address(operatorManager2));

        vm.startPrank(owner);
        bytes32 t1 = trigger.registerTrigger(address(staking), address(operatorManager1), sequencer1, MIN_TRIGGER_INTERVAL);
        trigger.registerTrigger(address(staking), address(operatorManager2), sequencer2, MIN_TRIGGER_INTERVAL);
        vm.stopPrank();

        assertEq(trigger.getActiveTriggerCount(), 2);

        vm.prank(owner);
        trigger.deactivateTrigger(t1);

        assertEq(trigger.getActiveTriggerCount(), 1);
    }

    /*//////////////////////////////////////////////////////////////
                         HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setupSequencer(address sequencer, address layer2, address operatorManager) internal {
        vm.prank(sequencer);
        staking.registerSequencer(layer2, operatorManager, 1000);
    }
}
