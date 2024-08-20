const { ethers } = require("hardhat");

async function Layer2ManagerV1_1() {
    //==== Layer2ManagerV1_1 =================================
    const Layer2ManagerV1_1Dep = await ethers.getContractFactory("Layer2ManagerV1_1");
    const layer2ManagerV1_1Logic = await Layer2ManagerV1_1Dep.deploy();
    await layer2ManagerV1_1Logic.deployed();
    console.log('Layer2ManagerV1_1' , layer2ManagerV1_1Logic.address)
}

const main = async () => {
  await Layer2ManagerV1_1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
