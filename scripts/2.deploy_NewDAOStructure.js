const { ethers } = require("hardhat");

async function Deploy_changeDAOStructure() {
    //==== Deploy DAOCommitteeProxy2 =================================
    const DAOCommitteeProxy2 = await ethers.getContractFactory("DAOCommitteeProxy2");
    const DAOCommitteeProxy2Contract = await DAOCommitteeProxy2.deploy();
    await DAOCommitteeProxy2Contract.deployed();
    console.log('DAOCommitteeProxy2 : ' , DAOCommitteeProxy2Contract.address)

    //==== Deploy DAOCommittee_V1 =================================
    const DAOCommittee_V1Dep = await ethers.getContractFactory("DAOCommittee_V1");
    const DAOCommittee_V1 = await DAOCommittee_V1Dep.deploy();
    await DAOCommittee_V1.deployed();
    console.log('DAOCommittee_V1 : ' , DAOCommittee_V1.address)

    //==== Deploy DAOCommitteeOwner =================================
    const DAOCommittee_OwnerDep = await ethers.getContractFactory("DAOCommitteeOwner");
    const DAOCommittee_Owner = await DAOCommittee_OwnerDep.deploy();
    await DAOCommittee_Owner.deployed();
    console.log('DAOCommittee_Owner : ' , DAOCommittee_Owner.address)
}

const main = async () => {
  await Deploy_changeDAOStructure()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
