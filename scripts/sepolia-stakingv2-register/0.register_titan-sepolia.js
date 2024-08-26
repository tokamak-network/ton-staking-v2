const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const SeigManager_Json = require('../../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json')
const SeigManagerV1_3_Json = require('../../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json')
const DAO_Json = require('../../artifacts/contracts/dao/DAOCommitteeAddV1_1.sol/DAOCommitteeAddV1_1.json')

const L1BridgeRegistryV1_1_Json = require('../../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../artifacts/contracts/layer2/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json')


// sepolia
const DepositManagerAddress = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
const SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
const DAOCommitteeProxyAddress = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

// deployed address
const l1BridgeRegistryAddress ="0xC8479A9F10a1E6275e0bFC4F9e058631fe63b8dC";
const layer2ManagerAddress ="0xffb690feeFb2225394ad84594C4a270c04be0b55";
const CandidateAddOnFactoryProxyAddress ="0x63c95fbA722613Cb4385687E609840Ed10262434";

const titan_info = {
  systemConfig : "0x1cA73f6E80674E571dc7a8128ba370b8470D4D87",
  type: 1,
  amount: ethers.BigNumber.from("1000100000000000000000"),
  flagTon: true,
  name: "Titan-sepolia",
  bridge: "0x1F032B938125f9bE411801fb127785430E7b3971",
  portal: "",
  l2TON: "0x7c6b91d9be155a6db01f749217d76ff02a7227f2"
}
const thanos_info = {
  systemConfig : "0xB8209Cc81f0A8Ccdb09238bB1313A039e6BFf741",
  type: 2,
  amount: ethers.BigNumber.from("1000100000000000000000"),
  flagTon: true,
  name: "Thanos-sepolia",
  bridge: "0x385076516318551d566CAaE5EC59c23fe09cbF65",
  portal: "0x7b6db1316e22167b56211cDDC33431098BaBC3c2",
  l2TON: "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000"
}

// async function resetRollupConfig() {

//   const accounts = await ethers.getSigners()
//   const deployer = accounts[0]
//   const deployerAddress = await deployer.getAddress()

//   console.log("deployer", deployerAddress)
//   const l1BridgeRegistry = new ethers.Contract(l1BridgeRegistryAddress,  L1BridgeRegistryV1_1_Json.abi, deployer)

//   const tx2 = await (await l1BridgeRegistry.connect(deployer).resetRollupConfig(
//     thanos_info.systemConfig
//   )).wait()

//   console.log("thanos_info resetRollupConfig ", tx2)

// }

async function registerRollupConfigByManager() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()

  console.log("deployer", deployerAddress)
  const l1BridgeRegistry = new ethers.Contract(l1BridgeRegistryAddress,  L1BridgeRegistryV1_1_Json.abi, deployer)

  // const tx1 = await (await l1BridgeRegistry.connect(deployer).registerRollupConfigByManager(
  //   titan_info.systemConfig,
  //   titan_info.type,
  //   titan_info.l2TON
  // )).wait()

  // console.log("titan_info registerRollupConfigByManager ", tx1.transactionHash)

  const tx2 = await (await l1BridgeRegistry.connect(deployer).registerRollupConfigByManager(
    thanos_info.systemConfig,
    thanos_info.type,
    thanos_info.l2TON
  )).wait()

  console.log("thanos_info registerRollupConfigByManager ", tx2.transactionHash)

}

async function viewSystemConfigOfL1BridgeRegistry() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()

  console.log("deployer", deployerAddress)
  const l1BridgeRegistry = new ethers.Contract(l1BridgeRegistryAddress,  L1BridgeRegistryV1_1_Json.abi, deployer)

  const titan_rollupType = await l1BridgeRegistry.rollupType(titan_info.systemConfig);
  const thanos_rollupType = await l1BridgeRegistry.rollupType(thanos_info.systemConfig);
  console.log("titan_rollupType", titan_rollupType)
  console.log("thanos_rollupType", thanos_rollupType)


  const titan_l2TON = await l1BridgeRegistry.l2TON(titan_info.systemConfig);
  const thanos_l2TON = await l1BridgeRegistry.l2TON(thanos_info.systemConfig);
  console.log("titan_l2TON", titan_l2TON)
  console.log("thanos_l2TON", thanos_l2TON)


  const titan_l1Bridge = await l1BridgeRegistry.l1Bridge(titan_info.bridge);
  console.log("titan_l1Bridge", titan_l1Bridge)

  const thanos_l1Bridge = await l1BridgeRegistry.l1Bridge(thanos_info.bridge);
  const thanos_portal = await l1BridgeRegistry.portal(thanos_info.portal);
  console.log("thanos_l1Bridge", thanos_l1Bridge)
  console.log("thanos_portal", thanos_portal)

}

async function registerCandidateAddOn() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()
  console.log("deployer", deployerAddress)
  const layer2Manager = new ethers.Contract(layer2ManagerAddress,  Layer2ManagerV1_1_Json.abi, deployer)


  const tx1 = await (await layer2Manager.connect(deployer).registerCandidateAddOn(
    titan_info.systemConfig,
    titan_info.amount,
    titan_info.flagTon,
    titan_info.name
  )).wait()

  console.log("titan_info registerCandidateAddOn ", titan_info)
  console.log(tx1.transactionHash)

  const tx2 = await (await layer2Manager.connect(deployer).registerCandidateAddOn(
    thanos_info.systemConfig,
    thanos_info.amount,
    thanos_info.flagTon,
    thanos_info.name
  )).wait()

  console.log("thanos_info registerCandidateAddOn ", thanos_info)
  console.log(tx2.transactionHash)

}

async function viewRollupConfigInfoLayer2Manager() {

  const accounts = await ethers.getSigners()
  const deployer = accounts[0]
  const deployerAddress = await deployer.getAddress()

  console.log("deployer", deployerAddress)
  const layer2Manager = new ethers.Contract(layer2ManagerAddress,  Layer2ManagerV1_1_Json.abi, deployer)

  const titan_rollupConfigInfo = await layer2Manager.rollupConfigInfo(titan_info.systemConfig);
  const thanos_rollupConfigInfo = await layer2Manager.rollupConfigInfo(thanos_info.systemConfig);
  console.log("titan_rollupConfigInfo", titan_rollupConfigInfo)
  console.log("thanos_rollupConfigInfo", thanos_rollupConfigInfo)


  const titan_CandidateAddOnInfo = await layer2Manager.operatorInfo(titan_rollupConfigInfo.operatorManager);
  const thanos_CandidateAddOnInfo = await layer2Manager.operatorInfo(thanos_rollupConfigInfo.operatorManager);
  console.log("titan_CandidateAddOnInfo", titan_CandidateAddOnInfo)
  console.log("thanos_CandidateAddOnInfo", thanos_CandidateAddOnInfo)

}

const main = async () => {
  // await resetRollupConfig()
  // await registerRollupConfigByManager()
  // await viewSystemConfigOfL1BridgeRegistry()

  // 0xa30fe40285b8f5c0457dbc3b7c8a280373c40044 TON approve layer2Manager
  // 2000200000000000000000
  // 0xffb690feeFb2225394ad84594C4a270c04be0b55
  await registerCandidateAddOn()

  await viewRollupConfigInfoLayer2Manager()

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
