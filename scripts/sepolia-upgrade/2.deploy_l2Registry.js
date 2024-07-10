const { ethers } = require("hardhat");

async function L2RegistryV1_1() {

  //==== L2RegistryV1_1 =================================
  const L2RegistryV1_1Dep = await ethers.getContractFactory("L2RegistryV1_1");
  const l2RegistryV1_1 = await L2RegistryV1_1Dep.deploy();
  await l2RegistryV1_1.deployed();
  console.log('L2RegistryV1_1' , l2RegistryV1_1.address)
}

const main = async () => {
  await L2RegistryV1_1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
