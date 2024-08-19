import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from "hardhat-deploy/types";
// import "hardhat-deploy/src/type-extensions";
// import "@nomiclabs/hardhat-ethers";

import { L1BridgeRegistryProxy } from "../typechain-types/contracts/layer2/L1BridgeRegistryProxy"
import { L1BridgeRegistryV1_1 } from "../typechain-types/contracts/layer2/L1BridgeRegistryV1_1.sol"

import { DepositManagerProxy } from "../typechain-types/contracts/stake/managers/DepositManagerProxy"
import { SeigManagerProxy } from "../typechain-types/contracts/stake/managers/SeigManagerProxy"

import { Layer2ManagerProxy } from "../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../typechain-types/contracts/layer2/Layer2ManagerV1_1.sol"
import { OperatorManagerFactory } from "../typechain-types/contracts/layer2/factory/OperatorManagerFactory.sol"
import { OperatorV1_1 } from "../typechain-types/contracts/layer2/OperatorV1_1.sol"

import { DAOCommitteeAddV1_1 } from "../typechain-types/contracts/dao/DAOCommitteeAddV1_1.sol"
import { CandidateAddOnFactoryProxy } from "../typechain-types/contracts/dao/factory/CandidateAddOnFactoryProxy"
import { CandidateAddOnFactory } from "../typechain-types/contracts/dao/factory/CandidateAddOnFactory.sol"
import { CandidateAddOnV1_1 } from "../typechain-types/contracts/dao/CandidateAddOnV1_1.sol"

import { SeigManagerV1_3 } from "../typechain-types/contracts/stake/managers/SeigManagerV1_3.sol"
import { DepositManagerV1_1 } from "../typechain-types/contracts/stake/managers/DepositManagerV1_1.sol"

// write down th manager address of L1BridgeRegistry
// const L1BridgeRegistry_Manager_Address = null
// sepolia test
const L1BridgeRegistry_Manager_Address = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'

const deployV2: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const minimumInitialDepositAmount = hre.ethers.utils.parseEther("1000.1")

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

    //==== L1BridgeRegistry =================================
    const L1BridgeRegistryDeployment = await deploy("L1BridgeRegistryV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    const L1BridgeRegistryProxyDeployment = await deploy("L1BridgeRegistryProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const l1BridgeRegistryProxy = (await hre.ethers.getContractAt(
        L1BridgeRegistryProxyDeployment.abi,
        L1BridgeRegistryProxyDeployment.address
    )) as L1BridgeRegistryProxy;


    let impl_l1BridgeRegistry = await l1BridgeRegistryProxy.implementation()
    if (impl_l1BridgeRegistry != L1BridgeRegistryProxyDeployment.address) {
        await (await l1BridgeRegistryProxy.connect(deploySigner).upgradeTo(L1BridgeRegistryProxyDeployment.address)).wait()
    }

    const l1BridgeRegistry = (await hre.ethers.getContractAt(
        L1BridgeRegistryProxyDeployment.abi,
        l1BridgeRegistryProxy.address
    )) as L1BridgeRegistryV1_1;


    //==== OperatorManagerFactory =========================
    const OperatorV1_1Deployment = await deploy("OperatorV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    const OperatorManagerFactoryDeployment = await deploy("OperatorManagerFactory", {
        from: deployer,
        args: [OperatorV1_1Deployment.address],
        log: true
    });

    const operatorManagerFactory = (await hre.ethers.getContractAt(
        OperatorManagerFactoryDeployment.abi,
        OperatorManagerFactoryDeployment.address
    )) as OperatorManagerFactory;

    let ton_operatorManagerFactory = await operatorManagerFactory.ton()
    if (TON != ton_operatorManagerFactory) {
        await (await operatorManagerFactory.connect(deploySigner).setAddresses(
            DepositManager,
            TON,
            WTON)).wait()
    }

    //==== CandidateAddOnV1_1 =================================
    const Layer2CandidateV1_1Deployment = await deploy("CandidateAddOnV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    //==== CandidateAddOnFactory =================================
    const CandidateAddOnFactoryDeployment = await deploy("CandidateAddOnFactory", {
        from: deployer,
        args: [],
        log: true
    });

    const CandidateAddOnFactoryProxyDeployment = await deploy("CandidateAddOnFactoryProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const candidateAddOnFactoryProxy = (await hre.ethers.getContractAt(
        CandidateAddOnFactoryProxyDeployment.abi,
        CandidateAddOnFactoryProxyDeployment.address
    )) as CandidateAddOnFactoryProxy;

    let impl_candidateAddOnFactoryProxy = await candidateAddOnFactoryProxy.implementation()
    if (impl_candidateAddOnFactoryProxy != CandidateAddOnFactoryDeployment.address) {
        await (await candidateAddOnFactoryProxy.connect(deploySigner).upgradeTo(CandidateAddOnFactoryDeployment.address)).wait()
    }

    const candidateAddOnFactory = (await hre.ethers.getContractAt("CandidateAddOnFactory", candidateAddOnFactoryProxy.address, deploySigner)) as Layer2CandidateFactory

    let layer2CandidateImp_layer2CandidateFactory = await candidateAddOnFactory.candidateAddOnImp()

    if (Layer2CandidateV1_1Deployment.address != layer2CandidateImp_layer2CandidateFactory) {
        await (await candidateAddOnFactory.connect(deploySigner).setAddress(
            DepositManager,
            DAOCommitteeProxy,
            Layer2CandidateV1_1Deployment.address,
            TON,
            WTON,
            l1BridgeRegistryProxy.address
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

    if (L1BridgeRegistry_Manager_Address != null) {
        let res = await l1BridgeRegistryProxy.isManager(L1BridgeRegistry_Manager_Address)
        if (res == false) {
            await (await l1BridgeRegistryProxy.connect(deploySigner).addManager(L1BridgeRegistry_Manager_Address)).wait()
        }
    }

    const layer2Manager = (await hre.ethers.getContractAt(
        Layer2ManagerV1_1Deployment.abi,
        Layer2ManagerProxy_1Deployment.address
    )) as Layer2ManagerV1_1;

    let l2Register_layer2Manager = await layer2Manager.l2Register()
    if (l2Register_layer2Manager != l1BridgeRegistryProxy.address) {
        await (await layer2Manager.connect(deploySigner).setAddresses(
                l1BridgeRegistryProxy.address,
                operatorManagerFactory.address,
                TON, WTON, DAOCommitteeProxy, DepositManager,
                SeigManager, swapProxy
            )
        ).wait()
    }

    let minimumInitialDepositAmount_layer2Manager = await layer2Manager.minimumInitialDepositAmount()

    if (!(minimumInitialDepositAmount_layer2Manager.eq(minimumInitialDepositAmount))) {
        await (await layer2Manager.connect(deploySigner).setMinimumInitialDepositAmount(
            minimumInitialDepositAmount)
        ).wait()
    }


    let ton_l1BridgeRegistry = await l1BridgeRegistry.ton()
    if (TON != ton_l1BridgeRegistry) {
        await (await l1BridgeRegistry.connect(deploySigner).setAddresses(
            layer2Manager.address,
            SeigManager,
            TON
            )).wait()
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