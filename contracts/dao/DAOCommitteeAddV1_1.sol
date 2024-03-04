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

// import "hardhat/console.sol";

interface ILayer2CandidateFactory {
   function deploy(
        address _sender,
        string memory _name,
        address _committee,
        address _seigManager
    )
        external
        returns (address);
}

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
        require(msg.sender == layer2Manager, "sender is not a layer2Manager");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender is not an admin");
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "zero address");
        _;
    }
    //////////////////////////////////////////////////////////////////////
    // setters
    function setLayer2CandidateFactory(address _layer2CandidateFactory) external onlyOwner nonZeroAddress(_layer2CandidateFactory) {
        layer2CandidateFactory = _layer2CandidateFactory;
    }

    function setLayer2Manager(address _layer2CandidateFactory) external onlyOwner nonZeroAddress(_layer2CandidateFactory) {
        layer2Manager = _layer2CandidateFactory;
    }
    //////////////////////////////////////////////////////////////////////
    //

    function createLayer2Candidate(string calldata _memo, address _operatorAddress)
        public
        onlyLayer2Manager
        returns (address)
    {
        // Candidate
        address candidateContract = ILayer2CandidateFactory(layer2CandidateFactory).deploy(
            _operatorAddress,
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
