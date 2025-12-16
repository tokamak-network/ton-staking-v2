// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IIDAOCommittee} from "../dao/interfaces/IIDAOCommittee.sol";
import {IOperatorManagerFactory} from "../layer2/interfaces/IOperatorManagerFactory.sol";
import {IL1BridgeRegistry} from "../layer2/interfaces/IL1BridgeRegistry.sol";
import {IOptimismSystemConfig} from "../layer2/interfaces/IOptimismSystemConfig.sol";
import {IOptimismPortal} from "../layer2/interfaces/IOptimismPortal.sol";
import {IStandardBridge} from "../layer2/interfaces/IStandardBridge.sol";
import {IOperator} from "../layer2/interfaces/IOperator.sol";
import {IIDepositManager} from "../stake/interfaces/IIDepositManager.sol";
import {ISeigManager} from "../stake/interfaces/ISeigManager.sol";
import {ISeigManagerV3} from "../stake/interfaces/ISeigManagerV3.sol";
import {ITON} from "../stake/interfaces/ITON.sol";
import {IWTON} from "../stake/interfaces/IWTON.sol";

import "./Layer2ManagerStorage.sol";
import "./Layer2ManagerV1_2Storage.sol";
import "../proxy/ProxyStorage.sol";
import {AccessibleCommon} from "../common/AccessibleCommon.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";

/**
 * @title Layer2ManagerV1_2
 * @notice TON Staking V3 Layer2 Manager - Bridged TON 조회 기능 추가
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 *      다중 구현체 패턴 - V1_1의 추가 함수만 포함 (Selector Routing)
 */
contract Layer2ManagerV1_2 is ProxyStorage, AccessibleCommon, Layer2ManagerStorage, Layer2ManagerV1_2Storage {
    using SafeERC20 for IERC20;

    // ==========================================
    // V3 신규: Bridged TON 조회
    // ==========================================

    /// @notice L2의 Bridged TON 조회
    /// @param layer2 L2 주소
    /// @return bridgedTON Bridged TON 양 (TON 단위)
    function getBridgedTONByLayer(address layer2) public view returns (uint256 bridgedTON) {
        address operator = operatorOfLayer[layer2];
        if (operator == address(0)) return 0;
        address rollupConfig = operatorInfo[operator].rollupConfig;
        if (rollupConfig == address(0)) return 0;
        return _getBridgedTON(rollupConfig);
    }

    /// @notice Bridged TON 조회 (rollupConfig로)
    /// @param rollupConfig RollupConfig 주소
    /// @return bridgedTON Bridged TON 양 (TON 단위)
    function getBridgedTON(address rollupConfig) public view returns (uint256 bridgedTON) {
        return _getBridgedTON(rollupConfig);
    }

    /// @notice SystemConfig(rollupConfig) 주소로 Layer2 주소 조회
    /// @param systemConfig SystemConfig 컨트랙트 주소
    /// @return layer2 해당 Layer2 주소 (없으면 address(0))
    function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2) {
        address operatorManager = rollupConfigInfo[systemConfig].operatorManager;
        if (operatorManager == address(0)) return address(0);
        return operatorInfo[operatorManager].candidateAddOn;
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /// @notice Bridged TON 내부 조회 함수
    /// @dev L1BridgeRegistry.layer2TVL 사용 (타입별 bridge/portal 조회 로직 포함)
    function _getBridgedTON(address rollupConfig) internal view returns (uint256 bridgedTON) {
        bridgedTON = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
    }
}
