const { ethers } = require("hardhat");

async function OperatorV1_1() {

    //==== OperatorV1_1 =================================
    const OperatorV1_1Dep = await ethers.getContractFactory("OperatorV1_1");
    const operatorV1_1 = await OperatorV1_1Dep.deploy();
    await operatorV1_1.deployed();
    console.log('operatorV1_1' , operatorV1_1.address)
}

const main = async () => {
  await OperatorV1_1()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
