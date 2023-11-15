const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");

const networkName = "mainnet"

const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DAOCommitteeOwnerABI = require("../../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const SeigManagerProxyABI = require("../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json").abi;
const SeigManagerABI = require("../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json").abi;

// mainnet network
const oldContractInfo = {
    TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
    WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
    Layer2Registry: "0x0b3E174A2170083e770D5d4Cf56774D221b7063e",
    DepositManager: "0x56E465f654393fa48f007Ed7346105c7195CEe43",
    CoinageFactory: "0x5b40841eeCfB429452AB25216Afc1e1650C07747",
    OldDAOVaultMock: "",
    SeigManager: "0x710936500aC59e8551331871Cbad3D33d5e0D909",
    PowerTON: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
    DAOVault: "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
    DAOAgendaManager: "0xcD4421d082752f363E1687544a09d5112cD4f484",
    CandidateFactory: "0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942",
    DAOCommittee: "0xd1A3fDDCCD09ceBcFCc7845dDba666B7B8e6D1fb",
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
}
const nowContractInfo = {
    TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
    WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
    Layer2Registry: "0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b",
    DepositManager: "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e",
    CoinageFactory: "",
    SeigManager: "0x0b55a0f463b6defb81c6063973763951712d0e5f",
}

async function changeSeigManagerLogic() {

    await hre.network.provider.send("hardhat_impersonateAccount", [
        daoAdminAddress,
    ]);
    const daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    //========================
    const DAOCommitteeOwnerDep = await ethers.getContractFactory("DAOCommitteeOwner");
    const daoCommitteeOwnerLogic = await DAOCommitteeOwnerDep.deploy();
    await daoCommitteeOwnerLogic.deployed();
    console.log('daoCommitteeOwnerLogic' , daoCommitteeOwnerLogic.address)
    //========================
    const SeigManagerDep = await ethers.getContractFactory("SeigManager");
    const seigManagerLogic = await SeigManagerDep.deploy();
    await seigManagerLogic.deployed();
    console.log('seigManagerLogic' , seigManagerLogic.address)

    //== 다오 프록시 막은것 풀기 ======================
    const daoCommitteeProxy = new ethers.Contract(
        oldContractInfo.DAOCommitteeProxy,
        DAOCommitteeProxyABI,
        daoCommitteeAdmin
    )

    let pauseProxy = await daoCommitteeProxy.pauseProxy()
    console.log('pauseProxy', pauseProxy)

    if (pauseProxy == true) {
        await (await daoCommitteeProxy.connect(daoCommitteeAdmin).setProxyPause(false)).wait()
    }
    pauseProxy = await daoCommitteeProxy.pauseProxy()
    console.log('pauseProxy', pauseProxy)

    //== daoCommitteeProxy updateTo  ======================
    let imp1 = await daoCommitteeProxy.implementation()
    if(imp1.toLowerCase() != daoCommitteeOwnerLogic.address.toLowerCase()) {
        await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
            daoCommitteeOwnerLogic.address)).wait()
    }

    //== daoCommittee  ======================
    const daoCommittee = new ethers.Contract(
        daoCommitteeProxy.address,
        DAOCommitteeOwnerABI,
        daoCommitteeAdmin
    )

    //== SeigManager updateTo  ======================
    const seigManagerProxy = new ethers.Contract(
        nowContractInfo.SeigManager,
        SeigManagerProxyABI,
        daoCommitteeAdmin
    )

    let imp = await seigManagerProxy.implementation()
    if(imp.toLowerCase() != seigManagerLogic.address.toLowerCase()) {
        await (await daoCommittee.connect(daoCommitteeAdmin).setTargetUpgradeTo(
            seigManagerProxy.address, seigManagerLogic.address)).wait()
    }

    //========================
    const seigManager = new ethers.Contract(
        nowContractInfo.SeigManager,
        SeigManagerABI,
        daoCommitteeAdmin
    )

    let totalSupplyOfTon = await seigManager.totalSupplyOfTon()
    console.log('totalSupplyOfTon', totalSupplyOfTon)

}


async function main() {
      await changeSeigManagerLogic()
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

