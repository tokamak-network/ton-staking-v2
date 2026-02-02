// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISeigManager {
    function stakeOf(address layer2, address account) external view returns (uint256);
    function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
    function l1BridgeRegistry() external view returns (address);
    function layer2Manager() external view returns (address);
    function excludeFromL2Seigniorage(address _layer2) external returns (bool);
    function includeFromL2Seigniorage(address _layer2) external returns (bool);
    function onDeposit(address layer2, address account, uint256 amount) external returns (bool);
    function deployCoinage(address layer2) external returns (bool);
    function setCommissionRate(address layer2, uint256 commission, bool isCommissionRateNegative) external returns (bool);
    function progressSnapshotId() external view returns (uint256);
}
