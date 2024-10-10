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
const DAOCommitteeProxyABI = require("../../abi/DAOCommitteeProxy.json").abi;
const SeigManagerProxyABI = require("../../artifacts/contracts/stake/managers/SeigManagerProxy.sol/SeigManagerProxy.json").abi;
const SeigManagerABI = require("../../artifacts/contracts/stake/managers/SeigManager.sol/SeigManager.json").abi;

const DAOAgendaManagerABI = require("../../abi/daoAgendaManager.json").abi;
const DAOVaultABI = require("../../abi/DAOVault.json").abi;
const DAOCommitteeV1ABI = require("../../artifacts/contracts/dao/DAOCommittee_V1.sol/DAOCommittee_V1.json").abi;
const DepositManagerProxy_Json = require('../../abi/DepositManagerProxy.json')
const DepositManagerABI = require("../../artifacts/contracts/stake/managers/DepositManager.sol/DepositManager.json").abi;
const DepositManagerSetDelayABI = require("../../abi/DepositManager_setWithdrawalDelay.json")



describe("DAOAgenda Test", () => {

    let daoCommitteeAdmin;
    let daoCommitteeProxy;
    let daoCommitteeSigner;
    let testSetDeploy;
    // let daoCommitteeDAOVaultLogic;
    let daoCommitteeOwnerLogic;
    let ton;
    let wton;

    let daoCommittee;
    let daoCommitteeOwner;
    let daoagendaManager;
    let daovault;
    let depositManagerProxy;
    let depositManager;

    let testAddr = "f0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";
    let tonAddr = "2be5e8c109e2197D077D13A82dAead6a9b3433C5";
    let wtonAddr = "c4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2";
    let testZeroAddr = "0000000000000000000000000000000000000000";

    let member1;
    let member2;
    let member3;

    let member1Contract;
    let member2Contract;
    let member3Contract;

    let member1Addr = "0x39a13a796a3cd9f480c28259230d2ef0a7026033"
    let member2Addr = "0xd1820b18be7f6429f1f44104e4e15d16fb199a43"
    let member3Addr = "0x42adfaae7db56b294225ddcfebef48b337b34b23"

    let member1ContractAddr = "0x576c7a48fcef1c70db632bb1504d9a5c0d0190d3"
    // let member2ContractAddr = "0x42ccf0769e87cb2952634f607df1c7d62e0bbc52"
    let member2ContractAddr = "0x0F42D1C40b95DF7A1478639918fc358B4aF5298D"
    // let member3ContractAddr = "0x5d9a0646c46245a8a3b4775afb3c54d07bcb1764"
    let member3ContractAddr = "0x06D34f65869Ec94B3BA8c0E08BCEb532f65005E2"

    let beforeclaimAmount;
    let afterclaimAmount;

    let wtonCheck = "0xf0B595d10a92A5a9BC3fFeA7e79f5d266b6035Ea";

    let sendether = "0xDE0B6B3A7640000"

    let zeroAddr = "0x0000000000000000000000000000000000000000";
    let oneAddr = "0x0000000000000000000000000000000000000001";
    let twoAddr = "0x0000000000000000000000000000000000000002";
    let tosAddr = "0x409c4D8cd5d2924b9bc5509230d16a61289c8153";

    let depositManagerSetDelay;

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
        DAOCommitteeProxy: "0xDD9f0cCc044B0781289Ee318e5971b0139602C26",
        DepositManagerProxy : "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e"
    }

    const nowContractInfo = {
        TON: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
        WTON: "0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2",
        Layer2Registry: "0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b",
        DepositManager: "0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e",
        CoinageFactory: "",
        SeigManager: "0x0b55a0f463b6defb81c6063973763951712d0e5f",
    }

    let daoCommitteeDAOVaultLogic = "0xba5634e0c432af80060cf19e0940b59b2dc31173"
    let setDelayAddr = "0xAB9231f3081B5C3C27d34Ed4CEFc1280f89ff687" 

    before('create fixture loader', async () => {
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

    describe("Setting the DAOCommitteeDAOVault", () => {
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

        it("Deploy the TestSetDealy", async () => {
            const TestSetDealyDep = await ethers.getContractFactory("TestSetDealy");
            testSetDeploy = await TestSetDealyDep.deploy();

            await testSetDeploy.deployed();
        })

        it("Deploy & set the DepositManagerSetDealy Contract", async () => {
            let deploySetDelay = new ethers.ContractFactory(
                DepositManagerSetDelayABI.abi,
                DepositManagerSetDelayABI.bytecode,
                daoCommitteeAdmin
            )

            depositManagerSetDelay = await deploySetDelay.deploy();
        })

    })

    // describe("daoagendaManager Test", () => {
    //     it("set setImplementation2 ", async () => {
    //         const logicAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"

    //         const receipt0 = await (await depositManagerProxy.connect(daoCommitteeSigner).setImplementation2(
    //             logicAddress,
    //             1, 
    //             true
    //         )).wait()
    //         // console.log(receipt0)

    //         // console.log(receipt)
    //     })

    //     it("set setSelectorImplementations2", async () => {
    //         const selector1 = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
    //         const logicAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"

    //         const receipt = await (await depositManagerProxy.connect(daoCommitteeSigner).setSelectorImplementations2(
    //             [selector1], 
    //             logicAddress
    //         )).wait()
    //         // console.log(receipt)
    //     })
    // })

    describe("Setting Test", () => {
        it("DAOVault TON Addr check", async () => {
            let tonaddr = await daovault.ton();
            expect(tonaddr).to.be.equal(twoAddr)
        })

        it("DAOVault WTON Addr check", async () => {
            let wtonaddr = await daovault.wton();
            expect(wtonaddr).to.be.equal(twoAddr)
        })
    })

    describe("Agenda Test", () => {
        // it("DAO upgradeTo DAOVaultLogic", async () => {
        //     let imp1 = await daoCommitteeProxy.implementation()
        //     console.log('imp1', imp1)

        //     if(imp1.toLowerCase() != daoCommitteeDAOVaultLogic.toLowerCase()) {
        //         await (await daoCommitteeProxy.connect(daoCommitteeAdmin).upgradeTo(
        //             daoCommitteeDAOVaultLogic)).wait()
        //     }

        //     let imp2 = await daoCommitteeProxy.implementation()
        //     expect(imp2.toLowerCase()).to.be.equal(daoCommitteeDAOVaultLogic.toLowerCase())
        //     // console.log('imp2', imp2)
        //     console.log('upgradeTo done')
        // })

        it("set DAO NewLogic", async () => {
            daoCommittee = new ethers.Contract(
                daoCommitteeProxy.address,
                DAOCommitteeV1ABI,
                daoCommitteeAdmin
            )
        })

        it("Create new Agenda (setSelectorImplementations2)", async () => {
            const noticePeriod = await daoagendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoagendaManager.minimumVotingPeriodSeconds();
            // const bytes4value = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
            // // console.log("bytes4value :", bytes4value)
            // const selector = Web3EthAbi.encodeFunctionSignature("setSelectorImplementations2(bytes4[],address)");
            // const targetBytes4 = "dc5a709f";
            // const data1 = padLeft(targetBytes4.toString(), 64);
            // const data2 = padLeft(testZeroAddr.toString(), 64);
            // // const data1 = "0x0000000000000000000000000000000000000000000000000000000xdc5a709f"
            // // console.log("data1 :", data1)
            // // console.log("data2 :", data2)
            // const data = data1 + data2
            // const functionBytecode = selector.concat(data);
            // // const functionBytecode = "0x4a5df50f000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001dc5a709f00000000000000000000000000000000000000000000000000000000"
            // console.log("functionBytecode :", functionBytecode)
            
            let targets = [];
            let functionBytecodes = [];
            // const logicAddress = "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5"
            // const logicAddress = depositManagerSetDelay.address
            // const logicAddress = "0xAB9231f3081B5C3C27d34Ed4CEFc1280f89ff687"
            const logicAddress = setDelayAddr
            const selector1 = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
            //--------------

            const functionBytecode0 = depositManagerProxy.interface.encodeFunctionData(
                "setImplementation2", [logicAddress,1,true])
                // console.log("functionBytecode1 :", functionBytecode1);

            targets.push(nowContractInfo.DepositManager);
            functionBytecodes.push(functionBytecode0)

            //--------------
            const functionBytecode1 = depositManagerProxy.interface.encodeFunctionData(
                "setSelectorImplementations2", [[selector1],logicAddress])
                // console.log("functionBytecode1 :", functionBytecode1);

            // const selector1 = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
            // const functionBytecode1 = depositManagerProxy.interface.encodeFunctionData(
            //     "setSelectorImplementations2", [[selector1],logicAddress])
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
            // console.log("param : ", param)

            // const param = "0x00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000151800000000000000000000000000000000000000000000000000000000000002a3000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000b58ca72b12f01fc05f8f252e226f3e2089bd00e0000000000000000000000000b58ca72b12f01fc05f8f252e226f3e2089bd00e0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000647cd5f6630000000000000000000000002be5e8c109e2197d077d13a82daead6a9b3433c5000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000844a5df50f00000000000000000000000000000000000000000000000000000000000000400000000000000000000000002be5e8c109e2197d077d13a82daead6a9b3433c50000000000000000000000000000000000000000000000000000000000000001a818d6510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    
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
            // expect(executionInfo[0][0]).to.be.equal(oldContractInfo.DepositManagerProxy);
            // expect(executionInfo[1][0]).to.be.equal(functionBytecode);
        })

        it('increase block time and check votable', async function () {
            const agenda = await daoagendaManager.agendas(agendaID);  
            // console.log(agenda)
            // const noticeEndTimestamp = agenda[AGENDA_INDEX_NOTICE_END_TIMESTAMP];
            const noticeEndTimestamp = agenda[1];
            // console.log("noticeEndTimestamp :", noticeEndTimestamp);;
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

        it("setAgendaStatus test (Owner)", async () => {    
            expect(await daoagendaManager.getAgendaStatus(agendaID)).to.be.equal(2);
            //setAgendaStatus(_agendaID,_status, _result)
            //_status = 3 -> AGENDA_STATUS_WAITING_EXEC
            //_result = 1 -> AGENDA_RESULT_ACCEPTED
            await daoCommittee.connect(daoCommitteeAdmin).setAgendaStatus(
                agendaID,
                3,
                1
            );

            expect(await daoagendaManager.getAgendaStatus(agendaID)).to.be.equal(3);
            let getResult = await daoagendaManager.getAgendaResult(agendaID)
            // console.log(getResult);
            expect(Number(getResult.result)).to.be.equal(1);
        })

        it("check vote result/status & increase can ExecuteTime", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            // console.log(agenda)
            // console.log("agenda Result :", agenda[10])
            // console.log("agenda status :", agenda[11])

            let votingEndTime = await daoagendaManager.getAgendaVotingEndTimeSeconds(agendaID)
            // console.log("agenda[4] :",  agenda[4])
            // console.log("votingEndTime :",  votingEndTime)

            if (agenda[10] == 3) {
                const votingEndTimestamp = agenda[4];
                const currentTime = await time.latest();
                if (currentTime < votingEndTimestamp) {
                    await time.increaseTo(Number(votingEndTimestamp));
                }
                expect(await daoagendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
            }
        });

        
        it("execute agenda (anyone)", async () => {
            const agenda = await daoagendaManager.agendas(agendaID);
            const agendaInfo = await daoagendaManager.getExecutionInfo(agendaID);
            expect(agenda[6]).to.be.equal(0);
            // console.log("agendaInfo : ", agendaInfo)            
            await (await daoCommittee.executeAgenda(agendaID)).wait();;

            const afterAgenda = await daoagendaManager.agendas(agendaID); 
            const afterAgendaInfo = await daoagendaManager.getExecutionInfo(agendaID); 
            // console.log("afterAgendaInfo : ", afterAgendaInfo)            
            expect(afterAgenda[13]).to.be.equal(true);
            expect(afterAgenda[6]).to.be.gt(0); 
        })

        it("set depositManager", async () => {
            depositManager = new ethers.Contract(
                nowContractInfo.DepositManager,  
                DepositManagerABI, 
                daoCommitteeAdmin
            )
        })

        it("need revert depositManagerProxy setWithdrawalDelay", async () => {
            await expect(
                depositManager.connect(member2).setWithdrawalDelay(
                    member2ContractAddr,
                    316000
                )
            ).to.be.revertedWith("Not acceptable")

            // await depositManager.connect(member2).setWithdrawalDelay(
            //     member2ContractAddr,
            //     316000
            // )

            let getAmount = await depositManager.withdrawalDelay(member2ContractAddr)
            // console.log(getAmount);
            expect(getAmount).to.be.equal(0);
        })

        it("check getSelector", async () => {
            const selector1 = Web3EthAbi.encodeFunctionSignature("setWithdrawalDelay(address,uint256)");
            console.log("selector1", selector1);
            let logic = await depositManagerProxy.getSelectorImplementation2(selector1)
            let logic2 = await depositManagerProxy.implementation2(1)
            expect(logic).to.be.equal(logic2)
            expect(logic).to.be.equal(setDelayAddr)
        })
        

    })
})