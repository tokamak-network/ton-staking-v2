const { ethers } = require("hardhat");
const {encodeFunctionSignature, encodeParameters} = require('web3-eth-abi')
const SeigManager_Json = require('../../test/abi/SeigManagerV1.json')
const SeigManagerProxy_Json = require('../../test/abi/SeigManagerProxy.json')
const DepositManagerProxy_Json = require('../../test/abi/DepositManagerProxy.json')
const DAOCommitteeOwner_Json = require('../../test/abi/DAOCommitteeOwner.json')
const DepositManagerV1_1_Json = require('../../test/abi/DepositManagerV1_1.json')
const DAOCommitteeAddV1_1_Json = require('../../test/abi/DAOCommitteeAddV1_1.json')
const DAOAgendaManager_Json = require('../../test/abi/DAOAgendaManager.json')
const SeigManagerV1_3_Json = require('../../test/abi/SeigManagerV1_3.json')
const Ton_Json = require('../../abi/TON.json')
const DAOCommittee_V1_Json = require('../../test/abi/DAOCommittee_V1.json')

const tester = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

const  L1BridgeRegistryProxy = "0x35822B4be688B06E58479Ed289E928cB25Cb3c68"
const  CandidateAddOnFactoryProxy = "0x4e13CfdCf03A5bB11d55f2537108860d44F3C098"
const  Layer2ManagerProxy = "0x53faC2e379cBfFd4C32D2b6FBBA83De102DDA2E5"
const  SeigManagerV1_3 = "0x1ae2b8a23384e4D76290eF9AE30Edf574D82d991"
const  DepositManagerV1_1 = "0xa9d1AaE84f4fF55d72B5f2D71fFAFe99a3F9BdE2"

let TON = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044"
let DAOAgendaManager = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08"
let DAOCommitteeProxy = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
let SeigManagerAddress = "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7"
let DepositManagerAddress = "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
let tonHaveAddr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"

async function upgradeContracts_v25_2 () {

    console.log('\n==== upgradeContracts_v25_2.5 ===== ')
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
    const seigManager = new ethers.Contract(SeigManagerAddress,  SeigManager_Json.abi, deployer)
    const tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)
    const seigManagerProxy = new ethers.Contract(SeigManagerAddress,  SeigManagerProxy_Json.abi, deployer)
    const depositManagerProxy = new ethers.Contract(DepositManagerAddress,  DepositManagerProxy_Json.abi, deployer)
    const daoCommitteeOwner = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeOwner_Json.abi, deployer)
    const depositManagerV1_1 = new ethers.Contract(DepositManagerAddress,  DepositManagerV1_1_Json.abi, deployer)
    const seigManagerV1_1 = new ethers.Contract(SeigManagerAddress,  SeigManagerV1_3_Json.abi, deployer)
    ///--- Agenda ---------------------------------
    let targets = []
    let params = []
    let callDtata

    // =========================================
    //  set DAOCommitteeProxy candidateAddOnFactory --> 이전에 프록시를 해야 하는데, 로직으로 설정을 잘못함.
    targets.push(DAOCommitteeProxy)
    callDtata = daoCommitteeOwner.interface.encodeFunctionData("setCandidateAddOnFactory", [CandidateAddOnFactoryProxy])
    params.push(callDtata)
    console.log('set DAOCommitteeProxy CandidateAddOnFactoryProxy')

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

    const daoCommitteeAddV1_1 = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeAddV1_1_Json.abi, deployer)

    console.log("daoCommitteeAddV1_1.candidateAddOnFactory", await daoCommitteeAddV1_1.candidateAddOnFactory())


}

const main = async () => {

    // await upgradeContracts_v25_2()
    // await executeAgenda(35)

    await views()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});