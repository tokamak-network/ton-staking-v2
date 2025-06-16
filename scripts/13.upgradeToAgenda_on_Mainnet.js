const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOAgendaManagerABI = require("../abi/daoAgendaManager.json").abi;
const SeigManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const DepositManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const TonABI = require("../abi/TON.json").abi;
const CandidateABI = require("../abi/Candidate.json").abi;
const DAOLogicABI = require("../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const candidateAddOnFactoryProxyABI = require("../artifacts/contracts/dao/factory/CandidateAddOnFactoryProxy.sol/CandidateAddOnFactoryProxy.json").abi;


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
    let tonAddr = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5";
    let candidateAddOnFactoryProxyAddr = "0xFA8ce5caF456115E72B96E5074769b8f66AA5861"

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

    //==== Set TON =================================
    let ton = new ethers.Contract(
        tonAddr,
        TonABI,
        ethers.provider
    )

    //==== Set candidateAddOnFactoryProxy =================================
    let candidateAddOnFactoryProxy = new ethers.Contract(
        candidateAddOnFactoryProxyAddr,
        candidateAddOnFactoryProxyABI,
        ethers.provider
    )

    //==== pauseCheck =================================
    let pauseProxy = await daoCommitteeProxy.pauseProxy()

    if (pauseProxy == true) {
        await daoCommitteeProxy.setProxyPause(false)
    }

    console.log("pauseProxy pass")

    //==== upgradeTo, upgradeTo2 Address =================================
    let candidateAddOnFactoryAddr = ""
    let daoCommittee_V2Addr = ""

    //==== Create Agenda =================================
    let targets = []
    let params = []
    let callDtata

    // =========================================
    // 1. set candidateAddOnFactoryProxy upgradeTo
    targets.push(candidateAddOnFactoryProxyAddr)
    callDtata = candidateAddOnFactoryProxy.interface.encodeFunctionData("upgradeTo", [candidateAddOnFactoryAddr])
    params.push(callDtata)

    // =========================================
    // 2. upgradeTo2 daoCommittee_V2
    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("upgradeTo2", [daoCommittee_V2Addr])
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
