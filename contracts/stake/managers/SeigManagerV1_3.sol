// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRefactor } from "../interfaces/IRefactor.sol";
import { DSMath } from "../../libraries/DSMath.sol";
import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";
import { CoinageFactoryI } from "../../dao/interfaces/CoinageFactoryI.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { Layer2I } from "../../dao/interfaces/Layer2I.sol";
import { SeigManagerV1I } from "../interfaces/SeigManagerV1I.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../../common/AuthControlSeigManager.sol";
import { SeigManagerStorage } from "./SeigManagerStorage.sol";
import { SeigManagerV1_1Storage } from "./SeigManagerV1_1Storage.sol";
import { SeigManagerV1_3Storage } from "./SeigManagerV1_3Storage.sol";

import "hardhat/console.sol";

interface MinterRoleRenounceTarget {
  function renounceMinter() external;
}

interface PauserRoleRenounceTarget {
  function renouncePauser() external;
}

interface OwnableTarget {
  function renounceOwnership() external;
  function transferOwnership(address newOwner) external;
}

interface IILayer2Registry {
  function layer2s(address layer2) external view returns (bool);
  function numLayer2s() external view  returns (uint256);
  function layer2ByIndex(uint256 index) external view returns (address);
}

interface IPowerTON {
  function updateSeigniorage(uint256 amount) external;
  function onDeposit(address layer2, address account, uint256 amount) external;
  function onWithdraw(address layer2, address account, uint256 amount) external;
}

interface ITON {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}

interface IRefactorCoinageSnapshot {
  function snapshot() external returns (uint256 id);
}

interface ICandidate {
  function updateSeigniorage() external returns (bool);
}

// interface IDepositManager {
//   function updateSeigniorage() external returns (bool);
// }

interface IL2Registry {
  function layer2TVL(address _systemConfig) external view returns (uint256 amount);
}

interface ILayer2Manager {
  function updateSeigniorage(address systemConfig, uint256 amount) external ;
  function systemConfigOfOperator(address operator) external returns (address);
  function issueStatusLayer2(address systemConfig) external returns (uint8);
}

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
contract SeigManagerV1_3 is ProxyStorage, AuthControlSeigManager, SeigManagerStorage, SeigManagerV1_1Storage, DSMath, SeigManagerV1_3Storage {

  //////////////////////////////
  // Modifiers
  //////////////////////////////

  modifier onlyRegistry() {
    require(msg.sender == _registry, "not onlyRegistry");
    _;
  }

  modifier onlyRegistryOrOperator(address layer2) {
    require(msg.sender == _registry || msg.sender == Layer2I(layer2).operator(), "not onlyRegistryOrOperator");
    _;
  }

  modifier onlyDepositManager() {
    require(msg.sender == _depositManager, "not onlyDepositManager");
    _;
  }

  modifier checkCoinage(address layer2) {
    require(address(_coinages[layer2]) != address(0), "SeigManager: coinage has not been deployed yet");
    _;
  }

  modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
      require(paused, "Pausable: not paused");
      _;
  }

  //////////////////////////////
  // Events
  //////////////////////////////

  event SeigGiven(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig);
  event Comitted(address indexed layer2);

  /** These were reflected from 18732908 block. */
  event AddedSeigAtLayer(address layer2, uint256 seigs, uint256 operatorSeigs, uint256 nextTotalSupply, uint256 prevTotalSupply);

  /** It was deleted from block 18732908, but was added again on v1. */
  event CommitLog1(uint256 totalStakedAmount, uint256 totalSupplyOfWTON, uint256 prevTotalSupply, uint256 nextTotalSupply);

  /** Added from v1_3. */
  event SeigGiven2(address indexed layer2, uint256 totalSeig, uint256 stakedSeig, uint256 unstakedSeig, uint256 powertonSeig, uint256 daoSeig, uint256 pseig, uint256 l2TotalSeigs, uint256 layer2Seigs);

  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  function setLayer2Manager(address layer2Manager_) external onlyOwner {
    layer2Manager = layer2Manager_;
  }

  function setLayer2StartBlock(uint256 startBlock_) external onlyOwner {
    layer2StartBlock = startBlock_;
  }

  function setL2Registry(address l2Registry_) external onlyOwner {
    l2Registry = l2Registry_;
  }

  //////////////////////////////
  // checkCoinage
  //////////////////////////////

  function updateSeigniorageOperator()
    public
    checkCoinage(msg.sender)
    returns (bool)
  {
    return _updateSeigniorage(true);
  }

  function updateSeigniorage()
    public
    checkCoinage(msg.sender)
    returns (bool)
  {
    return _updateSeigniorage(false);
  }

  /**
   * @dev Callback for a new commit
   */
  /// on v1_3, it is changed with reflecting L2 sequencer.
  function _updateSeigniorage(bool _isSenderOperator)
    internal
    returns (bool)
  {
    // short circuit if paused
    if (paused) {
      return true;
    }
    require(block.number > _lastSeigBlock, "last seig block is not past");

    uint256 operatorAmount = getOperatorAmount(msg.sender);
    require(operatorAmount >= minimumAmount, "minimumAmount is insufficient");

    RefactorCoinageSnapshotI coinage = _coinages[msg.sender];

    require(_increaseTot(_isSenderOperator), '_increaseTot false');

    _lastCommitBlock[msg.sender] = block.number;

    // 2. increase total supply of {coinages[layer2]}
    // RefactorCoinageSnapshotI coinage = _coinages[msg.sender];

    uint256 prevTotalSupply = coinage.totalSupply();
    uint256 nextTotalSupply = _tot.balanceOf(msg.sender);

    // short circuit if there is no seigs for the layer2
    if (prevTotalSupply >= nextTotalSupply) {
      emit Comitted(msg.sender);
      return true;
    }

    uint256 seigs = nextTotalSupply - prevTotalSupply;
    address operator = Layer2I(msg.sender).operator();
    uint256 operatorSeigs;

    // calculate commission amount
    bool isCommissionRateNegative_ = _isCommissionRateNegative[msg.sender];

    (nextTotalSupply, operatorSeigs) = _calcSeigsDistribution(
      msg.sender,
      coinage,
      prevTotalSupply,
      seigs,
      isCommissionRateNegative_,
      operator
    );

    // gives seigniorages to the layer2 as coinage
    coinage.setFactor(
      _calcNewFactor(
        prevTotalSupply,
        nextTotalSupply,
        coinage.factor()
      )
    );

    // give commission to operator or delegators
    if (operatorSeigs != 0) {
      if (isCommissionRateNegative_) {
        // TODO: adjust arithmetic error
        // burn by 𝜸
        coinage.burnFrom(operator, operatorSeigs);
      } else {
        coinage.mint(operator, operatorSeigs);
      }
    }

    IWTON(_wton).mint(address(_depositManager), seigs);

    emit Comitted(msg.sender);
    emit AddedSeigAtLayer(msg.sender, seigs, operatorSeigs, nextTotalSupply, prevTotalSupply);

    return true;
  }


  //////////////////////////////
  // External functions
  //////////////////////////////

  function getOperatorAmount(address layer2) public view returns (uint256) {
    address operator = Layer2I(layer2).operator();
    return _coinages[layer2].balanceOf(operator);
  }

  function updateSeigniorageLayer(address layer2) external returns (bool){
    require(ICandidate(layer2).updateSeigniorage(), "fail updateSeigniorage");
    return true;
  }

  //////////////////////////////
  // Public functions
  //////////////////////////////


  //////////////////////////////
  // Internal functions
  //////////////////////////////

  function _calcSeigsDistribution(
    address layer2,
    RefactorCoinageSnapshotI coinage,
    uint256 prevTotalSupply,
    uint256 seigs,
    bool isCommissionRateNegative_,
    address operator
  ) internal returns (
    uint256 nextTotalSupply,
    uint256 operatorSeigs
  ) {
    if (block.number >= delayedCommissionBlock[layer2] && delayedCommissionBlock[layer2] != 0) {
      _commissionRates[layer2] = delayedCommissionRate[layer2];
      _isCommissionRateNegative[layer2] = delayedCommissionRateNegative[layer2];
      delayedCommissionBlock[layer2] = 0;
    }

    uint256 commissionRate = _commissionRates[msg.sender];

    nextTotalSupply = prevTotalSupply + seigs;

    // short circuit if there is no commission rate
    if (commissionRate == 0) {
      return (nextTotalSupply, operatorSeigs);
    }

    // if commission rate is possitive
    if (!isCommissionRateNegative_) {
      operatorSeigs = rmul(seigs, commissionRate); // additional seig for operator
      nextTotalSupply = nextTotalSupply - operatorSeigs;
      return (nextTotalSupply, operatorSeigs);
    }

    // short circuit if there is no previous total deposit (meanning, there is no deposit)
    if (prevTotalSupply == 0) {
      return (nextTotalSupply, operatorSeigs);
    }

    // See negative commission distribution formular here: TBD
    uint256 operatorBalance = coinage.balanceOf(operator);

    // short circuit if there is no operator deposit
    if (operatorBalance == 0) {
      return (nextTotalSupply, operatorSeigs);
    }

    uint256 operatorRate = rdiv(operatorBalance, prevTotalSupply);

    // ɑ: insufficient seig for operator
    operatorSeigs = rmul(
      rmul(seigs, operatorRate), // seigs for operator
      commissionRate
    );

    // β:
    uint256 delegatorSeigs = operatorRate == RAY
      ? operatorSeigs
      : rdiv(operatorSeigs, RAY - operatorRate);

    // 𝜸:
    operatorSeigs = operatorRate == RAY
      ? operatorSeigs
      : operatorSeigs + rmul(delegatorSeigs, operatorRate);

    nextTotalSupply = nextTotalSupply + delegatorSeigs;

    return (nextTotalSupply, operatorSeigs);
  }

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

  function allowIssuanceLayer2Seigs(address layer2) public returns (address systemConfig, bool allowed) {
      systemConfig = ILayer2Manager(layer2Manager).systemConfigOfOperator(Layer2I(layer2).operator());
      if(systemConfig == address(0)) allowed = false;
      else {
        if(ILayer2Manager(layer2Manager).issueStatusLayer2(systemConfig) != 0) allowed = true;
      }
  }

  function _increaseTot(bool _isSenderOperator) internal returns (bool result) {

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

    // L2 sequencers
    uint256 l2TotalSeigs = 0;
    uint256 curLayer2Tvl = 0;
    address systemConfig;
    bool layer2Allowed;
    Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

    if (layer2StartBlock < block.number){
      (systemConfig, layer2Allowed) = allowIssuanceLayer2Seigs(msg.sender);
      if (layer2Allowed) {
        curLayer2Tvl = IL2Registry(l2Registry).layer2TVL(systemConfig);
        // 다음에 반영되게 수정
        // totalLayer2TVL = totalLayer2TVL - oldLayer2Info.layer2Tvl + curLayer2Tvl;
        if (totalLayer2TVL != 0) {
          l2TotalSeigs = rdiv(rmul(maxSeig, totalLayer2TVL*1e9),tos);
        }
      }
    }
    console.log('totalLayer2TVL %s', totalLayer2TVL);
    console.log('l2TotalSeigs %s', l2TotalSeigs);

    // pseig
    // uint256 totalPseig = rmul(maxSeig - stakedSeig, relativeSeigRate);
    uint256 totalPseig = rmul(maxSeig - stakedSeig - l2TotalSeigs, relativeSeigRate);

    nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
    _lastSeigBlock = block.number;

    _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

    emit CommitLog1(
      _tot.totalSupply(),
      tos,
      prevTotalSupply,
      nextTotalSupply
    );

    uint256 unstakedSeig = maxSeig - stakedSeig - l2TotalSeigs;
    uint256 powertonSeig;
    uint256 daoSeig;
    uint256 relativeSeig;

    if (layer2Manager != address(0) && l2TotalSeigs != 0) {
      IWTON(_wton).mint(layer2Manager, l2TotalSeigs);
    }

    if (address(_powerton) != address(0)) {
      powertonSeig = rmul(unstakedSeig, powerTONSeigRate);
      IWTON(_wton).mint(address(_powerton), powertonSeig);
      // IPowerTON(_powerton).updateSeigniorage(powertonSeig);
    }

    if (dao != address(0)) {
      daoSeig = rmul(unstakedSeig, daoSeigRate);
      IWTON(_wton).mint(address(dao), daoSeig);
    }

    if (relativeSeigRate != 0) {
      relativeSeig = totalPseig;
      accRelativeSeig = accRelativeSeig + relativeSeig;
    }

    console.logBool(layer2Allowed);

    // L2 seigs settlement
    uint256 layer2Seigs = 0;
    if (layer2Allowed){
      if (l2RewardPerUint == 0) l2RewardPerUint = 1 ether;
      l2RewardPerUint += l2TotalSeigs / totalLayer2TVL;

      Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];

      if (_isSenderOperator || oldLayer2Info.layer2Tvl > curLayer2Tvl) {
        layer2Seigs += unSettledReward(msg.sender);
        ILayer2Manager(layer2Manager).updateSeigniorage(systemConfig, layer2Seigs);
        newLayer2Info.initialDebt = curLayer2Tvl * l2RewardPerUint ;

      } else if(newLayer2Info.initialDebt == 0) {
        newLayer2Info.initialDebt = curLayer2Tvl * l2RewardPerUint ;
      }

      newLayer2Info.layer2Tvl = curLayer2Tvl;
      totalLayer2TVL = totalLayer2TVL - oldLayer2Info.layer2Tvl + curLayer2Tvl;

    }


    // on v1_3. changed event
    // emit SeigGiven(msg.sender, maxSeig, stakedSeig, unstakedSeig, powertonSeig, daoSeig, relativeSeig);
    emit SeigGiven2(msg.sender, maxSeig, stakedSeig, unstakedSeig, powertonSeig, daoSeig, relativeSeig, l2TotalSeigs, layer2Seigs);

    result = true;
  }

  function unSettledReward(address layer2) public  view returns (uint256 amount) {
    Layer2Reward memory layer2Info = layer2RewardInfo[layer2];
    if (layer2Info.layer2Tvl != 0) amount = layer2Info.layer2Tvl * l2RewardPerUint - layer2Info.initialDebt;
  }

  //=====

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

}
