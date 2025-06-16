import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { mine, time } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import {encodeFunctionSignature, encodeParameters} from 'web3-eth-abi'
import { marshalString, unmarshalString } from '../../shared/marshal';

import { L1BridgeRegistryProxy } from "../../../typechain-types/contracts/layer2/L1BridgeRegistryProxy"
import { L1BridgeRegistryV1_1 } from "../../../typechain-types/contracts/layer2/L1BridgeRegistryV1_1"

import { Layer2ManagerProxy } from "../../../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../../../typechain-types/contracts/layer2/Layer2ManagerV1_1"
import { OperatorManagerFactory } from "../../../typechain-types/contracts/layer2/factory/OperatorManagerFactory.sol"
import { OperatorManagerV1_1 } from "../../../typechain-types/contracts/layer2/OperatorManagerV1_1"
import { DAOCommittee_V1 } from "../../../typechain-types/contracts/dao/DAOCommittee_V1"
import { DAOCommittee_V2 } from "../../../typechain-types/contracts/dao/DAOCommittee_V2"

import { DAOCommitteeOwner } from "../../../typechain-types/contracts/dao/DAOCommitteeOwner"
import { DAOCommitteeProxy2 } from "../../../typechain-types/contracts/proxy/DAOCommitteeProxy2"

import { CandidateAddOnFactoryProxy } from "../../../typechain-types/contracts/dao/factory/CandidateAddOnFactoryProxy"
import { CandidateAddOnFactory } from "../../../typechain-types/contracts/dao/factory/CandidateAddOnFactory"

import { CandidateAddOnV1_1 } from "../../../typechain-types/contracts/dao/CandidateAddOnV1_1"
import { LegacySystemConfig } from "../../../typechain-types/contracts/layer2/LegacySystemConfig"
import { SeigManagerV1_3 } from "../../../typechain-types/contracts/stake/managers/SeigManagerV1_3"
import { SeigManagerV1_2 } from "../../../typechain-types/contracts/stake/managers/SeigManagerV1_2"

import { DepositManagerV1_1 } from "../../../typechain-types/contracts/stake/managers/DepositManagerV1_1"

import { MockSystemConfigFactory } from "../../../typechain-types/contracts/mocks/MockSystemConfigFactory.sol"
import { MockSystemConfig } from "../../../typechain-types/contracts/mocks/MockSystemConfig.sol"
import { InvalidCandidateAddOn } from "../../../typechain-types/contracts/mocks/InvalidCandidateAddOn"


import Ton_Json from '../../abi/TON.json'
import Wton_Json from '../../abi/WTON.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'
import DAOCommitteeProxy2_Json from '../../abi/DAOCommitteeProxy2.json'
import DAOCommittee_V1_Json from '../../abi/DAOCommittee_V1.json'
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

let thanosSystemConfig: any
let thanosSystemConfigContract: MockSystemConfig

let pastAddr = "0x3bFda92Fa3bC0AB080Cac3775147B6318b1C5115"
let wtonhaveAddr = "0x735985022e5EF7BeFA272986FdFB7dE6aC675ed8"
let tonHaveAddr = "0x7897ccD146b97639c0Dd99A17383e0b11681996E"

const daoOwnerAddress = "0xB4983DA083A5118C903910DB4f5a480B1D9f3687"
let tonMinterAddress = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
let tonMinter: Signer
let seigniorageCommitteeAddress = "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
let seigniorageCommittee: Signer

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

describe('TON Staking V2', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let legacySystemConfigTest2: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorManagerV1_1:OperatorManagerV1_1 , operatorManagerFactory: OperatorManagerFactory
    let daoCommitteeAddV1_1: DAOCommittee_V1

    let candidateAddOnV1_1Imp: CandidateAddOnV1_1
    let candidateAddOnFactoryImp:CandidateAddOnFactory , candidateAddOnFactoryProxy: CandidateAddOnFactoryProxy, candidateAddOnFactory: CandidateAddOnFactory
    let tonContract: Contract, wtonContract: Contract
    let daoContract: Contract, daoV2Contract: Contract,  daoCommitteeProxy2: DAOCommitteeProxy2
    let daoV2ContractOwner: Contract, daoV2ContractCommittee: Contract;
    let patchedCandidateAddOnFactory: CandidateAddOnFactory
    let daoCommittee_V2: DAOCommittee_V2

    let depositManager: Contract,  depositManagerProxy: Contract, seigManager: Contract, seigManagerProxy: Contract;

    let seigManagerV1_3: SeigManagerV1_3, seigManagerV1_2: SeigManagerV1_2;
    let depositManagerV1_1: DepositManagerV1_1;

    let daoAdmin: Signer;
    let daoOwner: Signer;

    let titanLayerAddress: string, titanOperatorContractAddress: string;
    let titanLayerContract: CandidateAddOnV1_1;
    let titanOperatorContract: OperatorManagerV1_1

    let thanosLayerAddress: string, thanosOperatorContractAddress: string;
    let thanosLayerContract: CandidateAddOnV1_1;
    let thanosOperatorContract: OperatorManagerV1_1


    let mockSystemConfigFactory: MockSystemConfigFactory
    let mockSystemConfig: MockSystemConfig
    let mockCandidateAddress: string, mockOperatorContractAddress: string;
    let mockCandidateCotract: CandidateAddOnV1_1
    let mockOperatorContract: OperatorManagerV1_1


    let powerTon: string
    let pastDepositor:Signer, wtonHave:Signer, tonHave:Signer
    let layer2Info_1 : any;
    let layer2Info_2 : any;
    let daoAgendaManagerContract: Contract
    let daoCommitteeProxy2Contract: DAOCommitteeProxy2
    let daoCommittee_V1: DAOCommittee_V1
    let daoCommitteeOwner: DAOCommitteeOwner
    let daoCommitteeContract:  Contract
    let agendaId: BigNumber

    let titanLayerSeigs: Array<string>;
    let thanosLayerSeigs: Array<string>;


    const daoOwnerAddress = "0xb4983da083a5118c903910db4f5a480b1d9f3687"

    /// Layer2Manager 주소가 address(0)이거나, layer2StartBlock == 1 일때, L2 시뇨리지 발행되지 않습니다.
    /// layer1 업데이트 시뇨리지 테스트입니다.
    async function updateSeigniorageLayer_Layer2Manager_ZeroAddress() {

        /// l2TotalSeigs, layer2Seigs 가 모두 0 이어야 한다.

        let claimableL2SeigniorageTitan = await seigManager.claimableL2Seigniorage(titanLayerAddress);
        // console.log('claimableL2SeigniorageTitan', claimableL2SeigniorageTitan)
        let claimableL2SeigniorageThanos = null;

        const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)

        const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
        const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)

        let lastSeigBlock =  await seigManager.lastSeigBlock();
        let block1 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block1.number);
        let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()
        // console.log( ' totalSupplyOfTon (before)   ', ethers.utils.formatUnits(totalSupplyOfTon,27) , 'WTON')

        let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

        // let powerTonBalance = await wtonContract.balanceOf(powerTon);

        let layer2RewardInfoTitanPrev = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        const totalTvl = await seigManager.totalLayer2TVL()

        // console.log('\n updateSeigniorage... ' )
        const receipt = await (await seigManager.connect(pastDepositor).updateSeigniorageLayer(layer2Info_1.layer2)).wait()

        const topic = seigManager.interface.getEventTopic('CommitLog1');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);

        let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

        expect(stakedB).to.be.gt(stakedA)
        // expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalance)

        let block2 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block2.number);
        let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()

        let seigPerBlock =  await seigManager.seigPerBlock();
        // console.log('\nseigPerBlock ', ethers.utils.formatUnits(seigPerBlock,27) , 'WTON')

        expect(
            totalSupplyOfTon_after.sub(totalSupplyOfTon)
        ).to.be.eq(seigPerBlock)

        let totalSupplyOfTon_2 = await seigManager["totalSupplyOfTon_2()"]()
        // console.log( ' totalSupplyOfTon_2    ', ethers.utils.formatUnits(totalSupplyOfTon_2,27) , 'WTON')
        expect(totalSupplyOfTon_2).to.be.gt(ethers.constants.Zero)

        //=============================
        const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
        const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
        const deployedEvent1 = seigManager.interface.parseLog(log1);
        expect(deployedEvent1.args.l2TotalSeigs).to.be.eq(ethers.constants.Zero);
        expect(deployedEvent1.args.layer2Seigs).to.be.eq(ethers.constants.Zero);

        const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const afterTotalTvl = await seigManager.totalLayer2TVL()

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            .sub(deployedEvent1.args.layer2Seigs)
        )

        expect(afterWtonBalanceOfLayer2Operator).to.be.eq(
            prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs))

        if(claimableL2SeigniorageThanos == null) {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan)

        } else {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan.add(claimableL2SeigniorageThanos))
        }

    }

    /// Layer2Manager 주소가 address(0)이거나, layer2StartBlock == 1 일때, L2 시뇨리지 발행되지 않습니다.
    /// Layer2Manager 주소가 Titan 의 업데이트 시뇨리지 테스트입니다.
    async function updateSeigniorageTitan_Layer2Manager_ZeroAddress() {

        /// l2TotalSeigs, layer2Seigs 가 모두 0 이어야 한다.

        //------------------
        let lastSeigBlock =  await seigManager.lastSeigBlock();
        // console.log('\nlastSeigBlock', lastSeigBlock)
        let block1 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block1.number);
        let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

        let claimableL2SeigniorageTitan = await seigManager.claimableL2Seigniorage(titanLayerAddress);
        // console.log('claimableL2SeigniorageTitan', claimableL2SeigniorageTitan)
        let claimableL2SeigniorageThanos = null
        if(thanosLayerAddress != null)
            claimableL2SeigniorageThanos = await seigManager.claimableL2Seigniorage(thanosLayerAddress);
        // console.log('claimableL2SeigniorageThanos', claimableL2SeigniorageThanos)


        const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const totalTvl = await seigManager.totalLayer2TVL()
        const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)

        const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)


        let stakedPrev = await titanLayerContract.totalStaked()
        let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
        let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
        // let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

        let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress)
        // console.log('estimatedDistribute', estimatedDistribute)

        const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

        const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
        expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
        expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

        let stakedAfter = await titanLayerContract.totalStaked()
        let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
        let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

        expect(stakedAfter).to.be.gt(stakedPrev)
        expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
        expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
        // expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


        let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()

        let seigPerBlock =  await seigManager.seigPerBlock();

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
        // expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
        expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
        expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
        expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
        expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

        expect(estimatedDistribute.l2TotalSeigs).to.be.eq(ethers.constants.Zero)
        expect(estimatedDistribute.layer2Seigs).to.be.eq(ethers.constants.Zero)

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
        )

        const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const afterTotalTvl = await seigManager.totalLayer2TVL()

        let layer2RewardInfo = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        // console.log('layer2RewardInfo', layer2RewardInfo)
        expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);
        expect(claimableL2SeigniorageTitan).to.be.eq(deployedEvent1.args.layer2Seigs)


        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            .sub(deployedEvent1.args.layer2Seigs)
        )

        expect(afterWtonBalanceOfLayer2Operator).to.be.eq(
            prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs))

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(estimatedDistribute.layer2Seigs)

        if(claimableL2SeigniorageThanos == null) {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan)

        } else {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan.add(claimableL2SeigniorageThanos))
        }

    }

    /// Layer2Manager 주소가 address(0)이거나, layer2StartBlock == 1 일때, L2 시뇨리지 발행되지 않습니다.
    /// Thanos 의 업데이트 시뇨리지 테스트입니다.
    async function updateSeigniorageThanos_Layer2Manager_ZeroAddress() {

        /// l2TotalSeigs, layer2Seigs 가 모두 0 이어야 한다.

        let layerAddress = thanosLayerAddress
        let operatorContractAddress = thanosOperatorContractAddress
        let layerContract = thanosLayerContract

        // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
        let lastSeigBlock =  await seigManager.lastSeigBlock();
        // console.log('\nlastSeigBlock', lastSeigBlock)
        let block1 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block1.number);
        let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

        let claimableL2SeigniorageTitan = await seigManager.claimableL2Seigniorage(titanLayerAddress);
        // console.log('claimableL2SeigniorageTitan', claimableL2SeigniorageTitan)

        let claimableL2SeigniorageThanos= await seigManager.claimableL2Seigniorage(thanosLayerAddress);
        // console.log('claimableL2SeigniorageThanos', claimableL2SeigniorageThanos)

        const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
        const totalTvl = await seigManager.totalLayer2TVL()
        const rollupConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
        const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)

        let stakedPrev = await layerContract.totalStaked()
        let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
        let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
        // let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

        let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress)
        // console.log('estimatedDistribute', estimatedDistribute)

        const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()

        const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        expect(deployedEvent.args.layer2).to.be.eq(layerAddress)
        expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
        expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)


        let stakedAfter = await layerContract.totalStaked()
        let stakedAddr1After = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
        let stakedAddr2After = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

        expect(stakedAfter).to.be.gt(stakedPrev)
        expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
        expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
        // expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


        // console.log('\nblock number :', block2.number);
        let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
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
        // expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
        expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
        expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
        expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
        expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

        expect(estimatedDistribute.l2TotalSeigs).to.be.eq(ethers.constants.Zero)
        expect(estimatedDistribute.layer2Seigs).to.be.eq(ethers.constants.Zero)

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
        )

        const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
        const afterTotalTvl = await seigManager.totalLayer2TVL()

        // console.log('afterTotalTvl', afterTotalTvl)
        // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
        // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

        let layer2RewardInfo = await seigManager.getLayer2RewardInfo(layerAddress)
        // console.log('layer2RewardInfo', layer2RewardInfo)
        expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            .sub(deployedEvent1.args.layer2Seigs)
        )

        expect(afterWtonBalanceOfLayer2Operator).to.be.eq(
            prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs))

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(estimatedDistribute.layer2Seigs)

        expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
            claimableL2SeigniorageTitan.add(claimableL2SeigniorageThanos))
    }

    /// layer1 에서 업데이트 시뇨리지를 실행할때의 테스트입니다.
    async function updateSeigniorageLayer1() {

        let claimableL2SeigniorageTitan = await seigManager.claimableL2Seigniorage(titanLayerAddress);
        // console.log('claimableL2SeigniorageTitan', claimableL2SeigniorageTitan)

        let claimableL2SeigniorageThanos = null
        if(thanosLayerAddress != null)
            claimableL2SeigniorageThanos = await seigManager.claimableL2Seigniorage(thanosLayerAddress);


        const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)

        const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)

        const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)

        // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
        let lastSeigBlock =  await seigManager.lastSeigBlock();
        // console.log('\nlastSeigBlock', lastSeigBlock)
        let block1 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block1.number);
        let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()
        // console.log( ' totalSupplyOfTon (before)   ', ethers.utils.formatUnits(totalSupplyOfTon,27) , 'WTON')

        let stakedA = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

        // let powerTonBalance = await wtonContract.balanceOf(powerTon);

        let layer2RewardInfoTitanPrev = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        const totalTvl = await seigManager.totalLayer2TVL()

        // console.log('\n updateSeigniorage... ' )

        const receipt = await (await seigManager.connect(pastDepositor).updateSeigniorageLayer(layer2Info_1.layer2)).wait()

        const topic = seigManager.interface.getEventTopic('CommitLog1');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        // console.log('\n totalStakedAmount : ',  ethers.utils.formatUnits(deployedEvent.args.totalStakedAmount,27) , 'WTON' )
        // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

        let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

        expect(stakedB).to.be.gt(stakedA)
        // expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalance)

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

        //=============================
        const topic1 = seigManager.interface.getEventTopic('SeigGiven2');
        const log1 = receipt.logs.find(x => x.topics.indexOf(topic1) >= 0);
        const deployedEvent1 = seigManager.interface.parseLog(log1);

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(ethers.constants.Zero);


        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
        )

        const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const afterTotalTvl = await seigManager.totalLayer2TVL()

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            .sub(deployedEvent1.args.layer2Seigs)
        )

        expect(afterWtonBalanceOfLayer2Operator).to.be.eq(
            prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs))

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(ethers.constants.Zero)

        if(claimableL2SeigniorageThanos == null) {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan)

        } else {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan.add(claimableL2SeigniorageThanos))
        }

    }

    /// Titan 에서 업데이트 시뇨리지를 실행할때의 테스트입니다.
    async function updateSeigniorageTitan() {

        let lastSeigBlock =  await seigManager.lastSeigBlock();
        // console.log('\nlastSeigBlock', lastSeigBlock)
        let block1 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block1.number);
        let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

        let claimableL2SeigniorageTitan = await seigManager.claimableL2Seigniorage(titanLayerAddress);
        let claimableL2SeigniorageThanos = null
        if(thanosLayerAddress != null)
            claimableL2SeigniorageThanos = await seigManager.claimableL2Seigniorage(thanosLayerAddress);
        // console.log('claimableL2SeigniorageThanos', claimableL2SeigniorageThanos)


        const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const totalTvl = await seigManager.totalLayer2TVL()
        const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)

        const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)


        let stakedPrev = await titanLayerContract.totalStaked()
        let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
        let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)
        // let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

        let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress)
        // console.log('estimatedDistribute', estimatedDistribute)

        const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

        const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
        expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
        expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)

        let stakedAfter = await titanLayerContract.totalStaked()
        let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
        let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

        expect(stakedAfter).to.be.gt(stakedPrev)
        expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
        expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
        // expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


        let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()

        let seigPerBlock =  await seigManager.seigPerBlock();

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
        // expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
        expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
        expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
        expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
        expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)


        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
        )

        const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const afterTotalTvl = await seigManager.totalLayer2TVL()

        let layer2RewardInfo = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        // console.log('layer2RewardInfo', layer2RewardInfo)
        expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);
        expect(claimableL2SeigniorageTitan).to.be.eq(deployedEvent1.args.layer2Seigs)


        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            .sub(deployedEvent1.args.layer2Seigs)
        )

        expect(afterWtonBalanceOfLayer2Operator).to.be.eq(
            prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs))

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(estimatedDistribute.layer2Seigs)

        if(claimableL2SeigniorageThanos == null) {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan)

        } else {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan.add(claimableL2SeigniorageThanos))
        }

    }

    /// Titan을 reject 한후에 Titan에서 업데이트 시뇨리지를 실행할때의 테스트입니다.
    /// 이경우 titan은 l2 시뇨리지를 이벤트에 layer2Seigs 값이 0이어야 합니다. 즉, 이번 커밋으로 이 레이어에 추가된 시뇨리지는 없다는 의미입니다
    async function updateSeigniorageTitan_reject() {

        let lastSeigBlock =  await seigManager.lastSeigBlock();
        // console.log('\nlastSeigBlock', lastSeigBlock)
        let block1 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block1.number);
        let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

        let claimableL2SeigniorageTitan = await seigManager.claimableL2Seigniorage(titanLayerAddress);

        let claimableL2SeigniorageThanos = await seigManager.claimableL2Seigniorage(thanosLayerAddress);


        const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const totalTvl = await seigManager.totalLayer2TVL()
        const rollupConfig = await layer2Manager.rollupConfigOfOperator(titanOperatorContractAddress)
        // console.log('rollupConfig', rollupConfig)


        const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)
        // console.log('curLayer2Tvl', curLayer2Tvl)

        let stakedPrev = await titanLayerContract.totalStaked()
        let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
        let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

        let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress)
        // console.log('estimatedDistribute', estimatedDistribute)

        const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(titanLayerAddress)).wait()

        const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        expect(deployedEvent.args.layer2).to.be.eq(titanLayerAddress)
        expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
        expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)
        // console.log('deployedEvent.args', deployedEvent.args)

        let stakedAfter = await titanLayerContract.totalStaked()
        let stakedAddr1After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr1.address)
        let stakedAddr2After = await seigManager["stakeOf(address,address)"](titanLayerAddress, addr2.address)

        expect(stakedAfter).to.be.gt(stakedPrev)
        expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
        expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

        let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()

        let seigPerBlock =  await seigManager.seigPerBlock();

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
        // expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
        expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
        expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
        expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
        expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(ethers.constants.Zero)

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
        )

        const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(titanOperatorContractAddress)
        const afterTotalTvl = await seigManager.totalLayer2TVL()

        let layer2RewardInfo = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        // console.log('layer2RewardInfo', layer2RewardInfo)
        expect(layer2RewardInfo.layer2Tvl).to.be.eq(ethers.constants.Zero);
        expect(claimableL2SeigniorageTitan).to.be.eq(deployedEvent1.args.layer2Seigs)

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            .sub(deployedEvent1.args.layer2Seigs)
        )

        expect(afterWtonBalanceOfLayer2Operator).to.be.eq(
            prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs))

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(estimatedDistribute.layer2Seigs)

        if(claimableL2SeigniorageThanos == null) {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan)

        } else {

            expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
                claimableL2SeigniorageTitan.add(claimableL2SeigniorageThanos))
        }

    }

    /// Thanos 에서 업데이트 시뇨리지를 실행할때의 테스트입니다.
    async function updateSeigniorageThanos() {
        let layerAddress = thanosLayerAddress
        let operatorContractAddress = thanosOperatorContractAddress
        let layerContract = thanosLayerContract

        // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
        let lastSeigBlock =  await seigManager.lastSeigBlock();
        // console.log('\nlastSeigBlock', lastSeigBlock)
        let block1 = await ethers.provider.getBlock('latest');
        // console.log('\nblock number :', block1.number);
        let totalSupplyOfTon = await seigManager["totalSupplyOfTon()"]()

        let claimableL2SeigniorageTitan = await seigManager.claimableL2Seigniorage(titanLayerAddress);
        // console.log('claimableL2SeigniorageTitan', claimableL2SeigniorageTitan)

        let claimableL2SeigniorageThanos= await seigManager.claimableL2Seigniorage(thanosLayerAddress);
        // console.log('claimableL2SeigniorageThanos', claimableL2SeigniorageThanos)

        const prevWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const prevWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
        const totalTvl = await seigManager.totalLayer2TVL()
        const rollupConfig = await layer2Manager.rollupConfigOfOperator(operatorContractAddress)
        const curLayer2Tvl = await l1BridgeRegistry.layer2TVL(rollupConfig)

        let stakedPrev = await layerContract.totalStaked()
        let stakedAddr1Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
        let stakedAddr2Prev = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)
        // let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

        let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,layerAddress)
        // console.log('estimatedDistribute', estimatedDistribute)

        const receipt = await (await seigManager.connect(deployer).updateSeigniorageLayer(layerAddress)).wait()

        const topic = seigManager.interface.getEventTopic('AddedSeigAtLayer');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        expect(deployedEvent.args.layer2).to.be.eq(layerAddress)
        expect(deployedEvent.args.seigs).to.be.gt(ethers.constants.Zero)
        expect(deployedEvent.args.nextTotalSupply).to.be.gt(deployedEvent.args.prevTotalSupply)


        let stakedAfter = await layerContract.totalStaked()
        let stakedAddr1After = await seigManager["stakeOf(address,address)"](layerAddress, addr1.address)
        let stakedAddr2After = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

        expect(stakedAfter).to.be.gt(stakedPrev)
        expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
        expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)
        // expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


        // console.log('\nblock number :', block2.number);
        let totalSupplyOfTon_after = await seigManager["totalSupplyOfTon()"]()
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
        // expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
        expect(estimatedDistribute.daoSeig).to.be.eq(deployedEvent1.args.daoSeig)
        expect(estimatedDistribute.relativeSeig).to.be.eq(deployedEvent1.args.pseig)
        expect(estimatedDistribute.l2TotalSeigs).to.be.eq(deployedEvent1.args.l2TotalSeigs)
        expect(estimatedDistribute.layer2Seigs).to.be.eq(deployedEvent1.args.layer2Seigs)

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs).sub(deployedEvent1.args.layer2Seigs)
        )

        const afterWtonBalanceOfLayer2Manager = await wtonContract.balanceOf(layer2Manager.address)
        const afterWtonBalanceOfLayer2Operator = await wtonContract.balanceOf(operatorContractAddress)
        const afterTotalTvl = await seigManager.totalLayer2TVL()

        // console.log('afterTotalTvl', afterTotalTvl)
        // console.log('afterWtonBalanceOfLayer2Manager', afterWtonBalanceOfLayer2Manager)
        // console.log('afterWtonBalanceOfLayer2Operator', afterWtonBalanceOfLayer2Operator)

        let layer2RewardInfo = await seigManager.getLayer2RewardInfo(layerAddress)
        // console.log('layer2RewardInfo', layer2RewardInfo)
        expect(layer2RewardInfo.layer2Tvl).to.be.eq(curLayer2Tvl);

        expect(await wtonContract.balanceOf(layer2Manager.address)).to.be.eq(
            prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)
            .sub(deployedEvent1.args.layer2Seigs)
        )

        expect(afterWtonBalanceOfLayer2Operator).to.be.eq(
            prevWtonBalanceOfLayer2Operator.add(deployedEvent1.args.layer2Seigs))

        expect(deployedEvent1.args.layer2Seigs).to.be.eq(estimatedDistribute.layer2Seigs)

        expect(prevWtonBalanceOfLayer2Manager.add(deployedEvent1.args.l2TotalSeigs)).to.be.gte(
            claimableL2SeigniorageTitan.add(claimableL2SeigniorageThanos))

    }

    /// 스테이킹을 approve and call 함수를 이용하여 합니다.
    async function depositApproveAndCall(layerAddress: string, account: Signer, amount:BigNumber ) {
        // let layerAddress = thanosLayerAddress
        // let account = addr1
        // let amount = ethers.utils.parseEther("200000")

        await (await tonContract.connect(tonMinter).mint(account.address, amount))

        const beforeBalance = await tonContract.balanceOf(account.address);
        expect(beforeBalance).to.be.gte(amount)

        let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, account.address)

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

        expect(roundDown(stakedB.add(ethers.BigNumber.from("9")),4)).to.be.eq(
            roundDown(stakedA.add(amount.mul(ethers.BigNumber.from("1000000000"))), 4)
        )
    }

    /// 스테이킹을 approve and call 함수를 wton을 이용하여 합니다.
    async function depositApproveAndCallWithWton(layerAddress: string, account: Signer, wtonAmount:BigNumber ) {

        // let layerAddress = thanosLayerAddress
        // let account = addr2

        // let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

        await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

        const beforeBalance = await wtonContract.balanceOf(account.address);
        expect(beforeBalance).to.be.gte(wtonAmount)

        await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

        let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
        // console.log(stakedA)

        await (await depositManager.connect(account)["deposit(address,uint256)"](
            layerAddress,
            wtonAmount
        )).wait()

        const afterBalance = await wtonContract.balanceOf(account.address);
        expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

        let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
        // console.log(stakedB)

        expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
            roundDown(stakedA.add(wtonAmount), 3)
        )
    }

        /// 타이탄에서 wton으로 스테이킹합니다.
        async function depositWithWton( layerAddress: string, account: Signer, wtonAmount:BigNumber ) {


            // let account = addr2

            // let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

            const beforeBalance = await wtonContract.balanceOf(account.address);
            expect(beforeBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
            // console.log(stakedA)

            await (await depositManager.connect(account)["deposit(address,uint256)"](
                layerAddress,
                wtonAmount
            )).wait()

            const afterBalance = await wtonContract.balanceOf(account.address);
            expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
            // console.log(stakedB)

            expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        }

        /// 레이어에서 wton으로 스테이킹을 다른 사람에게 합니다.
        async function depositWithWton2(layerAddress: string, account: Signer, wtonAmount:BigNumber ) {

            await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

            const beforeSenderBalance = await wtonContract.balanceOf(account.address);
            // console.log("beforeSenderBalance :", beforeSenderBalance);
            expect(beforeSenderBalance).to.be.gte(wtonAmount)

            await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

            let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            await (await depositManager.connect(account)["deposit(address,address,uint256)"](
                layerAddress,
                addr2.address,
                wtonAmount
            )).wait()

            const afterSenderBalance = await wtonContract.balanceOf(account.address);
            expect(afterSenderBalance).to.be.eq(beforeSenderBalance.sub(wtonAmount))

            let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, addr2.address)

            expect(roundDown(stakedB.add(ethers.BigNumber.from("3")),3)).to.be.eq(
                roundDown(stakedA.add(wtonAmount), 3)
            )
        }

    /// 출금요청합니다.
    async function requestWithdrawal (layer2: string, account: Signer, wtonAmount:BigNumber ) {

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
    }

    /// 출금합니다.
    async function processRequest (layer2: string, account: Signer ) {
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
    }

    // 타이탄을 l2 시뇨리지 부여하지 않도록 합니다.
    async function rejectCandidateTitan() {

        expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
        expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(false)

        let l2Info = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        let totalLayer2TVL = await seigManager.totalLayer2TVL()
        console.log('totalLayer2TVL', totalLayer2TVL)

        let allowIssuanceLayer2Seigs = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
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

        const topic2 = seigManagerV1_3.interface.getEventTopic('ExcludedFromL2Seigniorage');
        const log2 = receipt.logs.find(x => x.topics.indexOf(topic2) >= 0);
        const deployedEvent2 = seigManagerV1_3.interface.parseLog(log2);

        expect(deployedEvent2.args.layer2).to.be.eq(titanLayerAddress)

        expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(true)
        let l2InfoAfter = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        let totalLayer2TVLAfter = await seigManager.totalLayer2TVL()

        expect(l2InfoAfter.layer2Tvl).to.be.eq(ethers.constants.Zero)
        expect(totalLayer2TVLAfter).to.be.eq(totalLayer2TVL.sub(l2Info.layer2Tvl))

        let allowIssuanceLayer2SeigsAfter = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
        expect(allowIssuanceLayer2SeigsAfter.allowed).to.be.eq(false)

        expect(await seigManager.isPauseL2Seigniorage(titanLayerAddress)).to.be.eq(true)
    }

    // 타이탄을 l2 시뇨리지 부여를 재개합니다.
    async function restoreCandidateTitan() {
        expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
        expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(true)
        let claimableL2SeigniorageTitanPrev = await seigManager.claimableL2Seigniorage(titanLayerAddress);
        let l2Info = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        let totalLayer2TVL = await seigManager.totalLayer2TVL()

        let allowIssuanceLayer2Seigs = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)

        expect(allowIssuanceLayer2Seigs.allowed).to.be.eq(false)
        let curLayer2Tvl = await l1BridgeRegistry.layer2TVL(legacySystemConfig.address);

        const receipt =  await (await l1BridgeRegistry.connect(seigniorageCommittee).restoreCandidateAddOn(
            legacySystemConfig.address,
            false
        )).wait()
        const topic = l1BridgeRegistry.interface.getEventTopic('RestoredCandidateAddOn');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = l1BridgeRegistry.interface.parseLog(log);
        // console.log(deployedEvent.args)
        expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)

        expect(await l1BridgeRegistry.rejectRollupConfig(legacySystemConfig.address)).to.be.eq(false)
        let l2InfoAfter = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        let totalLayer2TVLAfter = await seigManager.totalLayer2TVL()

        expect(l2InfoAfter.layer2Tvl).to.be.eq(curLayer2Tvl)
        expect(l2InfoAfter.startBlock).to.be.gt(ethers.constants.Zero)

        expect(totalLayer2TVLAfter).to.be.eq(totalLayer2TVL.add(curLayer2Tvl))

        let allowIssuanceLayer2SeigsAfter = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
        expect(allowIssuanceLayer2SeigsAfter.allowed).to.be.eq(true)
        expect(await seigManager.isPauseL2Seigniorage(titanLayerAddress)).to.be.eq(false)

    }
    before('create fixture loader', async () => {
        const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, powerTonAddress,
            DAOAgendaManager,
            L1BridgeRegistryProxy, OperatorManagerFactory, CandidateAddOnFactoryProxy, Layer2ManagerProxy
         } = await getNamedAccounts();

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
        tonMinter = daoAdmin

        tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)
        wtonContract = new ethers.Contract(WTON,  Wton_Json.abi, deployer)
        daoContract = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeProxy_Json.abi, deployer)
        depositManager = new ethers.Contract(DepositManager,  DepositManager_Json.abi, deployer)
        depositManagerProxy = new ethers.Contract(DepositManager,  DepositManagerProxy_Json.abi, deployer)

        seigManager = new ethers.Contract(SeigManager,  SeigManager_Json.abi, deployer)
        seigManagerProxy = new ethers.Contract(SeigManager,  SeigManagerProxy_Json.abi, deployer)
        powerTon = powerTonAddress
        // tonContract.connect(daoAdmin).mint(addr1, utils.parseEther("2000"))
        // wtonContract.connect(daoAdmin).mint(addr1, utils.parseEther("2000"))

        l1BridgeRegistryProxy = (await ethers.getContractAt("L1BridgeRegistryV1_1", L1BridgeRegistryProxy, deployer)) as L1BridgeRegistryProxy
        l1BridgeRegistry = (await ethers.getContractAt("L1BridgeRegistryV1_1", L1BridgeRegistryProxy, deployer)) as L1BridgeRegistryV1_1
        operatorManagerFactory =  (await ethers.getContractAt("OperatorManagerFactory", OperatorManagerFactory, deployer)) as OperatorManagerFactory
        candidateAddOnFactory =  (await ethers.getContractAt("CandidateAddOnFactory", CandidateAddOnFactoryProxy, deployer)) as CandidateAddOnFactory
        candidateAddOnFactoryProxy =  (await ethers.getContractAt("CandidateAddOnFactoryProxy", CandidateAddOnFactoryProxy, deployer)) as CandidateAddOnFactoryProxy

        layer2ManagerProxy = (await ethers.getContractAt("Layer2ManagerProxy", Layer2ManagerProxy, deployer)) as Layer2ManagerProxy
        layer2Manager = (await ethers.getContractAt("Layer2ManagerV1_1", Layer2ManagerProxy, deployer)) as Layer2ManagerV1_1
        seigManagerV1_3 =(await ethers.getContractAt("SeigManagerV1_3", SeigManager, deployer)) as SeigManagerV1_3;

        daoCommitteeProxy2Contract =(await ethers.getContractAt("DAOCommitteeProxy2", DAOCommitteeProxy, deployer)) as DAOCommitteeProxy2;

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
            thanosSystemConfigOwnerAddress,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            thanosSystemConfigOwnerAddress,
            "0x10000000000000000000000000",
        ]);
        thanosSystemConfigOwner = await hre.ethers.getSigner(thanosSystemConfigOwnerAddress);

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
            // console.log(addresses)

            await (await legacySystemConfig.connect(deployer).setAddresses(
                name, addresses, l1BridgeRegistryProxy.address, deployer.address
            )).wait()
        })

        it('registerSystemConfigByManager  ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 1;
            let name = 'Titan'
            let receipt = await (await l1BridgeRegistry.connect(daoAdmin)["registerRollupConfigByManager(address,uint8,address,string)"](
                legacySystemConfig.address,
                type,
                l2TonAddress,
                name
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('RegisteredRollupConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
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

            await (await legacySystemConfigTest2.connect(deployer).setAddresses(
                name, addresses,  l1BridgeRegistryProxy.address, deployer.address
            )).wait()
        })

        it('registerSystemConfigByManager : Already registered l2Bridge addresses cannot be registered. ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 1;
            let name = 'Titan'

             await expect(l1BridgeRegistry.connect(manager)["registerRollupConfigByManager(address,uint8,address,string)"](
                legacySystemConfigTest2.address,
                type,
                l2TonAddress,
                name
            )).to.be.revertedWith("AuthControl: Caller is not a manager")
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

    // patch version
    describe('# DAO.upgradeTo(DAOCommittee_V1) ', () => {
        it('deploy CandidateAddOnFactory', async () => {
            patchedCandidateAddOnFactory = (await (await ethers.getContractFactory("CandidateAddOnFactory")).connect(deployer).deploy()) as CandidateAddOnFactory;
        })

        it('deploy DAOCommittee_V2', async () => {
            daoCommittee_V2 = (await (await ethers.getContractFactory("DAOCommittee_V2")).connect(deployer).deploy()) as DAOCommittee_V2;
        })

    })


    ///--- Agenda ---------------------------------
    describe('# Agenda', () => {

        it('Submit an agenda', async () => {
            const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, DAOAgendaManager,
                 CandidateAddOnFactoryProxy
            } = await getNamedAccounts();
            let targets = []
            let params = []
            let callDtata

            // =========================================
            // 1. set candidateAddOnFactoryProxy upgradeTo
            targets.push(CandidateAddOnFactoryProxy)
            callDtata = candidateAddOnFactoryProxy.interface.encodeFunctionData("upgradeTo", [patchedCandidateAddOnFactory.address])
            params.push(callDtata)

            // =========================================
            // 2. upgradeTo2 daoCommittee_V2
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("upgradeTo2", [daoCommittee_V2.address])
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

            let logic = await candidateAddOnFactoryProxy.implementation()
            expect(logic).to.be.equal(patchedCandidateAddOnFactory.address)


            let logicDao = await daoCommitteeProxy2Contract.implementation2(0)
            expect(logicDao).to.be.equal(daoCommittee_V2.address)

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

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(daoAdmin).mint(addr1.address, amount))
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

        it('Layers that are not registered in the L1BridgeRegistry cannot be registered.', async () => {
            expect((await layer2Manager.statusLayer2(legacySystemConfigTest2.address))).to.be.eq(0)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(daoAdmin).mint(addr1.address, amount))
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

     describe('# MockSystemConfigFactory ', () => {
        it('set MockSystemConfigFactory ', async () => {

            mockSystemConfigFactory = (await (await ethers.getContractFactory("MockSystemConfigFactory")).connect(deployer).deploy()) as MockSystemConfigFactory;

            let name = 'Thanos'

            const receipt = await (await mockSystemConfigFactory.connect(thanosSystemConfigOwner).createMockSystemConfig(
                name
            )).wait()

            const topic = mockSystemConfigFactory.interface.getEventTopic('CreatedMockSystemConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = mockSystemConfigFactory.interface.parseLog(log);

            expect(deployedEvent.args.name).to.be.eq(name)

            thanosSystemConfigContract = (new ethers.Contract(deployedEvent.args.mockSystemConfig,  MockSystemConfig_Json.abi, deployer)) as MockSystemConfig
            thanosSystemConfig = thanosSystemConfigContract.address


            let portal = await thanosSystemConfigContract.optimismPortal()
            await tonContract.connect(tonMinter).mint(portal, utils.parseEther("2000000"))


        })
    })

    describe('# ThanosSystemConfig : Thanos ', () => {


        it('registerRollupConfigByManager  ', async () => {
            const {thanosL2TON } = await getNamedAccounts();

            let type = 2;
            let name = 'Thanos'

            let receipt = await (await l1BridgeRegistry.connect(daoAdmin)["registerRollupConfigByManager(address,uint8,address,string)"](
                thanosSystemConfig,
                type,
                thanosL2TON,
                name
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('RegisteredRollupConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(thanosSystemConfig)
            expect(deployedEvent.args.type_).to.be.eq(type)

        })
    })


    describe('# DepositManager : CandidateAddOn titanLayerAddress ', () => {

        it('deposit to titanLayerAddress using approveAndCall', async () => {

            let layerAddress = titanLayerAddress
            let account = addr1
            let amount = ethers.utils.parseEther("20000")

            await depositApproveAndCall(
                layerAddress,
                account,
                amount
            );

        })

        it('deposit to titanLayerAddress using deposit(address,uint256)', async () => {

            let account = addr2
            let amount = ethers.utils.parseEther("200000")

            await depositWithWton(
                titanLayerAddress,
                account,
                amount
            );

        })

        it('deposit to titanLayerAddress using deposit(address,address,uint256) ', async () => {

            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

            await depositWithWton2(
                titanLayerAddress,
                account,
                wtonAmount
            );

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

        it('seigManager: updateSeigniorageLayer : (1) updateSeigniorage to titanLayerAddress ', async () => {
            await updateSeigniorageTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer : (2) updateSeigniorage to titanLayerAddress   ', async () => {

            await updateSeigniorageTitan();
        })
    })


    describe('# register CandidateAddOn : thanosCandidateAddOn ', () => {
        it('register CandidateAddOn : thanosCandidateAddOn', async () => {

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


    describe('# DepositManager : CandidateAddOn : thanosCandidateAddOn ', () => {

        it('deposit to thanosLayerAddress using approveAndCall', async () => {
            let layerAddress = thanosLayerAddress
            let account = addr1
            let amount = ethers.utils.parseEther("200000")

            await depositApproveAndCall(
                layerAddress,
                account,
                amount
            );
        })

        it('deposit to thanosLayerAddress using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)
            let layerAddress = thanosLayerAddress
            let account = addr2

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))


            await depositWithWton(layerAddress, account, wtonAmount );


        })

        it('seigManager: updateSeigniorageLayer : (1) updateSeigniorage to thanosLayer ', async () => {

            await updateSeigniorageThanos();

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

            await (await depositManager.connect(account)["deposit(address,address,uint256)"](
                layerAddress,
                addr2.address,
                wtonAmount
            )).wait()

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

        it('seigManager: updateSeigniorageLayer : (2) updateSeigniorage to thanosLayerAddress ', async () => {

            await updateSeigniorageThanos();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer : (3) updateSeigniorage to thanosLayerAddress   ', async () => {
            await updateSeigniorageThanos();
        })


        // it('evm_mine', async () => {
        //     ethers.provider.send("evm_increaseTime", [60*60*24*7])
        //     ethers.provider.send("evm_mine");
        // });

        // it('Layer2Contract: updateSeigniorage : (4) updateSeigniorage to thanosLayerAddress   ', async () => {
        //     await updateSeigniorageThanos();


        // })

        // it('evm_mine', async () => {
        //     ethers.provider.send("evm_increaseTime", [60*60*24*7])
        //     ethers.provider.send("evm_mine");
        // });

        // it('Layer2Contract: updateSeigniorage : (5) updateSeigniorage to thanosLayerAddress : operator ', async () => {
        //     await updateSeigniorageThanos();

        // })


        it('requestWithdrawal to titanLayerAddress', async () => {
            console.log('thanosLayerAddress', thanosLayerAddress)
            let layer2 = thanosLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            await requestWithdrawal (layer2, account, wtonAmount);

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

            await processRequest(layer2, account);
        });

    })


    describe('# DepositManager : CandidateAddOn : titanCandidateAddOn ', () => {

        it('seigManager: updateSeigniorageLayer : (3) updateSeigniorage to titanLayerAddress ', async () => {
            await updateSeigniorageTitan();

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : (4) updateSeigniorage to titanLayerAddress ', async () => {
            await updateSeigniorageTitan();

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        // it('Layer2Contract: updateSeigniorage : (5) updateSeigniorage to titanLayerAddress ', async () => {

        //     await updateSeigniorageTitan();

        // })

    })


    describe('# Reject titanCandidateAddOn test ', () => {

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('reject CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
            await rejectCandidateTitan();
        })
        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        })

        it('Layer2Contract: updateSeigniorage : updateSeigniorage to titanLayerAddress ', async () => {
            await updateSeigniorageTitan_reject();


        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : updateSeigniorage to thanosLayerAddress ', async () => {
                await updateSeigniorageThanos()
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
            await restoreCandidateTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('updateSeigniorage to layer1', async () => {
            await updateSeigniorageLayer1()
        })

        it('reject CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {

            await rejectCandidateTitan();

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : updateSeigniorage to thanosLayerAddress ', async () => {

            await updateSeigniorageThanos()

        })


        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('updateSeigniorage to layer1', async () => {
            await updateSeigniorageLayer1()

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : updateSeigniorage to titanLayerAddress ', async () => {

            await updateSeigniorageTitan_reject()


        })

    })


    describe("# Reject updating seigniorage from unknown sender", () => {
        it("updateSeigniorage", async () => {
            const accounts = await ethers.getSigners();
            const { L2Registry, DepositManager } = await getNamedAccounts();

            const invalidCandidateAddOnFactory = await ethers.getContractFactory(
                "InvalidCandidateAddOn",
            );
            // console.log(`thanos : ${thanosOperatorContractAddress}`);
            // console.log(`layer2Registry : ${L2Registry}`);
            const invalidCandidateAddOn = await invalidCandidateAddOnFactory.deploy(
                thanosOperatorContractAddress,
                L2Registry,
                seigManager.address
            );
            await invalidCandidateAddOn.deployed();
            // console.log(`invalidCandidateAddOn : ${invalidCandidateAddOn.address}`);

            const layer2Registry = await ethers.getContractAt(
                "Layer2Registry",
                L2Registry,
            );

            layer2Registry.deployCoinage(
                invalidCandidateAddOn.address,
                seigManager.address,
            );

            await layer2Registry.register(invalidCandidateAddOn.address);

            await wtonContract
                .connect(tonMinter)
                .mint(accounts[0].address, ethers.utils.parseUnits("1014", 27));

            await wtonContract
                .connect(accounts[0])
                .approve(depositManager.address, ethers.utils.parseUnits("1014", 27));
            await (
                await depositManager
                    .connect(accounts[0])
                    ["deposit(address,address,uint256)"](
                        invalidCandidateAddOn.address,
                        thanosOperatorContractAddress,
                        ethers.utils.parseUnits("1014", 27),
                    )
            ).wait();

            const prevTotalLayer2TVL = await seigManager.totalLayer2TVL();
            // console.log(`before ${await seigManager.totalLayer2TVL()}`);
            await invalidCandidateAddOn.updateSeigniorage();
            // console.log(`after ${await seigManager.totalLayer2TVL()}`);

            expect(await seigManager.totalLayer2TVL()).to.be.eq(prevTotalLayer2TVL);
        });
    });

});

