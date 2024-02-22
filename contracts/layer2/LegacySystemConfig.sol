// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract LegacySystemConfig is Ownable {

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
    address public l2Ton;
    uint64 public gasLimit;
    string public name;

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    /* ========== onlyOwner ========== */

    function setAddresses(string memory _name, Addresses memory _addresses, address _l2Ton) external onlyOwner {
        name = _name;
        addresses = _addresses;
        l2Ton = _l2Ton;
    }

    function setGasLimit(uint64 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
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
