// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StorageStateCommitteeV3 {
    mapping(uint256 => string) public agendaMemo;

    // EIP-1271 관련 상태 변수들
    address public multiSigWallet; // DAO Owner (DEFAULT_ADMIN_ROLE)

    uint256 constant public threshold = 1;

    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;
    mapping(address => address) internal owners;
    mapping(bytes32 => uint256) public signedMessages;

}