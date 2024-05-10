const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const SeigManager_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json')
const SeigManagerV1_3_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json')

async function setSeigManagerV1_3() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()

  console.log("deployer", deployerAddress)

  const DepositManagerAddress = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
  const SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
  const L2RegistryProxyAddress = "0x817442BB8aa891AaE2a1EA009086f61c7FB14372"
  const Layer2ManagerProxyAddress = "0x0237839A14194085B5145D1d1e1E77dc92aCAF06"

  const deployedTitanLayer = "0xeA2c15fdf4cE802Ba188e7D4460D979E9df5fD51"
  const deployedTitanOperator = "0x1A8e48401697DcF297A02c90d3480c35885f8959"

  const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
  const seigManagerV1_3 = new ethers.Contract(SeigManagerAddress,  SeigManagerV1_3_Json.abi, deployer)

  let tos = await seigManagerV1_3.totalSupplyOfTon()
  let seigStartBlock = await seigManager.seigStartBlock()

  console.log('tos', tos)
  console.log('seigStartBlock', seigStartBlock)

  // let initialTotal = ethers.BigNumber.from("1000000000101504124955859969558056752000000000")
  // await (await seigManager.connect(deployer).setInitialTotalSupply(
  //   initialTotal
  // )).wait()

  // await (await seigManager.connect(deployer).setLayer2Manager(
  //   Layer2ManagerProxyAddress
  // )).wait()

  // await (await seigManager.connect(deployer).setL2Registry(
  //   L2RegistryProxyAddress
  // )).wait()

  let initialTotalSupply = await seigManager.initialTotalSupply()
  console.log('initialTotalSupply', initialTotalSupply)
}

const main = async () => {
  await setSeigManagerV1_3()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
