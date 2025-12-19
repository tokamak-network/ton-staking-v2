// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IApproveAndCallReceiver {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata data) external;
}

contract MockTON is ERC20 {
    constructor() ERC20("TON", "TON") {
        // Initial supply
        _mint(msg.sender, 50_000_000 * 1e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice approveAndCall 구현 (실제 TON 컨트랙트와 동일)
    function approveAndCall(address spender, uint256 amount, bytes calldata data) external returns (bool) {
        _approve(msg.sender, spender, amount);
        IApproveAndCallReceiver(spender).receiveApproval(msg.sender, amount, address(this), data);
        return true;
    }
}
