// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Import interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Import contracts for verification - V3
import {L1BridgeRegistryV1_2} from "../src/layer2/L1BridgeRegistryV1_2.sol";
import {Layer2ManagerV3} from "../src/layer2/Layer2ManagerV3.sol";
import {SeigManagerV3_1} from "../src/stake/managers/SeigManagerV3_1.sol";
import {RAT} from "../src/validator/RAT.sol";

/// @notice Minimal interface for DisputeGameFactory verification
interface IDisputeGameFactoryMinimal {
    function rat() external view returns (address);
    function systemConfig() external view returns (address);
    function initBonds(uint32 gameType) external view returns (uint256);
}

/**
 * @title VerifyGenesisSetup
 * @notice Verifies that genesis setup is correct
 *
 * This script verifies:
 * 1. Genesis-only settings (contract deployments, basic initialize)
 * 2. Runtime settings (V3 parameters, L1BridgeRegistry mappings)
 *
 * Run with --verify-runtime to also check runtime configuration.
 */
contract VerifyGenesisSetup is Script {
    // Addresses loaded from addresses.json
    address public ton;
    address public wton;
    address public ratProxy;
    address public l1BridgeRegistryProxy;
    address public layer2ManagerProxy;
    address public seigManagerProxy;
    address public depositManagerProxy;
    address public validatorRewardProxy;
    address public disputeGameFactory;
    address public systemConfig;
    address public daoCommitteeProxy;
    address public mockLayer2;
    address public operatorManager;

    // Test accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant TON_STAKING_DEPLOYER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant VALIDATOR = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    uint256 public errorCount = 0;
    uint256 public checkCount = 0;

    // No longer using direct slot reads - using view functions instead

    function run() external {
        console.log("=== Verifying Genesis Setup ===");
        console.log("");

        // Load addresses from JSON
        _loadAddresses();

        // Run genesis-only checks
        console.log("========================================");
        console.log("  PHASE 1: Genesis-Only Verification");
        console.log("========================================");
        console.log("");

        _verifyContractDeployments();
        _verifyRATGenesisStorage();
        _verifyDisputeGameFactoryStorage();
        _verifyLayer2ManagerStorage();
        _verifyDepositManagerConfiguration();
        _verifyValidatorRewardConfiguration();
        _verifyDAOConfiguration();
        _verifyTokenPermissions();
        _verifyTokenBalances();

        // Check if runtime verification is requested
        bool verifyRuntime = vm.envOr("VERIFY_RUNTIME", false);

        if (verifyRuntime) {
            console.log("");
            console.log("========================================");
            console.log("  PHASE 2: Runtime Configuration Check");
            console.log("========================================");
            console.log("");

            _verifyRATRuntimeStorage();
            _verifyL1BridgeRegistryMappings();
            _verifySeigManagerV3();
        } else {
            console.log("");
            console.log("NOTE: Runtime verification skipped.");
            console.log("Set VERIFY_RUNTIME=true to also check runtime configuration.");
        }

        // Print summary
        console.log("");
        console.log("=== Verification Summary ===");
        console.log("Total checks:", checkCount);
        console.log("Failed checks:", errorCount);

        if (errorCount == 0) {
            console.log("");
            console.log("All checks passed!");
        } else {
            console.log("");
            console.log(errorCount, "check(s) failed!");
            revert("Genesis verification failed");
        }
    }

    function _loadAddresses() internal {
        console.log("--- Loading Addresses ---");

        // Load addresses from environment variables
        ton = vm.envAddress("TON");
        wton = vm.envAddress("WTON");
        ratProxy = vm.envAddress("RAT_PROXY");
        l1BridgeRegistryProxy = vm.envAddress("L1_BRIDGE_REGISTRY_PROXY");
        layer2ManagerProxy = vm.envAddress("LAYER2_MANAGER_PROXY");
        seigManagerProxy = vm.envAddress("SEIG_MANAGER_PROXY");
        depositManagerProxy = vm.envAddress("DEPOSIT_MANAGER_PROXY");
        validatorRewardProxy = vm.envAddress("VALIDATOR_REWARD_PROXY");
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY");
        systemConfig = vm.envAddress("SYSTEM_CONFIG");
        daoCommitteeProxy = vm.envAddress("DAO_COMMITTEE_PROXY");
        mockLayer2 = vm.envAddress("MOCK_LAYER2");
        operatorManager = vm.envAddress("OPERATOR_MANAGER");

        console.log("Addresses loaded from environment");
        console.log("");
    }

    function _verifyContractDeployments() internal {
        console.log("--- Verifying Contract Deployments ---");

        _check("TON deployed", ton.code.length > 0);
        _check("WTON deployed", wton.code.length > 0);
        _check("RAT deployed", ratProxy.code.length > 0);
        _check("L1BridgeRegistry deployed", l1BridgeRegistryProxy.code.length > 0);
        _check("Layer2Manager deployed", layer2ManagerProxy.code.length > 0);
        _check("SeigManager deployed", seigManagerProxy.code.length > 0);
        _check("DepositManager deployed", depositManagerProxy.code.length > 0);
        _check("ValidatorReward deployed", validatorRewardProxy.code.length > 0);
        _check("DAO deployed", daoCommitteeProxy.code.length > 0);
        _check("DisputeGameFactory deployed", disputeGameFactory.code.length > 0);
        _check("SystemConfig deployed", systemConfig.code.length > 0);

        console.log("");
    }

    function _verifyRATGenesisStorage() internal {
        console.log("--- Verifying RAT Genesis Storage (from initialize) ---");

        RAT rat = RAT(payable(ratProxy));

        // These values should be set by RAT.initialize()

        // slashingPenalty (10 WTON)
        uint256 slashingPenalty = rat.slashingPenalty();
        _check("RAT.slashingPenalty() = 10 WTON", slashingPenalty == 10e27);
        console.log("  slashingPenalty:", slashingPenalty / 1e27, "WTON");

        // validatorBuffer (50 WTON)
        uint256 validatorBuffer = rat.validatorBuffer();
        _check("RAT.validatorBuffer() = 50 WTON", validatorBuffer == 50e27);
        console.log("  validatorBuffer:", validatorBuffer / 1e27, "WTON");

        // ratTriggerProbability (1e27 = 100%)
        uint256 triggerProb = rat.ratTriggerProbability();
        _check("RAT.ratTriggerProbability() = 1e27 (100%)", triggerProb == 1e27);
        console.log("  ratTriggerProbability:", triggerProb);

        // minimumThreshold (60 WTON)
        uint256 minThreshold = rat.minimumThreshold();
        _check("RAT.minimumThreshold() = 60 WTON", minThreshold == 60e27);
        console.log("  minimumThreshold:", minThreshold / 1e27, "WTON");

        // evidenceSubmissionPeriod (3600 seconds)
        uint256 evidencePeriod = rat.evidenceSubmissionPeriod();
        _check("RAT.evidenceSubmissionPeriod() = 3600", evidencePeriod == 3600);
        console.log("  evidenceSubmissionPeriod:", evidencePeriod, "seconds");

        // seigManager
        address seigManagerAddr = rat.seigManager();
        _check("RAT.seigManager() = seigManagerProxy", seigManagerAddr == seigManagerProxy);
        console.log("  seigManager:", seigManagerAddr);

        // wton
        address wtonAddr = rat.wton();
        _check("RAT.wton() = wton", wtonAddr == wton);
        console.log("  wton:", wtonAddr);

        // ton
        address tonAddr = rat.ton();
        _check("RAT.ton() = ton", tonAddr == ton);
        console.log("  ton:", tonAddr);

        // layer2Manager
        address layer2ManagerAddr = rat.layer2Manager();
        _check("RAT.layer2Manager() = layer2ManagerProxy", layer2ManagerAddr == layer2ManagerProxy);
        console.log("  layer2Manager:", layer2ManagerAddr);

        // owner check via AccessControl (should be deployer)
        bool hasAdminRole = rat.hasRole(rat.DEFAULT_ADMIN_ROLE(), TON_STAKING_DEPLOYER);
        _check("RAT.hasRole(DEFAULT_ADMIN_ROLE, deployer) = true", hasAdminRole);
        console.log("  deployer has admin role:", hasAdminRole);

        console.log("");
    }

    function _verifyRATRuntimeStorage() internal {
        console.log("--- Verifying RAT Runtime Storage (set after genesis) ---");

        RAT rat = RAT(payable(ratProxy));

        // l1BridgeRegistry (set at runtime)
        address l1BridgeReg = rat.l1BridgeRegistry();
        _check("RAT.l1BridgeRegistry() = l1BridgeRegistryProxy", l1BridgeReg == l1BridgeRegistryProxy);
        console.log("  l1BridgeRegistry:", l1BridgeReg);

        // relaxedValidatorCheck (should be true)
        bool relaxedCheck = rat.relaxedValidatorCheck();
        _check("RAT.relaxedValidatorCheck() = true", relaxedCheck);
        console.log("  relaxedValidatorCheck:", relaxedCheck);

        console.log("");
    }

    function _verifyDisputeGameFactoryStorage() internal {
        console.log("--- Verifying DisputeGameFactory Storage ---");

        IDisputeGameFactoryMinimal dgf = IDisputeGameFactoryMinimal(disputeGameFactory);

        // RAT address
        address dgfRat = dgf.rat();
        _check("DGF.rat() = ratProxy", dgfRat == ratProxy);
        console.log("  rat:", dgfRat);

        // SystemConfig address
        address dgfSystemConfig = dgf.systemConfig();
        _check("DGF.systemConfig() = systemConfig", dgfSystemConfig == systemConfig);
        console.log("  systemConfig:", dgfSystemConfig);

        // initBonds[GameType 0]
        uint256 initBond = dgf.initBonds(0);
        _check("DGF.initBonds(0) = 0.08 ETH", initBond == 0.08 ether);
        console.log("  initBonds(0):", initBond / 1e18, "ETH");

        console.log("");
    }

    function _verifyL1BridgeRegistryMappings() internal {
        console.log("--- Verifying L1BridgeRegistry Mappings (Runtime) ---");

        L1BridgeRegistryV1_2 registry = L1BridgeRegistryV1_2(l1BridgeRegistryProxy);

        // Check disputeGameFactory[systemConfig] = true
        bool isDGFRegistered = registry.disputeGameFactory(systemConfig);
        _check("disputeGameFactory[systemConfig] = true", isDGFRegistered);
        console.log("  disputeGameFactory[systemConfig]:", isDGFRegistered);

        // Check rollupConfigWithDisputeGameFactory[dgf] = systemConfig
        address registeredSystemConfig = registry.rollupConfigWithDisputeGameFactory(disputeGameFactory);
        _check("rollupConfigWithDisputeGameFactory[dgf] = systemConfig", registeredSystemConfig == systemConfig);
        console.log("  rollupConfigWithDisputeGameFactory[dgf]:", registeredSystemConfig);

        console.log("");
    }

    function _verifyLayer2ManagerStorage() internal {
        console.log("--- Verifying Layer2Manager Storage ---");

        Layer2ManagerV3 layer2Manager = Layer2ManagerV3(layer2ManagerProxy);

        // Check getLayer2BySystemConfig via function call
        address registeredLayer2 = layer2Manager.getLayer2BySystemConfig(systemConfig);
        _check("getLayer2BySystemConfig != 0", registeredLayer2 != address(0));
        _check("getLayer2BySystemConfig = mockLayer2", registeredLayer2 == mockLayer2);
        console.log("  getLayer2BySystemConfig:", registeredLayer2);
        _check("Layer2 contract deployed", registeredLayer2.code.length > 0);

        // Check rollupConfigInfo[systemConfig]
        (uint8 status, address storedOperatorManager) = layer2Manager.rollupConfigInfo(systemConfig);
        _check("rollupConfigInfo.status > 0", status > 0);
        _check("rollupConfigInfo.operatorManager = operatorManager", storedOperatorManager == operatorManager);
        console.log("  rollupConfigInfo.status:", status);
        console.log("  rollupConfigInfo.operatorManager:", storedOperatorManager);

        // Check operatorInfo[operatorManager]
        (address storedRollupConfig, address storedCandidateAddOn) = layer2Manager.operatorInfo(operatorManager);
        _check("operatorInfo.rollupConfig = systemConfig", storedRollupConfig == systemConfig);
        _check("operatorInfo.candidateAddOn = layer2", storedCandidateAddOn == mockLayer2);
        console.log("  operatorInfo.candidateAddOn:", storedCandidateAddOn);

        console.log("");
    }

    function _verifySeigManagerV3() internal {
        console.log("--- Verifying SeigManager V3 Configuration (Runtime) ---");

        SeigManagerV3_1 seigManager = SeigManagerV3_1(seigManagerProxy);

        // Check v3Migrated
        bool v3Migrated = seigManager.v3Migrated();
        _check("v3Migrated() = true", v3Migrated);
        console.log("  v3Migrated:", v3Migrated);

        // Check ratContract using view function
        address ratContractAddr = seigManager.ratContract();
        _check("SeigManager.ratContract() = ratProxy", ratContractAddr == ratProxy);
        console.log("  ratContract:", ratContractAddr);

        // Check validatorReward
        address validatorReward = seigManager.validatorReward();
        _check("validatorReward() = validatorRewardProxy", validatorReward == validatorRewardProxy);
        console.log("  validatorReward:", validatorReward);

        // Check maxChallengers
        uint256 maxChallengers = seigManager.maxChallengers();
        _check("maxChallengers() > 0", maxChallengers > 0);
        console.log("  maxChallengers:", maxChallengers);

        // Check V3 distribution ratios
        uint256 daoDistributionRatio = seigManager.daoDistributionRatio();
        _check("daoDistributionRatio() > 0", daoDistributionRatio > 0);
        console.log("  daoDistributionRatio:", daoDistributionRatio / 1e25, "%");

        console.log("");
    }

    function _verifyTokenBalances() internal {
        console.log("--- Verifying Token Balances ---");

        IERC20 tonToken = IERC20(ton);
        IERC20 wtonToken = IERC20(wton);

        // Check deployer balances
        uint256 deployerTON = tonToken.balanceOf(DEPLOYER);
        uint256 deployerWTON = wtonToken.balanceOf(DEPLOYER);
        _check("Deployer has TON", deployerTON > 0);
        _check("Deployer has WTON", deployerWTON > 0);
        console.log("  Deployer TON:", deployerTON / 1e18);
        console.log("  Deployer WTON:", deployerWTON / 1e27);

        // Check validator balances
        uint256 validatorTON = tonToken.balanceOf(VALIDATOR);
        uint256 validatorWTON = wtonToken.balanceOf(VALIDATOR);
        _check("Validator has TON", validatorTON > 0);
        _check("Validator has WTON", validatorWTON > 0);
        console.log("  Validator TON:", validatorTON / 1e18);
        console.log("  Validator WTON:", validatorWTON / 1e27);

        console.log("");
    }

    function _verifyDepositManagerConfiguration() internal {
        console.log("--- Verifying DepositManager Configuration ---");

        // Check WTON address
        (bool success, bytes memory data) = depositManagerProxy.staticcall(abi.encodeWithSignature("wton()"));
        require(success, "Failed to call wton()");
        address depositManagerWTON = abi.decode(data, (address));
        _check("DepositManager.wton() = wton", depositManagerWTON == wton);
        console.log("  wton:", depositManagerWTON);

        // Check SeigManager address
        (success, data) = depositManagerProxy.staticcall(abi.encodeWithSignature("seigManager()"));
        require(success, "Failed to call seigManager()");
        address depositManagerSeigManager = abi.decode(data, (address));
        _check("DepositManager.seigManager() = seigManagerProxy", depositManagerSeigManager == seigManagerProxy);
        console.log("  seigManager:", depositManagerSeigManager);

        console.log("");
    }

    function _verifyValidatorRewardConfiguration() internal {
        console.log("--- Verifying ValidatorReward Configuration ---");

        // Check WTON address
        (bool success, bytes memory data) = validatorRewardProxy.staticcall(abi.encodeWithSignature("wton()"));
        require(success, "Failed to call wton()");
        address validatorRewardWTON = abi.decode(data, (address));
        _check("ValidatorReward.wton() = wton", validatorRewardWTON == wton);
        console.log("  wton:", validatorRewardWTON);

        // Check SeigManager address
        (success, data) = validatorRewardProxy.staticcall(abi.encodeWithSignature("seigManager()"));
        require(success, "Failed to call seigManager()");
        address validatorRewardSeigManager = abi.decode(data, (address));
        _check("ValidatorReward.seigManager() = seigManagerProxy", validatorRewardSeigManager == seigManagerProxy);
        console.log("  seigManager:", validatorRewardSeigManager);

        console.log("");
    }

    function _verifyDAOConfiguration() internal {
        console.log("--- Verifying DAO Configuration ---");

        // Check DAO contract is deployed
        _check("DAO contract deployed", daoCommitteeProxy.code.length > 0);
        console.log("  daoCommitteeProxy:", daoCommitteeProxy);

        console.log("");
    }

    function _verifyTokenPermissions() internal {
        console.log("--- Verifying Token Permissions ---");

        // Check WTON minter role for SeigManager
        (bool success, bytes memory data) = wton.staticcall(
            abi.encodeWithSignature("isMinter(address)", seigManagerProxy)
        );
        if (success && data.length > 0) {
            bool seigManagerIsMinter = abi.decode(data, (bool));
            _check("SeigManager is WTON minter", seigManagerIsMinter);
            console.log("  SeigManager is WTON minter:", seigManagerIsMinter);
        }

        // Check WTON minter role for DepositManager
        (success, data) = wton.staticcall(
            abi.encodeWithSignature("isMinter(address)", depositManagerProxy)
        );
        if (success && data.length > 0) {
            bool depositManagerIsMinter = abi.decode(data, (bool));
            _check("DepositManager is WTON minter", depositManagerIsMinter);
            console.log("  DepositManager is WTON minter:", depositManagerIsMinter);
        }

        console.log("");
    }

    function _check(string memory description, bool condition) internal {
        checkCount++;
        if (condition) {
            console.log("[PASS]", description);
        } else {
            console.log("[FAIL]", description);
            errorCount++;
        }
    }
}
