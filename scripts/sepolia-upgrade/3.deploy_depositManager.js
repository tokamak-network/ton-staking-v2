const { ethers } = require("hardhat");

async function DepositManagerV1_1() {

  //==== DepositManagerV1_1 =================================
  const DepositManagerV1_1Dep = await ethers.getContractFactory("DepositManagerV1_1");
  const depositManagerV1_1 = await DepositManagerV1_1Dep.deploy();
  await depositManagerV1_1.deployed();
  console.log('DepositManagerV1_1' , depositManagerV1_1.address)
}

const main = async () => {
  await DepositManagerV1_1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
