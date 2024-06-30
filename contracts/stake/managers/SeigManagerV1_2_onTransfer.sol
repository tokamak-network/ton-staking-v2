// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import { IRefactor } from "../interfaces/IRefactor.sol";
import { DSMath } from "../../libraries/DSMath.sol";
import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";
// import { CoinageFactoryI } from "../../dao/interfaces/CoinageFactoryI.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { Layer2I } from "../../dao/interfaces/Layer2I.sol";
import { SeigManagerV1I } from "../interfaces/SeigManagerV1I.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../../common/AuthControlSeigManager.sol";
import { SeigManagerStorage } from "./SeigManagerStorage.sol";
import { SeigManagerV1_1Storage } from "./SeigManagerV1_1Storage.sol";
import { SeigManagerV1_2_onTransfer_Storage } from "./SeigManagerV1_2_onTransfer_Storage.sol";

import "hardhat/console.sol";

interface IPowerTON {
  function updateSeigniorage(uint256 amount) external;
  function onDeposit(address layer2, address account, uint256 amount) external;
  function onWithdraw(address layer2, address account, uint256 amount) external;
}

interface ITON {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}

error BlackList_Error();
error Add_BlackList_Error();
error Delete_BlackList_Error();

/**
 * @dev SeigManager gives seigniorage to operator and WTON holders.
 * For each commit by operator, operator (or user) will get seigniorage
 * in propotion to the staked (or delegated) amount of WTON.
 *
 * [Tokens]
 * - {tot} tracks total staked or delegated WTON of each Layer2 contract (and depositor?).
 * - {coinages[layer2]} tracks staked or delegated WTON of user or operator to a Layer2 contract.
 *
 * For each commit by operator,
 *  1. increases all layer2's balance of {tot} by (the staked amount of WTON) /
 *     (total supply of TON and WTON) * (num blocks * seigniorage per block).
 *  2. increases all depositors' blanace of {coinages[layer2]} in proportion to the staked amount of WTON,
 *     up to the increased amount in step (1).
 *  3. set the layer2's balance of {committed} as the layer2's {tot} balance.
 *
 * For each stake or delegate with amount of {v} to a Layer2,
 *  1. mint {v} {coinages[layer2]} tokens to the account
 *  2. mint {v} {tot} tokens to the layer2 contract
 *
 * For each unstake or undelegate (or get rewards) with amount of {v} to a Layer2,
 *  1. burn {v} {coinages[layer2]} tokens from the account
 *  2. burn {v + ⍺} {tot} tokens from the layer2 contract,
 *   where ⍺ = SEIGS * staked ratio of the layer2 * withdrawal ratio of the account
 *     - SEIGS                              = tot total supply - tot total supply at last commit from the layer2
 *     - staked ratio of the layer2     = tot balance of the layer2 / tot total supply
 *     - withdrawal ratio of the account  = amount to withdraw / total supply of coinage
 *
 */
contract SeigManagerV1_2_onTransfer
  is
  ProxyStorage, AuthControlSeigManager, SeigManagerStorage, SeigManagerV1_1Storage, SeigManagerV1_2_onTransfer_Storage, DSMath
{

  event SeigGiven(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig);

  /** It was deleted from block 18732908, but was added again on v1. */
  event CommitLog1(uint256 totalStakedAmount, uint256 totalSupplyOfWTON, uint256 prevTotalSupply, uint256 nextTotalSupply);

  event AddedBlackList(address account);
  event DeletedBlackList(address account);

  //////////////////////////////
  // External functions
  //////////////////////////////

  /**
   * @dev Callback for a token transfer
   *      Modify at V1_2_onTransfer
   *      Executed when callbackEnabled of TON(or WTON) is true.
   *      When the sender and receiver are blacklisted, the transmission is canceled.
   */
  function onTransfer(address sender, address recipient, uint256 amount) external returns (bool) {
    console.log("call onTransfer ");

    require(msg.sender == address(_ton) || msg.sender == address(_wton),
      "SeigManager: only TON or WTON can call onTransfer");


    if (!paused) {
      _increaseTot();
    }

    // An error occurs when the sender or recipient is blacklisted.
    if (blacklists[sender] || blacklists[recipient]) revert BlackList_Error();

    return true;
  }

  function addBlackList(address[] calldata accounts) external onlyOwner {
    uint256 i;
    for (i ; i < accounts.length; i++) {
      if (!blacklists[accounts[i]] && accounts[i] != address(0)) {
        blacklists[accounts[i]] = true;
        emit AddedBlackList(accounts[i]);
      }
    }
  }

  function deleteBlackList(address[] calldata accounts) external onlyOwner {
    uint256 i;
    for (i ; i < accounts.length; i++) {
      if (blacklists[accounts[i]] && accounts[i] != address(0)) {
        blacklists[accounts[i]] = false;
        emit DeletedBlackList(accounts[i]);
      }
    }
  }

  //////////////////////////////
  // Internal functions
  //////////////////////////////


  function _calcNewFactor(uint256 source, uint256 target, uint256 oldFactor) internal pure returns (uint256) {
    return rdiv(rmul(target, oldFactor), source);
  }

  function _calcNumSeigBlocks() internal view returns (uint256) {
    require(!paused);

    uint256 span = block.number - _lastSeigBlock;
    if (_unpausedBlock < _lastSeigBlock) {
      return span;
    }

    return span - (_unpausedBlock - _pausedBlock);
  }


  function _increaseTot() internal returns (bool) {
    // short circuit if already seigniorage is given.
    if (block.number <= _lastSeigBlock) {
      return false;
    }

    if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
      _lastSeigBlock = block.number;
      return false;
    }

    uint256 prevTotalSupply;
    uint256 nextTotalSupply;

    // 1. increase total supply of {tot} by maximum seigniorages * staked rate
    //    staked rate = total staked amount / total supply of (W)TON

    prevTotalSupply = _tot.totalSupply();

    // maximum seigniorages
    uint256 maxSeig = _calcNumSeigBlocks() * _seigPerBlock;

    // total supply of (W)TON , https://github.com/tokamak-network/TON-total-supply
    uint256 tos = totalSupplyOfTon();

    // maximum seigniorages * staked rate
    uint256 stakedSeig = rdiv(
      rmul(
        maxSeig,
        // total staked amount
        _tot.totalSupply()
      ),
      tos
    );

    // pseig
    uint256 totalPseig = rmul(maxSeig - stakedSeig, relativeSeigRate);

    nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
    _lastSeigBlock = block.number;

    _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

    emit CommitLog1(
      _tot.totalSupply(),
      tos,
      prevTotalSupply,
      nextTotalSupply
    );

    uint256 unstakedSeig = maxSeig - stakedSeig;
    uint256 powertonSeig;
    uint256 daoSeig;
    uint256 relativeSeig;

    if (address(_powerton) != address(0)) {
      powertonSeig = rmul(unstakedSeig, powerTONSeigRate);
      IWTON(_wton).mint(address(_powerton), powertonSeig);
      IPowerTON(_powerton).updateSeigniorage(powertonSeig);
    }

    if (dao != address(0)) {
      daoSeig = rmul(unstakedSeig, daoSeigRate);
      IWTON(_wton).mint(address(dao), daoSeig);
    }

    if (relativeSeigRate != 0) {
      relativeSeig = totalPseig;
      accRelativeSeig = accRelativeSeig + relativeSeig;
    }

    emit SeigGiven(msg.sender, maxSeig, stakedSeig, unstakedSeig, powertonSeig, daoSeig, relativeSeig);

    return true;
  }


  // https://github.com/tokamak-network/TON-total-supply
  // 50,000,000 + 3.92*(target block # - 10837698) - TON in 0x0..1 - 178111.66690985573
  function totalSupplyOfTon() public view returns (uint256 tos) {

    uint256 startBlock = (seigStartBlock == 0? SEIG_START_MAINNET: seigStartBlock);
    uint256 initial = (initialTotalSupply == 0? INITIAL_TOTAL_SUPPLY_MAINNET: initialTotalSupply);
    uint256 burntAmount =(burntAmountAtDAO == 0? BURNT_AMOUNT_MAINNET: burntAmountAtDAO);

    tos = initial
      + (_seigPerBlock * (block.number - startBlock))
      - (ITON(_ton).balanceOf(address(1)) * (10 ** 9))
      - burntAmount ;
  }

  // Actual wton and ton issuance amount
  // function totalSupplyOfTon_1() public view returns (uint256 tos) {
  //   tos = (
  //     (ITON(_ton).totalSupply() - ITON(_ton).balanceOf(_wton) - ITON(_ton).balanceOf(address(1))) * (10 ** 9)
  //     ) + ITON(_wton).totalSupply();
  // }

  /// Unstaked wton was not reflected, this function was used as totalSupplyOfTon before 18732908 block.
  function totalSupplyOfTon_2() public view returns (uint256 tos) {
    tos = (
        (ITON(_ton).totalSupply() - ITON(_ton).balanceOf(_wton) - ITON(_ton).balanceOf(address(0)) - ITON(_ton).balanceOf(address(1))
      ) * (10 ** 9)) + (_tot.totalSupply());
  }

}
