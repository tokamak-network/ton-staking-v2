// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {DelegateStakingV3} from "../contracts/DelegateStakingV3.sol";
import {DelegateTrigger} from "../contracts/DelegateTrigger.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";
import {MockWTON} from "../test/mocks/WTONMock.sol";
import {MockSeigManagerV3} from "../test/mocks/MockSeigManagerV3.sol";
import {MockLayer2ManagerV3} from "../test/mocks/MockLayer2ManagerV3.sol";
import {MockOperatorManagerV3} from "../test/mocks/MockOperatorManagerV3.sol";

/**
 * @title DeployLocalV3
 * @notice Deploys full V3 test environment for local testing
 * @dev Run with: forge script script/DeployLocalV3.s.sol --rpc-url local --broadcast
 *
 * This script deploys:
 * 1. Mock tokens (TON, WTON)
 * 2. Mock V3 infrastructure (SeigManager, Layer2Manager)
 * 3. DelegateStakingV3
 * 4. DelegateTrigger
 * 5. Test L2s with OperatorManagers
 */
contract DeployLocalV3Script is Script {
    // Deployed contracts
    ERC20Mock public ton;
    MockWTON public wton;
    MockSeigManagerV3 public seigManager;
    MockLayer2ManagerV3 public layer2Manager;
    DelegateStakingV3 public staking;
    DelegateTrigger public trigger;

    // Test addresses
    address public deployer;
    address public sequencer1;
    address public sequencer2;
    address public layer2_1;
    address public layer2_2;
    address public operatorManager1;
    address public operatorManager2;

    function setUp() public {}

    // Private keys for sequencers (Anvil default accounts)
    uint256 constant SEQUENCER1_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d; // Account #1
    uint256 constant SEQUENCER2_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a; // Account #2

    function run() public {
        // Use Anvil's default account #0
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        deployer = vm.addr(deployerPrivateKey);

        // Create test addresses
        sequencer1 = vm.addr(SEQUENCER1_PK); // Anvil account #1
        sequencer2 = vm.addr(SEQUENCER2_PK); // Anvil account #2
        layer2_1 = makeAddr("layer2_1");
        layer2_2 = makeAddr("layer2_2");

        console2.log("========== DEPLOYING V3 TEST ENVIRONMENT ==========");
        console2.log("Deployer:", deployer);
        console2.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Mock Tokens
        _deployTokens();

        // 2. Deploy Mock V3 Infrastructure
        _deployV3Infrastructure();

        // 3. Deploy DelegateStakingV3
        _deployDelegateStaking();

        // 4. Deploy DelegateTrigger
        _deployTrigger();

        // 5. Setup L2s and Sequencers (without authorization)
        _setupL2sAndSequencers();

        // 6. Mint test tokens
        _mintTestTokens();

        vm.stopBroadcast();

        // 7. Authorize DelegateStaking on OperatorManagers (requires sequencer keys)
        _authorizeStakingOnOperatorManagers();

        // Print summary
        _printSummary();
    }

    function _deployTokens() internal {
        console2.log("\n--- Deploying Tokens ---");

        // Deploy Mock TON (18 decimals)
        ton = new ERC20Mock("Tokamak Network", "TON");
        console2.log("TON Mock deployed at:", address(ton));

        // Deploy Mock WTON (27 decimals)
        wton = new MockWTON();
        wton.setTON(address(ton));
        console2.log("WTON Mock deployed at:", address(wton));
    }

    function _deployV3Infrastructure() internal {
        console2.log("\n--- Deploying V3 Infrastructure ---");

        // Deploy MockSeigManagerV3
        seigManager = new MockSeigManagerV3(address(ton), address(wton));
        console2.log("MockSeigManagerV3 deployed at:", address(seigManager));

        // Deploy MockLayer2ManagerV3
        layer2Manager = new MockLayer2ManagerV3(address(ton), address(wton));
        console2.log("MockLayer2ManagerV3 deployed at:", address(layer2Manager));

        // Wire up
        seigManager.setLayer2Manager(address(layer2Manager));
        layer2Manager.setSeigManager(address(seigManager));

        console2.log("V3 Infrastructure wired up");
    }

    function _deployDelegateStaking() internal {
        console2.log("\n--- Deploying DelegateStakingV3 ---");

        uint256 unbondingPeriod = 7 days;
        staking = new DelegateStakingV3(
            address(ton),
            address(wton),
            address(seigManager),
            address(layer2Manager),
            unbondingPeriod,
            deployer // owner
        );
        console2.log("DelegateStakingV3 deployed at:", address(staking));
    }

    function _deployTrigger() internal {
        console2.log("\n--- Deploying DelegateTrigger ---");

        trigger = new DelegateTrigger(address(wton), deployer);
        console2.log("DelegateTrigger deployed at:", address(trigger));
    }

    function _setupL2sAndSequencers() internal {
        console2.log("\n--- Setting up L2s and Sequencers ---");

        // Register L2 #1
        operatorManager1 = layer2Manager.registerLayer2(layer2_1, sequencer1);
        console2.log("L2 #1 registered:");
        console2.log("  Layer2:", layer2_1);
        console2.log("  Sequencer:", sequencer1);
        console2.log("  OperatorManager:", operatorManager1);

        // Register L2 #2
        operatorManager2 = layer2Manager.registerLayer2(layer2_2, sequencer2);
        console2.log("L2 #2 registered:");
        console2.log("  Layer2:", layer2_2);
        console2.log("  Sequencer:", sequencer2);
        console2.log("  OperatorManager:", operatorManager2);

        // Set up bridged TON (simulating bridge activity)
        uint256 bridgedAmount = 100_000 ether;
        seigManager.updateBridgedTON(layer2_1, bridgedAmount);
        seigManager.updateBridgedTON(layer2_2, bridgedAmount);
        console2.log("BridgedTON set to", bridgedAmount / 1e18, "for each L2");
    }

    function _authorizeStakingOnOperatorManagers() internal {
        console2.log("\n--- Authorizing DelegateStaking on OperatorManagers ---");

        // Sequencer1 authorizes DelegateStaking
        vm.startBroadcast(SEQUENCER1_PK);
        MockOperatorManagerV3(operatorManager1).authorizeClaimer(address(staking));
        vm.stopBroadcast();
        console2.log("Sequencer1 authorized DelegateStaking on OperatorManager1");

        // Sequencer2 authorizes DelegateStaking
        vm.startBroadcast(SEQUENCER2_PK);
        MockOperatorManagerV3(operatorManager2).authorizeClaimer(address(staking));
        vm.stopBroadcast();
        console2.log("Sequencer2 authorized DelegateStaking on OperatorManager2");
    }

    function _mintTestTokens() internal {
        console2.log("\n--- Minting Test Tokens ---");

        uint256 mintAmount = 1_000_000 ether; // 1M TON
        uint256 wtonAmount = mintAmount * 1e9; // Convert to WTON (27 decimals)

        // Mint to deployer
        ton.mint(deployer, mintAmount);
        wton.mint(deployer, wtonAmount);

        // Mint to sequencers
        ton.mint(sequencer1, mintAmount);
        ton.mint(sequencer2, mintAmount);

        // Mint WTON to SeigManager (for seigniorage distribution)
        wton.mint(address(seigManager), wtonAmount * 10);

        // Mint WTON to OperatorManagers (for testing claims)
        wton.mint(operatorManager1, wtonAmount);
        wton.mint(operatorManager2, wtonAmount);
        // Update pending rewards
        MockOperatorManagerV3(operatorManager1).mockSetPendingRewards(wtonAmount);
        MockOperatorManagerV3(operatorManager2).mockSetPendingRewards(wtonAmount);

        console2.log("Minted tokens to deployer, sequencers, and V3 contracts");
    }

    function _printSummary() internal view {
        console2.log("\n========== DEPLOYMENT SUMMARY ==========");
        console2.log("Network: localhost (Anvil)");
        console2.log("Chain ID: 31337");
        console2.log("");
        console2.log("TOKEN ADDRESSES:");
        console2.log("  TON:                  ", address(ton));
        console2.log("  WTON:                 ", address(wton));
        console2.log("");
        console2.log("V3 INFRASTRUCTURE:");
        console2.log("  SeigManager:          ", address(seigManager));
        console2.log("  Layer2Manager:        ", address(layer2Manager));
        console2.log("");
        console2.log("DELEGATE STAKING:");
        console2.log("  DelegateStakingV3:    ", address(staking));
        console2.log("  DelegateTrigger:      ", address(trigger));
        console2.log("");
        console2.log("L2 #1:");
        console2.log("  Layer2:               ", layer2_1);
        console2.log("  Sequencer:            ", sequencer1);
        console2.log("  OperatorManager:      ", operatorManager1);
        console2.log("");
        console2.log("L2 #2:");
        console2.log("  Layer2:               ", layer2_2);
        console2.log("  Sequencer:            ", sequencer2);
        console2.log("  OperatorManager:      ", operatorManager2);
        console2.log("");
        console2.log("TEST ACCOUNTS (Anvil defaults):");
        console2.log("  Deployer (#0):        ", deployer);
        console2.log("  Sequencer1 (#1):      ", sequencer1);
        console2.log("  Sequencer2 (#2):      ", sequencer2);
        console2.log("==========================================");
        console2.log("");
        console2.log("NEXT STEPS:");
        console2.log("1. Sequencer registers: staking.registerSequencer(layer2, operatorManager, commission)");
        console2.log("2. User stakes: staking.stake(sequencer, amount)");
        console2.log("3. Trigger seigniorage: staking.triggerSeigniorage(sequencer)");
        console2.log("4. Claim rewards: staking.claimRewards(sequencer)");
        console2.log("");
    }
}
