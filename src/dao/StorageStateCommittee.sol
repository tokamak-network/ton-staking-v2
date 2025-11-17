// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import { IStorageStateCommittee } from "./interfaces/IStorageStateCommittee.sol";
import { ICandidateFactory } from "./interfaces/ICandidateFactory.sol";
import { ILayer2Registry } from "./interfaces/ILayer2Registry.sol";
import { ISeigManager } from "./interfaces/ISeigManager.sol";
import { IDAOAgendaManager } from "./interfaces/IDAOAgendaManager.sol";
import { IDAOVault } from "./interfaces/IDAOVault.sol";
import { ICandidate } from "./interfaces/ICandidate.sol";

contract StorageStateCommittee  {
    enum AgendaStatus { NONE, NOTICE, VOTING, EXEC, ENDED, PENDING, RISK }
    enum AgendaResult { UNDEFINED, ACCEPT, REJECT, DISMISS }
    struct CandidateInfo {
        address candidateContract;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    address public ton;
    IDAOVault public daoVault;
    IDAOAgendaManager public agendaManager;
    ICandidateFactory public candidateFactory;
    ILayer2Registry public layer2Registry;
    ISeigManager public seigManager;

    address[] public candidates;
    address[] public members;
    uint256 public maxMember;

    // candidate EOA => candidate information
    mapping(address => CandidateInfo) internal _candidateInfos;
    uint256 public quorum;

    uint256 public activityRewardPerSecond;

    modifier validAgendaManager() {
        require(address(agendaManager) != address(0), "StorageStateCommittee: AgendaManager is zero");
        _;
    }

    modifier validCommitteeL2Factory() {
        require(address(candidateFactory) != address(0), "StorageStateCommittee: invalid CommitteeL2Factory");
        _;
    }

    modifier validLayer2Registry() {
        require(address(layer2Registry) != address(0), "StorageStateCommittee: invalid Layer2Registry");
        _;
    }

    modifier validSeigManager() {
        require(address(seigManager) != address(0), "StorageStateCommittee: invalid SeigManagere");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "StorageStateCommittee: not a member");
        _;
    }

    modifier onlyMemberContract() {
        address candidate = ICandidate(msg.sender).candidate();
        require(isMember(candidate), "StorageStateCommittee: not a member");
        _;
    }

    function isMember(address _candidate) public view returns (bool) {
        return _candidateInfos[_candidate].memberJoinedTime > 0;
    }

    function candidateContract(address _candidate) public view returns (address) {
        return _candidateInfos[_candidate].candidateContract;
    }

    function candidateInfos(address _candidate) external view returns (CandidateInfo memory) {
        return _candidateInfos[_candidate];
    }

    /*function getCandidate() public view returns (address) {
        ILayer2(_candidateContract).
    }*/
}
