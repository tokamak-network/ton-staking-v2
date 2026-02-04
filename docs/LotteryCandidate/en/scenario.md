# Usage Scenario

## Basic Flow

1. **Operator Setup**: Create a candidate via `createLotteryCandidate` and set the entry fee via `setEntryFee`.
2. **Deposit Funds**: Users call `depositTON` or `depositWTON`. Assets are recorded in `_balances` and staked in `DepositManager`.
3. **Lottery Entry**: Users call `enterLottery()`. The entry fee is deducted from their balance and moved to the Prize Pool.
4. **Drawing & Payout**: The operator calls `drawWinner()`. One participant is chosen at random, and the entire Prize Pool is added to their internal balance.
5. **Seigniorage Distribution**: Any user or the operator calls `updateSeigniorage()`. Network rewards are measured and distributed to all depositors proportional to their current share.

## Withdrawal (Unstaking)

1. **Request Withdrawal**: User calls `requestWithdrawal(amount)`. Amount is deducted from their internal balance and requested from `DepositManager`.
2. **Process Withdrawal**: After the withdrawal delay, users call `processWithdrawal()` to receive actual TON/WTON.

## Seigniorage Distribution Mechanism

┌─────────────────────────────────────────────────────────────┐
│                   Call updateSeigniorage()                  │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Record coinage.balanceOf(this) (before)                 │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Call SeigManager.updateSeigniorage()                    │
│     → SeigManager increases coinage factor                  │
│     → All holders' balanceOf() increases (rebase)           │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Record coinage.balanceOf(this) (after)                  │
│     seigniorage = after - before                            │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  4. _distributeSeigniorage(seigniorage)                     │
│     → Proportional distribution to internal _balances       │
│     → totalDeposited += seigniorage                         │
└─────────────────────────────────────────────────────────────┘
