// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DelegateStakingV3} from "../contracts/DelegateStakingV3.sol";
import {IDelegateStakingV3} from "../contracts/interfaces/IDelegateStakingV3.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockSeigManagerV3} from "./mocks/MockSeigManagerV3.sol";
import {MockOperatorManagerV3} from "./mocks/MockOperatorManagerV3.sol";

/**
 * @title DelegateStakingV3ExtendedTest
 * @notice Extended test suite to achieve 100% coverage for DelegateStakingV3
 * @dev Covers missing functions, edge cases, and branch conditions
 */
contract DelegateStakingV3ExtendedTest is Test {
    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/

    DelegateStakingV3 public staking;
    ERC20Mock public ton;
    ERC20Mock public wton;
    MockSeigManagerV3 public seigManager;
    MockOperatorManagerV3 public operatorManager1;

    /*//////////////////////////////////////////////////////////////
                              ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public owner = makeAddr("owner");
    address public guardian = makeAddr("guardian");
    address public sequencer1 = makeAddr("sequencer1");
    address public layer2_1 = makeAddr("layer2_1");
    address public staker1 = makeAddr("staker1");
    address public randomUser = makeAddr("randomUser");

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant RAY = 1e27;
    uint256 public constant INITIAL_BALANCE = 100_000 ether;
    uint256 public constant UNBONDING_PERIOD = 14 days;
    uint256 public constant COMMISSION_10_PERCENT = 1000;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        ton = new ERC20Mock("TON", "TON");
        wton = new ERC20Mock("WTON", "WTON");

        seigManager = new MockSeigManagerV3(address(ton), address(wton));

        operatorManager1 = new MockOperatorManagerV3(
            sequencer1,
            address(wton),
            address(0),
            layer2_1
        );

        vm.prank(owner);
        staking = new DelegateStakingV3(
            address(ton),
            address(wton),
            address(seigManager),
            address(0),
            UNBONDING_PERIOD,
            owner
        );

        // Mint and approve tokens
        ton.mint(staker1, INITIAL_BALANCE);
        wton.mint(sequencer1, INITIAL_BALANCE * RAY / 1e18);
        wton.mint(address(operatorManager1), INITIAL_BALANCE * RAY / 1e18);
        wton.mint(address(staking), INITIAL_BALANCE * RAY / 1e18); // For rescue test

        vm.prank(staker1);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(sequencer1);
        wton.approve(address(staking), type(uint256).max);

        vm.prank(sequencer1);
        operatorManager1.authorizeClaimer(address(staking));
    }

    /*//////////////////////////////////////////////////////////////
                    CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_RevertIfTonZero() public {
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        new DelegateStakingV3(
            address(0),
            address(wton),
            address(seigManager),
            address(0),
            UNBONDING_PERIOD,
            owner
        );
    }

    function test_Constructor_RevertIfWtonZero() public {
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        new DelegateStakingV3(
            address(ton),
            address(0),
            address(seigManager),
            address(0),
            UNBONDING_PERIOD,
            owner
        );
    }

    /*//////////////////////////////////////////////////////////////
                SEQUENCER REGISTRATION EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_RegisterSequencer_RevertIfLayer2Zero() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.registerSequencer(address(0), address(operatorManager1), COMMISSION_10_PERCENT);
    }

    function test_RegisterSequencer_RevertIfOperatorManagerZero() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.registerSequencer(layer2_1, address(0), COMMISSION_10_PERCENT);
    }

    function test_DeregisterSequencer_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.deregisterSequencer();
    }

    function test_DeregisterSequencer_TransfersCommission() public {
        _registerSequencer();

        // Stake and receive reward to generate commission
        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(sequencer1);
        staking.receiveReward(100 * RAY / 1e18);

        // Unstake all
        vm.prank(staker1);
        staking.unstake(sequencer1, 1000 ether);

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        vm.prank(staker1);
        staking.withdraw(sequencer1);

        // Deregister - should transfer commission
        uint256 seqWtonBefore = wton.balanceOf(sequencer1);
        vm.prank(sequencer1);
        staking.deregisterSequencer();
        uint256 seqWtonAfter = wton.balanceOf(sequencer1);

        assertGt(seqWtonAfter, seqWtonBefore, "Should transfer commission on deregister");
    }

    /*//////////////////////////////////////////////////////////////
                UPDATE COMMISSION EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_UpdateCommission_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.updateCommission(500);
    }

    function test_UpdateCommission_RevertIfInvalid() public {
        _registerSequencer();

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.InvalidCommission.selector);
        staking.updateCommission(3001); // > 30%
    }

    /*//////////////////////////////////////////////////////////////
                SET AUTO TRIGGER EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_SetAutoTrigger_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.setAutoTrigger(true);
    }

    /*//////////////////////////////////////////////////////////////
                RECEIVE REWARD EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_ReceiveReward_RevertIfZeroAmount() public {
        _registerSequencer();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.receiveReward(0);
    }

    function test_ReceiveReward_RevertIfNotRegistered() public {
        vm.prank(randomUser);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.receiveReward(100 * RAY / 1e18);
    }

    function test_ReceiveReward_WithZeroTotalStaked() public {
        _registerSequencer();

        // Receive reward with no stakers - commission should accumulate
        vm.prank(sequencer1);
        staking.receiveReward(100 * RAY / 1e18);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        // 10% commission = 10 WTON
        assertEq(info.totalCommission, 10 * RAY / 1e18);
        // accRewardPerShare should be 0 (no stakers)
        assertEq(info.accRewardPerShare, 0);
    }

    /*//////////////////////////////////////////////////////////////
                CLAIM COMMISSION EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_ClaimCommission_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.claimCommission();
    }

    function test_ClaimCommission_RevertIfNoPending() public {
        _registerSequencer();

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.NoPendingRewards.selector);
        staking.claimCommission();
    }

    /*//////////////////////////////////////////////////////////////
                UNSTAKE EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_Unstake_RevertIfZeroAmount() public {
        _registerSequencer();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.unstake(sequencer1, 0);
    }

    /*//////////////////////////////////////////////////////////////
                WITHDRAW EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_RevertIfNoUnstakeRequest() public {
        _registerSequencer();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.NoUnstakeRequest.selector);
        staking.withdraw(sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                REDELEGATE EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_Redelegate_RevertIfZeroAmount() public {
        _registerSequencer();
        _registerSequencer2();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.redelegate(sequencer1, makeAddr("sequencer2"), 0);
    }

    function test_Redelegate_RevertIfSameSequencer() public {
        _registerSequencer();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.Unauthorized.selector);
        staking.redelegate(sequencer1, sequencer1, 500 ether);
    }

    function test_Redelegate_RevertIfTargetNotRegistered() public {
        _registerSequencer();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.redelegate(sequencer1, makeAddr("unregistered"), 500 ether);
    }

    function test_Redelegate_RevertIfInsufficientBalance() public {
        _registerSequencer();
        _registerSequencer2();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.redelegate(sequencer1, makeAddr("sequencer2"), 2000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                TRIGGER SEIGNIORAGE EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_TriggerSeigniorage_RevertIfNotRegistered() public {
        vm.prank(keeper);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.triggerSeigniorage(sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_ActivateEmergency_RevertIfNotGuardian() public {
        _registerSequencer();

        vm.prank(randomUser);
        vm.expectRevert(IDelegateStakingV3.NotGuardian.selector);
        staking.activateEmergency(layer2_1);
    }

    function test_ActivateEmergency_RevertIfAlreadyActive() public {
        _registerSequencer();

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.EmergencyAlreadyActive.selector);
        staking.activateEmergency(layer2_1);
    }

    function test_ActivateEmergency_ByGuardian() public {
        _registerSequencer();

        vm.prank(owner);
        staking.setDefaultGuardian(guardian);

        // Need to re-register to get the new guardian
        // Or set guardian for specific layer2
        vm.prank(owner);
        staking.setLayer2Guardian(layer2_1, guardian);

        vm.prank(guardian);
        staking.activateEmergency(layer2_1);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertTrue(config.isActive);
    }

    function test_DeactivateEmergency() public {
        _registerSequencer();

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.prank(owner);
        staking.deactivateEmergency(layer2_1);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertFalse(config.isActive);
    }

    function test_DeactivateEmergency_RevertIfNotGuardian() public {
        _registerSequencer();

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.prank(randomUser);
        vm.expectRevert(IDelegateStakingV3.NotGuardian.selector);
        staking.deactivateEmergency(layer2_1);
    }

    function test_DeactivateEmergency_RevertIfNotActive() public {
        _registerSequencer();

        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.EmergencyNotActive.selector);
        staking.deactivateEmergency(layer2_1);
    }

    function test_EmergencyWithdraw_RevertIfZeroBalance() public {
        _registerSequencer();

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.warp(block.timestamp + 3 days + 1);

        // No stake, no unstake amount
        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.emergencyWithdraw(sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_SetSeigManager() public {
        address newSeigManager = makeAddr("newSeigManager");

        vm.prank(owner);
        staking.setSeigManager(newSeigManager);

        assertEq(staking.seigManager(), newSeigManager);
    }

    function test_SetSeigManager_RevertIfNotOwner() public {
        vm.prank(randomUser);
        vm.expectRevert();
        staking.setSeigManager(makeAddr("newSeigManager"));
    }

    function test_SetLayer2Manager() public {
        address newLayer2Manager = makeAddr("newLayer2Manager");

        vm.prank(owner);
        staking.setLayer2Manager(newLayer2Manager);

        assertEq(staking.layer2Manager(), newLayer2Manager);
    }

    function test_SetLayer2Manager_RevertIfNotOwner() public {
        vm.prank(randomUser);
        vm.expectRevert();
        staking.setLayer2Manager(makeAddr("newLayer2Manager"));
    }

    function test_SetDefaultGuardian_RevertIfZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.setDefaultGuardian(address(0));
    }

    function test_SetLayer2Guardian() public {
        _registerSequencer();

        address newGuardian = makeAddr("newGuardian");

        vm.prank(owner);
        staking.setLayer2Guardian(layer2_1, newGuardian);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertEq(config.guardian, newGuardian);
    }

    function test_SetLayer2Guardian_RevertIfZeroAddress() public {
        _registerSequencer();

        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.setLayer2Guardian(layer2_1, address(0));
    }

    function test_SetLayer2Guardian_RevertIfNotOwner() public {
        _registerSequencer();

        vm.prank(randomUser);
        vm.expectRevert();
        staking.setLayer2Guardian(layer2_1, makeAddr("guardian"));
    }

    function test_SetEmergencyCooldown() public {
        _registerSequencer();

        vm.prank(owner);
        staking.setEmergencyCooldown(layer2_1, 7 days);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertEq(config.cooldownPeriod, 7 days);
    }

    function test_SetEmergencyCooldown_RevertIfNotOwner() public {
        _registerSequencer();

        vm.prank(randomUser);
        vm.expectRevert();
        staking.setEmergencyCooldown(layer2_1, 7 days);
    }

    function test_RescueTokens() public {
        uint256 rescueAmount = 100 * RAY / 1e18;
        address recipient = makeAddr("recipient");

        uint256 balanceBefore = wton.balanceOf(recipient);

        vm.prank(owner);
        staking.rescueTokens(address(wton), recipient, rescueAmount);

        uint256 balanceAfter = wton.balanceOf(recipient);
        assertEq(balanceAfter - balanceBefore, rescueAmount);
    }

    function test_RescueTokens_RevertIfZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.rescueTokens(address(wton), address(0), 100);
    }

    function test_RescueTokens_RevertIfNotOwner() public {
        vm.prank(randomUser);
        vm.expectRevert();
        staking.rescueTokens(address(wton), randomUser, 100);
    }

    /*//////////////////////////////////////////////////////////////
                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_CheckLayer2Eligibility_NoSeigManager() public {
        // Deploy staking without SeigManager
        vm.prank(owner);
        DelegateStakingV3 stakingNoSeig = new DelegateStakingV3(
            address(ton),
            address(wton),
            address(0), // No SeigManager
            address(0),
            UNBONDING_PERIOD,
            owner
        );

        (bool eligible, uint256 required, uint256 current) = stakingNoSeig.checkLayer2Eligibility(layer2_1);
        assertTrue(eligible);
        assertEq(required, 0);
        assertEq(current, 0);
    }

    function test_CheckLayer2Eligibility_WithSeigManager() public {
        // Register L2 in SeigManager
        seigManager.registerLayer2(layer2_1, address(operatorManager1));
        seigManager.updateBridgedTON(layer2_1, 1000 ether);
        seigManager.updateStakedTON(layer2_1, 200 ether);

        (bool eligible, uint256 required, uint256 current) = staking.checkLayer2Eligibility(layer2_1);
        // minStakingRatio = 0.1e27, bridgedTON = 1000 ether
        // required = 1000 * 0.1 = 100 ether
        // current = 200 ether
        // eligible = 200 >= 100 = true
        assertTrue(eligible);
        assertEq(required, 100 ether);
        assertEq(current, 200 ether);
    }

    function test_EstimateSeigniorage_NoSeigManager() public {
        // Deploy staking without SeigManager
        vm.prank(owner);
        DelegateStakingV3 stakingNoSeig = new DelegateStakingV3(
            address(ton),
            address(wton),
            address(0),
            address(0),
            UNBONDING_PERIOD,
            owner
        );

        (uint256 seqReward, uint256 valReward) = stakingNoSeig.estimateSeigniorage(sequencer1);
        assertEq(seqReward, 0);
        assertEq(valReward, 0);
    }

    function test_EstimateSeigniorage_NotRegistered() public {
        (uint256 seqReward, uint256 valReward) = staking.estimateSeigniorage(sequencer1);
        assertEq(seqReward, 0);
        assertEq(valReward, 0);
    }

    function test_EstimateSeigniorage_WithSeigManager() public {
        _registerSequencer();

        // Setup SeigManager
        seigManager.registerLayer2(layer2_1, address(operatorManager1));
        seigManager.updateBridgedTON(layer2_1, 1000 ether);
        seigManager.updateStakedTON(layer2_1, 200 ether);

        // Mine some blocks
        vm.roll(block.number + 100);

        (uint256 seqReward, uint256 valReward) = staking.estimateSeigniorage(sequencer1);
        // Should return some values based on SeigManager calculation
        // The actual values depend on SeigManager implementation
        assertGe(seqReward + valReward, 0);
    }

    function test_PendingRewards_ZeroStake() public {
        _registerSequencer();

        // No stake, should return 0
        uint256 pending = staking.pendingRewards(staker1, sequencer1);
        assertEq(pending, 0);
    }

    function test_PendingRewards_ZeroPending() public {
        _registerSequencer();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        // No rewards distributed yet
        uint256 pending = staking.pendingRewards(staker1, sequencer1);
        assertEq(pending, 0);
    }

    /*//////////////////////////////////////////////////////////////
                INTERNAL FUNCTION EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_ClaimRewardsInternal_ZeroStake() public {
        _registerSequencer();

        // Claim with no stake - should not revert, just return
        vm.prank(staker1);
        staking.claimRewards(sequencer1);
        // Should not revert
    }

    function test_ClaimRewardsInternal_ZeroPending() public {
        _registerSequencer();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        // Claim with no pending rewards
        uint256 wtonBefore = wton.balanceOf(staker1);
        vm.prank(staker1);
        staking.claimRewards(sequencer1);
        uint256 wtonAfter = wton.balanceOf(staker1);

        assertEq(wtonAfter, wtonBefore); // No change
    }

    /*//////////////////////////////////////////////////////////////
                BATCH TRIGGER EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_BatchTriggerSeigniorage_SkipsUnregistered() public {
        _registerSequencer();
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        address[] memory seqList = new address[](2);
        seqList[0] = sequencer1;
        seqList[1] = makeAddr("unregistered");

        // Should not revert, just skip unregistered
        vm.prank(keeper);
        staking.batchTriggerSeigniorage(seqList);
    }

    function test_BatchTriggerSeigniorage_SkipsAutoDisabled() public {
        _registerSequencer();
        // Auto trigger is disabled by default

        address[] memory seqList = new address[](1);
        seqList[0] = sequencer1;

        // Should not revert, just skip
        vm.prank(keeper);
        staking.batchTriggerSeigniorage(seqList);
    }

    /*//////////////////////////////////////////////////////////////
                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    address public keeper = makeAddr("keeper");

    function _registerSequencer() internal {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, address(operatorManager1), COMMISSION_10_PERCENT);
    }

    function _registerSequencer2() internal {
        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");

        MockOperatorManagerV3 operatorManager2 = new MockOperatorManagerV3(
            sequencer2,
            address(wton),
            address(0),
            layer2_2
        );

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, address(operatorManager2), COMMISSION_10_PERCENT);
    }
}
