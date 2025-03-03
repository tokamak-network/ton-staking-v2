// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import '../../proxy/ProxyStorage.sol';
import {AuthControlSeigManager} from '../../common/AuthControlSeigManager.sol';
import {SeigManagerStorage} from './SeigManagerStorage.sol';
import {SeigManagerV1_1Storage} from './SeigManagerV1_1Storage.sol';
import {SeigManagerV1_3Storage} from './SeigManagerV1_3Storage.sol';

contract SeigManagerV1_4 is
    ProxyStorage,
    AuthControlSeigManager,
    SeigManagerStorage,
    SeigManagerV1_1Storage,
    SeigManagerV1_3Storage
{

    event SetMaxLoopCount(uint256 _maxLoopCount);

    //////////////////////////////
    // onlyOwner
    //////////////////////////////

    /**
     * @notice Set the layer2Manager address
     * @param layer2Manager_    the layer2Manager address
     */
    function setLayer2Manager(address layer2Manager_) external onlyOwner {
        layer2Manager = layer2Manager_;
    }

    /**
     * @notice Set the start block number of issuing a l2 seigniorage
     * @param startBlock_    the start block number
     */
    function setLayer2StartBlock(uint256 startBlock_) external onlyOwner {
        layer2StartBlock = startBlock_;
    }

    /**
     * @notice Set the l1BridgeRegistry_ address
     * @param l1BridgeRegistry_    the l1BridgeRegistry address
     */
    function setL1BridgeRegistry(address l1BridgeRegistry_) external onlyOwner {
        l1BridgeRegistry = l1BridgeRegistry_;
    }


    /**
     * @notice Sets the maximum number of settlement commits
     * @param _maxLoopCount    Sets the maximum number of settlement commits in the _unsettledLayer2Reward settlement function.
     *                         If maxLoopCount not set or zero, the MAX_LOOP_COUNT value is used as the maximum number of settlement commits.
     */
    function setMaxLoopCount(uint256 _maxLoopCount) external onlyOwner {
        require(maxLoopCount != _maxLoopCount, "same");
        maxLoopCount = _maxLoopCount;
        emit SetMaxLoopCount(_maxLoopCount);
    }



}
