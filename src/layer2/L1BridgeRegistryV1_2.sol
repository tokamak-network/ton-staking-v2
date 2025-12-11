// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "../stake/interfaces/IERC20.sol";
import {IOptimismSystemConfig} from "../layer2/interfaces/IOptimismSystemConfig.sol";

import "../proxy/ProxyStorage.sol";

/// @notice Layer2Manager V3 인터페이스 (updateBridgedTON 추가)
interface ILayer2ManagerV3 {
    function updateBridgedTON(address rollupConfig) external;
}
import {AuthControlL1BridgeRegistry} from "../common/AuthControlL1BridgeRegistry.sol";
import "./L1BridgeRegistryStorage.sol";
import "./L1BridgeRegistryV1_2Storage.sol";

/**
 * @title L1BridgeRegistryV1_2
 * @notice TON Staking V3 - Bridged TON 변경 감지 및 Layer2Manager 알림 기능
 * @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
 *
 * V1_1 대비 변경사항:
 * - layer2TVL 조회 시 TVL 변경 감지 및 Layer2Manager.updateBridgedTON 호출
 * - 프록시에서 이 함수만 새 로직으로 매핑하면 됨
 */
contract L1BridgeRegistryV1_2 is
    ProxyStorage,
    AuthControlL1BridgeRegistry,
    L1BridgeRegistryStorage,
    L1BridgeRegistryV1_2Storage
{
    // ==========================================
    // Events
    // ==========================================

    /// @notice TVL 변경 감지 이벤트
    event TVLChanged(
        address indexed rollupConfig,
        uint256 oldTVL,
        uint256 newTVL,
        address indexed bridgeOrPortal
    );

    // ==========================================
    // Public Functions - 수정된 함수들
    // ==========================================

    /**
     * @notice View the liquidity of Layer2 TON for a specific rollupConfig.
     *         TVL이 변경되면 Layer2Manager에 알림
     * @param rollupConfig the rollupConfig address
     * @dev 이 함수는 V1_1의 layer2TVL을 대체함
     */
    function layer2TVL(address rollupConfig) public returns (uint256 amount) {
        uint8 _type = rollupInfo[rollupConfig].rollupType;
        address targetAddress;

        if (_type == 1) {
            // Legacy Optimism (l1StandardBridge)
            targetAddress = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
            if (l1Bridge[targetAddress]) {
                amount = IERC20(ton).balanceOf(targetAddress);
            }
        } else if (_type == 2) {
            // Bedrock Optimism (optimismPortal)
            targetAddress = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (portal[targetAddress]) {
                amount = IERC20(ton).balanceOf(targetAddress);
            }
        }

        // TVL 변경 감지 및 Layer2Manager 알림
        if (targetAddress != address(0)) {
            uint256 lastTVL = lastKnownTVL[targetAddress];

            if (amount != lastTVL) {
                // TVL 변경됨 - 캐시 업데이트
                lastKnownTVL[targetAddress] = amount;
                lastTVLUpdateBlock[targetAddress] = block.number;

                emit TVLChanged(rollupConfig, lastTVL, amount, targetAddress);

                // Layer2Manager에 Bridged TON 변경 알림
                if (layer2Manager != address(0)) {
                    // Layer2Manager.updateBridgedTON은 SeigManager.onBridgedTONChange를 호출
                    try ILayer2ManagerV3(layer2Manager).updateBridgedTON(rollupConfig) {
                        // 성공
                    } catch {
                        // 실패해도 계속 진행 (view 함수 호환성 유지)
                    }
                }
            }
        }
    }

    /**
     * @notice View only 버전 (상태 변경 없음)
     * @param rollupConfig the rollupConfig address
     */
    function layer2TVLView(address rollupConfig) public view returns (uint256 amount) {
        uint8 _type = rollupInfo[rollupConfig].rollupType;

        if (_type == 1) {
            address l1Bridge_ = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
            if (l1Bridge[l1Bridge_]) amount = IERC20(ton).balanceOf(l1Bridge_);
        } else if (_type == 2) {
            address optimismPortal_ = IOptimismSystemConfig(rollupConfig).optimismPortal();
            if (portal[optimismPortal_]) amount = IERC20(ton).balanceOf(optimismPortal_);
        }
    }

    /**
     * @notice 마지막으로 알려진 TVL 조회
     * @param rollupConfig the rollupConfig address
     */
    function getLastKnownTVL(address rollupConfig) external view returns (uint256 tvl, uint256 updateBlock) {
        uint8 _type = rollupInfo[rollupConfig].rollupType;
        address targetAddress;

        if (_type == 1) {
            targetAddress = IOptimismSystemConfig(rollupConfig).l1StandardBridge();
        } else if (_type == 2) {
            targetAddress = IOptimismSystemConfig(rollupConfig).optimismPortal();
        }

        if (targetAddress != address(0)) {
            tvl = lastKnownTVL[targetAddress];
            updateBlock = lastTVLUpdateBlock[targetAddress];
        }
    }

    /**
     * @notice 명시적으로 Bridged TON 업데이트 트리거
     * @param rollupConfig the rollupConfig address
     * @dev 누구나 호출 가능 (permissionless update)
     */
    function triggerBridgedTONUpdate(address rollupConfig) external {
        uint8 _type = rollupInfo[rollupConfig].rollupType;
        require(_type != 0, "NotRegistered");

        // layer2TVL 호출하면 자동으로 변경 감지 및 알림
        layer2TVL(rollupConfig);
    }

    /**
     * @notice 여러 rollupConfig의 Bridged TON 일괄 업데이트
     * @param rollupConfigs rollupConfig 주소 배열
     */
    function batchUpdateBridgedTON(address[] calldata rollupConfigs) external {
        for (uint256 i = 0; i < rollupConfigs.length; i++) {
            uint8 _type = rollupInfo[rollupConfigs[i]].rollupType;
            if (_type != 0) {
                layer2TVL(rollupConfigs[i]);
            }
        }
    }
}

