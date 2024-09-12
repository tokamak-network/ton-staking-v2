import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts, deployments} from 'hardhat'

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

describe('Layer2Manager', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let legacySystemConfigTest2: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorV1_1:OperatorManagerV1_1 , operatorFactory: OperatorManagerFactory, daoCommitteeAddV1_1: DAOCommitteeAddV1_1

    let layer2CandidateV1_1Imp: CandidateAddOnV1_1
    let layer2CandidateFactoryImp:CandidateAddOnFactory , layer2CandidateFactoryProxy: CandidateAddOnFactoryProxy, layer2CandidateFactory: CandidateAddOnFactory
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


    let powerTon: string
    let pastDepositor:Signer, wtonHave:Signer, tonHave:Signer
    let layer2Info_1 : any;
    let layer2Info_2 : any;

    let daoContractAdd : DAOCommitteeAddV1_1;
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

        legacySystemConfig = new ethers.Contract(deployedLegacySystemConfigAddress, LegacySystemConfig_Json.abi,  deployer) as LegacySystemConfig
        layer2Manager = new ethers.Contract(deployedLayer2ManagerProxyAddress, Layer2ManagerV1_1_Json.abi,  deployer) as Layer2ManagerV1_1
        operatorFactory = new ethers.Contract(deployedOperatorFactoryAddress, OperatorFactory_Json.abi,  deployer) as OperatorFactory
        layer2ManagerProxy = new ethers.Contract(deployedLayer2ManagerProxyAddress, Layer2ManagerProxy_Json.abi,  deployer) as Layer2ManagerProxy

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

    })

    // describe('# upgradeTo Layer2ManagerV1_1 ', () => {
    //     it('deploy', async () => {
    //         const layer2ManagerV1_1 = (await (await ethers.getContractFactory("Layer2ManagerV1_1")).connect(deployer).deploy()) as L1BridgeRegistryV1_1;

    //         await (await layer2ManagerProxy.connect(tonHave).upgradeTo(layer2ManagerV1_1.address)).wait()

    //     });
    // })

    describe('# upgradeTo DepositManagerV1_1 ', () => {
        it('deploy', async () => {
            const depositManagerV1_1 = (await (await ethers.getContractFactory("DepositManagerV1_1")).connect(deployer).deploy()) as DepositManagerV1_1;

            const selector1 = encodeFunctionSignature("ton()");
            const selector2 = encodeFunctionSignature("minDepositGasLimit()");
            const selector3 = encodeFunctionSignature("setMinDepositGasLimit(uint256)");
            const selector4 = encodeFunctionSignature("withdrawAndDepositL2(address,uint256)");

            let functionBytecodes = [
                selector1, selector2, selector3, selector4 ];

            const index = 2;
            // expect(await depositManagerProxy.implementation2(index)).to.be.eq(ethers.constants.AddressZero)

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

        });
    })

    describe('# withdrawAndDepositL2 ', () => {


        it('withdrawAndDepositL2 : deployedTitanLayer', async () => {

            let stakeOf = await seigManager["stakeOf(address,address)"](deployedTitanLayer, tonHave.address);
            console.log("stakeOf", stakeOf)

            const depositManagerV1 = new ethers.Contract(depositManager.address,  DepositManagerV1_1_Json.abi, deployer)
            const amount = ethers.utils.parseEther("10"+"0".repeat(9))
            const gasEstimated =  await depositManagerV1.connect(tonHave).estimateGas.withdrawAndDepositL2(
                deployedTitanLayer,
                amount
            )
            // console.log("gasEstimated", gasEstimated)

            const receipt = await (await depositManagerV1.connect(tonHave).withdrawAndDepositL2(
                deployedTitanLayer,
                amount
            )).wait()
            // console.log("receipt", receipt)
            let stakeOf1 = await seigManager["stakeOf(address,address)"](deployedTitanLayer, tonHave.address);
            // console.log("stakeOf1", stakeOf1)

            const topic = depositManagerV1.interface.getEventTopic('WithdrawalAndDeposited');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = depositManagerV1.interface.parseLog(log);
            console.log("deployedEvent.args", deployedEvent.args)

        })


        // it('withdrawAndDepositL2 : deployedThanosLayer', async () => {

        //     let stakeOf = await seigManager["stakeOf(address,address)"](deployedThanosLayer, tonHave.address);
        //     // console.log("stakeOf", stakeOf)

        //     const depositManagerV1 = new ethers.Contract(depositManager.address,  DepositManagerV1_1_Json.abi, deployer)
        //     const amount = ethers.utils.parseEther("10"+"0".repeat(9))
        //     const gasEstimated =  await depositManagerV1.connect(tonHave).estimateGas.withdrawAndDepositL2(
        //         deployedThanosLayer,
        //         amount
        //     )
        //     // console.log("gasEstimated", gasEstimated)

        //     const receipt = await (await depositManagerV1.connect(tonHave).withdrawAndDepositL2(
        //         deployedThanosLayer,
        //         amount
        //     )).wait()
        //     // console.log("receipt", receipt)
        //     let stakeOf1 = await seigManager["stakeOf(address,address)"](deployedThanosLayer, tonHave.address);
        //     // console.log("stakeOf1", stakeOf1)

        //     const topic = depositManagerV1.interface.getEventTopic('WithdrawalAndDeposited');
        //     const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        //     const deployedEvent = depositManagerV1.interface.parseLog(log);
        //     // console.log("deployedEvent", deployedEvent)


        // })

    })


});

