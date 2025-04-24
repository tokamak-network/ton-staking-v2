// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract CandidateAddOnStorage1   {
    mapping(bytes4 => bool) internal _supportedInterfaces;
    bool public isLayer2Candidate;
    // address public candidate;
    string public memo;
    // address public committee;
    // address public seigManager;

    // uint256(keccak256("CANDIDATE")) - 1
    uint256 internal constant _CANDIDATE_SLOT =
        0xa62771101a79dd4b4d7b861524e85faa4569e99d6bb6b09233805dccb1ea480e;
    // uint256(keccak256("COMMITTEE")) - 1
    uint256 internal constant _COMMITTEE_SLOT =
        0xed7ead75dab2b778f814bef3e24d121e608a2464b0363d0d34b193757e18edb7;
     // uint256(keccak256("SEIGMANAGER")) - 1
    uint256 internal constant _SEIGMANAGER_SLOT =
        0x7088c9d198dd5a695a7839f4b2a2bf4569dc44d17d42047752072568a6f42416;


    function candidate() public view returns (address addr) {
        assembly {
            addr := sload(_CANDIDATE_SLOT)
        }
    }

    function committee() public view returns (address addr) {
        assembly {
            addr := sload(_COMMITTEE_SLOT)
        }
    }

    function seigManager() public view returns (address addr) {
        assembly {
            addr := sload(_SEIGMANAGER_SLOT)
        }
    }

}
