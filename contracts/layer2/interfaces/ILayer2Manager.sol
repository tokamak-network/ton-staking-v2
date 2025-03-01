// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface ILayer2Manager {
    function pauseCandidateAddOn(address rollupConfig) external;
    function unpauseCandidateAddOn(address rollupConfig) external;
}