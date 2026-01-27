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

// Dynamic rollup type management errors
error TypeNotSupportedError();
error TypeAlreadyExistsError();
error InvalidTypeError();

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
    // Rollup types are dynamically registered via addRollupType()
    // TYPE 1: Optimism Legacy, TYPE 2: Optimism Bedrock, TYPE 3: Optimism Bedrock DisputeGame

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
     * @dev Uses dynamic rollup type configuration to call the appropriate getter function
     * @param rollupConfig the rollupConfig address
     */
    function layer2Tvl(address rollupConfig) public view virtual returns (uint256 amount) {
        uint8 _type = rollupInfo[rollupConfig].rollupType;

        if (_type == 0) return 0;

        RollupTypeConfig memory config = rollupTypeConfig[_type];

        // Call the configured function selector to get bridge contract address
        (bool success, bytes memory data) = rollupConfig.staticcall(
            abi.encodeWithSelector(config.tvlContractGetter)
        );

        if (!success || data.length == 0) return 0;

        address bridgeContract = abi.decode(data, (address));
        if (bridgeContract == address(0)) return 0;

        // Return TON balance in the bridge contract
        amount = IERC20(ton).balanceOf(bridgeContract);
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
    ) internal virtual {
        if (_l2Ton == address(0)) revert RegisterError(4);

        // Type 0 is reserved (invalid), and type must be registered via addRollupType()
        if (_type == 0) revert RegisterError(1);

        // Verify that the rollup type has been registered via addRollupType()
        if (rollupTypeConfig[_type].bridgeContractGetter == bytes4(0)) revert TypeNotSupportedError();

        ROLLUP_INFO storage info = rollupInfo[rollupConfig];

        if (info.rollupType != 0) revert RegisterError(2);
        if (!_availableForRegistration(rollupConfig, _type)) revert RegisterError(3);

        // Dynamic registration for all types (TYPE 1+)
        RollupTypeConfig memory config = rollupTypeConfig[_type];

        // 1. Register deposit bridge address (always register to l1Bridge mapping)
        bytes4 getter = config.bridgeContractGetter;
        (bool success, bytes memory data) = rollupConfig.staticcall(
            abi.encodeWithSelector(getter)
        );
        if (!success || data.length < 32) revert BridgeError();

        address bridgeAddr = abi.decode(data, (address));
        if (bridgeAddr == address(0)) revert BridgeError();

        // Register bridge address to l1Bridge mapping
        // Note: bridgePattern determines which function to call for deposits (handled in DepositManager)
        l1Bridge[bridgeAddr] = true;
        emit AddedBridge(rollupConfig, bridgeAddr);

        // 2. Register TVL query address (if different from bridge)
        getter = config.tvlContractGetter;
        if (getter != bytes4(0) && getter != config.bridgeContractGetter) {
            (success, data) = rollupConfig.staticcall(
                abi.encodeWithSelector(getter)
            );
            if (success && data.length >= 32) {
                address tvlAddr = abi.decode(data, (address));
                if (tvlAddr != address(0) && tvlAddr != bridgeAddr) {
                    // TVL contract is different from bridge contract
                    // Register it as portal for TVL queries
                    portal[tvlAddr] = true;
                    rollupConfigWithPortal[tvlAddr] = rollupConfig;
                    emit AddedPortal(rollupConfig, tvlAddr);
                }
            }
        }

        // 3. Register DisputeGameFactory (if applicable)
        getter = config.disputeGameFactoryGetter;
        if (getter != bytes4(0)) {
            (success, data) = rollupConfig.staticcall(
                abi.encodeWithSelector(getter)
            );

            // If disputeGameFactoryGetter is set, factory address is REQUIRED
            if (!success || data.length < 32) revert DisputeGameFactoryError();

            address factoryAddr = abi.decode(data, (address));
            if (factoryAddr == address(0)) revert DisputeGameFactoryError();

            disputeGameFactory[rollupConfig] = true;
            rollupConfigWithDisputeGameFactory[factoryAddr] = rollupConfig;
            emit AddedDisputeGameFactory(rollupConfig, factoryAddr);
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
    ) internal view virtual returns (bool valid) {
        ROLLUP_INFO memory info = rollupInfo[rollupConfig];

        // Already registered or rejected
        if (info.rollupType != 0 || info.rejectedSeigs) return false;

        // Dynamic validation for all types
        RollupTypeConfig memory config = rollupTypeConfig[_type];

        // Check if the type is registered (has bridgeContractGetter)
        if (config.bridgeContractGetter == bytes4(0)) return false;

        // 1. Check bridge address using bridgeContractGetter
        (bool success, bytes memory data) = rollupConfig.staticcall(
            abi.encodeWithSelector(config.bridgeContractGetter)
        );

        if (!success || data.length < 32) return false;

        address bridgeAddr = abi.decode(data, (address));
        if (bridgeAddr == address(0) || l1Bridge[bridgeAddr]) return false;

        // 2. Check TVL address if different from bridge (portal check)
        if (config.tvlContractGetter != bytes4(0) && config.tvlContractGetter != config.bridgeContractGetter) {
            (bool tvlSuccess, bytes memory tvlData) = rollupConfig.staticcall(
                abi.encodeWithSelector(config.tvlContractGetter)
            );
            if (tvlSuccess && tvlData.length >= 32) {
                address tvlAddr = abi.decode(tvlData, (address));
                // If portal address already used by another rollupConfig, not available
                if (tvlAddr != address(0) && portal[tvlAddr]) return false;
            }
        }

        // 3. Check DisputeGameFactory if required
        if (config.disputeGameFactoryGetter != bytes4(0)) {
            (bool factorySuccess, bytes memory factoryData) = rollupConfig.staticcall(
                abi.encodeWithSelector(config.disputeGameFactoryGetter)
            );
            if (factorySuccess && factoryData.length >= 32) {
                address factoryAddr = abi.decode(factoryData, (address));
                // If factory address already used, not available
                if (factoryAddr != address(0) && rollupConfigWithDisputeGameFactory[factoryAddr] != address(0)) {
                    return false;
                }
            }
        }

        // All checks passed
        valid = true;
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

    // ==========================================
    // Dynamic Rollup Type Management
    // ==========================================

    /**
     * @notice Event occurs when a new rollup type is added
     * @param rollupType The type number
     * @param name Type name
     * @param bridgeContractGetter Function selector to get deposit bridge address
     * @param tvlContractGetter Function selector to get TVL query address
     * @param disputeGameFactoryGetter Function selector to get DisputeGameFactory address (bytes4(0) if not applicable)
     * @param bridgePattern Bridge function pattern (0=ERC20, 1=NATIVE, 2=CUSTOM, ...)
     */
    event RollupTypeAdded(
        uint8 indexed rollupType,
        string name,
        bytes4 bridgeContractGetter,
        bytes4 tvlContractGetter,
        bytes4 disputeGameFactoryGetter,
        uint8 bridgePattern
    );

    /**
     * @notice Event occurs when a rollup type is updated
     * @param rollupType The type number
     * @param name Type name
     * @param bridgeContractGetter Function selector for deposit bridge
     * @param tvlContractGetter Function selector for TVL query
     * @param disputeGameFactoryGetter Function selector for DisputeGameFactory (bytes4(0) if not applicable)
     * @param bridgePattern Bridge pattern
     * @param v3Eligible Whether V3 eligible
     */
    event RollupTypeUpdated(
        uint8 indexed rollupType,
        string name,
        bytes4 bridgeContractGetter,
        bytes4 tvlContractGetter,
        bytes4 disputeGameFactoryGetter,
        uint8 bridgePattern,
        bool v3Eligible
    );

    // ==========================================
    // Dynamic Rollup Type Management (V1_2)
    // ==========================================

    /**
     * @notice Add a new rollup type configuration
     * @dev Only callable by Manager
     * @param _type Rollup type number (1-255)
     * @param _name Type name (e.g., "Legacy", "Bedrock", "DisputeGame")
     * @param _bridgeContractGetter Function selector to get deposit bridge address from rollupConfig
     * @param _tvlContractGetter Function selector to get TVL query address from rollupConfig
     * @param _disputeGameFactoryGetter Function selector to get DisputeGameFactory address (bytes4(0) if not applicable)
     * @param _bridgePattern Bridge function pattern (0=ERC20, 1=NATIVE, 2=CUSTOM, ...)
     * @param _v3Eligible Whether this type is eligible for V3 whitepaper seigniorage
     */
    function addRollupType(
        uint8 _type,
        string calldata _name,
        bytes4 _bridgeContractGetter,
        bytes4 _tvlContractGetter,
        bytes4 _disputeGameFactoryGetter,
        uint8 _bridgePattern,
        bool _v3Eligible
    ) external onlyManager {
        if (_type == 0) revert InvalidTypeError();

        // Check if type already registered (has config)
        if (rollupTypeConfig[_type].bridgeContractGetter != bytes4(0)) revert TypeAlreadyExistsError();

        // Set bitmap bit if V3 eligible
        if (_v3Eligible) {
            v3SeigniorageEligibleTypes |= (1 << _type);
        }

        // Store configuration
        rollupTypeConfig[_type] = RollupTypeConfig({
            bridgeContractGetter: _bridgeContractGetter,
            tvlContractGetter: _tvlContractGetter,
            disputeGameFactoryGetter: _disputeGameFactoryGetter,
            bridgePattern: _bridgePattern,
            name: _name
        });

        emit RollupTypeAdded(_type, _name, _bridgeContractGetter, _tvlContractGetter, _disputeGameFactoryGetter, _bridgePattern);
    }

    /**
     * @notice Update rollup type configuration
     * @dev Can update all properties of an existing type
     * @param _type Rollup type number
     * @param _name Type name (e.g., "Legacy", "Bedrock", "DisputeGame")
     * @param _bridgeContractGetter Function selector for deposit bridge address
     * @param _tvlContractGetter Function selector for TVL query address
     * @param _disputeGameFactoryGetter Function selector for DisputeGameFactory (bytes4(0) if not applicable)
     * @param _bridgePattern Bridge function pattern (0=ERC20, 1=NATIVE, 2=CUSTOM, ...)
     * @param _v3Eligible Whether the type should be eligible for V3 seigniorage
     */
    function updateRollupType(
        uint8 _type,
        string calldata _name,
        bytes4 _bridgeContractGetter,
        bytes4 _tvlContractGetter,
        bytes4 _disputeGameFactoryGetter,
        uint8 _bridgePattern,
        bool _v3Eligible
    ) external onlyManager {
        if (_type == 0) revert InvalidTypeError();

        // Check if type exists (has config)
        RollupTypeConfig storage config = rollupTypeConfig[_type];
        if (config.bridgeContractGetter == bytes4(0)) revert TypeNotSupportedError();

        // Check if anything actually changed
        bool currentV3Eligible = (v3SeigniorageEligibleTypes & (1 << _type)) != 0;
        bool nameChanged = keccak256(bytes(config.name)) != keccak256(bytes(_name));
        bool configChanged = config.bridgeContractGetter != _bridgeContractGetter ||
                            config.tvlContractGetter != _tvlContractGetter ||
                            config.disputeGameFactoryGetter != _disputeGameFactoryGetter ||
                            config.bridgePattern != _bridgePattern;
        bool eligibilityChanged = currentV3Eligible != _v3Eligible;

        // If nothing changed, return early to save gas
        if (!nameChanged && !configChanged && !eligibilityChanged) return;

        // Update bitmap if eligibility changed
        if (eligibilityChanged) {
            if (_v3Eligible) {
                v3SeigniorageEligibleTypes |= (1 << _type);
            } else {
                v3SeigniorageEligibleTypes &= ~(1 << _type);
            }
        }

        // Update configuration
        config.bridgeContractGetter = _bridgeContractGetter;
        config.tvlContractGetter = _tvlContractGetter;
        config.disputeGameFactoryGetter = _disputeGameFactoryGetter;
        config.bridgePattern = _bridgePattern;
        config.name = _name;

        emit RollupTypeUpdated(_type, _name, _bridgeContractGetter, _tvlContractGetter, _disputeGameFactoryGetter, _bridgePattern, _v3Eligible);
    }

    // ==========================================
    // View Functions - Dynamic Rollup Types
    // ==========================================

    /**
     * @notice Check if a rollup type is eligible for V3 whitepaper seigniorage
     * @param _type Rollup type number
     * @return eligible True if the type is V3 seigniorage eligible
     */
    function isValidRollupType(uint8 _type) public view returns (bool eligible) {
        // Check bitmap bit is set
        return (v3SeigniorageEligibleTypes & (1 << _type)) != 0;
    }

    /**
     * @notice Get bridge pattern for a rollup type
     * @param _type Rollup type number
     * @return pattern Bridge function pattern (0=ERC20, 1=NATIVE, 2=CUSTOM, ...)
     */
    function getBridgePattern(uint8 _type) public view returns (uint8 pattern) {
        return rollupTypeConfig[_type].bridgePattern;
    }

    /**
     * @notice Get bridge contract getter selector for a rollup type
     * @param _type Rollup type number
     * @return selector Function selector to call on rollupConfig for deposit bridge
     */
    function getBridgeContractGetter(uint8 _type) public view returns (bytes4 selector) {
        return rollupTypeConfig[_type].bridgeContractGetter;
    }

    /**
     * @notice Get TVL contract getter selector for a rollup type
     * @param _type Rollup type number
     * @return selector Function selector to call on rollupConfig for TVL query
     */
    function getTvlContractGetter(uint8 _type) public view returns (bytes4 selector) {
        return rollupTypeConfig[_type].tvlContractGetter;
    }

    /**
     * @notice Get the function selector for getting DisputeGameFactory address for a rollup type
     * @param _type Rollup type number
     * @return selector The function selector (bytes4(0) if not applicable)
     */
    function getDisputeGameFactoryGetter(uint8 _type) public view returns (bytes4 selector) {
        return rollupTypeConfig[_type].disputeGameFactoryGetter;
    }

    /**
     * @notice Get rollup type configuration
     * @param _type Rollup type number
     * @return config The full configuration struct
     */
    function getRollupTypeConfig(uint8 _type) external view returns (RollupTypeConfig memory config) {
        return rollupTypeConfig[_type];
    }

    /**
     * @notice Get all V3 seigniorage eligible rollup types (bitmap)
     * @return bitmap The bitmap of V3 eligible types
     */
    function getV3SeigniorageEligibleTypes() external view returns (uint256 bitmap) {
        return v3SeigniorageEligibleTypes;
    }
}
