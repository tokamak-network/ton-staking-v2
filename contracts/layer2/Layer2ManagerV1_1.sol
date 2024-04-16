// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Layer2ManagerStorage.sol";
import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";

import "hardhat/console.sol";

interface IL2Register {
    function systemConfigType(address systemConfig) external view returns (uint8);
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

interface IOperator {
    function isOperator(address addr) external view returns (bool);
}


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

    modifier onlySeigManger() {
        require(seigManager == msg.sender, "sender is not a SeigManager");
        _;
    }

    modifier onlyOperator(address systemConfig) {
        require(systemConfig != address(0), "zero systemConfig");
        address operatorContract = operatorOfSystemConfig[systemConfig];
        require(operatorContract != address(0), "zero operatorContract");
        require(IOperator(operatorContract).isOperator(msg.sender), "sender is not an operator");
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

        // if(minimumRelectedAmount == 0) minimumRelectedAmount = 1e27;

        emit SetAddresses(_l2Register, _operatorFactory, _ton, _wton, _dao, _depositManager, _seigManager, _swapProxy);
    }

    function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner {
        require(minimumInitialDepositAmount != _minimumInitialDepositAmount, "same");
        minimumInitialDepositAmount = _minimumInitialDepositAmount;

        emit SetMinimumInitialDepositAmount(_minimumInitialDepositAmount);
    }

    /* ========== onlySeigManger  ========== */

    function updateSeigniorage(address systemConfig, uint256 amount) external onlySeigManger {
        IERC20(wton).safeTransfer(operatorOfSystemConfig[systemConfig], amount);
    }


    /* ========== Anybody can execute ========== */

    /// @notice ERC20 Approve callback
    /// @param owner    Account that called approveAndCall
    /// @param spender  OnApprove function contract address
    /// @param amount   Approved amount
    /// @param data     Data used in OnApprove contract
    /// @return bool    true
    function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool) {
        require(msg.sender == ton || msg.sender == wton, "sender is not ton nor wton");
        require(spender == address(this), "wrong spender parameter");
        bytes memory _data = data;
        address _systemConfig;
        require(data.length > 20, "wrong data length");
        assembly {
            _systemConfig := mload(add(add(_data, 0x14), 0))
        }

        require(_systemConfig != address(0), "wrong data length");
        require(_checkLayer2(_systemConfig), "unValidated Layer2");

        if(msg.sender == ton ) _transferDepositAmount(owner, _systemConfig, amount, true, string(bytes(data[20:])));
        else _transferDepositAmount(owner, _systemConfig, amount, false, string(bytes(data[20:])));

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
        nonZeroAddress(systemConfig)
    {
        require(bytes(memo).length != 0, "check memo");

        require(_checkLayer2(systemConfig), "unValidated Layer2");
        _transferDepositAmount(msg.sender, systemConfig, amount, flagTon, memo);
    }


    /* ========== VIEW ========== */

    function checkLayer2TVL(address _systemConfig) public view returns (bool result, uint256 amount) {

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

    function _registerLayer2Candidate(
        address _systemConfig,
        uint256 _wtonAmount,
        string memory _memo
    ) internal nonZeroAddress(_systemConfig) {

        address operator = IOperatorFactory(operatorFactory).createOperator(_systemConfig);

        require(operator != address(0) && systemConfigOfOperator[operator] == address(0), "wrong operator");

        operatorOfSystemConfig[_systemConfig] = operator;
        systemConfigOfOperator[operator] = _systemConfig;

        address layer2Candidate = IIDAOCommittee(dao).createLayer2Candidate(_memo, operator);

        layer2CandidateOfOperator[operator] = layer2Candidate;

        _approve(depositManager, _wtonAmount);

        require(
            IIDepositManager(depositManager).deposit(layer2Candidate, operator, _wtonAmount),
            "Fail Stake");

        issueStatusLayer2[_systemConfig] = 1;

        emit RegisteredLayer2Candidate(_systemConfig, _wtonAmount, _memo, operator, layer2Candidate);

    }

    function _approve(address _addr, uint256 _wtonAmount) internal {
        uint256 allow_ = IERC20(wton).allowance(address(this), _addr);
        if (allow_ < _wtonAmount) IERC20(wton).approve(_addr, type(uint256).max);
    }

    function _checkLayer2(address systemConfig) internal view returns (bool){
        require(operatorOfSystemConfig[systemConfig] == address(0), "already registered");
        (bool check, ) = checkLayer2TVL(systemConfig);
        return check;
    }

    function _transferDepositAmount(
        address sender,
        address systemConfig,
        uint256 amount,
        bool flagTon,
        string calldata memo
    ) internal {

        if (flagTon) { // with ton

            require(amount >= minimumInitialDepositAmount, "unsatisfied initialDepositAmount");
            IERC20(ton).safeTransferFrom(sender, address(this), amount);
            require(
                ITON(ton).approveAndCall(wton, amount, abi.encode(swapProxy, swapProxy)),
                "fail to swap ton to wton"
            );
            _registerLayer2Candidate(systemConfig, amount*1e9, memo);

        } else { // with wton

            require( (amount / 1e9) >= minimumInitialDepositAmount, "unsatisfied initialDepositAmount");
            IERC20(wton).safeTransferFrom(sender, address(this), amount);
            _registerLayer2Candidate(systemConfig, amount, memo);

        }
    }

}