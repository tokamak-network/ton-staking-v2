// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICandidateAddOn {
    function initialize(
        address _candidate,
        string memory _memo,
        address _committee,
        address _seigManager,
        address _ton,
        address _wton
    ) external;
}

