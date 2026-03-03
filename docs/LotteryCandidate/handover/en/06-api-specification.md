# 6. API Specification Summary

[← Back to Table of Contents](./README.md) | [← Previous: Data Structure](./05-data-structure.md)

---

## 6.1 LotteryCandidate Function Specification

### User Functions (Callable by Anyone)

| Function | Parameter | Return Value | Description |
|------|----------|--------|------|
| `depositTON` | `uint256 tonAmount` | `bool` | Deposit TON (requires prior approve) |
| `depositWTON` | `uint256 wtonAmount` | `bool` | Deposit WTON (requires prior approve) |
| `onApprove` | `address owner, address spender, uint256 amount, bytes data` | `bool` | TON's `approveAndCall` callback (automatic deposit processing) |
| `enterLottery` | - | `bool` | Enter current round lottery (deducts entry fee from balance) |
| `requestWithdrawal` | `uint256 amount` | `bool` | Request withdrawal (in WTON, 27 decimals) |
| `processWithdrawal` | `uint256 n` | `bool` | Process n pending withdrawal requests |
| `updateSeigniorage` | - | `bool` | Update seigniorage and distribute it to all depositors |

### Operator Only Functions (`onlyOperator`)

> Operator = `candidate` address (operator set upon initialization)

| Function | Parameter | Return Value | Description |
|------|----------|--------|------|
| `drawWinner` | - | `address winner` | Draw winner for current round, proceed to next round |
| `setEntryFee` | `uint256 _entryFee` | - | Set entry fee to be applied from the next round |
| `changeMember` | `uint256 _memberIndex` | `bool` | Challenge DAO committee member slot |
| `retireMember` | - | `bool` | Retire from DAO committee (adds to blacklist) |
| `castVote` | `uint256 _agendaID, uint256 _vote, string _comment` | - | Agenda vote (0=abstain, 1=approve, 2=reject) |
| `claimActivityReward` | - | - | Claim DAO activity reward in WTON |

### Admin Only Functions (`onlyOwner`)

| Function | Parameter | Return Value | Description |
|------|----------|--------|------|
| `initialize` | `address _candidate, bool _isLayer2Candidate, string _memo, address _committee, address _seigManager, address _depositManager, address _ton, address _wton, uint256 _entryFee` | - | Initialize (Can only be called once) |
| `setSeigManager` | `address _seigManager` | - | Change SeigManager address |
| `setCommittee` | `address _committee` | - | Change Committee address |
| `setDepositManager` | `address _depositManager` | - | Change DepositManager address |
| `setTon` | `address _ton` | - | Change TON token address |
| `setWton` | `address _wton` | - | Change WTON token address |
| `setMemo` | `string _memo` | - | Change memo |

### Read-Only Functions (View)

| Function | Parameter | Return Value | Description |
|------|----------|--------|------|
| `balanceOf` | `address account` | `uint256` | User's internal WTON balance (27 decimals) |
| `totalStaked` | - | `uint256` | Coinage total supply |
| `totalDeposited` | - | `uint256` | Total internal deposit sum |
| `getDepositors` | - | `address[]` | List of all depositor addresses |
| `getDepositorCount` | - | `uint256` | Number of depositors |
| `getRoundParticipants` | `uint256 round` | `address[]` | List of round participant addresses |
| `getRoundParticipantCount` | `uint256 round` | `uint256` | Number of round participants |
| `roundEntered` | `uint256 round, address account` | `bool` | Whether a specific account entered the round |
| `roundWinner` | `uint256 round` | `address` | Round winner address |
| `roundDrawn` | `uint256 round` | `bool` | Whether the round draw is complete |
| `roundPrizePool` | `uint256 round` | `uint256` | Round prize pool (WTON, 27 decimals) |
| `currentRound` | - | `uint256` | Current round number |
| `entryFee` | - | `uint256` | Current entry fee (WTON, 27 decimals) |
| `candidate` | - | `address` | Operator address |
| `operator` | - | `address` | Returns `address(this)` (ILayer2) |
| `isLayer2` | - | `bool` | Always returns `true` (ILayer2) |
| `isCandidateContract` | - | `bool` | Always returns `true` |

---

## 6.2 Event Specification

| Event | Parameter | Triggered When |
|--------|----------|----------|
| `Deposited` | `address indexed account, uint256 amount` | Upon deposit completion |
| `LotteryEntered` | `uint256 indexed round, address indexed account, uint256 entryFee` | Upon entering lottery |
| `LotteryWinnerDrawn` | `uint256 indexed round, address indexed winner, uint256 prizeAmount` | Upon drawing winner |
| `SeigniorageReceived` | `uint256 amount` | Upon receiving seigniorage |
| `SeigniorageDistributed` | `uint256 totalAmount, uint256 depositorCount` | Upon completing seigniorage distribution |
| `WithdrawalRequested` | `address indexed account, uint256 amount, uint256 requestIndex` | Upon withdrawal request |
| `WithdrawalProcessed` | `address indexed account, uint256 amount, uint256 requestIndex` | Upon withdrawal processing completion |
| `EntryFeeUpdated` | `uint256 newEntryFee, uint256 effectiveFromRound` | Upon setting entry fee change |
| `TonUpdated` | `address ton` | Upon TON address change |
| `WtonUpdated` | `address wton` | Upon WTON address change |
| `DepositManagerUpdated` | `address depositManager` | Upon DepositManager address change |

---

## 6.3 DAOCommittee_V1 Functions related to LotteryCandidate

| Function | Access Control | Description |
|------|----------|------|
| `createLotteryCandidate(string memo)` | Anyone | Create LotteryCandidate (deploy proxy + initialize via Factory) |
| `changeMember(uint256 _memberIndex)` | Candidate Contract Only | Replace committee member with higher staking than the existing member |
| `retireMember()` | Member Contract Only | Retire from committee (automatically added to blacklist) |
| `castVote(uint256 _agendaID, uint256 _vote, string _comment)` | Member Contract Only | Agenda vote |
| `claimActivityReward(address _receiver)` | Member Contract Only | Claim activity reward WTON (paid from DAO Vault) |

---

## 6.4 Frontend ABI Coverage

**File:** `demo-frontend/src/contracts/abi.ts`

ABI functions defined in the frontend and actual usage:

| Function | ABI Definition | UI Implementation |
|------|---------|---------|
| `depositTON` | ○ | ○ (`DepositForm.tsx`) |
| `depositWTON` | ○ | X (ABI only exists) |
| `enterLottery` | ○ | ○ (`LotteryActions.tsx`) |
| `drawWinner` | ○ | ○ (`LotteryActions.tsx`) |
| `updateSeigniorage` | ○ | ○ (`SeignioragePanel.tsx`) |
| `requestWithdrawal` | ○ | **X (UI not implemented)** |
| `processWithdrawal` | ○ | **X (UI not implemented)** |
| `setEntryFee` | ○ | X (ABI only exists) |
| `balanceOf` | ○ | ○ (Multiple components) |
| `totalDeposited` | ○ | ○ |
| `currentRound` | ○ | ○ |
| `entryFee` | ○ | ○ |
| Other View functions | ○ | ○ |

---

[Next: Deployment and Operations →](./07-deployment-operations.md)
