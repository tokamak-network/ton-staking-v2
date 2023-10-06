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

async function deposit() {
    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const DaoCommitteeAdminAddress = "0xb4983da083a5118c903910db4f5a480b1d9f3687"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        DaoCommitteeAdminAddress,
    ]);
    const daoCommitteeAdmin = await hre.ethers.getSigner(DaoCommitteeAdminAddress);

    const daoCommittee = await ethers.getContractAt("DAOCommitteeExtend", DAOCommitteeProxy, deployer)

    const depositManagerProxy = JSON.parse(await fs.readFileSync("./deployments/localhost/DepositManagerProxy.json"));
    // console.log("depositManagerProxy.address :", depositManagerProxy.address);
    const depositManagerForMigration = await ethers.getContractAt("DepositManagerForMigration", depositManagerProxy.address, deployer)

    //staked, Talken, DXM Corp in exist mainnet L1
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

    //level19 deposit
    const layerlevel19 = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+level19Addr+".json"));

    // const layerHammerDAO = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764.json"));
    const layerHammerDAO = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/"+hammerDAOAddr+".json"));
    const newLayerAddr = JSON.parse(await fs.readFileSync("./data/newlayer2s.json"));

    const hammerDAOdepositors = [];
    const hammerDAOamounts = [];

    for (let i = 0; i < layerHammerDAO.length; i++) {
        if(layerHammerDAO[i].balance == 0){
            continue;
        } 
        hammerDAOdepositors.push(layerHammerDAO[i].account);
        hammerDAOamounts.push(layerHammerDAO[i].balance);
    }
    console.log(hammerDAOdepositors)
    console.log(hammerDAOamounts)
    console.log(newLayerAddr)
    console.log(newLayerAddr[2])

    console.log("error point1")
    await depositManagerForMigration.connect(deployer).depositWithoutTransfer(newLayerAddr[2],hammerDAOdepositors,hammerDAOamounts);
    console.log("error point2")
    for (let i = 0; i < layerHammerDAO.length; i++) {
        let tx = await depositManagerForMigration.accStaked(hammerDAOAddr,layerHammerDAO[i].account)
        if(Number(tx) == 0) {
            console.log("=====================[",i,"] pass====================");
            continue;
        }
        if(tx != layerHammerDAO[i].balance) {
            console.log("=====================error====================");
            break;
        }
    }
    
}


async function main() {
    // await enterLayer2();
    await deposit();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });