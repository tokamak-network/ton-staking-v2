// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOperateContract {
    function isOperator(address addr) external view returns (bool) ;
    function rollupConfig() external view returns (address) ;
    function manager() external view returns (address) ;
    function claimByCandidateAddOn(uint256 amount, bool falgTon) external;
    function depositByCandidateAddOn(uint256 amount) external ;
}

