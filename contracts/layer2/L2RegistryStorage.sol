// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract L2RegistryStorage   {

    struct Layer2Info {
        uint256 l2Tvl;
        uint256 initialDebt;
        uint256 unClaimedAmount;
        uint256 claimedAmount;
    }

    address public layer2Manager;
    address public seigManager;

    /// systemConfig - type (0:empty, 1: optimism legacy, 2: optimism bedrock )
    mapping (address => uint8) public systemConfigType;

    mapping (address => bool) public l1Bridge;
    mapping (address => bool) public portal;

     // L2 전체 TVL 양 : 실시간으로 반영하자.
    uint256 public totalTvl;

    // systemConfig - layer2 info
    mapping (address => Layer2Info) public l2Info;
    uint256 public rewardPerUnit;
    uint256 public unReflectedSeigs;
    uint256 public minimumRelectedAmount;
}