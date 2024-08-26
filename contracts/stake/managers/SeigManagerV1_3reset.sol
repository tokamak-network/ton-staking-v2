// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DSMath } from "../../libraries/DSMath.sol";
import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { Layer2I } from "../../dao/interfaces/Layer2I.sol";

import "../../proxy/ProxyStorage.sol";
import { AuthControlSeigManager } from "../../common/AuthControlSeigManager.sol";
import { SeigManagerStorage } from "./SeigManagerStorage.sol";
import { SeigManagerV1_1Storage } from "./SeigManagerV1_1Storage.sol";
import { SeigManagerV1_3Storage } from "./SeigManagerV1_3Storage.sol";


contract SeigManagerV1_3reset is ProxyStorage, AuthControlSeigManager, SeigManagerStorage, SeigManagerV1_1Storage, DSMath, SeigManagerV1_3Storage {

  /// @dev
  function reset() external onlyOwner {
    l2Registry = address(0);
    layer2Manager = address(0);
    layer2StartBlock = 0;
    totalLayer2TVL = 0;
    l2RewardPerUint = 0;
    totalLayer2TVL = 0;
  }

}
