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
    newLayer2s.push(layer2Info_level19.layer2)
    console.log(layer2Info_level19.operator)
    console.log(layer2Info_level19.operatorAdmin)


    await fs.writeFileSync("./data/newlayer2s.json", JSON.stringify(newLayer2s));
}

async function deposit() {
    //staked, Talken, DXM Corp
    const hammerDAOAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764";
    const tokamak1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033";
    const DXMCorpAddr = "0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c";
    const level19Addr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52";
    const danalFintechAddr = "0x97d0a5880542ab0e699c67e7f4ff61f2e5200484"
    const DeSpreadAddr = "0x2000fc16911fc044130c29c1aa49d3e0b101716a";
    const decipherAddr = "0x17602823b5fe43a65ad7122946a73b019e77fd33"
    const TalkenAddr = "0xb9d336596ea2662488641c4ac87960bfdcb94c6e";
    const DSRVAddr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66";
    const stakedAddr = "0xcc38c7aaf2507da52a875e93f57451e58e8c6372";

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