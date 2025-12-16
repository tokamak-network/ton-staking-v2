// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title L1BridgeRegistryV1_2Storage
/// @notice V3 신규 스토리지 변수
contract L1BridgeRegistryV1_2Storage {
    /// @notice rollupConfig => DisputeGameFactory 등록여부
    /// @dev RAT에서 triggerAttentionTest 호출 시 factory 검증용
    mapping(address => bool) public disputeGameFactory;

    /// @notice DisputeGameFactory => rollupConfig
    mapping(address => address) public rollupConfigWithDisputeGameFactory;

    /// @notice portal => rollupConfig
    mapping(address => address) public rollupConfigWithPortal;
}
