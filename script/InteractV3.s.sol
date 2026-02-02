// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DelegateStakingV3} from "../contracts/DelegateStakingV3.sol";
import {MockOperatorManagerV3} from "../test/mocks/MockOperatorManagerV3.sol";

/**
 * @title InteractV3
 * @notice Scripts for interacting with DelegateStakingV3 on local Anvil
 * @dev Each function is a separate interaction scenario
 *
 * Usage:
 *   # Register sequencer
 *   forge script script/InteractV3.s.sol:RegisterSequencer --rpc-url local --broadcast
 *
 *   # Stake TON
 *   forge script script/InteractV3.s.sol:StakeTON --rpc-url local --broadcast
 *
 *   # Claim rewards
 *   forge script script/InteractV3.s.sol:ClaimRewards --rpc-url local --broadcast
 *
 *   # Trigger seigniorage
 *   forge script script/InteractV3.s.sol:TriggerSeigniorage --rpc-url local --broadcast
 *
 *   # Full flow test
 *   forge script script/InteractV3.s.sol:FullFlowTest --rpc-url local --broadcast
 */

// ============================================
// Register Sequencer Script
// ============================================
contract RegisterSequencer is Script {
    function run() external {
        // Load environment or use defaults
        address stakingAddr = vm.envOr("STAKING", address(0));
        address layer2 = vm.envOr("LAYER2", address(0));
        address operatorManager = vm.envOr("OPERATOR_MANAGER", address(0));
        uint256 commission = vm.envOr("COMMISSION", uint256(1000)); // 10%

        require(stakingAddr != address(0), "Set STAKING env var");
        require(layer2 != address(0), "Set LAYER2 env var");
        require(operatorManager != address(0), "Set OPERATOR_MANAGER env var");

        uint256 privateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d) // Anvil #1
        );

        console2.log("Registering sequencer...");
        console2.log("  Staking:", stakingAddr);
        console2.log("  Layer2:", layer2);
        console2.log("  OperatorManager:", operatorManager);
        console2.log("  Commission:", commission);

        vm.startBroadcast(privateKey);

        DelegateStakingV3 staking = DelegateStakingV3(stakingAddr);
        staking.registerSequencer(layer2, operatorManager, commission);

        vm.stopBroadcast();

        console2.log("Sequencer registered successfully!");
    }
}

// ============================================
// Stake TON Script
// ============================================
contract StakeTON is Script {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", address(0));
        address tonAddr = vm.envOr("TON", address(0));
        address sequencer = vm.envOr("SEQUENCER", address(0));
        uint256 amount = vm.envOr("AMOUNT", uint256(1000 ether));

        require(stakingAddr != address(0), "Set STAKING env var");
        require(tonAddr != address(0), "Set TON env var");
        require(sequencer != address(0), "Set SEQUENCER env var");

        uint256 privateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) // Anvil #0
        );
        address staker = vm.addr(privateKey);

        console2.log("Staking TON...");
        console2.log("  Staker:", staker);
        console2.log("  Sequencer:", sequencer);
        console2.log("  Amount:", amount / 1e18, "TON");

        vm.startBroadcast(privateKey);

        IERC20 ton = IERC20(tonAddr);
        DelegateStakingV3 staking = DelegateStakingV3(stakingAddr);

        // Approve and stake
        ton.approve(stakingAddr, amount);
        staking.stake(sequencer, amount);

        vm.stopBroadcast();

        console2.log("Staked successfully!");
        console2.log("  New stake balance:", staking.getStakeInfo(staker, sequencer).amount / 1e18, "TON");
    }
}

// ============================================
// Trigger Seigniorage Script
// ============================================
contract TriggerSeigniorage is Script {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", address(0));
        address sequencer = vm.envOr("SEQUENCER", address(0));

        require(stakingAddr != address(0), "Set STAKING env var");
        require(sequencer != address(0), "Set SEQUENCER env var");

        uint256 privateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        console2.log("Triggering seigniorage...");
        console2.log("  Sequencer:", sequencer);

        vm.startBroadcast(privateKey);

        DelegateStakingV3 staking = DelegateStakingV3(stakingAddr);
        staking.triggerSeigniorage(sequencer);

        vm.stopBroadcast();

        console2.log("Seigniorage triggered!");
    }
}

// ============================================
// Claim Rewards Script
// ============================================
contract ClaimRewards is Script {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", address(0));
        address wtonAddr = vm.envOr("WTON", address(0));
        address sequencer = vm.envOr("SEQUENCER", address(0));

        require(stakingAddr != address(0), "Set STAKING env var");
        require(wtonAddr != address(0), "Set WTON env var");
        require(sequencer != address(0), "Set SEQUENCER env var");

        uint256 privateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address staker = vm.addr(privateKey);

        DelegateStakingV3 staking = DelegateStakingV3(stakingAddr);
        IERC20 wton = IERC20(wtonAddr);

        uint256 pendingRewards = staking.pendingRewards(staker, sequencer);
        uint256 wtonBalanceBefore = wton.balanceOf(staker);

        console2.log("Claiming rewards...");
        console2.log("  Staker:", staker);
        console2.log("  Sequencer:", sequencer);
        console2.log("  Pending rewards:", pendingRewards / 1e27, "WTON (in TON equivalent)");

        vm.startBroadcast(privateKey);

        staking.claimRewards(sequencer);

        vm.stopBroadcast();

        uint256 wtonBalanceAfter = wton.balanceOf(staker);
        console2.log("Rewards claimed!");
        console2.log("  WTON received:", (wtonBalanceAfter - wtonBalanceBefore) / 1e27, "WTON (in TON equivalent)");
    }
}

// ============================================
// Unstake Script
// ============================================
contract Unstake is Script {
    function run() external {
        address stakingAddr = vm.envOr("STAKING", address(0));
        address sequencer = vm.envOr("SEQUENCER", address(0));
        uint256 amount = vm.envOr("AMOUNT", uint256(500 ether));

        require(stakingAddr != address(0), "Set STAKING env var");
        require(sequencer != address(0), "Set SEQUENCER env var");

        uint256 privateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        console2.log("Requesting unstake...");
        console2.log("  Amount:", amount / 1e18, "TON");

        vm.startBroadcast(privateKey);

        DelegateStakingV3 staking = DelegateStakingV3(stakingAddr);
        staking.unstake(sequencer, amount);

        vm.stopBroadcast();

        console2.log("Unstake requested! Wait for unbonding period to withdraw.");
    }
}

// ============================================
// Full Flow Test Script
// ============================================
contract FullFlowTest is Script {
    // Default addresses (update these after deployment)
    address constant TON = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant WTON = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant SEIG_MANAGER = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    address constant LAYER2_MANAGER = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
    address constant STAKING = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;

    function run() external {
        // Use Anvil test accounts
        uint256 deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        uint256 sequencerKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

        address deployer = vm.addr(deployerKey);
        address sequencer = vm.addr(sequencerKey);

        // These need to be obtained from deployment
        address layer2 = vm.envOr("LAYER2", makeAddr("layer2_1"));
        address operatorManager = vm.envOr("OPERATOR_MANAGER", address(0));

        require(operatorManager != address(0), "Set OPERATOR_MANAGER env var from deployment");

        DelegateStakingV3 staking = DelegateStakingV3(STAKING);
        IERC20 ton = IERC20(TON);
        IERC20 wton = IERC20(WTON);

        console2.log("========== FULL FLOW TEST ==========\n");

        // Step 1: Sequencer registers
        console2.log("STEP 1: Register Sequencer");
        vm.startBroadcast(sequencerKey);
        staking.registerSequencer(layer2, operatorManager, 1000); // 10% commission
        vm.stopBroadcast();
        console2.log("  Sequencer registered with 10% commission\n");

        // Step 2: User stakes
        console2.log("STEP 2: User Stakes 1000 TON");
        vm.startBroadcast(deployerKey);
        ton.approve(STAKING, 1000 ether);
        staking.stake(sequencer, 1000 ether);
        vm.stopBroadcast();
        console2.log("  Staked 1000 TON to sequencer");
        console2.log("  Total pool:", staking.getSequencerInfo(sequencer).totalStaked / 1e18, "TON\n");

        // Step 3: Trigger seigniorage
        console2.log("STEP 3: Trigger Seigniorage");
        vm.startBroadcast(deployerKey);
        staking.triggerSeigniorage(sequencer);
        vm.stopBroadcast();
        console2.log("  Seigniorage triggered\n");

        // Step 4: Check pending rewards
        console2.log("STEP 4: Check Pending Rewards");
        uint256 pending = staking.pendingRewards(deployer, sequencer);
        console2.log("  Pending rewards:", pending / 1e27, "WTON (in TON equivalent)\n");

        // Step 5: Claim rewards
        console2.log("STEP 5: Claim Rewards");
        uint256 wtonBefore = wton.balanceOf(deployer);
        vm.startBroadcast(deployerKey);
        staking.claimRewards(sequencer);
        vm.stopBroadcast();
        uint256 wtonAfter = wton.balanceOf(deployer);
        console2.log("  Rewards claimed:", (wtonAfter - wtonBefore) / 1e27, "WTON (in TON equivalent)\n");

        // Step 6: Sequencer claims commission
        console2.log("STEP 6: Sequencer Claims Commission");
        uint256 seqWtonBefore = wton.balanceOf(sequencer);
        vm.startBroadcast(sequencerKey);
        staking.claimCommission();
        vm.stopBroadcast();
        uint256 seqWtonAfter = wton.balanceOf(sequencer);
        console2.log("  Commission claimed:", (seqWtonAfter - seqWtonBefore) / 1e27, "WTON\n");

        console2.log("========== TEST COMPLETE ==========");
    }
}
