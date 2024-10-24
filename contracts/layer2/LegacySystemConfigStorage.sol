// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LegacySystemConfigStorage {

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

    address public proxyOwner;

    Addresses public addresses;
    // address public l2Ton;
    string public name;

    address public l1BridgeRegistry;

}
