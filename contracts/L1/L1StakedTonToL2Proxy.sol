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

    function setSeigManger(address _seigManger) external onlyManager {
        require(seigManger != _seigManger, "same");
        seigManger = _seigManger;
    }

    function setL2SeigManager(address _l2SeigManager) external onlyManager {
        require(l2SeigManager != _l2SeigManager, "same");
        l2SeigManager = _l2SeigManager;
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
