// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IL2CrossDomainMessenger } from "../interfaces/IL2CrossDomainMessenger.sol";


/// @title  A root contract from which it execute upgrades
/// @notice Does not contain upgrade logic itself, only the means to call upgrade contracts and execute them
/// @dev    We use these upgrade contracts as they allow multiple actions to take place in an upgrade
///         and for these actions to interact. However because we are delegatecalling into these upgrade
///         contracts, it's important that these upgrade contract do not touch or modify contract state.
contract L2DAOExecutor is AccessControlUpgradeable, ReentrancyGuard {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public l2crossDomainMessenger;
    address public l1DAOContract;

    event L2Executed(bool success ,address indexed executor, bytes data);

    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    modifier checkL1() {
        require(
            msg.sender == address(l2crossDomainMessenger) && IL2CrossDomainMessenger(l2crossDomainMessenger).xDomainMessageSender() == l1DAOContract, 
            "only call L1DAOContract"
        );
        _;
    }

    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Initialise the L2CrossDomainMessenger
    /// @param _crossDomainMessenger The admin who can update other roles, and itself - ADMIN_ROLE
    function initialize(
        address _crossDomainMessenger,
        address _l1DAOContract
    ) 
        public 
        onlyOwner 
    {
        l2crossDomainMessenger = _crossDomainMessenger;
        l1DAOContract = _l1DAOContract;
    }

    function execute(
        address target,
        bytes memory functionBytecode
    )
        public
        checkL1
        nonReentrant
    {
        (bool success, ) = address(target).call(functionBytecode);

        emit L2Executed(success, target, functionBytecode);
    }

    function multiExecute(
        address[] memory target,
        bytes[] memory functionBytecode
    )  
        public
        checkL1
        nonReentrant
    {
        for (uint256 i = 0; i < target.length; i++) {
            (bool success, ) = address(target[i]).call(functionBytecode[i]);
            require(success, "DAOCommittee: Failed to execute the agenda");
        }
    }

    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}