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
    const depositors2 = [];
    const amounts2 = [];
    
    const depositors3 = [];
    const amounts3 = [];

    const depositors4 = [];
    const amounts4 = [];
    
    const lengthstandard = 100

    if(layerlevel19.length >= lengthstandard) {
        for (let i = 0; i < lengthstandard; i++) {
            if(layerlevel19[i].balance == 0){
                continue;
            } 
            level19depositors.push(layerlevel19[i].account);
            level19amounts.push(layerlevel19[i].balance);
        }

        for (let j = lengthstandard; j < layerlevel19.length; j++) {
            if(layerlevel19[j].balance == 0){
                continue;
            } 
            depositors2.push(layerlevel19[j].account);
            amounts2.push(layerlevel19[j].balance);
        }
    } else {
        for (let i = 0; i < layerlevel19.length; i++) {
            if(layerlevel19[i].balance == 0){
                continue;
            } 
            level19depositors.push(layerlevel19[i].account);
            level19amounts.push(layerlevel19[i].balance);
        }

    }

    // for (let i = 0; i < lengthstandard; i++) {
    //     if(layerlevel19[i].balance == 0){
    //         continue;
    //     } 
    //     level19depositors.push(layerlevel19[i].account);
    //     level19amounts.push(layerlevel19[i].balance);
    // }

    // for (let j = lengthstandard; j < (lengthstandard*2); j++) {
    //     if(layerlevel19[j].balance == 0){
    //         continue;
    //     } 
    //     depositors2.push(layerlevel19[j].account);
    //     amounts2.push(layerlevel19[j].balance);
    // }

    // for (let k = (lengthstandard*2); k < (lengthstandard*3); k++) {
    //     if(layerlevel19[k].balance == 0){
    //         continue;
    //     } 
    //     depositors3.push(layerlevel19[k].account);
    //     amounts3.push(layerlevel19[k].balance);
    // }

    // for (let l = (lengthstandard*3); l < layerlevel19.length; l++) {
    //     if(layerlevel19[l].balance == 0){
    //         continue;
    //     } 
    //     depositors4.push(layerlevel19[l].account);
    //     amounts4.push(layerlevel19[l].balance);
    // }

    
    // console.log(level19depositors)
    // console.log(level19amounts)
    // console.log(newLayerAddr)
    console.log("level19 start")
    console.log("length :", layerlevel19.length)
    console.log("depositors.length :", level19depositors.length)
    console.log("depositors2.length :", depositors2.length)
    console.log("depositors3.length :", depositors3.length)
    console.log("depositors4.length :", depositors4.length)
    //before input
    for (let i = 0; i < layerlevel19.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[0],layerlevel19[i].account)
        if(Number(tx) == 0) {
            // console.log("=====================[",i,"] PASS ====================");
            continue;
        } else {
            break;
        }
    }


    if(layerlevel19.length >= lengthstandard) {
        console.log("1")
        await (
            await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[0],level19depositors,level19amounts)
        ).wait();
        console.log("2")
        await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[0],depositors2,amounts2);
        console.log("3")
        // await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[0],depositors3,amounts3);
        // console.log("4")
        // await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[0],depositors4,amounts4);
        // console.log("5")
    } else {
        await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[0],level19depositors,level19amounts);
    }
    console.log("level19 end")
    //check
    for (let i = 0; i < layerlevel19.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[0],layerlevel19[i].account)
        // console.log("layerlevel19.account : ", layerlevel19[i].account)
        // console.log("layerlevel19.amount : ", layerlevel19[i].balance)
        // console.log("depositAmount :  ", tx);
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerlevel19[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    
    const lengthstandard = 40

    const depositors = [];
    const amounts = [];

    const depositors2 = [];
    const amounts2 = [];

    const depositors3 = [];
    const amounts3 = [];

    const depositors4 = [];
    const amounts4 = [];

    const depositors5 = [];
    const amounts5 = [];

    const depositors6 = [];
    const amounts6 = [];

    const depositors7 = [];
    const amounts7 = [];

    const depositors8 = [];
    const amounts8 = [];

    const depositors9 = [];
    const amounts9 = [];

    const depositors10 = [];
    const amounts10 = [];

    let i
    // console.log("1");
    for (i = 0; i < lengthstandard; i++) {
        // console.log("============== [", i, "] ==============")
        // console.log(layertokamak[i].account)
        // console.log(layertokamak[i].balance)
        if(layertokamak[i].balance == 0){
            continue;
        } 
        // console.log("============== [", i, "] ==============")
        depositors.push(layertokamak[i].account);
        amounts.push(layertokamak[i].balance);
    }
    for (i = lengthstandard; i < (lengthstandard*2); i++) {
        // console.log("============== [", i, "] ==============")
        // console.log(layertokamak[i].account)
        // console.log(layertokamak[i].balance)
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors2.push(layertokamak[i].account);
        amounts2.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*2); i < (lengthstandard*3); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors3.push(layertokamak[i].account);
        amounts3.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*3); i < (lengthstandard*4); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors4.push(layertokamak[i].account);
        amounts4.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*4); i < (lengthstandard*5); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors5.push(layertokamak[i].account);
        amounts5.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*5); i < (lengthstandard*6); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors6.push(layertokamak[i].account);
        amounts6.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*6); i < (lengthstandard*7); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors7.push(layertokamak[i].account);
        amounts7.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*7); i < (lengthstandard*8); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors8.push(layertokamak[i].account);
        amounts8.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*8); i < (lengthstandard*9); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors9.push(layertokamak[i].account);
        amounts9.push(layertokamak[i].balance);
    }
    for (i = (lengthstandard*9); i < (layertokamak.length); i++) {
        if(layertokamak[i].balance == 0){
            continue;
        } 
        depositors10.push(layertokamak[i].account);
        amounts10.push(layertokamak[i].balance);
    }

    // for (i = 0; i < layertokamak.length; i++) {
    //     if(layertokamak[i].balance == 0){
    //         continue;
    //     } 
    //     depositors.push(layertokamak[i].account);
    //     amounts.push(layertokamak[i].balance);
    // }
    
    //before input
    for (let i = 0; i < layertokamak.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[0],layertokamak[i].account)
        if(Number(tx) == 0) {
            continue;
        } else {
            break;
        }
    }

    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    console.log("tokamak start")
    console.log("length :", layertokamak.length)
    console.log("depositors.length :", depositors.length)
    console.log("depositors.length :", depositors2.length)
    console.log("depositors.length :", depositors3.length)
    console.log("depositors.length :", depositors4.length)
    console.log("depositors.length :", depositors5.length)
    console.log("depositors.length :", depositors6.length)
    console.log("depositors.length :", depositors7.length)
    console.log("depositors.length :", depositors8.length)
    console.log("depositors.length :", depositors9.length)
    console.log("depositors.length :", depositors10.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors,amounts);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors2,amounts2);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors3,amounts3);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors4,amounts4);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors5,amounts5);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors6,amounts6);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors7,amounts7);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors8,amounts8);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors9,amounts9);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[1],depositors10,amounts10);
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
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[2],depositors,amounts);
    console.log("hammerDAO end")
    //check
    for (let i = 0; i < layerHammerDAO.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[2],layerHammerDAO[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerHammerDAO[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[3],depositors,amounts);
    console.log("DXMCorp end")

    //check
    for (let i = 0; i < layerDXMCorp.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[3],layerDXMCorp[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerDXMCorp[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[4],depositors,amounts);
    console.log("danalFintech end")

    //check
    for (let i = 0; i < layerdanalFintech.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[4],layerdanalFintech[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerdanalFintech[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    
    const lengthstandard = 40

    const depositors = [];
    const amounts = [];

    const depositors2 = [];
    const amounts2 = [];

    let i
    for (i = 0; i < lengthstandard; i++) {
        // console.log("============== [", i, "] ==============")
        // console.log(layertokamak[i].account)
        // console.log(layertokamak[i].balance)
        if(layerDeSpread[i].balance == 0){
            continue;
        } 
        // console.log("============== [", i, "] ==============")
        depositors.push(layerDeSpread[i].account);
        amounts.push(layerDeSpread[i].balance);
    }
    for (i = lengthstandard; i < layerDeSpread.length; i++) {
        // console.log("============== [", i, "] ==============")
        // console.log(layertokamak[i].account)
        // console.log(layertokamak[i].balance)
        if(layerDeSpread[i].balance == 0){
            continue;
        } 
        depositors2.push(layerDeSpread[i].account);
        amounts2.push(layerDeSpread[i].balance);
    }

    // for (let i = 0; i < layerDeSpread.length; i++) {
    //     if(layerDeSpread[i].balance == 0){
    //         continue;
    //     } 
    //     depositors.push(layerDeSpread[i].account);
    //     amounts.push(layerDeSpread[i].balance);
    // }
    // console.log(depositors)
    // console.log(amounts)
    // console.log(newLayerAddr)
    
    console.log("DeSpread start")
    console.log("length :", layerDeSpread.length)
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[5],depositors,amounts);
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[5],depositors2,amounts2);
    console.log("DeSpread end")

    //check
    for (let i = 0; i < layerDeSpread.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[5],layerDeSpread[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerDeSpread[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[6],depositors,amounts);
    console.log("decipher end")

    //check
    for (let i = 0; i < layerdecipher.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[6],layerdecipher[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerdecipher[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[7],depositors,amounts);
    console.log("Talken end")

    //check
    for (let i = 0; i < layerTalken.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[7],layerTalken[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerTalken[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[8],depositors,amounts);
    console.log("DSRV end")

    //check
    for (let i = 0; i < layerDSRV.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[8],layerDSRV[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerDSRV[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
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
    console.log("depositors.length :", depositors.length)
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[9],depositors,amounts);
    console.log("staked end")

    //check
    for (let i = 0; i < layerstaked.length; i++) {
        let tx = await depositManagerForMigration.accStaked(newLayerAddr[9],layerstaked[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] PASS ====================");
            continue;
        }
        if(tx != layerstaked[i].balance) {
            console.log("=====================[",i,"] ERROR ====================");
            break;
        }
    }
}


async function main() {
    await level19();
    // await tokamak();
    // await hammerDAO();
    // await DXMCorp();
    // await danalFintech();
    // await DeSpread();
    // await decipher();
    // await Talken();
    // await DSRV();
    // await staked();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });