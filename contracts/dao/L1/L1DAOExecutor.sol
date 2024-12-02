// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IL1CrossDomainMessenger } from "../interfaces/IL1CrossDomainMessenger.sol";


/// @title  A root contract from which it execute upgrades
/// @notice Does not contain upgrade logic itself, only the means to call upgrade contracts and execute them
/// @dev    We use these upgrade contracts as they allow multiple actions to take place in an upgrade
///         and for these actions to interact. However because we are delegatecalling into these upgrade
///         contracts, it's important that these upgrade contract do not touch or modify contract state.
contract L1DAOExecutor is AccessControlUpgradeable, ReentrancyGuard {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public l1crossDomainMessenger;
    address public l1DAOContract;
    address public l2DAOContract;

    event L1Executed(address indexed executor, bytes data);

    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Initialise the L1DAOExecutor
    /// @param _l1crossDomainMessenger l1crossDomainMessenger Address
    /// @param _l1DAOContract l1DAOContract Address
    /// @param _l2DAOContract l2DAOContract Address
    function initialize(
        address _l1crossDomainMessenger
        address _l1DAOContract,
        address _l2DAOContract
    ) 
        public 
        onlyOwner 
    {
        l1crossDomainMessenger = _l1crossDomainMessenger;
        l1DAOContract = _l1DAOContract;
        l2DAOContract = _l2DAOContract;
    }

    function execute(
        bytes memory message,
        uint32 _minGasLimit
    )
        public
        nonReentrant
    {
        IL1CrossDomainMessenger(l1crossDomainMessenger).sendMessage(
            l2DAOContract, 
            message, 
            _minGasLimit
        );


        emit L1Executed(l2DAOContract, message);
    }

    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}