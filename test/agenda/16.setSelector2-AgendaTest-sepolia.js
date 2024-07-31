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
const SeigManagerV1ABI = require("../../artifacts/contracts/stake/managers/SeigManagerV1_1.sol/SeigManagerV1_1.json").abi;
const SeigManagerV3ABI = require("../../artifacts/contracts/stake/managers/SeigManagerV1_3.sol/SeigManagerV1_3.json").abi;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;

const CandidateABI = require("../../abi/Candidate.json").abi;

const Layer2ManagerABI = require("../../artifacts/contracts/layer2/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json").abi;

const DAOCommitteeV1ABI = require("../../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const DepositManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const DepositManagerABI = require("../../artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json").abi;


describe("DAOAgenda Test", () => {

    let daoCommitteeAdmin;
    let daoCommitteeAdminContract;
    let daoCommitteeProxy;
    // let daoCommitteeDAOVaultLogic;
    let daoCommitteeOwnerLogic;
    let ton;
    let wton;
    
    let depositManagerContract;
    let seigManagerContract;
    let seigManagerProxyContract;
    let seigManagerV1Contract;
    let seigManagerV3Contract;

    let daoCommittee;
    let daoCommitteeOwner;
    let daoagendaManager;
    let daovault;

    let testAddr = "f0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";
    let tonAddr = "a30fe40285b8f5c0457dbc3b7c8a280373c40044";
    let wtonAddr = "79e0d92670106c85e9067b56b8f674340dca0bbd";

    let pause_role = "0xfcb9fcbfa83b897fb2d5cf4b58962164105c1e71489a37ef3ae0db3fdce576f6"

    let member1;
    let member2;
    let member3;

    let talken;

    let member1Contract;
    let member2Contract;
    let member3Contract;
    let talkenContract;

    let member1ContractLogic;
    let member2ContractLogic;
    let member3ContractLogic;

    let talkenContractLogic;


    let member1Addr = "0xD4335A175c36c0922F6A368b83f9F6671bf07606"
    let member2Addr = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea"
    let member3Addr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"

    let member4Addr = "0xbc8896ebb2e3939b1849298ef8da59e09946cf66"

    // let newMember1Addr = "0xea8e2ec08dcf4971bdcdfffe21439995378b44f3"
    // let newMember1ContractAddr = "0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF"

    let member1ContractAddr = "0xaeB0463a2Fd96C68369C1347ce72997406Ed6409"
    let member2ContractAddr = "0xBdbB2C17846027c75802464d4aFdD23a9192E103"
    let member3ContractAddr = "0xAbD15C021942Ca54aBd944C91705Fe70FEA13f0d"

    let talkenAddr = "0xc1eba383D94c6021160042491A5dfaF1d82694E6"
    let talkenContractAddr = "0x277201BF0B20C672b023408Bf7778cFf3779b476"

    let seigManagerOwnerAddr = "0x757DE9c340c556b56f62eFaE859Da5e08BAAE7A2"
    let seigManagerOwner;

    let sendether = "0xDE0B6B3A7640000"

    let zeroAddr = "0x0000000000000000000000000000000000000000";
    let oneAddr = "0x0000000000000000000000000000000000000001";
    let twoAddr = "0x0000000000000000000000000000000000000002";

    let adminBytes = "0x0000000000000000000000000000000000000000000000000000000000000000"

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
        DAOCommitteeProxy: "0xA2101482b28E3D99ff6ced517bA41EFf4971a386",
        DepositManagerProxy: "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F"
    }

    const nowContractInfo = {
        TON: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
        WTON: "0x79e0d92670106c85e9067b56b8f674340dca0bbd",
        Layer2Registry: "0xA0a9576b437E52114aDA8b0BC4149F2F5c604581",
        DepositManager: "0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F",
        CoinageFactory: "",
        SeigManager: "0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7",
    }

    let minimumAmount = ethers.utils.parseUnits("1000", 18);

    let daoCommitteeLogic;

    let daoCommittee_V1_Contract;
    let daoCommittee_Owner_Contract;

    let daoCommitteeProxy2;
    let daoCommitteeProxy2Contract;

    let user1;
    // let user1Addr = "0x9FC3da866e7DF3a1c57adE1a97c9f00a70f010c8" //mainnet
    let user1Addr = "0x9b7E335088762aD8061C04D08C37902ABC8ACb87"
    let user1Contract;
    let user1ContractLogic;
    let user1ContractAddr;

    let user2;
    // let user2Addr = "0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97" //mainnet
    let user2Addr = "0x184ba627DB853244c9f17f3Cb4378cB8B39bf147"
    let user2Contract;
    let user2ContractLogic;
    let user2ContractAddr;

    let user3;
    let user3Addr = "0x6E1c4a442E9B9ddA59382ee78058650F1723E0F6";

    let agendaID;
    let beforeAgendaID;

    let layer2ManagerContract;
    let layer2ManagerAddr = "0x0237839A14194085B5145D1d1e1E77dc92aCAF06"

    let layer2CandidateFactoryAddr = "0x770739A468D9262960ee0669f9Eaf0db6E21F81A"

    let legacySystemConfigAddr = "0x1cA73f6E80674E571dc7a8128ba370b8470D4D87"

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
        // [daoCommitteeAdmin] = await ethers.getSigners();
        await hre.network.provider.send("hardhat_impersonateAccount", [
            daoAdminAddress,
        ]);
        daoCommitteeAdmin = await hre.ethers.getSigner(daoAdminAddress);
        
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

        await hre.network.provider.send("hardhat_impersonateAccount", [
            oldContractInfo.DAOCommitteeProxy,
        ]);

        await network.provider.send("hardhat_setBalance", [
            oldContractInfo.DAOCommitteeProxy,
            "0x10000000000000000000000000",
        ]);
        daoCommitteeSigner = await hre.ethers.getSigner(oldContractInfo.DAOCommitteeProxy);
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

        it("set depositManager", async () => {
            depositManagerProxy = new ethers.Contract(
                nowContractInfo.DepositManager,  
                DepositManagerProxy_Json.abi, 
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

        it("Set TalkenCandidateContract", async () => {
            talkenContractLogic = new ethers.Contract(
                talkenContractAddr,
                CandidateABI,
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

        it("Set SeigManagerProxy", async () => {
            seigManagerProxyContract = new ethers.Contract(
                nowContractInfo.SeigManager,
                SeigManagerProxyABI,
                daoCommitteeAdmin
            )
        })

        it("Set DepositManager", async () => {
            depositManagerContract = new ethers.Contract(
                nowContractInfo.DepositManager,
                DepositManagerABI,
                daoCommitteeAdmin
            )
        })

        it("Set SeigManagerV1", async () => {
            seigManagerV1Contract = new ethers.Contract(
                nowContractInfo.SeigManager,
                SeigManagerV1ABI,
                daoCommitteeAdmin
            )
        })

        it("Set SeigManagerV3", async () => {
            seigManagerV3Contract = new ethers.Contract(
                nowContractInfo.SeigManager,
                SeigManagerV3ABI,
                daoCommitteeAdmin
            )
        })

        it("Set Layer2Manager", async () => {
            layer2ManagerContract = new ethers.Contract(
                layer2ManagerAddr,
                Layer2ManagerABI,
                daoCommitteeAdmin
            )
        })

        it("set DAO NewLogic", async () => {
            daoCommittee = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommitteeV1ABI,
                daoCommitteeAdmin
            )
        })
    })

    describe("Agenda Test", () => {
        it("Create new Agenda (setSelectorImplementations2)", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            // const selector = Web3EthAbi.encodeFunctionSignature("setMinimumNoticePeriodSeconds(uint256)");
            // const newMinimumNoticePeriod = 30;
            // const data = padLeft(newMinimumNoticePeriod.toString(16), 64);
            // const functionBytecode = selector.concat(data);

            let targets = [];
            let functionBytecodes = [];
            const logicAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"
            const selector1 = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(bytes4[],address)");

            const functionBytecode0 = depositManagerProxy.interface.encodeFunctionData(
                "setImplementation2", [logicAddress,1,true])
                // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(nowContractInfo.DepositManager);
            functionBytecodes.push(functionBytecode0)

            //--------------
            const functionBytecode1 = depositManagerProxy.interface.encodeFunctionData(
                "setSelectorImplementations2", [[selector1],logicAddress])
                // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(nowContractInfo.DepositManager);
            functionBytecodes.push(functionBytecode1)

            const param = Web3EthAbi.encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    functionBytecodes
                ]
            )
    
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
            // expect(executionInfo[0][0]).to.be.equal(daoagendaManager.address);
            // expect(executionInfo[1][0]).to.be.equal(functionBytecode);
        })

        it('increase block time and check votable', async function () {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const noticeEndTimestamp = agenda[AGENDA_INDEX_NOTICE_END_TIMESTAMP];
            const noticeEndTimestamp = agenda[1];
            await time.increaseTo(Number(noticeEndTimestamp));
            expect(await daoagendaManager.isVotableStatus(agendaID)).to.be.equal(true);
        });

        it("cast vote (member2)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // const beforeCountingYes = agenda[AGENDA_INDEX_COUNTING_YES];
            const beforeCountingYes = agenda[7];
            const beforeCountingNo = agenda[8];
            const beforeCountingAbstain = agenda[9];
            
            const vote = 1
            
            // first cast not setting so check member
            let checkMember = await daoCommittee.isMember(member2Addr)
            expect(checkMember).to.be.equal(true)

            // counting 0:abstainVotes 1:yesVotes 2:noVotes
            await daoCommittee.connect(member2Contract).castVote(
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

    })

})
