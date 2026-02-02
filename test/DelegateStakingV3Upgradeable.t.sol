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
        assertEq(staking.version(), "1.0.0");
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
        assertEq(staking.version(), "1.0.0");
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

        // 4. Trigger seigniorage
        vm.prank(user2);
        staking.triggerSeigniorage(sequencer1);

        // 5. Check pending rewards
        uint256 pending = staking.pendingRewards(user1, sequencer1);
        assertGt(pending, 0);

        // 6. Claim rewards
        uint256 wtonBefore = wton.balanceOf(user1);
        vm.prank(user1);
        staking.claimRewards(sequencer1);
        assertGt(wton.balanceOf(user1), wtonBefore);

        // 7. Unstake
        vm.prank(user1);
        staking.unstake(sequencer1, 500 ether);

        // 8. Wait for unbonding
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        // 9. Withdraw
        uint256 tonBefore = ton.balanceOf(user1);
        vm.prank(user1);
        staking.withdraw(sequencer1);
        assertEq(ton.balanceOf(user1), tonBefore + 500 ether);

        // 10. Upgrade contract
        DelegateStakingV3Upgradeable newImpl = new DelegateStakingV3Upgradeable();
        vm.prank(owner);
        staking.upgradeToAndCall(address(newImpl), "");

        // 11. Verify state persisted after upgrade
        assertEq(staking.getTotalStaked(), 500 ether);

        // 12. Continue operations after upgrade
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
}
