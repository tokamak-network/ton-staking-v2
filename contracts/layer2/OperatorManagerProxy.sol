// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title
/// @notice
contract OperatorManagerProxy is Proxy, ERC1967Upgrade, Ownable {
    address public rollupConfig;

    constructor(address _rollupConfig) {
        rollupConfig = _rollupConfig;
    }

    function upgradeTo(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address _logic, bytes memory _data) external onlyOwner {
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