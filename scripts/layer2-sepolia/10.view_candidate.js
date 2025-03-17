const { ethers } = require("hardhat");
const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')
const DAOAgendaManager_Json = require('../../test/abi/DAOAgendaManager.json')
const Ton_Json = require('../../abi/TON.json')
const DAOCommittee_V1_Json = require('../../test/abi/DAOCommittee_V1.json')
const L1BridgeRegistryV1_1_Json = require('../../test/abi/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../test/abi/Layer2ManagerV1_1.json')
const DAOCommitteeAddV1_1_Json = require('../../test/abi/DAOCommitteeAddV1_1.json')
const SeigManagerV1_Json = require('../../test/abi/SeigManagerV1.json')

const tester = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

const  L1BridgeRegistryProxy = "0x35822B4be688B06E58479Ed289E928cB25Cb3c68"

const  SeigManagerProxy = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"

const  Layer2ManagerProxy = "0x53faC2e379cBfFd4C32D2b6FBBA83De102DDA2E5"

let TON = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"
let DAOAgendaManager = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08"
let DAOCommitteeProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

let thanos_sepolia = {
    rollupConfig : "0x6eF61974A3CDa7BbD0a4DD0A613f56d211c8AfDC",
    type : 2,
    l2TON : "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000",
     name : "Thanos Sepolia",
    candidateAddOn: "0xDBD15bD93FEb9689071f9c4e4eDee8dc1C06dE42"
}

async function views() {

    console.log('\n==== views ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    const l1BridgeRegistryV1_1 = new ethers.Contract(L1BridgeRegistryProxy,  L1BridgeRegistryV1_1_Json.abi, deployer)

    console.log("l1BridgeRegistryV1_1.availableForRegistration ",thanos_sepolia.rollupConfig, " ",
        await l1BridgeRegistryV1_1.availableForRegistration(
            thanos_sepolia.rollupConfig,
            thanos_sepolia.type
        ))

}


async function view_dao_info() {

    console.log('\n==== view_dao_info ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    const committee = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeAddV1_1_Json.abi, deployer)
    const layer2Manager = await committee.layer2Manager()
    const candidateAddOnFactory = await committee.candidateAddOnFactory()

    console.log("layer2Manager ", layer2Manager)
    console.log("candidateAddOnFactory ", candidateAddOnFactory)

}


async function checkL1BridgeDetail() {

    console.log('\n==== checkL1BridgeDetail  ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    const committee = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeAddV1_1_Json.abi, deployer)
    const layer2Manager = await committee.layer2Manager()

    const layer2ManagerContract = new ethers.Contract(layer2Manager,  Layer2ManagerV1_1_Json.abi, deployer)

    const checkL1BridgeDetail = await layer2ManagerContract.checkL1BridgeDetail(thanos_sepolia.rollupConfig)

    console.log("layer2Manager ", layer2Manager)
    console.log("checkL1BridgeDetail ", checkL1BridgeDetail)

}

async function estimatedDistribute() {

    console.log('\n==== estimatedDistribute  ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]

    let block= await ethers.provider.getBlock('latest');

    const seigManager = new ethers.Contract(SeigManagerProxy,  SeigManagerV1_Json.abi, deployer)

    const estimatedDistribute = await seigManager.estimatedDistribute(
        block.number+1 ,
        thanos_sepolia.candidateAddOn,
        false)

    console.log("estimatedDistribute ", estimatedDistribute)

}

const main = async () => {


    await checkL1BridgeDetail()
    await estimatedDistribute()

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});