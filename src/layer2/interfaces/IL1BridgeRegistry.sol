// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IL1BridgeRegistry {
    /// @notice Rollup configuration types
    /// @dev 0: NONE (empty), 1: LEGARCY (optimism legacy), 2: OPTIMISM_BEDROCK (native TON), 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
    enum TYPE_ROLLUPCONFIG {
        NONE,
        LEGARCY,
        OPTIMISM_BEDROCK,
        OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
    }

    function getRollupInfo(address rollupConfig) external view returns (
        uint8   rollupType,
        address l2Ton,
        bool    rejectedSeigs,
        bool    rejectedL2Deposit,
        string  memory name
    );
    function registeredNames(bytes32 byteName) external view returns (bool);
    function l2Ton(address rollupConfig) external view returns (address);
    function rollupType(address rollupConfig) external view returns (uint8);
    function checkLayer2Tvl(address _rollupConfig) external view returns (bool result, uint256 amount);
    function layer2Tvl(address _rollupConfig) external view returns (uint256 amount);

    /// @notice DisputeGameFactory => rollupConfig 역방향 매핑
    /// @dev RAT에서 factory 검증 시 사용
    function rollupConfigWithDisputeGameFactory(address factory) external view returns (address rollupConfig);

    /// @notice Portal => rollupConfig 역방향 매핑
    /// @dev SeigManager.onBridgedTONChange에서 호출자 검증 시 사용
    function rollupConfigWithPortal(address portal) external view returns (address rollupConfig);
}