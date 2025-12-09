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
    while (Date.now() < wakeUpTime) { }
}

async function CreateAgendaAboutRFC13() {
    //prepare before execute
    //Need deployer token
    //Need Pre-setting
    let daoCommitteeProxyAddr = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
    let daoAgendaManagerAddr = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08";
    let tonAddr = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044";
    let daoCommitteeV2Addr = "";

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

    //==== Set TON =================================
    let ton = new ethers.Contract(
        tonAddr,
        TonABI,
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
    // 1. upgradeTo2 daoCommittee_V2
    targets.push(daoCommitteeProxyAddr)
    callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("upgradeTo2", [daoCommitteeV2Addr])
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



const main = async () => {
    await CreateAgendaAboutRFC13()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
