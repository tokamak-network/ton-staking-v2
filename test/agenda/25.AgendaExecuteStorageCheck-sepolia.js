const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const { readContracts, deployedContracts } = require("../common_func");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");

const { expect, assert } = chai;
chai.use(solidity);
require("chai").should();

const Web3EthAbi = require('web3-eth-abi');
const { padLeft } = require('web3-utils');

const { time } = require("@nomicfoundation/hardhat-network-helpers");

const networkName = "sepolia"

// const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'
const daoAdminAddress = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

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

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;

const CandidateABI = require("../../abi/Candidate.json").abi;
const DepositManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const SeigManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const MultiSigwallet_Json = require('../abi/MultiSigWallet.json')


describe("DAO Proxy Change Test", () => {

    let execute = false

    let daoCommitteeAdmin;
    let daoCommitteeAdminContract;
    let daoCommitteeProxy;

    let ton;
    let wton;
    
    let seigManagerContract;
    let seigManagerProxy;

    let daoCommittee;
    let daoCommitteeOwner;
    let daoagendaManager;

    let seigManagerV1_2;
    let seigManagerV1_3;
    let depositManagerV1_1;

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

    let member1ContractAddr = "0xaeb0463a2fd96c68369c1347ce72997406ed6409"
    let member2ContractAddr = "0xabd15c021942ca54abd944c91705fe70fea13f0d"
    let member3ContractAddr = "0xbdbb2c17846027c75802464d4afdd23a9192e103"

    let sendether = "0xDE0B6B3A7640000"

    let zeroAddr = "0x0000000000000000000000000000000000000000";

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


    let daoCommitteeLogic;

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

    let multiSigWalletContractAddr = "0x413aD34ed87fF3778Fc4B2472C447E25F6ed9b3F"
    let multiSigWalletContract;

    let owner1Addr = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea"
    let owner2Addr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
    let owner3Addr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"

    let owner1
    let owner2
    let owner3


    let richTONAddr = "0x89E883c4FF815CFDE8D619856caa50EDf3bEE516"
    let richTON;

    let cooldownTime = 259200


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
        await hre.network.provider.send("hardhat_impersonateAccount", [
            daoAdminAddress,
        ]);
        daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            oldContractInfo.DAOCommitteeProxy,
        ]);
        daoCommitteeAdminContract =  await hre.ethers.getSigner(oldContractInfo.DAOCommitteeProxy);
        
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

        it("set DAOCommittee_V1", async () => {
            daoCommitteeLogic = await ethers.getContractAt(
                "DAOCommittee_V1", 
                DAOCommittee_V1_Addr, 
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
        
        it("set SeigManagerV1_3", async () => {
            seigManagerV1_2 = await ethers.getContractAt(
                "SeigManagerV1_2", 
                SeigManagerV1_2_Addr, 
                daoCommitteeAdmin
            )
        })

        it("set SeigManagerV1_3", async () => {
            seigManagerV1_3 = await ethers.getContractAt(
                "SeigManagerV1_3", 
                SeigManagerV1_3_Addr, 
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
                L1BridgeRegistryV1_1_Addr, 
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
                Layer2ManagerV1_1_Addr, 
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


        // it("Deploy the LegacySystemConfig", async () => {
        //     const legacySystemConfigContract = await ethers.getContractFactory("LegacySystemConfig")
        //     legacySystemConfig = await legacySystemConfigContract.deploy();

        //     await legacySystemConfig.deployed()
        // })

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


        it("Set MultiSigWalletContract", async () => {
            multiSigWalletContract = new ethers.Contract(
                multiSigWalletContractAddr,
                MultiSigwallet_Json.abi,
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


        // it("setting the LegacySystemConfig", async () => {
        //     let name = 'Titan'
        //     let l1MessengerAddress = "0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE"
        //     let l1BridgeAddress = "0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD"

        //     let addresses = {
        //         l1CrossDomainMessenger: l1MessengerAddress,
        //         l1ERC721Bridge: ethers.constants.AddressZero,
        //         l1StandardBridge: l1BridgeAddress,
        //         l2OutputOracle: ethers.constants.AddressZero,
        //         optimismPortal: ethers.constants.AddressZero,
        //         optimismMintableERC20Factory: ethers.constants.AddressZero
        //     }
        //     await (await legacySystemConfig.setAddresses(
        //         name, addresses, l1BridgeRegistryProxy.address
        //     )).wait()
        // })

        // it('L1BridgeRegistryProxy transferOwnership', async () => {
        //     await (await l1BridgeRegistryProxy.addManager(oldContractInfo.DAOCommitteeProxy)).wait()
        //     await (await l1BridgeRegistryProxy.transferOwnership(oldContractInfo.DAOCommitteeProxy)).wait()
        //     expect(await l1BridgeRegistryProxy.isAdmin(oldContractInfo.DAOCommitteeProxy)).to.be.eq(true)
        // });

    })

    describe("Check the Storage", () => {
        it("Check implementation", async () => {
            let implementation = await daoCommitteeProxy.implementation()
            if (execute) {
                expect(implementation).to.be.equal(DAOCommitteeProxy2_Addr)
            } else {
                expect(implementation).not.to.be.equal(DAOCommitteeProxy2_Addr)
            }
        })

        it("Check proxyImplementation(0) = DAOCommittee_V1", async () => {
            let implementation = await daoCommitteeProxy2Contract.proxyImplementation(0)
            if (execute) {
                expect(implementation).to.be.equal(DAOCommittee_V1_Addr)
            } else {
                expect(implementation).not.to.be.equal(DAOCommittee_V1_Addr)
            }
        })

        it("Check proxyImplementation(1) = DAOCommitteeOwner", async () => {
            let implementation = await daoCommitteeProxy2Contract.proxyImplementation(1)
            if (execute) {
                expect(implementation).to.be.equal(DAOCommitteeOwner_Addr)
            } else {
                expect(implementation).not.to.be.equal(DAOCommitteeOwner_Addr)
            }
        })

        it("Check CandidateAddOnFactory Addr", async () => {
            let address = await daoCommitteeProxy2Contract.candidateAddOnFactory()
            if (execute) {
                expect(address).to.be.equal(candidateAddOnFactoryProxy.address)
            } else {
                expect(address).not.to.be.equal(candidateAddOnFactoryProxy.address)
            }
        })

        it("Check Layer2Manager Addr", async () => {
            let address = await daoCommitteeProxy2Contract.layer2Manager()
            if (execute) {
                expect(address).to.be.equal(layer2ManagerProxy.address)
            } else {
                expect(address).not.to.be.equal(layer2ManagerProxy.address)
            }
        })

        it("Check daoCommitteeOwner cooldownTime", async () => {
            if (execute) {
                let getCooldownTime = await daoCommittee_Owner_Contract.cooldownTime()
                expect(getCooldownTime).to.be.equal(cooldownTime)
            } else {
                await expect(daoCommittee_Owner_Contract.cooldownTime()).to.be.reverted;
            }
        })

        it("Check ton Addr", async () => {
            let address = await daoCommitteeProxy.ton()
            let address2 = await daoCommitteeProxy2Contract.ton()
            if (execute) {
                expect(address).to.be.equal(address2)
                expect(address).to.be.equal(ton.address)
            }
        })

        it("Check daoVault Addr", async () => {
            let address = await daoCommitteeProxy.daoVault()
            let address2 = await daoCommitteeProxy2Contract.daoVault()
            if (execute) {
                expect(address).to.be.equal(address2)
                expect(address).to.be.equal(oldContractInfo.DAOVault)
            }
        })

        it("Check agendaManager Addr", async () => {
            let address = await daoCommitteeProxy.agendaManager()
            let address2 = await daoCommitteeProxy2Contract.agendaManager()
            if (execute) {
                expect(address).to.be.equal(address2)
                expect(address).to.be.equal(oldContractInfo.DAOAgendaManager)
            }
        })

        it("Check candidateFactory Addr", async () => {
            let address = await daoCommitteeProxy.candidateFactory()
            let address2 = await daoCommitteeProxy2Contract.candidateFactory()
            // console.log(address)
            // console.log(address2)
            if (execute) {
                expect(address).to.be.equal(address2)
                expect(address.toUpperCase()).to.be.equal(nowContractInfo.CandidateFactory.toUpperCase())
            }
        })

        it("Check layer2Registry Addr", async () => {
            let address = await daoCommitteeProxy.layer2Registry()
            let address2 = await daoCommitteeProxy2Contract.layer2Registry()
            // console.log(address)
            // console.log(address2)
            if (execute) {
                expect(address).to.be.equal(address2)
                expect(address.toUpperCase()).to.be.equal(nowContractInfo.Layer2Registry.toUpperCase())
            }
        })

        it("Check seigManager Addr", async () => {
            let address = await daoCommitteeProxy.seigManager()
            let address2 = await daoCommitteeProxy2Contract.seigManager()
            // console.log(address)
            // console.log(address2)
            if (execute) {
                expect(address).to.be.equal(address2)
                expect(address.toUpperCase()).to.be.equal(nowContractInfo.SeigManager.toUpperCase())
            }
        })

        it("Check maxMember", async () => {
            let maxMember = await daoCommitteeProxy.maxMember()
            let maxMember2 = await daoCommitteeProxy2Contract.maxMember()
            if (execute) {
                expect(maxMember).to.be.equal(maxMember2)
                expect(maxMember).to.be.equal(3)
            }
        })

        it("Check quorum", async () => {
            let quorum = await daoCommitteeProxy.quorum()
            let quorum2 = await daoCommitteeProxy2Contract.quorum()
            if (execute) {
                expect(quorum).to.be.equal(quorum2)
                expect(quorum).to.be.equal(2)
            }
        })
        
        it("Check wton", async () => {
            let wtonAddr= await daoCommitteeProxy2Contract.wton()
            if (execute) {
                expect(wtonAddr.toUpperCase()).to.be.equal((wton.address).toUpperCase())
            }
        })
    })


})
