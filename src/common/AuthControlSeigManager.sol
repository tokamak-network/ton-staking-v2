//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AuthRole.sol";

contract AuthControlSeigManager is AuthRole, ERC165Storage, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "AuthControl: Caller is not an admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "AuthControl: Caller is not a minter");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "AuthControl: Caller is not an operator");
        _;
    }

    modifier onlyChallenger() {
        require(hasRole(CHALLENGER_ROLE, msg.sender), "AuthControl: Caller is not a challenger");
        _;
    }

    modifier onlyPauser() {
        require(hasRole(PAUSE_ROLE, msg.sender), "AuthControl: Caller is not a pauser");
        _;
    }

    modifier onlyMinterOrAdmin() {
        require(isAdmin(msg.sender) || hasRole(MINTER_ROLE, msg.sender), "not onlyMinterOrAdmin");
        _;
    }

    modifier onlyChallengerOrAdmin() {
        require(isAdmin(msg.sender) || hasRole(CHALLENGER_ROLE, msg.sender), "not onlyChallengerOrAdmin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        require(!hasRole(DEFAULT_ADMIN_ROLE, account), "already granted");
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function addMinter(address account) public virtual onlyOwner {
        require(!hasRole(MINTER_ROLE, account), "already granted");
        _grantRole(MINTER_ROLE, account);
    }

    function addOperator(address account) public virtual onlyOwner {
        require(!hasRole(OPERATOR_ROLE, account), "already granted");
        _grantRole(OPERATOR_ROLE, account);
    }

    function addChallenger(address account) public virtual onlyChallengerOrAdmin {
        require(!hasRole(CHALLENGER_ROLE, account), "already granted");
        _grantRole(CHALLENGER_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        require(hasRole(DEFAULT_ADMIN_ROLE, account), "already not granted");
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeMinter(address account) public virtual onlyOwner {
        require(hasRole(MINTER_ROLE, account), "already not granted");
        _revokeRole(MINTER_ROLE, account);
    }

    function removeChallenger(address account) public virtual onlyOwner {
        require(hasRole(CHALLENGER_ROLE, account), "already not granted");
        _revokeRole(CHALLENGER_ROLE, account);
    }

    function removeOperator(address account) public virtual onlyOwner {
        require(hasRole(OPERATOR_ROLE, account), "already not granted");
        _revokeRole(OPERATOR_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");
        require(!hasRole(DEFAULT_ADMIN_ROLE, newAdmin), "already granted");

        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function renounceOwnership() public onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function renounceMinter() public {
        require(hasRole(MINTER_ROLE, msg.sender), "already not granted");
        _revokeRole(MINTER_ROLE, msg.sender);
    }

    function renounceOperator() public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "already not granted");
        _revokeRole(OPERATOR_ROLE, msg.sender);
    }

    function renounceChallenger() public {
        require(hasRole(CHALLENGER_ROLE, msg.sender), "already not granted");
        _revokeRole(CHALLENGER_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isOwner() public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isMinter(address account) public view virtual returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isOperator(address account) public view virtual returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function isChallenger(address account) public view virtual returns (bool) {
        return hasRole(CHALLENGER_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Storage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}