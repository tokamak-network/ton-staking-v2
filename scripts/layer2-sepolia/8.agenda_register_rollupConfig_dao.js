const { ethers } = require("hardhat");
const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')
const DAOAgendaManager_Json = require('../../test/abi/DAOAgendaManager.json')
const Ton_Json = require('../../abi/TON.json')
const DAOCommittee_V1_Json = require('../../test/abi/DAOCommittee_V1.json')
const L1BridgeRegistryV1_1_Json = require('../../test/abi/L1BridgeRegistryV1_1.json')
const Layer2ManagerV1_1_Json = require('../../test/abi/Layer2ManagerV1_1.json')
const DAOCommitteeAddV1_1_Json = require('../../test/abi/DAOCommitteeAddV1_1.json')

const tester = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

const  L1BridgeRegistryProxy = "0x35822B4be688B06E58479Ed289E928cB25Cb3c68"

const  Layer2ManagerProxy = "0x53faC2e379cBfFd4C32D2b6FBBA83De102DDA2E5"

let TON = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"
let DAOAgendaManager = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08"
let DAOCommitteeProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

let thanos_sepolia = {
    rollupConfig : "0x6eF61974A3CDa7BbD0a4DD0A613f56d211c8AfDC",
    type : 2,
    l2TON : "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000",
     name : "Thanos Sepolia"
}

async function proposeAgenda_registerRollupConfigByManager () {

    console.log('\n==== proposeAgenda_registerRollupConfigByManager ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    let deployerAddress = await deployer.getAddress()

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     tester,
    // ]);
    // await hre.network.provider.send("hardhat_setBalance", [
    //     tester,
    //     "0x10000000000000000000000000",
    // ]);
    // deployer = await hre.ethers.getSigner(tester);
    // deployerAddress = tester

    console.log('deployer ', deployerAddress)

    const daoAgendaManagerContract = new ethers.Contract(DAOAgendaManager,  DAOAgendaManager_Json.abi, deployer)
    const tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)
    const l1BridgeRegistryV1_1 = new ethers.Contract(L1BridgeRegistryProxy,  L1BridgeRegistryV1_1_Json.abi, deployer)


    ///--- Agenda ---------------------------------
    let targets = []
    let params = []
    let callDtata

    // =========================================
    //  L1BridgeRegistryProxy.registerRollupConfigByManager
    // (address rollupConfig, uint8 _type, address _l2TON, string calldata _name)
    targets.push(L1BridgeRegistryProxy)
    callDtata = l1BridgeRegistryV1_1.interface.encodeFunctionData("registerRollupConfigByManager(address,uint8,address,string)",
        [
            thanos_sepolia.rollupConfig,
            thanos_sepolia.type,
            thanos_sepolia.l2TON,
            thanos_sepolia.name
        ])
    params.push(callDtata)
    console.log('L1BridgeRegistryProxy.registerRollupConfigByManager')

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
    console.log('make an agenda')

    // =========================================
    // Propose an agenda
    let receipt = await (await tonContract.connect(deployer).approveAndCall(
        DAOCommitteeProxy,
        agendaFee,
        param
    )).wait()

    console.log('Propose an agenda receipt ', receipt)
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
    // expect(agenda.executedTimestamp).to.be.gt(0);
    // expect(agenda.executed).to.be.equal(true);

    console.log('Aagenda before executeing ', agenda)
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

async function exec_registerCandidateAddOn() {

    console.log('\n==== exec_registerCandidateAddOn ===== ')
    // const accounts = await ethers.getSigners()
    // let deployer = accounts[0]

    await hre.network.provider.send("hardhat_impersonateAccount", [
        tester,
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
        tester,
        "0x10000000000000000000000000",
    ]);
    deployer = await hre.ethers.getSigner(tester);
    deployerAddress = tester


    const layer2ManagerV1_1 = new ethers.Contract(Layer2ManagerProxy,  Layer2ManagerV1_1_Json.abi, deployer)
    const receipt = await (await layer2ManagerV1_1.registerCandidateAddOn(
        thanos_sepolia.rollupConfig,
        ethers.BigNumber.from("1000100000000000000000"),
        true,
        thanos_sepolia.name
    )).wait()

    console.log("Layer2ManagerV1_1.exec_registerCandidateAddOn ",receipt)

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

    // await proposeAgenda_registerRollupConfigByManager()
    // await executeAgenda(34)
    // await views()

    await exec_registerCandidateAddOn()

    // await view_dao_info()

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});