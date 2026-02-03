// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DeployV3Full.s.sol";

// Slashing Implementations
import {Layer2Manager_Slashing} from "../src/layer2/Layer2Manager_Slashing.sol";
import {SeigManager_Slashing} from "../src/stake/managers/SeigManager_Slashing.sol";
import {DepositManager_Slashing} from "../src/stake/managers/DepositManager_Slashing.sol";

// DAO Committee
import {DAOCommitteeProxy2} from "../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../src/dao/DAOCommitteeOwner.sol";
import {Candidate} from "../src/dao/Candidate.sol";
import {CandidateFactory} from "../src/dao/factory/CandidateFactory.sol";
import {CandidateFactoryProxy} from "../src/dao/factory/CandidateFactoryProxy.sol";
import {CandidateAddOnV1_1} from "../src/dao/CandidateAddOnV1_1.sol";
import {LotteryCandidate} from "../src/dao/LotteryCandidate.sol";
import {CandidateAddOnFactory} from "../src/dao/factory/CandidateAddOnFactory.sol";
import {CandidateAddOnFactoryProxy} from "../src/dao/factory/CandidateAddOnFactoryProxy.sol";
import {LotteryCandidateFactory} from "../src/dao/factory/LotteryCandidateFactory.sol";
import {LotteryCandidateFactoryProxy} from "../src/dao/factory/LotteryCandidateFactoryProxy.sol";

/**
 * @title DeployV3WithSlashing
 * @notice DeployV3Full을 상속받아 Slashing + DAO 기능을 추가하는 배포 스크립트
 * @dev Stack too deep 문제 해결을 위해 함수를 작게 분리
 */
contract DeployV3WithSlashing is DeployV3Full {
    // ==========================================
    // Slashing Implementations
    // ==========================================
    address public seigManagerSlashingImpl;
    address public depositManagerSlashingImpl;
    address public layer2ManagerSlashingImpl;

    // ==========================================
    // DAO Committee
    // ==========================================
    address public daoVault;
    address public daoAgendaManager;
    address public daoCommitteeProxy;
    DAOCommitteeProxy2 public daoCommitteeProxy2;
    DAOCommittee_V1 public daoCommitteeImpl;
    DAOCommitteeOwner public daoCommitteeOwner;
    Candidate public candidateImpl;
    CandidateFactory public candidateFactoryLogic;
    CandidateFactoryProxy public candidateFactoryProxy;
    CandidateAddOnV1_1 public candidateAddOnImpl;
    LotteryCandidate public lotteryCandidateImpl;
    CandidateAddOnFactory public candidateAddOnFactoryLogic;
    CandidateAddOnFactoryProxy public candidateAddOnFactoryProxy;
    LotteryCandidateFactory public lotteryCandidateFactoryLogic;
    LotteryCandidateFactoryProxy public lotteryCandidateFactoryProxy;

    // Slashing parameters
    uint256 constant SLASHING_REWARD_RATE = 1000; // 10% = 1000 (basis points)

    function run() external override {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);
        proxyAdmin = _getProxyAdmin(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 부모 클래스의 기본 배포 수행
        _deployTokens();
        _deployCoinageInfrastructure(deployer);
        _deployLayer2Registry(deployer);
        _deployManagerProxies();
        _deployManagerImplementations();

        // Slashing 구현체 배포 (초기화 전에)
        _deploySlashingImplementations();

        _initializeManagers(deployer);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(deployer);
        _deployV3Contracts(deployer);
        _setupCrossReferences(deployer);

        // DAO 배포
        _deployDAOVault();
        _deployDAOAgendaManager();
        _deployDAOCommittee();
        _addMinterSetting();
        _addSeigManagerSetting();
        _setupContractOwner();

        vm.stopBroadcast();

        _printSummaryWithSlashing();
        _saveDeploymentWithSlashing();
    }

    // ==========================================
    // Slashing 구현체 배포
    // ==========================================
    function _deploySlashingImplementations() internal {
        seigManagerSlashingImpl = address(new SeigManager_Slashing());
        depositManagerSlashingImpl = address(new DepositManager_Slashing());
        layer2ManagerSlashingImpl = address(new Layer2Manager_Slashing());
    }

    // ==========================================
    // Override: Initialize Managers with Slashing
    // ==========================================
    function _initializeManagers(address deployer) internal override {
        // 부모의 기본 초기화 호출
        super._initializeManagers(deployer);

        // Slashing routing 추가
        _setupSeigManagerSlashing();
        _setupDepositManagerSlashing();
    }

    function _setupSeigManagerSlashing() internal {
        SeigManagerProxy(payable(seigManagerProxy)).setAliveImplementation2(
            seigManagerSlashingImpl,
            true
        );
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = SeigManager_Slashing.onSlash.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(
            selectors,
            seigManagerSlashingImpl
        );
    }

    function _setupDepositManagerSlashing() internal {
        DepositManagerProxy(payable(depositManagerProxy)).setAliveImplementation2(
            depositManagerSlashingImpl,
            true
        );
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = DepositManager_Slashing.setSlashingRewardRate.selector;
        selectors[1] = DepositManager_Slashing.slash.selector;
        selectors[2] = bytes4(keccak256("slashingRewardRate()"));
        DepositManagerProxy(payable(depositManagerProxy)).setSelectorImplementations2(
            selectors,
            depositManagerSlashingImpl
        );

        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(
            SLASHING_REWARD_RATE
        );
    }

    // ==========================================
    // Override: Cross References with Slashing
    // ==========================================
    function _setupCrossReferences(address /* deployer */) internal override {
        // NOTE: We override this completely to skip setAddresses2 call
        // because we need to set daoCommitteeProxy as DAO later in _configureLayer2ManagerDAO

        _setupSeigManagerRefs();
        _setupLayer2ManagerRefsPartial(); // Only setAddresses1, skip setAddresses2
        _setupOtherManagerRefs();
        _setupLayer2ManagerSlashing();
    }

    /// @notice Setup Layer2Manager refs partially (only setAddresses1)
    /// @dev setAddresses2 will be called later in _configureLayer2ManagerDAO with daoCommitteeProxy
    function _setupLayer2ManagerRefsPartial() internal {
        Layer2ManagerV3(layer2ManagerProxy).setAddresses1(
            l1BridgeRegistryProxy,
            operatorManagerFactory,
            ton,
            wton
        );
        // NOTE: setAddresses2 is NOT called here - it will be called in _configureLayer2ManagerDAO
    }

    function _setupLayer2ManagerSlashing() internal {
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setAliveImplementation2(
            layer2ManagerSlashingImpl,
            true
        );
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = Layer2Manager_Slashing.slashingCandidate.selector;
        Layer2ManagerProxy(payable(layer2ManagerProxy)).setSelectorImplementations2(
            selectors,
            layer2ManagerSlashingImpl
        );
    }

    // ==========================================
    // DAO 배포 함수들 (분리해서 stack too deep 회피)
    // ==========================================
    function _deployDAOVault() internal {
        bytes memory args = abi.encode(ton, wton);
        daoVault = deployCode("abis/DAOVault.json", args);
    }

    function _deployDAOAgendaManager() internal {
        daoAgendaManager = deployCode("abis/DAOAgendaManager.json");
    }

    function _deployDAOCommittee() internal {
        _deployDAOCommitteeProxy();
        _deployDAOCommitteeImpl();
        _deployDAOCommitteeOwner();
        _deployCandidateFactory();
        _deployCandidateAddOnFactory();
        _deployLotteryCandidateFactory();
        _configureDAOCommittee();
        _configureLayer2ManagerDAO();
    }

    function _deployDAOCommitteeProxy() internal {
        daoCommitteeProxy2 = new DAOCommitteeProxy2();

        bytes memory args = abi.encode(
            ton,
            address(daoCommitteeProxy2),
            address(seigManagerProxy),
            address(layer2RegistryProxy),
            address(daoAgendaManager),
            address(1), // candidateFactory - 나중에 설정
            address(daoVault)
        );
        daoCommitteeProxy = deployCode("abis/DAOCommitteeProxy.json", args);
    }

    function _deployDAOCommitteeImpl() internal {
        daoCommitteeImpl = new DAOCommittee_V1();
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).upgradeTo2(address(daoCommitteeImpl));
    }

    function _deployDAOCommitteeOwner() internal {
        daoCommitteeOwner = new DAOCommitteeOwner();
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setAliveImplementation2(
            address(daoCommitteeOwner),
            true
        );
        _setupDAOOwnerSelectors1();
        _setupDAOOwnerSelectors2();
    }

    function _setupDAOOwnerSelectors1() internal {
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = DAOCommitteeOwner.setCooldownTime.selector;
        selectors[1] = DAOCommitteeOwner.setCandidateAddOnFactory.selector;
        selectors[2] = DAOCommitteeOwner.setLayer2Manager.selector;
        selectors[3] = DAOCommitteeOwner.setSeigManager.selector;
        selectors[4] = DAOCommitteeOwner.setDaoVault.selector;
        selectors[5] = DAOCommitteeOwner.setLayer2Registry.selector;
        selectors[6] = DAOCommitteeOwner.setAgendaManager.selector;
        selectors[7] = DAOCommitteeOwner.setCandidateFactory.selector;
        selectors[8] = DAOCommitteeOwner.setTon.selector;
        selectors[9] = DAOCommitteeOwner.setLotteryCandidateFactory.selector;
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setSelectorImplementations2(
            selectors,
            address(daoCommitteeOwner)
        );
    }

    function _setupDAOOwnerSelectors2() internal {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = DAOCommitteeOwner.setWton.selector;
        selectors[1] = DAOCommitteeOwner.increaseMaxMember.selector;
        selectors[2] = DAOCommitteeOwner.setQuorum.selector;
        selectors[3] = DAOCommitteeOwner.decreaseMaxMember.selector;
        selectors[4] = DAOCommitteeOwner.setActivityRewardPerSecond.selector;
        selectors[5] = DAOCommitteeOwner.setCandidatesSeigManager.selector;
        selectors[6] = DAOCommitteeOwner.setCandidatesCommittee.selector;
        selectors[7] = DAOCommitteeOwner.daoExecuteTransaction.selector;
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setSelectorImplementations2(
            selectors,
            address(daoCommitteeOwner)
        );
    }

    function _deployCandidateFactory() internal {
        candidateImpl = new Candidate();
        lotteryCandidateImpl = new LotteryCandidate();
        candidateFactoryLogic = new CandidateFactory();
        candidateFactoryProxy = new CandidateFactoryProxy();
        candidateFactoryProxy.upgradeTo(address(candidateFactoryLogic));

        CandidateFactory(address(candidateFactoryProxy)).setAddress(
            address(depositManagerProxy),
            daoCommitteeProxy,
            address(candidateImpl),
            ton,
            wton
        );
    }

    function _deployCandidateAddOnFactory() internal {
        candidateAddOnImpl = new CandidateAddOnV1_1();
        candidateAddOnFactoryLogic = new CandidateAddOnFactory();
        candidateAddOnFactoryProxy = new CandidateAddOnFactoryProxy();
        candidateAddOnFactoryProxy.upgradeTo(address(candidateAddOnFactoryLogic));

        CandidateAddOnFactory(address(candidateAddOnFactoryProxy)).setAddress(
            address(depositManagerProxy),
            daoCommitteeProxy,
            address(candidateAddOnImpl),
            ton,
            wton,
            address(l1BridgeRegistryProxy)
        );
    }

    function _deployLotteryCandidateFactory() internal {
        lotteryCandidateFactoryLogic = new LotteryCandidateFactory();
        lotteryCandidateFactoryProxy = new LotteryCandidateFactoryProxy();
        lotteryCandidateFactoryProxy.upgradeTo(address(lotteryCandidateFactoryLogic));

        LotteryCandidateFactory(address(lotteryCandidateFactoryProxy)).setAddress(
            address(depositManagerProxy),
            daoCommitteeProxy,
            address(lotteryCandidateImpl),
            ton,
            wton
        );
    }

    function _configureDAOCommittee() internal {
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(address(candidateFactoryProxy));
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(
            address(candidateAddOnFactoryProxy)
        );
        DAOCommitteeOwner(daoCommitteeProxy).setLotteryCandidateFactory(
            address(lotteryCandidateFactoryProxy)
        );
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(address(layer2ManagerProxy));
        DAOCommitteeOwner(daoCommitteeProxy).setWton(wton);
    }

    function _configureLayer2ManagerDAO() internal {
        // Note: setAddresses1 is already called in _setupLayer2ManagerRefsPartial
        // Now call setAddresses2 with daoCommitteeProxy as DAO
        Layer2ManagerV3(layer2ManagerProxy).setAddresses2(
            daoCommitteeProxy,
            depositManagerProxy,
            seigManagerProxy,
            address(0)
        );
    }

    function _addMinterSetting() internal {
        Layer2Registry(layer2RegistryProxy).addMinter(daoCommitteeProxy);
    }

    function _addSeigManagerSetting() internal {
        SeigManagerV1_2(seigManagerProxy).setData(
            address(0),
            daoCommitteeProxy,
            0,
            0.5e27,
            0.5e27,
            93096,
            1000.1e27
        );
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(1);
    }

    function _setupContractOwner() internal {
        _transferProxyOwnerships();
        _transferFactoryOwnerships();
    }

    function _transferProxyOwnerships() internal {
        SeigManagerProxy(payable(seigManagerProxy)).transferAdmin(daoCommitteeProxy);
        DepositManagerProxy(payable(depositManagerProxy)).transferOwnership(daoCommitteeProxy);
        Layer2RegistryProxy(payable(layer2RegistryProxy)).transferOwnership(daoCommitteeProxy);
        Layer2ManagerProxy(payable(layer2ManagerProxy)).transferOwnership(daoCommitteeProxy);
        L1BridgeRegistryProxy(payable(l1BridgeRegistryProxy)).transferAdmin(daoCommitteeProxy);
    }

    function _transferFactoryOwnerships() internal {
        CandidateFactoryProxy(payable(address(candidateFactoryProxy))).transferOwnership(
            daoCommitteeProxy
        );
        CandidateAddOnFactoryProxy(payable(address(candidateAddOnFactoryProxy))).transferOwnership(
            daoCommitteeProxy
        );
        LotteryCandidateFactoryProxy(payable(address(lotteryCandidateFactoryProxy))).transferOwnership(
            daoCommitteeProxy
        );
    }

    // ==========================================
    // Summary & Save
    // ==========================================
    function _printSummaryWithSlashing() internal view {
        console.log("=== Deployment Summary (With Slashing) ===");
        console.log("Tokens: TON=%s, WTON=%s", ton, wton);
        console.log("SeigManager Proxy:", seigManagerProxy);
        console.log("DepositManager Proxy:", depositManagerProxy);
        console.log("Layer2Manager Proxy:", layer2ManagerProxy);
        console.log("DAOCommittee Proxy:", daoCommitteeProxy);
        console.log(
            "Slashing Impls: Seig=%s, Deposit=%s, L2=%s",
            seigManagerSlashingImpl,
            depositManagerSlashingImpl,
            layer2ManagerSlashingImpl
        );
    }
    // ==========================================
    // Save Deployment JSON (stack-safe version)
    // ==========================================
    function _saveDeploymentWithSlashing() internal {
        // Step 1: 각각 개별적으로 저장 (스택 부하 최소화)
        string memory json = _jsonStart();
        json = string.concat(json, _jsonTokens());
        json = string.concat(json, _jsonCore());
        json = string.concat(json, _jsonManagers());
        json = string.concat(json, _jsonV3());
        json = string.concat(json, _jsonDAO());
        json = string.concat(json, _jsonEnd());

        vm.writeFile("deployments/v3-with-slashing.json", json);
    }

    function _jsonStart() internal pure returns (string memory) {
        return "{\n";
    }

    function _jsonTokens() internal view returns (string memory) {
        return
            string.concat(
                '  "ton": "',
                vm.toString(ton),
                '",\n',
                '  "wton": "',
                vm.toString(wton),
                '",\n'
            );
    }

    function _jsonCore() internal view returns (string memory) {
        return
            string.concat(
                '  "coinageFactory": "',
                vm.toString(coinageFactory),
                '",\n',
                '  "layer2RegistryProxy": "',
                vm.toString(layer2RegistryProxy),
                '",\n'
            );
    }

    function _jsonManagers() internal view returns (string memory) {
        string memory part1 = string.concat(
            '  "seigManagerProxy": "',
            vm.toString(seigManagerProxy),
            '",\n'
        );
        string memory part2 = string.concat(
            '  "depositManagerProxy": "',
            vm.toString(depositManagerProxy),
            '",\n'
        );
        string memory part3 = string.concat(
            '  "layer2ManagerProxy": "',
            vm.toString(layer2ManagerProxy),
            '",\n'
        );
        string memory part4 = string.concat(
            '  "l1BridgeRegistryProxy": "',
            vm.toString(l1BridgeRegistryProxy),
            '",\n'
        );
        string memory part5 = string.concat(
            '  "operatorManagerFactory": "',
            vm.toString(operatorManagerFactory),
            '",\n'
        );
        return string.concat(part1, part2, part3, part4, part5);
    }

    function _jsonV3() internal view returns (string memory) {
        return
            string.concat(
                '  "ratProxy": "',
                vm.toString(ratProxy),
                '",\n',
                '  "validatorPoolProxy": "',
                vm.toString(validatorPoolProxy),
                '",\n'
            );
    }

    function _jsonDAO() internal view returns (string memory) {
        string memory part1 = string.concat('  "daoVault": "', vm.toString(daoVault), '",\n');
        string memory part2 = string.concat(
            '  "daoAgendaManager": "',
            vm.toString(daoAgendaManager),
            '",\n'
        );
        string memory part3 = string.concat(
            '  "daoCommitteeProxy": "',
            vm.toString(daoCommitteeProxy),
            '",\n'
        );
        string memory part4 = string.concat(
            '  "candidateFactoryProxy": "',
            vm.toString(address(candidateFactoryProxy)),
            '",\n'
        );
        string memory part5 = string.concat(
            '  "candidateAddOnFactoryProxy": "',
            vm.toString(address(candidateAddOnFactoryProxy)),
            '"\n'
        );
        return string.concat(part1, part2, part3, part4, part5);
    }

    function _jsonEnd() internal pure returns (string memory) {
        return "}";
    }
}
