// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Layer2ManagerV1_2Storage
/// @notice V3 신규 스토리지 - Bridged TON 조회 및 SequencerVault 관련
contract Layer2ManagerV1_2Storage {
    // ==========================================
    // V3 신규: Bridged TON 조회 관련
    // ==========================================

    /// @notice L2별 최신 Bridged TON (캐시, 선택적)
    mapping(address => uint256) public cachedBridgedTON;

    /// @notice L2별 마지막 업데이트 블록
    mapping(address => uint256) public lastBridgedTONUpdateBlock;

    // ==========================================
    // V3 신규: SequencerVault 관련
    // ==========================================

    /// @notice SequencerVault 주소 (TYPE 3 롤업용)
    address public sequencerVault;

    // ==========================================
    // V3 신규: 슬래싱 관련
    // ==========================================

    /// @notice 슬래싱된 DisputeGame 주소를 기록하여 중복 슬래싱 방지
    mapping(address => bool) public slashedDisputeGames;
}
