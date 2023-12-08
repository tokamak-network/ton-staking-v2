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

    struct CoinageSyncPacket{
        address layer2;
        RefactorCoinage refactor;
    }

    struct CoinageSyncPackets {
        uint32 syncTime;
        CoinageSyncPacket[] layerRefactors;
    }


}