// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRefactor } from "../stake/interfaces/IRefactor.sol";
import { DSMath } from "../libraries/DSMath.sol";
import { L2RefactorCoinageSnapshotI } from "../stake/interfaces/L2RefactorCoinageSnapshotI.sol";
import { CoinageFactoryI } from "../dao/interfaces/CoinageFactoryI.sol";

import { Layer2I } from "../dao/interfaces/Layer2I.sol";

import "../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../common/AuthControlSeigManager.sol";
import { L2SeigManagerStorage } from "./L2SeigManagerStorage.sol";

interface IILayer2Registry {
  function layer2s(address layer2) external view returns (bool);
  function numLayer2s() external view  returns (uint256);
  function layer2ByIndex(uint256 index) external view returns (address);
}

interface IRefactorCoinageSnapshot {
  function snapshot() external returns (uint256 id);
}

contract L2SeigManager is ProxyStorage, AuthControlSeigManager, L2SeigManagerStorage, DSMath {

  //////////////////////////////
  // Modifiers
  //////////////////////////////

  modifier onlyMessengerAndL1StakedTonToL2() {

      require(
          l2CrossDomainMessenger == msg.sender &&
          IL2CrossDomainMessenger(l2CrossDomainMessenger).xDomainMessageSender() == l1StakedTonToL2,
          "not onlyMessengerAndL1StakedTonToL2");
      _;
  }

  modifier onlyOwner() {
    require(isAdmin(msg.sender)
      , "not admin");
    _;
  }


  event CoinageCreated(address indexed layer2, address coinage);
  event OnSnapshot(uint256 snapshotId);
  event Updated(
    address layer2,
    address account,
    IRefactor.Factor totFactor,
    IRefactor.Balance totTotalBalance,
    IRefactor.Balance totLayerBalance,
    IRefactor.Factor layerFactor,
    IRefactor.Balance layerTotalBalance,
    IRefactor.Balance layerAccountBalance
    );
  event UpdatedSeigniorage(address layer2,  IRefactor.Factor totFactor, IRefactor.Factor layerFactor);


  //////////////////////////////
  // Constuctor
  //////////////////////////////

  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  function initialize (
    address l1StakedTonToL2_
  ) external onlyOwner {
      l1StakedTonToL2 = l1StakedTonToL2_;
  }

  //////////////////////////////
  // onlyMessengerAndL1StakedTonToL2
  //////////////////////////////

  function deposit(address account, uint256 amount)
    external
    onlyMessengerAndL1StakedTonToL2
    returns (bool)
  {
    return true;
  }

  function unstaking(address account, uint256 amount)
    external
    onlyMessengerAndL1StakedTonToL2
    returns (bool)
  {
    return true;
  }

  function updatedSeigniorage(address layer2, uint256 amount)
    external
    onlyMessengerAndL1StakedTonToL2
    returns (bool)
  {
    return true;
  }

  //////////////////////////////
  // External functions
  //////////////////////////////

  function stakeOf(address layer2, address account) public view returns (uint256) {
      return getLswtonToSwton(layer2, lswton[layer2][account]);
  }

  // function stakeOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256 amount) {
  //   return _coinages[layer2].balanceOfAt(account, snapshotId);
  // }

  function stakeOf(address account) external view returns (uint256 amount) {
    uint256 num = _numLayer2s;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = _l1layer2ByIndex[_l1layer2ByIndex[i]];
      amount += getLswtonToSwton(layer2, lswton[layer2][account]);
    }
  }

  // function stakeOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
  //   uint256 num = _numLayer2s;
  //   for (uint256 i = 0 ; i < num; i++){
  //     amount += _coinages[_l1layer2ByIndex[i]].balanceOfAt(account, snapshotId);
  //   }
  // }

  function stakeOfTotal(address layer2) external view returns (uint256 amount) {
    amount = getLswtonToSwton(layer2, totalLswton[layer2]);
  }

  function stakeOfTotal() external view returns (uint256 amount) {
    uint256 num = _numLayer2s;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = _l1layer2ByIndex[_l1layer2ByIndex[i]];
      amount += getLswtonToSwton(layer2, totalLswton[layer2]);
    }
  }

  // function stakeOfTotalAt(uint256 snapshotId) external view returns (uint256 amount) {
  //   amount = _tot.totalSupplyAt(snapshotId);
  // }

  function onSnapshot() external returns (uint256 snapshotId) {
    snapshotId = lastSnapshotId;
    emit OnSnapshot(snapshotId);
    lastSnapshotId++;
  }

  //////////////////////////////
  // Public functions
  //////////////////////////////

  function getSwtonToLswton(address layer2, uint256 amount) public view returns (uint256) {
    if (amount == 0) return 0;
    return (amount * 1e27) / index[layer2];
  }

  function getLswtonToSwton(address layer2, uint256 lswton_) public view returns (uint256) {
    if (lswton_ == 0) return 0;
    return (lswton_ * index[layer2]) / 1e27;
  }


  //////////////////////////////
  // Internal functions
  //////////////////////////////

  //////////////////////////////
  // Storage getters
  //////////////////////////////

  //=====
  function progressSnapshotId() public view returns (uint256) {
      return lastSnapshotId;
  }

}
