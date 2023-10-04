import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from 'hardhat'

import DepositManager_Json from '../abi/DepositManager.json'
import DAOCommitteeProxy_Json from '../abi/DAOCommitteeProxy.json'

const fs = require('fs');

let layer2Info_level19 : any;
let layer2Info_tokamak : any;
let layer2Info_hammerDAO : any;

let DAOCommitteeProxy = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26";

async function enterLayer2() {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)
    
    // const [deployer2, addr1, addr2 ] = await ethers.getSigners();
    // const { deployer } = await hre.getNamedAccounts();
    // const { deploy } = hre.deployments;

    // const deploySigner = await hre.ethers.getSigner(deployer);

    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    const level19AdminAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    await hre.network.provider.send("hardhat_impersonateAccount", [
        level19AdminAddress,
    ]);
    const level19Admin = await hre.ethers.getSigner(level19AdminAddress);
    
    const DaoCommitteeAdminAddress = "0xb4983da083a5118c903910db4f5a480b1d9f3687"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        DaoCommitteeAdminAddress,
    ]);
    const daoCommitteeAdmin = await hre.ethers.getSigner(DaoCommitteeAdminAddress);

    const daoCommittee = await ethers.getContractAt("DAOCommitteeExtend", DAOCommitteeProxy, deployer)

    layer2Info_level19 = {
        operatorAdmin: level19AdminAddress,
        isLayer2Candidate: false,
        name: "level19_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    const receipt = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_level19.name,
        layer2Info_level19.operatorAdmin,
    )).wait()

    const topic = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    const deployedEvent = daoCommittee.interface.parseLog(log);
    layer2Info_level19.layer2 =  deployedEvent.args.candidateContract;
    layer2Info_level19.operator =  deployedEvent.args.candidate;
    console.log(deployedEvent.args.memo)
    console.log(layer2Info_level19.name)
    console.log("layer2Info_level19.layer2 :", layer2Info_level19.layer2);
    console.log(layer2Info_level19.operator)
    console.log(layer2Info_level19.operatorAdmin)
}

async function deposit() {

}


async function main() {
    await enterLayer2();
    await deposit();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });