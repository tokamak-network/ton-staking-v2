// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";
import "./CandidateStorage.sol";
import "./CandidateAddOnStorage.sol";

/**
 * @title CandidateAddOnProxy
 * @dev
 */
contract CandidateAddOnProxy is Proxy, CandidateStorage, CandidateAddOnStorage {

}
