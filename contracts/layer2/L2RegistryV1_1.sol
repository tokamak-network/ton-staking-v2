// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/ProxyStorage.sol";
import { AuthControlL2Registry } from "../common/AuthControlL2Registry.sol";
import "./L2RegistryStorage.sol";

import "hardhat/console.sol";

interface ISystemConfig {
    function owner() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address addr_);
    function l1StandardBridge() external view returns (address addr_);
    function l2OutputOracle() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_) ;
    function l2Ton() external view returns (address addr_) ;
}

contract L2RegistryV1_1 is ProxyStorage, AuthControlL2Registry, L2RegistryStorage {

    enum TYPE_SYSTEMCONFIG {
        NONE,
        LEGARCY,
        OPTIMISM_BEDROCK
    }

    event RegisteredSystemConfig(address systemConfig, uint8 type_);
    event ChangedType(address systemConfig, uint8 type_);

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    modifier onlySystemConfig() {
        require(systemConfigType[msg.sender] != 0, "unregistered systemConfig");
        _;
    }

    modifier nonZero(uint256 value) {
        require(value != 0, "zero");
        _;
    }
    /* ========== onlyOwner ========== */

    /* ========== onlyManager ========== */

    function registerSystemConfigByManager(address _systemConfig, uint8 _type)  external  onlyManager {
        _registerSystemConfig(_systemConfig, _type);
    }

    function changeType(address _systemConfig, uint8 _type)  external  onlyManager {
        require(systemConfigType[_systemConfig] != 0, "unregistered");
        require(systemConfigType[_systemConfig] != _type, "same type");
        systemConfigType[_systemConfig] = _type;

        emit ChangedType(_systemConfig, _type);
    }

    /* ========== onlyOperator ========== */

    function registerSystemConfig(address _systemConfig, uint8 _type)  external  onlyOperator {
        _registerSystemConfig(_systemConfig, _type);
    }

    /* ========== onlySystemConfig ========== */
    function increaseTvl(uint256 amount) external onlySystemConfig nonZero(amount) {
            tvlL2[msg.sender] += amount;
    }

    function decreaseTvl(uint256 amount) external onlySystemConfig nonZero(amount) {
            if(tvlL2[msg.sender] > amount)  tvlL2[msg.sender] -= amount;
            else tvlL2[msg.sender] = 0;
    }

    // function resetTvl(uint256 amount) external onlySystemConfig {
    //      tvlL2[msg.sender] = amount;
    // }

    /* ========== internal ========== */

    function _registerSystemConfig(address _systemConfig, uint8 _type) internal {
        require(_type != 0, "zero type");
        require(_type <= uint8(type(TYPE_SYSTEMCONFIG).max), "unsupported type");
        require(systemConfigType[_systemConfig] == 0, "already registered");
        require(availableForRegistration(_systemConfig, _type), "unavailable for registration");

        systemConfigType[_systemConfig] = _type;
        l1Bridge[ISystemConfig(_systemConfig).l1StandardBridge()] = true;

        emit RegisteredSystemConfig(_systemConfig, _type);
    }


    function availableForRegistration(address _systemConfig, uint8 _type) public view returns (bool valid){
        address l1Bridge_ = ISystemConfig(_systemConfig).l1StandardBridge();
        if(l1Bridge_ != address(0)) {

            if (_type == 1) {
                if(systemConfigType[_systemConfig] == 0 && l1Bridge[l1Bridge_] == false) {
                    valid = true;
                }
            } else if (_type == 2) {

                address portal_ = ISystemConfig(_systemConfig).optimismPortal();
                if(portal_ != address(0)) {
                    if(systemConfigType[_systemConfig] == 0 && !portal[portal_]) {
                        valid = true;
                    }
                }
            }
        }
    }

}
