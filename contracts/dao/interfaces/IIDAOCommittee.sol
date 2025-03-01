// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IIDAOCommittee {
     function createCandidateAddOn(string calldata _memo, address _rollupConfig) external returns (address);
}
