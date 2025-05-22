// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StorageStateCommitteeV2 {
    address internal _implementation;
    bool public pauseProxy;

    // 마이그레이션 함. 이전 레이어 정보
    mapping(address => CandidateInfo2) internal _oldCandidateInfos;

    struct CandidateInfo2 {
        address candidateContract;
        address newCandidate;
        uint256 indexMembers;
        uint128 memberJoinedTime;
        uint128 rewardPeriod;
        uint128 claimedTimestamp;
    }

    address public wton;
    address public layer2Manager;
    address public candidateAddOnFactory;

    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public privateLayer2;

    mapping(address => uint256) public cooldown;

    uint256 public cooldownTime;
}