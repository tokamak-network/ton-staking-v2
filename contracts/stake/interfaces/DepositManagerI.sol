// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface DepositManagerI {
  function owner() external view returns (address);
  function wton() external view returns (address);
  function registry() external view returns (address);
  function seigManager() external view returns (address);

  function accStaked(address layer2, address account) external view returns (uint256 wtonAmount);
  function accStakedLayer2(address layer2) external view returns (uint256 wtonAmount);
  function accStakedAccount(address account) external view returns (uint256 wtonAmount);

  function pendingUnstaked(address layer2, address account) external view returns (uint256 wtonAmount);
  function pendingUnstakedLayer2(address layer2) external view returns (uint256 wtonAmount);
  function pendingUnstakedAccount(address account) external view returns (uint256 wtonAmount);

  function accUnstaked(address layer2, address account) external view returns (uint256 wtonAmount);
  function accUnstakedLayer2(address layer2) external view returns (uint256 wtonAmount);
  function accUnstakedAccount(address account) external view returns (uint256 wtonAmount);


  function withdrawalRequestIndex(address layer2, address account) external view returns (uint256 index);
  function withdrawalRequest(address layer2, address account, uint256 index) external view returns (uint128 withdrawableBlockNumber, uint128 amount, bool processed );

  function WITHDRAWAL_DELAY() external view returns (uint256);

  function setSeigManager(address seigManager) external;
  function deposit(address layer2, uint256 amount) external returns (bool);
  function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
  function processRequest(address layer2) external returns (bool);
  function requestWithdrawalAll(address layer2) external returns (bool);
  function processRequests(address layer2, uint256 n) external returns (bool);

  function numRequests(address layer2, address account) external view returns (uint256);
  function numPendingRequests(address layer2, address account) external view returns (uint256);

  function slash(address layer2, address recipient, uint256 amount) external returns (bool);
}
