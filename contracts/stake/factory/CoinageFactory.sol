// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AutoRefactorCoinageI } from "../interfaces/AutoRefactorCoinageI.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// import { AutoRefactorCoinageProxy } from "../tokens/AutoRefactorCoinageProxy.sol";
import { CoinageFactoryI } from "../interfaces/CoinageFactoryI.sol";
import { RefactorCoinageSnapshotProxy } from "../tokens/RefactorCoinageSnapshotProxy.sol";


contract CoinageFactory is CoinageFactoryI, Ownable {
  // uint256 constant public RAY = 10 ** 27; // 1 RAY
  // uint256 constant internal _DEFAULT_FACTOR = RAY;
  uint256 constant internal _DEFAULT_FACTOR = 10 ** 27;

  address public autoCoinageLogic;

  function setAutoCoinageLogic(address newLogic) external onlyOwner {
    autoCoinageLogic = newLogic;
  }

  function deploy() external override returns (address) {
    RefactorCoinageSnapshotProxy c = new RefactorCoinageSnapshotProxy();
    c.upgradeTo(autoCoinageLogic);
    c.addMinter(msg.sender);

    AutoRefactorCoinageI(address(c)).initialize(
      "StakedWTON",
      "sWTON",
      _DEFAULT_FACTOR,
      msg.sender
    );

    // c.renounceMinter();
    c.transferOwnership(msg.sender);

    return address(c);
  }
}