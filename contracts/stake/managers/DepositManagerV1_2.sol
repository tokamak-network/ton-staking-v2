// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISeigManager} from '../interfaces/ISeigManager.sol';
import {ILayer2Registry} from '../../dao/interfaces/ILayer2Registry.sol';

import '../../proxy/ProxyStorage.sol';
import {AccessibleCommon} from '../../common/AccessibleCommon.sol';
import {DepositManagerStorage} from './DepositManagerStorage.sol';
import {DepositManagerV1_1Storage} from './DepositManagerV1_1Storage.sol';

/**
 * @dev DepositManagerV1_2 is an upgraded version of DepositManager that adds the WithdrawalRequestCanceled event
 *      to the redeposit function. This event allows for accurate tracking of TON circulating supply by
 *      distinguishing between "fresh deposits" and "withdrawal cancellations (redeposits)".
 *      When users cancel their withdrawal requests via redeposit, both Deposited and WithdrawalRequestCanceled
 *      events are emitted, enabling precise calculation of net pending withdrawals for liquidity analysis.
 * @notice Proposal: https://github.com/tokamak-network/tokamak-dao-contracts/discussions/16
 * @notice RFC: https://github.com/tokamak-network/tokamak-dao-contracts/discussions/17
 * @notice Test Files:
 * - test/deposit-manager-v1-2-standalone.test.ts
 * - test/deposit-manager-v1-2-agenda.test.ts
 * - test/shared/depositManagerHelpers.ts
 */
contract DepositManagerV1_2 is
    ProxyStorage,
    AccessibleCommon,
    DepositManagerStorage,
    DepositManagerV1_1Storage
{

    ////////////////////
    // Modifiers
    ////////////////////

    modifier onlyLayer2(address layer2) {
      require(ILayer2Registry(_registry).layer2s(layer2), "Caller is not a Layer2");
      _;
    }


    ////////////////////
    // Events
    ////////////////////

    event Deposited(address indexed layer2, address depositor, uint256 amount);
    event WithdrawalRequestCanceled(address indexed layer2, address depositor, uint256 amount);


    ////////////////////
    // Re-deposit function
    ////////////////////

    /**
     * @dev re-deposit pending requests in the pending queue
     */

    function redeposit(address layer2) external returns (bool) {
      uint256 i = _withdrawalRequestIndex[layer2][msg.sender];
      require(_redeposit(layer2, i, 1), "fail redeposit");
      return true;
    }

    function redepositMulti(address layer2, uint256 n) external returns (bool) {
      uint256 i = _withdrawalRequestIndex[layer2][msg.sender];
      require(_redeposit(layer2, i, n), "fail redeposit");
      return true;
    }

    function _redeposit(address layer2, uint256 i, uint256 n) internal onlyLayer2(layer2) returns (bool) {
      uint256 accAmount;

      WithdrawalReqeust[] memory requsts = _withdrawalRequests[layer2][msg.sender];

      require(requsts.length > 0, "DepositManager: no request");
      require(requsts.length - i >= n, "DepositManager: n exceeds num of pending requests");

      uint256 e = i + n;
      for (; i < e; i++) {
        // WithdrawalReqeust storage r = _withdrawalRequests[layer2][msg.sender][i];
        WithdrawalReqeust memory r = requsts[i];

        uint256 amount = r.amount;

        require(!r.processed, "DepositManager: pending request already processed");
        require(amount > 0, "DepositManager: no valid pending request");

        accAmount = accAmount + amount;
        r.processed = true;
        _withdrawalRequests[layer2][msg.sender][i] = r;
      }

      // deposit-related storages
      _accStaked[layer2][msg.sender] = _accStaked[layer2][msg.sender] + accAmount;
      _accStakedLayer2[layer2] = _accStakedLayer2[layer2] + accAmount;
      _accStakedAccount[msg.sender] = _accStakedAccount[msg.sender] + accAmount;

      // withdrawal-related storages
      _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] - accAmount;
      _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] - accAmount;
      _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] - accAmount;

      _withdrawalRequestIndex[layer2][msg.sender] += n;

      emit Deposited(layer2, msg.sender, accAmount);

      // add event for withdrawal request canceled
      emit WithdrawalRequestCanceled(layer2, msg.sender, accAmount);

      require(ISeigManager(_seigManager).onDeposit(layer2, msg.sender, accAmount), "fail SeigManager.onDeposit");

      return true;
    }
}
