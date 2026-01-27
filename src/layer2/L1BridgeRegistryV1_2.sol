// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IOptimismSystemConfig} from "../layer2/interfaces/IOptimismSystemConfig.sol";
import {ILayer2Manager} from "../layer2/interfaces/ILayer2Manager.sol";
import {IL1BridgeRegistry} from "../layer2/interfaces/IL1BridgeRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ProxyStorage} from "../proxy/ProxyStorage.sol";
import {AuthControlL1BridgeRegistry} from "../common/AuthControlL1BridgeRegistry.sol";
import {L1BridgeRegistryStorage} from "./L1BridgeRegistryStorage.sol";
import {L1BridgeRegistryV1_2Storage} from "./L1BridgeRegistryV1_2Storage.sol";

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
error DisputeGameFactoryError();

/**
 * @title L1BridgeRegistryV1_2
 * @notice TON Staking V3 - DisputeGameFactory 저장 및 조회 기능 (RAT 연동용)
 * @dev 스토리지만 상속, 필요한 함수만 추가
 *
 * 추가 함수:
 * - getDisputeGameFactory: 저장된 factory 조회
 * - isTrustedFactory: factory 검증
 */
contract L1BridgeRegistryV1_2 is
    ProxyStorage,
    AuthControlL1BridgeRegistry,
    L1BridgeRegistryStorage,
    L1BridgeRegistryV1_2Storage
{
    // TYPE_ROLLUPCONFIG enum is defined in IL1BridgeRegistry interface

    // ==========================================
    // Events
    // ==========================================

    event SetAddresses(address _layer2Manager, address _seigManager, address _ton);
    event SetSeigniorageCommittee(address _seigniorageCommittee);

    /**
     * @notice  Event occurs when registering rollupConfig
     * @param   rollupConfig      the rollupConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     * @param   l2Ton        the L2 TON address
     * @param   name         the candidate name
     */
    event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2Ton, string name);

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
     * @notice  Event occurs when an optimismPortal address is registered during system configuration registration.
     * @param rollupConfig          the rollupConfig address
     * @param rejectedL2Deposit     if it is true, allow the withdrawDepositL2 function.
     */
    event SetBlockingL2Deposit(address rollupConfig, bool rejectedL2Deposit);

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
     * @notice  Event occurs when a disputeGameFactory address is registered during system configuration registration.
     * @param rollupConfig          the rollupConfig address
     * @param disputeGameFactory    the disputeGameFactory address
     */
    event AddedDisputeGameFactory(address rollupConfig, address disputeGameFactory);

    /**
     * @notice  Event occurs when upgrading rollup type to TYPE 3
     * @param rollupConfig      the rollupConfig address
     * @param previousType      the previous rollup type (1 or 2)
     * @param portal            the portal address
     * @param disputeGameFactory the disputeGameFactory address
     */
    event UpgradedToType3(address rollupConfig, uint8 previousType, address portal, address disputeGameFactory);

    /**
     * @notice  Event occurs when type registrant is set
     * @param rollupType        the rollup type
     * @param registrant        the registrant address
     */
    event TypeRegistrantSet(uint8 indexed rollupType, address indexed registrant);

    /**
     * @notice  Error when upgrading rollup type
     * @param x 1: not registered
     *          2: already target type
     *          3: DisputeGameFactory not available
     *          4: Portal not available
     */
    error UpgradeError(uint x);

    /**
     * @notice  Error when caller is not authorized
     */
    error NotAuthorizedError();

    // ==========================================
    // Modifiers
    // ==========================================

    modifier onlySeigniorageCommittee() {
        _onlySeigniorageCommittee();
        _;
    }

    function _onlySeigniorageCommittee() internal view {
        require(seigniorageCommittee == msg.sender, 'PermissionError');
    }

    /**
     * @notice 타입별 등록 권한 체크
     * @dev Manager이거나 해당 타입의 등록 권한자만 허용
     */
    modifier onlyTypeRegistrant(uint8 _type) {
        _onlyTypeRegistrant(_type);
        _;
    }

    function _onlyTypeRegistrant(uint8 _type) internal view {
        address registrant = typeRegistrant[_type];
        if (registrant == address(0)) {
            if (!isManager(msg.sender)) revert NotAuthorizedError();
        } else {
            if (!isManager(msg.sender) && msg.sender != registrant) revert NotAuthorizedError();
        }
    }

    /* ========== onlyOwner ========== */

    /**
     * @param _layer2Manager    the layer2Manager address
     * @param _seigManager      the seigManager address
     * @param _ton              the ton address
     */
    function setAddresses(
        address _layer2Manager,
        address _seigManager,
        address _ton
    ) external onlyOwner {
        require(ton == address(0), "already initialized");

        _nonZeroAddress(_layer2Manager, _seigManager, _ton);
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
    ) external onlyOwner {
        require(seigniorageCommittee != _seigniorageCommittee, "same");
        seigniorageCommittee = _seigniorageCommittee;

        emit SetSeigniorageCommittee(_seigniorageCommittee);
    }

    /* ========== onlySeigniorageCommittee ========== */

    /**
     * @notice Stop issuing seigniorage to the layer 2 sequencer of a specific rollupConfig.
     *         Unsettled seigniorage to the layer 2 sequencer can no longer be settled.
     * @param rollupConfig the rollupConfig address
     */
    function rejectCandidateAddOn(address rollupConfig) external onlySeigniorageCommittee {
        _nonRejected(rollupConfig);

        ROLLUP_INFO storage info = rollupInfo[rollupConfig];
        require(info.rollupType != 0, "NonRegistered");
        info.rejectedSeigs = true;
        info.rejectedL2Deposit = true;

        ILayer2Manager(layer2Manager).pauseCandidateAddOn(rollupConfig);
        emit RejectedCandidateAddOn(rollupConfig);
    }

    /**
     * Start to issue seigniorage to the layer 2 sequencer of a specific rollupConfig from now on.
     * @param rollupConfig          the rollupConfig address
     * @param rejectedL2Deposit     if it is true, allow the withdrawDepositL2 function.
     */
    function restoreCandidateAddOn(
        address rollupConfig,
        bool rejectedL2Deposit
    ) external onlySeigniorageCommittee {
        _onlyRejectedRollupConfig(rollupConfig);

        ROLLUP_INFO storage info = rollupInfo[rollupConfig];
        info.rejectedSeigs = false;
        info.rejectedL2Deposit = rejectedL2Deposit;

        ILayer2Manager(layer2Manager).unpauseCandidateAddOn(rollupConfig);
        emit RestoredCandidateAddOn(rollupConfig);
    }

    /* ========== onlyManager ========== */

    /**
     * @notice Registers Layer2 for a specific rollupConfig by the manager.
     * @param rollupConfig      the rollupConfig address
     * @param _type         1: legacy, 2: bedrock with nativeTON, 3: bedrock with DisputeGame & nativeTON
     */
    function registerRollupConfigByManager(
        address rollupConfig,
        uint8 _type,
        address _l2Ton,
        string calldata _name
    ) external onlyManager {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2Ton, _name);
    }

    function registerRollupConfigByManager(
        address rollupConfig,
        uint8 _type,
        address _l2Ton
    ) external onlyManager {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2Ton, '');
    }

    /**
     * @notice 타입별 등록 권한자 설정
     * @param _type 롤업 타입 (1, 2, 3, ...)
     * @param _registrant 등록 권한자 주소 (address(0)이면 Manager만 등록 가능)
     */
    function setTypeRegistrant(uint8 _type, address _registrant) external onlyManager {
        typeRegistrant[_type] = _registrant;
        emit TypeRegistrantSet(_type, _registrant);
    }

    /**
     * @notice Upgrade rollup type from TYPE 1 or 2 to TYPE 3
     * @param rollupConfig the rollupConfig address
     */
    function upgradeToType3(address rollupConfig) external onlyManager {
        _nonRejected(rollupConfig);

        ROLLUP_INFO storage info = rollupInfo[rollupConfig];
        uint8 currentType = info.rollupType;

        // Must be registered (TYPE 1 or 2)
        if (currentType == 0) revert UpgradeError(1);
        // Already TYPE 3
        if (currentType != 1 && currentType != 2) revert UpgradeError(2);

        // Check DisputeGameFactory is available
        address disputeGameFactory_ = IOptimismSystemConfig(rollupConfig).disputeGameFactory();
        if (disputeGameFactory_ == address(0)) revert UpgradeError(3);

        // Check Portal is available
        address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
        if (portal_ == address(0)) revert UpgradeError(4);

        if (!portal[portal_]) portal[portal_] = true;
        address existingConfig = rollupConfigWithPortal[portal_];
        if(existingConfig == address(0)) {
            rollupConfigWithPortal[portal_] = rollupConfig;
            emit AddedPortal(rollupConfig, portal_);
        } else if (existingConfig != rollupConfig) {
                revert PortalError();
        }

        // Register DisputeGameFactory
        address existingRollupConfig = rollupConfigWithDisputeGameFactory[disputeGameFactory_];
        if (existingRollupConfig != address(0) && existingRollupConfig != rollupConfig) {
            // DisputeGameFactory가 이미 다른 rollupConfig에 등록되어 있으면 안됨
            revert DisputeGameFactoryError();
        }
        disputeGameFactory[rollupConfig] = true;
        rollupConfigWithDisputeGameFactory[disputeGameFactory_] = rollupConfig;

        // Update type to 3
        info.rollupType = 3;

        emit AddedDisputeGameFactory(rollupConfig, disputeGameFactory_);
        emit UpgradedToType3(rollupConfig, currentType, portal_, disputeGameFactory_);
    }

    /* ========== onlyRegistrant ========== */

    /**
     * @notice Registers Layer2 for a specific rollupConfig by Registrant.
     * @dev Uses V1_2's _registerRollupConfig which properly sets rollupConfigWithPortal
     * @param rollupConfig       the rollupConfig address
     * @param _type          1: legacy, 2: bedrock with nativeTON, 3: bedrock with DisputeGame & nativeTON
     */
    function registerRollupConfig(
        address rollupConfig,
        uint8 _type,
        address _l2Ton,
        string calldata _name
    ) external onlyRegistrant {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2Ton, _name);
    }

    function registerRollupConfig(
        address rollupConfig,
        uint8 _type,
        address _l2Ton
    ) external onlyRegistrant {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2Ton, '');
    }

    /* ========== onlyTypeRegistrant ========== */

    /**
     * @notice 타입별 권한 체크를 통한 롤업 등록
     * @dev Manager이거나 해당 타입의 typeRegistrant만 호출 가능
     * @param rollupConfig      the rollupConfig address
     * @param _type         1: legacy, 2: bedrock with nativeTON, 3: bedrock with DisputeGame & nativeTON
     */
    function registerRollupConfigByType(
        address rollupConfig,
        uint8 _type,
        address _l2Ton,
        string calldata _name
    ) external onlyTypeRegistrant(_type) {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2Ton, _name);
    }

    function registerRollupConfigByType(
        address rollupConfig,
        uint8 _type,
        address _l2Ton
    ) external onlyTypeRegistrant(_type) {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2Ton, '');
    }

    /* ========== public ========== */

    /**
     * @notice View the rollupType of rollupConfig
     * @param rollupConfig the rollup address
     * @return rollupType_  the rollupType 0:empty, 1: optimism legacy, 2: optimism bedrock native TON, 3: bedrock with DisputeGame
     */
    function rollupType(address rollupConfig) external view returns (uint8 rollupType_) {
        return rollupInfo[rollupConfig].rollupType;
    }

    /**
     * @notice Returns whether the issuance of seigniorage to the given layer 2 is restricted.
     * @param rollupConfig the rollup address
     * @return rejectedSeigs  If it is true, Seigniorage issuance has been stopped for this layer2.
     */
    function rejectRollupConfig(address rollupConfig) external view returns (bool rejectedSeigs) {
        return rollupInfo[rollupConfig].rejectedSeigs;
    }

    /**
     * @notice Returns whether the issuance of seigniorage to the given layer 2 is restricted.
     * @param rollupConfig the rollup address
     * @return rejectedSeigs  If it is true, Seigniorage issuance has been stopped for this layer2.
     */
    function isRejectedSeigs(address rollupConfig) external view returns (bool rejectedSeigs) {
        return rollupInfo[rollupConfig].rejectedSeigs;
    }

    /**
     * @notice Returns whether the issuance of seigniorage to the given layer 2 is restricted.
     * @param rollupConfig the rollup address
     * @return rejectedL2Deposit  If it is true, stop depositing at this layer.
     */
    function isRejectedL2Deposit(
        address rollupConfig
    ) external view returns (bool rejectedL2Deposit) {
        return rollupInfo[rollupConfig].rejectedL2Deposit;
    }

    /**
     * @notice View the l2 ton address of rollupConfig
     * @param rollupConfig the rollup address
     * @return l2TonAddress  the l2 ton address
     */
    function l2Ton(address rollupConfig) external view returns (address l2TonAddress) {
        return rollupInfo[rollupConfig].l2TON;
    }

    /**
     * @notice View the l2 ton address of rollupConfig
     * @param rollupConfig          the rollup address
     * @return type_                the layer 2 type ( 1: legacy optimism, 2: bedrock optimism with TON native token, 3: bedrock with DisputeGame)
     * @return l2Ton_               the L2 TON address
     * @return rejectedSeigs_       If it is true, Seigniorage issuance has been stopped for this layer2.
     * @return rejectedL2Deposit_    If it is true, stop depositing at this layer.
     * @return name_                the candidate name
     */
    function getRollupInfo(
        address rollupConfig
    )
        external
        view
        returns (
            uint8 type_,
            address l2Ton_,
            bool rejectedSeigs_,
            bool rejectedL2Deposit_,
            string memory name_
        )
    {
        ROLLUP_INFO memory info = rollupInfo[rollupConfig];
        return (info.rollupType, info.l2TON, info.rejectedSeigs, info.rejectedL2Deposit, info.name);
    }

    /**
     * @notice View the liquidity of Layer2 TON for a specific rollupConfig.
     * @param rollupConfig the rollupConfig address
     */
    function layer2Tvl(address rollupConfig) public view returns (uint256 amount) {
        uint _type = rollupInfo[rollupConfig].rollupType;

        if (_type == 1) {
            address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = IERC20(ton).balanceOf(l1Bridge_);
        } else if (_type == 2 || _type == 3) {
            address optimismPortal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = IERC20(ton).balanceOf(optimismPortal_);
        }
    }


    /**
     * @notice Check whether a specific rollupConfig can be registered as a type.
     * @param rollupConfig      the rollupConfig address
     * @param _type         1: legacy, 2: bedrock with nativeTON, 3: bedrock with DisputeGame & nativeTON
     */
    function availableForRegistration(
        address rollupConfig,
        uint8 _type
    ) public view returns (bool valid) {
        return _availableForRegistration(rollupConfig, _type);
    }

    /* ========== internal ========== */

    function _nonZeroAddress(address _addr1, address _addr2, address _addr3) internal pure {
        if (_addr1 == address(0) || _addr2 == address(0) || _addr3 == address(0))
            revert ZeroAddressError();
    }

    function _nonRejected(address rollupConfig) internal view {
        if (rollupInfo[rollupConfig].rejectedSeigs) revert NonRejectedError();
    }

    function _onlyRejectedRollupConfig(address rollupConfig) internal view {
        if (!rollupInfo[rollupConfig].rejectedSeigs) revert OnlyRejectedError();
    }

    function _registerRollupConfig(
        address rollupConfig,
        uint8 _type,
        address _l2Ton,
        string memory _name
    ) internal {
        if (_l2Ton == address(0)) revert RegisterError(4);
        if (_type == 0 || _type > uint8(type(IL1BridgeRegistry.TYPE_ROLLUPCONFIG).max)) revert RegisterError(1);

        ROLLUP_INFO storage info = rollupInfo[rollupConfig];

        if (info.rollupType != 0) revert RegisterError(2);
        if (!_availableForRegistration(rollupConfig, _type)) revert RegisterError(3);

        if (_type == 1 || _type == 2 || _type == 3) {
            address bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
            if (bridge_ == address(0)) revert BridgeError();
            l1Bridge[bridge_] = true;
            emit AddedBridge(rollupConfig, bridge_);
        }

        if (_type == 2 ) {
            address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (portal_ == address(0)) revert PortalError();
            portal[portal_] = true;
            rollupConfigWithPortal[portal_] = rollupConfig;
            emit AddedPortal(rollupConfig, portal_);
        }

        if( _type == 3 ) {
            address disputeGameFactory_ = IOptimismSystemConfig(rollupConfig).disputeGameFactory();
            address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (disputeGameFactory_ == address(0)) revert DisputeGameFactoryError();
            if (portal_ == address(0)) revert PortalError();

            portal[portal_] = true;
            rollupConfigWithPortal[portal_] = rollupConfig;

            disputeGameFactory[rollupConfig] = true;
            rollupConfigWithDisputeGameFactory[disputeGameFactory_] = rollupConfig;

            emit AddedDisputeGameFactory(rollupConfig, disputeGameFactory_);
        }

        info.rollupType = _type;
        info.l2TON = _l2Ton;
        if (bytes(_name).length != 0) info.name = _name;
        // registeredNames[bytes32(bytes(_name))] = true;

        emit RegisteredRollupConfig(rollupConfig, _type, _l2Ton, _name);
    }


    function _availableForRegistration(
        address rollupConfig,
        uint8 _type
    ) internal view returns (bool valid) {
        // if (registeredNames[bytes32(bytes(_name))] == true) {
        //     valid = false;
        // } else {
        ROLLUP_INFO memory info = rollupInfo[rollupConfig];

        if (!info.rejectedSeigs) {
            address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();

            if (l1Bridge_ != address(0)) {
                if (_type == 1) {
                    if (info.rollupType == 0 && !l1Bridge[l1Bridge_]) valid = true;
                } else if (_type == 2) {
                    address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
                    if (portal_ != address(0)) {
                        if (info.rollupType == 0 && !portal[portal_]) valid = true;
                    }
                } else if (_type == 3) {
                    address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
                    address disputeGameFactory_ = IOptimismSystemConfig(rollupConfig).disputeGameFactory();
                    if (portal_ != address(0) && disputeGameFactory_ != address(0)) {
                        if (info.rollupType == 0 &&
                            !portal[portal_] &&
                            !disputeGameFactory[disputeGameFactory_]) valid = true;
                    }
                }
            }
        }
        // }
    }


    function _resetRollupConfig(address rollupConfig) internal {
        ROLLUP_INFO storage info = rollupInfo[rollupConfig];
        if (info.rejectedSeigs) revert NonRejectedError();

        address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
        address optimismPortal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
        address disputeGameFactory_ = IOptimismSystemConfig(rollupConfig).disputeGameFactory();

        if (l1Bridge_ != address(0) && l1Bridge[l1Bridge_]) l1Bridge[l1Bridge_] = false;
        if (optimismPortal_ != address(0) && portal[optimismPortal_])
            portal[optimismPortal_] = false;

        if (disputeGameFactory_ != address(0) && disputeGameFactory[disputeGameFactory_]) disputeGameFactory[disputeGameFactory_] = false;
        if (rollupConfigWithDisputeGameFactory[disputeGameFactory_] != address(0)) rollupConfigWithDisputeGameFactory[disputeGameFactory_] = address(0);

        // registeredNames[bytes32(bytes(info.name))] = false;

        info.rollupType = 0;
        info.l2TON = address(0);
        info.rejectedSeigs = false;
        info.rejectedL2Deposit = false;
        info.name = '';
    }
}
