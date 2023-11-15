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

}
