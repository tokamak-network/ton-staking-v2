// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICandidateFactory } from "./interfaces/ICandidateFactory.sol";

import { ICandidate } from "./interfaces/ICandidate.sol";
import { ILayer2 } from "./interfaces/ILayer2.sol";
import { IDAOAgendaManager } from "./interfaces/IDAOAgendaManager.sol";
import { ISeigManager } from "./interfaces/ISeigManager.sol";
import { ICoinage } from "./interfaces/ICoinage.sol";
import { ICandidateAddOnFactory } from "./interfaces/ICandidateAddOnFactory.sol";
import { LibAgenda } from "./lib/Agenda.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {AccessControl} from "../accessControl/AccessControl.sol";
import {ERC165A}  from "../accessControl/ERC165A.sol";

import "./StorageStateCommittee.sol";
import "./StorageStateCommitteeV2.sol";
import "./StorageStateCommitteeV3.sol";
import "./lib/BytesLib.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error ClaimTONError();
error ClaimWTONError();

contract DAOCommittee_V3 is
    StorageStateCommittee,
    AccessControl,
    ERC165A,
    StorageStateCommitteeV2,
    StorageStateCommitteeV3
{
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    bytes private constant claimTONBytes = hex"ef0d5594";
    bytes private constant claimERC20Bytes = hex"f848091a";
    bytes private constant claimWTONBytes = hex"f52bba70";

    enum CurrentResult { PENDING, ACCEPT, REJECT, DISMISS, NO_CONSENSUS, NO_AGENDA }
    enum CurrentStatus { NONE, NOTICE, VOTING, WAITING_EXEC, EXECUTED, ENDED, NO_AGENDA}

    struct AgendaCreatingData {
        address[] target;
        uint128 noticePeriodSeconds;
        uint128 votingPeriodSeconds;
        bool atomicExecute;
        bytes[] functionBytecode;
        string memo;
    }

    //////////////////////////////
    // Events
    //////////////////////////////

    event AgendaCreated(
        address indexed from,
        uint256 indexed id,
        address[] targets,
        uint128 noticePeriodSeconds,
        uint128 votingPeriodSeconds,
        bool atomicExecute
    );



    /// @notice This is the ApproveAndCall function that runs in the TON Contract. 
    ///         can create an Agenda through this function.
    /// @param owner Owner who created the function.
    /// @param data  Data containing the content to be executed in the corresponding function.
    /// @return Whether or not the execution succeeded
    function onApprove(
        address owner,
        address ,
        uint256 ,
        bytes calldata data
    ) external returns (bool) {
        require(msg.sender == ton, "It's not from TON");
        AgendaCreatingData memory agendaData = _decodeAgendaData(data);
        require(agendaData.target.length != 0, "need target");
        require(agendaData.atomicExecute, "atomicExecute need true");
        require(agendaData.target.length == agendaData.functionBytecode.length, "need same length");
        require(agendaData.votingPeriodSeconds >= agendaManager.minimumVotingPeriodSeconds(), "need over minimumVotingPeriodSeconds");

        for (uint256 i = 0; i < agendaData.target.length; i++) {
            if(agendaData.target[i] == address(daoVault)) {
                bytes memory abc = agendaData.functionBytecode[i];
                bytes memory selector1 = abc.slice(0, 4);

                if (selector1.equal(claimTONBytes)) revert ClaimTONError();
                else if (selector1.equal(claimERC20Bytes)) {
                    bytes memory tonaddr = _toBytes(ton);
                    bytes memory ercaddr = abc.slice(16, 20);
                    bool check3 = ercaddr.equal(tonaddr);
                    require(!check3, 'claimERC20 ton dont use');
                } else if (selector1.equal(claimWTONBytes)) {
                    revert ClaimWTONError();
                }
            }
        }

        _createAgenda(
            owner,
            agendaData.target,
            agendaData.noticePeriodSeconds,
            agendaData.votingPeriodSeconds,
            agendaData.atomicExecute,
            agendaData.functionBytecode,
            agendaData.memo
        );

        return true;
    }

    /// @notice Returns the current status and results for agendaID.
    /// @param _agendaID Owner who created the function.
    /// @return currentResult Current value of AgendaResult
    /// @return currentStatus Current value of AgendaStatus
    function currentAgendaStatus(uint256 _agendaID) external view returns (uint256 currentResult, uint256 currentStatus) {
        //Result -> 0: pending, 1: ACCEPT, 2: REJECT, 3: DISMISS, 4: NO CONSENSUS, 5: NO AGENDA
        //Status -> 0: NONE, 1: NOTICE, 2: VOTING, 3: WAITING_EXEC, 4: EXECUTED, 5: ENDED, 6: NO AGENDA
        uint256 numAgendas = agendaManager.numAgendas();
        if(numAgendas <=  _agendaID){
            // No Agenda
            // (NO AGENDA, NO AGENDA)
            return (5, 6);
        }

        uint256 noticeEndTime = agendaManager.getAgendaNoticeEndTimeSeconds(_agendaID);
        uint256 votingEndTime = agendaManager.getAgendaVotingEndTimeSeconds(_agendaID);
        
        if (block.timestamp < noticeEndTime) {
            //Notice Time
            //(PENDING, NOTICE)
            return (0, 1);
        } else if (noticeEndTime <= block.timestamp && votingEndTime == 0) {
            //NoticeTime은 지났지만 아무도 투표 안했을때
            //(NO CONSENSUS, VOTING)
            currentResult = 4;
            currentStatus = 2;
            return (currentResult, currentStatus);
        } else if (noticeEndTime <= block.timestamp &&  block.timestamp <= votingEndTime) {
            //NoticeTime이 지나고 누군가 투표 하였고 투표가 종료되지 않았을때
            (uint256 result,) = agendaManager.getAgendaResult(_agendaID);
            currentStatus = 2;
            return (result, currentStatus);
        } else if (votingEndTime < block.timestamp && votingEndTime != 0) {
            //votingEndTime이 지난뒤 결과
            (uint256 yes, uint256 no, uint256 abstain) = agendaManager.getVotingCount(_agendaID);
            if (quorum <= yes) {
                // yes
                (uint256 result, bool executed) = agendaManager.getAgendaResult(_agendaID);
                currentResult = result;
                if (executed) {
                    currentStatus = 4;
                } else {
                    currentStatus = 3;
                }
                return (currentResult, currentStatus);
            } else if (quorum <= no) {
                // no (REJECT, ENDED)
                currentResult = 2;
                currentStatus = 5;
                return (currentResult, currentStatus);
            } else if (quorum <= abstain) {
                // (DISMISS, ENDED)
                currentResult = 3;
                currentStatus = 5;
                return (currentResult, currentStatus);
            } else {
                // (NO CONSENSUS, ENDED)
                currentResult = 4;
                currentStatus = 5;
                return (currentResult, currentStatus);
            }
        }
    }

    // /// @notice Returns the current status and results for agendaID.
    // /// @param _agendaID The ID of the agenda to check.
    // /// @return currentResult Current agenda result (PENDING, ACCEPT, REJECT, DISMISS, NO_CONSENSUS, NO_AGENDA)
    // /// @return currentStatus Current agenda status (NONE, NOTICE, VOTING, WAITING_EXEC, EXECUTED, ENDED, NO_AGENDA)
    // function currentAgendaStatus(uint256 _agendaID) external view returns (CurrentResult currentResult, CurrentStatus currentStatus) {
    //     uint256 numAgendas = agendaManager.numAgendas();
    //     if(numAgendas <=  _agendaID){
    //         // No Agenda
    //         // (NO AGENDA, NO AGENDA)
    //         return (CurrentResult.NO_AGENDA, CurrentStatus.NO_AGENDA);
    //     }

    //     uint256 noticeEndTime = agendaManager.getAgendaNoticeEndTimeSeconds(_agendaID);
    //     if (block.timestamp < noticeEndTime) {
    //         //Notice Time
    //         //(PENDING, NOTICE)
    //         return (CurrentResult.PENDING, CurrentStatus.NOTICE);
    //     }

    //     uint256 votingEndTime = agendaManager.getAgendaVotingEndTimeSeconds(_agendaID);
    //     if (votingEndTime == 0) {
    //         //When the NoticeTime has passed but no one has voted
    //         //(NO CONSENSUS, VOTING)
    //         return (CurrentResult.NO_CONSENSUS, CurrentStatus.VOTING);
    //     }
        
    //     if (block.timestamp <= votingEndTime) {
    //         //When the NoticeTime has passed and someone has voted, but voting has not ended
    //         (uint256 result,) = agendaManager.getAgendaResult(_agendaID);
    //         return (CurrentResult(result), CurrentStatus.VOTING);
    //     }
        
    //     //Results after votingEndTime has passed
    //     (uint256 yes, uint256 no, uint256 abstain) = agendaManager.getVotingCount(_agendaID);
        
    //     if (quorum <= yes) {
    //         (uint256 result, bool executed) = agendaManager.getAgendaResult(_agendaID);
    //         if (executed) {
    //             return (CurrentResult(result), CurrentStatus.EXECUTED);
    //         } else {
    //             return (CurrentResult(result), CurrentStatus.WAITING_EXEC);
    //         }
    //     }

    //     if (quorum <= no) {
    //         // no (REJECT, ENDED)
    //         return (CurrentResult.REJECT, CurrentStatus.ENDED);
    //     }

    //     if (quorum <= abstain) {
    //         // (DISMISS, ENDED)
    //         return (CurrentResult.DISMISS, CurrentStatus.ENDED);
    //     }

    //     // (NO CONSENSUS, ENDED)
    //     return (CurrentResult.NO_CONSENSUS, CurrentStatus.ENDED);
    // }

    /// @notice decompose agendaData so that it can be used.
    /// @param input input the bytes data
    function _decodeAgendaData(bytes calldata input)
        internal
        pure
        returns (AgendaCreatingData memory data)
    {
        (data.target, data.noticePeriodSeconds, data.votingPeriodSeconds, data.atomicExecute, data.functionBytecode, data.memo) =
            abi.decode(input, (address[], uint128, uint128, bool, bytes[], string));
    }

    /// @notice Convert address to bytes.
    /// @param a address
    function _toBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /// @notice Create an agenda.
    /// @param _creator Agenda creator address
    /// @param _targets Target to execute through agenda
    /// @param _noticePeriodSeconds Notice period of agenda
    /// @param _votingPeriodSeconds Voting period of agenda
    /// @param _atomicExecute Single agenda or multi-agenda
    /// @param _functionBytecodes Functions to execute via agenda
    /// @param _memo This is a memo field and was added for snapshot linking.
    /// @return agendaID
    function _createAgenda(
        address _creator,
        address[] memory _targets,
        uint128 _noticePeriodSeconds,
        uint128 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] memory _functionBytecodes,
        string memory _memo
    )
        internal
        validAgendaManager
        returns (uint256)
    {
        // pay to create agenda, burn ton.
        _payCreatingAgendaFee(_creator);

        uint256 agendaID = agendaManager.newAgenda(
            _targets,
            _noticePeriodSeconds,
            _votingPeriodSeconds,
            _atomicExecute,
            _functionBytecodes
        );

        agendaMemo[agendaID] = _memo;

        emit AgendaCreated(
            _creator,
            agendaID,
            _targets,
            _noticePeriodSeconds,
            _votingPeriodSeconds,
            _atomicExecute
        );

        return agendaID;
    }

    /// @notice Pay the fee to create the agenda.
    /// @param _creator Address of the person who created the agenda
    function _payCreatingAgendaFee(address _creator) internal {
        uint256 fee = agendaManager.createAgendaFees();

        IERC20(ton).safeTransferFrom(_creator, address(this), fee);
        IERC20(ton).safeTransfer(address(1), fee);
    }


}