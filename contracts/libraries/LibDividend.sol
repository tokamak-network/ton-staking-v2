// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title LibDividend
 */
library LibDividend {

    struct Distribution {
        bool exists;
        uint256 totalDistribution;
        uint256 lastBalance;
    }
}