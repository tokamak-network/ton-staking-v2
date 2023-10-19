const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const networkName = "goerli"
const pauseBlock = 9768417
const startBlock = 8437208
const dataFolder = './data-goerli'

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

async function deposit(deployer) {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let layer2s = JSON.parse(await fs.readFileSync(dataFolder + "/layer2_name_map_created.json"));

    const depositManager = new ethers.Contract(
        contractInfos.abis["DepositManagerProxy"].address,
        contractInfos.abis["DepositManagerForMigration"].abi,
        deployer
    )
    console.log('depositManager', depositManager.address)

    const layer2Registry = new ethers.Contract(
        contractInfos.abis["Layer2RegistryProxy"].address,
        contractInfos.abis["Layer2Registry"].abi,
        deployer
    )

    const txs = 2

    let kk = 1;
    for (let layer2 of layer2s) {
        if (kk == 3) {

            console.log('layer2', layer2)
            let balances = JSON.parse(await fs.readFileSync(dataFolder + "/layer2-accounts-balances/"+layer2.oldLayer.toLowerCase()+".json"));
            // console.log('balances length ', balances.length)

            let start = 0;
            let end = balances.length;
            let txCounts = Math.ceil(end/txs);

            // console.log('end', end)
            // console.log('txCounts', txCounts)
            for (let i = 0; i < txCounts; i++) {
                let accounts = []
                let amounts = []
                for (let j = i * txs ; j < i * txs + txs ; j++){
                    if(j >= end ) break;
                    accounts.push(balances[j].account)
                    amounts.push(ethers.BigNumber.from(balances[j].balance))
                }
                console.log('accounts', accounts)
                console.log('amounts', amounts)
                console.log('layer2.newLayer', layer2.newLayer)


                let layer2s = await layer2Registry.layer2s(layer2.newLayer)
                console.log('layer2s', layer2s)

                const gos = await depositManager.connect(deployer).estimateGas["depositWithoutTransfer(address,address[],uint256[])"](layer2.newLayer, accounts, amounts)
                console.log('gos', gos)

                let receipt = await (await depositManager.connect(deployer)["depositWithoutTransfer(address,address[],uint256[])"](layer2.newLayer, accounts, amounts)).wait();
                console.log('receipt transactionHash', receipt.transactionHash)
            }
        }

        kk++;
    }

}


async function main() {
    const [ deployer ] = await ethers.getSigners()
    console.log(deployer.address)

    await deposit(deployer)
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

