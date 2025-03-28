import { expect } from '../../shared/expect'
import { ethers, network, getNamedAccounts, deployments} from 'hardhat'

import { mine, time } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumber, Signer, utils, Contract, Bytes } from 'ethers'
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
import { CandidateProxy } from "../../../typechain-types/contracts/dao/CandidateProxy"

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

let zeroAddr = "0x0000000000000000000000000000000000000000";

function roundDown(val:BigNumber, decimals:number) {
    return ethers.utils.formatUnits(val, decimals).split(".")[0]
}

async function execAllowance(contract: any, fromSigner: Signer, toAddress: string, amount: BigNumber) {
    let allowance = await contract.allowance(fromSigner.address, toAddress);
    if (allowance.lt(amount)) {
        await contract.connect(fromSigner).approve(toAddress, amount);
    }
}

function stringToBytes(str: string): number[] {
    const buffer = Buffer.from(str, 'utf8');
    return Array.from(buffer);
}

describe("DEV DAO Test on Sepolia (About Upgraded StakingV2.5)", () => {
    //member : user1, layer2Operator
    //blackList : user2
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer, user1: Signer, user2: Signer, user3: Signer

    let daoOwner: Signer;
    let wtonHave:Signer, tonHave:Signer

    let candidateAddOnV1_1Imp: CandidateAddOnV1_1
    let candidateAddOnFactoryImp:CandidateAddOnFactory , candidateAddOnFactoryProxy: CandidateAddOnFactoryProxy, candidateAddOnFactory: CandidateAddOnFactory
    let tonContract: Contract, wtonContract: Contract, faucetContract: Faucetv2
    let daoCommitteeProxy: Contract, daoContract: Contract, daoV2Contract: Contract, daoAgendaManager: Contract

    let legacySystemConfig: LegacySystemConfig
    let layer2ManagerProxy: Layer2ManagerProxy, layer2Manager: Layer2ManagerV1_1
    let layer2Registry: Layer2Registry;

    let titanLayerAddress: string, titanOperatorContractAddress: string;
    let titanLayerContract: CandidateAddOnV1_1;
    let titanOperatorContract: OperatorManagerV1_1

    let seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3, seigManagerV1_2: SeigManagerV1_2;

    let depositManager: Contract,  depositManagerProxy: Contract;
    let depositManagerV1_1: DepositManagerV1_1;    

    let daoVaultContract: Contract

    let daoAgendaManagerContract: Contract
    let daoCommitteeProxy2Contract: DAOCommitteeProxy2
    let daoCommittee_V1: DAOCommittee_V1
    let daoCommitteeOwner: DAOCommitteeOwner
    let daoCommitteeContract:  Contract

    let user1CandidateContract: Candidate
    let user1CandidateProxyContract: Contract
    let user2CandidateContract: Contract
    let layer2privateCandidateContract: Contract

    let multiSigWalletContract: Contract

    let layer2Operator: Signer;
    let l1BridgeRegistryProxy: L1BridgeRegistryProxy, l1BridgeRegistryV_1: L1BridgeRegistryV1_1, l1BridgeRegistry: L1BridgeRegistryV1_1
    let operatorManagerFactory: OperatorManagerFactory

    interface CandidateType {
        address: string,
        contract: Candidate | CandidateAddOnV1_1 | any
    }

    let candidate1 : CandidateType
    let candidate2 : CandidateType
    let candidateAddOn1 : CandidateType
    let layer2Candidate1 : CandidateType

    let mockLayer2: MockLayer2
    let privatelayer2: MockLayer2

    let deployed : any

    let agendaID : any

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



    before('create fixture loadter', async () => {
        const accounts = await ethers.getSigners();

        deployer = accounts[0]
        manager = accounts[1]
        addr1 = accounts[2]
        addr2 = accounts[3]
        user1 = accounts[4]
        user2 = accounts[5]
        user3 = accounts[6]
        layer2Operator = addr2

        // console.log(user1.address)

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
    })

    describe("Contract from deployments", () => {
        it("deployments", async () => {
            await deployments.fixture();
            deployed = await deployments.all()

            tonContract = new ethers.Contract(deployed.TON.address, Ton_Json.abi,  deployer)
            wtonContract = new ethers.Contract(deployed.WTON.address,  Wton_Json.abi, deployer)

            faucetContract = await ethers.getContractAt("Faucetv2", deployed.Faucetv2.address, deployer) as Faucetv2

            daoCommitteeProxy = new ethers.Contract(deployed.DAOCommitteeProxy.address,  DAOCommitteeProxy_JSON.abi, deployer)
            daoCommitteeContract = new ethers.Contract(deployed.DAOCommitteeProxy.address, DAOCommittee_V1_Json.abi,  deployer)
            daoAgendaManagerContract = new ethers.Contract(deployed.DAOAgendaManager.address, DAOAgendaManager_JSON.abi,  deployer)

            daoVaultContract = new ethers.Contract(deployed.DAOVault.address, DAOVault_JSON.abi, deployer)

            daoCommitteeProxy2Contract = (await ethers.getContractAt("DAOCommitteeProxy2", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommitteeProxy2;
            daoCommitteeOwner = (await ethers.getContractAt("DAOCommitteeOwner", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommitteeOwner;
            daoCommittee_V1 = (await ethers.getContractAt("DAOCommittee_V1", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommittee_V1;

            
            seigManagerV1_2 = (await ethers.getContractAt("SeigManagerV1_2", deployed.SeigManagerProxy.address, deployer)) as SeigManagerV1_2;
            seigManagerV1_3 = (await ethers.getContractAt("SeigManagerV1_3", deployed.SeigManagerProxy.address, deployer)) as SeigManagerV1_3;
            seigManager = new ethers.Contract(deployed.SeigManagerProxy.address,  SeigManager_Json.abi, deployer)
            
            depositManagerV1_1 = (await ethers.getContractAt("DepositManagerV1_1", deployed.DepositManagerProxy.address, deployer)) as DepositManagerV1_1;
            depositManager = (await ethers.getContractAt("DepositManager", deployed.DepositManagerProxy.address, deployer)) as DepositManagerV1_1;
            
            multiSigWalletContract = new ethers.Contract(deployed.MultiSigWallet.address,  MultiSigWallet_JSON.abi, deployer)
            
            layer2ManagerProxy = (await ethers.getContractAt("Layer2ManagerProxy", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerProxy;
            layer2Manager = (await ethers.getContractAt("Layer2ManagerV1_1", deployed.Layer2ManagerProxy.address, deployer)) as Layer2ManagerV1_1;
            
            layer2Registry = (await ethers.getContractAt("Layer2Registry", deployed.Layer2RegistryProxy.address, deployer)) as Layer2Registry;

            l1BridgeRegistryProxy = (await ethers.getContractAt("L1BridgeRegistryProxy", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryProxy
            l1BridgeRegistry = (await ethers.getContractAt("L1BridgeRegistryV1_1", deployed.L1BridgeRegistryProxy.address, deployer)) as L1BridgeRegistryV1_1
            operatorManagerFactory = (await ethers.getContractAt("OperatorManagerFactory", deployed.OperatorManagerFactory.address, deployer)) as OperatorManagerFactory;

            await hre.network.provider.send("hardhat_impersonateAccount", [
                daoCommitteeProxy.address,
            ]);
            await hre.network.provider.send("hardhat_setBalance", [
                daoCommitteeProxy.address,
                "0x10000000000000000000000000",
            ]);
            manager =  await hre.ethers.getSigner(daoCommitteeProxy.address);
        })
    })

    describe("transfer Owner", () => {
        it("daoAgendaManagerContract transfer Owner", async () => {
            let checkOwner = await daoAgendaManagerContract.owner()
            if ( checkOwner !=  daoCommitteeProxy.address) {
                await daoAgendaManagerContract.connect(deployer).transferOwnership(daoCommitteeProxy.address)
            }
            checkOwner = await daoAgendaManagerContract.owner()
            expect(checkOwner.toLowerCase()).to.be.equal(daoCommitteeProxy.address.toLowerCase())
        });

        it("daoVaultContract transfer Owner", async () => {
            let checkOwner = await daoVaultContract.owner()
            if ( checkOwner !=  daoCommitteeProxy.address) {
                await daoVaultContract.connect(deployer).transferOwnership(daoCommitteeProxy.address)
            }
            checkOwner = await daoVaultContract.owner()
            expect(checkOwner.toLowerCase()).to.be.equal(daoCommitteeProxy.address.toLowerCase())
        })

        it("daoVault Have WTON", async () => {
            let amount = ethers.utils.parseEther("10000000000000")
            await (await faucetContract.connect(deployer).transferToken2(daoVaultContract.address, amount)).wait()
        })

        it("seigManager transfer Owner", async () => {
            let checkOwner = await seigManager.isAdmin(daoCommitteeProxy.address)
            if ( checkOwner ==  false) {
                await seigManager.connect(deployer).addAdmin(daoCommitteeProxy.address)
            }
            checkOwner = await seigManager.isAdmin(daoCommitteeProxy.address)
            expect(checkOwner).to.be.equal(true)
        })

        it("depositManager transfer Owner", async () => {
            let checkOwner = await depositManager.isAdmin(daoCommitteeProxy.address)
            if ( checkOwner ==  false) {
                await depositManager.connect(deployer).addAdmin(daoCommitteeProxy.address)
            }
            checkOwner = await depositManager.isAdmin(daoCommitteeProxy.address)
            expect(checkOwner).to.be.equal(true)
        })

        it("give the Admin Role", async () => {
            let adminRole = "0x0000000000000000000000000000000000000000000000000000000000000000"
            let getRoleAdmin = await daoCommitteeProxy.getRoleAdmin(adminRole);
            // console.log(getRoleAdmin)
            let beforehasRole = await daoCommitteeProxy.hasRole(
                getRoleAdmin,
                multiSigWalletContract.address
            )
            expect(beforehasRole).to.be.equal(false);

            await daoCommitteeProxy.connect(deployer).grantRole(
                getRoleAdmin,
                multiSigWalletContract.address
            )

            let roleCheck = await daoCommitteeProxy.hasRole(
                getRoleAdmin,
                multiSigWalletContract.address
            )

            expect(roleCheck).to.be.equal(true)
        })
    })

    describe("registerLayer2CandidateByOwner Test", ()=> {
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
                contract: candidateContract
            }
            privatelayer2 = mockLayer2;
        });


        it("set layer2privateCandidateContract", async () => {
            let candidateInfo = await daoCommittee_V1.candidateInfos(mockLayer2.address)
            
            layer2privateCandidateContract = (await ethers.getContractAt("Candidate", candidateInfo.candidateContract, deployer)) as Candidate;

            layer2Candidate1 = {
                address : candidateInfo.candidateContract,
                contract: layer2privateCandidateContract
            }
        })

        it("privateLayer2 Check", async () => {
            let privateLayer2Check = await daoCommittee_V1.privateLayer2(mockLayer2.address);
            // console.log("privateLayer2Check :", privateLayer2Check)
            expect(privateLayer2Check).to.be.equal(true)
        })

        it("operatorAmountCheck", async () => {
            let operatorAmountCheck = await daoCommittee_V1.operatorAmountCheck(mockLayer2.address, layer2Operator.address);
            // console.log("operatorAmountCheck :", operatorAmountCheck)
            expect(operatorAmountCheck).to.be.gt(0)
        })

        it("operatorCheck", async () => {
            let operatorAmount = await daoCommittee_V1.operatorCheck(mockLayer2.address);
            // console.log("operatorAmount :", operatorAmount)
            expect(operatorAmount).to.be.gt(0)
        })
    })

    describe("DAOCommittee_V1 Logic Test", () => {
        it("Storage Check", async () => {
            let dao_V1 = await daoCommittee_V1.pauseProxy()
            let dao_Owner = await daoCommitteeOwner.pauseProxy()
            let proxy1 = await daoCommitteeProxy.pauseProxy()
            let proxy2 = await daoCommitteeProxy2Contract.pauseProxy()

            expect(dao_V1).to.be.equal(dao_Owner)
            expect(proxy1).to.be.equal(proxy2)
            expect(dao_V1).to.be.equal(proxy2)

            let dao_V1cool = await daoCommittee_V1.cooldownTime()
            let dao_Ownercool = await daoCommitteeOwner.cooldownTime()
            let proxy2cool = await daoCommitteeProxy2Contract.cooldownTime()

            expect(dao_V1cool).not.to.be.equal(0)
            expect(dao_V1cool).to.be.equal(dao_Ownercool)
            expect(dao_V1cool).to.be.equal(proxy2cool)

            let dao_V1_wton = await daoCommittee_V1.wton()
            let dao_Owner_wton = await daoCommitteeOwner.wton()
            let proxy2_wton = await daoCommitteeProxy2Contract.wton()

            expect(dao_V1_wton).not.to.be.equal(zeroAddr)
            expect(dao_V1_wton).to.be.equal(dao_Owner_wton)
            expect(dao_V1_wton).to.be.equal(proxy2_wton)

            let dao_V1_layer2Manager = await daoCommittee_V1.layer2Manager()
            let dao_Owner_layer2Manager = await daoCommitteeOwner.layer2Manager()
            let proxy2_layer2Manager = await daoCommitteeProxy2Contract.layer2Manager()

            expect(dao_V1_layer2Manager).not.to.be.equal(zeroAddr)
            expect(dao_V1_layer2Manager).to.be.equal(dao_Owner_layer2Manager)
            expect(dao_V1_layer2Manager).to.be.equal(proxy2_layer2Manager)

            let dao_V1_candidateAddOnFactory = await daoCommittee_V1.candidateAddOnFactory()
            let dao_Owner_candidateAddOnFactory = await daoCommitteeOwner.candidateAddOnFactory()
            let proxy2_candidateAddOnFactory = await daoCommitteeProxy2Contract.candidateAddOnFactory()

            expect(dao_V1_candidateAddOnFactory).not.to.be.equal(zeroAddr)
            expect(dao_V1_candidateAddOnFactory).to.be.equal(dao_Owner_candidateAddOnFactory)
            expect(dao_V1_candidateAddOnFactory).to.be.equal(proxy2_candidateAddOnFactory)
        })


        it("1. createCandidate (anyone)", async () => {
            let beforeCandidateLength = Number(await daoCommittee_V1.candidatesLength())

            let checkalreadyMake = await daoCommittee_V1.candidateContract(user1.address)

            if(checkalreadyMake == zeroAddr) {
                const receipt = await (await daoCommittee_V1.connect(user1).createCandidate(
                    "TestCandidate"
                )).wait()
    
                const topic = daoCommitteeContract.interface.getEventTopic('CandidateContractCreated');
                const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
                const deployedEvent = daoCommitteeContract.interface.parseLog(log);

                let afterCandidateLength = Number(await daoCommittee_V1.candidatesLength())
                expect(afterCandidateLength).to.be.gt(beforeCandidateLength)
    
                let candidateInfo = await daoCommittee_V1.candidateInfos(user1.address)
                // console.log("candidateInfo : ", candidateInfo);
                expect(user1.address).to.be.equal(deployedEvent.args.candidate)
                expect(candidateInfo.candidateContract).to.be.equal(deployedEvent.args.candidateContract)
                expect(candidateInfo.memberJoinedTime).to.be.equal(0)
            } else {
                console.log("already createCandidate");
            }

        })

        it("set user1CandidateContract", async () => {
            let candidateInfo = await daoCommittee_V1.candidateInfos(user1.address)
            
            user1CandidateContract = (await ethers.getContractAt("Candidate", candidateInfo.candidateContract, deployer)) as Candidate;
            user1CandidateProxyContract = (await ethers.getContractAt("CandidateProxy", candidateInfo.candidateContract, deployer)) as CandidateProxy;

            candidate1 = {
                address : candidateInfo.candidateContract,
                contract: user1CandidateContract
            }
        })

        it("privateLayer2 Check", async () => {
            let privateLayer2Check = await daoCommittee_V1.privateLayer2(user1.address);
            // console.log("privateLayer2Check :", privateLayer2Check)
            expect(privateLayer2Check).to.be.equal(false)

            privateLayer2Check = await daoCommittee_V1.privateLayer2(candidate1.address);
            // console.log("privateLayer2Check :", privateLayer2Check)
            expect(privateLayer2Check).to.be.equal(false)
        })

        it("createCandidate operatorAmountCheck", async () => {
            let operatorAmountCheck = await daoCommittee_V1.operatorAmountCheck(candidate1.address, user1.address);
            // console.log("operatorAmountCheck :", operatorAmountCheck)
            expect(operatorAmountCheck).to.be.equal(0)
        })

        it("createCandidate operatorCheck", async () => {
            let operatorAmount = await daoCommittee_V1.operatorCheck(user1.address);
            // console.log("operatorAmount :", operatorAmount)
            expect(operatorAmount).to.be.equal(0)
        })

        it("2. createCandidateOwner (Owner)", async () => {
            // console.log(daoCommittee_V1_Contract)
            let beforeCandidateLength = await daoCommittee_V1.candidatesLength()

            let checkalreadyMake = await daoCommittee_V1.candidateContract(user2.address)

            if(checkalreadyMake == zeroAddr) {
                const receipt = await (await daoCommittee_V1.connect(deployer).createCandidateOwner(
                    "TestCandidate2",
                    user2.address
                )).wait()
    
                const topic = daoCommitteeContract.interface.getEventTopic('CandidateContractCreated');
                const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
                const deployedEvent = daoCommitteeContract.interface.parseLog(log);

                let afterCandidateLength = await daoCommittee_V1.candidatesLength()
                expect(afterCandidateLength).to.be.gt(beforeCandidateLength)
                
                let candidateInfo = await daoCommittee_V1.candidateInfos(user2.address)
                // console.log("candidateInfo : ", candidateInfo);
                expect(user2.address).to.be.equal(deployedEvent.args.candidate)
                expect(candidateInfo.candidateContract).to.be.equal(deployedEvent.args.candidateContract)
                expect(candidateInfo.memberJoinedTime).to.be.equal(0)
            } else {
                console.log("already createCandidate");
            }
        })

        it("set user2CandidateContract", async () => {
            let candidateInfo = await daoCommittee_V1.candidateInfos(user2.address)
            
            user2CandidateContract = (await ethers.getContractAt("Candidate", candidateInfo.candidateContract, deployer)) as Candidate;

            candidate2 = {
                address : candidateInfo.candidateContract,
                contract: user2CandidateContract
            }
        })


        it("3. changeMember (don't staking don't use)", async () => {
            await expect(
                user1CandidateContract.connect(user1).changeMember(
                    0
                )
            ).to.be.revertedWith("need more operatorDeposit");
        })

        it("staking the TON about Candidate1", async () => {
            let amount = ethers.utils.parseEther("2000")

            await depositApproveAndCall(
                candidate1.address,
                user1,
                amount
            )
        })

        it("createCandidate operatorAmountCheck", async () => {
            let operatorAmountCheck = await daoCommittee_V1.operatorAmountCheck(candidate1.address, user1.address);
            // console.log("operatorAmountCheck :", operatorAmountCheck)
            expect(operatorAmountCheck).to.be.gt(0)
        })

        it("createCandidate operatorCheck", async () => {
            let operatorAmount = await daoCommittee_V1.operatorCheck(user1.address);
            // console.log("operatorAmount :", operatorAmount)
            expect(operatorAmount).to.be.gt(0)
        })

        it("4. changeMember (after staking)", async () => {
            let memberCheck = await daoCommittee_V1.members(0)
            expect(memberCheck).to.be.equal(zeroAddr)

            await (
                await user1CandidateContract.connect(user1).changeMember(0)
            ).wait();

            memberCheck = await daoCommittee_V1.members(0)
            expect(memberCheck.toUpperCase()).to.be.equal(user1.address.toUpperCase())
        })

        it("staking the TON about Candidate2", async () => {
            let amount = ethers.utils.parseEther("1500")

            await depositApproveAndCall(
                candidate2.address,
                user2,
                amount
            )
        })

        it("createCandidateOwner operatorAmountCheck", async () => {
            let operatorAmountCheck = await daoCommittee_V1.operatorAmountCheck(candidate2.address, user2.address);
            // console.log("operatorAmountCheck :", operatorAmountCheck)
            expect(operatorAmountCheck).to.be.gt(0)
        })

        it("createCandidateOwner operatorCheck", async () => {
            let operatorAmount = await daoCommittee_V1.operatorCheck(user2.address);
            // console.log("operatorAmount :", operatorAmount)
            expect(operatorAmount).to.be.gt(0)
        })

        it("5. changeMember (If you are not the owner of the CandidateContract, revert)", async () => {
            await expect(
                user1CandidateContract.connect(user2).changeMember(
                    0
                )
            ).to.be.revertedWith("Candidate: sender is not the candidate of this contract");
        })

        it("6. changeMember (not enough amount)", async () => {
            await expect(
                user2CandidateContract.connect(user2).changeMember(
                    0
                )
            ).to.be.revertedWith("not enough amount");
        })

        it("7. changeMember (registerLayer2CandidateByOwner)", async () => {
            let memberCheck = await daoCommittee_V1.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)

            await (
                await layer2privateCandidateContract.connect(layer2Operator).changeMember(1)
            ).wait();

            memberCheck = await daoCommittee_V1.members(1)
            expect(memberCheck.toUpperCase()).to.be.equal(mockLayer2.address.toUpperCase())
        })

        it("8. changeMember cooldown Test", async () => {
            await expect(
                layer2privateCandidateContract.connect(layer2Operator).changeMember(
                    2
                )
            ).to.be.revertedWith("DAOCommittee: need cooldown");
        })


        it("9. retireMember can't execute no Member", async () => {
            await expect(
                user2CandidateContract.connect(user2).retireMember()
            ).to.be.revertedWith("DAOCommittee: not a member");
        })

        it("10. changeMember (createCanidateByOwner)", async () => {
            let memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck).to.be.equal(zeroAddr)

            await (
                await user2CandidateContract.connect(user2).changeMember(2)
            ).wait();

            memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck.toUpperCase()).to.be.equal(user2.address.toUpperCase())
        })
        
        it("11. retireMember (add blackList) (onlyMember)", async () => {
            let memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck.toUpperCase()).to.be.equal(user2.address.toUpperCase())
            // let beforeWTONAmount = await wton.balanceOf(member2.address)
            let blacklistCheck = await daoCommittee_V1.blacklist(user2CandidateContract.address)
            expect(blacklistCheck).to.be.equal(false)

            await (
                await user2CandidateContract.connect(user2).retireMember()
            ).wait();

            memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck).to.be.equal(zeroAddr)

            blacklistCheck = await daoCommittee_V1.blacklist(user2CandidateContract.address)
            expect(blacklistCheck).to.be.equal(true)
        })

        it('increase block time and check votable', async function () {
            const cooldownTime = 86400;
            const currentTime = await time.latest();
            // console.log("2")
            // console.log(currentTime)
            await time.increaseTo(Number(currentTime)+Number(cooldownTime));
            const currentTime2 = await time.latest();
            // console.log(currentTime2)
        });

        it("12. blacklist can't changeMember", async () => {
            await expect(
                user2CandidateContract.connect(user2).changeMember(
                    2
                )
            ).to.be.revertedWith("DAOCommittee: blacklisted member");
        })

        it("13. blacklist can't claimActivityReward", async () => {
            await expect(
                user2CandidateContract.connect(user2).claimActivityReward()
            ).to.be.revertedWith("DAOCommittee: blacklisted member");
        })

        it("14. setMemoOnCandidate (anyone)", async () => {
            let beforeMemo = await user1CandidateContract.memo();
            let changeMemo = "Change"

            await daoCommittee_V1.connect(user1).setMemoOnCandidate(
                user1.address,
                "Change"
            )

            let afterMemo = await user1CandidateContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
            expect(changeMemo).to.be.equal(afterMemo)
        })

        it("15. setMemoOnCandidateContract (anyone)", async () => {
            let beforeMemo = await layer2privateCandidateContract.memo();
            let changeMemo = "Change2"

            await daoCommittee_V1.connect(layer2Operator).setMemoOnCandidateContract(
                layer2privateCandidateContract.address,
                "Change2"
            )

            let afterMemo = await layer2privateCandidateContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
            expect(changeMemo).to.be.equal(afterMemo)
        })

        it("16. OnApprove reverted Test (claimTON)", async () => {
            const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();

            const agendaFee = await daoAgendaManagerContract.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];
            // let targets: string[] = [];
            // let functionBytecodes: Bytes[];


            const selector1 = encodeFunctionSignature("claimTON(address,uint256)");
            // const claimAmount = 100000000000000000
            let claimAmount = ethers.utils.parseEther("1")

            // const data1 = padLeft(addr1.address.toString(), 64);
            // // console.log("data1 : ", data1);
            // const data2 = padLeft(claimAmount.toString(16), 64);
            // // console.log("data2 : ", data2)
            // const data3 = data1 + data2
            // // console.log("data3 : ", data3);
            // const functionBytecode1 = selector1.concat(data3)

            // const data1 = marshalString(
            //     [addr1.address, claimAmount]
            //       .map(unmarshalString)
            //       .map(str => padLeft(str, 64))
            //       .join(''),
            // );
            // const data1 = ethers.utils.defaultAbiCoder.encode(
            //     ['address', 'uint256'],
            //     [addr1.address, amount]
            //   );
            // const functionBytecode1 = selector1.concat(data1)
            // console.log("functionBytecode1 : ", functionBytecode1)

            // const bytes = [stringToBytes(functionBytecode1)]
            // let bytes2: Uint8Array = new Uint8Array([0xef0d55940x0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc0000000000000000000000000000000000000000000000056bc75e2d63100000]);
            
            const addr = addr1.address.toLowerCase().replace("0x","");
            const data1 = padLeft(addr,64);

            const amountHex = BigNumber.from(claimAmount).toHexString().replace("0x","");
            const data2 = padLeft(amountHex,64);

            const data3 = data1 + data2;
            // console.log("Combined Data:", data3)
            const functionBytecode1 = selector1 + data3;
            // console.log("Function Bytescode: ", functionBytecode1)

            targets.push(deployed.DAOVault.address);
            functionBytecodes.push(functionBytecode1)
            // console.log("deployed.DAOVault.address :", deployed.DAOVault.address);
            // const param = encodeParameters(
            //     ["address[]", "uint128", "uint128", "bool", "bytes[]"],
            //     [
            //         targets, 
            //         noticePeriod.toString(),
            //         votingPeriod.toString(),
            //         false,
            //         functionBytecodes
            //     ]
            // )

            const param = ethers.utils.defaultAbiCoder.encode(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    functionBytecodes.map((hex) => ethers.utils.arrayify(hex))
                ]
            )

            // const data = marshalString(
            //     [depositManager.address, layerAddress]
            //       .map(unmarshalString)
            //       .map(str => padLeft(str, 64))
            //       .join(''),
            //   );

            // console.log("deployed.DAOVault.address :", deployed.DAOVault.address);
            await checkBalanceTon(user1, agendaFee);
            // console.log("deployed.DAOVault.address :", deployed.DAOVault.address);

            await expect(
                tonContract.connect(user1).approveAndCall(
                    daoCommittee_V1.address,
                    agendaFee,
                    param
            )).to.be.reverted;

        })

        it("17. OnApprove reverted Test (claimERC20) (TON)", async () => {
            const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();

            const agendaFee = await daoAgendaManagerContract.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = encodeFunctionSignature("claimERC20(address,address,uint256)");
            let claimAmount = ethers.utils.parseEther("1")

            const addr = tonContract.address.toLowerCase().replace("0x","");
            const data1 = padLeft(addr,64);

            const addr2 = user1.address.toLowerCase().replace("0x","");
            const data2 = padLeft(addr2,64);

            const amountHex = BigNumber.from(claimAmount).toHexString().replace("0x","");
            const data3 = padLeft(amountHex,64);
            const data4 = data1 + data2 + data3

            const functionBytecode1 = selector1 + data4;

            targets.push(deployed.DAOVault.address);
            functionBytecodes.push(functionBytecode1)
            // console.log("functionBytecode1.length :", functionBytecode1.length);

            const param = ethers.utils.defaultAbiCoder.encode(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    functionBytecodes.map((hex) => ethers.utils.arrayify(hex))
                ]
            )

            await checkBalanceTon(user1, agendaFee);

            let agendaID = (await daoAgendaManagerContract.numAgendas()).sub(1);

            await expect(
                tonContract.connect(user1).approveAndCall(
                    daoCommittee_V1.address,
                    agendaFee,
                    param
            )).to.be.reverted;
        })

        it("18. OnApprove pass Test (claimERC20) (WTON)", async () => {
            const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();

            const agendaFee = await daoAgendaManagerContract.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = encodeFunctionSignature("claimERC20(address,address,uint256)");
            // console.log("selector1 : ", selector1);
            let claimAmount = ethers.utils.parseEther("1")

            const addr = wtonContract.address.toLowerCase().replace("0x","");
            const data1 = padLeft(addr,64);

            const addr2 = user1.address.toLowerCase().replace("0x","");
            const data2 = padLeft(addr2,64);

            const amountHex = BigNumber.from(claimAmount).toHexString().replace("0x","");
            const data3 = padLeft(amountHex,64);
            const data4 = data1 + data2 + data3

            const functionBytecode1 = selector1 + data4

            targets.push(deployed.DAOVault.address);
            functionBytecodes.push(functionBytecode1)

            const param = encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    functionBytecodes
                ]
            )
            // console.log(functionBytecodes);

            await checkBalanceTon(user1, agendaFee);

            await (await tonContract.connect(user1).approveAndCall(
                daoCommittee_V1.address,
                agendaFee,
                param
            )).wait();
        })

        it("19. Create new Agenda (Reduce MinimumNoticePeriod)", async () => {
            const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();
            
            const selector = encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            const newMinimumNoticePeriod = 30;
            const amountHex = BigNumber.from(newMinimumNoticePeriod).toHexString().replace("0x","");
            const data = padLeft(amountHex,64);
            // const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector+data;

            const param = encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    [daoAgendaManagerContract.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode]
                ]
            );
    
            const agendaFee = await daoAgendaManagerContract.createAgendaFees();
            expect(agendaFee).to.be.gt(0);

            await checkBalanceTon(user1, agendaFee);

            const beforeBalance = await tonContract.balanceOf(user1.address);

            // create agenda
            await tonContract.connect(user1).approveAndCall(
                daoCommittee_V1.address,
                agendaFee,
                param
            );

            const afterBalance = await tonContract.balanceOf(user1.address);
            expect(afterBalance).to.be.lt(beforeBalance);
            expect(beforeBalance.sub(afterBalance)).to.be.equal(agendaFee)

            agendaID = (await daoAgendaManagerContract.numAgendas()).sub(1);
            //const executionInfo = await agendaManager.executionInfos(agendaID);
            const executionInfo = await daoAgendaManagerContract.getExecutionInfo(agendaID);
            // console.log("executionInfo :", executionInfo);
            expect(executionInfo[0][0]).to.be.equal(daoAgendaManagerContract.address);
            expect(executionInfo[1][0]).to.be.equal(functionBytecode);
        })

        // it("Get revoke", async () => {
        //     let adminRole = "0x0000000000000000000000000000000000000000000000000000000000000000"
        //     let address = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea"
        //     const dataRevokeRole = daoCommitteeProxy.interface.encodeFunctionData(
        //       "revokeRole",
        //       [adminRole,address]
        //     )
        //     console.log(dataRevokeRole)
        // })


        it('increase block time and check votable', async function () {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            // const noticeEndTimestamp = agenda[AGENDA_INDEX_NOTICE_END_TIMESTAMP];
            const noticeEndTimestamp = agenda[1];
            await time.increaseTo(Number(noticeEndTimestamp)+Number(10));
            expect(await daoAgendaManagerContract.isVotableStatus(agendaID)).to.be.equal(true);
        });

         
        it("blacklist can't castVote", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            const vote = 1
            await expect(
                daoCommittee_V1.connect(user2).castVote(
                    agendaID,
                    vote,
                    "member2 vote"
                )
            ).to.be.reverted;
        })

        it("20. cast vote (user1)", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1.isMember(user1.address)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await user1CandidateContract.connect(user1).castVote(
                agendaID,
                vote,
                "member2 vote"
            )

            const voterInfo2 = await daoAgendaManagerContract.voterInfos(agendaID, user1.address);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoAgendaManagerContract.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoAgendaManagerContract.getVoteStatus(agendaID, user1.address);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("21. No duplicate voting (user1)", async () => {
            const vote = 2
            await expect(user1CandidateContract.connect(user1).castVote(
                agendaID,
                vote,
                "user1 vote"
            )).to.be.reverted;
        })

        it("22. cast vote (layer2Operator)", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member

            // memberCheck = await daoCommittee_V1.members(1)
            // expect(memberCheck.toUpperCase()).to.be.equal(mockLayer2.address.toUpperCase())

            let checkMember = await daoCommittee_V1.isMember(mockLayer2.address)
            // console.log(checkMember)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await layer2privateCandidateContract.connect(layer2Operator).castVote(
                agendaID,
                vote,
                "layer2Operator vote"
            )

            const agenda2 = await daoAgendaManagerContract.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const voterInfo2 = await daoAgendaManagerContract.voterInfos(agendaID, mockLayer2.address);
            // expect(voterInfo2[VOTER_INFO_ISVOTER]).to.be.equal(true);
            expect(voterInfo2[0]).to.be.equal(true);
            // expect(voterInfo2[VOTER_INFO_HAS_VOTED]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            // expect(voterInfo2[VOTER_INFO_VOTE]).to.be.equal(_vote);
            expect(voterInfo2[2]).to.be.equal(vote);


            const result = await daoAgendaManagerContract.getVoteStatus(agendaID, mockLayer2.address);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);
            // const timestamp = await daoAgendaManagerContract.getAgendaTimestamps(agendaID);
            // console.log(timestamp)
            // console.log("agenda Result :", agenda[10])
            // console.log("agenda status :", agenda[11])

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                const currentTime = await time.latest();
                // console.log(votingEndTimestamp)
                // console.log(currentTime)
                await time.increaseTo(Number(votingEndTimestamp)+Number(10));

                expect(await daoAgendaManagerContract.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });

    
        it("23. execute agenda (anyone)", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            const beforeValue = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            
            await daoCommittee_V1.executeAgenda(agendaID);
            const afterValue = await daoAgendaManagerContract.minimumNoticePeriodSeconds();

            expect(beforeValue).to.be.not.equal(afterValue);
            expect(afterValue).to.be.equal(30);

            const afterAgenda = await daoAgendaManagerContract.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        it("24. Create new Agenda", async () => {
            const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();
            const selector = encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 30;
            const amountHex = BigNumber.from(newMinimumNoticePeriod).toHexString().replace("0x","");
            const data = padLeft(amountHex, 64);
            const functionBytecode = selector+(data);

            const param = encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    [daoAgendaManagerContract.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode]
                ]
            );
    
            const agendaFee = await daoAgendaManagerContract.createAgendaFees();
            expect(agendaFee).to.be.gt(0);


            await checkBalanceTon(user1, agendaFee);

            const beforeBalance = await tonContract.balanceOf(user1.address);

            // create agenda
            await tonContract.connect(user1).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            );

            const afterBalance = await tonContract.balanceOf(user1.address);
            expect(afterBalance).to.be.lt(beforeBalance);
            expect(beforeBalance.sub(afterBalance)).to.be.equal(agendaFee)

            agendaID = (await daoAgendaManagerContract.numAgendas()).sub(1);
            //const executionInfo = await agendaManager.executionInfos(agendaID);
            const executionInfo = await daoAgendaManagerContract.getExecutionInfo(agendaID);
            // console.log("executionInfo :", executionInfo);
            expect(executionInfo[0][0]).to.be.equal(daoAgendaManagerContract.address);
            expect(executionInfo[1][0]).to.be.equal(functionBytecode);
        })



        it("25. setAgendaStatus test (Owner)", async () => {    
            expect(await daoAgendaManagerContract.getAgendaStatus(agendaID)).to.be.equal(1);

            await daoCommittee_V1.connect(deployer).setAgendaStatus(
                agendaID,
                2,
                0
            );

            expect(await daoAgendaManagerContract.getAgendaStatus(agendaID)).to.be.equal(2);
        })   

        it("26. updateSeigniorage test (createCandidate)", async () => {
            const beforeSeigBlock = await seigManager.lastCommitBlock(user1CandidateContract.address)

            await user1CandidateContract.connect(user1).updateSeigniorage()

            const afterSeigBlock = await seigManager.lastCommitBlock(user1CandidateContract.address)

            expect(afterSeigBlock).to.be.gt(beforeSeigBlock)
        })

        it("27. updateSeigniorage test (create privateLayer2)", async () => {
            const beforeSeigBlock = await seigManager.lastCommitBlock(mockLayer2.address)

            await mockLayer2.connect(layer2Operator).updateSeigniorage()

            const afterSeigBlock = await seigManager.lastCommitBlock(mockLayer2.address)

            expect(afterSeigBlock).to.be.gt(beforeSeigBlock)
        })

        it("28. getClaimableActivityReward & claimActivityReward test (createCandidate)", async () => {
            let amount = await daoCommittee_V1.getClaimableActivityReward(user1.address)
            expect(amount).to.be.gt(0);
            // console.log(amount)
            // const wtonBalance = await wtonContract.balanceOf(daoVaultContract.address)
            // console.log(wtonBalance)

            // let candidateInfos = await daoCommittee_V1.candidateInfos(user1.address)
            // console.log(candidateInfos)
            
            // const currentTime = await time.latest();
            // console.log(currentTime)

            await user1CandidateContract.connect(user1).claimActivityReward()

            let amount2 = await daoCommittee_V1.getClaimableActivityReward(user1.address)
            expect(amount).to.be.gt(amount2);
        })

        it("29. getClaimableActivityReward & claimActivityReward test (createCandidate)", async () => {
            let amount = await daoCommittee_V1.getClaimableActivityReward(mockLayer2.address)
            expect(amount).to.be.gt(0);
            // console.log(amount)
            // const wtonBalance = await wtonContract.balanceOf(daoVaultContract.address)
            // console.log(wtonBalance)

            // let candidateInfos = await daoCommittee_V1.candidateInfos(user1.address)
            // console.log(candidateInfos)
            
            // const currentTime = await time.latest();
            // console.log(currentTime)

            await layer2privateCandidateContract.connect(layer2Operator).claimActivityReward()

            let amount2 = await daoCommittee_V1.getClaimableActivityReward(mockLayer2.address)
            expect(amount).to.be.gt(amount2);
        })


        it("30. isCandidate (view)", async () => {
            let checkisCandidate = await daoCommittee_V1.isCandidate(user1.address)
            expect(checkisCandidate).to.be.equal(true)
        })

        it("31. isCandidate (view)", async () => {
            let checkisCandidate = await daoCommittee_V1.isCandidate(mockLayer2.address)
            expect(checkisCandidate).to.be.equal(true)
        })

        it("32. totalSupplyOnCandidate (view)", async () => {
            let amount = await daoCommittee_V1.totalSupplyOnCandidate(user1.address)
            expect(amount).to.be.gt(0)
        })


        it("33. totalSupplyOnCandidate (view)", async () => {
            let amount = await daoCommittee_V1.totalSupplyOnCandidate(mockLayer2.address)
            expect(amount).to.be.gt(0)
        })


        it("34. balanceOfOnCandidate (view)", async () => {
            let amount = await daoCommittee_V1.balanceOfOnCandidate(
                user1.address,
                user1.address
            )
            expect(amount).to.be.gt(0)
        })

        it("35. balanceOfOnCandidate (view)", async () => {
            let amount = await daoCommittee_V1.balanceOfOnCandidate(
                mockLayer2.address,
                layer2Operator.address
            )
            expect(amount).to.be.gt(0)
        })

        it("36. totalSupplyOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V1.totalSupplyOnCandidateContract(
                user1CandidateContract.address
            )
            expect(amount).to.be.gt(0)
        })

        it("37. totalSupplyOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V1.totalSupplyOnCandidateContract(
                layer2privateCandidateContract.address
            )
            expect(amount).to.be.gt(0)
        })

        it("38. balanceOfOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V1.balanceOfOnCandidateContract(
                user1CandidateContract.address,
                user1.address
            )
            expect(amount).to.be.gt(0)
        })

        it("39. balanceOfOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V1.balanceOfOnCandidateContract(
                layer2privateCandidateContract.address,
                layer2Operator.address
            )
            expect(amount).to.be.gt(0)
        })

        it("40. candidatesLength (view)", async () => {
            let length = await daoCommittee_V1.candidatesLength()
            expect(length).to.be.gt(0)
        })

        it("41. isExistCandidate (view)", async () => {
            let check = await daoCommittee_V1.isExistCandidate(user1.address)
            expect(check).to.be.equal(true)
        })

        it("42. isExistCandidate (view)", async () => {
            let check = await daoCommittee_V1.isExistCandidate(mockLayer2.address)
            expect(check).to.be.equal(true)
        })

    })

    describe("DAOCommitteeOwner Logic Test", () => {
        it("1. setSeigManager test", async () => {
            let beforeAddr = await daoCommitteeOwner.seigManager()
            
            await daoCommitteeOwner.connect(deployer).setSeigManager(user1.address)
    
            let afterAddr = await daoCommitteeOwner.seigManager()
            expect(afterAddr).to.be.equal(user1.address)
            // expect(beforeAddr).to.be.not.equal(afterAddr)

            await daoCommitteeOwner.connect(deployer).setSeigManager(beforeAddr)
            afterAddr = await daoCommitteeOwner.seigManager()
            expect(afterAddr.toUpperCase()).to.be.equal(beforeAddr.toUpperCase())
        })

        it("2. setDaoVault test", async () => {
            let beforeDaoVault = await daoCommitteeOwner.daoVault()

            await daoCommitteeOwner.connect(deployer).setDaoVault(
                user1.address
            )

            let afterDaoVault = await daoCommitteeOwner.daoVault()
            expect(afterDaoVault.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setDaoVault(
                beforeDaoVault
            )

            let afterDAOVault2 = await daoCommitteeOwner.daoVault()
            expect(afterDAOVault2.toUpperCase()).to.be.equal(beforeDaoVault.toUpperCase())
        })


        it("3. setLayer2Registry test", async () => {
            let beforeData = await daoCommitteeOwner.layer2Registry()

            await daoCommitteeOwner.connect(deployer).setLayer2Registry(
                user1.address
            )

            let afterData = await daoCommitteeOwner.layer2Registry()
            expect(afterData.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setLayer2Registry(
                beforeData
            )

            let afterData2 = await daoCommitteeOwner.layer2Registry()
            expect(afterData2.toUpperCase()).to.be.equal(beforeData.toUpperCase())
        })

        it("4. setAgendaManager test", async () => {
            let beforeData = await daoCommitteeOwner.agendaManager()

            await daoCommitteeOwner.connect(deployer).setAgendaManager(
                user1.address
            )

            let afterData = await daoCommitteeOwner.agendaManager()
            expect(afterData.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setAgendaManager(
                beforeData
            )

            let afterData2 = await daoCommitteeOwner.agendaManager()
            expect(afterData2.toUpperCase()).to.be.equal(beforeData.toUpperCase())
        })

        it("5. setCandidateFactory test", async () => {
            let beforeData = await daoCommitteeOwner.candidateFactory()

            await daoCommitteeOwner.connect(deployer).setCandidateFactory(
                user1.address
            )

            let afterData = await daoCommitteeOwner.candidateFactory()
            expect(afterData.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setCandidateFactory(
                beforeData
            )

            let afterData2 = await daoCommitteeOwner.candidateFactory()
            expect(afterData2.toUpperCase()).to.be.equal(beforeData.toUpperCase())
        })

        it("6. setTon test", async () => {
            let beforeData = await daoCommitteeOwner.ton()

            await daoCommitteeOwner.connect(deployer).setTon(
                user1.address
            )

            let afterData = await daoCommitteeOwner.ton()
            expect(afterData.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setTon(
                beforeData
            )

            let afterData2 = await daoCommitteeOwner.ton()
            expect(afterData2.toUpperCase()).to.be.equal(beforeData.toUpperCase())
        })

        it("7. setWTON test", async () => {
            let beforeData = await daoCommitteeOwner.wton()

            await daoCommitteeOwner.connect(deployer).setWton(
                user1.address
            )

            let afterData = await daoCommitteeOwner.wton()
            
            expect(afterData.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setWton(
                beforeData
            )

            let afterData2 = await daoCommitteeOwner.wton()
            expect(afterData2.toUpperCase()).to.be.equal(beforeData.toUpperCase())
        })

        it("8. increaseMaxMember test", async () => {
            await daoCommitteeOwner.connect(deployer).increaseMaxMember(
                4,
                3
            )

            let afterData = await daoCommitteeOwner.maxMember()
            expect(afterData).to.be.equal(4)
        })

        it("9. setQuorum test", async () => {
            await daoCommitteeOwner.connect(deployer).setQuorum(
                4
            )

            let afterData = await daoCommitteeOwner.quorum()
            expect(afterData).to.be.equal(4)
        })

        it("10. decreaseMaxMember test", async () => {
            await daoCommitteeOwner.connect(deployer).decreaseMaxMember(
                3,
                2
            )

            let afterData = await daoCommitteeOwner.maxMember()
            expect(afterData).to.be.equal(3)
        })

        it("11. setActivityRewardPerSecond test", async () => {
            let beforeData = await daoCommitteeOwner.activityRewardPerSecond()

            await daoCommitteeOwner.connect(deployer).setActivityRewardPerSecond(
                1
            )

            let afterData = await daoCommitteeOwner.activityRewardPerSecond()
            expect(afterData).to.be.equal(1)

            await daoCommitteeOwner.connect(deployer).setActivityRewardPerSecond(
                beforeData
            )

            let afterData2 = await daoCommitteeOwner.activityRewardPerSecond()
            expect(afterData2).to.be.equal(beforeData)
        })

        it("12. setCandidatesSeigManager test", async () => {
            let beforeData = await user1CandidateContract.seigManager()

            await daoCommitteeOwner.connect(deployer).setCandidatesSeigManager(
                [user1CandidateContract.address],
                user1.address
            )

            let afterData = await user1CandidateContract.seigManager()
            expect(afterData.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setCandidatesSeigManager(
                [user1CandidateContract.address],
                beforeData
            )

            let afterData2 = await user1CandidateContract.seigManager()
            expect(afterData2.toUpperCase()).to.be.equal(beforeData.toUpperCase())
        })

        it("13. setCandidatesCommittee test", async () => {
            let beforeData = await user1CandidateContract.committee()

            await daoCommitteeOwner.connect(deployer).setCandidatesCommittee(
                [user1CandidateContract.address],
                user1.address
            )

            let afterData = await user1CandidateContract.committee()
            expect(afterData.toUpperCase()).to.be.equal(user1.address.toUpperCase())

            await daoCommitteeOwner.connect(deployer).setCandidatesCommittee(
                [user1CandidateContract.address],
                beforeData
            )

            let afterData2 = await user1CandidateContract.committee()
            expect(afterData2.toUpperCase()).to.be.equal(beforeData.toUpperCase())
        })

        it("14. setBurntAmountAtDAO test", async () => {
            // let check = await seigManagerV1Contract.isAdmin(daoCommitteeAdmin.address)
            // let check2 = await seigManagerV1Contract.isAdmin(daoCommittee_Owner_Contract.address)
            // console.log(check)
            // console.log(check2)

            let beforeData = await seigManager.burntAmountAtDAO()

            await daoCommitteeOwner.connect(deployer).setBurntAmountAtDAO(
                10
            )

            let afterData = await seigManager.burntAmountAtDAO()
            // console.log(afterData)
            expect(afterData).to.be.equal(10)

            await daoCommitteeOwner.connect(deployer).setBurntAmountAtDAO(
                beforeData
            )

            let afterData2 = await seigManager.burntAmountAtDAO()
            // console.log(afterData2)
            expect(afterData2).to.be.equal(beforeData)
        })

        it("15. setCooldownTime test", async () => {
            let beforeData = await daoCommitteeOwner.cooldownTime()
            let cooldownTime = 86400
            expect(beforeData).to.be.equal(cooldownTime)

            await daoCommitteeOwner.connect(deployer).setCooldownTime(
                10
            )

            let afterData = await daoCommitteeOwner.cooldownTime()
            expect(afterData).to.be.equal(10)
        })

        it("16. daoExecuteTransaction can't execute anyone", async () => {
            const dataSetDao = seigManager.interface.encodeFunctionData(
                "setDao",
                [zeroAddr]
            )

            await expect(
                daoCommitteeOwner.connect(user1).daoExecuteTransaction(
                    seigManager.address,
                    dataSetDao
                )
            ).to.be.reverted;
        })

        it("17. daoExecuteTransaction can execute onlyOwner", async () => {
            let beforeGlobalDelay = await depositManager.globalWithdrawalDelay()

            const dataSetGlobalWithdrawalDelay = depositManager.interface.encodeFunctionData(
                "setGlobalWithdrawalDelay",
                [10]
            )

            await daoCommitteeOwner.connect(deployer).daoExecuteTransaction(
                depositManager.address,
                dataSetGlobalWithdrawalDelay
            )

            let afterGlobalDelay = await depositManager.globalWithdrawalDelay()
            expect(afterGlobalDelay).to.be.equal(10)
            expect(afterGlobalDelay).not.to.be.equal(beforeGlobalDelay)

        })


    })

    describe("MultiSigWallet Test", () => {
        it("send TON & ETH into MultiSigWallet Contract", async () => {
            let amount = ethers.utils.parseEther("0.5")
            await (await faucetContract.connect(deployer).transferToken1(multiSigWalletContract.address, amount)).wait()

            await addr1.sendTransaction({
                to: multiSigWalletContract.address,
                value: amount
            })
        })

        it("MultiSigWallet execute the Send ETH", async () => {
            const recipient = user1.address;
            const ethAmount = ethers.utils.parseEther("0.5");
            
            await multiSigWalletContract.connect(user2).submitTransaction(
                recipient,
                ethAmount,
                "0x"
            );

            // await MultiSigWalletContract.connect(owner1).confirmTransaction(0)
            await multiSigWalletContract.connect(user3).confirmTransaction(0)
            const beforeBalance = Number(await ethers.provider.getBalance(recipient)); 

            await multiSigWalletContract.connect(user3).executeTransaction(0)
            // const afterBalance = await ethers.provider.getBalance(recipient);

            expect(Number(await ethers.provider.getBalance(recipient))).to.be.equal(beforeBalance+Number(ethAmount))
        })

        it("MultiSigWallet execute the Send ERC20 transfer", async () => {
            const tokenAmount = ethers.utils.parseEther("0.5")
            const dataTransfer = tonContract.interface.encodeFunctionData(
              "transfer",
              [user1.address, tokenAmount]
            )
      
            await multiSigWalletContract.connect(user1).submitTransaction(
              tonContract.address,
              0,
              dataTransfer
            );
      
            await multiSigWalletContract.connect(user2).confirmTransaction(1)
            // await MultiSigWalletContract.connect(owner3).confirmTransaction(1)
      
            await multiSigWalletContract.connect(user1).executeTransaction(1)
      
            expect(await tonContract.balanceOf(user1.address)).to.be.equal(tokenAmount)
        })

        it("ConfirmTransaction cannot be executed for a Transaction that has already been executeTransactioned.", async () => {
            await expect(
                multiSigWalletContract.connect(user3).confirmTransaction(
                    1
                )
            ).to.be.revertedWith("tx already executed");
        })
    
        it("executeTransaction cannot be executed for a Transaction that has already been executeTransactioned.", async () => {
            await expect(
                multiSigWalletContract.connect(user3).executeTransaction(
                    1
                )
            ).to.be.revertedWith("tx already executed");
        })
        
        it("can't changeOwner by Owner", async () => {
            await expect(
                multiSigWalletContract.connect(user3).changeOwner(
                    0,
                    user1.address
                )
            ).to.be.revertedWith("Only MultiSigContract can execute");
        })

        it("MultiSigWallet execute the DAOCommitteeOwner(setCooldown)", async () => {
            let beforeCooldown = await daoCommitteeOwner.cooldownTime()
            expect(beforeCooldown).to.be.equal(10)
      
            const dataSetCooldown = daoCommitteeOwner.interface.encodeFunctionData(
              "setCooldownTime",
              [100]
            )
      
            await multiSigWalletContract.connect(user2).submitTransaction(
                daoCommitteeOwner.address,
              0,
              dataSetCooldown
            );
      
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(user3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(user3).executeTransaction(count-1)
      
            let afterCooldown = await daoCommitteeOwner.cooldownTime()
            expect(afterCooldown).to.be.equal(100)
        })

        it("MultiSigWallet execute the DAOCommmitee_V1(removeFromBlacklist)", async () => {
            let beforeBlackList = await daoCommittee_V1.blacklist(user2CandidateContract.address)
            expect(beforeBlackList).to.be.equal(true)

            const dataRemoveBlackList = daoCommittee_V1.interface.encodeFunctionData(
                "removeFromBlacklist",
                [user2CandidateContract.address]
            )

            await multiSigWalletContract.connect(user2).submitTransaction(
                daoCommittee_V1.address,
                0,
                dataRemoveBlackList
            );
      
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(user3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(user3).executeTransaction(count-1)

            let afterBlackList = await daoCommittee_V1.blacklist(user2CandidateContract.address)
            expect(afterBlackList).to.be.equal(false)
        })

        it("MultiSigWallet execute the SeigManager(setDao)", async () => {
            let beforeAddr = await seigManager.dao()
            expect(beforeAddr).to.be.equal(daoVaultContract.address)

            const dataSetDao = seigManager.interface.encodeFunctionData(
              "setDao",
              [zeroAddr]
            )
              
            const dataExecuteTransaction = daoCommitteeOwner.interface.encodeFunctionData(
              "daoExecuteTransaction",
              [seigManager.address, dataSetDao]
            )
      
            await multiSigWalletContract.connect(user2).submitTransaction(
                daoCommitteeOwner.address,
                0,
                dataExecuteTransaction
            );
      
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(user3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(user3).executeTransaction(count-1)
      
            let afterAddr = await seigManager.dao()
            expect(afterAddr).to.be.equal(zeroAddr)
        })

        it("MultiSigWallet execute the agendaManager(setCreateAgendaFees)", async () => {
            let beforeAgendaFee = await daoAgendaManagerContract.createAgendaFees()

            const dataSetDao = daoAgendaManagerContract.interface.encodeFunctionData(
                "setCreateAgendaFees",
                [10]
              )

            const dataExecuteTransaction = daoCommitteeOwner.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoAgendaManagerContract.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(user2).submitTransaction(
                daoCommitteeOwner.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(user3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(user3).executeTransaction(count-1)


            let afterAgendaFee = await daoAgendaManagerContract.createAgendaFees()
            expect(afterAgendaFee).to.be.equal(10)
            expect(afterAgendaFee).not.to.be.equal(beforeAgendaFee)
        })

        it("MultiSigWallet execute the agendaManager(setMinimumNoticePeriodSeconds)", async () => {
            let beforeNotice = await daoAgendaManagerContract.minimumNoticePeriodSeconds()

            const dataSetDao = daoAgendaManagerContract.interface.encodeFunctionData(
                "setMinimumNoticePeriodSeconds",
                [100]
              )

            const dataExecuteTransaction = daoCommitteeOwner.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoAgendaManagerContract.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(user1).submitTransaction(
                daoCommitteeOwner.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(user3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(user3).executeTransaction(count-1)


            let afterNotice = await daoAgendaManagerContract.minimumNoticePeriodSeconds()
            expect(afterNotice).to.be.equal(100)
            expect(afterNotice).not.to.be.equal(beforeNotice)
        })

        it("MultiSigWallet execute the agendaManager(setMinimumVotingPeriodSeconds)", async () => {
            let beforeVoting = await daoAgendaManagerContract.minimumVotingPeriodSeconds()

            const dataSetDao = daoAgendaManagerContract.interface.encodeFunctionData(
                "setMinimumVotingPeriodSeconds",
                [10]
              )

            const dataExecuteTransaction = daoCommitteeOwner.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoAgendaManagerContract.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(user3).submitTransaction(
                daoCommitteeOwner.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(user2).confirmTransaction(count-1)
            await multiSigWalletContract.connect(user2).executeTransaction(count-1)


            let afterVoting = await daoAgendaManagerContract.minimumVotingPeriodSeconds()
            expect(afterVoting).to.be.equal(10)
            expect(afterVoting).not.to.be.equal(beforeVoting)
        })

        it("MultiSigWallet execute the agendaManager(setExecutingPeriodSeconds)", async () => {
            let beforeExecuting = await daoAgendaManagerContract.executingPeriodSeconds()

            const dataSetDao = daoAgendaManagerContract.interface.encodeFunctionData(
                "setExecutingPeriodSeconds",
                [30000]
              )

            const dataExecuteTransaction = daoCommitteeOwner.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoAgendaManagerContract.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(user2).submitTransaction(
                daoCommitteeOwner.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(user1).confirmTransaction(count-1)
            await multiSigWalletContract.connect(user1).executeTransaction(count-1)


            let afterExecuting = await daoAgendaManagerContract.executingPeriodSeconds()
            expect(afterExecuting).to.be.equal(30000)
            expect(afterExecuting).not.to.be.equal(beforeExecuting)
        })
    })

    describe("createCandidateAddOn Test", () => {

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

        it("registerCandidateAddOn", async () => {
            expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(0)

            let amount = await layer2Manager.minimumInitialDepositAmount();
            let amount2 = ethers.utils.parseEther("2000")
            await checkBalanceTon(addr1,amount2);
            let balance = await tonContract.balanceOf(addr1.address)
            expect(balance).to.be.gt(amount)

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
            
            const topic2 = daoCommittee_V1.interface.getEventTopic('CandidateContractCreated');
            const log2 = receipt.logs.find(x => x.topics.indexOf(topic2) >= 0);
            const deployedEvent2 = daoCommittee_V1.interface.parseLog(log2);

            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            expect(deployedEvent.args.memo).to.be.eq(name)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

            titanLayerAddress = deployedEvent.args.candidateAddOn;
            titanOperatorContractAddress = deployedEvent.args.operator;
            expect((await layer2Manager.statusLayer2(legacySystemConfig.address))).to.be.eq(1)
            // console.log(deployedEvent2)
            // console.log(addr1.address)
            // console.log(titanLayerAddress)
            // console.log(titanOperatorContractAddress)

            titanLayerContract =  (await ethers.getContractAt("CandidateAddOnV1_1", titanLayerAddress, deployer)) as CandidateAddOnV1_1
            titanOperatorContract = (await ethers.getContractAt("OperatorManagerV1_1", titanOperatorContractAddress, deployer)) as OperatorManagerV1_1
        })

        it("privateLayer2 Check", async () => {
            let privateLayer2Check = await daoCommittee_V1.privateLayer2(titanOperatorContract.address);
            // console.log("privateLayer2Check :", privateLayer2Check)
            expect(privateLayer2Check).to.be.equal(false)
        })

        it("CandidateAddOn operatorAmountCheck", async () => {
            let operatorAmountCheck = await daoCommittee_V1.operatorAmountCheck(titanLayerContract.address, titanOperatorContract.address);
            // console.log("operatorAmountCheck :", operatorAmountCheck)
            expect(operatorAmountCheck).to.be.gt(0)
        })

        it("CandidateAddOn operatorCheck", async () => {
            let operatorAmount = await daoCommittee_V1.operatorCheck(titanOperatorContract.address);
            // console.log("operatorAmount :", operatorAmount)
            expect(operatorAmount).to.be.gt(0)
        })


        it("changeMember (CandidateAddOn)", async () => {
            let memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck).to.be.equal(zeroAddr)

            await (
                await titanLayerContract.connect(deployer).changeMember(2)
            ).wait();

            memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck.toUpperCase()).to.be.equal(titanOperatorContract.address.toUpperCase())
        })

        it("setMemoOnCandidate (createCandidateAddon)", async () => {
            let beforeMemo = await titanLayerContract.memo();

            await daoCommittee_V1.connect(deployer).setMemoOnCandidate(
                titanOperatorContract.address,
                "titanMemo"
            )

            let afterMemo = await titanLayerContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
        })

        it("setMemoOnCandidateContract (createCandidateAddon)", async () => {
            let beforeMemo = await titanLayerContract.memo();
            let changeMemo = "Change2"

            await daoCommittee_V1.connect(deployer).setMemoOnCandidateContract(
                titanLayerContract.address,
                "Change2"
            )

            let afterMemo = await titanLayerContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
            expect(changeMemo).to.be.equal(afterMemo)
        })

        it("getClaimableActivityReward & claimActivityReward test (createCandidateAddon)", async () => {
            let amount = await daoCommittee_V1.getClaimableActivityReward(titanOperatorContract.address)
            expect(amount).to.be.gt(0);

            await titanLayerContract.connect(deployer).claimActivityReward()

            let amount2 = await daoCommittee_V1.getClaimableActivityReward(titanOperatorContract.address)
            expect(amount).to.be.gt(amount2);
        })

        it("totalStaked & stakedOf test (createCandidateAddon)", async () => {
            let totalStakedAmount = await titanLayerContract.totalStaked()
            let stakedOfAmount = await titanLayerContract.stakedOf(titanOperatorContract.address)

            expect(totalStakedAmount).to.be.equal(stakedOfAmount)
            expect(totalStakedAmount).to.be.gt(0)            
        })

        it("updateSeigniorage test (createCandidateAddon)", async () => {
            const beforeSeigBlock = await seigManager.lastCommitBlock(titanLayerContract.address)

            await titanLayerContract.connect(user1).updateSeigniorage()

            const afterSeigBlock = await seigManager.lastCommitBlock(titanLayerContract.address)

            expect(afterSeigBlock).to.be.gt(beforeSeigBlock)
        })

        it("Create new Agenda", async () => {
            const noticePeriod = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManagerContract.minimumVotingPeriodSeconds();
            const selector = encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 40;
            const amountHex = BigNumber.from(newMinimumNoticePeriod).toHexString().replace("0x","");
            const data = padLeft(amountHex, 64);
            const functionBytecode = selector+(data);

            const param = encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    [daoAgendaManagerContract.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode]
                ]
            );
    
            const agendaFee = await daoAgendaManagerContract.createAgendaFees();
            expect(agendaFee).to.be.gt(0);


            await checkBalanceTon(user1, agendaFee);

            const beforeBalance = await tonContract.balanceOf(user1.address);

            // create agenda
            await tonContract.connect(user1).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            );

            const afterBalance = await tonContract.balanceOf(user1.address);
            expect(afterBalance).to.be.lt(beforeBalance);
            expect(beforeBalance.sub(afterBalance)).to.be.equal(agendaFee)

            agendaID = (await daoAgendaManagerContract.numAgendas()).sub(1);
            //const executionInfo = await agendaManager.executionInfos(agendaID);
            const executionInfo = await daoAgendaManagerContract.getExecutionInfo(agendaID);
            // console.log("executionInfo :", executionInfo);
            expect(executionInfo[0][0]).to.be.equal(daoAgendaManagerContract.address);
            expect(executionInfo[1][0]).to.be.equal(functionBytecode);
        })

        it("currentAgendaStatus test", async () => {
            let result = await daoCommittee_V1.currentAgendaStatus((agendaID+1))
            expect(result.agendaResult).to.be.equal(5)
            expect(result.agendaStatus).to.be.equal(6)

            result = await daoCommittee_V1.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(0)
            expect(result.agendaStatus).to.be.equal(1)
        })

        it('increase block time and check votable', async function () {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            // const noticeEndTimestamp = agenda[AGENDA_INDEX_NOTICE_END_TIMESTAMP];
            const noticeEndTimestamp = agenda[1];
            await time.increaseTo(Number(noticeEndTimestamp)+Number(10));
            expect(await daoAgendaManagerContract.isVotableStatus(agendaID)).to.be.equal(true);
        });

        it("currentAgendaStatus test", async () => {
            // const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            // const noticeEndTimestamp = agenda[1];
            // const votingEndTimestamp = agenda[4];
            // const currentTime = await time.latest();
            // console.log(noticeEndTimestamp)
            // console.log(votingEndTimestamp)
            // console.log(currentTime)
            let result = await daoCommittee_V1.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(0)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("cast vote (candidateAddOn)", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1.isMember(titanOperatorContract.address)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await titanLayerContract.connect(deployer).castVote(
                agendaID,
                vote,
                "member2 vote"
            )

            const voterInfo2 = await daoAgendaManagerContract.voterInfos(agendaID, titanOperatorContract.address);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoAgendaManagerContract.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoAgendaManagerContract.getVoteStatus(agendaID, titanOperatorContract.address);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        
        it("currentAgendaStatus test", async () => {
            let result = await daoCommittee_V1.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(4)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("cast vote (createCandidate)", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1.isMember(user1.address)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await user1CandidateContract.connect(user1).castVote(
                agendaID,
                vote,
                "member2 vote"
            )

            const voterInfo2 = await daoAgendaManagerContract.voterInfos(agendaID, user1.address);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoAgendaManagerContract.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoAgendaManagerContract.getVoteStatus(agendaID, user1.address);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("currentAgendaStatus test", async () => {
            let result = await daoCommittee_V1.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(1)
            expect(result.agendaStatus).to.be.equal(3)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                await time.increaseTo(Number(votingEndTimestamp)+Number(10));

                expect(await daoAgendaManagerContract.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });

        it("execute agenda", async () => {
            const agenda = await daoAgendaManagerContract.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            const beforeValue = await daoAgendaManagerContract.minimumNoticePeriodSeconds();
            
            await daoCommittee_V1.executeAgenda(agendaID);

            const afterValue = await daoAgendaManagerContract.minimumNoticePeriodSeconds();

            expect(beforeValue).to.be.not.equal(afterValue);
            expect(afterValue).to.be.equal(40);

            const afterAgenda = await daoAgendaManagerContract.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        it("currentAgendaStatus test", async () => {
            let result = await daoCommittee_V1.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(1)
            expect(result.agendaStatus).to.be.equal(4)
        })

        it("retireMember (candidateAddOn) (add blackList) (onlyMember)", async () => {
            let memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck.toUpperCase()).to.be.equal(titanOperatorContract.address.toUpperCase())
            // let beforeWTONAmount = await wton.balanceOf(member2.address)
            let blacklistCheck = await daoCommittee_V1.blacklist(titanLayerContract.address)
            expect(blacklistCheck).to.be.equal(false)

            await (
                await titanLayerContract.connect(deployer).retireMember()
            ).wait();

            memberCheck = await daoCommittee_V1.members(2)
            expect(memberCheck).to.be.equal(zeroAddr)

            blacklistCheck = await daoCommittee_V1.blacklist(titanLayerContract.address)
            expect(blacklistCheck).to.be.equal(true)
        })

    })

})