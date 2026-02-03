// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DelegateStakingV3Upgradeable} from "../contracts/DelegateStakingV3Upgradeable.sol";
import {IDelegateStakingV3} from "../contracts/interfaces/IDelegateStakingV3.sol";

/**
 * @title InteractV3Upgradeable
 * @notice Scripts for interacting with DelegateStakingV3Upgradeable on local Anvil
 * @dev Each contract is a separate interaction scenario
 *
 * Usage:
 *   # First deploy the environment
 *   forge script script/DeployLocalV3Upgradeable.s.sol --rpc-url http://localhost:8545 --broadcast
 *
 *   # Then run interactions:
 *   forge script script/InteractV3Upgradeable.s.sol:StakeTON --rpc-url http://localhost:8545 --broadcast
 *   forge script script/InteractV3Upgradeable.s.sol:ClaimRewards --rpc-url http://localhost:8545 --broadcast
 *   forge script script/InteractV3Upgradeable.s.sol:TriggerSeigniorage --rpc-url http://localhost:8545 --broadcast
 *   forge script script/InteractV3Upgradeable.s.sol:FullFlowTest --rpc-url http://localhost:8545 --broadcast
 */

// ============================================
// Shared Constants (Default Anvil deployment addresses)
// ============================================
abstract contract DeploymentAddresses {
    // These are deterministic addresses from DeployLocalV3Upgradeable
    // Update if deployment order changes
    address constant TON = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant WTON = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant SEIG_MANAGER = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    address constant LAYER2_MANAGER = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
    address constant IMPLEMENTATION = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
    address constant PROXY = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
    address constant TRIGGER = 0x0165878A594ca255338adfa4d48449f69242Eb8F;

    // Anvil default private keys
    uint256 constant DEPLOYER_PK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant SEQUENCER1_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 constant SEQUENCER2_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    uint256 constant USER1_PK = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
    uint256 constant USER2_PK = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;
}

// ============================================
// Stake TON Script
// ============================================
contract StakeTON is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address tonAddr = vm.envOr("TON", TON);
        address sequencer = vm.envOr("SEQUENCER", vm.addr(SEQUENCER1_PK));
        uint256 amount = vm.envOr("AMOUNT", uint256(1000 ether));
        uint256 privateKey = vm.envOr("PRIVATE_KEY", USER1_PK);

        address staker = vm.addr(privateKey);

        console2.log("=== Staking TON ===");
        console2.log("Staker:", staker);
        console2.log("Sequencer:", sequencer);
        console2.log("Amount:", amount / 1e18, "TON");

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);
        IERC20 ton = IERC20(tonAddr);

        uint256 balanceBefore = ton.balanceOf(staker);
        console2.log("TON Balance before:", balanceBefore / 1e18);

        vm.startBroadcast(privateKey);
        ton.approve(stakingAddr, amount);
        staking.stake(sequencer, amount);
        vm.stopBroadcast();

        IDelegateStakingV3.StakeInfo memory info = staking.getStakeInfo(staker, sequencer);
        console2.log("\nStaked successfully!");
        console2.log("New stake amount:", info.amount / 1e18, "TON");
        console2.log("Total pool:", staking.getSequencerInfo(sequencer).totalStaked / 1e18, "TON");
    }
}

// ============================================
// Trigger Seigniorage Script
// ============================================
contract TriggerSeigniorage is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address sequencer = vm.envOr("SEQUENCER", vm.addr(SEQUENCER1_PK));
        uint256 privateKey = vm.envOr("PRIVATE_KEY", USER1_PK);

        console2.log("=== Triggering Seigniorage ===");
        console2.log("Sequencer:", sequencer);

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);

        vm.startBroadcast(privateKey);
        staking.triggerSeigniorage(sequencer);
        vm.stopBroadcast();

        console2.log("Seigniorage triggered!");

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer);
        console2.log("Sequencer commission:", info.totalCommission / 1e27, "WTON");
    }
}

// ============================================
// Claim Rewards Script
// ============================================
contract ClaimRewards is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address wtonAddr = vm.envOr("WTON", WTON);
        address sequencer = vm.envOr("SEQUENCER", vm.addr(SEQUENCER1_PK));
        uint256 privateKey = vm.envOr("PRIVATE_KEY", USER1_PK);

        address staker = vm.addr(privateKey);

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);
        IERC20 wton = IERC20(wtonAddr);

        uint256 pending = staking.pendingRewards(staker, sequencer);
        uint256 wtonBefore = wton.balanceOf(staker);

        console2.log("=== Claiming Rewards ===");
        console2.log("Staker:", staker);
        console2.log("Sequencer:", sequencer);
        console2.log("Pending rewards:", pending / 1e27, "WTON");

        // Need to wait for cooldown (12 seconds after staking)
        vm.warp(block.timestamp + 13);

        vm.startBroadcast(privateKey);
        staking.claimRewards(sequencer);
        vm.stopBroadcast();

        uint256 wtonAfter = wton.balanceOf(staker);
        console2.log("\nRewards claimed!");
        console2.log("WTON received:", (wtonAfter - wtonBefore) / 1e27, "WTON");
    }
}

// ============================================
// Unstake Script
// ============================================
contract Unstake is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address sequencer = vm.envOr("SEQUENCER", vm.addr(SEQUENCER1_PK));
        uint256 amount = vm.envOr("AMOUNT", uint256(500 ether));
        uint256 privateKey = vm.envOr("PRIVATE_KEY", USER1_PK);

        address staker = vm.addr(privateKey);

        console2.log("=== Requesting Unstake ===");
        console2.log("Amount:", amount / 1e18, "TON");

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);

        vm.startBroadcast(privateKey);
        staking.unstake(sequencer, amount);
        vm.stopBroadcast();

        IDelegateStakingV3.StakeInfo memory info = staking.getStakeInfo(staker, sequencer);
        console2.log("\nUnstake requested!");
        console2.log("Remaining stake:", info.amount / 1e18, "TON");
        console2.log("Pending unstake:", info.unstakeAmount / 1e18, "TON");
        console2.log("Unlock time:", info.unstakeTime + staking.unbondingPeriod());
    }
}

// ============================================
// Withdraw Script
// ============================================
contract Withdraw is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address tonAddr = vm.envOr("TON", TON);
        address sequencer = vm.envOr("SEQUENCER", vm.addr(SEQUENCER1_PK));
        uint256 privateKey = vm.envOr("PRIVATE_KEY", USER1_PK);

        address staker = vm.addr(privateKey);

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);
        IERC20 ton = IERC20(tonAddr);

        IDelegateStakingV3.StakeInfo memory infoBefore = staking.getStakeInfo(staker, sequencer);
        uint256 tonBefore = ton.balanceOf(staker);

        console2.log("=== Withdrawing ===");
        console2.log("Pending unstake:", infoBefore.unstakeAmount / 1e18, "TON");

        // Fast forward past unbonding period
        vm.warp(block.timestamp + staking.unbondingPeriod() + 1);

        vm.startBroadcast(privateKey);
        staking.withdraw(sequencer);
        vm.stopBroadcast();

        uint256 tonAfter = ton.balanceOf(staker);
        console2.log("\nWithdrawn!");
        console2.log("TON received:", (tonAfter - tonBefore) / 1e18, "TON");
    }
}

// ============================================
// Redelegate Script
// ============================================
contract Redelegate is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address fromSequencer = vm.envOr("FROM_SEQUENCER", vm.addr(SEQUENCER1_PK));
        address toSequencer = vm.envOr("TO_SEQUENCER", vm.addr(SEQUENCER2_PK));
        uint256 amount = vm.envOr("AMOUNT", uint256(300 ether));
        uint256 privateKey = vm.envOr("PRIVATE_KEY", USER1_PK);

        address staker = vm.addr(privateKey);

        console2.log("=== Redelegating ===");
        console2.log("From:", fromSequencer);
        console2.log("To:", toSequencer);
        console2.log("Amount:", amount / 1e18, "TON");

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);

        vm.startBroadcast(privateKey);
        staking.redelegate(fromSequencer, toSequencer, amount);
        vm.stopBroadcast();

        console2.log("\nRedelegated!");
        console2.log("Stake with Seq1:", staking.getStakeInfo(staker, fromSequencer).amount / 1e18, "TON");
        console2.log("Stake with Seq2:", staking.getStakeInfo(staker, toSequencer).amount / 1e18, "TON");
    }
}

// ============================================
// Sequencer Claim Commission Script
// ============================================
contract ClaimCommission is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address wtonAddr = vm.envOr("WTON", WTON);
        uint256 privateKey = vm.envOr("PRIVATE_KEY", SEQUENCER1_PK);

        address sequencer = vm.addr(privateKey);

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);
        IERC20 wton = IERC20(wtonAddr);

        IDelegateStakingV3.SequencerInfo memory info = staking.getSequencerInfo(sequencer);
        uint256 wtonBefore = wton.balanceOf(sequencer);

        console2.log("=== Claiming Commission ===");
        console2.log("Sequencer:", sequencer);
        console2.log("Pending commission:", info.totalCommission / 1e27, "WTON");

        vm.startBroadcast(privateKey);
        staking.claimCommission();
        vm.stopBroadcast();

        uint256 wtonAfter = wton.balanceOf(sequencer);
        console2.log("\nCommission claimed!");
        console2.log("WTON received:", (wtonAfter - wtonBefore) / 1e27, "WTON");
    }
}

// ============================================
// View State Script
// ============================================
contract ViewState is Script, DeploymentAddresses {
    function run() external view {
        address stakingAddr = vm.envOr("STAKING", PROXY);

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);

        address sequencer1 = vm.addr(SEQUENCER1_PK);
        address sequencer2 = vm.addr(SEQUENCER2_PK);
        address user1 = vm.addr(USER1_PK);

        console2.log("=== Contract State ===");
        console2.log("Version:", staking.version());
        console2.log("Owner:", staking.owner());
        console2.log("Paused:", staking.paused());
        console2.log("Total Staked:", staking.getTotalStaked() / 1e18, "TON");
        console2.log("Sequencer Count:", staking.getSequencerCount());

        console2.log("\n--- Sequencer 1 ---");
        IDelegateStakingV3.SequencerInfo memory info1 = staking.getSequencerInfo(sequencer1);
        console2.log("Registered:", info1.isRegistered);
        console2.log("Commission:", info1.commission, "bp");
        console2.log("Total Staked:", info1.totalStaked / 1e18, "TON");
        console2.log("Total Commission:", info1.totalCommission / 1e27, "WTON");
        console2.log("Auto Trigger:", info1.autoTriggerEnabled);

        console2.log("\n--- Sequencer 2 ---");
        IDelegateStakingV3.SequencerInfo memory info2 = staking.getSequencerInfo(sequencer2);
        console2.log("Registered:", info2.isRegistered);
        console2.log("Commission:", info2.commission, "bp");
        console2.log("Total Staked:", info2.totalStaked / 1e18, "TON");

        console2.log("\n--- User 1 Stakes ---");
        IDelegateStakingV3.StakeInfo memory stake1 = staking.getStakeInfo(user1, sequencer1);
        console2.log("Stake with Seq1:", stake1.amount / 1e18, "TON");
        console2.log("Pending Rewards:", staking.pendingRewards(user1, sequencer1) / 1e27, "WTON");
    }
}

// ============================================
// Full Flow Test Script
// ============================================
contract FullFlowTest is Script, DeploymentAddresses {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", PROXY);
        address tonAddr = vm.envOr("TON", TON);
        address wtonAddr = vm.envOr("WTON", WTON);

        DelegateStakingV3Upgradeable staking = DelegateStakingV3Upgradeable(stakingAddr);
        IERC20 ton = IERC20(tonAddr);
        IERC20 wton = IERC20(wtonAddr);

        address sequencer1 = vm.addr(SEQUENCER1_PK);
        address user1 = vm.addr(USER1_PK);

        console2.log("====================================================================");
        console2.log("                    FULL FLOW TEST                                  ");
        console2.log("====================================================================");
        console2.log("");

        // Step 1: Check initial state
        console2.log("STEP 1: Initial State");
        console2.log("  Contract Version:", staking.version());
        console2.log("  Sequencer1 registered:", staking.getSequencerInfo(sequencer1).isRegistered);
        console2.log("  User1 TON balance:", ton.balanceOf(user1) / 1e18, "TON");
        console2.log("");

        // Step 2: User stakes
        console2.log("STEP 2: User1 Stakes 1000 TON to Sequencer1");
        vm.startBroadcast(USER1_PK);
        ton.approve(stakingAddr, 1000 ether);
        staking.stake(sequencer1, 1000 ether);
        vm.stopBroadcast();
        console2.log("  Staked:", staking.getStakeInfo(user1, sequencer1).amount / 1e18, "TON");
        console2.log("  Pool total:", staking.getSequencerInfo(sequencer1).totalStaked / 1e18, "TON");
        console2.log("");

        // Step 3: Trigger seigniorage
        console2.log("STEP 3: Trigger Seigniorage");
        vm.startBroadcast(USER1_PK);
        staking.triggerSeigniorage(sequencer1);
        vm.stopBroadcast();
        uint256 pendingRewards = staking.pendingRewards(user1, sequencer1);
        console2.log("  Pending rewards:", pendingRewards / 1e27, "WTON");
        console2.log("  Sequencer commission:", staking.getSequencerInfo(sequencer1).totalCommission / 1e27, "WTON");
        console2.log("");

        // Step 4: Wait for cooldown and claim rewards
        console2.log("STEP 4: Claim Rewards (after 12s cooldown)");
        vm.warp(block.timestamp + 13);
        uint256 wtonBefore = wton.balanceOf(user1);
        vm.startBroadcast(USER1_PK);
        staking.claimRewards(sequencer1);
        vm.stopBroadcast();
        uint256 wtonAfter = wton.balanceOf(user1);
        console2.log("  WTON received:", (wtonAfter - wtonBefore) / 1e27, "WTON");
        console2.log("");

        // Step 5: Sequencer claims commission
        console2.log("STEP 5: Sequencer1 Claims Commission");
        uint256 seqWtonBefore = wton.balanceOf(sequencer1);
        vm.startBroadcast(SEQUENCER1_PK);
        staking.claimCommission();
        vm.stopBroadcast();
        uint256 seqWtonAfter = wton.balanceOf(sequencer1);
        console2.log("  Commission received:", (seqWtonAfter - seqWtonBefore) / 1e27, "WTON");
        console2.log("");

        // Step 6: Unstake
        console2.log("STEP 6: User1 Requests Unstake 500 TON");
        vm.startBroadcast(USER1_PK);
        staking.unstake(sequencer1, 500 ether);
        vm.stopBroadcast();
        IDelegateStakingV3.StakeInfo memory stakeInfo = staking.getStakeInfo(user1, sequencer1);
        console2.log("  Remaining stake:", stakeInfo.amount / 1e18, "TON");
        console2.log("  Pending unstake:", stakeInfo.unstakeAmount / 1e18, "TON");
        console2.log("");

        // Step 7: Withdraw after unbonding
        console2.log("STEP 7: Withdraw (after unbonding period)");
        vm.warp(block.timestamp + staking.unbondingPeriod() + 1);
        uint256 tonBefore = ton.balanceOf(user1);
        vm.startBroadcast(USER1_PK);
        staking.withdraw(sequencer1);
        vm.stopBroadcast();
        uint256 tonAfterWithdraw = ton.balanceOf(user1);
        console2.log("  TON withdrawn:", (tonAfterWithdraw - tonBefore) / 1e18, "TON");
        console2.log("");

        // Final state
        console2.log("====================================================================");
        console2.log("                    FINAL STATE                                     ");
        console2.log("--------------------------------------------------------------------");
        console2.log("  User1 TON balance:", ton.balanceOf(user1) / 1e18);
        console2.log("  User1 WTON balance:", wton.balanceOf(user1) / 1e27);
        console2.log("  User1 stake:", staking.getStakeInfo(user1, sequencer1).amount / 1e18, "TON");
        console2.log("  Sequencer1 WTON:", wton.balanceOf(sequencer1) / 1e27);
        console2.log("  Total staked:", staking.getTotalStaked() / 1e18, "TON");
        console2.log("====================================================================");
    }
}
