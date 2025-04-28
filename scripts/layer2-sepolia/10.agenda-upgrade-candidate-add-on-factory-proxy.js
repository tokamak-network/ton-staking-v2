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
const CandidateAddOnFactoryProxy_Json = require('../../test/abi/CandidateAddOnFactoryProxy.json')


const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')

const tester = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
const seigniorageCommittee_ = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
let seigniorageCommittee

let TON = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"
let DAOAgendaManager = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08"
let DAOCommitteeProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

let L1BridgeRegistryProxy = "0x2D47fa57101203855b336e9E61BC9da0A6dd0Dbc"
let Layer2ManagerProxy = "0x58B4C2FEf19f5CDdd944AadD8DC99cCC71bfeFDc"

let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
let DepositManagerAddress = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
let CandidateAddOnFactoryProxy = "0xf37493caC8BF8df0bD96146211D93D548d506fb9"
let CandidateAddOnFactoryImplementation = "0x88F7Fe8eD56300Ec8a3D53d7b806B0223f8e276A"

let seigniorageCommitteeAddress = seigniorageCommittee_
let tonHaveAddr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let ThanosSepoliaV2_CandidateAddOn = "0x0990385f7bB5b97e2250635C0391f0FfB1fd781b"
let ThanosSepoliaV2_RollupConfig = "0x6eF61974A3CDa7BbD0a4DD0A613f56d211c8AfDC"

let agendaId = 0

async function proposeAgenda_upgrade_candidateAddOnFactoryProxy() {

    console.log('\n==== proposeAgenda_upgrade_candidateAddOnFactoryProxy ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()

    console.log('proposer ', deployerAddress)

    const l1BridgeRegistry = new ethers.Contract(L1BridgeRegistryProxy,  L1BridgeRegistryV1_1_Json.abi, deployer)
    const Layer2Manager = new ethers.Contract(Layer2ManagerProxy,  Layer2ManagerV1_1_Json.abi, deployer)
    const daoAgendaManagerContract = new ethers.Contract(DAOAgendaManager,  DAOAgendaManager_Json.abi, deployer)
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
    const tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)
    const candidateAddOnFactoryProxy = new ethers.Contract(CandidateAddOnFactoryProxy,  CandidateAddOnFactoryProxy_Json.abi, deployer)

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

    targets.push(CandidateAddOnFactoryProxy)
    callDtata = candidateAddOnFactoryProxy.interface.encodeFunctionData(
        "upgradeTo", [
            CandidateAddOnFactoryImplementation
        ])
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

    console.log('deployer ', deployerAddress)
    console.log("\n======= CandidateAddOnFactoryProxy ============")
    const candidateAddOnFactoryProxy = new ethers.Contract(CandidateAddOnFactoryProxy,  CandidateAddOnFactoryProxy_Json.abi, deployer)
    console.log("implementation", await candidateAddOnFactoryProxy.implementation())

}

const main = async () => {
    // await proposeAgenda_upgrade_candidateAddOnFactoryProxy()

    // await executeAgenda("48")

    await view()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});