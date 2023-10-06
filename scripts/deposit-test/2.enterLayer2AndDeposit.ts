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

async function enterLayer2() {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)
    
    // const [deployer2, addr1, addr2 ] = await ethers.getSigners();
    // const { deployer } = await hre.getNamedAccounts();
    // const { deploy } = hre.deployments;

    // const deploySigner = await hre.ethers.getSigner(deployer);
    const newLayer2s = []

    const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    
    await hre.network.provider.send("hardhat_impersonateAccount", [
        deployerAddress,
    ]);
    const deployer = await hre.ethers.getSigner(deployerAddress);

    //--------------level19-----------------1
    const level19AdminAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    
    await hre.network.provider.send("hardhat_impersonateAccount", [
        level19AdminAddress,
    ]);
    const level19Admin = await hre.ethers.getSigner(level19AdminAddress);

    //--------------tokamak1-----------------2
    const tokamakAdminAddress = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
    
    await hre.network.provider.send("hardhat_impersonateAccount", [
        tokamakAdminAddress,
    ]);
    const tokamakAdmin = await hre.ethers.getSigner(tokamakAdminAddress);

    //--------------hammerDAO-----------------3
    const hammerAdminAddress = "0x90F79bf6EB2c4f870365E785982E1f101E93b906"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        hammerAdminAddress,
    ]);
    const hammerAdmin = await hre.ethers.getSigner(hammerAdminAddress);

    //--------------DXMCorp-----------------4
    const DXMCorpAdminAddress = "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        DXMCorpAdminAddress,
    ]);
    const DXMCorpAdmin = await hre.ethers.getSigner(DXMCorpAdminAddress);

    //--------------danalFintech-----------------5
    const danalFintechAdminAddress = "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        danalFintechAdminAddress,
    ]);
    const danalFintechAdmin = await hre.ethers.getSigner(danalFintechAdminAddress);

    //--------------DeSpread-----------------6
    const DeSpreadAdminAddress = "0x976EA74026E726554dB657fA54763abd0C3a0aa9"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        DeSpreadAdminAddress,
    ]);
    const DeSpreadAdmin = await hre.ethers.getSigner(DeSpreadAdminAddress);

    //--------------decipher-----------------7
    const decipherAdminAddress = "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        decipherAdminAddress,
    ]);
    const decipherAdmin = await hre.ethers.getSigner(decipherAdminAddress);

    //--------------Talken-----------------8
    const TalkenAdminAddress = "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        TalkenAdminAddress,
    ]);
    const TalkenAdmin = await hre.ethers.getSigner(TalkenAdminAddress);

    //--------------DSRV-----------------9
    const DSRVAdminAddress = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        DSRVAdminAddress,
    ]);
    const DSRVAdmin = await hre.ethers.getSigner(DSRVAdminAddress);

    //--------------staked-----------------10
    const stakedAdminAddress = "0xBcd4042DE499D14e55001CcbB24a551F3b954096"

    await hre.network.provider.send("hardhat_impersonateAccount", [
        stakedAdminAddress,
    ]);
    const stakedAdmin = await hre.ethers.getSigner(stakedAdminAddress);
    
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

    layer2Info_tokamak = {
        operatorAdmin: tokamakAdminAddress,
        isLayer2Candidate: false,
        name: "level19_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_hammerDAO = {
        operatorAdmin: hammerAdminAddress,
        isLayer2Candidate: false,
        name: "hammerDAO_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_DXMCorp = {
        operatorAdmin: DXMCorpAdminAddress,
        isLayer2Candidate: false,
        name: "DXMCorp_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_danalFintech = {
        operatorAdmin: danalFintechAdminAddress,
        isLayer2Candidate: false,
        name: "danalFintech_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_DeSpread = {
        operatorAdmin: DeSpreadAdminAddress,
        isLayer2Candidate: false,
        name: "DeSpread_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_decipher = {
        operatorAdmin: decipherAdminAddress,
        isLayer2Candidate: false,
        name: "DeSpread_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_Talken = {
        operatorAdmin: TalkenAdminAddress,
        isLayer2Candidate: false,
        name: "Talken_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_DSRV = {
        operatorAdmin: DSRVAdminAddress,
        isLayer2Candidate: false,
        name: "DSRV_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    layer2Info_staked = {
        operatorAdmin: stakedAdminAddress,
        isLayer2Candidate: false,
        name: "staked_V2",
        committee: daoCommittee.address,
        layer2: null,
        operator: null,
        layerContract: null,
        coinageContract: null
    }

    const receipt1 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_level19.name,
        layer2Info_level19.operatorAdmin,
    )).wait()

    const topic = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log = receipt1.logs.find(x => x.topics.indexOf(topic) >= 0);
    const deployedEvent = daoCommittee.interface.parseLog(log);
    layer2Info_level19.layer2 = deployedEvent.args.candidateContract;
    layer2Info_level19.operator = deployedEvent.args.candidate;
    // console.log(deployedEvent.args.memo)
    // console.log(layer2Info_level19.name)
    console.log("layer2Info_level19.layer2 :", layer2Info_level19.layer2);
    newLayer2s.push(layer2Info_level19.layer2)
    // console.log(layer2Info_level19.operator)
    // console.log(layer2Info_level19.operatorAdmin)

    const receipt2 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_tokamak.name,
        layer2Info_tokamak.operatorAdmin,
    )).wait()

    const topic2 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log2 = receipt2.logs.find(x => x.topics.indexOf(topic2) >= 0);
    const deployedEvent2 = daoCommittee.interface.parseLog(log2);
    layer2Info_tokamak.layer2 = deployedEvent2.args.candidateContract;
    layer2Info_tokamak.operator = deployedEvent2.args.candidate;
    console.log("layer2Info_tokamak.layer2 :", layer2Info_tokamak.layer2);
    newLayer2s.push(layer2Info_tokamak.layer2)

    const receipt3 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_hammerDAO.name,
        layer2Info_hammerDAO.operatorAdmin,
    )).wait()

    const topic3 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log3 = receipt3.logs.find(x => x.topics.indexOf(topic3) >= 0);
    const deployedEvent3 = daoCommittee.interface.parseLog(log3);
    layer2Info_hammerDAO.layer2 = deployedEvent3.args.candidateContract;
    layer2Info_hammerDAO.operator = deployedEvent3.args.candidate;
    console.log("layer2Info_hammerDAO.layer2 :", layer2Info_hammerDAO.layer2);
    newLayer2s.push(layer2Info_hammerDAO.layer2)

    const receipt4 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_DXMCorp.name,
        layer2Info_DXMCorp.operatorAdmin,
    )).wait()

    const topic4 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log4 = receipt4.logs.find(x => x.topics.indexOf(topic4) >= 0);
    const deployedEvent4 = daoCommittee.interface.parseLog(log4);
    layer2Info_DXMCorp.layer2 = deployedEvent4.args.candidateContract;
    layer2Info_DXMCorp.operator = deployedEvent4.args.candidate;
    console.log("layer2Info_DXMCorp.layer2 :", layer2Info_DXMCorp.layer2);
    newLayer2s.push(layer2Info_DXMCorp.layer2)

    const receipt5 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_danalFintech.name,
        layer2Info_danalFintech.operatorAdmin,
    )).wait()

    const topic5 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log5 = receipt5.logs.find(x => x.topics.indexOf(topic5) >= 0);
    const deployedEvent5 = daoCommittee.interface.parseLog(log5);
    layer2Info_danalFintech.layer2 = deployedEvent5.args.candidateContract;
    layer2Info_danalFintech.operator = deployedEvent5.args.candidate;
    console.log("layer2Info_danalFintech.layer2 :", layer2Info_danalFintech.layer2);
    newLayer2s.push(layer2Info_danalFintech.layer2)

    const receipt6 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_DeSpread.name,
        layer2Info_DeSpread.operatorAdmin,
    )).wait()

    const topic6 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log6 = receipt6.logs.find(x => x.topics.indexOf(topic6) >= 0);
    const deployedEvent6 = daoCommittee.interface.parseLog(log6);
    layer2Info_DeSpread.layer2 = deployedEvent6.args.candidateContract;
    layer2Info_DeSpread.operator = deployedEvent6.args.candidate;
    console.log("layer2Info_DeSpread.layer2 :", layer2Info_DeSpread.layer2);
    newLayer2s.push(layer2Info_DeSpread.layer2)

    const receipt7 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_decipher.name,
        layer2Info_decipher.operatorAdmin,
    )).wait()

    const topic7 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log7 = receipt7.logs.find(x => x.topics.indexOf(topic7) >= 0);
    const deployedEvent7 = daoCommittee.interface.parseLog(log7);
    layer2Info_decipher.layer2 = deployedEvent7.args.candidateContract;
    layer2Info_decipher.operator = deployedEvent7.args.candidate;
    console.log("layer2Info_decipher.layer2 :", layer2Info_decipher.layer2);
    newLayer2s.push(layer2Info_decipher.layer2)

    const receipt8 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_Talken.name,
        layer2Info_Talken.operatorAdmin,
    )).wait()

    const topic8 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log8 = receipt8.logs.find(x => x.topics.indexOf(topic8) >= 0);
    const deployedEvent8 = daoCommittee.interface.parseLog(log8);
    layer2Info_Talken.layer2 = deployedEvent8.args.candidateContract;
    layer2Info_Talken.operator = deployedEvent8.args.candidate;
    console.log("layer2Info_Talken.layer2 :", layer2Info_Talken.layer2);
    newLayer2s.push(layer2Info_Talken.layer2)

    const receipt9 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_DSRV.name,
        layer2Info_DSRV.operatorAdmin,
    )).wait()

    const topic9 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log9 = receipt9.logs.find(x => x.topics.indexOf(topic9) >= 0);
    const deployedEvent9 = daoCommittee.interface.parseLog(log9);
    layer2Info_DSRV.layer2 = deployedEvent9.args.candidateContract;
    layer2Info_DSRV.operator = deployedEvent9.args.candidate;
    console.log("layer2Info_DSRV.layer2 :", layer2Info_DSRV.layer2);
    newLayer2s.push(layer2Info_DSRV.layer2)

    const receipt10 = await (await daoCommittee.connect(
        daoCommitteeAdmin
    )["createCandidate(string,address)"](
        layer2Info_staked.name,
        layer2Info_staked.operatorAdmin,
    )).wait()

    const topic10 = daoCommittee.interface.getEventTopic('CandidateContractCreated');
    const log10 = receipt10.logs.find(x => x.topics.indexOf(topic10) >= 0);
    const deployedEvent10 = daoCommittee.interface.parseLog(log10);
    layer2Info_staked.layer2 = deployedEvent10.args.candidateContract;
    layer2Info_staked.operator = deployedEvent10.args.candidate;
    console.log("layer2Info_staked.layer2 :", layer2Info_staked.layer2);
    newLayer2s.push(layer2Info_staked.layer2)

    await fs.writeFileSync("./data/newlayer2s.json", JSON.stringify(newLayer2s));
}

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

    const layerHammerDAO = JSON.parse(await fs.readFileSync("./data/layer2-accounts-balances/0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764.json"));
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