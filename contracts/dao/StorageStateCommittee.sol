// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IStorageStateCommittee } from "./interfaces/IStorageStateCommittee.sol";
import { ICandidateFactory } from "./interfaces/ICandidateFactory.sol";
import { ILayer2Registry } from "./interfaces/ILayer2Registry.sol";
import { ISeigManager } from "./interfaces/ISeigManager.sol";
import { IDAOAgendaManager } from "./interfaces/IDAOAgendaManager.sol";
import { IDAOVault } from "./interfaces/IDAOVault.sol";
import { ICandidate } from "./interfaces/ICandidate.sol";

contract StorageStateCommittee is IStorageStateCommittee {
    enum AgendaStatus { NONE, NOTICE, VOTING, EXEC, ENDED, PENDING, RISK }
    enum AgendaResult { UNDEFINED, ACCEPT, REJECT, DISMISS }

    address public override ton;
    IDAOVault public override daoVault;
    IDAOAgendaManager public override agendaManager;
    ICandidateFactory public override candidateFactory;
    ILayer2Registry public override layer2Registry;
    ISeigManager public override seigManager;

    address[] public override candidates;
    address[] public override members;
    uint256 public override maxMember;

    // candidate EOA => candidate information
    mapping(address => CandidateInfo) internal _candidateInfos;
    uint256 public override quorum;

    uint256 public override activityRewardPerSecond;

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

    function isMember(address _candidate) public view override returns (bool) {
        return _candidateInfos[_candidate].memberJoinedTime > 0;
    }

    function candidateContract(address _candidate) public view override returns (address) {
        return _candidateInfos[_candidate].candidateContract;
    }

    function candidateInfos(address _candidate) external view override returns (CandidateInfo memory) {
        return _candidateInfos[_candidate];
    }

    /*function getCandidate() public view returns (address) {
        ILayer2(_candidateContract).
    }*/
}
