import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts, deployments} from 'hardhat'

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
import { CandidateAddOnFactoryProxy } from "../../../typechain-types/contracts/dao/factory/CandidateAddOnFactoryProxy"
import { CandidateAddOnFactory } from "../../../typechain-types/contracts/dao/factory/CandidateAddOnFactory"

import { CandidateAddOnV1_1 } from "../../../typechain-types/contracts/dao/CandidateAddOnV1_1"
import { LegacySystemConfig } from "../../../typechain-types/contracts/layer2/LegacySystemConfig"
import { SeigManagerV1_2 } from "../../../typechain-types/contracts/stake/managers/SeigManagerV1_2"
import { SeigManagerV1_3 } from "../../../typechain-types/contracts/stake/managers/SeigManagerV1_3"
import { DepositManagerV1_1 } from "../../../typechain-types/contracts/stake/managers/DepositManagerV1_1"

import { DAOCommitteeProxy2 } from "../../../typechain-types/contracts/proxy/DAOCommitteeProxy2"
import { DAOCommittee_V1 } from "../../../typechain-types/contracts/dao/DAOCommittee_V1"
import { DAOCommitteeOwner } from "../../../typechain-types/contracts/dao/DAOCommitteeOwner"
import { Candidate } from "../../../typechain-types/contracts/dao/Candidate"

import { MockSystemConfigFactory } from "../../../typechain-types/contracts/mocks/MockSystemConfigFactory.sol"
import { MockSystemConfig } from "../../../typechain-types/contracts/mocks/MockSystemConfig.sol"

import Ton_Json from '../../abi/TON.json'
import Wton_Json from '../../abi/WTON.json'
import DAOCommitteeProxy_Json from '../../abi/DAOCommitteeProxy.json'
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
let thanosManager: Signer
let thanosSystemConfig: any
let thanosSystemConfigContract: MockSystemConfig

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
        MultiProposerableTransactionExecutor: "0x0Fd5632f3b52458C31A2C3eE1F4b447001872Be9"
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

describe('Rehearsal of upgrading staking V2 on the sepola ', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1
    let l1BridgeRegistryOld: L1BridgeRegistryV1_1


    let legacySystemConfig: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorManagerV1_1:OperatorManagerV1_1 , operatorManagerFactory: OperatorManagerFactory

    let candidateAddOnV1_1Imp: CandidateAddOnV1_1
    let candidateAddOnFactoryImp:CandidateAddOnFactory , candidateAddOnFactoryProxy: CandidateAddOnFactoryProxy, candidateAddOnFactory: CandidateAddOnFactory
    let tonContract: Contract, wtonContract: Contract, daoContract: Contract, daoV2Contract: Contract
    let depositManager: Contract,  depositManagerProxy: Contract;
    let seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3, seigManagerV1_2: SeigManagerV1_2;
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
        // console.log('claimableL2SeigniorageTitan', claimableL2SeigniorageTitan)
        // console.log('claimableL2SeigniorageThanos', claimableL2SeigniorageThanos)


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
        // let powerTonBalancePrev = await wtonContract.balanceOf(powerTon);

        let estimatedDistribute = await seigManager.estimatedDistribute(block1.number+1,titanLayerAddress)

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
        // console.log("SeigGiven2", deployedEvent1.args)
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
        // console.log('afterTotalTvl', afterTotalTvl)
        // console.log('titanLayerAddress', titanLayerAddress)

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

        let portal = await thanosSystemConfigContract.optimismPortal()
        await tonContract.balanceOf(portal)

        // await deployed.WTON.connect(daoAdmin).addMinter(deployed.seigManagerV2.address)
        let lastSeigBlock =  await seigManager.lastSeigBlock();
        // console.log('\nlastSeigBlock', lastSeigBlock)
        let block1 = await ethers.provider.getBlock('latest');
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
        // console.log('stakedAddr1After', stakedAddr1After)
        // console.log('stakedAddr2After', stakedAddr2After)

        expect(stakedAfter).to.be.gt(stakedPrev)
        expect(stakedAddr1After).to.be.gt(stakedAddr1Prev)
        expect(stakedAddr2After).to.be.gt(stakedAddr2Prev)

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

        expect(roundDown(stakedB.add(ethers.BigNumber.from("3")),6)).to.be.eq(
            roundDown(stakedA.add(amount.mul(ethers.BigNumber.from("1000000000"))), 6)
        )
    }

    // /// 스테이킹을 approve and call 함수를 wton을 이용하여 합니다.
    // async function depositApproveAndCallWithWton(layerAddress: string, account: Signer, wtonAmount:BigNumber ) {

    //     // let layerAddress = thanosLayerAddress
    //     // let account = addr2

    //     // let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

    //     await (await wtonContract.connect(tonMinter).mint(account.address, wtonAmount))

    //     const beforeBalance = await wtonContract.balanceOf(account.address);
    //     expect(beforeBalance).to.be.gte(wtonAmount)

    //     await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

    //     let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
    //     // console.log(stakedA)

    //     await (await depositManager.connect(account)["deposit(address,uint256)"](
    //         layerAddress,
    //         wtonAmount
    //     )).wait()

    //     const afterBalance = await wtonContract.balanceOf(account.address);
    //     expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

    //     let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, account.address)
    //     // console.log(stakedB)

    //     expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
    //         roundDown(stakedA.add(wtonAmount), 3)
    //     )
    // }

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

        expect(roundDown(stakedB.add(ethers.BigNumber.from("2")),3)).to.be.eq(
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

        expect(roundDown(stakedA.sub(ethers.BigNumber.from("1")),5)).to.be.eq(
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

        let globalWithdrawalDelay = await depositManager.getDelayBlocks(layer2)

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

        // await hre.network.provider.send("hardhat_impersonateAccount", [
        //     pastAddr,
        // ]);
        // await hre.network.provider.send("hardhat_setBalance", [
        //     pastAddr,
        //     "0x10000000000000000000000000",
        // ]);
        // pastDepositor = await hre.ethers.getSigner(pastAddr);
        pastAddr = addr2.address
        pastDepositor = addr2

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
            ownerAddressInfo.Thanos.MultiProposerableTransactionExecutor,
        ]);
        await hre.network.provider.send("hardhat_setBalance", [
            ownerAddressInfo.Thanos.MultiProposerableTransactionExecutor,
            "0x10000000000000000000000000",
        ]);
        thanosManager =  await hre.ethers.getSigner(ownerAddressInfo.Thanos.MultiProposerableTransactionExecutor);


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
            // await (await tonContract.connect(tonMinter).mint(pastAddr, ethers.utils.parseEther("10000"))).wait()
            await (await wtonContract.connect(tonMinter).mint(wtonHave.address, ethers.utils.parseEther("10000000000000"))).wait()
            await (await wtonContract.connect(tonMinter).mint(addr2.address, ethers.utils.parseEther("10000000000000"))).wait()


        }).timeout(10000);
    })

    describe('# Initialize of contracts ', () => {

        it('Reject all layers of L1BridgeRegistry', async () => {

            // let L1BridgeRegistryProxyOldAddress = "0x58813D18b019F670d43be0D80Af968C99cc82c05"
            // let Layer2ManagerOldAddress = "0x0fDb12aF5Fece558d17237E2D252EC5dbA25396b"
            // let L1BridgeRegistryProxyOldAddress = "0x3268e4D8276c58A806E83B3B080Cf29514A837cf"
            // let Layer2ManagerOldAddress = "0xab303E7CBFd19C998268e19d830770e215AbDF7F"
            // 4th
            let L1BridgeRegistryProxyOldAddress = "0x35822B4be688B06E58479Ed289E928cB25Cb3c68"
            let Layer2ManagerOldAddress = "0x53faC2e379cBfFd4C32D2b6FBBA83De102DDA2E5"


            const l1BridgeRegistryOld = (await ethers.getContractAt("L1BridgeRegistryV1_1", L1BridgeRegistryProxyOldAddress, deployer)) as L1BridgeRegistryV1_1
            const Layer2ManagerOld = (await ethers.getContractAt("Layer2ManagerV1_1", Layer2ManagerOldAddress, deployer)) as Layer2ManagerV1_1

            let seigniorageCommittee1 = await l1BridgeRegistryOld.seigniorageCommittee()
            console.log('seigniorageCommittee', seigniorageCommittee1)
            await (await l1BridgeRegistryOld.connect(daoAdmin).setSeigniorageCommittee(seigniorageCommitteeAddress)).wait()
            seigniorageCommittee1 = await l1BridgeRegistryOld.seigniorageCommittee()

            let totalLayer2TVL = await seigManager.totalLayer2TVL()

            // let titan = "0x501C74df1aDEb8024738D880B01306a92d6e722d"
            let thanosSepolia = "0x6eF61974A3CDa7BbD0a4DD0A613f56d211c8AfDC"

            let rollup = thanosSepolia
            let info = await Layer2ManagerOld.rollupConfigInfo(rollup)
            console.log(info)

            if (info.status == 1) {
                await (await l1BridgeRegistryOld.connect(seigniorageCommittee).rejectCandidateAddOn(rollup)).wait()
                totalLayer2TVL = await seigManager.totalLayer2TVL()
                console.log('totalLayer2TVL reject ThanosSepolia', totalLayer2TVL)
            }

            expect(await seigManager.totalLayer2TVL()).to.be.eq(ethers.constants.Zero)

            await (await l1BridgeRegistryOld.connect(daoAdmin).setSeigniorageCommittee(ethers.constants.AddressZero)).wait()

        }).timeout(10000);

        it('Initialize of seigManager', async () => {

            await (await seigManager.connect(daoOwner).setL1BridgeRegistry(ethers.constants.AddressZero)).wait()
            await (await seigManager.connect(daoOwner).setLayer2Manager(ethers.constants.AddressZero)).wait()
            await (await seigManager.connect(daoOwner).setLayer2StartBlock(ethers.constants.Zero)).wait()
            await (await seigManager.connect(daoOwner).resetL2RewardPerUint()).wait()

            expect(await seigManager.layer2Manager()).to.be.eq(ethers.constants.AddressZero)
            expect(await seigManager.l1BridgeRegistry()).to.be.eq(ethers.constants.AddressZero)
            expect(await seigManager.layer2StartBlock()).to.be.eq(ethers.constants.Zero)
            expect(await seigManager.l2RewardPerUint()).to.be.eq(ethers.constants.Zero)

            expect(await seigManager.totalLayer2TVL()).to.be.eq(ethers.constants.Zero)

        }).timeout(10000);

    })

    describe('# Contracts from deployments', () => {
        it('deployments', async () => {
            await deployments.fixture();
            let deployed = await deployments.all()
            // console.log(deployed)

            l1BridgeRegistryProxy = (await ethers.getContractAt("L1BridgeRegistryProxy", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryProxy
            l1BridgeRegistry = (await ethers.getContractAt("L1BridgeRegistryV1_1", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryV1_1
            operatorManagerFactory = (await ethers.getContractAt("OperatorManagerFactory", deployed.OperatorManagerFactory.address, deployer)) as OperatorManagerFactory;
            candidateAddOnFactoryProxy = (await ethers.getContractAt("CandidateAddOnFactoryProxy", deployed.CandidateAddOnFactoryProxy.address, deployer)) as CandidateAddOnFactoryProxy;
            candidateAddOnFactory = (await ethers.getContractAt("CandidateAddOnFactory", deployed.CandidateAddOnFactoryProxy.address, deployer)) as CandidateAddOnFactory;

            layer2ManagerProxy = (await ethers.getContractAt("Layer2ManagerProxy", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerProxy;
            layer2Manager = (await ethers.getContractAt("Layer2ManagerV1_1", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerV1_1;

            seigManagerV1_2 = (await ethers.getContractAt("SeigManagerV1_2", deployed.SeigManagerV1_2.address, deployer)) as SeigManagerV1_2;
            seigManagerV1_3 = (await ethers.getContractAt("SeigManagerV1_3", deployed.SeigManagerV1_3.address, deployer)) as SeigManagerV1_3;
            depositManagerV1_1 = (await ethers.getContractAt("DepositManagerV1_1", deployed.DepositManagerV1_1.address, deployer)) as DepositManagerV1_1;
            daoCommitteeProxy2Contract = (await ethers.getContractAt("DAOCommitteeProxy2", deployed.DAOCommitteeProxy2.address, deployer)) as DAOCommitteeProxy2;
            daoCommitteeOwner = (await ethers.getContractAt("DAOCommitteeOwner", deployed.DAOCommitteeOwner.address, deployer)) as DAOCommitteeOwner;
            daoCommittee_V1 = (await ethers.getContractAt("DAOCommittee_V1", deployed.DAOCommittee_V1.address, deployer)) as DAOCommittee_V1;
            legacySystemConfig = (await ethers.getContractAt("LegacySystemConfig", deployed.LegacySystemConfigProxy.address, deployer )) as LegacySystemConfig;

            // console.log('l1BridgeRegistryProxy', l1BridgeRegistryProxy.address)
            // console.log('l1BridgeRegistry', l1BridgeRegistry.address)
            // console.log('operatorManagerFactory', operatorManagerFactory.address)

            // console.log('candidateAddOnFactoryProxy', candidateAddOnFactoryProxy.address)
            // console.log('candidateAddOnFactory', candidateAddOnFactory.address)

            // console.log('candidateAddOnFactoryProxy', candidateAddOnFactoryProxy.address)
            // console.log('candidateAddOnFactory', candidateAddOnFactory.address)

            // console.log('seigManagerV1_2', seigManagerV1_2.address)
            // console.log('seigManagerV1_3', seigManagerV1_3.address)
            // console.log('depositManagerV1_1', depositManagerV1_1.address)
            // console.log('daoCommitteeProxy2Contract', daoCommitteeProxy2Contract.address)
            // console.log('daoCommitteeOwner', daoCommitteeOwner.address)
            // console.log('daoCommittee_V1', daoCommittee_V1.address)


            let temp_seigniorageCommitteeAddress = await l1BridgeRegistry.seigniorageCommittee();

            if (temp_seigniorageCommitteeAddress != ethers.constants.AddressZero &&
                temp_seigniorageCommitteeAddress.toLowerCase() != seigniorageCommitteeAddress.toLowerCase())
            {
                seigniorageCommitteeAddress = temp_seigniorageCommitteeAddress;

                await hre.network.provider.send("hardhat_impersonateAccount", [
                    seigniorageCommitteeAddress,
                ]);
                await hre.network.provider.send("hardhat_setBalance", [
                    seigniorageCommitteeAddress,
                    "0x10000000000000000000000000",
                ]);
                seigniorageCommittee = await hre.ethers.getSigner(seigniorageCommitteeAddress);
            }


        }).timeout(100000);
    })

    // describe('# TransferOwner to DAOCommittee ', () => {

    //     it('CandidateAddOnFactoryProxy ', async () => {
    //         const {DAOCommitteeProxy} = await getNamedAccounts();
    //         await (await candidateAddOnFactoryProxy.connect(deployer).transferOwnership(DAOCommitteeProxy)).wait()

    //         expect(await candidateAddOnFactoryProxy.isAdmin(deployer.address)).to.be.eq(false)
    //         expect(await candidateAddOnFactoryProxy.isAdmin(DAOCommitteeProxy)).to.be.eq(true)
    //     });

    //     it('operatorManagerFactory ', async () => {
    //         const {DAOCommitteeProxy} = await getNamedAccounts();
    //         await (await operatorManagerFactory.connect(deployer).transferOwnership(DAOCommitteeProxy)).wait()
    //         expect(await operatorManagerFactory.owner()).to.be.eq(DAOCommitteeProxy)
    //     });

    //     it('L1BridgeRegistryProxy ', async () => {
    //         const {DAOCommitteeProxy} = await getNamedAccounts();
    //         await (await l1BridgeRegistryProxy.connect(deployer).transferAdmin(DAOCommitteeProxy)).wait()
    //         expect(await l1BridgeRegistryProxy.isAdmin(deployer.address)).to.be.eq(false)
    //         expect(await l1BridgeRegistryProxy.isAdmin(DAOCommitteeProxy)).to.be.eq(true)
    //     });

    //     it('Layer2ManagerProxy ', async () => {
    //         const {DAOCommitteeProxy} = await getNamedAccounts();
    //         await (await layer2ManagerProxy.connect(deployer).transferOwnership(DAOCommitteeProxy)).wait()
    //         expect(await layer2ManagerProxy.isAdmin(deployer.address)).to.be.eq(false)
    //         expect(await layer2ManagerProxy.isAdmin(DAOCommitteeProxy)).to.be.eq(true)
    //     });
    // })

    ///--- Agenda ---------------------------------
    describe('# Agenda', () => {

        it('Submit an agenda', async () => {
            const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, DAOAgendaManager } = await getNamedAccounts();

            let targets = []
            let params = []
            let callDtata

            // =========================================
            // 1. upgradeTO daoCommitteeProxy2Contract
            targets.push(DAOCommitteeProxy)
            callDtata = depositManagerProxy.interface.encodeFunctionData("upgradeTo", [daoCommitteeProxy2Contract.address])
            params.push(callDtata)

            // =========================================
            // 2. upgradeTo2 daoCommittee_V1
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("upgradeTo2", [daoCommittee_V1.address])
            params.push(callDtata)

            // =========================================
            // 3. setImplementation2 1, true, daoCommitteeOwner
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("setImplementation2", [daoCommitteeOwner.address, 1, true])
            params.push(callDtata)

            // =========================================
            // 4. setSelectorImplementations2  daoCommitteeOwner
            const _setLayer2CandidateFactory = encodeFunctionSignature("setCandidateAddOnFactory(address)");
            const _setLayer2Manager = encodeFunctionSignature("setLayer2Manager(address)");
            const _setTargetSetLayer2Manager = encodeFunctionSignature("setTargetSetLayer2Manager(address,address)");
            const _setTargetSetL2Registry = encodeFunctionSignature("setTargetSetL1BridgeRegistry(address,address)");
            const _setTargetLayer2StartBlock = encodeFunctionSignature("setTargetLayer2StartBlock(address,uint256)");
            const _setTargetSetImplementation2 = encodeFunctionSignature("setTargetSetImplementation2(address,address,uint256,bool)");
            const _setTargetSetSelectorImplementations2 = encodeFunctionSignature("setTargetSetSelectorImplementations2(address,bytes4[],address)");

            const _setSeigManager = encodeFunctionSignature("setSeigManager(address)");
            const _setTargetSeigManager = encodeFunctionSignature("setTargetSeigManager(address,address)")
            const _setSeigPause = encodeFunctionSignature("setSeigPause()")
            const _setSeigUnpause = encodeFunctionSignature("setSeigUnpause()")
            const _setTargetGlobalWithdrawalDelay = encodeFunctionSignature("setTargetGlobalWithdrawalDelay(addres,uint256)")
            const _setTargetAddMinter = encodeFunctionSignature("setTargetAddMinter(address,address)")
            const _setTargetUpgradeTo = encodeFunctionSignature("setTargetUpgradeTo(address,address)")
            const _setTargetSetTON = encodeFunctionSignature("setTargetSetTON(address,address)")
            const _setTargetSetWTON = encodeFunctionSignature("setTargetSetWTON(address,address)")
            const _setDaoVault = encodeFunctionSignature("setDaoVault(address)")
            const _setLayer2Registry = encodeFunctionSignature("setLayer2Registry(address)")
            const _setAgendaManager = encodeFunctionSignature("setAgendaManager(address)")
            const _setCandidateFactory = encodeFunctionSignature("setCandidateFactory(address)")
            const _setTon = encodeFunctionSignature("setTon(address)")
            const _setWton = encodeFunctionSignature("setWton(address)")
            const _setActivityRewardPerSecond = encodeFunctionSignature("setActivityRewardPerSecond(uint256)")
            const _setCandidatesSeigManager = encodeFunctionSignature("setCandidatesSeigManager(address[],address)")
            const _setCandidatesCommittee = encodeFunctionSignature("setCandidatesCommittee(address[],address)")
            const _setCreateAgendaFees = encodeFunctionSignature("setCreateAgendaFees(uint256)")
            const _setMinimumNoticePeriodSeconds = encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)")
            const _setMinimumVotingPeriodSeconds = encodeFunctionSignature("setMinimumVotingPeriodSeconds(uint256)")
            const _setExecutingPeriodSeconds = encodeFunctionSignature("setExecutingPeriodSeconds(uint256)")
            const _increaseMaxMember = encodeFunctionSignature("increaseMaxMember(uint256,uint256)")
            const _setQuorum = encodeFunctionSignature("setQuorum(uint256)")
            const _decreaseMaxMember = encodeFunctionSignature("decreaseMaxMember(uint256,uint256)")
            const _setBurntAmountAtDAO = encodeFunctionSignature("setBurntAmountAtDAO(uint256)")

            const functions = [
                _setLayer2CandidateFactory,_setLayer2Manager,_setTargetSetLayer2Manager,_setTargetSetL2Registry,
                _setTargetLayer2StartBlock,_setTargetSetImplementation2,_setTargetSetSelectorImplementations2,
                _setSeigManager,_setTargetSeigManager,_setSeigPause,_setSeigUnpause,
                _setTargetGlobalWithdrawalDelay,_setTargetAddMinter,_setTargetUpgradeTo,_setTargetSetTON,_setTargetSetWTON,
                _setDaoVault,_setLayer2Registry,_setAgendaManager,_setCandidateFactory,_setTon,_setWton,
                _increaseMaxMember,_setQuorum,_decreaseMaxMember,_setBurntAmountAtDAO,
                _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setCreateAgendaFees,
                _setMinimumNoticePeriodSeconds,_setMinimumVotingPeriodSeconds,_setExecutingPeriodSeconds
            ]

            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData(
                "setSelectorImplementations2", [
                    functions,
                    daoCommitteeOwner.address
                 ])
            params.push(callDtata)


            // =========================================
            //  upgrade SeigManager SeigManagerV1_2
            targets.push(seigManagerProxy.address)
            callDtata = seigManagerProxy.interface.encodeFunctionData("upgradeTo",
                [
                    seigManagerV1_2.address,
                ])
            params.push(callDtata)


            // =========================================
            //  upgrade SeigManager setTargetSetImplementation2
            targets.push(seigManagerProxy.address)
            callDtata = seigManagerProxy.interface.encodeFunctionData("setImplementation2",
                [
                    seigManagerV1_3.address,
                    1,
                    true
                ])
            params.push(callDtata)


            // =========================================
            //  upgrade SeigManager setTargetSetSelectorImplementations2
            targets.push(seigManagerProxy.address)

            const selector1 = encodeFunctionSignature("updateSeigniorage()");
            const selector2 = encodeFunctionSignature("updateSeigniorageLayer(address)");
            const selector3 = encodeFunctionSignature("estimatedDistribute(uint256,address)");
            const selector4 = encodeFunctionSignature("excludeFromL2Seigniorage(address)");
            const selector5 = encodeFunctionSignature("includeFromL2Seigniorage(address)");
            const selector6 = encodeFunctionSignature("claimableL2Seigniorage(address)");
            const selector7 = encodeFunctionSignature("pause()");
            const selector8 = encodeFunctionSignature("unpause()");


            let functionBytecodes = [
                selector1, selector2, selector3, selector4, selector5,
                selector6, selector7, selector8
            ];

            callDtata = seigManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
                [
                    functionBytecodes,
                    seigManagerV1_3.address
                ])
            params.push(callDtata)

            // =========================================
            //  upgrade DepositManager setTargetSetImplementation2
            targets.push(depositManagerProxy.address)
            callDtata = depositManagerProxy.interface.encodeFunctionData("setImplementation2",
                [
                    depositManagerV1_1.address,
                    3,
                    true
                ])
            params.push(callDtata)

            // =========================================
            //  upgrade DepositManager setTargetSetSelectorImplementations2
            targets.push(depositManagerProxy.address)
            const selector_1 = encodeFunctionSignature("ton()");
            const selector_2 = encodeFunctionSignature("minDepositGasLimit()");
            const selector_3 = encodeFunctionSignature("setMinDepositGasLimit(uint32)");
            const selector_4 = encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");
            const selector_5 = encodeFunctionSignature("l1BridgeRegistry()");
            const selector_6 = encodeFunctionSignature("layer2Manager()");
            const selector_7 = encodeFunctionSignature("setAddresses(address,address)");
            const selector_8 = encodeFunctionSignature("requestWithdrawal(address,uint256)");

            let functionBytecodes_1 = [ selector_1, selector_2, selector_3, selector_4, selector_5, selector_6, selector_7, selector_8];

            callDtata = depositManagerProxy.interface.encodeFunctionData("setSelectorImplementations2",
                [
                    functionBytecodes_1,
                    depositManagerV1_1.address

                ])
            params.push(callDtata)

            // =========================================
            //  set DAOCommitteeProxy candidateAddOnFactory
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeOwner.interface.encodeFunctionData("setCandidateAddOnFactory", [candidateAddOnFactory.address])
            params.push(callDtata)

            // =========================================
            //  set DAOCommitteeProxy layer2Manager
            targets.push(DAOCommitteeProxy)
            callDtata = daoCommitteeOwner.interface.encodeFunctionData("setLayer2Manager", [layer2Manager.address])
            params.push(callDtata)

            // =========================================
            //  set seigManagerProxy setLayer2Manager
            targets.push(seigManagerProxy.address)
            callDtata = seigManagerV1_2.interface.encodeFunctionData("setLayer2Manager", [layer2ManagerProxy.address])
            params.push(callDtata)

            // =========================================
            //  set seigManagerProxy setLayer2Manager
            targets.push(seigManagerProxy.address)
            callDtata = seigManagerV1_2.interface.encodeFunctionData("setL1BridgeRegistry", [l1BridgeRegistryProxy.address])
            params.push(callDtata)

            // =========================================
            //  set DAOCommitteeProxy setAddresses
            targets.push(depositManagerProxy.address)
            callDtata = depositManagerV1_1.interface.encodeFunctionData("setAddresses", [
                l1BridgeRegistryProxy.address,
                layer2Manager.address ])
            params.push(callDtata)

            // =========================================
            //  registerSystemConfigByManager  Titan
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();
            let name = 'Titan'
            targets.push(l1BridgeRegistry.address)
            callDtata = l1BridgeRegistry.interface.encodeFunctionData("registerRollupConfigByManager(address,uint8,address,string)", [ legacySystemConfig.address, 1,  l2TonAddress, name])
            params.push(callDtata)

            // =========================================
            //  registerSystemConfigByManager  Thanos
            const {thanosSepoliaSystemConfig, thanosL2TON } = await getNamedAccounts();
            name = 'Thanos-Sepolia'
            targets.push(l1BridgeRegistry.address)
            callDtata = l1BridgeRegistry.interface.encodeFunctionData(
                "registerRollupConfigByManager(address,uint8,address,string)",
                [ thanosSepoliaSystemConfig, 2,  thanosL2TON, name])
            params.push(callDtata)


            // // =========================================
            // //  l1BridgeRegistry  seigniorageCommittee
            // targets.push(l1BridgeRegistry.address)
            // callDtata = l1BridgeRegistry.interface.encodeFunctionData(
            //     "setSeigniorageCommittee(address)",
            //     [ seigniorageCommitteeAddress])
            // params.push(callDtata)


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
            const daoCommitteeContractV2 = new ethers.Contract(DAOCommitteeProxy, DAOCommitteeProxy2_Josn.abi,  deployer)
            const _setTargetSetImplementation2 = encodeFunctionSignature("setTargetSetImplementation2(address,address,uint256,bool)");
            let logic = await daoCommitteeContractV2.getSelectorImplementation2(_setTargetSetImplementation2)

            expect(logic).to.be.equal(daoCommitteeOwner.address)
            expect(await daoCommitteeContractV2.implementation2(1)).to.be.equal(daoCommitteeOwner.address)

            //-- check titan rollupConfig
            const {l2TonAddress } = await getNamedAccounts();
            let titanInfo = await l1BridgeRegistry.rollupInfo(legacySystemConfig.address)
            expect(titanInfo.l2TON).to.be.equal(l2TonAddress)
            expect(titanInfo.rejectedSeigs).to.be.equal(false)
            expect(titanInfo.rejectedSeigs).to.be.equal(false)
            expect(titanInfo.name).to.be.equal('Titan')

        })

    })

    ///---- After executing an agenda --------------------------------

    describe('# Titan checkLayer2TVL', () => {
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

    describe('# Thanos checkLayer2TVL', () => {
        it('If the rollupConfig or L1Bridge address does not exist, the result is returned as false.', async () => {
            const {thanosSepoliaL1StandardBridge } = await getNamedAccounts();
            let rollupConfig = thanosSepoliaL1StandardBridge

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

            const addr = tonHave
            let amount = await layer2Manager.minimumInitialDepositAmount();
            // amount = amount.add(ethers.utils.parseEther("0.1"))
            // console.log('amount', amount)

            let balance = await tonContract.balanceOf(addr.address)
            expect(balance).to.be.gt(amount)

            let allowance = await tonContract.allowance(addr.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr).approve(layer2Manager.address, amount);
            }

            const name = await legacySystemConfig.name()
            const operatorAddress = await operatorManagerFactory.getAddress(legacySystemConfig.address)

            const receipt = await (await layer2Manager.connect(addr).registerCandidateAddOn(
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

            // console.log('titanLayerAddress', titanLayerAddress)
            // console.log('titanLayerContract', titanLayerContract.address)
            // console.log('titanOperatorContract', titanOperatorContract.address)
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


        it('registerCandidateAddOn : thanosCandidateAddOn', async () => {
            const {thanosSepoliaSystemConfig } = await getNamedAccounts();
            expect((await layer2Manager.statusLayer2(thanosSepoliaSystemConfig))).to.be.eq(0)

            const addr = tonHave
            let amount = await layer2Manager.minimumInitialDepositAmount();
            // amount = amount.add(ethers.utils.parseEther("0.1"))
            // console.log('amount', amount)

            let balance = await tonContract.balanceOf(addr.address)
            expect(balance).to.be.gt(amount)

            let allowance = await tonContract.allowance(addr.address, layer2Manager.address)
            if(allowance.lt(amount)){
                await tonContract.connect(addr).approve(layer2Manager.address, amount);
            }

            let name = 'Thanos-Sepolia'
            const operatorAddress = await operatorManagerFactory.getAddress(thanosSepoliaSystemConfig)

            const receipt = await (await layer2Manager.connect(addr).registerCandidateAddOn(
                thanosSepoliaSystemConfig,
                amount,
                true,
                name
            )).wait()

            const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2Manager.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(thanosSepoliaSystemConfig)
            expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            expect(deployedEvent.args.memo).to.be.eq(name)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

            thanosLayerAddress = deployedEvent.args.candidateAddOn;
            thanosOperatorContractAddress = deployedEvent.args.operator;
            expect((await layer2Manager.statusLayer2(thanosSepoliaSystemConfig))).to.be.eq(1)

            thanosLayerContract =  (await ethers.getContractAt("CandidateAddOnV1_1", thanosLayerAddress, deployer)) as CandidateAddOnV1_1
            thanosOperatorContract = (await ethers.getContractAt("OperatorManagerV1_1", thanosOperatorContractAddress, deployer)) as OperatorManagerV1_1


            thanosSystemConfigContract = (new ethers.Contract(thanosSepoliaSystemConfig,  MockSystemConfig_Json.abi, deployer)) as MockSystemConfig
            let portal = await thanosSystemConfigContract.optimismPortal()
            // console.log('portal', portal)
            await tonContract.connect(tonMinter).mint(portal, utils.parseEther("2000000"))

            // console.log('thanosLayerAddress', thanosLayerAddress)
            // console.log('thanosLayerContract', thanosLayerContract.address)
            // console.log('thanosOperatorContract', thanosOperatorContract.address)

        })
    })

    describe('# DepositManager : Titan CandidateAddOn ', () => {

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
            let account = addr2
            let amount = ethers.utils.parseEther("30"+"0".repeat(9))

            await depositWithWton(
                thanosLayerAddress,
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

        it('deposit to thanosLayerAddress using deposit(address,address,uint256) ', async () => {

            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

            await depositWithWton2(
                thanosLayerAddress,
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

        it('seigManager: updateSeigniorageLayer : (1) updateSeigniorage to thanosLayerAddress ', async () => {
            await updateSeigniorageThanos();

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });


        it('seigManager: updateSeigniorageLayer : (2) updateSeigniorage to titanLayerAddress ', async () => {
            await updateSeigniorageTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer :  (3) updateSeigniorage to titanLayerAddress ', async () => {
            await updateSeigniorageTitan();

        })

        /* Titan is closed
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
            let globalWithdrawalDelay_l = await depositManager.withdrawalDelay(layer2)
            if (globalWithdrawalDelay.lt(globalWithdrawalDelay_l) ) globalWithdrawalDelay = globalWithdrawalDelay_l

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
        */

        it('requestWithdrawal to thanosLayerAddress', async () => {
            let layer2 = thanosLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            await requestWithdrawal (layer2, account, wtonAmount);


        }).timeout(100000000)

        it('processRequest to thanosLayerAddress will be fail when delay time didn\'t pass.', async () => {
            let layer2 = thanosLayerAddress
            let account = addr1

            await expect(
                    depositManager.connect(account)["processRequest(address,bool)"](
                    layer2,
                    true
                )
            ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

        });

        it('processRequest to thanosLayerAddress.', async () => {
            let layer2 = thanosLayerAddress
            let account = addr1

            await processRequest(layer2, account);
        });

    })

    // 기존의 다오 candidate 테스트
    describe('# DepositManager : DAOCandidate ', () => {

        it('deposit to layer1 using approveAndCall', async () => {
            let account = addr2
            let tonAmount = ethers.utils.parseEther("10")

            await depositApproveAndCall(layer2Info_1.layer2, account, tonAmount)

        })

        it('deposit to layer2 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = addr2
            let tonAmount = ethers.utils.parseEther("100")

            await depositApproveAndCall(layer2Info_2.layer2, account, tonAmount)

        })

        it('deposit to layer1 using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let account = addr1

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);

            await depositWithWton(
                layer2Info_1.layer2,
                account,
                wtonAmount
            );

        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {

            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);


            await depositWithWton2(
                layer2Info_2.layer2,
                account,
                wtonAmount
            );
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

            let unallocatedSeigniorage = await await seigManager.unallocatedSeigniorage();
            expect(stakeOfTotal.sub(stakeOfAllLayers)).to.be.eq(unallocatedSeigniorage);

        }).timeout(100000000);

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('updateSeigniorage to layer1', async () => {
            await updateSeigniorageLayer1();

        })

        it('requestWithdrawal to layer1', async () => {

            let layer2 = layer2Info_1.layer2
            let account = pastDepositor
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            await requestWithdrawal (layer2, account, wtonAmount);

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

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('processRequest to layer1.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = pastDepositor

            await processRequest(layer2, account);
        });
    })

    describe('# withdrawAndDepositL2 : Thanos LayerCandidate ', () => {

        it('deposit to Thanos using approveAndCall', async () => {

            let layerAddress = thanosLayerAddress
            let account = addr1
            let amount = ethers.utils.parseEther("200000")

            await depositApproveAndCall(
                layerAddress,
                account,
                amount
            );
        })


        it('deposit to layer1 using approveAndCall', async () => {
            let account = addr2
            let amount = ethers.utils.parseEther("200000")

            await depositApproveAndCall(
                layer2Info_1.layer2,
                account,
                amount
            );
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('withdrawAndDepositL2 : Not supported in DAOCandidate layer.', async () => {
            let layer2 = layer2Info_1.layer2
            let account = addr2
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

            await expect(depositManager.connect(account).withdrawAndDepositL2(
                layer2,
                wtonAmount
            )).to.be.revertedWith("OperatorError")

        })

        it('withdrawAndDepositL2 : Failure if the staking amount is insufficient', async () => {
            let layer = thanosLayerAddress
            let account = addr2
            let stakedA = await seigManager["stakeOf(address,address)"](layer, account.address)

            await expect(depositManager.connect(account).withdrawAndDepositL2(
                layer,
                stakedA.add(ethers.constants.One)
            )).to.be.revertedWith("staked amount is insufficient")
        })

        it('When you run it, deposit money to L2 immediately without delay blocks.', async () => {
            let layer = thanosLayerAddress
            let operatorContract = thanosOperatorContract

            let account = addr2

            let rollupConfig = await operatorContract.rollupConfig()
            expect(rollupConfig).to.be.not.eq(ethers.constants.AddressZero)

            let prevLayer2TVL = await l1BridgeRegistry.layer2TVL(rollupConfig)

            let stakedA = await seigManager["stakeOf(address,address)"](layer, account.address)
            let amount = stakedA.div(BigNumber.from("4"))
            let receipt = await (await depositManager.connect(account).withdrawAndDepositL2(
                layer,
                amount
            )).wait()

            const topic = depositManager.interface.getEventTopic('WithdrawalAndDeposited');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = depositManager.interface.parseLog(log);
            expect(deployedEvent.args.layer2).to.be.eq(layer)
            expect(deployedEvent.args.account).to.be.eq(account.address)
            expect(deployedEvent.args.amount).to.be.eq(amount)

            let stakedB = await seigManager["stakeOf(address,address)"](layer, account.address)
            expect(stakedB).to.be.eq(stakedA.sub(amount))

            const afterTonBalance = await tonContract.balanceOf(depositManager.address);
            expect(await l1BridgeRegistry.layer2TVL(rollupConfig)).to.be.eq(
                prevLayer2TVL.add(amount.div(BigNumber.from("1000000000"))))

        })
    })


    describe('# reject CandidateAddOn : L1BridgeRegistry ', () => {
        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('reject CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.not.eq(addr1.address)
            await expect(
                l1BridgeRegistry.connect(addr1).rejectCandidateAddOn(
                    legacySystemConfig.address
                )
            ).to.be.revertedWith("PermissionError")
        })

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

        // it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
        //     await restoreCandidateTitan();
        // })

        // it('evm_mine', async () => {
        //     ethers.provider.send("evm_increaseTime", [60*60*24*7])
        //     ethers.provider.send("evm_mine");
        // });
    })


    describe('# DepositManager : CandidateAddOn : thanosCandidateAddOn ', () => {

        it('Layer2Contract:  updateSeigniorage to thanosLayerAddress ', async () => {

            await updateSeigniorageThanos();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });


        it('Layer2Contract:  updateSeigniorage to thanosLayerAddress ', async () => {

            await updateSeigniorageThanos();
        })


    })

    describe('# restore CandidateAddOn : L1BridgeRegistry ', () => {

        it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.not.eq(addr1.address)
            await expect(
                l1BridgeRegistry.connect(addr1).restoreCandidateAddOn(
                    legacySystemConfig.address,
                    false
                )
            ).to.be.revertedWith("PermissionError")
        })

        it('restore CandidateAddOn (titanCandidateAddOn) : Only rejected layers can be restored.', async () => {
            const {thanosSystemConfig, thanosL2TON } = await getNamedAccounts();

            expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
            expect(await l1BridgeRegistry.rejectRollupConfig(thanosSystemConfig)).to.be.eq(false)
            await expect(
                l1BridgeRegistry.connect(seigniorageCommittee).restoreCandidateAddOn(
                    thanosSystemConfig,
                    false
                )
            ).to.be.revertedWith("OnlyRejectedError")
        })

        it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {

            await restoreCandidateTitan();
        })

    })

    describe('# DepositManager : CandidateAddOn : titanCandidateAddOn ', () => {

        it('seigManager: updateSeigniorageLayer : (1) updateSeigniorage to titanLayerAddress', async () => {

            await updateSeigniorageTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : (2) updateSeigniorage to titanLayerAddress ', async () => {
            await updateSeigniorageTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage : (3) updateSeigniorage to titanLayerAddress  ', async () => {
            await updateSeigniorageTitan();

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });
    })

    describe('# DepositManager : CandidateAddOn : titanCandidateAddOn ', () => {

        it('seigManager: updateSeigniorageLayer :  updateSeigniorage to titanCandidateAddOn  ', async () => {

            await updateSeigniorageTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer :  updateSeigniorage to titanCandidateAddOn ', async () => {
            await updateSeigniorageTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('seigManager: updateSeigniorageLayer :  updateSeigniorage to titanCandidateAddOn ', async () => {
            await updateSeigniorageTitan();

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage :  updateSeigniorage to titanCandidateAddOn  ', async () => {
            await updateSeigniorageTitan();
        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });

        it('Layer2Contract: updateSeigniorage :  updateSeigniorage to titanCandidateAddOn ', async () => {
            await updateSeigniorageTitan();

        })
        /* Titan is closed
        it('requestWithdrawal to titanLayerAddress', async () => {
             let layerAddress = titanLayerAddress
            let operatorContractAddress = titanOperatorContractAddress
            let layerContract = titanLayerContract
            let operatorContract = titanOperatorContract
            let operatorOwner = titanManager

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

        }).timeout(100000000)

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
            let globalWithdrawalDelay_l = await depositManager.withdrawalDelay(layer2)
            if (globalWithdrawalDelay.lt(globalWithdrawalDelay_l) ) globalWithdrawalDelay = globalWithdrawalDelay_l

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
        */
    })

    // 기존의 다오 candidate 테스트
    describe('# DepositManager : DAOCandidate ', () => {

        it('deposit to layer1 using approveAndCall', async () => {

            let account = addr2
            let tonAmount = ethers.utils.parseEther("100")

            await depositApproveAndCall(layer2Info_1.layer2, account, tonAmount)

        })

        it('deposit to layer2 using approveAndCall', async () => {
            let account = addr2
            let tonAmount = ethers.utils.parseEther("100")

            await depositApproveAndCall(layer2Info_2.layer2, account, tonAmount)
        })

        it('deposit to layer1 using deposit(address,uint256)', async () => {
            let account = addr1

            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);

            await depositWithWton(
                layer2Info_1.layer2,
                account,
                wtonAmount
            );
        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);


            await depositWithWton2(
                layer2Info_2.layer2,
                account,
                wtonAmount
            );
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

            let unallocatedSeigniorage = await await seigManager.unallocatedSeigniorage();
            expect(stakeOfTotal.sub(stakeOfAllLayers)).to.be.eq(unallocatedSeigniorage);
        });

        it('updateSeigniorage to layer1', async () => {
            await updateSeigniorageLayer1();
        })

        it('requestWithdrawal to layer1', async () => {

            let layer2 = layer2Info_1.layer2
            let account = pastDepositor
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            await requestWithdrawal (layer2, account, wtonAmount);
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

            await processRequest(layer2, account);
        });

    })

});


