// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ICandidate } from "./interfaces/ICandidate.sol";
import { ITarget } from "./interfaces/ITarget.sol";
import { IPauser } from "./interfaces/IPauser.sol";

import { AccessControl } from "../accessControl/AccessControl.sol";
import {ERC165A}  from "../accessControl/ERC165A.sol";

import "./StorageStateCommittee.sol";
import "./StorageStateCommitteeV2.sol";

/**
 * @notice Error that occurs when Set Address
 * @param x 1: same candidateAddOnFactory address
 *          2: same layer2Manager address
 *          3: same seigManager address
 *          4: same daoVault address
 *          5: same layer2Registry address
 *          6: same agendaManager address
 *          7: same candidateFactory address
 *          8: same ton address
 *          9: same wton address
 */
error SameAddressError(uint x);

contract DAOCommitteeOwner is
    StorageStateCommittee,
    AccessControl,
    ERC165A,
    StorageStateCommitteeV2
{   
    /**
     * @notice Event that occurs when calling setCooldown function
     * @param cooldownTime    This value is the period of time after changeMember is executed until the corresponding Candidate executes the next changeMember.
     */
    event SetCooldownTime(
        uint256 cooldownTime
    );

    /**
     * @notice Event that occurs when calling increaseMaxMember & decreaseMaxMember function
     * @param prevSlotMax    Before number of member slot
     * @param slotMax    New number of member slot
     */
    event ChangedSlotMaximum(
        uint256 indexed prevSlotMax,
        uint256 indexed slotMax
    );

    /**
     * @notice Event that occurs when calling setQuorum function
     * @param newQuorum    New quorum
     */
    event QuorumChanged(
        uint256 newQuorum
    );

    /**
     * @notice Event that occurs when calling decreaseMaxMember function
     * @param slotIndex    Reducing Member slot index
     * @param prevMember    Reducing Member Address
     * @param newMember    Replaced Member Address
     */
    event ChangedMember(
        uint256 indexed slotIndex,
        address prevMember,
        address indexed newMember
    );

    /**
     * @notice Event that occurs when calling setActivityRewardPerSecond function
     * @param newReward    New value of RewardPerSecond
     */
    event ActivityRewardChanged(
        uint256 newReward
    );

    /**
     * @notice Event that occurs when calling setCandidateAddOnFactory function
     * @param candidateAddOnFactoryAddr    CandidateAddOnFactory Address
     */
    event SetCandidateAddOnFactory(
        address candidateAddOnFactoryAddr
    );

    /**
     * @notice Event that occurs when calling setLayer2Manager function
     * @param layer2ManagerAddr    Layer2Manager Address
     */
    event SetLayer2Manager(
        address layer2ManagerAddr
    );

    /**
     * @notice Event that occurs when calling setSeigManager function
     * @param seigManagerAddr    SeigManager Address
     */
    event SetSeigManager(
        address seigManagerAddr
    );

    /**
     * @notice Event that occurs when calling setDaoVault function
     * @param daoVaultAddr    DaoVault Address
     */
    event SetDaoVault(
        address daoVaultAddr
    );

    /**
     * @notice Event that occurs when calling setLayer2Registry function
     * @param layer2RegistryAddr    Layer2Registry Address
     */
    event SetLayer2Registry(
        address layer2RegistryAddr
    );

    /**
     * @notice Event that occurs when calling setAgendaManager function
     * @param agendaManagerAddr    AgendaManager Address
     */
    event SetAgendaManager(
        address agendaManagerAddr
    );
    
    /**
     * @notice Event that occurs when calling setCandidateFactory function
     * @param candidateFactoryAddr    candidateFactory Address
     */
    event SetCandidateFactory(
        address candidateFactoryAddr
    );

    /**
     * @notice Event that occurs when calling setTon function
     * @param tonAddr    TON Address
     */
    event SetTON(
        address tonAddr
    );

    /**
     * @notice Event that occurs when calling setWton function
     * @param wtonAddr    WTON Address
     */
    event SetWTON(
        address wtonAddr
    );

    /**
     * @notice Event that occurs when calling setWton function
     * @param to        execute target address
     * @param data      transaction data
     * @param success   Check the Transaction success
     */
    event DAOExecuteTransaction(
        address to,
        bytes data,
        bool success
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

    /// @notice Set the cooldownTime
    /// @param _cooltime The period after which changeMember can be executed again
    function setCooldownTime(
        uint256 _cooltime
    )
        external
        onlyOwner
    {
        cooldownTime = _cooltime;
        emit SetCooldownTime(cooldownTime);
    }

    /// @notice Set the candidateAddOnFactory
    /// @param _candidateAddOnFactory candidateAddOnFactory address
    function setCandidateAddOnFactory(address _candidateAddOnFactory)
        external
        onlyOwner
        nonZero(_candidateAddOnFactory)
    {
        if (candidateAddOnFactory == _candidateAddOnFactory) revert SameAddressError(1);
        candidateAddOnFactory = _candidateAddOnFactory;

        emit SetCandidateAddOnFactory(_candidateAddOnFactory);
    }

    /// @notice Set the layer2Manager
    /// @param _layer2Manager layer2Manager address
    function setLayer2Manager(address _layer2Manager)
        external
        onlyOwner
        nonZero(_layer2Manager)
    {
        if (layer2Manager == _layer2Manager) revert SameAddressError(2);
        layer2Manager = _layer2Manager;
        emit SetLayer2Manager(_layer2Manager);
    }

    /// @notice Set the seigManager
    /// @param _seigManager seigManager address
    function setSeigManager(address _seigManager) external onlyOwner nonZero(_seigManager) {
        if (address(seigManager) == _seigManager) revert SameAddressError(3);
        seigManager = ISeigManager(_seigManager);
        emit SetSeigManager(_seigManager);
    }

    /// @notice Set the daoVault
    /// @param _daoVault daoVault address
    function setDaoVault(address _daoVault) external onlyOwner nonZero(_daoVault) {
        if (address(daoVault) == _daoVault) revert SameAddressError(4);
        daoVault = IDAOVault(_daoVault);
        emit SetDaoVault(_daoVault);
    }

    /// @notice Set Layer2Registry contract address
    /// @param _layer2Registry New Layer2Registry contract address
    function setLayer2Registry(address _layer2Registry) external onlyOwner nonZero(_layer2Registry) {
        if (address(layer2Registry) == _layer2Registry) revert SameAddressError(5);
        layer2Registry = ILayer2Registry(_layer2Registry);
        emit SetLayer2Registry(_layer2Registry);
    }

    /// @notice Set DAOAgendaManager contract address
    /// @param _agendaManager New DAOAgendaManager contract address
    function setAgendaManager(address _agendaManager) external onlyOwner nonZero(_agendaManager) {
        if (address(agendaManager) == _agendaManager) revert SameAddressError(6);
        agendaManager = IDAOAgendaManager(_agendaManager);
        emit SetAgendaManager(_agendaManager);
    }

    /// @notice Set CandidateFactory contract address
    /// @param _candidateFactory New CandidateFactory contract address
    function setCandidateFactory(address _candidateFactory) external onlyOwner nonZero(_candidateFactory) {
        if (address(candidateFactory) == _candidateFactory) revert SameAddressError(7);
        candidateFactory = ICandidateFactory(_candidateFactory);
        emit SetCandidateFactory(_candidateFactory);
    }

    /// @notice Set TON contract address
    /// @param _ton ton address
    function setTon(address _ton) external onlyOwner nonZero(_ton) {
        if (address(ton) == _ton) revert SameAddressError(8);
        ton = _ton;
        emit SetTON(_ton);
    }

    /// @notice Set WTON contract address
    /// @param _wton wton address
    function setWton(address _wton) external onlyOwner nonZero(_wton) {
        if (address(wton) == _wton) revert SameAddressError(9);
        wton = _wton;
        emit SetWTON(_wton);
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
        _fillMemberSlot();
        _setQuorum(_quorum);
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
        _setQuorum(_quorum);
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
        
        if(reducingMember != address(0)){
            reducingCandidate.indexMembers = 0;
            if (reducingCandidate.memberJoinedTime > reducingCandidate.claimedTimestamp) {
                reducingCandidate.rewardPeriod += (uint128(block.timestamp) - reducingCandidate.memberJoinedTime);
            } else {
                reducingCandidate.rewardPeriod += (uint128(block.timestamp) - reducingCandidate.claimedTimestamp);
            }
            reducingCandidate.memberJoinedTime = 0;
        }

        members.pop();
        maxMember = maxMember - 1;
        _setQuorum(_quorum);

        emit ChangedMember(_reducingMemberIndex, reducingMember, tailMember);
        emit ChangedSlotMaximum(maxMember + 1, maxMember);
    }

    /// @notice Set the activityReward value received as a reward for member activity
    /// @param _value activityRewardPerSecond
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

    /// @notice DAO burns seigManager's seigniorage.
    /// @param _burnAmount burnAmount
    function setBurntAmountAtDAO(
        uint256 _burnAmount
    )
        external
        onlyOwner
        validSeigManager
    {
        ITarget(address(seigManager)).setBurntAmountAtDAO(_burnAmount);
    }

    /// @notice This is a function executed by the DAO multisig wallet council.
    /// @param _to Address to execute
    /// @param _data The function to be executed.
    function daoExecuteTransaction(
        address _to,
        bytes memory _data
    )
        external
        onlyOwner
        nonZero(_to)
    {
        require(_data.length != 0, "invalid data");
        (bool success, ) = address(_to).call(_data);

        emit DAOExecuteTransaction(_to,_data,success);
    }   

    /// @notice This function is used to increase member slots.
    function _fillMemberSlot() internal {
        for (uint256 i = members.length; i < maxMember; i++) {
            members.push(address(0));
        }
    }

    /// @notice Set new quorum
    /// @param _quorum New quorum
    function _setQuorum(
        uint256 _quorum
    )
        internal
    {
        require(_quorum > maxMember / 2, "DAOCommittee: invalid quorum");
        require(_quorum <= maxMember, "DAOCommittee: quorum exceed max member");
        quorum = _quorum;
        emit QuorumChanged(quorum);
    }
}