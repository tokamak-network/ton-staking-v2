// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LotteryCandidateStorage {
    mapping(bytes4 => bool) internal _supportedInterfaces;
    bool public isLayer2Candidate;
    address public candidate;       // Operator address
    string public memo;

    address public committee;
    address public seigManager;

    address public depositManager;
    address public ton;
    address public wton;

    // ========================================
    // Internal Balance Tracking
    // ========================================
    // Actual funds are in DepositManager (LotteryCandidate as layer2)
    // This storage tracks individual user shares
    mapping(address => uint256) internal _balances;      // User's balance (WTON, 27 decimals)
    uint256 public totalDeposited;                       // Sum of all user balances

    // Track depositors for seigniorage distribution
    address[] internal _depositors;
    mapping(address => bool) internal _isDepositor;

    // ========================================
    // Lottery System
    // ========================================
    uint256 public currentRound;
    mapping(uint256 => address[]) internal _roundParticipants;
    mapping(uint256 => mapping(address => bool)) internal _roundEntered;
    mapping(uint256 => address) internal _roundWinner;
    mapping(uint256 => bool) internal _roundDrawn;

    // Entry fee: changes apply from next round
    uint256 public entryFee;           // Current round's entry fee (WTON, 27 decimals)
    uint256 public pendingEntryFee;    // Next round's entry fee (set by operator)
    bool public hasPendingEntryFee;    // Whether pendingEntryFee is set

    // Lottery prize pool per round (in internal balance, not actual WTON transfer)
    mapping(uint256 => uint256) internal _roundPrizePool;

    // ========================================
    // Withdrawal Management
    // ========================================
    struct WithdrawalRequest {
        address user;
        uint256 amount;
        uint256 requestBlock;
        bool processed;
    }
    WithdrawalRequest[] public withdrawalRequests;
    uint256 public lastProcessedRequestIndex;

    // Seigniorage Distribution
    // ========================================
    // Seigniorage is distributed based on current _balances ratio
    // When seigniorage arrives, it's added to users' _balances proportionally
    uint256 public pendingSeigniorage;  // Seigniorage waiting to be distributed
}
