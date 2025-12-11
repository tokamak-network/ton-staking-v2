// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockTON is ERC20 {
    constructor() ERC20("TON", "TON") {
        // Initial supply
        _mint(msg.sender, 50_000_000 * 1e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
