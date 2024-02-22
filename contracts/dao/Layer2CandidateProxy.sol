// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";
import "./CandidateStorage.sol";
import "./Layer2CandidateStorage.sol";

/**
 * @title Layer2CandidateProxy
 * @dev
 */
contract Layer2CandidateProxy is Proxy, CandidateStorage, Layer2CandidateStorage {

}
