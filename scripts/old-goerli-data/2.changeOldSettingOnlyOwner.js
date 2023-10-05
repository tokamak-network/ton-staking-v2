const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const networkName = "goerli"
const pauseBlock = 9768417
const startBlock = 8437208
const dataFolder = './data-goerli'
const daoAdminAddress = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'

// goerli network
const oldContractInfo = {
    TON: "0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00",
    WTON: "0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6",
    Layer2Registry: "0x6817e1c04748eae68EBFF13216280Df1ec15ba86",
    DepositManager: "0x0ad659558851f6ba8a8094614303F56d42f8f39A",
    CoinageFactory: "0x09207BdB146E41dadad015aB3d835f66498b0A0c",
    OldDAOVaultMock: "0xFD7C2c54a0A755a46793A91449806A4b14E3eEe8",
    SeigManager: "0x446ece59ef429B774Ff116432bbB123f1915D9E3",
    PowerTON: "0x7F379E61F2F1cAf23Ccd4EBaa92797FbCDF00d68",
    DAOVault: "0xb0B9c6076D46E333A8314ccC242992A625931C99",
    DAOAgendaManager: "0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21",
    CandidateFactory: "0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e",
    DAOCommittee: "0xF7368a07653de908a8510e5d768c9C71b71cB2Ae",
    DAOCommitteeProxy: "0x3C5ffEe61A384B384ed38c0983429dcDb49843F6"
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

