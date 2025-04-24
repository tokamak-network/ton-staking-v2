const { ethers } = require("hardhat");
const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')
const DAOAgendaManager_Json = require('../../test/abi/DAOAgendaManager.json')
const Ton_Json = require('../../abi/TON.json')
const DAOCommittee_V1_Json = require('../../test/abi/DAOCommittee_V1.json')
const L1BridgeRegistryV1_1_Json = require('../../test/abi/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../test/abi/Layer2ManagerV1_1.json')
const DAOCommitteeAddV1_1_Json = require('../../test/abi/DAOCommitteeAddV1_1.json')
const SeigManager_Json = require('../../test/abi/SeigManagerV1.json')
const tester = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

const  L1BridgeRegistryProxy = "0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4"

const  Layer2ManagerProxy = "0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D"

let TON = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"
let DAOAgendaManager = "0xcD4421d082752f363E1687544a09d5112cD4f484"
let DAOCommitteeProxy = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"

// async function views() {

//     console.log('\n==== views ===== ')
//     const accounts = await ethers.getSigners()
//     let deployer = accounts[0]
//     const l1BridgeRegistryV1_1 = new ethers.Contract(L1BridgeRegistryProxy,  L1BridgeRegistryV1_1_Json.abi, deployer)

//     console.log("l1BridgeRegistryV1_1.availableForRegistration ",thanos_sepolia.rollupConfig, " ",
//         await l1BridgeRegistryV1_1.availableForRegistration(
//             thanos_sepolia.rollupConfig,
//             thanos_sepolia.type
//         ))

// }

async function view_seigManager_info() {

    console.log('\n==== view ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()
    let SeigManagerAddress = "0x0b55a0f463b6defb81c6063973763951712d0e5f"

    console.log('deployer ', deployerAddress)

    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
    console.log("layer2Manager", await seigManager.layer2Manager())
    console.log("l1BridgeRegistry", await seigManager.l1BridgeRegistry())
    console.log("layer2StartBlock", await seigManager.layer2StartBlock())
    console.log("l2RewardPerUint", await seigManager.l2RewardPerUint())
    console.log("totalLayer2TVL", await seigManager.totalLayer2TVL())

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



const main = async () => {

    await view_seigManager_info()
    await view_dao_info()

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});