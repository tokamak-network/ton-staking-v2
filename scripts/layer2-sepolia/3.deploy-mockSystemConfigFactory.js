const { ethers } = require("hardhat");

async function deployMockSystemConfigFactory() {
    //==== MockSystemConfigFactory =================================
    const MockSystemConfigFactoryDep = await ethers.getContractFactory("MockSystemConfigFactory");
    const MockSystemConfigFactory = await MockSystemConfigFactoryDep.deploy();
    await MockSystemConfigFactory.deployed()

    // console.log('tx' , tx)
    console.log('MockSystemConfigFactory' , MockSystemConfigFactory.address)
}

const main = async () => {
  await deployMockSystemConfigFactory()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
