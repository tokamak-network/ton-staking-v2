// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";
import "../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../common/AuthControlSeigManager.sol";
import { L2SeigManagerStorage } from "./L2SeigManagerStorage.sol";

interface IL2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract L2SeigManager is ProxyStorage, AuthControlSeigManager, L2SeigManagerStorage, DSMath {

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
    address l1StakedTonToL2_,
    address l2messanger_
  ) external onlyOwner {
      l1StakedTonToL2 = l1StakedTonToL2_;
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
      }
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
      // 기존에 이미 데이타가 있으면 초기화하고 다시 등록하자.
    }
    return true;
  }

  function deposit(address layer2, address account, uint256 swtonAmount)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
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
    uint256 lswton = getSwtonToLswton(layer2, swtonAmount);
    LibL2StakedInfo.StakedInfo storage info = stakedInfo[layer2][account];

    require(swtonAmount <= info.deposit, 'insufficient balance');
    if (info.lswton < lswton)  info.lswton = 0;
    else info.lswton -= lswton;

    require(lswton <= totalLswton[layer2], 'insufficient');
    totalLswton[layer2] -= lswton;
    emit Unstaked(layer2, account, swtonAmount, lswton);
    return true;
  }

  function rebaseIndex(address layer2, uint256 sharePerRay)
    external
    onlyL1StakedTonInL2
    returns (bool)
  {
    uint256 totalSwton = getLswtonToSwton(layer2, totalLswton[layer2]);
    uint256 addAmount = (totalSwton * sharePerRay / 1e27);
    uint256 oldIndex = index[layer2];
    uint256 newIndex = oldIndex * (totalSwton + addAmount) / totalSwton ;

    emit RebasedIndex(layer2, sharePerRay, oldIndex, newIndex);
    return true;
  }

  //////////////////////////////
  // External functions
  //////////////////////////////

  function stakeOf(address layer2, address account) public view returns (uint256) {
      return getLswtonToSwton(layer2, stakedInfo[layer2][account].lswton);
  }

  // function stakeOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256 amount) {
  //   return _coinages[layer2].balanceOfAt(account, snapshotId);
  // }

  function stakeOf(address account) external view returns (uint256 amount) {
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

  function stakeOfTotal(address layer2) external view returns (uint256 amount) {
    amount = getLswtonToSwton(layer2, totalLswton[layer2]);
  }

  function stakeOfTotal() external view returns (uint256 amount) {
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

  function viewStakedInfo(address layer2, address account) public view returns (LibL2StakedIndex.StakedInfo memory) {
    return stakedInfo[layer2][account];
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
