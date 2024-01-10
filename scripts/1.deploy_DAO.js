const { ethers } = require("hardhat");

async function DeployDAOCommitteeDAOVault() {

    //==== DAOCommitteeDAOVault =================================
    const DAOCommitteeDAOVaultDep = await ethers.getContractFactory("DAOCommitteeDAOVault");
    const daoCommitteeDAOVaultLogic = await DAOCommitteeDAOVaultDep.deploy();
    await daoCommitteeDAOVaultLogic.deployed();
    console.log('daoCommitteeDAOVaultLogic' , daoCommitteeDAOVaultLogic.address)
}

async function DeployDAOCommitteeOwner() {
    //==== DAOCommitteeOwner =================================
    const DAOCommitteeOwnerDep = await ethers.getContractFactory("DAOCommitteeOwner");
    const daoCommitteeOwnerLogic = await DAOCommitteeOwnerDep.deploy();
    await daoCommitteeOwnerLogic.deployed();
    console.log('daoCommitteeOwnerLogic' , daoCommitteeOwnerLogic.address)
}

async function DeployDAOCommittee_V1() {
    //==== DAOCommitteeOwner =================================
    const DAOCommittee_V1Dep = await ethers.getContractFactory("DAOCommittee_V1");
    const DAOCommittee_V1 = await DAOCommittee_V1Dep.deploy();
    await DAOCommittee_V1.deployed();
    console.log('DAOCommittee_V1' , DAOCommittee_V1.address)
}

const main = async () => {
  // await DeployDAOCommitteeDAOVault()
  await DeployDAOCommitteeOwner()
  await DeployDAOCommittee_V1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
