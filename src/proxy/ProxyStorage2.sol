//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ProxyStorage2  {

    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;

}