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

  modifier onlyL1StakedTonInL2() {
    require(msg.sender == l1StakedTonInL2, "not l1StakedTonInL2");
    _;
  }

  modifier onlyL1StakedTonInL2OrOwner() {
    require(msg.sender == l1StakedTonInL2 || isAdmin(msg.sender)
      , "not l1StakedTonInL2 or admin");
    _;
  }

  modifier checkCoinage(address layer2) {
    require(address(_coinages[layer2]) != address(0), "SeigManager: coinage has not been deployed yet");
    _;
  }
  event UnstakeLog(uint coinageBurnAmount, uint totBurnAmount);

  event CoinageCreated(address indexed layer2, address coinage);
  event OnSnapshot(uint256 snapshotId);

  //////////////////////////////
  // Constuctor
  //////////////////////////////

  function initialize (
    address factory_
  ) external {
    factory = factory_;
    address c = CoinageFactoryI(factory).deploy();
    require(c != address(0), "zero tot");
    _tot = L2RefactorCoinageSnapshotI(c);
  }

  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  function transferCoinageOwnership(address newSeigManager, address[] calldata coinages_) external onlyOwner {
    for (uint256 i = 0; i < coinages_.length; i++) {
      L2RefactorCoinageSnapshotI c = L2RefactorCoinageSnapshotI(coinages_[i]);
      c.addMinter(newSeigManager);
      c.renounceMinter();
      c.transferOwnership(newSeigManager);
    }
  }

  //////////////////////////////
  // onlyL1StakedTonInL2OrOwner
  //////////////////////////////

  function register(address layer2)
    external
    onlyL1StakedTonInL2OrOwner
    returns (bool)
  {
    require(!_l1layer2s[layer2], "already register");
    require(address(_coinages[layer2]) == address(0), "coinage not zero");

    address c = CoinageFactoryI(factory).deploy();

    _l1layer2s[layer2] = true;
    _l1layer2ByIndex[_numLayer2s] = layer2;
    _numLayer2s += 1;

    _coinages[layer2] = L2RefactorCoinageSnapshotI(c);
    emit CoinageCreated(layer2, c);

    return true;
  }


  //////////////////////////////
  // onlyL1StakedTonInL2
  //////////////////////////////

  function update(
    address layer2,
    address account,
    IRefactor.Factor memory totFactor,
    IRefactor.Balance memory totTotalBalance,
    IRefactor.Balance memory totLayerBalance,
    IRefactor.Factor memory layerFactor,
    IRefactor.Balance memory layerTotalBalance,
    IRefactor.Balance memory layerAccountBalance)
    external
    onlyL1StakedTonInL2
    checkCoinage(layer2)
    returns (bool)
  {
    _tot.updateFactor(totFactor);
    _tot.updateBalance(totLayerBalance, totTotalBalance, layer2, true, true);

    _coinages[layer2].updateFactor(layerFactor);
    _coinages[layer2].updateBalance(layerTotalBalance, layerAccountBalance, account, true, true);

    return true;
  }

  function updateSeigniorage(
      address layer2,
      IRefactor.Factor memory totFactor,
      IRefactor.Factor memory layerFactor)
      external
      onlyL1StakedTonInL2
      checkCoinage(layer2)
      returns (bool)
  {
      _tot.updateFactor(totFactor);
      _coinages[layer2].updateFactor(layerFactor);
    return true;
  }



  //////////////////////////////
  // External functions
  //////////////////////////////

  function stakeOf(address layer2, address account) public view returns (uint256) {
    return _coinages[layer2].balanceOf(account);
  }

  function stakeOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256 amount) {
    return _coinages[layer2].balanceOfAt(account, snapshotId);
  }

  function stakeOf(address account) external view returns (uint256 amount) {
    uint256 num = _numLayer2s;
    for (uint256 i = 0 ; i < num; i++){
      amount += _coinages[_l1layer2ByIndex[i]].balanceOf(account);
    }
  }

  function stakeOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
    uint256 num = _numLayer2s;
    for (uint256 i = 0 ; i < num; i++){
      amount += _coinages[_l1layer2ByIndex[i]].balanceOfAt(account, snapshotId);
    }
  }

  function stakeOfTotal() external view returns (uint256 amount) {
    amount = _tot.totalSupply();
  }

  function stakeOfTotalAt(uint256 snapshotId) external view returns (uint256 amount) {
    amount = _tot.totalSupplyAt(snapshotId);
  }

  function onSnapshot() external returns (uint256 snapshotId) {
    snapshotId = lastSnapshotId;
    emit OnSnapshot(snapshotId);
    lastSnapshotId++;
  }

  //////////////////////////////
  // Public functions
  //////////////////////////////


  //////////////////////////////
  // Internal functions
  //////////////////////////////

  //////////////////////////////
  // Storage getters
  //////////////////////////////

  function tot() external view returns (address) { return address(_tot); }
  function coinages(address layer2) external view returns (address) { return address(_coinages[layer2]); }

  //=====
  function progressSnapshotId() public view returns (uint256) {
      return lastSnapshotId;
  }

}
