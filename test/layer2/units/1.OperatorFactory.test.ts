import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { BigNumber, Signer } from 'ethers'
// import { l2ProjectLaunchFixtures, l1Fixtures } from './shared/fixtures'
// import { L2ProjectLaunchFixture, L1Fixture } from './shared/fixtureInterfaces'
import { L2RegistryProxy } from "../../../typechain-types/contracts/layer2/L2RegistryProxy"
import { L2RegistryV1_1 } from "../../../typechain-types/contracts/layer2/L2RegistryV1_1"

import { LegacySystemConfig } from "../../../typechain-types/contracts/layer2/LegacySystemConfig"
import { OperatorFactory } from "../../../typechain-types/contracts/layer2/factory/OperatorFactory.sol"
import { OperatorV1_1 } from "../../../typechain-types/contracts/layer2/OperatorV1_1"

describe('OperatorFactory', () => {
    let deployer: Signer, addr1: Signer, addr2: Signer
    let l2RegistryProxy: L2RegistryProxy, l2RegistryV_1: L2RegistryV1_1, l2Registry: L2RegistryV1_1
    let legacySystemConfig: LegacySystemConfig
    let sampleSystemConfig: LegacySystemConfig
    let operatorFactory: OperatorFactory
    let operatorV1_1 : OperatorV1_1

    before('create fixture loader', async () => {
        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        addr1 = accounts[1]
        addr2 = accounts[2]

        // l2RegistryV_1 = (await (await ethers.getContractFactory("L2RegistryV1_1")).connect(deployer).deploy()) as L2RegistryV1_1;
        // l2RegistryProxy = (await (await ethers.getContractFactory("L2RegistryProxy")).connect(deployer).deploy()) as L2RegistryProxy;

        // await (await l2RegistryProxy.connect(deployer).upgradeTo(l2RegistryV_1.address)).wait()

        // l2Registry = (await ethers.getContractAt("L2RegistryV1_1", l2RegistryProxy.address, deployer)) as L2RegistryV1_1

        operatorV1_1 = (await (await ethers.getContractFactory("OperatorV1_1")).connect(deployer).deploy()) as OperatorV1_1;
        operatorFactory = (await (await ethers.getContractFactory("OperatorFactory")).connect(deployer).deploy(operatorV1_1.address)) as OperatorFactory;

    })

    describe('SystemConfig', () => {

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
                name, addresses, l2Ton
            )).wait()
        })
    })

    describe('# createOperator', () => {

        it('createOperator can not be executed by not an SystemConfig\'s owner', async () => {

            expect(await legacySystemConfig.owner()).to.be.not.eq(addr1.address)
            await expect(
                operatorFactory.connect(addr1).createOperator(
                    legacySystemConfig.address
                )
            ).to.be.revertedWith("not config's owner")
        })

        it('createOperator can be executed by SystemConfig\'s owner', async () => {

            expect(await legacySystemConfig.owner()).to.be.eq(deployer.address)

            let operatorAddress = await operatorFactory.getAddress(legacySystemConfig.address)

            let receipt = await (await operatorFactory.connect(deployer).createOperator(
                legacySystemConfig.address
            )).wait()

            const topic = operatorFactory.interface.getEventTopic('CreatedOperator');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = operatorFactory.interface.parseLog(log);

            expect(deployedEvent.args.systemConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.owner).to.be.eq(deployer.address)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)

        })
    })

    describe('# changeOperatorImplementaion ', () => {

        it('changeOperatorImplementaion can not be executed by not owner', async () => {

            expect(await operatorFactory.owner()).to.be.not.eq(addr1.address)
            await expect(
                operatorFactory.connect(addr1).changeOperatorImplementaion(
                    legacySystemConfig.address
                )
            ).to.be.revertedWith("Ownable: caller is not the owner")
        })

        it('changeOperatorImplementaion : zero address is not accepted.', async () => {
            expect(await operatorFactory.owner()).to.be.eq(deployer.address)
            await expect(
                operatorFactory.connect(deployer).changeOperatorImplementaion(
                    ethers.constants.AddressZero
                )
            ).to.be.revertedWith("zero address")
        })

        it('changeOperatorImplementaion  ', async () => {
            expect(await operatorFactory.owner()).to.be.eq(deployer.address)

            let receipt = await (await operatorFactory.connect(deployer).changeOperatorImplementaion(
                sampleSystemConfig.address
            )).wait()

            const topic = operatorFactory.interface.getEventTopic('ChangedOperatorImplementaion');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = operatorFactory.interface.parseLog(log);

            expect(deployedEvent.args.newOperatorImplementation).to.be.eq(sampleSystemConfig.address)
            expect(await operatorFactory.operatorImplementation()).to.be.eq(sampleSystemConfig.address)

        })

        it('cannot be changed with same', async () => {
            await expect(
                operatorFactory.connect(deployer).changeOperatorImplementaion(
                    sampleSystemConfig.address
                )
            ).to.be.revertedWith("same")
        })
    });

});

