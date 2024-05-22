// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICandidateFactory } from "./interfaces/ICandidateFactory.sol";

import { ICandidate } from "./interfaces/ICandidate.sol";
import { ILayer2 } from "./interfaces/ILayer2.sol";
import { IDAOAgendaManager } from "./interfaces/IDAOAgendaManager.sol";
import { LibAgenda } from "./lib/Agenda.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {AccessControl} from "../accessControl/AccessControl.sol";
import {ERC165A}  from "../accessControl/ERC165A.sol";

import "./StorageStateCommittee.sol";
import "../proxy/ProxyStorage2.sol";
import "./StorageStateCommitteeV2.sol";
import "./lib/BytesLib.sol";

import "hardhat/console.sol";

interface IISeigManager {
    function coinages(address layer2) external view returns (address);
    function getOperatorAmount(address layer2) external view returns (uint256);
    function minimumAmount() external view returns (uint256);
}

interface IICoinage {
    function balanceOf(address account) external view returns (uint256);
}

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

contract DAOCommittee_V1 is 
    StorageStateCommittee, 
    AccessControl, 
    ERC165A, 
    ProxyStorage2, 
    StorageStateCommitteeV2 
{
    using BytesLib for bytes;

    bytes constant claimTONBytes = hex"ef0d5594";
    bytes constant claimERC20Bytes = hex"f848091a";
    bytes constant claimWTONBytes = hex"f52bba70";

    enum ApplyResult { NONE, SUCCESS, NOT_ELECTION, ALREADY_COMMITTEE, SLOT_INVALID, ADDMEMBER_FAIL, LOW_BALANCE }

    struct AgendaCreatingData {
        address[] target;
        uint128 noticePeriodSeconds;
        uint128 votingPeriodSeconds;
        bool atomicExecute;
        bytes[] functionBytecode;
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

    event AgendaVoteCasted(
        address indexed from,
        uint256 indexed id,
        uint256 voting,
        string comment
    );

    event AgendaExecuted(
        uint256 indexed id,
        address[] target
    );

    event CandidateContractCreated(
        address indexed candidate,
        address indexed candidateContract,
        string memo
    );

    event Layer2Registered(
        address indexed candidate,
        address indexed candidateContract,
        string memo
    );

    event ChangedMember(
        uint256 indexed slotIndex,
        address prevMember,
        address indexed newMember
    );

    event ClaimedActivityReward(
        address indexed candidate,
        address receiver,
        uint256 amount
    );

    event ChangedMemo(
        address candidate,
        string newMemo
    );

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DAOCommittee: msg.sender is not an admin");
        _;
    }

    modifier validMemberIndex(uint256 _index) {
        require(_index < maxMember, "DAOCommittee: invalid member index");
        _;
    }

    modifier nonZero(address _addr) {
        require(_addr != address(0), "DAOCommittee: zero address");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC165A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyLayer2Manager() {
        require(msg.sender == layer2Manager, "sender is not a layer2Manager");
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // Managing members
    function createCandidate(string calldata _memo)
        external
    {
        address _operator = msg.sender;
        require(!isExistCandidate(_operator), "DAOCommittee: candidate already registerd");

        // Candidate
        address candidateContract = candidateFactory.deploy(
            _operator,
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
            _candidateInfos[_operator].candidateContract == address(0),
            "DAOCommittee: The candidate already has contract"
        );
        require(
            layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager)),
            "DAOCommittee: failed to registerAndDeployCoinage"
        );

        _candidateInfos[_operator] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_operator);

        emit CandidateContractCreated(_operator, candidateContract, _memo);

    }

    function createCandidateOwner(string calldata _memo, address _operatorAddress)
        public
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
        onlyOwner
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

        if(_candidateInfos[_operatorAddress].candidateContract != address(0) ) {

            require(_oldCandidateInfos[_operatorAddress].candidateContract == address(0), "already migrated");

            _oldCandidateInfos[_operatorAddress] = CandidateInfo2({
                candidateContract: _candidateInfos[_operatorAddress].candidateContract,
                newCandidate: candidateContract,
                memberJoinedTime: _candidateInfos[_operatorAddress].memberJoinedTime,
                indexMembers: _candidateInfos[_operatorAddress].indexMembers,
                rewardPeriod: _candidateInfos[_operatorAddress].rewardPeriod,
                claimedTimestamp: _candidateInfos[_operatorAddress].claimedTimestamp
            });

            _candidateInfos[_operatorAddress].candidateContract = candidateContract;

        } else {

            _candidateInfos[_operatorAddress] = CandidateInfo({
                candidateContract: candidateContract,
                memberJoinedTime: 0,
                indexMembers: 0,
                rewardPeriod: 0,
                claimedTimestamp: 0
            });

            candidates.push(_operatorAddress);
        }

        require(
            layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager)),
            "DAOCommittee: failed to registerAndDeployCoinage"
        );

        emit CandidateContractCreated(_operatorAddress, candidateContract, _memo);
    }

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

    /// @notice Replaces an existing member
    /// @param _memberIndex The member slot index to be replaced
    /// @return Whether or not the execution succeeded
    function changeMember(
        uint256 _memberIndex
    )
        external
        validMemberIndex(_memberIndex)
        returns (bool)
    {
        address newMember = ICandidate(msg.sender).candidate();
        uint256 operatorAmount = operatorAmountCheck(msg.sender,newMember);
        console.log("operatorAmount :", operatorAmount);
        uint256 minimumAmount = IISeigManager(address(seigManager)).minimumAmount();
        console.log("minimumAmount :", minimumAmount);
        require(operatorAmount >= minimumAmount, "need more operatorDeposit");

        CandidateInfo storage candidateInfo = _candidateInfos[newMember];
        require(
            ICandidate(msg.sender).isCandidateContract(),
            "DAOCommittee: sender is not a candidate contract"
        );
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );
        require(
            candidateInfo.memberJoinedTime == 0,
            "DAOCommittee: already member"
        );

        address prevMember = members[_memberIndex];
        address prevMemberContract = candidateContract(prevMember);

        candidateInfo.memberJoinedTime = uint128(block.timestamp);
        candidateInfo.indexMembers = _memberIndex;

        members[_memberIndex] = newMember;

        if (prevMember == address(0)) {
            emit ChangedMember(_memberIndex, prevMember, newMember);
            return true;
        }

        require(
            ICandidate(msg.sender).totalStaked() > ICandidate(prevMemberContract).totalStaked(),
            "not enough amount"
        );

        CandidateInfo storage prevCandidateInfo = _candidateInfos[prevMember];
        prevCandidateInfo.indexMembers = 0;
        if (prevCandidateInfo.memberJoinedTime > prevCandidateInfo.claimedTimestamp) {
            prevCandidateInfo.rewardPeriod += (uint128(block.timestamp) - prevCandidateInfo.memberJoinedTime);
        } else {
            prevCandidateInfo.rewardPeriod += (uint128(block.timestamp) - prevCandidateInfo.claimedTimestamp);
        }
        prevCandidateInfo.memberJoinedTime = 0;

        emit ChangedMember(_memberIndex, prevMember, newMember);

        return true;
    }

    /// @notice Retires member
    /// @return Whether or not the execution succeeded
    function retireMember() onlyMemberContract external returns (bool) {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );
        members[candidateInfo.indexMembers] = address(0);
        if (candidateInfo.memberJoinedTime > candidateInfo.claimedTimestamp) {
            candidateInfo.rewardPeriod += (uint128(block.timestamp) - candidateInfo.memberJoinedTime);
        } else {
            candidateInfo.rewardPeriod += (uint128(block.timestamp) - candidateInfo.claimedTimestamp);
        }
        candidateInfo.memberJoinedTime = 0;

        uint256 prevIndex = candidateInfo.indexMembers;
        candidateInfo.indexMembers = 0;
        emit ChangedMember(prevIndex, candidate, address(0));

        return true;
    }

    function setMemoOnCandidate(
        address _candidate,
        string calldata _memo
    )
        external
    {
        address candidateContract = candidateContract(_candidate);
        setMemoOnCandidateContract(candidateContract, _memo);
    }

    /// @notice Set memo
    /// @param _candidateContract candidate contract address
    /// @param _memo New memo on this candidate
    function setMemoOnCandidateContract(
        address _candidateContract,
        string calldata _memo
    )
        public
    {
        address candidate = ICandidate(_candidateContract).candidate();
        address contractOwner = candidate;
        if (ICandidate(_candidateContract).isLayer2Candidate()) {
            contractOwner = ILayer2(candidate).operator();
        }
        require(
            msg.sender == contractOwner,
            "DAOCommittee: sender is not the candidate of this contract"
        );

        ICandidate(_candidateContract).setMemo(_memo);
        emit ChangedMemo(candidate, _memo);
    }

    //////////////////////////////////////////////////////////////////////
    // Managing agenda

    function onApprove(
        address owner,
        address ,
        uint256 ,
        bytes calldata data
    ) external returns (bool) {
        require(msg.sender == ton, "It's not from TON");
        AgendaCreatingData memory agendaData = _decodeAgendaData(data);
         
        for (uint256 i = 0; i < agendaData.target.length; i++) {
            if(agendaData.target[i] == address(daoVault)) {
                bytes memory abc = agendaData.functionBytecode[i];
                bytes memory selector1 = abc.slice(0, 4);

                if (selector1.equal(claimTONBytes)) revert('claimTON dont use');
                else if (selector1.equal(claimERC20Bytes)) {
                    bytes memory tonaddr = toBytes(ton);
                    bytes memory ercaddr = abc.slice(16, 20);
                    bool check3 = ercaddr.equal(tonaddr);
                    require(!check3, 'claimERC20 ton dont use');
                } else if (selector1.equal(claimWTONBytes)) {
                    revert('claimWTON dont use');
                }
            }
        }

        _createAgenda(
            owner,
            agendaData.target,
            agendaData.noticePeriodSeconds,
            agendaData.votingPeriodSeconds,
            agendaData.atomicExecute,
            agendaData.functionBytecode
        );

        return true;
    }

    /// @notice Vote on an agenda
    /// @param _agendaID The agenda ID
    /// @param _vote voting type
    /// @param _comment voting comment
    function castVote(
        uint256 _agendaID,
        uint256 _vote,
        string calldata _comment
    )
        external
        validAgendaManager
    {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );

        agendaManager.castVote(
            _agendaID,
            candidate,
            _vote
        );

        (uint256 yes, uint256 no, uint256 abstain) = agendaManager.getVotingCount(_agendaID);

        if (quorum <= yes) {
            // yes
            agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.ACCEPT);
            agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.WAITING_EXEC);
        } else if (quorum <= no) {
            // no
            agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.REJECT);
            agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
        } else if (quorum <= abstain + no) {
            // dismiss
            agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.DISMISS);
            agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
        }

        emit AgendaVoteCasted(msg.sender, _agendaID, _vote, _comment);
    }

    /// @notice Set the agenda status as ended(denied or dismissed)
    /// @param _agendaID Agenda ID
    function endAgendaVoting(uint256 _agendaID) external {
        agendaManager.endAgendaVoting(_agendaID);
    }

    /// @notice Execute the accepted agenda
    /// @param _agendaID Agenda ID
    function executeAgenda(uint256 _agendaID) external validAgendaManager {
        require(
            agendaManager.canExecuteAgenda(_agendaID),
            "DAOCommittee: can not execute the agenda"
        );

         (address[] memory target,
             bytes[] memory functionBytecode,
             bool atomicExecute,
             uint256 executeStartFrom
         ) = agendaManager.getExecutionInfo(_agendaID);

        if (atomicExecute) {
            agendaManager.setExecutedAgenda(_agendaID);
            for (uint256 i = 0; i < target.length; i++) {
                (bool success, ) = address(target[i]).call(functionBytecode[i]);
                require(success, "DAOCommittee: Failed to execute the agenda");
            }
        } else {
            uint256 succeeded = 0;
            for (uint256 i = executeStartFrom; i < target.length; i++) {
                bool success = _call(target[i], functionBytecode[i].length, functionBytecode[i]);
                if (success) {
                    succeeded = succeeded + 1;
                } else {
                    break;
                }
            }

            agendaManager.setExecutedCount(_agendaID, succeeded);
            if (executeStartFrom + succeeded == target.length) {
                agendaManager.setExecutedAgenda(_agendaID);
            }
        }

        emit AgendaExecuted(_agendaID, target);
    }

    /// @notice Set status and result of specific agenda
    /// @param _agendaID Agenda ID
    /// @param _status New status
    /// @param _result New result
    function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) external onlyOwner {
        agendaManager.setResult(_agendaID, LibAgenda.AgendaResult(_result));
        agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus(_status));
    }

    /// @notice Call updateSeigniorage on SeigManager
    /// @param _candidate Candidate address to be updated
    /// @return Whether or not the execution succeeded
    function updateSeigniorage(address _candidate) public returns (bool) {
        address candidateContract = _candidateInfos[_candidate].candidateContract;
        return ICandidate(candidateContract).updateSeigniorage();
    }

    /// @notice Claims the activity reward for member
    function claimActivityReward(address _receiver) external {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );
        uint256 amount = getClaimableActivityReward(candidate);
        require(amount > 0, "DAOCommittee: you don't have claimable wton");

        uint256 wtonAmount = _toRAY(amount);
        daoVault.claimERC20(wton,_receiver, wtonAmount);
        candidateInfo.claimedTimestamp = uint128(block.timestamp);
        candidateInfo.rewardPeriod = 0;

        emit ClaimedActivityReward(candidate, _receiver, wtonAmount);
    }

    function _toRAY(uint256 v) public pure returns (uint256) {
        return v * 10 ** 9;
    }

    function fillMemberSlot() internal {
        for (uint256 i = members.length; i < maxMember; i++) {
            members.push(address(0));
        }
    }

    function _decodeAgendaData(bytes calldata input)
        internal
        pure
        returns (AgendaCreatingData memory data)
    {
        (data.target, data.noticePeriodSeconds, data.votingPeriodSeconds, data.atomicExecute, data.functionBytecode) =
            abi.decode(input, (address[], uint128, uint128, bool, bytes[]));
    }

    function toBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function byteToUnit256(bytes memory reason) internal pure returns (uint256) {
        if (reason.length != 32) {
            if (reason.length < 68) revert('Unexpected error');
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (uint256));
    }

    function payCreatingAgendaFee(address _creator) internal {
        uint256 fee = agendaManager.createAgendaFees();

        require(IERC20(ton).transferFrom(_creator, address(this), fee), "DAOCommittee: failed to transfer ton from creator");
        require(IERC20(ton).transfer(address(1), fee), "DAOCommittee: failed to burn");
    }

    function _createAgenda(
        address _creator,
        address[] memory _targets,
        uint128 _noticePeriodSeconds,
        uint128 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] memory _functionBytecodes
    )
        internal
        validAgendaManager
        returns (uint256)
    {
        // pay to create agenda, burn ton.
        payCreatingAgendaFee(_creator);

        uint256 agendaID = agendaManager.newAgenda(
            _targets,
            _noticePeriodSeconds,
            _votingPeriodSeconds,
            _atomicExecute,
            _functionBytecodes
        );

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

    function _call(address target, uint256 paramLength, bytes memory param) internal returns (bool) {
        bool result;
        assembly {
            let data := add(param, 32)
            result := call(sub(gas(), 40000), target, 0, data, paramLength, 0, 0)
        }

        return result;
    }

    function isCandidate(address _candidate) external view returns (bool) {
        CandidateInfo storage info = _candidateInfos[_candidate];

        if (info.candidateContract == address(0)) {
            return false;
        }

        bool supportIsCandidateContract = ERC165Checker.supportsInterface(
            info.candidateContract,
            ICandidate(info.candidateContract).isCandidateContract.selector
        );

        if (supportIsCandidateContract == false) {
            return false;
        }

        return ICandidate(info.candidateContract).isCandidateContract();
    }

    function totalSupplyOnCandidate(
        address _candidate
    )
        external
        view
        returns (uint256 totalsupply)
    {
        address candidateContract = candidateContract(_candidate);
        return totalSupplyOnCandidateContract(candidateContract);
    }

    function balanceOfOnCandidate(
        address _candidate,
        address _account
    )
        external
        view
        returns (uint256 amount)
    {
        address candidateContract = candidateContract(_candidate);
        return balanceOfOnCandidateContract(candidateContract, _account);
    }

    function totalSupplyOnCandidateContract(
        address _candidateContract
    )
        public
        view
        returns (uint256 totalsupply)
    {
        require(_candidateContract != address(0), "This account is not a candidate");

        return ICandidate(_candidateContract).totalStaked();
    }

    function balanceOfOnCandidateContract(
        address _candidateContract,
        address _account
    )
        public
        view
        returns (uint256 amount)
    {
        require(_candidateContract != address(0), "This account is not a candidate");

        return ICandidate(_candidateContract).stakedOf(_account);
    }

    function candidatesLength() external view returns (uint256) {
        return candidates.length;
    }

    function isExistCandidate(address _candidate) public view returns (bool isExist) {
        return _candidateInfos[_candidate].candidateContract != address(0);
    }

    function getClaimableActivityReward(address _candidate) public view returns (uint256) {
        CandidateInfo storage info = _candidateInfos[_candidate];
        uint256 period = info.rewardPeriod;

        if (info.memberJoinedTime > 0) {
            if (info.memberJoinedTime > info.claimedTimestamp) {
                period = period + block.timestamp - info.memberJoinedTime;
            } else {
                period = period + block.timestamp - info.claimedTimestamp;
            }
        }

        return period * activityRewardPerSecond;
    }

    function getOldCandidateInfos(address _oldCandidate) public view returns (CandidateInfo2 memory) {
        return _oldCandidateInfos[_oldCandidate];
    }

    function operatorAmountCheck(address layer2,address operator) public view returns (uint256 operatorAmount) {
        address coinage = IISeigManager(address(seigManager)).coinages(layer2); 
        operatorAmount = IICoinage(coinage).balanceOf(operator);
    }
}