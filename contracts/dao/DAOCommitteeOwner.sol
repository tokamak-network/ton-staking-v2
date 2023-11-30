// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AccessControl } from "../accessControl/AccessControl.sol";
import "./StorageStateCommittee.sol";

interface ITarget {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function setSeigManager(address _seigManager) external;
    function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) external;
    function addMinter(address account) external;
    function upgradeTo(address logic) external;
    function setTON(address tonAddr) external;
}

interface IPauser {
    function pause() external ;
    function unpause() external;
}

contract DAOCommitteeOwner is StorageStateCommittee, AccessControl {

    modifier onlyOwner() {
        require(
            ITarget(address(this)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "DAOCommittee: not admin");
        _;
    }

    modifier nonZero(address _addr) {
        require(_addr != address(0), "DAOCommittee: zero address");
        _;
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

}