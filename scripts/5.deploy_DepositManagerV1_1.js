const { ethers } = require("hardhat");

async function deployDepositManagerV1_1() {
    //==== DepositManagerV1_1 =================================
    const DepositManagerV1_1Dep = await ethers.getContractFactory("DepositManagerV1_1");
    const DepositManagerV1_1Logic = await DepositManagerV1_1Dep.deploy();
    await DepositManagerV1_1Logic.deployed()

    // console.log('tx' , tx)
    console.log('DepositManagerV1_1' , DepositManagerV1_1Logic.address)
}

const main = async () => {
  await deployDepositManagerV1_1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
