// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IDAOCommittee } from "./interfaces/IDAOCommittee.sol";
import { ICandidate } from "./interfaces/ICandidate.sol";
import { ILayer2 } from "./interfaces/ILayer2.sol";
import { ISeigManager } from "./interfaces/ISeigManager.sol";
import { IWTON } from "../stake/interfaces/IWTON.sol";

import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";
import "./LotteryCandidateStorage.sol";

interface IDepositManager {
    function deposit(address layer2, address account, uint256 amount) external returns (bool);
    function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
    function processRequest(address layer2, bool receiveTON) external returns (bool);
}

/// @title LotteryCandidate
/// @notice Candidate with lottery participation and seigniorage distribution
/// @dev Users deposit TON/WTON, LotteryCandidate deposits to DepositManager and tracks balances internally
contract LotteryCandidate is ProxyStorage, AccessibleCommon, LotteryCandidateStorage, ILayer2 {
    using SafeERC20 for IERC20;

    // ========================================
    // Events
    // ========================================
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event LotteryEntered(uint256 indexed round, address indexed account, uint256 entryFee);
    event LotteryWinnerDrawn(uint256 indexed round, address indexed winner, uint256 prizeAmount);
    event EntryFeeUpdated(uint256 newEntryFee, uint256 effectiveFromRound);
    event SeigniorageReceived(uint256 amount);
    event SeigniorageDistributed(uint256 totalAmount, uint256 depositorCount);
    event WithdrawalRequested(address indexed account, uint256 amount, uint256 requestIndex);
    event WithdrawalProcessed(address indexed account, uint256 amount, uint256 requestIndex);
    event TonUpdated(address ton);
    event WtonUpdated(address wton);
    event DepositManagerUpdated(address depositManager);

    // ========================================
    // Modifiers
    // ========================================
    modifier onlyOperator() {
        require(candidate == msg.sender, "LotteryCandidate: not operator");
        _;
    }

    // ========================================
    // ILayer2 Interface
    // ========================================
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId] || super.supportsInterface(interfaceId);
    }

    function operator() external view override returns (address) { return address(this); }
    function isLayer2() external pure override returns (bool) { return true; }
    function currentFork() external pure override returns (uint256) { return 1; }
    function lastEpoch(uint256) external pure override returns (uint256) { return 1; }
    function changeOperator(address) external pure override {
        revert("LotteryCandidate: changeOperator not supported");
    }

    // ========================================
    // Initialization
    // ========================================
    function initialize(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _memo,
        address _committee,
        address _seigManager,
        address _depositManager,
        address _ton,
        address _wton,
        uint256 _initialEntryFee
    ) external onlyOwner {
        require(
            _candidate != address(0) &&
            _committee != address(0) &&
            _seigManager != address(0) &&
            _depositManager != address(0) &&
            _ton != address(0) &&
            _wton != address(0),
            "LotteryCandidate: zero address"
        );

        candidate = _candidate;
        isLayer2Candidate = _isLayer2Candidate;
        committee = _committee;
        seigManager = _seigManager;
        memo = _memo;
        depositManager = _depositManager;
        ton = _ton;
        wton = _wton;
        currentRound = 1;
        entryFee = _initialEntryFee;

        _registerInterface(ICandidate(address(this)).isCandidateContract.selector);
    }

    // ========================================
    // Admin Functions
    // ========================================
    function setSeigManager(address _seigManager) external onlyOwner {
        require(_seigManager != address(0), "LotteryCandidate: zero address");
        seigManager = _seigManager;
    }

    function setCommittee(address _committee) external onlyOwner {
        require(_committee != address(0), "LotteryCandidate: zero address");
        committee = _committee;
    }

    function setMemo(string calldata _memo) external onlyOwner {
        memo = _memo;
    }

    function setDepositManager(address _depositManager) external onlyOwner {
        require(_depositManager != address(0), "LotteryCandidate: zero address");
        depositManager = _depositManager;
        emit DepositManagerUpdated(_depositManager);
    }

    function setTon(address _ton) external onlyOwner {
        require(_ton != address(0), "LotteryCandidate: zero address");
        ton = _ton;
        emit TonUpdated(_ton);
    }

    function setWton(address _wton) external onlyOwner {
        require(_wton != address(0), "LotteryCandidate: zero address");
        wton = _wton;
        emit WtonUpdated(_wton);
    }

    /// @notice Set entry fee for lottery (applies from next round)
    /// @param _entryFee New entry fee in WTON (27 decimals)
    function setEntryFee(uint256 _entryFee) external onlyOperator {
        pendingEntryFee = _entryFee;
        hasPendingEntryFee = true;
        emit EntryFeeUpdated(_entryFee, currentRound + 1);
    }

    // ========================================
    // Deposit Functions
    // ========================================
    
    /// @notice Deposit TON via approveAndCall
    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata
    ) external returns (bool) {
        require(msg.sender == ton, "LotteryCandidate: only TON");
        require(spender == address(this), "LotteryCandidate: invalid spender");
        return _depositTON(owner, amount);
    }

    /// @notice Deposit TON directly
    function depositTON(uint256 tonAmount) external returns (bool) {
        require(tonAmount > 0, "LotteryCandidate: zero amount");
        IERC20(ton).safeTransferFrom(msg.sender, address(this), tonAmount);
        return _depositTON(msg.sender, tonAmount);
    }

    /// @notice Deposit WTON directly
    function depositWTON(uint256 wtonAmount) external returns (bool) {
        require(wtonAmount > 0, "LotteryCandidate: zero amount");
        IERC20(wton).safeTransferFrom(msg.sender, address(this), wtonAmount);
        return _depositWTON(msg.sender, wtonAmount);
    }

    function _depositTON(address account, uint256 tonAmount) internal returns (bool) {
        // Convert TON to WTON
        IERC20(ton).safeIncreaseAllowance(wton, tonAmount);
        require(IWTON(wton).swapFromTON(tonAmount), "LotteryCandidate: swap failed");
        
        uint256 wtonAmount = tonAmount * 1e9;
        return _depositWTON(account, wtonAmount);
    }

    function _depositWTON(address account, uint256 wtonAmount) internal returns (bool) {
        // Deposit to DepositManager (LotteryCandidate as layer2 AND depositor)
        // Internal storage handles individual user shares
        IERC20(wton).safeIncreaseAllowance(depositManager, wtonAmount);
        require(
            IDepositManager(depositManager).deposit(address(this), address(this), wtonAmount),
            "LotteryCandidate: deposit failed"
        );

        // Track in internal storage
        if (!_isDepositor[account]) {
            _isDepositor[account] = true;
            _depositors.push(account);
        }
        _balances[account] += wtonAmount;
        totalDeposited += wtonAmount;

        emit Deposited(account, wtonAmount);
        return true;
    }

    // ========================================
    // Withdrawal Functions
    // ========================================

    /// @notice Request withdrawal of deposited funds
    /// @param amount Amount of WTON to withdraw
    function requestWithdrawal(uint256 amount) external returns (bool) {
        require(amount > 0, "LotteryCandidate: zero amount");
        require(_balances[msg.sender] >= amount, "LotteryCandidate: insufficient balance");

        // Deduct from user's internal balance
        _balances[msg.sender] -= amount;
        totalDeposited -= amount;

        // Request from DepositManager
        require(
            IDepositManager(depositManager).requestWithdrawal(address(this), amount),
            "LotteryCandidate: requestWithdrawal failed"
        );

        // Record request
        uint256 requestIndex = withdrawalRequests.length;
        withdrawalRequests.push(WithdrawalRequest({
            user: msg.sender,
            amount: amount,
            requestBlock: block.number,
            processed: false
        }));

        emit WithdrawalRequested(msg.sender, amount, requestIndex);
        return true;
    }

    /// @notice Process matured withdrawal requests
    /// @param n Number of requests to process
    function processWithdrawal(uint256 n) external returns (bool) {
        require(n > 0, "LotteryCandidate: n is zero");
        
        uint256 lastIdx = lastProcessedRequestIndex;
        uint256 totalRequests = withdrawalRequests.length;
        
        for (uint256 i = 0; i < n && (lastIdx + i) < totalRequests; i++) {
            uint256 currentIdx = lastIdx + i;
            WithdrawalRequest storage req = withdrawalRequests[currentIdx];
            
            if (req.processed) continue;

            // Process with DepositManager (assume TON for now, or could be parameter)
            // Note: DepositManager handles delay check. If it fails, this function reverts.
            require(
                IDepositManager(depositManager).processRequest(address(this), false),
                "LotteryCandidate: processRequest failed"
            );

            // Mark as processed and send WTON to user
            req.processed = true;
            IERC20(wton).safeTransfer(req.user, req.amount);

            emit WithdrawalProcessed(req.user, req.amount, currentIdx);
        }

        lastProcessedRequestIndex = lastIdx + n > totalRequests ? totalRequests : lastIdx + n;
        return true;
    }

    // ========================================
    // Lottery Functions
    // ========================================

    /// @notice Enter current lottery round
    /// @dev Deducts entryFee from user's internal balance and adds to prize pool
    function enterLottery() external returns (bool) {
        uint256 round = currentRound;
        require(!_roundEntered[round][msg.sender], "LotteryCandidate: already entered");
        require(entryFee > 0, "LotteryCandidate: entry fee not set");
        require(_balances[msg.sender] >= entryFee, "LotteryCandidate: insufficient balance");

        // Deduct entry fee from user's balance
        _balances[msg.sender] -= entryFee;
        totalDeposited -= entryFee;

        // Add to prize pool
        _roundPrizePool[round] += entryFee;

        // Record participation
        _roundEntered[round][msg.sender] = true;
        _roundParticipants[round].push(msg.sender);

        emit LotteryEntered(round, msg.sender, entryFee);
        return true;
    }

    /// @notice Draw winner for current round and distribute prize
    /// @dev Only operator can call. Winner receives entire prize pool added to their balance.
    function drawWinner() external onlyOperator returns (address winner) {
        uint256 round = currentRound;
        require(!_roundDrawn[round], "LotteryCandidate: already drawn");
        
        address[] storage participants = _roundParticipants[round];
        uint256 participantCount = participants.length;
        require(participantCount > 0, "LotteryCandidate: no participants");

        // Select random winner (equal probability for all participants)
        uint256 winnerIndex = uint256(
            keccak256(abi.encodePacked(block.prevrandao, block.timestamp, round, participantCount))
        ) % participantCount;
        
        winner = participants[winnerIndex];

        // Transfer prize pool to winner's balance
        uint256 prizeAmount = _roundPrizePool[round];
        _balances[winner] += prizeAmount;
        totalDeposited += prizeAmount;

        // Update round state
        _roundWinner[round] = winner;
        _roundDrawn[round] = true;

        // Apply pending entry fee for next round
        if (hasPendingEntryFee) {
            entryFee = pendingEntryFee;
            hasPendingEntryFee = false;
        }

        // Move to next round
        currentRound = round + 1;

        emit LotteryWinnerDrawn(round, winner, prizeAmount);
    }

    // ========================================
    // Seigniorage Functions
    // ========================================

    /// @notice Receive seigniorage and distribute to depositors based on their balance ratio
    /// @param amount Amount of WTON seigniorage to distribute
    function receiveSeigniorage(uint256 amount) external onlyOperator returns (bool) {
        require(amount > 0, "LotteryCandidate: zero amount");
        require(totalDeposited > 0, "LotteryCandidate: no depositors");

        // Transfer WTON from operator
        IERC20(wton).safeTransferFrom(msg.sender, address(this), amount);

        // Distribute proportionally and deposit to DepositManager
        _distributeSeigniorage(amount);
        
        totalDeposited += amount;

        // Deposit to DepositManager for the contract
        IERC20(wton).safeIncreaseAllowance(depositManager, amount);
        require(
            IDepositManager(depositManager).deposit(address(this), address(this), amount),
            "LotteryCandidate: seigniorage deposit failed"
        );

        emit SeigniorageReceived(amount);
        emit SeigniorageDistributed(amount, _depositors.length);
        return true;
    }

    function _distributeSeigniorage(uint256 amount) internal returns (uint256 distributed) {
        uint256 total = totalDeposited;
        uint256 len = _depositors.length;
        
        for (uint256 i = 0; i < len; i++) {
            address dep = _depositors[i];
            uint256 bal = _balances[dep];
            if (bal > 0) {
                uint256 share = (amount * bal) / total;
                if (share > 0) {
                    _balances[dep] += share;
                    distributed += share;
                }
            }
        }

        // Handle dust
        if (distributed < amount && len > 0) {
            for (uint256 i = len; i > 0; i--) {
                address dep = _depositors[i - 1];
                if (_balances[dep] > 0) {
                    _balances[dep] += (amount - distributed);
                    return amount;
                }
            }
        }
    }

    // ========================================
    // View Functions
    // ========================================

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getDepositors() external view returns (address[] memory) {
        return _depositors;
    }

    function getDepositorCount() external view returns (uint256) {
        return _depositors.length;
    }

    function getRoundParticipants(uint256 round) external view returns (address[] memory) {
        return _roundParticipants[round];
    }

    function getRoundParticipantCount(uint256 round) external view returns (uint256) {
        return _roundParticipants[round].length;
    }

    function roundEntered(uint256 round, address account) external view returns (bool) {
        return _roundEntered[round][account];
    }

    function roundWinner(uint256 round) external view returns (address) {
        return _roundWinner[round];
    }

    function roundDrawn(uint256 round) external view returns (bool) {
        return _roundDrawn[round];
    }

    function roundPrizePool(uint256 round) external view returns (uint256) {
        return _roundPrizePool[round];
    }

    // ========================================
    // DAO Committee Functions
    // ========================================

    function isCandidateContract() external pure returns (bool) {
        return true;
    }

    function changeMember(uint256 _memberIndex) external onlyOperator returns (bool) {
        return IDAOCommittee(committee).changeMember(_memberIndex);
    }

    function retireMember() external onlyOperator returns (bool) {
        return IDAOCommittee(committee).retireMember();
    }

    function castVote(
        uint256 _agendaID,
        uint256 _vote,
        string calldata _comment
    ) external onlyOperator {
        IDAOCommittee(committee).castVote(_agendaID, _vote, _comment);
    }

    function claimActivityReward() external onlyOperator {
        IDAOCommittee(committee).claimActivityReward(candidate);
    }

    function updateSeigniorage() external returns (bool) {
        require(seigManager != address(0), "LotteryCandidate: SeigManager not set");
        require(ISeigManager(seigManager).updateSeigniorage(), "LotteryCandidate: updateSeigniorage failed");
        return true;
    }
}
