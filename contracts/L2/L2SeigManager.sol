// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";
import { LibL2StakedInfo } from "../libraries/LibL2StakedInfo.sol";

import "../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../common/AuthControlSeigManager.sol";
import { L2SeigManagerStorage } from "./L2SeigManagerStorage.sol";

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
  event Unstaked(address layer2, address account, uint256 swtonAmount, uint256 lswton);
  event RebasedIndex(address layer2, uint256 sharePerRay, uint256 oldIndex, uint256 newIndex);

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

  //////////////////////////////
  // onlyL1StakedTonInL2
  //////////////////////////////
  function _checkLayer(address layer2) internal ifFree {
      if (!_l1layer2s[layer2]) {
          _l1layer2s[layer2] = true;
          _l1layer2ByIndex[_numLayer2s] = layer2;
          _numLayer2s++;
          if (index[layer2] == 0)  index[layer2] = 1e27;
      }
  }

  function _replace(address layer2, address account, uint256 swtonAmount) internal {
    uint256 lswton = getSwtonToLswton(layer2, swtonAmount);
    LibL2StakedInfo.StakedInfo storage info = stakedInfo[layer2][account];
    uint256 oldLswton = info.lswton;
    info.deposit = swtonAmount;
    info.lswton = lswton;
    totalLswton[layer2] = totalLswton[layer2] - oldLswton + lswton;
  }


  function register(address account, LibL1StakedInfo.L1StakedPacket[] memory packets)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    require(packets.length != 0, "no packets");
    uint256 num = packets.length;
    for (uint256 i; i < num; i++) {
      address layer2 = packets[i].layer;
      _checkLayer(layer2);
      _replace(layer2, account, packets[i].stakedAmount);
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

  function unstaking(address layer2, address account, uint256 swtonAmount)
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

    emit Unstaked(layer2, account, swtonAmount, lswton);
    return true;
  }

  function rebaseIndex(address layer2, uint256 sharePerRay)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    _checkLayer(layer2);
    uint256 totalSwton = getLswtonToSwton(layer2, totalLswton[layer2]);

    uint256 addAmount = (totalSwton * sharePerRay / 1e27);
    uint256 oldIndex = index[layer2];
    uint256 newIndex = oldIndex * (totalSwton + addAmount) / totalSwton ;
    index[layer2] = newIndex;

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
    uint256 num = _numLayer2s;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = _l1layer2ByIndex[i];
      amount += getLswtonToSwton(layer2, stakedInfo[layer2][account].lswton);
    }
  }

  // function stakeOfAt(address account, uint256 snapshotId) external view returns (uint256 amount) {
  //   uint256 num = _numLayer2s;
  //   for (uint256 i = 0 ; i < num; i++){
  //     amount += _coinages[_l1layer2ByIndex[i]].balanceOfAt(account, snapshotId);
  //   }
  // }

  function totalSupply(address layer2) external view returns (uint256 amount) {
    amount = getLswtonToSwton(layer2, totalLswton[layer2]);
  }

  function totalSupply() external view returns (uint256 amount) {
    uint256 num = _numLayer2s;
    for (uint256 i = 0 ; i < num; i++){
      address layer2 = _l1layer2ByIndex[i];
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

  //////////////////////////////
  // Storage getters
  //////////////////////////////

  //=====
  function progressSnapshotId() public view returns (uint256) {
      return lastSnapshotId;
  }

}
