// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IL1BridgeRegistry {
    /// @notice Rollup type constants (dynamically registered via addRollupType)
    /// @dev TYPE 0: Reserved (invalid)
    /// @dev TYPE 1: Optimism Legacy (Titan) - uses l1StandardBridge(), depositERC20To()
    /// @dev TYPE 2: Optimism Bedrock (Thanos) - uses optimismPortal(), bridgeNativeTokenTo()
    /// @dev TYPE 3: Optimism Bedrock DisputeGame - uses optimismPortal(), bridgeNativeTokenTo(), V3 eligible
    /// @dev TYPE 4+: Future rollup types can be added dynamically without contract changes

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

    // ========== V1_3 Dynamic Type Management ==========

    /// @notice Check if a rollup type is valid and active for V3 seigniorage
    function isValidRollupType(uint8 _type) external view returns (bool);

    /// @notice Get bridge pattern for a rollup type (0=ERC20, 1=NATIVE, 2=CUSTOM, ...)
    function getBridgePattern(uint8 _type) external view returns (uint8);

    /// @notice Get TVL contract getter selector for a rollup type
    function getTvlContractGetter(uint8 _type) external view returns (bytes4);
}