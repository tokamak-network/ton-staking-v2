// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract SeigManagerV1_VoteStorage  {
    address public voteToken;
    uint256 public totalVotes;
    mapping(address => uint256) public votes;
}
