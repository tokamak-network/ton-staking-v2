// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title
 */
library LibL1StakedInfo {

    struct L1Staked {
        uint32 syncTime;
        uint256 balanceFactor;
        uint256 factor;
        uint256 stakedAmount;
    }

    struct L1StakedPacket {
        address layer;
        uint256 stakedAmount;
    }
}