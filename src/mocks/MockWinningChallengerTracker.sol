// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title MockWinningChallengerTracker
/// @notice Mock version of WinningChallengerTracker for testing
/// @dev Used with MockFaultDisputeGame3 for E2E tests
contract MockWinningChallengerTracker {
    /// @notice Mapping from game address to challenger address to winner status
    mapping(address => mapping(address => bool)) private _isWinner;

    /// @notice Mapping from game address to array of winning challengers
    mapping(address => address[]) private _winners;

    /// @notice Emitted when a winning challenger is recorded
    event WinnerRecorded(address indexed game, address indexed winner);

    /// @notice Records a winning challenger for a specific game
    /// @param game The address of the dispute game
    /// @param winner The address of the winning challenger
    /// @param gameCreator The address of the game creator (to exclude from winners)
    function recordWinner(address game, address winner, address gameCreator) external {
        // Only the game contract itself can record winners
        require(msg.sender == game, "MockWinningChallengerTracker: caller must be the game");

        // Game creator (Proposer) is excluded from winners
        if (winner == gameCreator) return;

        // Skip if already recorded (no duplicates)
        if (_isWinner[game][winner]) return;

        // Record the winner
        _isWinner[game][winner] = true;
        _winners[game].push(winner);

        emit WinnerRecorded(game, winner);
    }

    /// @notice Returns all winning challengers for a specific game
    /// @param game The address of the dispute game
    /// @return Array of winning challenger addresses
    function getWinningChallengers(address game) external view returns (address[] memory) {
        return _winners[game];
    }

    /// @notice Returns the count of winning challengers for a specific game
    /// @param game The address of the dispute game
    /// @return Number of winning challengers
    function getWinningChallengersCount(address game) external view returns (uint256) {
        return _winners[game].length;
    }

    /// @notice Checks if an address is a winning challenger for a specific game
    /// @param game The address of the dispute game
    /// @param challenger The address to check
    /// @return True if the address is a winning challenger
    function isWinningChallenger(address game, address challenger) external view returns (bool) {
        return _isWinner[game][challenger];
    }

    // ============================================
    // Test Helpers
    // ============================================

    /// @notice Manually add a winning challenger (for testing)
    /// @param game The address of the dispute game
    /// @param winner The address to add as winner
    function addWinnerForTest(address game, address winner) external {
        if (_isWinner[game][winner]) return;
        _isWinner[game][winner] = true;
        _winners[game].push(winner);
        emit WinnerRecorded(game, winner);
    }

    /// @notice Clear all winners for a game (for testing)
    /// @param game The address of the dispute game
    function clearWinnersForTest(address game) external {
        address[] storage winners = _winners[game];
        for (uint256 i = 0; i < winners.length; i++) {
            _isWinner[game][winners[i]] = false;
        }
        delete _winners[game];
    }
}
