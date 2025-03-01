// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISeigManager {
    function stakeOf(address layer2, address account) external view returns (uint256);
    function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
    function l1BridgeRegistry() external view returns (address);
    function layer2Manager() external view returns (address);
}
