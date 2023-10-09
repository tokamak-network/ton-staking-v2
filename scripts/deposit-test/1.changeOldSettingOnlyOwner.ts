const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const networkName = "localhost"
const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'
const powerTONAdminAddress = '0x15280a52E79FD4aB35F4B9Acbb376DCD72b44Fd1'

// mainnet network
const oldContractInfo = {
    TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
    WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
    // Layer2Registry: "0x6817e1c04748eae68EBFF13216280Df1ec15ba86",
    // DepositManager: "0x0ad659558851f6ba8a8094614303F56d42f8f39A",
    // CoinageFactory: "0x09207BdB146E41dadad015aB3d835f66498b0A0c",
    // OldDAOVaultMock: "0xFD7C2c54a0A755a46793A91449806A4b14E3eEe8",
    SeigManager: "0x710936500aC59e8551331871Cbad3D33d5e0D909",
    PowerTON: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
    DAOVault: "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
    // DAOAgendaManager: "0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21",
    // CandidateFactory: "0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e",
    // DAOCommittee: "0xF7368a07653de908a8510e5d768c9C71b71cB2Ae",
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

    await hre.network.provider.send("hardhat_impersonateAccount", [
        powerTONAdminAddress,
    ]);
    const powerTONAdmin = await hre.ethers.getSigner(powerTONAdminAddress);

    // dao
    const daoCommittee = new ethers.Contract(
        oldContractInfo.DAOCommitteeProxy,
        contractInfos.abis["DAOCommitteeExtend"].abi,
        daoCommitteeAdmin
    )
    console.log('daoCommittee', daoCommittee.address)

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

    let autoCoinageSnapshot = "0x85Ca9f611C363065252EA9462c90743922767b55"
    let lockTOSDividendPool = "0x17332F84Cc0bbaD551Cd16675F406A0a2c55E28C"

    const PowerTONSwapperProxyABI = JSON.parse(await fs.readFileSync("./abi/PowerTONSwapperProxy.json")).abi;

    const powerTonProxy = new ethers.Contract(
        oldContractInfo.PowerTON,
        PowerTONSwapperProxyABI,
        powerTONAdmin
    )

    await (await powerTonProxy.connect(powerTONAdmin).upgradeTo(
        contractInfos.abis["PowerTONUpgrade"].address
        )).wait()

    // powerTon

    const powerTon = new ethers.Contract(
        oldContractInfo.PowerTON,
        contractInfos.abis["PowerTONUpgrade"].abi,
        powerTONAdmin
    )
    
    await (await powerTon.connect(powerTONAdmin).setSeigManager(
        contractInfos.abis["SeigManagerProxy"].address
        )).wait()

    // const powerTon = new ethers.Contract(
    //     oldContractInfo.PowerTON,
    //     contractInfos.abis["PowerTONHammerDAO"].abi,
    //     powerTONAdmin
    // )

    // await (await powerTon.connect(powerTONAdmin).setInfo(
    //     oldContractInfo.WTON,
    //     autoCoinageSnapshot,
    //     contractInfos.abis["SeigManagerProxy"].address,
    //     lockTOSDividendPool
    //     )).wait()

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

