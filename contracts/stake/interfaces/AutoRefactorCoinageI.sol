// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface AutoRefactorCoinageI {
  function factor() external view returns (uint256);
  function setFactor(uint256 factor) external returns (bool);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function mint(address account, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function addMinter(address account) external;
  function renounceMinter() external;
  function transferOwnership(address newOwner) external;
}
