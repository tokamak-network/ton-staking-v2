// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ICandidateFactory} from './interfaces/ICandidateFactory.sol';

import {ICandidate} from './interfaces/ICandidate.sol';
import {ILayer2} from './interfaces/ILayer2.sol';
import {IDAOAgendaManager} from './interfaces/IDAOAgendaManager.sol';
import {ISeigManager} from './interfaces/ISeigManager.sol';
import {ICoinage} from './interfaces/ICoinage.sol';
import {ICandidateAddOnFactory} from './interfaces/ICandidateAddOnFactory.sol';
import {LibAgenda} from './lib/Agenda.sol';
import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

import {AccessControl} from '../accessControl/AccessControl.sol';
import {ERC165A} from '../accessControl/ERC165A.sol';

import './StorageStateCommittee.sol';
import './StorageStateCommitteeV2.sol';
import './StorageStateCommitteeV3.sol';
import './lib/BytesLib.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

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

interface IMultiSigWallet {
    function isOwner(address owner) external view returns (bool);
    function numConfirmationsRequired() external view returns (uint256);
}

contract DAOCommittee_V2 is
    StorageStateCommittee,
    AccessControl,
    ERC165A,
    StorageStateCommitteeV2,
    StorageStateCommitteeV3
{
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    bytes private constant claimTONBytes = hex'ef0d5594';
    bytes private constant claimWTONBytes = hex'f52bba70';
    bytes private constant claimERC20Bytes = hex'f848091a';

    // ERC-1271 Magic Values
    bytes4 private constant MAGICVALUE = 0x20c13b0b;
    bytes4 private constant INVALID_SIGNATURE = 0xffffffff;

    bytes32 public constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    enum CurrentResult {
        PENDING,
        ACCEPT,
        REJECT,
        DISMISS,
        NO_CONSENSUS,
        NO_AGENDA
    }
    enum CurrentStatus {
        NONE,
        NOTICE,
        VOTING,
        WAITING_EXEC,
        EXECUTED,
        ENDED,
        NO_AGENDA
    }

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

    event AgendaVoteCasted(
        address indexed from,
        uint256 indexed id,
        uint256 voting,
        string comment
    );

    event AgendaExecuted(uint256 indexed id, address[] target);

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

    event ChangedMember(uint256 indexed slotIndex, address prevMember, address indexed newMember);

    event ClaimedActivityReward(address indexed candidate, address receiver, uint256 amount);

    event ChangedMemo(address candidateContract, string newMemo);

    event MemberBlacklisted(address indexed member, uint256 timestamp);

    event MultiSigWalletSet(address indexed oldWallet, address indexed newWallet);

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            'not admin'
        );
        _;
    }

    modifier validMemberIndex(uint256 _index) {
        require(_index < maxMember, 'invalid index');
        _;
    }

    modifier nonZero(address _addr) {
        require(_addr != address(0), 'zero addr');
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // ERC-1271 Implementation
    //////////////////////////////////////////////////////////////////////

    /**
     * @notice Signature validation according to EIP-1271 standard
     * @dev Validates signatures from MultiSigWallet owners (DAO Contract Owner)
     * @dev Safe Wallet can use this when DAO Contract is one of its signers
     * @param _hash Hash that was signed
     * @param _signature Signature data (multiple signatures from MultiSigWallet owners)
     * @return magicValue ERC-1271 magic value
     */
    function isValidSignature(
        bytes memory _hash,
        bytes memory _signature
    ) external view returns (bytes4 magicValue) {
        require(_signature.length >= 130, 'bad sig len');
        if (multiSigWallet == address(0)) {
            return INVALID_SIGNATURE;
        }
        require(
            hasRole(DEFAULT_ADMIN_ROLE, multiSigWallet),
            'multisig not admin'
        );
        bytes memory messageData = encodeMessageDataForSafe(_hash);
        bytes32 messageHash = keccak256(messageData);
        if (_validateSignatures(messageHash, _signature)) {
            return MAGICVALUE;
        }
        return INVALID_SIGNATURE;
    }

    /**
     * @notice Verify multiple signatures from MultiSigWallet owners
     * @dev Validates signatures from DAO Contract's MultiSigWallet owners
     * @param _hash Hash that was signed
     * @param _signature Concatenated signature data from MultiSigWallet owners
     * @return true if valid signatures meet MultiSigWallet threshold
     */
    function _validateSignatures(
        bytes32 _hash,
        bytes memory _signature
    ) internal view returns (bool) {
        uint256 requiredSigs = IMultiSigWallet(multiSigWallet).numConfirmationsRequired();
        uint256 sigCount = _signature.length / 65;
        
        if (sigCount < requiredSigs) return false;

        address[] memory signers = new address[](sigCount);
        uint256 validSigs = 0;

        for (uint256 i = 0; i < sigCount; i++) {
            bytes memory sigPart = _signature.slice(i * 65, 65);
            address signer = _recoverSigner(_hash, sigPart);

            // MultiSig 소유자이고 중복이 아닌 경우
            if (IMultiSigWallet(multiSigWallet).isOwner(signer) && !_isDuplicate(signers, signer, i)) {
                signers[i] = signer;
                validSigs++;
            }
        }

        if (requiredSigs <= validSigs ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Recovers signer address from ECDSA signature
     * @param _hash Hash that was signed
     * @param _signature Signature data (65 bytes)
     * @return signer Signer address
     */
    function _recoverSigner(
        bytes32 _hash,
        bytes memory _signature
    ) internal pure returns (address signer) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // Prevent signature malleability
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "bad sig 's' value"
        );

        require(v == 31 || v == 32, "bad sig 'v' value");

        // Create Ethereum signed message hash
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked('\x19Ethereum Signed Message:\n32', _hash)
        );
        signer = ecrecover(ethSignedMessageHash, v - 4, r, s);

        require(signer != address(0), 'Invalid signer');
        return signer;
    }

    function encodeMessageDataForSafe(bytes memory message) public view returns (bytes memory) {
        bytes32 safeMessageHash = keccak256(abi.encode(SAFE_MSG_TYPEHASH, keccak256(message)));
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeMessageHash);
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @notice Check for duplicate signers
     * @param signers Array of signer addresses
     * @param signer Address to check
     * @param currentIndex Current index in the array
     * @return true if duplicate found
     */
    function _isDuplicate(
        address[] memory signers,
        address signer,
        uint256 currentIndex
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < currentIndex; i++) {
            if (signers[i] == signer) return true;
        }
        return false;
    }

    /**
     * @notice Verify that you are the owner of MultiSigWallet
     * @param _address Enter address
     * @return true True if the owner of MultiSigWallet
     */
    function isOwner(address _address) public view returns (bool) {
        return IMultiSigWallet(multiSigWallet).isOwner(_address);
    }

    /**
     * @notice Sets MultiSigWallet address (onlyOwner)
     * @dev MultiSigWallet becomes the DAO Owner and its owners' signatures are validated via EIP-1271
     * @param _multiSigWallet New MultiSigWallet address
     */
    function setMultiSigWallet(
        address _multiSigWallet
    ) external onlyOwner nonZero(_multiSigWallet) {
        address oldWallet = multiSigWallet;
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _multiSigWallet),
            'not admin'
        );
        multiSigWallet = _multiSigWallet;
        emit MultiSigWalletSet(oldWallet, _multiSigWallet);
    }

    //////////////////////////////////////////////////////////////////////
    // Managing members

    /// @notice Removes candidates registered in the blacklist.
    /// @param _candidate Candidate address to be updated
    function removeFromBlacklist(address _candidate) external onlyOwner {
        require(blacklist[_candidate], 'Not blacklisted');
        blacklist[_candidate] = false;
    }

    /// @notice Registers a new Candidate managed by msg.sender.
    /// @param _memo Candidate Memo
    function createCandidate(
        string calldata _memo
    ) external validSeigManager validLayer2Registry validCommitteeL2Factory {
        address _operator = msg.sender;
        require(!isExistCandidate(_operator), 'already registered');

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
            'zero candidate'
        );

        require(
            layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager)),
            'coinage failed'
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

    /// @notice Registers a new Candidate managed by operator.
    /// @param _memo Candidate Memo
    /// @param _operatorAddress operatorAddress
    function createCandidateOwner(
        string calldata _memo,
        address _operatorAddress
    ) public validSeigManager validLayer2Registry validCommitteeL2Factory onlyOwner {
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
            'DAOCommittee: deployed candidateContract is zero'
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
            'DAOCommittee: failed to registerAndDeployCoinage'
        );

        emit CandidateContractCreated(_operatorAddress, candidateContract, _memo);
    }

    /// @notice Registers a new Candidate managed by operatorManagerContract.
    /// @param _memo Candidate Memo
    /// @param _operatorManagerAddress operatorManagerContract Address
    /// @return candidateContract Address
    function createCandidateAddOn(
        string calldata _memo,
        address _operatorManagerAddress
    ) public returns (address) {
        if (msg.sender != layer2Manager) revert PermissionError();

        // Candidate
        address candidateContract = ICandidateAddOnFactory(candidateAddOnFactory).deploy(
            _operatorManagerAddress,
            _memo,
            address(this),
            address(seigManager)
        );
        if (candidateContract == address(0)) revert CreateCandiateError(1);
        if (_candidateInfos[_operatorManagerAddress].candidateContract != address(0))
            revert CreateCandiateError(2);

        _candidateInfos[_operatorManagerAddress] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_operatorManagerAddress);

        if (!layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager)))
            revert CreateCandiateError(3);
        emit CandidateContractCreated(_operatorManagerAddress, candidateContract, _memo);

        return candidateContract;
    }

    /// @notice Registers the exist layer2 on DAO by owner
    /// @param _operator Operator address of the layer2 contract
    /// @param _layer2 Layer2 contract address to be registered
    /// @param _memo A memo for the candidate
    function registerLayer2CandidateByOwner(
        address _operator,
        address _layer2,
        string memory _memo
    ) external onlyOwner {
        _registerLayer2Candidate(_operator, _layer2, _memo);
    }

    /// @notice Replaces an existing member
    /// @param _memberIndex The member slot index to be replaced
    /// @return Whether or not the execution succeeded
    function changeMember(
        uint256 _memberIndex
    ) external validMemberIndex(_memberIndex) returns (bool) {
        address newMember = ICandidate(msg.sender).candidate();
        uint256 operatorAmount = operatorCheck(newMember);
        uint256 minimumAmount = ISeigManager(address(seigManager)).minimumAmount();
        require(operatorAmount >= minimumAmount, 'insufficient deposit');

        CandidateInfo storage candidateInfo = _candidateInfos[newMember];
        require(
            ICandidate(msg.sender).isCandidateContract(),
            'not candidate contract'
        );
        require(
            candidateInfo.candidateContract == msg.sender,
            'DAOCommittee: invalid candidate contract'
        );
        require(
            cooldown[candidateInfo.candidateContract] < block.timestamp,
            'cooldown'
        );
        require(!blacklist[candidateInfo.candidateContract], 'blacklisted');
        require(candidateInfo.memberJoinedTime == 0, 'already member');

        address prevMember = members[_memberIndex];
        address prevMemberContract = candidateContract(prevMember);

        candidateInfo.memberJoinedTime = uint128(block.timestamp);
        candidateInfo.indexMembers = _memberIndex;

        cooldown[candidateInfo.candidateContract] = block.timestamp + cooldownTime;
        members[_memberIndex] = newMember;

        if (prevMember == address(0)) {
            emit ChangedMember(_memberIndex, prevMember, newMember);
            return true;
        }

        require(
            ICandidate(msg.sender).totalStaked() > ICandidate(prevMemberContract).totalStaked(),
            'not enough amount'
        );

        CandidateInfo storage prevCandidateInfo = _candidateInfos[prevMember];
        prevCandidateInfo.indexMembers = 0;
        if (prevCandidateInfo.memberJoinedTime > prevCandidateInfo.claimedTimestamp) {
            prevCandidateInfo.rewardPeriod += (uint128(block.timestamp) -
                prevCandidateInfo.memberJoinedTime);
        } else {
            prevCandidateInfo.rewardPeriod += (uint128(block.timestamp) -
                prevCandidateInfo.claimedTimestamp);
        }
        prevCandidateInfo.memberJoinedTime = 0;

        emit ChangedMember(_memberIndex, prevMember, newMember);

        return true;
    }

    /// @notice If you remove a Member's qualifications through retireMember,
    ///         they will be added to the blacklist and will not be able to use any functions
    ///         that a Candidate can perform in the future.
    ///         Please check before executing the function.
    /// @return Whether or not the execution succeeded
    function retireMember() external returns (bool) {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(candidateInfo.memberJoinedTime > 0, 'not member');
        require(
            candidateInfo.candidateContract == msg.sender,
            'DAOCommittee: invalid candidate contract'
        );
        members[candidateInfo.indexMembers] = address(0);
        if (candidateInfo.memberJoinedTime > candidateInfo.claimedTimestamp) {
            candidateInfo.rewardPeriod += (uint128(block.timestamp) -
                candidateInfo.memberJoinedTime);
        } else {
            candidateInfo.rewardPeriod += (uint128(block.timestamp) -
                candidateInfo.claimedTimestamp);
        }
        candidateInfo.memberJoinedTime = 0;

        uint256 prevIndex = candidateInfo.indexMembers;
        candidateInfo.indexMembers = 0;

        blacklist[candidateInfo.candidateContract] = true;
        emit MemberBlacklisted(candidate, block.timestamp);

        emit ChangedMember(prevIndex, candidate, address(0));

        return true;
    }

    /// @notice Registers a new Candidate managed by operatorManagerContract.
    /// @param _candidate Candidate Memo
    /// @param _memo Candidate Memo
    function setMemoOnCandidate(address _candidate, string calldata _memo) external {
        address candidateContract = candidateContract(_candidate);
        setMemoOnCandidateContract(candidateContract, _memo);
    }

    /// @notice Set memo
    /// @param _candidateContract candidate contract address
    /// @param _memo New memo on this candidate
    function setMemoOnCandidateContract(address _candidateContract, string calldata _memo) public {
        address candidate = ICandidate(_candidateContract).candidate();
        address contractOwner = candidate;
        if (ICandidate(_candidateContract).isLayer2Candidate()) {
            contractOwner = ILayer2(candidate).operator();
        }
        require(
            msg.sender == contractOwner,
            'DAOCommittee: sender is not the candidate of this contract'
        );

        ICandidate(_candidateContract).setMemo(_memo);
        emit ChangedMemo(_candidateContract, _memo);
    }

    //////////////////////////////////////////////////////////////////////
    // Managing agenda

    /// @notice This is the ApproveAndCall function that runs in the TON Contract.
    ///         can create an Agenda through this function.
    /// @param owner Owner who created the function.
    /// @param data  Data containing the content to be executed in the corresponding function.
    /// @return Whether or not the execution succeeded
    function onApprove(
        address owner,
        address,
        uint256,
        bytes calldata data
    ) external returns (bool) {
        require(msg.sender == ton, "It's not from TON");
        AgendaCreatingData memory agendaData = _decodeAgendaData(data);
        require(agendaData.target.length != 0, 'need target');
        require(agendaData.atomicExecute, 'need atomic');
        require(agendaData.target.length == agendaData.functionBytecode.length, 'length mismatch');
        require(
            agendaData.votingPeriodSeconds >= agendaManager.minimumVotingPeriodSeconds(),
            'need over minimumVotingPeriodSeconds'
        );

        for (uint256 i = 0; i < agendaData.target.length; i++) {
            if (agendaData.target[i] == address(daoVault)) {
                bytes memory abc = agendaData.functionBytecode[i];
                bytes memory selector1 = abc.slice(0, 4);

                if (selector1.equal(claimTONBytes)) revert ClaimTONError();
                if (selector1.equal(claimWTONBytes)) revert ClaimWTONError();

                bytes memory erc20Address = abc.slice(16, 20);
                if (selector1.equal(claimERC20Bytes) && erc20Address.equal(_toBytes(ton))) {
                    revert('claimERC20 ton dont use');
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

    /// @notice Vote on an agenda
    /// @param _agendaID The agenda ID
    /// @param _vote voting type (counting 0:abstainVotes 1:yesVotes 2:noVotes)
    /// @param _comment voting comment
    function castVote(
        uint256 _agendaID,
        uint256 _vote,
        string calldata _comment
    ) external validAgendaManager {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            'DAOCommittee: invalid candidate contract'
        );
        require(!blacklist[candidateInfo.candidateContract], 'DAOCommittee: blacklisted member');

        agendaManager.castVote(_agendaID, candidate, _vote);

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

            if ((yes + remainingVotes < quorum) && (no + remainingVotes < quorum)) {
                // dismiss
                agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.DISMISS);
                agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
            }
        }

        emit AgendaVoteCasted(msg.sender, _agendaID, _vote, _comment);
    }

    /// @notice Returns the current status and results for agendaID.
    /// @param _agendaID The ID of the agenda to check.
    /// @return currentResult Current agenda result (PENDING, ACCEPT, REJECT, DISMISS, NO_CONSENSUS, NO_AGENDA)
    /// @return currentStatus Current agenda status (NONE, NOTICE, VOTING, WAITING_EXEC, EXECUTED, ENDED, NO_AGENDA)
    function currentAgendaStatus(
        uint256 _agendaID
    ) external view returns (CurrentResult currentResult, CurrentStatus currentStatus) {
        uint256 numAgendas = agendaManager.numAgendas();
        if (numAgendas <= _agendaID) {
            // No Agenda
            // (NO AGENDA, NO AGENDA)
            return (CurrentResult.NO_AGENDA, CurrentStatus.NO_AGENDA);
        }

        uint256 noticeEndTime = agendaManager.getAgendaNoticeEndTimeSeconds(_agendaID);
        if (block.timestamp < noticeEndTime) {
            //Notice Time
            //(PENDING, NOTICE)
            return (CurrentResult.PENDING, CurrentStatus.NOTICE);
        }

        uint256 votingEndTime = agendaManager.getAgendaVotingEndTimeSeconds(_agendaID);
        if (votingEndTime == 0) {
            //When the NoticeTime has passed but no one has voted
            //(NO CONSENSUS, VOTING)
            return (CurrentResult.NO_CONSENSUS, CurrentStatus.VOTING);
        }

        if (block.timestamp <= votingEndTime) {
            //When the NoticeTime has passed and someone has voted, but voting has not ended
            (uint256 result, ) = agendaManager.getAgendaResult(_agendaID);
            return (CurrentResult(result), CurrentStatus.VOTING);
        }

        //Results after votingEndTime has passed
        (uint256 yes, uint256 no, uint256 abstain) = agendaManager.getVotingCount(_agendaID);

        if (quorum <= yes) {
            (uint256 result, bool executed) = agendaManager.getAgendaResult(_agendaID);
            if (executed) {
                return (CurrentResult(result), CurrentStatus.EXECUTED);
            } else {
                return (CurrentResult(result), CurrentStatus.WAITING_EXEC);
            }
        }
        if (quorum <= no) {
            // no (REJECT, ENDED)
            return (CurrentResult.REJECT, CurrentStatus.ENDED);
        }
        if (quorum <= abstain) {
            // (DISMISS, ENDED)
            return (CurrentResult.DISMISS, CurrentStatus.ENDED);
        }
        // (NO CONSENSUS, ENDED)
        return (CurrentResult.NO_CONSENSUS, CurrentStatus.ENDED);
    }

    /// @notice Execute the accepted agenda
    /// @param _agendaID Agenda ID
    function executeAgenda(uint256 _agendaID) external validAgendaManager {
        require(
            agendaManager.canExecuteAgenda(_agendaID),
            'DAOCommittee: can not execute the agenda'
        );

        (
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,

        ) = agendaManager.getExecutionInfo(_agendaID);

        if (atomicExecute) {
            agendaManager.setExecutedAgenda(_agendaID);
            for (uint256 i = 0; i < target.length; i++) {
                (bool success, ) = address(target[i]).call(functionBytecode[i]);
                require(success, 'exec failed');
            }
        }

        emit AgendaExecuted(_agendaID, target);
    }

    /// @notice Set status and result of specific agenda
    /// @param _agendaID Agenda ID
    /// @param _status New status
    /// @param _result New result
    function setAgendaStatus(
        uint256 _agendaID,
        uint256 _status,
        uint256 _result
    ) external onlyOwner {
        agendaManager.setResult(_agendaID, LibAgenda.AgendaResult(_result));
        agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus(_status));
    }

    /// @notice Call updateSeigniorage on SeigManager
    /// @param _candidate Candidate address to be updated
    /// @return Whether or not the execution succeeded
    function updateSeigniorage(address _candidate) external returns (bool) {
        address candidateContract = _candidateInfos[_candidate].candidateContract;
        return ICandidate(candidateContract).updateSeigniorage();
    }

    /// @notice Claims the activity reward for member
    function claimActivityReward(address _receiver) public {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            'DAOCommittee: invalid candidate contract'
        );
        require(!blacklist[candidateInfo.candidateContract], 'DAOCommittee: blacklisted member');
        uint256 amount = getClaimableActivityReward(candidate);
        require(amount > 0, "no claimable");

        candidateInfo.claimedTimestamp = uint128(block.timestamp);
        candidateInfo.rewardPeriod = 0;

        uint256 wtonAmount = _toRAY(amount);
        daoVault.claimERC20(wton, _receiver, wtonAmount);

        emit ClaimedActivityReward(candidate, _receiver, wtonAmount);
    }

    /// @notice Convert Wei units to Ray units.
    /// @param v Value to change to Ray
    /// @return Returns the reflected value of Ray
    function _toRAY(uint256 v) internal pure returns (uint256) {
        return v * 10 ** 9;
    }

    /// @notice decompose agendaData so that it can be used.
    /// @param input input the bytes data
    function _decodeAgendaData(
        bytes calldata input
    ) internal pure returns (AgendaCreatingData memory data) {
        (
            data.target,
            data.noticePeriodSeconds,
            data.votingPeriodSeconds,
            data.atomicExecute,
            data.functionBytecode,
            data.memo
        ) = abi.decode(input, (address[], uint128, uint128, bool, bytes[], string));
    }

    /// @notice Convert address to bytes.
    /// @param a address
    function _toBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /// @notice Pay the fee to create the agenda.
    /// @param _creator Address of the person who created the agenda
    function _payCreatingAgendaFee(address _creator) internal {
        uint256 fee = agendaManager.createAgendaFees();

        IERC20(ton).safeTransferFrom(_creator, address(this), fee);
        IERC20(ton).safeTransfer(address(1), fee);
    }

    /// @notice Registers the exist layer2 on DAO by owner
    /// @param _operator Operator address of the layer2 contract
    /// @param _layer2 Layer2 contract address to be registered
    /// @param _memo A memo for the candidate
    function _registerLayer2Candidate(
        address _operator,
        address _layer2,
        string memory _memo
    ) internal validSeigManager validLayer2Registry validCommitteeL2Factory {
        require(!isExistCandidate(_layer2), 'already registered');

        require(_layer2 != address(0), 'zero contract');

        ILayer2 layer2 = ILayer2(_layer2);
        require(layer2.isLayer2(), 'invalid layer2');
        require(layer2.operator() == _operator, 'invalid operator');

        address candidateContract = candidateFactory.deploy(
            _layer2,
            true,
            _memo,
            address(this),
            address(seigManager)
        );

        require(
            candidateContract != address(0),
            'DAOCommittee: deployed candidateContract is zero'
        );

        _candidateInfos[_layer2] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_layer2);
        privateLayer2[_layer2] = true;

        emit Layer2Registered(_layer2, candidateContract, _memo);
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
    ) internal validAgendaManager returns (uint256) {
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

    /// @notice Function to check if it is a candidate
    /// @param _candidate Candidate Address
    /// @return If true, Candidate, if false, not Candidate
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

    /// @notice Return totalSupply of Candidate
    /// @param _candidate Candidate Address
    /// @return totalsupply of Candidate
    function totalSupplyOnCandidate(
        address _candidate
    ) external view returns (uint256 totalsupply) {
        address candidateContract = candidateContract(_candidate);
        return totalSupplyOnCandidateContract(candidateContract);
    }

    /// @notice Return Amount of account in Candidate
    /// @param _candidate Candidate Address
    /// @param _account   Account Address
    /// @return amount of account in Candidate
    function balanceOfOnCandidate(
        address _candidate,
        address _account
    ) external view returns (uint256 amount) {
        address candidateContract = candidateContract(_candidate);
        return balanceOfOnCandidateContract(candidateContract, _account);
    }

    /// @notice Return totalsupply of CandidateContract
    /// @param _candidateContract CandidateContract Address
    /// @return totalsupply of CandidateContract
    function totalSupplyOnCandidateContract(
        address _candidateContract
    ) public view returns (uint256 totalsupply) {
        require(_candidateContract != address(0), 'not candidate');

        return ICandidate(_candidateContract).totalStaked();
    }

    /// @notice Return amount of account in CandidateContract
    /// @param _candidateContract CandidateContract Address
    /// @param _account account Address
    /// @return amount of account in CandidateContract
    function balanceOfOnCandidateContract(
        address _candidateContract,
        address _account
    ) public view returns (uint256 amount) {
        require(_candidateContract != address(0), 'not candidate');

        return ICandidate(_candidateContract).stakedOf(_account);
    }

    /// @notice Return candidateLength
    /// @return candidateLength
    function candidatesLength() external view returns (uint256) {
        return candidates.length;
    }

    /// @notice Whether there is a CandidateContract registered as a candidate
    /// @return isExist If isExist is true, there is a CandidteContract, otherwise there is not.
    function isExistCandidate(address _candidate) public view returns (bool isExist) {
        return _candidateInfos[_candidate].candidateContract != address(0);
    }

    /// @notice calculates how much reward candidate can receive.
    /// @param  _candidate candidate Address
    /// @return return reward amount
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

    /// @notice Returns information about oldCandidate.
    /// @param  _oldCandidate oldcandidate Address
    /// @return return CandidateInfo2
    function getOldCandidateInfos(
        address _oldCandidate
    ) external view returns (CandidateInfo2 memory) {
        return _oldCandidateInfos[_oldCandidate];
    }

    /// @notice Return how much the operator in layer2 has staked.
    /// @param  layer2  layer2 Address
    /// @param  operator operator Address
    /// @return operatorAmount
    function operatorAmountCheck(
        address layer2,
        address operator
    ) public view returns (uint256 operatorAmount) {
        address coinage = ISeigManager(address(seigManager)).coinages(layer2);
        operatorAmount = ICoinage(coinage).balanceOf(operator);
    }

    /// @notice Operators can see how much their Contract have staked.
    /// @param  candidate candidate Address
    /// @return operatorAmount
    function operatorCheck(address candidate) public view returns (uint256 operatorAmount) {
        CandidateInfo memory info = _candidateInfos[candidate];
        address coinage;
        if (privateLayer2[candidate]) {
            coinage = ISeigManager(address(seigManager)).coinages(candidate);
            operatorAmount = ICoinage(coinage).balanceOf(ILayer2(candidate).operator());
        } else {
            coinage = ISeigManager(address(seigManager)).coinages(info.candidateContract);
            operatorAmount = ICoinage(coinage).balanceOf(candidate);
        }
    }

    function version() public pure virtual returns (string memory) {
        return '2.0.0';
    }
}
