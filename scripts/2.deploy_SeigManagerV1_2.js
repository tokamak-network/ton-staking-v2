const { ethers } = require("hardhat");

async function deploySeigManagerV1_2() {
    //==== SeigManagerV1_2 =================================
    const SeigManagerV1_2Dep = await ethers.getContractFactory("SeigManagerV1_2");
    const SeigManagerV1_2Logic = await SeigManagerV1_2Dep.deploy();
    await SeigManagerV1_2Logic.deployed();
    console.log('SeigManagerV1_2Logic' , SeigManagerV1_2Logic.address)
}

const main = async () => {
  await deploySeigManagerV1_2()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
