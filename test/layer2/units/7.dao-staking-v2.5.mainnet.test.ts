import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts, deployments} from 'hardhat'

import { mine, time } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import {encodeFunctionSignature, encodeParameters} from 'web3-eth-abi'
import { marshalString, unmarshalString } from '../../shared/marshal';

import { L1BridgeRegistryProxy } from "../../../typechain-types/contracts/layer2/L1BridgeRegistryProxy"
import { L1BridgeRegistryV1_1 } from "../../../typechain-types/contracts/layer2/L1BridgeRegistryV1_1.sol"

import { Layer2ManagerProxy } from "../../../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../../../typechain-types/contracts/layer2/Layer2ManagerV1_1.sol"
import { OperatorManagerFactory } from "../../../typechain-types/contracts/layer2/factory/OperatorManagerFactory.sol"
import { OperatorManagerV1_1 } from "../../../typechain-types/contracts/layer2/OperatorManagerV1_1.sol"
import { DAOCommitteeAddV1_1 } from "../../../typechain-types/contracts/dao/DAOCommitteeAddV1_1.sol"
import { CandidateAddOnFactoryProxy } from "../../../typechain-types/contracts/dao/factory/CandidateAddOnFactoryProxy"
import { CandidateAddOnFactory } from "../../../typechain-types/contracts/dao/factory/CandidateAddOnFactory.sol"

import { CandidateAddOnV1_1 } from "../../../typechain-types/contracts/dao/CandidateAddOnV1_1.sol"
import { LegacySystemConfig } from "../../../typechain-types/contracts/layer2/LegacySystemConfig"
import { SeigManagerV1_3 } from "../../../typechain-types/contracts/stake/managers/SeigManagerV1_3.sol"
import { DepositManagerV1_1 } from "../../../typechain-types/contracts/stake/managers/DepositManagerV1_1.sol"

import { DAOCommitteeProxy2 } from "../../../typechain-types/contracts/proxy/DAOCommitteeProxy2"
import { DAOCommittee_V1 } from "../../../typechain-types/contracts/dao/DAOCommittee_V1.sol"
import { DAOCommitteeOwner } from "../../../typechain-types/contracts/dao/DAOCommitteeOwner.sol"
import { Candidate } from "../../../typechain-types/contracts/dao/Candidate.sol"

import { MockSystemConfigFactory } from "../../../typechain-types/contracts/mocks/MockSystemConfigFactory.sol"
import { MockSystemConfig } from "../../../typechain-types/contracts/mocks/MockSystemConfig.sol"

import Ton_Json from '../../abi/TON.json'
import Wton_Json from '../../abi/WTON.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'
import DAOCommitteeAddV1_1_Json from '../../abi/DAOCommitteeAddV1_1.json'
import SeigManager_Json from '../../abi/SeigManagerV1.json'
import SeigManagerProxy_Json from '../../abi/SeigManagerProxy.json'
import DepositManagerProxy_Json from '../../abi/DepositManagerProxy.json'

import DepositManager_Json from '../../abi/DepositManager.json'
import DAOCommitteeOwner_Json from '../../abi/DAOCommitteeOwner.json'
import DAOCandidate_Json from '../../abi/Candidate.json'

import LegacySystemConfig_Json from '../../abi/LegacySystemConfig.json'
import MockSystemConfig_Json from '../../abi/MockSystemConfig.json'
import MockL1StandardBridge_Json from '../../abi/MockL1StandardBridge.json'

import DAOAgendaManager_Json from '../../abi/DAOAgendaManager.json'
import DAOCommittee_V1_Json from '../../abi/DAOCommittee_.json'
import Candidate_Json from '../../abi/Candidate.json'
import DAOCommitteeProxy2_Josn from '../../abi/DAOCommitteeProxy2.json'

const layers = [
    {"oldLayer":"0x42ccf0769e87cb2952634f607df1c7d62e0bbc52","newLayer":"0x0F42D1C40b95DF7A1478639918fc358B4aF5298D","operator":"0xd1820b18be7f6429f1f44104e4e15d16fb199a43","name":"level"},
    {"oldLayer":"0x39a13a796a3cd9f480c28259230d2ef0a7026033","newLayer":"0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF","operator":"0xea8e2ec08dcf4971bdcdfffe21439995378b44f3","name":"tokamak1"},
    {"oldLayer":"0x41fb4bad6fba9e9b6e45f3f96ba3ad7ec2ff5b3c","newLayer":"0x44e3605d0ed58FD125E9C47D1bf25a4406c13b57","operator":"0x566b98a715ef8f60a93a208717d9182310ac3867","name":"DXM Corp"},
    {"oldLayer":"0xbc8896ebb2e3939b1849298ef8da59e09946cf66","newLayer":"0x2B67D8D4E61b68744885E243EfAF988f1Fc66E2D","operator":"0x8dfcbc1df9933c8725618015d10b7b6de2d2c6f8","name":"DSRV"},
    {"oldLayer":"0xcc38c7aaf2507da52a875e93f57451e58e8c6372","newLayer":"0x2c25A6be0e6f9017b5bf77879c487eed466F2194","operator":"0x247a0829c63c5b40dc6b21cf412f80227dc7fb76","name":"staked"},
    {"oldLayer":"0x17602823b5fe43a65ad7122946a73b019e77fd33","newLayer":"0xbc602C1D9f3aE99dB4e9fD3662CE3D02e593ec5d","operator":"0xba33eddfd3e4e155a6da10281d9069bf44743228","name":"decipher"},
    {"oldLayer":"0x2000fc16911fc044130c29c1aa49d3e0b101716a","newLayer":"0xC42cCb12515b52B59c02eEc303c887C8658f5854","operator":"0xfc9c403993bea576c28ac901bd62640bff8b057a","name":"DeSpread"},
    {"oldLayer":"0x97d0a5880542ab0e699c67e7f4ff61f2e5200484","newLayer":"0xf3CF23D896Ba09d8EcdcD4655d918f71925E3FE5","operator":"0x887af02970781a088962dbaa299a1eba8d573321","name":"Danal Fintech"},
    {"oldLayer":"0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764","newLayer":"0x06D34f65869Ec94B3BA8c0E08BCEb532f65005E2","operator":"0x42adfaae7db56b294225ddcfebef48b337b34b23","name":"Hammer DAO"},
    {"oldLayer":"0xb9d336596ea2662488641c4ac87960bfdcb94c6e","newLayer":"0x36101b31e74c5E8f9a9cec378407Bbb776287761","operator":"0xcc2f386adca481a00d614d5aa77a30984f264a07","name":"Talken"},
]

let thanosSystemConfigOwnerAddress = "0x9E628CaAd7A6dD3ce48E78812241B41BdbeF6244"
let thanosSystemConfigOwner: Signer

let pastAddr = "0x3bFda92Fa3bC0AB080Cac3775147B6318b1C5115"
let wtonhaveAddr = "0x735985022e5EF7BeFA272986FdFB7dE6aC675ed8"
let tonHaveAddr = "0x7897ccD146b97639c0Dd99A17383e0b11681996E"

const daoOwnerAddress = "0xB4983DA083A5118C903910DB4f5a480B1D9f3687"
let tonMinterAddress = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
let tonMinter: Signer
let seigniorageCommitteeAddress = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
let seigniorageCommittee: Signer
let titanManager: Signer

let ownerAddressInfo =  {
    L2BridgeRegistry: {
        owner: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
        manager: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
    },
    Layer2Manager: {
        owner: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
    },
    OperatorManagerFactory: {
        owner: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
    },
    Titan : {
        MultiProposerableTransactionExecutor: "0x014E38eAA7C9B33FeF08661F8F0bFC6FE43f1496"
    }
}

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

describe('Layer2Manager', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorManagerV1_1:OperatorManagerV1_1 , operatorManagerFactory: OperatorManagerFactory, daoCommitteeAddV1_1: DAOCommitteeAddV1_1

    let candidateAddOnV1_1Imp: CandidateAddOnV1_1
    let candidateAddOnFactoryImp:CandidateAddOnFactory , candidateAddOnFactoryProxy: CandidateAddOnFactoryProxy, candidateAddOnFactory: CandidateAddOnFactory
    let tonContract: Contract, wtonContract: Contract, daoContract: Contract, daoV2Contract: Contract
    let depositManager: Contract,  depositManagerProxy: Contract, seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3;
    let depositManagerV1_1: DepositManagerV1_1;

    let daoAdmin: Signer;
    let daoOwner: Signer;

    let titanLayerAddress: string, titanOperatorContractAddress: string;
    let titanLayerContract: CandidateAddOnV1_1;
    let titanOperatorContract: OperatorManagerV1_1

    let pastDepositor:Signer, wtonHave:Signer, tonHave:Signer
    let layer2Info_1 : any;
    let layer2Info_2 : any;

    let daoAgendaManagerContract: Contract
    let daoCommitteeProxy2Contract: DAOCommitteeProxy2
    let daoCommittee_V1: DAOCommittee_V1
    let daoCommitteeOwner: DAOCommitteeOwner
    let daoCommitteeContract:  Contract
    let agendaId: BigNumber

    // const daoOwnerAddress = "0xb4983da083a5118c903910db4f5a480b1d9f3687"

    before('create fixture loader', async () => {
        const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, DAOAgendaManager } = await getNamedAccounts();

        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        manager = accounts[1]
        addr1 = accounts[2]
        addr2 = accounts[3]
        layer2Info_1 = {
            operatorAdmin: layers[0].operator,
            isLayer2Candidate: false,
            name: layers[0].name,
            layer2: layers[0].newLayer,
            operator: layers[0].operator,
            layerContract: null,
            coinageContract: null
        }

        layer2Info_2 = {
            operatorAdmin: layers[1].operator,
            isLayer2Candidate: false,
            name: layers[1].name,
            layer2:  layers[1].newLayer,
            operator: layers[1].operator,
            layerContract: null,
            coinageContract: null
        }

        await network.provider.send("hardhat_impersonateAccount", [
            DAOCommitteeProxy,
        ]);

        await network.provider.send("hardhat_setBalance", [
            DAOCommitteeProxy,
            "0x10000000000000000000000000",
        ]);
        await network.provider.send("hardhat_impersonateAccount", [
            daoOwnerAddress,
        ]);

        await network.provider.send("hardhat_setBalance", [
            daoOwnerAddress,
            "0x10000000000000000000000000",
        ]);

        daoAdmin = await ethers.getSigner(DAOCommitteeProxy);
        daoOwner = await ethers.getSigner(daoOwnerAddress);
        daoAgendaManagerContract = new ethers.Contract(DAOAgendaManager, DAOAgendaManager_Json.abi,  deployer)
        tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)
        wtonContract = new ethers.Contract(WTON,  Wton_Json.abi, deployer)
        daoContract = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeProxy_Json.abi, deployer)
        depositManager = new ethers.Contract(DepositManager,  DepositManager_Json.abi, deployer)
        depositManagerProxy = new ethers.Contract(DepositManager,  DepositManagerProxy_Json.abi, deployer)

        seigManager = new ethers.Contract(SeigManager,  SeigManager_Json.abi, deployer)
        seigManagerProxy = new ethers.Contract(SeigManager,  SeigManagerProxy_Json.abi, deployer)
        // tonContract.connect(daoAdmin).mint(addr1, utils.parseEther("2000"))
        // wtonContract.connect(daoAdmin).mint(addr1, utils.parseEther("2000"))

        await hre.network.provider.send("hardhat_impersonateAccount", [
            pastAddr,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            pastAddr,
            "0x10000000000000000000000000",
        ]);
        pastDepositor = await hre.ethers.getSigner(pastAddr);

        let wtonhaveAddr = "0x735985022e5EF7BeFA272986FdFB7dE6aC675ed8"

        await hre.network.provider.send("hardhat_impersonateAccount", [
            wtonhaveAddr,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            wtonhaveAddr,
            "0x10000000000000000000000000",
        ]);
        wtonHave = await hre.ethers.getSigner(wtonhaveAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            tonHaveAddr,
        ]);

        tonHave = await hre.ethers.getSigner(tonHaveAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            seigniorageCommitteeAddress,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            seigniorageCommitteeAddress,
            "0x10000000000000000000000000",
        ]);
        seigniorageCommittee = await hre.ethers.getSigner(seigniorageCommitteeAddress);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            ownerAddressInfo.Titan.MultiProposerableTransactionExecutor,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            ownerAddressInfo.Titan.MultiProposerableTransactionExecutor,
            "0x10000000000000000000000000",
        ]);
        titanManager =  await hre.ethers.getSigner(ownerAddressInfo.Titan.MultiProposerableTransactionExecutor);

    })

    describe('# Tester', () => {
        it('mint ton', async () => {

            await (await tonContract.connect(daoAdmin).mint(addr1.address, ethers.utils.parseEther("2000"))).wait()
            await (await tonContract.connect(daoAdmin).mint(addr2.address, ethers.utils.parseEther("2000"))).wait()

        })
    })

    describe('# Contracts from deployments', () => {
        it('deployments', async () => {
            await deployments.fixture();
            let deployed = await deployments.all()
            l1BridgeRegistryProxy = (await ethers.getContractAt("L1BridgeRegistryProxy", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryProxy
            l1BridgeRegistry = (await ethers.getContractAt("L1BridgeRegistryV1_1", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryV1_1
            operatorManagerFactory = (await ethers.getContractAt("OperatorManagerFactory", deployed.OperatorManagerFactory.address, deployer)) as OperatorManagerFactory;
            candidateAddOnFactoryProxy = (await ethers.getContractAt("CandidateAddOnFactoryProxy", deployed.CandidateAddOnFactoryProxy.address, deployer)) as CandidateAddOnFactoryProxy;
            candidateAddOnFactory = (await ethers.getContractAt("CandidateAddOnFactory", deployed.CandidateAddOnFactoryProxy.address, deployer)) as CandidateAddOnFactory;

            layer2ManagerProxy = (await ethers.getContractAt("Layer2ManagerProxy", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerProxy;
            layer2Manager = (await ethers.getContractAt("Layer2ManagerV1_1", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerV1_1;

            seigManagerV1_3 = (await ethers.getContractAt("SeigManagerV1_3", deployed.SeigManagerV1_3.address, deployer)) as SeigManagerV1_3;
            depositManagerV1_1 = (await ethers.getContractAt("DepositManagerV1_1", deployed.DepositManagerV1_1.address, deployer)) as DepositManagerV1_1;
            daoCommitteeProxy2Contract = (await ethers.getContractAt("DAOCommitteeProxy2", deployed.DAOCommitteeProxy2.address, deployer)) as DAOCommitteeProxy2;
            daoCommitteeOwner = (await ethers.getContractAt("DAOCommitteeOwner", deployed.DAOCommitteeOwner.address, deployer)) as DAOCommitteeOwner;
            daoCommittee_V1 = (await ethers.getContractAt("DAOCommittee_V1", deployed.DAOCommittee_V1.address, deployer)) as DAOCommittee_V1;
            legacySystemConfig = (await ethers.getContractAt("LegacySystemConfig", deployed.LegacySystemConfig.address, deployer )) as LegacySystemConfig;

            // console.log('l1BridgeRegistryProxy', l1BridgeRegistryProxy.address)
            // console.log('l1BridgeRegistry', l1BridgeRegistry.address)
            // console.log('operatorManagerFactory', operatorManagerFactory.address)

            // console.log('candidateAddOnFactoryProxy', candidateAddOnFactoryProxy.address)
            // console.log('candidateAddOnFactory', candidateAddOnFactory.address)

            // console.log('candidateAddOnFactoryProxy', candidateAddOnFactoryProxy.address)
            // console.log('candidateAddOnFactory', candidateAddOnFactory.address)

            // console.log('seigManagerV1_3', seigManagerV1_3.address)
            // console.log('depositManagerV1_1', depositManagerV1_1.address)
            // console.log('daoCommitteeProxy2Contract', daoCommitteeProxy2Contract.address)
            // console.log('daoCommitteeOwner', daoCommitteeOwner.address)
            // console.log('daoCommittee_V1', daoCommittee_V1.address)
        })
    })

    describe('# TransferOwner to DAOCommittee ', () => {

        it('CandidateAddOnFactoryProxy ', async () => {
            const {DAOCommitteeProxy} = await getNamedAccounts();
            await (await candidateAddOnFactoryProxy.connect(deployer).transferOwnership(DAOCommitteeProxy)).wait()

            expect(await candidateAddOnFactoryProxy.isAdmin(deployer.address)).to.be.eq(false)
            expect(await candidateAddOnFactoryProxy.isAdmin(DAOCommitteeProxy)).to.be.eq(true)
        });

        it('operatorManagerFactory ', async () => {
            const {DAOCommitteeProxy} = await getNamedAccounts();
            await (await operatorManagerFactory.connect(deployer).transferOwnership(DAOCommitteeProxy)).wait()
            expect(await operatorManagerFactory.owner()).to.be.eq(DAOCommitteeProxy)
        });

        it('L1BridgeRegistryProxy ', async () => {
            const {DAOCommitteeProxy} = await getNamedAccounts();
            await (await l1BridgeRegistryProxy.connect(deployer).transferOwnership(DAOCommitteeProxy)).wait()
            expect(await l1BridgeRegistryProxy.isAdmin(deployer.address)).to.be.eq(false)
            expect(await l1BridgeRegistryProxy.isAdmin(DAOCommitteeProxy)).to.be.eq(true)
        });

        it('Layer2ManagerProxy ', async () => {
            const {DAOCommitteeProxy} = await getNamedAccounts();
            await (await layer2ManagerProxy.connect(deployer).transferOwnership(DAOCommitteeProxy)).wait()
            expect(await layer2ManagerProxy.isAdmin(deployer.address)).to.be.eq(false)
            expect(await layer2ManagerProxy.isAdmin(DAOCommitteeProxy)).to.be.eq(true)
        });
    })

    ///--- Agenda ---------------------------------
    describe('# Agenda', () => {

        it('Submit an agenda', async () => {
            const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, DAOAgendaManager } = await getNamedAccounts();

            let targets = []
            let params = []
            let callDtata

            // =========================================
            // 1. upgradeTO daoCommitteeProxy2Contract
            targets.push(DAOCommitteeProxy)
            callDtata = depositManagerProxy.interface.encodeFunctionData("upgradeTo", [daoCommitteeProxy2Contract.address])
            params.push(callDtata)

            // =========================================
            // 2. upgradeTo2 daoCommittee_V1
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("upgradeTo2", [daoCommittee_V1.address])
            params.push(callDtata)

            // =========================================
            // 3. setImplementation2 1, true, daoCommitteeOwner
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("setImplementation2", [daoCommitteeOwner.address, 1, true])
            params.push(callDtata)

            // =========================================
            // 4. setSelectorImplementations2  daoCommitteeOwner
            const _setLayer2CandidateFactory = encodeFunctionSignature("setCandidateAddOnFactory(address)");
            const _setLayer2Manager = encodeFunctionSignature("setLayer2Manager(address)");
            const _setTargetSetLayer2Manager = encodeFunctionSignature("setTargetSetLayer2Manager(address,address)");
            const _setTargetSetL2Registry = encodeFunctionSignature("setTargetSetL1BridgeRegistry(address,address)");
            const _setTargetLayer2StartBlock = encodeFunctionSignature("setTargetLayer2StartBlock(address,uint256)");
            const _setTargetSetImplementation2 = encodeFunctionSignature("setTargetSetImplementation2(address,address,uint256,bool)");
            const _setTargetSetSelectorImplementations2 = encodeFunctionSignature("setTargetSetSelectorImplementations2(address,bytes4[],address)");

            const _setSeigManager = encodeFunctionSignature("setSeigManager(address)");
            const _setTargetSeigManager = encodeFunctionSignature("setTargetSeigManager(address,address)")
            const _setSeigPause = encodeFunctionSignature("setSeigPause()")
            const _setSeigUnpause = encodeFunctionSignature("setSeigUnpause()")
            const _setTargetGlobalWithdrawalDelay = encodeFunctionSignature("setTargetGlobalWithdrawalDelay(addres,uint256)")
            const _setTargetAddMinter = encodeFunctionSignature("setTargetAddMinter(address,address)")
            const _setTargetUpgradeTo = encodeFunctionSignature("setTargetUpgradeTo(address,address)")
            const _setTargetSetTON = encodeFunctionSignature("setTargetSetTON(address,address)")
            const _setTargetSetWTON = encodeFunctionSignature("setTargetSetWTON(address,address)")
            const _setDaoVault = encodeFunctionSignature("setDaoVault(address)")
            const _setLayer2Registry = encodeFunctionSignature("setLayer2Registry(address)")
            const _setAgendaManager = encodeFunctionSignature("setAgendaManager(address)")
            const _setCandidateFactory = encodeFunctionSignature("setCandidateFactory(address)")
            const _setTon = encodeFunctionSignature("setTon(address)")
            const _setWton = encodeFunctionSignature("setWton(address)")
            const _setActivityRewardPerSecond = encodeFunctionSignature("setActivityRewardPerSecond(uint256)")
            const _setCandidatesSeigManager = encodeFunctionSignature("setCandidatesSeigManager(address[],address)")
            const _setCandidatesCommittee = encodeFunctionSignature("setCandidatesCommittee(address[],address)")
            const _setCreateAgendaFees = encodeFunctionSignature("setCreateAgendaFees(uint256)")
            const _setMinimumNoticePeriodSeconds = encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)")
            const _setMinimumVotingPeriodSeconds = encodeFunctionSignature("setMinimumVotingPeriodSeconds(uint256)")
            const _setExecutingPeriodSeconds = encodeFunctionSignature("setExecutingPeriodSeconds(uint256)")
            const _increaseMaxMember = encodeFunctionSignature("increaseMaxMember(uint256,uint256)")
            const _setQuorum = encodeFunctionSignature("setQuorum(uint256)")
            const _decreaseMaxMember = encodeFunctionSignature("decreaseMaxMember(uint256,uint256)")
            const _setBurntAmountAtDAO = encodeFunctionSignature("setBurntAmountAtDAO(uint256)")

            const functions = [
                _setLayer2CandidateFactory,_setLayer2Manager,_setTargetSetLayer2Manager,_setTargetSetL2Registry,
                _setTargetLayer2StartBlock,_setTargetSetImplementation2,_setTargetSetSelectorImplementations2,
                _setSeigManager,_setTargetSeigManager,_setSeigPause,_setSeigUnpause,
                _setTargetGlobalWithdrawalDelay,_setTargetAddMinter,_setTargetUpgradeTo,_setTargetSetTON,_setTargetSetWTON,
                _setDaoVault,_setLayer2Registry,_setAgendaManager,_setCandidateFactory,_setTon,_setWton,
                _increaseMaxMember,_setQuorum,_decreaseMaxMember,_setBurntAmountAtDAO,
                _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setCreateAgendaFees,
                _setMinimumNoticePeriodSeconds,_setMinimumVotingPeriodSeconds,_setExecutingPeriodSeconds
            ]

            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData(
                "setSelectorImplementations2", [
                    functions,
                    daoCommitteeOwner.address
                 ])
            params.push(callDtata)

             // =========================================
            //  upgrade SeigManager setTargetSetImplementation2
            targets.push(seigManagerProxy.address)
            callDtata = seigManagerProxy.interface.encodeFunctionData("setImplementation2",
                [
                    seigManagerV1_3.address,
                    1,
                    true
                ])
            params.push(callDtata)


            // =========================================
            //  upgrade SeigManager setTargetSetSelectorImplementations2
            targets.push(seigManagerProxy.address)

            const selector1 = encodeFunctionSignature("setLayer2StartBlock(uint256)");
            const selector2 = encodeFunctionSignature("setLayer2Manager(address)");
            const selector3 = encodeFunctionSignature("setL1BridgeRegistry(address)");
            const selector4 = encodeFunctionSignature("updateSeigniorage()");
            const selector5 = encodeFunctionSignature("updateSeigniorageOperator()");
            const selector6 = encodeFunctionSignature("updateSeigniorageLayer()");
            const selector7 = encodeFunctionSignature("allowIssuanceLayer2Seigs(address)");
            const selector8 = encodeFunctionSignature("totalLayer2TVL()");
            const selector9 = encodeFunctionSignature("layer2RewardInfo(address)");
            const selector10 = encodeFunctionSignature("l1BridgeRegistry()");
            const selector11 = encodeFunctionSignature("layer2Manager()");
            const selector12 = encodeFunctionSignature("layer2StartBlock()");
            const selector13 = encodeFunctionSignature("l2RewardPerUint()");
            const selector14 = encodeFunctionSignature("unSettledReward(address)");
            const selector15 = encodeFunctionSignature("estimatedDistribute(uint256,address,bool)");
            const selector16 = encodeFunctionSignature("excludeFromSeigniorage(address)");
             const selector17 = encodeFunctionSignature("unallocatedSeigniorage()");
            const selector18 = encodeFunctionSignature("unallocatedSeigniorageAt(uint256)");
            const selector19 = encodeFunctionSignature("stakeOfAllLayers()");
            const selector20 = encodeFunctionSignature("stakeOfAllLayersAt(uint256)");

            let functionBytecodes = [
                selector1, selector2, selector3, selector4, selector5,
                selector6, selector7, selector8, selector9, selector10,
                selector11, selector12, selector13, selector14, selector15,
                selector16,selector17, selector18, selector19, selector20
            ];

            callDtata = seigManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
                [
                    functionBytecodes,
                    seigManagerV1_3.address
                ])
            params.push(callDtata)

            // =========================================
            //  upgrade DepositManager setTargetSetImplementation2
            targets.push(depositManagerProxy.address)
            callDtata = depositManagerProxy.interface.encodeFunctionData("setImplementation2",
                [
                    depositManagerV1_1.address,
                    2,
                    true
                ])
            params.push(callDtata)

            // =========================================
            //  upgrade DepositManager setTargetSetSelectorImplementations2
            targets.push(depositManagerProxy.address)
            const selector_1 = encodeFunctionSignature("ton()");
            const selector_2 = encodeFunctionSignature("minDepositGasLimit()");
            const selector_3 = encodeFunctionSignature("setMinDepositGasLimit(uint256)");
            const selector_4 = encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");
            const selector_5 = encodeFunctionSignature("l1BridgeRegistry()");
            const selector_6 = encodeFunctionSignature("layer2Manager()");
            const selector_7 = encodeFunctionSignature("setAddresses(address,address)");

            let functionBytecodes_1 = [ selector_1, selector_2, selector_3, selector_4, selector_5, selector_6, selector_7];

            callDtata = depositManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
                [
                    functionBytecodes_1,
                    depositManagerV1_1.address

                ])
            params.push(callDtata)

            // =========================================
            //  set DAOCommitteeProxy candidateAddOnFactory
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeOwner.interface.encodeFunctionData("setCandidateAddOnFactory", [candidateAddOnFactory.address])
            params.push(callDtata)

            // =========================================
            //  set DAOCommitteeProxy layer2Manager
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeOwner.interface.encodeFunctionData("setLayer2Manager", [layer2Manager.address])
            params.push(callDtata)

            // =========================================
            //  set seigManagerProxy setLayer2Manager
            targets.push(seigManagerProxy.address)
            callDtata = seigManagerV1_3.interface.encodeFunctionData("setLayer2Manager", [layer2ManagerProxy.address])
            params.push(callDtata)

            // =========================================
            //  set seigManagerProxy setLayer2Manager
            targets.push(seigManagerProxy.address)
            callDtata = seigManagerV1_3.interface.encodeFunctionData("setL1BridgeRegistry", [l1BridgeRegistryProxy.address])
            params.push(callDtata)


            // =========================================
            //  set DAOCommitteeProxy setAddresses
            targets.push(depositManagerProxy.address)
            callDtata = depositManagerV1_1.interface.encodeFunctionData("setAddresses", [
                l1BridgeRegistryProxy.address,
                layer2Manager.address ])
            params.push(callDtata)

            // =========================================
            //  registerSystemConfigByManager  Titan
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();
            let name = 'Titan'
            targets.push(l1BridgeRegistry.address)
            callDtata = l1BridgeRegistry.interface.encodeFunctionData("registerRollupConfigByManager(address,uint8,address,string)", [ legacySystemConfig.address, 1,  l2TonAddress, name])
            params.push(callDtata)

            // =========================================
            // . make an agenda
            const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();
            const agendaFee = await daoAgendaManagerContract.createAgendaFees();
            const param = encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    params
                ]
            )

            // =========================================
            // Propose an agenda
            let receipt = await (await tonContract.connect(tonHave).approveAndCall(
                DAOCommitteeProxy,
                agendaFee,
                param
            )).wait()

            // console.log('receipt ', receipt)
            agendaId = (await daoAgendaManagerContract.numAgendas()).sub(1);
            const executionInfo = await daoAgendaManagerContract.getExecutionInfo(agendaId);
            // console.log("executionInfo :", executionInfo);
            // expect(executionInfo[0][0]).to.be.equal(DAOCommitteeProxy);
            // expect(executionInfo[1][0]).to.be.equal(param);
        }).timeout(100000000);

        it('Pass the noticePeriod before voting', async function () {
            // console.log('agendaId  ', agendaId)
            const agenda = await daoAgendaManagerContract.agendas(agendaId);
            const noticeEndTimestamp = agenda[1];
            await time.increaseTo(Number(noticeEndTimestamp));
            expect(await daoAgendaManagerContract.isVotableStatus(agendaId)).to.be.equal(true);
        });

        it("Vote an agenda", async () => {
            const { DAOCommitteeProxy, daoMember1, daoMember2, daoMember3 } = await getNamedAccounts();

            daoCommitteeContract = new ethers.Contract(DAOCommitteeProxy, DAOCommittee_V1_Json.abi,  deployer)

            const agenda = await daoAgendaManagerContract.agendas(agendaId);
            // console.log('agenda  ', agenda)
            const beforeCountingYes = agenda.countingYes;
            const beforeCountingNo = agenda.countingNo;
            const beforeCountingAbstain = agenda.countingAbstain;

            const vote = 1

            const daoMember1Contract = new ethers.Contract(daoMember1, Candidate_Json.abi,  deployer)
            let daoMember1CandidateAddress = await daoMember1Contract.candidate()
            let checkMember = await daoCommitteeContract.isMember(daoMember1CandidateAddress)
            expect(checkMember).to.be.equal(true)

            const daoMember2Contract = new ethers.Contract(daoMember2, Candidate_Json.abi,  deployer)
            let daoMember2CandidateAddress = await daoMember2Contract.candidate()
            checkMember = await daoCommitteeContract.isMember(daoMember2CandidateAddress)
            expect(checkMember).to.be.equal(true)

            await network.provider.send("hardhat_impersonateAccount", [ daoMember1CandidateAddress]);
            await network.provider.send("hardhat_setBalance", [ daoMember1CandidateAddress, "0x10000000000000000000000000", ]);
            await network.provider.send("hardhat_impersonateAccount", [ daoMember2CandidateAddress]);
            await network.provider.send("hardhat_setBalance", [ daoMember2CandidateAddress, "0x10000000000000000000000000", ]);

            let daoMember1Signer = await ethers.getSigner(daoMember1CandidateAddress);
            let daoMember2Signer = await ethers.getSigner(daoMember2CandidateAddress);

            // console.log('daoMember1Signer', daoMember1Signer.address)
            // console.log('daoMember2Signer', daoMember2Signer.address)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await (await daoMember1Contract.connect(daoMember1Signer).castVote(
                agendaId,
                vote,
                "member1 vote"
            )).wait()

            // enum AgendaStatus { NONE, NOTICE, VOTING, WAITING_EXEC, EXECUTED, ENDED }
            // enum AgendaResult { PENDING, ACCEPT, REJECT, DISMISS }
            let agendaInfo = await daoAgendaManagerContract.agendas(agendaId);
            // console.log('agenda after voting ', agendaInfo)
            expect(agendaInfo.countingYes).to.be.equal(Number(beforeCountingYes)+1);
            expect(agendaInfo.countingNo).to.be.equal(Number(beforeCountingNo));
            expect(agendaInfo.countingAbstain).to.be.equal(Number(beforeCountingAbstain));
            expect(agendaInfo.status).to.be.equal(2);
            expect(agendaInfo.result).to.be.equal(0);

            const voterInfo1 = await daoAgendaManagerContract.voterInfos(agendaId, daoMember1CandidateAddress);
            // console.log('voterInfo of daoMember1Candidate ', voterInfo1)
            expect(voterInfo1.hasVoted).to.be.equal(true);
            expect(voterInfo1.vote).to.be.equal(vote);

            await (await daoMember2Contract.connect(daoMember2Signer).castVote(
                agendaId,
                vote,
                "member2 vote"
            )).wait()
            agendaInfo = await daoAgendaManagerContract.agendas(agendaId);
            // console.log('agenda after voting ', agendaInfo)
            expect(agendaInfo.countingYes).to.be.equal(Number(beforeCountingYes)+2);
            expect(agendaInfo.countingNo).to.be.equal(Number(beforeCountingNo));
            expect(agendaInfo.countingAbstain).to.be.equal(Number(beforeCountingAbstain));
            expect(agendaInfo.status).to.be.equal(3);
            expect(agendaInfo.result).to.be.equal(1);

            const voterInfo2 = await daoAgendaManagerContract.voterInfos(agendaId, daoMember2CandidateAddress);
            // console.log('voterInfo of daoMember2Candidate ', voterInfo2)
            expect(voterInfo2.hasVoted).to.be.equal(true);
            expect(voterInfo2.vote).to.be.equal(vote);

            const getVoteStatusMember1 = await daoAgendaManagerContract.getVoteStatus(agendaId, daoMember1CandidateAddress);
            expect(getVoteStatusMember1[0]).to.be.equal(true);
            expect(getVoteStatusMember1[1]).to.be.equal(vote);

            const getVoteStatusMember2 = await daoAgendaManagerContract.getVoteStatus(agendaId, daoMember2CandidateAddress);
            expect(getVoteStatusMember2[0]).to.be.equal(true);
            expect(getVoteStatusMember2[1]).to.be.equal(vote);
        })

        it('Pass the votingPeriod before executing', async function () {
            // let agendaInfo = await daoAgendaManagerContract.agendas(agendaId);
            // console.log('agendaInfo  ', agendaInfo)

            let votingEndTime = await daoAgendaManagerContract.getAgendaVotingEndTimeSeconds(agendaId)

            await time.increaseTo(Number(votingEndTime));
            expect(await daoAgendaManagerContract.canExecuteAgenda(agendaId)).to.be.equal(true);

        });

        it('Execute an agenda', async () => {
            let agenda = await daoAgendaManagerContract.agendas(agendaId);
            expect(agenda.executedTimestamp).to.be.equal(0);
            expect(agenda.executed).to.be.equal(false);

            await (await daoCommitteeContract.executeAgenda(agendaId)).wait();

            agenda = await daoAgendaManagerContract.agendas(agendaId);
            expect(agenda.executedTimestamp).to.be.gt(0);
            expect(agenda.executed).to.be.equal(true);

        })

        it('Check the storages', async () => {

            //----- check logic
            const { DAOCommitteeProxy, daoMember1, daoMember2, daoMember3 } = await getNamedAccounts();
            const daoCommitteeContractV2 = new ethers.Contract(DAOCommitteeProxy, DAOCommitteeProxy2_Josn.abi,  deployer)
            const _setTargetSetImplementation2 = encodeFunctionSignature("setTargetSetImplementation2(address,address,uint256,bool)");
            let logic = await daoCommitteeContractV2.getSelectorImplementation2(_setTargetSetImplementation2)

            expect(logic).to.be.equal(daoCommitteeOwner.address)
            expect(await daoCommitteeContractV2.implementation2(1)).to.be.equal(daoCommitteeOwner.address)

            //-- check titan rollupConfig
            const {l2TonAddress } = await getNamedAccounts();
            let titanInfo = await l1BridgeRegistry.rollupInfo(legacySystemConfig.address)
            expect(titanInfo.l2TON).to.be.equal(l2TonAddress)
            expect(titanInfo.rejectedSeigs).to.be.equal(false)
            expect(titanInfo.rejectedSeigs).to.be.equal(false)
            expect(titanInfo.name).to.be.equal('Titan')

        })

    })


    ///---- After executing an agenda --------------------------------

    describe('# Titan checkLayer2TVL', () => {
        it('If the rollupConfig or L1Bridge address does not exist, the result is returned as false.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();
            let rollupConfig = l1MessengerAddress

            expect(await layer2Manager.l1BridgeRegistry()).to.be.eq(l1BridgeRegistry.address)
            expect(await l1BridgeRegistry.rollupType(rollupConfig)).to.be.eq(0)

            let check = await layer2Manager.checkLayer2TVL(rollupConfig)
            expect(check.result).to.be.eq(false)
            expect(check.amount).to.be.eq(ethers.constants.Zero)
        })

        it('If the rollupConfig or L1Bridge address exist, the result is returned as false.', async () => {

            expect(await layer2Manager.l1BridgeRegistry()).to.be.eq(l1BridgeRegistry.address)
            expect(await l1BridgeRegistry.rollupType(legacySystemConfig.address)).to.be.eq(1)

            let check = await layer2Manager.checkLayer2TVL(legacySystemConfig.address)
            expect(check.result).to.be.eq(true)
            expect(check.amount).to.be.gt(ethers.constants.Zero)
        })
    })

    describe('# registerCandidateAddOn ', () => {

        it('Fail if systemConfig is an invalid address', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                l1BridgeRegistry.address,
                amount,
                true,
                'test1'
            )).to.be.rejectedWith("RegisterError")
        })

        it('Failure in case of insufficient ton balance', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                legacySystemConfig.address,
                amount,
                true,
                'test1'
            )).to.be.rejectedWith("TRANSFER_FROM_FAILED")
        })

        it('Failure when there is no prior approval of wton', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()
            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                legacySystemConfig.address,
                amount.mul(utils.parseEther("1000000000")),
                false,
                'test1'
            )).to.be.rejectedWith("TRANSFER_FROM_FAILED")
        })

        it('Fail if there is no content in memo', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                legacySystemConfig.address,
                amount,
                true,
                ''
            )).to.be.rejectedWith("ZeroBytesError")
        })

        it('registerCandidateAddOn : titanCandidateAddOn', async () => {
            expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(0)

            const addr = tonHave
            let amount = await layer2Manager.minimumInitialDepositAmount();
            // amount = amount.add(ethers.utils.parseEther("0.1"))
            // console.log('amount', amount)

            let balance = await tonContract.balanceOf(addr.address)
            expect(balance).to.be.gt(amount)

            let allowance = await tonContract.allowance(addr.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfig.name()
            const operatorAddress = await operatorManagerFactory.getAddress(legacySystemConfig.address)

            const receipt = await (await layer2Manager.connect(addr).registerCandidateAddOn(
                legacySystemConfig.address,
                amount,
                true,
                name
            )).wait()

            const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            expect(deployedEvent.args.memo).to.be.eq(name)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

            titanLayerAddress = deployedEvent.args.candidateAddOn;
            titanOperatorContractAddress = deployedEvent.args.operator;
            expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(1)

            titanLayerContract =  (await ethers.getContractAt("CandidateAddOnV1_1", titanLayerAddress, deployer)) as CandidateAddOnV1_1
            titanOperatorContract = (await ethers.getContractAt("OperatorManagerV1_1", titanOperatorContractAddress, deployer)) as OperatorManagerV1_1
        })

        it('If the layer has already been created, it will fail.', async () => {

            expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(1)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(daoAdmin).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfig.name()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                legacySystemConfig.address,
                amount,
                true,
                name
            ) ).to.be.revertedWith("RegisterError");
        })

    })


    describe('# DepositManager : CandidateAddOn ', () => {

        it('deposit to titanLayerAddress using approveAndCall', async () => {

            let account = addr1
            let amount = ethers.utils.parseEther("2000")

            const beforeBalance = await tonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(amount)

            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)
            // console.log("stakedA :", stakedA);

            const data = marshalString(
                [depositManager.address, titanLayerAddress]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                amount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(amount))

            let stakedB = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)
            // console.log("stakedB :", stakedB);

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(amount.mul(ethers.BigNumber.from("1000000000"))), 3)
            )
        })

        it('deposit to titanLayerAddress using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let account = addr1

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await (await wtonContract.connect(daoAdmin).mint(account.address, wtonAmount))

            const beforeBalance = await wtonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)
            // console.log(stakedA)

            await (await depositManager.connect(account)["deposit(address,uint256)"](
                titanLayerAddress,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)
            // console.log(stakedB)

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        })

        it('deposit to titanLayerAddress using deposit(address,address,uint256) ', async () => {

            let account = addr2
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await (await wtonContract.connect(daoAdmin).mint(account.address, wtonAmount))

            const beforeSenderBalance = await wtonContract.balanceOf(account.address);
            // console.log("beforeSenderBalance :", beforeSenderBalance);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            await (await depositManager.connect(account)["deposit(address,address,uint256)"](
                titanLayerAddress,
                addr2.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await wtonContract.balanceOf(account.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            expect(roundDown(stakedB.add(ethers.BigNumber.from("3")),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('The operator\'s staking amount must be greater than minimumAmount.', async () => {
            expect(await titanLayerContract.operator()).to.be.eq(titanOperatorContractAddress);
            let staked = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)
            // console.log(ethers.utils.formatUnits(staked, 27) )
            expect(await seigManager.minimumAmount()).to.be.not.gt(staked)
        })

        it('seigManager: updateSeigniorageLayer : first updateSeigniorage to titanLayerAddress : no give seigniorage to l2', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)
            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            )

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)


            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer : second updateSeigniorage to titanLayerAddress : not operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            )

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)
            expect(afterWtonBalanceOfLayer2Manager).to.be.gt(ethers.constants.Zero)

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });


        it('Layer2Contract: updateSeigniorage : operator claim: the third updateSeigniorage to titanLayerAddress : operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)
            // console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)


            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(titanManager.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(titanManager)["updateSeigniorage(uint256,bool)"](afterCall, false)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

            // let afterCall = 1; claim mode
            let totalBalanceOfLayer2Manager = prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            let sendAmountToOperator = deployedEvent1.args.layer2Seigs

            let managerBalance = prevWtonBalanceOfManager.add(prevWtonBalanceOfLayer2Operator.add(sendAmountToOperator))
            expect(afterWtonBalanceOfManager).to.be.eq(managerBalance)

            expect(afterWtonBalanceOfLayer2Manager).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
            )
            expect(afterWtonBalanceOfLayer2Operator).to.be.eq(ethers.constants.Zero)

            expect(afterWtonBalanceOfManager).to.be.eq(prevWtonBalanceOfLayer2Operator.add(estimatedDistribute.layer2Seigs))

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : operator staking : the forth updateSeigniorage to titanLayerAddress : operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()
            const managerOfOperatorManager = await titanOperatorContract.manager();

            // console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)
            // console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let stakedOperatorPrev = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)
            let stakedManagerEoaPrev: BigNumber = await seigManager["stakeOf(address,address)"](titanLayerAddress, managerOfOperatorManager)

            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(titanManager.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(titanManager)["updateSeigniorage(uint256,bool)"](afterCall, false)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let stakedOperatorAfter = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)
            let stakedManagerEoaAfter: BigNumber = await seigManager["stakeOf(address,address)"](titanLayerAddress, managerOfOperatorManager)

            // console.log('stakedOperatorAfter', stakedOperatorAfter)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

            // let afterCall = 2; staking mode

            let stakedAmount = prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs)
            // console.log('stakedAmount', stakedAmount)

            expect(afterWtonBalanceOfManager).to.be.eq(prevWtonBalanceOfManager)

            expect(afterWtonBalanceOfLayer2Manager).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
            )
            expect(afterWtonBalanceOfLayer2Operator).to.be.eq(ethers.constants.Zero)

            expect(stakedOperatorAfter).to.be.gte(stakedOperatorPrev)
            expect(BigNumber.from(roundDown(stakedManagerEoaAfter,2))).to.be.gte(
                BigNumber.from(roundDown(stakedManagerEoaPrev.add(estimatedDistribute.layer2Seigs),2)))


        })

        it('requestWithdrawal to titanLayerAddress', async () => {

            let layer2 = titanLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            const beforeBalance = await wtonContract.balanceOf(account.address)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await seigManager["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedA.sub(ethers.constants.Two),5)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 5)
            )

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

        })


        it('processRequest to titanLayerAddress will be fail when delay time didn\'t pass.', async () => {
            let layer2 = titanLayerAddress
            let account = addr1

            await expect(
                    depositManager.connect(account)["processRequest(address,bool)"](
                    layer2,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to titanLayerAddress.', async () => {
            let layer2 = titanLayerAddress
            let account = addr1
            const beforeBalance = await tonContract.balanceOf(account.address)
            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            let accUnstakedA = await depositManager.accUnstaked(layer2, account.address)
            let accUnstakedLayer2A = await depositManager.accUnstakedLayer2(layer2)
            let accUnstakedAccountA = await depositManager.accUnstakedAccount(account.address)

            let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay()

            await mine(globalWithdrawalDelay, { interval: 12 });

            await (await depositManager.connect(account)["processRequest(address,bool)"](
                layer2,
                true
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.add(pendingUnstakedA.div(BigNumber.from("1"+"0".repeat(9)))))

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(ethers.constants.Zero)

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.sub(pendingUnstakedA))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.sub(pendingUnstakedA))

            expect(
                await depositManager.accUnstaked(layer2, account.address)
            ).to.be.eq(accUnstakedA.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedLayer2(layer2 )
            ).to.be.eq(accUnstakedLayer2A.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedAccount(account.address)
            ).to.be.eq(accUnstakedAccountA.add(pendingUnstakedA))

        });

    })

    // 기존의 다오 candidate 테스트
    describe('# DepositManager : DAOCandidate ', () => {

        it('deposit to layer1 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor
            let tonAmount = ethers.utils.parseEther("1")

            // await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await tonContract.balanceOf(account.address);
            // console.log("beforeTONBalance :", beforeBalance);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)
            // console.log("stakedA :", stakedA);

            const data = marshalString(
                [depositManager.address, layer2Info_1.layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)
            // console.log("stakedB :", stakedB);

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 3)
            )
        })

        it('deposit to layer2 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor
            let tonAmount = ethers.utils.parseEther("1")

            // await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await tonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, account.address)

            const data = marshalString(
                [depositManager.address, layer2Info_2.layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),2)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 2)
            )
        })

        it('deposit to layer1 using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);

            const beforeBalance = await wtonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            await (await depositManager.connect(account)["deposit(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            // expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
            //     roundDown(stakedA.add(wtonAmount), 3)
            // )
        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            // console.log(deployed.seigManagerV2)
            // let account = deployer
            let account = pastDepositor
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);

            const beforeSenderBalance = await wtonContract.balanceOf(account.address);
            // console.log("beforeSenderBalance :", beforeSenderBalance);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);
            // await deployed.WTON.connect(account).approve(depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)

            await (await depositManager.connect(pastDepositor)["deposit(address,address,uint256)"](
                layer2Info_2.layer2,
                addr1.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await wtonContract.balanceOf(account.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.BigNumber.from("3")),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        })

        it('set layerContract', async () => {
            layer2Info_1.layerContract = new ethers.Contract(
                layer2Info_1.layer2, DAOCandidate_Json.abi, deployer
            );

        });


        it('query unallocatedSeigniorage', async () => {

            let stakeOfAllLayers = await await seigManager["stakeOfAllLayers()"]();
            let stakeOfTotal = await await seigManager["stakeOfTotal()"]();
            expect(stakeOfTotal).to.be.gt(stakeOfAllLayers);
            // console.log( ' stakeOfAllLayers      ', ethers.utils.formatUnits(stakeOfAllLayers,27) , 'WTON')
            // console.log( ' stakeOfTotal      ', ethers.utils.formatUnits(stakeOfTotal,27) , 'WTON')

            let unallocatedSeigniorage = await await seigManager.unallocatedSeigniorage();
            // console.log( ' unallocatedSeigniorage      ', ethers.utils.formatUnits(unallocatedSeigniorage,27) , 'WTON')

            expect(stakeOfTotal.sub(stakeOfAllLayers)).to.be.eq(unallocatedSeigniorage);

            // console.log( ' stakeOfTotal.sub(stakeOfAllLayers)     ', ethers.utils.formatUnits(stakeOfTotal.sub(stakeOfAllLayers),27) , 'WTON')
        });

        it('updateSeigniorage to layer1', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (before)   ', ethers.utils.formatUnits(totalSupplyOfTon,27) , 'WTON')

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            // console.log('\n updateSeigniorage... ' )

            const receipt = await (await seigManager.connect(pastDepositor).updateSeigniorageLayer(layer2Info_1.layer2)).wait()

            const topic = seigManager.interface.getEventTopic('CommitLog1');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            // console.log('\n totalStakedAmount : ',  ethers.utils.formatUnits(deployedEvent.args.totalStakedAmount,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            expect(stakedB).to.be.gt(stakedA)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            let totalSupplyOfTon_2 = await seigManager["totalSupplyOfTon_2()"]()
            // console.log( ' totalSupplyOfTon_2    ', ethers.utils.formatUnits(totalSupplyOfTon_2,27) , 'WTON')
            expect(totalSupplyOfTon_2).to.be.gt(ethers.constants.Zero)
        })

        it('requestWithdrawal to layer1', async () => {

            let layer2 = layer2Info_1.layer2
            let account = pastDepositor
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            // let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay();
            // let getDelayBlocks = await depositManager.getDelayBlocks(layer2);
            // let numRequests = await depositManager.numRequests(layer2, account.address);
            // let index = await depositManager.withdrawalRequestIndex(layer2, account.address);
            // let withdrawalRequest = await depositManager.withdrawalRequest(layer2, account.address, index);

            const beforeBalance = await wtonContract.balanceOf(account.address)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)

            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            expect(roundDown(stakedA.sub(ethers.constants.Two),5)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 5)
            )

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

        })

        it('processRequest to layer1 will be fail when delay time didn\'t pass.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = pastDepositor

            let numPendingRequests = await depositManager.numPendingRequests(layer2, account.address);

            await expect(
                    depositManager.connect(account)["processRequests(address,uint256,bool)"](
                    layer2,
                     numPendingRequests,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to layer1.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = pastDepositor
            const beforeBalance = await wtonContract.balanceOf(account.address)

            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            let accUnstakedA = await depositManager.accUnstaked(layer2, account.address)
            let accUnstakedLayer2A = await depositManager.accUnstakedLayer2(layer2)
            let accUnstakedAccountA = await depositManager.accUnstakedAccount(account.address)


            let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay()

            await mine(globalWithdrawalDelay, { interval: 12 });

            let index = await depositManager.withdrawalRequestIndex(layer2, account.address);
            let numRequests = await depositManager.numRequests(layer2, account.address);
            let numPendingRequests = await depositManager.numPendingRequests(layer2, account.address);

            let withdrawalAmount = ethers.constants.Zero
            let i = 0
            for (i = index.toNumber() ; i < numRequests.toNumber() ; i++) {
                let withdrawalRequest = await depositManager.withdrawalRequest(layer2, account.address, i);
                withdrawalAmount = withdrawalAmount.add(withdrawalRequest.amount)
            }


            await (await  depositManager.connect(account)["processRequests(address,uint256,bool)"](
                layer2,
                numPendingRequests,
                false
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);

            expect(afterBalance).to.be.eq(beforeBalance.add(pendingUnstakedA))

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(ethers.constants.Zero)

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.sub(pendingUnstakedA))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.sub(pendingUnstakedA))

            expect(
                await depositManager.accUnstaked(layer2, account.address)
            ).to.be.eq(accUnstakedA.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedLayer2(layer2 )
            ).to.be.eq(accUnstakedLayer2A.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedAccount(account.address)
            ).to.be.eq(accUnstakedAccountA.add(pendingUnstakedA))

        });
    })

    describe('# withdrawAndDepositL2 : LayerCandidate ', () => {

        it('deposit to Titan using approveAndCall', async () => {

            let account = tonHave
            let tonAmount = ethers.utils.parseEther("100")

            const beforeBalance = await tonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)

            const data = marshalString(
                [depositManager.address, titanLayerAddress]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 3)
            )
        })


        it('deposit to layer1 using approveAndCall', async () => {

            let account = tonHave
            let tonAmount = ethers.utils.parseEther("100")

            const beforeBalance = await tonContract.balanceOf(account.address);

            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            const data = marshalString(
                [depositManager.address, layer2Info_1.layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 3)
            )
        })

        it('withdrawAndDepositL2 : Not supported in DAOCandidate layer.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = tonHave
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

            await expect(depositManager.connect(account).withdrawAndDepositL2(
                layer2,
                wtonAmount
            )).to.be.revertedWith("OperatorError")

        })

        it('withdrawAndDepositL2 : Failure if the staking amount is insufficient', async () => {

            let account = tonHave
            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)

            await expect(depositManager.connect(account).withdrawAndDepositL2(
                titanLayerAddress,
                stakedA.add(ethers.constants.One)
            )).to.be.revertedWith("staked amount is insufficient")
        })

        it('When you run it, deposit money to L2 immediately without delay blocks.', async () => {
            let account = tonHave

            let rollupConfig = await titanOperatorContract.rollupConfig()
            expect(rollupConfig).to.be.not.eq(ethers.constants.AddressZero)

            let prevLayer2TVL = await l1BridgeRegistry.layer2TVL(rollupConfig)

            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)

            let receipt = await (await depositManager.connect(account).withdrawAndDepositL2(
                titanLayerAddress,
                stakedA
            )).wait()

            const topic = depositManager.interface.getEventTopic('WithdrawalAndDeposited');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = depositManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.account).to.be.eq(account.address)
            expect(deployedEvent.args.amount).to.be.eq(stakedA)

            let stakedB = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)
            expect(stakedB).to.be.eq(ethers.constants.Zero)

            const afterTonBalance = await tonContract.balanceOf(depositManager.address);
            expect(await l1BridgeRegistry.layer2TVL(rollupConfig)).to.be.eq(
                prevLayer2TVL.add(stakedA.div(BigNumber.from("1000000000"))))

        })
    })

    describe('# reject CandidateAddOn : L1BridgeRegistry ', () => {

        it('reject CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.not.eq(addr1.address)
            await expect(
                l1BridgeRegistry.connect(addr1).rejectCandidateAddOn(
                    legacySystemConfig.address
                )
            ).to.be.revertedWith("PermissionError")
        })

        it('reject CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {

            await (await l1BridgeRegistry.connect(daoAdmin).setSeigniorageCommittee(seigniorageCommitteeAddress)).wait()

            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
            expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(false)

            let l2Info = await seigManager.layer2RewardInfo(titanLayerAddress)
            let totalLayer2TVL = await seigManager.totalLayer2TVL()

            let allowIssuanceLayer2Seigs = await seigManager["allowIssuanceLayer2Seigs(address)"](titanLayerAddress)

            expect(allowIssuanceLayer2Seigs.allowed).to.be.eq(true)

            const receipt =  await (await l1BridgeRegistry.connect(seigniorageCommittee).rejectCandidateAddOn(
                legacySystemConfig.address
            )).wait()
            const topic = l1BridgeRegistry.interface.getEventTopic('RejectedCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);
            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)

            const topic1 = layer2Manager.interface.getEventTopic('PausedCandidateAddOn');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = layer2Manager.interface.parseLog(log1);
            expect(deployedEvent1.args.rollupConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent1.args.candidateAddOn).to.be.eq(titanLayerAddress)

            const topic2 = seigManagerV1_3.interface.getEventTopic('ExcludedFromSeigniorage');
            const log2 = receipt.logs.find(x => x.topics.indexOf(topic2) >= 0);
            const deployedEvent2 = seigManagerV1_3.interface.parseLog(log2);

            expect(deployedEvent2.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent2.args.layer2Tvl).to.be.eq(l2Info.layer2Tvl)
            expect(deployedEvent2.args.initialDebt).to.be.eq(l2Info.initialDebt)


            expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(true)
            let l2InfoAfter = await seigManager.layer2RewardInfo(titanLayerAddress)
            let totalLayer2TVLAfter = await seigManager.totalLayer2TVL()

            expect(l2InfoAfter.layer2Tvl).to.be.eq(ethers.constants.Zero)
            expect(l2InfoAfter.initialDebt).to.be.eq(ethers.constants.Zero)
            expect(totalLayer2TVLAfter).to.be.eq(totalLayer2TVL.sub(l2Info.layer2Tvl))

            let allowIssuanceLayer2SeigsAfter = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
            expect(allowIssuanceLayer2SeigsAfter.allowed).to.be.eq(false)

        })
    })


    describe('# DepositManager : CandidateAddOn : titanCandidateAddOn ', () => {

        it('seigManager: updateSeigniorageLayer : updateSeigniorage to titanLayerAddress : no give seigniorage to l2', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            const allowIssuanceLayer2Seigs = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
            expect(allowIssuanceLayer2Seigs.allowed).to.be.eq(false)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            )

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(ethers.constants.Zero);
        })

        it('Layer2Contract: updateSeigniorage : operator claim:  updateSeigniorage to titanLayerAddress : operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)
            // console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)


            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(titanManager.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(titanManager)["updateSeigniorage(uint256,bool)"](afterCall,false)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            expect(deployedEvent1.args.layer2Seigs).to.be.eq(ethers.constants.Zero);

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            // let afterCall = 1; claim mode
            let totalBalanceOfLayer2Manager = prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            let sendAmountToOperator = deployedEvent1.args.layer2Seigs

            let managerBalance = prevWtonBalanceOfManager.add(prevWtonBalanceOfLayer2Operator.add(sendAmountToOperator))
            expect(afterWtonBalanceOfManager).to.be.eq(managerBalance)

            expect(afterWtonBalanceOfLayer2Manager).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
            )
            expect(afterWtonBalanceOfLayer2Operator).to.be.eq(ethers.constants.Zero)
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : operator staking :  forth updateSeigniorage to titanLayerAddress : operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)
            // console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let stakedOperatorPrev = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)

            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(titanManager.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(titanManager)["updateSeigniorage(uint256,bool)"](afterCall,false)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let stakedOperatorAfter = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)

            // console.log('stakedOperatorAfter', stakedOperatorAfter)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(titanManager.address)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            // let afterCall = 2; staking mode

            let stakedAmount = prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs)
            // console.log('stakedAmount', stakedAmount)

            expect(afterWtonBalanceOfManager).to.be.eq(prevWtonBalanceOfManager)

            expect(afterWtonBalanceOfLayer2Manager).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
            )
            expect(afterWtonBalanceOfLayer2Operator).to.be.eq(ethers.constants.Zero)

            expect(stakedOperatorAfter).to.be.gte(stakedOperatorPrev.add(estimatedDistribute.layer2Seigs))

        })

    })

    describe('# restore CandidateAddOn : L1BridgeRegistry ', () => {

        it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.not.eq(addr1.address)
            await expect(
                l1BridgeRegistry.connect(addr1).restoreCandidateAddOn(
                    legacySystemConfig.address,
                    false
                )
            ).to.be.revertedWith("PermissionError")
        })

        it('restore CandidateAddOn (titanCandidateAddOn) : Only rejected layers can be restored.', async () => {
            const {thanosSystemConfig, thanosL2TON } = await getNamedAccounts();

            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
            expect(await l1BridgeRegistry.rejectRollupConfig(thanosSystemConfig)).to.be.eq(false)
            await expect(
                l1BridgeRegistry.connect(seigniorageCommittee).restoreCandidateAddOn(
                    thanosSystemConfig,
                    false
                )
            ).to.be.revertedWith("OnlyRejectedError")
        })

        it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {

            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
            expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(true)

            let l2Info = await seigManager.layer2RewardInfo(titanLayerAddress)
            let totalLayer2TVL = await seigManager.totalLayer2TVL()
            let allowIssuanceLayer2Seigs = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
            expect(allowIssuanceLayer2Seigs.allowed).to.be.eq(false)

            const receipt =  await (await l1BridgeRegistry.connect(seigniorageCommittee).restoreCandidateAddOn(
                legacySystemConfig.address,
                false
            )).wait()
            const topic = l1BridgeRegistry.interface.getEventTopic('RestoredCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);
            // sconsole.log(deployedEvent.args)
            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)

            expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(false)
            let l2InfoAfter = await seigManager.layer2RewardInfo(titanLayerAddress)
            let totalLayer2TVLAfter = await seigManager.totalLayer2TVL()

            expect(l2InfoAfter.layer2Tvl).to.be.eq(ethers.constants.Zero)
            expect(l2InfoAfter.initialDebt).to.be.eq(ethers.constants.Zero)
            expect(totalLayer2TVLAfter).to.be.eq(totalLayer2TVL.sub(l2Info.layer2Tvl))

            let allowIssuanceLayer2SeigsAfter = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
            expect(allowIssuanceLayer2SeigsAfter.allowed).to.be.eq(true)

        })

    })


    describe('# DepositManager : CandidateAddOn : titanCandidateAddOn ', () => {

        it('seigManager: updateSeigniorageLayer : the first updateSeigniorage to titanCandidateAddOn : no give seigniorage to l2', async () => {
            let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract

            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            let allowIssuanceLayer2Seigs =  await seigManager.allowIssuanceLayer2Seigs(layerAddress);
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)

            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            // console.log('stakedPrev', stakedPrev)
            // console.log('stakedAddr1Prev', stakedAddr1Prev)
            // console.log('stakedAddr2Prev', stakedAddr2Prev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(layerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await layerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            // console.log('stakedAfter', stakedAfter)
            // console.log('stakedAddr1After', stakedAddr1After)
            // console.log('stakedAddr2After', stakedAddr2After)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)
            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            )

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

            // expect(deployedEvent1.args.l2TotalSeigs).to.be.eq(ethers.constants.Zero);
            expect(deployedEvent1.args.layer2Seigs).to.be.eq(ethers.constants.Zero);

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer : the second updateSeigniorage to titanCandidateAddOn : give seigniorage to l2', async () => {
            let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract

            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            // console.log('rollupConfig', rollupConfig)

            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            // console.log('updateSeigniorageLayer deployedEvent.args', deployedEvent.args)

            expect(deployedEvent.args.layer2).to.be.eq(layerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await layerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            // console.log('stakedAfter', stakedAfter)
            // console.log('stakedAddr1After', stakedAddr1After)
            // console.log('stakedAddr2After', stakedAddr2After)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)
            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            )

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer : the third updateSeigniorage to titanCandidateAddOn : not operator ', async () => {
            let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract


            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('operatorContractAddress', operatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)


            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(layerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await layerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            )

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)


            let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)
            expect(afterWtonBalanceOfLayer2Manager).to.be.gt(ethers.constants.Zero)

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : operator claim: the fourth updateSeigniorage to titanCandidateAddOn : operator ', async () => {
            let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract
            let operatorContract = titanOperatorContract
            let operatorOwner = titanManager

            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('operatorContractAddress', operatorContractAddress)
            const prevTonBalanceOfLayer2Manager = await tonContract.balanceOf(layer2Manager.address)
            const prevTonBalanceOfLayer2Operator = await tonContract.balanceOf(operatorContractAddress)
            const prevTonBalanceOfManager = await tonContract.balanceOf(operatorOwner.address)


            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(operatorOwner.address)

            const prevUnSettledReward = await seigManager.unSettledReward(layerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)
            // console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)


            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, layerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await operatorContract.isOperator(operatorOwner.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            // bool : true -> claim for TON
            const receipt = await (await layerContract.connect(operatorOwner)["updateSeigniorage(uint256,bool)"](afterCall,true)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(layerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await layerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(operatorOwner.address)

            const afterTonBalanceOfLayer2Manager = await tonContract.balanceOf(layer2Manager.address)
            const afterTonBalanceOfLayer2Operator = await tonContract.balanceOf(operatorContractAddress)
            const afterTonBalanceOfManager = await tonContract.balanceOf(operatorOwner.address)


            let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

            // let afterCall = 1; claim mode, flag = true , claim for TON
            let totalBalanceOfLayer2Manager = prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            let sendAmountToOperator = deployedEvent1.args.layer2Seigs

            //==
            let claimAmount = prevWtonBalanceOfLayer2Operator.add(sendAmountToOperator).div(ethers.BigNumber.from("1000000000"))
            let managerTonBalance = prevTonBalanceOfManager.add(claimAmount)
            expect(afterTonBalanceOfManager).to.be.eq(managerTonBalance)

            //=====
            // let managerBalance = prevWtonBalanceOfManager.add(prevWtonBalanceOfLayer2Operator.add(sendAmountToOperator))
            // expect(afterWtonBalanceOfManager).to.be.eq(managerBalance)

            expect(afterWtonBalanceOfLayer2Manager).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
            )
            expect(afterWtonBalanceOfLayer2Operator).to.be.eq(ethers.constants.Zero)

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : operator staking : the fifth updateSeigniorage to titanCandidateAddOn : operator ', async () => {
            let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract
            let operatorContract = titanOperatorContract
            let operatorOwner = titanManager

            const managerOfOperatorManager = await titanOperatorContract.manager();

            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('operatorContractAddress', operatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)
            const prevUnSettledReward = await seigManager.unSettledReward(layerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const rollupConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)
            // console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            let stakedOperatorPrev = await seigManager["stakeOf(address,address)"](layerAddress, operatorContractAddress)
            let stakedManagerEoaPrev: BigNumber = await seigManager["stakeOf(address,address)"](titanLayerAddress, managerOfOperatorManager)

            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, layerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await operatorContract.isOperator(operatorOwner.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await layerContract.connect(operatorOwner)["updateSeigniorage(uint256,bool)"](afterCall,false)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(layerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            // console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await layerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            let stakedOperatorAfter = await seigManager["stakeOf(address,address)"](layerAddress, operatorContractAddress)
            let stakedManagerEoaAfter: BigNumber = await seigManager["stakeOf(address,address)"](titanLayerAddress, managerOfOperatorManager)

            // console.log('stakedOperatorAfter', stakedOperatorAfter)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            // console.log(deployedEvent1.args)

            expect(estimatedDistribute.maxSeig).to.be.eq(deployedEvent1.args.totalSeig)
            expect(estimatedDistribute.stakedSeig).to.be.eq(deployedEvent1.args.stakedSeig)
            expect(estimatedDistribute.unstakedSeig).to.be.eq(deployedEvent1.args.unstakedSeig)
            expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
            expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
            expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
            expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
            expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

            const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const afterTotalTvl = await seigManager.totalLayer2TVL()
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)

            let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
            // console.log('layer2RewardInfo', layer2RewardInfo)

            // console.log('afterTotalTvl', afterTotalTvl)
            // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

            // let afterCall = 2; staking mode

            let stakedAmount = prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs)
            // console.log('stakedAmount', stakedAmount)

            expect(afterWtonBalanceOfManager).to.be.eq(prevWtonBalanceOfManager)

            expect(afterWtonBalanceOfLayer2Manager).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
            )
            expect(afterWtonBalanceOfLayer2Operator).to.be.eq(ethers.constants.Zero)

            expect(stakedOperatorAfter).to.be.gte(stakedOperatorPrev)
            expect(BigNumber.from(roundDown(stakedManagerEoaAfter,2))).to.be.gte(
                BigNumber.from(roundDown(stakedManagerEoaPrev.add(estimatedDistribute.layer2Seigs),2)))

        })

        it('requestWithdrawal to titanLayerAddress', async () => {
             let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract
            let operatorContract = titanOperatorContract
            let operatorOwner = titanManager

            let layer2 = titanLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            const beforeBalance = await wtonContract.balanceOf(account.address)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await seigManager["stakeOf(address,address)"](layer2, account.address)

            expect(roundDown(stakedA.sub(ethers.constants.Two),5)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 5)
            )

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

        })

        it('processRequest to titanLayerAddress will be fail when delay time didn\'t pass.', async () => {
            let layer2 = titanLayerAddress
            let account = addr1

            await expect(
                    depositManager.connect(account)["processRequest(address,bool)"](
                    layer2,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to titanLayerAddress.', async () => {
            let layer2 = titanLayerAddress
            let account = addr1
            const beforeBalance = await tonContract.balanceOf(account.address)
            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            let accUnstakedA = await depositManager.accUnstaked(layer2, account.address)
            let accUnstakedLayer2A = await depositManager.accUnstakedLayer2(layer2)
            let accUnstakedAccountA = await depositManager.accUnstakedAccount(account.address)

            let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay()

            await mine(globalWithdrawalDelay, { interval: 12 });

            await (await depositManager.connect(account)["processRequest(address,bool)"](
                layer2,
                true
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.add(pendingUnstakedA.div(BigNumber.from("1"+"0".repeat(9)))))

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(ethers.constants.Zero)

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.sub(pendingUnstakedA))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.sub(pendingUnstakedA))

            expect(
                await depositManager.accUnstaked(layer2, account.address)
            ).to.be.eq(accUnstakedA.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedLayer2(layer2 )
            ).to.be.eq(accUnstakedLayer2A.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedAccount(account.address)
            ).to.be.eq(accUnstakedAccountA.add(pendingUnstakedA))

        });

    })

    // 기존의 다오 candidate 테스트
    describe('# DepositManager : DAOCandidate ', () => {

        it('deposit to layer1 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor
            let tonAmount = ethers.utils.parseEther("1")

            // await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await tonContract.balanceOf(account.address);
            // console.log("beforeTONBalance :", beforeBalance);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)
            // console.log("stakedA :", stakedA);

            const data = marshalString(
                [depositManager.address, layer2Info_1.layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)
            // console.log("stakedB :", stakedB);

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 3)
            )
        })

        it('deposit to layer2 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor
            let tonAmount = ethers.utils.parseEther("1")

            // await deployed.TON.connect(deployer).transfer(account.address, tonAmount);

            const beforeBalance = await tonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(tonAmount)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, account.address)

            const data = marshalString(
                [depositManager.address, layer2Info_2.layer2]
                  .map(unmarshalString)
                  .map(str => padLeft(str, 64))
                  .join(''),
            );

            await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),1)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 1)
            )
        })

        it('deposit to layer1 using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let account = pastDepositor

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);

            const beforeBalance = await wtonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            await (await depositManager.connect(account)["deposit(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            // expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
            //     roundDown(stakedA.add(wtonAmount), 3)
            // )
        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            // console.log(deployed.seigManagerV2)
            // let account = deployer
            let account = pastDepositor
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);

            const beforeSenderBalance = await wtonContract.balanceOf(account.address);
            // console.log("beforeSenderBalance :", beforeSenderBalance);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);
            // await deployed.WTON.connect(account).approve(depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)

            await (await depositManager.connect(pastDepositor)["deposit(address,address,uint256)"](
                layer2Info_2.layer2,
                addr1.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await wtonContract.balanceOf(account.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_2.layer2, addr1.address)

            expect(roundDown(stakedB.add(ethers.BigNumber.from("1")),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        })

        it('set layerContract', async () => {
            layer2Info_1.layerContract = new ethers.Contract(
                layer2Info_1.layer2, DAOCandidate_Json.abi, deployer
            );

        });


        it('query unallocatedSeigniorage', async () => {

            let stakeOfAllLayers = await await seigManager["stakeOfAllLayers()"]();
            let stakeOfTotal = await await seigManager["stakeOfTotal()"]();
            expect(stakeOfTotal).to.be.gt(stakeOfAllLayers);
            // console.log( ' stakeOfAllLayers      ', ethers.utils.formatUnits(stakeOfAllLayers,27) , 'WTON')
            // console.log( ' stakeOfTotal      ', ethers.utils.formatUnits(stakeOfTotal,27) , 'WTON')

            let unallocatedSeigniorage = await await seigManager.unallocatedSeigniorage();
            // console.log( ' unallocatedSeigniorage      ', ethers.utils.formatUnits(unallocatedSeigniorage,27) , 'WTON')

            expect(stakeOfTotal.sub(stakeOfAllLayers)).to.be.eq(unallocatedSeigniorage);

            // console.log( ' stakeOfTotal.sub(stakeOfAllLayers)     ', ethers.utils.formatUnits(stakeOfTotal.sub(stakeOfAllLayers),27) , 'WTON')
        });

        it('updateSeigniorage to layer1', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (before)   ', ethers.utils.formatUnits(totalSupplyOfTon,27) , 'WTON')

            let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            // console.log('\n updateSeigniorage... ' )

            const receipt = await (await seigManager.connect(pastDepositor).updateSeigniorageLayer(layer2Info_1.layer2)).wait()

            const topic = seigManager.interface.getEventTopic('CommitLog1');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            // console.log('\n totalStakedAmount : ',  ethers.utils.formatUnits(deployedEvent.args.totalStakedAmount,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            expect(stakedB).to.be.gt(stakedA)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            // console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            // console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            let totalSupplyOfTon_2 = await seigManager["totalSupplyOfTon_2()"]()
            // console.log( ' totalSupplyOfTon_2    ', ethers.utils.formatUnits(totalSupplyOfTon_2,27) , 'WTON')
            expect(totalSupplyOfTon_2).to.be.gt(ethers.constants.Zero)
        })

        it('requestWithdrawal to layer1', async () => {

            let layer2 = layer2Info_1.layer2
            let account = pastDepositor
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            // let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay();
            // let getDelayBlocks = await depositManager.getDelayBlocks(layer2);
            // let numRequests = await depositManager.numRequests(layer2, account.address);
            // let index = await depositManager.withdrawalRequestIndex(layer2, account.address);
            // let withdrawalRequest = await depositManager.withdrawalRequest(layer2, account.address, index);

            const beforeBalance = await wtonContract.balanceOf(account.address)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)

            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance)

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, account.address)

            expect(roundDown(stakedA.sub(ethers.constants.Two),5)).to.be.eq(
                roundDown(stakedB.add(wtonAmount), 5)
            )

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(pendingUnstakedA.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

        })

        it('processRequest to layer1 will be fail when delay time didn\'t pass.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = pastDepositor

            let numPendingRequests = await depositManager.numPendingRequests(layer2, account.address);

            await expect(
                    depositManager.connect(account)["processRequests(address,uint256,bool)"](
                    layer2,
                     numPendingRequests,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to layer1.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = pastDepositor
            const beforeBalance = await wtonContract.balanceOf(account.address)

            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            let accUnstakedA = await depositManager.accUnstaked(layer2, account.address)
            let accUnstakedLayer2A = await depositManager.accUnstakedLayer2(layer2)
            let accUnstakedAccountA = await depositManager.accUnstakedAccount(account.address)


            let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay()

            await mine(globalWithdrawalDelay, { interval: 12 });

            let index = await depositManager.withdrawalRequestIndex(layer2, account.address);
            let numRequests = await depositManager.numRequests(layer2, account.address);
            let numPendingRequests = await depositManager.numPendingRequests(layer2, account.address);

            let withdrawalAmount = ethers.constants.Zero
            let i = 0
            for (i = index.toNumber() ; i < numRequests.toNumber() ; i++) {
                let withdrawalRequest = await depositManager.withdrawalRequest(layer2, account.address, i);
                withdrawalAmount = withdrawalAmount.add(withdrawalRequest.amount)
            }


            await (await  depositManager.connect(account)["processRequests(address,uint256,bool)"](
                layer2,
                numPendingRequests,
                false
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);

            expect(afterBalance).to.be.eq(beforeBalance.add(pendingUnstakedA))

            expect(
                await depositManager.pendingUnstaked(layer2, account.address)
            ).to.be.eq(ethers.constants.Zero)

            expect(
                await depositManager.pendingUnstakedLayer2(layer2 )
            ).to.be.eq(pendingUnstakedLayer2A.sub(pendingUnstakedA))

            expect(
                await depositManager.pendingUnstakedAccount(account.address)
            ).to.be.eq(pendingUnstakedAccountA.sub(pendingUnstakedA))

            expect(
                await depositManager.accUnstaked(layer2, account.address)
            ).to.be.eq(accUnstakedA.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedLayer2(layer2 )
            ).to.be.eq(accUnstakedLayer2A.add(pendingUnstakedA))

            expect(
                await depositManager.accUnstakedAccount(account.address)
            ).to.be.eq(accUnstakedAccountA.add(pendingUnstakedA))

        });
    })

});

