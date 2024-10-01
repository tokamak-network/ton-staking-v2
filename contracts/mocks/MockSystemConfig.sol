// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MockL1StandardBridge {
    constructor() {}
    receive() external payable {
        revert("cannot receive Ether");
    }
}

contract MockOptimismPortal {
    constructor() {}
    receive() external payable {
        revert("cannot receive Ether");
    }
}


contract MockSystemConfig {

    /// @notice Struct representing the addresses of L1 system contracts. These should be the
    ///         proxies and will differ for each OP Stack chain.
    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address l2OutputOracle;
        address optimismPortal;
        address optimismMintableERC20Factory;
    }

    Addresses public addresses;
    // address public l2Ton;
    string public name;

    /* ========== CONSTRUCTOR ========== */
    constructor(string memory _name) {
        name = _name;

        addresses = Addresses(
            address(0),
            address(0),
            address(new MockL1StandardBridge()),
            address(0),
            address(new MockOptimismPortal()),
            address(0)
        );
    }
    receive() external payable {
        revert("cannot receive Ether");
    }

    /* ========== view ========== */

    function l1CrossDomainMessenger() external view returns (address addr_) {
        addr_ = addresses.l1CrossDomainMessenger;
    }

    function l1ERC721Bridge() external view returns (address addr_) {
        addr_ = addresses.l1ERC721Bridge;
    }

    function l1StandardBridge() external view returns (address addr_) {
        addr_ = addresses.l1StandardBridge;
    }

    function l2OutputOracle() external view returns (address addr_) {
        addr_ = addresses.l2OutputOracle;
    }

    function optimismPortal() external view returns (address addr_) {
        addr_ = addresses.optimismPortal;
    }

    function optimismMintableERC20Factory() external view returns (address addr_) {
        addr_ = addresses.optimismMintableERC20Factory;
    }

}
