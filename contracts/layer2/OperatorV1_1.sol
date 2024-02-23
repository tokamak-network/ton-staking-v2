// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./OperatorStorage.sol";

/// @title
/// @notice
contract OperatorV1_1 is Ownable, OperatorStorage {
    address public systemConfig;

    event OperateInitialized(address systemConfig);

    receive() external payable {}

    /* ========== CONSTRUCTOR ========== */
    constructor() { }

}