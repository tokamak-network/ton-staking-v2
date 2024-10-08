// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Layer2ManagerStorage.sol";
import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";

/**
 * @notice  Error that occurs when registering CandidateAddOn
 * @param x 1: don't create operator
 *          2: already rollupConfigOfOperator registered
 *          3: fail deposit
 *          4: already operatorOfRollupConfig registered
 *          5: unvalidated Layer2
 *          6: insufficient initialDepositAmount
 *          7: fail to swap ton to wton
 *          8: wrong data length
 */
error RegisterError(uint x);
error ZeroAddressError();
error ZeroBytesError();  // memo check
error SameValueError();
error StatusError();
error ExcludeError();
/**
 * @notice  Error in onApprove function
 * @param x 1: sender is not ton nor wton
 *          2: wrong spender parameter
 *          3: wrong data parameter length
 */
error OnApproveError(uint x);

interface IL1BridgeRegistry {
    function getRollupInfo(address rollupConfig) external view returns (
        uint8   rollupType,
        address l2TON,
        bool    rejectedSeigs,
        bool    rejectedL2Deposit,
        string  memory name
    );
    function registeredNames(bytes32 byteName) external view returns (bool);
    function l2TON(address rollupConfig) external view returns (address);
    function rollupType(address rollupConfig) external view returns (uint8);
    function checkLayer2TVL(address _rollupConfig) external view returns (bool result, uint256 amount);
}

interface OnApprove {
    function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool);
}

interface IOptimismSystemConfig {
    function owner() external view returns (address);
    function optimismPortal() external view returns (address addr_);
    function l1StandardBridge() external view returns (address addr_);
}

interface IStandardBridge {
    function deposits(address, address) external view returns (uint256);
}

interface IOptimismPortal {
    function depositedAmount() external view returns (uint256);
}

interface IIDAOCommittee {
     function createCandidateAddOn(string calldata _memo, address _rollupConfig) external returns (address);
}

interface IIDepositManager {
    function deposit(address layer2, address account, uint256 amount) external returns (bool);
}

interface IOperatorManagerFactory {
    function createOperatorManager(address _rollupConfig) external returns (address);
}

interface ITON {
    function approveAndCall(address spender, uint256 amount, bytes memory data) external returns (bool);
}

interface IWTON {
     function swapFromTON(uint256 tonAmount) external returns (bool);
}

interface IOperator {
    function isOperator(address addr) external view returns (bool);
}

contract  Layer2ManagerV1_1 is ProxyStorage, AccessibleCommon, Layer2ManagerStorage {

    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;

    address internal constant LEGACY_ERC20_NATIVE_TOKEN = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

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

    /**
     * @notice Event occurs when setting the minimum initial deposit amount
     * @param _minimumInitialDepositAmount the minimum initial deposit amount
     */
    event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount);

    /**
     * @notice Event occurs when registering CandidateAddOn
     * @param rollupConfig      the rollupConfig address
     * @param wtonAmount        the wton amount depositing when registering CandidateAddOn
     * @param memo              the name of CandidateAddOn
     * @param operator          an operatorManager contract address
     * @param candidateAddOn    a candidateAddOn address
     */
    event RegisteredCandidateAddOn(address rollupConfig, uint256 wtonAmount, string memo, address operator, address candidateAddOn);

    /**
     * @notice Event occurs when pausing the CandidateAddOn
     * @param rollupConfig      the rollupConfig address
     * @param candidateAddOn    the candidateAddOn address
     */
    event PausedCandidateAddOn(address rollupConfig, address candidateAddOn);

    /**
     * @notice Event occurs when pausing the CandidateAddOn
     * @param rollupConfig      the rollupConfig address
     * @param candidateAddOn    the candidateAddOn address
     */
    event UnpausedCandidateAddOn(address rollupConfig, address candidateAddOn);

    /**
     * @notice Event occurs when pausisetting the operatorManagerFactory
     * @param _operatorManagerFactory   the operatorManagerFactory address
     */
    event SetOperatorManagerFactory(address _operatorManagerFactory);

    modifier onlySeigManger() {
        require(seigManager == msg.sender, "sender is not a SeigManager");
        _;
    }

    modifier onlyL1BridgeRegistry() {
        require(l1BridgeRegistry == msg.sender, "sender is not a L1BridgeRegistry");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    /* ========== onlyOwner ========== */

    function setAddresses(
        address _l1BridgeRegistry,
        address _operatorManagerFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _seigManager,
        address _swapProxy
    )  external  onlyOwner {
        l1BridgeRegistry = _l1BridgeRegistry;
        operatorManagerFactory = _operatorManagerFactory;
        ton = _ton;
        wton = _wton;
        dao = _dao;
        depositManager = _depositManager;
        seigManager = _seigManager;
        swapProxy = _swapProxy;

        emit SetAddresses(_l1BridgeRegistry, _operatorManagerFactory, _ton, _wton, _dao, _depositManager, _seigManager, _swapProxy);
    }

    function setOperatorManagerFactory(
        address _operatorManagerFactory
    )  external  onlyOwner {
        operatorManagerFactory = _operatorManagerFactory;
        emit SetOperatorManagerFactory( _operatorManagerFactory);
    }

    /**
     * @notice  Set the minimum TON deposit amount required when creating a CandidateAddOn.
     *          Due to calculating swton, it is recommended to set DepositManager's minimum deposit + 0.1 TON
     * @param   _minimumInitialDepositAmount the minimum initial deposit amount
     */
    function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner {
        require(minimumInitialDepositAmount != _minimumInitialDepositAmount, "same");
        minimumInitialDepositAmount = _minimumInitialDepositAmount;

        emit SetMinimumInitialDepositAmount(_minimumInitialDepositAmount);
    }


    /* ========== onlyL2Register ========== */

    /**
     * @notice Pause the CandidateAddOn
     * @param rollupConfig the rollupConfig address
     */
    function pauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree {
         SeqSeigStatus memory info = rollupConfigInfo[rollupConfig];
        // require(info.stateIssue == 1, "not in normal status");
        if (info.status != 1) revert StatusError();

        address _layer2 = operatorInfo[info.operatorManager].candidateAddOn;
        _nonZeroAddress(_layer2);

        rollupConfigInfo[rollupConfig].status = 2;
        emit PausedCandidateAddOn(rollupConfig, _layer2);

        (bool success, ) = seigManager.call(abi.encodeWithSignature("excludeFromSeigniorage(address)",_layer2));
        if (!success) revert ExcludeError();

    }

    /**
     * @notice Unpause the CandidateAddOn
     * @param rollupConfig the rollupConfig address
     */
    function unpauseCandidateAddOn(address rollupConfig) external onlyL1BridgeRegistry ifFree {
        SeqSeigStatus memory info = rollupConfigInfo[rollupConfig];
        // require(info.stateIssue == 2, "not in pause status");
        if (info.status != 2) revert StatusError();

        rollupConfigInfo[rollupConfig].status = 1;
        emit UnpausedCandidateAddOn(rollupConfig, operatorInfo[info.operatorManager].candidateAddOn);
    }

    /* ========== onlySeigManger  ========== */

    /**
     * @notice When executing update seigniorage, the seigniorage is settled to the Operator of Layer 2.
     * @param rollupConfig the rollupConfig address
     * @param amount the amount to give a seigniorage
     */
    function updateSeigniorage(address rollupConfig, uint256 amount) external onlySeigManger {

        IERC20(wton).safeTransfer(rollupConfigInfo[rollupConfig].operatorManager, amount);
    }

    /* ========== Anybody can execute ========== */

    /**
     * @notice Register the CandidateAddOn
     * @param rollupConfig     rollupConfig's address
     * @param amount           transferred amount
     * @param flagTon          if true, amount is ton, otherwise it wton
     * @param memo             layer's name
     */
    function registerCandidateAddOn(
        address rollupConfig,
        uint256 amount,
        bool flagTon,
        string calldata memo
    )
        external
    {
        _nonZeroAddress(rollupConfig);
        if (bytes(memo).length == 0) revert ZeroBytesError();
        if (rollupConfigInfo[rollupConfig].operatorManager != address(0)) revert RegisterError(4);
        (bool res,) = _availableRegister(rollupConfig, memo);

        if (!res) revert RegisterError(5);
        _transferDepositAmount(msg.sender, rollupConfig, amount, flagTon, memo);
    }


    /// @notice ERC20 Approve callback
    /// @param owner    Account that called approveAndCall
    /// @param spender  OnApprove function contract address
    /// @param amount   Approved amount
    /// @param data     Data used in OnApprove contract
    /// @return bool    true
    function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool) {
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
        (bool res,) = _availableRegister(_rollupConfig, string(_message));
        if (!res) revert RegisterError(5);

        // if (msg.sender == ton) _transferDepositAmount(owner, _rollupConfig, amount, true, string(bytes(data[20:])));
        // else _transferDepositAmount(owner, _rollupConfig, amount, false, string(bytes(data[20:])));

        if (msg.sender == ton) _transferDepositAmount(owner, _rollupConfig, amount, true, string(_message));
        else _transferDepositAmount(owner, _rollupConfig, amount, false, string(_message));

        return true;
    }

    /* ========== VIEW ========== */

    /**
     * @notice View the rollupConfig address of the operator address.
     * @param _oper     the operator address
     * @return          the rollupConfig address
     */
    function rollupConfigOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].rollupConfig;
    }

    /**
     * @notice View the operator address of the rollupConfig address.
     * @param _rollupConfig      the rollupConfig address
     * @return          the operator address
     */
    function operatorOfRollupConfig(address _rollupConfig) external view returns (address) {
        return rollupConfigInfo[_rollupConfig].operatorManager;
    }

    /**
     * @notice  View the CandidateAddOn address of the operator address.
     * @param _oper     the operator address
     * @return          the candidateAddOn address
     */
    function candidateAddOnOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].candidateAddOn;
    }

    /**
     * @notice View the status of seigniorage provision for Layer 2 corresponding to rollupConfig.
     * @param _rollupConfig     the rollupConfig address
     * @return              the status of seigniorage provision for Layer 2
     *                      ( 0: none , 1: registered, 2: paused )
     */
    function statusLayer2(address _rollupConfig) external view returns (uint8) {
        return rollupConfigInfo[_rollupConfig].status;
    }

    /**
     * @notice  Check Layer 2’s TON liquidity-related information
     * @param _rollupConfig the rollupConfig address
     * @return result       whether layer 2 TON liquidity can be checked
     * @return amount       the layer 2's TON amount (total value liquidity)
     */
    function checkLayer2TVL(address _rollupConfig) public view returns (bool result, uint256 amount) {
         return _checkLayer2TVL(_rollupConfig);
    }

    /**
     * @notice Layer 2 related information search
     * @param _rollupConfig     the rollupConfig address
     * @return result           whether Layer2 information can be searched
     * @return l1Bridge         the L1 bridge address
     * @return portal           the optimism portal address
     * @return l2Ton            the L2 TON address
     */
    function checkL1Bridge(address _rollupConfig) public view returns (bool result, address l1Bridge, address portal, address l2Ton) {
         (result, l1Bridge, portal, l2Ton,,,,) = _checkL1BridgeDetail(_rollupConfig);
    }

    function availableRegister(address _rollupConfig, string memory _name) external view returns (bool result, uint256 amount) {
        return _availableRegister(_rollupConfig, _name) ;
    }


    /**
     * @notice Layer 2 related information search
     * @param _rollupConfig     the rollupConfig address
     * @return result           whether Layer2 information can be searched
     * @return l1Bridge         the L1 bridge address
     * @return portal           the optimism portal address
     * @return l2Ton            the L2 TON address
     * @return _type            the layer 2 type ( 1: legacy optimism, 2: bedrock optimism with TON native token)
     * @return status           status for giving seigniorage ( 0: none , 1: registered, 2: paused )
     * @return rejectedSeigs     If it is true, Seigniorage issuance has been stopped for this layer2.
     * @return rejectedL2Deposit If it is true, stop depositing at this layer.
     */
    function checkL1BridgeDetail(address _rollupConfig) external view
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
         (result, l1Bridge, portal, l2Ton, _type, status, rejectedSeigs, rejectedL2Deposit) = _checkL1BridgeDetail(_rollupConfig);
    }

    function _checkL1BridgeDetail(address _rollupConfig)
        public
        view
        returns (bool result, address l1Bridge, address portal, address l2Ton, uint8 _type, uint8 status,
        bool rejectedSeigs, bool rejectedL2Deposit)
    {
        (_type, , rejectedSeigs, rejectedL2Deposit,) = IL1BridgeRegistry(l1BridgeRegistry).getRollupInfo(_rollupConfig);

        status = rollupConfigInfo[_rollupConfig].status;

        if (rollupConfigInfo[_rollupConfig].status == 1) {

            address l1Bridge_ = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();

            if (l1Bridge_ != address(0)) {
                if (_type == 1 || _type == 2) l2Ton = IL1BridgeRegistry(l1BridgeRegistry).l2TON(_rollupConfig);

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


    /* ========== internal ========== */

    function _nonZeroAddress(address _addr) internal pure {
        if(_addr == address(0)) revert ZeroAddressError();
    }

    function _registerCandidateAddOn(
        address _rollupConfig,
        uint256 _wtonAmount,
        string calldata _memo
    ) internal  {
        address operator = IOperatorManagerFactory(operatorManagerFactory).createOperatorManager(_rollupConfig);

        if (operator == address(0)) revert RegisterError(1);
        if (operatorInfo[operator].rollupConfig != address(0)) revert RegisterError(2);
        address candidateAddOn = IIDAOCommittee(dao).createCandidateAddOn(_memo, operator);
        operatorInfo[operator] = CandidateAddOnInfo({
            rollupConfig: _rollupConfig,
            candidateAddOn : candidateAddOn
        });

        rollupConfigInfo[_rollupConfig] = SeqSeigStatus({
            status: 1,
            operatorManager: operator
        });

        emit RegisteredCandidateAddOn(_rollupConfig, _wtonAmount, _memo, operator, candidateAddOn);

        if (IERC20(wton).allowance(address(this), depositManager) < _wtonAmount) IERC20(wton).approve(depositManager, type(uint256).max);
        if (!IIDepositManager(depositManager).deposit(candidateAddOn, operator, _wtonAmount)) revert RegisterError(3);

    }

    function _availableRegister(address _rollupConfig, string memory _name) internal view returns (bool result, uint256 amount) {

        (uint8 _type,,,,string  memory name_) = IL1BridgeRegistry(l1BridgeRegistry).getRollupInfo(_rollupConfig);
        // if (bytes32(bytes(_name)) != bytes32((bytes(name_)))) return (false, 0);  /// It must be the same as the name registered in l1BridgeRegister.

        if (_type == 1) { // optimism legacy : titan

            address l1Bridge = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();
            if (l1Bridge != address(0)) {
                amount = IERC20(ton).balanceOf(l1Bridge);
                result = true;
            }

        } else if (_type == 2) { // optimism bedrock native TON: thanos, on-demand-l2

            address l1Bridge = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();
            address optimismPortal = IOptimismSystemConfig(_rollupConfig).optimismPortal();
            if (optimismPortal != address(0) && l1Bridge != address(0) ) {
                amount = IERC20(ton).balanceOf(optimismPortal);
                result = true;
            }
        }
    }

    function _checkLayer2TVL(address _rollupConfig) internal view returns (bool result, uint256 amount) {

        uint8 _type = IL1BridgeRegistry(l1BridgeRegistry).rollupType(_rollupConfig);

        if (_type == 1) { // optimism legacy : titan

            address l1Bridge = IOptimismSystemConfig(_rollupConfig).l1StandardBridge();
            if (l1Bridge != address(0)) {
                amount = IERC20(ton).balanceOf(l1Bridge);
                result = true;
            }

        } else if (_type == 2) { // optimism bedrock native TON: thanos, on-demand-l2
            address optimismPortal = IOptimismSystemConfig(_rollupConfig).optimismPortal();
            if (optimismPortal != address(0)) {
                amount = IERC20(ton).balanceOf(optimismPortal);
                result = true;
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

        if (flagTon) { // with ton
            address _ton = ton;

            if (amount < minimumInitialDepositAmount) revert RegisterError(6);
            IERC20(_ton).safeTransferFrom(sender, address(this), amount);
            if (IERC20(_ton).allowance(address(this), _wton) < amount) IERC20(_ton).approve(_wton, type(uint256).max);
            if (!IWTON(_wton).swapFromTON(amount)) revert RegisterError(7);
            _registerCandidateAddOn(_rollupConfig, amount*1e9, memo);

        } else { // with wton

            if ((amount / 1e9) < minimumInitialDepositAmount) revert RegisterError(6);
            IERC20(_wton).safeTransferFrom(sender, address(this), amount);
            _registerCandidateAddOn(_rollupConfig, amount, memo);

        }
    }

}