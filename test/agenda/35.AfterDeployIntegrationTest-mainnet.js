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
const DAOCommittee_V2ABI = require("../../artifacts/contracts/dao/DAOCommittee_V2.sol/DAOCommittee_V2.json").abi;
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


describe("Pre-Deploy IntegrationTest on Mainnet", () => {

    let candidateAddOnFactoryAddr = ""
    let daoCommittee_V2Addr = ""

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
    let daoCommittee_V2_Contract;
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

    let l1Messenger_Addr = "0xfd76ef26315Ea36136dC40Aeafb5D276d37944AE"
    let l1Bridge_Addr = "0x59aa194798Ba87D26Ba6bEF80B85ec465F4bbcfD"
    let l2Ton_Addr = "0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2"

    let multiSigWalletContractAddr = "0xE3F72E959834d0A72aFb2ea79F5ec2b4243d2d95"
    let multiSigWalletContract;

    let owner1Addr = "0x77b9D55e98126CD457D8F914647e634613D2A7fc"
    let owner2Addr = "0x9de8cAc67B6514837c31F367aC18a457d8f34c3D"
    let owner3Addr = "0xa4ABB4Bb512Fc1fecF5556ADDa9B8a4C96dc3790"

    let owner1
    let owner2
    let owner3

    let titanLayerContract
    let titanOperatorContract

    let titanOperator

    let operatorManagerFactory

    let richTONAddr = "0x89E883c4FF815CFDE8D619856caa50EDf3bEE516"
    let richTON;

    let cooldownTime = 259200

    let memo

    let newDAOCommittee_V2Contract


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


        it("set CandidateAddOnFactoryProxy", async () => {
            candidateAddOnFactoryProxy = await ethers.getContractAt(
                "CandidateAddOnFactoryProxy", 
                CandidateAddOnFactoryProxy_Addr, 
                daoCommitteeAdmin
            )
        })

        it("Set candidateAddOnFactory", async () => {
            candidateAddOnFactory = new ethers.Contract(
                candidateAddOnFactoryProxy.address,
                CandidateFactory_ABI,
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

    describe("Agenda Pass", () => {
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
        

        it("Ensure the agenda is properly executed proxyImplementation(0) = DAOCommittee_V2", async () => {
            let implementation = await daoCommitteeProxy2Contract.proxyImplementation(0)
            expect(implementation).to.be.equal(daoCommittee_V2Addr)
        })

        it("set DAO NewLogic2", async () => {
            daoCommittee_V2_Contract = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommittee_V2ABI,
                daoCommitteeAdmin
            )
        })
    })

    describe("Check the executed agenda", () => {
        it("Check implementation", async () => {
            let implementation = await daoCommitteeProxy.implementation()
            expect(implementation).to.be.equal(DAOCommitteeProxy2_Addr)
        })

        it("Check proxyImplementation(0) = DAOCommittee_V2", async () => {
            let implementation = await daoCommitteeProxy2Contract.proxyImplementation(0)
            expect(implementation).to.be.equal(daoCommittee_V2Addr)
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
            expect(address).to.be.equal(address2)
            expect(address).to.be.equal(ton.address)
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

        it("Check privateLayer2", async () => {
            let privateLayer2Check = await daoCommitteeProxy2Contract.privateLayer2(user1.address);
            expect(privateLayer2Check).to.be.equal(false)
        })
    })

    describe("currentAgendaVeiw Test", () => {
        it("1. Return for an Agenda that has not been created", async () => {
            agendaID = await daoagendaManager.numAgendas()

            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(5)
            expect(result.currentStatus).to.be.equal(6)
        })

        it("Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 40;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            memo = "https://snapshot.box/#/explore"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode],
                    memo
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

        it("check the agenda Memo", async () => {
            let daoMemo = await daoCommittee_V2_Contract.agendaMemo(agendaID)
            // console.log(daoMemo)
            // console.log(memo)
            expect(daoMemo).to.be.equal(memo)
        })

        it("2. Returns a status called NoticeTime", async () => {
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(0)
            expect(result.currentStatus).to.be.equal(1)
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(4)
            expect(result.currentStatus).to.be.equal(2)
        })

        it("castVote member1", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V2_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(newMember1Contract).castVote(
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(0)
            expect(result.currentStatus).to.be.equal(2)
        })

        it("castVote member3", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V2_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(member3Contract).castVote(
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(1)
            expect(result.currentStatus).to.be.equal(2)
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(1)
            expect(result.currentStatus).to.be.equal(3)
        })


        it("execute agenda (anyone)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            await daoCommittee_V2_Contract.executeAgenda(agendaID);

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        it("7. Returns (ACCEPT, EXECUTED)", async () => {
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(1)
            expect(result.currentStatus).to.be.equal(4)
        })

        it("Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 40;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            memo = "https://snapshot.box/#/explore1"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode],
                    memo
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

        it("check the agenda Memo", async () => {
            let daoMemo = await daoCommittee_V2_Contract.agendaMemo(agendaID)
            // console.log(daoMemo)
            // console.log(memo)
            expect(daoMemo).to.be.equal(memo)
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(4)
            expect(result.currentStatus).to.be.equal(2)
        })

        it("castVote member1", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 0
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V2_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(newMember1Contract).castVote(
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(0)
            expect(result.currentStatus).to.be.equal(2)
        })

        it("castVote member3", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 0
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V2_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(member3Contract).castVote(
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(3)
            expect(result.currentStatus).to.be.equal(2)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            const votingEndTimestamp = agenda[4];
            const restVotingEndTime = Number(votingEndTimestamp) + Number(10)
            await time.increaseTo(Number(restVotingEndTime));
        });

        it("11. Returns (DISMISS, ENDED)", async () => {
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(3)
            expect(result.currentStatus).to.be.equal(5)
        })

        it("Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 40;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            memo = "https://snapshot.box/#/explore2"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode],
                    memo
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

        it("check the agenda Memo", async () => {
            let daoMemo = await daoCommittee_V2_Contract.agendaMemo(agendaID)
            // console.log(daoMemo)
            // console.log(memo)
            expect(daoMemo).to.be.equal(memo)
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
            let checkMember = await daoCommittee_V2_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(newMember1Contract).castVote(
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
            let checkMember = await daoCommittee_V2_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(member3Contract).castVote(
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(2)
            expect(result.currentStatus).to.be.equal(2)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            const votingEndTimestamp = agenda[4];
            const restVotingEndTime = Number(votingEndTimestamp) + Number(10)
            await time.increaseTo(Number(restVotingEndTime));
        });

        it("13. Returns (REJECT, ENDED)", async () => {
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(2)
            expect(result.currentStatus).to.be.equal(5)
        })


        it("Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 40;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            memo = "https://snapshot.box/#/explore3"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode],
                    memo
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

        it("check the agenda Memo", async () => {
            let daoMemo = await daoCommittee_V2_Contract.agendaMemo(agendaID)
            // console.log(daoMemo)
            // console.log(memo)
            expect(daoMemo).to.be.equal(memo)
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
            let checkMember = await daoCommittee_V2_Contract.isMember(newMember1Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(newMember1Contract).castVote(
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
            let checkMember = await daoCommittee_V2_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(member3Contract).castVote(
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
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(0)
            expect(result.currentStatus).to.be.equal(2)
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            const votingEndTimestamp = agenda[4];
            const restVotingEndTime = Number(votingEndTimestamp) + Number(10)
            await time.increaseTo(Number(restVotingEndTime));
        });

        it("15. Returns (NO CONSENSUS, ENDED)", async () => {
            let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
            expect(result.currentResult).to.be.equal(4)
            expect(result.currentStatus).to.be.equal(5)
        })

    })

    describe("DAOCommittee_V2 Logic test", () => {
        it("1. createCandidate (anyone)", async () => {
            let beforeCandidateLength = await daoCommittee_V2_Contract.candidatesLength()
            let candidateInfo1 = await daoCommittee_V2_Contract.candidates(beforeCandidateLength-1)
            // console.log(candidateInfo1)

            let checkalreadyMake = await daoCommittee_V2_Contract.candidateContract(user1.address)

            if(checkalreadyMake == zeroAddr) {
                await daoCommittee_V2_Contract.connect(user1).createCandidate(
                    "TestCandidate"
                );
    
                let afterCandidateLength = await daoCommittee_V2_Contract.candidatesLength()
                expect(afterCandidateLength).to.be.gt(beforeCandidateLength)
    
                let candidateInfo2 = await daoCommittee_V2_Contract.candidates(afterCandidateLength-1)
                // console.log(candidateInfo2)
    
                let candidateInfo = await daoCommittee_V2_Contract.candidateInfos(user1Addr)
                // console.log("candidateInfo : ", candidateInfo);
                expect(candidateInfo.memberJoinedTime).to.be.equal(0)
            } else {
                console.log("already createCandidate");
            }

        })

        it("2. set user1CandidateContract", async () => {
            let candidateInfo = await daoCommittee_V2_Contract.candidateInfos(user1Addr)
            user1ContractAddr = candidateInfo.candidateContract;
            // console.log("user1ContractAddr: ", user1ContractAddr)

            // await hre.network.provider.send("hardhat_impersonateAccount", [
            //     user1ContractAddr,
            // ]);
            // user1Contract = await hre.ethers.getSigner(user1ContractAddr);

            // await hre.network.provider.send("hardhat_setBalance", [
            //     user1Contract,
            //     sendether
            // ]);

            user1ContractLogic = new ethers.Contract(
                user1ContractAddr,
                CandidateABI,
                daoCommitteeAdmin
            )
        })

        it("3. retireMember (get TON) (add blackList) (onlyMember)", async () => {
            let memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck).to.be.equal(member2AddrUpper)
            // let beforeWTONAmount = await wton.balanceOf(member2.address)
            let blacklistCheck = await daoCommittee_V2_Contract.blacklist(member2ContractLogic.address)
            expect(blacklistCheck).to.be.equal(false)

            await (
                await member2ContractLogic.connect(member2).retireMember()
            ).wait();

            memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)
            // let afterWTONAmount = await wton.balanceOf(member2.address)
            // expect(afterWTONAmount).to.be.gt(beforeWTONAmount)
            blacklistCheck = await daoCommittee_V2_Contract.blacklist(member2ContractLogic.address)
            expect(blacklistCheck).to.be.equal(true)
        })

        it("4. blacklist can't changeMember", async () => {
            await expect(
                member2ContractLogic.connect(member2).changeMember(
                    1
                )
            ).to.be.revertedWith("DAOCommittee: blacklisted member");
        })

        it("5. blacklist can't claimActivityReward", async () => {
            await expect(
                member2ContractLogic.connect(member2).claimActivityReward()
            ).to.be.revertedWith("DAOCommittee: blacklisted member");
        })

        it("6. changeMemeber (anyone)", async () => {
            let memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)

            await (
                await stakedContractLogic.connect(staked).changeMember(1)
            ).wait();

            memberCheck = await daoCommittee_V2_Contract.members(1)
            // console.log(memberCheck.toUpperCase())
            // console.log(stakedAddr.toUpperCase())
            expect(memberCheck.toUpperCase()).to.be.equal(stakedAddr.toUpperCase())
        })

        it("7. setMemoOnCandidate (anyone)", async () => {
            let beforeMemo = await user1ContractLogic.memo();

            await daoCommittee_V2_Contract.connect(user1).setMemoOnCandidate(
                user1Addr,
                "Change"
            )

            let afterMemo = await user1ContractLogic.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
        })

        it("8. setMemoOnCandidateContract (anyone)", async () => {
            let beforeMemo = await user1ContractLogic.memo();

            await daoCommittee_V2_Contract.connect(user1).setMemoOnCandidateContract(
                user1ContractAddr,
                "Change2"
            )

            let afterMemo = await user1ContractLogic.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
        })

        it("9. OnApprove reverted Test (claimTON)", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimTON(address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            const claimAmount = 100000000000000000000

            const data1 = padLeft(testAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(claimAmount.toString(16), 64);
            // console.log("data2 : ", data2)
            const data3 = data1 + data2
            // console.log("data3 : ", data3);

            const functionBytecode1 = selector1.concat(data3)
            // console.log("functionBytecode1 :", functionBytecode1);
            // console.log("functionBytecode1.length :", functionBytecode1.length);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)

            let memo = "test"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    targets, 
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    false,
                    functionBytecodes,
                    memo
                ]
            )

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            // let agendaID = (await daoagendaManager.numAgendas()).sub(1);

            await expect(
                ton.connect(daoCommitteeAdmin).approveAndCall(
                    daoCommitteeProxy.address,
                    agendaFee,
                    param
            )).to.be.reverted;

        })

        it("10. OnApprove reverted Test (claimERC20) (TON)", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimERC20(address,address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            const claimAmount = 100000000000000000000

            const data1 = padLeft(tonAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(testAddr.toString(), 64);
            // console.log("data2 : ", data2)
            const data3 = padLeft(claimAmount.toString(16), 64);
            // console.log("data3 : ", data3);
            const data4 = data1 + data2 + data3
            // console.log("data4 : ", data4);

            const functionBytecode1 = selector1.concat(data4)
            // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)
            // console.log("functionBytecode1.length :", functionBytecode1.length);

            let memo = "test"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    targets, 
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    false,
                    functionBytecodes,
                    memo
                ]
            )

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            agendaID = (await daoagendaManager.numAgendas()).sub(1);

            await expect(
                ton.connect(daoCommitteeAdmin).approveAndCall(
                    daoCommitteeProxy.address,
                    agendaFee,
                    param
            )).to.be.reverted;
        })

        it("11. OnApprove pass Test (claimERC20) (WTON)", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();

            const agendaFee = await daoagendaManager.createAgendaFees();

            let targets = [];
            let functionBytecodes = [];

            const selector1 = Web3EthAbi.encodeFunctionSignature("claimERC20(address,address,uint256)");
            // console.log("selector1 : ", selector1);
            // console.log("selector1.length : ", selector1.length);
            const claimAmount = 100000000000000000000

            const data1 = padLeft(wtonAddr.toString(), 64);
            // console.log("data1 : ", data1);
            const data2 = padLeft(testAddr.toString(), 64);
            // console.log("data2 : ", data2)
            const data3 = padLeft(claimAmount.toString(16), 64);
            // console.log("data3 : ", data3);
            const data4 = data1 + data2 + data3
            // console.log("data4 : ", data4);

            const functionBytecode1 = selector1.concat(data4)
            // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(oldContractInfo.DAOVault);
            functionBytecodes.push(functionBytecode1)
            // console.log("functionBytecode1.length :", functionBytecode1.length);

            let memo = "test"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    targets, 
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    functionBytecodes,
                    memo
                ]
            )

            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            if (agendaFee.gt(beforeBalance))
                    await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            // let agendaID = (await daoagendaManager.numAgendas()).sub(1);

            await ton.connect(daoCommitteeAdmin).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            );
        })

        it("check", async () => {
            beforeAgendaID = await daoagendaManager.numAgendas();
        })

        it("12. Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            const newMinimumNoticePeriod = 30;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            let memo = "test"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode],
                    memo
                ]
            );
    
            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            const agendaFee = await daoagendaManager.createAgendaFees();
            expect(agendaFee).to.be.gt(0);

            if (agendaFee.gt(beforeBalance))
                await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            const beforeBalance2 = await ton.balanceOf(daoCommitteeAdmin.address);

            // create agenda
            await ton.connect(daoCommitteeAdmin).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            );

            const afterBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            expect(afterBalance).to.be.lt(beforeBalance2);
            expect(beforeBalance2.sub(afterBalance)).to.be.equal(agendaFee)

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

        
        it("13. blacklist can't castVote", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            const vote = 1
            await expect(
                daoCommittee_V2_Contract.connect(member2).castVote(
                    agendaID,
                    vote,
                    "member2 vote"
                )
            ).to.be.reverted;
        })


        it("14. cast vote (staked)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V2_Contract.isMember(stakedAddr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(stakedContract).castVote(
                agendaID,
                vote,
                "member2 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, stakedAddr);
            // expect(voterInfo2[VOTER_INFO_ISVOTER]).to.be.equal(true);
            expect(voterInfo2[0]).to.be.equal(true);
            // expect(voterInfo2[VOTER_INFO_HAS_VOTED]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            // expect(voterInfo2[VOTER_INFO_VOTE]).to.be.equal(_vote);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, stakedAddr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("15. cannnot cast vote (user1)", async () => {
            const vote = 2
            await expect(daoCommittee_V2_Contract.connect(user1).castVote(
                agendaID,
                vote,
                "user1 vote"
            )).to.be.reverted;
        })

        it("16. cast vote (member3)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V2_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(member3Contract).castVote(
                agendaID,
                vote,
                "member3 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, member3Addr);
            // expect(voterInfo2[VOTER_INFO_ISVOTER]).to.be.equal(true);
            expect(voterInfo2[0]).to.be.equal(true);
            // expect(voterInfo2[VOTER_INFO_HAS_VOTED]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            // expect(voterInfo2[VOTER_INFO_VOTE]).to.be.equal(_vote);
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
            // console.log("agenda Result :", agenda[10])
            // console.log("agenda status :", agenda[11])

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                const currentTime = await time.latest();
                if (currentTime < votingEndTimestamp) {
                    await time.increaseTo(Number(votingEndTimestamp));
                }
                expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });


        it("17. execute agenda (anyone)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            const beforeValue = await daoagendaManager.minimumNoticePeriodSeconds();
            // console.log("agendaID : ", agendaID)
            // console.log("beforeAgendaID : ", beforeAgendaID)
            // console.log("beforeValue :", beforeValue)
            
            // let diffAgenda = agendaID - beforeAgendaID

            // const check = await daoagendaManager.canExecuteAgenda(agendaID);
            // console.log(check)
            // const check2 = await daoagendaManager.getExecutionInfo(agendaID);
            // console.log(check2)
            
            await daoCommittee_V2_Contract.executeAgenda(agendaID);
            const afterValue = await daoagendaManager.minimumNoticePeriodSeconds();

            // expect(beforeValue).to.be.not.equal(afterValue);
            expect(afterValue).to.be.equal(30);

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        it("18. Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            const newMinimumNoticePeriod = 40;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            let memo = "test"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode],
                    memo
                ]
            );
    
            const beforeBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            const agendaFee = await daoagendaManager.createAgendaFees();
            expect(agendaFee).to.be.gt(0);

            if (agendaFee.gt(beforeBalance))
                await (await ton.connect(daoCommitteeAdmin).mint(daoCommitteeAdmin.address, agendaFee)).wait();

            const beforeBalance2 = await ton.balanceOf(daoCommitteeAdmin.address);

            // create agenda
            await ton.connect(daoCommitteeAdmin).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            );

            const afterBalance = await ton.balanceOf(daoCommitteeAdmin.address);
            expect(afterBalance).to.be.lt(beforeBalance2);
            expect(beforeBalance2.sub(afterBalance)).to.be.equal(agendaFee)

            agendaID = (await daoagendaManager.numAgendas()).sub(1);
            //const executionInfo = await agendaManager.executionInfos(agendaID);
            const executionInfo = await daoagendaManager.getExecutionInfo(agendaID);
            // console.log("executionInfo :", executionInfo);
            expect(executionInfo[0][0]).to.be.equal(daoagendaManager.address);
            expect(executionInfo[1][0]).to.be.equal(functionBytecode);
        })

        it("19. updateSeigniorage test (anyone)", async () => {
            const beforeSeigBlock = await seigManagerContract.lastCommitBlock(member2ContractAddr)

            await daoCommittee_V2_Contract.connect(user1).updateSeigniorage(member2Addr)

            const afterSeigBlock = await seigManagerContract.lastCommitBlock(member2ContractAddr)

            expect(afterSeigBlock).to.be.gt(beforeSeigBlock)
        })

        it("20. getClaimableActivityReward & claimActivityReward test (anyone)", async () => {
            let amount = await daoCommittee_V2_Contract.getClaimableActivityReward(stakedAddr)
            expect(amount).to.be.gt(0);

            await (
                await stakedContractLogic.connect(staked).claimActivityReward()
            ).wait()
            
            let amount2 = await daoCommittee_V2_Contract.getClaimableActivityReward(stakedAddr)
            expect(amount).to.be.gt(amount2);
        })

        it("21. isCandidate (view)", async () => {
            let checkisCandidate = await daoCommittee_V2_Contract.isCandidate(member2Addr)
            expect(checkisCandidate).to.be.equal(true)
        })

        it("22. totalSupplyOnCandidate (view)", async () => {
            let amount = await daoCommittee_V2_Contract.totalSupplyOnCandidate(member2Addr)
            expect(amount).to.be.gt(0)
        })

        it("23. balanceOfOnCandidate (view)", async () => {
            let amount = await daoCommittee_V2_Contract.balanceOfOnCandidate(
                member2Addr,
                member2Addr
            )
            expect(amount).to.be.gt(0)
        })

        it("24. totalSupplyOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V2_Contract.totalSupplyOnCandidateContract(
                member2ContractAddr
            )
            expect(amount).to.be.gt(0)
        })

        it("25. balanceOfOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V2_Contract.balanceOfOnCandidateContract(
                member2ContractAddr,
                member2Addr
            )
            expect(amount).to.be.gt(0)
        })

        it("26. candidatesLength (view)", async () => {
            let length = await daoCommittee_V2_Contract.candidatesLength()
            expect(length).to.be.gt(0)
        })

        it("27. isExistCandidate (view)", async () => {
            let check = await daoCommittee_V2_Contract.isExistCandidate(member2Addr)
            expect(check).to.be.equal(true)
        })

        it("28. getOldCandidateInfos (view)", async () => {
            let oldinfo = await daoCommittee_V2_Contract.getOldCandidateInfos(member2Addr)
            // console.log(oldinfo);
            expect(oldinfo.rewardPeriod).to.be.equal(0)
        })

        it("29. operatorAmountCheck (view)", async () => {
            let amount = await daoCommittee_V2_Contract.operatorAmountCheck(
                member2ContractAddr,
                member2Addr
            )
            expect(amount).to.be.gt(0)
        })
    })

    describe("MultiSigWallet Test", () => {
        it("send TON & ETH into MultiSigWallet Contract", async () => {
            await ton.connect(richTON).transfer(
                multiSigWalletContract.address,
                ethers.utils.parseEther("1000")
            )

            await richTON.sendTransaction({
                to: multiSigWalletContract.address,
                value: ethers.utils.parseEther("0.5")
            })
        })

        it("MultiSigWallet execute the Send ETH", async () => {
            const recipient = user1.address;
            const ethAmount = ethers.utils.parseEther("0.5");
            
            await multiSigWalletContract.connect(owner1).submitTransaction(
                recipient,
                ethAmount,
                "0x"
            );

            // await MultiSigWalletContract.connect(owner1).confirmTransaction(0)
            await multiSigWalletContract.connect(owner2).confirmTransaction(1)
            const beforeBalance = Number(await ethers.provider.getBalance(recipient)); 

            await multiSigWalletContract.connect(owner3).executeTransaction(1)
            // const afterBalance = await ethers.provider.getBalance(recipient);

            expect(Number(await ethers.provider.getBalance(recipient))).to.be.gt(beforeBalance)
        })

        it("MultiSigWallet execute the Send ERC20 transfer", async () => {
            const tokenAmount = ethers.utils.parseEther("100");
            const dataTransfer = ton.interface.encodeFunctionData(
              "transfer",
              [user1.address, tokenAmount]
            )
      
            await multiSigWalletContract.connect(owner1).submitTransaction(
              ton.address,
              0,
              dataTransfer
            );
      
            await multiSigWalletContract.connect(owner2).confirmTransaction(2)
            // await MultiSigWalletContract.connect(owner3).confirmTransaction(1)
      
            await multiSigWalletContract.connect(owner3).executeTransaction(2)
      
            expect(await ton.balanceOf(user1.address)).to.be.equal(tokenAmount)
        })

        it("ConfirmTransaction cannot be executed for a Transaction that has already been executeTransactioned.", async () => {
            await expect(
                multiSigWalletContract.connect(owner3).confirmTransaction(
                    1
                )
            ).to.be.revertedWith("tx already executed");
        })
    
        it("executeTransaction cannot be executed for a Transaction that has already been executeTransactioned.", async () => {
            await expect(
                multiSigWalletContract.connect(owner3).executeTransaction(
                    1
                )
            ).to.be.revertedWith("tx already executed");
        })
        
        it("can't changeOwner by Owner", async () => {
            await expect(
                multiSigWalletContract.connect(owner1).changeOwner(
                    0,
                    user1.address
                )
            ).to.be.revertedWith("Only MultiSigContract can execute");
        })

        it("MultiSigWallet execute the DAOCommitteeOwner(setCooldown)", async () => {
            let beforeCooldown = await daoCommittee_Owner_Contract.cooldownTime()
            expect(beforeCooldown).to.be.equal(cooldownTime)
      
            const dataSetCooldown = daoCommittee_Owner_Contract.interface.encodeFunctionData(
              "setCooldownTime",
              [100]
            )
      
            await multiSigWalletContract.connect(owner2).submitTransaction(
              daoCommittee_Owner_Contract.address,
              0,
              dataSetCooldown
            );
      
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(owner3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(owner3).executeTransaction(count-1)
      
            let afterCooldown = await daoCommittee_Owner_Contract.cooldownTime()
            expect(afterCooldown).to.be.equal(100)
        })

        it("MultiSigWallet execute the DAOCommmitee_V1(removeFromBlacklist)", async () => {
            let beforeBlackList = await daoCommittee_V2_Contract.blacklist(member2ContractAddr)
            expect(beforeBlackList).to.be.equal(true)

            const dataRemoveBlackList = daoCommittee_V2_Contract.interface.encodeFunctionData(
                "removeFromBlacklist",
                [member2ContractAddr]
            )

            await multiSigWalletContract.connect(owner2).submitTransaction(
                daoCommittee_V2_Contract.address,
                0,
                dataRemoveBlackList
            );
      
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(owner3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(owner3).executeTransaction(count-1)

            let afterBlackList = await daoCommittee_V2_Contract.blacklist(member2ContractAddr)
            expect(afterBlackList).to.be.equal(false)
        })

        it("Now Member & Total Supply Check", async () => {
            // console.log("newmember1 :", newMember1Addr) //index0
            // console.log("staked :", stakedAddr)         //index1
            // console.log("member3 :", member3Addr)       //index2
            let index1TotalSupply = await daoCommittee_V2_Contract.totalSupplyOnCandidate(stakedAddr)
            let index2TotalSupply = await daoCommittee_V2_Contract.totalSupplyOnCandidate(member3Addr)
            let TotalSupply = await daoCommittee_V2_Contract.totalSupplyOnCandidate(member2Addr)

            // console.log("index0TotalSupply :", index0TotalSupply)
            // console.log("index1TotalSupply :", index1TotalSupply)
            // console.log("index2TotalSupply :", index2TotalSupply)
            expect(TotalSupply).to.be.gt(index1TotalSupply)
            expect(TotalSupply).to.be.gt(index2TotalSupply)
        })

        it("changeMember cooldown Test", async () => {
            let beforeAddr = await daoCommittee_V2_Contract.members(1)
            expect(beforeAddr.toUpperCase()).to.be.equal(stakedAddr.toUpperCase())

            await (
                await member2ContractLogic.connect(member2).changeMember(1)
            ).wait();

            let afterAddr = await daoCommittee_V2_Contract.members(1)
            expect(afterAddr.toUpperCase()).to.be.equal(member2Addr.toUpperCase())

            await expect(
                member2ContractLogic.connect(member2).changeMember(
                    2
                )
            ).to.be.revertedWith("DAOCommittee: need cooldown");
        })


        it("MultiSigWallet execute the agendaManager(setCreateAgendaFees)", async () => {
            let beforeAgendaFee = await daoagendaManager.createAgendaFees()

            const dataSetDao = daoagendaManager.interface.encodeFunctionData(
                "setCreateAgendaFees",
                [10]
              )

            const dataExecuteTransaction = daoCommittee_Owner_Contract.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoagendaManager.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(owner2).submitTransaction(
                daoCommittee_Owner_Contract.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(owner3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(owner3).executeTransaction(count-1)


            let afterAgendaFee = await daoagendaManager.createAgendaFees()
            expect(afterAgendaFee).to.be.equal(10)
            expect(afterAgendaFee).not.to.be.equal(beforeAgendaFee)
        })

        it("MultiSigWallet execute the agendaManager(setMinimumNoticePeriodSeconds)", async () => {
            let beforeNotice = await daoagendaManager.minimumNoticePeriodSeconds()

            const dataSetDao = daoagendaManager.interface.encodeFunctionData(
                "setMinimumNoticePeriodSeconds",
                [10]
              )

            const dataExecuteTransaction = daoCommittee_Owner_Contract.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoagendaManager.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(owner2).submitTransaction(
                daoCommittee_Owner_Contract.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(owner3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(owner3).executeTransaction(count-1)


            let afterNotice = await daoagendaManager.createAgendaFees()
            expect(afterNotice).to.be.equal(10)
            expect(afterNotice).not.to.be.equal(beforeNotice)
        })

        it("MultiSigWallet execute the agendaManager(setMinimumVotingPeriodSeconds)", async () => {
            let beforeVoting = await daoagendaManager.minimumVotingPeriodSeconds()

            const dataSetDao = daoagendaManager.interface.encodeFunctionData(
                "setMinimumVotingPeriodSeconds",
                [10]
              )

            const dataExecuteTransaction = daoCommittee_Owner_Contract.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoagendaManager.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(owner2).submitTransaction(
                daoCommittee_Owner_Contract.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(owner3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(owner3).executeTransaction(count-1)


            let afterVoting = await daoagendaManager.minimumVotingPeriodSeconds()
            expect(afterVoting).to.be.equal(10)
            expect(afterVoting).not.to.be.equal(beforeVoting)
        })

        it("MultiSigWallet execute the agendaManager(setExecutingPeriodSeconds)", async () => {
            let beforeExecuting = await daoagendaManager.executingPeriodSeconds()

            const dataSetDao = daoagendaManager.interface.encodeFunctionData(
                "setExecutingPeriodSeconds",
                [10]
              )

            const dataExecuteTransaction = daoCommittee_Owner_Contract.interface.encodeFunctionData(
                "daoExecuteTransaction",
                [daoagendaManager.address, dataSetDao]
            )
    
            await multiSigWalletContract.connect(owner2).submitTransaction(
                daoCommittee_Owner_Contract.address,
                0,
                dataExecuteTransaction
            );
    
            let count = Number(await multiSigWalletContract.getTransactionCount())
            await multiSigWalletContract.connect(owner3).confirmTransaction(count-1)
            await multiSigWalletContract.connect(owner3).executeTransaction(count-1)


            let afterExecuting = await daoagendaManager.executingPeriodSeconds()
            expect(afterExecuting).to.be.equal(10)
            expect(afterExecuting).not.to.be.equal(beforeExecuting)
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

        it('set Titan LegacySystemConfig ', async () => {
            legacySystemConfig = (await (await ethers.getContractFactory("LegacySystemConfig")).connect(daoCommitteeAdmin).deploy())

            let name = 'Titan'
            let addresses = {
                l1CrossDomainMessenger: l1Messenger_Addr,
                l1ERC721Bridge: ethers.constants.AddressZero,
                l1StandardBridge: l1Bridge_Addr,
                l2OutputOracle: ethers.constants.AddressZero,
                optimismPortal: ethers.constants.AddressZero,
                optimismMintableERC20Factory: ethers.constants.AddressZero
            }

            await (await legacySystemConfig.connect(daoCommitteeAdmin).setAddresses(
                name, addresses, l1BridgeRegistryProxy.address, daoCommitteeAdmin.address
            )).wait()
        })

        it('registerSystemConfigByManager  ', async () => {
            let type = 1;
            let name = 'Titan'

            // console.log("1")
            // console.log(daoCommitteeAdminContract.address)
            // let check = await l1BridgeRegistryProxy.isManager(daoCommitteeAdminContract.address)
            // console.log(check)
            let receipt = await (await l1BridgeRegistryV_1.connect(daoCommitteeAdminContract)["registerRollupConfigByManager(address,uint8,address,string)"](
                legacySystemConfig.address,
                type,
                l2Ton_Addr,
                name
            )).wait()
            // console.log("2")

            const topic = l1BridgeRegistryV_1.interface.getEventTopic('RegisteredRollupConfig');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = l1BridgeRegistryV_1.interface.parseLog(log);

            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.type_).to.be.eq(type)
        })

        it("registerCandidateAddOn", async () => {
            expect((await layer2ManagerV1_1.statusLayer2(legacySystemConfig.address))).to.be.eq(0)

            let amount = await layer2ManagerV1_1.minimumInitialDepositAmount();
            let amount2 = ethers.utils.parseEther("2000")
            await (await ton.connect(daoCommitteeAdmin).transfer(
                user1.address,
                amount2
            )).wait()
            let balance = await ton.balanceOf(user1.address)
            expect(balance).to.be.gt(amount)

            let allowance = await ton.allowance(user1.address, layer2ManagerV1_1.address)
            if(allowance.lt(amount)){
                await ton.connect(user1).approve(layer2ManagerV1_1.address, amount);
            }

            const name = await legacySystemConfig.name()
            const operatorAddress = await operatorManagerFactory.getAddress(legacySystemConfig.address)

            const receipt = await (await layer2ManagerV1_1.connect(user1).registerCandidateAddOn(
                legacySystemConfig.address,
                amount,
                true,
                name
            )).wait()

            const topic = layer2ManagerV1_1.interface.getEventTopic('RegisteredCandidateAddOn');
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = layer2ManagerV1_1.interface.parseLog(log);
            
            const topic2 = daoCommittee_V2_Contract.interface.getEventTopic('CandidateContractCreated');
            const log2 = receipt.logs.find(x => x.topics.indexOf(topic2) >= 0);
            const deployedEvent2 = daoCommittee_V2_Contract.interface.parseLog(log2);

            expect(deployedEvent.args.rollupConfig).to.be.eq(legacySystemConfig.address)
            expect(deployedEvent.args.wtonAmount).to.be.eq(amount.mul(BigNumber.from("1000000000")))
            expect(deployedEvent.args.memo).to.be.eq(name)
            expect(deployedEvent.args.operator).to.be.eq(operatorAddress)
            expect(deployedEvent.args.candidateAddOn).to.be.not.eq(ethers.constants.AddressZero)

            titanLayerAddress = deployedEvent.args.candidateAddOn;
            titanOperatorContractAddress = deployedEvent.args.operator;
            expect((await layer2ManagerV1_1.statusLayer2(legacySystemConfig.address))).to.be.eq(1)
            // console.log(deployedEvent2)
            // console.log(addr1.address)
            // console.log(titanLayerAddress)
            // console.log(titanOperatorContractAddress)

            titanLayerContract =  (await ethers.getContractAt(
                "CandidateAddOnV1_1", 
                titanLayerAddress, 
                daoCommitteeAdmin
            )) 

            titanOperatorContract = (await ethers.getContractAt(
                "OperatorManagerV1_1", 
                titanOperatorContractAddress, 
                daoCommitteeAdmin
            ))

            await hre.network.provider.send("hardhat_impersonateAccount", [
                titanOperatorContractAddress,
            ]);
            titanOperator = await hre.ethers.getSigner(titanOperatorContractAddress);

            await hre.network.provider.send("hardhat_setBalance", [
                titanOperatorContractAddress,
                sendether
            ]);
        })

        it("privateLayer2 Check", async () => {
            let privateLayer2Check = await daoCommittee_V2_Contract.privateLayer2(titanOperatorContract.address);
            // console.log("privateLayer2Check :", privateLayer2Check)
            expect(privateLayer2Check).to.be.equal(false)
        })

        it("CandidateAddOn operatorAmountCheck", async () => {
            let operatorAmountCheck = await daoCommittee_V2_Contract.operatorAmountCheck(titanLayerContract.address, titanOperatorContract.address);
            // console.log("operatorAmountCheck :", operatorAmountCheck)
            expect(operatorAmountCheck).to.be.gt(0)
        })

        it("CandidateAddOn operatorCheck", async () => {
            let operatorAmount = await daoCommittee_V2_Contract.operatorCheck(titanOperatorContract.address);
            // console.log("operatorAmount :", operatorAmount)
            expect(operatorAmount).to.be.gt(0)
        })

        it("retireMember number1", async () => {
            let memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck).to.be.equal(member2AddrUpper)
            // let beforeWTONAmount = await wton.balanceOf(member2.address)
            let blacklistCheck = await daoCommittee_V2_Contract.blacklist(member2ContractLogic.address)
            expect(blacklistCheck).to.be.equal(false)

            await (
                await member2ContractLogic.connect(member2).retireMember()
            ).wait();

            memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)
            // let afterWTONAmount = await wton.balanceOf(member2.address)
            // expect(afterWTONAmount).to.be.gt(beforeWTONAmount)
            blacklistCheck = await daoCommittee_V2_Contract.blacklist(member2ContractLogic.address)
            expect(blacklistCheck).to.be.equal(true)
        })


        it("changeMember (CandidateAddOn) is success", async () => {
            let memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)

            let check = await titanLayerContract.operator();
            let check2 = await titanLayerContract.candidate();
            let check3 = await titanLayerContract.committee();
            expect(check).to.be.equal(check2)
            expect(check).to.be.equal(titanOperatorContract.address)
            expect(check3).to.be.equal(oldContractInfo.DAOCommitteeProxy)
            // console.log(check)
            // console.log(check2)
            // console.log(check3)
            // console.log(titanOperatorContract.address)
            // console.log(user1.address)

            await (
                await titanLayerContract.connect(daoCommitteeAdmin).changeMember(1)
            ).wait();

            memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck.toUpperCase()).to.be.equal(titanOperatorContract.address.toUpperCase())
        })

        it("setMemoOnCandidate (createCandidateAddon) is success", async () => {
            let beforeMemo = await titanLayerContract.memo();

            await daoCommittee_V2_Contract.connect(daoCommitteeAdmin).setMemoOnCandidate(
                titanOperatorContract.address,
                "titanMemo"
            )

            let afterMemo = await titanLayerContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
        })

        it("setMemoOnCandidateContract (createCandidateAddon)", async () => {
            let beforeMemo = await titanLayerContract.memo();
            let changeMemo = "Change2"

            await daoCommittee_V2_Contract.connect(daoCommitteeAdmin).setMemoOnCandidateContract(
                titanLayerContract.address,
                "Change2"
            )

            let afterMemo = await titanLayerContract.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
            expect(changeMemo).to.be.equal(afterMemo)
        })

        it("getClaimableActivityReward & claimActivityReward test (createCandidateAddon)", async () => {
            let amount = await daoCommittee_V2_Contract.getClaimableActivityReward(titanOperatorContract.address)
            expect(amount).to.be.gt(0);

            await titanLayerContract.connect(daoCommitteeAdmin).claimActivityReward()

            let amount2 = await daoCommittee_V2_Contract.getClaimableActivityReward(titanOperatorContract.address)
            expect(amount).to.be.gt(amount2);
        })

        it("totalStaked & stakedOf test (createCandidateAddon)", async () => {
            let totalStakedAmount = await titanLayerContract.totalStaked()
            let stakedOfAmount = await titanLayerContract.stakedOf(titanOperatorContract.address)

            expect(totalStakedAmount).to.be.equal(stakedOfAmount)
            expect(totalStakedAmount).to.be.gt(0)            
        })

        it("updateSeigniorage test (createCandidateAddon)", async () => {
            const beforeSeigBlock = await seigManagerV1_2.lastCommitBlock(titanLayerContract.address)
            console.log(beforeSeigBlock)

            await titanLayerContract.connect(user1).updateSeigniorage()

            const afterSeigBlock = await seigManagerV1_2.lastCommitBlock(titanLayerContract.address)
            console.log(afterSeigBlock)

            expect(afterSeigBlock).to.be.gt(beforeSeigBlock)
        })

        it("Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            
            const newMinimumNoticePeriod = 40;
            const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            const functionBytecode = selector.concat(data);

            let memo = "test"

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]", "string"],
                [
                    [daoagendaManager.address], 
                    noticePeriod.toString(), 
                    votingPeriod.toString(), 
                    true, 
                    [functionBytecode],
                    memo
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
            let checkMember = await daoCommittee_V2_Contract.isMember(titanOperatorContract.address)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await titanLayerContract.connect(daoCommitteeAdmin).castVote(
                agendaID,
                vote,
                "member1 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, titanOperatorContract.address);
            expect(voterInfo2[0]).to.be.equal(true);
            expect(voterInfo2[1]).to.be.equal(true);
            expect(voterInfo2[2]).to.be.equal(vote);

            const agenda2 = await daoagendaManager.agendas(agendaID);
            expect(agenda2[7]).to.be.equal(Number(beforeCountingYes)+1);
            expect(agenda2[8]).to.be.equal(Number(beforeCountingNo));
            expect(agenda2[9]).to.be.equal(Number(beforeCountingAbstain));

            const result = await daoagendaManager.getVoteStatus(agendaID, titanOperatorContract.address);
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
            let checkMember = await daoCommittee_V2_Contract.isMember(member3Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V2_Contract.connect(member3Contract).castVote(
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
            
            await daoCommittee_V2_Contract.executeAgenda(agendaID);

            const afterValue = await daoagendaManager.minimumNoticePeriodSeconds();

            expect(beforeValue).to.be.not.equal(afterValue);
            expect(afterValue).to.be.equal(40);

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        // it("currentAgendaStatus test", async () => {
        //     let result = await daoCommittee_V2_Contract.currentAgendaStatus(agendaID)
        //     expect(result.agendaResult).to.be.equal(1)
        //     expect(result.agendaStatus).to.be.equal(4)
        // })

        it("retireMember (candidateAddOn) (add blackList) (onlyMember)", async () => {
            let memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck.toUpperCase()).to.be.equal(titanOperatorContract.address.toUpperCase())
            // let beforeWTONAmount = await wton.balanceOf(member2.address)
            let blacklistCheck = await daoCommittee_V2_Contract.blacklist(titanLayerContract.address)
            expect(blacklistCheck).to.be.equal(false)

            await (
                await titanLayerContract.connect(daoCommitteeAdmin).retireMember()
            ).wait();

            memberCheck = await daoCommittee_V2_Contract.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)

            blacklistCheck = await daoCommittee_V2_Contract.blacklist(titanLayerContract.address)
            expect(blacklistCheck).to.be.equal(true)
        })

    })


})
