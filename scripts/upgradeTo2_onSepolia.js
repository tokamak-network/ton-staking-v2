const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommittee_V2ABI = require("../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;

const Web3EthAbi = require('web3-eth-abi');

const sepoliaContractInfo = {
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    DAOCommitteeProxy2: "0x0cb4E974302864D1059028de86757Ca55D121Cb8",
    DAOCommittee_V1: "0xB800a42D9A8e5036B75246aeDA578DCe58f85B18",
    DAOCommitteeOwner: "0x34B6e334D88436Fbbb9c316865A1BA454769C090",
    Layer2CandidateFactory: "0x770739A468D9262960ee0669f9Eaf0db6E21F81A",
    Layer2Manager: "0x0237839A14194085B5145D1d1e1E77dc92aCAF06",
    MultiSigWallet: ""
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

async function ChangeUpgradeTo2() {
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy2 =================================
    let daoCommitteeProxy2 = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOProxy2ABI,
        ethers.provider
    )

    let newLogicDAOv2Address = "0x4c20f793bD3F4106819c9a705670D30E18bdB983"

    //==== pauseCheck =================================
    let pauseProxy = await daoCommitteeProxy2.pauseProxy()

    if (pauseProxy == true) {
        await daoCommitteeProxy2.setProxyPause(false)
    }

    console.log("pauseProxy pass")

    //==== DAOCommitteeProxy2 upgradeTo2 DAOCommittee_V2 =================================
    await daoCommitteeProxy2.connect(deployer).upgradeTo2(
        newLogicDAOv2Address
    )
    console.log("upgradeTo newLogic done")
}

async function setMultiSigWallet() {
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommittee_V2 =================================
    let daoCommittee_V2 = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOProxy2ABI,
        ethers.provider
    )

    //==== DAOCommittee_V2 set MultiSigWalletContract =================================
    await daoCommitteeProxy2.connect(deployer).upgradeTo2(
        newLogicDAOv2Address
    )

}


const main = async () => {
  await ChangeUpgradeTo2()
  await setMultiSigWallet()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
