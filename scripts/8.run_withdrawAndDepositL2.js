const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const SeigManager_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json')

async function withdrawAndDepositL2() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()

  console.log("deployer", deployerAddress)

  const DepositManagerAddress = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
  const SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"

  const deployedTitanLayer = "0xeA2c15fdf4cE802Ba188e7D4460D979E9df5fD51"
  const deployedTitanOperator = "0x1A8e48401697DcF297A02c90d3480c35885f8959"

  const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
  const depositManagerV1 = new ethers.Contract(DepositManagerAddress,  DepositManagerV1_1_Json.abi, deployer)

  let stakeOf = await seigManager["stakeOf(address,address)"](deployedTitanLayer, deployerAddress);
  console.log("stakeOf", stakeOf)

  const amount = ethers.utils.parseEther("10"+"0".repeat(9))
  const gasEstimated =  await depositManagerV1.connect(deployer).estimateGas.withdrawAndDepositL2(
      deployedTitanLayer,
      amount
  )
  console.log("gasEstimated", gasEstimated)

  const receipt = await (await depositManagerV1.connect(deployer).withdrawAndDepositL2(
      deployedTitanLayer,
      amount
  )).wait()
  // console.log("receipt", receipt)
  let stakeOf1 = await seigManager["stakeOf(address,address)"](deployedTitanLayer, deployerAddress);
  console.log("stakeOf1", stakeOf1)

}

const main = async () => {
  await withdrawAndDepositL2()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
