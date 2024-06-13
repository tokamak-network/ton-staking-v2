// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Layer2ManagerStorage.sol";
import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";


interface IL2Register {
    function systemConfigType(address systemConfig) external view returns (uint8);
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

/**
 * @notice  Error in onApprove function
 * @param x 1: sender is not ton nor wton
 *          2: wrong spender parameter
 *          3: wrong data parameter length
 */
error OnApproveError(uint x);

contract  Layer2ManagerV1_1 is ProxyStorage, AccessibleCommon, Layer2ManagerStorage {

    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;

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

    event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount);
    event RegisteredLayer2Candidate(address systemConfig, uint256 wtonAmount, string memo, address operator, address layer2Candidate);
    event PausedLayer2Candidate(address systemConfig, address _layer2);
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

        require(
            l2Register != _l2Register
            || operatorFactory != _operatorFactory
            || ton != _ton
            || wton != _wton
            || dao != _dao
            || depositManager != _depositManager
            || seigManager != _seigManager
            || swapProxy != _swapProxy
            , "all same"
        );

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

    function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner {
        require(minimumInitialDepositAmount != _minimumInitialDepositAmount, "same");
        minimumInitialDepositAmount = _minimumInitialDepositAmount;

        emit SetMinimumInitialDepositAmount(_minimumInitialDepositAmount);
    }


    /* ========== onlyL2Register ========== */
    function pauseLayer2Candidate(address systemConfig) external onlyL2Register ifFree {

        require(systemConfigInfo[systemConfig].stateIssue == 1, "not in normal status");

        address _layer2 = operatorInfo[systemConfigInfo[systemConfig].operator].layer2Candidate;
        require(_layer2 != address(0), "zero layer2");

        // issueStatusLayer2[systemConfig] = 2;
        systemConfigInfo[systemConfig].stateIssue = 2;
        emit PausedLayer2Candidate(systemConfig, _layer2);
        (bool success, ) = seigManager.call(abi.encodeWithSignature("excludeFromSeigniorage(address)",_layer2));
        require(success, "fail excludeFromSeigniorage");
    }

    function unpauseLayer2Cnadidate(address systemConfig) external onlyL2Register ifFree {
        require(systemConfigInfo[systemConfig].stateIssue == 2, "not in pause status");

        // issueStatusLayer2[systemConfig] = 1;
        systemConfigInfo[systemConfig].stateIssue = 1;
        emit UnpausedLayer2Candidate(systemConfig, operatorInfo[systemConfigInfo[systemConfig].operator].layer2Candidate);
    }

    /* ========== onlySeigManger  ========== */

    function updateSeigniorage(address systemConfig, uint256 amount) external onlySeigManger {

        IERC20(wton).safeTransfer(systemConfigInfo[systemConfig].operator, amount);
    }

    /* ========== Anybody can execute ========== */
    function systemConfigOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].systemConfig;
    }

    function operatorOfSystemConfig(address _sys) external view returns (address) {
        return systemConfigInfo[_sys].operator;
    }

    function layer2CandidateOfOperator(address _oper) external view returns (address) {
        return operatorInfo[_oper].layer2Candidate;
    }

    function issueStatusLayer2(address _sys) external view returns (uint8) {
        return systemConfigInfo[_sys].stateIssue;
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

        // bytes memory _data = data;
        bytes calldata _message;
        address _systemConfig;
        // require(data.length > 20, "wrong data length");
        if (data.length <= 20) revert OnApproveError(3);
        assembly {
            // _systemConfig := mload(add(add(_data, 0x14), 0))
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

    /// @notice Register the Layer2Candidate
    /// @param systemConfig     systemConfig's address
    /// @param amount           transfered amount
    /// @param flagTon          if true, amount is ton, otherwise it it wton
    /// @param memo             layer's name
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


    /* ========== VIEW ========== */

    function checkLayer2TVL(address _systemConfig) public view returns (bool result, uint256 amount) {
         return _checkLayer2TVL(_systemConfig);
    }


    function checkL1Bridge(address _systemConfig) public view returns (bool result, address l1Bridge, address l2Ton) {

        uint8 _type = IL2Register(l2Register).systemConfigType(_systemConfig);

        try
            ISystemConfig(_systemConfig).l1StandardBridge() returns (address l1Bridge_) {
                if (l1Bridge_ != address(0)) {
                    if (_type == 1) l2Ton = ISystemConfig(_systemConfig).l2Ton();
                    else if (_type == 2) l2Ton = address(bytes20(bytes('0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000')));
                    if (l2Ton != address(0)) {
                        // if (_type == 1 || _type == 2) {
                        result = true;
                        l1Bridge = l1Bridge_;
                        // }
                    }
                }
            } catch (bytes memory ) { }
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

        uint8 _type = IL2Register(l2Register).systemConfigType(_systemConfig);

        if (_type == 1) { // optimism legacy : titan
            try
                ISystemConfig(_systemConfig).l1StandardBridge() returns (address l1Bridge) {
                    if (l1Bridge != address(0)) {
                        address l2Ton = ISystemConfig(_systemConfig).l2Ton();
                        if (l2Ton != address(0)) {
                            amount = IStandardBridge(l1Bridge).deposits(ton, l2Ton);
                            result = true;
                        }
                    }
            } catch (bytes memory ) { }

        } else if (_type == 2) { // optimism bedrock : thanos, on-demand-l2
            try
                ISystemConfig(_systemConfig).optimismPortal() returns (address optimismPortal) {
                    if (optimismPortal != address(0)) {
                        amount = IOptimismPortal(optimismPortal).depositedAmount();
                        result = true;
                    }
            } catch (bytes memory ) { }
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

        if (flagTon) { // with ton

            if (amount < minimumInitialDepositAmount) revert RegisterError(6);
            IERC20(ton).safeTransferFrom(sender, address(this), amount);
            if (IERC20(ton).allowance(address(this), wton) < amount) IERC20(ton).approve(wton, type(uint256).max);
            if (!IWTON(wton).swapFromTON(amount)) revert RegisterError(7);
            _registerLayer2Candidate(systemConfig, amount*1e9, memo);

        } else { // with wton

            if ((amount / 1e9) < minimumInitialDepositAmount) revert RegisterError(6);
            IERC20(wton).safeTransferFrom(sender, address(this), amount);
            _registerLayer2Candidate(systemConfig, amount, memo);

        }
    }

}