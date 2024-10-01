import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts, deployments} from 'hardhat'

import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

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

import LegacySystemConfig_Json from '../../../artifacts/contracts/layer2/LegacySystemConfig.sol/LegacySystemConfig.json'
import Layer2ManagerV1_1_Json from '../../../artifacts/contracts/layer2/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json'
import OperatorFactory_Json from '../../../artifacts/contracts/layer2/factory/OperatorManagerFactory.sol/OperatorManagerFactory.json'
import Layer2ManagerProxy_Json from '../../../artifacts/contracts/layer2/Layer2ManagerProxy.sol/Layer2ManagerProxy.json'
import DepositManagerV1_1_Json from '../../../artifacts/contracts/stake/managers/DepositManagerV1_1.sol/DepositManagerV1_1.json'
import Layer2Candidate_Json from '../../../artifacts/contracts/dao/CandidateAddOnV1_1.sol/CandidateAddOnV1_1.json'
import SeigManagerV1_3_Json from '../../../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json'
import SeigManagerV1_2_Json from '../../../artifacts/contracts/stake/managers/SeigManagerV1_2.sol/SeigManagerV1_2.json'
import OperatorV1_1_Json from '../../../artifacts/contracts/layer2/OperatorManagerV1_1.sol/OperatorManagerV1_1.json'
import Layer2CandidateProxy_Json from '../../../artifacts/contracts/dao/CandidateAddOnProxy.sol/CandidateAddOnProxy.json'

const layers = [
    {"oldLayer":"","newLayer":"0xaeb0463a2fd96c68369c1347ce72997406ed6409","operator":"0xd4335a175c36c0922f6a368b83f9f6671bf07606","name":"candidate"},
    {"oldLayer":"","newLayer":"0xabd15c021942ca54abd944c91705fe70fea13f0d","operator":"0x757de9c340c556b56f62efae859da5e08baae7a2","name":"member_DAO"},
]

let pastAddr = "0xD4335A175c36c0922F6A368b83f9F6671bf07606"
let wtonhaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
let tonHaveAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

const daoOwnerAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinterAddress = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
let tonMinter

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

describe('Check SeigManager, depositManager', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
      let tonContract: Contract, wtonContract: Contract, daoContract: Contract, daoV2Contract: Contract
    let depositManager: Contract,  depositManagerProxy: Contract, seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3;

    let daoOwner: Signer;

    let powerTon: string

    const deployedLegacySystemConfigAddress = "0x1cA73f6E80674E571dc7a8128ba370b8470D4D87"
    const deployedLayer2ManagerProxyAddress = "0xffb690feeFb2225394ad84594C4a270c04be0b55"
    const deployedOperatorFactoryAddress = "0x8a42BcFC2EB5D38Ca48122854B91333203332919"
    const deployedDAOAddress = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    const deployedLayer2CandidateFactory = "0x63c95fbA722613Cb4385687E609840Ed10262434"

    const deployedTitanLayer = "0x4400458626eb4d7fc8f10811e9A2fB0A345a8875"
    const deployedTitanOperator = "0x7afEfd134118B7eCbF25F9E4e73C1aef8BE0603d"
    const deployedThanosLayer = "0x0e5417d597CC19abFb477Fa7e760AdcABDfe60E2"
    const deployedThanosOperator = "0xEE85eD759BcE873e0946448a7Fa922A3f177955F"

    const candidateLayer = "0xabd15c021942ca54abd944c91705fe70fea13f0d"

    before('create fixture loader', async () => {
        const { TON, DAOCommitteeProxy, WTON, DepositManager, SeigManager, powerTonAddress } = await getNamedAccounts();

        const accounts = await ethers.getSigners();
        deployer = accounts[0]
        console.log('deployer', deployer.address)

        daoOwner = await ethers.getSigner(daoOwnerAddress);
        tonContract = new ethers.Contract(TON, Ton_Json.abi,  deployer)
        wtonContract = new ethers.Contract(WTON,  Wton_Json.abi, deployer)
        // daoContract = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeProxy_Json.abi, deployer)
        daoContract = new ethers.Contract(DAOCommitteeProxy,  DAOCommitteeAddV1_1_Json.abi, deployer)
        depositManager = new ethers.Contract(DepositManager,  DepositManager_Json.abi, deployer)
        depositManagerProxy = new ethers.Contract(DepositManager,  DepositManagerProxy_Json.abi, deployer)

        seigManager = new ethers.Contract(SeigManager,  SeigManager_Json.abi, deployer)
        seigManagerProxy = new ethers.Contract(SeigManager,  SeigManagerProxy_Json.abi, deployer)
        seigManagerV1_3 = new ethers.Contract(SeigManager,  SeigManagerV1_3_Json.abi, deployer) as SeigManagerV1_3
        powerTon = powerTonAddress

    })

    /*
    describe('# SeigManager ', () => {

        it('seigManagerV1_3', async () => {
            const l1BridgeRegistry = await seigManagerV1_3.l1BridgeRegistry()
            const layer2Manager = await seigManagerV1_3.layer2Manager()
            const layer2StartBlock = await seigManagerV1_3.layer2StartBlock()
            const l2RewardPerUint = await seigManagerV1_3.l2RewardPerUint()
            const totalLayer2TVL = await seigManagerV1_3.totalLayer2TVL()

            // test1
            // const titan_info = {
            //     systemConfig: "0x1cA73f6E80674E571dc7a8128ba370b8470D4D87",
            //     operator : "0x1A8e48401697DcF297A02c90d3480c35885f8959",
            //     layer2Candidate: "0xeA2c15fdf4cE802Ba188e7D4460D979E9df5fD51"
            // }

            // const thanos_info = {
            //     systemConfig: "0xf8FCFDbdb7C4E734D035A5681Fd1fe08ec85e387",
            //     operator : "0x97f70424857fa4c79B76ef90E057e1FD4b8287Db",
            //     layer2Candidate: "0xF78d3E1f7ca9EFc672969cfc771c6207e3AfEB7E"
            // }

            // test2
            const titan_info = {
                systemConfig: "0x1cA73f6E80674E571dc7a8128ba370b8470D4D87",
                operator : "0x7afEfd134118B7eCbF25F9E4e73C1aef8BE0603d",
                layer2Candidate: "0x4400458626eb4d7fc8f10811e9A2fB0A345a8875"
            }

            const thanos_info = {
                systemConfig: "0xB8209Cc81f0A8Ccdb09238bB1313A039e6BFf741",
                operator : "0xEE85eD759BcE873e0946448a7Fa922A3f177955F",
                layer2Candidate: "0x0e5417d597CC19abFb477Fa7e760AdcABDfe60E2"
            }

            const layer2RewardInfo_titan = await seigManagerV1_3.layer2RewardInfo(titan_info.layer2Candidate)
            const layer2RewardInfo_thanos= await seigManagerV1_3.layer2RewardInfo(thanos_info.layer2Candidate)

            console.log("l1BridgeRegistry", l1BridgeRegistry)
            console.log("layer2Manager", layer2Manager)
            console.log("layer2StartBlock", layer2StartBlock)
            console.log("l2RewardPerUint", l2RewardPerUint)

            console.log("totalLayer2TVL", totalLayer2TVL)
            console.log("layer2RewardInfo_titan", layer2RewardInfo_titan)
            console.log("layer2RewardInfo_thanos", layer2RewardInfo_thanos)

        });

        // it('setLayer2Manager 스토리지 초기화 ', async () => {
        //     const receipt1 = await (await seigManagerV1_3.setLayer2Manager(ethers.constants.AddressZero)).wait()
        //     console.log("setLayer2Manager ", receipt1.transactionHash)
        // });

        // it('setL1BridgeRegistry 스토리지 초기화 ', async () => {
        //     const receipt2 = await (await seigManagerV1_3.setL1BridgeRegistry(ethers.constants.AddressZero)).wait()
        //     console.log("setL1BridgeRegistry", receipt2.transactionHash)

        // });

        // it('setLayer2StartBlock 스토리지 초기화 ', async () => {
        //       const receipt3 = await (await seigManagerV1_3.setLayer2StartBlock(ethers.constants.Zero)).wait()

        //       console.log("setLayer2StartBlock", receipt3.transactionHash)

        // });

        // it('resetL2RewardPerUint 스토리지 초기화 ', async () => {
        //     const receipt4 = await (await seigManagerV1_3.resetL2RewardPerUint()).wait()
        //    console.log("resetL2RewardPerUint", receipt4.transactionHash)

        // });

    })
    */
   /*
    describe('# DepositManager ', () => {

        it('depositManager', async () => {
            const ton = await depositManager.ton()
            const minDepositGasLimit = await  depositManager.minDepositGasLimit()

            console.log("ton", ton)
            console.log("minDepositGasLimit", minDepositGasLimit)

            const l1BridgeRegistry = await  depositManager.l1BridgeRegistry()
            const layer2Manager = await  depositManager.layer2Manager()
            console.log("l1BridgeRegistry", l1BridgeRegistry)
            console.log("layer2Manager", layer2Manager)

        });
    })
    */

    describe('# DAOCommittee ', () => {

        it('daoContract', async () => {
            const layer2Manager = await daoContract.layer2Manager()
            const candidateAddOnFactory = await  daoContract.candidateAddOnFactory()

            console.log("layer2Manager", layer2Manager)
            console.log("candidateAddOnFactory", candidateAddOnFactory)

        });

    })

});

