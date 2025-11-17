// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICandidateAddOnFactory {
   function deploy(
        address _sender,
        string memory _name,
        address _committee,
        address _seigManager
    )
        external
        returns (address);
}