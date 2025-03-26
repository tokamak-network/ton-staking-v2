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

describe("DEV DAO Test on Sepolia (About Upgraded StakingV2.5)", () => {
    let deployer: Signer, manager: Signer,  addr1: Signer,  addr2: Signer, user1: Signer, user2: Signer

    let daoOwner: Signer;
    let wtonHave:Signer, tonHave:Signer

    let candidateAddOnV1_1Imp: CandidateAddOnV1_1
    let candidateAddOnFactoryImp:CandidateAddOnFactory , candidateAddOnFactoryProxy: CandidateAddOnFactoryProxy, candidateAddOnFactory: CandidateAddOnFactory
    let tonContract: Contract, wtonContract: Contract, faucetContract: Faucetv2
    let daoCommitteeProxy: Contract, daoContract: Contract, daoV2Contract: Contract, daoAgendaManager: Contract

    let seigManager: Contract, seigManagerProxy: Contract;
    let seigManagerV1_3: SeigManagerV1_3, seigManagerV1_2: SeigManagerV1_2;

    let depositManager: Contract,  depositManagerProxy: Contract;
    let depositManagerV1_1: DepositManagerV1_1;    

    let daoAgendaManagerContract: Contract
    let daoCommitteeProxy2Contract: DAOCommitteeProxy2
    let daoCommittee_V1: DAOCommittee_V1
    let daoCommitteeOwner: DAOCommitteeOwner
    let daoCommitteeContract:  Contract

    let user1CandidateContract: Contract
    let user2CandidateContract: Contract

    interface CandidateType {
        address: string,
        contract: Candidate | CandidateAddOnV1_1 | any
    }

    let candidate1 : CandidateType
    let candidate2 : CandidateType
    let candidateAddOn1 : CandidateType
    let layer2Candidate1 : CandidateType

    let deployed : any

    async function checkBalanceTon(account: Signer, amount: BigNumber) {
        const tonBalance = await tonContract.balanceOf(account.address)
        if (tonBalance.lt(amount)) {
            await (await faucetContract.connect(deployer).transferToken1(account.address, amount)).wait()
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

            daoCommitteeProxy2Contract = (await ethers.getContractAt("DAOCommitteeProxy2", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommitteeProxy2;
            daoCommitteeOwner = (await ethers.getContractAt("DAOCommitteeOwner", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommitteeOwner;
            daoCommittee_V1 = (await ethers.getContractAt("DAOCommittee_V1", deployed.DAOCommitteeProxy.address, deployer)) as DAOCommittee_V1;

            seigManagerV1_2 = (await ethers.getContractAt("SeigManagerV1_2", deployed.SeigManagerProxy.address, deployer)) as SeigManagerV1_2;
            seigManagerV1_3 = (await ethers.getContractAt("SeigManagerV1_3", deployed.SeigManagerProxy.address, deployer)) as SeigManagerV1_3;
            seigManager = new ethers.Contract(deployed.SeigManagerProxy.address,  SeigManager_Json.abi, deployer)

            depositManagerV1_1 = (await ethers.getContractAt("DepositManagerV1_1", deployed.DepositManagerProxy.address, deployer)) as DepositManagerV1_1;
            depositManager = (await ethers.getContractAt("DepositManager", deployed.DepositManagerProxy.address, deployer)) as DepositManagerV1_1;

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

            candidate1 = {
                address : candidateInfo.candidateContract,
                contract: user1CandidateContract
            }
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

        it("4. chagneMember (after staking)", async () => {
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
    })

    describe("DAOCommitteeOwner Logic Test", () => {

    })


})