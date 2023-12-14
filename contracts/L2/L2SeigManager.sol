// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";
import { LibL2StakedInfo } from "../libraries/LibL2StakedInfo.sol";
import { SArrays } from "../libraries/SArrays.sol";

import "../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../common/AuthControlSeigManager.sol";
import { L2SeigManagerStorage } from "./L2SeigManagerStorage.sol";

import "hardhat/console.sol";

interface IL2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract L2SeigManager is ProxyStorage, AuthControlSeigManager, L2SeigManagerStorage {
  using SArrays for uint256[];

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
      address layer2 = layer2s[i];
      if (getIndex(layer2) == 0) _updateIndex(layer2, 1e27);

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
    LibL2StakedInfo.StakedInfo memory info = getStakedInfo(layer2, account);
    info.deposit += swtonAmount;
    info.lswton += lswton;

    uint256 tlswton = getTotalLswton(layer2) + lswton;

    _updateStakedInfo(layer2, account, info);
    _updateTotalLswton(layer2, tlswton);

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
    LibL2StakedInfo.StakedInfo memory info = getStakedInfo(layer2, account);
    require(swtonAmount <= info.deposit, 'insufficient balance');

    info.deposit -= swtonAmount;
    if (info.lswton < lswton)  info.lswton = 0;
    else info.lswton -= lswton;

    uint256 tlswton = getTotalLswton(layer2);
    require(lswton <= tlswton, 'insufficient totalLswton');
    tlswton -= lswton;

    _updateStakedInfo(layer2, account, info);
    _updateTotalLswton(layer2, tlswton);

    emit Withdrawal(layer2, account, swtonAmount, lswton);
    return true;
  }

  function rebaseIndex(address layer2, uint256 sharePerRay)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    _checkLayer(layer2);

    uint256 tlswton = getTotalLswton(layer2);
    uint256 oldIndex = getIndex(layer2);
    uint256 newIndex = oldIndex * ((tlswton * oldIndex  + tlswton * sharePerRay) / 1e27) / (tlswton * oldIndex / 1e27) ;

    _updateIndex(layer2, newIndex);

    emit RebasedIndex(layer2, sharePerRay, oldIndex, newIndex);
    return true;
  }


  //////////////////////////////
  // External functions
  //////////////////////////////

  function balanceOf(address layer2, address account) public view returns (uint256) {
    LibL2StakedInfo.StakedInfo memory info = getStakedInfo(layer2, account);
    return getLswtonToSwton(layer2, info.lswton);
  }

  function balanceOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256 amount) {
    LibL2StakedInfo.StakedInfo memory info = getStakedInfoAt(layer2, account, snapshotId);
    return getLswtonToSwton(layer2, info.lswton);
  }

  function balanceOf(address account) external view returns (uint256 amount) {
    uint256 num = getL1LayersNum();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = l1layer2s[i];
      LibL2StakedInfo.StakedInfo memory info = getStakedInfo(layer2, account);
      amount += getLswtonToSwton(layer2, info.lswton);
    }
  }

  function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
    uint256 num = getL1LayersNum();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = l1layer2s[i];
      LibL2StakedInfo.StakedInfo memory info = getStakedInfoAt(layer2, account, snapshotId);
      amount += getLswtonToSwton(layer2, info.lswton);
    }
  }

  function totalSupply(address layer2) external view returns (uint256 amount) {
    // uint256 tlswton = getTotalLswton(layer2);
    amount = getLswtonToSwton(layer2, getTotalLswton(layer2));
  }

  function totalSupplyAt(address layer2, uint256 snapshotId) external view returns (uint256 amount) {
    // uint256 tlswton = getTotalLswton(layer2);
    amount = getLswtonToSwton(layer2, getTotalLswtonAt(layer2, snapshotId));
  }

  function totalSupply() external view returns (uint256 amount) {
    uint256 num = getL1LayersNum();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = l1layer2s[i];
      amount += getLswtonToSwton(layer2, getTotalLswton(layer2));
    }
  }

  function totalSupplyAt(uint256 snapshotId) external view returns (uint256 amount) {
    uint256 num = getL1LayersNum();
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = l1layer2s[i];
      amount += getLswtonToSwton(layer2, getTotalLswtonAt(layer2, snapshotId));
    }
  }

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
    return (amount * 1e27) / getIndex(layer2);
  }

  function getLswtonToSwton(address layer2, uint256 lswton_) public view returns (uint256) {
    if (lswton_ == 0) return 0;
    return (lswton_ * getIndex(layer2)) / 1e27;
  }

  function viewStakedInfo(address layer2, address account) public view returns (LibL2StakedInfo.StakedInfo memory) {
    return getStakedInfo(layer2, account);
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
    if (getIndex(layer2) == 0) _updateIndex(layer2, 1e27);

    if (!_l1layer2s[layer2]) {
      _l1layer2s[layer2] = true;
      l1layer2s.push(layer2);
    }
  }

  function _replace(address layer2, address account, uint256 swtonAmount) internal returns (uint256 tlswton) {

    uint256 lswton = getSwtonToLswton(layer2, swtonAmount);
    LibL2StakedInfo.StakedInfo memory info = getStakedInfo(layer2, account);
    tlswton = getTotalLswton(layer2);
    uint256 oldTlswton = tlswton;
    uint256 oldLswton = info.lswton;

    if (lswton != oldLswton) {
      if (lswton != 0) tlswton += lswton;
      if (oldLswton != 0) tlswton -= oldLswton;

      info.deposit = swtonAmount;
      info.lswton = lswton;
      _updateStakedInfo(layer2, account, info);
      // console.log('stakedInfo %s %s  ', stakedInfo[layer2][account].lswton, stakedInfo[layer2][account].deposit);
      if(oldTlswton != tlswton)  _updateTotalLswton(layer2, tlswton);

      emit Replaced(layer2, account, oldLswton, lswton, tlswton);
    }
  }

  function _valueAtLastIndex(address layer2) internal view returns (uint256 value)
  {
    uint256 len = layerIndexSnapshotIds[layer2].length;
    value = (len == 0 ? index[layer2][0]: index[layer2][layerIndexSnapshotIds[layer2][len - 1]]);
  }

  function _valueAtLastTotalLswton(address layer2) internal view returns (uint256 value)
  {
    uint256 len = layerTlswtonSnapshotIds[layer2].length;
    value = (len == 0 ? totalLswton[layer2][0]: totalLswton[layer2][layerTlswtonSnapshotIds[layer2][len - 1]]);
  }

  function _valueAtLastStakedInfo(address layer2, address account) internal view returns (LibL2StakedInfo.StakedInfo memory)
  {
    uint256 len = stakedInfoSnapshotIds[layer2][account].length;
    return (len == 0 ? stakedInfo[layer2][account][0]: stakedInfo[layer2][account][stakedInfoSnapshotIds[layer2][account][len - 1]]);
  }

  function _valueAtIndex(uint256 snapshotId, address layer2) internal view
      returns (uint256)
  {
    require(snapshotId <= progressSnapshotId(), "snapshotId > progressSnapshotId");
    uint256 snapshotIdIndex = layerIndexSnapshotIds[layer2].findValue(snapshotId);
    return layerIndexSnapshotIds[layer2][snapshotIdIndex];
  }

  function _valueAtTotalLswton(uint256 snapshotId, address layer2) internal view
      returns (uint256)
  {
    require(snapshotId <= progressSnapshotId(), "snapshotId > progressSnapshotId");
    uint256 snapshotIdIndex = layerTlswtonSnapshotIds[layer2].findValue(snapshotId);
    return totalLswton[layer2][snapshotIdIndex];
  }

  function _valueAtStakedInfo(uint256 snapshotId, address layer2, address account) internal view
      returns (LibL2StakedInfo.StakedInfo memory)
  {
    require(snapshotId <= progressSnapshotId(), "snapshotId > progressSnapshotId");
    uint256 snapshotIdIndex = stakedInfoSnapshotIds[layer2][account].findValue(snapshotId);
    return stakedInfo[layer2][account][snapshotIdIndex];
  }

  function _updateIndex(address layer2, uint256 _index) internal {
    uint256 currentId = progressSnapshotId();
    if (_lastValue(layerIndexSnapshotIds[layer2]) < currentId) layerIndexSnapshotIds[layer2].push(currentId);
    index[layer2][currentId] = _index;
  }

  function _updateTotalLswton(address layer2, uint256 _tlswton) internal {
    uint256 currentId = progressSnapshotId();
    if (_lastValue(layerTlswtonSnapshotIds[layer2]) < currentId) layerTlswtonSnapshotIds[layer2].push(currentId);
    totalLswton[layer2][currentId] = _tlswton;
  }

  function _updateStakedInfo(address layer2, address account, LibL2StakedInfo.StakedInfo memory info) internal {
    uint256 currentId = progressSnapshotId();
    if (_lastValue(stakedInfoSnapshotIds[layer2][account]) < currentId) stakedInfoSnapshotIds[layer2][account].push(currentId);
    stakedInfo[layer2][account][currentId] = info;
  }

  function _lastValue(uint256[] storage ids) internal view returns (uint256) {
      return (ids.length == 0? 0: ids[ids.length - 1]);
  }

  //////////////////////////////
  // Storage getters
  //////////////////////////////

  //=====
  function progressSnapshotId() public view returns (uint256) {
      return lastSnapshotId;
  }

  function getIndex(address layer2) public view returns (uint256)
  {
    return _valueAtLastIndex(layer2);
  }

  function getTotalLswton(address layer2) public view returns (uint256)
  {
    return _valueAtLastTotalLswton(layer2);
  }

  function getStakedInfo(address layer2, address account) public view returns (LibL2StakedInfo.StakedInfo memory)
  {
    return _valueAtLastStakedInfo(layer2, account);
  }

  function getIndexAt(address layer2, uint256 snapshotId) public view returns (uint256)
  {
    return _valueAtIndex(snapshotId, layer2);
  }

  function getTotalLswtonAt(address layer2, uint256 snapshotId) public view returns (uint256)
  {
    return _valueAtTotalLswton(snapshotId, layer2);
  }

  function getStakedInfoAt(address layer2, address account, uint256 snapshotId) public view returns (LibL2StakedInfo.StakedInfo memory)
  {
    return _valueAtStakedInfo(snapshotId, layer2, account);
  }

}
