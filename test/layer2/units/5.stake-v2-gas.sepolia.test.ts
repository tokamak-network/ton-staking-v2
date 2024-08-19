import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import {encodeFunctionSignature} from 'web3-eth-abi'
import { marshalString, unmarshalString } from '../../shared/marshal';
import { gasUsedFunctions, exportLogsToExcel } from '../../shared/logUtils';

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

const layers = [
    {"oldLayer":"","newLayer":"0xaeb0463a2fd96c68369c1347ce72997406ed6409","operator":"0xd4335a175c36c0922f6a368b83f9f6671bf07606","name":"candidate"},
    {"oldLayer":"","newLayer":"0xabd15c021942ca54abd944c91705fe70fea13f0d","operator":"0x757de9c340c556b56f62efae859da5e08baae7a2","name":"member_DAO"},
]

let thanosSystemConfigOwnerAddress = "0x9E628CaAd7A6dD3ce48E78812241B41BdbeF6244"
let thanosSystemConfigOwner: Signer

let pastAddr = "0xD4335A175c36c0922F6A368b83f9F6671bf07606"
let wtonhaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
let tonHaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

const daoOwnerAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinterAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinter: Signer
let seigniorageCommitteeAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let seigniorageCommittee: Signer

let logUsedGas: Array<any> = []

// let wtonhaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

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
    let legacySystemConfigTest2: LegacySystemConfig
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

    let thanosLayerAddress: string, thanosOperatorContractAddress: string;
    let thanosLayerContract: CandidateAddOnV1_1;
    let thanosOperatorContract: OperatorManagerV1_1


    let powerTon: string
    let pastDepositor:Signer, wtonHave:Signer, tonHave:Signer
    let layer2Info_1 : any;
    let layer2Info_2 : any;

    before('create fixture loader', async () => {
        const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, powerTonAddress } = await getNamedAccounts();

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
        tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)
        wtonContract = new ethers.Contract(WTON,  Wton_Json.abi, deployer)
        daoContract = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeProxy_Json.abi, deployer)
        depositManager = new ethers.Contract(DepositManager,  DepositManager_Json.abi, deployer)
        depositManagerProxy = new ethers.Contract(DepositManager,  DepositManagerProxy_Json.abi, deployer)

        seigManager = new ethers.Contract(SeigManager,  SeigManager_Json.abi, deployer)
        seigManagerProxy = new ethers.Contract(SeigManager,  SeigManagerProxy_Json.abi, deployer)
        powerTon = powerTonAddress
        // tonContract.connect(tonMinter).mint(addr1, utils.parseEther("2000"))
        // wtonContract.connect(tonMinter).mint(addr1, utils.parseEther("2000"))

        await hre.network.provider.send("hardhat_impersonateAccount", [
            pastAddr,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            pastAddr,
            "0x10000000000000000000000000",
        ]);
        pastDepositor = await hre.ethers.getSigner(pastAddr);

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
            tonMinterAddress,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            tonMinterAddress,
            "0x10000000000000000000000000",
        ]);
        tonMinter = await hre.ethers.getSigner(tonMinterAddress);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            seigniorageCommitteeAddress,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            seigniorageCommitteeAddress,
            "0x10000000000000000000000000",
        ]);
        seigniorageCommittee = await hre.ethers.getSigner(seigniorageCommitteeAddress);


        await hre.network.provider.send("hardhat_impersonateAccount", [
            thanosSystemConfigOwnerAddress,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            thanosSystemConfigOwnerAddress,
            "0x10000000000000000000000000",
        ]);
        thanosSystemConfigOwner = await hre.ethers.getSigner(thanosSystemConfigOwnerAddress);

    })

    describe('# L1BridgeRegistry', () => {
        it('deploy', async () => {
            l1BridgeRegistryV_1 = (await (await ethers.getContractFactory("L1BridgeRegistryV1_1")).connect(deployer).deploy()) as L1BridgeRegistryV1_1;
            l1BridgeRegistryProxy = (await (await ethers.getContractFactory("L1BridgeRegistryProxy")).connect(deployer).deploy()) as L1BridgeRegistryProxy;

            await (await l1BridgeRegistryProxy.connect(deployer).upgradeTo(l1BridgeRegistryV_1.address)).wait()

            l1BridgeRegistry = (await ethers.getContractAt("L1BridgeRegistryV1_1", l1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryV1_1

        });
    })

    describe('# seigniorageCommittee', () => {

        it('setSeigniorageCommittee can not be executed by not an admin', async () => {

            expect(await l1BridgeRegistry.isAdmin(addr1.address)).to.be.eq(false)

            await expect(
                l1BridgeRegistry.connect(addr1).setSeigniorageCommittee(
                    seigniorageCommitteeAddress
                )
                ).to.be.revertedWith("AuthControl: Caller is not an admin")
        })

        it('setSeigniorageCommittee can be executed by admin', async () => {
            expect(await l1BridgeRegistry.isAdmin(deployer.address)).to.be.eq(true)

            let receipt = await (await l1BridgeRegistry.connect(deployer).setSeigniorageCommittee(
                seigniorageCommitteeAddress
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('SetSeigniorageCommittee');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args._seigniorageCommittee).to.be.eq(seigniorageCommitteeAddress)
            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
        })

    })

    describe('# OperatorManagerFactory', () => {
        it('deploy OperatorManagerV1_1', async () => {
            operatorManagerV1_1 = (await (await ethers.getContractFactory("OperatorManagerV1_1")).connect(deployer).deploy()) as OperatorManagerV1_1;
        });

        it('deploy OperatorManagerFactory ', async () => {

            operatorManagerFactory = (await (await ethers.getContractFactory("OperatorManagerFactory")).connect(deployer).deploy(operatorManagerV1_1.address)) as OperatorManagerFactory;
        })
    })

    describe('# CandidateAddOnV1_1', () => {
        it('deploy candidateAddOnV1_1Imp', async () => {
            candidateAddOnV1_1Imp = (await (await ethers.getContractFactory("CandidateAddOnV1_1")).connect(deployer).deploy()) as CandidateAddOnV1_1;
        });
    })

    describe('# CandidateAddOnFactoryProxy', () => {
        it('deploy', async () => {
            candidateAddOnFactoryImp = (await (await ethers.getContractFactory("CandidateAddOnFactory")).connect(deployer).deploy()) as CandidateAddOnFactory;
            candidateAddOnFactoryProxy = (await (await ethers.getContractFactory("CandidateAddOnFactoryProxy")).connect(deployer).deploy()) as CandidateAddOnFactoryProxy;

            await (await candidateAddOnFactoryProxy.connect(deployer).upgradeTo(candidateAddOnFactoryImp.address)).wait()

            candidateAddOnFactory = (await ethers.getContractAt("CandidateAddOnFactory", candidateAddOnFactoryProxy.address, deployer)) as CandidateAddOnFactory

            const { DepositManager, DAOCommitteeProxy, TON, WTON} = await getNamedAccounts();

            await (await candidateAddOnFactory.connect(deployer).setAddress(
                DepositManager,
                DAOCommitteeProxy,
                candidateAddOnV1_1Imp.address,
                TON,
                WTON,
                l1BridgeRegistryProxy.address
            )).wait()
        });
    })

    describe('# Layer2Manager', () => {
        it('deploy', async () => {
            layer2ManagerV1_1 = (await (await ethers.getContractFactory("Layer2ManagerV1_1")).connect(deployer).deploy()) as Layer2ManagerV1_1;
            layer2ManagerProxy = (await (await ethers.getContractFactory("Layer2ManagerProxy")).connect(deployer).deploy()) as Layer2ManagerProxy;
            await (await layer2ManagerProxy.connect(deployer).upgradeTo(layer2ManagerV1_1.address)).wait()
            layer2Manager = (await ethers.getContractAt("Layer2ManagerV1_1", layer2ManagerProxy.address, deployer)) as Layer2ManagerV1_1
        });

        it('addManager can be executed by admin', async () => {
            const receipt = await (await l1BridgeRegistryProxy.connect(deployer).addManager(manager.address)).wait()
            expect(await l1BridgeRegistryProxy.isManager(manager.address)).to.be.eq(true)

            logUsedGas.push(gasUsedFunctions('L1BridgeRegistry', 'addManager', '', receipt))
        })

        it('OperatorManagerFactory.setAddresses', async () => {
            const {DepositManager, TON, WTON } = await getNamedAccounts();

            const receipt = await (await operatorManagerFactory.connect(deployer).setAddresses(
                DepositManager,
                TON,
                WTON,
                layer2ManagerProxy.address
            )).wait()

            logUsedGas.push(gasUsedFunctions('OperatorManagerFactory', 'setAddresses', '', receipt))
        })

    })

    describe('# setAddresses', () => {

        it('setAddresses can not be executed by not an admin', async () => {
            const {TON, WTON, DAOCommitteeProxy, DepositManager, SeigManager, swapProxy} = await getNamedAccounts();

            expect(await layer2Manager.isAdmin(addr1.address)).to.be.eq(false)

            await expect(
                layer2Manager.connect(addr1).setAddresses(
                    l1BridgeRegistryProxy.address,
                    operatorManagerFactory.address,
                    TON, WTON, DAOCommitteeProxy, DepositManager,
                    SeigManager, swapProxy
                )
                ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('setAddresses can be executed by admin', async () => {

            const {TON, WTON, DAOCommitteeProxy, DepositManager, SeigManager, swapProxy} = await getNamedAccounts();
            expect(await layer2Manager.isAdmin(deployer.address)).to.be.eq(true)

            let receipt = await (await layer2Manager.connect(deployer).setAddresses(
                l1BridgeRegistryProxy.address,
                operatorManagerFactory.address,
                TON, WTON, DAOCommitteeProxy, DepositManager, SeigManager, swapProxy
            )).wait()

            const topic = layer2Manager.interface.getEventTopic('SetAddresses');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);

            expect(deployedEvent.args._l2Register).to.be.eq(l1BridgeRegistryProxy.address)
            expect(deployedEvent.args._operatorManagerFactory).to.be.eq(operatorManagerFactory.address)
            expect(deployedEvent.args._ton).to.be.eq(TON)
            expect(deployedEvent.args._wton).to.be.eq(WTON)
            expect(deployedEvent.args._dao).to.be.eq(DAOCommitteeProxy)
            expect(deployedEvent.args._depositManager).to.be.eq(DepositManager)
            expect(deployedEvent.args._seigManager).to.be.eq(SeigManager)
            expect(deployedEvent.args._swapProxy).to.be.eq(swapProxy)

            // expect(deployedEvent.args.accounts[0]).to.be.eq(l1BridgeRegistryProxy.address)
            // expect(deployedEvent.args.accounts[1]).to.be.eq(operatorManagerFactory.address)
            // expect(deployedEvent.args.accounts[2]).to.be.eq(TON)
            // expect(deployedEvent.args.accounts[3]).to.be.eq(WTON)
            // expect(deployedEvent.args.accounts[4]).to.be.eq(DAOCommitteeProxy)
            // expect(deployedEvent.args.accounts[5]).to.be.eq(DepositManager)
            // expect(deployedEvent.args.accounts[6]).to.be.eq(SeigManager)
            // expect(deployedEvent.args.accounts[7]).to.be.eq(swapProxy)


            logUsedGas.push(gasUsedFunctions('Layer2Manager', 'setAddresses', '', receipt))
        })

    })

    describe('# setMinimumInitialDepositAmount', () => {

        it('setMinimumInitialDepositAmount can not be executed by not an admin', async () => {

            expect(await layer2Manager.isAdmin(addr1.address)).to.be.eq(false)
            let minimumInitialDepositAmount = ethers.utils.parseEther("1000")
            await expect(
                layer2Manager.connect(addr1).setMinimumInitialDepositAmount(minimumInitialDepositAmount)
                ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('setMinimumInitialDepositAmount can be executed by admin', async () => {

            expect(await layer2Manager.isAdmin(deployer.address)).to.be.eq(true)
            let minimumInitialDepositAmount = ethers.utils.parseEther("1000")
            const receipt = await (await layer2Manager.connect(deployer).setMinimumInitialDepositAmount(minimumInitialDepositAmount)).wait()
            expect(await layer2Manager.minimumInitialDepositAmount()).to.be.eq(minimumInitialDepositAmount)

            logUsedGas.push(gasUsedFunctions('Layer2Manager', 'setMinimumInitialDepositAmount', '', receipt))
        })

        it('cannot set with same minimumInitialDepositAmount ', async () => {

            let minimumInitialDepositAmount = await layer2Manager.minimumInitialDepositAmount();

            await expect(
                layer2Manager.connect(deployer).setMinimumInitialDepositAmount(
                    minimumInitialDepositAmount
                )
            ).to.be.revertedWith("same")
        })

    })

    describe('# LegacySystemConfig : Titan ', () => {

        it('set Titan LegacySystemConfig ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            legacySystemConfig = (await (await ethers.getContractFactory("LegacySystemConfig")).connect(deployer).deploy()) as LegacySystemConfig;

            let name = 'Titan'
            let addresses = {
                l1CrossDomainMessenger: l1MessengerAddress,
                l1ERC721Bridge: ethers.constants.AddressZero,
                l1StandardBridge: l1BridgeAddress,
                l2OutputOracle: ethers.constants.AddressZero,
                optimismPortal: ethers.constants.AddressZero,
                optimismMintableERC20Factory: ethers.constants.AddressZero
            }
            let l2Ton = l2TonAddress

            const receipt = await (await legacySystemConfig.connect(deployer).setAddresses(
                name, addresses, l2Ton, l1BridgeRegistryProxy.address
            )).wait()

            logUsedGas.push(gasUsedFunctions('SystemConfig', 'setAddresses', '', receipt))
        })

        it('registerRollupConfigByManager  ', async () => {
            let type = 1;
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let receipt = await (await l1BridgeRegistry.connect(manager).registerRollupConfigByManager(
                legacySystemConfig.address,
                type,
                l2TonAddress
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('RegisteredRollupConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.type_).to.be.eq(type)

            logUsedGas.push(gasUsedFunctions('L1BridgeRegistry', 'registerRollupConfigByManager', '', receipt))
        })
    })

    describe('# LegacySystemConfig Test2', () => {

        it('set legacySystemConfigTest2 ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            legacySystemConfigTest2 = (await (await ethers.getContractFactory("LegacySystemConfig")).connect(deployer).deploy()) as LegacySystemConfig;

            let name = 'Thanos'
            let addresses = {
                l1CrossDomainMessenger: l1MessengerAddress,
                l1ERC721Bridge: ethers.constants.AddressZero,
                l1StandardBridge: l1BridgeAddress,
                l2OutputOracle: ethers.constants.AddressZero,
                optimismPortal: ethers.constants.AddressZero,
                optimismMintableERC20Factory: ethers.constants.AddressZero
            }
            let l2Ton = l2TonAddress

            const receipt = await (await legacySystemConfigTest2.connect(deployer).setAddresses(
                name, addresses, l2Ton, l1BridgeRegistryProxy.address
            )).wait()

            logUsedGas.push(gasUsedFunctions('L1BridgeRegistry', 'setAddresses', '', receipt))
        })

        it('registerRollupConfigByManager : Already registered l2Bridge addresses cannot be registered. ', async () => {
            let type = 1;
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

             await expect(l1BridgeRegistry.connect(manager).registerRollupConfigByManager(
                legacySystemConfigTest2.address,
                type,
                l2TonAddress
            )).to.be.revertedWith("RegisterError")
        })
    })

    describe('# checkLayer2TVL', () => {
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

    describe('# ThanosSystemConfig : Thanos ', () => {

        it('registerRollupConfigByManager  ', async () => {
            const {thanosSystemConfig, thanosL2TON } = await getNamedAccounts();

            let type = 2;

            let receipt = await (await l1BridgeRegistry.connect(manager).registerRollupConfigByManager(
                thanosSystemConfig,
                type,
                thanosL2TON
            )).wait()

            logUsedGas.push(gasUsedFunctions('L1BridgeRegistry', 'registerRollupConfigByManager', 'Thanos SystemConfig ', receipt))

            const topic = l1BridgeRegistry.interface.getEventTopic('RegisteredRollupConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(thanosSystemConfig)
            expect(deployedEvent.args.type_).to.be.eq(type)

        })
    })

    describe('# DAO.upgradeTo(DAOCommitteeAddV1_1) , SeigManagerV1_3 ', () => {
        it('deploy DAOCommitteeAddV1_1', async () => {
            daoCommitteeAddV1_1 = (await (await ethers.getContractFactory("DAOCommitteeAddV1_1")).connect(deployer).deploy()) as DAOCommitteeAddV1_1;
        })

        it('deploy SeigManagerV1_3', async () => {
            seigManagerV1_3 = (await (await ethers.getContractFactory("SeigManagerV1_3")).connect(deployer).deploy()) as SeigManagerV1_3;
        })

        it('deploy DepositManagerV1_1', async () => {
            depositManagerV1_1 = (await (await ethers.getContractFactory("DepositManagerV1_1")).connect(deployer).deploy()) as DepositManagerV1_1;
        })

        // it('setProxyPause', async () => {
        //     await (await daoContract.connect(daoOwner).setProxyPause(false)).wait()
        // })

        // it('changeLogic', async () => {
        //     const {DAOCommitteeOwner  } = await getNamedAccounts();

        //     await (await daoContract.connect(daoOwner).upgradeTo(DAOCommitteeOwner)).wait()
        // })

        it('upgradeTo', async () => {
            await (await daoContract.connect(daoOwner).upgradeTo(daoCommitteeAddV1_1.address)).wait()
        })

        it('SeigManager register function ', async () => {
            daoV2Contract = new ethers.Contract(daoContract.address, DAOCommitteeAddV1_1_Json.abi, deployer);

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

            let functionBytecodes = [
                selector1, selector2, selector3, selector4, selector5,
                selector6, selector7, selector8, selector9, selector10,
                selector11, selector12, selector13, selector14, selector15,
                selector16 ];

            const index = 1;
            expect(await seigManagerProxy.implementation2(index)).to.be.eq(ethers.constants.AddressZero)

            // await (await daoV2Contract.connect(daoOwner).setTargetSetImplementation2(
            //     seigManager.address,
            //     seigManagerV1_3.address,
            //     index, true)).wait();

            // await (await daoV2Contract.connect(daoOwner).setTargetSetSelectorImplementations2(
            //     seigManager.address,
            //     functionBytecodes,
            //     seigManagerV1_3.address)).wait()

            await (await seigManagerProxy.connect(daoOwner).setImplementation2(
                seigManagerV1_3.address,
                index, true)).wait();

            await (await seigManagerProxy.connect(daoOwner).setSelectorImplementations2(
                functionBytecodes,
                seigManagerV1_3.address)).wait()

            expect(await seigManagerProxy.implementation2(index)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector1)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector2)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector3)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector4)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector5)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector6)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector7)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector8)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector9)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector9)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector10)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector11)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector12)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector13)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector14)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector15)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector16)).to.be.eq(seigManagerV1_3.address)

        })

        it('DepositManager register function ', async () => {

            // const checkL1Bridge = encodeFunctionSignature("checkL1Bridge()");
            // console.log('checkL1Bridge', checkL1Bridge)
            // const onWithdraw = encodeFunctionSignature("onWithdraw(address,address,uint256)");
            // console.log('onWithdraw', onWithdraw)
            // const swapToTONAndTransfer = encodeFunctionSignature("swapToTONAndTransfer(address,uint256)");
            // console.log('swapToTONAndTransfer', swapToTONAndTransfer)

            const selector1 = encodeFunctionSignature("ton()");
            const selector2 = encodeFunctionSignature("minDepositGasLimit()");
            const selector3 = encodeFunctionSignature("setMinDepositGasLimit(uint256)");
            const selector4 = encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");

            let functionBytecodes = [
                selector1, selector2, selector3, selector4 ];

            const index = 1;
            expect(await depositManagerProxy.implementation2(index)).to.be.eq(ethers.constants.AddressZero)

            // await (await daoV2Contract.connect(daoOwner).setTargetSetImplementation2(
            //     depositManager.address,
            //     depositManagerV1_1.address,
            //     index, true)).wait();

            // await (await daoV2Contract.connect(daoOwner).setTargetSetSelectorImplementations2(
            //     depositManager.address,
            //     functionBytecodes,
            //     depositManagerV1_1.address)).wait()

            await (await depositManagerProxy.connect(daoOwner).setImplementation2(
                depositManagerV1_1.address,
                index, true)).wait();

            await (await depositManagerProxy.connect(daoOwner).setSelectorImplementations2(
                functionBytecodes,
                depositManagerV1_1.address)).wait()

            expect(await depositManagerProxy.implementation2(index)).to.be.eq(depositManagerV1_1.address)
            expect(await depositManagerProxy.getSelectorImplementation2(selector1)).to.be.eq(depositManagerV1_1.address)
            expect(await depositManagerProxy.getSelectorImplementation2(selector2)).to.be.eq(depositManagerV1_1.address)
            expect(await depositManagerProxy.getSelectorImplementation2(selector3)).to.be.eq(depositManagerV1_1.address)
            expect(await depositManagerProxy.getSelectorImplementation2(selector4)).to.be.eq(depositManagerV1_1.address)

        })

        it('setCandidateFactory to candidateAddOnFactory', async () => {
            await (await daoV2Contract.connect(daoOwner).setCandidateAddOnFactory(candidateAddOnFactory.address)).wait()
        })

        it('setLayer2Manager to layer2Manager', async () => {
            await (await daoV2Contract.connect(daoOwner).setLayer2Manager(layer2Manager.address)).wait()
        })

        it('setTargetSetLayer2Manager to layer2Manager', async () => {
            // await (await daoV2Contract.connect(daoOwner).setTargetSetLayer2Manager(seigManager.address, layer2Manager.address)).wait()

            await (await seigManager.connect(daoOwner).setLayer2Manager(layer2Manager.address)).wait()
        })

        it('setTargetSetL1BridgeRegistry to l2Register', async () => {
            // await (await daoV2Contract.connect(daoOwner).setTargetSetL1BridgeRegistry(seigManager.address, l1BridgeRegistry.address)).wait()

            await (await seigManager.connect(daoOwner).setL1BridgeRegistry(l1BridgeRegistry.address)).wait()
        })
    })

    describe('# registerCandidateAddOn ', () => {
        it('Fail if rollupConfig is an invalid address', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                l1BridgeRegistry.address,
                amount,
                true,
                'test1'
            )).to.be.rejectedWith("RegisterError(5)")
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
            )).to.be.rejectedWith("ZeroBytesError()")
        })

        it('registerCandidateAddOn', async () => {
            expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(0)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(tonMinter).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfig.name()
            const operatorAddress = await operatorManagerFactory.getAddress(legacySystemConfig.address)

            const receipt = await (await layer2Manager.connect(addr1).registerCandidateAddOn(
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

            logUsedGas.push(gasUsedFunctions('Layer2Manager', 'registerCandidateAddOn', 'using registerCandidateAddOn function', receipt))
        })

        it('If the layer has already been created, it will fail.', async () => {

            expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(1)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(tonMinter).mint(addr1.address, amount))
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

        it('Layers that are not registered in the L1BridgeRegistry cannot be registered.', async () => {
            expect((await layer2Manager.statusLayer2(legacySystemConfigTest2.address))).to.be.eq(0)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(tonMinter).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfigTest2.name()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                legacySystemConfigTest2.address,
                amount,
                true,
                name
            ) ).to.be.revertedWith("RegisterError");

        });

    })

    describe('# Operator Contract ', () => {

        it('Check Storages', async () => {
            // titanLayerContract =  (await ethers.getContractAt("CandidateAddOnV1_1", titanLayerAddress, deployer)) as CandidateAddOnV1_1
            expect(await titanOperatorContract.rollupConfig()).to.be.eq(legacySystemConfig.address)
            expect(await titanOperatorContract.layer2Manager()).to.be.eq(layer2Manager.address)
            expect(await titanOperatorContract.depositManager()).to.be.eq(depositManager.address)
            expect(await titanOperatorContract.ton()).to.be.eq(tonContract.address)
            expect(await titanOperatorContract.wton()).to.be.eq(wtonContract.address)
            expect(await titanOperatorContract.manager()).to.be.eq(deployer.address)

        })

        it('Only Manager can execute setExplorer function', async () => {
             let url = 'https://explorer.titan-sepolia.tokamak.network/'
            await expect(titanOperatorContract.connect(addr2).setExplorer(
                url
            )).to.be.rejectedWith("not onlyOwnerOrManager")
        })

        it('Only Manager can execute setExplorer function', async () => {
            let url = 'https://explorer.titan-sepolia.tokamak.network/'
            const receipt = await (await titanOperatorContract.connect(deployer).setExplorer(
                url
            )).wait()

            const topic = titanOperatorContract.interface.getEventTopic('SetExplorer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = titanOperatorContract.interface.parseLog(log);
            expect(deployedEvent.args._explorer).to.be.eq(url)
        })
    })


    describe('# L2Register', () => {

        describe('# setAddresses', () => {
            it('setAddresses : onlyOwner ', async () => {
                const {TON} = await getNamedAccounts();

                await expect(
                    l1BridgeRegistry.connect(addr1).setAddresses(
                        layer2Manager.address,
                        seigManager.address,
                        TON
                    )
                ).to.be.revertedWith("AuthControl: Caller is not an admin")
            })

            it('setAddresses : onlyOwner ', async () => {
                const {TON} = await getNamedAccounts();

                await (await l1BridgeRegistry.connect(deployer).setAddresses(
                        layer2Manager.address,
                        seigManager.address,
                        TON
                )).wait()

                expect(await l1BridgeRegistry.layer2Manager()).to.be.eq(layer2Manager.address)
            })
        })

    })

    describe('# SeigManagerV1_3', () => {
        it('SeigManagerV1_3 : setLayer2StartBlock', async () => {
            let block1 = await ethers.provider.getBlock('latest');
            // await (await daoV2Contract.connect(daoOwner).setTargetLayer2StartBlock(seigManager.address, block1.number + 1))
            const receipt = await (await seigManager.connect(daoOwner).setLayer2StartBlock(block1.number + 1)).wait()

            logUsedGas.push(gasUsedFunctions('SeigManagerV1_3', 'setLayer2StartBlock', '', receipt))
        });
    });


    describe('# DepositManager : CandidateAddOn ', () => {

        // titanLayerAddress = deployedEvent.args.candidateAddOn;
        // titanOperatorContractAddress = deployedEvent.args.operator;

        it('deposit to titanLayerAddress using approveAndCall', async () => {

            let account = addr1
            let amount = ethers.utils.parseEther("2000")
            await (await tonContract.connect(tonMinter).mint(addr1.address, amount))

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

            const receipt = await (await tonContract.connect(account).approveAndCall(
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

            logUsedGas.push(gasUsedFunctions('DepositManager', 'approveAndCall', 'deposit TON to Titan Candidate', receipt))

        })

        it('deposit to titanLayerAddress using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let account = addr2

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

            const beforeBalance = await wtonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)
            // console.log(stakedA)

            const receipt = await (await depositManager.connect(account)["deposit(address,uint256)"](
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

            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,uint256)', 'deposit WTON to Titan Candidate', receipt))

        })

        it('deposit to titanLayerAddress using deposit(address,address,uint256) ', async () => {

            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

            const beforeSenderBalance = await wtonContract.balanceOf(account.address);
            // console.log("beforeSenderBalance :", beforeSenderBalance);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            const receipt = await (await depositManager.connect(account)["deposit(address,address,uint256)"](
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

            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,address,uint256)', 'deposit WTON to Titan Candidate', receipt))

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

        it('seigManager: updateSeigniorageLayer : the first updateSeigniorage to titanLayerAddress : no give seigniorage to l2', async () => {
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
            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManagerV1_3', 'updateSeigniorageLayer(layerAddress)', 'the first updateSeigniorage : no give seigniorage to l2', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

        it('seigManager: updateSeigniorageLayer : the second updateSeigniorage to titanLayerAddress : not operator ', async () => {
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManagerV1_3', 'updateSeigniorageLayer(layerAddress)', 'the second updateSeigniorage : not operator', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(deployer.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(deployer)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManagerV1_3', 'updateSeigniorage(1)', 'the third updateSeigniorage of operator with claiming', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)

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

            // expect(afterWtonBalanceOfManager).to.be.eq(prevWtonBalanceOfLayer2Operator.add(estimatedDistribute.layer2Seigs))

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

            // console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(deployer.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(deployer)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManagerV1_3', 'updateSeigniorage(2)', 'the forth updateSeigniorage of operator with staking ', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)

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

            expect(stakedOperatorAfter).to.be.gte(stakedOperatorPrev.add(estimatedDistribute.layer2Seigs))

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

            const receipt = await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'requestWithdrawal', '', receipt))

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

            const receipt = await (await depositManager.connect(account)["processRequest(address,bool)"](
                layer2,
                true
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'processRequest', '', receipt))

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

            const receipt = await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'approveAndCall', 'deposit TON to DAOCandidate', receipt))

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

            const receipt = await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'approveAndCall', 'deposit TON to DAOCandidate', receipt))

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

            const receipt = await (await depositManager.connect(account)["deposit(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,uint256)', 'deposit WTON to DAOCandidate', receipt))

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

            const receipt = await (await depositManager.connect(pastDepositor)["deposit(address,address,uint256)"](
                layer2Info_2.layer2,
                addr1.address,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,address,uint256)', 'deposit WTON to DAOCandidate', receipt))

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

            let powerTonBalance = await wtonContract.balanceOf(powerTon);
            // console.log('\n updateSeigniorage... ' )

            const receipt = await (await seigManager.connect(pastDepositor).updateSeigniorageLayer(layer2Info_1.layer2)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManagerV1_3', 'updateSeigniorageLayer(layerAddress)', 'updateSeigniorage to DAOCandidate', receipt))

            const topic = seigManager.interface.getEventTopic('CommitLog1');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            // console.log('\n totalStakedAmount : ',  ethers.utils.formatUnits(deployedEvent.args.totalStakedAmount,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            expect(stakedB).to.be.gt(stakedA)
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalance)

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

            const receipt = await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'requestWithdrawal(address,uint256)', '', receipt))

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


            const receipt = await (await  depositManager.connect(account)["processRequests(address,uint256,bool)"](
                layer2,
                numPendingRequests,
                false
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'processRequests(address,uint256,bool)', '', receipt))

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

            const receipt = await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'approveAndCall', 'deposit TON to Titan CandidateAddOn', receipt))

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

            const receipt = await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'approveAndCall', 'deposit TON to DAO Candidate', receipt))

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

        it('withdrawAndDepositL2 : Failure if the request amount is zero', async () => {

            let account = tonHave

            await expect(depositManager.connect(account).withdrawAndDepositL2(
                titanLayerAddress,
                ethers.constants.Zero
            )).to.be.revertedWith("ZeroValueError")
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
            logUsedGas.push(gasUsedFunctions('DepositManager', 'withdrawAndDepositL2', '', receipt))

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

            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
            expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(false)

            let l2Info = await seigManager.layer2RewardInfo(titanLayerAddress)
            let totalLayer2TVL = await seigManager.totalLayer2TVL()
            let allowIssuanceLayer2Seigs = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
            expect(allowIssuanceLayer2Seigs.allowed).to.be.eq(true)

            const receipt =  await (await l1BridgeRegistry.connect(seigniorageCommittee).rejectCandidateAddOn(
                legacySystemConfig.address
            )).wait()

            logUsedGas.push(gasUsedFunctions('L1BridgeRegistry', 'rejectCandidateAddOn', 'legacySystemConfig', receipt))

            const topic = l1BridgeRegistry.interface.getEventTopic('RejectedCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);
            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)

            const topic1 = layer2Manager.interface.getEventTopic('PausedCandidateAddOn');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = layer2Manager.interface.parseLog(log1);
            expect(deployedEvent1.args.rollupConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent1.args._layer2).to.be.eq(titanLayerAddress)

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

        it('In the case of stopped layer 2, the result value of the checkL1Bridge function is false.', async () =>{

            let checkL1Bridge = await layer2Manager.checkL1Bridge(legacySystemConfig.address)
            expect(checkL1Bridge.result).to.be.eq(false)
        })

        it('deposit to titanLayerAddress using approveAndCall', async () => {

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

            const receipt = await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'approveAndCall', 'deposit TON to DAO Candidate', receipt))

            const afterBalance = await tonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(tonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(tonAmount.mul(ethers.BigNumber.from("1000000000"))), 3)
            )
        })

        it('In the case of stopped layer 2, The withdrawAndDepositL2 function cannot be executed.', async () =>{

            let account = tonHave

            let rollupConfig = await titanOperatorContract.rollupConfig()
            expect(rollupConfig).to.be.not.eq(ethers.constants.AddressZero)

            let prevLayer2TVL = await l1BridgeRegistry.layer2TVL(rollupConfig)
            let stakedA = await seigManager["stakeOf(address,address)"](titanLayerAddress, account.address)

            await expect( depositManager.connect(account).withdrawAndDepositL2(
                titanLayerAddress,
                stakedA
            )).to.be.revertedWith("CheckL1BridgeError")

        })

        it('register CandidateAddOn : thanosCandidateAddOn', async () => {
            const {thanosSystemConfig, thanosL2TON } = await getNamedAccounts();

            expect((await layer2Manager.statusLayer2(thanosSystemConfig))).to.be.eq(0)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(tonMinter).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = 'Thanos'
            const operatorAddress = await operatorManagerFactory.getAddress(thanosSystemConfig)

            const receipt = await (await layer2Manager.connect(addr1).registerCandidateAddOn(
                thanosSystemConfig,
                amount,
                true,
                name
            )).wait()

            logUsedGas.push(gasUsedFunctions('L1BridgeRegistry', 'registerCandidateAddOn', 'thanos SystemConfig', receipt))

            const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(thanosSystemConfig)
            expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            expect(deployedEvent.args.memo).to.be.eq(name)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

            thanosLayerAddress = deployedEvent.args.candidateAddOn;
            thanosOperatorContractAddress = deployedEvent.args.operator;
            expect((await layer2Manager.statusLayer2(thanosSystemConfig))).to.be.eq(1)
            expect((await l1BridgeRegistry.rollupType(thanosSystemConfig))).to.be.eq(2)

            thanosLayerContract =  (await ethers.getContractAt("CandidateAddOnV1_1", thanosLayerAddress, deployer)) as CandidateAddOnV1_1
            thanosOperatorContract = (await ethers.getContractAt("OperatorManagerV1_1", thanosOperatorContractAddress, deployer)) as OperatorManagerV1_1
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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            const allowIssuanceLayer2Seigs = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
            expect(allowIssuanceLayer2Seigs.allowed).to.be.eq(false)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', 'titanLayerAddress', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(deployer.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(deployer)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('titanLayerContract', 'updateSeigniorage', 'with claim', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)

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
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(deployer.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(deployer)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('titanLayerContract', 'updateSeigniorage', 'with staking', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const afterWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)

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


    describe('# DepositManager : CandidateAddOn : thanosCandidateAddOn ', () => {

        it('deposit to thanosLayerAddress using approveAndCall', async () => {
            let layerAddress = thanosLayerAddress
            let account = addr1
            let amount = ethers.utils.parseEther("200000")
            await (await tonContract.connect(tonMinter).mint(addr1.address, amount))

            const beforeBalance = await tonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(amount)

            let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
            // console.log("stakedA :", stakedA);

            const data = marshalString(
                [depositManager.address, layerAddress]
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

            let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
            // console.log("stakedB :", stakedB);

            expect(roundDown(stakedB.add(ethers.constants.Two),4)).to.be.eq(
                roundDown(stakedA.add(amount.mul(ethers.BigNumber.from("1000000000"))), 4)
            )
        })

        it('deposit to thanosLayerAddress using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)
            let layerAddress = thanosLayerAddress
            let account = addr2

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

            const beforeBalance = await wtonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
            // console.log(stakedA)

            const receipt = await (await depositManager.connect(account)["deposit(address,uint256)"](
                layerAddress,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,uint256)', '', receipt))

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
            // console.log(stakedB)

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        })

        it('seigManager: updateSeigniorageLayer : the first updateSeigniorage to thanosLayer : no give seigniorage to l2', async () => {
            let layerAddress = thanosLayerAddress
            let operatorContractAddress = thanosOperatorContractAddress
            let layerContract = thanosLayerContract

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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            // console.log('stakedPrev', stakedPrev)
            // console.log('stakedAddr1Prev', stakedAddr1Prev)
            // console.log('stakedAddr2Prev', stakedAddr2Prev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', 'no give seigniorage to l2', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            // expect(deployedEvent1.args.layer2Seigs).to.be.eq(ethers.constants.Zero);

        })

        it('deposit to thanosLayerAddress using deposit(address,address,uint256) ', async () => {
            let layerAddress = thanosLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

            const beforeSenderBalance = await wtonContract.balanceOf(account.address);
            // console.log("beforeSenderBalance :", beforeSenderBalance);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            const receipt = await (await depositManager.connect(account)["deposit(address,address,uint256)"](
                layerAddress,
                addr2.address,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,address,uint256)', '', receipt))

            const afterSenderBalance = await wtonContract.balanceOf(account.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            expect(roundDown(stakedB.add(ethers.BigNumber.from("3")),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer : the second updateSeigniorage to thanosLayerAddress : give seigniorage to l2', async () => {
            let layerAddress = thanosLayerAddress
            let operatorContractAddress = thanosOperatorContractAddress
            let layerContract = thanosLayerContract
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            // console.log('systemConfig', systemConfig)

            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', 'give seigniorage to l2', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

        it('seigManager: updateSeigniorageLayer : the third updateSeigniorage to thanosLayerAddress : not operator ', async () => {
            let layerAddress = thanosLayerAddress
            let operatorContractAddress = thanosOperatorContractAddress
            let layerContract = thanosLayerContract

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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', 'not operator', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

        it('Layer2Contract: updateSeigniorage : operator claim: the fourth updateSeigniorage to thanosLayerAddress : operator ', async () => {
            let layerAddress = thanosLayerAddress
            let operatorContractAddress = thanosOperatorContractAddress
            let operatorContract = thanosOperatorContract
            let layerContract = thanosLayerContract
            let operatorOwner = thanosSystemConfigOwner
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('operatorContractAddress', operatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(operatorOwner.address)

            const prevUnSettledReward = await seigManager.unSettledReward(layerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, layerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await operatorContract.isOperator(thanosSystemConfigOwner.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            const receipt = await (await layerContract.connect(thanosSystemConfigOwner)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('Layer2Contract', 'updateSeigniorage', 'operator', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

            let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
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

        it('Layer2Contract: updateSeigniorage : operator staking : the fifth updateSeigniorage to titanLayerAddress : operator ', async () => {
            let layerAddress = thanosLayerAddress
            let operatorContractAddress = thanosOperatorContractAddress
            let operatorContract = thanosOperatorContract
            let layerContract = thanosLayerContract
            let operatorOwner = thanosSystemConfigOwner

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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, layerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await operatorContract.isOperator(operatorOwner.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await layerContract.connect(operatorOwner)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('Layer2Contract', 'updateSeigniorage', 'with operator\'s staking', receipt))

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

            // console.log('stakedOperatorAfter', stakedOperatorAfter)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

            expect(stakedOperatorAfter).to.be.gte(stakedOperatorPrev.add(estimatedDistribute.layer2Seigs))

        })

        it('requestWithdrawal to titanLayerAddress', async () => {
            // let layerAddress = thanosLayerAddress
            // let operatorContractAddress = thanosOperatorContractAddress
            // let operatorContract = thanosOperatorContract
            // let layerContract = thanosLayerContract
            // let operatorOwner = thanosSystemConfigOwner

            let layer2 = thanosLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            const beforeBalance = await wtonContract.balanceOf(account.address)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            const receipt = await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'requestWithdrawal', '', receipt))

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
            let layer2 = thanosLayerAddress
            let account = addr1

            await expect(
                    depositManager.connect(account)["processRequest(address,bool)"](
                    layer2,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to titanLayerAddress.', async () => {
            let layer2 = thanosLayerAddress
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

            const receipt = await (await depositManager.connect(account)["processRequest(address,bool)"](
                layer2,
                true
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'processRequest', '', receipt))

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

    describe('# restore CandidateAddOn : L1BridgeRegistry ', () => {

        it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.not.eq(addr1.address)
            await expect(
                l1BridgeRegistry.connect(addr1).restoreCandidateAddOn(
                    legacySystemConfig.address
                )
            ).to.be.revertedWith("PermissionError")
        })

        it('restore CandidateAddOn (titanCandidateAddOn) : Only rejected layers can be restored.', async () => {
            const {thanosSystemConfig, thanosL2TON } = await getNamedAccounts();

            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
            expect(await l1BridgeRegistry.rejectRollupConfig(thanosSystemConfig)).to.be.eq(false)
            await expect(
                l1BridgeRegistry.connect(seigniorageCommittee).restoreCandidateAddOn(
                    thanosSystemConfig
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
                legacySystemConfig.address
            )).wait()
            logUsedGas.push(gasUsedFunctions('L1BridgeRegistry', 'restoreCandidateAddOn', '', receipt))

            const topic = l1BridgeRegistry.interface.getEventTopic('RestoredCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);
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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)

            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            // console.log('stakedPrev', stakedPrev)
            // console.log('stakedAddr1Prev', stakedAddr1Prev)
            // console.log('stakedAddr2Prev', stakedAddr2Prev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', '', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            // console.log('systemConfig', systemConfig)

            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', '', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
            // console.log('prev totalTvl', totalTvl)
            // console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            // console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            // console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await layerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress, false)
            // console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', '', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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
            let operatorOwner = deployer

            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            // console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            // console.log('operatorContractAddress', operatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(operatorOwner.address)

            const prevUnSettledReward = await seigManager.unSettledReward(layerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, layerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await operatorContract.isOperator(operatorOwner.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            const receipt = await (await layerContract.connect(operatorOwner)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('Layer2Contract', 'updateSeigniorage', 'with operator\'s claim', receipt))

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
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

            let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
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
            let operatorOwner = deployer

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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, layerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await operatorContract.isOperator(operatorOwner.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await layerContract.connect(operatorOwner)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('Layer2Contract', 'updateSeigniorage', 'with operator\'s staking', receipt))

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

            // console.log('stakedOperatorAfter', stakedOperatorAfter)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

            expect(stakedOperatorAfter).to.be.gte(stakedOperatorPrev.add(estimatedDistribute.layer2Seigs))

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : operator afterCall=0 : the fifth updateSeigniorage to titanCandidateAddOn : operator ', async () => {
            let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract
            let operatorContract = titanOperatorContract
            let operatorOwner = deployer

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
            const systemConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
            const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(systemConfig)
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

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            // console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, layerAddress, true)
            // console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 CandidateAddOn를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await operatorContract.isOperator(operatorOwner.address)).to.be.eq(true)
            let afterCall = 0; // 0: none, 1: claim, 2: staking
            const receipt = await (await layerContract.connect(operatorOwner)["updateSeigniorage(uint256)"](afterCall)).wait()
            logUsedGas.push(gasUsedFunctions('Layer2Contract', 'updateSeigniorage', 'with operator\'s staking', receipt))

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

            // console.log('stakedOperatorAfter', stakedOperatorAfter)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

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

            // let afterCall = 0;
            let layer2Balance = prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs)

            expect(afterWtonBalanceOfLayer2Operator).to.be.eq(layer2Balance);

            expect(afterWtonBalanceOfManager).to.be.eq(prevWtonBalanceOfManager)

            expect(afterWtonBalanceOfLayer2Manager).to.be.eq(
                prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
            )
            expect(afterWtonBalanceOfLayer2Operator).to.be.gt(ethers.constants.Zero)

        })

        it('requestWithdrawal to titanLayerAddress', async () => {
             let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract
            let operatorContract = titanOperatorContract
            let operatorOwner = deployer

            let layer2 = titanLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            const beforeBalance = await wtonContract.balanceOf(account.address)

            let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)
            let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
            let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
            let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

            const receipt = await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'requestWithdrawal', '', receipt))

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

            const receipt = await (await depositManager.connect(account)["processRequest(address,bool)"](
                layer2,
                true
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'processRequest', '', receipt))

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

            const receipt = await (await tonContract.connect(account).approveAndCall(
                wtonContract.address,
                tonAmount,
                data,
                {from: account.address}
            )).wait()
            logUsedGas.push(gasUsedFunctions('TonContract', 'approveAndCall', 'DepositManager.onApprove', receipt))


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

            const receipt = await (await depositManager.connect(account)["deposit(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,uint256)', '', receipt))

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

            const receipt = await (await depositManager.connect(pastDepositor)["deposit(address,address,uint256)"](
                layer2Info_2.layer2,
                addr1.address,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'deposit(address,address,uint256)', '', receipt))

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

            let powerTonBalance = await wtonContract.balanceOf(powerTon);
            // console.log('\n updateSeigniorage... ' )

            const receipt = await (await seigManager.connect(pastDepositor).updateSeigniorageLayer(layer2Info_1.layer2)).wait()
            logUsedGas.push(gasUsedFunctions('SeigManager', 'updateSeigniorageLayer', '', receipt))

            const topic = seigManager.interface.getEventTopic('CommitLog1');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            // console.log('\n totalStakedAmount : ',  ethers.utils.formatUnits(deployedEvent.args.totalStakedAmount,27) , 'WTON' )
            // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

            expect(stakedB).to.be.gt(stakedA)
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalance)

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

            const receipt = await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
                layer2Info_1.layer2,
                wtonAmount
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'requestWithdrawal', '', receipt))

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

            const receipt = await (await  depositManager.connect(account)["processRequests(address,uint256,bool)"](
                layer2,
                numPendingRequests,
                false
            )).wait()
            logUsedGas.push(gasUsedFunctions('DepositManager', 'processRequests', '', receipt))

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

    describe('# log', () => {
        it(" used gas",  async () => {
            const workSheetColumnName = [
                "Contract",
                "Name",
                "Tx",
                "Description",
                "GasUsed",
                "GasUsed (ETH) "
            ];
            const gasPrice = 10
            const workSheetName = 'Transactions';
            const filePath = './outputFile/log-used-gas.xlsx';

            exportLogsToExcel(logUsedGas, workSheetColumnName, workSheetName, filePath, gasPrice)

        })
    })
});

