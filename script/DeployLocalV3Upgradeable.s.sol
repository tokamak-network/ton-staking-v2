// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DelegateStakingV3Upgradeable} from "../contracts/DelegateStakingV3Upgradeable.sol";
import {DelegateTrigger} from "../contracts/DelegateTrigger.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";
import {MockWTON} from "../test/mocks/WTONMock.sol";
import {MockSeigManagerV3} from "../test/mocks/MockSeigManagerV3.sol";
import {MockLayer2ManagerV3} from "../test/mocks/MockLayer2ManagerV3.sol";
import {MockOperatorManagerV3} from "../test/mocks/MockOperatorManagerV3.sol";

/**
 * @title DeployLocalV3Upgradeable
 * @notice Deploys full V3 test environment with UUPS Upgradeable contract
 * @dev Run with: forge script script/DeployLocalV3Upgradeable.s.sol --rpc-url http://localhost:8545 --broadcast
 *
 * This script deploys:
 * 1. Mock tokens (TON, WTON)
 * 2. Mock V3 infrastructure (SeigManager, Layer2Manager)
 * 3. DelegateStakingV3Upgradeable (Implementation + Proxy)
 * 4. DelegateTrigger
 * 5. Test L2s with OperatorManagers
 */
contract DeployLocalV3UpgradeableScript is Script {
    // Deployed contracts
    ERC20Mock public ton;
    MockWTON public wton;
    MockSeigManagerV3 public seigManager;
    MockLayer2ManagerV3 public layer2Manager;
    DelegateStakingV3Upgradeable public implementation;
    DelegateStakingV3Upgradeable public staking; // Proxy
    address public proxy;
    DelegateTrigger public trigger;

    // Test addresses
    address public deployer;
    address public sequencer1;
    address public sequencer2;
    address public sequencer3; // Ineligible sequencer (doesn't meet minimum deposit)
    address public user1;
    address public user2;
    address public layer2_1;
    address public layer2_2;
    address public layer2_3;
    address public operatorManager1;
    address public operatorManager2;
    address public operatorManager3;

    // Anvil default private keys
    uint256 constant DEPLOYER_PK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Account #0
    uint256 constant SEQUENCER1_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d; // Account #1
    uint256 constant SEQUENCER2_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a; // Account #2
    uint256 constant USER1_PK = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6; // Account #3
    uint256 constant USER2_PK = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a; // Account #4
    uint256 constant SEQUENCER3_PK = 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba; // Account #5 (Ineligible)

    function setUp() public {}

    function run() public {
        // Setup addresses from Anvil accounts
        deployer = vm.addr(DEPLOYER_PK);
        sequencer1 = vm.addr(SEQUENCER1_PK);
        sequencer2 = vm.addr(SEQUENCER2_PK);
        sequencer3 = vm.addr(SEQUENCER3_PK);
        user1 = vm.addr(USER1_PK);
        user2 = vm.addr(USER2_PK);
        layer2_1 = makeAddr("layer2_1");
        layer2_2 = makeAddr("layer2_2");
        layer2_3 = makeAddr("layer2_3");

        console2.log("========== DEPLOYING V3 UPGRADEABLE TEST ENVIRONMENT ==========");
        console2.log("Deployer:", deployer);
        console2.log("Balance:", deployer.balance);

        vm.startBroadcast(DEPLOYER_PK);

        // 1. Deploy Mock Tokens
        _deployTokens();

        // 2. Deploy Mock V3 Infrastructure
        _deployV3Infrastructure();

        // 3. Deploy DelegateStakingV3Upgradeable (Implementation + Proxy)
        _deployDelegateStakingUpgradeable();

        // 4. Deploy DelegateTrigger
        _deployTrigger();

        // 5. Setup L2s and Sequencers
        _setupL2sAndSequencers();

        // 6. Mint test tokens
        _mintTestTokens();

        vm.stopBroadcast();

        // 7. Authorize DelegateStaking on OperatorManagers (requires sequencer keys)
        _authorizeStakingOnOperatorManagers();

        // 8. Register sequencers and enable auto-trigger
        _registerSequencers();

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

    function _deployDelegateStakingUpgradeable() internal {
        console2.log("\n--- Deploying DelegateStakingV3Upgradeable ---");

        // 1. Deploy Implementation
        implementation = new DelegateStakingV3Upgradeable();
        console2.log("Implementation deployed at:", address(implementation));

        // 2. Prepare initialization data
        uint256 unbondingPeriod = 5 minutes; // Short period for testing
        bytes memory initData = abi.encodeWithSelector(
            DelegateStakingV3Upgradeable.initialize.selector,
            address(ton),
            address(wton),
            address(seigManager),
            address(layer2Manager),
            unbondingPeriod,
            deployer // owner
        );

        // 3. Deploy Proxy
        proxy = address(new ERC1967Proxy(address(implementation), initData));
        staking = DelegateStakingV3Upgradeable(proxy);
        console2.log("Proxy deployed at:", proxy);
        console2.log("Version:", staking.version());
    }

    function _deployTrigger() internal {
        console2.log("\n--- Deploying DelegateTrigger ---");

        trigger = new DelegateTrigger(address(wton), deployer);
        console2.log("DelegateTrigger deployed at:", address(trigger));
    }

    function _setupL2sAndSequencers() internal {
        console2.log("\n--- Setting up L2s ---");

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

        // Register L2 #3 (Ineligible - doesn't meet minimum deposit)
        operatorManager3 = layer2Manager.registerLayer2(layer2_3, sequencer3);
        console2.log("L2 #3 registered (INELIGIBLE):");
        console2.log("  Layer2:", layer2_3);
        console2.log("  Sequencer:", sequencer3);
        console2.log("  OperatorManager:", operatorManager3);

        // Set up bridged TON (simulating bridge activity)
        uint256 bridgedAmount = 100_000 ether;
        seigManager.updateBridgedTON(layer2_1, bridgedAmount);
        seigManager.updateBridgedTON(layer2_2, bridgedAmount);
        seigManager.updateBridgedTON(layer2_3, bridgedAmount);

        // Set up staked TON for eligibility
        // L2 #1 and #2: Eligible (stakedTON >= required)
        // L2 #3: INELIGIBLE (stakedTON < required)
        uint256 stakedAmount = 10_000 ether;
        uint256 insufficientStake = 100 ether; // Much lower than required
        seigManager.updateStakedTON(layer2_1, stakedAmount);
        seigManager.updateStakedTON(layer2_2, stakedAmount);
        seigManager.updateStakedTON(layer2_3, insufficientStake); // Ineligible!

        console2.log("BridgedTON set to", bridgedAmount / 1e18, "for each L2");
        console2.log("StakedTON L2#1, L2#2:", stakedAmount / 1e18);
        console2.log("StakedTON L2#3 (INELIGIBLE):", insufficientStake / 1e18);
    }

    function _authorizeStakingOnOperatorManagers() internal {
        console2.log("\n--- Authorizing DelegateStaking on OperatorManagers ---");

        // Sequencer1 authorizes DelegateStaking
        vm.startBroadcast(SEQUENCER1_PK);
        MockOperatorManagerV3(operatorManager1).authorizeClaimer(proxy);
        vm.stopBroadcast();
        console2.log("Sequencer1 authorized DelegateStaking on OperatorManager1");

        // Sequencer2 authorizes DelegateStaking
        vm.startBroadcast(SEQUENCER2_PK);
        MockOperatorManagerV3(operatorManager2).authorizeClaimer(proxy);
        vm.stopBroadcast();
        console2.log("Sequencer2 authorized DelegateStaking on OperatorManager2");

        // Sequencer3 authorizes DelegateStaking (Ineligible)
        vm.startBroadcast(SEQUENCER3_PK);
        MockOperatorManagerV3(operatorManager3).authorizeClaimer(proxy);
        vm.stopBroadcast();
        console2.log("Sequencer3 authorized DelegateStaking on OperatorManager3 (INELIGIBLE)");
    }

    function _registerSequencers() internal {
        console2.log("\n--- Registering Sequencers ---");

        // Sequencer1 registers with 10% commission
        vm.startBroadcast(SEQUENCER1_PK);
        staking.registerSequencer(layer2_1, operatorManager1, 1000);
        staking.setAutoTrigger(true);
        vm.stopBroadcast();
        console2.log("Sequencer1 registered with 10% commission, auto-trigger enabled");

        // Sequencer2 registers with 5% commission
        vm.startBroadcast(SEQUENCER2_PK);
        staking.registerSequencer(layer2_2, operatorManager2, 500);
        staking.setAutoTrigger(true);
        vm.stopBroadcast();
        console2.log("Sequencer2 registered with 5% commission, auto-trigger enabled");

        // Sequencer3 registers with 15% commission (INELIGIBLE - doesn't meet min deposit)
        vm.startBroadcast(SEQUENCER3_PK);
        staking.registerSequencer(layer2_3, operatorManager3, 1500);
        staking.setAutoTrigger(false); // No auto-trigger since ineligible
        vm.stopBroadcast();
        console2.log("Sequencer3 registered with 15% commission (INELIGIBLE - min deposit not met)");
    }

    function _mintTestTokens() internal {
        console2.log("\n--- Minting Test Tokens ---");

        uint256 mintAmount = 1_000_000 ether; // 1M TON
        uint256 wtonAmount = mintAmount * 1e9; // Convert to WTON (27 decimals)

        // Mint to deployer
        ton.mint(deployer, mintAmount);
        wton.mint(deployer, wtonAmount);

        // Mint to users
        ton.mint(user1, mintAmount);
        ton.mint(user2, mintAmount);

        // Mint to sequencers
        ton.mint(sequencer1, mintAmount);
        ton.mint(sequencer2, mintAmount);
        ton.mint(sequencer3, mintAmount);

        // Mint WTON to SeigManager (for seigniorage distribution)
        wton.mint(address(seigManager), wtonAmount * 10);

        // Mint WTON to OperatorManagers (for testing claims)
        wton.mint(operatorManager1, wtonAmount);
        wton.mint(operatorManager2, wtonAmount);
        wton.mint(operatorManager3, wtonAmount);

        // Update pending rewards
        MockOperatorManagerV3(operatorManager1).mockSetPendingRewards(wtonAmount);
        MockOperatorManagerV3(operatorManager2).mockSetPendingRewards(wtonAmount);
        MockOperatorManagerV3(operatorManager3).mockSetPendingRewards(wtonAmount);

        console2.log("Minted 1M TON to deployer, users, and sequencers");
        console2.log("Minted WTON to V3 contracts for rewards");
    }

    function _printSummary() internal view {
        console2.log("\n");
        console2.log("====================================================================");
        console2.log("           V3 UPGRADEABLE DEPLOYMENT SUMMARY                        ");
        console2.log("====================================================================");
        console2.log(" Network: localhost (Anvil)    Chain ID: 31337                      ");
        console2.log("--------------------------------------------------------------------");
        console2.log(" TOKENS                                                             ");
        _logAddress("TON", address(ton));
        _logAddress("WTON", address(wton));
        console2.log("--------------------------------------------------------------------");
        console2.log(" V3 INFRASTRUCTURE                                                  ");
        _logAddress("SeigManager", address(seigManager));
        _logAddress("Layer2Manager", address(layer2Manager));
        console2.log("--------------------------------------------------------------------");
        console2.log(" DELEGATE STAKING (UUPS UPGRADEABLE)                                ");
        _logAddress("Implementation", address(implementation));
        _logAddress("Proxy", proxy);
        _logAddress("DelegateTrigger", address(trigger));
        console2.log("--------------------------------------------------------------------");
        console2.log(" L2 #1                                                              ");
        _logAddress("Layer2", layer2_1);
        _logAddress("Sequencer", sequencer1);
        _logAddress("OperatorManager", operatorManager1);
        console2.log("--------------------------------------------------------------------");
        console2.log(" L2 #2                                                              ");
        _logAddress("Layer2", layer2_2);
        _logAddress("Sequencer", sequencer2);
        _logAddress("OperatorManager", operatorManager2);
        console2.log("--------------------------------------------------------------------");
        console2.log(" L2 #3 (INELIGIBLE - min deposit not met)                           ");
        _logAddress("Layer2", layer2_3);
        _logAddress("Sequencer", sequencer3);
        _logAddress("OperatorManager", operatorManager3);
        console2.log("--------------------------------------------------------------------");
        console2.log(" TEST ACCOUNTS (Anvil)                                              ");
        _logAddress("Deployer (#0)", deployer);
        _logAddress("Sequencer1 (#1)", sequencer1);
        _logAddress("Sequencer2 (#2)", sequencer2);
        _logAddress("Sequencer3 (#5, INELIGIBLE)", sequencer3);
        _logAddress("User1 (#3)", user1);
        _logAddress("User2 (#4)", user2);
        console2.log("====================================================================");
        console2.log("");
        console2.log("QUICK START:");
        console2.log("  # Stake TON (as User1)");
        console2.log("  export STAKING=", proxy);
        console2.log("  forge script script/InteractV3Upgradeable.s.sol:StakeTON --rpc-url http://localhost:8545 --broadcast");
        console2.log("");
        console2.log("  # Full flow test");
        console2.log("  forge script script/InteractV3Upgradeable.s.sol:FullFlowTest --rpc-url http://localhost:8545 --broadcast");
        console2.log("");
    }

    function _logAddress(string memory name, address addr) internal pure {
        console2.log(string.concat("   ", name, ":"));
        console2.log("      ", addr);
    }
}
