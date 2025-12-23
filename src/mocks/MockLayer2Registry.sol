// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ILayer2Registry } from "../dao/interfaces/ILayer2Registry.sol";

contract MockLayer2Registry is ILayer2Registry {
    mapping(address => bool) public layer2s;
    address[] public layer2List;

    function register(address layer2) external override returns (bool) {
        if (!layer2s[layer2]) {
            layer2s[layer2] = true;
            layer2List.push(layer2);
        }
        return true;
    }

    function numLayer2s() external view override returns (uint256) {
        return layer2List.length;
    }

    function layer2ByIndex(uint256 index) external view override returns (address) {
        return layer2List[index];
    }

    function deployCoinage(address layer2, address seigManager) external override returns (bool) {
        return true;
    }

    function registerAndDeployCoinage(address layer2, address seigManager) external override returns (bool) {
        layer2s[layer2] = true;
        return true;
    }

    function unregister(address layer2) external override returns (bool) {
        layer2s[layer2] = false;
        return true;
    }
}
