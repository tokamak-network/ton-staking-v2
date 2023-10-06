import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from 'hardhat'

import DepositManager_Json from '../../abi/DepositManager.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'

const fs = require('fs');

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

let DAOCommitteeProxy = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26";

async function level19() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)
    const level19Addr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52";

    const layerlevel19 = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+level19Addr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const level19depositors = [];
    const level19amounts = [];

    for (let i = 0; i < layerlevel19.length; i++) {
        if(layerlevel19[i].balance == 0){
            continue;
        } 
        level19depositors.push(layerlevel19[i].account);
        level19amounts.push(layerlevel19[i].balance);
    }
    // console.log(level19depositors)
    // console.log(level19amounts)
    // console.log(newLayerAddr)
    console.log("level19 start")
    console.log("length :", layerlevel19.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[0],level19depositors,level19amounts);
    console.log("level19 end")
    //check
    for (let i = 0; i < layerlevel19.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[0],layerlevel19[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerlevel19[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function tokamak() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const tokamak1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033";

    const layertokamak = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+tokamak1Addr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layertokamak.length; i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors.push(layertokamak[i].account);
        amounts.push(layertokamak[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    console.log("tokamak start")
    console.log("length :", layertokamak.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors,amounts);
    console.log("tokamak end")
    //check
    for (let i = 0; i < layertokamak.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[1],layertokamak[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layertokamak[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function hammerDAO() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const hammerDAOAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764";

    const layerHammerDAO = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+hammerDAOAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerHammerDAO.length; i++) {
        if(layerHammerDAO[i].balance == 0){
            continue;
        } 
        depositors.push(layerHammerDAO[i].account);
        amounts.push(layerHammerDAO[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    console.log("hammerDAO start")
    console.log("length :", layerHammerDAO.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[2],depositors,amounts);
    console.log("hammerDAO end")
    //check
    for (let i = 0; i < layerHammerDAO.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[2],layerHammerDAO[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerHammerDAO[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function DXMCorp() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const DXMCorpAddr = "0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c";

    const layerDXMCorp = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+DXMCorpAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerDXMCorp.length; i++) {
        if(layerDXMCorp[i].balance == 0){
            continue;
        } 
        depositors.push(layerDXMCorp[i].account);
        amounts.push(layerDXMCorp[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)

    console.log("DXMCorp start")
    console.log("length :", layerDXMCorp.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[3],depositors,amounts);
    console.log("DXMCorp end")

    //check
    for (let i = 0; i < layerDXMCorp.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[3],layerDXMCorp[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerDXMCorp[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function danalFintech() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const danalFintechAddr = "0x97d0a5880542ab0e699c67e7f4ff61f2e5200484"

    const layerdanalFintech = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+danalFintechAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerdanalFintech.length; i++) {
        if(layerdanalFintech[i].balance == 0){
            continue;
        } 
        depositors.push(layerdanalFintech[i].account);
        amounts.push(layerdanalFintech[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    
    console.log("danalFintech start")
    console.log("length :", layerdanalFintech.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[4],depositors,amounts);
    console.log("danalFintech end")

    //check
    for (let i = 0; i < layerdanalFintech.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[4],layerdanalFintech[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerdanalFintech[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function DeSpread() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const DeSpreadAddr = "0x2000fc16911fc044130c29c1aa49d3e0b101716a";

    const layerDeSpread = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+DeSpreadAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerDeSpread.length; i++) {
        if(layerDeSpread[i].balance == 0){
            continue;
        } 
        depositors.push(layerDeSpread[i].account);
        amounts.push(layerDeSpread[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    
    console.log("DeSpread start")
    console.log("length :", layerDeSpread.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[5],depositors,amounts);
    console.log("DeSpread end")

    //check
    for (let i = 0; i < layerDeSpread.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[5],layerDeSpread[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerDeSpread[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function decipher() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const decipherAddr = "0x17602823b5fe43a65ad7122946a73b019e77fd33"

    const layerdecipher = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+decipherAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerdecipher.length; i++) {
        if(layerdecipher[i].balance == 0){
            continue;
        } 
        depositors.push(layerdecipher[i].account);
        amounts.push(layerdecipher[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    
    console.log("decipher start")
    console.log("length :", layerdecipher.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[6],depositors,amounts);
    console.log("decipher end")

    //check
    for (let i = 0; i < layerdecipher.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[6],layerdecipher[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerdecipher[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function Talken() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const TalkenAddr = "0xb9d336596ea2662488641c4ac87960bfdcb94c6e";

    const layerTalken = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+TalkenAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerTalken.length; i++) {
        if(layerTalken[i].balance == 0){
            continue;
        } 
        depositors.push(layerTalken[i].account);
        amounts.push(layerTalken[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    
    console.log("Talken start")
    console.log("length :", layerTalken.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[7],depositors,amounts);
    console.log("Talken end")

    //check
    for (let i = 0; i < layerTalken.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[7],layerTalken[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerTalken[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function DSRV() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const DSRVAddr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66";

    const layerDSRV = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+DSRVAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerDSRV.length; i++) {
        if(layerDSRV[i].balance == 0){
            continue;
        } 
        depositors.push(layerDSRV[i].account);
        amounts.push(layerDSRV[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    
    console.log("DSRV start")
    console.log("length :", layerDSRV.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[8],depositors,amounts);
    console.log("DSRV end")

    //check
    for (let i = 0; i < layerDSRV.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[8],layerDSRV[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerDSRV[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}

async function staked() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    const stakedAddr = "0xcc38c7aaf2507da52a875e93f57451e58e8c6372";

    const layerstaked = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+stakedAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));
    
    const depositors = [];
    const amounts = [];

    for (let i = 0; i < layerstaked.length; i++) {
        if(layerstaked[i].balance == 0){
            continue;
        } 
        depositors.push(layerstaked[i].account);
        amounts.push(layerstaked[i].balance);
    }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    
    console.log("staked start")
    console.log("length :", layerstaked.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[9],depositors,amounts);
    console.log("staked end")

    //check
    for (let i = 0; i < layerstaked.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[9],layerstaked[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerstaked[i].balance) {
            console.log("=====================[",i,"] error====================");
            break;
        }
    }
}


async function main() {
    // await enterLayer2();
    // await deposit();
    await level19();
    await tokamak();
    await hammerDAO();
    await DXMCorp();
    await danalFintech();
    await DeSpread();
    await decipher();
    await Talken();
    await DSRV();
    await staked();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });