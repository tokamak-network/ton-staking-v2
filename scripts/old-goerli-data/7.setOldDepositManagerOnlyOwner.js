const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const networkName = "goerli"
const pauseBlock = 9768417
const startBlock = 8437208
const dataFolder = './data-goerli'
const daoAdminAddress = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'
const goerliWtonAdmin = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2";

const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DepositManagerABI = require("../../abi/DepositManager.json").abi;

// goerli network
const oldContractInfo = {
    TON: "0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00",
    WTON: "0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6",
    Layer2Registry: "0x6817e1c04748eae68EBFF13216280Df1ec15ba86",
    DepositManager: "0x0ad659558851f6ba8a8094614303F56d42f8f39A",
    CoinageFactory: "0x09207BdB146E41dadad015aB3d835f66498b0A0c",
    OldDAOVaultMock: "0xFD7C2c54a0A755a46793A91449806A4b14E3eEe8",
    SeigManager: "0x446ece59ef429B774Ff116432bbB123f1915D9E3",
    PowerTON: "0x031B5b13Df847eB10c14451EB2a354EfEE23Cc94",
    DAOVault: "0xb0B9c6076D46E333A8314ccC242992A625931C99",
    DAOAgendaManager: "0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21",
    CandidateFactory: "0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e",
    DAOCommittee: "0xF7368a07653de908a8510e5d768c9C71b71cB2Ae",
    DAOCommitteeProxy: "0x3C5ffEe61A384B384ed38c0983429dcDb49843F6"
}

async function setOldDepositManagerAndMinter(deployer) {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    const WTONABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;

    await hre.network.provider.send("hardhat_impersonateAccount", [
        daoAdminAddress,
    ]);

    await hre.network.provider.send("hardhat_setBalance", [
        daoAdminAddress,
        "0x10000000000000000000000000",
      ]);

    const daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

    //==============================================
    // dao
    const daoCommittee = new ethers.Contract(
        oldContractInfo.DAOCommitteeProxy,
        DAOCommitteeExtendABI,
        ethers.provider
    )
    console.log('daoCommittee', daoCommittee.address)
    const DepositManager = new ethers.Contract(
        oldContractInfo.DepositManager,
        DepositManagerABI,
        ethers.provider
    )

    let seig = await DepositManager.seigManager()
    console.log('seig', seig)

    // console.log('contractInfos.abis["TestSeigManager"].address ', contractInfos.abis["TestSeigManager"].address)

    if(seig != contractInfos.abis["TestSeigManager"].address) {
        await (await daoCommittee.connect(daoCommitteeAdmin).setTargetSeigManager(
            oldContractInfo.DepositManager,
            contractInfos.abis["TestSeigManager"].address,
        )).wait()
    }

    console.log('setTargetSeigManager done ' )

    let owner = await DepositManager.owner()
    console.log('owner ', owner )
    console.log('daoCommittee.address ', daoCommittee.address )


    let globalWithdrawalDelay = await DepositManager.globalWithdrawalDelay()
    console.log('globalWithdrawalDelay ', globalWithdrawalDelay )
    console.log('oldContractInfo.DepositManager ', oldContractInfo.DepositManager )

    // const gos = await daoCommittee.connect(daoCommitteeAdmin).estimateGas["setTargetGlobalWithdrawalDelay(address,uint256)"](
    //     oldContractInfo.DepositManager, ethers.BigNumber.from("1"))

    // console.log('gos', gos)
    if(globalWithdrawalDelay.gt(ethers.constants.Zero)) {
        await (await daoCommittee.connect(daoCommitteeAdmin).setTargetGlobalWithdrawalDelay(
            oldContractInfo.DepositManager,
            ethers.constants.Zero
        )).wait()

        globalWithdrawalDelay = await DepositManager.globalWithdrawalDelay()
        console.log('globalWithdrawalDelay ', globalWithdrawalDelay )
    }

    //==============================================
    // WTON
    const wton = new ethers.Contract(
        oldContractInfo.WTON,
        WTONABI,
        daoCommitteeAdmin
    )

    let isMinter = await wton.isMinter(contractInfos.abis["SeigManagerProxy"].address)
    console.log('isMinter of WTON ', isMinter )

    if(isMinter == false) {


        let wtonAdmin = daoCommitteeAdmin;
        if(networkName == "goerli")  {
            await hre.network.provider.send("hardhat_impersonateAccount", [
                goerliWtonAdmin,
            ]);
            wtonAdmin = await hre.ethers.getSigner(goerliWtonAdmin);
        }
        console.log('wtonAdmin  ', wtonAdmin.address )


        await (await daoCommittee.connect(wtonAdmin).setTargetAddMinter(
            oldContractInfo.WTON,
            contractInfos.abis["SeigManagerProxy"].address
        )).wait()

        isMinter = await wton.isMinter(contractInfos.abis["SeigManagerProxy"].address)
        console.log('isMinter of WTON ', isMinter )
    }

}

async function main() {
    const [ deployer ] = await ethers.getSigners()
    console.log(deployer.address)

    await setOldDepositManagerAndMinter(deployer)
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

