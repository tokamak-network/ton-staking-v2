// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IIDAOCommittee} from "../dao/interfaces/IIDAOCommittee.sol";
import {IOperatorManagerFactory} from "../layer2/interfaces/IOperatorManagerFactory.sol";
import {IL1BridgeRegistry} from "../layer2/interfaces/IL1BridgeRegistry.sol";
import {IOptimismSystemConfig} from "../layer2/interfaces/IOptimismSystemConfig.sol";
import {IOptimismPortal} from "../layer2/interfaces/IOptimismPortal.sol";
import {IStandardBridge} from "../layer2/interfaces/IStandardBridge.sol";
import {IOperator} from "../layer2/interfaces/IOperator.sol";
import {IIDepositManager} from "../stake/interfaces/IIDepositManager.sol";
import {ISeigManager} from "../stake/interfaces/ISeigManager.sol";
import {ISeigManagerV3} from "../stake/interfaces/ISeigManagerV3.sol";
import {ITON} from "../stake/interfaces/ITON.sol";
import {IWTON} from "../stake/interfaces/IWTON.sol";

import "./Layer2ManagerStorage.sol";
import "./Layer2ManagerV1_2Storage.sol";
import "../proxy/ProxyStorage.sol";
import {AccessibleCommon} from "../common/AccessibleCommon.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";

/**
 * @notice Error codes for registerCandidateAddOn
 */
error RegisterError(uint x);
error ZeroAddressError();
error ZeroBytesError();
error SameValueError();
error StatusError();
error ExcludeError();
error IncludeError();
error OnApproveError(uint x);

/**
 * @title Layer2ManagerV1_2
 * @notice TON Staking V3 Layer2 Manager - Bridged TON 조회/업데이트 기능 추가
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 */
contract Layer2ManagerV1_2 is ProxyStorage, AccessibleCommon, Layer2ManagerStorage, Layer2ManagerV1_2Storage {
    using SafeERC20 for IERC20;

    address internal constant LEGACY_ERC20_NATIVE_TOKEN = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    // ==========================================
    // Events
    // ==========================================

    event SetAddresses(
        address _l2Register,
        address _operatorManagerFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _seigManager,
        address _swapProxy
    );

    event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount);

    event RegisteredCandidateAddOn(
        address rollupConfig,
        uint256 wtonAmount,
        string memo,
        address operator,
        address candidateAddOn
    );

    event PausedCandidateAddOn(address rollupConfig, address candidateAddOn);
    event UnpausedCandidateAddOn(address rollupConfig, address candidateAddOn);
    event SetOperatorManagerFactory(address _operatorManagerFactory);
    event TransferWTON(address layer2, address operator, uint256 amount);

    /// @notice V3 신규: Bridged TON 업데이트 이벤트
    event BridgedTONUpdated(
        address indexed rollupConfig,
        address indexed layer2,
        uint256 oldAmount,
        uint256 newAmount
    );

    /// @notice V3 신규: CandidateAddOn 등록 V3 이벤트
    event RegisteredCandidateAddOnV3(
        address rollupConfig,
        uint256 wtonAmount,
        uint256 initialBridgedTON,
        string memo,
        address operator,
        address candidateAddOn
    );

    // ==========================================
    // Modifiers
    // ==========================================

    modifier onlySeigManger() {
        require(seigManager == msg.sender, "sender is not a SeigManager");
        _;
    }

    modifier onlyL1BridgeRegistry() {
        require(l1BridgeRegistry == msg.sender, "sender is not a L1BridgeRegistry");
        _;
    }

    // ==========================================
    // Owner Functions
    // ==========================================

    function setAddresses(
        address _l1BridgeRegistry,
        address _operatorManagerFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _seigManager,
        address _swapProxy
    ) external onlyOwner {
        l1BridgeRegistry = _l1BridgeRegistry;
        operatorManagerFactory = _operatorManagerFactory;
        ton = _ton;
        wton = _wton;
        dao = _dao;
        depositManager = _depositManager;
        seigManager = _seigManager;
        swapProxy = _swapProxy;

        emit SetAddresses(
            _l1BridgeRegistry,
            _operatorManagerFactory,
            _ton,
            _wton,
            _dao,
            _depositManager,
            _seigManager,
            _swapProxy
        );
    }

    function setOperatorManagerFactory(address _operatorManagerFactory) external onlyOwner {
        operatorManagerFactory = _operatorManagerFactory;
        emit SetOperatorManagerFactory(_operatorManagerFactory);
    }

    function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount) external onlyOwner {
        require(minimumInitialDepositAmount != _minimumInitialDepositAmount, "same");
        minimumInitialDepositAmount = _minimumInitialDepositAmount;
        emit SetMinimumInitialDepositAmount(_minimumInitialDepositAmount);
    }

    // ==========================================
    // L1BridgeRegistry Functions
    // ==========================================

    function pauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree {
        SeqSeigStatus memory info = rollupConfigInfo[rollupConfig];
        if (info.status != 1) revert StatusError();

        address _layer2 = operatorInfo[info.operatorManager].candidateAddOn;
        _nonZeroAddress(_layer2);

        if (!ISeigManager(seigManager).excludeFromL2Seigniorage(_layer2)) revert ExcludeError();

        rollupConfigInfo[rollupConfig].status = 2;
        emit PausedCandidateAddOn(rollupConfig, _layer2);
    }

    function unpauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree {
        SeqSeigStatus memory info = rollupConfigInfo[rollupConfig];
        if (info.status != 2) revert StatusError();

        address _layer2 = operatorInfo[info.operatorManager].candidateAddOn;
        _nonZeroAddress(_layer2);

        rollupConfigInfo[rollupConfig].status = 1;
        emit UnpausedCandidateAddOn(rollupConfig, operatorInfo[info.operatorManager].candidateAddOn);

        if (!ISeigManager(seigManager).includeFromL2Seigniorage(_layer2)) revert IncludeError();
    }

    // ==========================================
    // SeigManager Functions
    // ==========================================

    function transferL2Seigniorage(address layer2, uint256 amount) external onlySeigManger {
        address operator = operatorOfLayer[layer2];
        require(operator != address(0), "wrong operator");

        IERC20(wton).safeTransfer(operator, amount);

        emit TransferWTON(layer2, operator, amount);
    }

    // ==========================================
    // Public Functions - Registration
    // ==========================================

    /**
     * @notice Register the CandidateAddOn (V2 호환)
     */
    function registerCandidateAddOn(
        address rollupConfig,
        uint256 amount,
        bool flagTon,
        string calldata memo
    ) external {
        _nonZeroAddress(rollupConfig);
        if (bytes(memo).length == 0) revert ZeroBytesError();
        if (rollupConfigInfo[rollupConfig].operatorManager != address(0)) revert RegisterError(4);
        (bool res, ) = _availableRegister(rollupConfig);

        if (!res) revert RegisterError(5);
        _transferDepositAmount(msg.sender, rollupConfig, amount, flagTon, memo);
    }

    /**
     * @notice Register the CandidateAddOn with V3 Bridged TON 초기화
     */
    function registerCandidateAddOnV3(
        address rollupConfig,
        uint256 amount,
        bool flagTon,
        string calldata memo
    ) external ifFree {
        _nonZeroAddress(rollupConfig);
        if (bytes(memo).length == 0) revert ZeroBytesError();
        if (rollupConfigInfo[rollupConfig].operatorManager != address(0)) revert RegisterError(4);
        (bool res, ) = _availableRegister(rollupConfig);

        if (!res) revert RegisterError(5);

        // 기존 등록 로직
        _transferDepositAmount(msg.sender, rollupConfig, amount, flagTon, memo);

        // V3 신규: 초기 Bridged TON 설정
        uint256 initialBridgedTON = getBridgedTON(rollupConfig);
        cachedBridgedTON[rollupConfig] = initialBridgedTON;
        lastBridgedTONUpdateBlock[rollupConfig] = block.number;

        // SeigManager에 Bridged TON 알림
        address layer2 = operatorInfo[rollupConfigInfo[rollupConfig].operatorManager].candidateAddOn;
        ISeigManagerV3(seigManager).initializeBridgedTON(layer2, initialBridgedTON);

        emit RegisteredCandidateAddOnV3(
            rollupConfig,
            flagTon ? amount * 1e9 : amount,
            initialBridgedTON,
            memo,
            rollupConfigInfo[rollupConfig].operatorManager,
            layer2
        );
    }

    /// @notice ERC20 Approve callback
    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (msg.sender != ton && msg.sender != wton) revert OnApproveError(1);
        if (spender != address(this)) revert OnApproveError(2);

        bytes calldata _message;
        address _rollupConfig;
        if (data.length <= 20) revert OnApproveError(3);
        assembly {
            _rollupConfig := shr(96, calldataload(data.offset))
            _message.offset := add(data.offset, 20)
            _message.length := sub(data.length, 20)
        }

        _nonZeroAddress(_rollupConfig);

        if (rollupConfigInfo[_rollupConfig].operatorManager != address(0)) revert RegisterError(4);
        (bool res, ) = _availableRegister(_rollupConfig);
        if (!res) revert RegisterError(5);

        if (msg.sender == ton)
            _transferDepositAmount(owner, _rollupConfig, amount, true, string(_message));
        else _transferDepositAmount(owner, _rollupConfig, amount, false, string(_message));

        return true;
    }

    // ==========================================
    // V3 신규: Bridged TON 조회/업데이트
    // ==========================================

    /**
     * @notice Bridged TON 조회 (L1 브리지에서 직접)
     * @param rollupConfig RollupConfig 주소
     * @return bridgedTON Bridged TON 양 (TON 단위)
     */
    function getBridgedTON(address rollupConfig) public view returns (uint256 bridgedTON) {
        (bool valid, address l1Bridge, address portal, , uint8 _type, , , ) = _checkL1BridgeDetail(
            rollupConfig
        );

        if (!valid) return 0;

        // Type에 따라 다른 주소에서 TON 잔액 조회
        if (_type == 1) {
            // Legacy Optimism (Titan)
            bridgedTON = IERC20(ton).balanceOf(l1Bridge);
        } else if (_type == 2) {
            // Bedrock Optimism (Thanos)
            bridgedTON = IERC20(ton).balanceOf(portal);
        }
    }

    /**
     * @notice Bridged TON 업데이트 (L1BridgeRegistry에서 호출)
     * @param rollupConfig RollupConfig 주소
     */
    function updateBridgedTON(address rollupConfig) external onlyL1BridgeRegistry {
        SeqSeigStatus memory info = rollupConfigInfo[rollupConfig];
        if (info.status == 0) return; // 미등록

        address layer2 = operatorInfo[info.operatorManager].candidateAddOn;
        if (layer2 == address(0)) return;

        uint256 oldAmount = cachedBridgedTON[rollupConfig];
        uint256 newAmount = getBridgedTON(rollupConfig);

        cachedBridgedTON[rollupConfig] = newAmount;
        lastBridgedTONUpdateBlock[rollupConfig] = block.number;

        // SeigManager에 변경 알림
        ISeigManagerV3(seigManager).onBridgedTONChange(layer2, newAmount);

        emit BridgedTONUpdated(rollupConfig, layer2, oldAmount, newAmount);
    }

    /**
     * @notice 캐시된 Bridged TON 조회
     */
    function getCachedBridgedTON(address rollupConfig) external view returns (uint256) {
        return cachedBridgedTON[rollupConfig];
    }

    // ==========================================
    // View Functions
    // ==========================================

    function rollupConfigOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].rollupConfig;
    }

    function operatorOfRollupConfig(address _rollupConfig) external view returns (address) {
        return rollupConfigInfo[_rollupConfig].operatorManager;
    }

    function candidateAddOnOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].candidateAddOn;
    }

    function statusLayer2(address _rollupConfig) external view returns (uint8) {
        return rollupConfigInfo[_rollupConfig].status;
    }

    function checkLayer2TVL(address _rollupConfig) public view returns (bool result, uint256 amount) {
        return _checkLayer2TVL(_rollupConfig);
    }

    function checkL1Bridge(
        address _rollupConfig
    ) public view returns (bool result, address l1Bridge, address portal, address l2Ton) {
        (result, l1Bridge, portal, l2Ton, , , , ) = _checkL1BridgeDetail(_rollupConfig);
    }

    function availableRegister(address _rollupConfig) external view returns (bool result, uint256 amount) {
        return _availableRegister(_rollupConfig);
    }

    function checkL1BridgeDetail(
        address _rollupConfig
    )
        external
        view
        returns (
            bool result,
            address l1Bridge,
            address portal,
            address l2Ton,
            uint8 _type,
            uint8 status,
            bool rejectedSeigs,
            bool rejectedL2Deposit
        )
    {
        (result, l1Bridge, portal, l2Ton, _type, status, rejectedSeigs, rejectedL2Deposit) = _checkL1BridgeDetail(
            _rollupConfig
        );
    }

    function layerInfo(address layer2) external view returns (address rollupConfig, address operator) {
        operator = operatorOfLayer[layer2];
        rollupConfig = operatorInfo[operator].rollupConfig;
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    function _nonZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) revert ZeroAddressError();
    }

    function _registerCandidateAddOn(
        address _rollupConfig,
        uint256 _wtonAmount,
        string calldata _memo
    ) internal {
        address operator = IOperatorManagerFactory(operatorManagerFactory).createOperatorManager(
            _rollupConfig
        );

        if (operator == address(0)) revert RegisterError(1);
        if (operatorInfo[operator].rollupConfig != address(0)) revert RegisterError(2);

        address candidateAddOn = IIDAOCommittee(dao).createCandidateAddOn(_memo, operator);
        operatorOfLayer[candidateAddOn] = operator;
        operatorInfo[operator] = CandidateAddOnInfo({
            rollupConfig: _rollupConfig,
            candidateAddOn: candidateAddOn
        });

        rollupConfigInfo[_rollupConfig] = SeqSeigStatus({status: 1, operatorManager: operator});

        emit RegisteredCandidateAddOn(_rollupConfig, _wtonAmount, _memo, operator, candidateAddOn);

        if (IERC20(wton).allowance(address(this), depositManager) < _wtonAmount)
            IERC20(wton).approve(depositManager, type(uint256).max);
        if (!IIDepositManager(depositManager).deposit(candidateAddOn, operator, _wtonAmount))
            revert RegisterError(3);
    }

    function _availableRegister(
        address _rollupConfig
    ) internal view returns (bool result, uint256 amount) {
        (uint8 _type, , , , ) = IL1BridgeRegistry(l1BridgeRegistry).getRollupInfo(_rollupConfig);

        if (_type == 1) {
            // optimism legacy : titan
            address l1Bridge = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();
            if (l1Bridge != address(0)) {
                amount = IERC20(ton).balanceOf(l1Bridge);
                result = true;
            }
        } else if (_type == 2) {
            // optimism bedrock native TON: thanos, on-demand-l2
            address l1Bridge = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();
            address optimismPortal = IOptimismSystemConfig(_rollupConfig).optimismPortal();
            if (optimismPortal != address(0) && l1Bridge != address(0)) {
                amount = IERC20(ton).balanceOf(optimismPortal);
                result = true;
            }
        }
    }

    function _checkLayer2TVL(
        address _rollupConfig
    ) internal view returns (bool result, uint256 amount) {
        uint8 _type = IL1BridgeRegistry(l1BridgeRegistry).rollupType(_rollupConfig);

        if (_type == 1) {
            // optimism legacy : titan
            address l1Bridge = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();
            if (l1Bridge != address(0)) {
                amount = IERC20(ton).balanceOf(l1Bridge);
                result = true;
            }
        } else if (_type == 2) {
            // optimism bedrock native TON: thanos, on-demand-l2
            address optimismPortal = IOptimismSystemConfig(_rollupConfig).optimismPortal();
            if (optimismPortal != address(0)) {
                amount = IERC20(ton).balanceOf(optimismPortal);
                result = true;
            }
        }
    }

    function _checkL1BridgeDetail(
        address _rollupConfig
    )
        public
        view
        returns (
            bool result,
            address l1Bridge,
            address portal,
            address l2Ton,
            uint8 _type,
            uint8 status,
            bool rejectedSeigs,
            bool rejectedL2Deposit
        )
    {
        (_type, , rejectedSeigs, rejectedL2Deposit, ) = IL1BridgeRegistry(l1BridgeRegistry)
            .getRollupInfo(_rollupConfig);

        status = rollupConfigInfo[_rollupConfig].status;

        if (rollupConfigInfo[_rollupConfig].status == 1) {
            address l1Bridge_ = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();

            if (l1Bridge_ != address(0)) {
                if (_type == 1 || _type == 2)
                    l2Ton = IL1BridgeRegistry(l1BridgeRegistry).l2TON(_rollupConfig);

                if (l2Ton != address(0)) {
                    result = true;
                    l1Bridge = l1Bridge_;
                }
            }

            if (_type == 2) {
                address portal_ = IOptimismSystemConfig(_rollupConfig).optimismPortal();

                if (portal_ == address(0)) result = false;
                else portal = portal_;
            }
        }
    }

    function _transferDepositAmount(
        address sender,
        address _rollupConfig,
        uint256 amount,
        bool flagTon,
        string calldata memo
    ) internal {
        address _wton = wton;

        if (flagTon) {
            // with ton
            address _ton = ton;

            if (amount < minimumInitialDepositAmount) revert RegisterError(6);
            IERC20(_ton).safeTransferFrom(sender, address(this), amount);
            if (IERC20(_ton).allowance(address(this), _wton) < amount)
                IERC20(_ton).approve(_wton, type(uint256).max);
            if (!IWTON(_wton).swapFromTON(amount)) revert RegisterError(7);
            _registerCandidateAddOn(_rollupConfig, amount * 1e9, memo);
        } else {
            // with wton
            if ((amount / 1e9) < minimumInitialDepositAmount) revert RegisterError(6);
            IERC20(_wton).safeTransferFrom(sender, address(this), amount);
            _registerCandidateAddOn(_rollupConfig, amount, memo);
        }
    }
}
