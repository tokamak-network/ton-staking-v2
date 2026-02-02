// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title MockFaultDisputeGame
 * @notice FaultDisputeGame mock for testing slashSequencerByGame
 * @dev Mimics the Optimism FaultDisputeGame interface
 */
contract MockFaultDisputeGame {
    // GameStatus enum (matches Optimism's)
    // 0 = IN_PROGRESS, 1 = CHALLENGER_WINS, 2 = DEFENDER_WINS
    uint8 public gameStatus;

    // SystemConfig address
    address public systemConfigAddr;

    // Challengers who won
    address[] public challengers;

    // ClaimData for challenger extraction
    struct ClaimData {
        uint32 parentIndex;
        address counteredBy;
        address claimant;
        uint128 bond;
        bytes32 claim;
        uint128 position;
        uint128 clock;
    }

    ClaimData[] public claims;

    constructor() {
        gameStatus = 0; // IN_PROGRESS by default
    }

    function setStatus(uint8 _status) external {
        gameStatus = _status;
    }

    function setSystemConfig(address _systemConfig) external {
        systemConfigAddr = _systemConfig;
    }

    function addChallenger(address _challenger) external {
        challengers.push(_challenger);
    }

    function addClaim(
        uint32 parentIndex,
        address counteredBy,
        address claimant,
        uint128 bond
    ) external {
        claims.push(ClaimData({
            parentIndex: parentIndex,
            counteredBy: counteredBy,
            claimant: claimant,
            bond: bond,
            claim: bytes32(0),
            position: 0,
            clock: 0
        }));
    }

    // FaultDisputeGame interface
    function status() external view returns (uint8) {
        return gameStatus;
    }

    function systemConfig() external view returns (address) {
        return systemConfigAddr;
    }

    function claimDataLen() external view returns (uint256) {
        return claims.length;
    }

    function claimData(uint256 index) external view returns (ClaimData memory) {
        return claims[index];
    }

    // Simple challenger getter (for single-challenger games)
    function challenger() external view returns (address) {
        if (challengers.length > 0) {
            return challengers[0];
        }
        return address(0);
    }

    // Resolve the game (CHALLENGER_WINS)
    function resolveAsChallengerWins() external {
        gameStatus = 1;
    }

    // Resolve the game (DEFENDER_WINS)
    function resolveAsDefenderWins() external {
        gameStatus = 2;
    }
}
