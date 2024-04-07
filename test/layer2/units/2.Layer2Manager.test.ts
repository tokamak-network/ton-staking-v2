import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import {encodeFunctionSignature} from 'web3-eth-abi'
import { marshalString, unmarshalString } from '../../shared/marshal';

// import { l2ProjectLaunchFixtures, l1Fixtures } from './shared/fixtures'
// import { L2ProjectLaunchFixture, L1Fixture } from './shared/fixtureInterfaces'
import { L2RegistryProxy } from "../../../typechain-types/contracts/layer2/L2RegistryProxy"
import { L2RegistryV1_1 } from "../../../typechain-types/contracts/layer2/L2RegistryV1_1.sol"
import { Layer2ManagerProxy } from "../../../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../../../typechain-types/contracts/layer2/Layer2ManagerV1_1.sol"
import { OperatorFactory } from "../../../typechain-types/contracts/layer2/factory/OperatorFactory.sol"
import { OperatorV1_1 } from "../../../typechain-types/contracts/layer2/OperatorV1_1.sol"
import { DAOCommitteeAddV1_1 } from "../../../typechain-types/contracts/dao/DAOCommitteeAddV1_1.sol"
import { Layer2CandidateFactoryProxy } from "../../../typechain-types/contracts/dao/factory/Layer2CandidateFactoryProxy"
import { Layer2CandidateFactory } from "../../../typechain-types/contracts/dao/factory/Layer2CandidateFactory.sol"

import { Layer2CandidateV1_1 } from "../../../typechain-types/contracts/dao/Layer2CandidateV1_1.sol"
import { LegacySystemConfig } from "../../../typechain-types/contracts/layer2/LegacySystemConfig.sol"
import { SeigManagerV1_3 } from "../../../typechain-types/contracts/stake/managers/SeigManagerV1_3.sol"

import Ton_Json from '../../abi/TON.json'
import Wton_Json from '../../abi/WTON.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'
import DAOCommitteeAddV1_1_Json from '../../abi/DAOCommitteeAddV1_1.json'
import SeigManager_Json from '../../abi/SeigManagerV1.json'
import SeigManagerProxy_Json from '../../abi/SeigManagerProxy.json'

import DepositManager_Json from '../../abi/DepositManager.json'
import DAOCommitteeOwner_Json from '../../abi/DAOCommitteeOwner.json'

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
    let l2RegistryProxy: L2RegistryProxy, l2RegistryV_1: L2RegistryV1_1, l2Registry: L2RegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let legacySystemConfigTest2: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorV1_1:OperatorV1_1 , operatorFactory: OperatorFactory, daoCommitteeAddV1_1: DAOCommitteeAddV1_1

    let layer2CandidateV1_1Imp: Layer2CandidateV1_1
    let layer2CandidateFactoryImp:Layer2CandidateFactory , layer2CandidateFactoryProxy: Layer2CandidateFactoryProxy, layer2CandidateFactory: Layer2CandidateFactory
    let tonContract: Contract, wtonContract: Contract, daoContract: Contract, daoV2Contract: Contract
    let depositManager: Contract, seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3;

    let daoAdmin: Signer;
    let daoOwner: Signer;
    let titanLayerAddress: string;
    let titanOperatorContractAddress: string;
    let titanLayerContract: Layer2CandidateV1_1;
    let titanOperatorContract: OperatorV1_1
    let powerTon: string

    const daoOwnerAddress = "0xb4983da083a5118c903910db4f5a480b1d9f3687"

    before('create fixture loader', async () => {
        const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, powerTonAddress } = await getNamedAccounts();

        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        manager = accounts[1]
        addr1 = accounts[2]
        addr2 = accounts[3]

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
        seigManager = new ethers.Contract(SeigManager,  SeigManager_Json.abi, deployer)
        seigManagerProxy = new ethers.Contract(SeigManager,  SeigManagerProxy_Json.abi, deployer)
        powerTon = powerTonAddress
        // tonContract.connect(daoAdmin).mint(addr1, utils.parseEther("2000"))
        // wtonContract.connect(daoAdmin).mint(addr1, utils.parseEther("2000"))

    })

    describe('# L2Registry', () => {
        it('deploy', async () => {
            l2RegistryV_1 = (await (await ethers.getContractFactory("L2RegistryV1_1")).connect(deployer).deploy()) as L2RegistryV1_1;
            l2RegistryProxy = (await (await ethers.getContractFactory("L2RegistryProxy")).connect(deployer).deploy()) as L2RegistryProxy;

            await (await l2RegistryProxy.connect(deployer).upgradeTo(l2RegistryV_1.address)).wait()

            l2Registry = (await ethers.getContractAt("L2RegistryV1_1", l2RegistryProxy.address, deployer)) as L2RegistryV1_1
        });
    })

    describe('# OperatorFactory', () => {
        it('deploy OperatorV1_1', async () => {
            operatorV1_1 = (await (await ethers.getContractFactory("OperatorV1_1")).connect(deployer).deploy()) as OperatorV1_1;
        });

        it('deploy OperatorFactory ', async () => {
            const {DepositManager, TON, WTON } = await getNamedAccounts();

            operatorFactory = (await (await ethers.getContractFactory("OperatorFactory")).connect(deployer).deploy(operatorV1_1.address)) as OperatorFactory;

            await (await operatorFactory.connect(deployer).setAddresses(
                DepositManager,
                TON,
                WTON)).wait()

        });
    })

    describe('# Layer2CandidateV1_1', () => {
        it('deploy layer2CandidateV1_1Imp', async () => {
            layer2CandidateV1_1Imp = (await (await ethers.getContractFactory("Layer2CandidateV1_1")).connect(deployer).deploy()) as Layer2CandidateV1_1;
        });
    })

    describe('# Layer2CandidateFactoryProxy', () => {
        it('deploy', async () => {
            layer2CandidateFactoryImp = (await (await ethers.getContractFactory("Layer2CandidateFactory")).connect(deployer).deploy()) as Layer2CandidateFactory;
            layer2CandidateFactoryProxy = (await (await ethers.getContractFactory("Layer2CandidateFactoryProxy")).connect(deployer).deploy()) as Layer2CandidateFactoryProxy;

            await (await layer2CandidateFactoryProxy.connect(deployer).upgradeTo(layer2CandidateFactoryImp.address)).wait()

            layer2CandidateFactory = (await ethers.getContractAt("Layer2CandidateFactory", layer2CandidateFactoryProxy.address, deployer)) as Layer2CandidateFactory

            const { DepositManager, DAOCommitteeProxy, TON, WTON} = await getNamedAccounts();

            await (await layer2CandidateFactory.connect(deployer).setAddress(
                DepositManager,
                DAOCommitteeProxy,
                layer2CandidateV1_1Imp.address,
                TON,
                WTON,
                l2RegistryProxy.address
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
            await (await l2RegistryProxy.connect(deployer).addManager(manager.address)).wait()
            expect(await l2RegistryProxy.isManager(manager.address)).to.be.eq(true)
        })
    })

    describe('# setAddresses', () => {

        it('setAddresses can not be executed by not an admin', async () => {
            const {TON, WTON, DAOCommitteeProxy, DepositManager, SeigManager, swapProxy} = await getNamedAccounts();

            expect(await layer2Manager.isAdmin(addr1.address)).to.be.eq(false)

            await expect(
                layer2Manager.connect(addr1).setAddresses(
                    l2RegistryProxy.address,
                    operatorFactory.address,
                    TON, WTON, DAOCommitteeProxy, DepositManager,
                    SeigManager, swapProxy
                )
                ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('setAddresses can be executed by admin', async () => {

            const {TON, WTON, DAOCommitteeProxy, DepositManager, SeigManager, swapProxy} = await getNamedAccounts();
            expect(await layer2Manager.isAdmin(deployer.address)).to.be.eq(true)

            let receipt = await (await layer2Manager.connect(deployer).setAddresses(
                l2RegistryProxy.address,
                operatorFactory.address,
                TON, WTON, DAOCommitteeProxy, DepositManager, SeigManager, swapProxy
            )).wait()

            const topic = layer2Manager.interface.getEventTopic('SetAddresses');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);

            expect(deployedEvent.args._l2Register).to.be.eq(l2RegistryProxy.address)
            expect(deployedEvent.args._operatorFactory).to.be.eq(operatorFactory.address)
            expect(deployedEvent.args._ton).to.be.eq(TON)
            expect(deployedEvent.args._wton).to.be.eq(WTON)
            expect(deployedEvent.args._dao).to.be.eq(DAOCommitteeProxy)
            expect(deployedEvent.args._depositManager).to.be.eq(DepositManager)
            expect(deployedEvent.args._seigManager).to.be.eq(SeigManager)
            expect(deployedEvent.args._swapProxy).to.be.eq(swapProxy)

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
            await (await layer2Manager.connect(deployer).setMinimumInitialDepositAmount(minimumInitialDepositAmount)).wait()
            expect(await layer2Manager.minimumInitialDepositAmount()).to.be.eq(minimumInitialDepositAmount)
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

    describe('# LegacySystemConfig', () => {

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

            await (await legacySystemConfig.connect(deployer).setAddresses(
                name, addresses, l2Ton, l2RegistryProxy.address
            )).wait()
        })

        it('registerSystemConfigByManager  ', async () => {
            let type = 1;

            let receipt = await (await l2Registry.connect(manager).registerSystemConfigByManager(
                legacySystemConfig.address,
                type
            )).wait()

            const topic = l2Registry.interface.getEventTopic('RegisteredSystemConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l2Registry.interface.parseLog(log);

            expect(deployedEvent.args.systemConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.type_).to.be.eq(type)
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

            await (await legacySystemConfigTest2.connect(deployer).setAddresses(
                name, addresses, l2Ton, l2RegistryProxy.address
            )).wait()
        })

        it('registerSystemConfigByManager : Already registered l2Bridge addresses cannot be registered. ', async () => {
            let type = 1;

             await expect(l2Registry.connect(manager).registerSystemConfigByManager(
                legacySystemConfigTest2.address,
                type
            )).to.be.revertedWith("unavailable for registration")
        })
    })

    describe('# checkLayer2TVL', () => {
        it('If the SystemConfig or L1Bridge address does not exist, the result is returned as false.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();
            let systemConfig = l1MessengerAddress

            expect(await layer2Manager.l2Register()).to.be.eq(l2Registry.address)
            expect(await l2Registry.systemConfigType(systemConfig)).to.be.eq(0)

            let check = await layer2Manager.checkLayer2TVL(systemConfig)
            expect(check.result).to.be.eq(false)
            expect(check.amount).to.be.eq(ethers.constants.Zero)
        })

        it('If the SystemConfig or L1Bridge address exist, the result is returned as false.', async () => {

            expect(await layer2Manager.l2Register()).to.be.eq(l2Registry.address)
            expect(await l2Registry.systemConfigType(legacySystemConfig.address)).to.be.eq(1)

            let check = await layer2Manager.checkLayer2TVL(legacySystemConfig.address)
            expect(check.result).to.be.eq(true)
            expect(check.amount).to.be.gt(ethers.constants.Zero)
        })

    })

    describe('# DAO.upgradeTo(DAOCommitteeAddV1_1) , SeigManagerV1_3 ', () => {
        it('deploy DAOCommitteeAddV1_1', async () => {
            daoCommitteeAddV1_1 = (await (await ethers.getContractFactory("DAOCommitteeAddV1_1")).connect(deployer).deploy()) as DAOCommitteeAddV1_1;
        })

        it('deploy SeigManagerV1_3', async () => {
            seigManagerV1_3 = (await (await ethers.getContractFactory("SeigManagerV1_3")).connect(deployer).deploy()) as SeigManagerV1_3;
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
            const selector3 = encodeFunctionSignature("setL2Registry(address)");
            const selector4 = encodeFunctionSignature("updateSeigniorage()");
            const selector5 = encodeFunctionSignature("updateSeigniorageOperator()");
            const selector6 = encodeFunctionSignature("updateSeigniorageLayer()");
            const selector7 = encodeFunctionSignature("allowIssuanceLayer2Seigs()");
            const selector8 = encodeFunctionSignature("totalLayer2TVL()");
            const selector9 = encodeFunctionSignature("layer2RewardInfo(address)");
            const selector10 = encodeFunctionSignature("l2Registry()");
            const selector11 = encodeFunctionSignature("layer2Manager()");
            const selector12 = encodeFunctionSignature("layer2StartBlock()");
            const selector13 = encodeFunctionSignature("l2RewardPerUint()");
            const selector14 = encodeFunctionSignature("unSettledReward(address)");
            const selector15 = encodeFunctionSignature("estimatedDistribute(uint256,address,bool)");

            let functionBytecodes = [
                selector1, selector2, selector3, selector4, selector5,
                selector6, selector7, selector8, selector9, selector10,
                selector11, selector12, selector13, selector14, selector15 ];

            const index = 1;
            await (await daoV2Contract.connect(daoOwner).setTargetSetImplementation2(
                seigManager.address,
                seigManagerV1_3.address,
                index, true)).wait();

            await (await daoV2Contract.connect(daoOwner).setTargetSetSelectorImplementations2(
                seigManager.address,
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
        })

        it('setCandidateFactory to layer2CandidateFactory', async () => {
            await (await daoV2Contract.connect(daoOwner).setLayer2CandidateFactory(layer2CandidateFactory.address)).wait()
        })

        it('setLayer2Manager to layer2Manager', async () => {
            await (await daoV2Contract.connect(daoOwner).setLayer2Manager(layer2Manager.address)).wait()
        })

        it('setTargetSetLayer2Manager to layer2Manager', async () => {
            await (await daoV2Contract.connect(daoOwner).setTargetSetLayer2Manager(seigManager.address, layer2Manager.address)).wait()
        })

        it('setTargetSetL2Registry to l2Register', async () => {
            await (await daoV2Contract.connect(daoOwner).setTargetSetL2Registry(seigManager.address, l2Registry.address)).wait()
        })
    })

    describe('# registerLayer2Candidate ', () => {
        it('Fail if systemConfig is an invalid address', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerLayer2Candidate(
                l2Registry.address,
                amount,
                true,
                'test1'
            )).to.be.rejectedWith("unValidated Layer2")
        })

        it('Failure in case of insufficient ton balance', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerLayer2Candidate(
                legacySystemConfig.address,
                amount,
                true,
                'test1'
            )).to.be.rejectedWith("TRANSFER_FROM_FAILED")
        })

        it('Failure when there is no prior approval of wton', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()
            await expect(layer2Manager.connect(addr1).registerLayer2Candidate(
                legacySystemConfig.address,
                amount.mul(utils.parseEther("1000000000")),
                false,
                'test1'
            )).to.be.rejectedWith("TRANSFER_FROM_FAILED")
        })

        it('Fail if there is no content in memo', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerLayer2Candidate(
                legacySystemConfig.address,
                amount,
                true,
                ''
            )).to.be.rejectedWith("check memo")
        })

        it('registerLayer2Candidate', async () => {
            expect((await layer2Manager.issueStatusLayer2(legacySystemConfig.address))).to.be.eq(0)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(daoAdmin).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfig.name()
            const operatorAddress = await operatorFactory.getAddress(legacySystemConfig.address)

            const receipt = await (await layer2Manager.connect(addr1).registerLayer2Candidate(
                legacySystemConfig.address,
                amount,
                true,
                name
            )).wait()

            const topic = layer2Manager.interface.getEventTopic('RegisteredLayer2Candidate');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);

            expect(deployedEvent.args.systemConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            expect(deployedEvent.args.memo).to.be.eq(name)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            expect(deployedEvent.args.layer2Candidate).to.be.not.eq(ethers.constants.AddressZero)

            titanLayerAddress = deployedEvent.args.layer2Candidate;
            titanOperatorContractAddress = deployedEvent.args.operator;
            expect((await layer2Manager.issueStatusLayer2(legacySystemConfig.address))).to.be.eq(1)

            titanLayerContract =  (await ethers.getContractAt("Layer2CandidateV1_1", titanLayerAddress, deployer)) as Layer2CandidateV1_1
            titanOperatorContract = (await ethers.getContractAt("OperatorV1_1", titanOperatorContractAddress, deployer)) as OperatorV1_1
        })

        it('If the layer has already been created, it will fail.', async () => {

            expect((await layer2Manager.issueStatusLayer2(legacySystemConfig.address))).to.be.eq(1)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(daoAdmin).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfig.name()

            await expect(layer2Manager.connect(addr1).registerLayer2Candidate(
                legacySystemConfig.address,
                amount,
                true,
                name
            ) ).to.be.revertedWith("already registered");
        })

        it('Layers that are not registered in the L2Registry cannot be registered.', async () => {
            expect((await layer2Manager.issueStatusLayer2(legacySystemConfigTest2.address))).to.be.eq(0)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(daoAdmin).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfigTest2.name()

            await expect(layer2Manager.connect(addr1).registerLayer2Candidate(
                legacySystemConfigTest2.address,
                amount,
                true,
                name
            ) ).to.be.revertedWith("unValidated Layer2");

        });

    })

    describe('# L2Register', () => {

        describe('# setAddresses', () => {
            it('setAddresses : onlyOwner ', async () => {
                const {TON} = await getNamedAccounts();

                await expect(
                    l2Registry.connect(addr1).setAddresses(
                        layer2Manager.address,
                        seigManager.address,
                        TON
                    )
                ).to.be.revertedWith("AuthControl: Caller is not an admin")
            })

            it('setAddresses : onlyOwner ', async () => {
                const {TON} = await getNamedAccounts();

                await (await l2Registry.connect(deployer).setAddresses(
                        layer2Manager.address,
                        seigManager.address,
                        TON
                )).wait()

                expect(await l2Registry.layer2Manager()).to.be.eq(layer2Manager.address)
            })
        })

    })

    describe('# SeigManagerV1_3', () => {
        it('SeigManagerV1_3 : setLayer2StartBlock', async () => {
            let block1 = await ethers.provider.getBlock('latest');
            await (await daoV2Contract.connect(daoOwner).setTargetLayer2StartBlock(seigManager.address, block1.number + 1))
        });
    });


    describe('# DepositManager : Layer2Candidate ', () => {

        // titanLayerAddress = deployedEvent.args.layer2Candidate;
        // titanOperatorContractAddress = deployedEvent.args.operator;

        it('deposit to titanLayerAddress using approveAndCall', async () => {

            let account = addr1
            let amount = ethers.utils.parseEther("2000")
            await (await tonContract.connect(daoAdmin).mint(addr1.address, amount))

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

            let account = addr2

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

            let account = addr1
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
            console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = layer2Manager.systemConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l2Registry.layer2TVL(systemConfig)
            console.log('prev totalTvl', totalTvl)
            console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

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
            console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            console.log(deployedEvent1.args)
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

            console.log('afterTotalTvl', afterTotalTvl)
            console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)


            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer : second updateSeigniorage to titanLayerAddress : not operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = layer2Manager.systemConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l2Registry.layer2TVL(systemConfig)
            console.log('prev totalTvl', totalTvl)
            console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            console.log('curLayer2Tvl', curLayer2Tvl)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress, false)
            console.log('estimatedDistribute', estimatedDistribute)

            const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

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
            console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            console.log(deployedEvent1.args)

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

            console.log('afterTotalTvl', afterTotalTvl)
            console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)


            let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
            console.log('layer2RewardInfo', layer2RewardInfo)
            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)
            expect(afterWtonBalanceOfLayer2Manager).to.be.gt(ethers.constants.Zero)

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });


        it('Layer2Contract: updateSeigniorage : operator claim:  third updateSeigniorage to titanLayerAddress : operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = layer2Manager.systemConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l2Registry.layer2TVL(systemConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            console.log('prev totalTvl', totalTvl)
            console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            console.log('curLayer2Tvl', curLayer2Tvl)
            console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 Layer2Candidate를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(deployer.address)).to.be.eq(true)
            let afterCall = 1; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(deployer)["updateSeigniorage(uint256)"](afterCall)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

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
            console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            console.log(deployedEvent1.args)

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
            console.log('layer2RewardInfo', layer2RewardInfo)

            console.log('afterTotalTvl', afterTotalTvl)
            console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

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

        it('Layer2Contract: updateSeigniorage : operator staking :  forth updateSeigniorage to titanLayerAddress : operator ', async () => {
            // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
            let lastSeigBlock =  await seigManager.lastSeigBlock();
            console.log('\nlastSeigBlock', lastSeigBlock)
            let block1 = await ethers.provider.getBlock('latest');
            // console.log('\nblock number :', block1.number);
            let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

            console.log('titanOperatorContractAddress', titanOperatorContractAddress)
            const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
            const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
            const prevWtonBalanceOfManager = await wtonContract.balanceOf(deployer.address)
            const prevUnSettledReward = await seigManager.unSettledReward(titanLayerAddress)
            expect(prevWtonBalanceOfLayer2Manager).to.be.gte(prevUnSettledReward)

            const totalTvl = await seigManager.totalLayer2TVL()
            const systemConfig = layer2Manager.systemConfigOfOperator(titanOperatorContractAddress)
            const curLayer2Tvl = await l2Registry.layer2TVL(systemConfig)
            const l2RewardPerUint = await seigManager.l2RewardPerUint()

            console.log('prev totalTvl', totalTvl)
            console.log('prevWtonBalanceOfLayer2Manager', prevWtonBalanceOfLayer2Manager)
            console.log('prevWtonBalanceOfLayer2Operator', prevWtonBalanceOfLayer2Operator)
            console.log('curLayer2Tvl', curLayer2Tvl)
            console.log('l2RewardPerUint', l2RewardPerUint)
            expect(l2RewardPerUint).to.be.gt(ethers.constants.Zero)

            let stakedPrev = await titanLayerContract.totalStaked()
            let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let stakedOperatorPrev = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)

            let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);
            console.log('stakedOperatorPrev', stakedOperatorPrev)

            let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1, titanLayerAddress, true)
            console.log('estimatedDistribute', estimatedDistribute)

            // operator 가 직접 정산을 하려면 반드시 Layer2Candidate를 통해 업데이트 시뇨리지를 실행해야 한다.
            expect(await titanOperatorContract.isOperator(deployer.address)).to.be.eq(true)
            let afterCall = 2; // 0: none, 1: claim, 2: staking
            const receipt = await (await titanLayerContract.connect(deployer)["updateSeigniorage(uint256)"](afterCall)).wait()

            const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
            expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
            expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

            console.log('\n prevTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.prevTotalSupply,27) , 'WTON' )
            console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

            let stakedAfter = await titanLayerContract.totalStaked()
            let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
            let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
            let stakedOperatorAfter = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)

            // expect(stakedPrev).to.be.eq(deployedEvent.args.prevTotalSupply)
            // expect(stakedAfter).to.be.gt(deployedEvent.args.nextTotalSupply)
            console.log('stakedOperatorAfter', stakedOperatorAfter)

            expect(stakedAfter).to.be.gt(stakedPrev)
            expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
            expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
            expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)

            let block2 = await ethers.provider.getBlock('latest');

            // console.log('\nblock number :', block2.number);
            let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
            console.log( ' totalSupplyOfTon (after)    ', ethers.utils.formatUnits(totalSupplyOfTon_after,27) , 'WTON')

            console.log('\ntotalSupplyOfTon_after.sub(totalSupplyOfTon)     :', ethers.utils.formatUnits(totalSupplyOfTon_after.sub(totalSupplyOfTon),27) , 'WTON')

            let seigPerBlock =  await seigManager.seigPerBlock();
            // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

            expect(
                totalSupplyOfTon_after.sub(totalSupplyOfTon)
            ).to.be.eq(seigPerBlock)

            //=============================
            const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
            const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
            const deployedEvent1 = seigManager.interface.parseLog(log1);
            console.log(deployedEvent1.args)

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
            console.log('layer2RewardInfo', layer2RewardInfo)

            console.log('afterTotalTvl', afterTotalTvl)
            console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
            console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

            expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

            // let afterCall = 2; staking mode

            let stakedAmount = prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs)
            console.log('stakedAmount', stakedAmount)

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
        it('deposit to level using approveAndCall', async () => {
        })
    })

    // requestWithdrawAndDeposit Of LayerCandidate
    describe('# DepositManager : DAOCandidate ', () => {
        it('deposit to level using approveAndCall', async () => {
        })
    })

});

