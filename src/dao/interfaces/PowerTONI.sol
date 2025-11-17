// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface PowerTONI {
  function seigManager() external view returns (address);
  function wton() external view returns (address);

  function currentRound() external view returns (uint256);
  function roundDuration() external view returns (uint256);
  function totalDeposits() external view returns (uint256);

  function winnerOf(uint256 round) external view returns (address);
  function powerOf(address account) external view returns (uint256);

  function init() external;
  function start() external;
  function endRound() external;

  function onDeposit(address layer2, address account, uint256 amount) external;
  function onWithdraw(address layer2, address account, uint256 amount) external;
}
