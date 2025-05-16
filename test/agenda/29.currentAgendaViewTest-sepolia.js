const hre = require("hardhat");

const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");

const { BigNumber, Signer, utils, Contract, Bytes } = require('ethers')

const { expect, assert } = chai;
chai.use(solidity);
require("chai").should();

const Web3EthAbi = require('web3-eth-abi');
const { padLeft } = require('web3-utils');

const { time } = require("@nomicfoundation/hardhat-network-helpers");

const networkName = "sepolia"

// const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'
const daoAdminAddress = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'

let daoAgendaMangerAddress = "0xcD4421d082752f363E1687544a09d5112cD4f484"; //DAOAgendaManager Address

const TonABI = require("../../abi/TON.json").abi;
const WtonABI = require("../../abi/WTON.json").abi;
const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DAOCommitteeOwnerABI = require("../../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommittee_V1ABI = require("../../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const SeigManagerProxyABI = require("../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json").abi;
const SeigManagerABI = require("../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json").abi;
const SeigManagerV1ABI = require("../../artifacts/contracts/stake/managers/SeigManagerV1_1.sol/SeigManagerV1_1.json").abi;
const DepositManagerABI = require("../../artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json").abi;
const OperatorManagerFactory_ABI = require("../../artifacts/contracts/layer2/factory/OperatorManagerFactory.sol/OperatorManagerFactory.json").abi;
const OperatorManagerV1_1_ABI = require("../../artifacts/contracts/layer2/OperatorManagerV1_1.sol/OperatorManagerV1_1.json").abi;
const CandidateFactory_ABI = require("../../artifacts/contracts/dao/factory/CandidateAddOnFactory.sol/CandidateAddOnFactory.json").abi;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;

const CandidateABI = require("../../abi/Candidate.json").abi;
const DepositManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const SeigManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const MultiSigwallet_Json = require('../abi/MultiSigWallet.json')


describe("currentAgendaStatus Test on Sepolia", () => {

    let daoCommitteeAdmin;
    let daoCommitteeAdminContract;
    let daoCommitteeProxy;
    // let daoCommitteeDAOVaultLogic;
    let daoCommitteeOwnerLogic;
    let ton;
    let wton;
    
    let depositManagerContract;
    let seigManagerContract;
    let seigManagerProxy;
    let seigManagerProxyContract;
    let seigManagerV1Contract;

    let daoCommittee;
    let daoCommitteeOwner;
    let daoagendaManager;
    let daovault;

    let seigManagerV1_2;
    let seigManagerV1_3;
    let depositManagerV1_1;

    let testAddr = "f0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";

    let pause_role = "0xfcb9fcbfa83b897fb2d5cf4b58962164105c1e71489a37ef3ae0db3fdce576f6"

    let member1;
    let member2;
    let member3;

    let member1Contract;
    let member2Contract;
    let member3Contract;

    let member1ContractLogic;
    let member2ContractLogic;
    let member3ContractLogic;

    let member1Addr = "0xd4335a175c36c0922f6a368b83f9f6671bf07606"
    let member2Addr = "0x757de9c340c556b56f62efae859da5e08baae7a2"
    let member3Addr = "0xf0b595d10a92a5a9bc3ffea7e79f5d266b6035ea"

    let member4Addr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66"

    let member1ContractAddr = "0xaeb0463a2fd96c68369c1347ce72997406ed6409"
    let member2ContractAddr = "0xabd15c021942ca54abd944c91705fe70fea13f0d"
    let member3ContractAddr = "0xbdbb2c17846027c75802464d4afdd23a9192e103"

    let beforeclaimAmount;
    let afterclaimAmount;

    let sendether = "0xDE0B6B3A7640000"

    let zeroAddr = "0x0000000000000000000000000000000000000000";
    let oneAddr = "0x0000000000000000000000000000000000000001";
    let twoAddr = "0x0000000000000000000000000000000000000002";
    let tosAddr = "0x409c4D8cd5d2924b9bc5509230d16a61289c8153";

    let adminBytes = "0x0000000000000000000000000000000000000000000000000000000000000000"


    // mainnet network
    const oldContractInfo = {
        TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
        WTON: "0x79e0d92670106c85e9067b56b8f674340dca0bbd",
        DAOVault: "0xB9F6c9E75418D7E5a536ADe08f0218196BB3eBa4",
        DAOAgendaManager: "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08",
        DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    }

    const nowContractInfo = {
        TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
        WTON: "0x79e0d92670106c85e9067b56b8f674340dca0bbd",
        Layer2Registry: "0xA0a9576b437E52114aDA8b0BC4149F2F5c604581",
        CandidateFactory: "0x04e3C2B720FB8896A7f9Ea59DdcA85fD45189C7f",
        CandidateAddOnFactory: "0x04e3C2B720FB8896A7f9Ea59DdcA85fD45189C7f",
        DepositManager: "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F",
        SeigManager: "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7",
    }

    let minimumAmount = ethers.utils.parseUnits("1000", 18);

    let daoCommittee_V1_Contract;
    let daoCommittee_Owner_Contract;

    let daoCommitteeProxy2;
    let daoCommitteeProxy2Contract;

    let user1;
    let user1Addr = "0x9FC3da866e7DF3a1c57adE1a97c9f00a70f010c8"
    let user1Contract;
    let user1ContractLogic;
    let user1ContractAddr;

    let user2;
    let user2Addr = "0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97"
    let user2Contract;
    let user2ContractLogic;
    let user2ContractAddr;

    let agendaID;
    let beforeAgendaID;

    let l1BridgeRegistryV_1;
    let l1BridgeRegistryProxy;
    let l1BridgeRegistry;
    let layer2ManagerV1_1;
    let layer2ManagerProxy;
    let candidateAddOnFactoryImp;
    let candidateAddOnFactoryProxy;
    let candidateAddOnFactory;
    let candidateAddOnV1_1;
    let legacySystemConfig;

    let L1BridgeRegistryV1_1_Addr = "0x16979Ee40B68Bb0e03a6Fa8cc6fb7f1FCC89ecc4"
    let L1BridgeRegistryProxy_Addr = "0x2D47fa57101203855b336e9E61BC9da0A6dd0Dbc"
    let OperatorManagerV1_1_Addr = "0x48f60aAf60D5E162b2DebFD4F70c88fE01b7c331"
    let OperatorManagerFactory_Addr = "0xEEbFD108e124bFeC9545bDbB32aB7840DBC1872e"
    let CandidateAddOnV1_1_Addr = "0xCB75860cFBe1c4668A1D90d8d6c80c1f2c9C93A4"
    let CandidateAddOnFactory_Addr = "0xF08360bdF665eCB2B91217E9843bB241b440239a"
    let CandidateAddOnFactoryProxy_Addr = "0xf37493caC8BF8df0bD96146211D93D548d506fb9"
    let Layer2ManagerV1_1_Addr = "0xF9d75D5814e1C3D734342bD5Ed0637b9c49c3f69"
    let Layer2ManagerProxy_Addr = "0x58B4C2FEf19f5CDdd944AadD8DC99cCC71bfeFDc"
    let SeigManagerV1_2_Addr = "0x1039C6b7C4A5920DCf2aD8BBaaB0fb3F02926898"
    let SeigManagerV1_3_Addr = "0x8C29A0C04a6A3dfee84b602fA13CD4A5a764B3dA"
    let DepositManagerV1_1_Addr = "0xfd0c0AA6505125eFab34A2195F1b9C99AFE8fB06"
    let DAOCommitteeProxy2_Addr = "0xC74b529Ad06E70fA51CDDAD11857D53E6354523d"
    let DAOCommitteeOwner_Addr = "0xf26D736db6a259AfD93ffDa027b0d7DD9748e3FB"
    let DAOCommittee_V1_Addr = "0x9Cb6e22A9a551c13159d818D540aE8bE299967fb"

    let l1Messenger_Addr = "0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE"
    let l1Bridge_Addr = "0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD"
    let l2Ton_Addr = "0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2"

    let multiSigWalletContractAddr = "0x413aD34ed87fF3778Fc4B2472C447E25F6ed9b3F"
    let multiSigWalletContract;

    let owner1Addr = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea"
    let owner2Addr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
    let owner3Addr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

    let owner1
    let owner2
    let owner3

    let titanLayerContract
    let titanOperatorContract

    let titanOperator

    let operatorManagerFactory

    let harveyLayerContractAddr = "0x72b45f14326e22a5B0A883cF0021C1860B9CCEF9"
    let harveyOperatorContractAddr = "0xaB024aDDd4b61e836Bb920Fb9f07bd2bAE0CFA8E"
    
    let harveyLayerContract
    let harveyOperatorContract
    let harveyOperator

    let harveyLayerAdmin
    let harveyLayerAdminAddr = "0x144c804b70b3F4f4ab086c3Bf76d9b0fA47D4823"

    let richTONAddr = "0x89E883c4FF815CFDE8D619856caa50EDf3bEE516"
    let richTON;

    let cooldownTime = 259200

    let deployer;

    let newDAOCommittee_V1Contract


    //changeMember before info
    // [
    //     '0x576C7a48fcEf1C70db632bb1504D9A5C0D0190D3',
    //     BigNumber { value: "0" },
    //     BigNumber { value: "1615364700" },
    //     BigNumber { value: "0" },
    //     BigNumber { value: "1635223931" },
    //     candidateContract: '0x576C7a48fcEf1C70db632bb1504D9A5C0D0190D3',
    //     indexMembers: BigNumber { value: "0" },
    //     memberJoinedTime: BigNumber { value: "1615364700" },
    //     rewardPeriod: BigNumber { value: "0" },
    //     claimedTimestamp: BigNumber { value: "1635223931" }
    //   ]

    before('create fixture loader', async () => {
        const accounts = await ethers.getSigners();
        deployer = accounts[0]


        await hre.network.provider.send("hardhat_impersonateAccount", [
            daoAdminAddress,
        ]);
        daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            oldContractInfo.DAOCommitteeProxy,
        ]);
        daoCommitteeAdminContract =  await hre.ethers.getSigner(oldContractInfo.DAOCommitteeProxy);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            harveyLayerAdminAddr,
        ]);
        harveyLayerAdmin =  await hre.ethers.getSigner(harveyLayerAdminAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member1Addr,
        ]);
        member1 = await hre.ethers.getSigner(member1Addr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member2Addr,
        ]);
        member2 = await hre.ethers.getSigner(member2Addr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member3Addr,
        ]);
        member3 = await hre.ethers.getSigner(member3Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            member1ContractAddr,
        ]);
        member1Contract = await hre.ethers.getSigner(member1ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member2ContractAddr,
        ]);
        member2Contract = await hre.ethers.getSigner(member2ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member3ContractAddr,
        ]);
        member3Contract = await hre.ethers.getSigner(member3ContractAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            user1Addr,
        ]);
        user1 = await hre.ethers.getSigner(user1Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            user2Addr,
        ]);
        user2 = await hre.ethers.getSigner(user2Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            owner1Addr,
        ]);
        owner1 = await hre.ethers.getSigner(owner1Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            owner2Addr,
        ]);
        owner2 = await hre.ethers.getSigner(owner2Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            owner3Addr,
        ]);
        owner3 = await hre.ethers.getSigner(owner3Addr);
        
        await hre.network.provider.send("hardhat_setBalance", [
            owner1Addr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            owner2Addr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            owner3Addr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            user1Addr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            member1ContractAddr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            member2ContractAddr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            member3ContractAddr,
            sendether
        ]);


        await hre.network.provider.send("hardhat_setBalance", [
            member3Addr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            daoCommitteeAdminContract.address,
            sendether
        ]);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            richTONAddr,
        ]);
        richTON = await hre.ethers.getSigner(richTONAddr);
        
        await hre.network.provider.send("hardhat_setBalance", [
            richTONAddr,
            sendether
        ]);
        
        await hre.network.provider.send("hardhat_setBalance", [
            harveyLayerAdminAddr,
            sendether
        ]);

    })

    describe("Setting TON-related Contract", () => {
        it("Set TON", async () => {
            ton = new ethers.Contract(
                oldContractInfo.TON,
                TonABI,
                daoCommitteeAdmin
            )
        })

        it("Set WTON", async () => {
            wton = new ethers.Contract(
                oldContractInfo.WTON,
                WtonABI,
                daoCommitteeAdmin
            )
        })

        it("Set SeigManager", async () => {
            seigManagerContract = new ethers.Contract(
                nowContractInfo.SeigManager,
                SeigManagerABI,
                daoCommitteeAdmin
            )
        })


        it("TON Admin Test", async () => {
            let balanceOfZero = await ton.balanceOf(ethers.constants.AddressZero)
            let balanceOfdaoAdminAddress = await ton.balanceOf(daoAdminAddress)
            // console.log('balanceOfZero' , balanceOfZero)
            // console.log('balanceOfdaoAdminAddress' , balanceOfdaoAdminAddress)

            await (await ton.connect(daoCommitteeAdmin).transfer(
                '0x0000000000000000000000000000000000000001',
                ethers.BigNumber.from("1")
            )).wait()

            balanceOfdaoAdminAddress = await ton.balanceOf(daoAdminAddress)
            // console.log('balanceOfdaoAdminAddress' , balanceOfdaoAdminAddress)
        })
    })

    describe("Set Contract", () => {
        it("set DAOCommitteeProxy2", async () => {
            daoCommitteeProxy2 = await ethers.getContractAt(
                "DAOCommitteeProxy2", 
                DAOCommitteeProxy2_Addr, 
                daoCommitteeAdmin
            )
        })

        it("set DAOCommitteeOwner", async () => {
            daoCommitteeOwner = await ethers.getContractAt(
                "DAOCommitteeOwner", 
                DAOCommitteeOwner_Addr, 
                daoCommitteeAdmin
            )
        })
        
        it("set SeigManagerV1_2", async () => {
            seigManagerV1_2 = await ethers.getContractAt(
                "SeigManagerV1_2", 
                nowContractInfo.SeigManager, 
                daoCommitteeAdmin
            )
        })

        it("set SeigManagerV1_3", async () => {
            seigManagerV1_3 = await ethers.getContractAt(
                "SeigManagerV1_3", 
                nowContractInfo.SeigManager, 
                daoCommitteeAdmin
            )
        })

        it("set DepositManagerV1_1", async () => {
            depositManagerV1_1 = await ethers.getContractAt(
                "DepositManagerV1_1", 
                DepositManagerV1_1_Addr, 
                daoCommitteeAdmin
            )
        })

        it("set L1BridgeRegistryV1_1", async () => {
            l1BridgeRegistryV_1 = await ethers.getContractAt(
                "L1BridgeRegistryV1_1", 
                L1BridgeRegistryProxy_Addr, 
                daoCommitteeAdmin
            )
        })

        it("set l1BridgeRegistryProxy", async () => {
            l1BridgeRegistryProxy = await ethers.getContractAt(
                "L1BridgeRegistryProxy", 
                L1BridgeRegistryProxy_Addr, 
                daoCommitteeAdmin
            )
        })

        it("set Layer2ManagerV1_1", async () => {
            layer2ManagerV1_1 = await ethers.getContractAt(
                "Layer2ManagerV1_1", 
                Layer2ManagerProxy_Addr, 
                daoCommitteeAdmin
            )
        })

        it("set Layer2ManagerProxy", async () => {
            layer2ManagerProxy = await ethers.getContractAt(
                "Layer2ManagerProxy", 
                Layer2ManagerProxy_Addr, 
                daoCommitteeAdmin
            )
        })

        it("set CandidateAddOnFactory", async () => {
            candidateAddOnFactoryImp = await ethers.getContractAt(
                "CandidateAddOnFactory", 
                CandidateAddOnFactory_Addr, 
                daoCommitteeAdmin
            )
        })
        it("set CandidateAddOnFactoryProxy", async () => {
            candidateAddOnFactoryProxy = await ethers.getContractAt(
                "CandidateAddOnFactoryProxy", 
                CandidateAddOnFactoryProxy_Addr, 
                daoCommitteeAdmin
            )
        })

        it("Set member1CandidateContract", async () => {
            member1ContractLogic = new ethers.Contract(
                member1ContractAddr,
                CandidateABI,
                daoCommitteeAdmin
            )
        })

        it("Set member2CandidateContract", async () => {
            member2ContractLogic = new ethers.Contract(
                member2ContractAddr,
                CandidateABI,
                daoCommitteeAdmin
            )
        })

        it("Set member3CandidateContract", async () => {
            member3ContractLogic = new ethers.Contract(
                member3ContractAddr,
                CandidateABI,
                daoCommitteeAdmin
            )
        })

    })

    describe("Set Contract", () => {
        it("Set DAOProxy", async () => {
            daoCommitteeProxy = new ethers.Contract(
                oldContractInfo.DAOCommitteeProxy,
                DAOCommitteeProxyABI,
                daoCommitteeAdmin
            )
        })

        it("set DAOProxy2", async () => {
            daoCommitteeProxy2Contract = new ethers.Contract(
                oldContractInfo.DAOCommitteeProxy,
                DAOProxy2ABI,
                daoCommitteeAdmin
            )
        })

        it("pauseProxy check", async () => {
            let pauseProxy = await daoCommitteeProxy.pauseProxy()
            // console.log('pauseProxy', pauseProxy)

            if (pauseProxy == true) {
                await (await daoCommitteeProxy.connect(daoCommitteeAdmin).setProxyPause(false)).wait()
            }
            pauseProxy = await daoCommitteeProxy.pauseProxy()
            // console.log('pauseProxy', pauseProxy)
        })

        it("set DAOAgendaManager", async () => {
            daoagendaManager = new ethers.Contract(
                oldContractInfo.DAOAgendaManager,
                DAOAgendaManagerABI,
                daoCommitteeAdmin
            )
        })

        it("set DAO NewLogic", async () => {
            daoCommittee_V1_Contract = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommittee_V1ABI,
                daoCommitteeAdmin
            )
        })

        it("set DAO OnwerLogic", async () => {
            daoCommittee_Owner_Contract = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommitteeOwnerABI,
                daoCommitteeAdmin
            )
        })

        it("set depositManager", async () => {
            depositManagerProxy = new ethers.Contract(
                nowContractInfo.DepositManager,  
                DepositManagerProxy_Json.abi, 
                daoCommitteeAdmin
            )
        })

        it("set seigManagerProxy", async () => {
            seigManagerProxy = new ethers.Contract(
                nowContractInfo.SeigManager,  
                SeigManagerProxy_Json.abi, 
                daoCommitteeAdmin
            )
        })

    })

    describe("Check the executed agenda", () => {
        it("Check implementation", async () => {
            let implementation = await daoCommitteeProxy.implementation()
            expect(implementation).to.be.equal(DAOCommitteeProxy2_Addr)
        })

        it("Check proxyImplementation(0) = DAOCommittee_V1", async () => {
            let implementation = await daoCommitteeProxy2Contract.proxyImplementation(0)
            expect(implementation).to.be.equal(DAOCommittee_V1_Addr)
        })

        it("Check proxyImplementation(1) = DAOCommitteeOwner", async () => {
            let implementation = await daoCommitteeProxy2Contract.proxyImplementation(1)
            expect(implementation).to.be.equal(DAOCommitteeOwner_Addr)
        })

        it("Check CandidateAddOnFactory Addr", async () => {
            let address = await daoCommitteeProxy2Contract.candidateAddOnFactory()
            expect(address).to.be.equal(candidateAddOnFactoryProxy.address)
        })

        it("Check Layer2Manager Addr", async () => {
            let address = await daoCommitteeProxy2Contract.layer2Manager()
            expect(address).to.be.equal(layer2ManagerProxy.address)
        })

        it("Check daoCommitteeOwner cooldownTime", async () => {
            let getCooldownTime = await daoCommittee_Owner_Contract.cooldownTime()
            expect(getCooldownTime).to.be.equal(cooldownTime)
        })

        it("Check ton Addr", async () => {
            let address = await daoCommitteeProxy.ton()
            let address2 = await daoCommitteeProxy2Contract.ton()

            expect(address.toUpperCase()).to.be.equal(address2.toUpperCase())
            expect(address.toUpperCase()).to.be.equal(ton.address.toUpperCase())
        })

        it("Check daoVault Addr", async () => {
            let address = await daoCommitteeProxy.daoVault()
            let address2 = await daoCommitteeProxy2Contract.daoVault()
            expect(address).to.be.equal(address2)
            expect(address).to.be.equal(oldContractInfo.DAOVault)
        })

        it("Check agendaManager Addr", async () => {
            let address = await daoCommitteeProxy.agendaManager()
            let address2 = await daoCommitteeProxy2Contract.agendaManager()
            expect(address).to.be.equal(address2)
            expect(address).to.be.equal(oldContractInfo.DAOAgendaManager)
        })

        it("Check candidateFactory Addr", async () => {
            let address = await daoCommitteeProxy.candidateFactory()
            let address2 = await daoCommitteeProxy2Contract.candidateFactory()
            // console.log(address)
            // console.log(address2)
            expect(address).to.be.equal(address2)
            expect(address.toUpperCase()).to.be.equal(nowContractInfo.CandidateFactory.toUpperCase())
        })

        it("Check layer2Registry Addr", async () => {
            let address = await daoCommitteeProxy.layer2Registry()
            let address2 = await daoCommitteeProxy2Contract.layer2Registry()
            // console.log(address)
            // console.log(address2)
            expect(address).to.be.equal(address2)
            expect(address.toUpperCase()).to.be.equal(nowContractInfo.Layer2Registry.toUpperCase())
        })

        it("Check seigManager Addr", async () => {
            let address = await daoCommitteeProxy.seigManager()
            let address2 = await daoCommitteeProxy2Contract.seigManager()
            // console.log(address)
            // console.log(address2)
            expect(address).to.be.equal(address2)
            expect(address.toUpperCase()).to.be.equal(nowContractInfo.SeigManager.toUpperCase())
        })

        it("Check maxMember", async () => {
            let maxMember = await daoCommitteeProxy.maxMember()
            let maxMember2 = await daoCommitteeProxy2Contract.maxMember()
            expect(maxMember).to.be.equal(maxMember2)
            expect(maxMember).to.be.equal(3)
        })

        it("Check quorum", async () => {
            let quorum = await daoCommitteeProxy.quorum()
            let quorum2 = await daoCommitteeProxy2Contract.quorum()
            expect(quorum).to.be.equal(quorum2)
            expect(quorum).to.be.equal(2)
        })
        
        it("Check wton", async () => {
            let wtonAddr= await daoCommitteeProxy2Contract.wton()
            expect(wtonAddr.toUpperCase()).to.be.equal((wton.address).toUpperCase())
        })
    })

    describe("Deploy And UpgradeTo2 newDAOLogic", () => {
        it("Deploy the DAOCommittee_V1", async () => {
            const newDAOCommitteeV1_1ImpContract = await ethers.getContractFactory("DAOCommittee_V1")
            newDAOCommittee_V1Contract = await newDAOCommitteeV1_1ImpContract.deploy();
        })

        it("upgradeTo2 Agenda", async () => {
            let targets = []
            let params = []
            let callDtata

            // =========================================
            //  1. set DAOCommitteeProxy upgradeTo2 to DAOCommittee_V1
            targets.push(daoCommitteeProxy.address)
            callDtata = daoCommitteeProxy2Contract.interface.encodeFunctionData("upgradeTo2", [newDAOCommittee_V1Contract.address])
            params.push(callDtata)

            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            const agendaFee = await daoagendaManager.createAgendaFees();
            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    params
                ]
            )

            await (await ton.connect(daoCommitteeAdmin).transfer(
                user1.address,
                agendaFee
            )).wait()

             // =========================================
            // Propose an agenda
            let receipt = await (await ton.connect(user1).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            )).wait()

            agendaID = (await daoagendaManager.numAgendas()).sub(1);
        })

        it('increase block time and check votable', async function () {
            agendaID = (await daoagendaManager.numAgendas()).sub(1);
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const noticeEndTimestamp = agenda[AGENDA_INDEX_NOTICE_END_TIMESTAMP];
            const noticeEndTimestamp = agenda[1];
            await time.increaseTo(Number(noticeEndTimestamp));
            expect(await daoagendaManager.isVotableStatus(agendaID)).to.be.equal(true);
        });


        it("castVote member1", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(member1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(member1Contract).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, member1Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, member1Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("castVote member3", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(member3Contract).castVote(
                agendaID,
                vote,
                "member3 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, member3Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, member3Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                await time.increaseTo(Number(votingEndTimestamp));

                expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });

        it("execute agenda", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            // const check = await daoagendaManager.canExecuteAgenda(agendaID);
            // console.log(check)
            // const check2 = await daoagendaManager.getExecutionInfo(agendaID);
            // console.log(check2)
            
            await daoCommittee_V1_Contract.executeAgenda(agendaID);

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })


        it("Ensure the agenda is properly executed proxyImplementation(0) = DAOCommittee_V1", async () => {
            let implementation = await daoCommitteeProxy2Contract.proxyImplementation(0)
            expect(implementation).to.be.equal(newDAOCommittee_V1Contract.address)
        })
    })

    describe("createCandidateAddOn Test before setting", () => {
        it("Set operatorManagerFactory", async () => {
            operatorManagerFactory = new ethers.Contract(
                OperatorManagerFactory_Addr,
                OperatorManagerFactory_ABI,
                daoCommitteeAdmin
            )
        })
    })

    describe("createCandidateAddOn Test", () => {

        // it('set Titan LegacySystemConfig ', async () => {
        //     legacySystemConfig = (await (await ethers.getContractFactory("LegacySystemConfig")).connect(daoCommitteeAdmin).deploy())

        //     let name = 'Titan'
        //     let addresses = {
        //         l1CrossDomainMessenger: l1Messenger_Addr,
        //         l1ERC721Bridge: ethers.constants.AddressZero,
        //         l1StandardBridge: l1Bridge_Addr,
        //         l2OutputOracle: ethers.constants.AddressZero,
        //         optimismPortal: ethers.constants.AddressZero,
        //         optimismMintableERC20Factory: ethers.constants.AddressZero
        //     }

        //     await (await legacySystemConfig.connect(daoCommitteeAdmin).setAddresses(
        //         name, addresses, l1BridgeRegistryProxy.address, daoCommitteeAdmin.address
        //     )).wait()
        // })

        // it('registerSystemConfigByManager  ', async () => {
        //     let type = 1;
        //     let name = 'Titan'

        //     // console.log("1")
        //     // console.log(daoCommitteeAdminContract.address)
        //     // let check = await l1BridgeRegistryProxy.isManager(daoCommitteeAdminContract.address)
        //     // console.log(check)
        //     let receipt = await (await l1BridgeRegistryV_1.connect(daoCommitteeAdminContract)["registerRollupConfigByManager(address,uint8,address,string)"](
        //         legacySystemConfig.address,
        //         type,
        //         l2Ton_Addr,
        //         name
        //     )).wait()
        //     // console.log("2")

        //     const topic = l1BridgeRegistryV_1.interface.getEventTopic('RegisteredRollupConfig');
        //     const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        //     const deployedEvent = l1BridgeRegistryV_1.interface.parseLog(log);

        //     expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
        //     expect(deployedEvent.args.type_).to.be.eq(type)
        // })

        // it("registerCandidateAddOn", async () => {
        //     expect((await layer2ManagerV1_1.statusLayer2(legacySystemConfig.address))).to.be.eq(0)

        //     let amount = await layer2ManagerV1_1.minimumInitialDepositAmount();
        //     let amount2 = ethers.utils.parseEther("2000")
        //     await (await ton.connect(daoCommitteeAdmin).transfer(
        //         user1.address,
        //         amount2
        //     )).wait()
        //     let balance = await ton.balanceOf(user1.address)
        //     expect(balance).to.be.gt(amount)

        //     let allowance = await ton.allowance(user1.address, layer2ManagerV1_1.address)
        //     if(allowance.lt(amount)){
        //         await ton.connect(user1).approve(layer2ManagerV1_1.address, amount);
        //     }

        //     const name = await legacySystemConfig.name()
        //     const operatorAddress = await operatorManagerFactory.getAddress(legacySystemConfig.address)

        //     const receipt = await (await layer2ManagerV1_1.connect(user1).registerCandidateAddOn(
        //         legacySystemConfig.address,
        //         amount,
        //         true,
        //         name
        //     )).wait()

        //     const topic = layer2ManagerV1_1.interface.getEventTopic('RegisteredCandidateAddOn');
        //     const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
        //     const deployedEvent = layer2ManagerV1_1.interface.parseLog(log);
            
        //     const topic2 = daoCommittee_V1_Contract.interface.getEventTopic('CandidateContractCreated');
        //     const log2 = receipt.logs.find(x => x.topics.indexOf(topic2) >= 0);
        //     const deployedEvent2 = daoCommittee_V1_Contract.interface.parseLog(log2);

        //     expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
        //     expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
        //     expect(deployedEvent.args.memo).to.be.eq(name)
        //     expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
        //     expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

        //     titanLayerAddress = deployedEvent.args.candidateAddOn;
        //     titanOperatorContractAddress = deployedEvent.args.operator;
        //     expect((await layer2ManagerV1_1.statusLayer2(legacySystemConfig.address))).to.be.eq(1)
        //     // console.log(deployedEvent2)
        //     // console.log(addr1.address)
        //     // console.log(titanLayerAddress)
        //     // console.log(titanOperatorContractAddress)

        //     titanLayerContract =  (await ethers.getContractAt(
        //         "CandidateAddOnV1_1", 
        //         titanLayerAddress, 
        //         daoCommitteeAdmin
        //     )) 

        //     titanOperatorContract = (await ethers.getContractAt(
        //         "OperatorManagerV1_1", 
        //         titanOperatorContractAddress, 
        //         daoCommitteeAdmin
        //     ))

        //     await hre.network.provider.send("hardhat_impersonateAccount", [
        //         titanOperatorContractAddress,
        //     ]);
        //     titanOperator = await hre.ethers.getSigner(titanOperatorContractAddress);

        //     await hre.network.provider.send("hardhat_setBalance", [
        //         titanOperatorContractAddress,
        //         sendether
        //     ]);
        // })

        it("Set HarveyLayerContract", async () => {
            harveyLayerContract =  (await ethers.getContractAt(
                "CandidateAddOnV1_1", 
                harveyLayerContractAddr, 
                daoCommitteeAdmin
            )) 

            harveyOperatorContract = (await ethers.getContractAt(
                "OperatorManagerV1_1", 
                harveyOperatorContractAddr, 
                daoCommitteeAdmin
            ))

            await hre.network.provider.send("hardhat_impersonateAccount", [
                harveyOperatorContractAddr,
            ]);
            harveyOperator = await hre.ethers.getSigner(harveyOperatorContractAddr);

            await hre.network.provider.send("hardhat_setBalance", [
                harveyOperatorContractAddr,
                sendether
            ]);
        })

        it("privateLayer2 Check", async () => {
            let privateLayer2Check = await daoCommittee_V1_Contract.privateLayer2(harveyOperatorContract.address);
            // console.log("privateLayer2Check :", privateLayer2Check)
            expect(privateLayer2Check).to.be.equal(false)
        })

        it("CandidateAddOn operatorAmountCheck", async () => {
            let operatorAmountCheck = await daoCommittee_V1_Contract.operatorAmountCheck(harveyLayerContract.address, harveyOperatorContract.address);
            // console.log("operatorAmountCheck :", operatorAmountCheck)
            expect(operatorAmountCheck).to.be.gt(0)
        })

        it("CandidateAddOn operatorCheck", async () => {
            let operatorAmount = await daoCommittee_V1_Contract.operatorCheck(harveyOperatorContract.address);
            // console.log("operatorAmount :", operatorAmount)
            expect(operatorAmount).to.be.gt(0)
        })

        it("retireMember number1", async () => {
            let memberCheck = await daoCommittee_V1_Contract.members(0)
            expect(memberCheck.toUpperCase()).to.be.equal(member1Addr.toUpperCase())
            // let beforeWTONAmount = await wton.balanceOf(member2.address)
            let blacklistCheck = await daoCommittee_V1_Contract.blacklist(member1ContractLogic.address)
            expect(blacklistCheck).to.be.equal(false)

            await (
                await member1ContractLogic.connect(member1).retireMember()
            ).wait();

            memberCheck = await daoCommittee_V1_Contract.members(0)
            expect(memberCheck).to.be.equal(zeroAddr)
            // let afterWTONAmount = await wton.balanceOf(member2.address)
            // expect(afterWTONAmount).to.be.gt(beforeWTONAmount)
            blacklistCheck = await daoCommittee_V1_Contract.blacklist(member1ContractLogic.address)
            expect(blacklistCheck).to.be.equal(true)
        })


        it("changeMember (CandidateAddOn) is success", async () => {
            let memberCheck = await daoCommittee_V1_Contract.members(0)
            expect(memberCheck).to.be.equal(zeroAddr)

            let check = await harveyLayerContract.operator();
            let check2 = await harveyLayerContract.candidate();
            let check3 = await harveyLayerContract.committee();
            expect(check).to.be.equal(check2)
            expect(check).to.be.equal(harveyOperatorContract.address)
            expect(check3).to.be.equal(oldContractInfo.DAOCommitteeProxy)
            // console.log(check)
            // console.log(check2)
            // console.log(check3)
            // console.log(harveyOperatorContract.address)
            // console.log(user1.address)

            await (
                await harveyLayerContract.connect(harveyLayerAdmin).changeMember(0)
            ).wait();

            memberCheck = await daoCommittee_V1_Contract.members(0)
            expect(memberCheck.toUpperCase()).to.be.equal(harveyOperatorContract.address.toUpperCase())
        })

        it("setMemoOnCandidate (createCandidateAddon) is success", async () => {
            let beforeMemo = await harveyLayerContract.memo();

            await daoCommittee_V1_Contract.connect(harveyLayerAdmin).setMemoOnCandidate(
                harveyOperatorContract.address,
                "titanMemo"
            )

            let afterMemo = await harveyLayerContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
        })

        it("setMemoOnCandidateContract (createCandidateAddon)", async () => {
            let beforeMemo = await harveyLayerContract.memo();
            let changeMemo = "Change2"

            await daoCommittee_V1_Contract.connect(harveyLayerAdmin).setMemoOnCandidateContract(
                harveyLayerContract.address,
                "Change2"
            )

            let afterMemo = await harveyLayerContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
            expect(changeMemo).to.be.equal(afterMemo)
        })

        it("getClaimableActivityReward & claimActivityReward test (createCandidateAddon)", async () => {
            let amount = await daoCommittee_V1_Contract.getClaimableActivityReward(harveyOperatorContract.address)
            expect(amount).to.be.gt(0);

            await harveyLayerContract.connect(harveyLayerAdmin).claimActivityReward()

            let amount2 = await daoCommittee_V1_Contract.getClaimableActivityReward(harveyOperatorContract.address)
            expect(amount).to.be.gt(amount2);
        })

        it("totalStaked & stakedOf test (createCandidateAddon)", async () => {
            let totalStakedAmount = await harveyLayerContract.totalStaked()
            let stakedOfAmount = await harveyLayerContract.stakedOf(harveyOperatorContract.address)

            expect(totalStakedAmount).to.be.equal(stakedOfAmount)
            expect(totalStakedAmount).to.be.gt(0)            
        })

        it("updateSeigniorage test (createCandidateAddon)", async () => {
            const beforeSeigBlock = await seigManagerV1_2.lastCommitBlock(harveyLayerContract.address)

            await harveyLayerContract.connect(user1).updateSeigniorage()

            const afterSeigBlock = await seigManagerV1_2.lastCommitBlock(harveyLayerContract.address)

            expect(afterSeigBlock).to.be.gt(beforeSeigBlock)
        })

        it("Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 40;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode]
                ]
            );
    
            const agendaFee = await daoagendaManager.createAgendaFees();
            expect(agendaFee).to.be.gt(0);

            await (await ton.connect(daoCommitteeAdmin).transfer(
                user1.address,
                agendaFee
            )).wait()

            const beforeBalance = await ton.balanceOf(user1.address);

            // create agenda
            await ton.connect(user1).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            );

            const afterBalance = await ton.balanceOf(user1.address);
            expect(afterBalance).to.be.lt(beforeBalance);
            expect(beforeBalance.sub(afterBalance)).to.be.equal(agendaFee)

            agendaID = (await daoagendaManager.numAgendas()).sub(1);
            //const executionInfo = await agendaManager.executionInfos(agendaID);
            const executionInfo = await daoagendaManager.getExecutionInfo(agendaID);
            // console.log("executionInfo :", executionInfo);
            expect(executionInfo[0][0]).to.be.equal(daoagendaManager.address);
            expect(executionInfo[1][0]).to.be.equal(functionBytecode);
        })

        it('increase block time and check votable', async function () {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const noticeEndTimestamp = agenda[AGENDA_INDEX_NOTICE_END_TIMESTAMP];
            const noticeEndTimestamp = agenda[1];
            await time.increaseTo(Number(noticeEndTimestamp)+Number(10));
            expect(await daoagendaManager.isVotableStatus(agendaID)).to.be.equal(true);
        });

        it("cast vote (candidateAddOn)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(harveyOperatorContract.address)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await harveyLayerContract.connect(harveyLayerAdmin).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, harveyOperatorContract.address);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, harveyOperatorContract.address);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("cast vote (createCandidate)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(member3Contract).castVote(
                agendaID,
                vote,
                "member3 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, member3Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, member3Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                await time.increaseTo(Number(votingEndTimestamp));

                expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });

        it("execute agenda", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            // const check = await daoagendaManager.canExecuteAgenda(agendaID);
            // console.log(check)
            // const check2 = await daoagendaManager.getExecutionInfo(agendaID);
            // console.log(check2)

            const beforeValue = await daoagendaManager.minimumNoticePeriodSeconds();
            
            await daoCommittee_V1_Contract.executeAgenda(agendaID);

            const afterValue = await daoagendaManager.minimumNoticePeriodSeconds();

            expect(beforeValue).to.be.not.equal(afterValue);
            expect(afterValue).to.be.equal(40);

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        // it("currentAgendaStatus test", async () => {
        //     let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
        //     expect(result.agendaResult).to.be.equal(1)
        //     expect(result.agendaStatus).to.be.equal(4)
        // })

        it("retireMember (candidateAddOn) (add blackList) (onlyMember)", async () => {
            let memberCheck = await daoCommittee_V1_Contract.members(0)
            expect(memberCheck.toUpperCase()).to.be.equal(harveyOperatorContract.address.toUpperCase())
            // let beforeWTONAmount = await wton.balanceOf(member2.address)
            let blacklistCheck = await daoCommittee_V1_Contract.blacklist(harveyLayerContract.address)
            expect(blacklistCheck).to.be.equal(false)

            await (
                await harveyLayerContract.connect(harveyLayerAdmin).retireMember()
            ).wait();

            memberCheck = await daoCommittee_V1_Contract.members(0)
            expect(memberCheck).to.be.equal(zeroAddr)

            blacklistCheck = await daoCommittee_V1_Contract.blacklist(harveyLayerContract.address)
            expect(blacklistCheck).to.be.equal(true)
        })

    })


})
