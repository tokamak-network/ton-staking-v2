const hre = require("hardhat");
const { ethers } = hre;


const L1DAOExecutorABI = require("../../artifacts/contracts/dao/L1/L1DAOExecutor.sol/L1DAOExecutor.json").abi;
const L2DAOExecutorABI = require("../../artifacts/contracts/dao/L2/L2DAOExecutor.sol/L2DAOExecutor.json").abi;
const Web3EthAbi = require('web3-eth-abi');

const sepoliaContractInfo = {
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    L1DAOExecutor: "0x109c37fdB56850A6dfd0e29290860B423c25f7e6",
    L2DAOExecutor: "0xDe6b80f4700C2148Ba2aF81640a23E153C007C7F"     //Thanos
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

async function Setting_L1DAOExecutor() {
    const [deployer] = await ethers.getSigners();

    const l1CrossDomainMessenger = "0xd054Bc768aAC07Dd0BaA2856a2fFb68F495E4CC2"
    const l1DAOContract = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    const l2DAOExecutor = "0xDe6b80f4700C2148Ba2aF81640a23E153C007C7F" 

    //==== Set L1DAOExecutor =================================
    let l1DAOExecutor = new ethers.Contract(
        sepoliaContractInfo.L1DAOExecutor,
        L1DAOExecutorABI,
        ethers.provider
    )

    //==== initialize L1DAOExecutor =================================
    await l1DAOExecutor.connect(deployer).initialize(
        l1CrossDomainMessenger,
        l1DAOContract,
        l2DAOExecutor
    )

    sleep(12000);

    //==== Check crossMessengerAddr =================================
    let crossMessengerAddr = await l1DAOExecutor.l1crossDomainMessenger()
    console.log("crossMessengerAddr : ", crossMessengerAddr)

    //==== Check l1daoexecutorAddr =================================
    let l1daoexecutorAddr = await l1DAOExecutor.l1DAOContract()
    console.log("l1DaoExecutorAddr : ", l1daoexecutorAddr)

    //==== Check l2DAOExecutor =================================
    let l2DAOExecutorAddr = await l1DAOExecutor.l2DAOContract()
    console.log("l2DAOExecutorAddr : ", l2DAOExecutorAddr)
}

const main = async () => {
  await Setting_L1DAOExecutor()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
