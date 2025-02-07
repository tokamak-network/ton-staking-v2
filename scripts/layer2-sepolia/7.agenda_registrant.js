const { ethers } = require("hardhat");
const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')
const DAOAgendaManager_Json = require('../../test/abi/DAOAgendaManager.json')
const Ton_Json = require('../../abi/TON.json')
const DAOCommittee_V1_Json = require('../../test/abi/DAOCommittee_V1.json')
const L1BridgeRegistryV1_1_Json = require('../../test/abi/L1BridgeRegistryV1_1.json')


const tester = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

const  L1BridgeRegistryProxy = "0x35822B4be688B06E58479Ed289E928cB25Cb3c68"

let TON = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"
let DAOAgendaManager = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08"
let DAOCommitteeProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"

let registrant = "0xfca535c88660e261f3bd82c81640366dbbb3517a"

async function registranst () {

    console.log('\n==== registranst ===== ')
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
    //  L1BridgeRegistryProxy.addRegistrant(address account)
    targets.push(L1BridgeRegistryProxy)
    callDtata = l1BridgeRegistryV1_1.interface.encodeFunctionData("addRegistrant",
        [
            registrant
        ])
    params.push(callDtata)
    console.log('L1BridgeRegistryProxy.addRegistrant')


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

    console.log('Aagenda Aefore executeing ', agenda)
}

async function views() {

    console.log('\n==== views ===== ')
    const accounts = await ethers.getSigners()
    let deployer = accounts[0]
    const l1BridgeRegistryV1_1 = new ethers.Contract(L1BridgeRegistryProxy,  L1BridgeRegistryV1_1_Json.abi, deployer)

    console.log("l1BridgeRegistryV1_1.isRegistrant ",registrant, " ", await l1BridgeRegistryV1_1.isRegistrant(registrant))

}

const main = async () => {

    // await registranst()
    // await executeAgenda(33)
    await views()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});