// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IDisputeGame
/// @notice Minimal interface for querying DisputeGame rootClaim
interface IDisputeGame {
    /// @notice Returns the root claim of this DisputeGame
    /// @dev rootClaim = keccak256(abi.encode(OutputRootProof))
    /// @return The root claim (hash of OutputRootProof)
    function rootClaim() external view returns (bytes32);

    /// @notice Returns the number of claims in this DisputeGame
    /// @return len_ The number of claims
    function claimDataLen() external view returns (uint256 len_);
}
