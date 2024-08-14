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
            let l2Ton = l2TonAddress

            await (await legacySystemConfig.connect(deployer).setAddresses(
                name, addresses, l2Ton, l1BridgeRegistryProxy.address
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
            let l2Ton = l2TonAddress

            await (await sampleSystemConfig.connect(deployer).setAddresses(
                name, addresses, l2Ton,  l1BridgeRegistryProxy.address
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

    describe('# addOperator', () => {

        it('addOperator can not be executed by not an admin', async () => {
            await expect(
                l1BridgeRegistryProxy.connect(operator).addRegistrant(operator.address)
                ).to.be.revertedWith("AuthControl: Caller is not an admin")
        })

        it('addOperator can be executed by admin', async () => {
            await (await l1BridgeRegistryProxy.connect(deployer).addRegistrant(operator.address)).wait()
            expect(await l1BridgeRegistryProxy.isRegistrant(operator.address)).to.be.eq(true)
        })
    })

    describe('# registerSystemConfigByManager', () => {

        it('registerSystemConfigByManager can not be executed by not manager', async () => {

            let type = 1;

            await expect(
                l1BridgeRegistry.connect(operator).registerSystemConfigByManager(
                    legacySystemConfig.address,
                    type
                )
            ).to.be.revertedWith("AuthControl: Caller is not a manager")
        })

        it('registerSystemConfigByManager : zero type is not accepted.', async () => {
            let type = 0;
            await expect(
                l1BridgeRegistry.connect(manager).registerSystemConfigByManager(
                    legacySystemConfig.address,
                    type
                )
            ).to.be.revertedWith("zero type")
        })

        it('registerSystemConfigByManager : type over max is not accepted.', async () => {
            let type = 3;
            await expect(
                l1BridgeRegistry.connect(manager).registerSystemConfigByManager(
                    legacySystemConfig.address,
                    type
                )
            ).to.be.revertedWith("unsupported type")
        })

        it('registerSystemConfigByManager  ', async () => {
            let type = 1;

            let receipt = await (await l1BridgeRegistry.connect(manager).registerSystemConfigByManager(
                legacySystemConfig.address,
                type
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('RegisteredSystemConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.systemConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.type_).to.be.eq(type)

            expect(await l1BridgeRegistry.systemConfigType(legacySystemConfig.address)).to.be.eq(type)

        })

        it('cannot be registered with same systemConfig ', async () => {
            let type = 2;
            await expect(
                l1BridgeRegistry.connect(manager).registerSystemConfigByManager(
                    legacySystemConfig.address,
                    type
                )
            ).to.be.revertedWith("already registered")
        })
    });

    describe('# changeType', () => {

        it('changeType can not be executed by not registrant', async () => {

            let type = 0;
            await expect(
                l1BridgeRegistry.connect(deployer).changeType(
                    legacySystemConfig.address,
                    type
                )
            ).to.be.revertedWith("AuthControl: Caller is not a registrant")
        })

        it('cannot be changed to the same value', async () => {

            let type = 1;
            await expect(
                l1BridgeRegistry.connect(operator).changeType(
                    legacySystemConfig.address,
                    type
                )
            ).to.be.revertedWith("same type")
        })

        it('changeType  ', async () => {
            let type = 2;
            let receipt = await (await l1BridgeRegistry.connect(operator).changeType(
                legacySystemConfig.address,
                type
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('ChangedType');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.systemConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.type_).to.be.eq(type)

            expect(await l1BridgeRegistry.systemConfigType(legacySystemConfig.address)).to.be.eq(type)

        })

    });

    describe('# registerSystemConfig', () => {

        it('registerSystemConfig can not be executed by not a registrant', async () => {

            let type = 1;

            await expect(
                l1BridgeRegistry.connect(deployer).registerSystemConfig(
                    legacySystemConfig.address,
                    type
                )
            ).to.be.revertedWith("AuthControl: Caller is not a registrant")
        })

        it('registerSystemConfig : zero type is not accepted.', async () => {
            let type = 0;
            await expect(
                l1BridgeRegistry.connect(operator).registerSystemConfig(
                    sampleSystemConfig.address,
                    type
                )
            ).to.be.revertedWith("zero type")
        })

        it('registerSystemConfig : type over max is not accepted.', async () => {
            let type = 3;
            await expect(
                l1BridgeRegistry.connect(operator).registerSystemConfig(
                    sampleSystemConfig.address,
                    type
                )
            ).to.be.revertedWith("unsupported type")
        })

        it('registerSystemConfig :  ', async () => {

            let type = 2;
            await expect(
                l1BridgeRegistry.connect(operator).registerSystemConfig(
                    sampleSystemConfig.address,
                    type
                )
            ).to.be.revertedWith("unavailable for registration")

        })

    });

});

