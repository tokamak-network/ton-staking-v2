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

        it("DAOProxyV2 owner(deployer) can selectorImplementations2", async () => {
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

        it("StorageStateCommittee Storage check", async () => {
            let tx = await daoCommitteeProxy.ton()
            let tx2 = await daoCommitteeProxy2Contract.ton()
            let tx3 = await daoCommittee_V1_Contract.ton()
            let tx4 = await daoCommittee_Owner_Contract.ton()

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)

            tx = await daoCommitteeProxy.daoVault()
            tx2 = await daoCommitteeProxy2Contract.daoVault()
            tx3 = await daoCommittee_V1_Contract.daoVault()
            tx4 = await daoCommittee_Owner_Contract.daoVault()

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)

            tx = await daoCommitteeProxy.agendaManager()
            tx2 = await daoCommitteeProxy2Contract.agendaManager()
            tx3 = await daoCommittee_V1_Contract.agendaManager()
            tx4 = await daoCommittee_Owner_Contract.agendaManager()

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)

            tx = await daoCommitteeProxy.candidateFactory()
            tx2 = await daoCommitteeProxy2Contract.candidateFactory()
            tx3 = await daoCommittee_V1_Contract.candidateFactory()
            tx4 = await daoCommittee_Owner_Contract.candidateFactory()

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)

            tx = await daoCommitteeProxy.layer2Registry()
            tx2 = await daoCommitteeProxy2Contract.layer2Registry()
            tx3 = await daoCommittee_V1_Contract.layer2Registry()
            tx4 = await daoCommittee_Owner_Contract.layer2Registry()

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)

            tx = await daoCommitteeProxy.seigManager()
            tx2 = await daoCommitteeProxy2Contract.seigManager()
            tx3 = await daoCommittee_V1_Contract.seigManager()
            tx4 = await daoCommittee_Owner_Contract.seigManager()

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)

            tx = await daoCommitteeProxy.members(0)
            tx2 = await daoCommitteeProxy2Contract.members(0)
            tx3 = await daoCommittee_V1_Contract.members(0)
            tx4 = await daoCommittee_Owner_Contract.members(0)

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)

            tx = await daoCommitteeProxy.maxMember()
            tx2 = await daoCommitteeProxy2Contract.maxMember()
            tx3 = await daoCommittee_V1_Contract.maxMember()
            tx4 = await daoCommittee_Owner_Contract.maxMember()

            console.log("tx :", tx)
            console.log("tx2 :", tx2)
            console.log("tx3 :", tx3)
            console.log("tx4 :", tx4)
        })
    })


    describe("DAOCommittee_V1 Claim Test", () => {
        it("member2 claim Contract", async () => {
            let amount = await daoCommittee_V1_Contract.getClaimableActivityReward(member2Addr)
            console.log(amount)
            expect(amount).to.be.gt(0);

            await member2ContractLogic.connect(member2).claimActivityReward();
            
            let amount2 = await daoCommittee_V1_Contract.getClaimableActivityReward(member2Addr)
            console.log(amount2)
            expect(amount2).to.be.equal(0);
        })

        it("member3 claim Contract", async () => {
            let amount = await daoCommittee_V1_Contract.getClaimableActivityReward(member3Addr)
            console.log(amount)
            expect(amount).to.be.gt(0);

            await member3ContractLogic.connect(member3).claimActivityReward();
            
            let amount2 = await daoCommittee_V1_Contract.getClaimableActivityReward(member3Addr)
            console.log(amount2)
            expect(amount2).to.be.equal(0);
        })

        it("newMember1 claim Contract", async () => {
            let amount = await daoCommittee_V1_Contract.getClaimableActivityReward(newMember1Addr)
            console.log(amount)
            expect(amount).to.be.gt(0);

            await newMember1ContractLogic.connect(newMember1).claimActivityReward();
            
            let amount2 = await daoCommittee_V1_Contract.getClaimableActivityReward(newMember1Addr)
            console.log(amount2)
            expect(amount2).to.be.equal(0);
        })
    })

    describe("changeMember Test", () => {
        it("member2 retire after same getClaimAmount", async () => {
            const block = await ethers.provider.getBlock('latest')
            // console.log("block.timestamp :", block.timestamp);
            let amount = await daoCommittee_V1_Contract.getClaimableActivityReward(member2Addr)

            await member2ContractLogic.connect(member2).retireMember();

            const block2 = await ethers.provider.getBlock('latest')
            // console.log("block2.timestamp :", block2.timestamp);
            let amount2 = await daoCommittee_V1_Contract.getClaimableActivityReward(member2Addr)

            expect(amount2).to.be.gt(amount);
            
            let blockDiff = block2.timestamp-block.timestamp
            let activityRewardPerSecond = await daoCommittee_V1_Contract.activityRewardPerSecond();
            // console.log("activityRewardPerSecond :", activityRewardPerSecond)
            let activityRewardPerSecondblockDiff = activityRewardPerSecond.mul(blockDiff)
            // console.log("activityRewardPerSecond10 :", activityRewardPerSecond10)
            let timeAddAmount = amount.add(activityRewardPerSecondblockDiff)
            expect(timeAddAmount).to.be.equal(amount2);
        })

        it("member2 can changeMember because deposit over 1000TON", async () => {
            const block = await ethers.provider.getBlock('latest')
            let amount = await daoCommittee_V1_Contract.getClaimableActivityReward(newMember1Addr)
            
            await member2ContractLogic.connect(member2).changeMember(0);
            // await daoCommittee_V1_Contract.connect(member2Contract).changeMember(0);

            const block2 = await ethers.provider.getBlock('latest')
            let amount2 = await daoCommittee_V1_Contract.getClaimableActivityReward(newMember1Addr)

            expect(amount2).to.be.gt(amount);
            
            let blockDiff = block2.timestamp-block.timestamp
            let activityRewardPerSecond = await daoCommittee_V1_Contract.activityRewardPerSecond();
            let activityRewardPerSecondblockDiff = activityRewardPerSecond.mul(blockDiff)
            let timeAddAmount = amount.add(activityRewardPerSecondblockDiff)
            expect(timeAddAmount).to.be.equal(amount2);
        })
    })
})