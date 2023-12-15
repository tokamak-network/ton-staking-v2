import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from 'hardhat'

import { L1StakedTonToL2 } from "../typechain-types/contracts/L1/L1StakedTonToL2.sol"
import { L1StakedTonToL2Proxy } from "../typechain-types/contracts/L1/L1StakedTonToL2Proxy"


const deployMigration: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deploySigner = await hre.ethers.getSigner(deployer);


    //==== SeigManager1 =========================
    const SeigManager1Deployment = await deploy("SeigManager1", {
        from: deployer,
        args: [],
        log: true
    });

    //==== L1StakedTonToL2 =================================

    const L1StakedTonToL2Deployment = await deploy("L1StakedTonToL2", {
        from: deployer,
        args: [],
        log: true
    });

    const L1StakedTonToL2ProxyDeployment = await deploy("L1StakedTonToL2Proxy", {
        from: deployer,
        args: [],
        log: true
    });

    const l1StakedTonToL2Proxy = (await hre.ethers.getContractAt(
        L1StakedTonToL2ProxyDeployment.abi,
        L1StakedTonToL2ProxyDeployment.address
    )) as L1StakedTonToL2Proxy;

    const l1StakedTonToL2 = (await hre.ethers.getContractAt(
        L1StakedTonToL2Deployment.abi,
        L1StakedTonToL2ProxyDeployment.address
    )) as L1StakedTonToL2;


    let impl = await l1StakedTonToL2Proxy.implementation()
    if (impl != L1StakedTonToL2Deployment.address) {
        await (await l1StakedTonToL2Proxy.connect(deploySigner).upgradeTo(L1StakedTonToL2Deployment.address)).wait()
    }

    //==== verify =================================
    if (hre.network.name != "hardhat") {
        await hre.run("etherscan-verify", {
            network: hre.network.name
        });
    }
};

export default deployMigration;