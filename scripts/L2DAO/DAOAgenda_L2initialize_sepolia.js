const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommitteeV1ABI = require("../../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const TONABI = require("../../abi/TON.json").abi;
const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const L1DAOExecutorABI = require("../../artifacts/contracts/dao/L1/L1DAOExecutor.sol/L1DAOExecutor.json").abi;
const L2DAOExecutorABI = require("../../artifacts/contracts/dao/L2/L2DAOExecutor.sol/L2DAOExecutor.json").abi;



const Web3EthAbi = require('web3-eth-abi');
const { padLeft } = require('web3-utils');

const sepoliaContractInfo = {
    TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
    DAOAgendaManager: "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08",
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    DAOCommitteeProxy2: "0x0cb4E974302864D1059028de86757Ca55D121Cb8",
    DAOCommittee_V1: "0xB800a42D9A8e5036B75246aeDA578DCe58f85B18",
    DAOCommitteeOwner: "0x34B6e334D88436Fbbb9c316865A1BA454769C090",
    Layer2CandidateFactory: "0x770739A468D9262960ee0669f9Eaf0db6E21F81A",
    Layer2Manager: "0x0237839A14194085B5145D1d1e1E77dc92aCAF06",
    L1DAOExecutor: "0x109c37fdB56850A6dfd0e29290860B423c25f7e6",
    L2DAOExecutor: "0xDe6b80f4700C2148Ba2aF81640a23E153C007C7F"     //Thanos
}

const mainnetContractInfo = {
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
    DAOCommitteeProxy2: "",
    DAOCommittee_V1: "",
    DAOCommitteeOwner: ""
}

function sleep(ms) {
    const wakeUpTime = Date.now() + ms;
    while (Date.now() < wakeUpTime) {}
}

//using the L1 DAO Executor
async function L1toL2Agenda() {
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    //==== pauseCheck =================================
    let pauseProxy = await daoCommitteeProxy.pauseProxy()

    if (pauseProxy == true) {
        await daoCommitteeProxy.setProxyPause(false)
    }

    console.log("pauseProxy pass")

    //==== Set DAOCommitteeV1 =================================
    let daoCommitteeV1 = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeV1ABI,
        ethers.provider
    )
    console.log("set DAOCommitteeV1 done")

    //==== Set DAOAgendaManager =================================
    let daoagendaManager = new ethers.Contract(
        sepoliaContractInfo.DAOAgendaManager,
        DAOAgendaManagerABI,
        ethers.provider
    )
    console.log("set DAOAgendaManager done")

    //==== Set L1DAOExecutorABI =================================
    let l1daoExecutor = new ethers.Contract(
        sepoliaContractInfo.L1DAOExecutor,
        L1DAOExecutorABI,
        ethers.provider
    )

    //==== Set L2DAOExecutorABI =================================
    let l2daoExecutor = new ethers.Contract(
        sepoliaContractInfo.L2DAOExecutor,
        L2DAOExecutorABI,
        ethers.provider
    )

    //==== Set TON =================================
    let ton = new ethers.Contract(
        sepoliaContractInfo.TON,
        TONABI,
        ethers.provider
    )
    console.log("set TON done")

    let targets = [];
    let functionBytecodes = [];

    let l2crossDomainMessengerAddr = "0x4200000000000000000000000000000000000007"
    let legacyERC20ETHAddr = "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000"
    let l2CrossTradeProxyAddr = "0x0c448437EDCb2a093266dF30619924AE8131b9E3"

    
    
    const functionBytecode0 = l2daoExecutor.interface.encodeFunctionData(
        "initialize", [l2crossDomainMessengerAddr, legacyERC20ETHAddr]
    )
        
    const functionBytecode1 = l2daoExecutor.interface.encodeFunctionData(
        "execute", [l2CrossTradeProxyAddr, functionBytecode0]
    )
        
    // const abiCoder = ethers.utils.defaultAbiCoder;
    // const message = abiCoder.encode()
        
    const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
    const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
        
    const selector1 = Web3EthAbi.encodeFunctionSignature("execute(bytes,uint32)");
        
        
    const minGasLimit = 300000

    // Simple Version

    // const functionBytecodeSimple = l1CrossDomainMessenger.interface.encodeFunctionData(
    //     "sendMessage", [l2DAOContractAddr, functionBytecode1, minGasLimit]
    // )
    // targets.push(sepoliaContractInfo.L1DAOExecutor);
    // functionBytecodes.push(functionBytecode2)

    const functionBytecode2 = l1daoExecutor.interface.encodeFunctionData(
        "execute", [functionBytecode1,minGasLimit]
    )

    targets.push(sepoliaContractInfo.L1DAOExecutor);
    functionBytecodes.push(functionBytecode2)

    const param = Web3EthAbi.encodeParameters(
        ["address[]", "uint128", "uint128", "bool", "bytes[]"],
        [
            targets, 
            noticePeriod.toString(), 
            votingPeriod.toString(), 
            true, 
            functionBytecodes
        ]
    );

    const agendaFee = await daoagendaManager.createAgendaFees();
    console.log("agendaFee :", agendaFee)

    // create agenda
    let tx = await ton.connect(deployer).approveAndCall(
        daoCommitteeProxy.address,
        agendaFee,
        param
    );
    console.log("tx : ", tx);


}


const main = async () => {
  await L1toL2Agenda()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
