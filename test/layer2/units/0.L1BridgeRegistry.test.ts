import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { BigNumber, Signer } from 'ethers'
// import { l2ProjectLaunchFixtures, l1Fixtures } from './shared/fixtures'
// import { L2ProjectLaunchFixture, L1Fixture } from './shared/fixtureInterfaces'

import { L1BridgeRegistryProxy } from "../../../typechain-types/contracts/layer2/L1BridgeRegistryProxy"
import { L1BridgeRegistryV1_1 } from "../../../typechain-types/contracts/layer2/L1BridgeRegistryV1_1.sol"

import { LegacySystemConfig } from "../../../typechain-types/contracts/layer2/LegacySystemConfig"

describe('L1BridgeRegistry', () => {
    let deployer: Signer, manager: Signer, operator: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let sampleSystemConfig: LegacySystemConfig

    before('create fixture loader', async () => {
        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        manager = accounts[1]
        operator = accounts[2]

        l1BridgeRegistryV_1 = (await (await ethers.getContractFactory("L1BridgeRegistryV1_1")).connect(deployer).deploy()) as L1BridgeRegistryV1_1;
        l1BridgeRegistryProxy = (await (await ethers.getContractFactory("L1BridgeRegistryProxy")).connect(deployer).deploy()) as L1BridgeRegistryProxy;

        await (await l1BridgeRegistryProxy.connect(deployer).upgradeTo(l1BridgeRegistryV_1.address)).wait()

        l1BridgeRegistry = (await ethers.getContractAt("L1BridgeRegistryV1_1", l1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryV1_1

    })

    describe('LegacySystemConfig', () => {

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

            await (await legacySystemConfig.connect(deployer).setAddresses(
                name, addresses, l1BridgeRegistryProxy.address
            )).wait()
        })

        it('set Sample LegacySystemConfig ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            sampleSystemConfig = (await (await ethers.getContractFactory("LegacySystemConfig")).connect(deployer).deploy()) as LegacySystemConfig;

            let name = 'Sample'
            let addresses = {
                l1CrossDomainMessenger: l1MessengerAddress,
                l1ERC721Bridge: ethers.constants.AddressZero,
                l1StandardBridge: l1BridgeAddress,
                l2OutputOracle: ethers.constants.AddressZero,
                optimismPortal: ethers.constants.AddressZero,
                optimismMintableERC20Factory: ethers.constants.AddressZero
            }

            await (await sampleSystemConfig.connect(deployer).setAddresses(
                name, addresses, l1BridgeRegistryProxy.address
            )).wait()
        })
    })

    describe('# addManager', () => {

        it('addManager can not be executed by not an admin', async () => {
            await expect(
                l1BridgeRegistryProxy.connect(manager).addManager(manager.address)
                ).to.be.revertedWith("AuthControl: Caller is not an admin")
        })

        it('addManager can be executed by admin', async () => {
            await (await l1BridgeRegistryProxy.connect(deployer).addManager(manager.address)).wait()
            expect(await l1BridgeRegistryProxy.isManager(manager.address)).to.be.eq(true)
        })
    })

    describe('# addRegistrant', () => {

        it('addRegistrant can not be executed by not an manager', async () => {
            await expect(
                l1BridgeRegistryProxy.connect(operator).addRegistrant(operator.address)
                ).to.be.revertedWith("AuthControl: Caller is not a manager")
        })

        it('addRegistrant can be executed by manager', async () => {
            await (await l1BridgeRegistryProxy.connect(manager).addRegistrant(operator.address)).wait()
            expect(await l1BridgeRegistryProxy.isRegistrant(operator.address)).to.be.eq(true)
        })
    })

    describe('# registerRollupConfigByManager', () => {

        it('registerRollupConfigByManager can not be executed by not manager', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 1;

            await expect(
                l1BridgeRegistry.connect(operator).registerRollupConfigByManager(
                    legacySystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("AuthControl: Caller is not a manager")
        })

        it('registerRollupConfigByManager : zero type is not accepted.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 0;
            await expect(
                l1BridgeRegistry.connect(manager).registerRollupConfigByManager(
                    legacySystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("RegisterError")
        })

        it('registerRollupConfigByManager : type over max is not accepted.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 3;
            await expect(
                l1BridgeRegistry.connect(manager).registerRollupConfigByManager(
                    legacySystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("RegisterError")
        })

        it('registerL2RollupConfigByManager  ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 1;

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

            expect(await l1BridgeRegistry.rollupType(legacySystemConfig.address)).to.be.eq(type)

        })

        it('cannot be registered with same rollupConfig ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 2;
            await expect(
                l1BridgeRegistry.connect(manager).registerRollupConfigByManager(
                    legacySystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("RegisterError")
        })
    });

    describe('# changeType', () => {

        it('changeType can not be executed by not registrant', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 0;
            await expect(
                l1BridgeRegistry.connect(deployer).changeType(
                    legacySystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("AuthControl: Caller is not a registrant")
        })

        it('cannot be changed to the same value', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 1;
            await expect(
                l1BridgeRegistry.connect(operator).changeType(
                    legacySystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("ChangeError")
        })

        it('changeType  ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            const sampleSystemConfig1 = (await (await ethers.getContractFactory("LegacySystemConfig")).connect(deployer).deploy()) as LegacySystemConfig;

            let name = 'Sample1'
            let addresses = {
                l1CrossDomainMessenger: l1MessengerAddress,
                l1ERC721Bridge: ethers.constants.AddressZero,
                l1StandardBridge: l1MessengerAddress,
                l2OutputOracle: ethers.constants.AddressZero,
                optimismPortal: l1MessengerAddress,
                optimismMintableERC20Factory: ethers.constants.AddressZero
            }

            await (await sampleSystemConfig1.connect(deployer).setAddresses(
                name, addresses, l1BridgeRegistryProxy.address
            )).wait()

            let type =1

            let receipt = await (await l1BridgeRegistry.connect(manager).registerRollupConfigByManager(
                sampleSystemConfig1.address,
                1,
                l2TonAddress
            )).wait()

            type =2
            receipt = await (await l1BridgeRegistry.connect(operator).changeType(
                sampleSystemConfig1.address,
                2,
                l2TonAddress
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('ChangedType');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(sampleSystemConfig1.address)
            expect(deployedEvent.args.type_).to.be.eq(type)

            expect(await l1BridgeRegistry.rollupType(sampleSystemConfig1.address)).to.be.eq(type)

        })

    });

    describe('# registerL1Config', () => {

        it('registerL1Config can not be executed by not a registrant', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 1;

            await expect(
                l1BridgeRegistry.connect(deployer).registerRollupConfig(
                    legacySystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("AuthControl: Caller is not a registrant")
        })

        it('registerL1Config : zero type is not accepted.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 0;
            await expect(
                l1BridgeRegistry.connect(operator).registerRollupConfig(
                    sampleSystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("RegisterError")
        })

        it('registerL1Config : type over max is not accepted.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 3;
            await expect(
                l1BridgeRegistry.connect(operator).registerRollupConfig(
                    sampleSystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("RegisterError")
        })

        it('registerL1Config :  ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 2;
            await expect(
                l1BridgeRegistry.connect(operator).registerRollupConfig(
                    sampleSystemConfig.address,
                    type,
                    l2TonAddress
                )
            ).to.be.revertedWith("RegisterError")

        })

    });

});

