// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Layer2ManagerV1_2Storage
/// @notice V3 신규 스토리지 - Bridged TON 조회
contract Layer2ManagerV1_2Storage {
    // ==========================================
    // V3 신규: Bridged TON 조회 관련
    // ==========================================

    /// @notice L2별 최신 Bridged TON (캐시, 선택적)
    mapping(address => uint256) public cachedBridgedTON;

    /// @notice L2별 마지막 업데이트 블록
    mapping(address => uint256) public lastBridgedTONUpdateBlock;
}
