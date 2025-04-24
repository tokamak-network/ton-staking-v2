const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOAgendaManagerABI = require("../abi/daoAgendaManager.json").abi;
const SeigManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const DepositManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const TonABI = require("../abi/TON.json").abi;
const SeigManagerV2ABI = require("../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json").abi;
const SeigManagerV3ABI = require("../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json").abi;
const DepositManagerV1ABI = require("../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json").abi;
const l1BridgeRegistryV1ABI = require("../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json").abi;
const CandidateABI = require("../abi/Candidate.json").abi;
const DAOLogicABI = require("../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;


const Web3EthAbi = require('web3-eth-abi');

function sleep(ms) {
    const wakeUpTime = Date.now() + ms;
    while (Date.now() < wakeUpTime) {}
}

async function CreateAgenda() {
    //prepare before execute
    //Need deployer token
    //Need Pre-setting
    let daoCommitteeProxyAddr = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26";
    let daoAgendaManagerAddr = "0xcD4421d082752f363E1687544a09d5112cD4f484";
    let depositManagerProxyAddr = "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e";
    let seigManagerProxyAddr = "0x0b55a0f463b6defb81c6063973763951712d0e5f";
    
    let tonAddr = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5";

    let daoCommitteeProxy2Addr = "0x9e7f54efF4A4D35097e0Acb6994A723F1a28368c";
    let daoCommitteeV1Addr = "0x9050Af1638f379A018737880aD946CdDA9101A25";
    let daoCommitteeOwnerAddr = "0xcb9859Dc0fBECa68eFFf2bce289150513fdF7D92";
    let seigManagerV1_2Addr = "0xb1958719b3Af9B4d85D93EFC5e317C97cCe9aBc4";
    let seigManagerV1_3Addr = "0xce18C6F84F10881eA47A43AF7311A29bb116F628";
    let depositManagerV1_1Addr = "0x74bC3031b9369e6b898e82784106257D4D37Eac5";
    let l1BridgeRegistryProxyAddr = "0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4";
    let layer2ManagerProxyAddr = "0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D";
    let candidateAddOnFactoryProxyAddr = "0xFA8ce5caF456115E72B96E5074769b8f66AA5861"

    let cooldownTime = 259200
    
    let legacySystemConfigAddr = ""

    // need the check setImplementation2 SeigManger & DepositManager number

    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        daoCommitteeProxyAddr,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        daoAgendaManagerAddr,
        DAOAgendaManagerABI,
        ethers.provider
    )

    //==== Set Proxy2Contract =================================
    let daoCommitteeProxy2Contract = new ethers.Contract(
        daoCommitteeProxyAddr,
        DAOProxy2ABI,
        ethers.provider
    )

    //==== Set SeigManagerProxy =================================
    let seigManagerProxy = new ethers.Contract(
        seigManagerProxyAddr,
        SeigManagerProxy_Json.abi,
        ethers.provider
    )

    //==== Set DepositManagerProxy =================================
    let depositManagerProxy = new ethers.Contract(
        depositManagerProxyAddr,
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
    let seigManagerV1_2 = new ethers.Contract(
        seigManagerV1_2Addr,
        SeigManagerV2ABI,
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
        tonAddr,
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
    let targets = []
    let params = []
    let callDtata

    // =========================================
    // 1. upgradeTo daoCommitteeProxy2Contract
    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeProxy.interface.encodeFunctionData("upgradeTo", [daoCommitteeProxy2Addr])
    params.push(callDtata)

    // =========================================
    // 2. upgradeTo2 daoCommittee_V1
    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("upgradeTo2", [daoCommitteeV1Addr])
    params.push(callDtata)

    // =========================================
    // 3. setImplementation2 1, true, daoCommitteeOwner
    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("setImplementation2", [daoCommitteeOwnerAddr, 1, true])
    params.push(callDtata)

    // =========================================
    // 4. setSelectorImplementations2  daoCommitteeOwner
    const _setCooldownTime = Web3EthAbi.encodeFunctionSignature("setCooldownTime(uint256)");
    const _setLayer2CandidateFactory = Web3EthAbi.encodeFunctionSignature("setCandidateAddOnFactory(address)");
    const _setLayer2Manager = Web3EthAbi.encodeFunctionSignature("setLayer2Manager(address)");
    const _setSeigManager = Web3EthAbi.encodeFunctionSignature("setSeigManager(address)");
    const _setDaoVault = Web3EthAbi.encodeFunctionSignature("setDaoVault(address)")
    const _setLayer2Registry = Web3EthAbi.encodeFunctionSignature("setLayer2Registry(address)")
    const _setAgendaManager = Web3EthAbi.encodeFunctionSignature("setAgendaManager(address)")
    const _setCandidateFactory = Web3EthAbi.encodeFunctionSignature("setCandidateFactory(address)")
    const _setTon = Web3EthAbi.encodeFunctionSignature("setTon(address)")
    const _setWton = Web3EthAbi.encodeFunctionSignature("setWton(address)")
    const _increaseMaxMember = Web3EthAbi.encodeFunctionSignature("increaseMaxMember(uint256,uint256)")
    const _setQuorum = Web3EthAbi.encodeFunctionSignature("setQuorum(uint256)")
    const _decreaseMaxMember = Web3EthAbi.encodeFunctionSignature("decreaseMaxMember(uint256,uint256)")
    const _setActivityRewardPerSecond = Web3EthAbi.encodeFunctionSignature("setActivityRewardPerSecond(uint256)")
    const _setCandidatesSeigManager = Web3EthAbi.encodeFunctionSignature("setCandidatesSeigManager(address[],address)")
    const _setCandidatesCommittee = Web3EthAbi.encodeFunctionSignature("setCandidatesCommittee(address[],address)")
    const _setBurntAmountAtDAO = Web3EthAbi.encodeFunctionSignature("setBurntAmountAtDAO(uint256)")
    const _setdaoExecuteTransaction = Web3EthAbi.encodeFunctionSignature({
        name: 'daoExecuteTransaction',
        type: 'function',
        inputs: [
            {
                type: 'address',
                name: '_to'
            },
            {
                type: 'bytes',
                name: '_data'
            }
        ]
    })

    const functions = [
        _setCooldownTime,_setLayer2CandidateFactory,_setLayer2Manager,_setSeigManager,_setDaoVault,_setLayer2Registry,
        _setAgendaManager,_setCandidateFactory,_setTon,_setWton,_increaseMaxMember,_setQuorum,_decreaseMaxMember,
        _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setBurntAmountAtDAO,_setdaoExecuteTransaction
    ]

    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData(
        "setSelectorImplementations2", [
            functions,
            daoCommitteeOwnerAddr
         ])
    params.push(callDtata)

    // =========================================
    // 5. upgrade SeigManager SeigManagerV1_2
    targets.push(seigManagerProxy.address)
    callDtata = seigManagerProxy.interface.encodeFunctionData("upgradeTo",
        [
            seigManagerV1_2Addr,
        ])
    params.push(callDtata)

    // =========================================
    // 6. upgrade SeigManager setImplementation2
    targets.push(seigManagerProxy.address)
    callDtata = seigManagerProxy.interface.encodeFunctionData("setImplementation2",
        [
            seigManagerV1_3Addr,
            1,
            true
        ])
    params.push(callDtata)

    // =========================================
    //  7. upgrade SeigManager setSelectorImplementations2
    targets.push(seigManagerProxy.address)

    const selector1 = Web3EthAbi.encodeFunctionSignature("updateSeigniorage()");
    const selector2 = Web3EthAbi.encodeFunctionSignature("updateSeigniorageLayer(address)");
    const selector3 = Web3EthAbi.encodeFunctionSignature("estimatedDistribute(uint256,address)");
    const selector4 = Web3EthAbi.encodeFunctionSignature("excludeFromL2Seigniorage(address)");
    const selector5 = Web3EthAbi.encodeFunctionSignature("includeFromL2Seigniorage(address)");
    const selector6 = Web3EthAbi.encodeFunctionSignature("claimableL2Seigniorage(address)");
    const selector7 = Web3EthAbi.encodeFunctionSignature("pause()");
    const selector8 = Web3EthAbi.encodeFunctionSignature("unpause()");

    let functionBytecodes = [
        selector1, selector2, selector3, selector4, selector5,
        selector6, selector7, selector8
    ];

    callDtata = seigManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
        [
            functionBytecodes,
            seigManagerV1_3Addr
        ])
    params.push(callDtata)

     // =========================================
    //  8. upgrade DepositManager setTargetSetImplementation2
    targets.push(depositManagerProxy.address)
    callDtata = depositManagerProxy.interface.encodeFunctionData("setImplementation2",
        [
            depositManagerV1_1Addr,
            2,
            true
        ])
    params.push(callDtata)

    // =========================================
    //  9. upgrade DepositManager setSelectorImplementations2
    targets.push(depositManagerProxy.address)
    const selector_1 = Web3EthAbi.encodeFunctionSignature("ton()");
    const selector_2 = Web3EthAbi.encodeFunctionSignature("minDepositGasLimit()");
    const selector_3 = Web3EthAbi.encodeFunctionSignature("setMinDepositGasLimit(uint32)");
    const selector_4 = Web3EthAbi.encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");
    const selector_5 = Web3EthAbi.encodeFunctionSignature("l1BridgeRegistry()");
    const selector_6 = Web3EthAbi.encodeFunctionSignature("layer2Manager()");
    const selector_7 = Web3EthAbi.encodeFunctionSignature("setAddresses(address,address)");
    const selector_8 = Web3EthAbi.encodeFunctionSignature("requestWithdrawal(address,uint256)");

    let functionBytecodes_1 = [ selector_1, selector_2, selector_3, selector_4, selector_5, selector_6, selector_7, selector_8];

    callDtata = depositManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
        [
            functionBytecodes_1,
            depositManagerV1_1Addr

        ])
    params.push(callDtata)

    // =========================================
    //  10. set DAOCommitteeProxy candidateAddOnFactory
    targets.push(daoCommitteeProxy.address)
    callDtata = daoCommitteeOwner.interface.encodeFunctionData("setCandidateAddOnFactory", [candidateAddOnFactoryProxyAddr])
    params.push(callDtata)

    // =========================================
    //  11. set DAOCommitteeProxy layer2Manager
    targets.push(daoCommitteeProxy.address)
    callDtata = daoCommitteeOwner.interface.encodeFunctionData("setLayer2Manager", [layer2ManagerProxyAddr])
    params.push(callDtata)

    // =========================================
    //  12. set seigManagerProxy setLayer2Manager
    targets.push(seigManagerProxy.address)
    callDtata = seigManagerV1_2.interface.encodeFunctionData("setLayer2Manager", [layer2ManagerProxyAddr])
    params.push(callDtata)

    // =========================================
    //  13. set seigManagerProxy setL1BridgeRegistry
    targets.push(seigManagerProxy.address)
    callDtata = seigManagerV1_2.interface.encodeFunctionData("setL1BridgeRegistry", [l1BridgeRegistryProxyAddr])
    params.push(callDtata)


    // =========================================
    //  14. set depositManagerProxy setAddresses
    targets.push(depositManagerProxy.address)
    callDtata = depositManagerV1_1.interface.encodeFunctionData("setAddresses", [
        l1BridgeRegistryProxyAddr,
        layer2ManagerProxyAddr 
    ])
    params.push(callDtata)

    // =========================================
    //  15. set daoCommitteeProxy setCooldownTime
    targets.push(daoCommitteeProxy.address)
    callDtata = daoCommitteeOwner.interface.encodeFunctionData("setCooldownTime", [
            cooldownTime
        ]
    )
    params.push(callDtata)

    // =========================================
    // . make an agenda
    const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
    const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
    const agendaFee = await daoagendaManager.createAgendaFees();
    const param = Web3EthAbi.encodeParameters(
        ["address[]", "uint128", "uint128", "bool", "bytes[]"],
        [
            targets,
            noticePeriod.toString(),
            votingPeriod.toString(),
            true,
            params
        ]
    )
    
    // =========================================
    // Propose an agenda
    console.log("deployerAddr :", deployer.address)
    let receipt = await ton.connect(deployer).approveAndCall(
        daoCommitteeProxy.address,
        agendaFee,
        param
    )
    console.log("tx Hash :", receipt.hash)
    console.log(receipt)
    console.log(receipt.nonce)
}


async function castVote() {
    const [deployer] = await ethers.getSigners();
    
    console.log("voter : ", deployer.address);
    
    let daoAgendaManagerAddr = "";
    let agendaID = 0
    
    //Member address : 
    let MemberContractAddr = ""
    //Member address : 
    // let MemberContractAddr = ""

    //==== Set MemberContract =================================
    let memberContract = new ethers.Contract(
        MemberContractAddr,
        CandidateABI,
        ethers.provider
    )

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        daoAgendaManagerAddr,
        DAOAgendaManagerABI,
        ethers.provider
    )
    
    const agenda = await daoagendaManager.agendas(agendaID);  

    // const beforeCountingYes = agenda[7];
    // const beforeCountingNo = agenda[8];
    // const beforeCountingAbstain = agenda[9];
    
    const vote = 1

    // counting 0:abstainVotes 1:yesVotes 2:noVotes
    await memberContract.connect(deployer).castVote(
        agendaID,
        vote,
        "vote"
    )
    console.log("vote done")

}

async function executeAgenda() {
    const [deployer] = await ethers.getSigners();
    let agendaID = 44

    let daoAgendaManagerAddr = "";
    let daoCommitteeProxyAddr = "";

    //==== Set DAOLogicV1 =================================
    let daoLogicV1 = new ethers.Contract(
        daoCommitteeProxyAddr,
        DAOLogicABI,
        ethers.provider
    )

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        daoAgendaManagerAddr,
        DAOAgendaManagerABI,
        ethers.provider
    )


    const agenda = await daoagendaManager.agendas(agendaID);
    
    await daoLogicV1.connect(deployer).executeAgenda(agendaID);
    console.log("executed agendaID :", agendaID)
}


const main = async () => {
  await CreateAgenda()
//   await castVote()
//   await executeAgenda()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
