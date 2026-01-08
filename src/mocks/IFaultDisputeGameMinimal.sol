// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GameStatus, Claim } from "lib/optimism/packages/contracts-bedrock/src/dispute/lib/Types.sol";

/// @title IDelayedWETHMinimal
/// @notice Minimal interface for DelayedWETH contract
interface IDelayedWETHMinimal {
    /// @notice Get the withdrawal delay in seconds
    function delay() external view returns (uint256);
}

/// @title IFaultDisputeGameMinimal
/// @notice Minimal interface for FaultDisputeGame needed for e2e testing
interface IFaultDisputeGameMinimal {
    /// @notice Attack a claim
    function attack(Claim _disputed, uint256 _parentIndex, Claim _claim) external payable;

    /// @notice Defend a claim
    function defend(Claim _disputed, uint256 _parentIndex, Claim _claim) external payable;

    /// @notice Resolve a claim
    function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) external;

    /// @notice Resolve the game
    function resolve() external returns (GameStatus status_);

    /// @notice Get the current game status
    function status() external view returns (GameStatus);

    /// @notice Get the root claim
    function rootClaim() external pure returns (Claim rootClaim_);

    /// @notice Get claim data (Position is encoded as uint128 internally but returned as uint256 in ABI)
    function claimData(uint256 _claimIndex) external view returns (
        uint32 parentIndex,
        address counteredBy,
        address claimant,
        uint128 bond,
        Claim claim,
        uint128 position,  // Changed from uint256 to uint128
        uint128 clock      // Changed from uint256 to uint128
    );

    /// @notice Get required bond for a position (Position type is uint128)
    function getRequiredBond(uint128 _position) external view returns (uint256);

    /// @notice Get claim count
    function claimDataLen() external view returns (uint256);

    /// @notice Get max game depth
    function maxGameDepth() external view returns (uint256);

    /// @notice Get split depth
    function splitDepth() external view returns (uint256);

    /// @notice Get max clock duration
    function maxClockDuration() external view returns (uint64);

    /// @notice Get credit for an address
    function credit(address _recipient) external view returns (uint256);

    /// @notice Claim credit (withdraw ETH)
    function claimCredit(address _recipient) external;

    /// @notice Get the DelayedWETH contract address
    function weth() external view returns (IDelayedWETHMinimal);
}
