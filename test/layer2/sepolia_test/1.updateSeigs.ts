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

describe('CandidateAddOnV1_1', () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let legacySystemConfigTest2: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorV1_1:OperatorManagerV1_1 , operatorFactory: OperatorManagerFactory, daoCommitteeAddV1_1: DAOCommitteeAddV1_1

    let layer2CandidateV1_1Imp: CandidateAddOnV1_1
    let layer2CandidateFactoryImp:CandidateAddOnFactory , layer2CandidateFactoryProxy: CandidateAddOnFactoryProxy, layer2CandidateFactory: Layer2CandidateFactory
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
        seigManagerV1_3 = new ethers.Contract(SeigManager,  SeigManagerV1_3_Json.abi, deployer) as SeigManagerV1_3
        powerTon = powerTonAddress

        // const deployedLegacySystemConfig = await deployments.get("LegacySystemConfig")
        // const deployedLayer2ManagerProxy = await deployments.get("Layer2ManagerProxy")
        // const deployedLayer2ManagerV1_1 = await deployments.get("Layer2ManagerV1_1")
        // const deployedOperatorFactory = await deployments.get("OperatorFactory")
        // legacySystemConfig = new ethers.Contract(deployedLegacySystemConfig.address, deployedLegacySystemConfig.abi,  deployer) as LegacySystemConfig
        // layer2Manager = new ethers.Contract(deployedLayer2ManagerProxy.address, deployedLayer2ManagerV1_1.abi,  deployer) as Layer2ManagerV1_1
        // operatorFactory = new ethers.Contract(deployedOperatorFactory.address, deployedOperatorFactory.abi,  deployer) as OperatorFactory


        legacySystemConfig = new ethers.Contract(deployedLegacySystemConfigAddress, LegacySystemConfig_Json.abi,  deployer) as LegacySystemConfig
        layer2Manager = new ethers.Contract(deployedLayer2ManagerProxyAddress, Layer2ManagerV1_1_Json.abi,  deployer) as Layer2ManagerV1_1
        operatorFactory = new ethers.Contract(deployedOperatorFactoryAddress, OperatorFactory_Json.abi,  deployer) as OperatorManagerFactory
        layer2ManagerProxy = new ethers.Contract(deployedLayer2ManagerProxyAddress, Layer2ManagerProxy_Json.abi,  deployer) as Layer2ManagerProxy
        // daoContract = new ethers.Contract(deployedDAOAddress, Layer2ManagerProxy_Json.abi,  deployer) as Layer2ManagerProxy


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

    describe('# 1.updateSeigs ', () => {

        it('upgrade Logic SeigManagerV1_3', async () => {
            const SeigManagerV1_3Dep = await ethers.getContractFactory("SeigManagerV1_3");
            const SeigManagerV1_3Logic = await SeigManagerV1_3Dep.deploy();
            await SeigManagerV1_3Logic.deployed()

            const selector1 = encodeFunctionSignature("setLayer2StartBlock(uint256)");
            const selector2 = encodeFunctionSignature("setLayer2Manager(address)");
            const selector3 = encodeFunctionSignature("setL1BridgeRegistry(address)");
            const selector4 = encodeFunctionSignature("updateSeigniorage()");
            const selector5 = encodeFunctionSignature("updateSeigniorageOperator()");
            const selector6 = encodeFunctionSignature("updateSeigniorageLayer()");
            const selector7 = encodeFunctionSignature("allowIssuanceLayer2Seigs()");
            const selector8 = encodeFunctionSignature("totalLayer2TVL()");
            const selector9 = encodeFunctionSignature("layer2RewardInfo(address)");
            const selector10 = encodeFunctionSignature("l1BridgeRegistry()");
            const selector11 = encodeFunctionSignature("layer2Manager()");
            const selector12 = encodeFunctionSignature("layer2StartBlock()");
            const selector13 = encodeFunctionSignature("l2RewardPerUint()");
            const selector14 = encodeFunctionSignature("unSettledReward(address)");
            const selector15 = encodeFunctionSignature("estimatedDistribute(uint256,address,bool)");

            const selector16 = encodeFunctionSignature("excludeFromSeigniorage(address)");
            const selector17 = encodeFunctionSignature("unallocatedSeigniorage()");
            const selector18 = encodeFunctionSignature("unallocatedSeigniorageAt(uint256)");
            const selector19 = encodeFunctionSignature("stakeOfAllLayers()");
            const selector20 = encodeFunctionSignature("stakeOfAllLayersAt(uint256)");

            let functionBytecodes = [
                selector1, selector2, selector3, selector4, selector5,
                selector6, selector7, selector8, selector9, selector10,
                selector11, selector12, selector13, selector14, selector15
                , selector16,
                selector17, selector18, selector19, selector20
            ];

            await (await seigManagerProxy.connect(daoOwner).setImplementation2(
                SeigManagerV1_3Logic.address, 1, true
            )).wait()

            await (await seigManagerProxy.connect(daoOwner).setSelectorImplementations2(
                functionBytecodes, SeigManagerV1_3Logic.address
            )).wait()

        })

        // it('view', async () => {

        //     let block1 = await ethers.provider.getBlock('latest')
        //     let seigPerBlock = ethers.BigNumber.from("3920000000000000000000000000")
        //     let OneBalance =  await tonContract.balanceOf("0000000000000000000000000000000000000001")
        //     let tos = await seigManagerV1_3.totalSupplyOfTon()
        //     let seigStartBlock = await seigManager.seigStartBlock()
        //     let burntAmountAtDAO = await seigManager.burntAmountAtDAO()
        //     let initialTotalSupply = await seigManager.initialTotalSupply()
        //     let span = block1.number - seigStartBlock.toNumber()
        //     let seigs = seigPerBlock.mul(ethers.BigNumber.from(""+span))

        //     console.log('tos', ethers.utils.formatUnits(tos, 27))
        //     console.log('initialTotalSupply', ethers.utils.formatUnits(initialTotalSupply, 27) )

        //     console.log('seigs', ethers.utils.formatUnits(seigs, 27))
        //     console.log('OneBalance', ethers.utils.formatUnits(OneBalance, 18))
        //     console.log('burntAmountAtDAO', ethers.utils.formatUnits(burntAmountAtDAO, 27))


        //     let l1bridgeBalance =  await tonContract.balanceOf("0x1F032B938125f9bE411801fb127785430E7b3971")
        //     console.log('l1bridgeBalance', ethers.utils.formatUnits(l1bridgeBalance, 18))

        // })

        it('candidateLayer updateSeigniorage', async () => {

            let stakeOf = await seigManager["stakeOf(address,address)"](candidateLayer, tonHave.address);
            console.log("stakeOf", stakeOf)

            const Candidate1 = new ethers.Contract(candidateLayer,  Layer2Candidate_Json.abi, deployer)

            const gasEstimated =  await Candidate1.connect(tonHave).estimateGas["updateSeigniorage()"]()
            console.log("gasEstimated", gasEstimated)

            const receipt = await (await Candidate1.connect(tonHave)["updateSeigniorage()"]()).wait()
            // console.log("receipt", receipt)
            let stakeOf1 = await seigManager["stakeOf(address,address)"](candidateLayer, tonHave.address);
            console.log("stakeOf1", stakeOf1)

            const topic = seigManagerV1_3.interface.getEventTopic('SeigGiven2');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManagerV1_3.interface.parseLog(log);
            console.log("deployedEvent.args", deployedEvent.args)


        })

        it('TitanCandidate updateSeigniorage', async () => {

            let stakeOf = await seigManager["stakeOf(address,address)"](deployedTitanLayer, tonHave.address);
            console.log("stakeOf", stakeOf)

            const TitanCandidate = new ethers.Contract(deployedTitanLayer,  Layer2Candidate_Json.abi, deployer)

            const gasEstimated =  await TitanCandidate.connect(tonHave).estimateGas["updateSeigniorage()"]()
            console.log("gasEstimated", gasEstimated)

            const receipt = await (await TitanCandidate.connect(tonHave)["updateSeigniorage()"]()).wait()
            // console.log("receipt", receipt)
            let stakeOf1 = await seigManager["stakeOf(address,address)"](deployedTitanLayer, tonHave.address);
            console.log("stakeOf1", stakeOf1)

            const topic = seigManagerV1_3.interface.getEventTopic('SeigGiven2');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = seigManagerV1_3.interface.parseLog(log);
            console.log("deployedEvent.args", deployedEvent.args)


        })

    //     it('evm_mine', async () => {
    //         ethers.provider.send("evm_increaseTime", [60*60*24])
    //         ethers.provider.send("evm_mine");

    //         await mine(7200, { interval: 12 });

    //     });

    //     it('TitanCandidate updateSeigniorage', async () => {

    //         let stakeOf = await seigManager["stakeOf(address,address)"](deployedTitanLayer, tonHave.address);
    //         console.log("stakeOf", stakeOf)

    //         const TitanCandidate = new ethers.Contract(deployedTitanLayer,  Layer2Candidate_Json.abi, deployer)

    //         const gasEstimated =  await TitanCandidate.connect(tonHave).estimateGas["updateSeigniorage()"]()
    //         console.log("gasEstimated", gasEstimated)

    //         const receipt = await (await TitanCandidate.connect(tonHave)["updateSeigniorage()"]()).wait()
    //         // console.log("receipt", receipt)
    //         let stakeOf1 = await seigManager["stakeOf(address,address)"](deployedTitanLayer, tonHave.address);
    //         console.log("stakeOf1", stakeOf1)

    //         const topic = seigManagerV1_3.interface.getEventTopic('SeigGiven2');
    //         const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
    //         const deployedEvent = seigManagerV1_3.interface.parseLog(log);
    //         console.log("deployedEvent", deployedEvent)

    //     })
    })

});

