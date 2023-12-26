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

const main = async () => {
  await DeployDAOCommitteeDAOVault()
  await DeployDAOCommitteeOwner()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
