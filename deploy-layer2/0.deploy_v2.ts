import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from "hardhat-deploy/types";
// import "hardhat-deploy/src/type-extensions";
// import "@nomiclabs/hardhat-ethers";

import { L2RegistryProxy } from "../typechain-types/contracts/layer2/L2RegistryProxy"
import { L2RegistryV1_1 } from "../typechain-types/contracts/layer2/L2RegistryV1_1.sol"

import { DepositManagerProxy } from "../typechain-types/contracts/stake/managers/DepositManagerProxy"
import { SeigManagerProxy } from "../typechain-types/contracts/stake/managers/SeigManagerProxy"

import { Layer2ManagerProxy } from "../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../typechain-types/contracts/layer2/Layer2ManagerV1_1.sol"
import { OperatorFactory } from "../typechain-types/contracts/layer2/factory/OperatorFactory.sol"
import { OperatorV1_1 } from "../typechain-types/contracts/layer2/OperatorV1_1.sol"

import { DAOCommitteeAddV1_1 } from "../typechain-types/contracts/dao/DAOCommitteeAddV1_1.sol"
import { Layer2CandidateFactoryProxy } from "../typechain-types/contracts/dao/factory/Layer2CandidateFactoryProxy"
import { Layer2CandidateFactory } from "../typechain-types/contracts/dao/factory/Layer2CandidateFactory.sol"
import { Layer2CandidateV1_1 } from "../typechain-types/contracts/dao/Layer2CandidateV1_1.sol"

import { SeigManagerV1_3 } from "../typechain-types/contracts/stake/managers/SeigManagerV1_3.sol"
import { DepositManagerV1_1 } from "../typechain-types/contracts/stake/managers/DepositManagerV1_1.sol"

// write down th manager address of L2Registry
const L2Registry_Manager_Address = null

const deployV2: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const minimumInitialDepositAmount = hre.ethers.utils.parseEther("1000")

    console.log('minimumInitialDepositAmount', minimumInitialDepositAmount )

    const { deployer, DepositManager, SeigManager, swapProxy, DAOCommitteeProxy, TON, WTON } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deploySigner = await hre.ethers.getSigner(deployer);
    console.log(deployer)

    if (hre.network.name == "hardhat" || hre.network.name == "local") {

        await hre.network.provider.send("hardhat_setBalance", [
            deployer,
            "0x10000000000000000000000000",
          ]);
    }

    //==== L2Registry =================================
    const L2RegistryDeployment = await deploy("L2RegistryV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    const L2RegistryProxyDeployment = await deploy("L2RegistryProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const l2RegistryProxy = (await hre.ethers.getContractAt(
        L2RegistryProxyDeployment.abi,
        L2RegistryProxyDeployment.address
    )) as L2RegistryProxy;


    let impl_l2RegistryProxy = await l2RegistryProxy.implementation()
    if (impl_l2RegistryProxy != L2RegistryDeployment.address) {
        await (await l2RegistryProxy.connect(deploySigner).upgradeTo(L2RegistryDeployment.address)).wait()
    }

    //==== OperatorFactory =========================
    const OperatorV1_1Deployment = await deploy("OperatorV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    const OperatorFactoryDeployment = await deploy("OperatorFactory", {
        from: deployer,
        args: [OperatorV1_1Deployment.address],
        log: true
    });

    const operatorFactory = (await hre.ethers.getContractAt(
        OperatorFactoryDeployment.abi,
        OperatorFactoryDeployment.address
    )) as OperatorFactory;

    let ton_operatorFactory = await operatorFactory.ton()
    if (TON != ton_operatorFactory) {
        await (await operatorFactory.connect(deploySigner).setAddresses(
            DepositManager,
            TON,
            WTON)).wait()
    }

    //==== Layer2CandidateV1_1 =================================
    const Layer2CandidateV1_1Deployment = await deploy("Layer2CandidateV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    //==== Layer2CandidateFactory =================================
    const Layer2CandidateFactoryDeployment = await deploy("Layer2CandidateFactory", {
        from: deployer,
        args: [],
        log: true
    });

    const Layer2CandidateFactoryProxyDeployment = await deploy("Layer2CandidateFactoryProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const layer2CandidateFactoryProxy = (await hre.ethers.getContractAt(
        Layer2CandidateFactoryProxyDeployment.abi,
        Layer2CandidateFactoryProxyDeployment.address
    )) as Layer2CandidateFactoryProxy;

    let impl_layer2CandidateFactoryProxy = await layer2CandidateFactoryProxy.implementation()
    if (impl_layer2CandidateFactoryProxy != Layer2CandidateFactoryDeployment.address) {
        await (await layer2CandidateFactoryProxy.connect(deploySigner).upgradeTo(Layer2CandidateFactoryDeployment.address)).wait()
    }

    const layer2CandidateFactory = (await hre.ethers.getContractAt("Layer2CandidateFactory", layer2CandidateFactoryProxy.address, deploySigner)) as Layer2CandidateFactory

    let layer2CandidateImp_layer2CandidateFactory = await layer2CandidateFactory.layer2CandidateImp()

    if (Layer2CandidateV1_1Deployment.address != layer2CandidateImp_layer2CandidateFactory) {
        await (await layer2CandidateFactory.connect(deploySigner).setAddress(
            DepositManager,
            DAOCommitteeProxy,
            Layer2CandidateV1_1Deployment.address,
            TON,
            WTON,
            l2RegistryProxy.address
        )).wait()
    }

    //==== Layer2Manager =================================
    const Layer2ManagerV1_1Deployment = await deploy("Layer2ManagerV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    const Layer2ManagerProxy_1Deployment = await deploy("Layer2ManagerProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const layer2ManagerProxy = (await hre.ethers.getContractAt(
        Layer2ManagerProxy_1Deployment.abi,
        Layer2ManagerProxy_1Deployment.address
    )) as Layer2ManagerProxy;

    let impl_layer2ManagerProxy = await layer2ManagerProxy.implementation()
    if (impl_layer2ManagerProxy != Layer2ManagerV1_1Deployment.address) {
        await (await layer2ManagerProxy.connect(deploySigner).upgradeTo(Layer2ManagerV1_1Deployment.address)).wait()
    }

    if (L2Registry_Manager_Address != null) {
        let res = await l2RegistryProxy.isManager(L2Registry_Manager_Address)
        if (res == false) {
            await (await l2RegistryProxy.connect(deploySigner).addManager(L2Registry_Manager_Address)).wait()
        }
    }

    const layer2Manager = (await hre.ethers.getContractAt(
        Layer2ManagerV1_1Deployment.abi,
        Layer2ManagerProxy_1Deployment.address
    )) as Layer2ManagerV1_1;

    let l2Register_layer2Manager = await layer2Manager.l2Register()
    if (l2Register_layer2Manager != l2RegistryProxy.address) {
        await (await layer2Manager.connect(deploySigner).setAddresses(
                l2RegistryProxy.address,
                operatorFactory.address,
                TON, WTON, DAOCommitteeProxy, DepositManager,
                SeigManager, swapProxy
            )
        ).wait()
    }

    let minimumInitialDepositAmount_layer2Manager = await layer2Manager.minimumInitialDepositAmount()
    if (minimumInitialDepositAmount_layer2Manager != minimumInitialDepositAmount) {
        await (await layer2Manager.connect(deploySigner).setMinimumInitialDepositAmount(
            minimumInitialDepositAmount)
        ).wait()
    }

    //==== SeigManagerV1_3 =================================



    //==== DepositManagerV1_1 =================================


    //=== daoCommittee
    //   await (await daoCommittee.connect(daoCommitteeAdmin).setCandidateFactory(candidateFactoryProxy.address)).wait()
    //   await (await daoCommittee.connect(daoCommitteeAdmin).setSeigManager(seigManagerProxy.address)).wait()
    //   await (await daoCommittee.connect(daoCommitteeAdmin).setLayer2Registry(layer2RegistryProxy.address)).wait()


    //==== verify =================================
    if (hre.network.name != "hardhat" && hre.network.name != "local") {
        await hre.run("etherscan-verify", {
            network: hre.network.name
        });
    }

}

export default deployV2;
deployV2.tags = ['SimpleStakingV2'];