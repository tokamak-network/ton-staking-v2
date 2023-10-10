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

async function totalStakingBalanceCheck() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    let contractInfos = await readContracts(__dirname+'/../../deployments/'+networkName);
    const depositManager = new ethers.Contract(
        contractInfos.abis["DepositManagerProxy"].address,
        contractInfos.abis["DepositManagerForMigration"].abi,
        deployer
    )

    const oldDepositManager = new ethers.Contract(
        oldContractInfo.DepositManager,
        contractInfos.abis["DepositManager"].abi,
        deployer
    )

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
    
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));

    let i;
    let newBalance;
    let oldBalance;
    console.log("===================[level19 start]====================");
    
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[0]);
    oldBalance = await oldDepositManager.accStakedLayer2(level19Addr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[level19 ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[level19 ERROR] ====================");
    }
    console.log("===================[level19 end]====================");

    console.log("===================[tokamak start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[1]);
    oldBalance = await oldDepositManager.accStakedLayer2(tokamak1Addr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[tokamak ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[tokamak ERROR] ====================");
    }
    console.log("===================[tokamak end]====================");

    console.log("===================[hammerDAO start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[2]);
    oldBalance = await oldDepositManager.accStakedLayer2(hammerDAOAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[hammerDAO ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[hammerDAO ERROR] ====================");
    }
    console.log("===================[hammerDAO end]====================");

    console.log("===================[DXMCorp start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[3]);
    oldBalance = await oldDepositManager.accStakedLayer2(DXMCorpAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[DXMCorp ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[DXMCorp ERROR] ====================");
    }
    console.log("===================[DXMCorp end]====================");

    console.log("===================[danalFintech start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[4]);
    oldBalance = await oldDepositManager.accStakedLayer2(danalFintechAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[danalFintech ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[danalFintech ERROR] ====================");
    }
    console.log("===================[danalFintech end]====================");

    console.log("===================[DeSpread start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[5]);
    oldBalance = await oldDepositManager.accStakedLayer2(DeSpreadAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[DeSpread ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[DeSpread ERROR] ====================");
    }
    console.log("===================[DeSpread end]====================");

    console.log("===================[decipher start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[6]);
    oldBalance = await oldDepositManager.accStakedLayer2(decipherAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[decipher ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[decipher ERROR] ====================");
    }
    console.log("===================[decipher end]====================");

    console.log("===================[Talken start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[7]);
    oldBalance = await oldDepositManager.accStakedLayer2(TalkenAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[Talken ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[Talken ERROR] ====================");
    }
    console.log("===================[Talken end]====================");

    console.log("===================[DSRV start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[8]);
    oldBalance = await oldDepositManager.accStakedLayer2(DSRVAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[DSRV ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[DSRV ERROR] ====================");
    }
    console.log("===================[DSRV end]====================");

    console.log("===================[staked start]====================");
    newBalance = await depositManager.accStakedLayer2(newLayerAddr[9]);
    oldBalance = await oldDepositManager.accStakedLayer2(stakedAddr);
    if(!newBalance.eq(oldBalance)) {
        console.log("=====================[staked ERROR] ====================");
        console.log(oldBalance);
        console.log(newBalance);
        console.log("=====================[staked ERROR] ====================");
    }
    console.log("===================[staked end]====================");
}

async function main() {
    await totalStakingBalanceCheck();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });