// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract Layer2ManagerStorage  {

    address public l2Register;
    address public operatorFactory;

    address public ton;
    address public wton;
    address public dao;
    address public depositManager;
    address public seigManager;
    address public swapProxy;

    uint256 public minimumInitialDepositAmount;   /// ton

    /// issueStatus for giving seigniorage
    /// systemConfig - stateIssue ( 0: none , 1: registered, 2: paused )
    mapping (address => uint8) public issueStatusLayer2;

    /// systemConfig - operator
    mapping (address => address) public operatorOfSystemConfig;

    /// operator - systemConfig
    mapping (address => address) public systemConfigOfOperator;

    /// operator - layer2Candidate
    mapping (address => address) public layer2CandidateOfOperator;


    bool internal free = true;

    modifier nonZero(uint256 value) {
        require(value != 0, "Z1");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(account != address(0), "Z2");
        _;
    }

    modifier ifFree {
        require(free, "lock");
        free = false;
        _;
        free = true;
    }
}