// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Layer2ManagerStorage.sol";
import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";

// import "hardhat/console.sol";

interface Il2RegistryForVerify {
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
    function create(address _systemConfig) external returns (address);
}

interface ITON {
    function approveAndCall(address spender, uint256 amount, bytes memory data) external returns (bool);
}

contract  Layer2ManagerV1_1 is ProxyStorage, AccessibleCommon, Layer2ManagerStorage {

    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;

    event SetAddresses(
        address _l2RegistryForVerify,
        address _operatorFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _swapProxy
    );
    event SetMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount);

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    /* ========== onlyOwner ========== */

    function setAddresses(
        address _l2RegistryForVerify,
        address _operatorFactory,
        address _ton,
        address _wton,
        address _dao,
        address _depositManager,
        address _swapProxy
    )  external  onlyOwner {

        require(
            l2RegistryForVerify != _l2RegistryForVerify
            || operatorFactory != _operatorFactory
            || ton != _ton
            || wton != _wton
            || dao != _dao
            || depositManager != _depositManager
            || swapProxy != _swapProxy
            , "all same"
        );

        l2RegistryForVerify = _l2RegistryForVerify;
        operatorFactory = _operatorFactory;
        ton = _ton;
        wton = _wton;
        dao = _dao;
        depositManager = _depositManager;
        swapProxy = _swapProxy;

        emit SetAddresses(_l2RegistryForVerify, _operatorFactory, _ton, _wton, _dao, _depositManager, _swapProxy);
    }

    function setMinimumInitialDepositAmount(uint256 _minimumInitialDepositAmount)  external  onlyOwner {
        require(minimumInitialDepositAmount != _minimumInitialDepositAmount, "same");
        minimumInitialDepositAmount = _minimumInitialDepositAmount;

        emit SetMinimumInitialDepositAmount(_minimumInitialDepositAmount);
    }

    /* ========== Anybody can execute ========== */

    /// @notice ERC20 Approve callback
    /// @param owner    Account that called approveAndCall
    /// @param spender  OnApprove function contract address
    /// @param amount   Approved amount
    /// @param data     Data used in OnApprove contract
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
        require(_checkLayer2(_systemConfig), "unvalidated Layer2");

        if(msg.sender == ton ) _transferDepositAmount(owner, _systemConfig, amount, true, string(bytes(data[20:])));
        else _transferDepositAmount(owner, _systemConfig, amount, false, string(bytes(data[20:])));

        return true;
    }


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

        require(_checkLayer2(systemConfig), "unvalidated Layer2");

        _transferDepositAmount(msg.sender, systemConfig, amount, flagTon, memo);
    }


    /* ========== VIEW ========== */

    function checkLayer2TVL(address _systemConfig) public view returns (bool result, uint256 amount) {

        uint8 _type = Il2RegistryForVerify(l2RegistryForVerify).systemConfigType(_systemConfig);

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

    /* ========== internal ========== */

    function _registerLayer2Candidate(
        address _systemConfig,
        uint256 _wtonAmount,
        string memory _memo
    ) internal nonZeroAddress(_systemConfig) {

        // create operator
        address operator = IOperatorFactory(operatorFactory).create(_systemConfig);
        require(operator != address(0) && systemConfigOfOperator[operator] == address(0), "wrong operator");

        operatorOfSystemConfig[_systemConfig] = operator;
        systemConfigOfOperator[operator] = _systemConfig;

        // 실제로 Layer2Candidate를 생성
        address layer2Candidate = IIDAOCommittee(dao).createLayer2Candidate(_memo, operator);

        _approve(depositManager, _wtonAmount);

        // operator 로 스테이킹한다.
        require(
            IIDepositManager(depositManager).deposit(layer2Candidate, operator, _wtonAmount),
            "Fail Stake");

        // 시뇨리지 발급 가능상태로 설정
        issueStatusLayer2[_systemConfig] = 1;
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