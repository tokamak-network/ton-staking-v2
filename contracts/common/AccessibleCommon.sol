//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessibleCommon is  ERC165Storage, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        require(!hasRole(DEFAULT_ADMIN_ROLE, account), "already granted");
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        require(hasRole(DEFAULT_ADMIN_ROLE, account), "already not granted");
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
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

    function transferOwnership(address newAdmin) public virtual {
        transferAdmin(newAdmin);
    }

    function renounceOwnership() public onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isOwner() public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Storage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
