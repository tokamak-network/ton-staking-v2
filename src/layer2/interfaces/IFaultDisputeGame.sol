// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDisputeGame } from "./IDisputeGame.sol";
import { Claim, Position, Clock } from "../lib/LibUDT.sol";

/// @title IFaultDisputeGame
/// @notice Extended interface for FaultDisputeGame to access claim data
interface IFaultDisputeGame is IDisputeGame {
    /// @notice Struct representing a claim in the dispute game
    struct ClaimData {
        uint32 parentIndex;
        address counteredBy;
        address claimant;
        uint128 bond;
        Claim claim;
        Position position;
        Clock clock;
    }

    /// @notice Returns the claim data at the given index
    /// @param index The index of the claim
    function claimData(uint256 index) external view returns (
        uint32 parentIndex,
        address counteredBy,
        address claimant,
        uint128 bond,
        Claim claim,
        Position position,
        Clock clock
    );
}
