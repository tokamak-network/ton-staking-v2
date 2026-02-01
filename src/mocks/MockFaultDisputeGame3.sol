// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IDisputeGame} from "../layer2/interfaces/IDisputeGame.sol";
import {GameStatus} from "../layer2/lib/Types.sol";
import {
    Claim,
    GameType,
    Hash,
    Duration,
    Timestamp,
    Clock,
    LibClock,
    LibGameType,
    LibClaim,
    LibDuration,
    LibTimestamp
} from "../layer2/lib/LibUDT.sol";
import {Position, LibPosition} from "../layer2/lib/LibPosition.sol";

/// @title IWinningChallengerTracker
/// @notice Interface for external winning challenger tracker
interface IWinningChallengerTracker {
    function recordWinner(address game, address winner, address gameCreator) external;
    function getWinningChallengers(address game) external view returns (address[] memory);
    function getWinningChallengersCount(address game) external view returns (uint256);
    function isWinningChallenger(address game, address challenger) external view returns (bool);
}

/// @title MockFaultDisputeGame3
/// @notice More realistic mock that simulates the actual FaultDisputeGame flow
/// @dev Supports move(), step(), resolveClaim() for realistic game simulation
contract MockFaultDisputeGame3 is IDisputeGame {
    using LibPosition for Position;
    using LibClock for Clock;

    // ============================================
    // Types
    // ============================================

    struct ClaimData {
        uint32 parentIndex;
        address counteredBy;
        address claimant;
        uint128 bond;
        Claim claim;
        Position position;
        Clock clock;
    }

    // ============================================
    // Constants
    // ============================================

    Position internal constant ROOT_POSITION = Position.wrap(1);
    uint256 public constant MAX_GAME_DEPTH = 73;
    uint256 public constant SPLIT_DEPTH = 30;

    // ============================================
    // State Variables
    // ============================================

    GameType internal immutable GAME_TYPE;
    Claim internal immutable ROOT_CLAIM;
    bytes internal _extraData;
    address internal immutable GAME_CREATOR;

    Timestamp public createdAt;
    Timestamp public resolvedAt;
    GameStatus public status;
    bool internal initialized;

    ClaimData[] public claimData;
    mapping(uint256 => uint256[]) public subgames;
    mapping(uint256 => bool) public resolvedSubgames;
    mapping(address => uint256) public credit;

    // Winning challenger tracking (internal storage for simple tests)
    mapping(address => bool) internal _isWinningChallenger;
    address[] internal _winningChallengers;

    // External tracker support (optional, for realistic E2E tests)
    address public winningChallengerTracker;

    // ============================================
    // Events
    // ============================================

    event Move(uint256 indexed parentIndex, Claim indexed claim, address indexed claimant);

    // ============================================
    // Errors
    // ============================================

    error GameNotInProgress();
    error ClaimAlreadyResolved();
    error OutOfOrderResolution();
    error AlreadyInitialized();
    error InvalidParentIndex();
    error DuplicateStep();

    // ============================================
    // Constructor
    // ============================================

    constructor(GameType gameType_, Claim rootClaim_, bytes memory extraData_, address creator_) {
        GAME_TYPE = gameType_;
        ROOT_CLAIM = rootClaim_;
        _extraData = extraData_;
        GAME_CREATOR = creator_;
        status = GameStatus.IN_PROGRESS;
    }

    // ============================================
    // Initialization
    // ============================================

    function initialize() public payable {
        _initialize(address(0));
    }

    function initialize(address _winningChallengerTracker) public payable {
        _initialize(_winningChallengerTracker);
    }

    function _initialize(address _winningChallengerTracker) internal {
        if (initialized) revert AlreadyInitialized();
        initialized = true;
        createdAt = Timestamp.wrap(uint64(block.timestamp));

        if (_winningChallengerTracker != address(0)) {
            winningChallengerTracker = _winningChallengerTracker;
        }

        // Add root claim (index 0)
        claimData.push(
            ClaimData({
                parentIndex: type(uint32).max,
                counteredBy: address(0),
                claimant: GAME_CREATOR,
                bond: uint128(msg.value),
                claim: ROOT_CLAIM,
                position: ROOT_POSITION,
                clock: LibClock.wrap(Duration.wrap(0), Timestamp.wrap(uint64(block.timestamp)))
            })
        );
    }

    // ============================================
    // Game Actions
    // ============================================

    /// @notice Make a move (attack or defend) against a claim
    /// @param _challengeIndex The index of the claim to challenge
    /// @param _claim The new claim
    /// @param _isAttack True for attack, false for defend
    function move(uint256 _challengeIndex, Claim _claim, bool _isAttack) external payable {
        if (status != GameStatus.IN_PROGRESS) revert GameNotInProgress();
        if (_challengeIndex >= claimData.length) revert InvalidParentIndex();

        ClaimData memory parent = claimData[_challengeIndex];
        Position nextPosition = parent.position.move(_isAttack);

        // Add new claim
        uint256 newClaimIndex = claimData.length;
        claimData.push(
            ClaimData({
                parentIndex: uint32(_challengeIndex),
                counteredBy: address(0),
                claimant: msg.sender,
                bond: uint128(msg.value),
                claim: _claim,
                position: nextPosition,
                clock: LibClock.wrap(Duration.wrap(0), Timestamp.wrap(uint64(block.timestamp)))
            })
        );

        // Register as child of parent
        subgames[_challengeIndex].push(newClaimIndex);

        emit Move(_challengeIndex, _claim, msg.sender);
    }

    /// @notice Step against a claim at max depth (proves claim is wrong)
    /// @param _claimIndex The index of the claim to step against
    function step(uint256 _claimIndex) external {
        if (status != GameStatus.IN_PROGRESS) revert GameNotInProgress();
        if (_claimIndex >= claimData.length) revert InvalidParentIndex();

        ClaimData storage claim = claimData[_claimIndex];
        if (claim.counteredBy != address(0)) revert DuplicateStep();

        // Mark the claim as stepped against (countered)
        claim.counteredBy = msg.sender;
    }

    /// @notice Resolve a subgame rooted at the given claim index
    /// @dev Must be called bottom-up in the DAG
    /// @param _claimIndex The index of the subgame root claim to resolve
    function resolveClaim(uint256 _claimIndex) external {
        if (status != GameStatus.IN_PROGRESS) revert GameNotInProgress();
        if (resolvedSubgames[_claimIndex]) revert ClaimAlreadyResolved();

        ClaimData storage subgameRootClaim = claimData[_claimIndex];
        uint256[] storage challengeIndices = subgames[_claimIndex];
        uint256 challengeIndicesLen = challengeIndices.length;

        // Case 1: Uncontested claim with no children (not root)
        if (challengeIndicesLen == 0 && _claimIndex != 0) {
            address counteredBy = subgameRootClaim.counteredBy;
            address recipient = counteredBy == address(0) ? subgameRootClaim.claimant : counteredBy;
            _distributeBond(recipient, subgameRootClaim);
            _recordWinningChallenger(recipient);
            resolvedSubgames[_claimIndex] = true;
            return;
        }

        // Case 2: Claim with children - find leftmost uncountered child
        address countered = address(0);
        Position leftmostPosition = Position.wrap(type(uint128).max);

        for (uint256 i = 0; i < challengeIndicesLen; i++) {
            uint256 challengeIndex = challengeIndices[i];

            // All children must be resolved first
            if (!resolvedSubgames[challengeIndex]) revert OutOfOrderResolution();

            ClaimData storage childClaim = claimData[challengeIndex];

            // Find leftmost uncountered child
            if (
                childClaim.counteredBy == address(0) &&
                Position.unwrap(leftmostPosition) > Position.unwrap(childClaim.position)
            ) {
                countered = childClaim.claimant;
                leftmostPosition = childClaim.position;
            }
        }

        // Mark as resolved
        resolvedSubgames[_claimIndex] = true;

        // Distribute bond to winner
        address bondRecipient = countered == address(0) ? subgameRootClaim.claimant : countered;
        _distributeBond(bondRecipient, subgameRootClaim);
        _recordWinningChallenger(bondRecipient);

        // Percolate result up
        subgameRootClaim.counteredBy = countered;
    }

    /// @notice Resolve the entire game after all claims are resolved
    function resolve() external returns (GameStatus) {
        if (status != GameStatus.IN_PROGRESS) revert GameNotInProgress();

        // For simple test compatibility: if root claim has no children and wasn't stepped on,
        // auto-resolve it (DEFENDER_WINS case)
        if (!resolvedSubgames[0]) {
            // If there are no children of root claim, allow direct resolution
            if (subgames[0].length == 0) {
                resolvedSubgames[0] = true;
            } else {
                revert OutOfOrderResolution();
            }
        }

        // Determine winner based on root claim's counteredBy
        status = claimData[0].counteredBy == address(0)
            ? GameStatus.DEFENDER_WINS
            : GameStatus.CHALLENGER_WINS;

        resolvedAt = Timestamp.wrap(uint64(block.timestamp));
        emit Resolved(status);
        return status;
    }

    // ============================================
    // Internal Functions
    // ============================================

    function _distributeBond(address _recipient, ClaimData storage _bonded) internal {
        credit[_recipient] += _bonded.bond;
    }

    function _recordWinningChallenger(address _recipient) internal {
        // Exclude game creator (proposer/defender)
        if (_recipient == GAME_CREATOR) return;

        // Use external tracker if available
        if (winningChallengerTracker != address(0)) {
            try
                IWinningChallengerTracker(winningChallengerTracker).recordWinner(
                    address(this),
                    _recipient,
                    GAME_CREATOR
                )
            {} catch {}
            return;
        }

        // Otherwise use internal storage
        if (_isWinningChallenger[_recipient]) return;
        _isWinningChallenger[_recipient] = true;
        _winningChallengers.push(_recipient);
    }

    // ============================================
    // View Functions
    // ============================================

    function gameType() external view returns (GameType) {
        return GAME_TYPE;
    }

    function rootClaim() external view returns (Claim) {
        return ROOT_CLAIM;
    }

    function extraData() external view returns (bytes memory) {
        return _extraData;
    }

    function gameData() external view returns (GameType, Claim, bytes memory) {
        return (GAME_TYPE, ROOT_CLAIM, _extraData);
    }

    function gameCreator() external pure returns (address) {
        // In real FaultDisputeGame, this is embedded via clones-with-immutable-args
        // For testing, we return address(0) to simulate the game creator
        return address(0);
    }

    /// @notice Returns the actual game creator (for testing)
    function actualGameCreator() external view returns (address) {
        return GAME_CREATOR;
    }

    function l1Head() external pure returns (Hash) {
        return Hash.wrap(bytes32(0));
    }

    function claimDataLen() external view returns (uint256) {
        return claimData.length;
    }

    function getWinningChallengers() external view returns (address[] memory) {
        if (winningChallengerTracker != address(0)) {
            return
                IWinningChallengerTracker(winningChallengerTracker).getWinningChallengers(
                    address(this)
                );
        }
        return _winningChallengers;
    }

    function getWinningChallengersCount() external view returns (uint256) {
        if (winningChallengerTracker != address(0)) {
            return
                IWinningChallengerTracker(winningChallengerTracker).getWinningChallengersCount(
                    address(this)
                );
        }
        return _winningChallengers.length;
    }

    function isWinningChallenger(address _challenger) external view returns (bool) {
        if (winningChallengerTracker != address(0)) {
            return
                IWinningChallengerTracker(winningChallengerTracker).isWinningChallenger(
                    address(this),
                    _challenger
                );
        }
        return _isWinningChallenger[_challenger];
    }

    function getSubgames(uint256 _claimIndex) external view returns (uint256[] memory) {
        return subgames[_claimIndex];
    }

    // ============================================
    // Test Helpers
    // ============================================

    /// @notice Add a winning challenger directly (for testing multi-challenger scenarios)
    /// @dev This bypasses game flow and directly adds to winning challengers
    function addWinningChallenger(address _challenger) external {
        _recordWinningChallenger(_challenger);
    }

    /// @notice Simple step function for basic tests (sets counteredBy on root claim)
    /// @dev Mimics MockFaultDisputeGame2 behavior for backward compatibility
    /// Also marks root claim as resolved so resolve() can be called directly
    function step() external {
        require(claimData[0].counteredBy == address(0), "Already countered");
        claimData[0].counteredBy = msg.sender;
        _recordWinningChallenger(msg.sender);
        // Mark root claim as resolved for simple test flow compatibility
        resolvedSubgames[0] = true;
    }

    /// @notice Force resolve a claim without checking children (for testing edge cases)
    function forceResolveClaim(uint256 _claimIndex, address _winner) external {
        resolvedSubgames[_claimIndex] = true;
        claimData[_claimIndex].counteredBy = _winner == claimData[_claimIndex].claimant
            ? address(0)
            : _winner;
        if (_winner != address(0)) {
            _recordWinningChallenger(_winner);
        }
    }

    /// @notice Set game status directly (for testing)
    function setStatus(GameStatus _status) external {
        status = _status;
    }
}
