// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/ProxyStorage.sol";
import { AuthControlL2Registry } from "../common/AuthControlL2Registry.sol";
import "./L2RegistryStorage.sol";
import "./L2RegistryV1_1Storage.sol";


// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "hardhat/console.sol";
interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);
}

interface ISystemConfig {
    function owner() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address addr_);
    function l1StandardBridge() external view returns (address addr_);
    function l2OutputOracle() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_) ;
    function l2Ton() external view returns (address addr_) ;
}


interface ILayer2Manager {
    function pauseLayer2Candidate(address systemConfig) external;
    function unpauseLayer2Cnadidate(address systemConfig) external;
}

contract L2RegistryV1_1 is ProxyStorage, AuthControlL2Registry, L2RegistryStorage, L2RegistryV1_1Storage {

    enum TYPE_SYSTEMCONFIG {
        NONE,
        LEGARCY,
        OPTIMISM_BEDROCK
    }

    event SetAddresses(address _layer2Manager, address _seigManager, address _ton);
    event RegisteredSystemConfig(address systemConfig, uint8 type_);
    event ChangedType(address systemConfig, uint8 type_);
    event SetSeigniorageCommittee(address _seigniorageCommittee);
    event RejectedLayer2Candidate(address _systemConfig);
    event RestoredLayer2Candidate(address _systemConfig);

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    modifier onlySystemConfig() {
        require(systemConfigType[msg.sender] != 0, "unregistered systemConfig");
        _;
    }

    modifier onlyLayer2Manager() {
        require(layer2Manager == msg.sender, "sender is not layer2Manager");
        _;
    }

    modifier onlySeigniorageCommittee() {
        require(seigniorageCommittee == msg.sender, "sender is not seigniorageCommittee");
        _;
    }

    modifier nonZero(uint256 value) {
        require(value != 0, "zero");
        _;
    }

    modifier nonZeroAddress(address value) {
        require(value != address(0), "zero address");
        _;
    }

    modifier nonRejected(address systemConfig) {
        require(!rejectSystemConfig[systemConfig], "rejected");
        _;
    }

    /* ========== onlyOwner ========== */
    function setAddresses(
        address _layer2Manager,
        address _seigManager,
        address _ton
    )  external
        nonZeroAddress(_layer2Manager)
        nonZeroAddress(_seigManager)
        nonZeroAddress(_ton)
        onlyOwner
    {

        layer2Manager = _layer2Manager;
        seigManager = _seigManager;
        ton = _ton;

        emit SetAddresses(_layer2Manager, _seigManager, _ton);
    }

    function setSeigniorageCommittee(
        address _seigniorageCommittee
    )  external
       onlyOwner
    {
        seigniorageCommittee = _seigniorageCommittee;

        emit SetSeigniorageCommittee(_seigniorageCommittee);
    }

    /* ========== onlySeigniorageCommittee ========== */

    function rejectLayer2Candidate(
        address _systemConfig
    )  external
       onlySeigniorageCommittee nonRejected(_systemConfig)
    {
        require (systemConfigType[_systemConfig] != 0, "not registered layer2");

        ILayer2Manager(layer2Manager).pauseLayer2Candidate(_systemConfig);
        emit RejectedLayer2Candidate(_systemConfig);
    }

    function restoreLayer2Candidate(
        address _systemConfig
    )  external
       onlySeigniorageCommittee
    {
        require (rejectSystemConfig[_systemConfig], "not rejected");
        rejectSystemConfig[_systemConfig] = false;
        ILayer2Manager(layer2Manager).unpauseLayer2Cnadidate(_systemConfig);
        emit RestoredLayer2Candidate(_systemConfig);
    }

    /* ========== onlyManager ========== */
    function registerSystemConfigByManager(address _systemConfig, uint8 _type)  external  onlyManager  nonRejected(_systemConfig){
        _registerSystemConfig(_systemConfig, _type);
    }

    /* ========== onlyRegistrant ========== */

    function changeType(address _systemConfig, uint8 _type)  external  onlyRegistrant  nonRejected(_systemConfig){
        require(systemConfigType[_systemConfig] != 0, "unregistered");
        require(systemConfigType[_systemConfig] != _type, "same type");
        systemConfigType[_systemConfig] = _type;

        emit ChangedType(_systemConfig, _type);
    }

    function registerSystemConfig(address _systemConfig, uint8 _type)  external  onlyRegistrant  nonRejected(_systemConfig){
        _registerSystemConfig(_systemConfig, _type);
    }

    /* ========== public ========== */
    function layer2TVL(address _systemConfig) external view returns (uint256 amount){

        uint _type = systemConfigType[_systemConfig];
        if (_type == 1) {
            address l1Bridge_ = ISystemConfig(_systemConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = IERC20(ton).balanceOf(l1Bridge_);

        } else if (_type == 2) {
             address optimismPortal_ = ISystemConfig(_systemConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = IERC20(ton).balanceOf(optimismPortal_);
        }
    }

    function availableForRegistration(address _systemConfig, uint8 _type) public view returns (bool valid){
        if (rejectSystemConfig[_systemConfig]) {
            valid = false;
        } else {
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

}
