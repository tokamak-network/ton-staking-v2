const { ethers } = require("hardhat");

async function L1BridgeRegistryV1_1() {

  //==== L1BridgeRegistryV1_1 =================================
  const L1BridgeRegistryV1_1Dep = await ethers.getContractFactory("L1BridgeRegistryV1_1");
  const l1BridgeRegistryV1_1 = await L1BridgeRegistryV1_1Dep.deploy();
  await l1BridgeRegistryV1_1.deployed();
  console.log('L1BridgeRegistryV1_1' , l1BridgeRegistryV1_1.address)
}

const main = async () => {
  await L1BridgeRegistryV1_1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
