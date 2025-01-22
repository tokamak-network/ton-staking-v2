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
import Thanos_Json from '../../abi/SystemConfig.json'
import Proxy_Json from '../../abi/Proxy.json'

const layers = [
    {"oldLayer":"","newLayer":"0xaeb0463a2fd96c68369c1347ce72997406ed6409","operator":"0xd4335a175c36c0922f6a368b83f9f6671bf07606","name":"candidate"},
    {"oldLayer":"","newLayer":"0xabd15c021942ca54abd944c91705fe70fea13f0d","operator":"0x757de9c340c556b56f62efae859da5e08baae7a2","name":"member_DAO"},
]

let pastAddr = "0xD4335A175c36c0922F6A368b83f9F6671bf07606"
let wtonhaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
let tonHaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

const daoOwnerAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinterAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinter: Signer
let seigniorageCommitteeAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let seigniorageCommittee: Signer
let titanManager: Signer

let ownerAddressInfo =  {
    L2BridgeRegistry: {
        owner: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
        manager: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
    },
    Layer2Manager: {
        owner: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    },
    OperatorManagerFactory: {
        owner: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    },
    Titan : {
        MultiProposerableTransactionExecutor: "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
    },
    Thanos : {
        MultiProposerableTransactionExecutor: "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
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

describe('Upgrade Thanos sepolia', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1
    let l1BridgeRegistryOld: L1BridgeRegistryV1_1


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
    let tonMinter: Signer;

    let titanLayerAddress: string, titanOperatorContractAddress: string;
    let titanLayerContract: CandidateAddOnV1_1;
    let titanOperatorContract: OperatorManagerV1_1

    let thanosLayerAddress: string, thanosOperatorContractAddress: string;
    let thanosLayerContract: CandidateAddOnV1_1;
    let thanosOperatorContract: OperatorManagerV1_1

    let pastDepositor:Signer, wtonHave:Signer, tonHave:Signer
    let layer2Info_1 : any;
    let layer2Info_2 : any;

    let daoAgendaManagerContract: Contract
    let daoCommitteeProxy2Contract: DAOCommitteeProxy2
    let daoCommittee_V1: DAOCommittee_V1
    let daoCommitteeOwner: DAOCommitteeOwner
    let daoCommitteeContract:  Contract
    let agendaId: BigNumber

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


        await hre.network.provider.send("hardhat_impersonateAccount", [
            DAOCommitteeProxy,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            DAOCommitteeProxy,
            "0x10000000000000000000000000",
        ]);

        tonMinter = daoOwner
    })

    describe('# Tester', () => {
        it('mint ton', async () => {

            await (await tonContract.connect(tonMinter).mint(addr1.address, ethers.utils.parseEther("10000"))).wait()
            await (await tonContract.connect(tonMinter).mint(addr2.address, ethers.utils.parseEther("10000"))).wait()
            await (await tonContract.connect(tonMinter).mint(tonHave.address, ethers.utils.parseEther("10000"))).wait()
            await (await tonContract.connect(tonMinter).mint(pastAddr, ethers.utils.parseEther("10000"))).wait()
            await (await wtonContract.connect(tonMinter).mint(wtonHave.address, ethers.utils.parseEther("10000000000000"))).wait()

        })
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
            expect(await thanos.seigniorageReceiver()).to.be.eq(deployer.address)

        })
    })
});


