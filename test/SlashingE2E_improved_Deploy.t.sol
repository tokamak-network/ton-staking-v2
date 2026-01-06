// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'forge-std/Test.sol';

// Tokens
import {ITON} from '../src/stake/interfaces/ITON.sol';
import {IWTON} from '../src/dao/interfaces/IWTON.sol';

// Coinage
import {RefactorCoinageSnapshot} from '../src/stake/tokens/RefactorCoinageSnapshot.sol';
import {CoinageFactory} from '../src/stake/factory/CoinageFactory.sol';

// Proxies
import {SeigManagerProxy} from '../src/stake/managers/SeigManagerProxy.sol';
import {DepositManagerProxy} from '../src/stake/managers/DepositManagerProxy.sol';
import {Layer2RegistryProxy} from '../src/stake/Layer2RegistryProxy.sol';
import {Layer2ManagerProxy} from '../src/layer2/Layer2ManagerProxy.sol';
import {L1BridgeRegistryProxy} from '../src/layer2/L1BridgeRegistryProxy.sol';

// Layer2Registry
import {Layer2Registry} from '../src/stake/Layer2Registry.sol';

// SeigManager Implementations
import {SeigManagerV1_2} from '../src/stake/managers/SeigManagerV1_2.sol';
import {SeigManagerV1_3} from '../src/stake/managers/SeigManagerV1_3.sol';
import {SeigManager_Slashing} from '../src/stake/managers/SeigManager_Slashing.sol';

// DepositManager Implementations
import {DepositManager} from '../src/stake/managers/DepositManager.sol';
import {
    DepositManager_setWithdrawalDelay
} from '../src/stake/managers/DepositManager_setWithdrawalDelay.sol';
import {DepositManagerV1_1} from '../src/stake/managers/DepositManagerV1_1.sol';
import {DepositManager_Slashing} from '../src/stake/managers/DepositManager_Slashing.sol';

// Layer2Manager
import {Layer2ManagerV1_1} from '../src/layer2/Layer2ManagerV1_1.sol';
import {Layer2Manager_Slashing} from '../src/layer2/Layer2Manager_Slashing.sol';

// L1BridgeRegistry
import {L1BridgeRegistryV1_1} from '../src/layer2/L1BridgeRegistryV1_1.sol';

// OperatorManager
import {OperatorManagerV1_1} from '../src/layer2/OperatorManagerV1_1.sol';
import {OperatorManagerFactory} from '../src/layer2/factory/OperatorManagerFactory.sol';

// DAO Committee
import {DAOCommitteeProxy2} from '../src/proxy/DAOCommitteeProxy2.sol';
import {DAOCommittee_V1} from '../src/dao/DAOCommittee_V1.sol';
import {DAOCommitteeOwner} from '../src/dao/DAOCommitteeOwner.sol';
import {Candidate} from '../src/dao/Candidate.sol';
import {CandidateFactory} from '../src/dao/factory/CandidateFactory.sol';
import {CandidateFactoryProxy} from '../src/dao/factory/CandidateFactoryProxy.sol';
import {CandidateAddOnV1_1} from '../src/dao/CandidateAddOnV1_1.sol';
import {CandidateAddOnFactory} from '../src/dao/factory/CandidateAddOnFactory.sol';
import {CandidateAddOnFactoryProxy} from '../src/dao/factory/CandidateAddOnFactoryProxy.sol';

/**
 * @title SlashingE2E_improved_Deploy
 * @notice E2E Slashing 테스트를 위한 전체 컨트랙트 배포 테스트
 * @dev docs/deployment-deployscript-slashUpdated.md 문서를 참조하여 작성
 */
contract SlashingE2E_improved_Deploy is Test {
    // Tokens
    address public ton;
    address public wton;

    // Coinage
    RefactorCoinageSnapshot public coinageLogic;
    CoinageFactory public coinageFactory;

    // Proxies
    SeigManagerProxy public seigManagerProxy;
    DepositManagerProxy public depositManagerProxy;
    Layer2RegistryProxy public layer2RegistryProxy;
    Layer2ManagerProxy public layer2ManagerProxy;
    L1BridgeRegistryProxy public l1BridgeRegistryProxy;

    // Layer2Registry
    Layer2Registry public layer2RegistryImpl;

    // SeigManager Implementations
    SeigManagerV1_2 public seigManagerV1_2;
    SeigManagerV1_3 public seigManagerV1_3;
    SeigManager_Slashing public seigManagerSlashing;

    // DepositManager Implementations
    DepositManager public depositManagerBase;
    DepositManager_setWithdrawalDelay public depositManagerSetDelay;
    DepositManagerV1_1 public depositManagerV1_1;
    DepositManager_Slashing public depositManagerSlashing;

    // Layer2Manager
    Layer2ManagerV1_1 public layer2ManagerV1_1;
    Layer2Manager_Slashing public layer2ManagerSlashing;

    // L1BridgeRegistry
    L1BridgeRegistryV1_1 public l1BridgeRegistryV1_1;

    // OperatorManager
    OperatorManagerV1_1 public operatorManagerV1_1Impl;
    OperatorManagerFactory public operatorManagerFactory;

    // DAOVault & DAOAgendaManager (ABI deployment)
    address public daoVault;
    address public daoAgendaManager;

    // DAO Committee
    address public daoCommitteeProxy; // ABI deployment
    DAOCommitteeProxy2 public daoCommitteeProxy2;
    DAOCommittee_V1 public daoCommitteeImpl;
    DAOCommitteeOwner public daoCommitteeOwner;
    Candidate public candidateImpl;
    CandidateFactory public candidateFactoryLogic;
    CandidateFactoryProxy public candidateFactoryProxy;
    CandidateAddOnV1_1 public candidateAddOnImpl;
    CandidateAddOnFactory public candidateAddOnFactoryLogic;
    CandidateAddOnFactoryProxy public candidateAddOnFactoryProxy;

    // Test accounts
    address public deployer;
    address public operator;
    address public challenger;

    // Constants
    uint256 public constant SEIG_PER_BLOCK = 3.92e18; // 3.92 TON per block
    uint256 public constant GLOBAL_WITHDRAWAL_DELAY = 93046; // ~2 weeks in blocks
    uint256 public constant SLASHING_REWARD_RATE = 1000; // 10%

    function setUp() public virtual {
        deployer = address(this);
        operator = makeAddr('operator');
        challenger = makeAddr('challenger');

        // 1. Deploy TON & WTON
        _deployTokens();

        // 2. Deploy CoinageFactory
        _deployCoinageFactory();

        // 3. Deploy Proxies
        _deployProxies();

        // 4. Deploy Layer2Registry
        _deployLayer2Registry();

        // 5. Deploy SeigManager
        _deploySeigManager();

        // 6. Deploy DepositManager
        _deployDepositManager();

        // 7. Deploy DAOVault
        _deployDAOVault();

        // 8. Deploy DAOAgendaManager
        _deployDAOAgendaManager();

        // 9. Deploy DAOCommittee
        _deployDAOCommittee();

        // 10. Deploy L1BridgeRegistry
        _deployL1BridgeRegistry();

        // 11. Deploy OperatorManagerFactory
        _deployOperatorManagerFactory();

        // 12. Deploy Layer2Manager
        _deployLayer2Manager();

        // 13. Setup Mint Permissions
        _setupMintPermissions();

        // 14. Setup SeigManager setData
        _setupSeigManager();

        // 15. Setup Contract Owner
        _setupContractOwner();
    }

    /// @notice 1. TON & WTON 배포
    function _deployTokens() internal {
        console.log('=== 1. Deploying TON & WTON ===');

        // TON 배포
        ton = deployCode('abis/TON.json');
        console.log('TON deployed at:', ton);

        // WTON 배포
        bytes memory wtonArgs = abi.encode(ton);
        wton = deployCode('abis/WTON.json', wtonArgs);
        console.log('WTON deployed at:', wton);
    }

    /// @notice 2. CoinageFactory 배포
    function _deployCoinageFactory() internal {
        console.log('\n=== 2. Deploying CoinageFactory ===');

        // RefactorCoinageSnapshot 배포
        coinageLogic = new RefactorCoinageSnapshot();
        console.log('CoinageLogic deployed at:', address(coinageLogic));

        // CoinageFactory 배포
        coinageFactory = new CoinageFactory();
        console.log('CoinageFactory deployed at:', address(coinageFactory));

        // CoinageFactory 기본 구현체 설정
        coinageFactory.setAutoCoinageLogic(address(coinageLogic));
        console.log('CoinageFactory logic set');
    }

    /// @notice 3. Proxy 배포
    function _deployProxies() internal {
        console.log('\n=== 3. Deploying Proxies ===');

        seigManagerProxy = new SeigManagerProxy();
        console.log('SeigManagerProxy deployed at:', address(seigManagerProxy));

        depositManagerProxy = new DepositManagerProxy();
        console.log('DepositManagerProxy deployed at:', address(depositManagerProxy));

        layer2RegistryProxy = new Layer2RegistryProxy();
        console.log('Layer2RegistryProxy deployed at:', address(layer2RegistryProxy));

        layer2ManagerProxy = new Layer2ManagerProxy();
        console.log('Layer2ManagerProxy deployed at:', address(layer2ManagerProxy));

        l1BridgeRegistryProxy = new L1BridgeRegistryProxy();
        console.log('L1BridgeRegistryProxy deployed at:', address(l1BridgeRegistryProxy));
    }

    /// @notice 4. Layer2Registry 배포
    function _deployLayer2Registry() internal {
        console.log('\n=== 4. Deploying Layer2Registry ===');

        // Step 1: 구현체 배포
        layer2RegistryImpl = new Layer2Registry();
        console.log('Layer2Registry implementation deployed at:', address(layer2RegistryImpl));

        // Step 2: 프록시에 구현체 설정
        layer2RegistryProxy.upgradeTo(address(layer2RegistryImpl));
        console.log('Layer2RegistryProxy upgraded to implementation');
    }

    /// @notice 5. SeigManager 배포 (다중 구현체 패턴)
    function _deploySeigManager() internal {
        console.log('\n=== 5. Deploying SeigManager (Multi-Implementation) ===');

        // Step 1: 모든 구현체 배포
        seigManagerV1_2 = new SeigManagerV1_2();
        console.log('SeigManagerV1_2 deployed at:', address(seigManagerV1_2));

        seigManagerV1_3 = new SeigManagerV1_3();
        console.log('SeigManagerV1_3 deployed at:', address(seigManagerV1_3));

        seigManagerSlashing = new SeigManager_Slashing();
        console.log('SeigManager_Slashing deployed at:', address(seigManagerSlashing));

        // Step 2: 프록시에 기본 구현체 설정
        seigManagerProxy.upgradeTo(address(seigManagerV1_2));
        console.log('SeigManagerProxy upgraded to V1_2');

        // Step 3: 초기화
        SeigManagerV1_2(address(seigManagerProxy)).initialize(
            ton,
            wton,
            address(layer2RegistryProxy),
            address(depositManagerProxy),
            SEIG_PER_BLOCK,
            address(coinageFactory),
            block.number
        );
        console.log('SeigManager initialized');

        // Step 4: V1_3 구현체 활성화
        seigManagerProxy.setAliveImplementation2(address(seigManagerV1_3), true);
        console.log('SeigManagerV1_3 activated');

        // Step 5: V1_3 함수들을 V1_3 구현체로 라우팅
        bytes4[] memory v1_3Selectors = new bytes4[](8);
        v1_3Selectors[0] = SeigManagerV1_3.pause.selector;
        v1_3Selectors[1] = SeigManagerV1_3.unpause.selector;
        v1_3Selectors[2] = SeigManagerV1_3.updateSeigniorage.selector;
        v1_3Selectors[3] = SeigManagerV1_3.updateSeigniorageLayer.selector;
        v1_3Selectors[4] = SeigManagerV1_3.estimatedDistribute.selector;
        v1_3Selectors[5] = SeigManagerV1_3.claimableL2Seigniorage.selector;
        v1_3Selectors[6] = SeigManagerV1_3.excludeFromL2Seigniorage.selector;
        v1_3Selectors[7] = SeigManagerV1_3.includeFromL2Seigniorage.selector;

        seigManagerProxy.setSelectorImplementations2(v1_3Selectors, address(seigManagerV1_3));
        console.log('SeigManagerV1_3 selectors routed');

        // Step 6: Slashing 구현체 활성화
        seigManagerProxy.setAliveImplementation2(address(seigManagerSlashing), true);
        console.log('SeigManager_Slashing activated');

        // Step 7: Slashing 함수를 Slashing 구현체로 라우팅
        bytes4[] memory slashingSelectors = new bytes4[](1);
        slashingSelectors[0] = SeigManager_Slashing.onSlash.selector;
        seigManagerProxy.setSelectorImplementations2(
            slashingSelectors,
            address(seigManagerSlashing)
        );
        console.log('SeigManager_Slashing selectors routed');
    }

    /// @notice 6. DepositManager 배포 (다중 구현체 패턴)
    function _deployDepositManager() internal {
        console.log('\n=== 6. Deploying DepositManager (Multi-Implementation) ===');

        // Step 1: 모든 구현체 배포
        depositManagerBase = new DepositManager();
        console.log('DepositManager base deployed at:', address(depositManagerBase));

        depositManagerSetDelay = new DepositManager_setWithdrawalDelay();
        console.log(
            'DepositManager_setWithdrawalDelay deployed at:',
            address(depositManagerSetDelay)
        );

        depositManagerV1_1 = new DepositManagerV1_1();
        console.log('DepositManagerV1_1 deployed at:', address(depositManagerV1_1));

        depositManagerSlashing = new DepositManager_Slashing();
        console.log('DepositManager_Slashing deployed at:', address(depositManagerSlashing));

        // Step 2: 프록시에 기본 구현체 설정
        depositManagerProxy.upgradeTo(address(depositManagerBase));
        console.log('DepositManagerProxy upgraded to base');

        // Step 3: 초기화
        DepositManager(address(depositManagerProxy)).initialize(
            wton,
            address(layer2RegistryProxy),
            address(seigManagerProxy),
            GLOBAL_WITHDRAWAL_DELAY,
            address(0) // powerTON address (not used in test)
        );
        console.log('DepositManager initialized');

        // Step 4: Index 1, 2, 3 구현체 활성화
        depositManagerProxy.setAliveImplementation2(address(depositManagerSetDelay), true);
        depositManagerProxy.setAliveImplementation2(address(depositManagerV1_1), true);
        depositManagerProxy.setAliveImplementation2(address(depositManagerSlashing), true);
        console.log('DepositManager additional implementations activated');

        // Step 5: setWithdrawalDelay 함수들을 setWithdrawalDelay 구현체로 라우팅
        bytes4[] memory setWithdrawalDelaySelectors = new bytes4[](2);
        setWithdrawalDelaySelectors[0] = DepositManager_setWithdrawalDelay
            .setWithdrawalDelay
            .selector;
        setWithdrawalDelaySelectors[1] = DepositManager_setWithdrawalDelay
            .setWithdrawalDelayByOwner
            .selector;
        depositManagerProxy.setSelectorImplementations2(
            setWithdrawalDelaySelectors,
            address(depositManagerSetDelay)
        );
        console.log('setWithdrawalDelay selectors routed');

        // Step 6: V1_1 함수들을 V1_1 구현체로 라우팅
        bytes4[] memory v1_1Selectors = new bytes4[](3);
        v1_1Selectors[0] = DepositManagerV1_1.setMinDepositGasLimit.selector;
        v1_1Selectors[1] = DepositManagerV1_1.setAddresses.selector;
        v1_1Selectors[2] = DepositManagerV1_1.withdrawAndDepositL2.selector;
        depositManagerProxy.setSelectorImplementations2(v1_1Selectors, address(depositManagerV1_1));
        console.log('DepositManagerV1_1 selectors routed');

        // Step 7: Slashing 함수들을 Slashing 구현체로 라우팅
        bytes4[] memory slashingSelectors = new bytes4[](2);
        slashingSelectors[0] = DepositManager_Slashing.slash.selector;
        slashingSelectors[1] = DepositManager_Slashing.setSlashingRewardRate.selector;
        depositManagerProxy.setSelectorImplementations2(
            slashingSelectors,
            address(depositManagerSlashing)
        );
        console.log('DepositManager_Slashing selectors routed');

        // Step 8: SlashingRewardRate 설정
        DepositManager_Slashing(address(depositManagerProxy)).setSlashingRewardRate(
            SLASHING_REWARD_RATE
        );
        console.log('SlashingRewardRate set to:', SLASHING_REWARD_RATE);
    }

    /// @notice 7. DAOVault 배포 (ABI)
    function _deployDAOVault() internal {
        console.log('\n=== 7. Deploying DAOVault ===');

        bytes memory daovaultArgs = abi.encode(ton, wton);
        daoVault = deployCode('abis/DAOVault.json', daovaultArgs);
        console.log('DAOVault deployed at:', daoVault);
    }

    /// @notice 8. DAOAgendaManager 배포 (ABI)
    function _deployDAOAgendaManager() internal {
        console.log('\n=== 8. Deploying DAOAgendaManager ===');

        daoAgendaManager = deployCode('abis/DAOAgendaManager.json');
        console.log('DAOAgendaManager deployed at:', daoAgendaManager);
    }

    /// @notice 9. DAOCommittee 배포 (다중 구현체 패턴)
    function _deployDAOCommittee() internal {
        console.log('\n=== 9. Deploying DAOCommittee (Multi-Implementation) ===');

        // Step 2: DAOCommitteeProxy2 배포
        daoCommitteeProxy2 = new DAOCommitteeProxy2();
        console.log('DAOCommitteeProxy2 deployed at:', address(daoCommitteeProxy2));

        // Step 1: DAOCommitteeProxy 배포 (ABI) - 구현체를 처음부터 설정
        bytes memory daoArgs = abi.encode(
            ton,
            address(daoCommitteeProxy2), // impl을 여기서 바로 설정
            address(seigManagerProxy),
            address(layer2RegistryProxy),
            address(daoAgendaManager),
            address(1), // candidateFactory 배포전, address(0)으로 설정 불가
            address(daoVault)
        );
        daoCommitteeProxy = deployCode('abis/DAOCommitteeProxy.json', daoArgs);
        console.log('DAOCommitteeProxy deployed at:', daoCommitteeProxy);

        // Step 3: DAOCommittee_V1 구현체 배포 및 설정
        daoCommitteeImpl = new DAOCommittee_V1();
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).upgradeTo2(address(daoCommitteeImpl));
        console.log('DAOCommitteeProxy2 set implementation to V1');

        // Step 4: DAOCommitteeOwner 배포 및 Selector Routing
        daoCommitteeOwner = new DAOCommitteeOwner();
        DAOCommitteeProxy2(payable(daoCommitteeProxy)).setAliveImplementation2(
            address(daoCommitteeOwner),
            true
        );

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
            address(daoCommitteeOwner)
        );
        console.log('DAOCommitteeOwner selectors routed');

        // Step 5: Candidate 구현체 배포
        candidateImpl = new Candidate();

        // Step 6: CandidateFactory 배포 및 설정
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
        console.log('CandidateFactory deployed and configured');

        // Step 7: CandidateAddOn 배포 및 설정
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
        console.log('CandidateAddOnFactory deployed and configured');

        // Step 8: DAOCommittee 추가 설정
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateFactory(address(candidateFactoryProxy));
        DAOCommitteeOwner(daoCommitteeProxy).setCandidateAddOnFactory(
            address(candidateAddOnFactoryProxy)
        );
        DAOCommitteeOwner(daoCommitteeProxy).setLayer2Manager(address(layer2ManagerProxy));
        DAOCommitteeOwner(daoCommitteeProxy).setWton(wton);
        console.log('DAOCommittee final configuration complete');
    }

    /// @notice 10. L1BridgeRegistry 배포
    function _deployL1BridgeRegistry() internal {
        console.log('\n=== 10. Deploying L1BridgeRegistry ===');

        // Step 1: 구현체 배포
        l1BridgeRegistryV1_1 = new L1BridgeRegistryV1_1();
        console.log('L1BridgeRegistryV1_1 deployed at:', address(l1BridgeRegistryV1_1));

        // Step 2: 프록시에 구현체 설정
        l1BridgeRegistryProxy.upgradeTo(address(l1BridgeRegistryV1_1));
        console.log('L1BridgeRegistryProxy upgraded to V1_1');

        // Step 3: 초기화
        L1BridgeRegistryV1_1(address(l1BridgeRegistryProxy)).setAddresses(
            address(layer2ManagerProxy),
            address(seigManagerProxy),
            ton
        );
        console.log('L1BridgeRegistry initialized');
    }

    /// @notice 11. OperatorManagerFactory 배포
    function _deployOperatorManagerFactory() internal {
        console.log('\n=== 11. Deploying OperatorManagerFactory ===');

        // Step 1: OperatorManager 구현체 배포
        operatorManagerV1_1Impl = new OperatorManagerV1_1();
        console.log(
            'OperatorManagerV1_1 implementation deployed at:',
            address(operatorManagerV1_1Impl)
        );

        // Step 2: Factory 배포
        operatorManagerFactory = new OperatorManagerFactory(address(operatorManagerV1_1Impl));
        console.log('OperatorManagerFactory deployed at:', address(operatorManagerFactory));

        // Step 3: 주소 설정
        operatorManagerFactory.setAddresses(
            address(depositManagerProxy),
            ton,
            wton,
            address(layer2ManagerProxy)
        );
        console.log('OperatorManagerFactory addresses set');
    }

    /// @notice 12. Layer2Manager 배포
    function _deployLayer2Manager() internal {
        console.log('\n=== 12. Deploying Layer2Manager ===');

        // Step 1: 모든 구현체 배포
        layer2ManagerV1_1 = new Layer2ManagerV1_1();
        console.log('Layer2ManagerV1_1 deployed at:', address(layer2ManagerV1_1));

        layer2ManagerSlashing = new Layer2Manager_Slashing();
        console.log('Layer2Manager_Slashing deployed at:', address(layer2ManagerSlashing));

        // Step 2: 프록시에 기본 구현체(V1_1) 설정
        layer2ManagerProxy.upgradeTo(address(layer2ManagerV1_1));
        console.log('Layer2ManagerProxy upgraded to V1_1');

        // Step 3: 초기화
        Layer2ManagerV1_1(address(layer2ManagerProxy)).setAddresses(
            address(l1BridgeRegistryProxy),
            address(operatorManagerFactory),
            ton,
            wton,
            address(daoCommitteeProxy), // DAO 설정
            address(depositManagerProxy),
            address(seigManagerProxy),
            address(0) // swapProxy (not used)
        );
        console.log('Layer2Manager addresses set');

        // Step 4: Slashing 구현체 활성화 및 라우팅
        layer2ManagerProxy.setAliveImplementation2(address(layer2ManagerSlashing), true);
        bytes4[] memory slashingSelectors = new bytes4[](1);
        slashingSelectors[0] = Layer2Manager_Slashing.slashingCandidate.selector;
        layer2ManagerProxy.setSelectorImplementations2(
            slashingSelectors,
            address(layer2ManagerSlashing)
        );
        console.log('Layer2Manager_Slashing selectors routed');

        // DepositManager에 Layer2Manager 주소 설정 (Slash 권한 위해 필요)
        DepositManagerV1_1(address(depositManagerProxy)).setAddresses(
            address(l1BridgeRegistryProxy),
            address(layer2ManagerProxy)
        );
        console.log('DepositManagerV1_1 addresses set');
    }

    /// @notice 13. Mint 권한 설정
    function _setupMintPermissions() internal {
        console.log('\n=== 13. Setting up Mint Permissions ===');

        // SeigManager가 코이니지 생성 가능하도록
        Layer2Registry(address(layer2RegistryProxy)).addMinter(address(seigManagerProxy));
        console.log('SeigManager added as minter to Layer2Registry');

        // SeigManager가 시뇨리지(WTON) 발행 가능하도록
        IWTON(wton).addMinter(address(seigManagerProxy));
        console.log('SeigManager added as minter to WTON');

        // DAOCommittee가 레이어2 등록 대행 가능하도록
        // ============== 이부분은 추가로 고민해봐야함 ==================
        Layer2Registry(address(layer2RegistryProxy)).addMinter(daoCommitteeProxy);
        console.log('DAOCommitteeProxy added as minter to Layer2Registry');
    }

    /// @notice 14. SeigManager setData
    function _setupSeigManager() internal {
        console.log('\n=== 14. Setting up SeigManagerV1_2 ===');

        // Step 1: setData
        SeigManagerV1_2(address(seigManagerProxy)).setData(
            address(0), //powerTON
            address(daoCommitteeProxy), //DAOCommitteeProxy Address
            0, //powerTONSeigRate_
            0.5e27, //daoSeigRate_
            0.5e27, //relativeSeigRate_
            93096, //adjustDelay_
            1000.1e27 //minimumAmount_
        );
        console.log('SeigManagerV1_2 setData complete');
    }

    /// @notice 15. Contract Owner 설정
    function _setupContractOwner() internal {
        console.log('\n=== 15. Setting up Contract Owner ===');

        // SeigManagerProxy
        seigManagerProxy.transferAdmin(daoCommitteeProxy);
        console.log('SeigManagerProxy ownership transferred to DAOCommitteeProxy');

        // DepositManagerProxy
        DepositManagerProxy(depositManagerProxy).transferOwnership(daoCommitteeProxy);
        console.log('DepositManagerProxy ownership transferred to DAOCommitteeProxy');

        // Layer2RegistryProxy
        Layer2RegistryProxy(layer2RegistryProxy).transferOwnership(daoCommitteeProxy);
        console.log('Layer2RegistryProxy ownership transferred to DAOCommitteeProxy');

        // Layer2ManagerProxy
        Layer2ManagerProxy(layer2ManagerProxy).transferOwnership(daoCommitteeProxy);
        console.log('Layer2ManagerProxy ownership transferred to DAOCommitteeProxy');

        // L1BridgeRegistryProxy
        L1BridgeRegistryProxy(l1BridgeRegistryProxy).transferAdmin(daoCommitteeProxy);
        console.log('L1BridgeRegistryProxy ownership transferred to DAOCommitteeProxy');

        // CandidateFactoryProxy
        CandidateFactoryProxy(candidateFactoryProxy).transferOwnership(daoCommitteeProxy);
        console.log('CandidateFactoryProxy ownership transferred to DAOCommitteeProxy');

        // CandidateAddOnFactoryProxy
        CandidateAddOnFactoryProxy(candidateAddOnFactoryProxy).transferOwnership(daoCommitteeProxy);
        console.log('CandidateAddOnFactoryProxy ownership transferred to DAOCommitteeProxy');
    }

    // ============================================
    // Test Functions
    // ============================================

    function test_DeploymentSuccessful() public view {
        console.log('\n=== Testing Deployment Success ===');

        // Verify all contracts are deployed
        assertTrue(ton != address(0), 'TON not deployed');
        assertTrue(wton != address(0), 'WTON not deployed');
        assertTrue(address(coinageFactory) != address(0), 'CoinageFactory not deployed');
        assertTrue(address(seigManagerProxy) != address(0), 'SeigManagerProxy not deployed');
        assertTrue(address(depositManagerProxy) != address(0), 'DepositManagerProxy not deployed');
        assertTrue(address(layer2RegistryProxy) != address(0), 'Layer2RegistryProxy not deployed');
        assertTrue(address(layer2ManagerProxy) != address(0), 'Layer2ManagerProxy not deployed');
        assertTrue(
            address(l1BridgeRegistryProxy) != address(0),
            'L1BridgeRegistryProxy not deployed'
        );
        assertTrue(
            address(operatorManagerFactory) != address(0),
            'OperatorManagerFactory not deployed'
        );
        assertTrue(daoVault != address(0), 'DAOVault not deployed');
        assertTrue(daoAgendaManager != address(0), 'DAOAgendaManager not deployed');

        console.log('All contracts deployed successfully!');
    }

    function test_SeigManagerConfiguration() public view {
        console.log('\n=== Testing SeigManager Configuration ===');

        // Verify SeigManager is properly configured
        SeigManagerV1_2 seigManager = SeigManagerV1_2(address(seigManagerProxy));

        assertEq(seigManager.ton(), ton, 'TON address mismatch');
        assertEq(seigManager.wton(), wton, 'WTON address mismatch');
        assertEq(seigManager.registry(), address(layer2RegistryProxy), 'Registry address mismatch');
        assertEq(
            seigManager.depositManager(),
            address(depositManagerProxy),
            'DepositManager address mismatch'
        );
        assertEq(seigManager.seigPerBlock(), SEIG_PER_BLOCK, 'SeigPerBlock mismatch');

        console.log('SeigManager configuration verified!');
    }

    function test_SeigManagerSetData() public view {
        console.log('\n=== Testing SeigManager setData ===');

        SeigManagerV1_2 seigManager = SeigManagerV1_2(address(seigManagerProxy));

        assertEq(seigManager.powerton(), address(0), 'powerTON mismatch');
        assertEq(seigManager.dao(), address(daoCommitteeProxy), 'DAOCommitteeProxy mismatch');
        assertEq(seigManager.powerTONSeigRate(), 0, 'powerTONSeigRate mismatch');
        assertEq(seigManager.daoSeigRate(), 0.5e27, 'daoSeigRate mismatch');
        assertEq(seigManager.relativeSeigRate(), 0.5e27, 'relativeSeigRate mismatch');
        assertEq(seigManager.adjustCommissionDelay(), 93096, 'adjustCommissionDelay mismatch');
        assertEq(seigManager.minimumAmount(), 1000.1e27, 'minimumAmount mismatch');

        console.log('SeigManager setData verified!');
    }

    function test_DepositManagerConfiguration() public view {
        console.log('\n=== Testing DepositManager Configuration ===');

        // Verify DepositManager is properly configured
        DepositManager depositManager = DepositManager(address(depositManagerProxy));

        assertEq(depositManager.wton(), wton, 'WTON address mismatch');
        assertEq(
            depositManager.registry(),
            address(layer2RegistryProxy),
            'Registry address mismatch'
        );
        assertEq(
            depositManager.seigManager(),
            address(seigManagerProxy),
            'SeigManager address mismatch'
        );
        assertEq(
            depositManager.globalWithdrawalDelay(),
            GLOBAL_WITHDRAWAL_DELAY,
            'GlobalWithdrawalDelay mismatch'
        );

        console.log('DepositManager configuration verified!');
    }

    function test_MintPermissions() public {
        console.log('\n=== Testing Mint Permissions ===');

        // Verify SeigManager has minter role on Layer2Registry
        assertTrue(
            Layer2Registry(address(layer2RegistryProxy)).isMinter(address(seigManagerProxy)),
            'SeigManager is not minter on Layer2Registry'
        );

        // Verify SeigManager has minter role on WTON
        assertTrue(
            IWTON(wton).isMinter(address(seigManagerProxy)),
            'SeigManager is not minter on WTON'
        );

        console.log('Mint permissions verified!');
    }
}
