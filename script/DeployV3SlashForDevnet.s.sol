// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Core Infrastructure
import {CoinageFactory} from "../src/stake/factory/CoinageFactory.sol";
import {RefactorCoinageSnapshot} from "../src/stake/tokens/RefactorCoinageSnapshot.sol";
import {Layer2Registry} from "../src/stake/Layer2Registry.sol";
import {Layer2RegistryProxy} from "../src/stake/Layer2RegistryProxy.sol";

// Manager Implementations
import {SeigManagerV1_2} from "../src/stake/managers/SeigManagerV1_2.sol";
import {SeigManagerV1_3} from "../src/stake/managers/SeigManagerV1_3.sol";
import {SeigManagerV1_4} from "../src/stake/managers/SeigManagerV1_4.sol";
import {DepositManager} from "../src/stake/managers/DepositManager.sol";
import {
    DepositManager_setWithdrawalDelay
} from "../src/stake/managers/DepositManager_setWithdrawalDelay.sol";
import {DepositManagerV1_1} from "../src/stake/managers/DepositManagerV1_1.sol";
import {DepositManagerV1_2} from "../src/stake/managers/DepositManagerV1_2.sol";
import {Layer2ManagerV1_1} from "../src/layer2/Layer2ManagerV1_1.sol";
import {Layer2ManagerV1_2} from "../src/layer2/Layer2ManagerV1_2.sol";
import {L1BridgeRegistryV1_2} from "../src/layer2/L1BridgeRegistryV1_2.sol";
import {Layer2Manager_Slashing} from "../src/layer2/Layer2Manager_Slashing.sol";

// Slashing Implementations
import {SeigManager_Slashing} from "../src/stake/managers/SeigManager_Slashing.sol";
import {DepositManager_Slashing} from "../src/stake/managers/DepositManager_Slashing.sol";

// Manager Proxies
import {SeigManagerProxy} from "../src/stake/managers/SeigManagerProxy.sol";
import {DepositManagerProxy} from "../src/stake/managers/DepositManagerProxy.sol";
import {Layer2ManagerProxy} from "../src/layer2/Layer2ManagerProxy.sol";
import {L1BridgeRegistryProxy} from "../src/layer2/L1BridgeRegistryProxy.sol";

// Operator Manager
import {OperatorManagerFactory} from "../src/layer2/factory/OperatorManagerFactory.sol";
import {OperatorManagerV1_2} from "../src/layer2/OperatorManagerV1_2.sol";

// V3 New Contracts
import {RAT} from "../src/validator/RAT.sol";
import {RATProxy} from "../src/validator/RATProxy.sol";
import {ValidatorRewardV1} from "../src/validator/ValidatorRewardV1.sol";
import {ValidatorRewardProxy} from "../src/validator/ValidatorRewardProxy.sol";
import {SequencerVault} from "../src/sequencer/SequencerVault.sol";
import {SequencerVaultProxy} from "../src/sequencer/SequencerVaultProxy.sol";

// DAO Committee
import {DAOCommitteeProxy2} from "../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../src/dao/DAOCommitteeOwner.sol";
import {Candidate} from "../src/dao/Candidate.sol";
import {CandidateFactory} from "../src/dao/factory/CandidateFactory.sol";
import {CandidateFactoryProxy} from "../src/dao/factory/CandidateFactoryProxy.sol";
import {CandidateAddOnV1_1} from "../src/dao/CandidateAddOnV1_1.sol";
import {CandidateAddOnFactory} from "../src/dao/factory/CandidateAddOnFactory.sol";
import {CandidateAddOnFactoryProxy} from "../src/dao/factory/CandidateAddOnFactoryProxy.sol";

// Interfaces
import {IWTON} from "../src/dao/interfaces/IWTON.sol";

interface IProxy {
    function upgradeTo(address impl) external;
    function transferOwnership(address newOwner) external;
}

interface IAdminProxy {
    function transferAdmin(address newAdmin) external;
}

interface IMinter {
    function addMinter(address account) external;
}

contract DeployV3SlashForDevnet is Script {
    // ==========================================
    // Devnet Configuration
    // ==========================================
    address constant OPTIMISM_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant DEPLOYER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant PROXY_ADMIN = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    uint256 constant RAY = 1e27;
    uint256 constant SEIG_PER_BLOCK = 3.92e18;
    uint256 constant GLOBAL_WITHDRAWAL_DELAY = 10;

    // RAT parameters
    uint256 constant RAT_TRIGGER_PROBABILITY = 1e27; // 100%
    uint256 constant RAT_SLASHING_PENALTY = 100 * 1e27;
    uint256 constant RAT_VALIDATOR_BUFFER = 100 * 1e27;
    uint256 constant RAT_MINIMUM_THRESHOLD = 200 * 1e27;
    uint256 constant RAT_EVIDENCE_PERIOD = 1 hours;

    // ==========================================
    // Deployed Addresses
    // ==========================================
    address public ton;
    address public wton;
    address public coinageFactory;
    address public coinageLogic;
    address public layer2RegistryProxy;
    address public layer2RegistryImpl;

    address public seigManagerProxy;
    address public depositManagerProxy;
    address public layer2ManagerProxy;
    address public l1BridgeRegistryProxy;

    address public seigManagerV1_2Impl;
    address public seigManagerV1_3Impl;
    address public seigManagerImpl;
    address public depositManagerBaseImpl;
    address public depositManagerSetDelayImpl;
    address public depositManagerV1_1Impl;
    address public depositManagerV1_2Impl;
    address public layer2ManagerV1_1Impl;
    address public layer2ManagerImpl;
    address public l1BridgeRegistryImpl;

    address public seigManagerSlashingImpl;
    address public depositManagerSlashingImpl;
    address public layer2ManagerSlashingImpl;

    address public operatorManagerFactory;
    address public operatorManagerImpl;

    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;
    address public sequencerVaultProxy;
    address public sequencerVaultImpl;

    // DAO Contracts
    address public daoVault;
    address public daoAgendaManager;
    address public daoCommitteeProxy;
    address public daoCommitteeProxy2;
    address public daoCommitteeImpl;
    address public daoCommitteeOwner;
    address public candidateImpl;
    address public candidateFactoryProxy;
    address public candidateAddOnFactoryProxy;

    function run() public {
        _loadOptimismAddresses();
        vm.startBroadcast(DEPLOYER);
        address deployer = DEPLOYER;

        console.log("=== TON Staking V3 Devnet Slash Deployment ===");

        // 1. Core Base
        _deployTokens();
        _deployCoinageInfrastructure();
        _deployLayer2Registry();
        _deployManagerProxies();
        _deployManagerImplementations();

        // 2. DAO Layer (New from SlashingE2E_improved_Deploy)
        _deployDAOVault();
        _deployDAOAgendaManager();
        _deployDAOCommittee();

        // 3. Managers & V3 Connect
        _initializeManagers(deployer);
        _setupMinterPermissions();
        _deployOperatorManagerFactory();
        _deployV3Contracts(deployer);
        _configureV3Contracts(deployer);

        // 4. Final Wiring
        _setupCrossReferences(deployer);
        _setupGovernanceOwnership(); // Transfers ownership to DAO

        vm.stopBroadcast();
        _printSummary();
    }

    function _loadOptimismAddresses() internal {}

    function _deployTokens() internal {
        console.log("--- Step 1: Deploy Tokens (via ABI) ---");

        // TON 배포
        ton = deployCode("./abis/TON.json");
        console.log("TON deployed at:", ton);

        // WTON 배포
        bytes memory wtonArgs = abi.encode(ton);
        wton = deployCode("./abis/WTON.json", wtonArgs);
        console.log("WTON deployed at:", wton);
    }

    function _deployCoinageInfrastructure() internal {
        console.log("--- Step 2: Deploy Coinage Infrastructure ---");
        coinageLogic = address(new RefactorCoinageSnapshot());
        CoinageFactory factory = new CoinageFactory();
        factory.setAutoCoinageLogic(coinageLogic);
        coinageFactory = address(factory);
    }

    function _deployLayer2Registry() internal {
        console.log("--- Step 3: Deploy Layer2Registry ---");
        layer2RegistryImpl = address(new Layer2Registry());
        Layer2RegistryProxy registryProxy = new Layer2RegistryProxy();
        IProxy(address(registryProxy)).upgradeTo(layer2RegistryImpl);
        layer2RegistryProxy = address(registryProxy);
    }

    function _deployManagerProxies() internal {
        console.log("--- Step 4: Deploy Manager Proxies ---");
        seigManagerProxy = address(new SeigManagerProxy());
        depositManagerProxy = address(new DepositManagerProxy());
        layer2ManagerProxy = address(new Layer2ManagerProxy());
        l1BridgeRegistryProxy = address(new L1BridgeRegistryProxy());
    }

    function _deployManagerImplementations() internal {
        console.log("--- Step 5: Deploy Manager Implementations ---");
        seigManagerV1_2Impl = address(new SeigManagerV1_2());
        seigManagerV1_3Impl = address(new SeigManagerV1_3());
        seigManagerImpl = address(new SeigManagerV1_4());

        depositManagerBaseImpl = address(new DepositManager());
        depositManagerSetDelayImpl = address(new DepositManager_setWithdrawalDelay());
        depositManagerV1_1Impl = address(new DepositManagerV1_1());
        depositManagerV1_2Impl = address(new DepositManagerV1_2());

        layer2ManagerV1_1Impl = address(new Layer2ManagerV1_1());
        layer2ManagerImpl = address(new Layer2ManagerV1_2());
        l1BridgeRegistryImpl = address(new L1BridgeRegistryV1_2());

        seigManagerSlashingImpl = address(new SeigManager_Slashing());
        depositManagerSlashingImpl = address(new DepositManager_Slashing());
        layer2ManagerSlashingImpl = address(new Layer2Manager_Slashing());
    }

    function _deployDAOVault() internal {
        console.log("--- Step DAO-1: Deploy DAOVault ---");
        bytes memory args = abi.encode(ton, wton);
        daoVault = deployCode("./abis/DAOVault.json", args);
        console.log("DAOVault:", daoVault);
    }

    function _deployDAOAgendaManager() internal {
        console.log("--- Step DAO-2: Deploy DAOAgendaManager ---");
        daoAgendaManager = deployCode("./abis/DAOAgendaManager.json");
        console.log("DAOAgendaManager:", daoAgendaManager);
    }

    function _deployDAOCommittee() internal {
        console.log("--- Step DAO-3: Deploy DAOCommittee ---");
        daoCommitteeProxy2 = address(new DAOCommitteeProxy2());

        bytes memory args = abi.encode(
            ton,
            daoCommitteeProxy2,
            seigManagerProxy,
            layer2RegistryProxy,
            daoAgendaManager,
            address(1), // temp factory
            daoVault
        );
        daoCommitteeProxy = deployCode("./abis/DAOCommitteeProxy.json", args);

        daoCommitteeImpl = address(new DAOCommittee_V1());
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).upgradeTo2(daoCommitteeImpl);

        daoCommitteeOwner = address(new DAOCommitteeOwner());
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setAliveImplementation2(
            daoCommitteeOwner,
            true
        );

        // Map selectors
        bytes4[] memory ownerSelectors = new bytes4[](17);
        ownerSelectors[0] = DAOCommitteeOwner.setCooldownTime.selector;
        ownerSelectors[1] = DAOCommitteeOwner.setCandidateAddOnFactory.selector;
        ownerSelectors[2] = DAOCommitteeOwner.setLayer2Manager.selector;
        ownerSelectors[3] = DAOCommitteeOwner.setSeigManager.selector;
        ownerSelectors[4] = DAOCommitteeOwner.setDaoVault.selector;
        ownerSelectors[5] = DAOCommitteeOwner.setLayer2Registry.selector;
        ownerSelectors[6] = DAOCommitteeOwner.setAgendaManager.selector;
        ownerSelectors[7] = DAOCommitteeOwner.setCandidateFactory.selector;
        ownerSelectors[8] = DAOCommitteeOwner.setTon.selector;
        ownerSelectors[9] = DAOCommitteeOwner.setWton.selector;
        ownerSelectors[10] = DAOCommitteeOwner.increaseMaxMember.selector;
        ownerSelectors[11] = DAOCommitteeOwner.setQuorum.selector;
        ownerSelectors[12] = DAOCommitteeOwner.decreaseMaxMember.selector;
        ownerSelectors[13] = DAOCommitteeOwner.setActivityRewardPerSecond.selector;
        ownerSelectors[14] = DAOCommitteeOwner.setCandidatesSeigManager.selector;
        ownerSelectors[15] = DAOCommitteeOwner.setCandidatesCommittee.selector;
        ownerSelectors[16] = DAOCommitteeOwner.daoExecuteTransaction.selector;
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setSelectorImplementations2(
            ownerSelectors,
            daoCommitteeOwner
        );

        candidateImpl = address(new Candidate());
        CandidateFactory cFactory = new CandidateFactory();
        candidateFactoryProxy = address(new CandidateFactoryProxy());
        IProxy(candidateFactoryProxy).upgradeTo(address(cFactory));
        cFactory.setAddress(depositManagerProxy, daoCommitteeProxy, candidateImpl, ton, wton);

        address cAddOnImpl = address(new CandidateAddOnV1_1());
        CandidateAddOnFactory cAddOnFactory = new CandidateAddOnFactory();
        candidateAddOnFactoryProxy = address(new CandidateAddOnFactoryProxy());
        IProxy(candidateAddOnFactoryProxy).upgradeTo(address(cAddOnFactory));
        cAddOnFactory.setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            cAddOnImpl,
            ton,
            wton,
            l1BridgeRegistryProxy
        );

        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(candidateFactoryProxy);
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(candidateAddOnFactoryProxy);

        console.log("DAOCommitteeProxy:", daoCommitteeProxy);
    }

    function _initializeManagers(address deployer) internal {
        console.log("--- Step 6: Initialize Managers ---");
        IProxy(seigManagerProxy).upgradeTo(seigManagerV1_2Impl);
        SeigManagerV1_2(seigManagerProxy).initialize(
            ton,
            wton,
            layer2RegistryProxy,
            depositManagerProxy,
            SEIG_PER_BLOCK,
            coinageFactory,
            block.number
        );

        // Initial setup with DAOCommittee as the DAO address
        SeigManagerV1_2(seigManagerProxy).setData(
            address(0),
            daoCommitteeProxy,
            0,
            0.5e27,
            0.5e27,
            10,
            1000.1e27
        );

        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
            seigManagerV1_3Impl,
            true
        );
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(seigManagerImpl, true);
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
            seigManagerSlashingImpl,
            true
        );

        _setupSeigManagerSelectors();

        IProxy(depositManagerProxy).upgradeTo(depositManagerBaseImpl);
        DepositManager(depositManagerProxy).initialize(
            wton,
            layer2RegistryProxy,
            seigManagerProxy,
            GLOBAL_WITHDRAWAL_DELAY,
            address(0)
        );

        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
            depositManagerSetDelayImpl,
            true
        );
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
            depositManagerV1_1Impl,
            true
        );
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
            depositManagerV1_2Impl,
            true
        );
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
            depositManagerSlashingImpl,
            true
        );

        _setupDepositManagerSelectors();
    }

    function _setupSeigManagerSelectors() internal {
        bytes4[] memory v1_3S = new bytes4[](6);
        v1_3S[0] = SeigManagerV1_3.pause.selector;
        v1_3S[1] = SeigManagerV1_3.unpause.selector;
        v1_3S[2] = SeigManagerV1_3.excludeFromL2Seigniorage.selector;
        v1_3S[3] = SeigManagerV1_3.includeFromL2Seigniorage.selector;
        v1_3S[4] = SeigManagerV1_3.claimableL2Seigniorage.selector;
        v1_3S[5] = SeigManagerV1_3.estimatedDistribute.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
            v1_3S,
            seigManagerV1_3Impl
        );

        bytes4[] memory slashingS = new bytes4[](1);
        slashingS[0] = SeigManager_Slashing.onSlash.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
            slashingS,
            seigManagerSlashingImpl
        );
    }

    function _setupDepositManagerSelectors() internal {
        bytes4[] memory slashingS = new bytes4[](2);
        slashingS[0] = DepositManager_Slashing.slash.selector;
        slashingS[1] = DepositManager_Slashing.setSlashingRewardRate.selector;
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(
            slashingS,
            depositManagerSlashingImpl
        );
    }

    function _setupMinterPermissions() internal {
        Layer2Registry(layer2RegistryProxy).addMinter(seigManagerProxy);
        IMinter(wton).addMinter(seigManagerProxy);
        Layer2Registry(layer2RegistryProxy).addMinter(daoCommitteeProxy);
    }

    function _deployOperatorManagerFactory() internal {
        operatorManagerImpl = address(new OperatorManagerV1_2());
        operatorManagerFactory = address(new OperatorManagerFactory(operatorManagerImpl));
        OperatorManagerFactory(operatorManagerFactory).setAddresses(
            depositManagerProxy,
            ton,
            wton,
            layer2ManagerProxy
        );
    }

    function _deployV3Contracts(address deployer) internal {
        ratImpl = address(new RAT());
        bytes memory ratInit = abi.encodeWithSelector(
            RAT.initialize.selector,
            seigManagerProxy,
            wton,
            ton,
            layer2ManagerProxy,
            deployer,
            RAT_TRIGGER_PROBABILITY
        );
        ratProxy = address(new RATProxy(ratImpl, PROXY_ADMIN, ratInit));

        validatorPoolImpl = address(new ValidatorRewardV1());
        bytes memory vPoolInit = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            seigManagerProxy,
            wton,
            ratProxy,
            deployer
        );
        validatorPoolProxy = address(
            new ValidatorRewardProxy(validatorPoolImpl, PROXY_ADMIN, vPoolInit)
        );

        sequencerVaultImpl = address(new SequencerVault());
        sequencerVaultProxy = address(new SequencerVaultProxy());
        IProxy(sequencerVaultProxy).upgradeTo(sequencerVaultImpl);
        SequencerVault(sequencerVaultProxy).initialize(
            seigManagerProxy,
            wton,
            ton,
            layer2ManagerProxy,
            l1BridgeRegistryProxy,
            deployer
        );
    }

    function _configureV3Contracts(address) internal {
        RAT(ratProxy).setL1BridgeRegistry(l1BridgeRegistryProxy);
        DepositManager_Slashing(depositManagerProxy).setSlashingRewardRate(1000);
    }

    function _setupCrossReferences(address deployer) internal {
        SeigManagerV1_2(seigManagerProxy).setLayer2Manager(layer2ManagerProxy);
        SeigManagerV1_4(seigManagerProxy).setValidatorReward(validatorPoolProxy);

        IProxy(layer2ManagerProxy).upgradeTo(layer2ManagerV1_1Impl);
        Layer2ManagerV1_1(layer2ManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton,
            daoCommitteeProxy,
            depositManagerProxy,
            seigManagerProxy,
            address(0)
        );

        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(
            layer2ManagerImpl,
            true
        );
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(
            layer2ManagerSlashingImpl,
            true
        );

        bytes4[] memory slashingS = new bytes4[](1);
        slashingS[0] = Layer2Manager_Slashing.slashingCandidate.selector;
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(
            slashingS,
            layer2ManagerSlashingImpl
        );

        IProxy(l1BridgeRegistryProxy).upgradeTo(l1BridgeRegistryImpl);
        L1BridgeRegistryV1_2(l1BridgeRegistryProxy).setAddresses(
            layer2ManagerProxy,
            seigManagerProxy,
            ton
        );

        DepositManagerV1_1(depositManagerProxy).setAddresses(
            l1BridgeRegistryProxy,
            layer2ManagerProxy
        );
    }

    function _setupGovernanceOwnership() internal {
        console.log("--- Step governance: Transferring Admin to DAO ---");
        IAdminProxy(seigManagerProxy).transferAdmin(daoCommitteeProxy);
        IProxy(depositManagerProxy).transferOwnership(daoCommitteeProxy);
        IProxy(layer2RegistryProxy).transferOwnership(daoCommitteeProxy);
        IProxy(layer2ManagerProxy).transferOwnership(daoCommitteeProxy);
        IAdminProxy(l1BridgeRegistryProxy).transferAdmin(daoCommitteeProxy);
    }

    function _printSummary() internal {
        console.log("-----------------------------------------");
        console.log("Deployment Summary:");
        console.log("DAOCommitteeProxy:", daoCommitteeProxy);
        console.log("Layer2ManagerProxy:", layer2ManagerProxy);
        console.log("DepositManagerProxy:", depositManagerProxy);
        console.log("SeigManagerProxy:", seigManagerProxy);
        console.log("-----------------------------------------");
    }
}
