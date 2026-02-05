// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DelegateStakingV3Upgradeable} from "../contracts/DelegateStakingV3Upgradeable.sol";
import {IDelegateStakingV3} from "../contracts/interfaces/IDelegateStakingV3.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MockWTON} from "./mocks/WTONMock.sol";
import {MockSeigManagerV3} from "./mocks/MockSeigManagerV3.sol";
import {MockLayer2ManagerV3} from "./mocks/MockLayer2ManagerV3.sol";
import {MockOperatorManagerV3} from "./mocks/MockOperatorManagerV3.sol";

/**
 * @title DelegateStakingV3UpgradeableTest
 * @notice Tests for the upgradeable version of DelegateStakingV3
 */
contract DelegateStakingV3UpgradeableTest is Test {
    DelegateStakingV3Upgradeable public implementation;
    ERC1967Proxy public proxy;
    DelegateStakingV3Upgradeable public staking;

    ERC20Mock public ton;
    MockWTON public wton;
    MockSeigManagerV3 public seigManager;
    MockLayer2ManagerV3 public layer2Manager;

    address public owner;
    address public user1;
    address public user2;
    address public sequencer1;
    address public layer2_1;
    address public operatorManager1;

    uint256 public constant INITIAL_BALANCE = 1_000_000 ether;
    uint256 public constant UNBONDING_PERIOD = 7 days;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        sequencer1 = makeAddr("sequencer1");
        layer2_1 = makeAddr("layer2_1");

        vm.startPrank(owner);

        // Deploy tokens
        ton = new ERC20Mock("TON", "TON");
        wton = new MockWTON();
        wton.setTON(address(ton));

        // Deploy V3 infrastructure
        seigManager = new MockSeigManagerV3(address(ton), address(wton));
        layer2Manager = new MockLayer2ManagerV3(address(ton), address(wton));
        seigManager.setLayer2Manager(address(layer2Manager));
        layer2Manager.setSeigManager(address(seigManager));

        // Register L2 and get operator manager
        operatorManager1 = layer2Manager.registerLayer2(layer2_1, sequencer1);

        // Deploy implementation
        implementation = new DelegateStakingV3Upgradeable();

        // Deploy proxy with initialization
        bytes memory initData = abi.encodeCall(
            DelegateStakingV3Upgradeable.initialize,
            (address(ton), address(wton), address(seigManager), address(layer2Manager), UNBONDING_PERIOD, owner)
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        staking = DelegateStakingV3Upgradeable(address(proxy));

        // Mint tokens
        ton.mint(user1, INITIAL_BALANCE);
        ton.mint(user2, INITIAL_BALANCE);
        wton.mint(address(seigManager), INITIAL_BALANCE * 1e9);
        wton.mint(operatorManager1, INITIAL_BALANCE * 1e9);
        MockOperatorManagerV3(operatorManager1).mockSetPendingRewards(INITIAL_BALANCE * 1e9);

        // Authorize staking contract
        vm.stopPrank();

        vm.prank(sequencer1);
        MockOperatorManagerV3(operatorManager1).authorizeClaimer(address(staking));
    }

    /*//////////////////////////////////////////////////////////////
                        INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Initialize_Success() public view {
        assertEq(address(staking.ton()), address(ton));
        assertEq(address(staking.wton()), address(wton));
        assertEq(staking.seigManager(), address(seigManager));
        assertEq(staking.layer2Manager(), address(layer2Manager));
        assertEq(staking.unbondingPeriod(), UNBONDING_PERIOD);
        assertEq(staking.owner(), owner);
        assertEq(staking.version(), "1.3.0");
        assertEq(staking.minStakeAmount(), 100 ether); // DEFAULT_MIN_STAKE
    }

    function test_Initialize_CannotReinitialize() public {
        vm.expectRevert();
        staking.initialize(address(ton), address(wton), address(seigManager), address(layer2Manager), UNBONDING_PERIOD, owner);
    }

    function test_Initialize_ZeroAddressReverts() public {
        DelegateStakingV3Upgradeable newImpl = new DelegateStakingV3Upgradeable();

        bytes memory initData = abi.encodeCall(
            DelegateStakingV3Upgradeable.initialize,
            (address(0), address(wton), address(seigManager), address(layer2Manager), UNBONDING_PERIOD, owner)
        );

        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        new ERC1967Proxy(address(newImpl), initData);
    }

    /*//////////////////////////////////////////////////////////////
                          PAUSABLE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Pause_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        staking.pause();
    }

    function test_Pause_Success() public {
        vm.prank(owner);
        staking.pause();
        assertTrue(staking.paused());
    }

    function test_Unpause_Success() public {
        vm.startPrank(owner);
        staking.pause();
        staking.unpause();
        vm.stopPrank();
        assertFalse(staking.paused());
    }

    function test_Stake_RevertsWhenPaused() public {
        // Setup
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);

        // Pause
        vm.prank(owner);
        staking.pause();

        // Try to stake
        vm.prank(user1);
        vm.expectRevert();
        staking.stake(sequencer1, 1000 ether);
    }

    function test_Unstake_RevertsWhenPaused() public {
        // Setup and stake
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Pause
        vm.prank(owner);
        staking.pause();

        // Try to unstake
        vm.prank(user1);
        vm.expectRevert();
        staking.unstake(sequencer1, 500 ether);
    }

    function test_ClaimRewards_RevertsWhenPaused() public {
        // Setup and stake
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Pause
        vm.prank(owner);
        staking.pause();

        // Try to claim
        vm.prank(user1);
        vm.expectRevert();
        staking.claimRewards(sequencer1);
    }

    function test_EmergencyWithdraw_WorksWhenPaused() public {
        // Setup and stake
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Activate emergency
        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        // Pause
        vm.prank(owner);
        staking.pause();

        // Fast forward past cooldown
        vm.warp(block.timestamp + 3 days + 1);

        // Emergency withdraw should still work (no whenNotPaused modifier)
        vm.prank(user1);
        staking.emergencyWithdraw(sequencer1);

        assertEq(ton.balanceOf(user1), INITIAL_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                          UPGRADE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_OnlyOwner() public {
        DelegateStakingV3Upgradeable newImpl = new DelegateStakingV3Upgradeable();

        vm.prank(user1);
        vm.expectRevert();
        staking.upgradeToAndCall(address(newImpl), "");
    }

    function test_Upgrade_Success() public {
        // Register sequencer and stake before upgrade
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        uint256 stakedBefore = staking.getTotalStaked();

        // Deploy new implementation
        DelegateStakingV3Upgradeable newImpl = new DelegateStakingV3Upgradeable();

        // Upgrade
        vm.prank(owner);
        staking.upgradeToAndCall(address(newImpl), "");

        // Verify state persisted
        assertEq(staking.getTotalStaked(), stakedBefore);
        assertEq(staking.version(), "1.3.0");
    }

    function test_Upgrade_WithReinitialization() public {
        // This is an example of how to use reinitializer for future upgrades
        // The current version doesn't need it, but shows the pattern

        uint256 totalStakedBefore = staking.getTotalStaked();

        // Deploy new implementation (in practice, this would be a V2 with reinitializer)
        DelegateStakingV3Upgradeable newImpl = new DelegateStakingV3Upgradeable();

        // Upgrade without calling any init function
        vm.prank(owner);
        staking.upgradeToAndCall(address(newImpl), "");

        // State should be preserved
        assertEq(staking.getTotalStaked(), totalStakedBefore);
    }

    /*//////////////////////////////////////////////////////////////
                   COMMISSION TIMELOCK TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CommissionTimelock_RequestAndApply() public {
        // Register sequencer
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000); // 10%

        // Request commission update
        vm.prank(sequencer1);
        staking.requestCommissionUpdate(2000); // 20%

        // Check pending commission
        (uint256 newCommission, uint256 effectiveTime) = staking.getPendingCommission(sequencer1);
        assertEq(newCommission, 2000);
        assertEq(effectiveTime, block.timestamp + 7 days);

        // Try to apply before timelock - should fail
        vm.prank(sequencer1);
        vm.expectRevert(DelegateStakingV3Upgradeable.CommissionTimelockNotElapsed.selector);
        staking.applyCommissionUpdate();

        // Fast forward past timelock
        vm.warp(block.timestamp + 7 days + 1);

        // Apply commission update
        vm.prank(sequencer1);
        staking.applyCommissionUpdate();

        // Verify commission updated
        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.commission, 2000);
    }

    function test_CommissionTimelock_Cancel() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.requestCommissionUpdate(2000);

        // Cancel the update
        vm.prank(sequencer1);
        staking.cancelCommissionUpdate();

        // Verify pending is cleared
        (uint256 newCommission, uint256 effectiveTime) = staking.getPendingCommission(sequencer1);
        assertEq(newCommission, 0);
        assertEq(effectiveTime, 0);

        // Commission should remain unchanged
        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.commission, 1000);
    }

    function test_CommissionTimelock_RevertIfNoPending() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        vm.expectRevert(DelegateStakingV3Upgradeable.NoPendingCommission.selector);
        staking.applyCommissionUpdate();
    }

    /*//////////////////////////////////////////////////////////////
                    MINIMUM STAKE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MinStake_RevertIfBelowMinimum() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);

        // Try to stake below minimum (99 TON < 100 TON)
        vm.expectRevert(DelegateStakingV3Upgradeable.BelowMinimumStake.selector);
        staking.stake(sequencer1, 99 ether);
        vm.stopPrank();
    }

    function test_MinStake_SuccessAtMinimum() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);

        // Stake exactly minimum (100 TON)
        staking.stake(sequencer1, 100 ether);
        vm.stopPrank();

        assertEq(staking.getTotalStaked(), 100 ether);
    }

    function test_MinStake_AdditionBelowMinimumAllowed() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);

        // Initial stake at minimum
        staking.stake(sequencer1, 100 ether);

        // Additional stake below minimum should work
        staking.stake(sequencer1, 1 ether);
        vm.stopPrank();

        assertEq(staking.getTotalStaked(), 101 ether);
    }

    function test_SetMinStakeAmount() public {
        vm.prank(owner);
        staking.setMinStakeAmount(200 ether);

        assertEq(staking.minStakeAmount(), 200 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    FLASH LOAN PROTECTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FlashLoanProtection_CooldownRequired() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        // Try to claim immediately - should fail
        vm.expectRevert(DelegateStakingV3Upgradeable.StakeCooldownNotElapsed.selector);
        staking.claimRewards(sequencer1);
        vm.stopPrank();
    }

    function test_FlashLoanProtection_ClaimAfterCooldown() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Trigger seigniorage to create rewards
        vm.prank(user2);
        staking.triggerSeigniorage(sequencer1);

        // Fast forward past cooldown (12 seconds)
        vm.warp(block.timestamp + 13 seconds);

        // Now claim should work
        vm.prank(user1);
        staking.claimRewards(sequencer1);
    }

    function test_FlashLoanProtection_UnstakeClaimsWithoutCooldown() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Trigger seigniorage
        vm.prank(user2);
        staking.triggerSeigniorage(sequencer1);

        // Unstake should work immediately and auto-claim rewards
        // (internal claim doesn't check cooldown)
        vm.prank(user1);
        staking.unstake(sequencer1, 500 ether);
    }

    /*//////////////////////////////////////////////////////////////
               EMERGENCY WITHDRAW WITH REWARDS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_EmergencyWithdraw_ClaimsRewards() public {
        // Setup
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Trigger seigniorage to create rewards
        vm.prank(user2);
        staking.triggerSeigniorage(sequencer1);

        // Check pending rewards exist
        uint256 pendingBefore = staking.pendingRewards(user1, sequencer1);
        assertGt(pendingBefore, 0);

        // Activate emergency
        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        // Fast forward past cooldown
        vm.warp(block.timestamp + 3 days + 1);

        // Record WTON balance before
        uint256 wtonBefore = wton.balanceOf(user1);

        // Emergency withdraw
        vm.prank(user1);
        staking.emergencyWithdraw(sequencer1);

        // Verify rewards were claimed
        uint256 wtonAfter = wton.balanceOf(user1);
        assertGt(wtonAfter, wtonBefore);
        assertEq(wtonAfter - wtonBefore, pendingBefore);

        // Verify TON was returned
        assertEq(ton.balanceOf(user1), INITIAL_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                      RESCUE TOKENS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RescueTokens_CannotRescueTON() public {
        // Send some TON to the contract accidentally
        vm.prank(user1);
        ton.transfer(address(staking), 100 ether);

        // Try to rescue
        vm.prank(owner);
        vm.expectRevert(DelegateStakingV3Upgradeable.CannotRescueStakingTokens.selector);
        staking.rescueTokens(address(ton), owner, 100 ether);
    }

    function test_RescueTokens_CannotRescueWTON() public {
        // Send some WTON to the contract accidentally
        wton.mint(address(staking), 100 ether * 1e9);

        // Try to rescue
        vm.prank(owner);
        vm.expectRevert(DelegateStakingV3Upgradeable.CannotRescueStakingTokens.selector);
        staking.rescueTokens(address(wton), owner, 100 ether * 1e9);
    }

    function test_RescueTokens_CanRescueOtherTokens() public {
        // Deploy a random token
        ERC20Mock randomToken = new ERC20Mock("RANDOM", "RND");
        randomToken.mint(address(staking), 100 ether);

        // Rescue should work
        vm.prank(owner);
        staking.rescueTokens(address(randomToken), owner, 100 ether);

        assertEq(randomToken.balanceOf(owner), 100 ether);
    }

    function test_RescueTokens_OnlyOwner() public {
        ERC20Mock randomToken = new ERC20Mock("RANDOM", "RND");
        randomToken.mint(address(staking), 100 ether);

        vm.prank(user1);
        vm.expectRevert();
        staking.rescueTokens(address(randomToken), user1, 100 ether);
    }

    function test_RescueTokens_ZeroAddressReverts() public {
        ERC20Mock randomToken = new ERC20Mock("RANDOM", "RND");
        randomToken.mint(address(staking), 100 ether);

        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.rescueTokens(address(randomToken), address(0), 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                      ADMIN FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetUnbondingPeriod_EmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DelegateStakingV3Upgradeable.UnbondingPeriodUpdated(UNBONDING_PERIOD, 14 days);
        staking.setUnbondingPeriod(14 days);

        assertEq(staking.unbondingPeriod(), 14 days);
    }

    function test_SetSeigManager_EmitsEvent() public {
        address newSeigManager = makeAddr("newSeigManager");

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DelegateStakingV3Upgradeable.SeigManagerUpdated(address(seigManager), newSeigManager);
        staking.setSeigManager(newSeigManager);

        assertEq(staking.seigManager(), newSeigManager);
    }

    function test_SetLayer2Manager_EmitsEvent() public {
        address newLayer2Manager = makeAddr("newLayer2Manager");

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DelegateStakingV3Upgradeable.Layer2ManagerUpdated(address(layer2Manager), newLayer2Manager);
        staking.setLayer2Manager(newLayer2Manager);

        assertEq(staking.layer2Manager(), newLayer2Manager);
    }

    /*//////////////////////////////////////////////////////////////
                    FULL E2E FLOW WITH PROXY
    //////////////////////////////////////////////////////////////*/

    function test_E2E_FullFlowThroughProxy() public {
        // 1. Register sequencer
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // 2. Enable auto-trigger
        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        // 3. User stakes
        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        assertEq(staking.getTotalStaked(), 1000 ether);

        // 4. Wait for stake cooldown (flash loan protection)
        vm.warp(block.timestamp + 13 seconds);

        // 5. Trigger seigniorage
        vm.prank(user2);
        staking.triggerSeigniorage(sequencer1);

        // 6. Check pending rewards
        uint256 pending = staking.pendingRewards(user1, sequencer1);
        assertGt(pending, 0);

        // 7. Claim rewards
        uint256 wtonBefore = wton.balanceOf(user1);
        vm.prank(user1);
        staking.claimRewards(sequencer1);
        assertGt(wton.balanceOf(user1), wtonBefore);

        // 8. Unstake
        vm.prank(user1);
        staking.unstake(sequencer1, 500 ether);

        // 9. Wait for unbonding
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        // 10. Withdraw
        uint256 tonBefore = ton.balanceOf(user1);
        vm.prank(user1);
        staking.withdraw(sequencer1);
        assertEq(ton.balanceOf(user1), tonBefore + 500 ether);

        // 11. Upgrade contract
        DelegateStakingV3Upgradeable newImpl = new DelegateStakingV3Upgradeable();
        vm.prank(owner);
        staking.upgradeToAndCall(address(newImpl), "");

        // 12. Verify state persisted after upgrade
        assertEq(staking.getTotalStaked(), 500 ether);
        assertEq(staking.version(), "1.3.0");

        // 13. Continue operations after upgrade
        vm.prank(user1);
        staking.unstake(sequencer1, 500 ether);

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        vm.prank(user1);
        staking.withdraw(sequencer1);

        assertEq(staking.getTotalStaked(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                    IMPLEMENTATION DIRECT CALL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Implementation_CannotBeInitialized() public {
        // Implementation should have initializers disabled
        vm.expectRevert();
        implementation.initialize(
            address(ton), address(wton), address(seigManager), address(layer2Manager), UNBONDING_PERIOD, owner
        );
    }

    function test_Implementation_CannotBeUsedDirectly() public {
        // Trying to use implementation directly should fail for proxy-only functions
        vm.expectRevert();
        implementation.upgradeToAndCall(address(implementation), "");
    }

    /*//////////////////////////////////////////////////////////////
                    SEQUENCER REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RegisterSequencer_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertTrue(info.isRegistered);
        assertEq(info.layer2, layer2_1);
        assertEq(info.operatorManager, operatorManager1);
        assertEq(info.commission, 1000);
    }

    function test_RegisterSequencer_RevertIfZeroLayer2() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.registerSequencer(address(0), operatorManager1, 1000);
    }

    function test_RegisterSequencer_RevertIfZeroOperatorManager() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.registerSequencer(layer2_1, address(0), 1000);
    }

    function test_RegisterSequencer_RevertIfAlreadyRegistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerAlreadyRegistered.selector);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);
    }

    function test_RegisterSequencer_RevertIfLayer2AlreadyRegistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // Try to register same layer2 with different sequencer
        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");

        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        // This should fail because layer2_1 is already registered
        vm.prank(sequencer2);
        vm.expectRevert(IDelegateStakingV3.Layer2AlreadyRegistered.selector);
        staking.registerSequencer(layer2_1, operatorManager2, 1000);
    }

    function test_RegisterSequencer_RevertIfInvalidCommission() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.InvalidCommission.selector);
        staking.registerSequencer(layer2_1, operatorManager1, 3001); // > MAX_COMMISSION
    }

    function test_RegisterSequencer_RevertIfNotOperator() public {
        address notOperator = makeAddr("notOperator");
        vm.prank(notOperator);
        vm.expectRevert(IDelegateStakingV3.InvalidOperatorManager.selector);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);
    }

    /*//////////////////////////////////////////////////////////////
                    DEREGISTER SEQUENCER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DeregisterSequencer_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.deregisterSequencer();

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertFalse(info.isRegistered);
    }

    function test_DeregisterSequencer_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.deregisterSequencer();
    }

    function test_DeregisterSequencer_RevertIfHasStakes() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.deregisterSequencer();
    }

    function test_DeregisterSequencer_TransfersCommission() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Trigger seigniorage to accumulate commission
        vm.prank(user2);
        staking.triggerSeigniorage(sequencer1);

        // Unstake all
        vm.warp(block.timestamp + 13 seconds);
        vm.prank(user1);
        staking.unstake(sequencer1, 1000 ether);

        // Get commission before deregister
        IDelegateStakingV3.SequencerInfo memory infoBefore = staking.getSequencerInfo(sequencer1);
        uint256 commissionAmount = infoBefore.totalCommission;

        uint256 wtonBefore = wton.balanceOf(sequencer1);

        // Deregister
        vm.prank(sequencer1);
        staking.deregisterSequencer();

        // Verify commission was transferred
        assertEq(wton.balanceOf(sequencer1) - wtonBefore, commissionAmount);
    }

    /*//////////////////////////////////////////////////////////////
                    COMMISSION UPDATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UpdateCommission_CallsRequestCommissionUpdate() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // updateCommission should internally call requestCommissionUpdate
        vm.prank(sequencer1);
        staking.updateCommission(2000);

        (uint256 newCommission, uint256 effectiveTime) = staking.getPendingCommission(sequencer1);
        assertEq(newCommission, 2000);
        assertGt(effectiveTime, 0);
    }

    function test_RequestCommissionUpdate_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.requestCommissionUpdate(2000);
    }

    function test_RequestCommissionUpdate_RevertIfInvalidCommission() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.InvalidCommission.selector);
        staking.requestCommissionUpdate(3001); // > MAX_COMMISSION
    }

    function test_ApplyCommissionUpdate_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.applyCommissionUpdate();
    }

    function test_CancelCommissionUpdate_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.cancelCommissionUpdate();
    }

    function test_CancelCommissionUpdate_RevertIfNoPending() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        vm.expectRevert(DelegateStakingV3Upgradeable.NoPendingCommission.selector);
        staking.cancelCommissionUpdate();
    }

    /*//////////////////////////////////////////////////////////////
                    AUTO TRIGGER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetAutoTrigger_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertTrue(info.autoTriggerEnabled);
    }

    function test_SetAutoTrigger_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.setAutoTrigger(true);
    }

    /*//////////////////////////////////////////////////////////////
                    RECEIVE REWARD TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReceiveReward_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Sequencer sends reward
        uint256 rewardAmount = 1000 ether * 1e9; // WTON
        wton.mint(sequencer1, rewardAmount);

        vm.startPrank(sequencer1);
        wton.approve(address(staking), rewardAmount);
        staking.receiveReward(rewardAmount);
        vm.stopPrank();

        // Verify rewards are pending
        uint256 pending = staking.pendingRewards(user1, sequencer1);
        assertGt(pending, 0);
    }

    function test_ReceiveReward_RevertIfZeroAmount() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.receiveReward(0);
    }

    function test_ReceiveReward_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.receiveReward(1000);
    }

    function test_ReceiveReward_WithZeroTotalStaked() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // No one has staked yet
        uint256 rewardAmount = 1000 ether * 1e9;
        wton.mint(sequencer1, rewardAmount);

        vm.startPrank(sequencer1);
        wton.approve(address(staking), rewardAmount);
        staking.receiveReward(rewardAmount);
        vm.stopPrank();

        // All goes to commission since no stakers
        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.totalCommission, rewardAmount * 1000 / 10000); // 10% commission
    }

    /*//////////////////////////////////////////////////////////////
                    CLAIM COMMISSION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ClaimCommission_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Trigger to accumulate commission
        vm.prank(user2);
        staking.triggerSeigniorage(sequencer1);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        uint256 commissionAmount = info.totalCommission;
        assertGt(commissionAmount, 0);

        uint256 wtonBefore = wton.balanceOf(sequencer1);

        vm.prank(sequencer1);
        staking.claimCommission();

        assertEq(wton.balanceOf(sequencer1) - wtonBefore, commissionAmount);
    }

    function test_ClaimCommission_RevertIfNotRegistered() public {
        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.claimCommission();
    }

    function test_ClaimCommission_RevertIfNoPending() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        vm.expectRevert(IDelegateStakingV3.NoPendingRewards.selector);
        staking.claimCommission();
    }

    /*//////////////////////////////////////////////////////////////
                    STAKE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Stake_RevertIfZeroAmount() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.stake(sequencer1, 0);
    }

    function test_Stake_RevertIfSequencerNotRegistered() public {
        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.stake(sequencer1, 1000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    UNSTAKE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Unstake_RevertIfZeroAmount() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.unstake(sequencer1, 0);
        vm.stopPrank();
    }

    function test_Unstake_RevertIfInsufficientBalance() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.unstake(sequencer1, 2000 ether);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_RevertIfNoUnstakeRequest() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.NoUnstakeRequest.selector);
        staking.withdraw(sequencer1);
        vm.stopPrank();
    }

    function test_Withdraw_RevertIfUnbondingPeriodNotElapsed() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        staking.unstake(sequencer1, 500 ether);

        vm.expectRevert(IDelegateStakingV3.UnstakingPeriodNotElapsed.selector);
        staking.withdraw(sequencer1);
        vm.stopPrank();
    }

    function test_Withdraw_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        staking.unstake(sequencer1, 500 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        uint256 tonBefore = ton.balanceOf(user1);
        vm.prank(user1);
        staking.withdraw(sequencer1);
        assertEq(ton.balanceOf(user1) - tonBefore, 500 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    REDELEGATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Redelegate_Success() public {
        // Setup two sequencers
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        // Stake to sequencer1
        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        // Redelegate to sequencer2
        staking.redelegate(sequencer1, sequencer2, 500 ether);
        vm.stopPrank();

        // Verify balances
        IDelegateStakingV3.StakeInfo memory stake1 = staking.getStakeInfo(user1, sequencer1);
        IDelegateStakingV3.StakeInfo memory stake2 = staking.getStakeInfo(user1, sequencer2);
        assertEq(stake1.amount, 500 ether);
        assertEq(stake2.amount, 500 ether);
    }

    function test_Redelegate_RevertIfZeroAmount() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.ZeroAmount.selector);
        staking.redelegate(sequencer1, sequencer2, 0);
        vm.stopPrank();
    }

    function test_Redelegate_RevertIfSameSequencer() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(DelegateStakingV3Upgradeable.CannotRedelegateToSame.selector);
        staking.redelegate(sequencer1, sequencer1, 500 ether);
        vm.stopPrank();
    }

    function test_Redelegate_RevertIfTargetNotRegistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address sequencer2 = makeAddr("sequencer2");

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.redelegate(sequencer1, sequencer2, 500 ether);
        vm.stopPrank();
    }

    function test_Redelegate_RevertIfInsufficientBalance() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.redelegate(sequencer1, sequencer2, 2000 ether);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    TRIGGER SEIGNIORAGE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TriggerSeigniorage_BySequencer() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Sequencer can trigger even without auto-trigger
        vm.prank(sequencer1);
        staking.triggerSeigniorage(sequencer1);
    }

    function test_TriggerSeigniorage_RevertIfNotRegistered() public {
        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.SequencerNotRegistered.selector);
        staking.triggerSeigniorage(sequencer1);
    }

    function test_TriggerSeigniorage_RevertIfAutoTriggerDisabled() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // Auto-trigger is disabled by default
        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.AutoTriggerDisabled.selector);
        staking.triggerSeigniorage(sequencer1);
    }

    function test_BatchTriggerSeigniorage_Success() public {
        // Setup two sequencers with auto-trigger
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);
        wton.mint(operatorManager2, INITIAL_BALANCE * 1e9);
        MockOperatorManagerV3(operatorManager2).mockSetPendingRewards(INITIAL_BALANCE * 1e9);

        vm.prank(sequencer2);
        MockOperatorManagerV3(operatorManager2).authorizeClaimer(address(staking));

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        vm.prank(sequencer2);
        staking.setAutoTrigger(true);

        // Stake to both
        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 500 ether);
        staking.stake(sequencer2, 500 ether);
        vm.stopPrank();

        // Batch trigger
        address[] memory sequencersList = new address[](2);
        sequencersList[0] = sequencer1;
        sequencersList[1] = sequencer2;

        vm.prank(user2);
        staking.batchTriggerSeigniorage(sequencersList);

        // Verify rewards for both
        assertGt(staking.pendingRewards(user1, sequencer1), 0);
        assertGt(staking.pendingRewards(user1, sequencer2), 0);
    }

    function test_BatchTriggerSeigniorage_SkipsUnregistered() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        address unregistered = makeAddr("unregistered");

        address[] memory sequencersList = new address[](2);
        sequencersList[0] = sequencer1;
        sequencersList[1] = unregistered;

        // Should not revert, just skip unregistered
        vm.prank(user2);
        staking.batchTriggerSeigniorage(sequencersList);
    }

    function test_BatchTriggerSeigniorage_SkipsAutoTriggerDisabled() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);
        // Auto-trigger disabled

        address[] memory sequencersList = new address[](1);
        sequencersList[0] = sequencer1;

        // Should not revert, just skip
        vm.prank(user2);
        staking.batchTriggerSeigniorage(sequencersList);
    }

    /*//////////////////////////////////////////////////////////////
                    EMERGENCY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ActivateEmergency_ByOwner() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertTrue(config.isActive);
    }

    function test_ActivateEmergency_ByGuardian() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address guardian = makeAddr("guardian");
        vm.prank(owner);
        staking.setLayer2Guardian(layer2_1, guardian);

        vm.prank(guardian);
        staking.activateEmergency(layer2_1);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertTrue(config.isActive);
    }

    function test_ActivateEmergency_RevertIfNotGuardian() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.NotGuardian.selector);
        staking.activateEmergency(layer2_1);
    }

    function test_ActivateEmergency_RevertIfAlreadyActive() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.EmergencyAlreadyActive.selector);
        staking.activateEmergency(layer2_1);
    }

    function test_DeactivateEmergency_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.prank(owner);
        staking.deactivateEmergency(layer2_1);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertFalse(config.isActive);
    }

    function test_DeactivateEmergency_RevertIfNotGuardian() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.NotGuardian.selector);
        staking.deactivateEmergency(layer2_1);
    }

    function test_DeactivateEmergency_RevertIfNotActive() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.EmergencyNotActive.selector);
        staking.deactivateEmergency(layer2_1);
    }

    function test_EmergencyWithdraw_RevertIfNotActive() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.EmergencyNotActive.selector);
        staking.emergencyWithdraw(sequencer1);
        vm.stopPrank();
    }

    function test_EmergencyWithdraw_RevertIfCooldownNotElapsed() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        // Try immediately without waiting for cooldown
        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.EmergencyCooldownNotElapsed.selector);
        staking.emergencyWithdraw(sequencer1);
    }

    function test_EmergencyWithdraw_RevertIfZeroBalance() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.warp(block.timestamp + 3 days + 1);

        // User has no stake
        vm.prank(user1);
        vm.expectRevert(IDelegateStakingV3.InsufficientBalance.selector);
        staking.emergencyWithdraw(sequencer1);
    }

    function test_EmergencyWithdraw_IncludesUnstakeAmount() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        staking.unstake(sequencer1, 500 ether);
        vm.stopPrank();

        vm.prank(owner);
        staking.activateEmergency(layer2_1);

        vm.warp(block.timestamp + 3 days + 1);

        uint256 tonBefore = ton.balanceOf(user1);
        vm.prank(user1);
        staking.emergencyWithdraw(sequencer1);

        // Should receive both staked and unstaked amounts
        assertEq(ton.balanceOf(user1) - tonBefore, 1000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetStakeInfo() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        IDelegateStakingV3.StakeInfo memory info = staking.getStakeInfo(user1, sequencer1);
        assertEq(info.amount, 1000 ether);
    }

    function test_GetSequencerByLayer2() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        assertEq(staking.getSequencerByLayer2(layer2_1), sequencer1);
    }

    function test_GetSequencerList_ExcludesDeregistered() public {
        // Register two sequencers
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        // Deregister sequencer1
        vm.prank(sequencer1);
        staking.deregisterSequencer();

        address[] memory activeList = staking.getSequencerList();
        assertEq(activeList.length, 1);
        assertEq(activeList[0], sequencer2);
    }

    function test_GetTotalStaked() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        assertEq(staking.getTotalStaked(), 1000 ether);
    }

    function test_PendingRewards_ZeroIfNoStake() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        assertEq(staking.pendingRewards(user1, sequencer1), 0);
    }

    function test_GetEmergencyConfig() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertFalse(config.isActive);
        assertEq(config.cooldownPeriod, 3 days);
        assertEq(config.guardian, owner);
    }

    function test_CheckLayer2Eligibility_NoSeigManager() public {
        // Create new staking with zero seigManager
        DelegateStakingV3Upgradeable impl = new DelegateStakingV3Upgradeable();
        bytes memory initData = abi.encodeCall(
            DelegateStakingV3Upgradeable.initialize,
            (address(ton), address(wton), address(0), address(layer2Manager), UNBONDING_PERIOD, owner)
        );
        ERC1967Proxy newProxy = new ERC1967Proxy(address(impl), initData);
        DelegateStakingV3Upgradeable newStaking = DelegateStakingV3Upgradeable(address(newProxy));

        (bool eligible, uint256 required, uint256 current) = newStaking.checkLayer2Eligibility(layer2_1);
        assertTrue(eligible);
        assertEq(required, 0);
        assertEq(current, 0);
    }

    function test_CheckLayer2Eligibility_WithSeigManager() public {
        // Setup mock with bridgedTON and stakedTON
        seigManager.updateBridgedTON(layer2_1, 1000 ether);
        seigManager.updateStakedTON(layer2_1, 200 ether);

        (bool eligible, uint256 required, uint256 current) = staking.checkLayer2Eligibility(layer2_1);
        // With 10% minStakingRatio: required = 1000 * 0.1 = 100 ether
        assertTrue(eligible);
        assertEq(required, 100 ether);
        assertEq(current, 200 ether);
    }

    function test_CheckLayer2Eligibility_NotEligible() public {
        // Setup mock with insufficient stake
        seigManager.updateBridgedTON(layer2_1, 1000 ether);
        seigManager.updateStakedTON(layer2_1, 50 ether); // Less than 10% of 1000

        (bool eligible, uint256 required, uint256 current) = staking.checkLayer2Eligibility(layer2_1);
        assertFalse(eligible);
        assertEq(required, 100 ether);
        assertEq(current, 50 ether);
    }

    function test_CheckLayer2Eligibility_ZeroBridged() public {
        // No bridgedTON set - should return eligible with 0 requirements
        (bool eligible, uint256 required, uint256 current) = staking.checkLayer2Eligibility(layer2_1);
        assertTrue(eligible); // 0 >= 0
        assertEq(required, 0);
        assertEq(current, 0);
    }

    function test_EstimateSeigniorage_NotRegistered() public {
        (uint256 seqReward, uint256 valReward) = staking.estimateSeigniorage(sequencer1);
        assertEq(seqReward, 0);
        assertEq(valReward, 0);
    }

    function test_EstimateSeigniorage_WithSeigManager() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // Setup mock with bridgedTON and stakedTON (must be eligible)
        seigManager.updateBridgedTON(layer2_1, 1000 ether);
        seigManager.updateStakedTON(layer2_1, 200 ether);

        // Mine some blocks to generate seigniorage
        vm.roll(block.number + 100);

        (uint256 seqReward, uint256 valReward) = staking.estimateSeigniorage(sequencer1);
        // Should have some rewards based on blocks passed
        assertGt(seqReward, 0);
        assertGt(valReward, 0);
    }

    function test_EstimateSeigniorage_ZeroBridgedTON() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // No bridgedTON - returns (0, 0)
        (uint256 seqReward, uint256 valReward) = staking.estimateSeigniorage(sequencer1);
        assertEq(seqReward, 0);
        assertEq(valReward, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetDefaultGuardian_Success() public {
        address newGuardian = makeAddr("newGuardian");

        vm.prank(owner);
        staking.setDefaultGuardian(newGuardian);

        assertEq(staking.defaultGuardian(), newGuardian);
    }

    function test_SetDefaultGuardian_RevertIfZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.setDefaultGuardian(address(0));
    }

    function test_SetLayer2Guardian_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address newGuardian = makeAddr("newGuardian");
        vm.prank(owner);
        staking.setLayer2Guardian(layer2_1, newGuardian);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertEq(config.guardian, newGuardian);
    }

    function test_SetLayer2Guardian_RevertIfZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.setLayer2Guardian(layer2_1, address(0));
    }

    function test_SetEmergencyCooldown_Success() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.setEmergencyCooldown(layer2_1, 7 days);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertEq(config.cooldownPeriod, 7 days);
    }

    function test_SetMinStakeAmount_EmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DelegateStakingV3Upgradeable.MinStakeAmountUpdated(100 ether, 200 ether);
        staking.setMinStakeAmount(200 ether);
    }

    function test_SetUnbondingPeriod_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        staking.setUnbondingPeriod(14 days);
    }

    function test_SetSeigManager_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        staking.setSeigManager(address(0));
    }

    function test_SetLayer2Manager_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        staking.setLayer2Manager(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                    PAUSED STATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RegisterSequencer_RevertsWhenPaused() public {
        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.registerSequencer(layer2_1, operatorManager1, 1000);
    }

    function test_DeregisterSequencer_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.deregisterSequencer();
    }

    function test_Redelegate_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        vm.prank(owner);
        staking.pause();

        vm.prank(user1);
        vm.expectRevert();
        staking.redelegate(sequencer1, sequencer2, 500 ether);
    }

    function test_Withdraw_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        staking.unstake(sequencer1, 500 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        vm.prank(owner);
        staking.pause();

        vm.prank(user1);
        vm.expectRevert();
        staking.withdraw(sequencer1);
    }

    function test_TriggerSeigniorage_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.setAutoTrigger(true);

        vm.prank(owner);
        staking.pause();

        vm.prank(user1);
        vm.expectRevert();
        staking.triggerSeigniorage(sequencer1);
    }

    function test_ReceiveReward_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.receiveReward(1000);
    }

    function test_ClaimCommission_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.claimCommission();
    }

    function test_SetAutoTrigger_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.setAutoTrigger(true);
    }

    function test_RequestCommissionUpdate_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.requestCommissionUpdate(2000);
    }

    function test_ApplyCommissionUpdate_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.requestCommissionUpdate(2000);

        vm.warp(block.timestamp + 7 days + 1);

        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.applyCommissionUpdate();
    }

    function test_CancelCommissionUpdate_RevertsWhenPaused() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(sequencer1);
        staking.requestCommissionUpdate(2000);

        vm.prank(owner);
        staking.pause();

        vm.prank(sequencer1);
        vm.expectRevert();
        staking.cancelCommissionUpdate();
    }

    /*//////////////////////////////////////////////////////////////
                    MEDIUM ISSUE FIX TESTS
    //////////////////////////////////////////////////////////////*/

    // Test: sequencerList removes deregistered sequencers (swap-and-pop)
    function test_SequencerListRemovesDeregistered() public {
        // Register two sequencers
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        // Verify both are in the list
        address[] memory list = staking.getSequencerList();
        assertEq(list.length, 2);

        // Deregister sequencer1
        vm.prank(sequencer1);
        staking.deregisterSequencer();

        // Verify only sequencer2 remains
        list = staking.getSequencerList();
        assertEq(list.length, 1);
        assertEq(list[0], sequencer2);
    }

    function test_GetSequencerCount() public {
        assertEq(staking.getSequencerCount(), 0);

        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        assertEq(staking.getSequencerCount(), 1);

        address sequencer2 = makeAddr("sequencer2");
        address layer2_2 = makeAddr("layer2_2");
        vm.prank(owner);
        address operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, operatorManager2, 500);

        assertEq(staking.getSequencerCount(), 2);

        // Deregister one
        vm.prank(sequencer1);
        staking.deregisterSequencer();

        assertEq(staking.getSequencerCount(), 1);
    }

    // Test: Batch size limit
    function test_BatchTriggerSeigniorage_RevertIfExceedsBatchSize() public {
        // Create array larger than MAX_BATCH_SIZE (50)
        address[] memory largeList = new address[](51);
        for (uint256 i = 0; i < 51; i++) {
            largeList[i] = makeAddr(string.concat("seq", vm.toString(i)));
        }

        vm.expectRevert(DelegateStakingV3Upgradeable.BatchSizeExceeded.selector);
        staking.batchTriggerSeigniorage(largeList);
    }

    function test_BatchTriggerSeigniorage_SuccessWithMaxBatchSize() public {
        // Create array at exactly MAX_BATCH_SIZE (50) - should work
        address[] memory maxList = new address[](50);
        for (uint256 i = 0; i < 50; i++) {
            maxList[i] = makeAddr(string.concat("seq", vm.toString(i)));
        }

        // Should not revert (will skip all since none are registered)
        staking.batchTriggerSeigniorage(maxList);
    }

    // Test: Unbonding period bounds
    function test_Initialize_RevertIfUnbondingPeriodTooLow() public {
        DelegateStakingV3Upgradeable impl = new DelegateStakingV3Upgradeable();
        bytes memory initData = abi.encodeCall(
            DelegateStakingV3Upgradeable.initialize,
            (address(ton), address(wton), address(seigManager), address(layer2Manager), 4 minutes, owner) // < 5 minutes
        );

        vm.expectRevert(DelegateStakingV3Upgradeable.UnbondingPeriodOutOfBounds.selector);
        new ERC1967Proxy(address(impl), initData);
    }

    function test_Initialize_RevertIfUnbondingPeriodTooHigh() public {
        DelegateStakingV3Upgradeable impl = new DelegateStakingV3Upgradeable();
        bytes memory initData = abi.encodeCall(
            DelegateStakingV3Upgradeable.initialize,
            (address(ton), address(wton), address(seigManager), address(layer2Manager), 31 days, owner) // > 30 days
        );

        vm.expectRevert(DelegateStakingV3Upgradeable.UnbondingPeriodOutOfBounds.selector);
        new ERC1967Proxy(address(impl), initData);
    }

    function test_SetUnbondingPeriod_RevertIfOutOfBounds() public {
        // Too low (< 5 minutes)
        vm.prank(owner);
        vm.expectRevert(DelegateStakingV3Upgradeable.UnbondingPeriodOutOfBounds.selector);
        staking.setUnbondingPeriod(4 minutes);

        // Too high (> 30 days)
        vm.prank(owner);
        vm.expectRevert(DelegateStakingV3Upgradeable.UnbondingPeriodOutOfBounds.selector);
        staking.setUnbondingPeriod(31 days);
    }

    function test_SetUnbondingPeriod_SuccessAtBounds() public {
        // At minimum (5 minutes)
        vm.prank(owner);
        staking.setUnbondingPeriod(5 minutes);
        assertEq(staking.unbondingPeriod(), 5 minutes);

        // At maximum (30 days)
        vm.prank(owner);
        staking.setUnbondingPeriod(30 days);
        assertEq(staking.unbondingPeriod(), 30 days);
    }

    // Test: New events for admin functions
    function test_SetDefaultGuardian_EmitsEvent() public {
        address newGuardian = makeAddr("newGuardian");

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DelegateStakingV3Upgradeable.DefaultGuardianUpdated(owner, newGuardian);
        staking.setDefaultGuardian(newGuardian);
    }

    function test_SetLayer2Guardian_EmitsEvent() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        address newGuardian = makeAddr("newGuardian");

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DelegateStakingV3Upgradeable.Layer2GuardianUpdated(layer2_1, owner, newGuardian);
        staking.setLayer2Guardian(layer2_1, newGuardian);
    }

    function test_SetEmergencyCooldown_EmitsEvent() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DelegateStakingV3Upgradeable.EmergencyCooldownUpdated(layer2_1, 3 days, 7 days);
        staking.setEmergencyCooldown(layer2_1, 7 days);
    }

    // Test: Withdrawn event includes sequencer
    function test_Withdrawn_EventIncludesSequencer() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        staking.unstake(sequencer1, 500 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit IDelegateStakingV3.Withdrawn(user1, sequencer1, 500 ether);
        staking.withdraw(sequencer1);
    }

    // Test: Constants are correct
    function test_Constants() public view {
        assertEq(staking.MAX_BATCH_SIZE(), 50);
        assertEq(staking.MIN_UNBONDING_PERIOD(), 5 minutes);
        assertEq(staking.MAX_UNBONDING_PERIOD(), 30 days);
    }

    /*//////////////////////////////////////////////////////////////
                      LOW PRIORITY FIX TESTS (v1.3.0)
    //////////////////////////////////////////////////////////////*/

    function test_Redelegate_RevertIfZeroAddress() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);

        vm.expectRevert(IDelegateStakingV3.ZeroAddress.selector);
        staking.redelegate(sequencer1, address(0), 500 ether);
        vm.stopPrank();
    }

    function test_RescueTokens_EmitsEvent() public {
        // Deploy a mock token
        ERC20Mock otherToken = new ERC20Mock("OTHER", "OTH");
        otherToken.mint(address(staking), 1000 ether);

        // Expect TokensRescued event
        vm.expectEmit(true, true, false, true);
        emit DelegateStakingV3Upgradeable.TokensRescued(address(otherToken), owner, 500 ether);

        vm.prank(owner);
        staking.rescueTokens(address(otherToken), owner, 500 ether);
    }

    function test_SetEmergencyCooldown_RevertIfBelowMin() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // Try to set cooldown below minimum (1 hour)
        vm.expectRevert(DelegateStakingV3Upgradeable.EmergencyCooldownOutOfBounds.selector);
        vm.prank(owner);
        staking.setEmergencyCooldown(layer2_1, 30 minutes);
    }

    function test_SetEmergencyCooldown_RevertIfAboveMax() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // Try to set cooldown above maximum (14 days)
        vm.expectRevert(DelegateStakingV3Upgradeable.EmergencyCooldownOutOfBounds.selector);
        vm.prank(owner);
        staking.setEmergencyCooldown(layer2_1, 15 days);
    }

    function test_SetEmergencyCooldown_SuccessWithinBounds() public {
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        // Set cooldown to 7 days (within bounds)
        vm.prank(owner);
        staking.setEmergencyCooldown(layer2_1, 7 days);

        IDelegateStakingV3.EmergencyConfig memory config = staking.getEmergencyConfig(layer2_1);
        assertEq(config.cooldownPeriod, 7 days);
    }

    function test_EmergencyCooldownConstants() public view {
        assertEq(staking.MIN_EMERGENCY_COOLDOWN(), 1 hours);
        assertEq(staking.MAX_EMERGENCY_COOLDOWN(), 14 days);
    }

    function test_BasisPointsUsedCorrectly() public {
        // Register sequencer with 10% commission (1000 bp)
        vm.prank(sequencer1);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);

        vm.startPrank(user1);
        ton.approve(address(staking), INITIAL_BALANCE);
        staking.stake(sequencer1, 1000 ether);
        vm.stopPrank();

        // Distribute rewards
        uint256 rewardAmount = 1000 ether;
        wton.mint(sequencer1, rewardAmount);

        vm.startPrank(sequencer1);
        wton.approve(address(staking), rewardAmount);
        staking.receiveReward(rewardAmount);
        vm.stopPrank();

        // Commission should be exactly 10% = 100 ether
        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer1);
        assertEq(info.totalCommission, 100 ether);
    }
}
