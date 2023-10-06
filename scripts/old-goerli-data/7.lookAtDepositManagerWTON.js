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

async function getDepositManagerInfos() {
    const RefactorCoinageSnapshotABI = JSON.parse(await fs.readFileSync("./abi/RefactorCoinageSnapshot.json")).abi;

    const DepositManagerABI = JSON.parse(await fs.readFileSync("./abi/DepositManager.json")).abi;
    const WTONABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));
    let oldLayers = JSON.parse(await fs.readFileSync(dataFolder + "/tot-balances.json"));

    const wtonContract = new ethers.Contract(
        oldContractInfo.WTON,
        WTONABI,
        ethers.provider
    )

    const oldDepositManager = new ethers.Contract(
        oldContractInfo.DepositManager,
        DepositManagerABI,
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


async function burnAndMint(amount) {
    await hre.network.provider.send("hardhat_impersonateAccount", [
        daoAdminAddress,
    ]);
    const daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);
    const WTONABI = JSON.parse(await fs.readFileSync("./abi/WTON.json")).abi;
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);

    const wtonContract = new ethers.Contract(
        oldContractInfo.WTON,
        WTONABI,
        ethers.provider
    )
    const receiptBurn = await (await wtonContract.connect(daoCommitteeAdmin)["burnFrom(address,uint256)"](
        oldContractInfo.DepositManager, amount)).wait()

    console.log('receiptBurn tx:', receiptBurn.transactionHash)

    const receiptMint = await (await wtonContract.connect(daoCommitteeAdmin)["mint(address,uint256)"](
        contractInfos.abis["DepositManager"].address, amount)).wait()

    console.log('receiptMint tx:', receiptMint.transactionHash)
}

async function main() {
    // const [ deployer ] = await ethers.getSigners()
    // console.log(deployer.address)

    // getDepositManager Infos
    let burnAmount = await getDepositManagerInfos()


    //============= only DAO Owner !!!
    if(burnAmount != null && burnAmount.gt(ethers.constants.Zero)) {
        await burnAndMint(burnAmount)
    }
    //=============
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

