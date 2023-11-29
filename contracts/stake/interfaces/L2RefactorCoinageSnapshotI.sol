// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRefactor } from "../interfaces/IRefactor.sol";
interface L2RefactorCoinageSnapshotI {
  function updateFactor(IRefactor.Factor memory _factor) external;
  function updateBalance(
    IRefactor.Balance memory _accountBalance,
    IRefactor.Balance memory _totalBalance,
    address account,
    bool accountBool,
    bool totalBool
  ) external;

  function factor() external view returns (uint256);
  function setFactor(uint256 factor) external returns (bool);
  function setSeigManager(address _seigManager) external  ;
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function addMinter(address account) external;
  function renounceMinter() external;
  function transferOwnership(address newOwner) external;
  function snapshot() external returns (uint256 id);
  function totalSupplyAt(uint256 snapshotId) external view returns (uint256 amount);
  function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256 amount);

  function getTotalAndFactor() external view returns (IRefactor.Balance memory, IRefactor.Factor memory);
  function getBalanceAndFactor(address account) external view returns (IRefactor.Balance memory, IRefactor.Factor memory);
  function getTotalAndFactorAt(uint256 snapshotId) external view returns (IRefactor.Balance memory, IRefactor.Factor memory);
  function getBalanceAndFactorAt(address account, uint256 snapshotId) external view returns (IRefactor.Balance memory, IRefactor.Factor memory);
}
