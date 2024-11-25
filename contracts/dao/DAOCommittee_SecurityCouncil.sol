// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AccessControl} from "../accessControl/AccessControl.sol";
import {ERC165A}  from "../accessControl/ERC165A.sol";

import "./StorageStateCommittee.sol";
import "../proxy/ProxyStorage2.sol";
import "./StorageStateCommitteeV2.sol";
import "./lib/BytesLib.sol";
import "./StorageStateCommittee_SC.sol";

error SameAddressError();
error PayableError();

contract DAOCommittee_SecurityCouncil is
    StorageStateCommittee,
    AccessControl,
    ERC165A,
    ProxyStorage2,
    StorageStateCommitteeV2,
    StorageStateCommittee_SC
{
    using BytesLib for bytes;

    event SetSecurityCouncil (address securityCouncil);
    event SetTimelockController (address timelockController);
    event ExecutedTransactions (address[] targets, bytes[] functionBytecodes, uint256[] payEthers);
    event ExecutedTransaction (address target, bytes functionBytecode, uint256 payEther);

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DAOCommittee: msg.sender is not an admin");
        _;
    }

    modifier onlyTimelockOrSecurityCouncil() {
        require(securityCouncil == msg.sender || timelockController == msg.sender,
            "DAOCommittee: msg.sender is not a security council");
        _;
    }

    /// @notice Set a security council address
    /// @param _securityCouncil     a security council address
    function setSecurityCouncil(
        address _securityCouncil
    )
        public onlyOwner
    {
        if (securityCouncil == _securityCouncil) revert SameAddressError();
        securityCouncil = _securityCouncil;
        emit SetSecurityCouncil(_securityCouncil);
    }

     function setTimelockController(
        address _timelockController
    )
        public onlyOwner
    {
        if (timelockController == _timelockController) revert SameAddressError();
        timelockController = _timelockController;
        emit SetTimelockController(_timelockController);
    }

    function executeTransactions(address[] calldata targets, bytes[] calldata functionBytecodes, uint256[] calldata payEthers)
        external payable onlyTimelockOrSecurityCouncil
    {
        require(targets.length != 0 &&
            targets.length == functionBytecodes.length &&
            targets.length == payEthers.length,
            "DAOCommittee_SecurityCouncil: wrong parameters"
        );

        uint256 sum;
        for (uint256 i = 0; i < payEthers.length; i++) sum += payEthers[i];
        if (uint256(msg.value) != sum) revert PayableError();

        for (uint256 i = 0; i < targets.length; i++) {
            bool success;
            if (payEthers[i] == 0)  (success, ) = address(targets[i]).call(functionBytecodes[i]);
            else (success, ) = payable(address(targets[i])).call{value:payEthers[i]}(functionBytecodes[i]);
            require(success, "DAOCommittee_SecurityCouncil: Failed to execute");
        }

        emit ExecutedTransactions(targets, functionBytecodes, payEthers);
    }

    function executeTransaction(address target, bytes calldata functionBytecode, uint256 payEther)
        external payable onlyTimelockOrSecurityCouncil
    {
        require(target != address(0) && uint256(msg.value) == payEther,
            "DAOCommittee_SecurityCouncil: wrong parameters"
        );
        bool success;
        if (msg.value == 0 ) (success, ) = address(target).call(functionBytecode);
        else (success, ) = payable(address(target)).call{value:payEther}(functionBytecode);

        require(success, "DAOCommittee_SecurityCouncil: Failed to execute");

        emit ExecutedTransaction(target, functionBytecode, payEther);
    }
}