// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract Layer2ManagerStorage   {

    address public l2RegistryForVerify;
    address public operatorFactory;

    address public ton;
    address public wton;
    address public dao;
    address public depositManager;
    address public swapProxy;

    uint256 public minimumInitialDepositAmount;

    /// issueStatus for giving seigniorage
    /// systemConfig - stateIssue ( 0: none , 1: registered, 2: paused )
    mapping (address => uint8) public issueStatusLayer2;

    /// systemConfig - operator
    mapping (address => address) public operatorOfSystemConfig;

    /// operator - systemConfig
    mapping (address => address) public systemConfigOfOperator;

    // L2 전체 TVL 양
    uint256 totalTvl;
    // L2 Tvl 양
    mapping (address => address) public l2Tvl;

    // IndexAmount * index = 환산된 시뇨리지
    uint256 tSeigsIndexAmount;
    uint256 l2SeigsIndexAMount;

    // L2 오퍼레이터에게 준 전체 시뇨리지 인덱스
    uint256 tIndex;
    // L2 오퍼레이터에게 주는 시뇨리지 인덱스
    mapping (address => address) public l2Index ;


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