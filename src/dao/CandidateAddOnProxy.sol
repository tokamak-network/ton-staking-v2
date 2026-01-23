// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";
import "./CandidateAddOnStorage1.sol";
import "./CandidateAddOnStorage.sol";

/**
 * @title CandidateAddOnProxy
 * @dev Storage changed from CandidateStorage to CandidateAddOnStorage1 to match
 *      CandidateAddOnV1_1 implementation storage layout (fixes storage collision issue #311)
 */
contract CandidateAddOnProxy is Proxy, CandidateAddOnStorage1, CandidateAddOnStorage {

}