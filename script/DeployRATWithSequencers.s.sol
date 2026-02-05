// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// V3 Contracts
import {RAT} from "../src/validator/RAT.sol";
import {RATInitParams, RATConfigParams} from "../src/validator/RATTypes.sol";
import {RATProxy} from "../src/validator/RATProxy.sol";

// Mocks
import {MockTON} from "../src/mocks/MockTON.sol";
import {MockWTON} from "../src/mocks/MockWTON.sol";
import {MockSystemConfig} from "../src/mocks/MockSystemConfig.sol";

/**
 * @title DeployRATWithSequencers
 * @notice RAT deployment with multiple L2 sequencers for comprehensive local testing
 * @dev Deploys RAT, tokens, L2 SystemConfigs, and registers validators
 *
 * Test Scenario:
 *   - 3 L2 Networks: Titan, Thanos, Tokamak
 *   - 4 Validators ready to register
 *   - Pre-minted tokens for testing
 *
 * Usage:
 *   forge script script/DeployRATWithSequencers.s.sol:DeployRATWithSequencers \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast \
 *     --via-ir \
 *     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 */
contract DeployRATWithSequencers is Script {
    // RAY constant (27 decimals)
    uint256 constant RAY = 1e27;

    // Anvil default accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant PROXY_ADMIN = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant VALIDATOR_1 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant VALIDATOR_2 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address constant SEQUENCER_1 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    address constant SEQUENCER_2 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
    address constant SEQUENCER_3 = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
    address constant USER_1 = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;

    // RAT parameters (Testing-optimized)
    uint256 constant RAT_TRIGGER_PROBABILITY = RAY; // 100% for testing
    uint256 constant RAT_EVIDENCE_PERIOD = 1 hours;
    uint256 constant RAT_SLASHING_PENALTY = 10 * RAY; // 10 WTON
    uint256 constant RAT_VALIDATOR_BUFFER = 50 * RAY; // 50 WTON
    uint256 constant RAT_MINIMUM_THRESHOLD = 60 * RAY; // 60 WTON
    uint256 constant RAT_MAX_VALIDATORS = 100;
    uint256 constant RAT_CHALLENGE_DURATION = 7 days;
    uint256 constant RAT_SAFETY_BUFFER = 1 days;
    uint256 constant RAT_ATTENTION_COST = 1e27; // 1 TON

    // Deployed addresses
    address public ton;
    address public wton;
    address public ratProxy;
    address public ratImpl;

    // L2 SystemConfigs (Sequencers)
    address public titanSystemConfig;
    address public thanosSystemConfig;
    address public tokamakSystemConfig;

    function run() public {
        vm.startBroadcast();

        // 1. Deploy tokens
        _deployTokens();

        // 2. Deploy RAT
        _deployRAT();

        // 3. Deploy L2 SystemConfigs (Sequencers)
        _deploySequencers();

        // 4. Mint test tokens to all accounts
        _mintTestTokens();

        // 5. Approve WTON for RAT contract (for validator registration)
        _approveTokens();

        vm.stopBroadcast();

        // Print summary
        _printSummary();

        // Save deployment JSON
        _saveDeployment();
    }

    function _deployTokens() internal {
        console.log("--- Deploying Tokens ---");

        // Deploy TON
        bytes32 saltTon = bytes32(uint256(1));
        ton = address(new MockTON{salt: saltTon}());
        console.log("TON:", ton);

        // Deploy WTON
        bytes32 saltWton = bytes32(uint256(2));
        MockWTON wtonContract = new MockWTON{salt: saltWton}();
        wtonContract.setTON(ton);
        wton = address(wtonContract);
        console.log("WTON:", wton);
    }

    function _deployRAT() internal {
        console.log("--- Deploying RAT ---");

        // Deploy RAT implementation
        ratImpl = address(new RAT());
        console.log("RAT Impl:", ratImpl);

        // Build init data
        RATInitParams memory initParams = RATInitParams({
            seigManager: DEPLOYER,
            wton: wton,
            ton: ton,
            layer2Manager: DEPLOYER,
            l1BridgeRegistry: DEPLOYER,
            owner: DEPLOYER
        });

        bytes memory initData = abi.encodeWithSelector(RAT.initialize.selector, initParams);

        // Deploy RAT proxy
        ratProxy = address(new RATProxy(ratImpl, PROXY_ADMIN, initData));
        console.log("RAT Proxy:", ratProxy);

        // Configure RAT
        RATConfigParams memory config = RATConfigParams({
            ratTriggerProbability: RAT_TRIGGER_PROBABILITY,
            evidenceSubmissionPeriod: RAT_EVIDENCE_PERIOD,
            slashingPenalty: RAT_SLASHING_PENALTY,
            validatorBuffer: RAT_VALIDATOR_BUFFER,
            minimumThreshold: RAT_MINIMUM_THRESHOLD,
            maxValidatorsPerL2: RAT_MAX_VALIDATORS,
            challengeGameDuration: RAT_CHALLENGE_DURATION,
            safetyBuffer: RAT_SAFETY_BUFFER,
            treasury: DEPLOYER,
            attentionCost: RAT_ATTENTION_COST,
            relaxedValidatorCheck: true
        });
        RAT(ratProxy).setConfig(config);
        console.log("RAT configured");
    }

    function _deploySequencers() internal {
        console.log("--- Deploying L2 Sequencers (SystemConfigs) ---");

        // Deploy Titan L2
        titanSystemConfig = address(new MockSystemConfig());
        MockSystemConfig(titanSystemConfig).setName("Titan");
        MockSystemConfig(titanSystemConfig).setUnsafeBlockSigner(SEQUENCER_1);
        console.log("Titan SystemConfig:", titanSystemConfig);

        // Deploy Thanos L2
        thanosSystemConfig = address(new MockSystemConfig());
        MockSystemConfig(thanosSystemConfig).setName("Thanos");
        MockSystemConfig(thanosSystemConfig).setUnsafeBlockSigner(SEQUENCER_2);
        console.log("Thanos SystemConfig:", thanosSystemConfig);

        // Deploy Tokamak L2
        tokamakSystemConfig = address(new MockSystemConfig());
        MockSystemConfig(tokamakSystemConfig).setName("Tokamak");
        MockSystemConfig(tokamakSystemConfig).setUnsafeBlockSigner(SEQUENCER_3);
        console.log("Tokamak SystemConfig:", tokamakSystemConfig);
    }

    function _mintTestTokens() internal {
        console.log("--- Minting Test Tokens ---");

        uint256 tonAmount = 1_000_000 * 1e18; // 1M TON
        uint256 wtonAmount = 1_000_000 * RAY; // 1M WTON

        address[8] memory accounts = [
            DEPLOYER, PROXY_ADMIN, VALIDATOR_1, VALIDATOR_2,
            SEQUENCER_1, SEQUENCER_2, SEQUENCER_3, USER_1
        ];
        string[8] memory names = [
            "DEPLOYER", "PROXY_ADMIN", "VALIDATOR_1", "VALIDATOR_2",
            "SEQUENCER_1", "SEQUENCER_2", "SEQUENCER_3", "USER_1"
        ];

        for (uint256 i = 0; i < accounts.length; i++) {
            MockTON(ton).mint(accounts[i], tonAmount);
            MockWTON(wton).mint(accounts[i], wtonAmount);
            console.log("Minted to", names[i], accounts[i]);
        }
    }

    function _approveTokens() internal {
        console.log("--- Approving Tokens for RAT ---");

        // Deployer approves WTON for RAT
        MockWTON(wton).approve(ratProxy, type(uint256).max);
        console.log("DEPLOYER approved WTON for RAT");
    }

    function _printSummary() internal view {
        console.log("");
        console.log("========================================");
        console.log("=== RAT Local Testing Environment ===");
        console.log("========================================");
        console.log("");
        console.log("--- Core Contracts ---");
        console.log("TON:", ton);
        console.log("WTON:", wton);
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT Impl:", ratImpl);
        console.log("");
        console.log("--- L2 Networks (Sequencers) ---");
        console.log("Titan:", titanSystemConfig);
        console.log("Thanos:", thanosSystemConfig);
        console.log("Tokamak:", tokamakSystemConfig);
        console.log("");
        console.log("--- Test Accounts ---");
        console.log("All accounts have 1M TON + 1M WTON");
        console.log("");
        console.log("Validators (can register to L2s):");
        console.log("  VALIDATOR_1:", VALIDATOR_1);
        console.log("  VALIDATOR_2:", VALIDATOR_2);
        console.log("");
        console.log("Sequencers (L2 operators):");
        console.log("  SEQUENCER_1 (Titan):", SEQUENCER_1);
        console.log("  SEQUENCER_2 (Thanos):", SEQUENCER_2);
        console.log("  SEQUENCER_3 (Tokamak):", SEQUENCER_3);
        console.log("");
        console.log("--- RAT Parameters ---");
        console.log("Minimum Deposit: 60 WTON");
        console.log("Slashing Penalty: 10 WTON");
        console.log("Evidence Period: 1 hour");
        console.log("RAT Trigger: 100%");
    }

    function _saveDeployment() internal view {
        string memory json = string(abi.encodePacked(
            '{\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "rpcUrl": "http://localhost:8545",\n',
            '  "contracts": {\n',
            '    "ton": "', vm.toString(ton), '",\n',
            '    "wton": "', vm.toString(wton), '",\n',
            '    "ratProxy": "', vm.toString(ratProxy), '",\n',
            '    "ratImpl": "', vm.toString(ratImpl), '"\n',
            '  },\n',
            '  "l2Networks": {\n',
            '    "titan": "', vm.toString(titanSystemConfig), '",\n',
            '    "thanos": "', vm.toString(thanosSystemConfig), '",\n',
            '    "tokamak": "', vm.toString(tokamakSystemConfig), '"\n',
            '  },\n',
            '  "accounts": {\n',
            '    "deployer": "', vm.toString(DEPLOYER), '",\n',
            '    "proxyAdmin": "', vm.toString(PROXY_ADMIN), '",\n',
            '    "validator1": "', vm.toString(VALIDATOR_1), '",\n',
            '    "validator2": "', vm.toString(VALIDATOR_2), '",\n',
            '    "sequencer1": "', vm.toString(SEQUENCER_1), '",\n',
            '    "sequencer2": "', vm.toString(SEQUENCER_2), '",\n',
            '    "sequencer3": "', vm.toString(SEQUENCER_3), '",\n',
            '    "user1": "', vm.toString(USER_1), '"\n',
            '  }\n',
            '}'
        ));

        console.log("\n=== DEPLOYMENT_JSON_START ===");
        console.log(json);
        console.log("=== DEPLOYMENT_JSON_END ===");
    }
}
