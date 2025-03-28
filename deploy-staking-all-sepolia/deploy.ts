import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
// import ethers from "@nomiclabs/hardhat-ethers";
import ethers from "ethers";
// import "hardhat-deploy/src/type-extensions";
import {encodeFunctionSignature} from 'web3-eth-abi'

import { DepositManager } from "../typechain-types/contracts/stake/managers/DepositManager"
import { DepositManagerProxy } from "../typechain-types/contracts/stake/managers/DepositManagerProxy"

import { SeigManagerV1_2 } from "../typechain-types/contracts/stake/managers/SeigManagerV1_2"
import { SeigManagerV1_3 } from "../typechain-types/contracts/stake/managers/SeigManagerV1_3"
import { SeigManagerProxy } from "../typechain-types/contracts/stake/managers/SeigManagerProxy"
import { Layer2Registry } from "../typechain-types/contracts/stake/Layer2Registry"
import { Layer2RegistryProxy } from "../typechain-types/contracts/stake/Layer2RegistryProxy"
import { CoinageFactory } from "../typechain-types/contracts/stake/factory/CoinageFactory"
import { RefactorCoinageSnapshot } from "../typechain-types/contracts/stake/tokens/RefactorCoinageSnapshot"
import { Candidate } from "../typechain-types/contracts/dao/Candidate"
import { CandidateProxy } from "../typechain-types/contracts/dao/CandidateProxy"
import { CandidateFactory } from "../typechain-types/contracts/dao/factory/CandidateFactory"
import { CandidateFactoryProxy } from "../typechain-types/contracts/dao/factory/CandidateFactoryProxy"

import { L1BridgeRegistryProxy } from "../typechain-types/contracts/layer2/L1BridgeRegistryProxy"
import { L1BridgeRegistryV1_1 } from "../typechain-types/contracts/layer2/L1BridgeRegistryV1_1"

import { Layer2ManagerProxy } from "../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../typechain-types/contracts/layer2/Layer2ManagerV1_1"
import { OperatorManagerFactory } from "../typechain-types/contracts/layer2/factory/OperatorManagerFactory.sol"
import { OperatorManagerV1_1 } from "../typechain-types/contracts/layer2/OperatorManagerV1_1"

import { CandidateAddOnFactoryProxy } from "../typechain-types/contracts/dao/factory/CandidateAddOnFactoryProxy"
import { CandidateAddOnFactory } from "../typechain-types/contracts/dao/factory/CandidateAddOnFactory"
import { CandidateAddOnV1_1 } from "../typechain-types/contracts/dao/CandidateAddOnV1_1"

import { DepositManagerV1_1 } from "../typechain-types/contracts/stake/managers/DepositManagerV1_1.sol"

import { LegacySystemConfig } from "../typechain-types/contracts/layer2/LegacySystemConfig"
import { LegacySystemConfigProxy } from "../typechain-types/contracts/layer2/LegacySystemConfigProxy"
import { Faucetv2 } from "../typechain-types/contracts/mocks/Faucetv2"
import { WTON } from "../typechain-types/contracts/mocks/WTON.sol"


import DAOCommitteeProxy_JSON from '../test/abi/DAOCommitteeProxy.json'
import MultiSigWallet_JSON from '../test/abi/MultiSigWallet.json'
import DAOAgendaManager_JSON from '../test/abi/DAOAgendaManager.json'
import DAOVault_JSON from '../test/abi/DAOVault.json'
import TON_JSON from '../test/abi/TON.json'
import WTON_JSON from '../test/abi/WTON.json'


let faucetInitialSupply = {
    ton: hre.ethers.utils.parseEther("500000000000000"),
    wton: hre.ethers.utils.parseEther("10000000000000"+"0".repeat(9))
}

let tokenInfos = {
    ton: '',
    wton: ''
}

//local Test
const MultiSigWalletOwners = [
    '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65',
    '0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc',
    '0x976EA74026E726554dB657fA54763abd0C3a0aa9'
]

//sepolia
// const MultiSigWalletOwners = [
//     '0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea',
//     '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2',
//     '0xc1eba383D94c6021160042491A5dfaF1d82694E6'
// ]

const swapProxy = "0x690f994b82f001059e24d79292c3c476854b767a";

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

    let addr;

    //===================

    const minimumInitialDepositAmount = hre.ethers.utils.parseEther("1000.1")

    // console.log('minimumInitialDepositAmount', minimumInitialDepositAmount )

    const daoInfos = {
        maxMember: hre.ethers.BigNumber.from("3"),
        quorum:  hre.ethers.BigNumber.from("2"),
        activityRewardPerSecond: hre.ethers.BigNumber.from("3170979198376458"),
        cooldownTime: hre.ethers.BigNumber.from("86400"),
    }

    const daoAgendaInfos = {
        createAgendaFees: hre.ethers.BigNumber.from("100000000000000000000"),
        minimumNoticePeriodSeconds:  hre.ethers.BigNumber.from("300"),
        minimumVotingPeriodSeconds: hre.ethers.BigNumber.from("600"),
        executingPeriodSeconds: hre.ethers.BigNumber.from("604800"),
    }

    const seigManagerInfo = {
        minimumAmount: hre.ethers.BigNumber.from("1000000000000000000000000000000"),
        powerTONSeigRate: hre.ethers.BigNumber.from("0"),
        relativeSeigRate: hre.ethers.BigNumber.from("500000000000000000000000000"),
        daoSeigRate: hre.ethers.BigNumber.from("500000000000000000000000000"),
        seigPerBlock: hre.ethers.BigNumber.from("3920000000000000000000000000"),
        adjustCommissionDelay:  hre.ethers.BigNumber.from("93096"),
        globalWithdrawalDelay: hre.ethers.BigNumber.from("93046"),
    }

    let ownerAddressInfo =  {
        L1BridgeRegistry: {
            owner: hre.ethers.constants.AddressZero,
            manager: hre.ethers.constants.AddressZero,
        },
        Layer2Manager: {
            owner: hre.ethers.constants.AddressZero
        },
        OperatorManagerFactory: {
            owner: hre.ethers.constants.AddressZero
        },
        Titan : {
            proxyOwner: hre.ethers.constants.AddressZero,
            manager: "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
        }
    }

    //==== TON =================================

    const TONDeployment = await deploy("TON",{
        // contract:
        // {
        //     abi: TON_JSON.abi,
        //     bytecode: TON_JSON.bytecode,
        //     // deployedBytecode: TON_JSON.deployedBytecode
        // },
        from: deployer,
        args: [],
        log: true
    });

    tokenInfos.ton = TONDeployment.address

    const tonContract = (await hre.ethers.getContractAt(
        TONDeployment.abi,
        TONDeployment.address
    ));

    //==== WTON =================================

    const WTONDeployment = await deploy("WTON",{
        // contract:
        // {
        //     abi: WTON_JSON.abi,
        //     bytecode: WTON_JSON.bytecode,
        //     // deployedBytecode: WTON_JSON.deployedBytecode
        // },
        from: deployer,
        args: [
            tokenInfos.ton
        ],
        log: true
    });

    tokenInfos.wton = WTONDeployment.address

    const wtonContract = (await hre.ethers.getContractAt(
        WTONDeployment.abi,
        WTONDeployment.address
    ));

    //==== Faucet =================================

    const Faucetv2Deployment = await deploy("Faucetv2",{
        from: deployer,
        // args: [
        //     tokenInfos.ton,
        //     tokenInfos.wton,
        //     hre.ethers.utils.parseEther("1200"),
        //     hre.ethers.utils.parseEther("200"),
        //     hre.ethers.BigNumber.from("86400")
        // ],
        args: [
            tokenInfos.ton,
            tokenInfos.wton,
            hre.ethers.utils.parseEther("1200"),
            hre.ethers.utils.parseEther("1000"+"0".repeat(9)),
            hre.ethers.BigNumber.from("1")
        ],
        log: true
    });

    const faucetContract = (await hre.ethers.getContractAt(
        Faucetv2Deployment.abi,
        Faucetv2Deployment.address
    ));

    //==== TON minter  =================================
    let isMinter = await tonContract.connect(deploySigner).isMinter(deploySigner.address)

    let balanceOfFaucet =  await tonContract.balanceOf(faucetContract.address)
    if (isMinter && balanceOfFaucet.eq(hre.ethers.constants.Zero) ) {
        await (await tonContract.connect(deploySigner).mint(Faucetv2Deployment.address, faucetInitialSupply.ton)).wait()
        await (await tonContract.connect(deploySigner).addMinter(tokenInfos.wton)).wait()
        await (await tonContract.connect(deploySigner)["renounceMinter()"]()).wait()

        await (await wtonContract.connect(deploySigner).mint(Faucetv2Deployment.address, faucetInitialSupply.ton)).wait()
    }

    //==== SeigManager =================================

    const SeigManagerV1_2Deployment = await deploy("SeigManagerV1_2", {
        from: deployer,
        args: [],
        log: true
    });

    const SeigManagerV1_3Deployment = await deploy("SeigManagerV1_3", {
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

   //==== DepositManager =================================

   const DepositManagerDeployment = await deploy("DepositManager", {
        from: deployer,
        args: [],
        log: true
    });

    const DepositManagerV1_1Deployment = await deploy("DepositManagerV1_1", {
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

    //==== DAOAgendaManager =================================

    const DAOAgendaManagerDeployment = await deploy("DAOAgendaManager",{
        contract:
        {
            abi: DAOAgendaManager_JSON.abi,
            bytecode: DAOAgendaManager_JSON.bytecode,
            // deployedBytecode: DAOAgendaManager_JSON.deployedBytecode
        },
        from: deployer,
        args: [],
        log: true
    });


    const daoAgendaManager = (await hre.ethers.getContractAt(
        DAOAgendaManagerDeployment.abi,
        DAOAgendaManagerDeployment.address
    ))

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

    //==== DAOVault =================================

    const DAOVaultDeployment = await deploy("DAOVault",{
        contract:
        {
            abi: DAOVault_JSON.abi,
            bytecode: DAOVault_JSON.bytecode,
            // deployedBytecode: DAOVault_JSON.deployedBytecode
        },
        from: deployer,
        args: [
            tokenInfos.ton,
            tokenInfos.wton
        ],
        log: true
    });

    const daoVault = (await hre.ethers.getContractAt(
        DAOVaultDeployment.abi,
        DAOVaultDeployment.address
    ))


    //==== MultiSigWallet ================================

    const MultiSigWalletDeployment = await deploy("MultiSigWallet", {
        contract: {
            abi: MultiSigWallet_JSON.abi,
            bytecode: MultiSigWallet_JSON.bytecode,
            // deployedBytecode: MultiSigWallet_JSON.deployedBytecode
        },
        from: deployer,
        args: [ MultiSigWalletOwners ],
        log: true
    });

    //==== DAOCommitteeProxy ================================

    const DAOCommittee_V1Deployment = await deploy("DAOCommittee_V1", {
        from: deployer,
        args: [],
        log: true
    });

    const DAOCommitteeOwnerDeployment = await deploy("DAOCommitteeOwner", {
        from: deployer,
        args: [],
        log: true
    });

    const DAOCommitteeProxy2Deployment = await deploy("DAOCommitteeProxy2", {
        from: deployer,
        args: [],
        log: true
    });

    const DAOCommitteeProxyDeployment = await deploy("DAOCommitteeProxy",{
        contract:
        {
            abi: DAOCommitteeProxy_JSON.abi,
            bytecode: DAOCommitteeProxy_JSON.bytecode,
            // deployedBytecode: DAOCommitteeProxy_JSON.deployedBytecode
        },
        from: deployer,
        args: [
            tokenInfos.ton,
            DAOCommitteeProxy2Deployment.address,
            seigManagerProxy.address,
            layer2RegistryProxy.address,
            daoAgendaManager.address,
            candidateFactory.address,
            daoVault.address
        ],
        log: true
    });

    //==== DAOCommitteeProxy upgradeTo DAOCommitteeProxy2 =======================================

    const daoCommitteeProxy = (await hre.ethers.getContractAt(
        DAOCommitteeProxyDeployment.abi,
        DAOCommitteeProxyDeployment.address
    ))

    // let daoCommitteeProxyImpl = await daoCommitteeProxy.implementation()
    // if (daoCommitteeProxyImpl != DAOCommitteeProxy2Deployment.address) {
    //     await (await daoCommitteeProxy.connect(deploySigner).upgradeTo(DAOCommitteeProxy2Deployment.address)).wait()
    // }

    //==== DAOCommitteeProxy2 upgradeTo =======================================

    const daoCommitteeProxy2 = (await hre.ethers.getContractAt(
        DAOCommitteeProxy2Deployment.abi,
        daoCommitteeProxy.address
    ))
    let daoCommitteeProxy2Impl = await daoCommitteeProxy2.implementation()
    if (daoCommitteeProxy2Impl != DAOCommittee_V1Deployment.address) {
        await (await daoCommitteeProxy2.connect(deploySigner).upgradeTo2(DAOCommittee_V1Deployment.address)).wait()
    }

    //==== DAOCommitteeProxy setFunctions DAOCommitteeOwner =======================================

    const selector01 = encodeFunctionSignature("setCooldownTime(uint256)");
    const selector02 = encodeFunctionSignature("setCandidateAddOnFactory(address)");
    const selector03 = encodeFunctionSignature("setLayer2Manager(address)");
    const selector04 = encodeFunctionSignature("setSeigManager(address)");
    const selector05 = encodeFunctionSignature("setDaoVault(address)");
    const selector06 = encodeFunctionSignature("setLayer2Registry(address)");
    const selector07 = encodeFunctionSignature("setAgendaManager(address)");
    const selector08 = encodeFunctionSignature("setCandidateFactory(address)");
    const selector09 = encodeFunctionSignature("setTon(address)");
    const selector10 = encodeFunctionSignature("setWton(address)");
    const selector11 = encodeFunctionSignature("increaseMaxMember(uint256,uint256)");
    const selector12 = encodeFunctionSignature("setQuorum(uint256)");
    const selector13 = encodeFunctionSignature("decreaseMaxMember(uint256,uint256)");
    const selector14 = encodeFunctionSignature("setActivityRewardPerSecond(uint256)");
    const selector15 = encodeFunctionSignature("daoExecuteTransaction(address,bytes)");
    const selector16 = encodeFunctionSignature("setCandidatesSeigManager(address[],address)");
    const selector17 = encodeFunctionSignature("setCandidatesCommittee(address[],address)");
    const selector18 = encodeFunctionSignature("setBurntAmountAtDAO(uint256)");

    let function01 = await daoCommitteeProxy2.getSelectorImplementation2(selector01)
    if (function01 == DAOCommittee_V1Deployment.address) {
        let functionBytecodes = [
            selector01, selector02, selector03, selector04, selector05,
            selector06, selector07, selector08, selector09, selector10,
            selector11, selector12, selector13, selector14, selector15,
            selector16, selector17, selector18
        ];

        await (await daoCommitteeProxy2.connect(deploySigner).setImplementation2(
            DAOCommitteeOwnerDeployment.address,
            1,
            true
        )).wait();

        await (await daoCommitteeProxy2.connect(deploySigner).setSelectorImplementations2(
            functionBytecodes,
            DAOCommitteeOwnerDeployment.address
        )).wait();

        const logic0 = await daoCommitteeProxy2.getSelectorImplementation2(selector01)
        // console.log('DAOCommitteeProxy setCooldown() logic : ', logic0);
    }

    //==== DAOCommitteeProxy Setting =======================================

    const daoCommitteeOwner = (await hre.ethers.getContractAt(
        DAOCommitteeOwnerDeployment.abi,
        daoCommitteeProxy.address
    ))

    let ton: string = await daoCommitteeOwner.ton()

    if ( ton.toLowerCase() !== (tokenInfos.ton.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setTon(tokenInfos.ton)).wait();
    }
    let wton = await daoCommitteeOwner.wton()
    if ( wton.toLowerCase() != (tokenInfos.wton.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setWton(tokenInfos.wton)).wait();
    }
    let maxMember = await daoCommitteeOwner.maxMember()
    if ( maxMember != daoInfos.maxMember ) {
        await (await daoCommitteeOwner.connect(deploySigner).increaseMaxMember(
            daoInfos.maxMember,
            daoInfos.quorum
        )).wait();
    }
    let activityRewardPerSecond = await daoCommitteeOwner.activityRewardPerSecond()
    if ( activityRewardPerSecond != daoInfos.activityRewardPerSecond ) {
        await (await daoCommitteeOwner.connect(deploySigner).setActivityRewardPerSecond(
            daoInfos.activityRewardPerSecond
        )).wait();
    }
    let cooldownTime = await daoCommitteeOwner.cooldownTime()
    if ( cooldownTime != daoInfos.cooldownTime ) {
        await (await daoCommitteeOwner.connect(deploySigner).setCooldownTime(
            daoInfos.cooldownTime
        )).wait();
    }

    //==== WTON minter  =================================

    let seigInWton = await wtonContract.seigManager()
    if (seigInWton != seigManagerProxy.address) {
        await (await wtonContract.connect(deploySigner).setSeigManager(seigManagerProxy.address)).wait()
    }

    isMinter = await wtonContract.connect(deploySigner).isMinter(deploySigner.address)
    if (isMinter) {
        await (await wtonContract.connect(deploySigner).addMinter(seigManagerProxy.address)).wait()
        await (await wtonContract.connect(deploySigner).addMinter(daoCommitteeProxy.address)).wait()
        await (await wtonContract.connect(deploySigner)["renounceMinter()"]()).wait()
    }

    // //==== DAOAgendaManager =================================

    // const DAOAgendaManagerDeployment = await deploy("DAOAgendaManager",{
    //     contract:
    //     {
    //         abi: DAOAgendaManager_JSON.abi,
    //         bytecode: DAOAgendaManager_JSON.bytecode,
    //         // deployedBytecode: DAOAgendaManager_JSON.deployedBytecode
    //     },
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const daoAgendaManager = (await hre.ethers.getContractAt(
    //     DAOAgendaManagerDeployment.abi,
    //     DAOAgendaManagerDeployment.address
    // ))

    //==== DAOAgendaManager Setting =======================================


    let committee = await daoAgendaManager.committee()
    addr = daoCommitteeProxy.address;
    if ( committee.toLowerCase() != (addr.toLowerCase()) ) {
        await (await daoAgendaManager.connect(deploySigner).setCommittee(daoCommitteeProxy.address)).wait();
    }

    let createAgendaFees = await daoAgendaManager.createAgendaFees()
    if ( createAgendaFees != daoAgendaInfos.createAgendaFees ) {
        await (await daoAgendaManager.connect(deploySigner).setCreateAgendaFees(
            daoAgendaInfos.createAgendaFees
        )).wait();
    }
    let minimumNoticePeriodSeconds = await daoAgendaManager.minimumNoticePeriodSeconds()
    if ( minimumNoticePeriodSeconds != daoAgendaInfos.minimumNoticePeriodSeconds ) {
        await (await daoAgendaManager.connect(deploySigner).setMinimumNoticePeriodSeconds(
            daoAgendaInfos.minimumNoticePeriodSeconds
        )).wait();
    }

    let minimumVotingPeriodSeconds = await daoAgendaManager.minimumVotingPeriodSeconds()
    if ( minimumVotingPeriodSeconds != daoAgendaInfos.minimumVotingPeriodSeconds ) {
        await (await daoAgendaManager.connect(deploySigner).setMinimumVotingPeriodSeconds(
            daoAgendaInfos.minimumVotingPeriodSeconds
        )).wait();
    }

    let executingPeriodSeconds = await daoAgendaManager.executingPeriodSeconds()
    if ( executingPeriodSeconds != daoAgendaInfos.executingPeriodSeconds ) {
        await (await daoAgendaManager.connect(deploySigner).setExecutingPeriodSeconds(
            daoAgendaInfos.executingPeriodSeconds
        )).wait();
    }

    let agendaManager = await daoCommitteeOwner.agendaManager()
    addr = daoAgendaManager.address;
    if ( agendaManager.toLowerCase() != (addr.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setAgendaManager(daoAgendaManager.address)).wait();
    }
    // //==== DAOVault =================================

    // const DAOVaultDeployment = await deploy("DAOVault",{
    //     contract:
    //     {
    //         abi: DAOVault_JSON.abi,
    //         bytecode: DAOVault_JSON.bytecode,
    //         // deployedBytecode: DAOVault_JSON.deployedBytecode
    //     },
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const daoVault = (await hre.ethers.getContractAt(
    //     DAOVaultDeployment.abi,
    //     DAOVaultDeployment.address
    // ))



    //==== DAOVault Setting =======================================


    let ton_ = await daoVault.ton()
    if ( ton_.toLowerCase() != (tokenInfos.ton.toLowerCase()) ) {
        await (await daoVault.connect(deploySigner).setTON(tokenInfos.ton)).wait();
    }


    let wton_ = await daoVault.wton()
    if ( wton_.toLowerCase() != (tokenInfos.wton.toLowerCase()) ) {
        await (await daoVault.connect(deploySigner).setWTON(tokenInfos.wton)).wait();
    }

    //---- DAO.setDaoVault

    let daoVaultAddress = await daoCommitteeOwner.daoVault()
    let addr1 = daoVault.address;
    if ( daoVaultAddress.toLowerCase() != (addr1.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setDaoVault(daoVault.address)).wait();
    }
    // //==== SeigManager =================================

    // const SeigManagerV1_2Deployment = await deploy("SeigManagerV1_2", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const SeigManagerV1_3Deployment = await deploy("SeigManagerV1_3", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const SeigManagerProxyDeployment = await deploy("SeigManagerProxy", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const seigManagerProxy = (await hre.ethers.getContractAt(
    //     SeigManagerProxyDeployment.abi,
    //     SeigManagerProxyDeployment.address
    // )) as SeigManagerProxy;


    //---- DAO.setSeigManager

    let seigManagerInDao = await daoCommitteeOwner.seigManager()
    addr = seigManagerProxy.address;
    if ( seigManagerInDao.toLowerCase() != (addr.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setSeigManager(seigManagerProxy.address)).wait();
    }

    //==== SeigManagerProxy upgradeTo =======================================

    let seigManagerImpl = await seigManagerProxy.implementation()
    if (seigManagerImpl != SeigManagerV1_2Deployment.address) {
        await (await seigManagerProxy.connect(deploySigner).upgradeTo(SeigManagerV1_2Deployment.address)).wait()
    }

    //==== SeigManagerProxy setFunctions =======================================

    const selector1 = encodeFunctionSignature("updateSeigniorage()");
    const selector2 = encodeFunctionSignature("updateSeigniorageLayer(address)");
    const selector3 = encodeFunctionSignature("estimatedDistribute(uint256,address)");
    const selector4 = encodeFunctionSignature("excludeFromL2Seigniorage(address)");
    const selector5 = encodeFunctionSignature("includeFromL2Seigniorage(address)");
    const selector6 = encodeFunctionSignature("claimableL2Seigniorage(address)");
    const selector7 = encodeFunctionSignature("pause()");
    const selector8 = encodeFunctionSignature("unpause()");

    let function0 = await seigManagerProxy.getSelectorImplementation2(selector1)
    if (function0 == SeigManagerV1_2Deployment.address) {

        let functionBytecodes = [
            selector1, selector2, selector3, selector4, selector5,
            selector6, selector7, selector8
        ];

        await (await seigManagerProxy.connect(deploySigner).setImplementation2(
            SeigManagerV1_3Deployment.address,
            1,
            true
        )).wait();


        await (await seigManagerProxy.connect(deploySigner).setSelectorImplementations2(
            functionBytecodes, SeigManagerV1_3Deployment.address)).wait();
        const logic0 = await seigManagerProxy.getSelectorImplementation2(selector1)
        // console.log('updateSeigniorage() logic : ', logic0);
    }

    // //==== DepositManager =================================
    // const DepositManagerDeployment = await deploy("DepositManager", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const DepositManagerV1_1Deployment = await deploy("DepositManagerV1_1", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const DepositManagerProxyDeployment = await deploy("DepositManagerProxy", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const depositManagerProxy = (await hre.ethers.getContractAt(
    //     DepositManagerProxyDeployment.abi,
    //     DepositManagerProxyDeployment.address
    // )) as DepositManagerProxy;


    //==== DepositManagerProxy upgradeTo =======================================
    let depositManagerImpl = await depositManagerProxy.implementation()
    if (depositManagerImpl != DepositManagerDeployment.address) {
        await (await depositManagerProxy.connect(deploySigner).upgradeTo(DepositManagerDeployment.address)).wait()
    }

    //==== DepositManagerProxy setFunctions =======================================

    const selector_1 = encodeFunctionSignature("ton()");
    const selector_2 = encodeFunctionSignature("minDepositGasLimit()");
    const selector_3 = encodeFunctionSignature("setMinDepositGasLimit(uint32)");
    const selector_4 = encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");
    const selector_5 = encodeFunctionSignature("l1BridgeRegistry()");
    const selector_6 = encodeFunctionSignature("layer2Manager()");
    const selector_7 = encodeFunctionSignature("setAddresses(address,address)");
    const selector_8 = encodeFunctionSignature("requestWithdrawal(address,uint256)");


    let function_0 = await depositManagerProxy.getSelectorImplementation2(selector_4)
    if (function_0 == DepositManagerDeployment.address) {

        let functionBytecodes_1 = [ selector_1, selector_2, selector_3, selector_4, selector_5, selector_6, selector_7, selector_8];

        await (await depositManagerProxy.connect(deploySigner).setImplementation2(
            DepositManagerV1_1Deployment.address,
            1,
            true
        )).wait();

        await (await depositManagerProxy.connect(deploySigner).setSelectorImplementations2(
            functionBytecodes_1,
            DepositManagerV1_1Deployment.address)
        ).wait();
        const logic0 = await depositManagerProxy.getSelectorImplementation2(selector_4)
        // console.log('withdrawAndDepositL2(address,uint256) logic : ', logic0);
    }

    // //==== Layer2Registry =================================

    // const Layer2RegistryDeployment = await deploy("Layer2Registry", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const Layer2RegistryProxyDeployment = await deploy("Layer2RegistryProxy", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const layer2RegistryProxy = (await hre.ethers.getContractAt(
    //     Layer2RegistryProxyDeployment.abi,
    //     Layer2RegistryProxyDeployment.address
    // )) as Layer2RegistryProxy;

    // let layer2RegistryImpl = await layer2RegistryProxy.implementation()
    // if (layer2RegistryImpl != Layer2RegistryDeployment.address) {
    //     await (await layer2RegistryProxy.connect(deploySigner).upgradeTo(Layer2RegistryDeployment.address)).wait()
    // }


    //---- DAO.setLayer2Registry

    let layer2RegistryInDao = await daoCommitteeOwner.layer2Registry()
    addr = layer2RegistryProxy.address;
    if ( layer2RegistryInDao.toLowerCase() != (addr.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setLayer2Registry(layer2RegistryProxy.address)).wait();
    }

    //==== Candidate =================================
    const CandidateDeployment = await deploy("Candidate", {
        from: deployer,
        args: [],
        log: true
    });

    // //==== CandidateFactory =================================
    // const CandidateFactoryDeployment = await deploy("CandidateFactory", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const CandidateFactoryProxyDeployment = await deploy("CandidateFactoryProxy", {
    //     from: deployer,
    //     args: [],
    //     log: true
    // });

    // const candidateFactoryProxy = (await hre.ethers.getContractAt(
    //     CandidateFactoryProxyDeployment.abi,
    //     CandidateFactoryProxyDeployment.address
    // )) as CandidateFactoryProxy;

    // let candidateFactoryImp = await candidateFactoryProxy.implementation()
    // if (candidateFactoryImp != CandidateFactoryDeployment.address) {
    //     await (await candidateFactoryProxy.connect(deploySigner).upgradeTo(CandidateFactoryDeployment.address)).wait()
    // }

    // const candidateFactory = (await hre.ethers.getContractAt(
    //     CandidateFactoryDeployment.abi,
    //     CandidateFactoryProxyDeployment.address
    // )) as CandidateFactory;

    //---- DAO.setCandidateFactory

    let candidateFactoryAddress = await daoCommitteeOwner.candidateFactory()
    addr = candidateFactory.address;
    if ( candidateFactoryAddress.toLowerCase() != (addr.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setCandidateFactory(candidateFactory.address)).wait();
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
    if (impl_l1BridgeRegistry != L1BridgeRegistryDeployment.address) {
        await (await l1BridgeRegistryProxy.connect(deploySigner).upgradeTo(L1BridgeRegistryDeployment.address)).wait()
    }

    const l1BridgeRegistry = (await hre.ethers.getContractAt(
        L1BridgeRegistryDeployment.abi,
        l1BridgeRegistryProxy.address
    )) as L1BridgeRegistryV1_1;


    //==== OperatorManagerFactory =========================
    const OperatorManagerV1_1Deployment = await deploy("OperatorManagerV1_1", {
        from: deployer,
        args: [],
        log: true
    });

    const OperatorManagerFactoryDeployment = await deploy("OperatorManagerFactory", {
        from: deployer,
        args: [OperatorManagerV1_1Deployment.address],
        log: true
    });

    const operatorManagerFactory = (await hre.ethers.getContractAt(
        OperatorManagerFactoryDeployment.abi,
        OperatorManagerFactoryDeployment.address
    )) as OperatorManagerFactory;

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


    //---- DAO.setCandidateAddOnFactory

    let candidateAddOnFactoryInDao = await daoCommitteeOwner.candidateAddOnFactory()
    addr = candidateAddOnFactoryProxy.address;
    if ( candidateAddOnFactoryInDao.toLowerCase() != (addr.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setCandidateAddOnFactory(candidateAddOnFactoryProxy.address)).wait();
    }

    //---------------

    let impl_candidateAddOnFactoryProxy = await candidateAddOnFactoryProxy.implementation()
    if (impl_candidateAddOnFactoryProxy != CandidateAddOnFactoryDeployment.address) {
        await (await candidateAddOnFactoryProxy.connect(deploySigner).upgradeTo(CandidateAddOnFactoryDeployment.address)).wait()
    }

    const candidateAddOnFactory = (await hre.ethers.getContractAt("CandidateAddOnFactory", candidateAddOnFactoryProxy.address, deploySigner)) as CandidateAddOnFactory

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



    //---- DAO.setLayer2Manager
    let layer2ManagerInDao = await daoCommitteeOwner.layer2Manager()
    addr = layer2ManagerProxy.address;
    if ( layer2ManagerInDao.toLowerCase() != (addr.toLowerCase()) ) {
        await (await daoCommitteeOwner.connect(deploySigner).setLayer2Manager(layer2ManagerProxy.address)).wait();
    }

    //-------

    let impl_layer2ManagerProxy = await layer2ManagerProxy.implementation()
    if (impl_layer2ManagerProxy != Layer2ManagerV1_1Deployment.address) {
        await (await layer2ManagerProxy.connect(deploySigner).upgradeTo(Layer2ManagerV1_1Deployment.address)).wait()
    }

    if (ownerAddressInfo.L1BridgeRegistry.manager != null || ownerAddressInfo.L1BridgeRegistry.manager != hre.ethers.constants.AddressZero  ) {
        let res = await l1BridgeRegistryProxy.isManager(ownerAddressInfo.L1BridgeRegistry.manager)
        if (res == false) {
            await (await l1BridgeRegistryProxy.connect(deploySigner).addManager(ownerAddressInfo.L1BridgeRegistry.manager)).wait()
        }
    }

    const layer2Manager = (await hre.ethers.getContractAt(
        Layer2ManagerV1_1Deployment.abi,
        Layer2ManagerProxy_1Deployment.address
    )) as Layer2ManagerV1_1;

    let minimumInitialDepositAmount_layer2Manager = await layer2Manager.minimumInitialDepositAmount()

    if (!(minimumInitialDepositAmount_layer2Manager.eq(minimumInitialDepositAmount))) {
        await (await layer2Manager.connect(deploySigner).setMinimumInitialDepositAmount(
            minimumInitialDepositAmount)
        ).wait()
    }


    //====== SeigManagerProxy Setting ==================
    const seigManagerV2 = (await hre.ethers.getContractAt(
        SeigManagerV1_2Deployment.abi,
        seigManagerProxy.address
    )) as SeigManagerV1_2;


    let tonInSeig = await seigManagerV2.ton()
    let block = await hre.ethers.provider.getBlock('latest')
    if (tonInSeig.toLowerCase() != tokenInfos.ton.toLowerCase()) {
        await (await seigManagerV2.connect(deploySigner).initialize(
            tokenInfos.ton,
            tokenInfos.wton,
            layer2RegistryProxy.address,
            depositManagerProxy.address,
            seigManagerInfo.seigPerBlock,
            coinageFactory.address,
            block.number
        )).wait()
    }

    let seigStartBlock = await seigManagerV2.seigStartBlock()
    if (seigStartBlock.eq(hre.ethers.constants.Zero)) {
        await (await seigManagerV2.setSeigStartBlock(block.number)).wait()
    }

    let burntAmountAtDAO = await seigManagerV2.burntAmountAtDAO()
    if (burntAmountAtDAO.eq(hre.ethers.constants.Zero)) {
        await (await seigManagerV2.setBurntAmountAtDAO(hre.ethers.constants.One)).wait()
    }

    let powerton_ = hre.ethers.constants.AddressZero
    let dao_ = daoVault.address

    let minimumAmount = await seigManagerV2.minimumAmount()
    if (minimumAmount != seigManagerInfo.minimumAmount) {
        await (await seigManagerV2.connect(deploySigner).setData(
            powerton_,
            dao_,
            seigManagerInfo.powerTONSeigRate,
            seigManagerInfo.daoSeigRate,
            seigManagerInfo.relativeSeigRate,
            seigManagerInfo.adjustCommissionDelay,
            seigManagerInfo.minimumAmount
        )).wait()
    }

    let l1BridgeRegistryInSeig = await seigManagerV2.l1BridgeRegistry()
    if (l1BridgeRegistryInSeig.toLowerCase() != l1BridgeRegistry.address.toLowerCase()) {
        await (await seigManagerV2.connect(deploySigner).setL1BridgeRegistry(
            l1BridgeRegistry.address
        )).wait()
    }

    let layer2ManagerInSeig = await seigManagerV2.layer2Manager()
    if (layer2ManagerInSeig.toLowerCase() != layer2Manager.address.toLowerCase()) {
        await (await seigManagerV2.connect(deploySigner).setLayer2Manager(
            layer2Manager.address
        )).wait()
    }

    //==== DepositManager SETTING =================================
    const depositManager = (await hre.ethers.getContractAt(
        DepositManagerDeployment.abi,
        depositManagerProxy.address
    )) as DepositManager;

    let wtonInDeposit = await depositManager.wton()
    if (wtonInDeposit.toLowerCase() != tokenInfos.wton.toLowerCase()) {
        await (await depositManager.connect(deploySigner).initialize(
            tokenInfos.wton,
            layer2RegistryProxy.address,
            seigManagerProxy.address,
            seigManagerInfo.globalWithdrawalDelay,
            hre.ethers.constants.AddressZero
        )).wait()
    }

    const depositManagerV1 = (await hre.ethers.getContractAt(
        DepositManagerV1_1Deployment.abi,
        depositManagerProxy.address
    )) as DepositManagerV1_1;

    let l1BridgeRegistryInDeposit = await depositManagerV1.l1BridgeRegistry()
    if (l1BridgeRegistryInDeposit.toLowerCase() != l1BridgeRegistry.address.toLowerCase()) {
        await (await depositManagerV1.connect(deploySigner).setAddresses(
            l1BridgeRegistry.address,
            layer2Manager.address
        )).wait()
    }

    //==== Layer2Manager setAddresses =================================

    let l1BridgeRegistry_layer2Manager = await layer2Manager.l1BridgeRegistry()
    if (l1BridgeRegistry_layer2Manager != l1BridgeRegistryProxy.address) {
        await (await layer2Manager.connect(deploySigner).setAddresses(
                l1BridgeRegistryProxy.address,
                operatorManagerFactory.address,
                tokenInfos.ton,
                tokenInfos.wton,
                daoCommitteeProxy.address,
                depositManagerProxy.address,
                seigManagerProxy.address,
                swapProxy
            )
        ).wait()
    }


    //==== l1BridgeRegistry setAddresses =================================
    let ton_l1BridgeRegistry = await l1BridgeRegistry.ton()
    if ((tokenInfos.ton).toLowerCase() != ton_l1BridgeRegistry.toLowerCase()) {
        await (await l1BridgeRegistry.connect(deploySigner).setAddresses(
            layer2Manager.address,
            seigManagerProxy.address,
            tokenInfos.ton
            )).wait()
    }


    // operatorManagerFactory.setAddresses
    let ton_operatorManagerFactory = await operatorManagerFactory.ton()
    if (tokenInfos.ton != ton_operatorManagerFactory) {
        await (await operatorManagerFactory.connect(deploySigner).setAddresses(
            depositManagerProxy.address,
            tokenInfos.ton,
            tokenInfos.wton,
            layer2ManagerProxy.address
        )).wait()
    }

    //====== candidateAddOnFactory setAddress ==================
    let layer2CandidateImp_layer2CandidateFactory = await candidateAddOnFactory.candidateAddOnImp()

    if (Layer2CandidateV1_1Deployment.address != layer2CandidateImp_layer2CandidateFactory) {
        await (await candidateAddOnFactory.connect(deploySigner).setAddress(
            depositManagerProxy.address,
            daoCommitteeProxy.address,
            Layer2CandidateV1_1Deployment.address,
            tokenInfos.ton,
            tokenInfos.wton,
            l1BridgeRegistryProxy.address
        )).wait()
    }

    //====== candidateFactory setAddress ==================
    let candidateDeploymentAddress = await candidateFactory.candidateImp()
    if (candidateDeploymentAddress != CandidateDeployment.address ) {
        await (await candidateFactory.connect(deploySigner).setAddress (
            depositManagerProxy.address,
            daoCommitteeProxy.address,
            CandidateDeployment.address,
            tokenInfos.ton,
            tokenInfos.wton,
          )).wait()
    }


    //====== layer2RegistryV2 addMinter ==================
    let isMinter1 = await layer2RegistryProxy.isMinter(daoCommitteeProxy.address)
    if (isMinter1 == false) {
        await (await layer2RegistryProxy.connect(deploySigner).addMinter(
            daoCommitteeProxy.address
          )).wait()
    }

    //====== seigManagerV2 addMinter ==================
    let isMinter2 = await seigManagerProxy.isMinter(layer2RegistryProxy.address)
    if (isMinter2 == false) {
        await (await seigManagerProxy.connect(deploySigner).addMinter(
            layer2RegistryProxy.address
          )).wait()
    }

    //====== L1BridgeRegistryV1_1  addManager ==================
    let isManager = await l1BridgeRegistryProxy.isManager(daoCommitteeProxy.address)
    if (!isManager) {
        await (await l1BridgeRegistryProxy.connect(deploySigner).addManager(daoCommitteeProxy.address)).wait();
    }

    //====== L1BridgeRegistryV1_1  setSeigniorageCommittee ==================
    let seigniorageCommittee = await l1BridgeRegistryProxy.seigniorageCommittee()
    if (seigniorageCommittee.toLowerCase() != daoCommitteeProxy.address.toLowerCase()) {
        await (await l1BridgeRegistry.connect(deploySigner).setSeigniorageCommittee(daoCommitteeProxy.address)).wait();
    }


    //======= TransferOwner to DAOCommittee ======================================

    // await (await candidateAddOnFactoryProxy.connect(deploySigner).transferOwnership(daoCommitteeProxy.address)).wait()
    // await (await operatorManagerFactory.connect(deploySigner).transferOwnership(daoCommitteeProxy.address)).wait()
    // await (await l1BridgeRegistryProxy.connect(deploySigner).transferAdmin(daoCommitteeProxy.address)).wait()
    // await (await layer2ManagerProxy.connect(deploySigner).transferOwnership(daoCommitteeProxy.address)).wait()


    // console.log("candidateAddOnFactoryProxy.isAdmin(deployer): ", await candidateAddOnFactoryProxy.isAdmin(deployer))
    // console.log("candidateAddOnFactoryProxy.isAdmin(DAOCommitteeProxy): ", await candidateAddOnFactoryProxy.isAdmin(daoCommitteeProxy.address))

    // console.log("operatorManagerFactory.owner(): ", await operatorManagerFactory.owner())

    // console.log("l1BridgeRegistryProxy.isAdmin(deployer): ", await l1BridgeRegistryProxy.isAdmin(deployer))
    // console.log("l1BridgeRegistryProxy.isAdmin(DAOCommitteeProxy): ", await l1BridgeRegistryProxy.isAdmin(daoCommitteeProxy.address))

    // console.log("layer2ManagerProxy.isAdmin(deployer): ", await layer2ManagerProxy.isAdmin(deployer))
    // console.log("layer2ManagerProxy.isAdmin(DAOCommitteeProxy): ", await layer2ManagerProxy.isAdmin(daoCommitteeProxy.address))


    //==== verify =================================
    if (hre.network.name != "hardhat" && hre.network.name != "local") {
        await hre.run("etherscan-verify", {
            network: hre.network.name
        });
    }
}

export default deployTonStakingV2;