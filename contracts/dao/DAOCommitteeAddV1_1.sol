// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICandidateFactory } from "./interfaces/ICandidateFactory.sol";

import { ICandidate } from "./interfaces/ICandidate.sol";
import { ILayer2 } from "./interfaces/ILayer2.sol";
import { IDAOAgendaManager } from "./interfaces/IDAOAgendaManager.sol";
import { LibAgenda } from "./lib/Agenda.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { AccessControl } from "../accessControl/AccessControl.sol";
import { ERC165A }  from "../accessControl/ERC165A.sol";

import "./StorageStateCommittee.sol";
import "./StorageStateCommitteeV2.sol";
import "./StorageStateCommitteeV3.sol";

contract DAOCommitteeAddV1_1 is
    StorageStateCommittee, AccessControl, ERC165A, StorageStateCommitteeV2, StorageStateCommitteeV3 {

    //////////////////////////////
    // Events
    //////////////////////////////

    event CandidateContractCreated(
        address indexed candidate,
        address indexed candidateContract,
        string memo
    );

    modifier onlyLayer2Manager() {
        require(msg.sender == layer2Manager, "DAOCommittee: msg.sender is not an admin");
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // setters

    //////////////////////////////////////////////////////////////////////
    //

    function createLayer2Candidate(string calldata _memo, address _operatorAddress)
        public
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
        onlyLayer2Manager
        returns (address)
    {
        // Candidate
        address candidateContract = candidateFactory.deploy(
            _operatorAddress,
            false,
            _memo,
            address(this),
            address(seigManager)
        );

        require(
            candidateContract != address(0),
            "DAOCommittee: deployed candidateContract is zero"
        );

        require(
            _candidateInfos[_operatorAddress].candidateContract == address(0),
            "DAOCommittee: The candidate already has contract"
        );

        _candidateInfos[_operatorAddress] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_operatorAddress);

        require(
            layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager)),
            "DAOCommittee: failed to registerAndDeployCoinage"
        );

        emit CandidateContractCreated(_operatorAddress, candidateContract, _memo);

        return candidateContract;
    }

}
