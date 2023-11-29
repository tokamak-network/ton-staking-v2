// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { CoinageFactoryI } from "../stake/interfaces/CoinageFactoryI.sol";
import { L2RefactorCoinageSnapshotProxy } from "./L2RefactorCoinageSnapshotProxy.sol";

interface IIAutoRefactorCoinage {
  function initialize (
      string memory name_,
      string memory symbol_,
      uint256 factor_,
      address seigManager_
    ) external;
}

contract CoinageFactory is CoinageFactoryI, Ownable {
  uint256 constant internal _DEFAULT_FACTOR = 10 ** 27;

  address public autoCoinageLogic;

  function setAutoCoinageLogic(address newLogic) external onlyOwner {
    autoCoinageLogic = newLogic;
  }

  function deploy() external override returns (address) {
    L2RefactorCoinageSnapshotProxy c = new L2RefactorCoinageSnapshotProxy();
    c.upgradeTo(autoCoinageLogic);
    c.addMinter(msg.sender);

    IIAutoRefactorCoinage(address(c)).initialize(
      "L1StakedWTON",
      "sWtonL1",
      _DEFAULT_FACTOR,
      msg.sender
    );

    // c.renounceMinter();
    c.transferOwnership(msg.sender);

    return address(c);
  }
}
