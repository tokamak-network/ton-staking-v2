# 4. Core Business Logic Description

[← Back to Table of Contents](./README.md) | [← Previous: Directory Structure](./03-directory-structure.md)

---

## 4.1 Key Modules

### 4.1.1 LotteryCandidate (Core Contract)

**File:** `src/dao/LotteryCandidate.sol`
**Inheritance Chain:** `ProxyStorage` → `AccessibleCommon` → `LotteryCandidateStorage` → `ILayer2`

LotteryCandidate **implements the ILayer2 interface to disguise itself as a Layer2**. Through this, it remains compatible with Tokamak's existing staking infrastructure (`DepositManager`, `SeigManager`), while internally tracking individual user balances separately and operating the lottery system.

**Core Differences from Existing Candidate:**

| Item | Candidate | LotteryCandidate |
|------|-----------|------------------|
| Deposit Method | User directly stakes in `DepositManager` | User deposits in LotteryCandidate → LotteryCandidate acts as an integrated staker in `DepositManager` |
| Balance Tracking | Directly tracked by `SeigManager`'s Coinage Token | Separately tracked via internal `_balances` mapping |
| Lottery Feature | None | Round-based lottery system |
| Seigniorage | `SeigManager` directly reflects to Coinage | LotteryCandidate manually distributes Coinage increments |

### 4.1.2 LotteryCandidateFactory (Factory)

**File:** `src/dao/factory/LotteryCandidateFactory.sol`

Can only be called from DAOCommittee (`onlyDAOCommittee`). Deploys and initializes a new LotteryCandidateProxy. Manages the `defaultEntryFee` (base entry fee) and initializes it with this value upon deployment.

### 4.1.3 DAOCommittee_V1 (Governance Hub)

**File:** `src/dao/DAOCommittee_V1.sol`

Calls LotteryCandidateFactory via the `createLotteryCandidate()` function. Overall manages candidate registration, committee membership management, agenda voting, and activity rewards.

---

## 4.2 Data Flow

### 4.2.1 Deposit Flow

```
User: depositTON(100 TON)
    │
    ├── 1. TON.transferFrom(user → LotteryCandidate, 100e18)
    ├── 2. WTON.swapFromTON(100e18)   // 100 TON → 100e27 WTON
    ├── 3. WTON.approve(DepositManager, 100e27)
    ├── 4. DepositManager.deposit(
    │         layer2 = address(this),     // LotteryCandidate = layer2
    │         account = address(this),    // LotteryCandidate = depositor
    │         amount = 100e27
    │      )
    ├── 5. _balances[user] += 100e27     // Internal balance update
    ├── 6. totalDeposited += 100e27
    └── 7. emit Deposited(user, 100e27)
```

**Key Points:**
- All assets are stored integrally in `DepositManager` under the LotteryCandidate name
- Individual user stakes are only tracked through the `_balances` mapping
- TON → WTON Conversion ratio: 1 TON = 1e9 WTON (decimals difference: 18 → 27)

### 4.2.2 Lottery Entry and Draw Flow

```
User: enterLottery()
    │
    ├── 1. require(_balances[user] >= entryFee)
    ├── 2. _balances[user] -= entryFee
    ├── 3. _roundPrizePool[currentRound] += entryFee
    ├── 4. _roundParticipants[round].push(user)
    ├── 5. _roundEntered[round][user] = true
    └── 6. emit LotteryEntered(round, user, entryFee)
```

```
Operator: drawWinner()
    │
    ├── 1. require(_roundParticipants[round].length > 0)
    ├── 2. randomIndex = uint256(keccak256(
    │         block.prevrandao, block.timestamp, round, participants.length
    │      )) % participants.length
    ├── 3. winner = _roundParticipants[round][randomIndex]
    ├── 4. _balances[winner] += _roundPrizePool[round]   // Pay prize
    ├── 5. _roundWinner[round] = winner
    ├── 6. _roundDrawn[round] = true
    ├── 7. currentRound++                                 // Next round
    ├── 8. Apply pendingEntryFee (if any)
    └── 9. emit LotteryWinnerDrawn(round, winner, prize)
```

**Key Points:**
- Entry fees only move within internal balances (no actual token transfers)
- Winner-Takes-All: The winner receives the entire prize pool
- Changing the entry fee: `setEntryFee()` → Stores in `pendingEntryFee` → Applied to the next round upon `drawWinner()`
- Randomness: Based on `block.prevrandao` (manipulatable on Mainnet → See [Security Considerations](./08-security.md))

### 4.2.3 Seigniorage Distribution Flow

```
Anyone: updateSeigniorage()
    │
    ├── 1. coinage = SeigManager.coinages(address(this))
    ├── 2. prevTotal = coinage.totalSupply()          // Record prev total supply
    ├── 3. SeigManager.updateSeigniorage(address(this))  // Seigniorage rebase
    ├── 4. afterTotal = coinage.totalSupply()          // After total supply
    ├── 5. increase = afterTotal - prevTotal           // Increase = seigniorage
    │
    └── _distributeSeigniorage(increase):
        ├── for each depositor in _depositors:
        │   ├── share = increase * _balances[depositor] / totalDeposited
        │   └── _balances[depositor] += share
        ├── totalDeposited += increase
        └── emit SeigniorageDistributed(increase, depositorCount)
```

**Key Points:**
- Seigniorage = Coinage `totalSupply` increase
- If distributed after balance reduced by lottery entry, received proportionally to reduced balance
- Dust (division remainder) is allocated to the last depositor
- First-Call Trap: In V2 mode, the first call only sets `startBlock` without distributing rewards → See [Known Issues](./09-known-issues.md)

### 4.2.4 Withdrawal Flow

```
User: requestWithdrawal(amount)
    │
    ├── 1. require(_balances[user] >= amount)
    ├── 2. _balances[user] -= amount
    ├── 3. totalDeposited -= amount
    ├── 4. DepositManager.requestWithdrawal(address(this), amount)
    ├── 5. withdrawalRequests.push({user, amount, block.number, false})
    └── 6. emit WithdrawalRequested(user, amount, index)

[Wait Period: GLOBAL_WITHDRAWAL_DELAY blocks elapsed]
  - Test: 10 blocks (demo)
  - Production: 93,046 blocks (~approx 2 weeks)

Anyone: processWithdrawal(n)
    │
    ├── for i in 0..n:
    │   ├── req = withdrawalRequests[lastProcessedRequestIndex]
    │   ├── require(block.number >= req.requestBlock + delay)
    │   ├── DepositManager.processRequest(address(this), false)
    │   ├── WTON.transfer(req.user, req.amount)
    │   ├── req.processed = true
    │   └── lastProcessedRequestIndex++
    └── emit WithdrawalProcessed(...)
```

**Key Points:**
- Processes withdrawal requests with a FIFO structure
- Instant internal balance deduction upon request (prevents lottery entry)
- Anyone can call `processWithdrawal` after the wait period elapses
- Actual WTON moves `DepositManager` → `LotteryCandidate` → `user`

---

[Next: Data Structure →](./05-data-structure.md)
