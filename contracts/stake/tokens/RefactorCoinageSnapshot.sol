// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AutoRefactorCoinageI } from "../interfaces/AutoRefactorCoinageI.sol";
import { DSMath } from "../../libraries/DSMath.sol";
import "../../libraries/SArrays.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlCoinage } from "../../common/AuthControlCoinage.sol";
import { RefactorCoinageSnapshotStorage } from "./RefactorCoinageSnapshotStorage.sol";


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
contract RefactorCoinageSnapshot is ProxyStorage, AuthControlCoinage, RefactorCoinageSnapshotStorage, DSMath {
    using SArrays for uint256[];

    event FactorSet(uint256 previous, uint256 current, uint256 shiftCount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ChangedBalance(address indexed account, Balance oldBalance, Balance newBalance, Balance oldTotalBalance, Balance newTotalBalance);
    event ChangedFactor(Factor previous, Factor next);
    event Snapshotted(uint256 id);

    function initialize (
      string memory name_,
      string memory symbol_,
      uint256 factor_
    ) external {

      require(factorSnapshots[0].factor == 0, "already initialized");

      name = name_;
      symbol = symbol_;
      factorSnapshots[0] = Factor(factor_, 0);

    }


    /**
     *  onlyOwner
     **/

    function setFactor(uint256 factor_) external onlyOwner returns (bool) {
      Factor memory previous = _valueAtFactorLast();
      // uint256 previous = _factor;

      uint256 count = 0;
      uint256 f = factor_;
      for (; f >= REFACTOR_BOUNDARY; f = f / REFACTOR_DIVIDER) {
        count = count++;
      }

      Factor memory nextFactor = Factor(f, count);
      _updateFactor(nextFactor);

      emit ChangedFactor(previous, nextFactor);
      return true;
    }

    /**
     *  onlyMinter
     **/

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
          _mint(account, amount);
          return true;
    }

    function burnFrom(address account, uint256 amount) public onlyMinter {
        _burn(account, amount);
    }

    // -------- external

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function snapshot() external onlyMinter returns (uint256 id) {
      id = lastSnapshotId;
      emit Snapshotted(id);
      lastSnapshotId++;
    }

    function decimals() external view virtual returns (uint8) {
        return 27;
    }

    // -------- public

    function factor() public view returns (uint256) {
      Factor memory _factor = _valueAtFactorLast();
      uint256 result = _factor.factor;
      for (uint256 i = 0; i < _factor.refactorCount; i++) {
        result = result * REFACTOR_DIVIDER;
      }
      return result;
    }

    // -------- internal

    function _mint(address account, uint256 amount) internal {
      require(account != address(0), "AutoRefactorCoinage: mint to the zero address");

      Balance memory _totalBalance = _valueAtTotalSupplyLast();
      Balance memory _accountBalance = _valueAtAccountBalanceLast(account);

      uint256 currentAccountBalance = applyFactor(_accountBalance);
      uint256 currentTotalBalance = applyFactor(_totalBalance);

      uint256 rbAmountAccount = _toRAYBased(currentAccountBalance + amount);
      uint256 rbAmountTotal = _toRAYBased(currentTotalBalance + amount);

      Balance memory newAccountBalance = Balance(rbAmountAccount, _accountBalance.refactoredCount);
      Balance memory newTotalBalance = Balance(rbAmountTotal, _totalBalance.refactoredCount);

      _update(newAccountBalance, newTotalBalance, account, true, true);

      emit ChangedBalance(account, _accountBalance, newAccountBalance, _totalBalance, newTotalBalance);

      emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
      require(account != address(0), "AutoRefactorCoinage: burn from the zero address");

      Balance memory _totalBalance = _valueAtTotalSupplyLast();
      Balance memory _accountBalance = _valueAtAccountBalanceLast(account);

      uint256 currentAccountBalance = applyFactor(_accountBalance);
      uint256 currentTotalBalance = applyFactor(_totalBalance);

      require(currentAccountBalance >= amount
        && currentTotalBalance >= amount, "insufficient balance");

      // uint256 rbAmountAccount = _toRAYBased(currentAccountBalance - amount);
      // uint256 rbAmountTotal = _toRAYBased(currentTotalBalance - amount);

      Balance memory newAccountBalance = Balance( _toRAYBased(currentAccountBalance - amount), _accountBalance.refactoredCount);
      Balance memory newTotalBalance = Balance(_toRAYBased(currentTotalBalance - amount), _totalBalance.refactoredCount);

      _update(newAccountBalance, newTotalBalance, account, true, true);

      emit ChangedBalance(account, _accountBalance, newAccountBalance, _totalBalance, newTotalBalance);

      emit Transfer(account, address(0), amount);
    }

    /**
     * @param v the value to be factored
     */
    function _applyFactor(uint256 v, uint256 refactoredCount) internal view returns (uint256) {

      if (v == 0) {
        return 0;
      }

      Factor memory _factor = _valueAtFactorLast();

      v = rmul2(v, _factor.factor);

      for (uint256 i = refactoredCount; i < _factor.refactorCount; i++) {
        v = v * REFACTOR_DIVIDER;
      }

      return v;
    }

    function _applyFactorAt(Balance memory _balance, Factor memory _factor) internal view returns (uint256) {

      if (_balance.balance == 0) {
        return 0;
      }

      _balance.balance = rmul2(_balance.balance, _factor.factor);

      for (uint256 i = _balance.refactoredCount; i < _factor.refactorCount; i++) {
        _balance.balance = _balance.balance * REFACTOR_DIVIDER;
      }

      return _balance.balance;
    }

    /**
     * @dev Calculate RAY BASED from RAY FACTORED
     */
    function _toRAYBased(uint256 rf) internal view returns (uint256 rb) {
      return rdiv2(rf, (_valueAtFactorLast()).factor);
    }

    /**
     * @dev Calculate RAY FACTORED from RAY BASED
     */
    function _toRAYFactored(uint256 rb) internal view returns (uint256 rf) {
      return rmul2(rb, (_valueAtFactorLast()).factor);
    }

    function _lastSnapshotId(uint256[] storage ids) internal view returns (uint256) {
        return (ids.length == 0? 0: ids[ids.length - 1]);
    }

    function _updateFactor(Factor memory _factor) internal {

      uint256 currentId = progressSnapshotId();
      uint256 factorIndex = _lastSnapshotId(factorSnapshotIds);

      if (factorIndex < currentId) factorSnapshotIds.push(currentId);
      factorSnapshots[currentId] = _factor;
    }

    function _update(
      Balance memory _accountBalance,
      Balance memory _totalBalance,
      address account,
      bool accountBool,
      bool totalBool
    ) internal  {

      uint256 currentId = progressSnapshotId();
      uint256 balanceIndex = _lastSnapshotId(accountBalanceIds[account]);
      uint256 totalIndex = _lastSnapshotId(totalSupplySnapshotIds);

      if (accountBool) {
        require(account != address(0), "zero account");
        if (balanceIndex < currentId) accountBalanceIds[account].push(currentId);
        accountBalanceSnapshots[account][currentId] = _accountBalance;
      }

      if (totalBool) {
        if (totalIndex < currentId) totalSupplySnapshotIds.push(currentId);
        totalSupplySnapshots[currentId] = _totalBalance;
      }

    }

    function progressSnapshotId() public view returns (uint256) {
        return lastSnapshotId;
    }

    function applyFactor(Balance memory _balance) public view returns (uint256 amount) {

      return _applyFactor(_balance.balance, _balance.refactoredCount);
    }

    function totalSupply() external view returns (uint256 amount)
    {
      amount = applyFactor(_valueAtTotalSupplyLast());
    }

    function balanceOf(address account) external view returns (uint256 amount)
    {
      amount = applyFactor(_valueAtAccountBalanceLast(account));
    }

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256 amount)
    {
      (, Balance memory _balance) = _valueAtTotalSupply(snapshotId);
      (, Factor memory _factor) = _valueAtFactor(snapshotId);

      // if (snapshotted1) {
          amount = _applyFactorAt(_balance, _factor);
      // }
    }

    function balanceOfAt(address account, uint256 snapshotId) external view
      returns (uint256 amount)
    {
      (, Balance memory _balance) = _valueAtAccount(snapshotId, account);
      (, Factor memory _factor) = _valueAtFactor(snapshotId);

      // if (snapshotted1 ) {
          amount = _applyFactorAt(_balance, _factor);
      // }
    }

    function _valueAtTotalSupplyLast() internal view
      returns (Balance memory)
    {
      uint256 index = 0;
      if(totalSupplySnapshotIds.length != 0) index = totalSupplySnapshotIds.length;
      return totalSupplySnapshots[index];
    }

    function _valueAtFactorLast() internal view
      returns (Factor memory)
    {
      uint256 index = 0;
      if(factorSnapshotIds.length != 0) index = factorSnapshotIds.length;
      return factorSnapshots[index];
    }

    function _valueAtAccountBalanceLast(address account) internal view
      returns (Balance memory)
    {
      uint256 index = 0;
      if(accountBalanceIds[account].length != 0) index = accountBalanceIds[account].length ;
      return accountBalanceSnapshots[account][index];
    }

    function _valueAtTotalSupply(uint256 snapshotId) internal view
      returns (bool snapshotted, Balance memory balance)
    {
      if (snapshotId == 0) {
        if(progressSnapshotId() > 0 ) {
           snapshotted = true;
           balance = totalSupplySnapshots[0];
        }
      } else if (snapshotId <= progressSnapshotId()) {

        uint256 index = totalSupplySnapshotIds.findValue(snapshotId);

        if(totalSupplySnapshotIds.length > 0) {
          snapshotted = true;
          balance = totalSupplySnapshots[index];
        } else {
          // snapshotted = false;
          balance = totalSupplySnapshots[0];
        }

      }

    }

    function _valueAtFactor(uint256 snapshotId) internal view
      returns (bool snapshotted, Factor memory factor_)
    {
      if (snapshotId == 0) {
        if(progressSnapshotId() > 0 ) {
           snapshotted = true;
           factor_ = factorSnapshots[0];
        }
      } else if (snapshotId <= progressSnapshotId()) {
        uint256 index = factorSnapshotIds.findValue(snapshotId);

        if(factorSnapshotIds.length > 0) {
          snapshotted = true;
          factor_ = factorSnapshots[index];
        } else {
          snapshotted = false;
          factor_ = factorSnapshots[0];
        }
      }

    }

    function _valueAtAccount(uint256 snapshotId, address account) internal view
        returns (bool snapshotted, Balance memory balance)
    {
      if (snapshotId == 0) {

        if(progressSnapshotId() > 0 ) {
           snapshotted = true;
           balance = accountBalanceSnapshots[account][0];
        }

      } else if (snapshotId <= progressSnapshotId()) {

          uint256 index = accountBalanceIds[account].findValue(snapshotId);
          if(accountBalanceIds[account].length > 0) {
            snapshotted = true;
            balance = accountBalanceSnapshots[account][index];
          } else {
            snapshotted = false;
            balance = accountBalanceSnapshots[account][0];
          }

        }
    }

}
