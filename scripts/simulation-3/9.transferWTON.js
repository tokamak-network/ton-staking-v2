const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const networkName = "mainnet"
const pauseBlock = 18231453
const startBlock = 10837675

const dataFolder = './data-mainnet'
const deployerAddress = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const OldDepositManagerABI = require("../old-abi/DepositManager.json").abi;

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

async function getDepositManagerInfos() {
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;

    const WTONABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));

    const wtonContract = new ethers.Contract(
        oldContractInfo.WTON,
        WTONABI,
        ethers.provider
    )

    const oldDepositManager = new ethers.Contract(
        oldContractInfo.DepositManager,
        OldDepositManagerABI,
        ethers.provider
    )

    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManagerMigration"].abi,
        ethers.provider
    )
    let totAddress = await seigManager.tot()
    const totContract = new ethers.Contract(
        totAddress,
        RefactorCoinageSnapshotABI,
        ethers.provider
    )

    let wtonBalanceOfDepositManager = await wtonContract.balanceOf(oldContractInfo.DepositManager)
    console.log('(1) wtonBalance Of DepositManager ', wtonBalanceOfDepositManager)

    let sumOfPending = ethers.constants.Zero
    for(let layer2 of layer2s) {
        // console.log('layer2 ', layer2)
        let pending = await oldDepositManager.pendingUnstakedLayer2(layer2.oldLayer)
        // console.log('pending ', pending)

        sumOfPending = sumOfPending.add(pending)
    }
    console.log('(2) pending amount Of DepositManager ', sumOfPending)

    let totTotal = await totContract.totalSupply()
    console.log('(3) totTotal ', totTotal)

    let totAndPending = totTotal.add(sumOfPending)

    console.log('= > totAndPending ', totAndPending)


    let burnAmount = wtonBalanceOfDepositManager.sub(sumOfPending)
    console.log(' *** => burnAmount : (1)-(2) : ', burnAmount)

    return burnAmount;
}


async function transferWTON(deployer, amount) {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     daoAdminAddress,
    // ]);
    // const daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);
    const WTONABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;

    // let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));
    let oldLayers = JSON.parse(await fs.readFileSync(dataFolder + "/tot-balances.json"));
    const wton = new ethers.Contract(
        oldContractInfo.WTON,
        WTONABI,
        deployer
    )

    const depositManager = new ethers.Contract(
        contractInfos.abis["DepositManagerProxy"].address,
        contractInfos.abis["DepositManagerForMigration"].abi,
        deployer
    )

    let oldLayer = oldLayers[0].layer2
    console.log(oldLayer);
    console.log(amount);

    let preBalance = await wton.balanceOf(contractInfos.abis["DepositManagerProxy"].address)
    console.log('preBalance',preBalance);
    await (await depositManager.connect(deployer).oldRequestWithdrawal(oldLayer, amount)).wait()
    await (await depositManager.connect(deployer).oldProcessRequest(oldLayer)).wait()
    let afterBalance = await wton.balanceOf(contractInfos.abis["DepositManagerProxy"].address)
    console.log('afterBalance',afterBalance);
}



async function main() {
    const [ deployer ] = await ethers.getSigners()
    console.log(deployer.address)

    // getDepositManager Infos
    let burnAmount = await getDepositManagerInfos()

    if(burnAmount != null && burnAmount.gt(ethers.constants.Zero)) {
        await transferWTON(deployer, burnAmount)
    }

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

