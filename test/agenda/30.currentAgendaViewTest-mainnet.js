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

const networkName = "mainnet"

const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'
// const daoAdminAddress = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

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

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;

const CandidateABI = require("../../abi/Candidate.json").abi;
const DepositManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const SeigManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const MultiSigwallet_Json = require('../abi/MultiSigWallet.json')


describe("DAO Proxy Change Test", () => {

    let execute = true

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
    let tonAddr = "2be5e8c109e2197D077D13A82dAead6a9b3433C5";
    let wtonAddr = "c4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2";

    let pause_role = "0xfcb9fcbfa83b897fb2d5cf4b58962164105c1e71489a37ef3ae0db3fdce576f6"

    let member1;
    let member2;
    let member3;

    let newMember1;

    let talken;

    let member1Contract;
    let member2Contract;
    let member3Contract;
    let talkenContract;

    let member1ContractLogic;
    let member2ContractLogic;
    let member3ContractLogic;
    let newMember1ContractLogic;
    let talkenContractLogic;

    let newMember1Contract;

    let member1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033"
    let member2Addr = "0xd1820b18be7f6429f1f44104e4e15d16fb199a43"
    let member2AddrUpper = "0xD1820b18bE7f6429F1f44104e4E15d16Fb199a43"
    let member3Addr = "0x42adfaae7db56b294225ddcfebef48b337b34b23"

    let member4Addr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66"

    let newMember1Addr = "0xea8e2ec08dcf4971bdcdfffe21439995378b44f3"
    let newMember1ContractAddr = "0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF"

    let member1ContractAddr = "0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3"
    // let member2ContractAddr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52"
    let member2ContractAddr = "0x0F42D1C40b95DF7A1478639918fc358B4aF5298D"
    // let member3ContractAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764"
    let member3ContractAddr = "0x06D34f65869Ec94B3BA8c0E08BCEb532f65005E2"

    let talkenAddr = "0xcc2f386adca481a00d614d5aa77a30984f264a07"
    let talkenUpperAddr = "0xCC2f386adcA481a00d614d5AA77A30984F264A07"
    let talkenContractAddr = "0x36101b31e74c5E8f9a9cec378407Bbb776287761"

    let stakedAddr = "0x247a0829c63c5b40dc6b21cf412f80227dc7fb76"
    let stakedContractAddr = "0x2c25a6be0e6f9017b5bf77879c487eed466f2194"
    let stakedContract;
    let stakedContractLogic;

    let beforeclaimAmount;
    let afterclaimAmount;

    let wtonCheck = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";

    let sendether = "0xDE0B6B3A7640000"

    let zeroAddr = "0x0000000000000000000000000000000000000000";
    let oneAddr = "0x0000000000000000000000000000000000000001";
    let twoAddr = "0x0000000000000000000000000000000000000002";
    let tosAddr = "0x409c4D8cd5d2924b9bc5509230d16a61289c8153";

    let adminBytes = "0x0000000000000000000000000000000000000000000000000000000000000000"


    // mainnet network
    const oldContractInfo = {
        TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
        WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
        Layer2Registry: "0x0b3E174A2170083e770D5d4Cf56774D221b7063e",
        DepositManager: "0x56E465f654393fa48f007Ed7346105c7195CEe43",
        CoinageFactory: "0x5b40841eeCfB429452AB25216Afc1e1650C07747",
        OldDAOVaultMock: "",
        SeigManager: "0x710936500aC59e8551331871Cbad3D33d5e0D909",
        PowerTON: "0x970298189050aBd4dc4F119ccae14ee145ad9371",
        DAOVault: "0x2520CD65BAa2cEEe9E6Ad6EBD3F45490C42dd303",
        DAOAgendaManager: "0xcD4421d082752f363E1687544a09d5112cD4f484",
        CandidateFactory: "0xE6713aF11aDB0cFD3C60e15b23E43f5548C32942",
        DAOCommittee: "0xd1A3fDDCCD09ceBcFCc7845dDba666B7B8e6D1fb",
        DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26"
    }

    const nowContractInfo = {
        TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
        WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
        Layer2Registry: "0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b",
        DepositManager: "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e",
        CoinageFactory: "",
        SeigManager: "0x0b55a0f463b6defb81c6063973763951712d0e5f",
        CandidateFactory: "0x9fc7100a16407ee24a79c834a56e6eca555a5d7c",
    }

    let SeigManagerUpper = "0x0b55a0f463b6DEFb81c6063973763951712D0E5F"

    let minimumAmount = ethers.utils.parseUnits("1000", 18);

    let daoCommitteeDAOVaultLogic = "0xba5634e0c432af80060cf19e0940b59b2dc31173"

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

    let L1BridgeRegistryV1_1_Addr = "0x259Ac335EB42d345A61bE48104eC0Ec20b283F14"
    let L1BridgeRegistryProxy_Addr = "0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4"
    let OperatorManagerV1_1_Addr = "0xB5F3b31dFB4DCe9a2FA12dE50A97250d60823750"
    let OperatorManagerFactory_Addr = "0xAf86b21edDdC78ea27E23A7F2151d60d4e069450"
    let CandidateAddOnV1_1_Addr = "0x73Bfd5cAEC63307784C7B6d2555F18ec24D96E2e"
    let CandidateAddOnFactory_Addr = "0x557E24b5CbFbDA3e5aC1bD01F38EcDe865791Bc5"
    let CandidateAddOnFactoryProxy_Addr = "0xFA8ce5caF456115E72B96E5074769b8f66AA5861"
    let Layer2ManagerV1_1_Addr = "0x2EB7f500125f11544392B83B87cDEb9456f3509f"
    let Layer2ManagerProxy_Addr = "0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D"
    let SeigManagerV1_2_Addr = "0xb1958719b3Af9B4d85D93EFC5e317C97cCe9aBc4"
    let SeigManagerV1_3_Addr = "0xce18C6F84F10881eA47A43AF7311A29bb116F628"
    let DepositManagerV1_1_Addr = "0x74bC3031b9369e6b898e82784106257D4D37Eac5"
    let DAOCommitteeProxy2_Addr = "0x9e7f54efF4A4D35097e0Acb6994A723F1a28368c"
    let DAOCommitteeOwner_Addr = "0xcb9859Dc0fBECa68eFFf2bce289150513fdF7D92"
    let DAOCommittee_V1_Addr = "0x9050Af1638f379A018737880aD946CdDA9101A25"

    let multiSigWalletContractAddr = "0xE3F72E959834d0A72aFb2ea79F5ec2b4243d2d95"
    let multiSigWalletContract;

    let owner1Addr = "0x77b9D55e98126CD457D8F914647e634613D2A7fc"
    let owner2Addr = "0x9de8cAc67B6514837c31F367aC18a457d8f34c3D"
    let owner3Addr = "0xa4ABB4Bb512Fc1fecF5556ADDa9B8a4C96dc3790"

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
            newMember1Addr,
        ]);
        newMember1 = await hre.ethers.getSigner(newMember1Addr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member2Addr,
        ]);
        member2 = await hre.ethers.getSigner(member2Addr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member3Addr,
        ]);
        member3 = await hre.ethers.getSigner(member3Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            talkenAddr,
        ]);
        talken = await hre.ethers.getSigner(talkenAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            stakedAddr,
        ]);
        staked = await hre.ethers.getSigner(stakedAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            member1ContractAddr,
        ]);
        member1Contract = await hre.ethers.getSigner(member1ContractAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            newMember1ContractAddr,
        ]);
        newMember1Contract = await hre.ethers.getSigner(newMember1ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member2ContractAddr,
        ]);
        member2Contract = await hre.ethers.getSigner(member2ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member3ContractAddr,
        ]);
        member3Contract = await hre.ethers.getSigner(member3ContractAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            talkenContractAddr,
        ]);
        talkenContract = await hre.ethers.getSigner(talkenContractAddr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            stakedContractAddr,
        ]);
        stakedContract = await hre.ethers.getSigner(stakedContractAddr);

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
            newMember1ContractAddr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            member3Addr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            talkenAddr,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            daoCommitteeAdminContract.address,
            sendether
        ]);

        await hre.network.provider.send("hardhat_setBalance", [
            stakedContractAddr,
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

        it("Set newMember1CandidateContract", async () => {
            newMember1ContractLogic = new ethers.Contract(
                newMember1ContractAddr,
                CandidateABI,
                daoCommitteeAdmin
            )
        })

        it("Set StakedCandidateContract", async () => {
            stakedContractLogic = new ethers.Contract(
                stakedContractAddr,
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
            if (execute) {
                let implementation = await daoCommitteeProxy2Contract.proxyImplementation(0)
                expect(implementation).to.be.equal(DAOCommittee_V1_Addr)
            } else {
                await expect(daoCommitteeProxy2Contract.proxyImplementation(0)).to.be.reverted;
            }
        })

        it("Check proxyImplementation(1) = DAOCommitteeOwner", async () => {
            if (execute) {
                let implementation = await daoCommitteeProxy2Contract.proxyImplementation(1)
                expect(implementation).to.be.equal(DAOCommitteeOwner_Addr)
            } else {
                await expect(daoCommitteeProxy2Contract.proxyImplementation(1)).to.be.reverted;
            }
        })

        it("Check CandidateAddOnFactory Addr", async () => {
            if (execute) {
                let address = await daoCommitteeProxy2Contract.candidateAddOnFactory()
                expect(address).to.be.equal(candidateAddOnFactoryProxy.address)
            } else {
                await expect(daoCommitteeProxy2Contract.candidateAddOnFactory()).to.be.reverted;
            }
        })

        it("Check Layer2Manager Addr", async () => {
            if (execute) {
                let address = await daoCommitteeProxy2Contract.layer2Manager()
                expect(address).to.be.equal(layer2ManagerProxy.address)
            } else {
                await expect(daoCommitteeProxy2Contract.layer2Manager()).to.be.reverted;
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
            let checkMember = await daoCommittee_V1_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(newMember1Contract).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, newMember1Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, newMember1Addr);
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

    describe("currentAgendaVeiw Test", () => {
        it("1. Return for an Agenda that has not been created", async () => {
            agendaID = await daoagendaManager.numAgendas()

            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(5)
            expect(result.agendaStatus).to.be.equal(6)
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

        it("increase Time", async () => {
            await time.increase(10);
        });

        it("2. Returns a status called NoticeTime", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(0)
            expect(result.agendaStatus).to.be.equal(1)
        })

        it('increase block time and check votable', async function () {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const noticeEndTimestamp = agenda[AGENDA_INDEX_NOTICE_END_TIMESTAMP];
            // const createTimestamp = agenda[0];
            const noticeEndTimestamp = agenda[1];
            // const votingEndTimestamp = agenda[4];
            // const currentTime = await time.latest();
            // console.log("currentTime", currentTime);
            // console.log("createTimestamp", createTimestamp)
            // console.log("noticeEndTimestamp", noticeEndTimestamp)
            // console.log("votingEndTimestamp", votingEndTimestamp)
            await time.increaseTo(Number(noticeEndTimestamp));
            // const currentTime2 = await time.latest();
            // console.log("currentTime2", currentTime2);
            expect(await daoagendaManager.isVotableStatus(agendaID)).to.be.equal(true);
        });

        it("3. Returns (NO CONSENSUS, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(4)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("castVote member1", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(newMember1Contract).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, newMember1Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, newMember1Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("4. Returns (pending, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(0)
            expect(result.agendaStatus).to.be.equal(2)
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

        it("5. Returns (ACCEPT, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(1)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                const restVotingEndTime = Number(votingEndTimestamp) + Number(10)
                await time.increaseTo(Number(restVotingEndTime));

                expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });

        it("6. Returns (ACCEPT, WAITING_EXEC)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(1)
            expect(result.agendaStatus).to.be.equal(3)
        })


        it("execute agenda (anyone)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            await daoCommittee_V1_Contract.executeAgenda(agendaID);

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        it("7. Returns (ACCEPT, EXECUTED)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(1)
            expect(result.agendaStatus).to.be.equal(4)
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
            // const createTimestamp = agenda[0];
            const noticeEndTimestamp = agenda[1];
            // const votingEndTimestamp = agenda[4];
            // const currentTime = await time.latest();
            // console.log("currentTime", currentTime);
            // console.log("createTimestamp", createTimestamp)
            // console.log("noticeEndTimestamp", noticeEndTimestamp)
            // console.log("votingEndTimestamp", votingEndTimestamp)
            await time.increaseTo(Number(noticeEndTimestamp));
            // const currentTime2 = await time.latest();
            // console.log("currentTime2", currentTime2);
            expect(await daoagendaManager.isVotableStatus(agendaID)).to.be.equal(true);
        });

        it("8. Returns (NO CONSENSUS, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(4)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("castVote member1", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 0
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(newMember1Contract).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, newMember1Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes));
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain+1));

            const result = await daoagendaManager.getVoteStatus(agendaID, newMember1Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("9. Returns (pending, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(0)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("castVote member3", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 0
            
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
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes));
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain)+1);

            const result = await daoagendaManager.getVoteStatus(agendaID, member3Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("10. Returns (DISMISS, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(3)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            const votingEndTimestamp = agenda[4];
            const restVotingEndTime = Number(votingEndTimestamp) + Number(10)
            await time.increaseTo(Number(restVotingEndTime));
        });

        it("11. Returns (DISMISS, ENDED)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(3)
            expect(result.agendaStatus).to.be.equal(5)
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
            await time.increaseTo(Number(noticeEndTimestamp));

            expect(await daoagendaManager.isVotableStatus(agendaID)).to.be.equal(true);
        });

        it("castVote member1", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 2
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(newMember1Contract).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, newMember1Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes));
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo+1));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, newMember1Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("castVote member3", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 2
            
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
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes));
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo)+1);
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, member3Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("12. Returns (REJECT, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(2)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            const votingEndTimestamp = agenda[4];
            const restVotingEndTime = Number(votingEndTimestamp) + Number(10)
            await time.increaseTo(Number(restVotingEndTime));
        });

        it("13. Returns (REJECT, ENDED)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(2)
            expect(result.agendaStatus).to.be.equal(5)
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
            let checkMember = await daoCommittee_V1_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(newMember1Contract).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, newMember1Addr);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, newMember1Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("castVote member3", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 2
            
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
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes));
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo)+1);
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, member3Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("14. Returns (PENDING, VOTING)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(0)
            expect(result.agendaStatus).to.be.equal(2)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            const votingEndTimestamp = agenda[4];
            const restVotingEndTime = Number(votingEndTimestamp) + Number(10)
            await time.increaseTo(Number(restVotingEndTime));
        });

        it("15. Returns (NO CONSENSUS, ENDED)", async () => {
            let result = await daoCommittee_V1_Contract.currentAgendaStatus(agendaID)
            expect(result.agendaResult).to.be.equal(4)
            expect(result.agendaStatus).to.be.equal(5)
        })

    })


})
