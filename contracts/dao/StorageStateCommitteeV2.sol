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

    // bytes internal claimTONBytes = hex"ef0d5594";
    // bytes internal claimERC20Bytes = hex"f848091a";
    // bytes internal claimWTONBytes = hex"f52bba70";
}