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

/**
 * @title DeployRATSimple
 * @notice Simplified RAT deployment for local frontend testing
 * @dev Deploys RAT with mock tokens and minimal dependencies
 *
 * Usage:
 *   forge script script/DeployRATSimple.s.sol:DeployRATSimple \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast \
 *     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 */
contract DeployRATSimple is Script {
    // RAY constant (27 decimals)
    uint256 constant RAY = 1e27;

    // Anvil default accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant PROXY_ADMIN = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant VALIDATOR_1 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant VALIDATOR_2 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

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

    function run() public {
        vm.startBroadcast();

        // Deploy tokens
        _deployTokens();

        // Deploy RAT (simplified - no SeigManager integration)
        _deployRAT();

        // Mint test tokens
        _mintTestTokens();

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

        // Build init data (simplified - using deployer as placeholders)
        RATInitParams memory initParams = RATInitParams({
            seigManager: DEPLOYER, // Placeholder - no real SeigManager
            wton: wton,
            ton: ton,
            layer2Manager: DEPLOYER, // Placeholder
            l1BridgeRegistry: DEPLOYER, // Placeholder
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

    function _mintTestTokens() internal {
        console.log("--- Minting Test Tokens ---");

        uint256 tonAmount = 1_000_000 * 1e18; // 1M TON
        uint256 wtonAmount = 1_000_000 * RAY; // 1M WTON

        address[4] memory accounts = [DEPLOYER, PROXY_ADMIN, VALIDATOR_1, VALIDATOR_2];
        string[4] memory names = ["DEPLOYER", "PROXY_ADMIN", "VALIDATOR_1", "VALIDATOR_2"];

        for (uint256 i = 0; i < accounts.length; i++) {
            MockTON(ton).mint(accounts[i], tonAmount);
            MockWTON(wton).mint(accounts[i], wtonAmount);
            console.log("Minted to", names[i], accounts[i]);
        }
    }

    function _printSummary() internal view {
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("TON:", ton);
        console.log("WTON:", wton);
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT Impl:", ratImpl);
        console.log("");
        console.log("Test Accounts (1M TON + 1M WTON each):");
        console.log("  DEPLOYER:", DEPLOYER);
        console.log("  PROXY_ADMIN:", PROXY_ADMIN);
        console.log("  VALIDATOR_1:", VALIDATOR_1);
        console.log("  VALIDATOR_2:", VALIDATOR_2);
    }

    function _saveDeployment() internal view {
        string memory json = string(abi.encodePacked(
            '{\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "rpcUrl": "http://localhost:8545",\n',
            '  "ton": "', vm.toString(ton), '",\n',
            '  "wton": "', vm.toString(wton), '",\n',
            '  "ratProxy": "', vm.toString(ratProxy), '",\n',
            '  "ratImpl": "', vm.toString(ratImpl), '",\n',
            '  "accounts": {\n',
            '    "deployer": "', vm.toString(DEPLOYER), '",\n',
            '    "proxyAdmin": "', vm.toString(PROXY_ADMIN), '",\n',
            '    "validator1": "', vm.toString(VALIDATOR_1), '",\n',
            '    "validator2": "', vm.toString(VALIDATOR_2), '"\n',
            '  }\n',
            '}'
        ));

        console.log("\n=== DEPLOYMENT_JSON_START ===");
        console.log(json);
        console.log("=== DEPLOYMENT_JSON_END ===");
    }
}
