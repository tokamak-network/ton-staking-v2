// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ILayer2 } from "../../dao/interfaces/ILayer2.sol";
import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";

/**
 * @dev DepositManager_setWithdrawalDelay Modify setWithdrawalDelay function
 *      https://github.com/tokamak-network/ton-staking-v2/issues/33
 */
contract DepositManager_setWithdrawalDelay is ProxyStorage, AccessibleCommon, DepositManagerStorage {

    uint256 public constant MAX_DELAY_BLOCKS =  216_000; // 60*60*24*30/12 = 216000 (1 block = 12 sec)

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
     * @param layer2               The layer2 address
     * @param withdrawalDelay_      The number of withdrawal delay blocks
    */
    function setWithdrawalDelay(address layer2, uint256 withdrawalDelay_) external {
        require(_isOperator(layer2, msg.sender));
        require(withdrawalDelay_ > globalWithdrawalDelay && withdrawalDelay_ <= MAX_DELAY_BLOCKS, "Not acceptable");

        withdrawalDelay[layer2] = withdrawalDelay_;
        emit SetWithdrawalDelay(layer2, withdrawalDelay_);
    }

    /**
     * @dev The administrator can set a withdrawal delay block.
     * @param layer2               The layer2 address
     * @param withdrawalDelay_      The number of withdrawal delay blocks
    */
    function setWithdrawalDelayByOwner(address layer2, uint256 withdrawalDelay_) external onlyOwner {
        require(globalWithdrawalDelay < withdrawalDelay_, "wrong withdrawalDelay");
        withdrawalDelay[layer2] = withdrawalDelay_;
        emit SetWithdrawalDelayByOwner(layer2, withdrawalDelay_);
    }

    function _isOperator(address layer2, address operator) internal view returns (bool) {
        return operator == ILayer2(layer2).operator();
    }
}