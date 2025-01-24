import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts, deployments} from 'hardhat'

import { mine, time } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import Thanos_Json from '../../abi/SystemConfig.json'
import Proxy_Json from '../../abi/Proxy.json'

describe('Upgrade Thanos sepolia', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer

    before('create fixture loader', async () => {

        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        manager = accounts[1]
        addr1 = accounts[2]
        addr2 = accounts[3]

    })


    describe('# Upgrade Thanos sepolia', () => {
        it('deploy Thanos new logic', async () => {
            const {thanosSepoliaSystemConfig, thanosSepoliaProxyAdmin } = await getNamedAccounts();
            await network.provider.send("hardhat_impersonateAccount", [ thanosSepoliaProxyAdmin]);
            await network.provider.send("hardhat_setBalance", [ thanosSepoliaProxyAdmin, "0x10000000000000000000000000", ]);
            let thanosSepoliaProxyAdminSigner = await ethers.getSigner(thanosSepoliaProxyAdmin);

            const newThanosContract = await (new ethers.ContractFactory(Thanos_Json.abi, Thanos_Json.bytecode)).connect(deployer).deploy()

            console.log(newThanosContract.address)
            const thanosProxy: Contract = (await ethers.getContractAt(Proxy_Json, thanosSepoliaSystemConfig, thanosSepoliaProxyAdminSigner))
            const thanos: Contract = (await ethers.getContractAt(Thanos_Json.abi, thanosSepoliaSystemConfig, deployer))

            let l1CrossDomainMessenger_ = await thanos.l1CrossDomainMessenger()
            let l1ERC721Bridge_ = await thanos.l1ERC721Bridge()
            let l1StandardBridge_ = await thanos.l1StandardBridge()
            let disputeGameFactory_ = await thanos.disputeGameFactory()
            let optimismPortal_ = await thanos.optimismPortal()
            let optimismMintableERC20Factory_ = await thanos.optimismMintableERC20Factory()
            let gasPayingToken_ = await thanos.gasPayingToken()
            let nativeTokenAddress_ = await thanos.nativeTokenAddress()
            let batchInbox_ = await thanos.batchInbox()
            console.log('l1CrossDomainMessenger_', l1CrossDomainMessenger_)
            console.log('l1ERC721Bridge_', l1ERC721Bridge_)
            console.log('l1StandardBridge_', l1StandardBridge_)
            console.log('disputeGameFactory_', disputeGameFactory_)
            console.log('optimismPortal_', optimismPortal_)
            console.log('optimismMintableERC20Factory_', optimismMintableERC20Factory_)
            console.log('gasPayingToken_', gasPayingToken_)
            console.log('nativeTokenAddress_', nativeTokenAddress_)
            console.log('batchInbox_', batchInbox_)

            const callDtata = newThanosContract.interface.encodeFunctionData(
                "initialize(address,uint32,uint32,bytes32,uint64,address,(uint32,uint8,uint8,uint32,uint32,uint128),address,(address,address,address,address,address,address,address,address,address))",
                [   thanosSepoliaProxyAdmin,
                    1368,
                    810949,
                    '0x00000000000000000000000061dc95e5f27266b94805ed23d95b4c9553a3d049',
                    200000000,
                    '0x0Fd5632f3b52458C31A2C3eE1F4b447001872Be9',
                    {
                        maxResourceLimit: 20000000,
                        elasticityMultiplier: 10,
                        baseFeeMaxChangeDenominator: 8,
                        minimumBaseFee: 1000000000,
                        systemTxMaxGas: 1000000,
                        maximumBaseFee: BigNumber.from('340282366920938463463374607431768211455')
                    },
                    batchInbox_,
                    {
                        l1CrossDomainMessenger: l1CrossDomainMessenger_,
                        l1ERC721Bridge: l1ERC721Bridge_,
                        l1StandardBridge: l1StandardBridge_,
                        disputeGameFactory: disputeGameFactory_,
                        optimismPortal: optimismPortal_,
                        optimismMintableERC20Factory: optimismMintableERC20Factory_,
                        gasPayingToken: gasPayingToken_[0],
                        nativeTokenAddress: nativeTokenAddress_,
                        seigniorageReceiver: deployer.address
                    }  ])


            await (await thanosProxy.connect(thanosSepoliaProxyAdminSigner).upgradeToAndCall(
                 newThanosContract.address
                , callDtata)).wait()

            expect(await thanos.l1CrossDomainMessenger()).to.be.eq(l1CrossDomainMessenger_)
            expect(await thanos.l1ERC721Bridge()).to.be.eq(l1ERC721Bridge_)
            expect(await thanos.l1StandardBridge()).to.be.eq(l1StandardBridge_)
            expect(await thanos.disputeGameFactory()).to.be.eq(disputeGameFactory_)
            expect(await thanos.optimismPortal()).to.be.eq(optimismPortal_)
            expect(await thanos.optimismMintableERC20Factory()).to.be.eq(optimismMintableERC20Factory_)
            // expect(await thanos.gasPayingToken()).to.be.eq(gasPayingToken_)
            expect(await thanos.nativeTokenAddress()).to.be.eq(nativeTokenAddress_)
            expect(await thanos.batchInbox()).to.be.eq(batchInbox_)
            expect(await thanos.unsafeBlockSigner()).to.be.eq(deployer.address)

        })
    })
});


