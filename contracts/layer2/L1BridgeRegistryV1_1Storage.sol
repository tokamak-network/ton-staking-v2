// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract L1BridgeRegistryV1_1Storage   {

    /// Set the layer where seigniorage issuance has been suspended to true.
    mapping (address => bool) public rejectSystemConfig;
    address public seigniorageCommittee;
}