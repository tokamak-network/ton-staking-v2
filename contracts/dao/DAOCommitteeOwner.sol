// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ICandidate } from "./interfaces/ICandidate.sol";

import { AccessControl } from "../accessControl/AccessControl.sol";
import {ERC165A}  from "../accessControl/ERC165A.sol";

import "./StorageStateCommittee.sol";
import "../proxy/ProxyStorage2.sol";
import "./StorageStateCommitteeV2.sol";

interface ITarget {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function setSeigManager(address _seigManager) external;
    function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) external;
    function addMinter(address account) external;
    function upgradeTo(address logic) external;
    function setTON(address tonAddr) external;
    function setWTON(address wtonAddr) external;
    function setBurntAmountAtDAO(uint256 _burntAmountAtDAO) external;
    function setLayer2Manager(address layer2Manager_) external;
    function setL2Registry(address l2Registry_) external;
    function setLayer2StartBlock(uint256 startBlock_) external;
    function setImplementation2(address newImplementation, uint256 index, bool alive) external;
    function setSelectorImplementations2(
        bytes4[] calldata _selectors,
        address _imp
    ) external;
}

interface IPauser {
    function pause() external ;
    function unpause() external;
}

contract DAOCommitteeOwner is 
    StorageStateCommittee, 
    AccessControl, 
    ERC165A, 
    ProxyStorage2,
    StorageStateCommitteeV2
{
    event ChangedSlotMaximum(
        uint256 indexed prevSlotMax,
        uint256 indexed slotMax
    );

    event QuorumChanged(
        uint256 newQuorum
    );

    event ChangedMember(
        uint256 indexed slotIndex,
        address prevMember,
        address indexed newMember
    );

    event ActivityRewardChanged(
        uint256 newReward
    );

    modifier onlyOwner() {
        require(
            ITarget(address(this)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "DAOCommittee: not admin");
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

    function setLayer2CandidateFactory(address _layer2CandidateFactory) external onlyOwner nonZero(_layer2CandidateFactory) {
        layer2CandidateFactory = _layer2CandidateFactory;
    }

    function setLayer2Manager(address _layer2CandidateFactory) external onlyOwner nonZero(_layer2CandidateFactory) {
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

    function setSeigManager(address _seigManager) external onlyOwner nonZero(_seigManager) {
        seigManager = ISeigManager(_seigManager);
    }

    function setTargetSeigManager(address target, address _seigManager) external onlyOwner {
        ITarget(target).setSeigManager(_seigManager);
    }

    function setSeigPause() external onlyOwner {
       IPauser(address(seigManager)).pause();
    }

    function setSeigUnpause() external onlyOwner {
       IPauser(address(seigManager)).unpause();
    }

    function setTargetGlobalWithdrawalDelay(address target, uint256 globalWithdrawalDelay_) external onlyOwner {
        ITarget(target).setGlobalWithdrawalDelay(globalWithdrawalDelay_);
    }

    function setTargetAddMinter(address token, address account) external onlyOwner {
        ITarget(token).addMinter(account);
    }

    function setTargetUpgradeTo(address target, address logic) external onlyOwner {
        ITarget(target).upgradeTo(logic);
    }

    function setTargetSetTON(address target, address tonAddr) external onlyOwner {
        ITarget(target).setTON(tonAddr);
    }

    function setTargetSetWTON(address target, address wtonAddr) external onlyOwner {
        ITarget(target).setWTON(wtonAddr);
    }

    function setDaoVault(address _daoVault) external onlyOwner nonZero(_daoVault) {
        daoVault = IDAOVault(_daoVault);
    }

    /// @notice Set Layer2Registry contract address
    /// @param _layer2Registry New Layer2Registry contract address
    function setLayer2Registry(address _layer2Registry) external onlyOwner nonZero(_layer2Registry) {
        layer2Registry = ILayer2Registry(_layer2Registry);
    }

    /// @notice Set DAOAgendaManager contract address
    /// @param _agendaManager New DAOAgendaManager contract address
    function setAgendaManager(address _agendaManager) external onlyOwner nonZero(_agendaManager) {
        agendaManager = IDAOAgendaManager(_agendaManager);
    }

    /// @notice Set CandidateFactory contract address
    /// @param _candidateFactory New CandidateFactory contract address
    function setCandidateFactory(address _candidateFactory) external onlyOwner nonZero(_candidateFactory) {
        candidateFactory = ICandidateFactory(_candidateFactory);
    }

    function setTon(address _ton) external onlyOwner nonZero(_ton) {
        ton = _ton;
    }

    function setWton(address _wton) external onlyOwner nonZero(_wton) {
        wton = _wton;
    }

    /// @notice Increases the number of member slot
    /// @param _newMaxMember New number of member slot
    /// @param _quorum New quorum
    function increaseMaxMember(
        uint256 _newMaxMember,
        uint256 _quorum
    )
        external
        onlyOwner
    {
        require(maxMember < _newMaxMember, "DAOCommittee: You have to call decreaseMaxMember to decrease");
        uint256 prevMaxMember = maxMember;
        maxMember = _newMaxMember;
        fillMemberSlot();
        setQuorum(_quorum);
        emit ChangedSlotMaximum(prevMaxMember, _newMaxMember);
    }

    /// @notice Set new quorum
    /// @param _quorum New quorum
    function setQuorum(
        uint256 _quorum
    )
        public
        onlyOwner
        validAgendaManager
    {
        require(_quorum > maxMember / 2, "DAOCommittee: invalid quorum");
        require(_quorum <= maxMember, "DAOCommittee: quorum exceed max member");
        quorum = _quorum;
        emit QuorumChanged(quorum);
    }

    /// @notice Decreases the number of member slot
    /// @param _reducingMemberIndex Reducing member slot index
    /// @param _quorum New quorum
    function decreaseMaxMember(
        uint256 _reducingMemberIndex,
        uint256 _quorum
    )
        external
        onlyOwner
        validMemberIndex(_reducingMemberIndex)
    {
        address reducingMember = members[_reducingMemberIndex];
        CandidateInfo storage reducingCandidate = _candidateInfos[reducingMember];

        address tailMember = members[members.length - 1];
        if (_reducingMemberIndex != members.length - 1) {
            CandidateInfo storage tailCandidate = _candidateInfos[tailMember];

            tailCandidate.indexMembers = _reducingMemberIndex;
            members[_reducingMemberIndex] = tailMember;
        }
        reducingCandidate.indexMembers = 0;
        if (reducingCandidate.memberJoinedTime > reducingCandidate.claimedTimestamp) {
            reducingCandidate.rewardPeriod += (uint128(block.timestamp) - reducingCandidate.memberJoinedTime);
        } else {
            reducingCandidate.rewardPeriod += (uint128(block.timestamp) - reducingCandidate.claimedTimestamp);
        }
        reducingCandidate.memberJoinedTime = 0;

        members.pop();
        maxMember = maxMember - 1;
        setQuorum(_quorum);

        emit ChangedMember(_reducingMemberIndex, reducingMember, tailMember);
        emit ChangedSlotMaximum(maxMember + 1, maxMember);
    }

    function setActivityRewardPerSecond(uint256 _value) external onlyOwner {
        activityRewardPerSecond = _value;
        emit ActivityRewardChanged(_value);
    }

    
     /// @notice Set SeigManager contract address on candidate contracts
    /// @param _candidateContracts Candidate contracts to be set
    /// @param _seigManager New SeigManager contract address
    function setCandidatesSeigManager(
        address[] calldata _candidateContracts,
        address _seigManager
    )
        external
        onlyOwner
        nonZero(_seigManager)
    {
        for (uint256 i = 0; i < _candidateContracts.length; i++) {
            ICandidate(_candidateContracts[i]).setSeigManager(_seigManager);
        }
    }

    /// @notice Set DAOCommitteeProxy contract address on candidate contracts
    /// @param _candidateContracts Candidate contracts to be set
    /// @param _committee New DAOCommitteeProxy contract address
    function setCandidatesCommittee(
        address[] calldata _candidateContracts,
        address _committee
    )
        external
        onlyOwner
        nonZero(_committee)
    {
        for (uint256 i = 0; i < _candidateContracts.length; i++) {
            ICandidate(_candidateContracts[i]).setCommittee(_committee);
        }
    }

     /// @notice Set fee amount of creating an agenda
    /// @param _fees Fee amount on TON
    function setCreateAgendaFees(
        uint256 _fees
    )
        external
        onlyOwner
        validAgendaManager
    {
        agendaManager.setCreateAgendaFees(_fees);
    }

    /// @notice Set the minimum notice period
    /// @param _minimumNoticePeriod New minimum notice period in second
    function setMinimumNoticePeriodSeconds(
        uint256 _minimumNoticePeriod
    )
        external
        onlyOwner
        validAgendaManager
    {
        agendaManager.setMinimumNoticePeriodSeconds(_minimumNoticePeriod);
    }

    /// @notice Set the minimum voting period
    /// @param _minimumVotingPeriod New minimum voting period in second
    function setMinimumVotingPeriodSeconds(
        uint256 _minimumVotingPeriod
    )
        external
        onlyOwner
        validAgendaManager
    {
        agendaManager.setMinimumVotingPeriodSeconds(_minimumVotingPeriod);
    }

    /// @notice Set the executing period
    /// @param _executingPeriodSeconds New executing period in second
    function setExecutingPeriodSeconds(
        uint256 _executingPeriodSeconds
    )
        external
        onlyOwner
        validAgendaManager
    {
        agendaManager.setExecutingPeriodSeconds(_executingPeriodSeconds);
    }

    function setBurntAmountAtDAO(
        uint256 _burnAmount
    )
        external
        onlyOwner
        validSeigManager
    {
        ITarget(address(seigManager)).setBurntAmountAtDAO(_burnAmount);
    }


    function fillMemberSlot() internal {
        for (uint256 i = members.length; i < maxMember; i++) {
            members.push(address(0));
        }
    }
}