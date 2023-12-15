import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { L1StakedTonInL2 } from "../typechain-types/contracts/L2/L1StakedTonInL2.sol"
import { L1StakedTonInL2Proxy } from "../typechain-types/contracts/L2/L1StakedTonInL2Proxy"

import { L2SeigManager } from "../typechain-types/contracts/L2/L2SeigManager.sol"
import { L2SeigManagerProxy } from "../typechain-types/contracts/L2/L2SeigManagerProxy"

const deployMigration: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deploySigner = await hre.ethers.getSigner(deployer);


    //==== L2SeigManager =========================
    const L2SeigManagerDeployment = await deploy("L2SeigManager", {
        from: deployer,
        args: [],
        log: true
    });

    const L2SeigManagerProxyDeployment = await deploy("L2SeigManagerProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const l2SeigManagerProxy = (await hre.ethers.getContractAt(
        L2SeigManagerProxyDeployment.abi,
        L2SeigManagerProxyDeployment.address
    )) as L2SeigManagerProxy;

    const l2SeigManager = (await hre.ethers.getContractAt(
        L2SeigManagerDeployment.abi,
        L2SeigManagerProxyDeployment.address
    )) as L2SeigManager;


    let impl2 = await l2SeigManagerProxy.implementation()
    if (impl2 != L2SeigManagerDeployment.address) {
        await (await l2SeigManagerProxy.connect(deploySigner).upgradeTo(L2SeigManagerDeployment.address)).wait()
    }

    //==== L1StakedTonInL2 =================================

    const L1StakedTonInL2Deployment = await deploy("L1StakedTonInL2", {
        from: deployer,
        args: [],
        log: true
    });

    const L1StakedTonInL2ProxyDeployment = await deploy("L1StakedTonInL2Proxy", {
        from: deployer,
        args: [],
        log: true
    });

    const l1StakedTonToL2Proxy = (await hre.ethers.getContractAt(
        L1StakedTonInL2ProxyDeployment.abi,
        L1StakedTonInL2ProxyDeployment.address
    )) as L1StakedTonInL2Proxy;

    const l1StakedTonToL2 = (await hre.ethers.getContractAt(
        L1StakedTonInL2Deployment.abi,
        L1StakedTonInL2ProxyDeployment.address
    )) as L1StakedTonInL2;


    let impl = await l1StakedTonToL2Proxy.implementation()
    if (impl != L1StakedTonInL2Deployment.address) {
        await (await l1StakedTonToL2Proxy.connect(deploySigner).upgradeTo(L1StakedTonInL2Deployment.address)).wait()
    }

    //==== verify =================================
    if (hre.network.name != "hardhat") {
        await hre.run("etherscan-verify", {
            network: hre.network.name
        });
    }
};

export default deployMigration;