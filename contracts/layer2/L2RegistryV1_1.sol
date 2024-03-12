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
    event SetLayer2Manager(address _layer2Manager);
    event UpdatedRewardPerUnit(uint256 rewardPerUnit, uint256 unReflectedSeigs, uint256 amount) ;
    event ClaimedSeigniorage(address systemConfig, uint256 amount);
    event SetMinimumRelectedAmount(uint256 _minimumRelectedAmount);

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

    // modifier onlySeigManager() {
    //     require(seigManager == msg.sender, "sender is not seigManager");
    //     _;
    // }

    modifier nonZero(uint256 value) {
        require(value != 0, "zero");
        _;
    }

    /* ========== onlyOwner ========== */
    function setLayer2Manager(address _layer2Manager)  external  onlyOwner {
        require(_layer2Manager != address(0), "zero layer2Manager");
        require(layer2Manager != _layer2Manager, "same");
        layer2Manager = _layer2Manager;

        emit SetLayer2Manager(_layer2Manager);
    }

    function setSeigManager(address _seigManager)  external  onlyOwner {
        require(_seigManager != address(0), "zero seigManager");
        require(seigManager != _seigManager, "same");
        seigManager = _seigManager;

        emit SetLayer2Manager(_seigManager);
    }


    function setMinimumRelectedAmount(uint256 _minimumRelectedAmount)  external  onlyOwner {
        require(minimumRelectedAmount != _minimumRelectedAmount, "same");
        minimumRelectedAmount = _minimumRelectedAmount;

        emit SetMinimumRelectedAmount(_minimumRelectedAmount);
    }


    /* ========== onlyManager ========== */
    function registerSystemConfigByManager(address _systemConfig, uint8 _type)  external  onlyManager {
        _registerSystemConfig(_systemConfig, _type);
    }



    /// to do..
    function resetTvl(address _systemConfig, uint256 amount) external onlyManager returns (bool) {
        uint256 oldAmount = l2Info[_systemConfig].l2Tvl;
        totalTvl = totalTvl + amount - oldAmount;
        l2Info[_systemConfig].l2Tvl = amount;
        return true;
    }

    /* ========== onlyOperator ========== */

    function changeType(address _systemConfig, uint8 _type)  external  onlyOperator {
        require(systemConfigType[_systemConfig] != 0, "unregistered");
        require(systemConfigType[_systemConfig] != _type, "same type");
        systemConfigType[_systemConfig] = _type;

        emit ChangedType(_systemConfig, _type);
    }

    function registerSystemConfig(address _systemConfig, uint8 _type)  external  onlyOperator {
        _registerSystemConfig(_systemConfig, _type);
    }

    /* ========== onlySystemConfig ========== */

    function increaseTvl(uint256 amount) external onlySystemConfig returns (bool) {
        if (amount != 0) {
            Layer2Info storage info = l2Info[msg.sender];
            if (info.initialDebt == 0) info.initialDebt = rewardPerUnit * amount / 1e18;
            info.l2Tvl += amount;
            totalTvl += amount;
        }
        return true;
    }

    function decreaseTvl(uint256 amount) external onlySystemConfig returns (bool) {

        if (totalTvl >= amount && l2Info[msg.sender].l2Tvl >= amount && amount != 0 ) {
            Layer2Info storage info = l2Info[msg.sender];

            uint256 curAmount = rewardPerUnit * info.l2Tvl / 1e18;
            if (curAmount >= info.initialDebt )  curAmount -= info.initialDebt;
            else curAmount = 0;
            if (curAmount >= info.claimedAmount ) curAmount -= info.claimedAmount;
            else curAmount = 0;

            info.unClaimedAmount += curAmount;
            info.initialDebt = rewardPerUnit * amount / 1e18;
            info.claimedAmount = 0;
            info.l2Tvl -= amount;
            totalTvl -= amount;
        }
        return true;
    }

     /* ========== onlyLayer2Manager ========== */


    function updateSeigniorage(uint256 amount) external onlyLayer2Manager {

        unReflectedSeigs += amount;
        if (unReflectedSeigs > minimumRelectedAmount && totalTvl != 0) {
            rewardPerUnit += (unReflectedSeigs * 1e18 / totalTvl) ;
            unReflectedSeigs = 0;
        }

        emit UpdatedRewardPerUnit(rewardPerUnit, unReflectedSeigs, amount);
    }

    function claimSeigniorage(address systemConfig) external onlyLayer2Manager returns(uint256 amount){
        amount = claimableSeigniorage(systemConfig);
        require(amount != 0 , "no claimable seigniorage");
        l2Info[systemConfig].claimedAmount += amount;
        l2Info[systemConfig].unClaimedAmount = 0;

         emit ClaimedSeigniorage(systemConfig, amount);
    }

     /* ========== public ========== */

    function claimableSeigniorage(address systemConfig) public view returns (uint256 amount) {
        Layer2Info memory info = l2Info[systemConfig];

        amount = rewardPerUnit * info.l2Tvl / 1e18;
        if (amount >= info.initialDebt )  amount -= info.initialDebt;
        else amount = 0;

        if (amount >= info.claimedAmount ) amount -= info.claimedAmount;
        else amount = 0;

        amount += info.unClaimedAmount;
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
