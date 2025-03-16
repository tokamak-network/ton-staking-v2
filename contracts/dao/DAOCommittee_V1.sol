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
import "./lib/BytesLib.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Error that occurs when creating Candidate
 * @param x 1: deployed candidateContract is zero
 *          2: The candidate already has contract
 *          3: failed to registerAndDeployCoinage
 */
error CreateCandiateError(uint x);
error PermissionError();
error ZeroAddressError();
error ClaimTONError();
error ClaimWTONError();

contract DAOCommittee_V1 is
    StorageStateCommittee,
    AccessControl,
    ERC165A,
    StorageStateCommitteeV2
{
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    bytes private constant claimTONBytes = hex"ef0d5594";
    bytes private constant claimERC20Bytes = hex"f848091a";
    bytes private constant claimWTONBytes = hex"f52bba70";

    enum ApplyResult { NONE, SUCCESS, NOT_ELECTION, ALREADY_COMMITTEE, SLOT_INVALID, ADD_MEMBER_FAIL, LOW_BALANCE }

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
        address candidateContract,
        string newMemo
    );

    event MemberBlacklisted(
        address indexed member,
        uint256 timestamp
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
        bytes4 onApproveInterfaceId = bytes4(keccak256("onApprove(address,address,uint256,bytes)"));
        return interfaceId == onApproveInterfaceId || super.supportsInterface(interfaceId);
    }

    modifier onlyLayer2Manager() {
        require(msg.sender == layer2Manager, "sender is not a layer2Manager");
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // Managing members
    function removeFromBlacklist(address _candidate) external onlyOwner {
        require(blacklist[_candidate], "Not blacklisted");
        blacklist[_candidate] = false;
    }

    function createCandidate(string calldata _memo)
        external
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
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
            CandidateInfo storage candidateInfo = _candidateInfos[_operatorAddress];
            CandidateInfo2 storage oldCandidateInfo = _oldCandidateInfos[_operatorAddress];

            require(oldCandidateInfo.candidateContract == address(0), "already migrated");
            oldCandidateInfo.candidateContract = candidateInfo.candidateContract;
            oldCandidateInfo.newCandidate = candidateContract;
            oldCandidateInfo.memberJoinedTime = candidateInfo.memberJoinedTime;
            oldCandidateInfo.indexMembers = candidateInfo.indexMembers;
            oldCandidateInfo.rewardPeriod = candidateInfo.rewardPeriod;
            oldCandidateInfo.claimedTimestamp = candidateInfo.claimedTimestamp;
            
            candidateInfo.candidateContract = candidateContract;
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

    function createCandidateAddOn(string calldata _memo, address _operatorManagerAddress)
        public
        returns (address)
    {
        if (msg.sender != layer2Manager) revert PermissionError();

        // Candidate
        address candidateContract = ICandidateAddOnFactory(candidateAddOnFactory).deploy(
            _operatorManagerAddress,
            _memo,
            address(this),
            address(seigManager)
        );
        if (candidateContract == address(0)) revert CreateCandiateError(1);
        if (_candidateInfos[_operatorManagerAddress].candidateContract != address(0)) revert CreateCandiateError(2);

        _candidateInfos[_operatorManagerAddress] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_operatorManagerAddress);

        if (!layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager))) revert CreateCandiateError(3);
        emit CandidateContractCreated(_operatorManagerAddress, candidateContract, _memo);

        return candidateContract;
    }

    /// @notice Registers the exist layer2 on DAO by owner
    /// @param _operator Operator address of the layer2 contract
    /// @param _layer2 Layer2 contract address to be registered
    /// @param _memo A memo for the candidate
    function registerLayer2CandidateByOwner(address _operator, address _layer2, string memory _memo)
        external
        onlyOwner
    {
        _registerLayer2Candidate(_operator, _layer2, _memo);
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
        uint256 operatorAmount = operatorCheck(newMember);
        uint256 minimumAmount = ISeigManager(address(seigManager)).minimumAmount();
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
        require(!blacklist[candidateInfo.candidateContract], "DAOCommittee: blacklisted member");

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
        claimActivityReward(candidate);

        blacklist[candidateInfo.candidateContract] = true;
        emit MemberBlacklisted(candidate, block.timestamp);

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
        emit ChangedMemo(_candidateContract, _memo);
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
        require(agendaData.atomicExecute, "atomicExecute need true");
        require(agendaData.target.length == agendaData.functionBytecode.length, "need same length");
        require(agendaData.votingPeriodSeconds >= agendaManager.minimumVotingPeriodSeconds(), "need over minimumVotingPeriodSeconds");

        for (uint256 i = 0; i < agendaData.target.length; i++) {
            if(agendaData.target[i] == address(daoVault)) {
                bytes memory abc = agendaData.functionBytecode[i];
                bytes memory selector1 = abc.slice(0, 4);

                if (selector1.equal(claimTONBytes)) revert ClaimTONError();
                else if (selector1.equal(claimERC20Bytes)) {
                    bytes memory tonaddr = toBytes(ton);
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
            agendaData.functionBytecode
        );

        return true;
    }

    /// @notice Vote on an agenda
    /// @param _agendaID The agenda ID
    /// @param _vote voting type (counting 0:abstainVotes 1:yesVotes 2:noVotes)
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
        } else {
            uint256 totalvotes = yes + no + abstain;
            uint256 remainingVotes = maxMember - totalvotes;

            if((yes + remainingVotes < quorum) && (no + remainingVotes < quorum)) {
                // dismiss
                agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.DISMISS);
                agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);    
            }
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
         ) = agendaManager.getExecutionInfo(_agendaID);

        if (atomicExecute) {
            agendaManager.setExecutedAgenda(_agendaID);
            for (uint256 i = 0; i < target.length; i++) {
                (bool success, ) = address(target[i]).call(functionBytecode[i]);
                require(success, "DAOCommittee: Failed to execute the agenda");
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
    function claimActivityReward(address _receiver) public {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );
        require(!blacklist[candidateInfo.candidateContract], "DAOCommittee: blacklisted member");
        uint256 amount = getClaimableActivityReward(candidate);
        require(amount > 0, "DAOCommittee: you don't have claimable wton");

        candidateInfo.claimedTimestamp = uint128(block.timestamp);
        candidateInfo.rewardPeriod = 0;

        uint256 wtonAmount = _toRAY(amount);
        daoVault.claimERC20(wton,_receiver, wtonAmount);

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

    function payCreatingAgendaFee(address _creator) internal {
        uint256 fee = agendaManager.createAgendaFees();

        IERC20(ton).safeTransferFrom(_creator, address(this), fee);
        IERC20(ton).safeTransfer(address(1), fee);
    }

    function _registerLayer2Candidate(address _operator, address _layer2, string memory _memo)
        internal
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
    {
        require(!isExistCandidate(_layer2), "DAOCommittee: candidate already registerd");

        require(
            _layer2 != address(0),
            "DAOCommittee: deployed candidateContract is zero"
        );

        ILayer2 layer2 = ILayer2(_layer2);
        require(
            layer2.isLayer2(),
            "DAOCommittee: invalid layer2 contract"
        );
        require(
            layer2.operator() == _operator,
            "DAOCommittee: invalid operator"
        );

        address candidateContract = candidateFactory.deploy(
            _layer2,
            true,
            _memo,
            address(this),
            address(seigManager)
        );

        require(
            candidateContract != address(0),
            "DAOCommittee: deployed candidateContract is zero"
        );

        _candidateInfos[_layer2] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_layer2);
        privateLayer2[_layer2] = _operator;

        emit Layer2Registered(_layer2, candidateContract, _memo);
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

        if (!supportIsCandidateContract) {
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
        address coinage = ISeigManager(address(seigManager)).coinages(layer2);
        operatorAmount = ICoinage(coinage).balanceOf(operator);
    }

    // function operatorCheck() public view returns (uint256 operatorAmount) {
    //     address candidate = ICandidate(msg.sender).candidate();
    //     CandidateInfo memory info = _candidateInfos[candidate];
    //     address coinage = ISeigManager(address(seigManager)).coinages(info.candidateContract);
    //     if (privateLayer2[candidate] != address(0)) {
    //         address layer2operator = privateLayer2[candidate];
    //         return operatorAmount = ICoinage(coinage).balanceOf(layer2operator);
    //     } else {
    //         return operatorAmount = ICoinage(coinage).balanceOf(candidate);    
    //     }
    // }

    function operatorCheck(address candidate) public view returns (uint256 operatorAmount) {
        CandidateInfo memory info = _candidateInfos[candidate];
        address coinage = ISeigManager(address(seigManager)).coinages(info.candidateContract);
        if (privateLayer2[candidate] != address(0)) {
            address layer2operator = privateLayer2[candidate];
            return operatorAmount = ICoinage(coinage).balanceOf(layer2operator);
        } else {
            return operatorAmount = ICoinage(coinage).balanceOf(candidate);    
        }
    }
}