import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts} from 'hardhat'

import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import {encodeFunctionSignature} from 'web3-eth-abi'
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

import { MockSystemConfigFactory } from "../../../typechain-types/contracts/mocks/MockSystemConfigFactory.sol"
import { MockSystemConfig } from "../../../typechain-types/contracts/mocks/MockSystemConfig.sol"
import { InvalidCandidateAddOn } from "../../../typechain-types/contracts/mocks/InvalidCandidateAddOn"



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

const layers = [
    {"oldLayer":"","newLayer":"0xaeb0463a2fd96c68369c1347ce72997406ed6409","operator":"0xd4335a175c36c0922f6a368b83f9f6671bf07606","name":"candidate"},
    {"oldLayer":"","newLayer":"0xabd15c021942ca54abd944c91705fe70fea13f0d","operator":"0x757de9c340c556b56f62efae859da5e08baae7a2","name":"member_DAO"},
]

let thanosSystemConfigOwnerAddress = "0x9E628CaAd7A6dD3ce48E78812241B41BdbeF6244"
let thanosSystemConfigOwner: Signer
let thanosSystemConfig: any
let thanosSystemConfigContract: MockSystemConfig

let pastAddr = "0xD4335A175c36c0922F6A368b83f9F6671bf07606"
let wtonhaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
let tonHaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

const daoOwnerAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinterAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinter: Signer
let seigniorageCommitteeAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let seigniorageCommittee: Signer

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

function sum(amounts: Array<string>)  {

    let amount = ethers.constants.Zero
    for(let i=0; i< amounts.length; i++) amount = amount.add(amounts[i])
    return amount;
}

async function logPause(seigManager:Contract, layerAddress: string){
    let layer2PauseBlockIndex =  await seigManager.getLayer2PauseBlockIndex(layerAddress)

    if(layer2PauseBlockIndex.length != 0 ) {
        for (let i=0; i < layer2PauseBlockIndex.length; i++){
            let pauseBlock = layer2PauseBlockIndex[i]
            let unpauseBlockIndex =  await seigManager.layer2UnpauseBlockIndex(layerAddress,pauseBlock)
        }
    }
}

describe('TON Staking V2.5', () => {
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

    let mockSystemConfigFactory: MockSystemConfigFactory
    let mockSystemConfig: MockSystemConfig
    let mockCandidateAddress: string, mockOperatorContractAddress: string;
    let mockCandidateCotract: CandidateAddOnV1_1
    let mockOperatorContract: OperatorManagerV1_1


    let powerTon: string
    let pastDepositor:Signer, wtonHave:Signer, tonHave:Signer
    let layer2Info_1 : any;
    let layer2Info_2 : any;

    let titanLayerSeigs: Array<string>;
    let thanosLayerSeigs: Array<string>;


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

        let powerTonBalance = await wtonContract.balanceOf(powerTon);

        let layer2RewardInfoTitanPrev = await seigManager.layer2RewardInfo(titanLayerAddress)
        const totalTvl = await seigManager.totalLayer2TVL()

        // console.log('\n updateSeigniorage... ' )
        const receipt = await (await seigManager.connect(pastDepositor).updateSeigniorageLayer(layer2Info_1.layer2)).wait()

        const topic = seigManager.interface.getEventTopic('CommitLog1');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);

        let stakedB = await seigManager["stakeOf(address,address)"](layer2Info_1.layer2, pastDepositor.address)

        expect(stakedB).to.be.gt(stakedA)
        expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalance)

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
        let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

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
        expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


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
        expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
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

        let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
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
        let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

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
        expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


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
        expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
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

        let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
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

        let powerTonBalance = await wtonContract.balanceOf(powerTon);

        let layer2RewardInfoTitanPrev = await seigManager.layer2RewardInfo(titanLayerAddress)
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
        let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

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
        expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


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
        expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
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

        let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
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
        expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
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

        let layer2RewardInfo = await seigManager.layer2RewardInfo(titanLayerAddress)
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
        let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

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
        expect(await wtonContract.balanceOf(powerTon)).to.be.gt(powerTonBalancePrev)


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
        expect(estimatedDistribute.powertonSeig).to.be.eq(deployedEvent1.args.powertonSeig)
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

        let layer2RewardInfo = await seigManager.layer2RewardInfo(layerAddress)
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

        expect(roundDown(stakedB.add(ethers.BigNumber.from("10")),4)).to.be.eq(
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

        let l2Info = await seigManager.layer2RewardInfo(titanLayerAddress)
        let totalLayer2TVL = await seigManager.totalLayer2TVL()
        // console.log('totalLayer2TVL', totalLayer2TVL)

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
        let l2InfoAfter = await seigManager.layer2RewardInfo(titanLayerAddress)
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
        let l2Info = await seigManager.layer2RewardInfo(titanLayerAddress)
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
        let l2InfoAfter = await seigManager.layer2RewardInfo(titanLayerAddress)
        let totalLayer2TVLAfter = await seigManager.totalLayer2TVL()

        expect(l2InfoAfter.layer2Tvl).to.be.eq(curLayer2Tvl)
        expect(l2InfoAfter.startBlock).to.be.gt(ethers.constants.Zero)

        expect(totalLayer2TVLAfter).to.be.eq(totalLayer2TVL.add(curLayer2Tvl))

        let allowIssuanceLayer2SeigsAfter = await seigManager.allowIssuanceLayer2Seigs(titanLayerAddress)
        expect(allowIssuanceLayer2SeigsAfter.allowed).to.be.eq(true)
        expect(await seigManager.isPauseL2Seigniorage(titanLayerAddress)).to.be.eq(false)

    }


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

        titanLayerSeigs = []
        thanosLayerSeigs = []

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
            const {DepositManager, TON, WTON } = await getNamedAccounts();

            operatorManagerFactory = (await (await ethers.getContractFactory("OperatorManagerFactory")).connect(deployer).deploy(operatorManagerV1_1.address)) as OperatorManagerFactory;

        });
    })

    describe('# CandidateAddOnV1_1', () => {
        it('deploy CandidateAddOnV1_1Imp', async () => {
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
            await (await l1BridgeRegistryProxy.connect(deployer).addManager(manager.address)).wait()
            expect(await l1BridgeRegistryProxy.isManager(manager.address)).to.be.eq(true)
        })

        it('OperatorManagerFactory.setAddresses', async () => {
            const {DepositManager, TON, WTON } = await getNamedAccounts();

            const receipt = await (await operatorManagerFactory.connect(deployer).setAddresses(
                DepositManager,
                TON,
                WTON,
                layer2ManagerProxy.address
            )).wait()
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

            await (await legacySystemConfig.connect(deployer).setAddresses(
                name, addresses, l1BridgeRegistryProxy.address, deployer.address
            )).wait()
        })

        it('registerSystemConfigByManager  ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 1;
            let name = 'Titan'

            let receipt = await (await l1BridgeRegistry.connect(manager)["registerRollupConfigByManager(address,uint8,address,string)"](
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

    describe('# MockSystemConfigFactory ', () => {
        it('create mockSystemConfig ', async () => {
            let name = 'MockSystemConfigTest1'

            const receipt = await (await mockSystemConfigFactory.connect(deployer).createMockSystemConfig(
                name
            )).wait()

            const topic = mockSystemConfigFactory.interface.getEventTopic('CreatedMockSystemConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = mockSystemConfigFactory.interface.parseLog(log);

            expect(deployedEvent.args.name).to.be.eq(name)

            mockSystemConfig = (new ethers.Contract(deployedEvent.args.mockSystemConfig,  MockSystemConfig_Json.abi, deployer)) as MockSystemConfig
        })

        it('registerSystemConfigByManager  ', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            let type = 2;
            let name = await mockSystemConfig.name()
            let l2TonAddress_native = "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000"
            let receipt = await (await l1BridgeRegistry.connect(manager)["registerRollupConfigByManager(address,uint8,address,string)"](
                mockSystemConfig.address,
                type,
                l2TonAddress_native,
                name
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('RegisteredRollupConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(mockSystemConfig.address)
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
                name, addresses, l1BridgeRegistryProxy.address, deployer.address
            )).wait()
        })

        it('registerRollupConfigByManager : Already registered l2Bridge addresses cannot be registered. ', async () => {
            let type = 1;
            let name = 'Titan'
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

             await expect(l1BridgeRegistry.connect(manager)["registerRollupConfigByManager(address,uint8,address,string)"](
                legacySystemConfigTest2.address,
                type,
                l2TonAddress,
                name
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

    describe('# _lastSeigBlock  ', () => {
        it('_lastSeigBlock  ', async () => {
            const lastSeigBlock = await seigManager.lastSeigBlock();

            console.log("lastSeigBlock %s", lastSeigBlock)

        })
    })

    describe('# ThanosSystemConfig : Thanos ', () => {


        it('registerRollupConfigByManager  ', async () => {
            const {thanosL2TON } = await getNamedAccounts();

            let type = 2;
            let name = 'Thanos'

            let receipt = await (await l1BridgeRegistry.connect(manager)["registerRollupConfigByManager(address,uint8,address,string)"](
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
            const selector6 = encodeFunctionSignature("updateSeigniorageLayer(address)");
            const selector7 = encodeFunctionSignature("allowIssuanceLayer2Seigs(address)");
            const selector8 = encodeFunctionSignature("totalLayer2TVL()");
            const selector9 = encodeFunctionSignature("layer2RewardInfo(address)");
            const selector10 = encodeFunctionSignature("l1BridgeRegistry()");
            const selector11 = encodeFunctionSignature("layer2Manager()");
            const selector12 = encodeFunctionSignature("layer2StartBlock()");
            const selector13 = encodeFunctionSignature("isPauseL2Seigniorage(address)");
            const selector14 = encodeFunctionSignature("includeFromL2Seigniorage(address)");
            const selector15 = encodeFunctionSignature("estimatedDistribute(uint256,address)");
            const selector16 = encodeFunctionSignature("excludeFromL2Seigniorage(address)");

            const selector17 = encodeFunctionSignature("unallocatedSeigniorage()");
            const selector18 = encodeFunctionSignature("unallocatedSeigniorageAt(uint256)");
            const selector19 = encodeFunctionSignature("stakeOfAllLayers()");
            const selector20 = encodeFunctionSignature("stakeOfAllLayersAt(uint256)");
            const selector21 = encodeFunctionSignature("claimableL2Seigniorage(address)");
            const selector22 = encodeFunctionSignature("claimL2Seigniorage(address,uint256)");

            const selector23 = encodeFunctionSignature("l2RewardPerUint()");
            const selector24 = encodeFunctionSignature("l2RewardAtBlock(uint256)");
            const selector25 = encodeFunctionSignature("layer2PauseBlockIndexLength(address)");
            const selector26 = encodeFunctionSignature("getLayer2PauseBlockIndex(address)");
            const selector27 = encodeFunctionSignature("layer2UnpauseBlockIndex(address,uint256)");

            let functionBytecodes = [
                selector1, selector2, selector3, selector4, selector5,
                selector6, selector7, selector8, selector9, selector10,
                selector11, selector12, selector13, selector14, selector15
                , selector16,
                selector17, selector18, selector19, selector20, selector21, selector22,
                selector23, selector24, selector25, selector26, selector27
            ];

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
            expect(await seigManagerProxy.getSelectorImplementation2(selector10)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector11)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector12)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector13)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector14)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector15)).to.be.eq(seigManagerV1_3.address)
            expect(await seigManagerProxy.getSelectorImplementation2(selector16)).to.be.eq(seigManagerV1_3.address)

        })

        it('DepositManager register function ', async () => {

            const selector1 = encodeFunctionSignature("ton()");
            const selector2 = encodeFunctionSignature("minDepositGasLimit()");
            const selector3 = encodeFunctionSignature("setMinDepositGasLimit(uint32)");
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


    describe('# registerCandidateAddOn : MockSystemConfig  ', () => {

        it('registerCandidateAddOn : MockSystemConfig ', async () => {
            const systemConfig = mockSystemConfig;

            expect((await layer2Manager.statusLayer2(systemConfig.address))).to.be.eq(0)

            const amount = await layer2Manager.minimumInitialDepositAmount();

            await (await tonContract.connect(tonMinter).mint(addr1.address, amount))
            let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            }

            const name = await systemConfig.name()
            const operatorAddress = await operatorManagerFactory.getAddress(systemConfig.address)

            const receipt = await (await layer2Manager.connect(addr1).registerCandidateAddOn(
                systemConfig.address,
                amount,
                true,
                name
            )).wait()

            const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);
            // console.log(deployedEvent.args)
            expect(deployedEvent.args.rollupConfig).to.be.eq(systemConfig.address)
            expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            expect(deployedEvent.args.memo).to.be.eq(name)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

            mockCandidateAddress = deployedEvent.args.candidateAddOn;
            mockOperatorContractAddress = deployedEvent.args.operator;
            expect((await layer2Manager.statusLayer2(systemConfig.address))).to.be.eq(1)

            mockCandidateCotract =  (await ethers.getContractAt("CandidateAddOnV1_1", mockCandidateAddress, deployer)) as CandidateAddOnV1_1
            mockOperatorContract = (await ethers.getContractAt("OperatorManagerV1_1", mockOperatorContractAddress, deployer)) as OperatorManagerV1_1
        })

    })

    describe('# registerCandidateAddOn ', () => {
        it('Fail if rollupConfig is an invalid address', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                l1BridgeRegistry.address,
                amount,
                true,
                'Titan'
            )).to.be.rejectedWith("RegisterError")
        })

        it('Failure in case of insufficient ton balance', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()

            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                legacySystemConfig.address,
                amount,
                true,
                'Titan'
            )).to.be.rejectedWith("TRANSFER_FROM_FAILED")
        })

        it('Failure when there is no prior approval of wton', async () => {
            const amount = await layer2Manager.minimumInitialDepositAmount()
            await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
                legacySystemConfig.address,
                amount.mul(utils.parseEther("1000000000")),
                false,
                'Titan'
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

    describe('# L1BridgeRegistry', () => {

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
            await (await seigManager.connect(daoOwner).setLayer2StartBlock(block1.number + 1))
        });
    });

    //===================================================


    describe('# DepositManager : CandidateAddOn titanLayerAddress ', () => {

        it('deposit to titanLayerAddress using approveAndCall', async () => {

            let layerAddress = titanLayerAddress
            let account = addr1
            let amount = ethers.utils.parseEther("200000")

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

    describe('# Layer2Manager ZeroAddress Test (1) deposit ', () => {

        it('deposit to titanLayerAddress using approveAndCall', async () => {

            if ((await seigManager.layer2Manager()) == layer2Manager.address) {
                await (await seigManager.connect(daoOwner).setLayer2Manager(ethers.constants.AddressZero)).wait()
            }

            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");

            await depositApproveAndCall(layer2Info_1.layer2, addr1, ethers.utils.parseEther("100"))

            if ((await seigManager.layer2Manager()) == ethers.constants.AddressZero) {
                await (await seigManager.connect(daoOwner).setLayer2Manager(layer2Manager.address)).wait()
            }

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

    });


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


    describe('# Layer2Manager ZeroAddress Test (2)  ', () => {

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('deposit to layer1 using approveAndCall', async () => {

            if ((await seigManager.layer2Manager()) == layer2Manager.address) {
                await (await seigManager.connect(daoOwner).setLayer2Manager(ethers.constants.AddressZero)).wait()
            }

            await depositApproveAndCall(layer2Info_1.layer2, addr1, ethers.utils.parseEther("100"))
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('updateSeigniorage to layer1 ', async () => {
            await updateSeigniorageLayer_Layer2Manager_ZeroAddress()
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        // it('updateSeigniorage to thanosLayerAddress ', async () => {
        //     updateSeigniorageThanos_Layer2Manager_ZeroAddress()
        // })

        // it('evm_mine', async () => {
        //     ethers.provider.send("evm_increaseTime", [60*60*24*7])
        //     ethers.provider.send("evm_mine");
        // });


        it('updateSeigniorage to titanLayerAddress ', async () => {
            await  updateSeigniorageTitan_Layer2Manager_ZeroAddress()

            if (await seigManager.layer2Manager() == ethers.constants.AddressZero) {
                await (await seigManager.connect(daoOwner).setLayer2Manager(layer2Manager.address)).wait()
            }
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });


    });

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

