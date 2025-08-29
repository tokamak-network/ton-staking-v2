// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StorageStateCommitteeV3 {
    mapping(uint256 => string) public agendaMemo;

    // EIP-1271 관련 상태 변수들
    address public multiSigWallet; // DAO Owner (DEFAULT_ADMIN_ROLE)
    mapping(bytes32 => bool) public usedSignatures; // 사용된 서명 추적
}