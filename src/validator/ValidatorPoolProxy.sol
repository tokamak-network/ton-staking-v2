// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";
import "./ValidatorPoolStorage.sol";

/**
 * @title ValidatorPoolProxy
 * @notice ValidatorPool 컨트랙트의 프록시
 * @dev Proxy와 ValidatorPoolStorage를 상속하여 업그레이드 가능한 패턴 구현
 */
contract ValidatorPoolProxy is Proxy, ValidatorPoolStorage {
    // Proxy의 onlyOwner modifier와 ValidatorPoolStorage의 storage를 공유
    // 실제 로직은 ValidatorPoolV1 implementation에서 처리
}
