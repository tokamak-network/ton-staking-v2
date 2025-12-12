// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IDisputeGame } from "../layer2/interfaces/IDisputeGame.sol";
import { GameStatus } from "../layer2/lib/Types.sol";
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
import { Position, LibPosition } from "../layer2/lib/LibPosition.sol";

// Mock interfaces needed for GameConstructorParams
interface IBigStepper {}
interface IDelayedWETH {
    function deposit() external payable;
}
interface IAnchorStateRegistry {
    function getAnchorRoot() external view returns (Hash, uint256);
    function respectedGameType() external view returns (GameType);
}
interface ISemver {
    function version() external view returns (string memory);
}

error GameNotInProgress();

contract MockFaultDisputeGame is IDisputeGame, ISemver {
    
    enum BondDistributionMode {
        UNDECIDED,
        NORMAL,
        REFUND
    }

    struct Proposal {
        Hash root;
        uint256 l2SequenceNumber;
    }

    struct ClaimData {
        uint32 parentIndex;
        address counteredBy;
        address claimant;
        uint128 bond;
        Claim claim;
        Position position;
        Clock clock;
    }

    struct ResolutionCheckpoint {
        bool initialCheckpointComplete;
        uint32 subgameIndex;
        Position leftmostPosition;
        address counteredBy;
    }

    struct GameConstructorParams {
        GameType gameType;
        Claim absolutePrestate;
        uint256 maxGameDepth;
        uint256 splitDepth;
        Duration clockExtension;
        Duration maxClockDuration;
        IBigStepper vm;
        IDelayedWETH weth;
        IAnchorStateRegistry anchorStateRegistry;
        uint256 l2ChainId;
    }

    // State Variables matching FaultDisputeGame
    Claim internal immutable ABSOLUTE_PRESTATE;
    uint256 internal immutable MAX_GAME_DEPTH;
    uint256 internal immutable SPLIT_DEPTH;
    Duration internal immutable MAX_CLOCK_DURATION;
    IBigStepper internal immutable VM;
    GameType internal immutable GAME_TYPE;
    IDelayedWETH internal immutable WETH;
    IAnchorStateRegistry internal immutable ANCHOR_STATE_REGISTRY;
    uint256 internal immutable L2_CHAIN_ID;
    Duration internal immutable CLOCK_EXTENSION;
    
    Position internal constant ROOT_POSITION = Position.wrap(1);
    
    uint256 internal constant HEADER_BLOCK_NUMBER_INDEX = 8;

    Timestamp public createdAt;
    Timestamp public resolvedAt;
    GameStatus public status;
    bool internal initialized;

    ClaimData[] public claimData;
    mapping(address => uint256) public normalModeCredit;
    mapping(Hash => bool) public claims;
    mapping(uint256 => uint256[]) public subgames;
    mapping(uint256 => bool) public resolvedSubgames;
    mapping(uint256 => ResolutionCheckpoint) public resolutionCheckpoints;
    Proposal public startingOutputRoot;
    bool public wasRespectedGameTypeWhenCreated;
    mapping(address => uint256) public refundModeCredit;
    mapping(address => bool) public hasUnlockedCredit;
    BondDistributionMode public bondDistributionMode;

    // Extra storage for IDisputeGame compliance
    Claim internal _rootClaim;
    bytes internal _extraData;

    constructor(
        GameConstructorParams memory _params,
        Claim rootClaim_,
        bytes memory extraData_
    ) {
        GAME_TYPE = _params.gameType;
        ABSOLUTE_PRESTATE = _params.absolutePrestate;
        MAX_GAME_DEPTH = _params.maxGameDepth;
        SPLIT_DEPTH = _params.splitDepth;
        CLOCK_EXTENSION = _params.clockExtension;
        MAX_CLOCK_DURATION = _params.maxClockDuration;
        VM = _params.vm;
        WETH = _params.weth;
        ANCHOR_STATE_REGISTRY = _params.anchorStateRegistry;
        L2_CHAIN_ID = _params.l2ChainId;
        
        _rootClaim = rootClaim_;
        _extraData = extraData_;
        status = GameStatus.IN_PROGRESS;
    }

    function version() public pure virtual returns (string memory) {
        return "1.8.0";
    }

    function initialize() public payable virtual {
        if (initialized) revert("AlreadyInitialized");
        initialized = true;
        createdAt = Timestamp.wrap(uint64(block.timestamp));
        
        // Add root claim
        claimData.push(
            ClaimData({
                parentIndex: type(uint32).max,
                counteredBy: address(0),
                claimant: msg.sender,
                bond: uint128(msg.value),
                claim: _rootClaim,
                position: ROOT_POSITION,
                clock: LibClock.wrap(Duration.wrap(0), Timestamp.wrap(uint64(block.timestamp)))
            })
        );
    }

    function gameType() external view returns (GameType) {
        return GAME_TYPE;
    }

    function gameCreator() external pure returns (address) {
        return address(0); // Mock
    }

    function l1Head() external pure returns (Hash) {
        return Hash.wrap(bytes32(0)); // Mock
    }

    function resolve() external returns (GameStatus) {
        if (status != GameStatus.IN_PROGRESS) revert GameNotInProgress();
        
        status = claimData[0].counteredBy == address(0) ? GameStatus.DEFENDER_WINS : GameStatus.CHALLENGER_WINS;        
        resolvedAt = Timestamp.wrap(uint64(block.timestamp));
        emit Resolved(status);
        return status;
    }

    function rootClaim() external view returns (Claim) {
        return _rootClaim;
    }

    function extraData() external view returns (bytes memory) {
        return _extraData;
    }

    function gameData() external view returns (GameType, Claim, bytes memory) {
        return (GAME_TYPE, _rootClaim, _extraData);
    }

    function step() external {
        claimData[0].counteredBy = msg.sender;
    }

    // Helper to set status for testing
    function setStatus(GameStatus _status) external {
        status = _status;
    }


}
