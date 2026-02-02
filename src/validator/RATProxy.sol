// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/Proxy.sol";

/**
 * @title RATProxy
 * @notice ETH 수신이 가능한 Proxy
 * @dev Proxy.sol을 상속받아 receive() 함수만 오버라이드
 * @dev Fast Withdrawal 수수료 등 ETH를 받아야 하는 컨트랙트에 사용
 */
contract RATProxy is Proxy {
    /// @notice ETH 수신 허용
    receive() external payable override {}
}
