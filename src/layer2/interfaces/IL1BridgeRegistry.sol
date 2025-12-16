// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IL1BridgeRegistry {

    function getRollupInfo(address rollupConfig) external view returns (
        uint8   rollupType,
        address l2TON,
        bool    rejectedSeigs,
        bool    rejectedL2Deposit,
        string  memory name
    );
    function registeredNames(bytes32 byteName) external view returns (bool);
    function l2TON(address rollupConfig) external view returns (address);
    function rollupType(address rollupConfig) external view returns (uint8);
    function checkLayer2TVL(address _rollupConfig) external view returns (bool result, uint256 amount);
    function layer2TVL(address _rollupConfig) external view returns (uint256 amount);

    /// @notice DisputeGameFactory => rollupConfig 역방향 매핑
    /// @dev RAT에서 factory 검증 시 사용
    function rollupConfigWithDisputeGameFactory(address factory) external view returns (address rollupConfig);

    /// @notice Portal => rollupConfig 역방향 매핑
    /// @dev SeigManager.onBridgedTONChange에서 호출자 검증 시 사용
    function rollupConfigWithPortal(address portal) external view returns (address rollupConfig);
}