const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");

const networkName = "local"
const pauseBlock = 18231453
const startBlock = 10837675

const dataFolder = './data-mainnet'
const deployerAddress = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;

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

//====== WTON  addMinter to seigManagerV2 ==================

//=== daoCommittee
//   await (await daoCommittee.connect(daoCommitteeAdmin).setCandidateFactory(candidateFactoryProxy.address)).wait()
//   await (await daoCommittee.connect(daoCommitteeAdmin).setSeigManager(seigManagerProxy.address)).wait()
//   await (await daoCommittee.connect(daoCommitteeAdmin).setLayer2Registry(layer2RegistryProxy.address)).wait()


async function changeDaoSetting() {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);

    await hre.network.provider.send("hardhat_impersonateAccount", [
        daoAdminAddress,
    ]);
    const daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    // dao
    const daoCommittee = new ethers.Contract(
        oldContractInfo.DAOCommitteeProxy,
        DAOCommitteeExtendABI,
        daoCommitteeAdmin
    )
    console.log('daoCommittee', daoCommittee.address)

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

    //========================


    await (await daoCommittee.connect(daoCommitteeAdmin).setCandidateFactory(
        contractInfos.abis["CandidateFactoryProxy"].address
        )).wait()


    await (await daoCommittee.connect(daoCommitteeAdmin).setSeigManager(
        contractInfos.abis["SeigManagerProxy"].address
        )).wait()

    await (await daoCommittee.connect(daoCommitteeAdmin).setLayer2Registry(
        contractInfos.abis["Layer2RegistryProxy"].address
        )).wait()


    let  layer2RegistryAddress = await daoCommittee.layer2Registry()
    console.log('layer2RegistryAddress', layer2RegistryAddress)
    console.log('Layer2RegistryProxy', contractInfos.abis["Layer2RegistryProxy"].address)

    let  seigManagerAddress = await daoCommittee.seigManager()
    console.log('seigManagerAddress', seigManagerAddress)
    console.log('SeigManagerProxy', contractInfos.abis["SeigManagerProxy"].address)

    let  candidateFactory = await daoCommittee.candidateFactory()
    console.log('candidateFactory', candidateFactory)
    console.log('CandidateFactoryProxy', contractInfos.abis["CandidateFactoryProxy"].address)

    // powerTon
    const PowerTONSwapperProxyABI = JSON.parse(await fs.readFileSync("./abi/PowerTONSwapperProxy.json")).abi;

    const powerTonProxy = new ethers.Contract(
        oldContractInfo.PowerTON,
        PowerTONSwapperProxyABI,
        daoCommitteeAdmin
    )
    console.log('powerTonProxy', powerTonProxy.address)
    console.log('PowerTONUpgrade', contractInfos.abis["PowerTONUpgrade"].address)
    let powerTOnImpl = await powerTonProxy.implementation()

    console.log('powerTOnImpl', powerTOnImpl)

    let powerTonAdmin = daoCommitteeAdmin;
    if(networkName == "goerli")  {
        await hre.network.provider.send("hardhat_impersonateAccount", [
            goerliPowerTonAdmin,
        ]);
        powerTonAdmin = await hre.ethers.getSigner(goerliPowerTonAdmin);
    } else if(networkName == "local") {
        await hre.network.provider.send("hardhat_impersonateAccount", [
            mainnetPowerTonAdmin,
        ]);
        powerTonAdmin = await hre.ethers.getSigner(mainnetPowerTonAdmin);
    }


    if(powerTOnImpl.toLowerCase() != contractInfos.abis["PowerTONUpgrade"].address.toLowerCase()) {
        let receipt = await (await powerTonProxy.connect(powerTonAdmin).upgradeTo(
            contractInfos.abis["PowerTONUpgrade"].address
            )).wait()
        console.log('receipt transactionHash', receipt.transactionHash)
    }

    const powerTon = new ethers.Contract(
        oldContractInfo.PowerTON,
        contractInfos.abis["PowerTONUpgrade"].abi,
        daoCommitteeAdmin
    )

    await (await powerTon.connect(powerTonAdmin).setSeigManager(
        contractInfos.abis["SeigManagerProxy"].address
        )).wait()

    seigManagerAddress = await powerTon.seigManager()
    console.log('seigManagerAddress', seigManagerAddress)
    console.log('SeigManagerProxy', contractInfos.abis["SeigManagerProxy"].address)


}


async function main() {
      await changeDaoSetting()
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

