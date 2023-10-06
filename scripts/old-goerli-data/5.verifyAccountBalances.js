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

async function verifyAccountBalance(deployer) {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));
    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )


    for (let layer2 of layer2s) {

        let layerAddress = layer2.newLayer
        let accounts = JSON.parse(await fs.readFileSync(dataFolder + "/layer2-accounts-balances/"+layer2.oldLayer.toLowerCase()+".json"));

        for (let account of accounts) {

            let balance = await seigManager["stakeOf(address,address)"](layerAddress, account.account)

            if(!balance.eq(ethers.BigNumber.from(account.balance))) {
                console.log('\n*** verifyAccountBalance not matched ! layer2 : ', layer2,', account: ',account , ', balance: ', balance )
            }
        }

    }

}

function getNewLayerAddress (layerList, oldLayer){
    for (let layer of layerList) {
        if(layer.oldLayer.toLowerCase() == oldLayer.toLowerCase()) return layer.newLayer.toLowerCase()
    }
    return null
}

async function verifyLayersTotalSupply(deployer) {
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));
    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )

    let oldLayers = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));

    for (let oldLayer of oldLayers) {

        let layerAddress = getNewLayerAddress(layer2s, oldLayer.layer2)

        let coinage = await seigManager.coinages(layerAddress)
        const coinageContract = new ethers.Contract(
            coinage,
            RefactorCoinageSnapshotABI,
            deployer
        )
        let totalSupply =  await coinageContract.totalSupply()

        if(!totalSupply.eq(ethers.BigNumber.from(oldLayer.balance))) {
            console.log('\n*** verifyLayersTotalSupply not matched ! layerAddress : ', layerAddress, ', oldLayer: ',oldLayer, ', totalSupply: ', totalSupply)
        }
    }

}


async function main() {
    const [ deployer ] = await ethers.getSigners()
    // console.log(deployer.address)

    await verifyAccountBalance(deployer)

    await verifyLayersTotalSupply(deployer)


}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

