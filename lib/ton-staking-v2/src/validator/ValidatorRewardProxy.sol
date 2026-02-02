// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title ValidatorRewardProxy
 * @notice ValidatorReward 컨트랙트의 프록시
 * @dev OpenZeppelin TransparentUpgradeableProxy 사용
 * @dev ERC1967 storage slot을 사용하여 implementation storage와 충돌 방지
 */
contract ValidatorRewardProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
