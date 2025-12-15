// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWTON is ERC20 {
    address public ton;
    mapping(address => bool) public minters;

    constructor() ERC20("Wrapped TON", "WTON") {}

    function setTON(address _ton) external {
        ton = _ton;
    }

    /// @notice Add a minter (for compatibility with real WTON)
    /// @param account Address to add as minter
    function addMinter(address account) external {
        minters[account] = true;
    }

    /// @notice Check if an address is a minter
    /// @param account Address to check
    function isMinter(address account) external view returns (bool) {
        return minters[account];
    }

    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function swapToTONAndTransfer(address to, uint256 wtonAmount) external returns (bool) {
        _burn(msg.sender, wtonAmount);
        // In real implementation, this would transfer TON
        return true;
    }
}
