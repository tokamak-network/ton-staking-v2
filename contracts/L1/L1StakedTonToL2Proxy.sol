// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../proxy/Proxy.sol";
import "./L1StakedTonToL2Storage.sol";

contract L1StakedTonToL2Proxy is Proxy, L1StakedTonToL2Storage
{
    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    constructor() {
        manager = msg.sender;
    }

    function renounceManagership() external onlyManager {
        emit ManagershipTransferred(manager, address(0));
        manager = address(0);
    }

    function transferManagership(address newManager) external onlyManager {
        require(newManager != address(0), "new manager is the zero address");
        emit ManagershipTransferred(manager, newManager);
        manager = newManager;
    }

}
