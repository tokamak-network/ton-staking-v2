// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface RefactorCoinageSnapshotI {
  function factor() external view returns (uint256);
  function setFactor(uint256 factor) external returns (bool);
  function setSeigManager(address _seigManager) external  ;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function mint(address account, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function addMinter(address account) external;
  function renounceMinter() external;
  function transferOwnership(address newOwner) external;
  function snapshot() external returns (uint256 id);
  function totalSupplyAt(uint256 snapshotId) external view returns (uint256 amount);
  function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256 amount);
}
