// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRefactor } from "../stake/interfaces/IRefactor.sol";
import { DSMath } from "../libraries/DSMath.sol";
import { RefactorCoinageSnapshotI } from "../stake/interfaces/RefactorCoinageSnapshotI.sol";
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

  modifier onlyRegistry() {
    require(msg.sender == _registry, "not onlyRegistry");
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
    address registry_,
    address factory_
  ) external {
    _registry = registry_;
    factory = factory_;
    address c = CoinageFactoryI(factory).deploy();
    require(c != address(0), "zero tot");
    _tot = RefactorCoinageSnapshotI(c);
  }

  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  function transferCoinageOwnership(address newSeigManager, address[] calldata coinages_) external onlyOwner {
    for (uint256 i = 0; i < coinages_.length; i++) {
      RefactorCoinageSnapshotI c = RefactorCoinageSnapshotI(coinages_[i]);
      c.addMinter(newSeigManager);
      c.renounceMinter();
      c.transferOwnership(newSeigManager);
    }
  }

  //////////////////////////////
  // onlyRegistry
  //////////////////////////////

  /**
   * @dev deploy coinage token for the layer2.
   */
  function deployCoinage(address layer2) external onlyRegistry returns (bool) {
    // create new coinage token for the layer2 contract
    if (address(_coinages[layer2]) == address(0)) {
      address c = CoinageFactoryI(factory).deploy();
      _coinages[layer2] = RefactorCoinageSnapshotI(c);
      emit CoinageCreated(layer2, c);
    }

    return true;
  }

  //////////////////////////////
  // onlyL1StakedTonInL2
  //////////////////////////////

  /**
   * @dev Callback for a new deposit
   */
  function updateFactorNBalance(
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
    _coinages[layer2].updateFactor(layerFactor);

    _tot.updateBalance(totLayerBalance, totTotalBalance, layer2, true, true);
    _coinages[layer2].updateBalance(layerTotalBalance, layerAccountBalance, account, true, true);

    return true;
  }

  function updateFactor(
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
  // checkCoinage
  //////////////////////////////


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
    uint256 num = IILayer2Registry(_registry).numLayer2s();
    // amount = 0;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = IILayer2Registry(_registry).layer2ByIndex(i);
      amount += _coinages[layer2].balanceOf(account);
    }
  }

  function stakeOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
    uint256 num = IILayer2Registry(_registry).numLayer2s();
    // amount = 0;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = IILayer2Registry(_registry).layer2ByIndex(i);
      amount += _coinages[layer2].balanceOfAt(account, snapshotId);
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

  function _isOperator(address layer2, address operator) internal view returns (bool) {
    return operator == Layer2I(layer2).operator();
  }

  function _additionalTotBurnAmount(address layer2, address account, uint256 amount)
    internal
    view
    returns (uint256 totAmount)
  {
    uint256 coinageTotalSupply = _coinages[layer2].totalSupply();
    uint256 totBalalnce = _tot.balanceOf(layer2);

    // NOTE: arithamtic operations (mul and div) make some errors, so we gonna adjust them under 1e-9 WTON.
    //       note that coinageTotalSupply and totBalalnce are RAY values.
    if (coinageTotalSupply >= totBalalnce && coinageTotalSupply - totBalalnce < WAD_) {
      return 0;
    }

    return rdiv(
      rmul(
        totBalalnce - coinageTotalSupply,
        amount
      ),
      coinageTotalSupply
    );
  }

  //////////////////////////////
  // Storage getters
  //////////////////////////////

  function registry() external view returns (address) { return address(_registry); }
  function tot() external view returns (address) { return address(_tot); }
  function coinages(address layer2) external view returns (address) { return address(_coinages[layer2]); }

  //=====
  function progressSnapshotId() public view returns (uint256) {
      return lastSnapshotId;
  }

}
