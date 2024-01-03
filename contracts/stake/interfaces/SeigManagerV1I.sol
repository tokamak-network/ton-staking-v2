// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface SeigManagerV1I {
  function registry() external view returns (address);
  function depositManager() external view returns (address);
  function ton() external view returns (address);
  function wton() external view returns (address);
  function powerton() external view returns (address);
  function tot() external view returns (address);
  function coinages(address layer2) external view returns (address);
  function commissionRates(address layer2) external view returns (uint256);

  function lastCommitBlock(address layer2) external view returns (uint256);
  function seigPerBlock() external view returns (uint256);
  function lastSeigBlock() external view returns (uint256);
  function pausedBlock() external view returns (uint256);
  function unpausedBlock() external view returns (uint256);
  function DEFAULT_FACTOR() external view returns (uint256);

  function deployCoinage(address layer2) external returns (bool);
  function setCommissionRate(address layer2, uint256 commission, bool isCommissionRateNegative) external returns (bool);

  function uncommittedStakeOf(address layer2, address account) external view returns (uint256);
  function uncommittedStakeOf(address account) external view returns (uint256 amount);
  function unallocatedSeigniorage() external view returns (uint256 amount);

  function stakeOf(address layer2, address account) external view returns (uint256);
  function stakeOf(address account) external view returns (uint256 amount);
  function stakeOfTotal() external view returns (uint256 amount);
  function stakeOfAllLayers() external view returns (uint256 amount);

  function additionalTotBurnAmount(address layer2, address account, uint256 amount) external view returns (uint256 totAmount);

  function onTransfer(address sender, address recipient, uint256 amount) external returns (bool);
  function updateSeigniorage() external returns (bool);
  function updateSeigniorageLayer(address layer2) external returns (bool);

  function onDeposit(address layer2, address account, uint256 amount) external returns (bool);
  function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
  function onSnapshot() external returns (uint256 snapshotId);

}
