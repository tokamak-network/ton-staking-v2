// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/ProxyStorage.sol";
import { AuthControlL1BridgeRegistry } from "../common/AuthControlL1BridgeRegistry.sol";
import "./L1BridgeRegistryStorage.sol";
/**
 * @notice  Error occurred when executing changeType function
 * @param x 1: sender is not ton nor wton
 *          2: wrong spender parameter
 *          3: zeroAddress l2 ton
 *          4: empty name
 */
error ChangeError(uint x);

/**
 * @notice  Error when executing registerRollupConfig function
 * @param x 1: unsupported type
 *          2: already registered
 *          3: unavailable for registration
 *          4: zero L2TON
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
    function l1StandardBridge() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_) ;
}

interface ILayer2Manager {
    function pauseCandidateAddOn(address rollupConfig) external;
    function unpauseCandidateAddOn(address rollupConfig) external;
}

contract L1BridgeRegistryV1_1 is ProxyStorage, AuthControlL1BridgeRegistry, L1BridgeRegistryStorage {

    enum TYPE_ROLLUPCONFIG {
        NONE,
        LEGARCY,
        OPTIMISM_BEDROCK
    }

    event SetAddresses(address _layer2Manager, address _seigManager, address _ton);
    event SetSeigniorageCommittee(address _seigniorageCommittee);

    /**
     * @notice  Event occurs when registering rollupConfig
     * @param   rollupConfig      the rollupConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     * @param   l2TON        the L2 TON address
     * @param   name         the candidate name
     */
    event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2TON, string name);

    /**
     * @notice  Event occurs when an account with registrant privileges changes the layer 2 type.
     * @param   rollupConfig      the rollupConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     * @param   l2TON        the L2 TON address
     * @param   name         the candidate name
     */
    event ChangedType(address rollupConfig, uint8 type_, address l2TON, string name);

    /**
     * @notice  Event occurs when onlySeigniorageCommittee stops issuing seigniorage
     *          to the layer 2 sequencer of a specific rollupConfig.
     * @param   rollupConfig  the rollupConfig address
     */
    event RejectedCandidateAddOn(address rollupConfig);

    /**
     * @notice  Event occurs when onlySeigniorageCommittee cancels stopping issuing seigniorage
     *          to the layer 2 sequencer of a specific rollupConfig.
     * @param   rollupConfig  the rollupConfig address
     */
    event RestoredCandidateAddOn(address rollupConfig);

    /**
     * @notice  Event occurs when a bridge address is registered during system configuration registration.
     * @param   rollupConfig    the rollupConfig address
     * @param   bridge          the bridge address
     */
    event AddedBridge(address rollupConfig, address bridge);

    /**
     * @notice  Event occurs when an optimismPortal address is registered during system configuration registration.
     * @param rollupConfig          the rollupConfig address
     * @param portal            the bridge address
     */
    event AddedPortal(address rollupConfig, address portal);

    /**
     * @notice  Event occurs when an optimismPortal address is registered during system configuration registration.
     * @param rollupConfig          the rollupConfig address
     * @param rejectedL2Deposit     if it is true, allow the withdrawDepositL2 function.
     */
    event SetBlockingL2Deposit(address rollupConfig, bool rejectedL2Deposit);

    modifier onlySeigniorageCommittee() {
        require(seigniorageCommittee == msg.sender, "PermissionError");
        _;
    }

    modifier nonRejected(address rollupConfig) {
        require(!rollupInfo[rollupConfig].rejectedSeigs, "rejected");
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

    // /**
    //  * Sets whether to allow the withdrawDepositL2 function.
    //  * @param rollupConfig          the rollupConfig address
    //  * @param rejectedL2Deposit     if it is true, allow the withdrawDepositL2 function.
    //  */
    // function setBlockingL2Deposit(
    //     address rollupConfig,
    //     bool rejectedL2Deposit
    // )  external onlySeigniorageCommittee {

    //     require (rollupInfo[rollupConfig].rollupType != 0, "NonRegistered");

    //     rollupInfo[rollupConfig].rejectedL2Deposit = rejectedL2Deposit;

    //     emit SetBlockingL2Deposit(rollupConfig, rejectedL2Deposit);
    // }

    /// @dev
    // function resetRollupConfig(address rollupConfig)  external  onlyOwner {
    // _resetRollupConfig(rollupConfig);
    // }

    /* ========== onlySeigniorageCommittee ========== */

    /**
     * @notice Stop issuing seigniorage to the layer 2 sequencer of a specific rollupConfig.
     * @param rollupConfig the rollupConfig address
     */
    function rejectCandidateAddOn(
        address rollupConfig
    )  external onlySeigniorageCommittee() {
        _nonRejected(rollupConfig);

        require (rollupInfo[rollupConfig].rollupType != 0, "NonRegistered");

        rollupInfo[rollupConfig].rejectedSeigs = true;
        rollupInfo[rollupConfig].rejectedL2Deposit = true;

        ILayer2Manager(layer2Manager).pauseCandidateAddOn(rollupConfig);
        emit RejectedCandidateAddOn(rollupConfig);
    }

    /**
     * Restore cancel stopping seigniorage to the layer 2 sequencer of a specific rollupConfig.
     * @param rollupConfig          the rollupConfig address
     * @param rejectedL2Deposit     if it is true, allow the withdrawDepositL2 function.
     */
    function restoreCandidateAddOn(
        address rollupConfig,
        bool rejectedL2Deposit
    )  external onlySeigniorageCommittee{
        _onlyRejectedRollupConfig(rollupConfig);

        rollupInfo[rollupConfig].rejectedSeigs = false;
        rollupInfo[rollupConfig].rejectedL2Deposit = rejectedL2Deposit;

        ILayer2Manager(layer2Manager).unpauseCandidateAddOn(rollupConfig);
        emit RestoredCandidateAddOn(rollupConfig);
    }

    /* ========== onlyManager ========== */

    /**
     * @notice Registers Layer2 for a specific rollupConfig by the manager.
     * @param rollupConfig      the rollupConfig address
     * @param _type         1: legacy, 2: bedrock with nativeTON
     */
    function registerRollupConfigByManager(address rollupConfig, uint8 _type, address _l2TON, string calldata _name)  external  onlyManager {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2TON, _name);
    }

    /* ========== onlyRegistrant ========== */

    /**
     * @notice Registers Layer2 for a specific rollupConfig by Registrant.
     * @param rollupConfig       the rollupConfig address
     * @param _type          1: legacy, 2: bedrock with nativeTON
     */
    function registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON, string calldata _name)  external onlyRegistrant {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2TON, _name);
    }

    /**
     * @notice Changes the Layer2 type for a specific rollupConfig by Registrant.
     * @param rollupConfig the rollupConfig address
     * @param _type          1: legacy, 2: bedrock with nativeTON
     * @param _name          the candidate name
     */
    function changeType(address rollupConfig, uint8 _type, address _l2TON, string calldata _name)  external  onlyRegistrant {

        ROLLUP_INFO memory info = rollupInfo[rollupConfig];
        if (info.rollupType == 0) revert ChangeError(1);
        if (info.rollupType == _type) revert ChangeError(2);
        if (_l2TON == address(0)) revert ChangeError(3);
        if (bytes(_name).length == 0) revert ChangeError(4);

        _resetRollupConfig(rollupConfig) ;
        _registerRollupConfig(rollupConfig, _type, _l2TON, _name);

        emit ChangedType(rollupConfig, _type, _l2TON, _name);
    }

    /* ========== public ========== */

    /**
     * @notice View the rollupType of rollupConfig
     * @param rollupConfig the rollup address
     * @return rollupType_  the rollupType 0:empty, 1: optimism legacy, 2: optimism bedrock native TON)
     */
    function rollupType(address rollupConfig) external view returns(uint8 rollupType_) {
        return  rollupInfo[rollupConfig].rollupType;
    }

    /**
     * @notice Returns whether the issuance of seigniorage to the given layer 2 is restricted.
     * @param rollupConfig the rollup address
     * @return rejectedSeigs  If it is true, Seigniorage issuance has been stopped for this layer2.
     */
    function rejectRollupConfig(address rollupConfig) external view returns(bool rejectedSeigs) {
        return  rollupInfo[rollupConfig].rejectedSeigs;
    }

    /**
     * @notice Returns whether the issuance of seigniorage to the given layer 2 is restricted.
     * @param rollupConfig the rollup address
     * @return rejectedSeigs  If it is true, Seigniorage issuance has been stopped for this layer2.
     */
    function isRejectedSeigs(address rollupConfig) external view returns(bool rejectedSeigs) {
        return  rollupInfo[rollupConfig].rejectedSeigs;
    }

    /**
     * @notice Returns whether the issuance of seigniorage to the given layer 2 is restricted.
     * @param rollupConfig the rollup address
     * @return rejectedL2Deposit  If it is true, stop depositing at this layer.
     */
    function isRejectedL2Deposit(address rollupConfig) external view returns(bool rejectedL2Deposit) {
        return  rollupInfo[rollupConfig].rejectedL2Deposit;
    }

    /**
     * @notice View the l2 ton address of rollupConfig
     * @param rollupConfig the rollup address
     * @return l2TonAddress  the l2 ton address
     */
    function l2TON(address rollupConfig) external view returns(address l2TonAddress) {
        return  rollupInfo[rollupConfig].l2TON;
    }

    /**
     * @notice View the l2 ton address of rollupConfig
     * @param rollupConfig          the rollup address
     * @return type_                the layer 2 type ( 1: legacy optimism, 2: bedrock optimism with TON native token)
     * @return l2TON_               the L2 TON address
     * @return rejectedSeigs_       If it is true, Seigniorage issuance has been stopped for this layer2.
     * @return rejectedL2Deposit_    If it is true, stop depositing at this layer.
     * @return name_                the candidate name
     */
    function getRollupInfo(address rollupConfig)
        external view
        returns (uint8 type_, address l2TON_, bool rejectedSeigs_, bool rejectedL2Deposit_, string  memory name_)
    {
        ROLLUP_INFO memory info = rollupInfo[rollupConfig];
        return (info.rollupType, info.l2TON, info.rejectedSeigs, info.rejectedL2Deposit, info.name);
    }

    /**
     * @notice View the liquidity of Layer2 TON for a specific rollupConfig.
     * @param rollupConfig the rollupConfig address
     */
    function layer2TVL(address rollupConfig) public view returns (uint256 amount){

        uint _type = rollupInfo[rollupConfig].rollupType;

        if (_type == 1) {
            address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = IERC20(ton).balanceOf(l1Bridge_);

        } else if (_type == 2) {
             address optimismPortal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = IERC20(ton).balanceOf(optimismPortal_);
        }
    }

    /**
     * @notice Check whether a specific rollupConfig can be registered as a type.
     * @param rollupConfig      the rollupConfig address
     * @param _type         1: legacy, 2: bedrock with nativeTON
     */
    function availableForRegistration(address rollupConfig, uint8 _type, string calldata _name) public view returns (bool valid){
        return _availableForRegistration(rollupConfig, _type, _name);
    }

    /* ========== internal ========== */

    function _nonZeroAddress(address _addr1, address _addr2, address _addr3) internal pure {
        if(_addr1 == address(0) || _addr2 == address(0) || _addr3 == address(0) ) revert ZeroAddressError();
    }

    function _nonRejected(address rollupConfig) internal view {
        if(rollupInfo[rollupConfig].rejectedSeigs) revert NonRejectedError();
    }

    function _onlyRejectedRollupConfig(address rollupConfig) internal view {
        if(!rollupInfo[rollupConfig].rejectedSeigs) revert OnlyRejectedError();
    }

    function _registerRollupConfig(address rollupConfig, uint8 _type, address _l2TON, string memory _name) internal {
        if (_l2TON == address(0)) revert RegisterError(4);
        if (_type == 0 || _type > uint8(type(TYPE_ROLLUPCONFIG).max)) revert RegisterError(1);

        ROLLUP_INFO storage info = rollupInfo[rollupConfig];

        if (info.rollupType != 0) revert RegisterError(2);
        if (!_availableForRegistration(rollupConfig, _type, _name)) revert RegisterError(3);

        if (_type == 1 || _type == 2) {
            address bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
            if (bridge_ == address(0)) revert BridgeError();
            l1Bridge[bridge_] = true;
            emit AddedBridge(rollupConfig, bridge_);
        }

        if (_type == 2) {
            address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (portal_ == address(0)) revert PortalError();
            portal[portal_] = true;
            emit AddedPortal(rollupConfig, portal_);
        }

        info.rollupType = _type;
        info.l2TON = _l2TON;
        info.name = _name;
        registeredNames[bytes32(bytes(_name))] = true;

        emit RegisteredRollupConfig(rollupConfig, _type, _l2TON, _name);
    }

    function _availableForRegistration(address rollupConfig, uint8 _type, string memory _name) internal view returns (bool valid){

        if (registeredNames[bytes32(bytes(_name))] == true) {
            valid = false;
        } else {
            ROLLUP_INFO memory info = rollupInfo[rollupConfig];

            if (!info.rejectedSeigs) {

                address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();

                if(l1Bridge_ != address(0)) {
                    if (_type == 1) {
                        if(info.rollupType == 0 && !l1Bridge[l1Bridge_]) valid = true;

                    } else if (_type == 2) {
                        address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
                        if (portal_ != address(0)) {
                            if (info.rollupType == 0 && !portal[portal_]) valid = true;
                        }
                    }
                }
            }
        }
    }

    function _resetRollupConfig(address rollupConfig) internal {
        ROLLUP_INFO storage info = rollupInfo[rollupConfig];
        if(info.rejectedSeigs) revert NonRejectedError();

        address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
        address optimismPortal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();

        if (l1Bridge_ != address(0) && l1Bridge[l1Bridge_]) l1Bridge[l1Bridge_] = false;
        if (optimismPortal_ != address(0) && portal[optimismPortal_]) portal[optimismPortal_] = false;

        registeredNames[bytes32(bytes(info.name))] = false;

        info.rollupType = 0;
        info.l2TON = address(0);
        info.rejectedSeigs = false;
        info.rejectedL2Deposit = false;
        info.name = '';
    }
}
