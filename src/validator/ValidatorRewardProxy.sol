// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";
import "./ValidatorRewardStorage.sol";

/**
 * @title ValidatorRewardProxy
 * @notice ValidatorReward 컨트랙트의 프록시
 * @dev Proxy와 ValidatorRewardStorage를 상속하여 업그레이드 가능한 패턴 구현
 */
contract ValidatorRewardProxy is Proxy, ValidatorRewardStorage {
    // Proxy의 onlyOwner modifier와 ValidatorRewardStorage의 storage를 공유
    // 실제 로직은 ValidatorRewardV1 implementation에서 처리
}
