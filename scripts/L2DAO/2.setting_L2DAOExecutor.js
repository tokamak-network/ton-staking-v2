const hre = require("hardhat");
const { ethers } = hre;


const L1DAOExecutorABI = require("../../artifacts/contracts/dao/L1/L1DAOExecutor.sol/L1DAOExecutor.json").abi;
const L2DAOExecutorABI = require("../../artifacts/contracts/dao/L2/L2DAOExecutor.sol/L2DAOExecutor.json").abi;
const Web3EthAbi = require('web3-eth-abi');

const sepoliaContractInfo = {
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    L1DAOExecutor: "0x109c37fdB56850A6dfd0e29290860B423c25f7e6",
    L2DAOExecutor: "0x988A796F5ca1d4848d00daC1c17d0A2Bbca18a9b"
}

const mainnetContractInfo = {
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
    L1DAOExecutor: "",
    L2DAOExecutor: ""
}

function sleep(ms) {
    const wakeUpTime = Date.now() + ms;
    while (Date.now() < wakeUpTime) {}
}

async function Setting_L2DAOExecutor() {
    const [deployer] = await ethers.getSigners();

    const l2CrossDomainMessenger = "0x4200000000000000000000000000000000000007"
    const l1DAOExecutor = "0x109c37fdB56850A6dfd0e29290860B423c25f7e6"
    const l1DAOProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

    //==== Set L2DAOExecutor =================================
    let l2DAOExecutor = new ethers.Contract(
        sepoliaContractInfo.L2DAOExecutor,
        L2DAOExecutorABI,
        ethers.provider
    )

    //==== initialize L2DAOExecutor =================================
    await l2DAOExecutor.connect(deployer).initialize(
        l2CrossDomainMessenger,
        l1DAOProxy
    )

    sleep(12000);

    //==== Check crossMessengerAddr =================================
    let crossMessengerAddr = await l2DAOExecutor.l2crossDomainMessenger()
    console.log("crossMessengerAddr : ", crossMessengerAddr)

    //==== Check l1daoexecutorAddr =================================
    let l1daoexecutorAddr = await l2DAOExecutor.l1DAOContract()
    console.log("l1DAOProxy : ", l1daoexecutorAddr)
}

const main = async () => {
  await Setting_L2DAOExecutor()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});