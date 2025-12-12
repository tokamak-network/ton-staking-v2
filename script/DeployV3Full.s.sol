// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// V3 Implementations
import {SeigManagerV1_4} from "../src/stake/managers/SeigManagerV1_4.sol";
import {DepositManagerV1_2} from "../src/stake/managers/DepositManagerV1_2.sol";
import {Layer2ManagerV1_2} from "../src/layer2/Layer2ManagerV1_2.sol";
import {L1BridgeRegistryV1_2} from "../src/layer2/L1BridgeRegistryV1_2.sol";

// V3 New Contracts
import {RAT} from "../src/validator/RAT.sol";
import {RATProxy} from "../src/validator/RATProxy.sol";
import {ValidatorPoolV1} from "../src/validator/ValidatorPoolV1.sol";
import {ValidatorPoolProxy} from "../src/validator/ValidatorPoolProxy.sol";

// Mocks for testing
import {MockTON} from "../test/v3/mocks/MockTON.sol";
import {MockWTON} from "../test/v3/mocks/MockWTON.sol";

/// @notice Proxy interface
interface IProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
}

/**
 * @title DeployV3Full
 * @notice 테스트넷용 전체 배포 스크립트 (처음부터 모든 것을 배포)
 * @dev forge script script/DeployV3Full.s.sol:DeployV3Full --rpc-url $LOCAL_RPC_URL --broadcast -vvvv
 *
 * 이 스크립트는 테스트 환경에서 TON Staking V3 전체 시스템을 배포합니다.
 * - Mock TON/WTON 배포
 * - 모든 매니저 컨트랙트 프록시 배포
 * - V3 신규 컨트랙트 (RAT, ValidatorPool) 배포
 */
contract DeployV3Full is Script {
    // ==========================================
    // Deployed Addresses
    // ==========================================

    // Tokens
    address public ton;
    address public wton;

    // Managers (Proxies)
    address public seigManagerProxy;
    address public depositManagerProxy;
    address public layer2ManagerProxy;
    address public l1BridgeRegistryProxy;

    // Implementations
    address public seigManagerImpl;
    address public depositManagerImpl;
    address public layer2ManagerImpl;
    address public l1BridgeRegistryImpl;

    // V3 Contracts
    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;

    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== V3 Full Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // ==========================================
        // Step 1: Deploy Mock Tokens
        // ==========================================
        console.log("\n--- Step 1: Deploy Tokens ---");

        ton = address(new MockTON());
        console.log("TON:", ton);

        MockWTON wtonContract = new MockWTON();
        wtonContract.setTON(ton);
        wton = address(wtonContract);
        console.log("WTON:", wton);

        // ==========================================
        // Step 2: Deploy Manager Implementations
        // ==========================================
        console.log("\n--- Step 2: Deploy Implementations ---");

        seigManagerImpl = address(new SeigManagerV1_4());
        console.log("SeigManagerV1_4 Impl:", seigManagerImpl);

        depositManagerImpl = address(new DepositManagerV1_2());
        console.log("DepositManagerV1_2 Impl:", depositManagerImpl);

        layer2ManagerImpl = address(new Layer2ManagerV1_2());
        console.log("Layer2ManagerV1_2 Impl:", layer2ManagerImpl);

        l1BridgeRegistryImpl = address(new L1BridgeRegistryV1_2());
        console.log("L1BridgeRegistryV1_2 Impl:", l1BridgeRegistryImpl);

        // ==========================================
        // Step 3: Deploy V3 Contracts
        // ==========================================
        console.log("\n--- Step 3: Deploy V3 Contracts ---");

        // RAT
        ratImpl = address(new RAT());
        ratProxy = address(new RATProxy());
        IProxy(ratProxy).upgradeTo(ratImpl);
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT Impl:", ratImpl);

        // ValidatorPool
        validatorPoolImpl = address(new ValidatorPoolV1());
        validatorPoolProxy = address(new ValidatorPoolProxy());
        IProxy(validatorPoolProxy).upgradeTo(validatorPoolImpl);
        console.log("ValidatorPool Proxy:", validatorPoolProxy);
        console.log("ValidatorPool Impl:", validatorPoolImpl);

        // ==========================================
        // Step 4: Initialize V3 Contracts
        // ==========================================
        console.log("\n--- Step 4: Initialize Contracts ---");

        // Note: In full deployment, seigManagerProxy would be deployed first
        // For now, use placeholder (deployer) for seigManager reference
        address seigManagerPlaceholder = deployer;

        RAT(ratProxy).initialize(
            seigManagerPlaceholder,
            wton,
            ton,
            deployer, // depositManager placeholder
            deployer
        );
        console.log("RAT initialized");

        ValidatorPoolV1(validatorPoolProxy).initialize(
            seigManagerPlaceholder,
            wton,
            ton,
            deployer
        );
        console.log("ValidatorPool initialized");

        // ==========================================
        // Step 5: Configure V3 Parameters
        // ==========================================
        console.log("\n--- Step 5: Configure Parameters ---");

        // RAT parameters
        RAT(ratProxy).setRatTriggerProbability(0.01e27);     // 1%
        RAT(ratProxy).setSlashingPenalty(100e27);           // 100 WTON
        RAT(ratProxy).setValidatorBuffer(100e27);           // 100 WTON
        RAT(ratProxy).setMinimumThreshold(1000e27);         // 1000 WTON
        RAT(ratProxy).setEvidenceSubmissionPeriod(1 hours);
        console.log("RAT parameters set");

        // ValidatorPool parameters
        ValidatorPoolV1(validatorPoolProxy).setSlashingPenalty(100e27);
        ValidatorPoolV1(validatorPoolProxy).setMinimumThreshold(1000e27);
        ValidatorPoolV1(validatorPoolProxy).setRatProbability(0.01e27);
        ValidatorPoolV1(validatorPoolProxy).setRatResponseWindow(1 hours);
        console.log("ValidatorPool parameters set");

        vm.stopBroadcast();

        // ==========================================
        // Output Summary
        // ==========================================
        console.log("\n=== Deployment Summary ===");
        console.log("TON:", ton);
        console.log("WTON:", wton);
        console.log("SeigManager Impl:", seigManagerImpl);
        console.log("DepositManager Impl:", depositManagerImpl);
        console.log("Layer2Manager Impl:", layer2ManagerImpl);
        console.log("L1BridgeRegistry Impl:", l1BridgeRegistryImpl);
        console.log("RAT Proxy:", ratProxy);
        console.log("ValidatorPool Proxy:", validatorPoolProxy);

        _saveDeployment();
    }

    function _saveDeployment() internal {
        string memory output = string(abi.encodePacked(
            "{\n",
            '  "ton": "', vm.toString(ton), '",\n',
            '  "wton": "', vm.toString(wton), '",\n',
            '  "seigManagerImpl": "', vm.toString(seigManagerImpl), '",\n',
            '  "depositManagerImpl": "', vm.toString(depositManagerImpl), '",\n',
            '  "layer2ManagerImpl": "', vm.toString(layer2ManagerImpl), '",\n',
            '  "l1BridgeRegistryImpl": "', vm.toString(l1BridgeRegistryImpl), '",\n',
            '  "ratProxy": "', vm.toString(ratProxy), '",\n',
            '  "ratImpl": "', vm.toString(ratImpl), '",\n',
            '  "validatorPoolProxy": "', vm.toString(validatorPoolProxy), '",\n',
            '  "validatorPoolImpl": "', vm.toString(validatorPoolImpl), '"\n',
            "}"
        ));

        vm.writeFile("deployments/v3-full.json", output);
        console.log("\nDeployment saved to deployments/v3-full.json");
    }
}

/**
 * @title DeployV3FullLocal
 * @notice 로컬 Anvil 테스트용 간소화된 배포
 * @dev anvil 실행 후: forge script script/DeployV3Full.s.sol:DeployV3FullLocal --rpc-url http://localhost:8545 --broadcast -vvvv
 */
contract DeployV3FullLocal is Script {
    function run() external {
        // Anvil default private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== V3 Local Deployment ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        MockTON tonContract = new MockTON();
        MockWTON wtonContractLocal = new MockWTON();
        wtonContractLocal.setTON(address(tonContract));

        console.log("TON:", address(tonContract));
        console.log("WTON:", address(wtonContractLocal));

        // Deploy V3 implementations
        address seigImpl = address(new SeigManagerV1_4());
        address depositImpl = address(new DepositManagerV1_2());
        address layer2Impl = address(new Layer2ManagerV1_2());
        address l1BridgeImpl = address(new L1BridgeRegistryV1_2());

        console.log("SeigManagerV1_4:", seigImpl);
        console.log("DepositManagerV1_2:", depositImpl);
        console.log("Layer2ManagerV1_2:", layer2Impl);
        console.log("L1BridgeRegistryV1_2:", l1BridgeImpl);

        // Deploy RAT
        address ratImplAddr = address(new RAT());
        RATProxy ratProxyContract = new RATProxy();
        IProxy(address(ratProxyContract)).upgradeTo(ratImplAddr);
        RAT(address(ratProxyContract)).initialize(
            deployer, // seigManager placeholder
            address(wtonContractLocal),
            address(tonContract),
            deployer, // depositManager placeholder
            deployer
        );

        console.log("RAT Proxy:", address(ratProxyContract));

        // Deploy ValidatorPool
        address vpImplAddr = address(new ValidatorPoolV1());
        ValidatorPoolProxy vpProxyContract = new ValidatorPoolProxy();
        IProxy(address(vpProxyContract)).upgradeTo(vpImplAddr);
        ValidatorPoolV1(address(vpProxyContract)).initialize(
            deployer,
            address(wtonContractLocal),
            address(tonContract),
            deployer
        );

        console.log("ValidatorPool Proxy:", address(vpProxyContract));

        vm.stopBroadcast();

        console.log("\n=== Local Deployment Complete ===");
    }
}
