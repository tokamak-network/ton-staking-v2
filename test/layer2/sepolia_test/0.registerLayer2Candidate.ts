import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts, deployments} from 'hardhat'

import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract } from 'ethers'
import { padLeft } from 'web3-utils'

import {encodeFunctionSignature} from 'web3-eth-abi'
import { marshalString, unmarshalString } from '../../shared/marshal';

import { L2RegistryProxy } from "../../../typechain-types/contracts/layer2/L2RegistryProxy"
import { L2RegistryV1_1 } from "../../../typechain-types/contracts/layer2/L2RegistryV1_1.sol"
import { Layer2ManagerProxy } from "../../../typechain-types/contracts/layer2/Layer2ManagerProxy"
import { Layer2ManagerV1_1 } from "../../../typechain-types/contracts/layer2/Layer2ManagerV1_1.sol"
import { OperatorFactory } from "../../../typechain-types/contracts/layer2/factory/OperatorFactory.sol"
import { OperatorV1_1 } from "../../../typechain-types/contracts/layer2/OperatorV1_1.sol"
import { DAOCommitteeAddV1_1 } from "../../../typechain-types/contracts/dao/DAOCommitteeAddV1_1.sol"
import { Layer2CandidateFactoryProxy } from "../../../typechain-types/contracts/dao/factory/Layer2CandidateFactoryProxy"
import { Layer2CandidateFactory } from "../../../typechain-types/contracts/dao/factory/Layer2CandidateFactory.sol"

import { Layer2CandidateV1_1 } from "../../../typechain-types/contracts/dao/Layer2CandidateV1_1.sol"
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
import OperatorFactory_Json from '../../../artifacts/contracts/layer2/factory/OperatorFactory.sol/OperatorFactory.json'
import Layer2ManagerProxy_Json from '../../../artifacts/contracts/layer2/Layer2ManagerProxy.sol/Layer2ManagerProxy.json'

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
    let l2RegistryProxy: L2RegistryProxy, l2RegistryV_1: L2RegistryV1_1, l2Registry: L2RegistryV1_1

    let legacySystemConfig: LegacySystemConfig
    let legacySystemConfigTest2: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2ManagerV1_1: Layer2ManagerV1_1, layer2Manager: Layer2ManagerV1_1
    let operatorV1_1:OperatorV1_1 , operatorFactory: OperatorFactory, daoCommitteeAddV1_1: DAOCommitteeAddV1_1

    let layer2CandidateV1_1Imp: Layer2CandidateV1_1
    let layer2CandidateFactoryImp:Layer2CandidateFactory , layer2CandidateFactoryProxy: Layer2CandidateFactoryProxy, layer2CandidateFactory: Layer2CandidateFactory
    let tonContract: Contract, wtonContract: Contract, daoContract: Contract, daoV2Contract: Contract
    let depositManager: Contract,  depositManagerProxy: Contract, seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3;
    let depositManagerV1_1: DepositManagerV1_1;

    let daoAdmin: Signer;
    let daoOwner: Signer;

    let titanLayerAddress: string, titanOperatorContractAddress: string;
    let titanLayerContract: Layer2CandidateV1_1;
    let titanOperatorContract: OperatorV1_1

    let thanosLayerAddress: string, thanosOperatorContractAddress: string;
    let thanosLayerContract: Layer2CandidateV1_1;
    let thanosOperatorContract: OperatorV1_1


    let powerTon: string
    let pastDepositor:Signer, wtonHave:Signer, tonHave:Signer
    let layer2Info_1 : any;
    let layer2Info_2 : any;

    let daoContractAdd : DAOCommitteeAddV1_1;
    const deployedLegacySystemConfigAddress = "0x1cA73f6E80674E571dc7a8128ba370b8470D4D87"
    const deployedLayer2ManagerProxyAddress = "0x0237839A14194085B5145D1d1e1E77dc92aCAF06"
    const deployedOperatorFactoryAddress = "0xBB8e650d9BB5c44E54539851636DEFEF37585E67"
    const deployedDAOAddress = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    const deployedLayer2CandidateFactory = "0x770739A468D9262960ee0669f9Eaf0db6E21F81A"

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

        // const deployedLegacySystemConfig = await deployments.get("LegacySystemConfig")
        // const deployedLayer2ManagerProxy = await deployments.get("Layer2ManagerProxy")
        // const deployedLayer2ManagerV1_1 = await deployments.get("Layer2ManagerV1_1")
        // const deployedOperatorFactory = await deployments.get("OperatorFactory")
        // legacySystemConfig = new ethers.Contract(deployedLegacySystemConfig.address, deployedLegacySystemConfig.abi,  deployer) as LegacySystemConfig
        // layer2Manager = new ethers.Contract(deployedLayer2ManagerProxy.address, deployedLayer2ManagerV1_1.abi,  deployer) as Layer2ManagerV1_1
        // operatorFactory = new ethers.Contract(deployedOperatorFactory.address, deployedOperatorFactory.abi,  deployer) as OperatorFactory


        legacySystemConfig = new ethers.Contract(deployedLegacySystemConfigAddress, LegacySystemConfig_Json.abi,  deployer) as LegacySystemConfig
        layer2Manager = new ethers.Contract(deployedLayer2ManagerProxyAddress, Layer2ManagerV1_1_Json.abi,  deployer) as Layer2ManagerV1_1
        operatorFactory = new ethers.Contract(deployedOperatorFactoryAddress, OperatorFactory_Json.abi,  deployer) as OperatorFactory
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

    describe('# registerLayer2Candidate ', () => {
        it('upgrade Logic Layer2ManagerV1_1', async () => {
            const Layer2ManagerV1_1Dep = await ethers.getContractFactory("Layer2ManagerV1_1");
            const Layer2ManagerV1_1Logic = await Layer2ManagerV1_1Dep.deploy();
            await Layer2ManagerV1_1Logic.deployed()

            await layer2ManagerProxy.connect(tonHave).upgradeTo(Layer2ManagerV1_1Logic.address)

        })

        it('upgrade Logic DAOCommitteeAddV1_1', async () => {
            const DAOCommitteeAddV1_1Dep = await ethers.getContractFactory("DAOCommitteeAddV1_1");
            const DAOCommitteeAddV1_1Logic = await DAOCommitteeAddV1_1Dep.deploy();
            await DAOCommitteeAddV1_1Logic.deployed()

            await daoContract.connect(tonMinter).upgradeTo(DAOCommitteeAddV1_1Logic.address)

            daoContractAdd = new ethers.Contract(daoContract.address, DAOCommitteeAddV1_1_Json.abi,  deployer) as DAOCommitteeAddV1_1


            console.log('layer2ManagerProxy', layer2ManagerProxy.address)
            console.log('daoContractAdd', daoContractAdd.address)

            let layer2ManagerAddress = await daoContractAdd.layer2Manager();
            console.log('layer2ManagerAddress', layer2ManagerAddress)
            if (layer2ManagerAddress != layer2ManagerProxy.address ) {
                await (await daoContractAdd.connect(tonMinter).setLayer2Manager(layer2ManagerProxy.address)).wait()
            }

            let layer2CandidateFactoryAddress = await daoContractAdd.layer2CandidateFactory();
            console.log('layer2CandidateFactoryAddress', layer2CandidateFactoryAddress)
            if (layer2CandidateFactoryAddress != deployedLayer2CandidateFactory ) {
                await (await daoContractAdd.connect(tonMinter).setLayer2CandidateFactory(deployedLayer2CandidateFactory)).wait()
            }

        })

        it('registerLayer2Candidate', async () => {

            let issueStatusLayer2 = await layer2Manager.issueStatusLayer2(legacySystemConfig.address)
            console.log("issueStatusLayer2", issueStatusLayer2)
            const amount = await layer2Manager.minimumInitialDepositAmount();
            console.log("amount", amount)
            const name = await legacySystemConfig.name()
            console.log("name", name)


            const operatorAddress = await operatorFactory.getAddress(legacySystemConfig.address)
            console.log("operatorAddress", operatorAddress)

            console.log("tonHave", tonHave.address)
            let allowance = await tonContract.allowance(tonHave.address, layer2Manager.address)
            console.log("allowance", allowance)

            // if(allowance.lt(amount)){
            //     await tonContract.connect(addr1).approve(layer2Manager.address, amount);
            // }

            const gasEstimated =  await layer2Manager.connect(tonHave).estimateGas.registerLayer2Candidate(
                legacySystemConfig.address,
                amount,
                true,
                name
            )
            console.log("gasEstimated", gasEstimated)

            // const receipt = await (await layer2Manager.connect(addr1).registerLayer2Candidate(
            //     legacySystemConfig.address,
            //     amount,
            //     true,
            //     name
            // )).wait()
            // console.log("receipt", receipt)

            // const topic = layer2Manager.interface.getEventTopic('RegisteredLayer2Candidate');
            // const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            // const deployedEvent = layer2Manager.interface.parseLog(log);
            // console.log("deployedEvent", deployedEvent)

            // expect(deployedEvent.args.systemConfig).to.be.eq(legacySystemConfig.address)
            // expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            // expect(deployedEvent.args.memo).to.be.eq(name)
            // expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            // expect(deployedEvent.args.layer2Candidate).to.be.not.eq(ethers.constants.AddressZero)

            // titanLayerAddress = deployedEvent.args.layer2Candidate;
            // titanOperatorContractAddress = deployedEvent.args.operator;
            // expect((await layer2Manager.issueStatusLayer2(legacySystemConfig.address))).to.be.eq(1)

            // titanLayerContract =  (await ethers.getContractAt("Layer2CandidateV1_1", titanLayerAddress, deployer)) as Layer2CandidateV1_1
            // titanOperatorContract = (await ethers.getContractAt("OperatorV1_1", titanOperatorContractAddress, deployer)) as OperatorV1_1
        })

    })
});
