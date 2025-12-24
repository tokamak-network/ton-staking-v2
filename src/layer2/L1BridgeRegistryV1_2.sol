// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IOptimismSystemConfig} from "../layer2/interfaces/IOptimismSystemConfig.sol";
import {ILayer2Manager} from "../layer2/interfaces/ILayer2Manager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../proxy/ProxyStorage.sol";
import {AuthControlL1BridgeRegistry} from "../common/AuthControlL1BridgeRegistry.sol";
import "./L1BridgeRegistryStorage.sol";
import "./L1BridgeRegistryV1_2Storage.sol";

/**
 * @notice  Error when executing registerRollupConfig function
 * @param x 1: unsupported type
 *          2: already registered
 *          3: unavailable for registration
 *          4: zero L2TON
 */
error RegisterError(uint x);
error NonRejectedError();
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
    enum TYPE_ROLLUPCONFIG {
        NONE,
        LEGARCY,
        OPTIMISM_BEDROCK,
        OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
    }

    // ==========================================
    // Events
    // ==========================================
     /**
     * @notice  Event occurs when registering rollupConfig
     * @param   rollupConfig      the rollupConfig address
     * @param   type_         0: none, 1: legacy, 2: bedrock with nativeTON
     * @param   l2TON        the L2 TON address
     * @param   name         the candidate name
     */
    event RegisteredRollupConfig(address rollupConfig, uint8 type_, address l2TON, string name);

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
     * @param disputeGameFactory the disputeGameFactory address
     */
    event UpgradedToType3(address rollupConfig, uint8 previousType, address disputeGameFactory);

    /**
     * @notice  Error when upgrading rollup type
     * @param x 1: not registered
     *          2: already TYPE 3
     *          3: DisputeGameFactory not available
     *          4: Portal not available
     */
    error UpgradeError(uint x);

    /* ========== onlyManager ========== */

    /**
     * @notice Registers Layer2 for a specific rollupConfig by the manager.
     * @param rollupConfig      the rollupConfig address
     * @param _type         1: legacy, 2: bedrock with nativeTON, 3: bedrock with DisputeGame & nativeTON
     */
    function registerRollupConfigByManager(
        address rollupConfig,
        uint8 _type,
        address _l2TON,
        string calldata _name
    ) external onlyManager {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2TON, _name);
    }

    function registerRollupConfigByManager(
        address rollupConfig,
        uint8 _type,
        address _l2TON
    ) external onlyManager {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2TON, '');
    }

    /**
     * @notice Upgrade rollup type from TYPE 1 or 2 to TYPE 3
     *         Requires the rollup to have deployed DisputeGameFactory
     * @param rollupConfig the rollupConfig address
     */
    function upgradeToType3(address rollupConfig) external onlyManager {
        _nonRejected(rollupConfig);

        ROLLUP_INFO storage info = rollupInfo[rollupConfig];
        uint8 currentType = info.rollupType;

        // Must be registered (TYPE 1 or 2)
        if (currentType == 0) revert UpgradeError(1);
        // Already TYPE 3
        if (currentType == 3) revert UpgradeError(2);

        // Check DisputeGameFactory is available
        address disputeGameFactory_ = IOptimismSystemConfig(rollupConfig).disputeGameFactory();
        if (disputeGameFactory_ == address(0)) revert UpgradeError(3);

        // Check Portal is available
        address portal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
        if (portal_ == address(0)) revert UpgradeError(4);

        // Register portal if not already registered (TYPE 1 case)
        if (!portal[portal_]) {
            portal[portal_] = true;
            rollupConfigWithPortal[portal_] = rollupConfig;
            emit AddedPortal(rollupConfig, portal_);
        }

        // Register DisputeGameFactory
        disputeGameFactory[rollupConfig] = true;
        rollupConfigWithDisputeGameFactory[disputeGameFactory_] = rollupConfig;

        // Update type to 3
        info.rollupType = 3;

        emit AddedDisputeGameFactory(rollupConfig, disputeGameFactory_);
        emit UpgradedToType3(rollupConfig, currentType, disputeGameFactory_);
    }

    /* ========== onlyRegistrant ========== */

    /**
     * @notice Registers Layer2 for a specific rollupConfig by Registrant.
     * @param rollupConfig       the rollupConfig address
     * @param _type          1: legacy, 2: bedrock with nativeTON, 3: bedrock with DisputeGame & nativeTON
     */
    function registerRollupConfig(
        address rollupConfig,
        uint8 _type,
        address _l2TON,
        string calldata _name
    ) external onlyRegistrant {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2TON, _name);
    }

    function registerRollupConfig(
        address rollupConfig,
        uint8 _type,
        address _l2TON
    ) external onlyRegistrant {
        _nonRejected(rollupConfig);
        _registerRollupConfig(rollupConfig, _type, _l2TON, '');
    }

    /* ========== public ========== */

    /**
     * @notice View the liquidity of Layer2 TON for a specific rollupConfig.
     * @param rollupConfig the rollupConfig address
     */
    function layer2TVL(address rollupConfig) public view returns (uint256 amount) {
        uint _type = rollupInfo[rollupConfig].rollupType;

        if (_type == 1) {
            address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = IERC20(ton).balanceOf(l1Bridge_);
        } else if (_type == 2 || _type == 3) {
            address optimismPortal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = IERC20(ton).balanceOf(optimismPortal_);
        }
    }


    /* ========== internal ========== */

    function _nonRejected(address rollupConfig) internal view {
        if (rollupInfo[rollupConfig].rejectedSeigs) revert NonRejectedError();
    }

    function _registerRollupConfig(
        address rollupConfig,
        uint8 _type,
        address _l2TON,
        string memory _name
    ) internal {
        if (_l2TON == address(0)) revert RegisterError(4);
        if (_type == 0 || _type > uint8(type(TYPE_ROLLUPCONFIG).max)) revert RegisterError(1);

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
        info.l2TON = _l2TON;
        if (bytes(_name).length != 0) info.name = _name;
        // registeredNames[bytes32(bytes(_name))] = true;

        emit RegisteredRollupConfig(rollupConfig, _type, _l2TON, _name);
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
