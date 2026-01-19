// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// DAO Implementations (0.8.4)
import {DAOCommitteeProxy2} from "../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../src/dao/DAOCommitteeOwner.sol";
import {Candidate} from "../src/dao/Candidate.sol";
import {CandidateAddOnV1_1} from "../src/dao/CandidateAddOnV1_1.sol";

// Factories
import {CandidateFactory} from "../src/dao/factory/CandidateFactory.sol";
import {CandidateFactoryProxy} from "../src/dao/factory/CandidateFactoryProxy.sol";
import {CandidateAddOnFactory} from "../src/dao/factory/CandidateAddOnFactory.sol";
import {CandidateAddOnFactoryProxy} from "../src/dao/factory/CandidateAddOnFactoryProxy.sol";

/// @notice Interface for DAOCommitteeProxy (0.7.6 contract)
interface IDAOCommitteeProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
}

/// @notice Interface for DAOCommitteeProxy2
interface IDAOCommitteeProxy2 {
    function upgradeTo2(address impl) external;
    function setAliveImplementation2(address impl, bool alive) external;
    function setSelectorImplementations2(bytes4[] calldata selectors, address impl) external;
    function implementation2(uint256 index) external view returns (address);
}

/**
 * @title DeployDAO
 * @notice DAO 컨트랙트 배포 스크립트 (Phase 6.5)
 * @dev
 * 사전 요구사항:
 * - DAOCommitteeProxy가 이미 배포되어 있어야 함 (0.7.6 버전)
 * - TON, WTON, SeigManagerProxy, DepositManagerProxy, Layer2RegistryProxy 주소 필요
 *
 * 환경변수:
 * - DAO_COMMITTEE_PROXY: 기존 DAOCommitteeProxy 주소 (필수)
 * - TON_ADDRESS: TON 토큰 주소
 * - WTON_ADDRESS: WTON 토큰 주소
 * - SEIG_MANAGER_PROXY: SeigManager 프록시 주소
 * - DEPOSIT_MANAGER_PROXY: DepositManager 프록시 주소
 * - LAYER2_MANAGER_PROXY: Layer2Manager 프록시 주소
 *
 * 사용법:
 * forge script script/DeployDAO.s.sol:DeployDAO \
 *   --rpc-url $RPC_URL \
 *   --broadcast \
 *   -vvvv
 */
contract DeployDAO is Script {
    // ==========================================
    // Deployed Addresses
    // ==========================================

    // Input addresses (from environment)
    address public daoCommitteeProxy;
    address public ton;
    address public wton;
    address public seigManagerProxy;
    address public depositManagerProxy;
    address public layer2ManagerProxy;

    // DAO Implementations
    address public daoCommitteeProxy2;
    address public daoCommitteeV1;
    address public daoCommitteeOwner;

    // Candidate
    address public candidateImpl;
    address public candidateAddOnImpl;

    // Factories
    address public candidateFactoryProxy;
    address public candidateFactoryImpl;
    address public candidateAddOnFactoryProxy;
    address public candidateAddOnFactoryImpl;

    function run() external virtual {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== DAO Contracts Deployment (Phase 6.5) ===");
        console.log("Deployer:", deployer);
        console.log("");

        // Load addresses from environment
        _loadAddresses();

        vm.startBroadcast(deployerPrivateKey);

        _deployDAOImplementations();
        _setupDAOProxy();
        _deployCandidateContracts();
        _deployFactories(deployer);
        _configureDAO();

        vm.stopBroadcast();

        _printSummary();
        _saveDeployment();
    }

    // ==========================================
    // Load Addresses from Environment
    // ==========================================
    function _loadAddresses() internal {
        console.log("--- Loading addresses from environment ---");

        // Required: DAOCommitteeProxy must exist
        daoCommitteeProxy = vm.envAddress("DAO_COMMITTEE_PROXY");
        require(daoCommitteeProxy != address(0), "DAO_COMMITTEE_PROXY not set");
        console.log("DAOCommitteeProxy:", daoCommitteeProxy);

        // Required: Core contracts
        ton = vm.envAddress("TON_ADDRESS");
        require(ton != address(0), "TON_ADDRESS not set");
        console.log("TON:", ton);

        wton = vm.envAddress("WTON_ADDRESS");
        require(wton != address(0), "WTON_ADDRESS not set");
        console.log("WTON:", wton);

        seigManagerProxy = vm.envAddress("SEIG_MANAGER_PROXY");
        require(seigManagerProxy != address(0), "SEIG_MANAGER_PROXY not set");
        console.log("SeigManagerProxy:", seigManagerProxy);

        depositManagerProxy = vm.envAddress("DEPOSIT_MANAGER_PROXY");
        require(depositManagerProxy != address(0), "DEPOSIT_MANAGER_PROXY not set");
        console.log("DepositManagerProxy:", depositManagerProxy);

        layer2ManagerProxy = vm.envAddress("LAYER2_MANAGER_PROXY");
        require(layer2ManagerProxy != address(0), "LAYER2_MANAGER_PROXY not set");
        console.log("Layer2ManagerProxy:", layer2ManagerProxy);

        console.log("");
    }

    // ==========================================
    // Step 1: Deploy DAO Implementations
    // ==========================================
    function _deployDAOImplementations() internal {
        console.log("--- Step 1: Deploy DAO Implementations ---");

        // DAOCommitteeProxy2 - 다중 구현체 라우터
        daoCommitteeProxy2 = address(new DAOCommitteeProxy2());
        console.log("DAOCommitteeProxy2:", daoCommitteeProxy2);

        // DAOCommittee_V1 - 메인 비즈니스 로직
        daoCommitteeV1 = address(new DAOCommittee_V1());
        console.log("DAOCommittee_V1:", daoCommitteeV1);

        // DAOCommitteeOwner - Owner 전용 설정 함수
        daoCommitteeOwner = address(new DAOCommitteeOwner());
        console.log("DAOCommitteeOwner:", daoCommitteeOwner);

        console.log("");
    }

    // ==========================================
    // Step 2: Setup DAO Proxy
    // ==========================================
    function _setupDAOProxy() internal {
        console.log("--- Step 2: Setup DAO Proxy ---");

        // Step 2.1: DAOCommitteeProxy.upgradeTo(DAOCommitteeProxy2)
        IDAOCommitteeProxy(daoCommitteeProxy).upgradeTo(daoCommitteeProxy2);
        console.log("DAOCommitteeProxy.upgradeTo(DAOCommitteeProxy2) done");

        // Step 2.2: DAOCommitteeProxy2.upgradeTo2(DAOCommittee_V1) - Index 0
        IDAOCommitteeProxy2(daoCommitteeProxy).upgradeTo2(daoCommitteeV1);
        console.log("DAOCommitteeProxy2.upgradeTo2(DAOCommittee_V1) done");

        // Step 2.3: DAOCommitteeOwner 활성화 및 Selector Routing
        IDAOCommitteeProxy2(daoCommitteeProxy).setAliveImplementation2(daoCommitteeOwner, true);
        console.log("DAOCommitteeOwner set alive");

        // DAOCommitteeOwner 함수들을 라우팅
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

        IDAOCommitteeProxy2(daoCommitteeProxy).setSelectorImplementations2(ownerSelectors, daoCommitteeOwner);
        console.log("DAOCommitteeOwner selectors registered (17 functions)");

        console.log("");
    }

    // ==========================================
    // Step 3: Deploy Candidate Contracts
    // ==========================================
    function _deployCandidateContracts() internal {
        console.log("--- Step 3: Deploy Candidate Contracts ---");

        // Candidate 구현체
        candidateImpl = address(new Candidate());
        console.log("Candidate Impl:", candidateImpl);

        // CandidateAddOnV1_1 구현체
        candidateAddOnImpl = address(new CandidateAddOnV1_1());
        console.log("CandidateAddOnV1_1 Impl:", candidateAddOnImpl);

        console.log("");
    }

    // ==========================================
    // Step 4: Deploy Factories
    // ==========================================
    function _deployFactories(address deployer) internal {
        console.log("--- Step 4: Deploy Factories ---");

        // CandidateFactory
        candidateFactoryImpl = address(new CandidateFactory());
        console.log("CandidateFactory Impl:", candidateFactoryImpl);

        CandidateFactoryProxy cfProxy = new CandidateFactoryProxy();
        candidateFactoryProxy = address(cfProxy);
        cfProxy.upgradeTo(candidateFactoryImpl);
        console.log("CandidateFactory Proxy:", candidateFactoryProxy);

        // CandidateFactory 설정
        CandidateFactory(candidateFactoryProxy).setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            candidateImpl,
            ton,
            wton
        );
        console.log("CandidateFactory.setAddress done");

        // CandidateAddOnFactory
        candidateAddOnFactoryImpl = address(new CandidateAddOnFactory());
        console.log("CandidateAddOnFactory Impl:", candidateAddOnFactoryImpl);

        CandidateAddOnFactoryProxy caofProxy = new CandidateAddOnFactoryProxy();
        candidateAddOnFactoryProxy = address(caofProxy);
        caofProxy.upgradeTo(candidateAddOnFactoryImpl);
        console.log("CandidateAddOnFactory Proxy:", candidateAddOnFactoryProxy);

        // CandidateAddOnFactory 설정
        // 참고: onDemandL1BridgeRegistry는 L1BridgeRegistryProxy 사용
        address l1BridgeRegistryProxy = vm.envOr("L1_BRIDGE_REGISTRY_PROXY", address(0));
        CandidateAddOnFactory(candidateAddOnFactoryProxy).setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            candidateAddOnImpl,
            ton,
            wton,
            l1BridgeRegistryProxy  // onDemandL1BridgeRegistry
        );
        console.log("CandidateAddOnFactory.setAddress done");

        console.log("");
    }

    // ==========================================
    // Step 5: Configure DAO
    // ==========================================
    function _configureDAO() internal {
        console.log("--- Step 5: Configure DAO ---");

        // DAOCommitteeOwner 함수 호출 (selector routing 됨)
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(candidateFactoryProxy);
        console.log("DAO.setCandidateFactory done");

        DAOCommitteeOwner(daoCommitteeProxy).setSeigManager(seigManagerProxy);
        console.log("DAO.setSeigManager done");

        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(candidateAddOnFactoryProxy);
        console.log("DAO.setCandidateAddOnFactory done");

        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(layer2ManagerProxy);
        console.log("DAO.setLayer2Manager done");

        console.log("");
    }

    // ==========================================
    // Output Summary
    // ==========================================
    function _printSummary() internal view {
        console.log("=== DAO Deployment Summary ===");
        console.log("");
        console.log("DAO Proxy:");
        console.log("  DAOCommitteeProxy (existing):", daoCommitteeProxy);
        console.log("");
        console.log("DAO Implementations:");
        console.log("  DAOCommitteeProxy2:", daoCommitteeProxy2);
        console.log("  DAOCommittee_V1:", daoCommitteeV1);
        console.log("  DAOCommitteeOwner:", daoCommitteeOwner);
        console.log("");
        console.log("Candidate:");
        console.log("  Candidate Impl:", candidateImpl);
        console.log("  CandidateAddOnV1_1 Impl:", candidateAddOnImpl);
        console.log("");
        console.log("Factories:");
        console.log("  CandidateFactory Proxy:", candidateFactoryProxy);
        console.log("  CandidateAddOnFactory Proxy:", candidateAddOnFactoryProxy);
    }

    function _saveDeployment() internal {
        string memory output = string(abi.encodePacked(
            "{\n",
            '  "daoCommitteeProxy": "', vm.toString(daoCommitteeProxy), '",\n',
            '  "daoCommitteeProxy2": "', vm.toString(daoCommitteeProxy2), '",\n',
            '  "daoCommitteeV1": "', vm.toString(daoCommitteeV1), '",\n',
            '  "daoCommitteeOwner": "', vm.toString(daoCommitteeOwner), '",\n',
            '  "candidateImpl": "', vm.toString(candidateImpl), '",\n',
            '  "candidateAddOnImpl": "', vm.toString(candidateAddOnImpl), '",\n',
            '  "candidateFactoryProxy": "', vm.toString(candidateFactoryProxy), '",\n',
            '  "candidateAddOnFactoryProxy": "', vm.toString(candidateAddOnFactoryProxy), '"\n',
            "}"
        ));

        vm.writeFile("deployments/dao.json", output);
        console.log("\nDeployment saved to deployments/dao.json");
    }
}

/**
 * @title DeployDAOLocal
 * @notice 로컬 테스트용 DAO 배포 (MockDAOCommitteeProxy 사용)
 * @dev
 * DeployV3FullLocal 실행 후 사용
 *
 * 사용법:
 * 1. DeployV3FullLocal 실행하여 TON Staking 컨트랙트 배포
 * 2. deployments/v3-full.json에서 주소 확인
 * 3. 환경변수 설정 후 실행
 */
contract DeployDAOLocal is DeployDAO {
    // MockDAOCommitteeProxy for testing (simplified 0.8.4 version)
    address public mockDaoProxy;

    function run() external override {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== DAO Local Deployment ===");
        console.log("Deployer:", deployer);
        console.log("");

        // Load V3 deployment addresses
        _loadV3Addresses();

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock DAO proxy for testing
        _deployMockDAOProxy(deployer);

        _deployDAOImplementations();
        _setupDAOProxy();
        _deployCandidateContracts();
        _deployFactories(deployer);
        _configureDAO();

        vm.stopBroadcast();

        _printSummary();
        _saveDeployment();
    }

    function _loadV3Addresses() internal {
        console.log("--- Loading V3 deployment addresses ---");

        // Load from deployments/v3-full.json
        string memory json = vm.readFile("deployments/v3-full.json");

        ton = vm.parseJsonAddress(json, ".ton");
        console.log("TON:", ton);

        wton = vm.parseJsonAddress(json, ".wton");
        console.log("WTON:", wton);

        seigManagerProxy = vm.parseJsonAddress(json, ".seigManagerProxy");
        console.log("SeigManagerProxy:", seigManagerProxy);

        depositManagerProxy = vm.parseJsonAddress(json, ".depositManagerProxy");
        console.log("DepositManagerProxy:", depositManagerProxy);

        layer2ManagerProxy = vm.parseJsonAddress(json, ".layer2ManagerProxy");
        console.log("Layer2ManagerProxy:", layer2ManagerProxy);

        console.log("");
    }

    function _deployMockDAOProxy(address deployer) internal {
        console.log("--- Deploying Mock DAO Proxy ---");

        // Deploy MockDAOCommitteeProxy (simplified for testing)
        MockDAOCommitteeProxy mock = new MockDAOCommitteeProxy(
            ton,
            seigManagerProxy,
            deployer  // layer2Registry placeholder
        );

        daoCommitteeProxy = address(mock);
        console.log("MockDAOCommitteeProxy:", daoCommitteeProxy);
        console.log("");
    }
}

/**
 * @title MockDAOCommitteeProxy
 * @notice 테스트용 간소화된 DAOCommitteeProxy (0.8.4)
 * @dev 실제 DAOCommitteeProxy(0.7.6)를 대체하는 테스트용 mock
 */
contract MockDAOCommitteeProxy {
    address internal _implementation;
    bool public pauseProxy;
    address public ton;
    address public seigManager;
    address public layer2Registry;

    // Admin role
    mapping(address => bool) public admins;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event Upgraded(address indexed implementation);

    modifier onlyAdmin() {
        require(admins[msg.sender], "MockDAOCommitteeProxy: not admin");
        _;
    }

    constructor(
        address _ton,
        address _seigManager,
        address _layer2Registry
    ) {
        ton = _ton;
        seigManager = _seigManager;
        layer2Registry = _layer2Registry;
        admins[msg.sender] = true;
        admins[address(this)] = true;
    }

    function hasRole(bytes32, address account) public view returns (bool) {
        return admins[account];
    }

    function upgradeTo(address impl) external onlyAdmin {
        require(impl != address(0), "zero address");
        require(_implementation != impl, "same address");
        _implementation = impl;
        emit Upgraded(impl);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    function setProxyPause(bool _pause) external onlyAdmin {
        pauseProxy = _pause;
    }

    fallback() external payable {
        address _impl = _implementation;
        require(_impl != address(0) && !pauseProxy, "proxy disabled");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
