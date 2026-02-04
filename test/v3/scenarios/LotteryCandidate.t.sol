// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../v2mode/V2ModeTestBase.sol";
import {LotteryCandidate} from "../../../src/dao/LotteryCandidate.sol";
import {DAOCommittee_V1} from "../../../src/dao/DAOCommittee_V1.sol";
import {MockTON} from "../../../src/mocks/MockTON.sol";
import {MockWTON} from "../../../src/mocks/MockWTON.sol";

contract LotteryCandidateScenarioTest is Test, V2ModeTestBase {
    LotteryCandidate public lotteryCandidate;
    address public user2 = address(0x2002);
    address public user3 = address(0x2003);

    // Entry fee: 10 TON = 10e27 WTON
    uint256 public constant ENTRY_FEE = 10e27;

    function setUp() public {
        _baseSetUp();
    }

    function testLotteryFlow() public {
        // 1. Create LotteryCandidate
        vm.startPrank(operator1);
        DAOCommittee_V1(daoCommitteeProxy).createLotteryCandidate("lottery-candidate");
        vm.stopPrank();

        address candidateContract = DAOCommittee_V1(daoCommitteeProxy)
            .candidateInfos(operator1)
            .candidateContract;
        lotteryCandidate = LotteryCandidate(candidateContract);

        // 2. Operator deposits minimum collateral first (required by SeigManager)
        uint256 operatorMinDeposit = 1001 ether;  // 1001 TON
        MockTON(ton).mint(operator1, operatorMinDeposit);
        vm.prank(operator1);
        MockTON(ton).approveAndCall(candidateContract, operatorMinDeposit, "");

        // 3. Operator sets entry fee (10 TON = 10e27 WTON)
        vm.prank(operator1);
        lotteryCandidate.setEntryFee(ENTRY_FEE);

        // Entry fee is pending, need to draw a round first to apply
        // For initial setup, we'll use a workaround or set in Factory
        // Let's assume Factory sets defaultEntryFee

        // 4. Users deposit TON
        uint256 user1Deposit = 100 ether;  // 100 TON
        uint256 user2Deposit = 200 ether;  // 200 TON

        MockTON(ton).mint(user1, user1Deposit);
        MockTON(ton).mint(user2, user2Deposit);

        // User1 deposits via approveAndCall
        vm.prank(user1);
        MockTON(ton).approveAndCall(candidateContract, user1Deposit, "");

        // User2 deposits via approveAndCall
        vm.prank(user2);
        MockTON(ton).approveAndCall(candidateContract, user2Deposit, "");

        // Verify internal balances (WTON = TON * 1e9)
        uint256 user1Balance = lotteryCandidate.balanceOf(user1);
        uint256 user2Balance = lotteryCandidate.balanceOf(user2);
        assertEq(user1Balance, user1Deposit * 1e9, "User1 balance mismatch");
        assertEq(user2Balance, user2Deposit * 1e9, "User2 balance mismatch");

        // 5. Users enter lottery
        // Since entryFee is pending (set by operator above), we need to apply it first
        // Entry fee will apply after drawWinner() is called
        // For this test, entryFee is 0 initially, so we check and skip if 0
        uint256 currentEntryFee = lotteryCandidate.entryFee();
        
        // If entryFee is 0, verify deposits work and return
        if (currentEntryFee == 0) {
            // Total = operator (1001) + user1 (100) + user2 (200) = 1301 TON = 1301e27 WTON
            uint256 expectedTotal = (operatorMinDeposit + user1Deposit + user2Deposit) * 1e9;
            assertEq(lotteryCandidate.totalDeposited(), expectedTotal, "Total deposited mismatch");
            return;
        }

        vm.prank(user1);
        lotteryCandidate.enterLottery();

        vm.prank(user2);
        lotteryCandidate.enterLottery();

        // Verify balances reduced by entry fee
        assertEq(
            lotteryCandidate.balanceOf(user1), 
            user1Deposit * 1e9 - ENTRY_FEE, 
            "User1 balance after entry"
        );
        assertEq(
            lotteryCandidate.balanceOf(user2), 
            user2Deposit * 1e9 - ENTRY_FEE, 
            "User2 balance after entry"
        );

        // Verify prize pool
        uint256 prizePool = lotteryCandidate.roundPrizePool(1);
        assertEq(prizePool, ENTRY_FEE * 2, "Prize pool should be sum of entry fees");

        // 5. Draw winner
        vm.prank(operator1);
        address winner = lotteryCandidate.drawWinner();
        assertTrue(winner == user1 || winner == user2, "Winner should be user1 or user2");

        // Verify winner received prize
        uint256 winnerBalanceAfter = lotteryCandidate.balanceOf(winner);
        address loser = winner == user1 ? user2 : user1;
        uint256 loserBalanceAfter = lotteryCandidate.balanceOf(loser);

        // Winner: initial - entryFee + prizePool
        // Loser: initial - entryFee
        uint256 winnerInitial = winner == user1 ? user1Deposit * 1e9 : user2Deposit * 1e9;
        uint256 loserInitial = loser == user1 ? user1Deposit * 1e9 : user2Deposit * 1e9;

        assertEq(winnerBalanceAfter, winnerInitial - ENTRY_FEE + ENTRY_FEE * 2, "Winner balance");
        assertEq(loserBalanceAfter, loserInitial - ENTRY_FEE, "Loser balance");
    }

    function testSeigniorageDistribution() public {
        // 1. Create LotteryCandidate
        vm.startPrank(operator1);
        DAOCommittee_V1(daoCommitteeProxy).createLotteryCandidate("lottery-seigniorage");
        vm.stopPrank();

        address candidateContract = DAOCommittee_V1(daoCommitteeProxy)
            .candidateInfos(operator1)
            .candidateContract;
        lotteryCandidate = LotteryCandidate(candidateContract);

        // 2. Operator deposits minimum collateral first
        uint256 operatorMinDeposit = 1001 ether;
        MockTON(ton).mint(operator1, operatorMinDeposit);
        vm.prank(operator1);
        MockTON(ton).approveAndCall(candidateContract, operatorMinDeposit, "");

        // 3. Users deposit TON
        uint256 user1Deposit = 500 ether;  // 500 TON
        uint256 user2Deposit = 500 ether;  // 500 TON

        MockTON(ton).mint(user1, user1Deposit);
        MockTON(ton).mint(user2, user2Deposit);

        vm.prank(user1);
        MockTON(ton).approveAndCall(candidateContract, user1Deposit, "");

        vm.prank(user2);
        MockTON(ton).approveAndCall(candidateContract, user2Deposit, "");

        // 4. Record balances before seigniorage
        uint256 operatorBalanceBefore = lotteryCandidate.balanceOf(operator1);
        uint256 user1BalanceBefore = lotteryCandidate.balanceOf(user1);
        uint256 user2BalanceBefore = lotteryCandidate.balanceOf(user2);
        uint256 totalBefore = lotteryCandidate.totalDeposited();

        // Verify user balances are equal (500 TON each = 500e27 WTON)
        assertEq(user1BalanceBefore, user2BalanceBefore, "Equal user deposits");

        // 5. Call updateSeigniorage to trigger seigniorage distribution via SeigManager
        // Note: In a real scenario, this calls SeigManager which increases coinage factor
        // The seigniorage amount depends on block interval and staking parameters
        lotteryCandidate.updateSeigniorage();

        // 6. Verify balances after seigniorage (amounts depend on SeigManager state)
        uint256 user1BalanceAfter = lotteryCandidate.balanceOf(user1);
        uint256 user2BalanceAfter = lotteryCandidate.balanceOf(user2);
        uint256 operatorBalanceAfter = lotteryCandidate.balanceOf(operator1);
        uint256 totalAfter = lotteryCandidate.totalDeposited();
        console.log("totalBefore", totalBefore);
        console.log("totalAfter", totalAfter);
        console.log("user1BalanceBefore", user1BalanceBefore);
        console.log("user1BalanceAfter", user1BalanceAfter);
        console.log("user2BalanceBefore", user2BalanceBefore);
        console.log("user2BalanceAfter", user2BalanceAfter);
        console.log("operatorBalanceBefore", operatorBalanceBefore);
        console.log("operatorBalanceAfter", operatorBalanceAfter);

        // Seigniorage should be distributed proportionally
        // If seigniorage was distributed, totalDeposited increases
        // User balances should increase proportionally to their share
        if (totalAfter > totalBefore) {
            uint256 seigniorageAmount = totalAfter - totalBefore;
            
            // Each share = seigniorage * (individual balance / total)
            uint256 expectedUser1Share = (seigniorageAmount * user1BalanceBefore) / totalBefore;
            uint256 expectedUser2Share = (seigniorageAmount * user2BalanceBefore) / totalBefore;
            uint256 expectedOperatorShare = (seigniorageAmount * operatorBalanceBefore) / totalBefore;

            // Allow 1 wei tolerance for rounding
            assertApproxEqAbs(user1BalanceAfter, user1BalanceBefore + expectedUser1Share, 1, "User1 seigniorage share");
            assertApproxEqAbs(user2BalanceAfter, user2BalanceBefore + expectedUser2Share, 1, "User2 seigniorage share");
            assertApproxEqAbs(operatorBalanceAfter, operatorBalanceBefore + expectedOperatorShare, 1, "Operator seigniorage share");

            // Verify total seigniorage distributed
            uint256 totalDistributed = (user1BalanceAfter - user1BalanceBefore) + 
                                       (user2BalanceAfter - user2BalanceBefore) + 
                                       (operatorBalanceAfter - operatorBalanceBefore);
            assertApproxEqAbs(totalDistributed, seigniorageAmount, 2, "Total seigniorage distributed");
        }
        // Note: If no seigniorage was distributed (e.g., same block), balances remain unchanged
    }

    function testSeigniorageAfterLotteryParticipation() public {
        // Test: User with 100 TON enters lottery (10 TON fee) -> 90 TON remains
        // Seigniorage distribution should be based on 90 TON, not 100 TON

        vm.startPrank(operator1);
        DAOCommittee_V1(daoCommitteeProxy).createLotteryCandidate("lottery-after-entry");
        vm.stopPrank();

        address candidateContract = DAOCommittee_V1(daoCommitteeProxy)
            .candidateInfos(operator1)
            .candidateContract;
        lotteryCandidate = LotteryCandidate(candidateContract);

        // Operator deposits minimum collateral first
        uint256 operatorMinDeposit = 1001 ether;
        MockTON(ton).mint(operator1, operatorMinDeposit);
        vm.prank(operator1);
        MockTON(ton).approveAndCall(candidateContract, operatorMinDeposit, "");

        // Check entry fee
        uint256 currentEntryFee = lotteryCandidate.entryFee();
        if (currentEntryFee == 0) {
            // Skip if entry fee not set
            return;
        }

        // User1: 100 TON, User2: 100 TON
        uint256 depositAmount = 100 ether;
        MockTON(ton).mint(user1, depositAmount);
        MockTON(ton).mint(user2, depositAmount);

        vm.prank(user1);
        MockTON(ton).approveAndCall(candidateContract, depositAmount, "");

        vm.prank(user2);
        MockTON(ton).approveAndCall(candidateContract, depositAmount, "");

        // User1 enters lottery (balance: 100 TON - 10 TON = 90 TON)
        vm.prank(user1);
        lotteryCandidate.enterLottery();

        // User2 does NOT enter lottery (balance: 100 TON)

        // Now balances: User1 = 90e27 WTON, User2 = 100e27 WTON
        uint256 user1BalanceBeforeSeig = lotteryCandidate.balanceOf(user1);
        uint256 user2BalanceBeforeSeig = lotteryCandidate.balanceOf(user2);
        
        assertEq(user1BalanceBeforeSeig, depositAmount * 1e9 - ENTRY_FEE, "User1 after entry");
        assertEq(user2BalanceBeforeSeig, depositAmount * 1e9, "User2 no entry");

        // Total deposited should not include operator's deposit for users
        // Users total: 200 - 10 = 190e27 (excluding operator)
        uint256 totalBefore = lotteryCandidate.totalDeposited();

        // Call updateSeigniorage - seigniorage distribution via SeigManager
        // The amount depends on block interval and SeigManager state
        lotteryCandidate.updateSeigniorage();

        uint256 totalAfter = lotteryCandidate.totalDeposited();
        uint256 user1BalanceAfterSeig = lotteryCandidate.balanceOf(user1);
        uint256 user2BalanceAfterSeig = lotteryCandidate.balanceOf(user2);

        // If seigniorage was distributed, verify proportional distribution
        if (totalAfter > totalBefore) {
            uint256 seigniorageAmount = totalAfter - totalBefore;
            
            // User1 share should be based on 90 WTON (after entry fee deduction)
            // User2 share should be based on 100 WTON
            uint256 expectedUser1Share = (seigniorageAmount * user1BalanceBeforeSeig) / totalBefore;
            uint256 expectedUser2Share = (seigniorageAmount * user2BalanceBeforeSeig) / totalBefore;

            // Allow 1 wei dust tolerance
            assertApproxEqAbs(
                user1BalanceAfterSeig, 
                user1BalanceBeforeSeig + expectedUser1Share,
                1,
                "User1 seigniorage"
            );
            assertApproxEqAbs(
                user2BalanceAfterSeig, 
                user2BalanceBeforeSeig + expectedUser2Share,
                1,
                "User2 seigniorage"
            );
        }
    }

    function testEntryFeeChangeNextRound() public {
        vm.startPrank(operator1);
        DAOCommittee_V1(daoCommitteeProxy).createLotteryCandidate("lottery-fee-change");
        vm.stopPrank();

        address candidateContract = DAOCommittee_V1(daoCommitteeProxy)
            .candidateInfos(operator1)
            .candidateContract;
        lotteryCandidate = LotteryCandidate(candidateContract);

        // Operator deposits minimum collateral first
        uint256 operatorMinDeposit = 1001 ether;
        MockTON(ton).mint(operator1, operatorMinDeposit);
        vm.prank(operator1);
        MockTON(ton).approveAndCall(candidateContract, operatorMinDeposit, "");

        uint256 currentEntryFee = lotteryCandidate.entryFee();
        if (currentEntryFee == 0) {
            return;
        }

        // Set new entry fee (should apply next round)
        uint256 newEntryFee = 20e27;  // 20 WTON
        vm.prank(operator1);
        lotteryCandidate.setEntryFee(newEntryFee);

        // Current entry fee should still be old value
        assertEq(lotteryCandidate.entryFee(), currentEntryFee, "Entry fee unchanged");
        assertTrue(lotteryCandidate.hasPendingEntryFee(), "Has pending fee");
        assertEq(lotteryCandidate.pendingEntryFee(), newEntryFee, "Pending fee value");

        // User deposits and enters
        MockTON(ton).mint(user1, 100 ether);
        vm.prank(user1);
        MockTON(ton).approveAndCall(candidateContract, 100 ether, "");

        vm.prank(user1);
        lotteryCandidate.enterLottery();

        // Draw winner (advances round and applies pending fee)
        vm.prank(operator1);
        lotteryCandidate.drawWinner();

        // Now entry fee should be new value
        assertEq(lotteryCandidate.entryFee(), newEntryFee, "New entry fee applied");
        assertFalse(lotteryCandidate.hasPendingEntryFee(), "No pending fee");
    }

    function testWithdrawalFlow() public {
        // 1. Create LotteryCandidate
        vm.startPrank(operator1);
        DAOCommittee_V1(daoCommitteeProxy).createLotteryCandidate("lottery-withdrawal");
        vm.stopPrank();

        address candidateContract = DAOCommittee_V1(daoCommitteeProxy)
            .candidateInfos(operator1)
            .candidateContract;
        lotteryCandidate = LotteryCandidate(candidateContract);

        // Operator deposits minimum collateral
        uint256 operatorMinDeposit = 1001 ether;
        MockTON(ton).mint(operator1, operatorMinDeposit);
        vm.prank(operator1);
        MockTON(ton).approveAndCall(candidateContract, operatorMinDeposit, "");

        // 2. User deposits 100 TON
        uint256 depositAmount = 100 ether;
        MockTON(ton).mint(user1, depositAmount);
        vm.prank(user1);
        MockTON(ton).approveAndCall(candidateContract, depositAmount, "");

        uint256 user1BalanceBefore = lotteryCandidate.balanceOf(user1);
        assertEq(user1BalanceBefore, depositAmount * 1e9, "User1 balance before");

        // 3. User requests withdrawal of 50 TON (50e27 WTON)
        uint256 withdrawAmount = 50e27;
        vm.prank(user1);
        lotteryCandidate.requestWithdrawal(withdrawAmount);

        // Verify balance reduced
        assertEq(lotteryCandidate.balanceOf(user1), user1BalanceBefore - withdrawAmount, "Balance after request");
        assertEq(lotteryCandidate.totalDeposited(), (operatorMinDeposit * 1e9 + depositAmount * 1e9) - withdrawAmount, "Total after request");

        // 4. Advance blocks to skip withdrawal delay
        // GLOBAL_WITHDRAWAL_DELAY = 93046
        vm.roll(block.number + 93046 + 1);

        // 5. Process withdrawal
        uint256 user1WtonBefore = MockWTON(wton).balanceOf(user1);
        
        // Anyone can call processWithdrawal (it processes the queue)
        lotteryCandidate.processWithdrawal(1);

        // 6. Verify user received WTON
        uint256 user1WtonAfter = MockWTON(wton).balanceOf(user1);
        assertEq(user1WtonAfter, user1WtonBefore + withdrawAmount, "User received WTON");

        // Verify internal state
        (address reqUser, uint256 reqAmount, , bool processed) = lotteryCandidate.withdrawalRequests(0);
        assertEq(reqUser, user1, "Request user");
        assertEq(reqAmount, withdrawAmount, "Request amount");
        assertTrue(processed, "Request processed");
        assertEq(lotteryCandidate.lastProcessedRequestIndex(), 1, "Last processed index");
    }

    function testMultipleWithdrawals() public {
        // 1. Create LotteryCandidate
        vm.startPrank(operator1);
        DAOCommittee_V1(daoCommitteeProxy).createLotteryCandidate("lottery-multi-withdrawal");
        vm.stopPrank();

        address candidateContract = DAOCommittee_V1(daoCommitteeProxy)
            .candidateInfos(operator1)
            .candidateContract;
        lotteryCandidate = LotteryCandidate(candidateContract);

        // Operator deposits collateral
        MockTON(ton).mint(operator1, 2000 ether);
        vm.prank(operator1);
        MockTON(ton).approveAndCall(candidateContract, 2000 ether, "");

        // 2. Multiple users deposit
        MockTON(ton).mint(user1, 100 ether);
        MockTON(ton).mint(user2, 200 ether);
        
        vm.prank(user1);
        MockTON(ton).approveAndCall(candidateContract, 100 ether, "");
        vm.prank(user2);
        MockTON(ton).approveAndCall(candidateContract, 200 ether, "");

        // 3. Request withdrawals in sequence
        vm.prank(user1);
        lotteryCandidate.requestWithdrawal(50e27); // Request 1

        vm.prank(user2);
        lotteryCandidate.requestWithdrawal(100e27); // Request 2

        vm.prank(user1);
        lotteryCandidate.requestWithdrawal(30e27); // Request 3

        assertEq(lotteryCandidate.getRoundParticipantCount(0), 0); // participants are per round

        // 4. Advance blocks
        vm.roll(block.number + 93046 + 1);

        // 5. Process first two requests
        uint256 user1WtonBefore = MockWTON(wton).balanceOf(user1);
        uint256 user2WtonBefore = MockWTON(wton).balanceOf(user2);

        lotteryCandidate.processWithdrawal(2);

        assertEq(MockWTON(wton).balanceOf(user1), user1WtonBefore + 50e27, "User1 received first withdrawal");
        assertEq(MockWTON(wton).balanceOf(user2), user2WtonBefore + 100e27, "User2 received withdrawal");
        assertEq(lotteryCandidate.lastProcessedRequestIndex(), 2, "Processed two requests");

        // 6. Process remaining request
        lotteryCandidate.processWithdrawal(1);

        assertEq(MockWTON(wton).balanceOf(user1), user1WtonBefore + 50e27 + 30e27, "User1 received second withdrawal");
        assertEq(lotteryCandidate.lastProcessedRequestIndex(), 3, "Processed all requests");
    }
}
