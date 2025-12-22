// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IOnApprove {
    function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool);
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
    /// @dev 토큰을 spender에게 전송한 후 onApprove 콜백 호출
    function approveAndCall(address spender, uint256 amount, bytes calldata data) external returns (bool) {
        // Approve first (for compatibility)
        _approve(msg.sender, spender, amount);

        // Transfer tokens to spender
        _transfer(msg.sender, spender, amount);

        // Call onApprove callback
        require(
            IOnApprove(spender).onApprove(msg.sender, spender, amount, data),
            "TON: onApprove failed"
        );

        return true;
    }
}
