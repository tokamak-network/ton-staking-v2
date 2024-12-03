const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommitteeV1ABI = require("../../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const TONABI = require("../../abi/TON.json").abi;
const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const L1DAOExecutorABI = require("../../artifacts/contracts/dao/L1/L1DAOExecutor.sol/L1DAOExecutor.json").abi;
const L2DAOExecutorABI = require("../../artifacts/contracts/dao/L2/L2DAOExecutor.sol/L2DAOExecutor.json").abi;
const L2CrossTradeProxyABI = require("../../abi/L2CrossTradeProxy.json").abi;
const L1CrossDomainMessagerABI = require("../../abi/IL1CrossDomainMessenger.json").abi;


const Web3EthAbi = require('web3-eth-abi');
const { padLeft } = require('web3-utils');

const sepoliaContractInfo = {
    TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
    DAOAgendaManager: "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08",
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    DAOCommitteeProxy2: "0x0cb4E974302864D1059028de86757Ca55D121Cb8",
    DAOCommittee_V1: "0xB800a42D9A8e5036B75246aeDA578DCe58f85B18",
    DAOCommitteeOwner: "0x34B6e334D88436Fbbb9c316865A1BA454769C090",
    Layer2CandidateFactory: "0x770739A468D9262960ee0669f9Eaf0db6E21F81A",
    Layer2Manager: "0x0237839A14194085B5145D1d1e1E77dc92aCAF06",
    L1DAOExecutor: "0x109c37fdB56850A6dfd0e29290860B423c25f7e6",
    l1CrossDomainMessenger: "0xd054Bc768aAC07Dd0BaA2856a2fFb68F495E4CC2",
    L2DAOExecutor: "0x988A796F5ca1d4848d00daC1c17d0A2Bbca18a9b",     //Thanos
    L2CrossTradeProxy: "0x040D333A908322eba974A8d40996f1367F2a2593"     //Thanos
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

async function executeAgenda() {
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    //==== pauseCheck =================================
    let pauseProxy = await daoCommitteeProxy.pauseProxy()

    if (pauseProxy == true) {
        await daoCommitteeProxy.setProxyPause(false)
    }

    console.log("pauseProxy pass")

    //==== Set DAOCommitteeV1 =================================
    let daoCommitteeV1 = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeV1ABI,
        ethers.provider
    )
    console.log("set DAOCommitteeV1 done")

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        sepoliaContractInfo.DAOAgendaManager,
        DAOAgendaManagerABI,
        ethers.provider
    )
    console.log("set DAOAgendaManager done")

    //==== Set L2CrossTradeProxy =================================
    let l2crossTradeProxy = new ethers.Contract(
        sepoliaContractInfo.L2CrossTradeProxy,
        L2CrossTradeProxyABI,
        ethers.provider
    )

    //==== Set L2DAOExecutorABI =================================
    let l2daoExecutor = new ethers.Contract(
        sepoliaContractInfo.L2DAOExecutor,
        L2DAOExecutorABI,
        ethers.provider
    )

    //==== Set L1CrossDomainMessenger =================================
    let l1CrossDomainMessenger = new ethers.Contract(
        sepoliaContractInfo.l1CrossDomainMessenger,
        L1CrossDomainMessagerABI,
        ethers.provider
    )

    //==== Set TON =================================
    let ton = new ethers.Contract(
        sepoliaContractInfo.TON,
        TONABI,
        ethers.provider
    )
    console.log("set TON done")

    let agendaId = 30
    let tx = await daoCommitteeV1.connect(deployer).executeAgenda(agendaId)
    console.log("tx :", tx)

}


const main = async () => {
  await executeAgenda()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
