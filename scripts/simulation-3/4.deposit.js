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

    const txs = 40

    for (let layer2 of layer2s) {
        console.log('layer2', layer2)
        let balances = JSON.parse(await fs.readFileSync(dataFolder + "/layer2-accounts-balances/"+layer2.oldLayer.toLowerCase()+".json"));
        console.log('balances length ', balances.length)

        let start = 0;
        let end = balances.length;
        let txCounts = Math.ceil(end/txs);

        console.log('balances.length : ', balances.length)
        console.log('txCounts', txCounts)
        for (let i = 0; i < txCounts; i++) {
            let accounts = []
            let amounts = []
            console.log('------- i : ' , i, ', txCounts:',txCounts )
            for (let j = i * txs ; j < i * txs + txs ; j++){
                if(j >= end ) break;
                accounts.push(balances[j].account)
                amounts.push(ethers.BigNumber.from(balances[j].balance))
            }

            console.log('layer2.newLayer', layer2.newLayer)
            // console.log('accounts', accounts)
            // console.log('amounts', amounts)

            console.log('accounts', accounts.length)
            console.log('amounts', amounts.length)

            let layer2s = await layer2Registry.layer2s(layer2.newLayer)
            console.log('layer2s', layer2s)

            // const gos = await depositManager.connect(deployer).estimateGas["depositWithoutTransfer(address,address[],uint256[])"](layer2.newLayer, accounts, amounts)
            // console.log('gos', gos)

            let receipt = await (await depositManager.connect(deployer)["depositWithoutTransfer(address,address[],uint256[])"](layer2.newLayer, accounts, amounts)).wait();
            console.log('receipt transactionHash', receipt.transactionHash)
        }

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

