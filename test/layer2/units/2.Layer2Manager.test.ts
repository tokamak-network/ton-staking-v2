import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { BigNumber, Signer } from 'ethers'
// import { l2ProjectLaunchFixtures, l1Fixtures } from './shared/fixtures'
// import { L2ProjectLaunchFixture, L1Fixture } from './shared/fixtureInterfaces'
import { L2RegistryProxy } from "../../../typechain-types/contracts/layer2/L2RegistryProxy"
import { L2RegistryV1_1 } from "../../../typechain-types/contracts/layer2/L2RegistryV1_1"
import { Layer2ManagerProxy } from "../../../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../../../typechain-types/contracts/layer2/Layer2ManagerV1_1.sol"

import { LegacySystemConfig } from "../../../typechain-types/contracts/layer2/LegacySystemConfig"

describe('Layer2Manager', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer
    let l2RegistryProxy: L2RegistryProxy, l2RegistryV_1: L2RegistryV1_1, l2Registry: L2RegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1

    before('create fixture loader', async () => {
        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        manager = accounts[1]
        addr1 = accounts[2]

    })

    describe('# L2Registry', () => {
        it('deploy', async () => {
            l2RegistryV_1 = (await (await ethers.getContractFactory("L2RegistryV1_1")).connect(deployer).deploy()) as L2RegistryV1_1;
            l2RegistryProxy = (await (await ethers.getContractFactory("L2RegistryProxy")).connect(deployer).deploy()) as L2RegistryProxy;

            await (await l2RegistryProxy.connect(deployer).upgradeTo(l2RegistryV_1.address)).wait()

            l2Registry = (await ethers.getContractAt("L2RegistryV1_1", l2RegistryProxy.address, deployer)) as L2RegistryV1_1
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
            const {TON, WTON, DAOCommitteeProxy, DepositManager, swapProxy} = await getNamedAccounts();

            expect(await layer2Manager.isAdmin(addr1.address)).to.be.eq(false)

            await expect(
                layer2Manager.connect(addr1).setAddresses(
                    l2RegistryProxy.address,
                    ethers.constants.AddressZero,
                    TON, WTON, DAOCommitteeProxy, DepositManager, swapProxy
                )
                ).to.be.revertedWith("Accessible: Caller is not an admin")
        })

        it('setAddresses can be executed by admin', async () => {

            const {TON, WTON, DAOCommitteeProxy, DepositManager, swapProxy} = await getNamedAccounts();
            expect(await layer2Manager.isAdmin(deployer.address)).to.be.eq(true)

            let receipt = await (await layer2Manager.connect(deployer).setAddresses(
                l2RegistryProxy.address,
                ethers.constants.AddressZero,
                TON, WTON, DAOCommitteeProxy, DepositManager, swapProxy
            )).wait()

            const topic = layer2Manager.interface.getEventTopic('SetAddresses');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);

            expect(deployedEvent.args._l2RegistryForVerify).to.be.eq(l2RegistryProxy.address)
            expect(deployedEvent.args._operatorFactory).to.be.eq(ethers.constants.AddressZero)
            expect(deployedEvent.args._ton).to.be.eq(TON)
            expect(deployedEvent.args._wton).to.be.eq(WTON)
            expect(deployedEvent.args._dao).to.be.eq(DAOCommitteeProxy)
            expect(deployedEvent.args._depositManager).to.be.eq(DepositManager)
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
                name, addresses, l2Ton
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

    describe('# checkLayer2TVL', () => {
        it('If the SystemConfig or L1Bridge address does not exist, the result is returned as false.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();
            let systemConfig = l1MessengerAddress

            expect(await layer2Manager.l2RegistryForVerify()).to.be.eq(l2Registry.address)
            expect(await l2Registry.systemConfigType(systemConfig)).to.be.eq(0)

            let check = await layer2Manager.checkLayer2TVL(systemConfig)
            expect(check.result).to.be.eq(false)
            expect(check.amount).to.be.eq(ethers.constants.Zero)
        })

        it('If the SystemConfig or L1Bridge address exist, the result is returned as false.', async () => {

            expect(await layer2Manager.l2RegistryForVerify()).to.be.eq(l2Registry.address)
            expect(await l2Registry.systemConfigType(legacySystemConfig.address)).to.be.eq(1)

            let check = await layer2Manager.checkLayer2TVL(legacySystemConfig.address)
            expect(check.result).to.be.eq(true)
            expect(check.amount).to.be.gt(ethers.constants.Zero)
        })


    })


});

