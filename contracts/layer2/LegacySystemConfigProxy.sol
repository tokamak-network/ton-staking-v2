// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./LegacySystemConfigStorage.sol";

/// @title
/// @notice
contract LegacySystemConfigProxy is Proxy, ERC1967Upgrade, Ownable, LegacySystemConfigStorage {

    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyProxyOwner() {
        require(proxyOwner == msg.sender, "LegacySystemConfigProxy: caller is not the proxyOwner");
        _;
    }

    constructor() {
        proxyOwner = msg.sender;
     }

     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        address oldOwner = proxyOwner;
        proxyOwner = newOwner;
        emit ProxyOwnershipTransferred(oldOwner, newOwner);

    }

    function upgradeTo(address newImplementation) external onlyProxyOwner {
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address _logic, bytes memory _data) external onlyProxyOwner {
         _upgradeToAndCall(_logic, _data, false);
    }

    function implementation() external view  returns (address impl) {
        return _implementation();
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}