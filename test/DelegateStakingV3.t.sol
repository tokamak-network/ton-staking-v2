// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DelegateStakingV3} from "../contracts/DelegateStakingV3.sol";
import {DelegateTrigger} from "../contracts/DelegateTrigger.sol";
import {IDelegateStakingV3} from "../contracts/interfaces/IDelegateStakingV3.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

/**
 * @title DelegateStakingV3Test
 * @notice Comprehensive test suite for DelegateStakingV3
 */
contract DelegateStakingV3Test is Test {
    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/

    DelegateStakingV3 public staking;
    DelegateTrigger public trigger;
    ERC20Mock public ton;
    ERC20Mock public wton;
    MockOperatorManager public operatorManager1;
    MockOperatorManager public operatorManager2;

    /*//////////////////////////////////////////////////////////////
                              ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public owner = makeAddr("owner");
    address public sequencer1 = makeAddr("sequencer1");
    address public sequencer2 = makeAddr("sequencer2");
    address public layer2_1 = makeAddr("layer2_1");
    address public layer2_2 = makeAddr("layer2_2");
    address public staker1 = makeAddr("staker1");
    address public staker2 = makeAddr("staker2");
    address public keeper = makeAddr("keeper");
    address public guardian = makeAddr("guardian");

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant INITIAL_BALANCE = 1_000_000 ether;
    uint256 public constant UNBONDING_PERIOD = 14 days;
    uint256 public constant DEFAULT_COMMISSION = 1000; // 10%
    uint256 public constant RAY = 1e27;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Deploy tokens
        ton = new ERC20Mock("TON", "TON");
        wton = new ERC20Mock("WTON", "WTON");

        // Deploy operator managers
        operatorManager1 = new MockOperatorManager(sequencer1, address(wton));
        operatorManager2 = new MockOperatorManager(sequencer2, address(wton));

        // Deploy staking contract
        vm.prank(owner);
        staking = new DelegateStakingV3(
            address(ton),
            address(wton),
            address(0), // No SeigManager for tests
            address(0), // No Layer2Manager for tests
            UNBONDING_PERIOD,
            owner
        );

        // Deploy trigger contract
        vm.prank(owner);
        trigger = new DelegateTrigger(address(wton), owner);

        // Setup initial balances
        ton.mint(staker1, INITIAL_BALANCE);
        ton.mint(staker2, INITIAL_BALANCE);
        wton.mint(sequencer1, INITIAL_BALANCE * RAY / 1e18);
        wton.mint(sequencer2, INITIAL_BALANCE * RAY / 1e18);
        wton.mint(address(operatorManager1), INITIAL_BALANCE * RAY / 1e18);
        wton.mint(address(operatorManager2), INITIAL_BALANCE * RAY / 1e18);

        // Approve tokens
        vm.prank(staker1);
        ton.approve(address(staking), type(uint256).max);
        vm.prank(staker2);
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
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.isRegistered, true);
        assertEq(info.layer2, layer2_1);
        assertEq(info.operatorManager, address(operatorManager1));
        assertEq(info.commission, DEFAULT_COMMISSION);
        assertEq(info.totalStaked, 0);
        assertEq(info.autoTriggerEnabled, false);
    }

    function test_RegisterSequencer_RevertIfNotOperator() public {
        address notOperator = makeAddr("notOperator");

        vm.prank(notOperator);
        vm.expectRevert(IDelegateStakingV3.InvalidOperatorManager.selector);
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);
    }

    function test_RegisterSequencer_RevertIfAlreadyRegistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerAlreadyRegistered.selector);
        staking.registerSequencer(layer2_2, address(operatorManager1), DEFAULT_COMMISSION);
    }

    function test_RegisterSequencer_RevertIfLayer2AlreadyRegistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);

        vm.prank(sequencer2);
        vm.expectRevert(IDelegateStakingV3.Layer2AlreadyRegistered.selector);
        staking.registerSequencer(layer2_1, address(operatorManager2), DEFAULT_COMMISSION);
    }

    function test_RegisterSequencer_RevertIfInvalidCommission() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.InvalidCommission.selector);
        staking.registerSequencer(layer2_1, address(operatorManager1), 3001);
    }

    function test_DeregisterSequencer() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);

        vm.prank(sequencer1);
        staking.deregisterSequencer();

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.isRegistered, false);
    }

    function test_UpdateCommission() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);

        vm.prank(sequencer1);
        staking.updateCommission(2000);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.commission, 2000);
    }

    function test_SetAutoTrigger() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.autoTriggerEnabled, true);
    }

    /*//////////////////////////////////////////////////////////////
                          STAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Stake() public {
        _registerSequencer1();

        uint256 stakeAmount = 1000 ether;

        vm.prank(staker1);
        staking.stake(sequencer1, stakeAmount);

        IDelegateStakingV3.StakeInfo memory stakeInfo = staking.getStakeInfo(staker1, sequencer1);
        assertEq(stakeInfo.amount, stakeAmount);

        IDelegateStakingV3.SequencerInfo memory seqInfo = staking.getSequencerInfo(sequencer1);
        assertEq(seqInfo.totalStaked, stakeAmount);

        assertEq(staking.getTotalStaked(), stakeAmount);
    }

    function test_Stake_MultipleStakers() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker2);
        staking.stake(sequencer1, 2000 ether);

        assertEq(staking.getTotalStaked(), 3000 ether);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.totalStaked, 3000 ether);
    }

    function test_Stake_RevertIfZeroAmount() public {
        _registerSequencer1();

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.stake(sequencer1, 0);
    }

    function test_Stake_RevertIfSequencerNotRegistered() public {
        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.stake(sequencer1, 1000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          UNSTAKE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Unstake() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        staking.unstake(sequencer1, 500 ether);

        IDelegateStakingV3.StakeInfo memory info = staking.getStakeInfo(staker1, sequencer1);
        assertEq(info.amount, 500 ether);
        assertEq(info.unstakeAmount, 500 ether);
        assertEq(info.unstakeTime, block.timestamp);
    }

    function test_Unstake_RevertIfInsufficientBalance() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.unstake(sequencer1, 1001 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        staking.unstake(sequencer1, 500 ether);

        // Fast forward past unbonding period
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        uint256 balanceBefore = ton.balanceOf(staker1);

        vm.prank(staker1);
        staking.withdraw(sequencer1);

        assertEq(ton.balanceOf(staker1), balanceBefore + 500 ether);

        IDelegateStakingV3.StakeInfo memory info = staking.getStakeInfo(staker1, sequencer1);
        assertEq(info.unstakeAmount, 0);
        assertEq(info.unstakeTime, 0);
    }

    function test_Withdraw_RevertIfPeriodNotElapsed() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        staking.unstake(sequencer1, 500 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.UnstakingPeriodNotElapsed.selector);
        staking.withdraw(sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                          REWARD TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReceiveReward() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        uint256 rewardAmount = 100 * RAY / 1e18; // 100 WTON in RAY units

        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);

        // Commission: 10% of 100 = 10 WTON
        uint256 expectedCommission = rewardAmount * DEFAULT_COMMISSION / 10000;
        assertEq(info.totalCommission, expectedCommission);
    }

    function test_ClaimRewards() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        uint256 rewardAmount = 100 * RAY / 1e18;

        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        uint256 pending = staking.pendingRewards(staker1, sequencer1);
        assertGt(pending, 0);

        uint256 balanceBefore = wton.balanceOf(staker1);

        vm.prank(staker1);
        staking.claimRewards(sequencer1);

        assertEq(wton.balanceOf(staker1), balanceBefore + pending);
    }

    function test_ClaimCommission() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        uint256 rewardAmount = 100 * RAY / 1e18;

        vm.prank(sequencer1);
        staking.receiveReward(rewardAmount);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        uint256 commission = info.totalCommission;

        uint256 balanceBefore = wton.balanceOf(sequencer1);

        vm.prank(sequencer1);
        staking.claimCommission();

        assertEq(wton.balanceOf(sequencer1), balanceBefore + commission);
    }

    /*//////////////////////////////////////////////////////////////
                        REDELEGATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Redelegate() public {
        _registerSequencer1();
        _registerSequencer2();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        staking.redelegate(sequencer1, sequencer2, 500 ether);

        IDelegateStakingV3.StakeInfo memory info1 = staking.getStakeInfo(staker1, sequencer1);
        IDelegateStakingV3.StakeInfo memory info2 = staking.getStakeInfo(staker1, sequencer2);

        assertEq(info1.amount, 500 ether);
        assertEq(info2.amount, 500 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ActivateEmergency() public {
        _registerSequencer1();

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertEq(config.isActive, true);
        assertEq(config.activationTime, block.timestamp);
    }

    function test_EmergencyWithdraw() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        // Activate emergency
        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        // Wait for cooldown
        vm.warp(block.timestamp + 3 days + 1);

        uint256 balanceBefore = ton.balanceOf(staker1);

        vm.prank(staker1);
        staking.emergencyWithdraw(sequencer1);

        assertEq(ton.balanceOf(staker1), balanceBefore + 1000 ether);
    }

    function test_EmergencyWithdraw_RevertIfNotActive() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.EmergencyNotActive.selector);
        staking.emergencyWithdraw(sequencer1);
    }

    function test_EmergencyWithdraw_RevertIfCooldownNotElapsed() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.prank(staker1);
        vm.expectRevert(IDelegateStakingV3.EmergencyCooldownNotElapsed.selector);
        staking.emergencyWithdraw(sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                        TRIGGER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TriggerSeigniorage_BySequencer() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        // Sequencer can always trigger
        vm.prank(sequencer1);
        staking.triggerSeigniorage(sequencer1);
    }

    function test_TriggerSeigniorage_ByAnyone_WhenAutoEnabled() public {
        _registerSequencer1();

        vm.prank(staker1);
        staking.stake(sequencer1, 1000 ether);

        // Enable auto trigger
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        // Anyone can trigger
        vm.prank(keeper);
        staking.triggerSeigniorage(sequencer1);
    }

    function test_TriggerSeigniorage_RevertIfAutoDisabled() public {
        _registerSequencer1();

        // Auto trigger disabled by default
        vm.prank(keeper);
        vm.expectRevert(IDelegateStakingV3.AutoTriggerDisabled.selector);
        staking.triggerSeigniorage(sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetUnbondingPeriod() public {
        vm.prank(owner);
        staking.setUnbondingPeriod(7 days);

        assertEq(staking.unbondingPeriod(), 7 days);
    }

    function test_SetDefaultGuardian() public {
        vm.prank(owner);
        staking.setDefaultGuardian(guardian);

        assertEq(staking.defaultGuardian(), guardian);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetSequencerList() public {
        _registerSequencer1();
        _registerSequencer2();

        address[] memory list = staking.getSequencerList();
        assertEq(list.length, 2);
        assertEq(list[0], sequencer1);
        assertEq(list[1], sequencer2);
    }

    function test_GetSequencerByLayer2() public {
        _registerSequencer1();

        address result = staking.getSequencerByLayer2(layer2_1);
        assertEq(result, sequencer1);
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _registerSequencer1() internal {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, address(operatorManager1), DEFAULT_COMMISSION);
    }

    function _registerSequencer2() internal {
        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, address(operatorManager2), DEFAULT_COMMISSION);
    }
}

/*//////////////////////////////////////////////////////////////
                        MOCK CONTRACTS
//////////////////////////////////////////////////////////////*/

/**
 * @notice Mock OperatorManager for testing
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
        // Mock: transfer tokens to caller
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 transferAmount = amount > balance ? balance : amount;
        if (transferAmount > 0) {
            IERC20(token).transfer(msg.sender, transferAmount);
        }
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}
