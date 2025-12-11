// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title DepositManagerV1_2Storage
/// @notice V3 신규 스토리지 - onStakingChange 콜백 관련
contract DepositManagerV1_2Storage {
    // ==========================================
    // V3 신규: SeigManager 콜백 설정
    // ==========================================

    /// @notice V3 스테이킹 변경 콜백 활성화 여부
    bool public v3CallbackEnabled;
}
