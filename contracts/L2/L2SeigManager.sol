// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";
import { LibL2StakedInfo } from "../libraries/LibL2StakedInfo.sol";

import "../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../common/AuthControlSeigManager.sol";
import { L2SeigManagerStorage } from "./L2SeigManagerStorage.sol";

import "hardhat/console.sol";

interface IL2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract L2SeigManager is ProxyStorage, AuthControlSeigManager, L2SeigManagerStorage {

  //////////////////////////////
  // Modifiers
  //////////////////////////////
  modifier onlyL1StakedTonInL2() {
    require(l1StakedTonInL2 == msg.sender, "not l1StakedTonInL2");
    _;
  }
  event OnSnapshot(uint256 snapshotId);
  event Deposited(address layer2, address account, uint256 swtonAmount, uint256 lswton);
  event Withdrawal(address layer2, address account, uint256 swtonAmount, uint256 lswton);
  event RebasedIndex(address layer2, uint256 sharePerRay, uint256 oldIndex, uint256 newIndex);
  event Replaced(address layer2, address account, uint256 oldLswton, uint256 lswton, uint256 tlswton);

  //////////////////////////////
  // Constuctor
  //////////////////////////////

  //////////////////////////////
  // onlyOwner
  //////////////////////////////

  function initialize (
    address l1StakedTonInL2_,
    address l2messanger_
  ) external onlyOwner {
      l1StakedTonInL2 = l1StakedTonInL2_;
      l2CrossDomainMessenger =l2messanger_;
  }

  function addLayers(address[] memory layer2s) external onlyOwner {
    for (uint256 i = 0; i < layer2s.length; i++) {
      if (index[layer2s[i]] == 0) index[layer2s[i]] = 1e27;

      if (!_l1layer2s[layer2s[i]]) {
        _l1layer2s[layer2s[i]] = true;
        l1layer2s.push(layer2s[i]);
      }
    }
  }

  //////////////////////////////
  // onlyL1StakedTonInL2
  //////////////////////////////

  function register(address account, LibL1StakedInfo.L1StakedPacket[] memory packets)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    require(packets.length != 0, "no packets");
    uint256 num = packets.length;
    // console.log('register num %s', num);

    for (uint256 i = 0; i < num; i++) {
      _checkLayer(packets[i].layer);
      _replace(packets[i].layer, account, packets[i].stakedAmount);
      // console.log('end');
    }
    return true;
  }

  function deposit(address layer2, address account, uint256 swtonAmount)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    _checkLayer(layer2);
    uint256 lswton = getSwtonToLswton(layer2, swtonAmount);

    LibL2StakedInfo.StakedInfo storage info = stakedInfo[layer2][account];
    info.deposit += swtonAmount;
    info.lswton += lswton;
    totalLswton[layer2] += lswton;

    emit Deposited(layer2, account, swtonAmount, lswton);
    return true;
  }

  function withdraw(address layer2, address account, uint256 swtonAmount)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    _checkLayer(layer2);
    uint256 lswton = getSwtonToLswton(layer2, swtonAmount);

    LibL2StakedInfo.StakedInfo storage info = stakedInfo[layer2][account];
    require(swtonAmount <= info.deposit, 'insufficient balance');

    if (info.lswton < lswton)  info.lswton = 0;
    else info.lswton -= lswton;

    require(lswton <= totalLswton[layer2], 'insufficient totalLswton');
    totalLswton[layer2] -= lswton;

    emit Withdrawal(layer2, account, swtonAmount, lswton);
    return true;
  }

  function rebaseIndex(address layer2, uint256 sharePerRay)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    console.log('rebaseIndex sharePerRay %s', sharePerRay);
    _checkLayer(layer2);
    uint256 tlswton = totalLswton[layer2];
    // console.log('rebaseIndex totalLswton[layer2] %s', tlswton);
    // console.log('rebaseIndex totalSwton %s', totalSwton);
    uint256 oldIndex = index[layer2];
    // uint256 addAmount = (tlswton * oldIndex / 1e27) * sharePerRay / 1e27;
    // console.log('rebaseIndex addAmount %s', addAmount);
    // uint256 newIndex = oldIndex * (totalSwton + addAmount) / totalSwton ;
    uint256 newIndex = oldIndex * ((tlswton * oldIndex  + tlswton * sharePerRay) / 1e27) / (tlswton * oldIndex / 1e27) ;

    // console.log('rebaseIndex oldIndex %s', oldIndex);
    // console.log('rebaseIndex newIndex %s', newIndex);

    index[layer2] = newIndex;

    // uint256 totalSwtonAfter = getLswtonToSwton(layer2, totalLswton[layer2]);
    // console.log('rebaseIndex totalSwtonAfter %s', totalSwtonAfter);

    emit RebasedIndex(layer2, sharePerRay, oldIndex, newIndex);
    return true;
  }

  //////////////////////////////
  // External functions
  //////////////////////////////

  function balanceOf(address layer2, address account) public view returns (uint256) {
      return getLswtonToSwton(layer2, stakedInfo[layer2][account].lswton);
  }

  // function stakeOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256 amount) {
  //   return _coinages[layer2].balanceOfAt(account, snapshotId);
  // }

  function balanceOf(address account) external view returns (uint256 amount) {
    uint256 num = getL1LayersNum();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = l1layer2s[i];
      amount += getLswtonToSwton(layer2, stakedInfo[layer2][account].lswton);
    }
  }

  // function stakeOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
  //   uint256 num = getL1LayersNum();
  //   for (uint256 i = 0 ; i < num; i++){
  //     amount += _coinages[l1layer2s[i]].balanceOfAt(account, snapshotId);
  //   }
  // }

  function totalSupply(address layer2) external view returns (uint256 amount) {
    amount = getLswtonToSwton(layer2, totalLswton[layer2]);
  }

  function totalSupply() external view returns (uint256 amount) {
    uint256 num = getL1LayersNum();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = l1layer2s[i];
      amount += getLswtonToSwton(layer2, totalLswton[layer2]);
    }
  }

  // function stakeOfTotalAt(uint256 snapshotId) external view returns (uint256 amount) {
  //   amount = _tot.totalSupplyAt(snapshotId);
  // }

  function onSnapshot() external returns (uint256 snapshotId) {
    snapshotId = lastSnapshotId;
    emit OnSnapshot(snapshotId);
    lastSnapshotId++;
  }

  //////////////////////////////
  // Public functions
  //////////////////////////////

  function getL1LayersNum() public view returns (uint256) {
    return l1layer2s.length;
  }

  function getSwtonToLswton(address layer2, uint256 amount) public view returns (uint256) {
    if (amount == 0) return 0;
    return (amount * 1e27) / index[layer2];
  }

  function getLswtonToSwton(address layer2, uint256 lswton_) public view returns (uint256) {
    if (lswton_ == 0) return 0;
    return (lswton_ * index[layer2]) / 1e27;
  }

  function viewStakedInfo(address layer2, address account) public view returns (LibL2StakedInfo.StakedInfo memory) {
    return stakedInfo[layer2][account];
  }

  function name() public pure returns (string memory) {
    return "Swton L1";
  }

  function symbol() public pure returns (string memory) {
    return "SWTON_L1";
  }

  function decimals() public pure returns (uint256) {
    return 27;
  }

  //////////////////////////////
  // Internal functions
  //////////////////////////////
  function _checkLayer(address layer2) internal ifFree {
    if (index[layer2] == 0) index[layer2] = 1e27;
    if (!_l1layer2s[layer2]) {
      _l1layer2s[layer2] = true;
      l1layer2s.push(layer2);
    }
  }


  function updateStakedInfo(LibL2StakedInfo.StakedInfo storage d, uint256 depositAmount, uint256 lswton) internal {
    d.deposit = depositAmount;
    d.lswton = lswton;
  }

  function _replace(address layer2, address account, uint256 swtonAmount) internal returns (uint256 tlswton) {

    uint256 lswton = getSwtonToLswton(layer2, swtonAmount);
    LibL2StakedInfo.StakedInfo memory info = stakedInfo[layer2][account];

    tlswton = totalLswton[layer2];
    uint256 oldLswton = info.lswton;

    if (lswton != oldLswton) {
      if (lswton != 0) tlswton += lswton;
      if (oldLswton != 0) tlswton -= oldLswton;
      updateStakedInfo(stakedInfo[layer2][account], swtonAmount, lswton);
      // console.log('stakedInfo %s %s  ', stakedInfo[layer2][account].lswton, stakedInfo[layer2][account].deposit);
      if(tlswton != totalLswton[layer2]) totalLswton[layer2] = tlswton;
      emit Replaced(layer2, account, oldLswton, lswton, tlswton);
    }
  }

  //////////////////////////////
  // Storage getters
  //////////////////////////////

  //=====
  function progressSnapshotId() public view returns (uint256) {
      return lastSnapshotId;
  }

}
