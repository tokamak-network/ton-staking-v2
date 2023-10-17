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

const v1Infos = {
    ton: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5',
    wton: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2',
    daoCommittee: '0xDD9f0cCc044B0781289Ee318e5971b0139602C26',
    globalWithdrawalDelay: ethers.BigNumber.from("93046"),
    lastSeigBlock : ethers.BigNumber.from("18169346"),
    pauseBlock: ethers.BigNumber.from("18231453"),
    seigPerBlock: ethers.BigNumber.from("3920000000000000000000000000"),
    powertonAddress: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
    daoVaultAddress : "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
    depositManager: "0x56E465f654393fa48f007Ed7346105c7195CEe43"
}

const seigManagerInfo = {
  minimumAmount: ethers.BigNumber.from("1000000000000000000000000000000"),
  powerTONSeigRate: ethers.BigNumber.from("100000000000000000000000000"),
  relativeSeigRate: ethers.BigNumber.from("400000000000000000000000000"),
  daoSeigRate: ethers.BigNumber.from("500000000000000000000000000"),
  seigPerBlock: ethers.BigNumber.from("3920000000000000000000000000"),
  adjustCommissionDelay:  ethers.BigNumber.from("93096"),
}

const deployTonStakingV2: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    console.log('deploy hre.network.config.chainId', hre.network.config.chainId)
    console.log('deploy hre.network.name', hre.network.name)

    const { deployer, DepositManager } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deploySigner = await hre.ethers.getSigner(deployer);
    console.log(deployer)

    if (hre.network.name == "hardhat" || hre.network.name == "local") {

        await hre.network.provider.send("hardhat_setBalance", [
            deployer,
            "0x10000000000000000000000000",
          ]);
    }

    //==== TestSeigManager =================================
    const TestSeigManagerDeployment = await deploy("TestSeigManager", {
        from: deployer,
        args: [],
        log: true
    });

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
    if (seigManagerImpl != SeigManagerMigrationDeployment.address) {
        await (await seigManagerProxy.connect(deploySigner).upgradeTo(SeigManagerMigrationDeployment.address)).wait()
    }

    //==== DepositManager =================================
    const DepositManagerDeployment = await deploy("DepositManager", {
        from: deployer,
        args: [],
        log: true
    });

    const DepositManagerForMigration = await deploy("DepositManagerForMigration", {
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


    const depositManagerForMigration = (await hre.ethers.getContractAt(
        DepositManagerForMigration.abi,
        DepositManagerProxyDeployment.address
    )) as DepositManagerForMigration;


    let depositManagerImpl = await depositManagerProxy.implementation()
    if (depositManagerImpl != DepositManagerForMigration.address) {
        await (await depositManagerProxy.connect(deploySigner).upgradeTo(DepositManagerForMigration.address)).wait()
    }

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
    if (candidateDeploymentAddress != CandidateDeployment.address ) {
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
    let wtonAddress1 = await depositManagerForMigration.wton()

    if (wtonAddress1 != v1Infos.wton) {
        await (await depositManagerForMigration.connect(deploySigner).initialize(
            v1Infos.wton,
            layer2RegistryProxy.address,
            seigManagerProxy.address,
            v1Infos.globalWithdrawalDelay,
            DepositManager
          )).wait()
    }

    //====== seigManagerV2 setData ==================
    let wtonAddress2 = await seigManager.wton()

    if (wtonAddress2 != v1Infos.wton) {
        await (await seigManager.connect(deploySigner).initialize(
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
    if (powertonAddress != v1Infos.powertonAddress ) {
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
    let isMinter1 = await layer2RegistryProxy.isMinter(v1Infos.daoCommittee)
    if (isMinter1 == false) {
        await (await layer2RegistryProxy.connect(deploySigner).addMinter(
            v1Infos.daoCommittee
          )).wait()
    }

    //====== seigManagerV2 addMinter ==================
    let isMinter2 = await seigManagerProxy.isMinter(layer2RegistryProxy.address)
    if (isMinter2 == false) {
        await (await seigManagerProxy.connect(deploySigner).addMinter(
            layer2RegistryProxy.address
          )).wait()
    }

    //====== TestSeigManager setAddresses ==================

    const testSeigManager = (await hre.ethers.getContractAt(
        TestSeigManagerDeployment.abi,
        TestSeigManagerDeployment.address
    )) as TestSeigManager;


    let newDepositManager = await testSeigManager.newDepositManager()
    if (newDepositManager != DepositManagerProxyDeployment.address) {
        await (await testSeigManager.connect(deploySigner).setAddresses(
            v1Infos.depositManager,
            DepositManagerProxyDeployment.address,
            v1Infos.wton
          )).wait()
    }

    //====== WTON  addMinter to seigManagerV2 ==================

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

export default deployTonStakingV2;