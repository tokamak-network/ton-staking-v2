const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOAgendaManagerABI = require("../abi/daoAgendaManager.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const SeigManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const DepositManagerProxy_Json = require('../abi/DepositManagerProxy.json')

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
}

const mainnetContractInfo = {
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
    DAOCommitteeProxy2: "",
    DAOCommittee_V1: "",
    DAOCommitteeOwner: ""
}

function sleep(ms) {
    const wakeUpTime = Date.now() + ms;
    while (Date.now() < wakeUpTime) {}
}

async function CreateAgendaTest() {
    //need Pre-setting
    let daoCommitteeProxy2 = "";
    let daoCommitteeLogic = "";
    let daoCommitteeOwner = "";
    let seigManagerV1_3 = "";
    
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    let oldDAOLogicAddress = "0xDC7e4c6cAe2123758f17D17572c6f6e820D2b431"

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        sepoliaContractInfo.DAOAgendaManager,
        DAOAgendaManagerABI,
        ethers.provider
    )

    //==== Set Proxy2Contract =================================
    let daoCommitteeProxy2Contract = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOProxy2ABI,
        ethers.provider
    )

    //==== Set seigManagerProxy =================================
    let seigManagerProxy = new ethers.Contract(
        sepoliaContractInfo.SeigManagerProxy,  
        SeigManagerProxy_Json.abi, 
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

    targets.push(sepoliaContractInfo.DAOCommitteeProxy);
    functionBytecodes.push(functionBytecode0)


    const functionBytecode1 = daoCommitteeProxy2Contract.interface.encodeFunctionData(
        "upgradeTo2", [daoCommitteeLogic]
    )

    targets.push(sepoliaContractInfo.DAOCommitteeProxy);
    functionBytecodes.push(functionBytecode1)

    const functionBytecode2 = daoCommitteeProxy2Contract.interface.encodeFunctionData(
        "setImplementation2", [daoCommitteeOwner, 1, true]
    )

    targets.push(sepoliaContractInfo.DAOCommitteeProxy);
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
            daoCommitteeOwner]
        )

    targets.push(sepoliaContractInfo.DAOCommitteeProxy);
    functionBytecodes.push(functionBytecode3)

    const functionBytecode4 = seigManagerProxy.interface.encodeFunctionData("setImplementation2",
        [
            seigManagerV1_3,
            1,
            true
        ])
    targets.push(seigManagerProxy.address)
    functionBytecodes.push(functionBytecode4)
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
