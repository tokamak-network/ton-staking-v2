// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IISeigManager {
    function updateSeigniorage() external returns (bool);
    function updateSeigniorageOperator() external returns (bool);
    function coinages(address layer2) external view returns (address);
    function onSettleReward(address layer2) external returns (bool);
}
