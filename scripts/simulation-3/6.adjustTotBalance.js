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

function getNewLayerAddress (layerList, oldLayer){
    for (let layer of layerList) {
        if(layer.oldLayer.toLowerCase() == oldLayer.toLowerCase()) return layer.newLayer.toLowerCase()
    }
    return null
}

async function getAdjustTotBalances(deployer) {
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));
    let oldLayers = JSON.parse(await fs.readFileSync(dataFolder + "/tot-balances.json"));

    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )
    let totAddress = await seigManager.tot()
    const totContract = new ethers.Contract(
        totAddress,
        RefactorCoinageSnapshotABI,
        deployer
    )

    let adjustTotBalanace = []
    let adjustTotTotalSupply = []

    let adjustTotBalanceSum = ethers.constants.Zero

    for (let oldLayer of oldLayers) {

        let layerAddress = getNewLayerAddress(layer2s, oldLayer.layer2)
        let balance = await totContract.balanceOf(layerAddress)
        // console.log('totContract balanceOf' ,layerAddress, ', balance', balance)
        // console.log('oldLayers oldLayer' ,oldLayer )

        // 예전 tot의 balance와 현재 tot balance가 같은지 확인한다.
        let oldBalance = ethers.BigNumber.from(oldLayer.balance)
        if(oldBalance.gt(balance)) {
            // console.log('adjustTotBalanace oldLayer ' ,oldLayer, ', newLayer : ', layerAddress, ', balanceOf', balance)

            let amount = oldBalance.sub(balance)
            adjustTotBalanace.push({
                oldLayer: oldLayer.layer2.toLowerCase(),
                newLayer: layerAddress.toLowerCase(),
                oldBalance: oldBalance.toString(),
                newBalance: balance.toString(),
                adjustAmount:  amount.toString()
            })

            adjustTotBalanceSum = adjustTotBalanceSum.add(amount)
        } else if(oldBalance.lt(balance)) {
            console.log('\n*** adjustTotBalances error ! oldLayer ' ,oldLayer, ', newLayer : ', layerAddress, ', balance', balance)
        }
    }
    await fs.writeFileSync(dataFolder + "/adjust-tot-balances.json", JSON.stringify(adjustTotBalanace));
    console.log('\n created  adjust-tot-balances.json ' )

    //--- tot-total-supply
    let oldTotToal = JSON.parse(await fs.readFileSync(dataFolder + "/tot-total-supply.json"));
    let oldtotal = ethers.BigNumber.from(oldTotToal[0])
    let totTotal = await totContract.totalSupply()
    console.log('\n *** oldTotToal ', oldtotal )
    console.log('current totTotal ', totTotal )


    let diffTotal = oldtotal.sub(totTotal)
    adjustTotTotalSupply.push(diffTotal.toString())

    await fs.writeFileSync(dataFolder + "/adjust-tot-total-supply.json", JSON.stringify(adjustTotTotalSupply));
    console.log('\n created  adjust-tot-total-supply.json ' )

    console.log('\n adjustTotBalanceSum ', adjustTotBalanceSum )
    console.log('diffTotal ', diffTotal )
}


async function execAdjustTotBalances(deployer) {
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let adjustLayers = JSON.parse(await fs.readFileSync(dataFolder + "/adjust-tot-balances.json"));
    // let adjustTotal = JSON.parse(await fs.readFileSync(dataFolder + "/adjust-tot-balances.json"));
    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManagerMigration"].abi,
        deployer
    )
    let totAddress = await seigManager.tot()
    const totContract = new ethers.Contract(
        totAddress,
        RefactorCoinageSnapshotABI,
        deployer
    )

    if (adjustLayers.length > 0) {

        for (let adjustLayer of adjustLayers) {
            if(parseInt(adjustLayer.adjustAmount) > 0) {
                let amount = ethers.BigNumber.from(adjustLayer.adjustAmount)
                let receipt = await (await seigManager.adjustTotBalance(adjustLayer.newLayer , amount)).wait()
                console.log('** adjustAmount ', adjustLayer.newLayer, amount, ', tx: ',receipt.transactionHash)
            } else {
                console.log('zero adjustAmount ', adjustLayer)
            }
        }
    } else {
        console.log('adjustLayers is empty')
    }

    let updateTotal = await totContract.totalSupply()
    console.log('\n *** updated tot total ', updateTotal)
}


async function main() {
    const [ deployer ] = await ethers.getSigners()
    // console.log(deployer.address)

    await getAdjustTotBalances(deployer)
    await execAdjustTotBalances(deployer)

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

