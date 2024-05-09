const { ethers } = require("hardhat");

async function deploySeigManagerV1_3() {
    //==== SeigManagerV1_3 =================================
    const SeigManagerV1_3Dep = await ethers.getContractFactory("SeigManagerV1_3");
    const SeigManagerV1_3Logic = await SeigManagerV1_3Dep.deploy();
    await SeigManagerV1_3Logic.deployed()

    // console.log('tx' , tx)
    console.log('SeigManagerV1_3Logic' , SeigManagerV1_3Logic.address)
}

const main = async () => {
  await deploySeigManagerV1_3()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
