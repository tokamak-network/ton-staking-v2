// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/ProxyStorage.sol";
import { AuthControlL1BridgeRegistry } from "../common/AuthControlL1BridgeRegistry.sol";
import "./L1BridgeRegistryStorage.sol";
import "./L1BridgeRegistryV1_1Storage.sol";

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
error NonRejectedError();
error OnlySeigniorageCommitteeError();
error OnlyRejectedError();
error NonRegisterdError();
error BridgeError();
error PortalError();

interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);
}

interface IOptimismSystemConfig {
    function owner() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address addr_);
    function l1StandardBridge() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_) ;
    function l2Ton() external view returns (address addr_) ;
}

interface ILayer2Manager {
    function pauseLayer2Candidate(address systemConfig) external;
    function unpauseLayer2Cnadidate(address systemConfig) external;
}

contract L1BridgeRegistryV1_1 is ProxyStorage, AuthControlL1BridgeRegistry, L1BridgeRegistryStorage, L1BridgeRegistryV1_1Storage {

    enum TYPE_SYSTEMCONFIG {
        NONE,
        LEGARCY,
        OPTIMISM_BEDROCK
    }

    event SetAddresses(address _layer2Manager, address _seigManager, address _ton);
    event SetSeigniorageCommittee(address _seigniorageCommittee);

    /**
     * @notice  Event occurs when registering SystemConfig
     * @param   systemConfig  the systemConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     */
    event RegisteredSystemConfig(address systemConfig, uint8 type_);

    /**
     * @notice  Event occurs when an account with registrant privileges changes the layer 2 type.
     * @param   systemConfig  the systemConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     */
    event ChangedType(address systemConfig, uint8 type_);

    /**
     * @notice  Event occurs when onlySeigniorageCommittee stops issuing seigniorage
     *          to the layer 2 sequencer of a specific systemConfig.
     * @param   _systemConfig  the systemConfig address
     */
    event RejectedLayer2Candidate(address _systemConfig);

    /**
     * @notice  Event occurs when onlySeigniorageCommittee cancels stoping issuing seigniorage
     *          to the layer 2 sequencer of a specific systemConfig.
     * @param   _systemConfig  the systemConfig address
     */
    event RestoredLayer2Candidate(address _systemConfig);

    /**
     * @notice  Event occurs when a bridge address is registered during system configuration registration.
     * @param   _systemConfig   the systemConfig address
     * @param   bridge          the bridge address
     */
    event AddedBridge(address _systemConfig, address bridge);

    /**
     * @notice  Event occurs when a optimismPortal address is registered during system configuration registration.
     * @param _systemConfig     the systemConfig address
     * @param portal            the bridge address
     */
    event AddedPortal(address _systemConfig, address portal);

    modifier onlySeigniorageCommittee() {
        require(seigniorageCommittee == msg.sender, "PermissionError");
        _;
    }

    modifier nonRejected(address systemConfig) {
        require(!rejectSystemConfig[systemConfig], "rejected");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor() {}

    /* ========== onlyOwner ========== */

    /**
     *
     * @param _layer2Manager    the layer2Manager address
     * @param _seigManager      the seigManager address
     * @param _ton              the ton address
     */
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

    /**
     * @notice  Set the seigniorageCommittee address.
     * @param _seigniorageCommittee the seigniorageCommittee address
     */
    function setSeigniorageCommittee(
        address _seigniorageCommittee
    )  external
       onlyOwner
    {
        seigniorageCommittee = _seigniorageCommittee;

        emit SetSeigniorageCommittee(_seigniorageCommittee);
    }

    /* ========== onlySeigniorageCommittee ========== */

    /**
     * @notice Stop issuing seigniorage to the layer 2 sequencer of a specific systemConfig.
     * @param _systemConfig the systemConfig address
     */
    function rejectLayer2Candidate(
        address _systemConfig
    )  external onlySeigniorageCommittee() {
        if(rejectSystemConfig[_systemConfig]) revert NonRejectedError();

        require (rollupType[_systemConfig] != 0, "NonRegistered");

        rejectSystemConfig[_systemConfig] = true;
        ILayer2Manager(layer2Manager).pauseLayer2Candidate(_systemConfig);
        emit RejectedLayer2Candidate(_systemConfig);
    }

    /**
     * Restore cancel stoping seigniorage to the layer 2 sequencer of a specific systemConfig.
     * @param _systemConfig the systemConfig address
     */
    function restoreLayer2Candidate(
        address _systemConfig
    )  external onlySeigniorageCommittee() {
        _onlyRejectedSystemConfig(_systemConfig);

        rejectSystemConfig[_systemConfig] = false;
        ILayer2Manager(layer2Manager).unpauseLayer2Cnadidate(_systemConfig);
        emit RestoredLayer2Candidate(_systemConfig);
    }

    /* ========== onlyManager ========== */

    /**
     * @notice Registers Layer2 for a specific systemConfig by the manager.
     * @param _systemConfig the systemConfig address
     * @param _type          1: legacy, 2: bedrock with nativeTON
     */
    function registerSystemConfigByManager(address _systemConfig, uint8 _type)  external  onlyManager {
        if(rejectSystemConfig[_systemConfig]) revert NonRejectedError();
        _registerSystemConfig(_systemConfig, _type);
    }

    /* ========== onlyRegistrant ========== */


    /**
     * @notice Registers Layer2 for a specific systemConfig by Registrant.
     * @param _systemConfig the systemConfig address
     * @param _type          1: legacy, 2: bedrock with nativeTON
     */
    function registerSystemConfig(address _systemConfig, uint8 _type)  external  onlyRegistrant {
        if(rejectSystemConfig[_systemConfig]) revert NonRejectedError();
        _registerSystemConfig(_systemConfig, _type);
    }

    /**
     * @notice Changes the Layer2 type for a specific systemConfig by Registrant.
     * @param _systemConfig the systemConfig address
     * @param _type          1: legacy, 2: bedrock with nativeTON
     */
    function changeType(address _systemConfig, uint8 _type)  external  onlyRegistrant {
        if (rollupType[_systemConfig] == 0) revert ChangeError(1);
        if (rollupType[_systemConfig] == _type) revert ChangeError(2);

        rollupType[_systemConfig] = _type;

        emit ChangedType(_systemConfig, _type);
    }

    /* ========== public ========== */

    /**
     * @notice View the liquidity of Layer2 TON for a specific systemConfig.
     * @param _systemConfig the systemConfig address
     */
    function layer2TVL(address _systemConfig) public view returns (uint256 amount){

        uint _type = rollupType[_systemConfig];

        if (_type == 1) {
            address l1Bridge_ = IOptimismSystemConfig(_systemConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = IERC20(ton).balanceOf(l1Bridge_);

        } else if (_type == 2) {
             address optimismPortal_ = IOptimismSystemConfig(_systemConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = IERC20(ton).balanceOf(optimismPortal_);
        }
    }

    /**
     * @notice Check whether a specific systemConfig can be registered as a type.
     * @param _systemConfig the systemConfig address
     * @param _type         1: legacy, 2: bedrock with nativeTON
     */
    function availableForRegistration(address _systemConfig, uint8 _type) public view returns (bool valid){
        return _availableForRegistration(_systemConfig, _type);
    }

    /* ========== internal ========== */

    function _nonZeroAddress(address _addr1, address _addr2, address _addr3) internal pure {
        if(_addr1 == address(0) || _addr2 == address(0) || _addr3 == address(0) ) revert ZeroAddressError();
    }

    function _onlyRejectedSystemConfig(address _systemConfig) internal view {
        if(!rejectSystemConfig[_systemConfig]) revert OnlyRejectedError();
    }

    function _registerSystemConfig(address _systemConfig, uint8 _type) internal {

        if (_type == 0 || _type > uint8(type(TYPE_SYSTEMCONFIG).max)) revert RegisterError(1);
        if (rollupType[_systemConfig] != 0) revert RegisterError(2);
        if (!_availableForRegistration(_systemConfig, _type)) revert RegisterError(3);

        rollupType[_systemConfig] = _type;
        if (_type == 1) {
            address bridge_ = IOptimismSystemConfig(_systemConfig).l1StandardBridge();
            if (bridge_ == address(0)) revert BridgeError();
            l1Bridge[bridge_] = true;
            emit AddedBridge(_systemConfig, bridge_);
        } else if (_type == 2) {
            address portal_ = IOptimismSystemConfig(_systemConfig).optimismPortal();
            if (portal_ == address(0)) revert PortalError();
            portal[portal_] = true;
            emit AddedPortal(_systemConfig, portal_);
        }

        emit RegisteredSystemConfig(_systemConfig, _type);
    }

    function _availableForRegistration(address _systemConfig, uint8 _type) internal view returns (bool valid){
        if (!rejectSystemConfig[_systemConfig]) {
            address l1Bridge_ = IOptimismSystemConfig(_systemConfig).l1StandardBridge();
            if(l1Bridge_ != address(0)) {
                if (_type == 1) {
                    if(rollupType[_systemConfig] == 0 && !l1Bridge[l1Bridge_]) valid = true;
                } else if (_type == 2) {
                    address portal_ = IOptimismSystemConfig(_systemConfig).optimismPortal();
                    if (portal_ != address(0)) {
                        if (rollupType[_systemConfig] == 0 && !portal[portal_]) valid = true;
                    }
                }
            }
        }
    }
}
