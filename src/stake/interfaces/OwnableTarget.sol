// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface OwnableTarget {
  function renounceOwnership() external;
  function transferOwnership(address newOwner) external;
}