// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { FullMath } from "../../libraries/FullMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ILayer2Manager } from '../../layer2/interfaces/ILayer2Manager.sol';
import { ILayer2Registry } from "../../dao/interfaces/ILayer2Registry.sol";
import { ITON } from "../interfaces/ITON.sol";
import {IL1BridgeRegistry} from '../../layer2/interfaces/IL1BridgeRegistry.sol';
import { MinterRoleRenounceTarget } from "../interfaces/MinterRoleRenounceTarget.sol";
import { PauserRoleRenounceTarget } from "../interfaces/PauserRoleRenounceTarget.sol";
import { OwnableTarget } from "../interfaces/OwnableTarget.sol";

import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";
import { CoinageFactoryI } from "../../dao/interfaces/CoinageFactoryI.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { Layer2I } from "../../dao/interfaces/Layer2I.sol";
import { SeigManagerV1I } from "../interfaces/SeigManagerV1I.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../../common/AuthControlSeigManager.sol";
import { SeigManagerStorage } from "./SeigManagerStorage.sol";
import { SeigManagerV1_1Storage } from "./SeigManagerV1_1Storage.sol";
import {SeigManagerV1_3Storage} from './SeigManagerV1_3Storage.sol';


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
contract SeigManagerV1_2 is ProxyStorage, AuthControlSeigManager, SeigManagerStorage, SeigManagerV1_1Storage,
  SeigManagerV1I, SeigManagerV1_3Storage
{

  uint256 internal constant WEI_UNIT = 1e18;

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


  //////////////////////////////
  // Events
  //////////////////////////////
  event Initialized(address ton_, address wton_, address registry_, address depositManager_, uint256 seigPerBlock_, address factory_, uint256 lastSeigBlock_);
  event CoinageCreated(address indexed layer2, address coinage);

  event CommissionRateSet(address indexed layer2, uint256 previousRate, uint256 newRate);
  event UnstakeLog(uint coinageBurnAmount, uint totBurnAmount);

   /** These were reflected from 18732908 block. */
  // event AddedSeigAtLayer(address layer2, uint256 seigs, uint256 operatorSeigs, uint256 nextTotalSupply, uint256 prevTotalSupply);
  event OnSnapshot(uint256 snapshotId);
  event SetPowerTONSeigRate(uint256 powerTONSeigRate);
  event SetDaoSeigRate(uint256 daoSeigRate);
  event SetPseigRate(uint256 pseigRate);

  /** It was deleted from block 18732908, but was added again on v1. */
  event CommitLog1(uint256 totalStakedAmount, uint256 totalSupplyOfWTON, uint256 prevTotalSupply, uint256 nextTotalSupply);

  event SetSeigStartBlock(uint256 _seigStartBlock);
  event SetInitialTotalSupply(uint256 _initialTotalSupply);
  event SetBurntAmountAtDAO(uint256 _burntAmountAtDAO);

  event Slashed(address layer2, address challenger);
  event SetL1BridgeRegistry (address l1BridgeRegistry_);
  event SetLayer2StartBlock (uint256 startBlock_);
  event SetLayer2Manager (address layer2Manager_);
  event SetPowerTON (address powerton_);
  event SetDao (address daoAddress);
  event SetCoinageFactory (address factory_) ;
  event SetAdjustDelay (uint256 adjustDelay_) ;
  event SetMinimumAmount (uint256 minimumAmount_) ;


  /**
   * @notice Event that occurs when seigniorage is distributed when update seigniorage is executed
   * @param layer2        The layer2 address
   * @param totalSeig     Total amount of seigniorage issued
   * @param stakedSeig    Seigniorage equals to the staking ratio in TON total supply
   *                      in total issued seigniorage
   * @param unstakedSeig  Total issued seigniorage minus stakedSeig
   * @param powertonSeig  Seigniorage distributed to powerton
   * @param daoSeig       Seigniorage distributed to dao
   * @param pseig         Seigniorage equal to relativeSeigRate ratio from unstakedSeig amount
   *                      Seigniorage given to stakers = stakedSeig + pseig
   * @param l2TotalSeigs  Seigniorage distributed to L2 sequencer
   * @param layer2Seigs   Seigniorage currently settled (give) to CandidateAddOn's operatorManager contract
   */
  event SeigGiven2(
      address indexed layer2,
      uint256 totalSeig,
      uint256 stakedSeig,
      uint256 unstakedSeig,
      uint256 powertonSeig,
      uint256 daoSeig,
      uint256 pseig,
      uint256 l2TotalSeigs,
      uint256 layer2Seigs
  );


  function initialize (
    address ton_,
    address wton_,
    address registry_,
    address depositManager_,
    uint256 seigPerBlock_,
    address factory_,
    uint256 lastSeigBlock_
  ) external {
    require(_ton == address(0) && _lastSeigBlock == 0, "already initialized");

    _ton = ton_;
    _wton = wton_;
    _registry = registry_;
    _depositManager = depositManager_;
    _seigPerBlock = seigPerBlock_;

    factory = factory_;
    address c = CoinageFactoryI(factory).deploy();
    require(c != address(0), "zero tot");
    _tot = RefactorCoinageSnapshotI(c);

    _lastSeigBlock = lastSeigBlock_;

    emit Initialized(
        ton_, wton_, registry_, depositManager_,
        seigPerBlock_, factory_,  lastSeigBlock_
    );

  }



  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  function setData(
      address powerton_,
      address daoAddress,
      uint256 powerTONSeigRate_,
      uint256 daoSeigRate_,
      uint256 relativeSeigRate_,
      uint256 adjustDelay_,
      uint256 minimumAmount_
  ) external onlyOwner {
    require(
      powerTONSeigRate + daoSeigRate + relativeSeigRate <= RAY, "exceeded seigniorage rate"
    );
    _powerton = powerton_;
    dao = daoAddress;
    powerTONSeigRate = powerTONSeigRate_;
    daoSeigRate = daoSeigRate_;
    relativeSeigRate = relativeSeigRate_;
    adjustCommissionDelay = adjustDelay_;
    minimumAmount = minimumAmount_;

    emit SetPowerTONSeigRate (powerTONSeigRate_);
    emit SetDaoSeigRate (daoSeigRate_) ;
    emit SetPseigRate (relativeSeigRate_) ;
  }

  function setPowerTON(address powerton_) external onlyOwner {
    require(_powerton != powerton_, "same") ;
    _powerton = powerton_;
    emit SetPowerTON (powerton_) ;
  }

  function setDao(address daoAddress) external onlyOwner {
    require(dao != daoAddress, "same") ;
    dao = daoAddress;
    emit SetDao (daoAddress) ;
  }

  function setPowerTONSeigRate(uint256 powerTONSeigRate_) external onlyOwner {
    require(powerTONSeigRate_ + daoSeigRate + relativeSeigRate <= RAY, "exceeded seigniorage rate");
    powerTONSeigRate = powerTONSeigRate_;
    emit SetPowerTONSeigRate (powerTONSeigRate_);
  }

  function setDaoSeigRate(uint256 daoSeigRate_) external onlyOwner {
    require(powerTONSeigRate + daoSeigRate_ + relativeSeigRate <= RAY, "exceeded seigniorage rate");
    daoSeigRate = daoSeigRate_;
    emit SetDaoSeigRate (daoSeigRate_) ;
  }

  function setPseigRate(uint256 pseigRate_) external onlyOwner {
    require(powerTONSeigRate + daoSeigRate + pseigRate_ <= RAY, "exceeded seigniorage rate");
    relativeSeigRate = pseigRate_;
    emit SetPseigRate (pseigRate_);
  }

  function setCoinageFactory(address factory_) external onlyOwner {
    require(factory != factory_, "same") ;
    factory = factory_;
    emit SetCoinageFactory (factory_) ;
  }

  function transferCoinageOwnership(address newSeigManager, address[] calldata coinages_) external onlyOwner {
    for (uint256 i = 0; i < coinages_.length; i++) {
      RefactorCoinageSnapshotI c = RefactorCoinageSnapshotI(coinages_[i]);
      c.addMinter(newSeigManager);
      c.renounceMinter();
      c.transferOwnership(newSeigManager);
    }
  }

  function renounceWTONMinter() external onlyOwner {
    IWTON(_wton).renounceMinter();
  }

  function setAdjustDelay(uint256 adjustDelay_) external onlyOwner {
    require(adjustCommissionDelay != adjustDelay_, "same") ;
    adjustCommissionDelay = adjustDelay_;
    emit SetAdjustDelay (adjustDelay_) ;
  }

  function setMinimumAmount(uint256 minimumAmount_) external onlyOwner {
    require(minimumAmount != minimumAmount_, "same") ;
    minimumAmount = minimumAmount_;
    emit SetMinimumAmount (minimumAmount_) ;
  }

  function setSeigStartBlock(uint256 _seigStartBlock) external onlyOwner {
    require(seigStartBlock != _seigStartBlock, "same") ;
    seigStartBlock = _seigStartBlock;
    emit SetSeigStartBlock(_seigStartBlock);
  }

  function setInitialTotalSupply(uint256 _initialTotalSupply) external onlyOwner {
    require(initialTotalSupply != _initialTotalSupply, "same") ;
    initialTotalSupply = _initialTotalSupply;
    emit SetInitialTotalSupply(_initialTotalSupply);
  }

  function setBurntAmountAtDAO(uint256 _burntAmountAtDAO) external onlyOwner {
    require(burntAmountAtDAO != _burntAmountAtDAO, "same") ;
    burntAmountAtDAO = _burntAmountAtDAO;
    emit SetBurntAmountAtDAO(_burntAmountAtDAO);
  }


  /**
   * @notice Set the layer2Manager address
   * @param layer2Manager_    the layer2Manager address
   */
  function setLayer2Manager(address layer2Manager_) external onlyOwner {
    require(layer2Manager != layer2Manager_, "same") ;
    layer2Manager = layer2Manager_;

    emit SetLayer2Manager (layer2Manager_) ;
  }

  /**
   * @notice Set the start block number of issuing a l2 seigniorage
   * @param startBlock_    the start block number
   */
  function setLayer2StartBlock(uint256 startBlock_) external onlyOwner {
    require(layer2StartBlock != startBlock_, "same") ;
    layer2StartBlock = startBlock_;
    emit SetLayer2StartBlock (startBlock_) ;
  }

  /**
   * @notice Set the l1BridgeRegistry_ address
   * @param l1BridgeRegistry_    the l1BridgeRegistry address
   */
  function setL1BridgeRegistry(address l1BridgeRegistry_) external onlyOwner {
    require(l1BridgeRegistry != l1BridgeRegistry_, "same") ;
    l1BridgeRegistry = l1BridgeRegistry_;
    emit SetL1BridgeRegistry (l1BridgeRegistry_) ;
  }

  // function resetL2RewardPerUint() external onlyOwner {
  //     require(layer2StartBlock == 0, 'Only possible when layer2StartBlock is 0');
  //     l2RewardPerUint = 0;
  //     emit ResetL2RewardPerUint (l1BridgeRegistry_) ;
  // }

  //====
  function renounceMinter(address target) public onlyOwner {
    MinterRoleRenounceTarget(target).renounceMinter();
  }

  function renouncePauser(address target) public onlyOwner {
    PauserRoleRenounceTarget(target).renouncePauser();
  }

  function renounceOwnership(address target) public onlyOwner {
    OwnableTarget(target).renounceOwnership();
  }

  function transferOwnership(address target, address newOwner) public onlyOwner {
    OwnableTarget(target).transferOwnership(newOwner);
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
      _lastCommitBlock[layer2] = block.number;
      // addChallenger(layer2);
      _coinages[layer2] = RefactorCoinageSnapshotI(c);
      emit CoinageCreated(layer2, c);
    }

    return true;
  }

  function setCommissionRate(
    address layer2,
    uint256 commissionRate,
    bool isCommissionRateNegative_
  )
    external
    onlyRegistryOrOperator(layer2)
    returns (bool)
  {
    require(address(_coinages[layer2]) != address(0), "invalid layer2");
    // check commission range
    require(
      (commissionRate == 0) ||
      (MIN_VALID_COMMISSION <= commissionRate && commissionRate <= MAX_VALID_COMMISSION),
      "SeigManager: commission rate must be 0 or between 1 RAY and 0.01 RAY"
    );

    uint256 previous = _commissionRates[layer2];
    if (adjustCommissionDelay == 0) {
      _commissionRates[layer2] = commissionRate;
      _isCommissionRateNegative[layer2] = isCommissionRateNegative_;
    } else {
      delayedCommissionBlock[layer2] = block.number + adjustCommissionDelay;
      delayedCommissionRate[layer2] = commissionRate;
      delayedCommissionRateNegative[layer2] = isCommissionRateNegative_;
    }

    emit CommissionRateSet(layer2, previous, commissionRate);

    return true;
  }

  // No implementation in registry.
  // function addChallenger(address account) public onlyRegistry {
  //   grantRole(CHALLENGER_ROLE, account);
  // }

  // No implementation in layer2 (candidate).
  function slash(address layer2, address challenger) external onlyChallenger checkCoinage(layer2) returns (bool) {
    Layer2I(layer2).changeOperator(challenger);
    emit Slashed(layer2, challenger);
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
    } else {
      require(_getOperatorAmount(layer2) >= minimumAmount, "OperatorCollateral is insufficient.");
    }

    _tot.mint(layer2, amount);
    _coinages[layer2].mint(account, amount);

    // if (_powerton != address(0)) IPowerTON(_powerton).onDeposit(layer2, account, amount);
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

    // if (_powerton != address(0)) IPowerTON(_powerton).onWithdraw(layer2, account, amount);
    emit UnstakeLog(amount, totAmount);

    return true;
  }


  //////////////////////////////
  // External functions
  //////////////////////////////

  /**
   * @dev Callback for a token transfer
   */
  function onTransfer(address sender, address recipient, uint256 amount) external returns (bool) {
    require(msg.sender == address(_ton) || msg.sender == address(_wton),
      "SeigManager: only TON or WTON can call onTransfer");

    if (!paused) {
      _increaseTot();
    }

    return true;
  }


  function additionalTotBurnAmount(address layer2, address account, uint256 amount)
    external
    view
    returns (uint256 totAmount)
  {
    return _additionalTotBurnAmount(layer2, account, amount);
  }


  function uncommittedStakeOf(address account) external view returns (uint256 amount) {

    uint256 num = ILayer2Registry(_registry).numLayer2s();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = ILayer2Registry(_registry).layer2ByIndex(i);
      amount += _uncommittedStakeOf(layer2, account);
    }
  }

  function uncommittedStakeOf(address layer2, address account) external view returns (uint256) {
    return _uncommittedStakeOf(layer2, account);
  }


  function stakeOf(address layer2, address account) external view returns (uint256) {
    return _coinages[layer2].balanceOf(account);
  }

  function stakeOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256 amount) {
    return _coinages[layer2].balanceOfAt(account, snapshotId);
  }

  function stakeOf(address account) external view returns (uint256 amount) {
    uint256 num = ILayer2Registry(_registry).numLayer2s();
    // amount = 0;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = ILayer2Registry(_registry).layer2ByIndex(i);
      amount += _coinages[layer2].balanceOf(account);
    }
  }

  function stakeOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
    uint256 num = ILayer2Registry(_registry).numLayer2s();
    // amount = 0;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = ILayer2Registry(_registry).layer2ByIndex(i);
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


  // https://github.com/tokamak-network/TON-total-supply
  // 50,000,000 + 3.92*(target block # - 10837698) - TON in 0x0..1 - 178111.66690985573
  function totalSupplyOfTon() external view returns (uint256 tos) {
    return _totalSupplyOfTon(block.number);
  }


  function unallocatedSeigniorage() external view returns (uint256 amount) {
      amount = _tot.totalSupply() - _stakeOfAllLayers();
  }

  function unallocatedSeigniorageAt(uint256 snapshotId) external view returns (uint256 amount) {
      amount = _tot.totalSupplyAt(snapshotId) - _stakeOfAllLayersAt(snapshotId);
  }

  function stakeOfAllLayers() external view returns (uint256 amount) {
    return _stakeOfAllLayers();
  }


  function stakeOfAllLayersAt(uint256 snapshotId) external view returns (uint256 amount) {
      return _stakeOfAllLayersAt(snapshotId);
  }


  /**
   * @notice Query the staking amount held by the operator
   * @param layer2 the layer2(candidate) address
   */
  function getOperatorAmount(address layer2) external view returns (uint256) {
    return _getOperatorAmount(layer2);
  }


  /**
   * @notice Query the unsettled amount of layer2
   * @param layer2   The layer2 address
   * @return amount  The unsettled amount of layer2
   */
  function unSettledReward(address layer2) external view returns (uint256 amount) {
      Layer2Reward memory layer2Info = layer2RewardInfo[layer2];
      if (layer2Info.layer2Tvl != 0)
          amount = l2RewardPerUint * (layer2Info.layer2Tvl / WEI_UNIT) - layer2Info.initialDebt;
  }

  function allowIssuanceLayer2Seigs(
      address layer2
  ) external view returns (address rollupConfig, bool allowed) {
        return _allowIssuanceLayer2Seigs(layer2);
  }

  function progressSnapshotId() external view returns (uint256) {
      return lastSnapshotId;
  }

  function isPauseL2Seigniorage(address layer2) external view returns (bool) {
    return _isPauseL2Seigniorage(layer2);
  }

  //////////////////////////////
  // Public functions
  //////////////////////////////


  // Actual wton and ton issuance amount
  // function totalSupplyOfTon_1() public view returns (uint256 tos) {
  //   tos = (
  //     (ITON(_ton).totalSupply() - ITON(_ton).balanceOf(_wton) - ITON(_ton).balanceOf(address(1))) * (10 ** 9)
  //     ) + ITON(_wton).totalSupply();
  // }

  /// Unstaked wton was not reflected, this function was used as totalSupplyOfTon before 18732908 block.
  function totalSupplyOfTon_2() external view returns (uint256 tos) {
    tos = (
        (ITON(_ton).totalSupply() - ITON(_ton).balanceOf(_wton) - ITON(_ton).balanceOf(address(0)) - ITON(_ton).balanceOf(address(1))
      ) * (10 ** 9)) + (_tot.totalSupply());
  }

  //////////////////////////////
  // Internal functions
  //////////////////////////////

  function _stakeOfAllLayers() internal view returns (uint256 amount) {
      uint256 num = ILayer2Registry(_registry).numLayer2s();
      for (uint256 i = 0; i < num; i++) {
          address layer2 = ILayer2Registry(_registry).layer2ByIndex(i);
          address coin = address(_coinages[layer2]);
          if (coin != address(0)) amount += _coinages[layer2].totalSupply();
      }
  }

  function _stakeOfAllLayersAt(uint256 snapshotId) internal view returns (uint256 amount) {
      uint256 num = ILayer2Registry(_registry).numLayer2s();
      for (uint256 i = 0; i < num; i++) {
          address layer2 = ILayer2Registry(_registry).layer2ByIndex(i);
          address coin = address(_coinages[layer2]);
          if (coin != address(0)) amount += _coinages[layer2].totalSupplyAt(snapshotId);
      }
  }

  function _getOperatorAmount(address layer2) internal view returns (uint256) {
      address operator = Layer2I(layer2).operator();
      return _coinages[layer2].balanceOf(operator);
  }

  function _uncommittedStakeOf(address layer2, address account) internal view returns (uint256) {
    RefactorCoinageSnapshotI coinage = RefactorCoinageSnapshotI(_coinages[layer2]);

    uint256 prevFactor = coinage.factor();
    uint256 prevTotalSupply = coinage.totalSupply();
    uint256 nextTotalSupply = _tot.balanceOf(layer2);
    uint256 newFactor = _calcNewFactor(prevTotalSupply, nextTotalSupply, prevFactor);

    uint256 uncommittedBalance = FullMath.rmul(
      FullMath.rdiv(coinage.balanceOf(account), prevFactor),
      newFactor
    );

    return (uncommittedBalance - _coinages[layer2].balanceOf(account));
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
    if (coinageTotalSupply >= totBalalnce && coinageTotalSupply - totBalalnce < WEI_UNIT) {
      return 0;
    }

    return FullMath.rdiv(
      FullMath.rmul(
        totBalalnce - coinageTotalSupply,
        amount
      ),
      coinageTotalSupply
    );
  }

  function _calcNewFactor(uint256 source, uint256 target, uint256 oldFactor) internal pure returns (uint256) {
    return FullMath.rdiv(FullMath.rmul(target, oldFactor), source);
  }

  function _isOperator(address layer2, address operator) internal view returns (bool) {
    return operator == Layer2I(layer2).operator();
  }


  function _increaseTot() internal returns (bool result) {
      if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
          _lastSeigBlock = block.number;
          return false;
      }

      // 1. increase total supply of {tot} by maximum seigniorages * staked rate
      //    staked rate = total staked amount / total supply of (W)TON
      uint256 prevTotalSupply = _tot.totalSupply();

      uint256 span = block.number - _lastSeigBlock;
      if (_unpausedBlock > _lastSeigBlock) span -= (_unpausedBlock - _pausedBlock);

      // maximum seigniorages
      uint256 maxSeig = span * _seigPerBlock;

      // total supply of (W)TON , https://github.com/tokamak-network/TON-total-supply
      uint256 tos = _totalSupplyOfTon(block.number);

      // maximum seigniorages * staked rate
      uint256 stakedSeig = FullMath.rdiv(
          FullMath.rmul(
              maxSeig,
              // total staked amount
              prevTotalSupply
          ),
          tos
      );
      // uint256 stakedSeig = maxSeig.mulDivRoundingUp(prevTotalSupply, RAY).mulDivRoundingUp(RAY, tos);

      // If layer2StartBlock is not set, set it to the previous block so that the signiorge will be accumulated to layer2 immediately.
      if (layer2StartBlock == 0) layer2StartBlock = block.number - 1;

      address wton_ = _wton;
      uint256 l2TotalSeigs;
      uint256 layer2Seigs;

      if (layer2Manager != address(0) && layer2StartBlock != 1) {
          if (layer2StartBlock <= block.number && totalLayer2TVL > 0) {
              uint256 tempTotalLayer2TVL = Math.min(totalLayer2TVL * 1e9, tos-prevTotalSupply);
              l2TotalSeigs = FullMath.rdiv(FullMath.rmul(maxSeig, tempTotalLayer2TVL), tos);
              l2RewardPerUint += (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
              IWTON(wton_).mint(layer2Manager, l2TotalSeigs);
          }

          (address rollupConfig, bool allowed) = _allowIssuanceLayer2Seigs(msg.sender);
          if (allowed && !_isPauseL2Seigniorage(msg.sender)) {
              uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
              Layer2Reward storage newLayer2Info = layer2RewardInfo[msg.sender];
              Layer2Reward memory oldLayer2Info = layer2RewardInfo[msg.sender];

              // update layer2 tvl if it has changed
              // Because the previous information(oldLayer2Info) was loaded into memory, the storage immediately reflects the latest information.
              if (oldLayer2Info.layer2Tvl != curLayer2Tvl) {
                  newLayer2Info.layer2Tvl = curLayer2Tvl;
                  totalLayer2TVL = totalLayer2TVL + curLayer2Tvl - oldLayer2Info.layer2Tvl;
              }

              // If this the first commit, set up an initial debt
              if (oldLayer2Info.startBlock == 0) {
                  newLayer2Info.startBlock = block.number;
              } else {
                  // distribute seigniorage to layer2 based on previous layer2 tvl
                  // layer2Tvl would be 0 when layer2 has been paused
                  if (oldLayer2Info.layer2Tvl > 0) {
                      layer2Seigs =
                          ((l2RewardPerUint * oldLayer2Info.layer2Tvl) / WEI_UNIT) -
                          oldLayer2Info.initialDebt;
                      // rewards just increase higher than layer2Debt because it is calculated based on previous layer2 tvl
                      if (layer2Seigs != 0) ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
                  }
              }
              newLayer2Info.initialDebt = (l2RewardPerUint * curLayer2Tvl) / WEI_UNIT;
          }
      }

      uint256 unstakedSeig = maxSeig - stakedSeig - l2TotalSeigs;
      uint256 totalPseig = FullMath.rmul(unstakedSeig, relativeSeigRate);
      uint256 nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
      _lastSeigBlock = block.number;

      _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

      emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, nextTotalSupply);

      uint256 powertonSeig;
      uint256 daoSeig;
      uint256 relativeSeig;

      if (_powerton != address(0)) {
          powertonSeig = FullMath.rmul(unstakedSeig, powerTONSeigRate);
          if (powertonSeig != 0) IWTON(wton_).mint(_powerton, powertonSeig);
      }

      if (dao != address(0)) {
          daoSeig = FullMath.rmul(unstakedSeig, daoSeigRate);
          if (daoSeig != 0) IWTON(wton_).mint(dao, daoSeig);
      }

      if (relativeSeigRate != 0) {
          relativeSeig = totalPseig;
          accRelativeSeig += relativeSeig;
      }

      emit SeigGiven2(
          msg.sender,
          maxSeig,
          stakedSeig,
          unstakedSeig,
          powertonSeig,
          daoSeig,
          relativeSeig,
          l2TotalSeigs,
          layer2Seigs
      );

      result = true;
  }


  function _totalSupplyOfTon(uint256 blockNumber) internal view returns (uint256 tos) {

    uint256 startBlock = (seigStartBlock == 0? SEIG_START_MAINNET: seigStartBlock);
    uint256 initial = (initialTotalSupply == 0? INITIAL_TOTAL_SUPPLY_MAINNET: initialTotalSupply);
    uint256 burntAmount =(burntAmountAtDAO == 0? BURNT_AMOUNT_MAINNET: burntAmountAtDAO);

    tos = initial
      + (_seigPerBlock * (blockNumber - startBlock))
      - (ITON(_ton).balanceOf(address(1)) * (10 ** 9))
      - burntAmount ;
  }


  function _allowIssuanceLayer2Seigs(
      address layer2
  ) internal view returns (address rollupConfig, bool allowed) {
      (rollupConfig, ) = ILayer2Manager(layer2Manager).layerInfo(layer2);
      if (ILayer2Manager(layer2Manager).statusLayer2(rollupConfig) == 1) allowed = true;
  }


  function _isPauseL2Seigniorage(address layer2) internal view returns (bool) {
      uint256[] memory pauseBlocks = layer2PauseBlocks[layer2];
      uint256 len = pauseBlocks.length;
      if (len == 0) return false;

      uint256 pauseBlock = pauseBlocks[len - 1];

      if (pauseBlock != 0 && layer2UnpauseBlocks[layer2][pauseBlock] == 0) return true;
      else return false;
  }

  function _layer2RewardInfo(address layer2) internal view returns (Layer2Reward memory) {
    Layer2Reward memory info = layer2RewardInfo[layer2];
    return info;
  }


  function getLayer2RewardInfo(address layer2) external view returns (Layer2Reward memory) {
    return _layer2RewardInfo(layer2);
  }

  //////////////////////////////
  // Storage getters
  //////////////////////////////

  // solium-disable
  function registry() external view returns (address) { return address(_registry); }
  function depositManager() external view returns (address) { return address(_depositManager); }
  function ton() external view returns (address) { return address(_ton); }
  function wton() external view returns (address) { return address(_wton); }
  function powerton() external view returns (address) { return address(_powerton); }
  function tot() external view returns (address) { return address(_tot); }
  function coinages(address layer2) external view returns (address) { return address(_coinages[layer2]); }
  function commissionRates(address layer2) external view returns (uint256) { return _commissionRates[layer2]; }
  function isCommissionRateNegative(address layer2) external view returns (bool) { return _isCommissionRateNegative[layer2]; }

  function lastCommitBlock(address layer2) external view returns (uint256) { return _lastCommitBlock[layer2]; }
  function seigPerBlock() external view returns (uint256) { return _seigPerBlock; }
  function lastSeigBlock() external view returns (uint256) { return _lastSeigBlock; }
  function pausedBlock() external view returns (uint256) { return _pausedBlock; }
  function unpausedBlock() external view returns (uint256) { return _unpausedBlock; }

  function DEFAULT_FACTOR() external pure returns (uint256) { return _DEFAULT_FACTOR; }
  // solium-enable


  //////////////////////////////
  // SeigManagerV1_3
  //////////////////////////////
  function updateSeigniorage() external returns (bool) {
    revert("SeigManagerV1_3");
    return false;
  }

  function updateSeigniorageLayer(address layer2) external returns (bool){
    revert("SeigManagerV1_3");
    return false;
  }

  function estimatedDistribute(
      uint256 blockNumber,
      address layer2
  )
      external
      view
      returns (
          uint256 maxSeig,
          uint256 stakedSeig,
          uint256 unstakedSeig,
          uint256 powertonSeig,
          uint256 daoSeig,
          uint256 relativeSeig,
          uint256 l2TotalSeigs,
          uint256 layer2Seigs
      )
  {
      revert("SeigManagerV1_3");
      return (0,0,0,0,0,0,0,0);
  }

  function claimableL2Seigniorage(address layer2) external view returns (uint256 amount) {
    revert("SeigManagerV1_3");
    return 0;
  }

  function excludeFromL2Seigniorage(address layer2) external returns (bool) {
    revert("SeigManagerV1_3");
    return false;
  }

  function includeFromL2Seigniorage(address layer2) external returns (bool) {
    revert("SeigManagerV1_3");
    return false;
  }

}