import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from 'hardhat'

import DepositManager_Json from '../../abi/DepositManager.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'

const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const networkName = "localhost"

// mainnet network
const oldContractInfo = {
    TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
    WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
    // Layer2Registry: "0x6817e1c04748eae68EBFF13216280Df1ec15ba86",
    DepositManager: "0x56E465f654393fa48f007Ed7346105c7195CEe43",
    // CoinageFactory: "0x09207BdB146E41dadad015aB3d835f66498b0A0c",
    // OldDAOVaultMock: "0xFD7C2c54a0A755a46793A91449806A4b14E3eEe8",
    SeigManager: "0x710936500aC59e8551331871Cbad3D33d5e0D909",
    PowerTON: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
    DAOVault: "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
    // DAOAgendaManager: "0x0e1583da47cf641305eDD1e4C6dB6DD18e138a21",
    // CandidateFactory: "0xd1c4fE0Ac211F8A41817c26D1801fd549D56E31e",
    // DAOCommittee: "0xF7368a07653de908a8510e5d768c9C71b71cB2Ae",
    DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
}

let layer2Info_level19 : any;
let layer2Info_tokamak : any;
let layer2Info_hammerDAO : any;
let layer2Info_DXMCorp : any;
let layer2Info_danalFintech : any;
let layer2Info_DeSpread : any;
let layer2Info_decipher : any;
let layer2Info_Talken : any;
let layer2Info_DSRV : any;
let layer2Info_staked : any;

async function totalStakingUserBalance() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    const seigManager = new ethers.Contract(
        contractInfos.abis["SeigManagerProxy"].address,
        contractInfos.abis["SeigManager"].abi,
        deployer
    )

    const level19Addr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52";
    const layerlevel19 = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+level19Addr+".json"));
    
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    let oldTotalBalance;
    let newTotalBalance;
    let i;
    console.log("===================[level19 start]====================");
    for (i = 0; i < layerlevel19.length; i++) {
        oldTotalBalance = oldTotalBalance + layerlevel19[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerlevel19.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[0], layerlevel19[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[level19 end]====================");

    const tokamak1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033";

    const layertokamak = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+tokamak1Addr+".json"));

    console.log("===================[tokamak start]====================");
    for (i = 0; i < layertokamak.length; i++) {
        oldTotalBalance = oldTotalBalance + layertokamak[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layertokamak.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[1], layertokamak[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[tokamak end]====================");

    const hammerDAOAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764";

    const layerHammerDAO = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+hammerDAOAddr+".json"));

    console.log("===================[hammerDAO start]====================");
    for (i = 0; i < layerHammerDAO.length; i++) {
        oldTotalBalance = oldTotalBalance + layerHammerDAO[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerHammerDAO.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[2], layerHammerDAO[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[hammerDAO end]====================");

    const DXMCorpAddr = "0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c";

    const layerDXMCorp = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+DXMCorpAddr+".json"));

    console.log("===================[DXMCorp start]====================");
    for (i = 0; i < layerDXMCorp.length; i++) {
        oldTotalBalance = oldTotalBalance + layerDXMCorp[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerDXMCorp.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[3], layerDXMCorp[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[DXMCorp end]====================");


    const danalFintechAddr = "0x97d0a5880542ab0e699c67e7f4ff61f2e5200484"

    const layerdanalFintech = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+danalFintechAddr+".json"));

    console.log("===================[danalFintech start]====================");
    for (i = 0; i < layerdanalFintech.length; i++) {
        oldTotalBalance = oldTotalBalance + layerdanalFintech[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerdanalFintech.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[4], layerdanalFintech[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[danalFintech end]====================");
    
    const DeSpreadAddr = "0x2000fc16911fc044130c29c1aa49d3e0b101716a";

    const layerDeSpread = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+DeSpreadAddr+".json"));

    console.log("===================[DeSpread start]====================");
    for (i = 0; i < layerDeSpread.length; i++) {
        oldTotalBalance = oldTotalBalance + layerDeSpread[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerDeSpread.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[5], layerDeSpread[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[DeSpread end]====================");

    const decipherAddr = "0x17602823b5fe43a65ad7122946a73b019e77fd33"

    const layerdecipher = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+decipherAddr+".json"));

    console.log("===================[decipher start]====================");
    for (i = 0; i < layerdecipher.length; i++) {
        oldTotalBalance = oldTotalBalance + layerdecipher[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerdecipher.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[6], layerdecipher[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[decipher end]====================");

    const TalkenAddr = "0xb9d336596ea2662488641c4ac87960bfdcb94c6e";

    const layerTalken = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+TalkenAddr+".json"));

    console.log("===================[Talken start]====================");
    for (i = 0; i < layerTalken.length; i++) {
        oldTotalBalance = oldTotalBalance + layerTalken[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerTalken.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[7], layerTalken[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[Talken end]====================");

    const DSRVAddr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66";

    const layerDSRV = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+DSRVAddr+".json"));

    console.log("===================[DSRV start]====================");
    for (i = 0; i < layerDSRV.length; i++) {
        oldTotalBalance = oldTotalBalance + layerDSRV[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerDSRV.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[8], layerDSRV[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[DSRV end]====================");

    const stakedAddr = "0xcc38c7aaf2507da52a875e93f57451e58e8c6372";

    const layerstaked = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+stakedAddr+".json"));

    console.log("===================[staked start]====================");
    for (i = 0; i < layerstaked.length; i++) {
        oldTotalBalance = oldTotalBalance + layerstaked[i].balance
    }
    if (oldTotalBalance == newTotalBalance) {
        console.log("===============DATA ERROR================")
    }
    for (i = 0; i < layerstaked.length; i++) {
        let balance = await seigManager["stakeOf(address,address)"](newLayerAddr[9], layerstaked[i].account)
        newTotalBalance = newTotalBalance + balance
    }
    if(oldTotalBalance != newTotalBalance) {
        console.log("===============totalBalance ERROR================")
        console.log(oldTotalBalance)
        console.log(newTotalBalance)
    }
    console.log("===================[staked end]====================");
}

async function main() {
    await totalStakingUserBalance();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });