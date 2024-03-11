// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract Layer2ManagerStorage  {

    struct Layer2Info {
        uint256 l2Tvl;
        uint256 initialDebt;
        uint256 unClaimedAmount;
        uint256 claimedAmount;
    }

    address public l2Register;
    address public operatorFactory;

    address public ton;
    address public wton;
    address public dao;
    address public depositManager;
    address public seigManager;
    address public swapProxy;

    uint256 public minimumInitialDepositAmount;

    // systemConfig - layer2 info
    mapping (address => Layer2Info) public l2Info;


    /// issueStatus for giving seigniorage
    /// systemConfig - stateIssue ( 0: none , 1: registered, 2: paused )
    mapping (address => uint8) public issueStatusLayer2;

    /// systemConfig - operator
    mapping (address => address) public operatorOfSystemConfig;
    // mapping (address => uint256) public claimedAmount;

    /// operator - systemConfig
    mapping (address => address) public systemConfigOfOperator;

    // L2 전체 TVL 양 : 실시간으로 반영하자.
    uint256 public totalTvl;
    // mapping (address => uint256) public l2Tvl;

    uint256 public acumulatedSeigniroge;
    uint256 public shares;
    uint256 public unReflectedSeigs;
    uint256 public minimumRelectedAmount;

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