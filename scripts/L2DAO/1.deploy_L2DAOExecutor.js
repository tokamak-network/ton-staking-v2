const { ethers } = require("hardhat");

async function DeployL1DAOExecutor() {
    //==== DAOCommitteeOwner =================================
    const L1DAOExecutorDep = await ethers.getContractFactory("L1DAOExecutor");
    const L1DAOExecutor = await L1DAOExecutorDep.deploy();
    await L1DAOExecutor.deployed();
    console.log('L1DAOExecutor' , L1DAOExecutor.address)
}


async function DeployL2DAOExecutor() {
    //==== DAOCommitteeOwner =================================
    const L2DAOExecutorDep = await ethers.getContractFactory("L2DAOExecutor");
    const L2DAOExecutor = await L2DAOExecutorDep.deploy();
    await L2DAOExecutor.deployed();
    console.log('L2DAOExecutor' , L2DAOExecutor.address)
}

const main = async () => {
  await DeployL1DAOExecutor()
  await DeployL2DAOExecutor()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
