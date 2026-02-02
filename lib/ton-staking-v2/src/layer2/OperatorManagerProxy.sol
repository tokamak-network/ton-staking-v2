// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title
/// @notice
contract OperatorManagerProxy is Proxy, ERC1967Upgrade, Ownable {
    // uint256(keccak256("ROLLUP_CONFIG")) - 1
    uint256 private constant _ROLLUP_CONFIG_SLOT =
        0xd8bedf058aa85a36377d4cf75d156448984f1301b93d1653448986b1166437d6;

    constructor(address _rollupConfig) {
        require (_rollupConfig != address(0), "zero rollupConfig");
        _setStorageAddress(_ROLLUP_CONFIG_SLOT, _rollupConfig);
    }

    function _setStorageAddress(uint256 slot, address newAddress) private  {
        assembly {
            sstore(slot, newAddress)
        }
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