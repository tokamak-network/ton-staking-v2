const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const SeigManagerV3ABI = require("../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json").abi;

const Web3EthAbi = require('web3-eth-abi');

const sepoliaContractInfo = {
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    DAOCommitteeProxy2: "0x399A7Aa3BF8da93319494CdFC495Ab20541eC1D4",
    DAOCommittee_V1: "0xaDf24e3885D4c8DB092514dF364b09f314F1e794",
    DAOCommitteeOwner: "0x63f116823B6Ed37271B0204A51e8ea4Eaa09c9a6",
    Layer2CandidateFactory: "0x770739A468D9262960ee0669f9Eaf0db6E21F81A",
    Layer2ManagerProxy: "0x0fDb12aF5Fece558d17237E2D252EC5dbA25396b",
    Layer2Manager: "0x0237839A14194085B5145D1d1e1E77dc92aCAF06",
    CandidateAddOnFactory: "0x2f60005daA6294081a7688bAb9BCb21ad45b0A90",
    L1BridgeRegistryProxy: "0xC8479A9F10a1E6275e0bFC4F9e058631fe63b8dC",
    SeigManagerProxy: "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
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

async function Check_DAOCommitteeOwner() {
    const [deployer] = await ethers.getSigners();

    //==== Set DAOCommitteeOwner =================================
    let daoCommitteeOwner = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeOwnerABI,
        ethers.provider
    )

    //==== Set SeigManagerProxy =================================
    let seigManagerV3 = new ethers.Contract(
        sepoliaContractInfo.SeigManagerProxy,
        SeigManagerV3ABI,
        ethers.provider
    )

    //==== Check Layer2Manager =================================
    let layer2ManagerAddr = await daoCommitteeOwner.layer2Manager()
    console.log("layer2ManagerProxyAddr : ", layer2ManagerAddr)

    //==== Check candidateAddOnFactory =================================
    let candidateAddOnFactoryAddr = await daoCommitteeOwner.candidateAddOnFactory()
    console.log("candidateAddOnFactoryAddr :", candidateAddOnFactoryAddr)

    //==== Check candidateAddOnFactory =================================
    let L1BridgeRegistryAddr = await seigManagerV3.l1BridgeRegistry()
    console.log("L1BridgeRegistryAddr :", L1BridgeRegistryAddr)
}

const main = async () => {
  await Check_DAOCommitteeOwner()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
