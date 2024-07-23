// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DSMath } from "../../libraries/DSMath.sol";
// import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";
// import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { Layer2I } from "../../dao/interfaces/Layer2I.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../../common/AuthControlSeigManager.sol";
import { SeigManagerStorage } from "./SeigManagerStorage.sol";
import { SeigManagerV1_1Storage } from "./SeigManagerV1_1Storage.sol";
import { SeigManagerV1_3Storage } from "./SeigManagerV1_3Storage.sol";
import { SeigManagerV1_VoteStorage } from "./SeigManagerV1_VoteStorage.sol";

error NotVoteTokenError();
error ZeroAmountError();
error InsufficientStaked();
error InsufficientVotes();
interface IILayer2Registry {
  function layer2s(address layer2) external view returns (bool);
  function numLayer2s() external view  returns (uint256);
  function layer2ByIndex(uint256 index) external view returns (address);
}

contract SeigManagerV1_Vote is ProxyStorage, AuthControlSeigManager, SeigManagerStorage, SeigManagerV1_1Storage, DSMath, SeigManagerV1_3Storage, SeigManagerV1_VoteStorage {


  //////////////////////////////
  // Modifiers
  //////////////////////////////

  modifier onlyDepositManager() {
    require(msg.sender == _depositManager, "not onlyDepositManager");
    _;
  }

  //////////////////////////////
  // Events
  //////////////////////////////
  event UnstakeLog(uint coinageBurnAmount, uint totBurnAmount);
  event IncreasedVoteToken(address account, uint256 amount);
  event DecreasedVoteToken(address account, uint256 amount);

  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  //////////////////////////////
  // onlyVoteToken
  //////////////////////////////

  function _onlyVoteToken() internal view {
    if (msg.sender != voteToken) revert NotVoteTokenError();
  }

  modifier checkCoinage(address layer2) {
    require(address(_coinages[layer2]) != address(0), "SeigManager: coinage has not been deployed yet");
    _;
  }

  //////////////////////////////
  //  external
  //////////////////////////////

  function increaseVoteToken(address account, uint256 amount) external {
    _onlyVoteToken();
    if (amount == 0) revert ZeroAmountError();
    if (amount > _availableRequestWithdraw(account)) revert InsufficientStaked();

    votes[account] += amount;
    totalVotes += amount;

    emit IncreasedVoteToken(account, amount);
  }

  function decreaseVoteToken(address account, uint256 amount) external {
    _onlyVoteToken();
    if (amount == 0) revert ZeroAmountError();

    // uint256 votes_ = votes[account];
    if (amount > votes[account]) revert InsufficientVotes();

    votes[account] -= amount;
    totalVotes -= amount;

    emit DecreasedVoteToken(account, amount);
  }

  function onWithdraw(address layer2, address account, uint256 amount)
    external
    onlyDepositManager
    checkCoinage(layer2)
    returns (bool)
  {
    require(_coinages[layer2].balanceOf(account) >= amount, "SeigManager: insufficiant balance to unstake");
    if (_availableRequestWithdraw(account) >= amount) revert InsufficientStaked();

    if (_isOperator(layer2, account)) {
      uint256 newAmount = _coinages[layer2].balanceOf(account) - amount;
      require(newAmount >= minimumAmount, "minimum amount is required");
    }

    // burn {v + ⍺} {tot} tokens to the layer2 contract,
    uint256 totAmount = _additionalTotBurnAmount(layer2, account, amount);
    _tot.burnFrom(layer2, amount+totAmount);

    // burn {v} {coinages[layer2]} tokens to the account
    _coinages[layer2].burnFrom(account, amount);

    // if (_powerton != address(0)) IPowerTON(_powerton).onWithdraw(layer2, account, amount);
    emit UnstakeLog(amount, totAmount);

    return true;
  }

  //////////////////////////////
  // View functions
  //////////////////////////////

  function availableRequestWithdraw(address account) external view returns (uint256 amount) {
    return _availableRequestWithdraw(account);
  }

  //////////////////////////////
  // Internal functions
  //////////////////////////////

  function _availableRequestWithdraw(address account) internal view returns (uint256 amount) {
    amount = _stakeOf(account);
    if (amount != 0) {
      uint256 votes_ = votes[account];
      if (amount >= votes_) amount -= votes_;
      else if (amount > votes_) amount = 0;
    }
  }

  function _stakeOf(address account) internal view returns (uint256 amount) {
    uint256 num = IILayer2Registry(_registry).numLayer2s();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = IILayer2Registry(_registry).layer2ByIndex(i);
      amount += _coinages[layer2].balanceOf(account);
    }
  }

  function _isOperator(address layer2, address operator) internal view returns (bool) {
    return operator == Layer2I(layer2).operator();
  }

  // return ⍺, where ⍺ = (tot.balanceOf(layer2) - coinages[layer2].totalSupply()) * (amount / coinages[layer2].totalSupply())
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

}
