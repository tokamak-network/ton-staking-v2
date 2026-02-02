// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWTON {
     function swapFromTON(uint256 tonAmount) external returns (bool);
     function swapToTON(uint256 wtonAmount) external returns (bool);
     function ton() external view returns (address);
}