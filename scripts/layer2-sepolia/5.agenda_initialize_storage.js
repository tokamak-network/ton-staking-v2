const { ethers } = require("hardhat");
const DepositManagerProxy_Json = require('../../artifacts/contracts/stake/managers/DepositManagerProxy.sol/DepositManagerProxy.json')
const DepositManager_Json = require('../../artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json')
const DepositManagerV1_1_Json = require('../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json')


const SeigManagerProxy_Json = require('../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json')



const L1BridgeRegistryV1_1_Json = require('../../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../artifacts/contracts/layer2/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json')
const SeigManager_Json = require('../../test/abi/SeigManagerV1.json')
const DAOAgendaManager_Json = require('../../abi/DAOAgendaManager.json')
const Ton_Json = require('../../abi/TON.json')

const DAOCommittee_V1_Json = require('../../test/abi/DAOCommittee_V1.json')

const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')

const tester = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
const seigniorageCommittee_ = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let seigniorageCommittee

let TON = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"
let DAOAgendaManager = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08"
let DAOCommitteeProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

let L1BridgeRegistryProxyOldAddress = "0x35822B4be688B06E58479Ed289E928cB25Cb3c68"
let Layer2ManagerOldAddress = "0x53faC2e379cBfFd4C32D2b6FBBA83De102DDA2E5"

let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
let DepositManagerAddress = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"

let seigniorageCommitteeAddress = seigniorageCommittee_
let tonHaveAddr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let ThanosSepolia = "0x6eF61974A3CDa7BbD0a4DD0A613f56d211c8AfDC"

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
    let info = await Layer2ManagerOld.rollupConfigInfo(ThanosSepolia)
    if (info.status == 1) {
        targets.push(L1BridgeRegistryProxyOldAddress)
        callDtata = l1BridgeRegistryOld.interface.encodeFunctionData(
            "rejectCandidateAddOn", [
                ThanosSepolia
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

async function executeAgenda(agendaId_) {

    let agendaId = ethers.BigNumber.from(""+agendaId_)
    console.log('\n==== executeAgenda ===== ', agendaId)
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]

    const block = await ethers.provider.getBlock('latest');
    console.log('block.timestamp', block.timestamp)

    const daoAgendaManagerContract = new ethers.Contract(DAOAgendaManager,  DAOAgendaManager_Json.abi, deployer)
    const daoCommitteeContract = new ethers.Contract(DAOCommitteeProxy, DAOCommittee_V1_Json.abi,  deployer)

    let agenda = await daoAgendaManagerContract.agendas(agendaId);

    // expect(agenda.executedTimestamp).to.be.equal(0);
    // expect(agenda.executed).to.be.equal(false);
    console.log('Agenda Before executeing ', agenda)

    let receipt = await (await daoCommitteeContract.connect(deployer).executeAgenda(agendaId)).wait();

    console.log('receipt', receipt)

    agenda = await daoAgendaManagerContract.agendas(agendaId);
    // // expect(agenda.executedTimestamp).to.be.gt(0);
    // // expect(agenda.executed).to.be.equal(true);

    console.log('Aagenda Aefore executeing ', agenda)


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

async function viewAfterPassingAgenda() {

    console.log('\n==== viewAfterPassingAgenda ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()
    let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"

    console.log('deployer ', deployerAddress)
    console.log("\n====== seigManager Storage ================" )
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
    const seigManagerProxy = new ethers.Contract(SeigManagerAddress,  SeigManagerProxy_Json.abi, deployer)

    const selector1 = encodeFunctionSignature("updateSeigniorage()");
    const selector2 = encodeFunctionSignature("updateSeigniorageLayer(address)");
    const selector3 = encodeFunctionSignature("estimatedDistribute(uint256,address)");
    const selector4 = encodeFunctionSignature("excludeFromL2Seigniorage(address)");
    const selector5 = encodeFunctionSignature("includeFromL2Seigniorage(address)");
    const selector6 = encodeFunctionSignature("claimableL2Seigniorage(address)");
    const selector7 = encodeFunctionSignature("pause()");
    const selector8 = encodeFunctionSignature("unpause()");

    const selector_totalSupplyOfTon = encodeFunctionSignature("totalSupplyOfTon()");

    console.log("implementation", await seigManagerProxy.implementation())
    console.log("getSelectorImplementation2 (selector_totalSupplyOfTon) ", await seigManagerProxy.getSelectorImplementation2(selector_totalSupplyOfTon))

    console.log("getSelectorImplementation2 (selector1) ", await seigManagerProxy.getSelectorImplementation2(selector1))
    console.log("getSelectorImplementation2 (selector2) ", await seigManagerProxy.getSelectorImplementation2(selector2))
    console.log("getSelectorImplementation2 (selector3) ", await seigManagerProxy.getSelectorImplementation2(selector3))
    console.log("getSelectorImplementation2 (selector4) ", await seigManagerProxy.getSelectorImplementation2(selector4))
    console.log("getSelectorImplementation2 (selector5) ", await seigManagerProxy.getSelectorImplementation2(selector5))
    console.log("getSelectorImplementation2 (selector6) ", await seigManagerProxy.getSelectorImplementation2(selector6))
    console.log("getSelectorImplementation2 (selector7) ", await seigManagerProxy.getSelectorImplementation2(selector7))
    console.log("getSelectorImplementation2 (selector8) ", await seigManagerProxy.getSelectorImplementation2(selector8))

    console.log("\nlayer2Manager", await seigManager.layer2Manager())
    console.log("l1BridgeRegistry", await seigManager.l1BridgeRegistry())
    console.log("layer2StartBlock", await seigManager.layer2StartBlock())
    console.log("l2RewardPerUint", await seigManager.l2RewardPerUint())
    console.log("totalLayer2TVL", await seigManager.totalLayer2TVL())

    console.log("\n====== DepositManager Storage ================" )
    const depositManagerProxy = new ethers.Contract(DepositManagerAddress,  DepositManagerProxy_Json.abi, deployer)
    const depositManager = new ethers.Contract(DepositManagerAddress,  DepositManager_Json.abi, deployer)
    const depositManagerV1 = new ethers.Contract(DepositManagerAddress,  DepositManagerV1_1_Json.abi, deployer)

    const selector_setWithdrawalDelay = encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
    const selector_deposit = encodeFunctionSignature("deposit(address,uint256)");

    const selector_1 = encodeFunctionSignature("ton()");
    const selector_2 = encodeFunctionSignature("minDepositGasLimit()");
    const selector_3 = encodeFunctionSignature("setMinDepositGasLimit(uint32)");
    const selector_4 = encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");
    const selector_5 = encodeFunctionSignature("l1BridgeRegistry()");
    const selector_6 = encodeFunctionSignature("layer2Manager()");
    const selector_7 = encodeFunctionSignature("setAddresses(address,address)");
    const selector_8 = encodeFunctionSignature("requestWithdrawal(address,uint256)");

    console.log("getSelectorImplementation2 (selector_setWithdrawalDelay) ", await depositManagerProxy.getSelectorImplementation2(selector_setWithdrawalDelay))
    console.log("getSelectorImplementation2 (selector_deposit) ", await depositManagerProxy.getSelectorImplementation2(selector_deposit))

    console.log("getSelectorImplementation2 (selector_1) ", await depositManagerProxy.getSelectorImplementation2(selector_1))
    console.log("getSelectorImplementation2 (selector_2) ", await depositManagerProxy.getSelectorImplementation2(selector_2))
    console.log("getSelectorImplementation2 (selector_3) ", await depositManagerProxy.getSelectorImplementation2(selector_3))
    console.log("getSelectorImplementation2 (selector_4) ", await depositManagerProxy.getSelectorImplementation2(selector_4))
    console.log("getSelectorImplementation2 (selector_5) ", await depositManagerProxy.getSelectorImplementation2(selector_5))
    console.log("getSelectorImplementation2 (selector_6) ", await depositManagerProxy.getSelectorImplementation2(selector_6))
    console.log("getSelectorImplementation2 (selector_7) ", await depositManagerProxy.getSelectorImplementation2(selector_7))
    console.log("getSelectorImplementation2 (selector_8) ", await depositManagerProxy.getSelectorImplementation2(selector_8))

    console.log("\nlayer2Manager", await depositManagerV1.layer2Manager())
    console.log("l1BridgeRegistry", await depositManagerV1.l1BridgeRegistry())
}

async function resetDepositManager() {
    console.log('\n==== resetDepositManager ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()

    const depositManagerV1 = new ethers.Contract(DepositManagerAddress,  DepositManagerV1_1_Json.abi, deployer)

    const receipt = await (await depositManagerV1.setAddresses(
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
    )).wait()

    console.log(receipt)
}


const main = async () => {
    // await proposeAgenda_rejectCandidateAddOn()

    // await executeAgenda("36")

    // await view()

    await viewAfterPassingAgenda()

    // await resetDepositManager()

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});