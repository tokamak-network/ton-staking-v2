// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title L1BridgeRegistryV1_2Storage
/// @notice V3 신규 스토리지 변수
contract L1BridgeRegistryV1_2Storage {
    /// @notice rollupConfig => DisputeGameFactory 등록여부
    /// @dev RAT에서 triggerAttentionTest 호출 시 factory 검증용
    mapping(address => bool) public disputeGameFactory;

    /// @notice DisputeGameFactory => rollupConfig
    mapping(address => address) public rollupConfigWithDisputeGameFactory;

    /// @notice portal => rollupConfig
    mapping(address => address) public rollupConfigWithPortal;

    /// @notice 타입별 등록 권한자
    /// @dev typeRegistrant[1] = TYPE 1 등록자, typeRegistrant[2] = TYPE 2 등록자, ...
    /// @dev address(0)이면 Manager만 등록 가능
    mapping(uint8 => address) public typeRegistrant;

    // ========== Dynamic Rollup Type Management (V1_3 features) ==========

    /// @notice Bridge function pattern constants for deposit operations
    /// @dev Using uint8 instead of enum for future extensibility
    uint8 public constant BRIDGE_PATTERN_ERC20 = 0;      // depositERC20To(address _l1Token, address _l2Token, address _to, uint256 _amount, uint32 _minGasLimit, bytes _extraData)
    uint8 public constant BRIDGE_PATTERN_NATIVE = 1;     // bridgeNativeTokenTo(address _to, uint256 _amount, uint32 _minGasLimit, bytes _extraData)
    uint8 public constant BRIDGE_PATTERN_CUSTOM = 2;     // Reserved for future custom bridge patterns

    /// @notice Rollup type configuration
    /// @dev Stores function selectors and bridge pattern for each rollup type
    struct RollupTypeConfig {
        bytes4 bridgeContractGetter;        // Function selector to call on rollupConfig to get deposit bridge address
                                            // TYPE 1: l1StandardBridge() = 0x078f29cf
                                            // TYPE 2,3: l1StandardBridge() = 0x078f29cf
                                            // TYPE 4+: custom function (e.g., bridge())
        bytes4 tvlContractGetter;           // Function selector to call on rollupConfig to get TVL query address
                                            // Usually same as bridgeContractGetter, but can be different
                                            // TYPE 1: l1StandardBridge() = 0x078f29cf (same as bridge)
                                            // TYPE 2,3: optimismPortal() = 0x0a49cb03 (different from bridge)
                                            // TYPE 4+: can be different (e.g., bridge() for deposit, portal() for TVL)
        bytes4 disputeGameFactoryGetter;    // Function selector to call on rollupConfig to get DisputeGameFactory address
                                            // TYPE 1,2: bytes4(0) (no factory)
                                            // TYPE 3: disputeGameFactory() = 0x0a1e5c7d
                                            // TYPE 4+: custom or bytes4(0) if not applicable
        bytes4 seigNotifierGetter;          // Function selector to call on rollupConfig to get the contract that triggers onBridgedTonChange()
                                            // TYPE 1: bytes4(0) (no notifier)
                                            // TYPE 2: bytes4(0) (V3 not supported)
                                            // TYPE 3: optimismPortal() = 0x0a49cb03
                                            // TYPE 4+: custom or bytes4(0) if not applicable
        uint8 bridgePattern;                // Which bridge function pattern to use for deposits (0=ERC20, 1=NATIVE, 2=CUSTOM, ...)
        string name;                        // Type name (e.g., "Legacy", "Bedrock", "DisputeGame")
    }

    /// @notice Bitmap tracking rollup types eligible for V3 whitepaper seigniorage
    /// @dev Each bit represents a type: bit N = 1 means TYPE N is eligible for V3 seigniorage
    /// @dev Supports up to 256 types (uint256 has 256 bits)
    uint256 public v3SeigniorageEligibleTypes;

    /// @notice Rollup type => configuration
    mapping(uint8 => RollupTypeConfig) public rollupTypeConfig;
}
