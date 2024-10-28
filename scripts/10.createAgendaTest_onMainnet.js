const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOAgendaManagerABI = require("../abi/daoAgendaManager.json").abi;
const SeigManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const DepositManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const TonABI = require("../abi/TON.json").abi;
const SeigManagerV3ABI = require("../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json").abi;
const DepositManagerV1ABI = require("../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json").abi;
const l1BridgeRegistryV1ABI = require("../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json").abi;


const Web3EthAbi = require('web3-eth-abi');

const sepoliaContractInfo = {
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    DAOCommitteeProxy2: "0x0cb4E974302864D1059028de86757Ca55D121Cb8",
    DAOCommittee_V1: "0xB800a42D9A8e5036B75246aeDA578DCe58f85B18",
    DAOCommitteeOwner: "0x34B6e334D88436Fbbb9c316865A1BA454769C090",
    Layer2CandidateFactory: "0x770739A468D9262960ee0669f9Eaf0db6E21F81A",
    Layer2Manager: "0x0237839A14194085B5145D1d1e1E77dc92aCAF06",
    DAOAgendaManager: "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08",
    SeigManagerProxy : "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7",
    DepositManagerProxy : "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F",
    TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
}

const mainnetContractInfo = {
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
    DAOAgendaManager: "0xcD4421d082752f363E1687544a09d5112cD4f484",
    SeigManagerProxy: "0x0b55a0f463b6defb81c6063973763951712d0e5f",
    DepositManagerProxy: "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e",
    TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
}

function sleep(ms) {
    const wakeUpTime = Date.now() + ms;
    while (Date.now() < wakeUpTime) {}
}

async function CreateAgendaTest() {
    //need Pre-setting
    let daoCommitteeProxy2 = "";
    let daoCommitteeLogic = "";
    let daoCommitteeOwnerAddr = "";
    let seigManagerV1_3Addr = "";
    let depositManagerV1_1Addr = "";
    let l1BridgeRegistryProxyAddr = "";
    let layer2ManagerProxyAddr = "";
    let legacySystemConfigAddr = ""
    let candidateAddOnFactoryProxyAddr = ""
    let l2TonAddress = "0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2"
    let name = 'Titan'
    need the check setImplementation2 SeigManger & DepositManager number
    
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        mainnetContractInfo.DAOCommitteeProxy,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    // let oldDAOLogicAddress = "0xDC7e4c6cAe2123758f17D17572c6f6e820D2b431"

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        mainnetContractInfo.DAOAgendaManager,
        DAOAgendaManagerABI,
        ethers.provider
    )

    //==== Set Proxy2Contract =================================
    let daoCommitteeProxy2Contract = new ethers.Contract(
        mainnetContractInfo.DAOCommitteeProxy,
        DAOProxy2ABI,
        ethers.provider
    )

    //==== Set SeigManagerProxy =================================
    let seigManagerProxy = new ethers.Contract(
        mainnetContractInfo.SeigManagerProxy,  
        SeigManagerProxy_Json.abi, 
        ethers.provider    
    ) 

    //==== Set DepositManagerProxy =================================
    let depositManagerProxy = new ethers.Contract(
        mainnetContractInfo.DepositManagerProxy,  
        DepositManagerProxy_Json.abi, 
        ethers.provider
    ) 

    //==== Set DaoCommitteeOwner =================================
    let daoCommitteeOwner = new ethers.Contract(
        daoCommitteeOwnerAddr,  
        DAOCommitteeOwnerABI, 
        ethers.provider
    ) 

    //==== Set seigManagerV1_3 =================================
    let seigManagerV1_3 = new ethers.Contract(
        seigManagerV1_3Addr,  
        SeigManagerV3ABI, 
        ethers.provider
    )

    //==== Set depositManagerV1_1 =================================
    let depositManagerV1_1 = new ethers.Contract(
        depositManagerV1_1Addr,  
        DepositManagerV1ABI, 
        ethers.provider
    ) 
    
    //==== Set TON =================================
    let ton = new ethers.Contract(
        mainnetContractInfo.TON,
        TonABI,
        ethers.provider
    )

    //==== Set l1BridgeRegistry =================================
    let l1BridgeRegistry = new ethers.Contract(
        l1BridgeRegistryProxyAddr,
        l1BridgeRegistryV1ABI,
        ethers.provider
    )

    //==== pauseCheck =================================
    let pauseProxy = await daoCommitteeProxy.pauseProxy()

    if (pauseProxy == true) {
        await daoCommitteeProxy.setProxyPause(false)
    }

    console.log("pauseProxy pass")

    //==== Create Agenda =================================
    const _setCandidateAddOnFactory = Web3EthAbi.encodeFunctionSignature(
        "setCandidateAddOnFactory(address)"
    ) 

    const _setLayer2Manager = Web3EthAbi.encodeFunctionSignature(
        "setLayer2Manager(address)"
    ) 

    const _setTargetSetLayer2Manager = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetLayer2Manager(address,address)"
    )

    const _setTargetSetL1BridgeRegistry = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetL1BridgeRegistry(address,address)"
    )

    const _setTargetLayer2StartBlock = Web3EthAbi.encodeFunctionSignature(
        "setTargetLayer2StartBlock(address,uint256)"
    )

    const _setTargetSetImplementation2 = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetImplementation2(address,address,uint256,bool)"
    )

    const _setTargetSetSelectorImplementations2 = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetSelectorImplementations2(address,bytes4[],address)"
    )

    const _setSeigManager = Web3EthAbi.encodeFunctionSignature(
        "setSeigManager(address)"
    )

    const _setTargetSeigManager = Web3EthAbi.encodeFunctionSignature(
        "setTargetSeigManager(address,address)"
    )

    const _setSeigPause = Web3EthAbi.encodeFunctionSignature(
        "setSeigPause()"
    )

    const _setSeigUnpause = Web3EthAbi.encodeFunctionSignature(
        "setSeigUnpause()"
    )

    const _setTargetGlobalWithdrawalDelay = Web3EthAbi.encodeFunctionSignature(
        "setTargetGlobalWithdrawalDelay(address,uint256)"
    )

    const _setTargetAddMinter = Web3EthAbi.encodeFunctionSignature(
        "setTargetAddMinter(address,address)"
    )

    const _setTargetUpgradeTo = Web3EthAbi.encodeFunctionSignature(
        "setTargetUpgradeTo(address,address)"
    )

    const _setTargetSetTON = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetTON(address,address)"
    )
    
    const _setTargetSetWTON = Web3EthAbi.encodeFunctionSignature(
        "setTargetSetWTON(address,address)"
    )

    const _setDaoVault = Web3EthAbi.encodeFunctionSignature(
        "setDaoVault(address)"
    )

    const _setLayer2Registry = Web3EthAbi.encodeFunctionSignature(
        "setLayer2Registry(address)"
    )

    const _setAgendaManager = Web3EthAbi.encodeFunctionSignature(
        "setAgendaManager(address)"
    )

    const _setCandidateFactory = Web3EthAbi.encodeFunctionSignature(
        "setCandidateFactory(address)"
    )

    const _setTon = Web3EthAbi.encodeFunctionSignature(
        "setTon(address)"
    )

    const _setWton = Web3EthAbi.encodeFunctionSignature(
        "setWton(address)"
    )

    const _increaseMaxMember = Web3EthAbi.encodeFunctionSignature(
        "increaseMaxMember(uint256,uint256)"
    )

    const _setQuorum = Web3EthAbi.encodeFunctionSignature(
        "setQuorum(uint256)"
    )

    const _decreaseMaxMember = Web3EthAbi.encodeFunctionSignature(
        "decreaseMaxMember(uint256,uint256)"
    )

    const _setBurntAmountAtDAO = Web3EthAbi.encodeFunctionSignature(
        "setBurntAmountAtDAO(uint256)"
    )

    const _setActivityRewardPerSecond = Web3EthAbi.encodeFunctionSignature(
        "setActivityRewardPerSecond(uint256)"
    )

    const _setCandidatesSeigManager = Web3EthAbi.encodeFunctionSignature(
        "setCandidatesSeigManager(address[],address)"
    )

    const _setCandidatesCommittee = Web3EthAbi.encodeFunctionSignature(
        "setCandidatesCommittee(address[],address)"
    )

    const _setCreateAgendaFees = Web3EthAbi.encodeFunctionSignature(
        "setCreateAgendaFees(uint256)"
    )

    const _setMinimumNoticePeriodSeconds = Web3EthAbi.encodeFunctionSignature(
        "setMinimumNoticePeriodSeconds(uint256)"
    )

    const _setMinimumVotingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
        "setMinimumVotingPeriodSeconds(uint256)"
    )

    const _setExecutingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
        "setExecutingPeriodSeconds(uint256)"
    )

    let setSelectorBytes = [
        _setCandidateAddOnFactory,_setLayer2Manager,_setTargetSetLayer2Manager,_setTargetSetL1BridgeRegistry,
        _setTargetLayer2StartBlock,_setTargetSetImplementation2,_setTargetSetSelectorImplementations2,
        _setSeigManager,_setTargetSeigManager,_setSeigPause,_setSeigUnpause,
        _setTargetGlobalWithdrawalDelay,_setTargetAddMinter,_setTargetUpgradeTo,_setTargetSetTON,_setTargetSetWTON,
        _setDaoVault,_setLayer2Registry,_setAgendaManager,_setCandidateFactory,_setTon,_setWton,
        _increaseMaxMember,_setQuorum,_decreaseMaxMember,_setBurntAmountAtDAO,
        _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setCreateAgendaFees,
        _setMinimumNoticePeriodSeconds,_setMinimumVotingPeriodSeconds,_setExecutingPeriodSeconds
    ]

    const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
    const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

    const agendaFee = await daoagendaManager.createAgendaFees();

    let targets = [];
    let functionBytecodes = [];
    
    const functionBytecode0 = daoCommitteeProxy.interface.encodeFunctionData(
        "upgradeTo", [daoCommitteeProxy2]
    )

    targets.push(mainnetContractInfo.DAOCommitteeProxy);
    functionBytecodes.push(functionBytecode0)


    const functionBytecode1 = daoCommitteeProxy2Contract.interface.encodeFunctionData(
        "upgradeTo2", [daoCommitteeLogic]
    )

    targets.push(mainnetContractInfo.DAOCommitteeProxy);
    functionBytecodes.push(functionBytecode1)

    const functionBytecode2 = daoCommitteeProxy2Contract.interface.encodeFunctionData(
        "setImplementation2", [daoCommitteeOwner.address, 1, true]
    )

    targets.push(mainnetContractInfo.DAOCommitteeProxy);
    functionBytecodes.push(functionBytecode2)

    const functionBytecode3 = daoCommitteeProxy2Contract.interface.encodeFunctionData(
        "setSelectorImplementations2", [
            [
                _setCandidateAddOnFactory,_setLayer2Manager,_setTargetSetLayer2Manager,_setTargetSetL1BridgeRegistry,
                _setTargetLayer2StartBlock,_setTargetSetImplementation2,_setTargetSetSelectorImplementations2,
                _setSeigManager,_setTargetSeigManager,_setSeigPause,_setSeigUnpause,
                _setTargetGlobalWithdrawalDelay,_setTargetAddMinter,_setTargetUpgradeTo,_setTargetSetTON,_setTargetSetWTON,
                _setDaoVault,_setLayer2Registry,_setAgendaManager,_setCandidateFactory,_setTon,_setWton,
                _increaseMaxMember,_setQuorum,_decreaseMaxMember,_setBurntAmountAtDAO,
                _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setCreateAgendaFees,
                _setMinimumNoticePeriodSeconds,_setMinimumVotingPeriodSeconds,_setExecutingPeriodSeconds
            ],
            daoCommitteeOwner.address]
        )

    targets.push(mainnetContractInfo.DAOCommitteeProxy);
    functionBytecodes.push(functionBytecode3)

    const functionBytecode4 = seigManagerProxy.interface.encodeFunctionData("setImplementation2",
        [
            seigManagerV1_3.address,
            1,
            true
        ])
    targets.push(seigManagerProxy.address)
    functionBytecodes.push(functionBytecode4)

    const selector1 = Web3EthAbi.encodeFunctionSignature("setLayer2StartBlock(uint256)");
    const selector2 = Web3EthAbi.encodeFunctionSignature("setLayer2Manager(address)");
    const selector3 = Web3EthAbi.encodeFunctionSignature("setL1BridgeRegistry(address)");
    const selector4 = Web3EthAbi.encodeFunctionSignature("updateSeigniorage()");
    const selector5 = Web3EthAbi.encodeFunctionSignature("updateSeigniorageOperator()");
    const selector6 = Web3EthAbi.encodeFunctionSignature("updateSeigniorageLayer()");
    const selector7 = Web3EthAbi.encodeFunctionSignature("allowIssuanceLayer2Seigs(address)");
    const selector8 = Web3EthAbi.encodeFunctionSignature("totalLayer2TVL()");
    const selector9 = Web3EthAbi.encodeFunctionSignature("layer2RewardInfo(address)");
    const selector10 = Web3EthAbi.encodeFunctionSignature("l1BridgeRegistry()");
    const selector11 = Web3EthAbi.encodeFunctionSignature("layer2Manager()");
    const selector12 = Web3EthAbi.encodeFunctionSignature("layer2StartBlock()");
    const selector13 = Web3EthAbi.encodeFunctionSignature("l2RewardPerUint()");
    const selector14 = Web3EthAbi.encodeFunctionSignature("unSettledReward(address)");
    const selector15 = Web3EthAbi.encodeFunctionSignature("estimatedDistribute(uint256,address,bool)");
    const selector16 = Web3EthAbi.encodeFunctionSignature("excludeFromSeigniorage(address)");
    const selector17 = Web3EthAbi.encodeFunctionSignature("unallocatedSeigniorage()");
    const selector18 = Web3EthAbi.encodeFunctionSignature("unallocatedSeigniorageAt(uint256)");
    const selector19 = Web3EthAbi.encodeFunctionSignature("stakeOfAllLayers()");
    const selector20 = Web3EthAbi.encodeFunctionSignature("stakeOfAllLayersAt(uint256)");

    let setSelectorBytes2 = [
        selector1, selector2, selector3, selector4, selector5,
        selector6, selector7, selector8, selector9, selector10,
        selector11, selector12, selector13, selector14, selector15,
        selector16,selector17, selector18, selector19, selector20
    ];

    const functionBytecode5 = seigManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
        [
            setSelectorBytes2,
            seigManagerV1_3.address
        ])
    targets.push(seigManagerProxy.address)
    functionBytecodes.push(functionBytecode5)

    const functionBytecode6 = depositManagerProxy.interface.encodeFunctionData("setImplementation2",
        [
            depositManagerV1_1.address,
            2,
            true
        ])
    targets.push(depositManagerProxy.address)
    functionBytecodes.push(functionBytecode6)

    const selector_1 = Web3EthAbi.encodeFunctionSignature("ton()");
    const selector_2 = Web3EthAbi.encodeFunctionSignature("minDepositGasLimit()");
    const selector_3 = Web3EthAbi.encodeFunctionSignature("setMinDepositGasLimit(uint256)");
    const selector_4 = Web3EthAbi.encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");
    const selector_5 = Web3EthAbi.encodeFunctionSignature("l1BridgeRegistry()");
    const selector_6 = Web3EthAbi.encodeFunctionSignature("layer2Manager()");
    const selector_7 = Web3EthAbi.encodeFunctionSignature("setAddresses(address,address)");

    let setSelectorBytes3 = [ selector_1, selector_2, selector_3, selector_4, selector_5, selector_6, selector_7];

    const functionBytecode7 = depositManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
        [
            setSelectorBytes3,
            depositManagerV1_1.address

        ])
    targets.push(depositManagerProxy.address)
    functionBytecodes.push(functionBytecode7)

    const functionBytecode8 = daoCommitteeOwner.interface.encodeFunctionData("setCandidateAddOnFactory", [candidateAddOnFactoryProxyAddr])
    targets.push(sepoliaContractInfo.DAOCommitteeProxy)
    functionBytecodes.push(functionBytecode8)

    const functionBytecode9 = daoCommitteeOwner.interface.encodeFunctionData("setLayer2Manager", [layer2ManagerProxyAddr])
    targets.push(sepoliaContractInfo.DAOCommitteeProxy)
    functionBytecodes.push(functionBytecode9)

    const functionBytecode10 = seigManagerV1_3.interface.encodeFunctionData("setLayer2Manager", [layer2ManagerProxyAddr])
    targets.push(seigManagerProxy.address)
    functionBytecodes.push(functionBytecode10)

    const functionBytecode11 = seigManagerV1_3.interface.encodeFunctionData("setL1BridgeRegistry", [l1BridgeRegistryProxyAddr])
    targets.push(seigManagerProxy.address)
    functionBytecodes.push(functionBytecode11)

    const functionBytecode12 = depositManagerV1_1.interface.encodeFunctionData("setAddresses", [
        l1BridgeRegistryProxyAddr,
        layer2ManagerProxyAddr ])
    targets.push(depositManagerProxy.address)
    functionBytecodes.push(functionBytecode12)

    const functionBytecode13 = l1BridgeRegistry.interface.encodeFunctionData("registerRollupConfigByManager(address,uint8,address,string)", [ legacySystemConfigAddr, 1,  l2TonAddress, name])
    targets.push(l1BridgeRegistryProxyAddr)
    functionBytecodes.push(functionBytecode13)

    const param = Web3EthAbi.encodeParameters(
        ["address[]", "uint128", "uint128", "bool", "bytes[]"],
        [
            targets,
            noticePeriod.toString(),
            votingPeriod.toString(),
            true,
            functionBytecodes
        ]
    )

    await ton.connect(deployer).approveAndCall(
        daoCommitteeProxy.address,
        agendaFee,
        param
    );
}


const main = async () => {
  await CreateAgendaTest()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
