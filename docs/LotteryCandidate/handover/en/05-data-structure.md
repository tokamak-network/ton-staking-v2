# 5. Data Structure

[← Back to Table of Contents](./README.md) | [← Previous: Core Business Logic](./04-business-logic.md)

---

## 5.1 Storage Schema (LotteryCandidateStorage)

**File:** `src/dao/LotteryCandidateStorage.sol`

### Proxy Storage (Inherited from ProxyStorage)

| Variable Name | Type | Description |
|--------|------|------|
| `pauseProxy` | `bool` | Proxy pause flag |
| `proxyImplementation` | `mapping(uint256 => address)` | Implementation address by index |
| `aliveImplementation` | `mapping(address => bool)` | Implementation active state |
| `selectorImplementation` | `mapping(bytes4 => address)` | Implementation routing by function selector |

### Candidate Basic Information

| Variable Name | Type | Description |
|--------|------|------|
| `_supportedInterfaces` | `mapping(bytes4 => bool)` | ERC165 supported interfaces map |
| `isLayer2Candidate` | `bool` | Whether it is a Layer2 candidate |
| `candidate` | `address` | Operator address |
| `memo` | `string` | Candidate description/memo |
| `committee` | `address` | DAOCommitteeProxy address |
| `seigManager` | `address` | SeigManager address |

### External Integration Addresses

| Variable Name | Type | Description |
|--------|------|------|
| `depositManager` | `address` | DepositManager contract address |
| `ton` | `address` | TON token contract address |
| `wton` | `address` | WTON token contract address |

### Internal Balance Tracking

| Variable Name | Type | Unit | Description |
|--------|------|------|------|
| `_balances` | `mapping(address => uint256)` | WTON (27 decimals) | Individual user internal balances |
| `totalDeposited` | `uint256` | WTON (27 decimals) | Total deposit sum (sum of `_balances`) |
| `_depositors` | `address[]` | - | Depositor address list (never deleted) |
| `_isDepositor` | `mapping(address => bool)` | - | Depositor registration status |

### Lottery System

| Variable Name | Type | Unit | Description |
|--------|------|------|------|
| `currentRound` | `uint256` | - | Current lottery round number |
| `_roundParticipants` | `mapping(uint256 => address[])` | - | Array of participant addresses by round |
| `_roundEntered` | `mapping(uint256 => mapping(address => bool))` | - | Participation status by round |
| `_roundWinner` | `mapping(uint256 => address)` | - | Winner address by round |
| `_roundDrawn` | `mapping(uint256 => bool)` | - | Draw completion status by round |
| `entryFee` | `uint256` | WTON (27 decimals) | Current round entry fee |
| `pendingEntryFee` | `uint256` | WTON (27 decimals) | Entry fee to be applied in the next round |
| `hasPendingEntryFee` | `bool` | - | Whether there is a pending entry fee |
| `_roundPrizePool` | `mapping(uint256 => uint256)` | WTON (27 decimals) | Accumulated prize pool by round |

### Withdrawal Management

| Variable Name | Type | Description |
|--------|------|------|
| `withdrawalRequests` | `WithdrawalRequest[]` | Withdrawal request queue (FIFO) |
| `lastProcessedRequestIndex` | `uint256` | Index of the last processed request |

### Seigniorage Tracking

| Variable Name | Type | Unit | Description |
|--------|------|------|------|
| `lastCoinageTotalSupply` | `uint256` | WTON (27 decimals) | Last recorded Coinage total supply |

---

## 5.2 WithdrawalRequest Struct

```solidity
struct WithdrawalRequest {
    address user;           // Address of withdrawal requester
    uint256 amount;         // Withdrawal amount (WTON, 27 decimals)
    uint256 requestBlock;   // Block number when request was created
    bool processed;         // Processing completion status
}
```

---

## 5.3 DAOCommittee Storage (LotteryCandidate Related)

**File:** `src/dao/StorageStateCommitteeV2.sol`

| Variable Name | Type | Description |
|--------|------|------|
| `lotteryCandidateFactory` | `address` | LotteryCandidateFactory contract address |
| `blacklist` | `mapping(address => bool)` | Blacklisted candidate contracts |
| `cooldown` | `mapping(address => uint256)` | Cooldown timestamp per candidate |
| `cooldownTime` | `uint256` | Cooldown period (in seconds) |

**File:** `src/dao/StorageStateCommittee.sol`

| Variable Name | Type | Description |
|--------|------|------|
| `candidates` | `address[]` | Array of all registered candidate addresses |
| `members` | `address[]` | Array of current committee members (by slot) |
| `maxMember` | `uint256` | Maximum number of committee members |
| `_candidateInfos` | `mapping(address => CandidateInfo)` | Detailed information per candidate |
| `activityRewardPerSecond` | `uint256` | Activity reward per second (WTON) |

---

## 5.4 State Management Method

### On-chain State
- All states are stored on the Ethereum L1 blockchain
- Implementation can be upgraded with a proxy pattern (storage layout preservation is essential)

### Dual Balance Tracking Structure

```
┌──────────────────────────────┐
│ DepositManager               │
│  └── Coinage Token           │  ← Actual assets (under LotteryCandidate name)
│       totalSupply = Total Pool│
└──────────────────────────────┘
              ▲
              │ 1:1 mapping (temporary mismatch possible depending on timing)
              ▼
┌──────────────────────────────┐
│ LotteryCandidate             │
│  _balances[userA] = 100e27   │  ← Internal ledger (individual user stakes)
│  _balances[userB] = 200e27   │
│  totalDeposited   = 300e27   │
└──────────────────────────────┘
```

### Frontend Caching
- TanStack React Query handles on-chain data caching
- Batch reading (multicall) with the `useReadContracts` hook
- Update to latest data with a manual `refetch()` button

---

## 5.5 Proxy Storage Layout Precautions

```
Slot order:
  ProxyStorage variables
  └── AccessibleCommon variables (including AccessControl)
      └── LotteryCandidateStorage variables
```

> **Important:** When upgrading, you must not insert new variables between existing ones.
> New variables must be added to the **very bottom** of the `LotteryCandidateStorage` file.
> Otherwise, storage slots will be shifted, and existing data will be corrupted.

---

[Next: API Specification →](./06-api-specification.md)
