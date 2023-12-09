// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../proxy/Proxy.sol";
import "./L1StakedTonToL2Storage.sol";

contract L1StakedTonToL2Proxy is Proxy, L1StakedTonToL2Storage
{
    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    constructor() {
        _manager = msg.sender;
    }

    function setSeigManger(address _seigManager) external onlyManager {
        require(seigManager != _seigManager, "same");
        seigManager = _seigManager;
    }

    function setL1StakedTonInL2(address _l1StakedTonInL2) external onlyManager {
        require(l1StakedTonInL2 != _l1StakedTonInL2, "same");
        l1StakedTonInL2 = _l1StakedTonInL2;
    }

    function setAddressManager(address addressManagerAddress) external onlyManager {
        require(addressManager != addressManagerAddress, "same");
        addressManager = addressManagerAddress;
    }

    function renounceManagership() external onlyManager {
        emit ManagershipTransferred(_manager, address(0));
        _manager = address(0);
    }

    function transferManagership(address newManager) external onlyManager {
        require(newManager != address(0), "new manager is the zero address");
        emit ManagershipTransferred(_manager, newManager);
        _manager = newManager;
    }

}
