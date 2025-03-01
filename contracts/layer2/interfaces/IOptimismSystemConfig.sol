// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IOptimismSystemConfig {
    function l1StandardBridge() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_) ;

}