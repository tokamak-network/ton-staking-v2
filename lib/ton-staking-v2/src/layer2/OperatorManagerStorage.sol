// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/// @title
/// @notice
contract OperatorManagerStorage {
    // address public rollupConfig;
    // address public layer2Manager;
    // address public depositManager;
    // address public ton;
    // address public wton;
    // address public manager;

      // uint256(keccak256("TON")) - 1
    uint256 internal constant _TON_ADDRESS_SLOT =
        0x88940a795d305b6429c31402afcae61ef7d829b8a9fe2a9861b8c30cd60e80ec;
    // uint256(keccak256("WTON")) - 1
    uint256 internal constant _WTON_ADDRESS_SLOT =
        0x5fa7357c3468b094bc9c15b746af6189f046af1501ae9751f49e7b4dd5616e97;
    // uint256(keccak256("DEPOSIT_MANAGER")) - 1
    uint256 internal constant _DEPOSIT_MANAGER_ADDRESS_SLOT =
        0x6ab12bb59b8ea07c1cc11427fce17c9e354c419041651472a04b9843d34380a9;
    // uint256(keccak256("LAYER2_MANAGER")) - 1
    uint256 internal constant _LAYER2_MANAGER_ADDRESS_SLOT =
        0x1e5e236e704b4589753ab620fd23d3321a80f8eee20526988a54214ac5af8eed;
    // uint256(keccak256("ROLLUP_CONFIG")) - 1
    uint256 internal constant _ROLLUP_CONFIG_SLOT =
        0xd8bedf058aa85a36377d4cf75d156448984f1301b93d1653448986b1166437d6;
    // uint256(keccak256("MANAGER")) - 1
    uint256 internal constant _MANAGER_SLOT =
        0xaf290d8680820aad922855f39b306097b20e28774d6c1ad35a20325630c3a02b;

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


    function depositManager() public view returns (address addr) {
        assembly {
            addr := sload(_DEPOSIT_MANAGER_ADDRESS_SLOT)
        }
    }


    function layer2Manager() public view returns (address addr) {
        assembly {
            addr := sload(_LAYER2_MANAGER_ADDRESS_SLOT)
        }
    }

    function rollupConfig() public view returns (address addr) {
        assembly {
            addr := sload(_ROLLUP_CONFIG_SLOT)
        }
    }

    function manager() public view returns (address addr) {
        assembly {
            addr := sload(_MANAGER_SLOT)
        }
    }

    function _setStorageAddress(uint256 slot, address newAddress) internal  {
        assembly {
            sstore(slot, newAddress)
        }
    }

    modifier onlyManager() {
        require(msg.sender == manager(), "not manager");
        _;
    }

    modifier nonZeroAddress(address addr) {
        require(addr != address(0), "zero address");
        _;
    }


}