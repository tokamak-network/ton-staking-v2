// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AutoRefactorCoinageI } from "../interfaces/AutoRefactorCoinageI.sol";
import { DSMath } from "../../libraries/DSMath.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlCoinage } from "../../common/AuthControlCoinage.sol";
import { AutoRefactorCoinageStorage } from "./AutoRefactorCoinageStorage.sol";


/**
 * @dev Implementation of coin age token based on ERC20 of openzeppelin/-solidity
 *
 * AutoRefactorCoinage stores `_totalSupply` and `_balances` as RAY BASED value,
 * `_allowances` as RAY FACTORED value.
 *
 * This takes public function (including _approve) parameters as RAY FACTORED value
 * and internal function (including approve) parameters as RAY BASED value, and emits event in RAY FACTORED value.
 *
 * `RAY BASED` = `RAY FACTORED`  / factor
 *
 *  factor increases exponentially for each block mined.
 */
contract AutoRefactorCoinage is ProxyStorage, AuthControlCoinage, AutoRefactorCoinageStorage, DSMath {

  event FactorSet(uint256 previous, uint256 current, uint256 shiftCount);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event ChangedBalance(address indexed account, uint256 balance, uint256 refactoredCount);

  function initialize (
    string memory name_,
    string memory symbol_,
    uint256 factor_,
    address seigManager_
  ) external {

    require(_factor == 0, "already initialized");

    name = name_;
    symbol = symbol_;
    _factor = factor_;
    seigManager = seigManager_;
  }


  /**
   *  onlyOwner
   **/

  function setFactor(uint256 factor_) external onlyOwner returns (bool) {
    uint256 previous = _factor;

    uint256 count = 0;
    uint256 f = factor_;


    for (; f >= REFACTOR_BOUNDARY; f = f / REFACTOR_DIVIDER) {
      count++;
    }

    refactorCount = count;
    _factor = f;

    emit FactorSet(previous, f, count);
    return true;
  }

  function setSeigManager(address _seigManager) external onlyOwner {
    seigManager = _seigManager;
  }

  /**
   *  onlyMinter
   **/

  function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
  }

  function burnFrom(address account, uint256 amount) public onlyMinter {
      _burnFrom(account, amount);
  }

  // -------- external

  function burn(uint256 amount) external {
      _burn(msg.sender, amount);
  }

  function decimals() external view virtual returns (uint8) {
      return 27;
  }

  function totalSupply() external view returns (uint256) {
    return _applyFactor(_totalSupply.balance, _totalSupply.refactoredCount) + _totalSupply.remain;
  }

  // -------- public

  function factor() public view returns (uint256) {
    uint256 result = _factor;
    for (uint256 i = 0; i < refactorCount; i++) {
      result = result * REFACTOR_DIVIDER;
    }
    return result;
  }

  function balanceOf(address account) public view returns (uint256) {
    Balance storage b = balances[account];

    return _applyFactor(b.balance, b.refactoredCount) + b.remain;
  }

  // -------- internal

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "AutoRefactorCoinage: mint to the zero address");
    Balance storage b = balances[account];

    uint256 currentBalance = balanceOf(account);
    uint256 newBalance = currentBalance + amount;

    uint256 rbAmount = _toRAYBased(newBalance);
    b.balance = rbAmount;
    b.refactoredCount = refactorCount;

    addTotalSupply(amount);

    emit ChangedBalance(account, rbAmount, refactorCount);

    emit Transfer(address(0), account, _toRAYFactored(rbAmount));
  }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "AutoRefactorCoinage: burn from the zero address");
    Balance storage b = balances[account];

    uint256 currentBalance = balanceOf(account);
    uint256 newBalance = currentBalance - amount;

    uint256 rbAmount = _toRAYBased(newBalance);

    b.balance = rbAmount;
    b.refactoredCount = refactorCount;

    subTotalSupply(amount);

    emit ChangedBalance(account, rbAmount, refactorCount);

    emit Transfer(account, address(0), _toRAYFactored(rbAmount));
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
  }

  /**
   * @param v the value to be factored
   */
  function _applyFactor(uint256 v, uint256 refactoredCount) internal view returns (uint256) {
    if (v == 0) {
      return 0;
    }

    v = rmul2(v, _factor);

    for (uint256 i = refactoredCount; i < refactorCount; i++) {
      v = v * REFACTOR_DIVIDER;
    }

    return v;
  }

  /**
   * @dev Calculate RAY BASED from RAY FACTORED
   */
  function _toRAYBased(uint256 rf) internal view returns (uint256 rb) {
    return rdiv2(rf, _factor);
  }

  /**
   * @dev Calculate RAY FACTORED from RAY BASED
   */
  function _toRAYFactored(uint256 rb) internal view returns (uint256 rf) {
    return rmul2(rb, _factor);
  }

  function addTotalSupply(uint256 amount) internal {
    uint256 currentSupply = _applyFactor(_totalSupply.balance, _totalSupply.refactoredCount);
    uint256 newSupply = currentSupply + amount;

    uint256 rbAmount = _toRAYBased(newSupply);
    _totalSupply.balance = rbAmount;
    _totalSupply.refactoredCount = refactorCount;

    emit ChangedBalance(address(0), rbAmount, refactorCount);
  }

  function subTotalSupply(uint256 amount) internal {
    uint256 currentSupply = _applyFactor(_totalSupply.balance, _totalSupply.refactoredCount);
    uint256 newSupply = currentSupply - amount;

    uint256 rbAmount = _toRAYBased(newSupply);
    _totalSupply.balance = rbAmount;
    _totalSupply.refactoredCount = refactorCount;

    emit ChangedBalance(address(0), rbAmount, refactorCount);
  }

  // unsupported functions

  // function transfer(address recipient, uint256 amount) public returns (bool) {
  //   revert();
  // }

  // function allowance(address owner, address spender) public view returns (uint256) {
  //   return 0;
  // }

  // function approve(address spender, uint256 amount) public returns (bool) {
  //   revert();
  // }

  // function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
  //   revert();
  // }
}
