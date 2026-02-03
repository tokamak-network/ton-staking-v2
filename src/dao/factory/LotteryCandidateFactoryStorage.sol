// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LotteryCandidateFactoryStorage {
    address public depositManager;
    address public daoCommittee;
    address public lotteryCandidateImp;
    address public ton;
    address public wton;
    uint256 public defaultEntryFee;  // Default entry fee for new LotteryCandidates (WTON, 27 decimals)
}
