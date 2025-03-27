// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract CandidateAddOnStorage {
    // address public ton;
    // address public wton;

    // uint256(keccak256("TON")) - 1
    uint256 internal constant _TON_ADDRESS_SLOT =
        0x88940a795d305b6429c31402afcae61ef7d829b8a9fe2a9861b8c30cd60e80ec;
    // uint256(keccak256("WTON")) - 1
    uint256 internal constant _WTON_ADDRESS_SLOT =
        0x5fa7357c3468b094bc9c15b746af6189f046af1501ae9751f49e7b4dd5616e97;


    function ton() public view returns (address addr) {
        assembly {
            addr := sload(_TON_ADDRESS_SLOT)
        }
    }

    function wton() public view returns (address addr) {
        assembly {
            addr := sload(_WTON_ADDRESS_SLOT)
        }
    }

    function _setStorageAddress(uint256 slot, address newAddress) internal  {
        assembly {
            sstore(slot, newAddress)
        }
    }
}
