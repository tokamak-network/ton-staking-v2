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
const oldAutoRefactoryCoinageABI = require("../../abi/AutoRefactorCoinage.json").abi;

const level19Addr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52";
const tokamak1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033";
const hammerDAOAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764";
const DXMCorpAddr = "0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c";
const danalFintechAddr = "0x97d0a5880542ab0e699c67e7f4ff61f2e5200484"
const DeSpreadAddr = "0x2000fc16911fc044130c29c1aa49d3e0b101716a";
const decipherAddr = "0x17602823b5fe43a65ad7122946a73b019e77fd33"
const TalkenAddr = "0xb9d336596ea2662488641c4ac87960bfdcb94c6e";
const DSRVAddr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66";
const stakedAddr = "0xcc38c7aaf2507da52a875e93f57451e58e8c6372";

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

async function burnFrombeforeCheck(deployer) {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let coinageInfo = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));
    // const seigManager = new ethers.Contract(
    //     contractInfos.abis["SeigManagerProxy"].address,
    //     contractInfos.abis["SeigManager"].abi,
    //     deployer
    // )
    const oldseigManager =  new ethers.Contract(
        oldContractInfo.SeigManager,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )

    let i;
    for (i = 0; i < coinageInfo.length; i++) {
        let getOldCoinageAddr = (await oldseigManager.connect(deployer).coinages(coinageInfo[i].layer2)).toLowerCase()
        if(getOldCoinageAddr == coinageInfo[i].coinage) {
            const oldAutoRefactoryCoinage = new ethers.Contract(
                getOldCoinageAddr,
                oldAutoRefactoryCoinageABI,
                deployer
            )
            
            let checkBalance = await oldAutoRefactoryCoinage.totalSupply();
            if(checkBalance != coinageInfo[i].balance) {
                console.log("============ Coinage totalSupply DATA ERROR ============");
            } else {
                console.log("============ before ", i ," Check PASS ============");
            }
        } else {
            console.log("getOldCoinageAddr :", getOldCoinageAddr)
            console.log("coinageInfo[i].coinage :", coinageInfo[i].coinage)
            console.log("============ Coinage Addr DATA ERROR ============");
        }
    }

}

async function burnFromCoinage(deployer) {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let coinageInfo = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));

    const oldseigManager =  new ethers.Contract(
        oldContractInfo.SeigManager,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )

    let i;
    let j;
    for (i = 0; i < coinageInfo.length; i++) {
        let layer2Info = JSON.parse(await fs.readFileSync(dataFolder + "/layer2-accounts-balances/"+coinageInfo[i].layer2+".json"));
        console.log("============ Addr ", i ," Check PASS ============");
        console.log("============ Layer2Addr ", coinageInfo[i].layer2 ," ============");
        console.log("============ CoinageAddr ", coinageInfo[i].coinage ," ============");
        const oldAutoRefactoryCoinage = new ethers.Contract(
            coinageInfo[i].coinage,
            oldAutoRefactoryCoinageABI,
            deployer
        )

        console.log("layer2Info.length : ", layer2Info.length);
        // for(j = 150; j < layer2Info.length; j++){
        //     console.log("layer2Info.account : ",layer2Info[j].account)
        //     console.log("layer2Info.balance : ",layer2Info[j].balance)
        //     await oldAutoRefactoryCoinage.connect(deployer).burnFrom(
        //         layer2Info[j].account,
        //         layer2Info[j].balance
        //     )
        // }
        for(j = 0; j < layer2Info.length -1; j++){
            console.log("layer2Info.account : ",layer2Info[j].account)
            console.log("layer2Info.balance : ",layer2Info[j].balance)
            await oldAutoRefactoryCoinage.connect(deployer).burnFrom(
                layer2Info[j].account,
                layer2Info[j].balance
            )
        }

        let checkBalance = await oldAutoRefactoryCoinage.totalSupply();
        console.log("before final checkBalance : ", checkBalance);

        console.log("layer2Info.account : ",layer2Info[layer2Info.length-1].account)
        console.log("layer2Info.balance : ",layer2Info[layer2Info.length-1].balance)
        await oldAutoRefactoryCoinage.connect(deployer).burnFrom(
            layer2Info[layer2Info.length-1].account,
            checkBalance
        )   
        let diffBalance = Number(layer2Info[layer2Info.length-1].balance) - Number(checkBalance)
        checkBalance = await oldAutoRefactoryCoinage.totalSupply();
        console.log("final checkBalance : ", checkBalance);
        console.log("diff balance :", diffBalance);
    }

    // for (i = 0; i < coinageInfo.length; i++) {
    //     let layer2Info = JSON.parse(await fs.readFileSync(dataFolder + "/layer2-accounts-balances/"+coinageInfo[i].layer2+".json"));
    //     console.log("============ Addr ", i ," Check PASS ============");
    //     console.log("============ Layer2Addr ", coinageInfo[i].layer2 ," ============");
    //     console.log("============ CoinageAddr ", coinageInfo[i].coinage ," ============");
    //     const oldAutoRefactoryCoinage = new ethers.Contract(
    //         coinageInfo[i].coinage,
    //         oldAutoRefactoryCoinageABI,
    //         deployer
    //     )

    //     for(j = 0; j < layer2Info.length; j++){
    //         console.log("layer2Info.account : ",layer2Info[j].account)
    //         await oldAutoRefactoryCoinage.connect(deployer).burnFrom(
    //             layer2Info[j].account,
    //             layer2Info[j].balance
    //         )
    //     }
    // }

}

async function burnFromCoinageAfterCheck(deployer) {
    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    let coinageInfo = JSON.parse(await fs.readFileSync(dataFolder + "/coinages-total-supply.json"));
    // const seigManager = new ethers.Contract(
    //     contractInfos.abis["SeigManagerProxy"].address,
    //     contractInfos.abis["SeigManager"].abi,
    //     deployer
    // )
    const oldseigManager =  new ethers.Contract(
        oldContractInfo.SeigManager,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )

    let i;
    for (i = 0; i < coinageInfo.length; i++) {
        let getOldCoinageAddr = (await oldseigManager.connect(deployer).coinages(coinageInfo[i].layer2)).toLowerCase()
        if(getOldCoinageAddr == coinageInfo[i].coinage) {
            const oldAutoRefactoryCoinage = new ethers.Contract(
                getOldCoinageAddr,
                oldAutoRefactoryCoinageABI,
                deployer
            )
            
            let checkBalance = await oldAutoRefactoryCoinage.totalSupply();
            if(checkBalance != 0) {
                console.log("============ Coinage totalSupply DATA ERROR ============");
            } else {
                console.log("checkBalance[", i ,"] : ", checkBalance);
            }
        } else {
            console.log("============ Coinage Addr DATA ERROR ============");
        }
    }
}


async function main() {
    const [ deployer ] = await ethers.getSigners()
    console.log(deployer.address)

    // await burnFrombeforeCheck(deployer)
    await burnFromCoinage(deployer)
    // await burnFromCoinageAfterCheck(deployer)
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

