// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/ProxyStorage.sol";
import { AuthControlL2Registry } from "../common/AuthControlL2Registry.sol";
import "./L2RegistryStorage.sol";

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

    /* ========== internal ========== */

    function _registerSystemConfig(address _systemConfig, uint8 _type) internal {
        require(_type != 0, "zero type");
        require(_type <= uint8(type(TYPE_SYSTEMCONFIG).max), "unsupported type");
        require(systemConfigType[_systemConfig] == 0, "already registered");
        systemConfigType[_systemConfig] = _type;

        emit RegisteredSystemConfig(_systemConfig, _type);
    }

}
