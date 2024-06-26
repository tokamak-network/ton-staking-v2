// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract Layer2ManagerStorage  {

    struct OperatorInfo {
        address systemConfig;
        address layer2Candidate;
    }

    struct SystemConfigInfo {
        uint8 stateIssue; // status for giving seigniorage ( 0: none , 1: registered, 2: paused )
        address operator;
    }

    address public l2Register;
    address public operatorFactory;

    address public ton;
    address public wton;
    address public dao;
    address public depositManager;
    address public seigManager;
    address public swapProxy;

    uint256 public minimumInitialDepositAmount;   /// ton

    /// systemConfig - SystemConfigInfo
    mapping (address => SystemConfigInfo) public systemConfigInfo;

    /// operator - OperatorInfo
    mapping (address => OperatorInfo) public operatorInfo;

    bool internal _lock;

    modifier ifFree {
        require(!_lock, "lock");
        _lock = true;
        _;
        _lock = false;
    }
}