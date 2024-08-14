// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Layer2ManagerStorage.sol";
import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";


/**
 * @notice  Error that occurs when registering Layer2Candidate
 * @param x 1: don't create operator
 *          2: already systemConfigOfOperator registered
 *          3: fail deposit
 *          4: already operatorOfSystemConfig registered
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

interface IL2Register {
    function rollupType(address systemConfig) external view returns (uint8);
    function checkLayer2TVL(address _systemConfig) external view returns (bool result, uint256 amount);
}

interface OnApprove {
    function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool);
}

interface ISystemConfig {
    function owner() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address addr_);
    // function l1ERC721Bridge() external view returns (address addr_);
    function l1StandardBridge() external view returns (address addr_);
    function l2OutputOracle() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_) ;
    // function optimismMintableERC20Factory() external view returns (address addr_);
    // function batchInbox() external view returns (address addr_) ;
    function l2Ton() external view returns (address addr_) ;
}

interface IStandardBridge {
    function deposits(address, address) external view returns (uint256);
}

interface IOptimismPortal {
    function depositedAmount() external view returns (uint256);
}

interface IIDAOCommittee {
     function createLayer2Candidate(string calldata _memo, address _systemConfig) external returns (address);
}

interface IIDepositManager {
    function deposit(address layer2, address account, uint256 amount) external returns (bool);
}

interface IOperatorFactory {
    function createOperator(address _systemConfig) external returns (address);
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
        address _operatorFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _seigManager,
        address _swapProxy
    );

    /**
     * @notice Event occurs when setting the minimum initial deposit amount
     * @param _minimumInitialDepositAmount the inimum initial deposit amount
     */
    event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount);

    /**
     * @notice Event occurs when registering Layer2Candidate
     * @param systemConfig      the systemConfig address
     * @param wtonAmount        the wton amount depositing when registering Layer2Canddiate
     * @param memo              the name of Layer2Canddiate
     * @param operator          a opperator contract address
     * @param layer2Candidate   a layer2Candidate address
     */
    event RegisteredLayer2Candidate(address systemConfig, uint256 wtonAmount, string memo, address operator, address layer2Candidate);

    /**
     * @notice Event occurs when pausing the layer2 candidate
     * @param systemConfig      the systemConfig address
     * @param _layer2           the layer2 address
     */
    event PausedLayer2Candidate(address systemConfig, address _layer2);

    /**
     * @notice Event occurs when pausing the layer2 candidate
     * @param systemConfig      the systemConfig address
     * @param _layer2           the layer2 address
     */
    event UnpausedLayer2Candidate(address systemConfig, address _layer2);

    modifier onlySeigManger() {
        require(seigManager == msg.sender, "sender is not a SeigManager");
        _;
    }

    modifier onlyL2Register() {
        require(l2Register == msg.sender, "sender is not a l2Register");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    /* ========== onlyOwner ========== */

    function setAddresses(
        address _l2Register,
        address _operatorFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _seigManager,
        address _swapProxy
    )  external  onlyOwner {
        l2Register = _l2Register;
        operatorFactory = _operatorFactory;
        ton = _ton;
        wton = _wton;
        dao = _dao;
        depositManager = _depositManager;
        seigManager = _seigManager;
        swapProxy = _swapProxy;

        emit SetAddresses(_l2Register, _operatorFactory, _ton, _wton, _dao, _depositManager, _seigManager, _swapProxy);
    }

    /**
     * @notice  Set the minimum TON deposit amount required when creating a Layer2Candidate.
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
     * @notice Pause the layer2 candidate
     * @param systemConfig the systemConfig address
     */
    function pauseLayer2Candidate(address systemConfig) external onlyL2Register ifFree {
         SystemConfigInfo memory info = systemConfigInfo[systemConfig];
        // require(info.stateIssue == 1, "not in normal status");
        if (info.stateIssue != 1) revert StatusError();

        address _layer2 = operatorInfo[info.operator].layer2Candidate;
        _nonZeroAddress(_layer2);

        systemConfigInfo[systemConfig].stateIssue = 2;
        emit PausedLayer2Candidate(systemConfig, _layer2);

        (bool success, ) = seigManager.call(abi.encodeWithSignature("excludeFromSeigniorage(address)",_layer2));
        if (!success) revert ExcludeError();

    }

    /**
     * @notice Unpause the layer2 candidate
     * @param systemConfig the systemConfig address
     */
    function unpauseLayer2Cnadidate(address systemConfig) external onlyL2Register ifFree {
        SystemConfigInfo memory info = systemConfigInfo[systemConfig];
        // require(info.stateIssue == 2, "not in pause status");
        if (info.stateIssue != 2) revert StatusError();

        systemConfigInfo[systemConfig].stateIssue = 1;
        emit UnpausedLayer2Candidate(systemConfig, operatorInfo[info.operator].layer2Candidate);
    }

    /* ========== onlySeigManger  ========== */

    /**
     * @notice When executing update seigniorage, the seigniorage is settled to the Operator of Layer 2.
     * @param systemConfig the systemConfig address
     * @param amount the amount to give a seigniorage
     */
    function updateSeigniorage(address systemConfig, uint256 amount) external onlySeigManger {

        IERC20(wton).safeTransfer(systemConfigInfo[systemConfig].operator, amount);
    }

    /* ========== Anybody can execute ========== */

    /**
     * @notice Register the Layer2Candidate
     * @param systemConfig     systemConfig's address
     * @param amount           transfered amount
     * @param flagTon          if true, amount is ton, otherwise it it wton
     * param memo             layer's name
     */
    function registerLayer2Candidate(
        address systemConfig,
        uint256 amount,
        bool flagTon,
        string calldata memo
    )
        external
    {
        _nonZeroAddress(systemConfig);
        if (bytes(memo).length == 0) revert ZeroBytesError();
        if (systemConfigInfo[systemConfig].operator != address(0)) revert RegisterError(4);

        if (!_checkLayer2(systemConfig)) revert RegisterError(5);
        _transferDepositAmount(msg.sender, systemConfig, amount, flagTon, memo);
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
        address _systemConfig;
        if (data.length <= 20) revert OnApproveError(3);
        assembly {
            _systemConfig := shr(96, calldataload(data.offset))
            _message.offset := add(data.offset, 20)
            _message.length := sub(data.length, 20)
        }

        _nonZeroAddress(_systemConfig);

        if (systemConfigInfo[_systemConfig].operator != address(0)) revert RegisterError(4);

        if (!_checkLayer2(_systemConfig)) revert RegisterError(5);

        // if (msg.sender == ton) _transferDepositAmount(owner, _systemConfig, amount, true, string(bytes(data[20:])));
        // else _transferDepositAmount(owner, _systemConfig, amount, false, string(bytes(data[20:])));

        if (msg.sender == ton) _transferDepositAmount(owner, _systemConfig, amount, true, string(_message));
        else _transferDepositAmount(owner, _systemConfig, amount, false, string(_message));

        return true;
    }

    /* ========== VIEW ========== */

    /**
     * @notice View the systemConfig address of the operator address.
     * @param _oper     the operator address
     * @return          the systemConfig address
     */
    function systemConfigOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].systemConfig;
    }

    /**
     * @notice View the operator address of the systemConfig address.
     * @param _sys      the systemConfig address
     * @return          the operator address
     */
    function operatorOfSystemConfig(address _sys) external view returns (address) {
        return systemConfigInfo[_sys].operator;
    }

    /**
     * @notice  View the layer2Candidate address of the operator address.
     * @param _oper     the operator address
     * @return          the layer2Candidate address
     */
    function layer2CandidateOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].layer2Candidate;
    }

    /**
     * @notice View the status of seigniorage provision for Layer 2 corresponding to SystemConfig.
     * @param _sys      the systemConfig address
     * @return          the status of seigniorage provision for Layer 2
     *                  ( 0: none , 1: registered, 2: paused )
     */
    function issueStatusLayer2(address _sys) external view returns (uint8) {
        return systemConfigInfo[_sys].stateIssue;
    }

    /**
     * @notice  Check Layer 2’s TON liquidity related information
     * @param _systemConfig the syatemConfig address
     * @return result       whether layer 2 TON liquidity can be checked
     * @return amount       the layer 2's TON amount (total value liquidity)
     */
    function checkLayer2TVL(address _systemConfig) public view returns (bool result, uint256 amount) {
         return _checkLayer2TVL(_systemConfig);
    }

    /**
     * @notice Layer 2 related information search
     * @param _systemConfig     the systemConfig address
     * @return result           whether Layer2 information can be searched
     * @return l1Bridge         the L1 bridge address
     * @return portal           the optimism portal address
     * @return l2Ton            the L2 TON address
     */
    function checkL1Bridge(address _systemConfig) public view returns (bool result, address l1Bridge, address portal, address l2Ton) {

        uint8 _type = IL2Register(l2Register).rollupType(_systemConfig);

        if (systemConfigInfo[_systemConfig].stateIssue == 1) {

            address l1Bridge_ = ISystemConfig(_systemConfig).l1StandardBridge();

            if (l1Bridge_ != address(0)) {
                if (_type == 1) l2Ton = ISystemConfig(_systemConfig).l2Ton();
                else if (_type == 2) l2Ton = LEGACY_ERC20_NATIVE_TOKEN;

                if (l2Ton != address(0)) {
                    result = true;
                    l1Bridge = l1Bridge_;
                }
            }

            if (l2Ton == LEGACY_ERC20_NATIVE_TOKEN) {
                address portal_ = ISystemConfig(_systemConfig).optimismPortal();

                if (portal_ == address(0)) result = false;
                else portal = portal_;
            }
        }
    }


    /* ========== internal ========== */

    function _nonZeroAddress(address _addr) internal pure {
        if(_addr == address(0)) revert ZeroAddressError();
    }

    function _registerLayer2Candidate(
        address _systemConfig,
        uint256 _wtonAmount,
        string calldata _memo
    ) internal  {

        address operator = IOperatorFactory(operatorFactory).createOperator(_systemConfig);
        if (operator == address(0)) revert RegisterError(1);
        if (operatorInfo[operator].systemConfig != address(0)) revert RegisterError(2);

        address layer2Candidate = IIDAOCommittee(dao).createLayer2Candidate(_memo, operator);

        operatorInfo[operator] = OperatorInfo({
            systemConfig: _systemConfig,
            layer2Candidate : layer2Candidate
        });

        systemConfigInfo[_systemConfig] = SystemConfigInfo({
            stateIssue: 1,
            operator: operator
        });

        emit RegisteredLayer2Candidate(_systemConfig, _wtonAmount, _memo, operator, layer2Candidate);

        if (IERC20(wton).allowance(address(this), depositManager) < _wtonAmount) IERC20(wton).approve(depositManager, type(uint256).max);
        if (!IIDepositManager(depositManager).deposit(layer2Candidate, operator, _wtonAmount)) revert RegisterError(3);
    }

    function _checkLayer2TVL(address _systemConfig) internal view returns (bool result, uint256 amount) {

        uint8 _type = IL2Register(l2Register).rollupType(_systemConfig);

        if (_type == 1) { // optimism legacy : titan

            address l1Bridge = ISystemConfig(_systemConfig).l1StandardBridge();
            if (l1Bridge != address(0)) {
                address l2Ton = ISystemConfig(_systemConfig).l2Ton();
                if (l2Ton != address(0)) {
                    amount = IStandardBridge(l1Bridge).deposits(ton, l2Ton);
                    result = true;
                }
            }

        } else if (_type == 2) { // optimism bedrock native TON: thanos, on-demand-l2

            address optimismPortal = ISystemConfig(_systemConfig).optimismPortal();
            if (optimismPortal != address(0)) {
                amount = IOptimismPortal(optimismPortal).depositedAmount();
                result = true;
            }
        }
    }

    function _checkLayer2(address systemConfig) internal view returns (bool check){
        (check, ) = _checkLayer2TVL(systemConfig);
    }

    function _transferDepositAmount(
        address sender,
        address systemConfig,
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
            _registerLayer2Candidate(systemConfig, amount*1e9, memo);

        } else { // with wton

            if ((amount / 1e9) < minimumInitialDepositAmount) revert RegisterError(6);
            IERC20(_wton).safeTransferFrom(sender, address(this), amount);
            _registerLayer2Candidate(systemConfig, amount, memo);

        }
    }

}