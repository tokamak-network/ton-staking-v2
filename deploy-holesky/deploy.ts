import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from 'hardhat'

import { DepositManagerForMigration } from "../typechain-types/contracts/stake/managers/DepositManagerForMigration.sol"

import { DepositManager } from "../typechain-types/contracts/stake/managers/DepositManager.sol"
import { DepositManagerProxy } from "../typechain-types/contracts/stake/managers/DepositManagerProxy"
import { SeigManager } from "../typechain-types/contracts/stake/managers/SeigManager.sol"
import { SeigManagerProxy } from "../typechain-types/contracts/stake/managers/SeigManagerProxy"
import { Layer2Registry } from "../typechain-types/contracts/stake/Layer2Registry.sol"
import { Layer2RegistryProxy } from "../typechain-types/contracts/stake/Layer2RegistryProxy"
import { CoinageFactory } from "../typechain-types/contracts/stake/factory/CoinageFactory.sol"
import { RefactorCoinageSnapshot } from "../typechain-types/contracts/stake/tokens/RefactorCoinageSnapshot.sol"
import { Candidate } from "../typechain-types/contracts/dao/Candidate.sol"
import { CandidateProxy } from "../typechain-types/contracts/dao/CandidateProxy"
import { DAOCommitteeExtend } from "../typechain-types/contracts/dao/DAOCommitteeExtend.sol"
import { CandidateFactory } from "../typechain-types/contracts/dao/factory/CandidateFactory.sol"
import { CandidateFactoryProxy } from "../typechain-types/contracts/dao/factory/CandidateFactoryProxy"
import { PowerTONUpgrade } from "../typechain-types/contracts/stake/powerton/PowerTONUpgrade"
import { TestSeigManager } from "../typechain-types/contracts/test/TestSeigManager.sol"

const oldDepositManager = "0x0000000000000000000000000000000000000000"

const v1Infos = {
    ton: '0x3d15587A41851749982CDcB2880B0D3C380F84c9',
    wton: '0xe86fCf5213C785AcF9a8BFfEeDEfA9a2199f7Da6',
    daoCommittee: "0xfAe1b058b73D91cfcfb6b4E163DF9f905041F7b5",
    globalWithdrawalDelay: ethers.BigNumber.from("93046"),
    lastSeigBlock : ethers.BigNumber.from("0"),
    pauseBlock: ethers.BigNumber.from("0"),
    seigPerBlock: ethers.BigNumber.from("3920000000000000000000000000"),
    powertonAddress: "0x5BFb4BF760227ca68bb0d5C36cCaCEBbb466Dfc7",
    daoVaultAddress : "0xeB725ff92b9c9Db4F6f4f8af26703e5F8C908F6c",
    depositManager: null
}

const seigManagerInfo = {
  minimumAmount: ethers.BigNumber.from("1000000000000000000000000000000"),
  powerTONSeigRate: ethers.BigNumber.from("100000000000000000000000000"),
  relativeSeigRate: ethers.BigNumber.from("400000000000000000000000000"),
  daoSeigRate: ethers.BigNumber.from("500000000000000000000000000"),
  seigPerBlock: ethers.BigNumber.from("3920000000000000000000000000"),
  adjustCommissionDelay:  ethers.BigNumber.from("0"),
}

const deployMigration: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deploySigner = await hre.ethers.getSigner(deployer);


    //==== DAOCommitteeExtend =========================
    const DAOCommitteeExtendDeployment = await deploy("DAOCommitteeExtend", {
        from: deployer,
        args: [],
        log: true
    });

    //==== PowerTONUpgrade =================================

    const PowerTONUpgradeDeployment = await deploy("PowerTONUpgrade", {
        from: deployer,
        args: [],
        log: true
    });

    //==== SeigManager =================================

    const SeigManagerDeployment = await deploy("SeigManager", {
        from: deployer,
        args: [],
        log: true
    });

    const SeigManagerMigrationDeployment = await deploy("SeigManagerMigration", {
        from: deployer,
        args: [],
        log: true
    });

    const SeigManagerProxyDeployment = await deploy("SeigManagerProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const seigManagerProxy = (await hre.ethers.getContractAt(
        SeigManagerProxyDeployment.abi,
        SeigManagerProxyDeployment.address
    )) as SeigManagerProxy;

    const seigManager = (await hre.ethers.getContractAt(
        SeigManagerDeployment.abi,
        SeigManagerProxyDeployment.address
    )) as SeigManager;


    let seigManagerImpl = await seigManagerProxy.implementation()
    if (seigManagerImpl != SeigManagerDeployment.address) {
        await (await seigManagerProxy.connect(deploySigner).upgradeTo(SeigManagerDeployment.address)).wait()
    }

    //==== DepositManager =================================
    const DepositManagerDeployment = await deploy("DepositManager", {
        from: deployer,
        args: [],
        log: true
    });

    const DepositManagerProxyDeployment = await deploy("DepositManagerProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const depositManagerProxy = (await hre.ethers.getContractAt(
        DepositManagerProxyDeployment.abi,
        DepositManagerProxyDeployment.address
    )) as DepositManagerProxy;


    let depositManagerImpl = await depositManagerProxy.implementation()
    if (depositManagerImpl != DepositManagerDeployment.address) {
        await (await depositManagerProxy.connect(deploySigner).upgradeTo(DepositManagerDeployment.address)).wait()
    }
    const depositManager = (await hre.ethers.getContractAt(
        DepositManagerDeployment.abi,
        depositManagerProxy.address
    )) as DepositManager;

    //==== Layer2Registry =================================

    const Layer2RegistryDeployment = await deploy("Layer2Registry", {
        from: deployer,
        args: [],
        log: true
    });

    const Layer2RegistryProxyDeployment = await deploy("Layer2RegistryProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const layer2RegistryProxy = (await hre.ethers.getContractAt(
        Layer2RegistryProxyDeployment.abi,
        Layer2RegistryProxyDeployment.address
    )) as Layer2RegistryProxy;

    let layer2RegistryImpl = await layer2RegistryProxy.implementation()
    if (layer2RegistryImpl != Layer2RegistryDeployment.address) {
        await (await layer2RegistryProxy.connect(deploySigner).upgradeTo(Layer2RegistryDeployment.address)).wait()
    }


    //==== Candidate =================================
    const CandidateDeployment = await deploy("Candidate", {
        from: deployer,
        args: [],
        log: true
    });

    //==== CandidateFactory =================================
    const CandidateFactoryDeployment = await deploy("CandidateFactory", {
        from: deployer,
        args: [],
        log: true
    });

    const CandidateFactoryProxyDeployment = await deploy("CandidateFactoryProxy", {
        from: deployer,
        args: [],
        log: true
    });

    const candidateFactoryProxy = (await hre.ethers.getContractAt(
        CandidateFactoryProxyDeployment.abi,
        CandidateFactoryProxyDeployment.address
    )) as CandidateFactoryProxy;

    let candidateFactoryImp = await candidateFactoryProxy.implementation()
    if (candidateFactoryImp != CandidateFactoryDeployment.address) {
        await (await candidateFactoryProxy.connect(deploySigner).upgradeTo(CandidateFactoryDeployment.address)).wait()
    }

    const candidateFactory = (await hre.ethers.getContractAt(
        CandidateFactoryDeployment.abi,
        CandidateFactoryProxyDeployment.address
    )) as CandidateFactory;

    //====== candidateFactory setAddress ==================
    let candidateDeploymentAddress = await candidateFactory.candidateImp()
    let daoCommittee_candidateFactory = await candidateFactory.daoCommittee()

    // if (v1Infos.daoCommittee != null && candidateDeploymentAddress != CandidateDeployment.address ) {
    if (v1Infos.daoCommittee != null && daoCommittee_candidateFactory != v1Infos.daoCommittee ) {
        await (await candidateFactory.connect(deploySigner).setAddress (
             depositManagerProxy.address,
             v1Infos.daoCommittee,
             CandidateDeployment.address,
             v1Infos.ton,
             v1Infos.wton
          )).wait()
    }

    //==== RefactorCoinageSnapshot =================================
    const coinageDeployment = await deploy("RefactorCoinageSnapshot", {
        from: deployer,
        args: [],
        log: true
    });

    //==== CoinageFactory =================================

    const CoinageFactoryDeployment = await deploy("CoinageFactory", {
        from: deployer,
        args: [],
        log: true
    });

    const coinageFactory = (await hre.ethers.getContractAt(
        CoinageFactoryDeployment.abi,
        CoinageFactoryDeployment.address
    )) as CoinageFactory;

    let autoCoinageLogic = await coinageFactory.autoCoinageLogic()
    if (autoCoinageLogic != coinageDeployment.address) {
        await (await coinageFactory.connect(deploySigner).setAutoCoinageLogic(coinageDeployment.address)).wait()
    }

    //====== depositManagerV2 initialize ==================
    let wtonAddress1 = await depositManager.wton()

    if (wtonAddress1 != v1Infos.wton) {
        await (await depositManager.connect(deploySigner).initialize (
            v1Infos.wton,
            layer2RegistryProxy.address,
            seigManagerProxy.address,
            v1Infos.globalWithdrawalDelay,
            oldDepositManager
          )).wait()
    }

    //====== seigManagerV2 setData ==================
    let wtonAddress2 = await seigManager.wton()

    if (wtonAddress2 != v1Infos.wton) {
        await (await seigManager.connect(deploySigner).initialize (
            v1Infos.ton,
            v1Infos.wton,
            layer2RegistryProxy.address,
            depositManagerProxy.address,
            v1Infos.seigPerBlock,
            coinageFactory.address,
            v1Infos.lastSeigBlock
          )).wait()
    }

    let powertonAddress = await seigManager.powerton()
    if (v1Infos.powertonAddress != null &&
        v1Infos.daoVaultAddress != null &&
        powertonAddress != v1Infos.powertonAddress ) {
        await (await seigManager.connect(deploySigner).setData (
            v1Infos.powertonAddress,
            v1Infos.daoVaultAddress,
            seigManagerInfo.powerTONSeigRate,
            seigManagerInfo.daoSeigRate,
            seigManagerInfo.relativeSeigRate,
            seigManagerInfo.adjustCommissionDelay,
            seigManagerInfo.minimumAmount
          )).wait()
    }

    //====== layer2RegistryV2 addMinter ==================
    if (v1Infos.daoCommittee != null) {
        let isMinter1 = await layer2RegistryProxy.isMinter(v1Infos.daoCommittee)
        if (v1Infos.daoCommittee != "0x0000000000000000000000000000000000000000"
            && isMinter1 == false) {
            await (await layer2RegistryProxy.connect(deploySigner).addMinter(
                v1Infos.daoCommittee
            )).wait()
        }
    }

    //====== seigManagerV2 addMinter ==================
    let isMinter2 = await seigManagerProxy.isMinter(layer2RegistryProxy.address)
    if (isMinter2 == false) {
        await (await seigManagerProxy.connect(deploySigner).addMinter(
            layer2RegistryProxy.address
          )).wait()
    }

    //====== WTON  addMinter to seigManagerV2 ==================

    //=== daoCommittee
    //   await (await daoCommittee.connect(daoCommitteeAdmin).setCandidateFactory(candidateFactoryProxy.address)).wait()
    //   await (await daoCommittee.connect(daoCommitteeAdmin).setSeigManager(seigManagerProxy.address)).wait()
    //   await (await daoCommittee.connect(daoCommitteeAdmin).setLayer2Registry(layer2RegistryProxy.address)).wait()


    //==== verify =================================
    if (hre.network.name != "hardhat") {
        await hre.run("etherscan-verify", {
            network: hre.network.name
        });
    }
};

export default deployMigration;