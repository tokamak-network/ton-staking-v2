// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title L1BridgeRegistryV1_2Storage
/// @notice V3 신규 스토리지 변수
contract L1BridgeRegistryV1_2Storage {
    /// @notice 브리지/포탈별 마지막 알려진 TVL
    mapping(address => uint256) public lastKnownTVL;

    /// @notice 브리지/포탈별 마지막 업데이트 블록
    mapping(address => uint256) public lastTVLUpdateBlock;
}
