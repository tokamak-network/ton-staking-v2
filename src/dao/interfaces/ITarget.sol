// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITarget {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function setSeigManager(address _seigManager) external;
    function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) external;
    function addMinter(address account) external;
    function upgradeTo(address logic) external;
    function setTON(address tonAddr) external;
    function setWTON(address wtonAddr) external;
    function setBurntAmountAtDAO(uint256 _burntAmountAtDAO) external;
    function setLayer2Manager(address layer2Manager_) external;
    function setL1BridgeRegistry(address l1BridgeRegistry_) external;
    function setLayer2StartBlock(uint256 startBlock_) external;
    function setImplementation2(address newImplementation, uint256 index, bool alive) external;
    function setSelectorImplementations2(
        bytes4[] calldata _selectors,
        address _imp
    ) external;
}