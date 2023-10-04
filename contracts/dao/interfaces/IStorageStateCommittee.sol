// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ICandidateFactory } from "../interfaces/ICandidateFactory.sol";
import { ILayer2Registry } from "../interfaces/ILayer2Registry.sol";
import { ISeigManager } from "../interfaces/ISeigManager.sol";
import { IDAOAgendaManager } from "../interfaces/IDAOAgendaManager.sol";
import { IDAOVault } from "../interfaces/IDAOVault.sol";

interface IStorageStateCommittee {
    struct CandidateInfo {
        address candidateContract;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    function ton() external returns (address);
    function daoVault() external returns (IDAOVault);
    function agendaManager() external returns (IDAOAgendaManager);
    function candidateFactory() external returns (ICandidateFactory);
    function layer2Registry() external returns (ILayer2Registry);
    function seigManager() external returns (ISeigManager);
    function candidates(uint256 _index) external returns (address);
    function members(uint256 _index) external returns (address);
    function maxMember() external returns (uint256);
    function candidateInfos(address _candidate) external returns (CandidateInfo memory);
    function quorum() external returns (uint256);
    function activityRewardPerSecond() external returns (uint256);

    function isMember(address _candidate) external returns (bool);
    function candidateContract(address _candidate) external returns (address);
}


