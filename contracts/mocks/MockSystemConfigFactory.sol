// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { MockSystemConfig } from "./MockSystemConfig.sol";

/**
 * @notice  Error in createOperatorManager function
 * @param x 1: sender is not Layer2Manager
 *          2: zero rollupConfig's owner
 *          3: already created Operator
 */
error CreateError(uint x);

interface IMockSystemConfig {
    function l1StandardBridge() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_);
    function setName(string calldata _name) external ;
}

contract MockSystemConfigFactory {

    /**
     * @notice Event occurred when creating the OperatorManager Contract
     * @param mockSystemConfig      the mockSystemConfig address
     * @param l1StandardBridge      the l1StandardBridge address
     * @param optimismPortal        the optimismPortal address
     * @param name                  the name address
     */
    event CreatedMockSystemConfig(
        address mockSystemConfig,
        address l1StandardBridge,
        address optimismPortal,
        string name);

    constructor() { }


    function createMockSystemConfig(string calldata _name)
        external
        returns (
            address mockSystemConfig,
            address l1StandardBridge,
            address optimismPortal
            )
    {
        MockSystemConfig c = new MockSystemConfig();
        require(address(c) != address(0), "zero MockSystemConfig");
        c.setName(_name);
        c.setTargetOwner(c.optimismPortal(), msg.sender);
        c.transferOwnership(msg.sender);

        emit CreatedMockSystemConfig(
            address(c),
            c.l1StandardBridge(),
            c.optimismPortal(),
            _name
            );

        return (
            address(c),
            c.l1StandardBridge(),
            c.optimismPortal()
        );
    }

    function getAddress(address _mockSystemConfig)
        external view
        returns (
            address l1StandardBridge,
            address optimismPortal
            )
    {

        return (
            IMockSystemConfig(_mockSystemConfig).l1StandardBridge(),
            IMockSystemConfig(_mockSystemConfig).optimismPortal()
        );
    }

}

