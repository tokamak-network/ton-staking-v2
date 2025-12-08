import { expect } from './shared/expect'
import { ethers, network, getNamedAccounts } from 'hardhat'
import { BigNumber, Signer, Contract } from 'ethers'
import hre from 'hardhat'
import { jsonFixtures } from './shared/fixtures'
import DepositManagerProxy_Json from './abi/DepositManagerProxy.json'
import DepositManager_Dune_Json from './abi/DepositManager_Dune.json'
import {encodeFunctionSignature, encodeParameters} from 'web3-eth-abi'
import { time } from '@nomicfoundation/hardhat-network-helpers'
import DAOAgendaManager_Json from './abi/DAOAgendaManager.json'
import Candidate_Json from './abi/Candidate.json'
import DAOCommittee_V1_Json from './abi/DAOCommittee_.json'
import {
    STAKING_DECIMALS,
    roundDown,
    execAllowance,
    getActualStakeBalance,
    setupDeposit,
    setupWithdrawal,
    findEventInReceipt,
    expectStakeBalance
} from './shared/depositManagerHelpers'

describe('DepositManagerV1_2 - Agenda-based Registration Tests', () => {
    let deployer: Signer, addr1: Signer, addr2: Signer;
    let depositManagerV1_2: Contract;
    let depositManagerProxy: Contract;
    let wton: Contract;
    let seigManagerV2: Contract;
    let layer2Registry: Contract;
    let daoAgendaManager: Contract;
    let daoCommitteeProxy: Contract;
    let ton: Contract;
    let depositManagerV1_2Imp: Contract;
    let agendaID: BigNumber;
    let layer2Info: any;

    before('setup contracts for agenda test', async () => {
        [deployer, addr1, addr2] = await ethers.getSigners();

        // Get deployed contract addresses from hardhat config
        const {
            DepositManager, SeigManager, L2Registry, TON, WTON, DAOCommitteeProxy,
            DAOAgendaManager, CandidateFactory, DaoCommitteeAdminAddress,
            level19Address, level19Admin
        } = await getNamedAccounts();

        // Get contract ABIs
        const contractJson = await jsonFixtures();

        // Create contract instances from deployed addresses
        depositManagerProxy = new ethers.Contract(DepositManager, DepositManagerProxy_Json.abi, deployer);
        wton = new ethers.Contract(WTON, contractJson.WTON.abi, deployer);
        seigManagerV2 = new ethers.Contract(SeigManager, contractJson.SeigManager.abi, deployer);
        layer2Registry = new ethers.Contract(L2Registry, contractJson.L2Registry.abi, deployer);
        daoAgendaManager = new ethers.Contract(DAOAgendaManager, DAOAgendaManager_Json.abi, deployer);
        daoCommitteeProxy = new ethers.Contract(DAOCommitteeProxy, contractJson.DAOCommitteeProxy.abi, deployer);
        ton = new ethers.Contract(TON, contractJson.TON.abi, deployer);

        // Deploy DepositManagerV1_2 implementation
        const DepositManagerV1_2Factory = await ethers.getContractFactory("DepositManagerV1_2");
        depositManagerV1_2Imp = await DepositManagerV1_2Factory.deploy();

        // Use DepositManager_Dune.json ABI which includes all functions and events
        depositManagerV1_2 = new ethers.Contract(DepositManager, DepositManager_Dune_Json.abi, deployer);

        // Mint WTON for testing (using DAOCommitteeProxy as minter)
        await hre.network.provider.send("hardhat_impersonateAccount", [DAOCommitteeProxy]);
        await hre.network.provider.send("hardhat_setBalance", [
            DAOCommitteeProxy,
            "0x10000000000000000000000000",
        ]);
        const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);
        await wton.connect(daoAdmin).mint(await deployer.getAddress(), ethers.utils.parseEther("10000" + "0".repeat(9)));

        // Use fixed level layer2 address
        const layer2Address = "0x0F42D1C40b95DF7A1478639918fc358B4aF5298D";
        layer2Info = {
            operatorAdmin: level19Admin,
            layer2: layer2Address,
            operator: level19Admin
        };

        // Verify layer2 is registered in Layer2Registry
        const isRegistered = await layer2Registry.layer2s(layer2Address);
        if (!isRegistered) {
            throw new Error(`Layer2 ${layer2Address} is not registered in Layer2Registry. Please use an existing registered layer2.`);
        }
    });

    describe('Agenda Creation and Execution', () => {
        let daoCommitteeContract: Contract;
        let tonHave: Signer;
        let tonHaveAddr: string;

        before('setup tonHave for agenda creation', async () => {
            const {
                DAOCommitteeProxy
            } = await getNamedAccounts();

            // Try to get tonHave from named accounts, otherwise use a hardcoded address or deployer
            try {
                const accounts = await getNamedAccounts();
                tonHaveAddr = (accounts as any).tonHave;
            } catch (e) {
                // If tonHave is not in named accounts, use deployer
                tonHaveAddr = await deployer.getAddress();
            }

            // If still no address, use a known address or deployer
            if (!tonHaveAddr) {
                tonHaveAddr = await deployer.getAddress();
            }

            // Impersonate and fund the address
            await hre.network.provider.send("hardhat_impersonateAccount", [tonHaveAddr]);
            await hre.network.provider.send("hardhat_setBalance", [
                tonHaveAddr,
                "0x10000000000000000000000000",
            ]);
            tonHave = await hre.ethers.getSigner(tonHaveAddr);

            // Ensure tonHave has enough TON for agenda fee
            const agendaFee = await daoAgendaManager.createAgendaFees();
            const tonBalance = await ton.balanceOf(tonHaveAddr);
            if (tonBalance.lt(agendaFee)) {
                await hre.network.provider.send("hardhat_impersonateAccount", [DAOCommitteeProxy]);
                await hre.network.provider.send("hardhat_setBalance", [
                    DAOCommitteeProxy,
                    "0x10000000000000000000000000",
                ]);
                const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);
                await ton.connect(daoAdmin).mint(tonHaveAddr, agendaFee.mul(2));
            }
        });

        it('should ensure DAOCommitteeProxy is admin of DepositManagerProxy', async () => {
            const {
                DAOCommitteeProxy
            } = await getNamedAccounts();

            const isAdmin = await depositManagerProxy.isAdmin(DAOCommitteeProxy);
            if (!isAdmin) {
                await hre.network.provider.send("hardhat_impersonateAccount", [DAOCommitteeProxy]);
                await hre.network.provider.send("hardhat_setBalance", [
                    DAOCommitteeProxy,
                    "0x10000000000000000000000000",
                ]);
                const daoAdmin = await hre.ethers.getSigner(DAOCommitteeProxy);
                await depositManagerProxy.connect(daoAdmin).addAdmin(DAOCommitteeProxy);
            }
            expect(await depositManagerProxy.isAdmin(DAOCommitteeProxy)).to.be.equal(true);
        });

        it('should create agenda to register DepositManagerV1_2', async () => {

            const noticePeriod = await daoAgendaManager.minimumNoticePeriodSeconds();
            const votingPeriod = await daoAgendaManager.minimumVotingPeriodSeconds();
            const agendaFee = await daoAgendaManager.createAgendaFees();

            // Prepare agenda data
            const targets: string[] = [];
            const params: string[] = [];

            // 1. setImplementation2
            const implementationIndex = 3;
            const callData0 = depositManagerProxy.interface.encodeFunctionData(
                "setImplementation2",
                [depositManagerV1_2Imp.address, implementationIndex, true]
            );
            targets.push(depositManagerProxy.address);
            params.push(callData0);

            // 2. setSelectorImplementations2
            const selector1 = encodeFunctionSignature("redeposit(address)");
            const selector2 = encodeFunctionSignature("redepositMulti(address,uint256)");
            const redepositSelectors = [selector1, selector2];
            const callData1 = depositManagerProxy.interface.encodeFunctionData(
                "setSelectorImplementations2",
                [redepositSelectors, depositManagerV1_2Imp.address]
            );
            targets.push(depositManagerProxy.address);
            params.push(callData1);

            // Encode parameters for approveAndCall
            const param = encodeParameters(
                ["address[]", "uint128", "uint128", "bool", "bytes[]"],
                [
                    targets,
                    noticePeriod.toString(),
                    votingPeriod.toString(),
                    true,
                    params
                ]
            );

            // Create agenda
            const receipt = await (await ton.connect(tonHave).approveAndCall(
                daoCommitteeProxy.address,
                agendaFee,
                param
            )).wait();

            agendaID = (await daoAgendaManager.numAgendas()).sub(1);
            const executionInfo = await daoAgendaManager.getExecutionInfo(agendaID);
            expect(agendaID).to.not.be.undefined;
        }).timeout(100000000);

        it('should wait for notice period and make agenda votable', async () => {
            expect(agendaID).to.not.be.undefined;
            const agenda = await daoAgendaManager.agendas(agendaID);
            const noticeEndTimestamp = agenda[1];
            await time.increaseTo(Number(noticeEndTimestamp));
            expect(await daoAgendaManager.isVotableStatus(agendaID)).to.be.equal(true);
        });

        it('should vote on agenda', async () => {
            expect(agendaID).to.not.be.undefined;
            const {
                DAOCommitteeProxy,
                daoMember1,
                daoMember2
            } = await getNamedAccounts();

            daoCommitteeContract = new ethers.Contract(DAOCommitteeProxy, DAOCommittee_V1_Json.abi, deployer);

            const agenda = await daoAgendaManager.agendas(agendaID);
            const beforeCountingYes = agenda.countingYes;
            const beforeCountingNo = agenda.countingNo;
            const beforeCountingAbstain = agenda.countingAbstain;

            const vote = 1; // 1 = yes

            // Get candidate addresses
            const daoMember1Contract = new ethers.Contract(daoMember1, Candidate_Json.abi, deployer);
            const daoMember2Contract = new ethers.Contract(daoMember2, Candidate_Json.abi, deployer);

            const daoMember1CandidateAddress = await daoMember1Contract.candidate();
            const daoMember2CandidateAddress = await daoMember2Contract.candidate();

            let checkMember = await daoCommitteeContract.isMember(daoMember1CandidateAddress);
            expect(checkMember).to.be.equal(true);
            checkMember = await daoCommitteeContract.isMember(daoMember2CandidateAddress);
            expect(checkMember).to.be.equal(true);

            // Impersonate candidate addresses
            await network.provider.send("hardhat_impersonateAccount", [daoMember1CandidateAddress]);
            await network.provider.send("hardhat_setBalance", [daoMember1CandidateAddress, "0x10000000000000000000000000"]);
            await network.provider.send("hardhat_impersonateAccount", [daoMember2CandidateAddress]);
            await network.provider.send("hardhat_setBalance", [daoMember2CandidateAddress, "0x10000000000000000000000000"]);

            const daoMember1Signer = await ethers.getSigner(daoMember1CandidateAddress);
            const daoMember2Signer = await ethers.getSigner(daoMember2CandidateAddress);

            // Cast votes
            await (await daoMember1Contract.connect(daoMember1Signer).castVote(
                agendaID,
                vote,
                "member1 vote"
            )).wait();

            let agendaInfo = await daoAgendaManager.agendas(agendaID);
            expect(agendaInfo.countingYes).to.be.equal(Number(beforeCountingYes) + 1);
            expect(agendaInfo.countingNo).to.be.equal(Number(beforeCountingNo));
            expect(agendaInfo.countingAbstain).to.be.equal(Number(beforeCountingAbstain));
            expect(agendaInfo.status).to.be.equal(2); // VOTING

            await (await daoMember2Contract.connect(daoMember2Signer).castVote(
                agendaID,
                vote,
                "member2 vote"
            )).wait();

            agendaInfo = await daoAgendaManager.agendas(agendaID);
            expect(agendaInfo.countingYes).to.be.equal(Number(beforeCountingYes) + 2);
            expect(agendaInfo.countingNo).to.be.equal(Number(beforeCountingNo));
            expect(agendaInfo.countingAbstain).to.be.equal(Number(beforeCountingAbstain));
            expect(agendaInfo.status).to.be.equal(3); // WAITING_EXEC
            expect(agendaInfo.result).to.be.equal(1); // ACCEPT

            const voterInfo1 = await daoAgendaManager.voterInfos(agendaID, daoMember1CandidateAddress);
            expect(voterInfo1.hasVoted).to.be.equal(true);
            expect(voterInfo1.vote).to.be.equal(vote);

            const voterInfo2 = await daoAgendaManager.voterInfos(agendaID, daoMember2CandidateAddress);
            expect(voterInfo2.hasVoted).to.be.equal(true);
            expect(voterInfo2.vote).to.be.equal(vote);
        });

        it('should wait for voting period before executing', async () => {
            expect(agendaID).to.not.be.undefined;
            const votingEndTime = await daoAgendaManager.getAgendaVotingEndTimeSeconds(agendaID);
            await time.increaseTo(Number(votingEndTime));
            expect(await daoAgendaManager.canExecuteAgenda(agendaID)).to.be.equal(true);
        });

        it('should execute agenda', async () => {
            expect(agendaID).to.not.be.undefined;
            let agenda = await daoAgendaManager.agendas(agendaID);
            expect(agenda.executedTimestamp).to.be.equal(0);
            expect(agenda.executed).to.be.equal(false);

            await (await daoCommitteeContract.executeAgenda(agendaID)).wait();

            agenda = await daoAgendaManager.agendas(agendaID);
            expect(agenda.executedTimestamp).to.be.gt(0);
            expect(agenda.executed).to.be.equal(true);
        });

        it('should verify DepositManagerV1_2 is registered after agenda execution', async () => {
            expect(agendaID).to.not.be.undefined;
            const selector1 = encodeFunctionSignature("redeposit(address)");
            const selector2 = encodeFunctionSignature("redepositMulti(address,uint256)");

            // Check selector implementations
            const impl1 = await depositManagerProxy.getSelectorImplementation2(selector1);
            const impl2 = await depositManagerProxy.getSelectorImplementation2(selector2);
            expect(impl1.toLowerCase()).to.be.eq(depositManagerV1_2Imp.address.toLowerCase());
            expect(impl2.toLowerCase()).to.be.eq(depositManagerV1_2Imp.address.toLowerCase());
        });
    });

    describe('Functionality Tests After Agenda Registration', () => {
        let layer2: string;
        let account: Signer;
        let wtonAmount: BigNumber;
        let withdrawalAmount: BigNumber;

        before('setup', async () => {
            layer2 = layer2Info.layer2;
            account = addr1;
            wtonAmount = ethers.utils.parseEther("100" + "0".repeat(9));
        });

        it('should emit WithdrawalRequestCanceled event after agenda registration', async () => {
            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, wtonAmount);
            withdrawalAmount = await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, wtonAmount);

            const tx = await depositManagerV1_2.connect(account).redeposit(layer2);
            const receipt = await tx.wait();

            const depositedEvent = findEventInReceipt(depositManagerV1_2, receipt, 'Deposited');
            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');

            expect(depositedEvent).to.not.be.null;
            expect(canceledEvent).to.not.be.null;

            if (depositedEvent && canceledEvent) {
                expect(depositedEvent.args.amount).to.be.eq(withdrawalAmount);
                expect(canceledEvent.args.amount).to.be.eq(withdrawalAmount);
                expect(depositedEvent.args.layer2.toLowerCase()).to.be.eq(canceledEvent.args.layer2.toLowerCase());
                expect(depositedEvent.args.depositor.toLowerCase()).to.be.eq(canceledEvent.args.depositor.toLowerCase());
            }
        });

        it('should emit both Deposited and WithdrawalRequestCanceled events for redeposit after agenda', async () => {
            const newWtonAmount = ethers.utils.parseEther("50" + "0".repeat(9));
            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, newWtonAmount);
            await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, newWtonAmount);

            const tx = await depositManagerV1_2.connect(account).redeposit(layer2);
            const receipt = await tx.wait();

            const depositedEvent = findEventInReceipt(depositManagerV1_2, receipt, 'Deposited');
            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');

            expect(depositedEvent).to.not.be.null;
            expect(canceledEvent).to.not.be.null;

            if (depositedEvent && canceledEvent) {
                expect(depositedEvent.args.amount).to.be.eq(newWtonAmount);
                expect(canceledEvent.args.amount).to.be.eq(newWtonAmount);
                expect(depositedEvent.args.layer2.toLowerCase()).to.be.eq(canceledEvent.args.layer2.toLowerCase());
                expect(depositedEvent.args.depositor.toLowerCase()).to.be.eq(canceledEvent.args.depositor.toLowerCase());
            }
        });

        it('should emit both Deposited and WithdrawalRequestCanceled events for redepositMulti after agenda', async () => {
            const amount1 = ethers.utils.parseEther("10" + "0".repeat(9));
            const amount2 = ethers.utils.parseEther("20" + "0".repeat(9));
            const totalAmount = amount1.add(amount2);

            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, totalAmount);

            const actualStakeBalanceMulti = await getActualStakeBalance(seigManagerV2, layer2, account);
            const withdrawalAmount1 = actualStakeBalanceMulti.lt(amount1) ? actualStakeBalanceMulti : amount1;
            const remainingBalance = actualStakeBalanceMulti.sub(withdrawalAmount1);
            const withdrawalAmount2 = remainingBalance.lt(amount2) ? remainingBalance : amount2;

            await depositManagerV1_2.connect(account)["requestWithdrawal(address,uint256)"](layer2, withdrawalAmount1);
            await depositManagerV1_2.connect(account)["requestWithdrawal(address,uint256)"](layer2, withdrawalAmount2);

            const tx = await depositManagerV1_2.connect(account).redepositMulti(layer2, 2);
            const receipt = await tx.wait();

            const depositedEvent = findEventInReceipt(depositManagerV1_2, receipt, 'Deposited');
            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');

            expect(depositedEvent).to.not.be.null;
            expect(canceledEvent).to.not.be.null;

            if (depositedEvent && canceledEvent) {
                const expectedAmount = withdrawalAmount1.add(withdrawalAmount2);
                expect(depositedEvent.args.amount).to.be.eq(expectedAmount);
                expect(canceledEvent.args.amount).to.be.eq(expectedAmount);
                expect(depositedEvent.args.layer2.toLowerCase()).to.be.eq(canceledEvent.args.layer2.toLowerCase());
                expect(depositedEvent.args.depositor.toLowerCase()).to.be.eq(canceledEvent.args.depositor.toLowerCase());
            }
        });

        it('should correctly track net pending withdrawals after redeposit', async () => {
            // Get initial balance to account for previous test deposits
            const initialStakeBalance = await getActualStakeBalance(seigManagerV2, layer2, account);
            const initialPendingUnstaked = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());

            const testAmount = ethers.utils.parseEther("200" + "0".repeat(9));
            await setupDeposit(wton, depositManagerV1_2, deployer, account, layer2, testAmount);

            const stakedAfterDeposit = await getActualStakeBalance(seigManagerV2, layer2, account);
            // Check that the increase matches the deposit amount (accounting for rounding)
            const stakeIncrease = stakedAfterDeposit.sub(initialStakeBalance);
            expectStakeBalance(stakeIncrease, testAmount);

            const pendingUnstakedBefore = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());
            expect(pendingUnstakedBefore).to.be.eq(initialPendingUnstaked);

            const testWithdrawalAmount = await setupWithdrawal(depositManagerV1_2, seigManagerV2, account, layer2, testAmount);

            const pendingUnstakedAfterRequest = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());
            expect(pendingUnstakedAfterRequest).to.be.eq(pendingUnstakedBefore.add(testWithdrawalAmount));

            const stakedBeforeRedeposit = await getActualStakeBalance(seigManagerV2, layer2, account);
            const pendingUnstakedBeforeRedeposit = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());

            const tx = await depositManagerV1_2.connect(account).redeposit(layer2);
            const receipt = await tx.wait();

            const canceledEvent = findEventInReceipt(depositManagerV1_2, receipt, 'WithdrawalRequestCanceled');
            expect(canceledEvent).to.not.be.null;

            const stakedAfterRedeposit = await getActualStakeBalance(seigManagerV2, layer2, account);
            const pendingUnstakedAfterRedeposit = await depositManagerV1_2.pendingUnstaked(layer2, await account.getAddress());

            // Check that stake increased by the withdrawal amount (using expectStakeBalance for rounding tolerance)
            expectStakeBalance(stakedAfterRedeposit, stakedBeforeRedeposit.add(testWithdrawalAmount));
            expect(pendingUnstakedAfterRedeposit).to.be.eq(pendingUnstakedBeforeRedeposit.sub(testWithdrawalAmount));
        });
    });
});

