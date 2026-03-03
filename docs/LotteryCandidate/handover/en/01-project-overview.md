# 1. Project Overview

[← Back to Table of Contents](./README.md)

---

## 1.1 Purpose

LotteryCandidate is a smart contract project that **combines a Lossless Lottery mechanism on top of Tokamak Network's DAO governance staking system**.

Users can deposit (stake) TON tokens to receive network seigniorage rewards, while simultaneously having the opportunity to participate in round-based lotteries to win prizes. It is structured so that **the principal is preserved, and only the entry fee is exposed to risk**.

## 1.2 Target Users

| User Type | Description |
|-------------|------|
| **Normal Staker** | Users who want to deposit TON, receive seigniorage rewards, and participate in lotteries |
| **Operator** | Operators who create LotteryCandidates, execute lottery draws, and perform DAO committee activities |
| **DAO Committee** | Committee members participating in Tokamak Network governance |

## 1.3 Core Features

| Feature | Description |
|------|------|
| **Unified Staking Management** | Collects user deposits into a single pool to stake in `DepositManager`. Tracks individual stakes via internal balances (`_balances`) |
| **Round-based Lottery** | Deducts a fixed entry fee from internal balances. Winner-Takes-All format. Operator executes the draw |
| **Proportional Seigniorage Distribution** | Distributes the Coinage token total supply increase to all depositors based on their balance ratio when `SeigManager.updateSeigniorage()` is called |
| **Withdrawal Management** | A 2-step process: Withdrawal Request → Waiting Period (Global Withdrawal Delay) → Process Withdrawal |
| **DAO Governance Integration** | Features for committee member challenges, retirements, agenda voting, and claiming activity rewards |

## 1.4 Project Location

This project was developed on the `lotteryCandidate` branch of the **TON Staking V3** monorepo.

- **Monorepo:** `ton-staking-v2` (Entire TON Staking V3 system)
- **Feature Branch:** `lotteryCandidate`
- **Base Branch:** `ton-staking-v2`
- **Related Documentation Directory:** `docs/LotteryCandidate/`

---

[Next: System Architecture →](./02-system-architecture.md)
