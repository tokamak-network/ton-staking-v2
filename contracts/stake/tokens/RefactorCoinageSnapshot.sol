// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRefactor } from "../interfaces/IRefactor.sol";
import { AutoRefactorCoinageI } from "../interfaces/AutoRefactorCoinageI.sol";
import { DSMath } from "../../libraries/DSMath.sol";
import "../../libraries/SArrays.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlCoinage } from "../../common/AuthControlCoinage.sol";
import { RefactorCoinageSnapshotStorage } from "./RefactorCoinageSnapshotStorage.sol";


interface IIISeigManager {
  function progressSnapshotId() external view returns (uint256);
}
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
    event ChangedBalance(address indexed account, IRefactor.Balance oldBalance, IRefactor.Balance newBalance, IRefactor.Balance oldTotalBalance, IRefactor.Balance newTotalBalance);
    event ChangedFactor(IRefactor.Factor previous, IRefactor.Factor next);
    // event Snapshotted(uint256 id);

    function initialize (
      string memory name_,
      string memory symbol_,
      uint256 factor_,
      address seigManager_
    ) external {

      require(factorSnapshots[0].factor == 0, "already initialized");

      name = name_;
      symbol = symbol_;
      factorSnapshots[0] = IRefactor.Factor(factor_, 0);
      seigManager = seigManager_;
    }


    /**
     *  onlyOwner
     **/

    function setFactor(uint256 factor_) external onlyOwner returns (bool) {
      IRefactor.Factor memory previous = _valueAtFactorLast();
      // uint256 previous = _factor;
      uint256 count = 0;
      uint256 f = factor_;

      for (; f >= REFACTOR_BOUNDARY; f = f / REFACTOR_DIVIDER) {
        count++;
      }

      IRefactor.Factor memory nextFactor = IRefactor.Factor(f, count);
      _updateFactor(nextFactor);

      emit ChangedFactor(previous, nextFactor);
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
        _burn(account, amount);
    }

    // -------- external

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function decimals() external pure returns (uint8) {
        return 27;
    }

    // -------- public

    function factor() public view returns (uint256) {
      IRefactor.Factor memory _factor = _valueAtFactorLast();
      return _factor.factor * REFACTOR_DIVIDER ** _factor.refactorCount;
    }

    // -------- internal

    function _mint(address account, uint256 amount) internal {
      require(account != address(0), "AutoRefactorCoinage: mint to the zero address");

      IRefactor.Factor memory f = _valueAtFactorLast();
      IRefactor.Balance memory _totalBalance = _valueAtTotalSupplyLast();
      IRefactor.Balance memory _accountBalance = _valueAtAccountBalanceLast(account);

      uint256 currentAccountBalance = applyFactor(_accountBalance);
      uint256 currentTotalBalance = applyFactor(_totalBalance);

      uint256 rbAmountAccount = _toRAYBased(currentAccountBalance + amount);
      uint256 rbAmountTotal = _toRAYBased(currentTotalBalance + amount);

      IRefactor.Balance memory newAccountBalance = IRefactor.Balance(rbAmountAccount, f.refactorCount);
      IRefactor.Balance memory newTotalBalance = IRefactor.Balance(rbAmountTotal, f.refactorCount);

      _update(newAccountBalance, newTotalBalance, account, true, true);

      emit ChangedBalance(account, _accountBalance, newAccountBalance, _totalBalance, newTotalBalance);

      emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
      require(account != address(0), "AutoRefactorCoinage: burn from the zero address");
      IRefactor.Factor memory f = _valueAtFactorLast();
      IRefactor.Balance memory _totalBalance = _valueAtTotalSupplyLast();
      IRefactor.Balance memory _accountBalance = _valueAtAccountBalanceLast(account);

      uint256 currentTotalBalance = applyFactor(_totalBalance);
      uint256 currentAccountBalance = applyFactor(_accountBalance);

      require(currentAccountBalance >= amount
        && currentTotalBalance >= amount, "insufficient balance");

      uint256 rbAmountTotal = _toRAYBased(currentTotalBalance - amount);
      uint256 rbAmountAccount = _toRAYBased(currentAccountBalance - amount);

      IRefactor.Balance memory newTotalBalance = IRefactor.Balance(rbAmountTotal, f.refactorCount);
      IRefactor.Balance memory newAccountBalance = IRefactor.Balance(rbAmountAccount, f.refactorCount);

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

      IRefactor.Factor memory _factor = _valueAtFactorLast();

      v = rmul2(v, _factor.factor);

      if (_factor.refactorCount > refactoredCount) {
        v = v * REFACTOR_DIVIDER ** (_factor.refactorCount - refactoredCount);
      }
      return v;
    }

    function _applyFactorAt(IRefactor.Balance memory _balance, IRefactor.Factor memory _factor) internal pure returns (uint256) {
      if (_balance.balance == 0) {
        return 0;
      }
      _balance.balance = rmul2(_balance.balance, _factor.factor);
      if(_factor.refactorCount > _balance.refactoredCount) {
        _balance.balance = _balance.balance * REFACTOR_DIVIDER ** (_factor.refactorCount - _balance.refactoredCount);
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

    function _updateFactor(IRefactor.Factor memory _factor) internal {

      uint256 currentId = progressSnapshotId();
      uint256 factorIndex = _lastSnapshotId(factorSnapshotIds);

      if (factorIndex < currentId) factorSnapshotIds.push(currentId);
      factorSnapshots[currentId] = _factor;

    }

    function _update(
      IRefactor.Balance memory _accountBalance,
      IRefactor.Balance memory _totalBalance,
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
        return IIISeigManager(seigManager).progressSnapshotId();
    }

    function applyFactor(IRefactor.Balance memory _balance) public view returns (uint256 amount) {

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
      (IRefactor.Balance memory _balance,  IRefactor.Factor memory _factor) = getTotalAndFactorAt(snapshotId);
      amount = _applyFactorAt(_balance, _factor);
    }

    function balanceOfAt(address account, uint256 snapshotId) external view
      returns (uint256 amount)
    {
      (IRefactor.Balance memory _balance,  IRefactor.Factor memory _factor) = getBalanceAndFactorAt(account, snapshotId);
      amount = _applyFactorAt(_balance, _factor);
    }

    function getTotalAndFactor() public view returns (IRefactor.Balance memory, IRefactor.Factor memory)
    {
      return (_valueAtTotalSupplyLast(), _valueAtFactorLast());
    }

    function getBalanceAndFactor(address account) public view returns (IRefactor.Balance memory, IRefactor.Factor memory)
    {
      return (_valueAtAccountBalanceLast(account), _valueAtFactorLast());
    }

    function getTotalAndFactorAt(uint256 snapshotId) public view returns (IRefactor.Balance memory, IRefactor.Factor memory)
    {
      return (_valueAtTotalSupply(snapshotId), _valueAtFactor(snapshotId));
    }

    function getBalanceAndFactorAt(address account, uint256 snapshotId) public view returns (IRefactor.Balance memory, IRefactor.Factor memory)
    {
      return (_valueAtAccount(snapshotId, account), _valueAtFactor(snapshotId));
    }

    function _valueAtTotalSupplyLast() internal view
      returns (IRefactor.Balance memory)
    {
      uint256 index = 0;
      uint256 length = totalSupplySnapshotIds.length;
      if(length != 0) index = totalSupplySnapshotIds[length - 1];
      return totalSupplySnapshots[index];
    }

    function _valueAtFactorLast() internal view
      returns (IRefactor.Factor memory)
    {
      uint256 index = 0;
      uint256 length = factorSnapshotIds.length;
      if(length != 0) index = factorSnapshotIds[length - 1];
      return factorSnapshots[index];
    }

    function _valueAtAccountBalanceLast(address account) internal view
      returns (IRefactor.Balance memory)
    {
      uint256 index = 0;
      uint256 length = accountBalanceIds[account].length;
      if(length != 0) index = accountBalanceIds[account][length - 1];
      return accountBalanceSnapshots[account][index];
    }

    function _valueAtTotalSupply(uint256 snapshotId) internal view
      returns (IRefactor.Balance memory balance)
    {
      require(snapshotId <= progressSnapshotId(), "snapshotId > progressSnapshotId");
      uint256 index = totalSupplySnapshotIds.findValue(snapshotId);
      return totalSupplySnapshots[index];
    }

    function _valueAtFactor(uint256 snapshotId) internal view
      returns (IRefactor.Factor memory factor_)
    {
      require(snapshotId <= progressSnapshotId(), "snapshotId > progressSnapshotId");
      uint256 index = factorSnapshotIds.findValue(snapshotId);
      return factorSnapshots[index];
    }

    function _valueAtAccount(uint256 snapshotId, address account) internal view
        returns (IRefactor.Balance memory balance)
    {
      require(snapshotId <= progressSnapshotId(), "snapshotId > progressSnapshotId");
      uint256 index = accountBalanceIds[account].findValue(snapshotId);
      return accountBalanceSnapshots[account][index];
    }
}
