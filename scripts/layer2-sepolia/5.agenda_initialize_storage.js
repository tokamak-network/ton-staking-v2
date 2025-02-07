const { ethers } = require("hardhat");
const DepositManagerV1_1_Json = require('../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')
const L1BridgeRegistryV1_1_Json = require('../../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../artifacts/contracts/layer2/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json')
const SeigManager_Json = require('../../test/abi/SeigManagerV1.json')
const DAOAgendaManager_Json = require('../../abi/DAOAgendaManager.json')
const Ton_Json = require('../../abi/TON.json')

const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')

const tester = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
const seigniorageCommittee_ = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let seigniorageCommittee

let TON = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"
let DAOAgendaManager = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08"
let DAOCommitteeProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
let L1BridgeRegistryProxyOldAddress = "0x3268e4D8276c58A806E83B3B080Cf29514A837cf"
let Layer2ManagerOldAddress = "0xab303E7CBFd19C998268e19d830770e215AbDF7F"
let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
let seigniorageCommitteeAddress = seigniorageCommittee_
let TitanSepolia = "0x501C74df1aDEb8024738D880B01306a92d6e722d"
let tonHaveAddr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"

let agendaId = 0

async function proposeAgenda_rejectCandidateAddOn() {

    console.log('\n==== proposeAgenda_rejectCandidateAddOn ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()

    console.log('proposer ', deployerAddress)

    const l1BridgeRegistryOld = new ethers.Contract(L1BridgeRegistryProxyOldAddress,  L1BridgeRegistryV1_1_Json.abi, deployer)
    const Layer2ManagerOld = new ethers.Contract(Layer2ManagerOldAddress,  Layer2ManagerV1_1_Json.abi, deployer)
    const daoAgendaManagerContract = new ethers.Contract(DAOAgendaManager,  DAOAgendaManager_Json.abi, deployer)
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
    const tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     tonHaveAddr,
    // ]);

    // tonHave = await hre.ethers.getSigner(tonHaveAddr);
    // await (await tonContract.connect(tonHave).transfer(deployerAddress, ethers.utils.parseEther("10000"))).wait()


    ///--- Agenda ---------------------------------
    let targets = []
    let params = []
    let callDtata

    //----
    targets.push(L1BridgeRegistryProxyOldAddress)
    callDtata = l1BridgeRegistryOld.interface.encodeFunctionData(
        "setSeigniorageCommittee", [
            DAOCommitteeProxy
         ])
    params.push(callDtata)

    //----
    let info = await Layer2ManagerOld.rollupConfigInfo(TitanSepolia)
    if (info.status == 1) {
        targets.push(L1BridgeRegistryProxyOldAddress)
        callDtata = l1BridgeRegistryOld.interface.encodeFunctionData(
            "rejectCandidateAddOn", [
                TitanSepolia
            ])
        params.push(callDtata)
    }

    //----
    targets.push(SeigManagerAddress)
    callDtata = seigManager.interface.encodeFunctionData(
        "setL1BridgeRegistry", [
            ethers.constants.AddressZero
         ])
    params.push(callDtata)

    //----
    targets.push(SeigManagerAddress)
    callDtata = seigManager.interface.encodeFunctionData(
        "setLayer2Manager", [
            ethers.constants.AddressZero
         ])
    params.push(callDtata)

    //----
    targets.push(SeigManagerAddress)
    callDtata = seigManager.interface.encodeFunctionData(
        "setLayer2StartBlock", [
            ethers.constants.Zero
        ])
    params.push(callDtata)

    //----
    targets.push(SeigManagerAddress)
    callDtata = seigManager.interface.encodeFunctionData(
        "resetL2RewardPerUint", [])
    params.push(callDtata)

    // =========================================
    // . make an agenda
    const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
    const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();
    const agendaFee = await daoAgendaManagerContract.createAgendaFees();

    const param = encodeParameters(
        ["address[]", "uint128", "uint128", "bool", "bytes[]"],
        [
            targets,
            noticePeriod.toString(),
            votingPeriod.toString(),
            true,
            params
        ]
    )

    // =========================================
    // Propose an agenda
    let receipt = await (await tonContract.connect(deployer).approveAndCall(
        DAOCommitteeProxy,
        agendaFee,
        param
    )).wait()

    console.log('receipt ', receipt)
    agendaId = (await daoAgendaManagerContract.numAgendas()).sub(1);
    console.log('agendaId',agendaId)

    const executionInfo = await daoAgendaManagerContract.getExecutionInfo(agendaId);
    console.log("executionInfo :", executionInfo);
    // expect(executionInfo[0][0]).to.be.equal(DAOCommitteeProxy);
    // expect(executionInfo[1][0]).to.be.equal(param);
}

async function view() {

    console.log('\n==== view ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()
    let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"

    console.log('deployer ', deployerAddress)

    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
    console.log("layer2Manager", await seigManager.layer2Manager())
    console.log("l1BridgeRegistry", await seigManager.l1BridgeRegistry())
    console.log("layer2StartBlock", await seigManager.layer2StartBlock())
    console.log("l2RewardPerUint", await seigManager.l2RewardPerUint())
    console.log("totalLayer2TVL", await seigManager.totalLayer2TVL())

}

const main = async () => {
    // await proposeAgenda_rejectCandidateAddOn()

    await view()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});