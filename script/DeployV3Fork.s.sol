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
import {ValidatorRewardV1} from "../src/validator/ValidatorRewardV1.sol";
import {ValidatorRewardProxy} from "../src/validator/ValidatorRewardProxy.sol";

/// @notice Proxy interface
interface IProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
}

/**
 * @title DeployV3Fork
 * @notice 메인넷 포크에서 V3 배포 스크립트
 * @dev forge script script/DeployV3Fork.s.sol:DeployV3Fork --fork-url $MAINNET_RPC_URL -vvvv
 *
 * 이 스크립트는 새 구현체와 V3 컨트랙트만 배포합니다.
 * 프록시 업그레이드는 DAO 아젠다를 통해 별도로 진행해야 합니다.
 */
contract DeployV3Fork is Script {
    // ==========================================
    // Mainnet Addresses
    // From: docs/deployed-addresses-mainnet.md
    // ==========================================

    address constant TON = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;

    address constant SEIG_MANAGER_PROXY = 0x0b55a0f463b6DEFb81c6063973763951712D0E5F;
    address constant DEPOSIT_MANAGER_PROXY = 0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E;
    address constant LAYER2_MANAGER_PROXY = 0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D;
    address constant L1_BRIDGE_REGISTRY_PROXY = 0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4;

    // ==========================================
    // Deployed Addresses (output)
    // ==========================================

    address public seigManagerV1_4Impl;
    address public depositManagerV1_2Impl;
    address public layer2ManagerV1_2Impl;
    address public l1BridgeRegistryV1_2Impl;

    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== V3 Fork Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // ==========================================
        // Step 1: Deploy new implementations
        // ==========================================
        console.log("\n--- Step 1: Deploy Implementations ---");

        seigManagerV1_4Impl = address(new SeigManagerV1_4());
        console.log("SeigManagerV1_4:", seigManagerV1_4Impl);

        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        console.log("DepositManagerV1_2:", depositManagerV1_2Impl);

        layer2ManagerV1_2Impl = address(new Layer2ManagerV1_2());
        console.log("Layer2ManagerV1_2:", layer2ManagerV1_2Impl);

        l1BridgeRegistryV1_2Impl = address(new L1BridgeRegistryV1_2());
        console.log("L1BridgeRegistryV1_2:", l1BridgeRegistryV1_2Impl);

        // ==========================================
        // Step 2: Deploy V3 new contracts (RAT, ValidatorReward)
        // ==========================================
        console.log("\n--- Step 2: Deploy V3 Contracts ---");

        // Deploy RAT implementation
        ratImpl = address(new RAT());

        // Prepare RAT initialization data (V3: depositManager 제거)
        bytes memory ratInitData = abi.encodeWithSelector(
            RAT.initialize.selector,
            SEIG_MANAGER_PROXY,
            WTON,
            TON,
            LAYER2_MANAGER_PROXY,
            deployer
        );

        // Deploy RAT proxy with implementation and init data
        ratProxy = address(new RATProxy(ratImpl, deployer, ratInitData));
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT Impl:", ratImpl);

        // Deploy ValidatorReward implementation
        validatorPoolImpl = address(new ValidatorRewardV1());

        // Prepare ValidatorReward initialization data
        bytes memory validatorRewardInitData = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            SEIG_MANAGER_PROXY,
            WTON,
            ratProxy,   // RAT contract for validator info
            deployer,   // treasury (DAO)
            deployer    // owner
        );

        // Deploy ValidatorReward proxy with implementation and init data
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, deployer, validatorRewardInitData));
        console.log("ValidatorReward Proxy:", validatorPoolProxy);
        console.log("ValidatorReward Impl:", validatorPoolImpl);

        vm.stopBroadcast();

        // ==========================================
        // Step 3: Output DAO agenda items
        // ==========================================
        console.log("\n=== DAO Agenda Required ===");
        console.log("The following proxy upgrades require DAO approval:");
        console.log("");
        console.log("1. SeigManager Proxy Upgrade:");
        console.log("   Proxy:", SEIG_MANAGER_PROXY);
        console.log("   New Impl:", seigManagerV1_4Impl);
        console.log("");
        console.log("2. DepositManager Proxy Upgrade:");
        console.log("   Proxy:", DEPOSIT_MANAGER_PROXY);
        console.log("   New Impl:", depositManagerV1_2Impl);
        console.log("");
        console.log("3. Layer2Manager Proxy Upgrade:");
        console.log("   Proxy:", LAYER2_MANAGER_PROXY);
        console.log("   New Impl:", layer2ManagerV1_2Impl);
        console.log("");
        console.log("4. L1BridgeRegistry Proxy Upgrade:");
        console.log("   Proxy:", L1_BRIDGE_REGISTRY_PROXY);
        console.log("   New Impl:", l1BridgeRegistryV1_2Impl);

        // Save deployment info
        _saveDeployment();
    }

    function _saveDeployment() internal {
        string memory output = string(abi.encodePacked(
            "{\n",
            '  "seigManagerV1_4Impl": "', vm.toString(seigManagerV1_4Impl), '",\n',
            '  "depositManagerV1_2Impl": "', vm.toString(depositManagerV1_2Impl), '",\n',
            '  "layer2ManagerV1_2Impl": "', vm.toString(layer2ManagerV1_2Impl), '",\n',
            '  "l1BridgeRegistryV1_2Impl": "', vm.toString(l1BridgeRegistryV1_2Impl), '",\n',
            '  "ratProxy": "', vm.toString(ratProxy), '",\n',
            '  "ratImpl": "', vm.toString(ratImpl), '",\n',
            '  "validatorPoolProxy": "', vm.toString(validatorPoolProxy), '",\n',
            '  "validatorPoolImpl": "', vm.toString(validatorPoolImpl), '"\n',
            "}"
        ));

        vm.writeFile("deployments/v3-mainnet-fork.json", output);
        console.log("\nDeployment saved to deployments/v3-mainnet-fork.json");
    }
}

/**
 * @title DeployV3ForkWithImpersonation
 * @notice 포크 테스트용 - DAO impersonation으로 프록시 업그레이드 포함
 * @dev forge script script/DeployV3Fork.s.sol:DeployV3ForkWithImpersonation --fork-url $MAINNET_RPC_URL -vvvv
 */
contract DeployV3ForkWithImpersonation is Script {
    // Mainnet Addresses
    address constant TON = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;

    address constant SEIG_MANAGER_PROXY = 0x0b55a0f463b6DEFb81c6063973763951712D0E5F;
    address constant DEPOSIT_MANAGER_PROXY = 0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E;
    address constant LAYER2_MANAGER_PROXY = 0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D;
    address constant L1_BRIDGE_REGISTRY_PROXY = 0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4;

    // DAO Committee (proxy owner)
    address constant DAO_COMMITTEE = 0xDD9f0cCc044B0781289Ee318e5971b0139602C26;

    address public seigManagerV1_4Impl;
    address public depositManagerV1_2Impl;
    address public layer2ManagerV1_2Impl;
    address public l1BridgeRegistryV1_2Impl;

    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;

    function run() external {
        address deployer = address(0x1234);
        vm.deal(deployer, 100 ether);

        console.log("=== V3 Fork Deployment with Impersonation ===");

        // Step 1: Deploy implementations
        vm.startPrank(deployer);

        seigManagerV1_4Impl = address(new SeigManagerV1_4());
        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        layer2ManagerV1_2Impl = address(new Layer2ManagerV1_2());
        l1BridgeRegistryV1_2Impl = address(new L1BridgeRegistryV1_2());

        console.log("SeigManagerV1_4:", seigManagerV1_4Impl);
        console.log("DepositManagerV1_2:", depositManagerV1_2Impl);
        console.log("Layer2ManagerV1_2:", layer2ManagerV1_2Impl);
        console.log("L1BridgeRegistryV1_2:", l1BridgeRegistryV1_2Impl);

        // Step 2: Deploy V3 contracts
        ratImpl = address(new RAT());
        bytes memory ratInitData = abi.encodeWithSelector(
            RAT.initialize.selector,
            SEIG_MANAGER_PROXY, WTON, TON, LAYER2_MANAGER_PROXY, deployer
        );
        ratProxy = address(new RATProxy(ratImpl, deployer, ratInitData));

        validatorPoolImpl = address(new ValidatorRewardV1());
        bytes memory validatorRewardInitData = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            SEIG_MANAGER_PROXY, WTON, ratProxy, deployer, deployer
        );
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, deployer, validatorRewardInitData));

        console.log("RAT Proxy:", ratProxy);
        console.log("ValidatorReward Proxy:", validatorPoolProxy);

        vm.stopPrank();

        // Step 3: Upgrade proxies (impersonate DAO)
        console.log("\n--- Upgrading Proxies (DAO Impersonation) ---");

        vm.startPrank(DAO_COMMITTEE);

        IProxy(SEIG_MANAGER_PROXY).upgradeTo(seigManagerV1_4Impl);
        console.log("SeigManager upgraded");

        IProxy(DEPOSIT_MANAGER_PROXY).upgradeTo(depositManagerV1_2Impl);
        console.log("DepositManager upgraded");

        IProxy(LAYER2_MANAGER_PROXY).upgradeTo(layer2ManagerV1_2Impl);
        console.log("Layer2Manager upgraded");

        IProxy(L1_BRIDGE_REGISTRY_PROXY).upgradeTo(l1BridgeRegistryV1_2Impl);
        console.log("L1BridgeRegistry upgraded");

        vm.stopPrank();

        console.log("\n=== Deployment Complete ===");
    }
}

/**
 * @title DeployV3ForkSepolia
 * @notice Sepolia 포크에서 V3 배포 스크립트
 * @dev forge script script/DeployV3Fork.s.sol:DeployV3ForkSepolia --fork-url $SEPOLIA_RPC_URL -vvvv
 */
contract DeployV3ForkSepolia is Script {
    // ==========================================
    // Sepolia Addresses
    // ==========================================

    // From: docs/deployed-addresses-sepolia.md
    address constant TON = 0xa30fe40285B8f5c0457DbC3B7C8A280373c40044;
    address constant WTON = 0x79E0d92670106c85E9067b56B8F674340dCa0Bbd;

    address constant SEIG_MANAGER_PROXY = 0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7;
    address constant DEPOSIT_MANAGER_PROXY = 0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F;
    address constant LAYER2_MANAGER_PROXY = 0x58B4C2FEf19f5CDdd944AadD8DC99cCC71bfeFDc;
    address constant L1_BRIDGE_REGISTRY_PROXY = 0x2D47fa57101203855b336e9E61BC9da0A6dd0Dbc;

    // Deployed Addresses (output)
    address public seigManagerV1_4Impl;
    address public depositManagerV1_2Impl;
    address public layer2ManagerV1_2Impl;
    address public l1BridgeRegistryV1_2Impl;

    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== V3 Sepolia Fork Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy implementations
        console.log("\n--- Step 1: Deploy Implementations ---");

        seigManagerV1_4Impl = address(new SeigManagerV1_4());
        console.log("SeigManagerV1_4:", seigManagerV1_4Impl);

        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        console.log("DepositManagerV1_2:", depositManagerV1_2Impl);

        layer2ManagerV1_2Impl = address(new Layer2ManagerV1_2());
        console.log("Layer2ManagerV1_2:", layer2ManagerV1_2Impl);

        l1BridgeRegistryV1_2Impl = address(new L1BridgeRegistryV1_2());
        console.log("L1BridgeRegistryV1_2:", l1BridgeRegistryV1_2Impl);

        // Step 2: Deploy V3 contracts
        console.log("\n--- Step 2: Deploy V3 Contracts ---");

        ratImpl = address(new RAT());
        bytes memory ratInitData = abi.encodeWithSelector(
            RAT.initialize.selector,
            SEIG_MANAGER_PROXY,
            WTON,
            TON,
            LAYER2_MANAGER_PROXY,
            deployer
        );
        ratProxy = address(new RATProxy(ratImpl, deployer, ratInitData));
        console.log("RAT Proxy:", ratProxy);
        console.log("RAT Impl:", ratImpl);

        validatorPoolImpl = address(new ValidatorRewardV1());
        bytes memory validatorRewardInitData = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            SEIG_MANAGER_PROXY,
            WTON,
            ratProxy,   // RAT contract for validator info
            deployer,   // treasury (DAO)
            deployer    // owner
        );
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, deployer, validatorRewardInitData));
        console.log("ValidatorReward Proxy:", validatorPoolProxy);
        console.log("ValidatorReward Impl:", validatorPoolImpl);

        vm.stopBroadcast();

        // Output
        console.log("\n=== DAO Agenda Required (Sepolia) ===");
        console.log("1. SeigManager: ", SEIG_MANAGER_PROXY, " -> ", seigManagerV1_4Impl);
        console.log("2. DepositManager: ", DEPOSIT_MANAGER_PROXY, " -> ", depositManagerV1_2Impl);
        console.log("3. Layer2Manager: ", LAYER2_MANAGER_PROXY, " -> ", layer2ManagerV1_2Impl);
        console.log("4. L1BridgeRegistry: ", L1_BRIDGE_REGISTRY_PROXY, " -> ", l1BridgeRegistryV1_2Impl);

        _saveDeployment();
    }

    function _saveDeployment() internal {
        string memory output = string(abi.encodePacked(
            "{\n",
            '  "seigManagerV1_4Impl": "', vm.toString(seigManagerV1_4Impl), '",\n',
            '  "depositManagerV1_2Impl": "', vm.toString(depositManagerV1_2Impl), '",\n',
            '  "layer2ManagerV1_2Impl": "', vm.toString(layer2ManagerV1_2Impl), '",\n',
            '  "l1BridgeRegistryV1_2Impl": "', vm.toString(l1BridgeRegistryV1_2Impl), '",\n',
            '  "ratProxy": "', vm.toString(ratProxy), '",\n',
            '  "ratImpl": "', vm.toString(ratImpl), '",\n',
            '  "validatorPoolProxy": "', vm.toString(validatorPoolProxy), '",\n',
            '  "validatorPoolImpl": "', vm.toString(validatorPoolImpl), '"\n',
            "}"
        ));

        vm.writeFile("deployments/v3-sepolia-fork.json", output);
        console.log("\nDeployment saved to deployments/v3-sepolia-fork.json");
    }
}
