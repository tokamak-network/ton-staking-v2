// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {DelegateStakingMVP} from "../contracts/DelegateStakingMVP.sol";
import {IDelegateStakingMVP} from "../contracts/interfaces/IDelegateStakingMVP.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockWTON} from "./mocks/WTONMock.sol";

contract DelegateStakingMVPTest is Test {
    DelegateStakingMVP public staking;
    ERC20Mock public ton;
    MockWTON public wton;

    address public owner = makeAddr("owner");
    address public sequencer1 = makeAddr("sequencer1");
    address public sequencer2 = makeAddr("sequencer2");
    address public layer2_1 = makeAddr("layer2_1");
    address public layer2_2 = makeAddr("layer2_2");
    address public delegator1 = makeAddr("delegator1");
    address public delegator2 = makeAddr("delegator2");
    address public delegator3 = makeAddr("delegator3");

    uint256 public constant TON_UNIT = 1e18;
    uint256 public constant WTON_UNIT = 1e27; // RAY
    uint256 public constant INITIAL_TON = 10000 * TON_UNIT;
    uint256 public constant INITIAL_WTON = 10000 * WTON_UNIT;
    uint256 public constant UNBONDING_PERIOD = 7 days;
    uint256 public constant COMMISSION_10_PERCENT = 1000; // 10%

    function setUp() public {
        // Deploy tokens
        ton = new ERC20Mock("Tokamak Network", "TON");
        wton = new MockWTON();

        // Deploy staking contract
        staking = new DelegateStakingMVP(
            address(ton),
            address(wton),
            UNBONDING_PERIOD,
            owner
        );

        // Mint TON to delegators
        ton.mint(delegator1, INITIAL_TON);
        ton.mint(delegator2, INITIAL_TON);
        ton.mint(delegator3, INITIAL_TON);

        // Mint WTON to sequencers (for reward distribution)
        wton.mint(sequencer1, INITIAL_WTON);
        wton.mint(sequencer2, INITIAL_WTON);

        // Approve staking contract
        vm.prank(delegator1);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(delegator2);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(delegator3);
        ton.approve(address(staking), type(uint256).max);

        vm.prank(sequencer1);
        wton.approve(address(staking), type(uint256).max);
        vm.prank(sequencer2);
        wton.approve(address(staking), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                       SEQUENCER REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RegisterSequencer() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, COMMISSION_10_PERCENT);

        IDelegateStakingMVP.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertTrue(info.isRegistered);
        assertEq(info.layer2, layer2_1);
        assertEq(info.commission, COMMISSION_10_PERCENT);
        assertEq(info.totalStaked, 0);
        assertEq(info.accRewardPerShare, 0);

        // Check layer2 mapping
        assertEq(staking.getSequencerByLayer2(layer2_1), sequencer1);
    }

    function test_RegisterSequencer_EmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit IDelegateStakingMVP.SequencerRegistered(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, COMMISSION_10_PERCENT);
    }

    function test_RevertWhen_RegisterSequencerAlreadyRegistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, COMMISSION_10_PERCENT);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingMVP.SequencerAlreadyRegistered.selector);
        staking.registerSequencer(layer2_2, COMMISSION_10_PERCENT);
    }

    function test_RevertWhen_Layer2AlreadyRegistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, COMMISSION_10_PERCENT);

        vm.prank(sequencer2);
        vm.expectRevert(IDelegateStakingMVP.Layer2AlreadyRegistered.selector);
        staking.registerSequencer(layer2_1, COMMISSION_10_PERCENT);
    }

    function test_RevertWhen_InvalidCommission() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingMVP.InvalidCommission.selector);
        staking.registerSequencer(layer2_1, 3001); // > 30%
    }

    function test_RevertWhen_ZeroLayer2Address() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingMVP.ZeroAddress.selector);
        staking.registerSequencer(address(0), COMMISSION_10_PERCENT);
    }

    function test_UpdateCommission() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        vm.prank(sequencer1);
        staking.updateCommission(2000); // 20%

        IDelegateStakingMVP.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.commission, 2000);
    }

    function test_DeregisterSequencer() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        vm.prank(sequencer1);
        staking.deregisterSequencer();

        IDelegateStakingMVP.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertFalse(info.isRegistered);
        assertEq(staking.getSequencerByLayer2(layer2_1), address(0));
    }

    function test_RevertWhen_DeregisterWithStakes() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingMVP.InsufficientBalance.selector);
        staking.deregisterSequencer();
    }

    /*//////////////////////////////////////////////////////////////
                            STAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Stake() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        uint256 stakeAmount = 100 * TON_UNIT;
        uint256 balanceBefore = ton.balanceOf(delegator1);

        vm.prank(delegator1);
        staking.stake(sequencer1, stakeAmount);

        IDelegateStakingMVP.StakeInfo memory info = staking.getStakeInfo(delegator1, sequencer1);
        assertEq(info.amount, stakeAmount);
        assertEq(ton.balanceOf(delegator1), balanceBefore - stakeAmount);
        assertEq(ton.balanceOf(address(staking)), stakeAmount);

        IDelegateStakingMVP.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalStaked, stakeAmount);
        assertEq(staking.getTotalStaked(), stakeAmount);
    }

    function test_StakeMultipleDelegators() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        _stake(delegator1, sequencer1, 100 * TON_UNIT);
        _stake(delegator2, sequencer1, 200 * TON_UNIT);
        _stake(delegator3, sequencer1, 300 * TON_UNIT);

        IDelegateStakingMVP.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalStaked, 600 * TON_UNIT);
        assertEq(staking.getTotalStaked(), 600 * TON_UNIT);
    }

    function test_RevertWhen_StakeZeroAmount() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.ZeroAmount.selector);
        staking.stake(sequencer1, 0);
    }

    function test_RevertWhen_StakeToUnregisteredSequencer() public {
        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.SequencerNotRegistered.selector);
        staking.stake(sequencer1, 100 * TON_UNIT);
    }

    /*//////////////////////////////////////////////////////////////
                           UNSTAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Unstake() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        staking.unstake(sequencer1, 50 * TON_UNIT);

        IDelegateStakingMVP.StakeInfo memory info = staking.getStakeInfo(delegator1, sequencer1);
        assertEq(info.amount, 50 * TON_UNIT);
        assertEq(info.unstakeAmount, 50 * TON_UNIT);
        assertGt(info.unstakeTime, 0);

        IDelegateStakingMVP.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalStaked, 50 * TON_UNIT);
    }

    function test_RevertWhen_UnstakeInsufficientBalance() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.InsufficientBalance.selector);
        staking.unstake(sequencer1, 150 * TON_UNIT);
    }

    /*//////////////////////////////////////////////////////////////
                           WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        staking.unstake(sequencer1, 100 * TON_UNIT);

        // Fast forward past unbonding period
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        uint256 balanceBefore = ton.balanceOf(delegator1);
        vm.prank(delegator1);
        staking.withdraw(sequencer1);
        uint256 balanceAfter = ton.balanceOf(delegator1);

        assertEq(balanceAfter - balanceBefore, 100 * TON_UNIT);

        IDelegateStakingMVP.StakeInfo memory info = staking.getStakeInfo(delegator1, sequencer1);
        assertEq(info.unstakeAmount, 0);
        assertEq(info.unstakeTime, 0);
    }

    function test_RevertWhen_WithdrawBeforeUnbondingPeriod() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        staking.unstake(sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.UnstakingPeriodNotElapsed.selector);
        staking.withdraw(sequencer1);
    }

    function test_RevertWhen_WithdrawNoUnstakeRequest() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.NoUnstakeRequest.selector);
        staking.withdraw(sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                       REWARD DISTRIBUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReceiveReward_SingleDelegator() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        uint256 rewardAmount = 10 * WTON_UNIT;

        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        // Check commission (10%)
        IDelegateStakingMVP.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalCommission, 1 * WTON_UNIT); // 10% of 10

        // Check pending rewards (90%)
        uint256 pending = staking.pendingRewards(delegator1, sequencer1);
        assertEq(pending, 9 * WTON_UNIT); // 90% of 10
    }

    function test_ReceiveReward_MultipleDelegators() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT); // 1/3
        _stake(delegator2, sequencer1, 200 * TON_UNIT); // 2/3

        uint256 rewardAmount = 30 * WTON_UNIT;

        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        // Commission: 3 WTON (10%)
        // Distributed: 27 WTON (90%)
        // delegator1: 27 * 1/3 = 9 WTON
        // delegator2: 27 * 2/3 = 18 WTON

        uint256 pending1 = staking.pendingRewards(delegator1, sequencer1);
        uint256 pending2 = staking.pendingRewards(delegator2, sequencer1);

        assertEq(pending1, 9 * WTON_UNIT);
        assertEq(pending2, 18 * WTON_UNIT);
    }

    function test_ReceiveReward_MultipleRounds() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        // Round 1: 10 WTON
        vm.prank(sequencer1);
        staking.receiveReward(10 * WTON_UNIT);

        // Round 2: 20 WTON
        vm.prank(sequencer1);
        staking.receiveReward(20 * WTON_UNIT);

        // Total: 30 WTON, Commission: 3 WTON, Distributed: 27 WTON
        uint256 pending = staking.pendingRewards(delegator1, sequencer1);
        assertEq(pending, 27 * WTON_UNIT);

        IDelegateStakingMVP.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalCommission, 3 * WTON_UNIT);
    }

    function test_RevertWhen_ReceiveRewardZeroAmount() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingMVP.ZeroAmount.selector);
        staking.receiveReward(0);
    }

    function test_RevertWhen_ReceiveRewardNotSequencer() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.SequencerNotRegistered.selector);
        staking.receiveReward(10 * WTON_UNIT);
    }

    /*//////////////////////////////////////////////////////////////
                        CLAIM REWARDS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ClaimRewards() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(sequencer1);
        staking.receiveReward(10 * WTON_UNIT);

        uint256 balanceBefore = wton.balanceOf(delegator1);
        vm.prank(delegator1);
        staking.claimRewards(sequencer1);
        uint256 balanceAfter = wton.balanceOf(delegator1);

        assertEq(balanceAfter - balanceBefore, 9 * WTON_UNIT);

        // Pending should be 0 after claim
        assertEq(staking.pendingRewards(delegator1, sequencer1), 0);
    }

    function test_ClaimRewards_AutoClaimsOnStake() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(sequencer1);
        staking.receiveReward(10 * WTON_UNIT);

        uint256 balanceBefore = wton.balanceOf(delegator1);

        // Stake more - should auto-claim
        vm.prank(delegator1);
        staking.stake(sequencer1, 50 * TON_UNIT);

        uint256 balanceAfter = wton.balanceOf(delegator1);
        assertEq(balanceAfter - balanceBefore, 9 * WTON_UNIT);
    }

    function test_ClaimRewards_AutoClaimsOnUnstake() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(sequencer1);
        staking.receiveReward(10 * WTON_UNIT);

        uint256 balanceBefore = wton.balanceOf(delegator1);

        // Unstake - should auto-claim
        vm.prank(delegator1);
        staking.unstake(sequencer1, 50 * TON_UNIT);

        uint256 balanceAfter = wton.balanceOf(delegator1);
        assertEq(balanceAfter - balanceBefore, 9 * WTON_UNIT);
    }

    /*//////////////////////////////////////////////////////////////
                       CLAIM COMMISSION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ClaimCommission() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(sequencer1);
        staking.receiveReward(100 * WTON_UNIT);

        uint256 balanceBefore = wton.balanceOf(sequencer1);
        vm.prank(sequencer1);
        staking.claimCommission();
        uint256 balanceAfter = wton.balanceOf(sequencer1);

        // 10% commission = 10 WTON
        assertEq(balanceAfter - balanceBefore, 10 * WTON_UNIT);

        IDelegateStakingMVP.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalCommission, 0);
    }

    function test_RevertWhen_ClaimCommissionNoPending() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingMVP.NoPendingRewards.selector);
        staking.claimCommission();
    }

    /*//////////////////////////////////////////////////////////////
                         REDELEGATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Redelegate() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _registerSequencer(sequencer2, layer2_2, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        staking.redelegate(sequencer1, sequencer2, 50 * TON_UNIT);

        IDelegateStakingMVP.StakeInfo memory info1 = staking.getStakeInfo(delegator1, sequencer1);
        IDelegateStakingMVP.StakeInfo memory info2 = staking.getStakeInfo(delegator1, sequencer2);

        assertEq(info1.amount, 50 * TON_UNIT);
        assertEq(info2.amount, 50 * TON_UNIT);

        IDelegateStakingMVP.SequencerInfo memory seq1Info = staking.getSequencerInfo(sequencer1);
        IDelegateStakingMVP.SequencerInfo memory seq2Info = staking.getSequencerInfo(sequencer2);

        assertEq(seq1Info.totalStaked, 50 * TON_UNIT);
        assertEq(seq2Info.totalStaked, 50 * TON_UNIT);
    }

    function test_Redelegate_ClaimsBothSequencerRewards() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _registerSequencer(sequencer2, layer2_2, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);
        _stake(delegator1, sequencer2, 100 * TON_UNIT);

        // Distribute rewards to both
        vm.prank(sequencer1);
        staking.receiveReward(10 * WTON_UNIT);
        vm.prank(sequencer2);
        staking.receiveReward(20 * WTON_UNIT);

        uint256 balanceBefore = wton.balanceOf(delegator1);

        // Redelegate - should claim both
        vm.prank(delegator1);
        staking.redelegate(sequencer1, sequencer2, 50 * TON_UNIT);

        uint256 balanceAfter = wton.balanceOf(delegator1);

        // seq1: 10 - 10% = 9 WTON
        // seq2: 20 - 10% = 18 WTON
        // Total: 27 WTON
        assertEq(balanceAfter - balanceBefore, 27 * WTON_UNIT);
    }

    function test_RevertWhen_RedelegateSameSequencer() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.Unauthorized.selector);
        staking.redelegate(sequencer1, sequencer1, 50 * TON_UNIT);
    }

    function test_RevertWhen_RedelegateToUnregisteredSequencer() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        vm.prank(delegator1);
        vm.expectRevert(IDelegateStakingMVP.SequencerNotRegistered.selector);
        staking.redelegate(sequencer1, sequencer2, 50 * TON_UNIT);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetSequencerList() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _registerSequencer(sequencer2, layer2_2, COMMISSION_10_PERCENT);

        address[] memory list = staking.getSequencerList();
        assertEq(list.length, 2);
        assertEq(list[0], sequencer1);
        assertEq(list[1], sequencer2);
    }

    function test_GetSequencerList_ExcludesDeregistered() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _registerSequencer(sequencer2, layer2_2, COMMISSION_10_PERCENT);

        vm.prank(sequencer1);
        staking.deregisterSequencer();

        address[] memory list = staking.getSequencerList();
        assertEq(list.length, 1);
        assertEq(list[0], sequencer2);
    }

    /*//////////////////////////////////////////////////////////////
                           ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_SetUnbondingPeriod() public {
        vm.prank(owner);
        staking.setUnbondingPeriod(14 days);

        assertEq(staking.unbondingPeriod(), 14 days);
    }

    function test_RevertWhen_SetUnbondingPeriodNotOwner() public {
        vm.prank(delegator1);
        vm.expectRevert();
        staking.setUnbondingPeriod(14 days);
    }

    function test_EmergencyWithdraw() public {
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);
        _stake(delegator1, sequencer1, 100 * TON_UNIT);

        uint256 stuckAmount = 50 * TON_UNIT;

        vm.prank(owner);
        staking.emergencyWithdraw(address(ton), owner, stuckAmount);

        assertEq(ton.balanceOf(owner), stuckAmount);
    }

    /*//////////////////////////////////////////////////////////////
                         INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FullLifecycle() public {
        // 1. Register sequencer
        _registerSequencer(sequencer1, layer2_1, COMMISSION_10_PERCENT);

        // 2. Multiple delegators stake
        _stake(delegator1, sequencer1, 100 * TON_UNIT);
        _stake(delegator2, sequencer1, 200 * TON_UNIT);

        // 3. Sequencer distributes rewards
        vm.prank(sequencer1);
        staking.receiveReward(30 * WTON_UNIT);

        // 4. delegator1 claims rewards
        uint256 d1BalanceBefore = wton.balanceOf(delegator1);
        vm.prank(delegator1);
        staking.claimRewards(sequencer1);
        uint256 d1BalanceAfter = wton.balanceOf(delegator1);
        // Commission: 3 WTON, Distributed: 27 WTON
        // delegator1: 27 * 1/3 = 9 WTON
        assertEq(d1BalanceAfter - d1BalanceBefore, 9 * WTON_UNIT);

        // 5. delegator1 unstakes
        vm.prank(delegator1);
        staking.unstake(sequencer1, 100 * TON_UNIT);

        // 6. More rewards come in (only delegator2 should get them)
        vm.prank(sequencer1);
        staking.receiveReward(20 * WTON_UNIT);

        // 7. delegator2 claims
        uint256 d2BalanceBefore = wton.balanceOf(delegator2);
        vm.prank(delegator2);
        staking.claimRewards(sequencer1);
        uint256 d2BalanceAfter = wton.balanceOf(delegator2);
        // First round: 27 * 2/3 = 18 WTON
        // Second round: 20 - 2 (commission) = 18 WTON (all goes to delegator2)
        assertEq(d2BalanceAfter - d2BalanceBefore, 36 * WTON_UNIT);

        // 8. delegator1 withdraws after unbonding
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        uint256 d1TonBefore = ton.balanceOf(delegator1);
        vm.prank(delegator1);
        staking.withdraw(sequencer1);
        uint256 d1TonAfter = ton.balanceOf(delegator1);
        assertEq(d1TonAfter - d1TonBefore, 100 * TON_UNIT);

        // 9. Sequencer claims commission
        uint256 seqBalanceBefore = wton.balanceOf(sequencer1);
        vm.prank(sequencer1);
        staking.claimCommission();
        uint256 seqBalanceAfter = wton.balanceOf(sequencer1);
        // Total commission: 3 + 2 = 5 WTON
        assertEq(seqBalanceAfter - seqBalanceBefore, 5 * WTON_UNIT);
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

    function _registerSequencer(
        address sequencer,
        address layer2,
        uint256 commission
    ) internal {
        vm.prank(sequencer);
        staking.registerSequencer(layer2, commission);
    }

    function _stake(
        address delegator,
        address sequencer,
        uint256 amount
    ) internal {
        vm.prank(delegator);
        staking.stake(sequencer, amount);
    }
}
