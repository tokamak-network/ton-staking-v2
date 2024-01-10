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

const networkName = "sepolia"

// const daoAdminAddress = '0xb4983da083a5118c903910db4f5a480b1d9f3687'
const daoAdminAddress = '0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2'

const goerliPowerTonAdmin = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
const mainnetPowerTonAdmin = "0x15280a52e79fd4ab35f4b9acbb376dcd72b44fd1"

let daoAgendaMangerAddress = "0xcD4421d082752f363E1687544a09d5112cD4f484"; //DAOAgendaManager Address

const TonABI = require("../../abi/TON.json").abi;
const WtonABI = require("../../abi/WTON.json").abi;
const DAOCommitteeExtendABI = require("../../abi/DAOCommitteeExtend.json").abi;
const DAOCommitteeOwnerABI = require("../../artifacts/contracts/dao/DAOCommitteeOwner.sol/DAOCommitteeOwner.json").abi;
const DAOCommitteeDAOVaultABI = require("../../artifacts/contracts/dao/DAOCommitteeDAOVault.sol/DAOCommitteeDAOVault.json").abi;
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const SeigManagerProxyABI = require("../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json").abi;
const SeigManagerABI = require("../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json").abi;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;

const CandidateABI = require("../../abi/Candidate.json").abi;


describe("DAOAgenda Test", () => {

    let daoCommitteeAdmin;
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
    let wtonAddr = "79e0d92670106c85e9067b56b8f674340dca0bbd";

    let member1;
    let member2;
    let member3;

    let newMember1;

    let member1Contract;
    let member2Contract;
    let member3Contract;

    let member1ContractLogic;
    let member2ContractLogic;
    let member3ContractLogic;
    let newMember1ContractLogic;

    let newMember1Contract;

    let member1Addr = "0xd4335a175c36c0922f6a368b83f9f6671bf07606"
    let member2Addr = "0xf0b595d10a92a5a9bc3ffea7e79f5d266b6035ea"
    let member3Addr = "0x757de9c340c556b56f62efae859da5e08baae7a2"

    let member1ContractAddr = "0xaeb0463a2fd96c68369c1347ce72997406ed6409"
    let member2ContractAddr = "0xbdbb2c17846027c75802464d4afdd23a9192e103"
    let member3ContractAddr = "0xabd15c021942ca54abd944c91705fe70fea13f0d"

    let member4Addr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66"

    let newMember1Addr = "0xea8e2ec08dcf4971bdcdfffe21439995378b44f3"
    let newMember1ContractAddr = "0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF"


    let beforeclaimAmount;
    let afterclaimAmount;

    let wtonCheck = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";

    let sendether = "0xDE0B6B3A7640000"

    let zeroAddr = "0x0000000000000000000000000000000000000000";
    let oneAddr = "0x0000000000000000000000000000000000000001";
    let twoAddr = "0x0000000000000000000000000000000000000002";
    let tosAddr = "0xff3ef745d9878afe5934ff0b130868afddbc58e8";

    // sepolia network
    const oldContractInfo = {
        TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
        WTON: "0x79e0d92670106c85e9067b56b8f674340dca0bbd",
        Layer2Registry : "0xAdA189ff3D973753971eff71F6F41A9419a4a1F8",
        Layer2RegistryProxy : "0xA0a9576b437E52114aDA8b0BC4149F2F5c604581",
        DepositManager : "0x2d361b25395907a897f62e87A57b362264F36d7a",
        DepositManagerProxy : "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F",
        Candidate : "0xc462834ea537c23C6aAb31c2564dfE16e7CD37BD",
        CandidateFactory : "0xc004ae9c774A27d6bE6C860d8c414AC697D4dc28",
        CandidateFactoryProxy : "0x04e3C2B720FB8896A7f9Ea59DdcA85fD45189C7f",
        OldDAOVaultMock: "0x0F5AecE5E5F5CF594CaBDf2445D5984818fc1e34",
        SeigManager : "0xe05d62c21f4bba610F411A6F9BddF63cffb43B63",
        SeigManagerMigration: "0xBa3FBF5980Ba60bEe096cecEcDA3f28AC60904cC",
        SeigManagerProxy : "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7",
        PowerTON: "0xbe16830EeD019227892938Ae13C54Ec218772f48",
        DAOVault: "0xB9F6c9E75418D7E5a536ADe08f0218196BB3eBa4",
        DAOAgendaManager: "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08",
        DAOCommittee: "0x79cfbEaCB5470bBe3B8Fe76db2A61Fc59e588C38",
        DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386"
    }

    let daoCommitteeDAOVaultLogic = "0xba5634e0c432af80060cf19e0940b59b2dc31173"

    let daoCommitteeLogic;

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
            member1Addr,
        ]);
        member1 = await hre.ethers.getSigner(member1Addr);

        // await hre.network.provider.send("hardhat_impersonateAccount", [
        //     newMember1Addr,
        // ]);
        // newMember1 = await hre.ethers.getSigner(newMember1Addr);
        
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

        // await hre.network.provider.send("hardhat_impersonateAccount", [
        //     newMember1ContractAddr,
        // ]);
        // newMember1Contract = await hre.ethers.getSigner(newMember1ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member2ContractAddr,
        ]);
        member2Contract = await hre.ethers.getSigner(member2ContractAddr);
        
        await hre.network.provider.send("hardhat_impersonateAccount", [
            member3ContractAddr,
        ]);
        member3Contract = await hre.ethers.getSigner(member3ContractAddr);
        
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

        // await hre.network.provider.send("hardhat_setBalance", [
        //     newMember1ContractAddr,
        //     sendether
        // ]);

        await hre.network.provider.send("hardhat_setBalance", [
            member3Addr,
            sendether
        ]);
    })

    describe("deploy the DAOCommitte_V1", () => {
        it("Deploy the DAOCommitte_V1", async () => {
            const DAOLogic = await ethers.getContractFactory("DAOCommittee_V1");
            daoCommitteeLogic = await DAOLogic.deploy();

            await daoCommitteeLogic.deployed();
        })
    })

    describe("Setting the DAOCommitte_V1", () => {
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

        it("Set DAOProxy", async () => {
            daoCommitteeProxy = new ethers.Contract(
                oldContractInfo.DAOCommitteeProxy,
                DAOCommitteeProxyABI,
                daoCommitteeAdmin
            )
        })

        it("pauseProxy check", async () => {
            let pauseProxy = await daoCommitteeProxy.pauseProxy()
            console.log('pauseProxy', pauseProxy)

            if (pauseProxy == true) {
                await (await daoCommitteeProxy.connect(daoCommitteeAdmin).setProxyPause(false)).wait()
            }
            pauseProxy = await daoCommitteeProxy.pauseProxy()
            console.log('pauseProxy', pauseProxy)
        })

        // it("DAO upgradeTo newLogic", async () => {
        //     await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
        //         daoCommitteeLogic.address)).wait()
        // })

        it("set DAO NewLogic", async () => {
            daoCommittee = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommitteeExtendABI,
                daoCommitteeAdmin
            )
        })

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

        // it("Set newMember1CandidateContract", async () => {
        //     newMember1ContractLogic = new ethers.Contract(
        //         newMember1ContractAddr,
        //         CandidateABI,
        //         daoCommitteeAdmin
        //     )
        // })


    })

    describe("Setting Test", () => {
        it("DAOVault TON Addr check", async () => {
            let tonaddr = await daovault.ton();
            expect(tonaddr).to.be.equal(twoAddr)
        })

        it("DAOVault WTON Addr check", async () => {
            let wtonaddr = await daovault.wton();
            expect(wtonaddr).to.be.equal(oldContractInfo.WTON)
        })

        // it("DAO wton addr check", async () => {
        //     let wtonAddr = await daoCommittee.wton();
        //     expect(wtonAddr).to.be.equal(oldContractInfo.WTON);
        // })
    })

    // describe("getclaimAmount Test", () => {
    //     it("getClaimAmount member1", async () => {
    //         let amount = await daoCommittee.getClaimableActivityReward(member1Addr)
    //         let amount2 = await daoCommittee.getClaimableActivityReward(member1ContractAddr)
    //         console.log("amount : ", amount);
    //         console.log("amount2 : ", amount2);
    //     })

    //     it("getClaimAmount member2", async () => {
    //         let amount = await daoCommittee.getClaimableActivityReward(member2Addr)
    //         let amount2 = await daoCommittee.getClaimableActivityReward(member2ContractAddr)
    //         console.log("amount : ", amount);
    //         console.log("amount2 : ", amount2);
    //     })

    //     it("getClaimAmount member3", async () => {
    //         let amount = await daoCommittee.getClaimableActivityReward(member3Addr)
    //         let amount2 = await daoCommittee.getClaimableActivityReward(member3ContractAddr)
    //         console.log("amount : ", amount);
    //         console.log("amount2 : ", amount2);
    //     })

    //     it("getClaimAmount newMember3", async () => {
    //         let amount = await daoCommittee.getClaimableActivityReward(newMember1Addr)
    //         let amount2 = await daoCommittee.getClaimableActivityReward(newMember1ContractAddr)
    //         console.log("amount : ", amount);
    //         console.log("amount2 : ", amount2);
    //     })

    //     it("getClaimAmount newMember3", async () => {
    //         let amount = await daoCommittee.getClaimableActivityReward(member4Addr)
    //         // let amount2 = await daoCommittee.getClaimableActivityReward(newMember1ContractAddr)
    //         console.log("amount : ", amount);
    //         // console.log("amount2 : ", amount2);
    //     })
    // })

    describe("Contract Claim Test", () => {
        it("member2 claim Contract", async () => {
            let amount = await daoCommittee.getClaimableActivityReward(member2Addr)
            console.log(amount)
            expect(amount).to.be.gt(0);

            await member2ContractLogic.connect(member2).claimActivityReward();
            
            let amount2 = await daoCommittee.getClaimableActivityReward(member2Addr)
            console.log(amount2)
            expect(amount2).to.be.equal(0);
        })

        it("member3 claim Contract", async () => {
            let amount = await daoCommittee.getClaimableActivityReward(member3Addr)
            console.log(amount)
            expect(amount).to.be.gt(0);

            await member3ContractLogic.connect(member3).claimActivityReward();
            
            let amount2 = await daoCommittee.getClaimableActivityReward(member3Addr)
            console.log(amount2)
            expect(amount2).to.be.equal(0);
        })

        it("newMember1 claim Contract", async () => {
            let amount = await daoCommittee.getClaimableActivityReward(member1Addr)
            console.log(amount)
            expect(amount).to.be.gt(0);

            await member1ContractLogic.connect(member1).claimActivityReward();
            
            let amount2 = await daoCommittee.getClaimableActivityReward(member1Addr)
            console.log(amount2)
            expect(amount2).to.be.equal(0);
        })


        // it("member2 retire after same getClaimAmount", async () => {
        //     const block = await ethers.provider.getBlock('latest')
        //     // console.log("block.timestamp :", block.timestamp);
        //     let amount = await daoCommittee.getClaimableActivityReward(member2Addr)

        //     await daoCommittee.connect(member2Contract).retireMember();

        //     const block2 = await ethers.provider.getBlock('latest')
        //     // console.log("block2.timestamp :", block2.timestamp);
        //     let amount2 = await daoCommittee.getClaimableActivityReward(member2Addr)

        //     expect(amount2).to.be.gt(amount);
            
        //     let blockDiff = block2.timestamp-block.timestamp
        //     let activityRewardPerSecond = await daoCommittee.activityRewardPerSecond();
        //     // console.log("activityRewardPerSecond :", activityRewardPerSecond)
        //     let activityRewardPerSecondblockDiff = activityRewardPerSecond.mul(blockDiff)
        //     // console.log("activityRewardPerSecond10 :", activityRewardPerSecond10)
        //     let timeAddAmount = amount.add(activityRewardPerSecondblockDiff)
        //     expect(timeAddAmount).to.be.equal(amount2);
        // })

        // it("member2 changeMember member1 after same getClaimAmount", async () => {
        //     const block = await ethers.provider.getBlock('latest')
        //     let amount = await daoCommittee.getClaimableActivityReward(newMember1Addr)
            
        //     await daoCommittee.connect(member2Contract).changeMember(0);

        //     const block2 = await ethers.provider.getBlock('latest')
        //     let amount2 = await daoCommittee.getClaimableActivityReward(newMember1Addr)

        //     expect(amount2).to.be.gt(amount);
            
        //     let blockDiff = block2.timestamp-block.timestamp
        //     let activityRewardPerSecond = await daoCommittee.activityRewardPerSecond();
        //     let activityRewardPerSecondblockDiff = activityRewardPerSecond.mul(blockDiff)
        //     let timeAddAmount = amount.add(activityRewardPerSecondblockDiff)
        //     expect(timeAddAmount).to.be.equal(amount2);
        // })
    })
})
