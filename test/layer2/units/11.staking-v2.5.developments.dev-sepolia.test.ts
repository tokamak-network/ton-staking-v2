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
import { DepositManagerV1_1 } from "../../../typechain-types/contracts/stake/managers/DepositManagerV1_1.sol"
import { Layer2Registry } from "../../../typechain-types/contracts/stake/Layer2Registry"

import { DAOCommitteeProxy2 } from "../../../typechain-types/contracts/proxy/DAOCommitteeProxy2"
import { DAOCommittee_V1 } from "../../../typechain-types/contracts/dao/DAOCommittee_V1"
import { DAOCommitteeOwner } from "../../../typechain-types/contracts/dao/DAOCommitteeOwner"
import { Candidate } from "../../../typechain-types/contracts/dao/Candidate"

import { MockSystemConfigFactory } from "../../../typechain-types/contracts/mocks/MockSystemConfigFactory.sol"
import { MockSystemConfig } from "../../../typechain-types/contracts/mocks/MockSystemConfig.sol"
import { Faucetv2 } from "../../../typechain-types/contracts/mocks/Faucetv2"
import { MockLayer2 } from "../../../typechain-types/contracts/mocks/MockLayer2"

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

import DAOCommitteeProxy_JSON from '../../abi/DAOCommitteeProxy.json'
import MultiSigWallet_JSON from '../../abi/MultiSigWallet.json'
import DAOAgendaManager_JSON from '../../abi/DAOAgendaManager.json'
import DAOVault_JSON from '../../abi/DAOVault.json'
import { CompilationJobCreationErrorReason } from 'hardhat/types'

let tonHaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

const daoOwnerAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinterAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinter: Signer
let seigniorageCommitteeAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let seigniorageCommittee: Signer

let thanosSystemConfigOwnerAddress = "0x9E628CaAd7A6dD3ce48E78812241B41BdbeF6244"
let thanosSystemConfigOwner: Signer
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

describe('DEV Staking V2.5 Test On Sepolia', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1


    let legacySystemConfig: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorManagerV1_1:OperatorManagerV1_1 , operatorManagerFactory: OperatorManagerFactory

    let candidateAddOnV1_1Imp: CandidateAddOnV1_1
    let candidateAddOnFactoryImp:CandidateAddOnFactory , candidateAddOnFactoryProxy: CandidateAddOnFactoryProxy, candidateAddOnFactory: CandidateAddOnFactory
    let tonContract: Contract, wtonContract: Contract, faucetContract: Faucetv2
    let daoCommitteeProxy: Contract, daoContract: Contract, daoV2Contract: Contract, daoAgendaManager: Contract

    let depositManager: Contract,  depositManagerProxy: Contract;
    let seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3, seigManagerV1_2: SeigManagerV1_2;
    let depositManagerV1_1: DepositManagerV1_1;
    let layer2Registry: Layer2Registry;


    let daoAdmin: Signer;
    let daoOwner: Signer;
    let tonMinter: Signer;
    let titanManager: Signer;
    let thanosManager: Signer;
    let layer2Operator: Signer;

    let titanLayerAddress: string, titanOperatorContractAddress: string;
    let titanLayerContract: CandidateAddOnV1_1;
    let titanOperatorContract: OperatorManagerV1_1

    let thanosLayerAddress: string, thanosOperatorContractAddress: string;
    let thanosLayerContract: CandidateAddOnV1_1;
    let thanosOperatorContract: OperatorManagerV1_1

    let wtonHave:Signer, tonHave:Signer

    let daoAgendaManagerContract: Contract
    let daoCommitteeProxy2Contract: DAOCommitteeProxy2
    let daoCommittee_V1: DAOCommittee_V1
    let daoCommitteeOwner: DAOCommitteeOwner
    let daoCommitteeContract:  Contract
    let agendaId: BigNumber

    interface CandidateType {
        address: string,
        contract: Candidate | CandidateAddOnV1_1 | any,
        layer2: MockLayer2 | any
    }

    let candidate1 : CandidateType
    let candidateAddOn1 : CandidateType
    let layer2Candidate1 : CandidateType
    let mockLayer2: MockLayer2


    async function checkBalanceTon(account: Signer, amount: BigNumber) {
        const tonBalance = await tonContract.balanceOf(account.address)
        if (tonBalance.lt(amount)) {
            await (await faucetContract.connect(deployer).transferToken1(account.address, amount)).wait()
        }
    }

    async function checkBalanceWton(account: Signer, amount: BigNumber) {
        const wtonBalance = await wtonContract.balanceOf(account.address)

        if (wtonBalance.lt(amount)) {
            await (await faucetContract.connect(deployer).transferToken2(account.address, amount)).wait()
        }
    }

    /// layer1 에서 업데이트 시뇨리지를 실행할때의 테스트입니다.
    async function updateSeigniorageLayer1(layer2Address: string ) {

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

        let stakedA = await seigManager["stakeOf(address,address)"](layer2Address, addr1.address)

        // let powerTonBalance = await wtonContract.balanceOf(powerTon);

        let layer2RewardInfoTitanPrev = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        const totalTvl = await seigManager.totalLayer2TVL()

        // console.log('\n updateSeigniorage... ', layer2Address )

        const receipt = await (await seigManager.connect(addr1).updateSeigniorageLayer(layer2Address)).wait()

        const topic = seigManager.interface.getEventTopic('CommitLog1');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        // console.log('\n totalStakedAmount : ',  ethers.utils.formatUnits(deployedEvent.args.totalStakedAmount,27) , 'WTON' )
        // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

        let stakedB = await seigManager["stakeOf(address,address)"](layer2Address, addr1.address)

        expect(stakedB).to.be.gt(stakedA)

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


    /// layer1 에서 업데이트 시뇨리지를 실행할때의 테스트입니다.
    async function updateSeigniorageLayer2(layer2: MockLayer2) {

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

        let stakedA = await seigManager["stakeOf(address,address)"](layer2.address, addr1.address)

        // let powerTonBalance = await wtonContract.balanceOf(powerTon);

        let layer2RewardInfoTitanPrev = await seigManager.getLayer2RewardInfo(titanLayerAddress)
        const totalTvl = await seigManager.totalLayer2TVL()

        const receipt = await (await layer2.connect(addr1).updateSeigniorage()).wait()

        const topic = seigManager.interface.getEventTopic('CommitLog1');
        const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        const deployedEvent = seigManager.interface.parseLog(log);
        // console.log('\n totalStakedAmount : ',  ethers.utils.formatUnits(deployedEvent.args.totalStakedAmount,27) , 'WTON' )
        // console.log('\n nextTotalSupply : ',  ethers.utils.formatUnits(deployedEvent.args.nextTotalSupply,27) , 'WTON' )

        let stakedB = await seigManager["stakeOf(address,address)"](layer2.address, addr1.address)

        expect(stakedB).to.be.gt(stakedA)

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
        await checkBalanceTon(account, amount);

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

    /// 스테이킹을 approve and call 함수를 wton을 이용하여 합니다.
    async function depositApproveAndCallWithWton(layerAddress: string, account: Signer, wtonAmount:BigNumber ) {

        // let layerAddress = thanosLayerAddress
        // let account = addr2

        // let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
        await checkBalanceWton(account, wtonAmount);

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

        await checkBalanceWton(account, wtonAmount);

        const beforeBalance = await wtonContract.balanceOf(account.address);
        expect(beforeBalance).to.be.gte(wtonAmount)

        await execAllowance(wtonContract, account, depositManager.address, wtonAmount);

        let stakedA = await seigManager["stakeOf(address,address)"](layerAddress, account.address)

        await (await depositManager.connect(account)["deposit(address,uint256)"](
            layerAddress,
            wtonAmount
        )).wait()

        const afterBalance = await wtonContract.balanceOf(account.address);
        expect(afterBalance).to.be.eq(beforeBalance.sub(wtonAmount))

        let stakedB = await seigManager["stakeOf(address,address)"](layerAddress, account.address)

        expect(roundDown(stakedB.add(ethers.constants.Two),3)).to.be.eq(
            roundDown(stakedA.add(wtonAmount), 3)
        )
    }

    /// 레이어에서 wton으로 스테이킹을 다른 사람에게 합니다.
    async function depositWithWton2(layerAddress: string, account: Signer, wtonAmount:BigNumber ) {

        await checkBalanceWton(account, wtonAmount);


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
        const { TON, WTON } = await getNamedAccounts();

        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        manager = accounts[1]
        addr1 = accounts[2]
        addr2 = accounts[3]
        layer2Operator = addr2

        daoOwner = await ethers.getSigner(daoOwnerAddress);

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

        tonMinter = daoOwner

    })



    describe('# Contracts from deployments', () => {
        it('deployments', async () => {
            await deployments.fixture();
            let deployed = await deployments.all()
            // console.log(deployed)

            tonContract = new ethers.Contract(deployed.TON.address, Ton_Json.abi,  deployer)
            wtonContract = new ethers.Contract(deployed.WTON.address,  Wton_Json.abi, deployer)

            faucetContract = await ethers.getContractAt("Faucetv2", deployed.Faucetv2.address, deployer) as Faucetv2

            daoCommitteeProxy = new ethers.Contract(deployed.DAOCommitteeProxy.address,  DAOCommitteeProxy_JSON.abi, deployer)
            daoCommitteeContract = new ethers.Contract(deployed.DAOCommitteeProxy.address, DAOCommittee_V1_Json.abi,  deployer)
            daoAgendaManagerContract = new ethers.Contract(deployed.DAOAgendaManager.address, DAOAgendaManager_JSON.abi,  deployer)

            l1BridgeRegistryProxy = (await ethers.getContractAt("L1BridgeRegistryProxy", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryProxy
            l1BridgeRegistry = (await ethers.getContractAt("L1BridgeRegistryV1_1", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryV1_1
            operatorManagerFactory = (await ethers.getContractAt("OperatorManagerFactory", deployed.OperatorManagerFactory.address, deployer)) as OperatorManagerFactory;
            candidateAddOnFactoryProxy = (await ethers.getContractAt("CandidateAddOnFactoryProxy", deployed.CandidateAddOnFactoryProxy.address, deployer)) as CandidateAddOnFactoryProxy;
            candidateAddOnFactory = (await ethers.getContractAt("CandidateAddOnFactory", deployed.CandidateAddOnFactoryProxy.address, deployer)) as CandidateAddOnFactory;

            layer2ManagerProxy = (await ethers.getContractAt("Layer2ManagerProxy", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerProxy;
            layer2Manager = (await ethers.getContractAt("Layer2ManagerV1_1", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerV1_1;

            layer2Registry = (await ethers.getContractAt("Layer2Registry", deployed.Layer2RegistryProxy.address, deployer)) as Layer2Registry;

            seigManagerV1_2 = (await ethers.getContractAt("SeigManagerV1_2", deployed.SeigManagerProxy.address, deployer)) as SeigManagerV1_2;
            seigManagerV1_3 = (await ethers.getContractAt("SeigManagerV1_3", deployed.SeigManagerProxy.address, deployer)) as SeigManagerV1_3;
            seigManager = new ethers.Contract(deployed.SeigManagerProxy.address,  SeigManager_Json.abi, deployer)
            depositManagerV1_1 = (await ethers.getContractAt("DepositManagerV1_1", deployed.DepositManagerProxy.address, deployer)) as DepositManagerV1_1;
            depositManager = (await ethers.getContractAt("DepositManager", deployed.DepositManagerProxy.address, deployer)) as DepositManagerV1_1;

            daoCommitteeProxy2Contract = (await ethers.getContractAt("DAOCommitteeProxy2", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommitteeProxy2;
            daoCommitteeOwner = (await ethers.getContractAt("DAOCommitteeOwner", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommitteeOwner;
            daoCommittee_V1 = (await ethers.getContractAt("DAOCommittee_V1", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommittee_V1;
            // legacySystemConfig = (await ethers.getContractAt("LegacySystemConfig", deployed.LegacySystemConfigProxy.address, deployer )) as LegacySystemConfig;

            // console.log('daoCommitteeProxy', daoCommitteeProxy.address)
            // console.log('daoAgendaManagerContract', daoAgendaManagerContract.address)

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


            //==
            await hre.network.provider.send("hardhat_impersonateAccount", [
                daoCommitteeProxy.address,
            ]);
            await hre.network.provider.send("hardhat_setBalance", [
                daoCommitteeProxy.address,
                "0x10000000000000000000000000",
            ]);
            manager =  await hre.ethers.getSigner(daoCommitteeProxy.address);


        }).timeout(100000);
    })

    describe('# Tester', () => {
        it('faucet ton', async () => {

            await (await faucetContract.connect(addr1).requestTokens()).wait();
            await (await faucetContract.connect(addr2).requestTokens()).wait();
            await (await faucetContract.connect(tonHave).requestTokens()).wait();
            await (await faucetContract.connect(wtonHave).requestTokens()).wait();

            await (await faucetContract.connect(addr1).requestTokens()).wait();
            await (await faucetContract.connect(addr2).requestTokens()).wait();
            await (await faucetContract.connect(tonHave).requestTokens()).wait();
            await (await faucetContract.connect(wtonHave).requestTokens()).wait();

        }).timeout(10000);
    })

    describe('# createCandidate ', () => {
        it('Candidate ', async () => {

            const memo = "Candidate1"
            const receipt = await (await daoCommitteeContract.connect(addr1).createCandidate(
                memo
            )).wait()

            const topic = daoCommitteeContract.interface.getEventTopic('CandidateContractCreated');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = daoCommitteeContract.interface.parseLog(log);

            const candidateContract = new ethers.Contract(
                deployedEvent.args.candidateContract, DAOCandidate_Json.abi, deployer) as Candidate

            expect(deployedEvent.args.candidate).to.be.eq(addr1.address)
            expect(deployedEvent.args.candidateContract).to.be.eq(candidateContract.address)
            expect(deployedEvent.args.memo).to.be.eq(memo)

            candidate1 = {
                address : deployedEvent.args.candidateContract,
                contract: candidateContract,
                layer2: null
            }

        });

    })

    describe('# MockLayer2 registerLayer2CandidateByOwner ', () => {
        it('MockLayer2 ', async () => {
            mockLayer2 = (await (await ethers.getContractFactory("MockLayer2")).connect(layer2Operator).deploy(
                seigManager.address
            )) as MockLayer2;
        });

        it('registerAndDeployCoinage ', async () => {

            await (await layer2Registry.connect(layer2Operator).registerAndDeployCoinage(
                mockLayer2.address,
                seigManager.address
            )).wait()

        });

        it('Operators must stake at least 1000.1 TON', async () => {
            let layer2 = mockLayer2.address
            let account = layer2Operator
            let tonAmount = ethers.utils.parseEther("1000.1")

            await depositApproveAndCall(layer2, account, tonAmount)

        })

        it('registerLayer2CandidateByOwner ', async () => {
            const memo = "MockLayer2"

            const receipt = await (await daoCommitteeContract.connect(deployer).registerLayer2CandidateByOwner(
                layer2Operator.address,
                mockLayer2.address,
                memo
            )).wait()

            const topic = daoCommitteeContract.interface.getEventTopic('Layer2Registered');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = daoCommitteeContract.interface.parseLog(log);

            const candidateContract = new ethers.Contract(
                deployedEvent.args.candidateContract, DAOCandidate_Json.abi, deployer) as Candidate

            expect(deployedEvent.args.candidate).to.be.eq(mockLayer2.address)
            expect(deployedEvent.args.candidateContract).to.be.eq(candidateContract.address)
            expect(deployedEvent.args.memo).to.be.eq(memo)

            layer2Candidate1 = {
                address : deployedEvent.args.candidateContract,
                contract: candidateContract,
                layer2: mockLayer2
            }
        });
    })


    describe('# l1BridgeRegistry. registerRollupConfigByManager : Titan ', () => {

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

        it('transfer TON to LegacySystemConfig ', async () => {
            const { l1BridgeAddress, l2TonAddress } = await getNamedAccounts();

            const amount = hre.ethers.utils.parseEther("1000000")
            await (await faucetContract.connect(deployer).transferToken1(l1BridgeAddress, amount)).wait()
        })

        it('transfer WTON to LegacySystemConfig ', async () => {
            const {thanosSepoliaOptimismPortal } = await getNamedAccounts();

            const amount = hre.ethers.utils.parseEther("2000000")
            await (await faucetContract.connect(deployer).transferToken1(thanosSepoliaOptimismPortal, amount)).wait()
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

    describe('# l1BridgeRegistry. registerRollupConfigByManager : Thanos ', () => {

        it('registerSystemConfigByManager  ', async () => {
            const {thanosSepoliaSystemConfig, thanosSepoliaL1CrossDomainMessenger, thanosSepoliaL1StandardBridge, thanosL2TON, thanosSepoliaOptimismPortal } = await getNamedAccounts();

            let type = 2;
            let name = 'Thanos-Sepolia'

            let receipt = await (await l1BridgeRegistry.connect(manager)["registerRollupConfigByManager(address,uint8,address,string)"](
                thanosSepoliaSystemConfig,
                type,
                thanosL2TON,
                name
            )).wait()

            const topic = l1BridgeRegistry.interface.getEventTopic('RegisteredRollupConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistry.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(thanosSepoliaSystemConfig)
            expect(deployedEvent.args.type_).to.be.eq(type)
        })
    })

    describe('# Layer2Manager checkLayer2TVL', () => {
        it('If the rollupConfig or L1Bridge address does not exist, the result is returned as false.', async () => {
            const {l1MessengerAddress, l1BridgeAddress, l2TonAddress } = await getNamedAccounts();
            let rollupConfig = l1MessengerAddress

            expect(await layer2Manager.l1BridgeRegistry()).to.be.eq(l1BridgeRegistry.address)
            expect(await l1BridgeRegistry.rollupType(rollupConfig)).to.be.eq(0)

            let check = await layer2Manager.checkLayer2TVL(rollupConfig)
            expect(check.result).to.be.eq(false)
            expect(check.amount).to.be.eq(ethers.constants.Zero)
        })

        it('Titan: Check rollupType and checkLayer2TVL.', async () => {

            expect(await layer2Manager.l1BridgeRegistry()).to.be.eq(l1BridgeRegistry.address)
            expect(await l1BridgeRegistry.rollupType(legacySystemConfig.address)).to.be.eq(1)

            let check = await layer2Manager.checkLayer2TVL(legacySystemConfig.address)
            expect(check.result).to.be.eq(true)
            expect(check.amount).to.be.gt(ethers.constants.Zero)
        })

        it('Thanos: Check rollupType and checkLayer2TVL.', async () => {
            const {thanosSepoliaSystemConfig} = await getNamedAccounts();

            expect(await layer2Manager.l1BridgeRegistry()).to.be.eq(l1BridgeRegistry.address)
            expect(await l1BridgeRegistry.rollupType(thanosSepoliaSystemConfig)).to.be.eq(2)

            let check = await layer2Manager.checkLayer2TVL(thanosSepoliaSystemConfig)
            expect(check.result).to.be.eq(true)
            expect(check.amount).to.be.gt(ethers.constants.Zero)
        })
    })

    describe('# Layer2Manager registerCandidateAddOn ', () => {

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

            await checkBalanceTon(addr1, amount)

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

            await checkBalanceTon(addr, amount)

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
            // let portal = await thanosSystemConfigContract.optimismPortal()
            // await faucetContract.connect(deployer).transferToken1(portal, utils.parseEther("2000000"))
            // console.log('thanosLayerAddress', thanosLayerAddress)
            // console.log('thanosLayerContract', thanosLayerContract.address)
            // console.log('thanosOperatorContract', thanosOperatorContract.address)

        })
    })

    describe('# DepositManager : Titan CandidateAddOn ', () => {

        it('deposit to titanLayerAddress using approveAndCall', async () => {

            let layerAddress = titanLayerAddress
            let account = addr1
            let amount = ethers.utils.parseEther("2000")

            await depositApproveAndCall(
                layerAddress,
                account,
                amount
            );
        })

        it('deposit to titanLayerAddress using deposit(address,uint256)', async () => {

            let account = addr2
            let amount = ethers.utils.parseEther("2000")

            await depositWithWton(
                titanLayerAddress,
                account,
                amount
            );
        })

        it('deposit to thanosLayerAddress using approveAndCall', async () => {

            let layerAddress = thanosLayerAddress
            let account = addr1
            let amount = ethers.utils.parseEther("20000")

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

        it('requestWithdrawal to titanLayerAddress', async () => {
            let layer2 = titanLayerAddress
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("1"+"0".repeat(9))

            await requestWithdrawal (layer2, account, wtonAmount);


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

            await processRequest(layer2, account);
        });

    })

    describe('# DepositManager : Thanos CandidateAddOn ', () => {

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

    describe('# DepositManager : Candidate1 ', () => {

        it('Operators must stake at least 1000.1 TON', async () => {
            let layer2 = candidate1.address
            let account = addr1
            let tonAmount = ethers.utils.parseEther("1000.1")

            await depositApproveAndCall(layer2, account, tonAmount)

        })

        it('deposit to layer2 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)

            let account = addr2
            let tonAmount = ethers.utils.parseEther("100")

            await depositApproveAndCall(candidate1.address, account, tonAmount)

        })

        it('deposit to layer1 using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)

            let account = addr1
            let wtonAmount = ethers.utils.parseEther("1"+"0".repeat(9))

            await depositWithWton(
                candidate1.address,
                account,
                wtonAmount
            );

        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {

            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await depositWithWton2(
                candidate1.address,
                account,
                wtonAmount
            );
        })


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
            await updateSeigniorageLayer1(candidate1.address);

        })

        it('requestWithdrawal to layer1', async () => {

            let layer2 = candidate1.address
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

            await requestWithdrawal (layer2, account, wtonAmount);

        })

        it('processRequest to layer1 will be fail when delay time didn\'t pass.', async () => {
            let layer2 = candidate1.address
            let account = addr1

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
            let layer2 = candidate1.address
            let account = addr1

            await processRequest(layer2, account);
        });
    })

    describe('# DepositManager : MockLayer2 ', () => {

        it('deposit to layer2 using approveAndCall', async () => {
            // console.log(deployed.seigManagerV2)
            let layer2 = layer2Candidate1.layer2.address
            let account = addr1
            let tonAmount = ethers.utils.parseEther("100")

            await depositApproveAndCall(layer2, account, tonAmount)

        })

        it('deposit to layer1 using deposit(address,uint256)', async () => {
            // console.log(deployed.seigManagerV2)
            let layer2 = layer2Candidate1.layer2.address
            let account = addr2
            let wtonAmount = ethers.utils.parseEther("1"+"0".repeat(9))

            await depositWithWton(
                layer2,
                account,
                wtonAmount
            );

        })

        it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
            let layer2 = layer2Candidate1.layer2.address
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
            await depositWithWton2(
                layer2,
                account,
                wtonAmount
            );
        })


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

            await updateSeigniorageLayer2(layer2Candidate1.layer2);

        })

        it('evm_mine', async () => {
            ethers.provider.send("evm_increaseTime", [60*60*24*7])
            ethers.provider.send("evm_mine");
        });


        it('requestWithdrawal to layer1', async () => {
            let layer2 = layer2Candidate1.layer2.address
            let account = addr1
            let wtonAmount = ethers.utils.parseEther("11"+"0".repeat(9))

            await requestWithdrawal (layer2, account, wtonAmount);

        })

        it('processRequest to layer1 will be fail when delay time didn\'t pass.', async () => {
            let layer2 = layer2Candidate1.layer2.address
            let account = addr1

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
            let layer2 = layer2Candidate1.layer2.address
            let account = addr1

            await processRequest(layer2, account);
        });
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

    // describe('# withdrawAndDepositL2 : Thanos LayerCandidate ', () => {

    //     it('deposit to Thanos using approveAndCall', async () => {

    //         let layerAddress = thanosLayerAddress
    //         let account = addr1
    //         let amount = ethers.utils.parseEther("200000")

    //         await depositApproveAndCall(
    //             layerAddress,
    //             account,
    //             amount
    //         );
    //     })


    //     it('deposit to layer1 using approveAndCall', async () => {
    //         let account = addr2
    //         let amount = ethers.utils.parseEther("200000")

    //         await depositApproveAndCall(
    //             candidate1.address,
    //             account,
    //             amount
    //         );
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('withdrawAndDepositL2 : Not supported in DAOCandidate layer.', async () => {
    //         let layer2 = candidate1.address
    //         let account = addr2
    //         let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

    //         await expect(depositManager.connect(account).withdrawAndDepositL2(
    //             layer2,
    //             wtonAmount
    //         )).to.be.revertedWith("OperatorError")

    //     })

    //     it('withdrawAndDepositL2 : Failure if the staking amount is insufficient', async () => {
    //         let layer = thanosLayerAddress
    //         let account = addr2
    //         let stakedA = await seigManager["stakeOf(address,address)"](layer, account.address)

    //         await expect(depositManager.connect(account).withdrawAndDepositL2(
    //             layer,
    //             stakedA.add(ethers.constants.One)
    //         )).to.be.revertedWith("staked amount is insufficient")
    //     })

    //     it('When you run it, deposit money to L2 immediately without delay blocks.', async () => {
    //         let layer = thanosLayerAddress
    //         let operatorContract = thanosOperatorContract

    //         let account = addr2

    //         let rollupConfig = await operatorContract.rollupConfig()
    //         expect(rollupConfig).to.be.not.eq(ethers.constants.AddressZero)

    //         let prevLayer2TVL = await l1BridgeRegistry.layer2TVL(rollupConfig)

    //         let stakedA = await seigManager["stakeOf(address,address)"](layer, account.address)
    //         let amount = stakedA.div(BigNumber.from("4"))
    //         let receipt = await (await depositManager.connect(account).withdrawAndDepositL2(
    //             layer,
    //             amount
    //         )).wait()

    //         const topic = depositManager.interface.getEventTopic('WithdrawalAndDeposited');
    //         const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    //         const deployedEvent = depositManager.interface.parseLog(log);
    //         expect(deployedEvent.args.layer2).to.be.eq(layer)
    //         expect(deployedEvent.args.account).to.be.eq(account.address)
    //         expect(deployedEvent.args.amount).to.be.eq(amount)

    //         let stakedB = await seigManager["stakeOf(address,address)"](layer, account.address)
    //         expect(stakedB).to.be.eq(stakedA.sub(amount))

    //         const afterTonBalance = await tonContract.balanceOf(depositManager.address);
    //         expect(await l1BridgeRegistry.layer2TVL(rollupConfig)).to.be.eq(
    //             prevLayer2TVL.add(amount.div(BigNumber.from("1000000000"))))

    //     })
    // })


    // describe('# reject CandidateAddOn : L1BridgeRegistry ', () => {
    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('reject CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
    //         expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.not.eq(addr1.address)
    //         await expect(
    //             l1BridgeRegistry.connect(addr1).rejectCandidateAddOn(
    //                 legacySystemConfig.address
    //             )
    //         ).to.be.revertedWith("PermissionError")
    //     })

    //     it('reject CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {

    //         await rejectCandidateTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     })

    //     it('Layer2Contract: updateSeigniorage : updateSeigniorage to titanLayerAddress ', async () => {
    //         await updateSeigniorageTitan_reject();

    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     // it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
    //     //     await restoreCandidateTitan();
    //     // })

    //     // it('evm_mine', async () => {
    //     //     ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //     //     ethers.provider.send("evm_mine");
    //     // });
    // })


    // describe('# DepositManager : CandidateAddOn : thanosCandidateAddOn ', () => {

    //     it('Layer2Contract:  updateSeigniorage to thanosLayerAddress ', async () => {

    //         await updateSeigniorageThanos();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });


    //     it('Layer2Contract:  updateSeigniorage to thanosLayerAddress ', async () => {

    //         await updateSeigniorageThanos();
    //     })


    // })

    // describe('# restore CandidateAddOn : L1BridgeRegistry ', () => {

    //     it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {
    //         expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.not.eq(addr1.address)
    //         await expect(
    //             l1BridgeRegistry.connect(addr1).restoreCandidateAddOn(
    //                 legacySystemConfig.address,
    //                 false
    //             )
    //         ).to.be.revertedWith("PermissionError")
    //     })

    //     it('restore CandidateAddOn (titanCandidateAddOn) : Only rejected layers can be restored.', async () => {
    //         const {thanosSystemConfig, thanosL2TON } = await getNamedAccounts();

    //         expect(await l1BridgeRegistry.seigniorageCommittee()).to.be.eq(seigniorageCommitteeAddress)
    //         expect(await l1BridgeRegistry.rejectRollupConfig(thanosSystemConfig)).to.be.eq(false)
    //         await expect(
    //             l1BridgeRegistry.connect(seigniorageCommittee).restoreCandidateAddOn(
    //                 thanosSystemConfig,
    //                 false
    //             )
    //         ).to.be.revertedWith("OnlyRejectedError")
    //     })

    //     it('restore CandidateAddOn (titanCandidateAddOn) can be executed by seigniorageCommittee ', async () => {

    //         await restoreCandidateTitan();
    //     })

    // })

    // describe('# DepositManager : CandidateAddOn : titanCandidateAddOn ', () => {

    //     it('seigManager: updateSeigniorageLayer : (1) updateSeigniorage to titanLayerAddress', async () => {

    //         await updateSeigniorageTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('Layer2Contract: updateSeigniorage : (2) updateSeigniorage to titanLayerAddress ', async () => {
    //         await updateSeigniorageTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('Layer2Contract: updateSeigniorage : (3) updateSeigniorage to titanLayerAddress  ', async () => {
    //         await updateSeigniorageTitan();

    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });
    // })

    // describe('# DepositManager : CandidateAddOn : titanCandidateAddOn ', () => {

    //     it('seigManager: updateSeigniorageLayer :  updateSeigniorage to titanCandidateAddOn  ', async () => {

    //         await updateSeigniorageTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('seigManager: updateSeigniorageLayer :  updateSeigniorage to titanCandidateAddOn ', async () => {
    //         await updateSeigniorageTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('seigManager: updateSeigniorageLayer :  updateSeigniorage to titanCandidateAddOn ', async () => {
    //         await updateSeigniorageTitan();

    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('Layer2Contract: updateSeigniorage :  updateSeigniorage to titanCandidateAddOn  ', async () => {
    //         await updateSeigniorageTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('Layer2Contract: updateSeigniorage :  updateSeigniorage to titanCandidateAddOn ', async () => {
    //         await updateSeigniorageTitan();

    //     })
    //     /* Titan is closed
    //     it('requestWithdrawal to titanLayerAddress', async () => {
    //          let layerAddress = titanLayerAddress
    //         let operatorContractAddress = titanOperatorContractAddress
    //         let layerContract = titanLayerContract
    //         let operatorContract = titanOperatorContract
    //         let operatorOwner = titanManager

    //         let layer2 = titanLayerAddress
    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

    //         const beforeBalance = await wtonContract.balanceOf(account.address)

    //         let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)
    //         let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
    //         let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
    //         let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

    //         await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
    //             layer2,
    //             wtonAmount
    //         )).wait()

    //         const afterBalance = await wtonContract.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance)

    //         let stakedB = await seigManager["stakeOf(address,address)"](layer2, account.address)

    //         expect(roundDown(stakedA.sub(ethers.constants.Two),5)).to.be.eq(
    //             roundDown(stakedB.add(wtonAmount), 5)
    //         )

    //         expect(
    //             await depositManager.pendingUnstaked(layer2, account.address)
    //         ).to.be.eq(pendingUnstakedA.add(wtonAmount))

    //         expect(
    //             await depositManager.pendingUnstakedLayer2(layer2 )
    //         ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

    //         expect(
    //             await depositManager.pendingUnstakedAccount(account.address)
    //         ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

    //     }).timeout(100000000)

    //     it('processRequest to titanLayerAddress will be fail when delay time didn\'t pass.', async () => {
    //         let layer2 = titanLayerAddress
    //         let account = addr1

    //         await expect(
    //                 depositManager.connect(account)["processRequest(address,bool)"](
    //                 layer2,
    //                 true
    //             )
    //         ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

    //     });

    //     it('processRequest to titanLayerAddress.', async () => {
    //         let layer2 = titanLayerAddress
    //         let account = addr1
    //         const beforeBalance = await tonContract.balanceOf(account.address)
    //         let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
    //         let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
    //         let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

    //         let accUnstakedA = await depositManager.accUnstaked(layer2, account.address)
    //         let accUnstakedLayer2A = await depositManager.accUnstakedLayer2(layer2)
    //         let accUnstakedAccountA = await depositManager.accUnstakedAccount(account.address)

    //         let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay()
    //         let globalWithdrawalDelay_l = await depositManager.withdrawalDelay(layer2)
    //         if (globalWithdrawalDelay.lt(globalWithdrawalDelay_l) ) globalWithdrawalDelay = globalWithdrawalDelay_l

    //         await mine(globalWithdrawalDelay, { interval: 12 });

    //         await (await depositManager.connect(account)["processRequest(address,bool)"](
    //             layer2,
    //             true
    //         )).wait()

    //         const afterBalance = await tonContract.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance.add(pendingUnstakedA.div(BigNumber.from("1"+"0".repeat(9)))))

    //         expect(
    //             await depositManager.pendingUnstaked(layer2, account.address)
    //         ).to.be.eq(ethers.constants.Zero)

    //         expect(
    //             await depositManager.pendingUnstakedLayer2(layer2 )
    //         ).to.be.eq(pendingUnstakedLayer2A.sub(pendingUnstakedA))

    //         expect(
    //             await depositManager.pendingUnstakedAccount(account.address)
    //         ).to.be.eq(pendingUnstakedAccountA.sub(pendingUnstakedA))

    //         expect(
    //             await depositManager.accUnstaked(layer2, account.address)
    //         ).to.be.eq(accUnstakedA.add(pendingUnstakedA))

    //         expect(
    //             await depositManager.accUnstakedLayer2(layer2 )
    //         ).to.be.eq(accUnstakedLayer2A.add(pendingUnstakedA))

    //         expect(
    //             await depositManager.accUnstakedAccount(account.address)
    //         ).to.be.eq(accUnstakedAccountA.add(pendingUnstakedA))

    //     });
    //     */
    // })

    // // 기존의 다오 candidate 테스트
    // describe('# DepositManager : DAOCandidate ', () => {

    //     it('deposit to layer1 using approveAndCall', async () => {

    //         let account = addr2
    //         let tonAmount = ethers.utils.parseEther("100")

    //         await depositApproveAndCall(candidate1.address, account, tonAmount)

    //     })

    //     it('deposit to layer2 using approveAndCall', async () => {
    //         let account = addr2
    //         let tonAmount = ethers.utils.parseEther("100")

    //         await depositApproveAndCall(layer2Info_2.layer2, account, tonAmount)
    //     })

    //     it('deposit to layer1 using deposit(address,uint256)', async () => {
    //         let account = addr1

    //         let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
    //         await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);

    //         await depositWithWton(
    //             candidate1.address,
    //             account,
    //             wtonAmount
    //         );
    //     })

    //     it('deposit to tokamak using deposit(address,address,uint256) ', async () => {
    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))
    //         await wtonContract.connect(wtonHave).transfer(account.address, wtonAmount);


    //         await depositWithWton2(
    //             layer2Info_2.layer2,
    //             account,
    //             wtonAmount
    //         );
    //     })


    //     it('query unallocatedSeigniorage', async () => {

    //         let stakeOfAllLayers = await await seigManager["stakeOfAllLayers()"]();
    //         let stakeOfTotal = await await seigManager["stakeOfTotal()"]();
    //         expect(stakeOfTotal).to.be.gt(stakeOfAllLayers);

    //         let unallocatedSeigniorage = await await seigManager.unallocatedSeigniorage();
    //         expect(stakeOfTotal.sub(stakeOfAllLayers)).to.be.eq(unallocatedSeigniorage);
    //     });

    //     it('updateSeigniorage to layer1', async () => {
    //         await updateSeigniorageLayer1(candidate1.contract);
    //     })

    //     it('requestWithdrawal to layer1', async () => {

    //         let layer2 = candidate1.address
    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

    //         await requestWithdrawal (layer2, account, wtonAmount);
    //     })

    //     it('processRequest to layer1 will be fail when delay time didn\'t pass.', async () => {
    //         let layer2 = candidate1.address
    //         let account = addr1

    //         let numPendingRequests = await depositManager.numPendingRequests(layer2, account.address);

    //         await expect(
    //                 depositManager.connect(account)["processRequests(address,uint256,bool)"](
    //                 layer2,
    //                  numPendingRequests,
    //                 true
    //             )
    //         ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

    //     });

    //     it('processRequest to layer1.', async () => {
    //         let layer2 = candidate1.address
    //         let account = addr1

    //         await processRequest(layer2, account);
    //     });

    // })

    // describe('# createCandidateAddOn ', () => {

    //     // it('createCandidateAddOn ', async () => {

    //     // }

    //     it('createCandidateAddOn ', async () => {

    //         let rollupConfig= ""
    //         const memo = "CandidateAddOn1"
    //         const receipt = await (await layer2Manager.connect(addr1).registerCandidateAddOn(

    //         )).wait()

    //         const topic = daoCommitteeContract.interface.getEventTopic('CandidateContractCreated');
    //         const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    //         const deployedEvent = daoCommitteeContract.interface.parseLog(log);

    //         const candidateContract = new ethers.Contract(
    //             deployedEvent.args.candidateContract, DAOCandidate_Json.abi, deployer)

    //         expect(deployedEvent.args.candidate).to.be.eq(addr1.address)
    //         expect(deployedEvent.args.candidateContract).to.be.eq(candidateContract)
    //         expect(deployedEvent.args.memo).to.be.eq(memo)

    //         candidate1 = {
    //             address : deployedEvent.args.candidateContract,
    //             contract: candidateContract
    //         }

    //     });
    // })

    // describe('# Thanos checkLayer2TVL', () => {
    //     it('If the rollupConfig or L1Bridge address does not exist, the result is returned as false.', async () => {
    //         const {thanosSepoliaL1StandardBridge } = await getNamedAccounts();
    //         let rollupConfig = thanosSepoliaL1StandardBridge

    //         expect(await layer2Manager.l1BridgeRegistry()).to.be.eq(l1BridgeRegistry.address)
    //         expect(await l1BridgeRegistry.rollupType(rollupConfig)).to.be.eq(0)

    //         let check = await layer2Manager.checkLayer2TVL(rollupConfig)
    //         expect(check.result).to.be.eq(false)
    //         expect(check.amount).to.be.eq(ethers.constants.Zero)
    //     })

    //     it('If the rollupConfig or L1Bridge address exist, the result is returned as false.', async () => {

    //         expect(await layer2Manager.l1BridgeRegistry()).to.be.eq(l1BridgeRegistry.address)
    //         expect(await l1BridgeRegistry.rollupType(legacySystemConfig.address)).to.be.eq(1)

    //         let check = await layer2Manager.checkLayer2TVL(legacySystemConfig.address)
    //         expect(check.result).to.be.eq(true)
    //         expect(check.amount).to.be.gt(ethers.constants.Zero)
    //     })
    // })

    // describe('# registerCandidateAddOn ', () => {

    //     it('Fail if systemConfig is an invalid address', async () => {
    //         const amount = await layer2Manager.minimumInitialDepositAmount()

    //         await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
    //             l1BridgeRegistry.address,
    //             amount,
    //             true,
    //             'test1'
    //         )).to.be.rejectedWith("RegisterError")
    //     })

    //     it('Failure in case of insufficient ton balance', async () => {
    //         const amount = await layer2Manager.minimumInitialDepositAmount()

    //         await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
    //             legacySystemConfig.address,
    //             amount,
    //             true,
    //             'test1'
    //         )).to.be.rejectedWith("TRANSFER_FROM_FAILED")
    //     })

    //     it('Failure when there is no prior approval of wton', async () => {
    //         const amount = await layer2Manager.minimumInitialDepositAmount()
    //         await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
    //             legacySystemConfig.address,
    //             amount.mul(utils.parseEther("1000000000")),
    //             false,
    //             'test1'
    //         )).to.be.rejectedWith("TRANSFER_FROM_FAILED")
    //     })

    //     it('Fail if there is no content in memo', async () => {
    //         const amount = await layer2Manager.minimumInitialDepositAmount()

    //         await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
    //             legacySystemConfig.address,
    //             amount,
    //             true,
    //             ''
    //         )).to.be.rejectedWith("ZeroBytesError")
    //     })

    //     it('registerCandidateAddOn : titanCandidateAddOn', async () => {
    //         expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(0)

    //         const addr = tonHave
    //         let amount = await layer2Manager.minimumInitialDepositAmount();
    //         // amount = amount.add(ethers.utils.parseEther("0.1"))
    //         // console.log('amount', amount)

    //         let balance = await tonContract.balanceOf(addr.address)
    //         expect(balance).to.be.gt(amount)

    //         let allowance = await tonContract.allowance(addr.address, layer2Manager.address)
    //         if(allowance.lt(amount)){
    //             await tonContract.connect(addr).approve(layer2Manager.address, amount);
    //         }

    //         const name = await legacySystemConfig.name()
    //         const operatorAddress = await operatorManagerFactory.getAddress(legacySystemConfig.address)

    //         const receipt = await (await layer2Manager.connect(addr).registerCandidateAddOn(
    //             legacySystemConfig.address,
    //             amount,
    //             true,
    //             name
    //         )).wait()

    //         const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
    //         const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    //         const deployedEvent = layer2Manager.interface.parseLog(log);

    //         expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
    //         expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
    //         expect(deployedEvent.args.memo).to.be.eq(name)
    //         expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
    //         expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

    //         titanLayerAddress = deployedEvent.args.candidateAddOn;
    //         titanOperatorContractAddress = deployedEvent.args.operator;
    //         expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(1)

    //         titanLayerContract =  (await ethers.getContractAt("CandidateAddOnV1_1", titanLayerAddress, deployer)) as CandidateAddOnV1_1
    //         titanOperatorContract = (await ethers.getContractAt("OperatorManagerV1_1", titanOperatorContractAddress, deployer)) as OperatorManagerV1_1

    //         // console.log('titanLayerAddress', titanLayerAddress)
    //         // console.log('titanLayerContract', titanLayerContract.address)
    //         // console.log('titanOperatorContract', titanOperatorContract.address)
    //     })

    //     it('If the layer has already been created, it will fail.', async () => {

    //         expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(1)

    //         const amount = await layer2Manager.minimumInitialDepositAmount();

    //          await checkBalanceTon(addr1.address, amount);
    //         let allowance = await tonContract.allowance(addr1.address, layer2Manager.address)
    //         if(allowance.lt(amount)){
    //             await tonContract.connect(addr1).approve(layer2Manager.address, amount);
    //         }

    //         const name = await legacySystemConfig.name()

    //         await expect(layer2Manager.connect(addr1).registerCandidateAddOn(
    //             legacySystemConfig.address,
    //             amount,
    //             true,
    //             name
    //         ) ).to.be.revertedWith("RegisterError");
    //     })


    //     it('registerCandidateAddOn : thanosCandidateAddOn', async () => {
    //         const {thanosSepoliaSystemConfig } = await getNamedAccounts();
    //         expect((await layer2Manager.statusLayer2(thanosSepoliaSystemConfig))).to.be.eq(0)

    //         const addr = tonHave
    //         let amount = await layer2Manager.minimumInitialDepositAmount();
    //         // amount = amount.add(ethers.utils.parseEther("0.1"))
    //         // console.log('amount', amount)

    //         let balance = await tonContract.balanceOf(addr.address)
    //         expect(balance).to.be.gt(amount)

    //         let allowance = await tonContract.allowance(addr.address, layer2Manager.address)
    //         if(allowance.lt(amount)){
    //             await tonContract.connect(addr).approve(layer2Manager.address, amount);
    //         }

    //         let name = 'Thanos-Sepolia'
    //         const operatorAddress = await operatorManagerFactory.getAddress(thanosSepoliaSystemConfig)

    //         const receipt = await (await layer2Manager.connect(addr).registerCandidateAddOn(
    //             thanosSepoliaSystemConfig,
    //             amount,
    //             true,
    //             name
    //         )).wait()

    //         const topic = layer2Manager.interface.getEventTopic('RegisteredCandidateAddOn');
    //         const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    //         const deployedEvent = layer2Manager.interface.parseLog(log);

    //         expect(deployedEvent.args.rollupConfig).to.be.eq(thanosSepoliaSystemConfig)
    //         expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
    //         expect(deployedEvent.args.memo).to.be.eq(name)
    //         expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
    //         expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

    //         thanosLayerAddress = deployedEvent.args.candidateAddOn;
    //         thanosOperatorContractAddress = deployedEvent.args.operator;
    //         expect((await layer2Manager.statusLayer2(thanosSepoliaSystemConfig))).to.be.eq(1)

    //         thanosLayerContract =  (await ethers.getContractAt("CandidateAddOnV1_1", thanosLayerAddress, deployer)) as CandidateAddOnV1_1
    //         thanosOperatorContract = (await ethers.getContractAt("OperatorManagerV1_1", thanosOperatorContractAddress, deployer)) as OperatorManagerV1_1


    //         thanosSystemConfigContract = (new ethers.Contract(thanosSepoliaSystemConfig,  MockSystemConfig_Json.abi, deployer)) as MockSystemConfig
    //         let portal = await thanosSystemConfigContract.optimismPortal()
    //          await checkBalanceTon(portal, utils.parseEther("2000000"));
    //         // console.log(  'thanosLayerAddress', thanosLayerAddress)
    //         // console.log('thanosLayerContract', thanosLayerContract.address)
    //         // console.log('thanosOperatorContract', thanosOperatorContract.address)

    //     })
    // })

    // describe('# DepositManager : Titan CandidateAddOn ', () => {

    //     it('deposit to titanLayerAddress using approveAndCall', async () => {

    //         let layerAddress = titanLayerAddress
    //         let account = addr1
    //         let amount = ethers.utils.parseEther("200000")

    //         await depositApproveAndCall(
    //             layerAddress,
    //             account,
    //             amount
    //         );
    //     })

    //     it('deposit to titanLayerAddress using deposit(address,uint256)', async () => {

    //         let account = addr2
    //         let amount = ethers.utils.parseEther("200000")

    //         await depositWithWton(
    //             titanLayerAddress,
    //             account,
    //             amount
    //         );
    //     })

    //     it('deposit to thanosLayerAddress using approveAndCall', async () => {

    //         let layerAddress = thanosLayerAddress
    //         let account = addr1
    //         let amount = ethers.utils.parseEther("200000")

    //         await depositApproveAndCall(
    //             layerAddress,
    //             account,
    //             amount
    //         );

    //     })

    //     it('deposit to thanosLayerAddress using deposit(address,uint256)', async () => {
    //         let account = addr2
    //         let amount = ethers.utils.parseEther("30"+"0".repeat(9))

    //         await depositWithWton(
    //             thanosLayerAddress,
    //             account,
    //             amount
    //         );
    //     })

    //     it('deposit to titanLayerAddress using deposit(address,address,uint256) ', async () => {

    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

    //         await depositWithWton2(
    //             titanLayerAddress,
    //             account,
    //             wtonAmount
    //         );
    //     })

    //     it('deposit to thanosLayerAddress using deposit(address,address,uint256) ', async () => {

    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("10"+"0".repeat(9))

    //         await depositWithWton2(
    //             thanosLayerAddress,
    //             account,
    //             wtonAmount
    //         );
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('The operator\'s staking amount must be greater than minimumAmount.', async () => {
    //         expect(await titanLayerContract.operator()).to.be.eq(titanOperatorContractAddress);
    //         let staked = await seigManager["stakeOf(address,address)"](titanLayerAddress, titanOperatorContractAddress)
    //         // console.log(ethers.utils.formatUnits(staked, 27) )
    //         expect(await seigManager.minimumAmount()).to.be.not.gt(staked)
    //     })

    //     it('seigManager: updateSeigniorageLayer : (1) updateSeigniorage to titanLayerAddress ', async () => {
    //         await updateSeigniorageTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('seigManager: updateSeigniorageLayer : (1) updateSeigniorage to thanosLayerAddress ', async () => {
    //         await updateSeigniorageThanos();

    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });


    //     it('seigManager: updateSeigniorageLayer : (2) updateSeigniorage to titanLayerAddress ', async () => {
    //         await updateSeigniorageTitan();
    //     })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24*7])
    //         ethers.provider.send("evm_mine");
    //     });

    //     it('seigManager: updateSeigniorageLayer :  (3) updateSeigniorage to titanLayerAddress ', async () => {
    //         await updateSeigniorageTitan();

    //     })

    //     /* Titan is closed
    //     it('requestWithdrawal to titanLayerAddress', async () => {

    //         let layer2 = titanLayerAddress
    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

    //         const beforeBalance = await wtonContract.balanceOf(account.address)

    //         let stakedA = await seigManager["stakeOf(address,address)"](layer2, account.address)
    //         let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
    //         let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
    //         let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

    //         await (await depositManager.connect(account)["requestWithdrawal(address,uint256)"](
    //             layer2,
    //             wtonAmount
    //         )).wait()

    //         const afterBalance = await wtonContract.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance)

    //         let stakedB = await seigManager["stakeOf(address,address)"](layer2, account.address)

    //         expect(roundDown(stakedA.sub(ethers.constants.Two),5)).to.be.eq(
    //             roundDown(stakedB.add(wtonAmount), 5)
    //         )

    //         expect(
    //             await depositManager.pendingUnstaked(layer2, account.address)
    //         ).to.be.eq(pendingUnstakedA.add(wtonAmount))

    //         expect(
    //             await depositManager.pendingUnstakedLayer2(layer2 )
    //         ).to.be.eq(pendingUnstakedLayer2A.add(wtonAmount))

    //         expect(
    //             await depositManager.pendingUnstakedAccount(account.address)
    //         ).to.be.eq(pendingUnstakedAccountA.add(wtonAmount))

    //     })

    //     it('processRequest to titanLayerAddress will be fail when delay time didn\'t pass.', async () => {
    //         let layer2 = titanLayerAddress
    //         let account = addr1

    //         await expect(
    //                 depositManager.connect(account)["processRequest(address,bool)"](
    //                 layer2,
    //                 true
    //             )
    //         ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

    //     });

    //     it('processRequest to titanLayerAddress.', async () => {
    //         let layer2 = titanLayerAddress
    //         let account = addr1
    //         const beforeBalance = await tonContract.balanceOf(account.address)
    //         let pendingUnstakedA = await depositManager.pendingUnstaked(layer2, account.address)
    //         let pendingUnstakedLayer2A = await depositManager.pendingUnstakedLayer2(layer2)
    //         let pendingUnstakedAccountA = await depositManager.pendingUnstakedAccount(account.address)

    //         let accUnstakedA = await depositManager.accUnstaked(layer2, account.address)
    //         let accUnstakedLayer2A = await depositManager.accUnstakedLayer2(layer2)
    //         let accUnstakedAccountA = await depositManager.accUnstakedAccount(account.address)

    //         let globalWithdrawalDelay = await depositManager.globalWithdrawalDelay()
    //         let globalWithdrawalDelay_l = await depositManager.withdrawalDelay(layer2)
    //         if (globalWithdrawalDelay.lt(globalWithdrawalDelay_l) ) globalWithdrawalDelay = globalWithdrawalDelay_l

    //         await mine(globalWithdrawalDelay, { interval: 12 });

    //         await (await depositManager.connect(account)["processRequest(address,bool)"](
    //             layer2,
    //             true
    //         )).wait()

    //         const afterBalance = await tonContract.balanceOf(account.address);
    //         expect(afterBalance).to.be.eq(beforeBalance.add(pendingUnstakedA.div(BigNumber.from("1"+"0".repeat(9)))))

    //         expect(
    //             await depositManager.pendingUnstaked(layer2, account.address)
    //         ).to.be.eq(ethers.constants.Zero)

    //         expect(
    //             await depositManager.pendingUnstakedLayer2(layer2 )
    //         ).to.be.eq(pendingUnstakedLayer2A.sub(pendingUnstakedA))

    //         expect(
    //             await depositManager.pendingUnstakedAccount(account.address)
    //         ).to.be.eq(pendingUnstakedAccountA.sub(pendingUnstakedA))

    //         expect(
    //             await depositManager.accUnstaked(layer2, account.address)
    //         ).to.be.eq(accUnstakedA.add(pendingUnstakedA))

    //         expect(
    //             await depositManager.accUnstakedLayer2(layer2 )
    //         ).to.be.eq(accUnstakedLayer2A.add(pendingUnstakedA))

    //         expect(
    //             await depositManager.accUnstakedAccount(account.address)
    //         ).to.be.eq(accUnstakedAccountA.add(pendingUnstakedA))

    //     });
    //     */

    //     it('requestWithdrawal to thanosLayerAddress', async () => {
    //         let layer2 = thanosLayerAddress
    //         let account = addr1
    //         let wtonAmount = ethers.utils.parseEther("5"+"0".repeat(9))

    //         await requestWithdrawal (layer2, account, wtonAmount);


    //     }).timeout(100000000)

    //     it('processRequest to thanosLayerAddress will be fail when delay time didn\'t pass.', async () => {
    //         let layer2 = thanosLayerAddress
    //         let account = addr1

    //         await expect(
    //                 depositManager.connect(account)["processRequest(address,bool)"](
    //                 layer2,
    //                 true
    //             )
    //         ).to.be.rejectedWith("DepositManager: wait for withdrawal delay")

    //     });

    //     it('processRequest to thanosLayerAddress.', async () => {
    //         let layer2 = thanosLayerAddress
    //         let account = addr1

    //         await processRequest(layer2, account);
    //     });

    // })


});


