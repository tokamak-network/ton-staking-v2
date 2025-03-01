// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import "./LegacySystemConfigStorage.sol";


contract LegacySystemConfig is Ownable, LegacySystemConfigStorage {

    modifier nonZero(uint256 value) {
        require(value != 0, "zero");
        _;
    }

    /* ========== onlyOwner ========== */

    function setAddresses(
        string memory _name,
        Addresses memory _addresses,
        address _l1BridgeRegistry,
        address _unsafeBlockSigner
    ) external onlyOwner {
        name = _name;
        addresses = _addresses;
        l1BridgeRegistry = _l1BridgeRegistry;
        unsafeBlockSigner = _unsafeBlockSigner;
    }

    function setUnsafeBlockSigner(address _unsafeBlockSigner) external onlyOwner {
        unsafeBlockSigner = _unsafeBlockSigner;
    }

    /* ========== onlyL1Bridge ========== */


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