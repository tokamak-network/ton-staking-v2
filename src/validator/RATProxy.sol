// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";
import "./RATStorage.sol";

/**
 * @title RATProxy
 * @notice RAT 컨트랙트의 프록시
 * @dev Proxy와 RATStorage를 상속하여 업그레이드 가능한 패턴 구현
 */
contract RATProxy is Proxy, RATStorage {
    // Proxy의 onlyOwner modifier와 RATStorage의 storage를 공유
    // 실제 로직은 RAT implementation에서 처리
}
