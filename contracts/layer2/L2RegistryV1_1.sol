// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/ProxyStorage.sol";
import { AuthControlL2Registry } from "../common/AuthControlL2Registry.sol";
import "./L2RegistryStorage.sol";

// import "hardhat/console.sol";
interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);
}


/**
 * @notice  Error occurred when executing changeType function
 * @param x 1: sender is not ton nor wton
 *          2: wrong spender parameter
 */
error ChangeError(uint x);

/**
 * @notice  Error when executing registerSystemConfig function
 * @param x 1: unsupported type
 *          2: already registered
 *          3: unavailable for registration
 */
error RegisterError(uint x);
error ZeroAddressError();


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

    event SetAddresses(address _layer2Manager, address _seigManager, address _ton);
    event RegisteredSystemConfig(address systemConfig, uint8 type_);
    event ChangedType(address systemConfig, uint8 type_);

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    /* ========== onlyOwner ========== */
    function setAddresses(
        address _layer2Manager,
        address _seigManager,
        address _ton
    )  external onlyOwner {
        _nonZeroAddress(_layer2Manager, _seigManager,_ton );
        layer2Manager = _layer2Manager;
        seigManager = _seigManager;
        ton = _ton;

        emit SetAddresses(_layer2Manager, _seigManager, _ton);
    }

    /* ========== onlyManager ========== */
    function registerSystemConfigByManager(address _systemConfig, uint8 _type)  external  onlyManager {
        _registerSystemConfig(_systemConfig, _type);
    }

    /* ========== onlyRegistrant ========== */

    function changeType(address _systemConfig, uint8 _type)  external  onlyRegistrant {
        // require(systemConfigType[_systemConfig] != 0, "unregistered");
        // require(systemConfigType[_systemConfig] != _type, "same type");

        if (systemConfigType[_systemConfig] == 0) revert ChangeError(1);
        if (systemConfigType[_systemConfig] == _type) revert ChangeError(2);

        systemConfigType[_systemConfig] = _type;

        emit ChangedType(_systemConfig, _type);
    }

    function registerSystemConfig(address _systemConfig, uint8 _type)  external  onlyRegistrant {
        _registerSystemConfig(_systemConfig, _type);
    }

    /* ========== public ========== */
    function layer2TVL(address _systemConfig) public view returns (uint256 amount){

        uint _type = systemConfigType[_systemConfig];
        if (_type == 1) {
            address l1Bridge_ = ISystemConfig(_systemConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = IERC20(ton).balanceOf(l1Bridge_);

        } else if (_type == 2) {
             address optimismPortal_ = ISystemConfig(_systemConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = IERC20(ton).balanceOf(optimismPortal_);
        }
    }

    // function checkLayer2TVL(address _systemConfig) external view returns (bool result, uint256 amount) {
    //     amount = layer2TVL(_systemConfig);

    //     if (amount > 0) result = true;
    //     else if (systemConfigType[_systemConfig] == 1 || systemConfigType[_systemConfig] ==2 ) result = true;
    // }

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
    /* ========== internal ========== */

    function _nonZeroAddress(address _addr1, address _addr2, address _addr3) internal pure {
        if(_addr1 == address(0) || _addr2 == address(0) || _addr3 == address(0) ) revert ZeroAddressError();
    }

    function _registerSystemConfig(address _systemConfig, uint8 _type) internal {

        if (_type == 0 || _type > uint8(type(TYPE_SYSTEMCONFIG).max)) revert RegisterError(1);
        if (systemConfigType[_systemConfig] != 0) revert RegisterError(2);
        if (!availableForRegistration(_systemConfig, _type)) revert RegisterError(3);

        systemConfigType[_systemConfig] = _type;
        l1Bridge[ISystemConfig(_systemConfig).l1StandardBridge()] = true;

        emit RegisteredSystemConfig(_systemConfig, _type);
    }

}
