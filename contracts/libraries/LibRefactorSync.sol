// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import  "../stake/interfaces/IRefactor.sol";

/**
 * @title
 */
library LibRefactorSync {

    struct RefactorCoinage {
        IRefactor.Factor factor;
        IRefactor.Balance totalSupply;
        IRefactor.Balance accountBalance;
    }

    struct CoinageSyncInfo {
        address layer2;
        RefactorCoinage refactor;
        uint32 syncTime; // 동기화 시점
    }

    struct FactorSyncInfo {
        IRefactor.Factor factor;
        uint32 syncTime;
    }

    struct RefactorSyncPackets {
        address account;
        CoinageSyncInfo[] packets;
    }

}