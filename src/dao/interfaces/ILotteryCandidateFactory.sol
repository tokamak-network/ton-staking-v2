// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILotteryCandidateFactory {
    function deploy(
        address _sender,
        bool _isLayer2Candidate,
        string memory _name,
        address _committee,
        address _seigManager
    ) external returns (address);
}
