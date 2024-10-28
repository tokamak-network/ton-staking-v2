const hre = require("hardhat");
const { ethers } = hre;

const DAOCommitteeProxyABI = require("../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const DAOCommitteeOwnerABI = require("../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommitteeV1ABI = require("../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const DAOAgendaManagerABI = require("../abi/daoAgendaManager.json").abi;
const SeigManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const DepositManagerProxy_Json = require('../abi/DepositManagerProxy.json')
const TonABI = require("../abi/TON.json").abi;
const SeigManagerV3ABI = require("../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json").abi;
const DepositManagerV1ABI = require("../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json").abi;
const l1BridgeRegistryV1ABI = require("../artifacts/contracts/layer2/L1BridgeRegistryV1_1.sol/L1BridgeRegistryV1_1.json").abi;


const Web3EthAbi = require('web3-eth-abi');

const sepoliaContractInfo = {
    DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    DAOCommitteeProxy2: "0x0cb4E974302864D1059028de86757Ca55D121Cb8",
    DAOCommittee_V1: "0xB800a42D9A8e5036B75246aeDA578DCe58f85B18",
    DAOCommitteeOwner: "0x34B6e334D88436Fbbb9c316865A1BA454769C090",
    Layer2CandidateFactory: "0x770739A468D9262960ee0669f9Eaf0db6E21F81A",
    Layer2Manager: "0x0237839A14194085B5145D1d1e1E77dc92aCAF06",
    DAOAgendaManager: "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08",
    SeigManagerProxy : "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7",
    DepositManagerProxy : "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F",
    TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
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

async function CreateAgendaTest() {
    //need Pre-setting
    let daoCommitteeProxy2 = "0xbFDE9Bf0eb9f4D2ae12dD17Cb770c3289dC4fd42";
    let daoCommitteeLogic = "0x1E44122E3230957309B29636938e223705C0Da35";
    let daoCommitteeOwnerAddr = "0x84868ca4DD708cC035bcE0578054aa62c663e309";
    let seigManagerV1_3Addr = "0xB0A131FCc74F40b9Fb0379C4AEa7b97617305C31";
    let depositManagerV1_1Addr = "0x18D0F9bC41a82A540e166C949a4A5C02036dffcA";
    let l1BridgeRegistryProxyAddr = "0x3268e4D8276c58A806E83B3B080Cf29514A837cf";
    let layer2ManagerProxyAddr = "0xab303E7CBFd19C998268e19d830770e215AbDF7F";
    let l2TonAddress = "0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2"
    let legacySystemConfigAddr = "0x501C74df1aDEb8024738D880B01306a92d6e722d"
    let candidateAddOnFactoryProxyAddr = "0x31BE6c47233A65fA60877c087634DB582082E4da"
    
    const [deployer] = await ethers.getSigners();
    //==== Set DAOCommitteeProxy =================================
    let daoCommitteeProxy = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeProxyABI,
        ethers.provider
    )

    //==== Set DAOCommitteeV1 =================================
    let daoCommitteeV1_Contract = new ethers.Contract(
        sepoliaContractInfo.DAOCommitteeProxy,
        DAOCommitteeV1ABI,
        ethers.provider
    )


    //==== pauseCheck =================================
    let pauseProxy = await daoCommitteeProxy.pauseProxy()

    if (pauseProxy == true) {
        await daoCommitteeProxy.setProxyPause(false)
    }

    console.log("pauseProxy pass")

    // execute agenda
    let agendaID = 24
    let tx = await daoCommitteeV1_Contract.connect(deployer).executeAgenda(agendaID);
    console.log(tx);
  
}


const main = async () => {
  await CreateAgendaTest()
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
