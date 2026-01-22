// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDepositManager {
    function deposit(address layer2, address account, uint256 amount) external returns (bool);
}

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

    function swapToTONAndTransfer(address /* to */, uint256 wtonAmount) external returns (bool) {
        _burn(msg.sender, wtonAmount);
        // In real implementation, this would transfer TON
        return true;
    }

    /// @notice receiveApproval callback from TON.approveAndCall
    /// @dev Converts TON to WTON and deposits to DepositManager
    /// @param from User who initiated the approveAndCall
    /// @param amount TON amount (18 decimals)
    /// @param token TON address
    /// @param data abi.encode(depositManager, layer2)
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata data
    ) external {
        require(msg.sender == ton && token == ton, "only TON");

        // Transfer TON from user (using the approval)
        IERC20(ton).transferFrom(from, address(this), amount);

        // Convert TON to WTON (1 TON = 1e9 WTON in RAY)
        uint256 wtonAmount = amount * 1e9;

        // Decode data to get depositManager and layer2
        (address depositManager, address layer2) = abi.decode(data, (address, address));

        // Mint WTON to this contract
        _mint(address(this), wtonAmount);

        // Approve depositManager and deposit
        _approve(address(this), depositManager, wtonAmount);
        IDepositManager(depositManager).deposit(layer2, from, wtonAmount);
    }

    /// @notice onApprove callback from TON.approveAndCall
    /// @dev Converts TON to WTON and deposits to DepositManager
    /// @param owner User who initiated the approveAndCall
    /// @param amount TON amount (18 decimals)
    /// @param data abi.encode(depositManager, layer2)
    function onApprove(
        address owner,
        address /* spender */,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        require(msg.sender == ton, "only TON");

        // TON is already transferred to this contract by approveAndCall
        // Convert TON to WTON (1 TON = 1e9 WTON in RAY)
        uint256 wtonAmount = amount * 1e9;

        // Decode data to get depositManager and layer2
        (address depositManager, address layer2) = abi.decode(data, (address, address));

        // Mint WTON to this contract
        _mint(address(this), wtonAmount);

        // Approve depositManager and deposit
        _approve(address(this), depositManager, wtonAmount);
        IDepositManager(depositManager).deposit(layer2, owner, wtonAmount);

        return true;
    }
}
