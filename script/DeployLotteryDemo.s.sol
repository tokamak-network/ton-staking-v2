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
import {DepositManagerV3} from "../src/stake/managers/DepositManagerV3.sol";

// Manager Proxies
import {SeigManagerProxy} from "../src/stake/managers/SeigManagerProxy.sol";
import {DepositManagerProxy} from "../src/stake/managers/DepositManagerProxy.sol";

// DAO Contracts
import {DAOCommitteeProxy2} from "../src/proxy/DAOCommitteeProxy2.sol";
import {DAOCommittee_V1} from "../src/dao/DAOCommittee_V1.sol";
import {DAOCommitteeOwner} from "../src/dao/DAOCommitteeOwner.sol";
import {LotteryCandidate} from "../src/dao/LotteryCandidate.sol";
import {LotteryCandidateFactory} from "../src/dao/factory/LotteryCandidateFactory.sol";
import {LotteryCandidateFactoryProxy} from "../src/dao/factory/LotteryCandidateFactoryProxy.sol";

// DAO Storage and AccessControl
import {StorageStateCommittee} from "../src/dao/StorageStateCommittee.sol";
import {AccessControl} from "../src/accessControl/AccessControl.sol";

// Mocks
import {MockTON} from "../src/mocks/MockTON.sol";
import {MockWTON} from "../src/mocks/MockWTON.sol";

interface IProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
}

interface IDAOCommitteeProxy2 {
    function upgradeTo2(address impl) external;
    function setAliveImplementation2(address impl, bool alive) external;
    function setSelectorImplementations2(bytes4[] calldata selectors, address impl) external;
}

interface IDAOCommitteeOwner {
    function setLotteryCandidateFactory(address _lotteryCandidateFactory) external;
    function setSeigManager(address _seigManager) external;
    function setLayer2Registry(address _layer2Registry) external;
}

/// @notice Simple DAO Proxy for LotteryCandidate Demo
contract SimpleMockDAOProxy is StorageStateCommittee, AccessControl {
    address internal _implementation;
    bool public pauseProxy;

    event Upgraded(address indexed implementation);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _;
    }

    constructor(address _ton) {
        ton = _ton;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function upgradeTo(address impl) external onlyAdmin {
        require(impl != address(0), "zero address");
        _implementation = impl;
        emit Upgraded(impl);
    }

    function implementation() public view returns (address) {
        return _implementation;
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

/**
 * @title DeployLotteryDemo
 * @notice Deploys LotteryCandidate demo for local testing
 * @dev Usage:
 *   # Start anvil in a separate terminal
 *   anvil
 *
 *   # Deploy contracts
 *   forge script script/DeployLotteryDemo.s.sol:DeployLotteryDemo \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast \
 *     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 */
contract DeployLotteryDemo is Script {
    // Anvil default accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;  // Account #0
    address constant OPERATOR = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;  // Account #1
    address constant USER1 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;     // Account #2
    address constant USER2 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;     // Account #3
    address constant USER3 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;     // Account #4

    uint256 constant RAY = 1e27;
    uint256 constant SEIG_PER_BLOCK = 3.92e18;
    uint256 constant GLOBAL_WITHDRAWAL_DELAY = 10; // Fast for demo

    // Deployed addresses
    address public ton;
    address public wton;
    address public coinageFactory;
    address public coinageLogic;
    address public layer2RegistryProxy;
    address public seigManagerProxy;
    address public depositManagerProxy;
    address public daoCommitteeProxy;
    address public lotteryCandidateFactoryProxy;
    address public lotteryCandidateImpl;
    address public lotteryCandidate;

    function run() public {
        vm.startBroadcast();
        
        _deployTokens();
        _deployCoinageInfrastructure();
        _deployLayer2Registry();
        _deployManagerProxies();
        _initializeManagers();
        _setupMinterPermissions();
        _deployDAO();
        _createLotteryCandidate();
        _mintTestTokens();
        
        vm.stopBroadcast();
        
        _printSummary();
        _saveDeployment();
    }

    function _deployTokens() internal {
        console.log("--- Deploy Tokens ---");
        ton = address(new MockTON());
        console.log("TON:", ton);
        
        MockWTON wtonContract = new MockWTON();
        wtonContract.setTON(ton);
        wton = address(wtonContract);
        console.log("WTON:", wton);
    }

    function _deployCoinageInfrastructure() internal {
        console.log("--- Deploy Coinage ---");
        coinageLogic = address(new RefactorCoinageSnapshot());
        CoinageFactory factory = new CoinageFactory();
        factory.setAutoCoinageLogic(coinageLogic);
        coinageFactory = address(factory);
        console.log("CoinageFactory:", coinageFactory);
    }

    function _deployLayer2Registry() internal {
        console.log("--- Deploy Layer2Registry ---");
        address impl = address(new Layer2Registry());
        Layer2RegistryProxy proxy = new Layer2RegistryProxy();
        IProxy(address(proxy)).upgradeTo(impl);
        layer2RegistryProxy = address(proxy);
        console.log("Layer2Registry:", layer2RegistryProxy);
    }

    function _deployManagerProxies() internal {
        console.log("--- Deploy Manager Proxies ---");
        seigManagerProxy = address(new SeigManagerProxy());
        console.log("SeigManager:", seigManagerProxy);

        depositManagerProxy = address(new DepositManagerProxy());
        console.log("DepositManager:", depositManagerProxy);
    }

    function _initializeManagers() internal {
        console.log("--- Initialize Managers ---");
        
        // SeigManager
        address seigImpl = address(new SeigManagerV1_2());
        IProxy(seigManagerProxy).upgradeTo(seigImpl);
        
        SeigManagerV1_2(seigManagerProxy).initialize(
            ton,
            wton,
            layer2RegistryProxy,
            depositManagerProxy,
            SEIG_PER_BLOCK,
            coinageFactory,
            block.number
        );
        
        SeigManagerV1_2(seigManagerProxy).setData(
            address(0),     // powerTON
            DEPLOYER,       // dao (temp)
            0,              // powerTONSeigRate
            0.5e27,         // daoSeigRate
            0.5e27,         // relativeSeigRate
            10,             // adjustCommissionDelay
            1000.1e27       // minimumAmount
        );
        console.log("SeigManager initialized");

        // DepositManager
        address depositImpl = address(new DepositManagerV3());
        IProxy(depositManagerProxy).upgradeTo(depositImpl);
        
        DepositManagerV3(depositManagerProxy).initialize(
            wton,
            layer2RegistryProxy,
            seigManagerProxy,
            GLOBAL_WITHDRAWAL_DELAY,
            address(0)
        );
        console.log("DepositManager initialized");
    }

    function _setupMinterPermissions() internal {
        console.log("--- Setup Permissions ---");
        Layer2Registry(layer2RegistryProxy).addMinter(seigManagerProxy);
        MockWTON(wton).addMinter(seigManagerProxy);
        MockWTON(wton).addMinter(depositManagerProxy);
        console.log("Minter permissions set");
    }

    function _deployDAO() internal {
        console.log("--- Deploy DAO ---");
        
        // Simple DAO Proxy
        SimpleMockDAOProxy mockProxy = new SimpleMockDAOProxy(ton);
        daoCommitteeProxy = address(mockProxy);
        
        // DAO implementations
        address daoProxy2 = address(new DAOCommitteeProxy2());
        address daoV1 = address(new DAOCommittee_V1());
        address daoOwner = address(new DAOCommitteeOwner());
        
        // Setup routing
        mockProxy.upgradeTo(daoProxy2);
        IDAOCommitteeProxy2(daoCommitteeProxy).upgradeTo2(daoV1);
        IDAOCommitteeProxy2(daoCommitteeProxy).setAliveImplementation2(daoOwner, true);
        
        bytes4[] memory ownerSelectors = new bytes4[](3);
        ownerSelectors[0] = IDAOCommitteeOwner.setLotteryCandidateFactory.selector;
        ownerSelectors[1] = IDAOCommitteeOwner.setSeigManager.selector;
        ownerSelectors[2] = IDAOCommitteeOwner.setLayer2Registry.selector;
        IDAOCommitteeProxy2(daoCommitteeProxy).setSelectorImplementations2(ownerSelectors, daoOwner);
        
        // LotteryCandidate Factory
        lotteryCandidateImpl = address(new LotteryCandidate());
        LotteryCandidateFactoryProxy lcfProxy = new LotteryCandidateFactoryProxy();
        lotteryCandidateFactoryProxy = address(lcfProxy);
        lcfProxy.upgradeTo(address(new LotteryCandidateFactory()));
        
        // Configure factory - defaultEntryFee: 10 TON = 10e27 WTON
        LotteryCandidateFactory(lotteryCandidateFactoryProxy).setAddress(
            depositManagerProxy,
            daoCommitteeProxy,
            lotteryCandidateImpl,
            ton,
            wton
        );
        LotteryCandidateFactory(lotteryCandidateFactoryProxy).setDefaultEntryFee(10e27);
        
        // Configure DAO
        IDAOCommitteeOwner(daoCommitteeProxy).setLotteryCandidateFactory(lotteryCandidateFactoryProxy);
        IDAOCommitteeOwner(daoCommitteeProxy).setSeigManager(seigManagerProxy);
        IDAOCommitteeOwner(daoCommitteeProxy).setLayer2Registry(layer2RegistryProxy);
        
        // Grant MINTER_ROLE to DAO
        Layer2Registry(layer2RegistryProxy).addMinter(daoCommitteeProxy);
        
        console.log("DAOCommittee:", daoCommitteeProxy);
        console.log("LotteryCandidateFactory:", lotteryCandidateFactoryProxy);
    }

    function _createLotteryCandidate() internal {
        console.log("--- Create LotteryCandidate ---");
        
        // Operator creates LotteryCandidate via DAO
        vm.stopBroadcast();
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d); // OPERATOR private key
        
        DAOCommittee_V1(daoCommitteeProxy).createLotteryCandidate("Lottery Demo");
        
        // Get created LotteryCandidate address
        (address candidateContract, , , , ) = DAOCommittee_V1(daoCommitteeProxy).candidateInfos(OPERATOR);
        lotteryCandidate = candidateContract;
        
        console.log("LotteryCandidate created:", lotteryCandidate);
        console.log("Operator:", OPERATOR);
        
        // Operator deposits initial collateral (1001 TON minimum required by SeigManager)
        uint256 operatorDeposit = 1001 ether;
        MockTON(ton).mint(OPERATOR, operatorDeposit);
        MockTON(ton).approveAndCall(lotteryCandidate, operatorDeposit, "");
        console.log("Operator deposited:", operatorDeposit / 1e18, "TON");
        
        vm.stopBroadcast();
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80); // DEPLOYER private key
    }

    function _mintTestTokens() internal {
        console.log("--- Mint Test Tokens ---");
        
        uint256 tonAmount = 1000 ether;
        uint256 wtonAmount = 1000e27;
        
        address[3] memory users = [USER1, USER2, USER3];
        string[3] memory names = ["USER1", "USER2", "USER3"];
        
        for (uint256 i = 0; i < users.length; i++) {
            MockTON(ton).mint(users[i], tonAmount);
            MockWTON(wton).mint(users[i], wtonAmount);
            console.log("Minted to", names[i], ": 1000 TON + 1000 WTON");
        }
    }

    function _printSummary() internal view {
        console.log("");
        console.log("===========================================");
        console.log("  LotteryCandidate Demo Deployment Summary");
        console.log("===========================================");
        console.log("");
        console.log("Tokens:");
        console.log("  TON:", ton);
        console.log("  WTON:", wton);
        console.log("");
        console.log("Core Contracts:");
        console.log("  SeigManager:", seigManagerProxy);
        console.log("  DepositManager:", depositManagerProxy);
        console.log("  Layer2Registry:", layer2RegistryProxy);
        console.log("  DAOCommittee:", daoCommitteeProxy);
        console.log("");
        console.log("LotteryCandidate:");
        console.log("  Contract:", lotteryCandidate);
        console.log("  Operator:", OPERATOR);
        console.log("  EntryFee: 10 TON (10e27 WTON)");
        console.log("");
        console.log("Test Accounts (each has 1000 TON + 1000 WTON):");
        console.log("  USER1:", USER1);
        console.log("  USER2:", USER2);
        console.log("  USER3:", USER3);
        console.log("");
        console.log("Private Keys (for MetaMask):");
        console.log("  Deployer:  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        console.log("  Operator:  0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");
        console.log("  User1:     0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a");
        console.log("  User2:     0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6");
        console.log("  User3:     0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a");
        console.log("");
    }

    function _saveDeployment() internal view {
        string memory json = string(abi.encodePacked(
            "{\n",
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "rpcUrl": "http://localhost:8545",\n',
            '  "ton": "', vm.toString(ton), '",\n',
            '  "wton": "', vm.toString(wton), '",\n',
            '  "seigManager": "', vm.toString(seigManagerProxy), '",\n',
            '  "depositManager": "', vm.toString(depositManagerProxy), '",\n',
            '  "layer2Registry": "', vm.toString(layer2RegistryProxy), '",\n',
            '  "daoCommittee": "', vm.toString(daoCommitteeProxy), '",\n',
            '  "lotteryCandidate": "', vm.toString(lotteryCandidate), '",\n',
            '  "lotteryCandidateFactory": "', vm.toString(lotteryCandidateFactoryProxy), '",\n',
            '  "operator": "', vm.toString(OPERATOR), '",\n',
            '  "entryFee": "10000000000000000000000000000",\n',
            '  "accounts": {\n',
            '    "deployer": "', vm.toString(DEPLOYER), '",\n',
            '    "operator": "', vm.toString(OPERATOR), '",\n',
            '    "user1": "', vm.toString(USER1), '",\n',
            '    "user2": "', vm.toString(USER2), '",\n',
            '    "user3": "', vm.toString(USER3), '"\n',
            '  }\n',
            "}"
        ));

        console.log("\n=== DEPLOYMENT_JSON_START ===");
        console.log(json);
        console.log("=== DEPLOYMENT_JSON_END ===");
    }
}
