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
const DAOCommitteeDAOVaultABI = require("../../artifacts/contracts/dao/DAOCommitteeDAOVault.sol/DAOCommitteeDAOVault.json").abi;
const DAOCommittee_V1ABI = require("../../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const DAOProxy2ABI = require("../../artifacts/contracts/proxy/DAOCommitteeProxy2.sol/DAOCommitteeProxy2.json").abi;
const SeigManagerProxyABI = require("../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json").abi;
const SeigManagerABI = require("../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json").abi;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;

const CandidateABI = require("../../abi/Candidate.json").abi;


describe("DAO Proxy Change Test", () => {

    let daoCommitteeAdmin;
    let daoCommitteeAdminContract;
    let daoCommitteeProxy;
    // let daoCommitteeDAOVaultLogic;
    let daoCommitteeOwnerLogic;
    let ton;
    let wton;
    let seigManagerContract;

    let daoCommittee;
    let daoCommitteeOwner;
    let daoagendaManager;
    let daovault;

    let testAddr = "f0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";
    let tonAddr = "2be5e8c109e2197D077D13A82dAead6a9b3433C5";
    let wtonAddr = "c4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2";

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
            user1Addr,
        ]);
        user1 = await hre.ethers.getSigner(user1Addr);

        await hre.network.provider.send("hardhat_impersonateAccount", [
            user2Addr,
        ]);
        user2 = await hre.ethers.getSigner(user2Addr);
        
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

    describe("deploy & setting the Proxy2", () => {
        it("Deploy the DAOCommitteeProxy2", async () => {
            const DAOProxy2 = await ethers.getContractFactory("DAOCommitteeProxy2");
            daoCommitteeProxy2 = await DAOProxy2.connect(member2).deploy();

            await daoCommitteeProxy2.deployed();
        })

        it("Set DAOProxy", async () => {
            daoCommitteeProxy = new ethers.Contract(
                oldContractInfo.DAOCommitteeProxy,
                DAOCommitteeProxyABI,
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

        it("Set DAOProxy upgradeTo DAOProxy2", async () => {
            await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
                daoCommitteeProxy2.address)).wait()

            expect(await daoCommitteeProxy.implementation()).to.be.equal(daoCommitteeProxy2.address)
        })

        it("set DAOProxy2", async () => {
            daoCommitteeProxy2Contract =  new ethers.Contract(
                oldContractInfo.DAOCommitteeProxy,
                DAOProxy2ABI,
                daoCommitteeAdmin
            )

            let tx = await daoCommitteeProxy2Contract.hasRole(adminBytes, daoCommitteeAdmin.address)
            expect(tx).to.be.equal(true)
        })

        it("check Proxy & Proxy2 same storage", async () => {
            let ton1 = await daoCommitteeProxy.connect(daoCommitteeAdmin).ton()
            let ton2 = await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).ton()
            // console.log(ton1)
            // console.log(ton2)
            expect(ton1).to.be.equal(ton2)

            let role1 = await daoCommitteeProxy.DEFAULT_ADMIN_ROLE();
            let role2 = await daoCommitteeProxy2Contract.DEFAULT_ADMIN_ROLE();
            // console.log(role1)
            // console.log(role2)
            expect(role1).to.be.equal(role2)
        })

        it("DAOProxy2 check hasRole test", async () => {
            let tx = await daoCommitteeProxy2Contract.hasRole(adminBytes, daoCommitteeAdmin.address)
            expect(tx).to.be.equal(true)
            let tx2 = await daoCommitteeProxy2Contract.hasRole(adminBytes, daoCommitteeAdminContract.address)
            expect(tx2).to.be.equal(true)
        })

        it("DAOProxy check hasRole test", async () => {
            let tx = await daoCommitteeProxy.hasRole(adminBytes, daoCommitteeAdmin.address)
            // console.log("admin : ",tx)
            expect(tx).to.be.equal(true)
            let tx2 = await daoCommitteeProxy.hasRole(adminBytes, daoCommitteeAdminContract.address)
            // console.log("admin2 : ",tx2)
            expect(tx2).to.be.equal(true)
        })
    })

    describe("Deploy & Setting the DAOCommitte_V1 & DAOCommitteeOwner", () => {
        it("Deploy the DAOCommitte_V1", async () => {
            const DAOLogic = await ethers.getContractFactory("DAOCommittee_V1");
            daoCommitteeLogic = await DAOLogic.deploy();

            await daoCommitteeLogic.deployed();
        })

        it("Deploy the DAOCommitteOwner", async () => {
            const DAOOwnerContract = await ethers.getContractFactory("DAOCommitteeOwner");
            daoCommitteeOwner = await DAOOwnerContract.deploy();

            await daoCommitteeOwner.deployed();
        })

        // it("DAO upgradeTo newLogic", async () => {
        //     await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
        //         daoCommitteeLogic.address)).wait()
        // })

        it("Set DAOProxy2 upgradeTo2 DAOCommittee_V1", async () => {
            await (await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).upgradeTo2(
                daoCommitteeLogic.address)).wait()
        })

        it("DAOProxy2 not Owner don't setAliveImplementation2", async () => {
            await expect(
                daoCommitteeProxy2Contract.connect(member2).setAliveImplementation2(
                    daoCommitteeLogic.address, 
                    true
                )
            ).to.be.revertedWith("DAOCommitteeProxy2: msg.sender is not an admin");
        })

        it("DAOProxy2 setAliveImplementation2 DAOv2CommitteeV1", async () => {
            await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).setAliveImplementation2(
                daoCommitteeLogic.address, 
                true
            )
        })

        it("DAOProxy2 not Owner don't setImplementation2", async () => {
            await expect(
                daoCommitteeProxy2Contract.connect(member2).setImplementation2(
                    daoCommitteeLogic.address, 
                    0, 
                    true
                )
            ).to.be.revertedWith("DAOCommitteeProxy2: msg.sender is not an admin");
        })

        it("DAOProxy2 setImplementation2 DAOv2CommitteeV1", async () => {
            await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).setImplementation2(
                daoCommitteeLogic.address, 
                0, 
                true
            )
        })

        it("DAOProxy2 not owner(deployer) don't setAliveImplementation2 DAOv2CommitteeV2", async () => {
            await expect(
                daoCommitteeProxy2Contract.connect(member2).setAliveImplementation2(
                    daoCommitteeOwner.address, 
                    true
                )
            ).to.be.revertedWith("DAOCommitteeProxy2: msg.sender is not an admin");
        })

        it("DAOProxy2 setAliveImplementation2 DAOv2CommitteeV2", async () => {
            await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).setAliveImplementation2(
                daoCommitteeOwner.address, 
                true
            )
        })

        it("DAOProxy2 not Owner don't setImplementation2 DAOv2CommitteeV2", async () => {
            await expect(
                daoCommitteeProxy2Contract.connect(member2).setImplementation2(
                    daoCommitteeOwner.address, 
                    1, 
                    true
                )
            ).to.be.revertedWith("DAOCommitteeProxy2: msg.sender is not an admin");
        })

        it("DAOProxy2 setImplementation2 DAOv2CommitteeV2", async () => {
            await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).setImplementation2(
                daoCommitteeOwner.address, 
                1, 
                true
            )
        })

        it("DAOProxyV2 not owner(deployer) don't selectorImplementations2", async () => {
            const _setSeigManager = Web3EthAbi.encodeFunctionSignature(
                "setSeigManager(address)"
            )

            const _setTargetSeigManager = Web3EthAbi.encodeFunctionSignature(
                "setTargetSeigManager(address,address)"
            )

            const _setSeigPause = Web3EthAbi.encodeFunctionSignature(
                "setSeigPause()"
            )

            const _setSeigUnpause = Web3EthAbi.encodeFunctionSignature(
                "setSeigUnpause()"
            )

            const _setTargetGlobalWithdrawalDelay = Web3EthAbi.encodeFunctionSignature(
                "setTargetGlobalWithdrawalDelay(addres,uint256)"
            )

            const _setTargetAddMinter = Web3EthAbi.encodeFunctionSignature(
                "setTargetAddMinter(address,address)"
            )

            const _setTargetUpgradeTo = Web3EthAbi.encodeFunctionSignature(
                "setTargetUpgradeTo(address,address)"
            )

            const _setTargetSetTON = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetTON(address,address)"
            )
            
            const _setTargetSetWTON = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetWTON(address,address)"
            )

            const _setDaoVault = Web3EthAbi.encodeFunctionSignature(
                "setDaoVault(address)"
            )

            const _setLayer2Registry = Web3EthAbi.encodeFunctionSignature(
                "setLayer2Registry(address)"
            )

            const _setAgendaManager = Web3EthAbi.encodeFunctionSignature(
                "setAgendaManager(address)"
            )

            const _setCandidateFactory = Web3EthAbi.encodeFunctionSignature(
                "setCandidateFactory(address)"
            )

            const _setTon = Web3EthAbi.encodeFunctionSignature(
                "setTon(address)"
            )

            const _setWton = Web3EthAbi.encodeFunctionSignature(
                "setWton(address)"
            )

            const _setActivityRewardPerSecond = Web3EthAbi.encodeFunctionSignature(
                "setActivityRewardPerSecond(uint256)"
            )

            const _setCandidatesSeigManager = Web3EthAbi.encodeFunctionSignature(
                "setCandidatesSeigManager(address[],address)"
            )

            const _setCandidatesCommittee = Web3EthAbi.encodeFunctionSignature(
                "setCandidatesCommittee(address[],address)"
            )

            const _setCreateAgendaFees = Web3EthAbi.encodeFunctionSignature(
                "setCreateAgendaFees(uint256)"
            )

            const _setMinimumNoticePeriodSeconds = Web3EthAbi.encodeFunctionSignature(
                "setMinimumNoticePeriodSeconds(uint256)"
            )

            const _setMinimumVotingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
                "setMinimumVotingPeriodSeconds(uint256)"
            )

            const _setExecutingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
                "setExecutingPeriodSeconds(uint256)"
            )


            await expect(
                daoCommitteeProxy2Contract.connect(member2).setSelectorImplementations2(
                    [
                        _setSeigManager,_setTargetSeigManager,_setSeigPause,_setSeigUnpause,
                        _setTargetGlobalWithdrawalDelay,_setTargetAddMinter,_setTargetUpgradeTo,_setTargetSetTON,_setTargetSetWTON,
                        _setDaoVault,_setLayer2Registry,_setAgendaManager,_setCandidateFactory,_setTon,_setWton,
                        _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setCreateAgendaFees,
                        _setMinimumNoticePeriodSeconds,_setMinimumVotingPeriodSeconds,_setExecutingPeriodSeconds
                    ],
                    daoCommitteeOwner.address
            )).to.be.revertedWith("DAOCommitteeProxy2: msg.sender is not an admin");
        })

        it("DAOProxyV2 not owner(deployer) don't selectorImplementations2", async () => {
            const _setLayer2CandidateFactory = Web3EthAbi.encodeFunctionSignature(
                "setLayer2CandidateFactory(address)"
            ) 

            const _setLayer2Manager = Web3EthAbi.encodeFunctionSignature(
                "setLayer2Manager(address)"
            ) 

            const _setTargetSetLayer2Manager = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetLayer2Manager(address,address)"
            )

            const _setTargetSetL2Registry = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetL2Registry(address,address)"
            )

            const _setTargetLayer2StartBlock = Web3EthAbi.encodeFunctionSignature(
                "setTargetLayer2StartBlock(address,uint256)"
            )

            const _setTargetSetImplementation2 = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetImplementation2(address,address,uint256,bool)"
            )

            const _setTargetSetSelectorImplementations2 = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetSelectorImplementations2(address,bytes4[],address)"
            )

            const _setSeigManager = Web3EthAbi.encodeFunctionSignature(
                "setSeigManager(address)"
            )

            const _setTargetSeigManager = Web3EthAbi.encodeFunctionSignature(
                "setTargetSeigManager(address,address)"
            )

            const _setSeigPause = Web3EthAbi.encodeFunctionSignature(
                "setSeigPause()"
            )

            const _setSeigUnpause = Web3EthAbi.encodeFunctionSignature(
                "setSeigUnpause()"
            )

            const _setTargetGlobalWithdrawalDelay = Web3EthAbi.encodeFunctionSignature(
                "setTargetGlobalWithdrawalDelay(addres,uint256)"
            )

            const _setTargetAddMinter = Web3EthAbi.encodeFunctionSignature(
                "setTargetAddMinter(address,address)"
            )

            const _setTargetUpgradeTo = Web3EthAbi.encodeFunctionSignature(
                "setTargetUpgradeTo(address,address)"
            )

            const _setTargetSetTON = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetTON(address,address)"
            )
            
            const _setTargetSetWTON = Web3EthAbi.encodeFunctionSignature(
                "setTargetSetWTON(address,address)"
            )

            const _setDaoVault = Web3EthAbi.encodeFunctionSignature(
                "setDaoVault(address)"
            )

            const _setLayer2Registry = Web3EthAbi.encodeFunctionSignature(
                "setLayer2Registry(address)"
            )

            const _setAgendaManager = Web3EthAbi.encodeFunctionSignature(
                "setAgendaManager(address)"
            )

            const _setCandidateFactory = Web3EthAbi.encodeFunctionSignature(
                "setCandidateFactory(address)"
            )

            const _setTon = Web3EthAbi.encodeFunctionSignature(
                "setTon(address)"
            )

            const _setWton = Web3EthAbi.encodeFunctionSignature(
                "setWton(address)"
            )

            const _setActivityRewardPerSecond = Web3EthAbi.encodeFunctionSignature(
                "setActivityRewardPerSecond(uint256)"
            )

            const _setCandidatesSeigManager = Web3EthAbi.encodeFunctionSignature(
                "setCandidatesSeigManager(address[],address)"
            )

            const _setCandidatesCommittee = Web3EthAbi.encodeFunctionSignature(
                "setCandidatesCommittee(address[],address)"
            )

            const _setCreateAgendaFees = Web3EthAbi.encodeFunctionSignature(
                "setCreateAgendaFees(uint256)"
            )

            const _setMinimumNoticePeriodSeconds = Web3EthAbi.encodeFunctionSignature(
                "setMinimumNoticePeriodSeconds(uint256)"
            )

            const _setMinimumVotingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
                "setMinimumVotingPeriodSeconds(uint256)"
            )

            const _setExecutingPeriodSeconds = Web3EthAbi.encodeFunctionSignature(
                "setExecutingPeriodSeconds(uint256)"
            )


            await daoCommitteeProxy2Contract.connect(daoCommitteeAdmin).setSelectorImplementations2(
                    [
                        _setLayer2CandidateFactory,_setLayer2Manager,_setTargetSetLayer2Manager,_setTargetSetL2Registry,
                        _setTargetLayer2StartBlock,_setTargetSetImplementation2,_setTargetSetSelectorImplementations2,
                        _setSeigManager,_setTargetSeigManager,_setSeigPause,_setSeigUnpause,
                        _setTargetGlobalWithdrawalDelay,_setTargetAddMinter,_setTargetUpgradeTo,_setTargetSetTON,_setTargetSetWTON,
                        _setDaoVault,_setLayer2Registry,_setAgendaManager,_setCandidateFactory,_setTon,_setWton,
                        _setActivityRewardPerSecond,_setCandidatesSeigManager,_setCandidatesCommittee,_setCreateAgendaFees,
                        _setMinimumNoticePeriodSeconds,_setMinimumVotingPeriodSeconds,_setExecutingPeriodSeconds
                    ],
                    daoCommitteeOwner.address
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

    })

    describe("Setting another account & contract", () => {
        it("set DAOAgendaManager", async () => {
            daoagendaManager = new ethers.Contract(
                oldContractInfo.DAOAgendaManager,
                DAOAgendaManagerABI,
                daoCommitteeAdmin
            )
        })

        it("set DAOVault", async () => {
            daovault = new ethers.Contract(
                oldContractInfo.DAOVault,
                DAOVaultABI,
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

        it("Set TalkenCandidateContract", async () => {
            talkenContractLogic = new ethers.Contract(
                talkenContractAddr,
                CandidateABI,
                daoCommitteeAdmin
            )
        })
    })

    describe("DAOCommittee_V1 Logic test", () => {
        it("Contract Storage check", async () => {
            let v1Contract = await daoCommittee_V1_Contract.pauseProxy()
            let ownerContract = await daoCommittee_Owner_Contract.pauseProxy()
            let proxy1 = await daoCommitteeProxy.pauseProxy()
            let proxy2 = await daoCommitteeProxy2Contract.pauseProxy()
            
            expect(v1Contract).to.be.equal(ownerContract)
            expect(proxy1).to.be.equal(proxy2)
            expect(v1Contract).to.be.equal(proxy1)

            let v1ContractWTON = await daoCommittee_V1_Contract.wton()
            let ownerContractWTON = await daoCommittee_Owner_Contract.wton()
            expect(v1ContractWTON).to.be.equal(ownerContractWTON)
        })

        it("1. createCandidate (anyone)", async () => {
            let beforeCandidateLength = await daoCommittee_V1_Contract.candidatesLength()
            let candidateInfo1 = await daoCommittee_V1_Contract.candidates(beforeCandidateLength-1)
            // console.log(candidateInfo1)
            
            await daoCommittee_V1_Contract.connect(user1).createCandidate(
                "TestCandidate"
            );

            let afterCandidateLength = await daoCommittee_V1_Contract.candidatesLength()
            expect(afterCandidateLength).to.be.gt(beforeCandidateLength)

            let candidateInfo2 = await daoCommittee_V1_Contract.candidates(afterCandidateLength-1)
            // console.log(candidateInfo2)

            let candidateInfo = await daoCommittee_V1_Contract.candidateInfos(user1Addr)
            // console.log("candidateInfo : ", candidateInfo);
            expect(candidateInfo.memberJoinedTime).to.be.equal(0)
        })

        it("set user1CandidateContract", async () => {
            let candidateInfo = await daoCommittee_V1_Contract.candidateInfos(user1Addr)
            user1ContractAddr = candidateInfo.candidateContract;
            console.log("user1ContractAddr: ", user1ContractAddr)

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

        it("2. createCandidate (Owner)", async () => {
            // console.log(daoCommittee_V1_Contract)
            let beforeCandidateLength = await daoCommittee_V1_Contract.candidatesLength()

            await daoCommittee_V1_Contract.connect(daoCommitteeAdmin).createCandidateOwner(
                "TestCandidate2",
                user2Addr
            );

            let afterCandidateLength = await daoCommittee_V1_Contract.candidatesLength()
            expect(afterCandidateLength).to.be.gt(beforeCandidateLength)
            
            let candidateInfo = await daoCommittee_V1_Contract.candidateInfos(user2Addr)
            // console.log("candidateInfo : ", candidateInfo);
            expect(candidateInfo.memberJoinedTime).to.be.equal(0)
        })

        it("set user2CandidateContract", async () => {
            let candidateInfo = await daoCommittee_V1_Contract.candidateInfos(user2Addr)
            user2ContractAddr = candidateInfo.candidateContract;
            console.log("user2ContractAddr: ", user2ContractAddr)

            // await hre.network.provider.send("hardhat_impersonateAccount", [
            //     user2ContractAddr,
            // ]);
            // user2Contract = await hre.ethers.getSigner(user2ContractAddr);

            // await hre.network.provider.send("hardhat_setBalance", [
            //     user2Contract,
            //     sendether
            // ]);

            user2ContractLogic = new ethers.Contract(
                user2ContractAddr,
                CandidateABI,
                daoCommitteeAdmin
            )
        })

        it("3. retireMember (onlyMember)", async () => {
            let memberCheck = await daoCommittee_V1_Contract.members(1)
            expect(memberCheck).to.be.equal(member2AddrUpper)

            await member2ContractLogic.connect(member2).retireMember();

            memberCheck = await daoCommittee_V1_Contract.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)
        })

        it("4. changeMemeber (anyone)", async () => {
            let memberCheck = await daoCommittee_V1_Contract.members(1)
            expect(memberCheck).to.be.equal(zeroAddr)

            await member2ContractLogic.connect(member2).changeMember(1);

            memberCheck = await daoCommittee_V1_Contract.members(1)
            expect(memberCheck).to.be.equal(member2AddrUpper)
        })

        it("5. setMemoOnCandidate (anyone)", async () => {
            let beforeMemo = await user1ContractLogic.memo();

            await daoCommittee_V1_Contract.connect(user1).setMemoOnCandidate(
                user1Addr,
                "Change"
            )

            let afterMemo = await user1ContractLogic.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
        })

        it("6. setMemoOnCandidateContract (anyone)", async () => {
            let beforeMemo = await user1ContractLogic.memo();

            await daoCommittee_V1_Contract.connect(user1).setMemoOnCandidateContract(
                user1ContractAddr,
                "Change2"
            )

            let afterMemo = await user1ContractLogic.memo();
            expect(beforeMemo).to.be.not.equal(afterMemo)
        })

        it("7. OnApprove reverted Test (claimTON)", async () => {
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

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets, 
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    false,
                    functionBytecodes
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

        it("8. OnApprove reverted Test (claimERC20) (TON)", async () => {
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

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets, 
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    false,
                    functionBytecodes
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

        it("9. OnApprove pass Test (claimERC20) (WTON)", async () => {
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

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets, 
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    false,
                    functionBytecodes
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

        it("10. Create new Agenda", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            const newMinimumNoticePeriod = 30;
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

        it("11. cast vote (member2)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(member2Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(member2Contract).castVote(
                agendaID,
                vote,
                "member2 vote"
            )

            const voterInfo2 = await daoagendaManager.voterInfos(agendaID, member2Addr);
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

            const result = await daoagendaManager.getVoteStatus(agendaID, member2Addr);
            expect(result[0]).to.be.equal(true);
            expect(result[1]).to.be.equal(vote);
        })

        it("12. cannnot cast vote (user1)", async () => {
            const vote = 2
            await expect(daoCommittee_V1_Contract.connect(user1).castVote(
                agendaID,
                vote,
                "user1 vote"
            )).to.be.reverted;
        })

        it("13. cast vote (member3)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee_V1_Contract.isMember(member2Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee_V1_Contract.connect(member3Contract).castVote(
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
            console.log("agenda Result :", agenda[10])
            console.log("agenda status :", agenda[11])

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                const currentTime = await time.latest();
                if (currentTime < votingEndTimestamp) {
                    await time.increaseTo(Number(votingEndTimestamp));
                }
                expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });


        it("14. execute agenda (anyone)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            expect(agenda[6]).to.be.equal(0);

            const beforeValue = await daoagendaManager.minimumNoticePeriodSeconds();
            // console.log("agendaID : ", agendaID)
            // console.log("beforeAgendaID : ", beforeAgendaID)
            // console.log("beforeValue :", beforeValue)
            
            // let diffAgenda = agendaID - beforeAgendaID
            
            await daoCommittee_V1_Contract.executeAgenda(agendaID);
            const afterValue = await daoagendaManager.minimumNoticePeriodSeconds();

            // expect(beforeValue).to.be.not.equal(afterValue);
            expect(afterValue).to.be.equal(30);

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        it("15. Create new Agenda", async () => {
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

        it("16. setAgendaStatus test (Owner)", async () => {    
            expect(await daoagendaManager.getAgendaStatus(agendaID)).to.be.equal(1);

            await daoCommittee_V1_Contract.connect(daoCommitteeAdmin).setAgendaStatus(
                agendaID,
                2,
                0
            );

            expect(await daoagendaManager.getAgendaStatus(agendaID)).to.be.equal(2);
        })        

        it("17. endAgendaVoting test (anyone)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                const currentTime = await time.latest();
                if (currentTime < votingEndTimestamp) {
                    await time.increaseTo(Number(votingEndTimestamp));
                }
                expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
            }

            await daoCommittee_V1_Contract.connect(user1).endAgendaVoting(agendaID);

            expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(false);
        })      

        it("18. updateSeigniorage test (anyone)", async () => {
            const beforeSeigBlock = await seigManagerContract.lastCommitBlock(member2ContractAddr)

            await daoCommittee_V1_Contract.connect(user1).updateSeigniorage(member2Addr)

            const afterSeigBlock = await seigManagerContract.lastCommitBlock(member2ContractAddr)

            expect(afterSeigBlock).to.be.gt(beforeSeigBlock)
        })

        it("19. getClaimableActivityReward & claimActivityReward test (anyone)", async () => {
            let amount = await daoCommittee_V1_Contract.getClaimableActivityReward(member2Addr)
            expect(amount).to.be.gt(0);

            await member2ContractLogic.connect(member2).claimActivityReward();
            
            let amount2 = await daoCommittee_V1_Contract.getClaimableActivityReward(member2Addr)
            expect(amount2).to.be.equal(0);
        })

        it("20. isCandidate (view)", async () => {
            let checkisCandidate = await daoCommittee_V1_Contract.isCandidate(member2Addr)
            expect(checkisCandidate).to.be.equal(true)
        })

        it("21. totalSupplyOnCandidate (view)", async () => {
            let amount = await daoCommittee_V1_Contract.totalSupplyOnCandidate(member2Addr)
            expect(amount).to.be.gt(0)
        })

        it("22. balanceOfOnCandidate (view)", async () => {
            let amount = await daoCommittee_V1_Contract.balanceOfOnCandidate(
                member2Addr,
                member2Addr
            )
            expect(amount).to.be.gt(0)
        })

        it("23. totalSupplyOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V1_Contract.totalSupplyOnCandidateContract(
                member2ContractAddr
            )
            expect(amount).to.be.gt(0)
        })

        it("24. balanceOfOnCandidateContract (view)", async () => {
            let amount = await daoCommittee_V1_Contract.balanceOfOnCandidateContract(
                member2ContractAddr,
                member2Addr
            )
            expect(amount).to.be.gt(0)
        })

        it("25. candidatesLength (view)", async () => {
            let length = await daoCommittee_V1_Contract.candidatesLength()
            expect(length).to.be.gt(0)
        })

        it("26. isExistCandidate (view)", async () => {
            let check = await daoCommittee_V1_Contract.isExistCandidate(member2Addr)
            expect(check).to.be.equal(true)
        })

        it("27. getOldCandidateInfos (view)", async () => {
            let oldinfo = await daoCommittee_V1_Contract.getOldCandidateInfos(member2Addr)
            console.log(oldinfo)
            // expect(check).to.be.equal(true)
        })

        it("27. getOldCandidateInfos (view)", async () => {
            let amount = await daoCommittee_V1_Contract.operatorAmountCheck(
                member2ContractAddr,
                member2Addr
            )
            expect(amount).to.be.gt(0)
        })


    })

    describe("DAOCommitteeOwner Logic test", () => {
        it("setSeigManager test", async () => {
            let beforeAddr = await daoCommittee_Owner_Contract.seigManager()
            
            await daoCommittee_Owner_Contract.connect(daoCommitteeAdmin).setSeigManager(talkenAddr)
    
            let afterAddr = await daoCommittee_Owner_Contract.seigManager()
            expect(afterAddr).to.be.equal(talkenUpperAddr)
            // expect(beforeAddr).to.be.not.equal(afterAddr)

            await daoCommittee_Owner_Contract.connect(daoCommitteeAdmin).setSeigManager(nowContractInfo.SeigManager)
            afterAddr = await daoCommittee_Owner_Contract.seigManager()
            expect(afterAddr).to.be.equal(SeigManagerUpper)
        })

        it("setWTON test", async () => {
            // let beforeAddr = await daoCommittee_Owner_Contract.wton()
            
            await daoCommittee_Owner_Contract.connect(daoCommitteeAdmin).setWton(oldContractInfo.WTON)
    
            let afterAddr = await daoCommittee_Owner_Contract.wton()
            expect(afterAddr).to.be.equal(oldContractInfo.WTON)
            // expect(beforeAddr).to.be.not.equal(afterAddr)
        })
    })
})
