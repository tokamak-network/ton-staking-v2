// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {DelegateStakingV3Upgradeable} from "../../contracts/DelegateStakingV3Upgradeable.sol";
import {IDelegateStakingV3} from "../../contracts/interfaces/IDelegateStakingV3.sol";

/**
 * @title ForkTest
 * @notice Integration tests using mainnet fork
 * @dev Run with: forge test --match-contract ForkTest --fork-url $MAINNET_RPC_URL -vvv
 *
 * These tests verify the contract works correctly with:
 * 1. Real TON/WTON tokens
 * 2. Real V3 contracts (SeigManager, OperatorManager, Layer2Manager)
 *
 * Prerequisites:
 * - MAINNET_RPC_URL environment variable set
 * - V3 contracts deployed on mainnet (update addresses when available)
 */
contract ForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                            MAINNET ADDRESSES
    //////////////////////////////////////////////////////////////*/

    // Token addresses (confirmed mainnet)
    address constant TON = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;

    // V3 Contract addresses - UPDATE WHEN DEPLOYED
    // These are placeholder addresses that should be updated when V3 is deployed
    address constant SEIG_MANAGER_V3 = address(0); // TODO: Update when V3 deployed
    address constant LAYER2_MANAGER_V3 = address(0); // TODO: Update when V3 deployed

    // Known accounts with TON balance for testing
    address constant TON_WHALE = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5; // TON contract itself has balance

    /*//////////////////////////////////////////////////////////////
                              STATE
    //////////////////////////////////////////////////////////////*/

    DelegateStakingV3Upgradeable public staking;
    address public proxy;

    address public owner;
    address public sequencer;
    address public user1;
    address public user2;

    uint256 constant INITIAL_TON = 10000 ether;
    uint256 constant UNBONDING_PERIOD = 7 days;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier skipIfNoFork() {
        // Skip if not running with fork
        if (block.chainid != 1) {
            vm.skip(true);
        }
        _;
    }

    modifier skipIfV3NotDeployed() {
        if (SEIG_MANAGER_V3 == address(0) || LAYER2_MANAGER_V3 == address(0)) {
            vm.skip(true);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Only run setup if on mainnet fork
        if (block.chainid != 1) return;

        // Setup accounts
        owner = makeAddr("owner");
        sequencer = makeAddr("sequencer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy implementation
        DelegateStakingV3Upgradeable implementation = new DelegateStakingV3Upgradeable();

        // Deploy proxy with initialization
        bytes memory initData = abi.encodeWithSelector(
            DelegateStakingV3Upgradeable.initialize.selector,
            TON,
            WTON,
            SEIG_MANAGER_V3, // Can be address(0) initially
            LAYER2_MANAGER_V3, // Can be address(0) initially
            UNBONDING_PERIOD,
            owner
        );

        proxy = address(new ERC1967Proxy(address(implementation), initData));
        staking = DelegateStakingV3Upgradeable(proxy);

        // Fund test accounts with TON
        _fundWithTON(user1, INITIAL_TON);
        _fundWithTON(user2, INITIAL_TON);
    }

    function _fundWithTON(address account, uint256 amount) internal {
        // Deal TON to account (works with fork)
        deal(TON, account, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        BASIC FORK TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_TokenAddressesCorrect() public skipIfNoFork {
        // Verify TON token address
        assertEq(address(staking.ton()), TON);

        // Verify WTON token address
        assertEq(address(staking.wton()), WTON);

        // Verify tokens are valid ERC20 (have balanceOf)
        uint256 tonSupply = IERC20(TON).balanceOf(TON);
        assertGt(tonSupply, 0);
    }

    function test_Fork_InitialState() public skipIfNoFork {
        assertEq(staking.owner(), owner);
        assertEq(staking.unbondingPeriod(), UNBONDING_PERIOD);
        assertEq(staking.version(), "1.3.0");
        assertEq(staking.getTotalStaked(), 0);
        assertEq(staking.getSequencerCount(), 0);
    }

    function test_Fork_UserHasTON() public skipIfNoFork {
        uint256 balance = IERC20(TON).balanceOf(user1);
        assertEq(balance, INITIAL_TON);
    }

    /*//////////////////////////////////////////////////////////////
                    STAKING FLOW TESTS (NO V3)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test basic staking flow without V3 integration
     * @dev This test works even when V3 contracts are not deployed
     */
    function test_Fork_StakingFlow_NoV3() public skipIfNoFork {
        // Create mock addresses for sequencer registration
        address layer2 = makeAddr("layer2");
        address operatorManager = address(new MockOperatorManager(sequencer));

        // Register sequencer
        vm.prank(sequencer);
        staking.registerSequencer(layer2, operatorManager, 1000); // 10% commission

        // Verify registration
        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer);
        assertTrue(info.isRegistered);
        assertEq(info.commission, 1000);

        // User stakes TON
        vm.startPrank(user1);
        IERC20(TON).approve(address(staking), INITIAL_TON);
        staking.stake(sequencer, 1000 ether);
        vm.stopPrank();

        // Verify stake
        IDelegateStakingV3.StakeInfo memory stakeInfo = staking.getStakeInfo(user1, sequencer);
        assertEq(stakeInfo.amount, 1000 ether);
        assertEq(staking.getTotalStaked(), 1000 ether);

        // User unstakes
        vm.prank(user1);
        staking.unstake(sequencer, 500 ether);

        // Verify unstake request
        stakeInfo = staking.getStakeInfo(user1, sequencer);
        assertEq(stakeInfo.amount, 500 ether);
        assertEq(stakeInfo.unstakeAmount, 500 ether);

        // Wait for unbonding
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        // Withdraw
        uint256 balanceBefore = IERC20(TON).balanceOf(user1);
        vm.prank(user1);
        staking.withdraw(sequencer);
        uint256 balanceAfter = IERC20(TON).balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 500 ether);
    }

    /**
     * @notice Test redelegation flow
     */
    function test_Fork_Redelegation() public skipIfNoFork {
        // Setup two sequencers
        address layer2_1 = makeAddr("layer2_1");
        address layer2_2 = makeAddr("layer2_2");
        address sequencer2 = makeAddr("sequencer2");

        address opMgr1 = address(new MockOperatorManager(sequencer));
        address opMgr2 = address(new MockOperatorManager(sequencer2));

        vm.prank(sequencer);
        staking.registerSequencer(layer2_1, opMgr1, 1000);

        vm.prank(sequencer2);
        staking.registerSequencer(layer2_2, opMgr2, 500);

        // User stakes to sequencer1
        vm.startPrank(user1);
        IERC20(TON).approve(address(staking), INITIAL_TON);
        staking.stake(sequencer, 1000 ether);

        // Redelegate to sequencer2
        staking.redelegate(sequencer, sequencer2, 400 ether);
        vm.stopPrank();

        // Verify balances
        IDelegateStakingV3.StakeInfo memory info1 = staking.getStakeInfo(user1, sequencer);
        IDelegateStakingV3.StakeInfo memory info2 = staking.getStakeInfo(user1, sequencer2);

        assertEq(info1.amount, 600 ether);
        assertEq(info2.amount, 400 ether);
    }

    /**
     * @notice Test emergency withdrawal
     */
    function test_Fork_EmergencyWithdraw() public skipIfNoFork {
        address layer2 = makeAddr("layer2");
        address opMgr = address(new MockOperatorManager(sequencer));

        vm.prank(sequencer);
        staking.registerSequencer(layer2, opMgr, 1000);

        // User stakes
        vm.startPrank(user1);
        IERC20(TON).approve(address(staking), INITIAL_TON);
        staking.stake(sequencer, 1000 ether);
        vm.stopPrank();

        // Owner activates emergency
        vm.prank(owner);
        staking.activateEmergency(layer2);

        // Wait for cooldown
        vm.warp(block.timestamp + 3 days + 1);

        // Emergency withdraw
        uint256 balanceBefore = IERC20(TON).balanceOf(user1);
        vm.prank(user1);
        staking.emergencyWithdraw(sequencer);
        uint256 balanceAfter = IERC20(TON).balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 1000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                      V3 INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test V3 eligibility check
     * @dev Only runs when V3 contracts are deployed
     */
    function test_Fork_V3_CheckEligibility() public skipIfNoFork skipIfV3NotDeployed {
        address layer2 = makeAddr("layer2");

        (bool eligible, uint256 required, uint256 current) = staking.checkLayer2Eligibility(layer2);

        // Just verify it doesn't revert and returns data
        // Actual values depend on V3 state
        assertGe(required, 0);
        assertGe(current, 0);
    }

    /**
     * @notice Test V3 seigniorage estimation
     * @dev Only runs when V3 contracts are deployed
     */
    function test_Fork_V3_EstimateSeigniorage() public skipIfNoFork skipIfV3NotDeployed {
        address layer2 = makeAddr("layer2");
        address opMgr = address(new MockOperatorManager(sequencer));

        vm.prank(sequencer);
        staking.registerSequencer(layer2, opMgr, 1000);

        (uint256 seqReward, uint256 valReward) = staking.estimateSeigniorage(sequencer);

        // Verify it returns without reverting
        assertGe(seqReward, 0);
        assertGe(valReward, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Admin_SetV3Addresses() public skipIfNoFork {
        address newSeigManager = makeAddr("newSeigManager");
        address newLayer2Manager = makeAddr("newLayer2Manager");

        vm.startPrank(owner);
        staking.setSeigManager(newSeigManager);
        staking.setLayer2Manager(newLayer2Manager);
        vm.stopPrank();

        assertEq(staking.seigManager(), newSeigManager);
        assertEq(staking.layer2Manager(), newLayer2Manager);
    }

    function test_Fork_Admin_PauseUnpause() public skipIfNoFork {
        vm.prank(owner);
        staking.pause();
        assertTrue(staking.paused());

        vm.prank(owner);
        staking.unpause();
        assertFalse(staking.paused());
    }

    /*//////////////////////////////////////////////////////////////
                        UPGRADE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Upgrade() public skipIfNoFork {
        // Deploy new implementation
        DelegateStakingV3Upgradeable newImpl = new DelegateStakingV3Upgradeable();

        // Store state before upgrade
        uint256 totalStakedBefore = staking.getTotalStaked();
        address ownerBefore = staking.owner();

        // Upgrade
        vm.prank(owner);
        staking.upgradeToAndCall(address(newImpl), "");

        // Verify state preserved
        assertEq(staking.getTotalStaked(), totalStakedBefore);
        assertEq(staking.owner(), ownerBefore);
        assertEq(staking.version(), "1.3.0");
    }

    /*//////////////////////////////////////////////////////////////
                    GAS BENCHMARKS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_GasBenchmark_Stake() public skipIfNoFork {
        address layer2 = makeAddr("layer2");
        address opMgr = address(new MockOperatorManager(sequencer));

        vm.prank(sequencer);
        staking.registerSequencer(layer2, opMgr, 1000);

        vm.startPrank(user1);
        IERC20(TON).approve(address(staking), INITIAL_TON);

        uint256 gasBefore = gasleft();
        staking.stake(sequencer, 1000 ether);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for stake()", gasUsed);
        vm.stopPrank();
    }

    function test_Fork_GasBenchmark_ClaimRewards() public skipIfNoFork {
        address layer2 = makeAddr("layer2");
        address opMgr = address(new MockOperatorManager(sequencer));

        vm.prank(sequencer);
        staking.registerSequencer(layer2, opMgr, 1000);

        vm.startPrank(user1);
        IERC20(TON).approve(address(staking), INITIAL_TON);
        staking.stake(sequencer, 1000 ether);

        // Wait for cooldown
        vm.warp(block.timestamp + 13);

        uint256 gasBefore = gasleft();
        staking.claimRewards(sequencer);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for claimRewards()", gasUsed);
        vm.stopPrank();
    }
}

/**
 * @notice Mock OperatorManager for testing without V3
 */
contract MockOperatorManager {
    address public operator;

    constructor(address _operator) {
        operator = _operator;
    }

    function isOperator(address account) external view returns (bool) {
        return account == operator;
    }

    function claimERC20(address, uint256) external pure returns (bool) {
        return true;
    }
}
