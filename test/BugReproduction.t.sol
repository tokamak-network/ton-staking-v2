// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/dao/DAOCommittee_V1.sol";
import "../src/dao/interfaces/IDAOAgendaManager.sol";

contract MockDAOCommittee is DAOCommittee_V1 {
    function setQuorum(uint256 _quorum) external {
        quorum = _quorum;
    }
    function setAgendaManager(address _agendaManager) external {
        agendaManager = IDAOAgendaManager(_agendaManager);
    }
}

contract BugReproductionTest is Test {
    MockDAOCommittee committee;
    address mockAgendaManager = makeAddr("agendaManager");

    function setUp() public {
        committee = new MockDAOCommittee();
        committee.setAgendaManager(mockAgendaManager);
        committee.setQuorum(3);
    }

    function test_currentAgendaStatus_incorrect_during_voting() public {
        uint256 agendaID = 11;
        uint256 noticeEndTime = 1000;
        uint256 votingEndTime = 2000;
        uint256 currentTime = 1500; // Middle of voting period
        
        vm.warp(currentTime);

        // Mocking agendaManager calls
        vm.mockCall(
            mockAgendaManager,
            abi.encodeWithSelector(IDAOAgendaManager.getAgendaNoticeEndTimeSeconds.selector, agendaID),
            abi.encode(noticeEndTime)
        );
        vm.mockCall(
            mockAgendaManager,
            abi.encodeWithSelector(IDAOAgendaManager.getAgendaVotingEndTimeSeconds.selector, agendaID),
            abi.encode(votingEndTime)
        );
        vm.mockCall(
            mockAgendaManager,
            abi.encodeWithSelector(IDAOAgendaManager.getVotingCount.selector, agendaID),
            abi.encode(0, 0, 0) // No votes yet
        );

        (uint256 result, uint256 status) = committee.currentAgendaStatus(agendaID);
        
        console.log("Current Time:", currentTime);
        console.log("Notice End:", noticeEndTime);
        console.log("Voting End:", votingEndTime);
        console.log("Result:", result);
        console.log("Status:", status);
        
        // Status 2 is LibAgenda.AgendaStatus.VOTING
        // Status 5 is LibAgenda.AgendaStatus.ENDED
        // Result 4 is LibAgenda.AgendaResult.NO_CONSENSUS
        
        // The bug is that it returns (4, 5) even if currentTime < votingEndTime
        assertEq(status, 2, "Status should be VOTING (2) during voting period, but it is not");
    }

    function test_currentAgendaStatus_noticeEndTime_edgeCase() public {
        uint256 agendaID = 12;
        uint256 noticeEndTime = 1000;
        uint256 votingEndTime = 2000;
        uint256 currentTime = 1000; // Exactly at noticeEndTime
        
        vm.warp(currentTime);

        // Mocking agendaManager calls
        vm.mockCall(
            mockAgendaManager,
            abi.encodeWithSelector(IDAOAgendaManager.getAgendaNoticeEndTimeSeconds.selector, agendaID),
            abi.encode(noticeEndTime)
        );
        vm.mockCall(
            mockAgendaManager,
            abi.encodeWithSelector(IDAOAgendaManager.getAgendaVotingEndTimeSeconds.selector, agendaID),
            abi.encode(votingEndTime)
        );
        vm.mockCall(
            mockAgendaManager,
            abi.encodeWithSelector(IDAOAgendaManager.getVotingCount.selector, agendaID),
            abi.encode(0, 0, 0)
        );

        (uint256 result, uint256 status) = committee.currentAgendaStatus(agendaID);
        
        console.log("Current Time:", currentTime);
        console.log("Notice End:", noticeEndTime);
        console.log("Result:", result);
        console.log("Status:", status);
        
        // Should be VOTING (2) at noticeEndTime
        assertEq(status, 2, "Status should be VOTING (2) at noticeEndTime");
    }
}
