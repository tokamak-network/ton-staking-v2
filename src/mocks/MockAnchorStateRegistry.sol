// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title MockAnchorStateRegistry
/// @notice Mock version of AnchorStateRegistry for devnet testing
/// @dev Simplified implementation with only the minimal interface needed for OptimismPortal
///      Based on lib/optimism/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol
contract MockAnchorStateRegistry {
    /// @notice Address of the SystemConfig contract
    address public systemConfig;

    /// @notice Address of the DisputeGameFactory contract
    address public disputeGameFactory;

    /// @notice Whether the contract has been initialized
    bool private _initialized;

    /// @notice Emitted when the contract is initialized
    event Initialized(address systemConfig, address disputeGameFactory);

    /// @notice Initializes the contract
    /// @param _systemConfig The address of the SystemConfig contract
    /// @param _disputeGameFactory The address of the DisputeGameFactory contract
    /// @dev Simplified version - only stores systemConfig and disputeGameFactory
    ///      _startingAnchorRoot and _startingRespectedGameType are ignored in mock
    function initialize(
        address _systemConfig,
        address _disputeGameFactory,
        bytes32 /* _startingAnchorRoot */,  // Simplified - actual uses Proposal struct
        uint32 /* _startingRespectedGameType */  // Simplified - actual uses GameType
    ) external {
        require(!_initialized, "Already initialized");

        systemConfig = _systemConfig;
        disputeGameFactory = _disputeGameFactory;
        _initialized = true;

        // Ignore _startingAnchorRoot and _startingRespectedGameType in mock

        emit Initialized(_systemConfig, _disputeGameFactory);
    }

    /// @notice Sets the DisputeGameFactory address (for testing)
    /// @param _disputeGameFactory The new DisputeGameFactory address
    function setDisputeGameFactory(address _disputeGameFactory) external {
        disputeGameFactory = _disputeGameFactory;
    }

    /// @notice Returns the dispute game finality delay in seconds (hardcoded for mock)
    function disputeGameFinalityDelaySeconds() external pure returns (uint256) {
        return 0; // No delay in devnet
    }

    /// @notice Returns whether the contract is paused (always false for mock)
    function paused() external pure returns (bool) {
        return false;
    }
}
