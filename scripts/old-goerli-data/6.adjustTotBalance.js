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
    PowerTON: "0x031B5b13Df847eB10c14451EB2a354EfEE23Cc94",
    DAOVault: "0xb0B9c6076D46E333A8314ccC242992A625931C99",
    DAOAgendaManager: "0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21",
    CandidateFactory: "0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e",
    DAOCommittee: "0xF7368a07653de908a8510e5d768c9C71b71cB2Ae",
    DAOCommitteeProxy: "0x3C5ffEe61A384B384ed38c0983429dcDb49843F6"
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
    let adjustTotal = JSON.parse(await fs.readFileSync(dataFolder + "/adjust-tot-balances.json"));
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
                console.log('- adjustAmount ', adjustLayer.newLayer, amount, ', tx: ',receipt.transactionHash)
            } else {
                console.log('zero adjustAmount ', adjustLayer)
            }
        }
    } else {
        console.log('adjustLayers is empty')
    }

    let updateTotal = await totContract.totalSupply()
    console.log('\n *** updateTotTotal ', updateTotal)
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

