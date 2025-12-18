// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {RAT} from "../src/validator/RAT.sol";

/// @title DeployTONStakingRAT
/// @notice Deployment script for TON Staking V3 RAT contract
/// @dev Used for E2E testing with Optimism devnet
contract DeployTONStakingRAT is Script {
    // RAT parameters (configurable via environment variables)
    uint256 public slashingPenalty;      // C_off = 100 WTON (in RAY)
    uint256 public validatorBuffer;       // Δ_validator = 100 WTON (in RAY)
    uint256 public minimumThreshold;      // D_min = 200 WTON (in RAY)
    uint256 public ratTriggerProbability; // π_a = 1% (0.01 in RAY)
    uint256 public evidenceSubmissionPeriod; // 1 hour in seconds

    // External contract addresses
    address public seigManager;
    address public wton;
    address public ton;
    address public depositManager;
    address public layer2Manager;
    address public disputeGameFactory;
    address public l1BridgeRegistry;
    address public owner;
    address public treasury;

    // RAY constant (10^27)
    uint256 constant RAY = 1e27;

    function setUp() public {
        // Load parameters from environment variables or use defaults
        slashingPenalty = vm.envOr("RAT_SLASHING_PENALTY", uint256(100 * RAY));
        validatorBuffer = vm.envOr("RAT_VALIDATOR_BUFFER", uint256(100 * RAY));
        minimumThreshold = vm.envOr("RAT_MINIMUM_THRESHOLD", uint256(200 * RAY));
        ratTriggerProbability = vm.envOr("RAT_TRIGGER_PROBABILITY", uint256(RAY / 100)); // 1%
        evidenceSubmissionPeriod = vm.envOr("RAT_EVIDENCE_SUBMISSION_PERIOD", uint256(1 hours));

        // Load addresses from environment
        seigManager = vm.envAddress("SEIG_MANAGER");
        wton = vm.envAddress("WTON");
        ton = vm.envAddress("TON");
        depositManager = vm.envAddress("DEPOSIT_MANAGER");
        layer2Manager = vm.envAddress("LAYER2_MANAGER");
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY");
        l1BridgeRegistry = vm.envAddress("L1_BRIDGE_REGISTRY");
        owner = vm.envOr("RAT_OWNER", msg.sender);
        treasury = vm.envOr("RAT_TREASURY", msg.sender);
    }

    function run() external returns (address ratAddress) {
        vm.startBroadcast();

        // Deploy RAT implementation
        RAT ratImpl = new RAT();
        console.log("RAT Implementation deployed at:", address(ratImpl));

        // For devnet, we deploy without proxy for simplicity
        // In production, use TransparentUpgradeableProxy

        // Initialize RAT (V3: depositManager 제거)
        ratImpl.initialize(
            seigManager,
            wton,
            ton,
            layer2Manager,
            owner
        );
        console.log("RAT initialized with owner:", owner);

        // Set RAT parameters
        ratImpl.setSlashingPenalty(slashingPenalty);
        console.log("Slashing penalty set to:", slashingPenalty);

        ratImpl.setValidatorBuffer(validatorBuffer);
        console.log("Validator buffer set to:", validatorBuffer);

        ratImpl.setMinimumThreshold(minimumThreshold);
        console.log("Minimum threshold set to:", minimumThreshold);

        ratImpl.setRatTriggerProbability(ratTriggerProbability);
        console.log("RAT trigger probability set to:", ratTriggerProbability);

        ratImpl.setEvidenceSubmissionPeriod(evidenceSubmissionPeriod);
        console.log("Evidence submission period set to:", evidenceSubmissionPeriod);

        // Set L1BridgeRegistry for factory validation
        ratImpl.setL1BridgeRegistry(l1BridgeRegistry);
        console.log("L1BridgeRegistry set to:", l1BridgeRegistry);

        // Set treasury
        ratImpl.setTreasury(treasury);
        console.log("Treasury set to:", treasury);

        vm.stopBroadcast();

        console.log("========================================");
        console.log("RAT Deployment Complete");
        console.log("RAT Address:", address(ratImpl));
        console.log("========================================");

        return address(ratImpl);
    }
}

/// @title DeployTONStakingRATDevnet
/// @notice Simplified deployment for devnet testing
/// @dev Uses pre-funded accounts and mock addresses
contract DeployTONStakingRATDevnet is Script {
    // Devnet pre-funded account #10
    uint256 constant DEPLOY_PRIVATE_KEY = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;
    address constant DEPLOY_ADDRESS = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    // RAY constant
    uint256 constant RAY = 1e27;

    function run() external returns (address ratAddress) {
        // Use deployer's private key
        vm.startBroadcast(DEPLOY_PRIVATE_KEY);

        // Deploy RAT
        RAT rat = new RAT();
        console.log("RAT deployed at:", address(rat));

        // Initialize with mock addresses for devnet
        // These will be replaced with actual addresses from devnet-allocs
        address mockSeigManager = address(0x1001);
        address mockWton = address(0x1002);
        address mockTon = address(0x1003);
        address mockLayer2Manager = address(0x1005);

        rat.initialize(
            mockSeigManager,
            mockWton,
            mockTon,
            mockLayer2Manager,
            DEPLOY_ADDRESS
        );

        // Set default parameters
        rat.setSlashingPenalty(100 * RAY);      // 100 WTON
        rat.setValidatorBuffer(100 * RAY);       // 100 WTON
        rat.setMinimumThreshold(200 * RAY);      // 200 WTON
        rat.setRatTriggerProbability(RAY / 100); // 1%
        rat.setEvidenceSubmissionPeriod(1 hours);
        rat.setTreasury(DEPLOY_ADDRESS);

        vm.stopBroadcast();

        console.log("RAT Devnet Deployment Complete");
        console.log("RAT Address:", address(rat));

        return address(rat);
    }
}

/// @title DeployTONStakingRATForAllocs
/// @notice Deploy RAT and integrate with existing devnet-allocs
/// @dev Similar to asterisc's devnet_allocs.sh pattern
contract DeployTONStakingRATForAllocs is Script {
    uint256 constant RAY = 1e27;

    function run() external {
        // Read addresses from devnet deployment files
        string memory root = vm.projectRoot();
        string memory deployPath = string.concat(root, "/.devnet/addresses.json");

        // Check if deployment file exists
        if (!vm.exists(deployPath)) {
            console.log("ERROR: .devnet/addresses.json not found");
            console.log("Run 'make devnet-allocs' first");
            revert("Deployment file not found");
        }

        string memory json = vm.readFile(deployPath);

        // Parse addresses from JSON
        address disputeGameFactory = vm.parseJsonAddress(json, ".DisputeGameFactory");
        console.log("DisputeGameFactory:", disputeGameFactory);

        // Use environment variables for TON Staking addresses
        address seigManager = vm.envAddress("SEIG_MANAGER");
        address wton = vm.envAddress("WTON");
        address ton = vm.envAddress("TON");
        address depositManager = vm.envAddress("DEPOSIT_MANAGER");
        address layer2Manager = vm.envAddress("LAYER2_MANAGER");
        address l1BridgeRegistry = vm.envAddress("L1_BRIDGE_REGISTRY");

        vm.startBroadcast();

        // Deploy RAT
        RAT rat = new RAT();
        console.log("RAT deployed at:", address(rat));

        // Initialize (V3: depositManager 제거)
        rat.initialize(
            seigManager,
            wton,
            ton,
            layer2Manager,
            msg.sender
        );

        // Configure parameters
        rat.setSlashingPenalty(100 * RAY);
        rat.setValidatorBuffer(100 * RAY);
        rat.setMinimumThreshold(200 * RAY);
        rat.setRatTriggerProbability(RAY / 100);
        rat.setEvidenceSubmissionPeriod(1 hours);
        rat.setL1BridgeRegistry(l1BridgeRegistry);
        rat.setTreasury(msg.sender);

        vm.stopBroadcast();

        // Output deployment result
        console.log("========================================");
        console.log("RAT Deployment for Devnet Complete");
        console.log("RAT Address:", address(rat));
        console.log("");
        console.log("Next steps:");
        console.log("1. Update DisputeGameFactory to use RAT address");
        console.log("2. Register validators with RAT");
        console.log("========================================");
    }
}
