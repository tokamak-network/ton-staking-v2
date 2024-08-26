const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const SeigManager_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json')
const SeigManagerV1_3_Json = require('../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json')
const DAO_Json = require('../artifacts/contracts/dao/DAOCommitteeAddV1_1.sol/DAOCommitteeAddV1_1.json')

async function setSeigManagerV1_3() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()

  console.log("deployer", deployerAddress)
  // sepolia
  const DepositManagerAddress = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
  const SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
  const DAOCommitteeProxyAddress = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

  // deployed address
  const l1BridgeRegistryAddress ="0xC8479A9F10a1E6275e0bFC4F9e058631fe63b8dC";
  const layer2ManagerAddress ="0xffb690feeFb2225394ad84594C4a270c04be0b55";
  // const layer2StartBlock
  // const l2RewardPerUint
  // const totalLayer2TVL

  const CandidateAddOnFactoryProxyAddress ="0x63c95fbA722613Cb4385687E609840Ed10262434";

  //-----------------
  const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
  const seigManagerV1_3 = new ethers.Contract(SeigManagerAddress,  SeigManagerV1_3_Json.abi, deployer)

  // const dao = new ethers.Contract(DAOCommitteeProxyAddress,  DAO_Json.abi, deployer)


  let tos = await seigManagerV1_3.totalSupplyOfTon()
  let seigStartBlock = await seigManagerV1_3.seigStartBlock()

  console.log('tos', tos)
  console.log('seigStartBlock', seigStartBlock)

  let initialTotalSupply = await seigManagerV1_3.initialTotalSupply()
  console.log('initialTotalSupply', initialTotalSupply)

  // set seigManager
  // await (await seigManagerV1_3.connect(deployer).setLayer2Manager(
  //   layer2ManagerAddress
  // )).wait()

  // await (await seigManagerV1_3.connect(deployer).setL1BridgeRegistry(
  //   l1BridgeRegistryAddress
  // )).wait()

  // set dao
  // await (await dao.connect(deployer).setCandidateAddOnFactory(
  //   CandidateAddOnFactoryProxyAddress
  // )).wait()

  // await (await dao.connect(deployer).setLayer2Manager(
  //   layer2ManagerAddress
  // )).wait()


  let l1BridgeRegistry = await seigManagerV1_3.l1BridgeRegistry()
  console.log('l1BridgeRegistry', l1BridgeRegistry)

  let layer2Manager = await seigManagerV1_3.layer2Manager()
  console.log('layer2Manager', layer2Manager)

  let layer2StartBlock = await seigManagerV1_3.layer2StartBlock()
  console.log('layer2StartBlock', layer2StartBlock)

  let l2RewardPerUint = await seigManagerV1_3.l2RewardPerUint()
  console.log('l2RewardPerUint', l2RewardPerUint)

  let totalLayer2TVL = await seigManagerV1_3.totalLayer2TVL()
  console.log('totalLayer2TVL', totalLayer2TVL)


  // let candidateAddOnFactory = await dao.candidateAddOnFactory()
  // console.log('candidateAddOnFactory', candidateAddOnFactory)

  // let dao_layer2Manager = await dao.layer2Manager()
  // console.log('dao_layer2Manager', dao_layer2Manager)


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
