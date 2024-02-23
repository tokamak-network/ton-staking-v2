// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OperatorStorage.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISystemConfig {
    function owner() external view returns (address);
}

/// @title
/// @notice
contract OperatorV1_1 is Ownable, OperatorStorage {
    using SafeERC20 for IERC20;

    event TransferredManager(address previousManager, address newManager);
    event AddedOperator(address operator);
    event DeletedOperator(address operator);


    constructor() { }

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || msg.sender == manager, "not onlyOwnerOrManager");
        _;
    }

    /* ========== onlyOwnerOrManager ========== */
    function transferManager(address newManager) external nonZeroAddress(newManager) onlyOwnerOrManager {
        require (manager != newManager, "same");
        address prevManager = manager;
        manager = newManager;
        emit TransferredManager(prevManager, manager);
    }

    function addOperator(address addr_) external nonZeroAddress(addr_) onlyOwnerOrManager {
        require(!operator[addr_], "already added");
        operator[addr_] = true;
        emit AddedOperator(addr_);
    }

    function deleteOperator(address addr_) external nonZeroAddress(addr_) onlyOwnerOrManager {
        require(operator[addr_], "not operator");
        operator[addr_] = false;
        emit DeletedOperator(addr_);
    }

    /* ========== onlyManager ========== */

    function claim(address token, address to, uint256 amount) external nonZeroAddress(to) onlyManager {
        require(amount != 0, "zero");

        if(token == address(0)) {
            require(address(this).balance >= amount, "insufficient balance");
            payable(to).transfer(amount);

        } else {
            require(IERC20(token).balanceOf(address(this)) >= amount, "insufficient balance");
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /* ========== onlyOperator ========== */


    /* ========== public ========== */
    function acquireManager() external {
        require (msg.sender != manager, "already manager");
        require (msg.sender == ISystemConfig(systemConfig).owner(), "not config's owner");
        address prevManager = manager;
        manager = msg.sender;
        emit TransferredManager(prevManager, manager);
    }

    function isOperator(address addr) external view returns (bool) {
        return operator[addr];
    }

    /* ========== internal ========== */



}