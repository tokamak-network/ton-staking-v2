const { ethers } = require("hardhat");
const SeigManagerV1_3reset_Json = require('../../artifacts/contracts/stake/managers/SeigManagerV1_3reset.sol/SeigManagerV1_3reset.json')
const SeigManagerProxy_Json = require('../../test/abi/SeigManagerProxy.json')

async function deploySeigManagerV1_3reset() {
    //==== SeigManagerV1_3 =================================
    const SeigManagerV1_3Dep = await ethers.getContractFactory("SeigManagerV1_3reset");
    const SeigManagerV1_3Logic = await SeigManagerV1_3Dep.deploy();
    await SeigManagerV1_3Logic.deployed()

    // console.log('tx' , tx)
    console.log('SeigManagerV1_3reset' , SeigManagerV1_3Logic.address)
}

async function reset() {
  const deployer = await ethers.getSigner()

  console.log('deployer', deployer.address)

  const SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"

  const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManagerV1_3reset_Json.abi, deployer)

  const tx = await seigManager.reset();

  console.log(tx)
}


const main = async () => {
  // await deploySeigManagerV1_3reset()
  await reset()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
