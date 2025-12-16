// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title DepositManagerV1_2Storage
/// @notice V1_2 스토리지 - 미래 확장을 위한 예약 슬롯
contract DepositManagerV1_2Storage {
    // 예약된 슬롯 (향후 확장용)
    uint256[50] private __gap;
}
