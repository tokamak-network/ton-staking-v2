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

import "hardhat/console.sol";

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

interface ITarget {
    function setLayer2Manager(address layer2Manager_) external;
    function setL2Registry(address l2Registry_) external;
    function setLayer2StartBlock(uint256 startBlock_) external;
    function setImplementation2(address newImplementation, uint256 index, bool alive) external;
    function setSelectorImplementations2(
        bytes4[] calldata _selectors,
        address _imp
    ) external;
}

/**
 * @notice Error that occurs when creating Candidate
 * @param x 1: deployed candidateContract is zero
 *          2: The candidate already has contract
 *          3: failed to registerAndDeployCoinage
 */
error CreateCandiateError(uint x);
error PermissionError();
error ZeroAddressError();

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

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender is not an admin");
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // setters
    function setLayer2CandidateFactory(address _layer2CandidateFactory) external onlyOwner {
        _nonZeroAddress(_layer2CandidateFactory);
        layer2CandidateFactory = _layer2CandidateFactory;
    }

    function setLayer2Manager(address _layer2CandidateFactory) external onlyOwner {
        _nonZeroAddress(_layer2CandidateFactory);
        layer2Manager = _layer2CandidateFactory;
    }

    function setTargetSetLayer2Manager(address target, address layer2Manager_) external onlyOwner {
        ITarget(target).setLayer2Manager(layer2Manager_);
    }

    function setTargetSetL2Registry(address target, address l2Registry_) external onlyOwner {
        ITarget(target).setL2Registry(l2Registry_);
    }

    function setTargetLayer2StartBlock(address target, uint256 startBlock_) external onlyOwner {
        ITarget(target).setLayer2StartBlock(startBlock_);
    }

    function setTargetSetImplementation2(
        address target, address newImplementation, uint256 index, bool alive) external onlyOwner {
        ITarget(target).setImplementation2(newImplementation, index, alive);
    }

    function setTargetSetSelectorImplementations2(
        address target, bytes4[] calldata _selectors, address _imp) external onlyOwner {
        ITarget(target).setSelectorImplementations2(_selectors, _imp);
    }

    //////////////////////////////////////////////////////////////////////
    //

    function createLayer2Candidate(string calldata _memo, address _operatorAddress)
        public
        returns (address)
    {
        if (msg.sender != layer2Manager) revert PermissionError();

        // Candidate
        address candidateContract = ILayer2CandidateFactory(layer2CandidateFactory).deploy(
            _operatorAddress,
            _memo,
            address(this),
            address(seigManager)
        );

        if (candidateContract == address(0)) revert CreateCandiateError(1);
        if (_candidateInfos[_operatorAddress].candidateContract != address(0)) revert CreateCandiateError(2);

        _candidateInfos[_operatorAddress] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_operatorAddress);

        if (!layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager))) revert CreateCandiateError(3);
        emit CandidateContractCreated(_operatorAddress, candidateContract, _memo);

        return candidateContract;
    }

    function _nonZeroAddress(address _addr) internal pure {
        if(_addr == address(0)) revert ZeroAddressError();
    }

}
