// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRefactor } from "../interfaces/IRefactor.sol";
import { DSMath } from "../../libraries/DSMath.sol";
import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";

// import { Layer2I } from "../../dao/interfaces/Layer2I.sol";
import { SeigManagerI } from "../interfaces/SeigManagerI.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../../common/AuthControlSeigManager.sol";
import { SeigManagerStorage } from "./SeigManagerStorage.sol";

// interface MinterRoleRenounceTarget {
//   function renounceMinter() external;
// }

// interface PauserRoleRenounceTarget {
//   function renouncePauser() external;
// }

// interface OwnableTarget {
//   function renounceOwnership() external;
//   function transferOwnership(address newOwner) external;
// }

// interface IILayer2Registry {
//   function layer2s(address layer2) external view returns (bool);
//   function numLayer2s() external view  returns (uint256);
//   function layer2ByIndex(uint256 index) external view returns (address);
// }

// interface IPowerTON {
//   function updateSeigniorage(uint256 amount) external;
// }

// interface ITON {
//   function totalSupply() external view returns (uint256);
//   function balanceOf(address account) external view returns (uint256);
// }

interface IRefactorCoinageSnapshot {
  function snapshot() external returns (uint256 id);
}

// interface ICandidate {
//   function updateSeigniorage() external returns (bool);
// }

contract L2SeigManager is ProxyStorage, AuthControlSeigManager, SeigManagerStorage, SeigManagerI, DSMath {

  //////////////////////////////
  // Modifiers
  //////////////////////////////

  modifier onlyRegistry() {
    require(msg.sender == _registry, "not onlyRegistry");
    _;
  }

  modifier checkCoinage(address layer2) {
    require(address(_coinages[layer2]) != address(0), "SeigManager: coinage has not been deployed yet");
    _;
  }

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
  // onlyDepositManager
  //////////////////////////////

  /**
   * @dev Callback for a new deposit
   */
  function onDeposit(address layer2, address account, uint256 amount)
    external
    onlyDepositManager
    checkCoinage(layer2)
    returns (bool)
  {
    if (_isOperator(layer2, account)) {
      uint256 newAmount = _coinages[layer2].balanceOf(account) + amount;
      require(newAmount >= minimumAmount, "minimum amount is required");
    }
    _tot.mint(layer2, amount);
    _coinages[layer2].mint(account, amount);
    return true;
  }

  function onWithdraw(address layer2, address account, uint256 amount)
    external
    onlyDepositManager
    checkCoinage(layer2)
    returns (bool)
  {
    require(_coinages[layer2].balanceOf(account) >= amount, "SeigManager: insufficiant balance to unstake");

    if (_isOperator(layer2, account)) {
      uint256 newAmount = _coinages[layer2].balanceOf(account) - amount;
      require(newAmount >= minimumAmount, "minimum amount is required");
    }

    // burn {v + ⍺} {tot} tokens to the layer2 contract,
    uint256 totAmount = _additionalTotBurnAmount(layer2, account, amount);
    _tot.burnFrom(layer2, amount+totAmount);

    // burn {v} {coinages[layer2]} tokens to the account
    _coinages[layer2].burnFrom(account, amount);

    emit UnstakeLog(amount, totAmount);

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
