import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from 'hardhat'

import DepositManager_Json from '../../abi/DepositManager.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'

const fs = require('fs');

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
const DaoCommitteeAdminAddress = "0xb4983da083a5118c903910db4f5a480b1d9f3687"

async function enterLayer2() {
    /* layer 등록 순서
        1. level19
        2. tokamak
        3. hammerDAO
        4. DXMCorp
        5. danalFintech
        6. DeSpread
        7. decipher
        8. Talken
        9. DSRV
        10. staked
    */

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


    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const candidateABI = JSON.parse(await fs.readFileSync("./abi/Candidate.json")).abi;
    const layer2RegistryABI = JSON.parse(await fs.readFileSync("./abi/layer2Registry.json")).abi;
    const seigManagerABI = JSON.parse(await fs.readFileSync("./abi/seigManager.json")).abi;

    const layer2Registry = new ethers.Contract(
        oldContractInfo.Layer2Registry,
        layer2RegistryABI,
        ethers.provider
      );
    
    const seigManager = new ethers.Contract(
        oldContractInfo.SeigManager,
        seigManagerABI,
        ethers.provider
    );
    
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
    let coinageAddress = await seigManager.coinages(level19Addr)

    let layerContract = new ethers.Contract(
        level19Addr,
        candidateABI,
        ethers.provider
    );
    let operatorAddress = await layerContract.operator()
    const level19AdminAddress = operatorAddress

    //--------------tokamak1-----------------2

    // let coinageAddress = await seigManager.coinages(tokamak1Addr)

    layerContract = new ethers.Contract(
        tokamak1Addr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const tokamakAdminAddress = operatorAddress
    
    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     tokamakAdminAddress,
    // ]);
    // const tokamakAdmin = await hre.ethers.getSigner(tokamakAdminAddress);

    //--------------hammerDAO-----------------3

    layerContract = new ethers.Contract(
        hammerDAOAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const hammerAdminAddress = operatorAddress

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     hammerAdminAddress,
    // ]);
    // const hammerAdmin = await hre.ethers.getSigner(hammerAdminAddress);

    //--------------DXMCorp-----------------4

    layerContract = new ethers.Contract(
        DXMCorpAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const DXMCorpAdminAddress = operatorAddress

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     DXMCorpAdminAddress,
    // ]);
    // const DXMCorpAdmin = await hre.ethers.getSigner(DXMCorpAdminAddress);

    //--------------danalFintech-----------------5

    layerContract = new ethers.Contract(
        danalFintechAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const danalFintechAdminAddress = operatorAddress


    // const danalFintechAdminAddress = "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     danalFintechAdminAddress,
    // ]);
    // const danalFintechAdmin = await hre.ethers.getSigner(danalFintechAdminAddress);

    //--------------DeSpread-----------------6

    layerContract = new ethers.Contract(
        DeSpreadAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const DeSpreadAdminAddress = operatorAddress

    // const DeSpreadAdminAddress = "0x976EA74026E726554dB657fA54763abd0C3a0aa9"

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     DeSpreadAdminAddress,
    // ]);
    // const DeSpreadAdmin = await hre.ethers.getSigner(DeSpreadAdminAddress);

    //--------------decipher-----------------7

    layerContract = new ethers.Contract(
        decipherAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const decipherAdminAddress = operatorAddress

    // const decipherAdminAddress = "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955"

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     decipherAdminAddress,
    // ]);
    // const decipherAdmin = await hre.ethers.getSigner(decipherAdminAddress);

    //--------------Talken-----------------8

    layerContract = new ethers.Contract(
        TalkenAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const TalkenAdminAddress = operatorAddress

    
    // const TalkenAdminAddress = "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f"

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     TalkenAdminAddress,
    // ]);
    // const TalkenAdmin = await hre.ethers.getSigner(TalkenAdminAddress);

    //--------------DSRV-----------------9

    layerContract = new ethers.Contract(
        DSRVAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const DSRVAdminAddress = operatorAddress


    // const DSRVAdminAddress = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     DSRVAdminAddress,
    // ]);
    // const DSRVAdmin = await hre.ethers.getSigner(DSRVAdminAddress);

    //--------------staked-----------------10

    layerContract = new ethers.Contract(
        stakedAddr,
        candidateABI,
        ethers.provider
    );
    operatorAddress = await layerContract.operator()

    const stakedAdminAddress = operatorAddress


    // const stakedAdminAddress = "0xBcd4042DE499D14e55001CcbB24a551F3b954096"

    // await hre.network.provider.send("hardhat_impersonateAccount", [
    //     stakedAdminAddress,
    // ]);
    // const stakedAdmin = await hre.ethers.getSigner(stakedAdminAddress);


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
    await enterLayer2();
    // await deposit();
}
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });