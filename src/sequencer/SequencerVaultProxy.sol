// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";
import "./SequencerVaultStorage.sol";

/**
 * @title SequencerVaultProxy
 * @notice SequencerVault 컨트랙트의 프록시
 * @dev Proxy와 SequencerVaultStorage를 상속하여 업그레이드 가능한 패턴 구현
 */
contract SequencerVaultProxy is Proxy, SequencerVaultStorage {
    // Proxy의 onlyOwner modifier와 SequencerVaultStorage의 storage를 공유
    // 실제 로직은 SequencerVault implementation에서 처리
}
