// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "../accessControl/AccessControl.sol";
import {ERC165A}  from "../accessControl/ERC165A.sol";

import "./StorageStateCommittee.sol";
import "../proxy/ProxyStorage2.sol";
import "./StorageStateCommitteeV2.sol";
import "./lib/BytesLib.sol";
import "./StorageStateCommittee_SC.sol";
interface IIDAOVault {
    function wton() external view returns(address);
}

error SameAddressError();
error PayableError();
error DisallowedFunctionCallError();

contract DAOCommittee_SecurityCouncil is
    StorageStateCommittee,
    AccessControl,
    ERC165A,
    ProxyStorage2,
    StorageStateCommitteeV2,
    StorageStateCommittee_SC
{
    using BytesLib for bytes;

    bytes4 constant SELECTOR_CLAIM_TON = hex"ef0d5594";
    bytes4 constant SELECTOR_CLAIM_ERC20 = hex"f848091a";
    bytes4 constant SELECTOR_CLAIM_WTON = hex"f52bba70";

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
        for (uint256 i = 0; i < payEthers.length; i++) {
            require(_checkInvalidTransaction(targets[i], functionBytecodes[i]));
            sum += payEthers[i];
        }
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

        require(_checkInvalidTransaction(target, functionBytecode));

        bool success;
        if (msg.value == 0 ) (success, ) = address(target).call(functionBytecode);
        else (success, ) = payable(address(target)).call{value:payEther}(functionBytecode);

        require(success, "DAOCommittee_SecurityCouncil: Failed to execute");

        emit ExecutedTransaction(target, functionBytecode, payEther);
    }

    function _checkInvalidTransaction(address target, bytes memory functionByte) internal view returns (bool) {

        if (target == address(daoVault)) {
            bytes4 selector = bytes4(functionByte.slice(0, 4)) ;

            if(selector == SELECTOR_CLAIM_TON) revert DisallowedFunctionCallError();

            else if(selector == SELECTOR_CLAIM_ERC20) {
                if (address(bytes20(functionByte.slice(16,20))) == ton) revert DisallowedFunctionCallError();

            } else if(selector == SELECTOR_CLAIM_WTON) {
                uint256 balanceOf;
                if (wton == address(0)) balanceOf = IERC20(IIDAOVault(target).wton()).balanceOf(target);
                else  balanceOf = IERC20(wton).balanceOf(target);

                if (balanceOf < uint256(bytes32(functionByte.slice(36,32)))) revert DisallowedFunctionCallError();
            }
        }
        return true;
    }
}