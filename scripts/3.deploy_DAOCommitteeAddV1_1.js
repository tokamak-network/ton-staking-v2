const { ethers } = require("hardhat");

async function deployDAOCommitteeAddV1_1() {
    //==== DAOCommitteeAddV1_1 =================================
    const DAOCommitteeAddV1_1Dep = await ethers.getContractFactory("DAOCommitteeAddV1_1");
    const DAOCommitteeAddV1_1Logic = await DAOCommitteeAddV1_1Dep.deploy();
    await DAOCommitteeAddV1_1Logic.deployed()

    // console.log('tx' , tx)
    console.log('DAOCommitteeAddV1_1' , DAOCommitteeAddV1_1Logic.address)
}

const main = async () => {
  await deployDAOCommitteeAddV1_1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
