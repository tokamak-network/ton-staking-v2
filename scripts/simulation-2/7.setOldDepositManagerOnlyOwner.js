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
const DepositManagerABI = require("../../abi/DepositManager.json").abi;

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
        await (await daoCommittee.connect(daoCommitteeAdmin).setTargetAddMinter(
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

