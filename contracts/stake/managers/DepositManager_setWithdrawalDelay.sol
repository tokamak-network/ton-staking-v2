// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";
interface ILayer2 {
  function operator() external view returns (address);
}

/**
 * @dev DepositManager_setWithdrawalDelay Modify setWithdrawalDelay function
 *      https://github.com/tokamak-network/ton-staking-v2/issues/33
 */
contract DepositManager_setWithdrawalDelay is ProxyStorage, AccessibleCommon, DepositManagerStorage {

    uint256 public constant MAX_DELAY_BLOCKS =  216000; // 60*60*24*30/12 = 216000 (1 block = 12 sec)

    /**
     * @notice Event that occurs when calling the setWithdrawalDelay function
     * @param layer2              The layer2 address
     * @param withdrawalDelay_    The number of withdrawal delay blocks
     */
    event SetWithdrawalDelay(address indexed layer2, uint256 withdrawalDelay_);

    /**
     * @notice Event that occurs when calling the setWithdrawalDelayByOwner function
     * @param layer2              The layer2 address
     * @param withdrawalDelay_    The number of withdrawal delay blocks
     */
    event SetWithdrawalDelayByOwner(address indexed layer2, uint256 withdrawalDelay_);

    /**
     * @dev The operator of that layer can set the withdrawal delay block to be greater than the global delay block or less than one month.
     * @param l2chain               The layer2 address
     * @param withdrawalDelay_      The number of withdrawal delay blocks
    */
    function setWithdrawalDelay(address l2chain, uint256 withdrawalDelay_) external {
        require(_isOperator(l2chain, msg.sender));
        require(withdrawalDelay_ > globalWithdrawalDelay && withdrawalDelay_ <= MAX_DELAY_BLOCKS, "Not acceptable");

        withdrawalDelay[l2chain] = withdrawalDelay_;
        emit SetWithdrawalDelay(l2chain, withdrawalDelay_);
    }

    /**
     * @dev The administrator can set a withdrawal delay block.
     * @param l2chain               The layer2 address
     * @param withdrawalDelay_      The number of withdrawal delay blocks
    */
    function setWithdrawalDelayByOwner(address l2chain, uint256 withdrawalDelay_) external onlyOwner {
        withdrawalDelay[l2chain] = withdrawalDelay_;
        emit SetWithdrawalDelayByOwner(l2chain, withdrawalDelay_);
    }

    function _isOperator(address layer2, address operator) internal view returns (bool) {
        return operator == ILayer2(layer2).operator();
    }
}