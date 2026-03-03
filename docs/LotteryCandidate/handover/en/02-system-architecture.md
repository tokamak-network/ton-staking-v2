# 2. System Architecture

[← Back to Table of Contents](./README.md) | [← Previous: Project Overview](./01-project-overview.md)

---

## 2.1 Overall Structure Description

LotteryCandidate is an extension module built on top of Tokamak Network's TON Staking V3 system.

```
┌─────────────────────────────────────────────────────────────────┐
│                         User (EOA)                               │
│                    MetaMask / Web3 Wallet                        │
└────────┬──────────────────────────────────────────┬─────────────┘
         │ depositTON / depositWTON                  │ enterLottery
         │ requestWithdrawal                         │ updateSeigniorage
         ▼                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   LotteryCandidateProxy                         │
│                 (Proxy → delegatecall)                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              LotteryCandidate (Implementation)             │  │
│  │                                                           │  │
│  │  _balances: Individual internal balances (WTON, 27 decimals)│  │
│  │  totalDeposited: Total sum of deposits                      │  │
│  │  currentRound: Current lottery round                         │  │
│  │  _roundPrizePool: Prize pool per round                       │  │
│  │  withdrawalRequests[]: Withdrawal request queue              │  │
│  └───────────┬───────────────────────┬───────────────────────┘  │
└──────────────┼───────────────────────┼──────────────────────────┘
               │                       │
     ┌─────────▼──────────┐  ┌────────▼─────────────┐
     │   DepositManager   │  │     SeigManager       │
     │  (Actual Asset     │  │  (Generates Seignio-  │
     │   Storage)         │  │   rage)               │
     │  deposit()         │  │  updateSeigniorage()  │
     │  requestWithdrawal │  │  coinages()           │
     │  processRequest()  │  │                       │
     └────────────────────┘  └───────────────────────┘
               │                       │
     ┌─────────▼──────────┐  ┌────────▼─────────────┐
     │    TON / WTON      │  │   Coinage Token       │
     │  (ERC20 Tokens)     │  │  (Staking Receipt    │
     │                    │  │   Token per L2)         │
     │  TON: 18 decimals  │  │  27 decimals          │
     │  WTON: 27 decimals │  │  totalSupply increase =│
     │  1 TON = 1e9 WTON  │  │  Seigniorage generated │
     └────────────────────┘  └───────────────────────┘
               │
     ┌─────────▼──────────────────────────────────────┐
     │              DAOCommittee_V1                     │
     │  (DAO Governance Hub)                             │
     │                                                 │
     │  createLotteryCandidate() → Calls Factory        │
     │  changeMember() / retireMember()                │
     │  castVote() / executeAgenda()                   │
     │  claimActivityReward()                          │
     └─────────────────────────────────────────────────┘
```

## 2.2 Contract Deployment Flow

```
DAOCommittee_V1.createLotteryCandidate(memo)
    │
    ▼
LotteryCandidateFactory.deploy()
    │
    ├── Deploy new LotteryCandidateProxy()
    ├── Set proxy.upgradeTo(lotteryCandidateImp)
    ├── Call LotteryCandidate.initialize(...)
    ├── Register Layer2Registry.registerAndDeployCoinage()
    └── Transfer proxy admin → to committee
```

## 2.3 Tech Stack Used

| Category | Technology | Version |
|------|------|------|
| **Smart Contract Language** | Solidity | 0.8.19 (Main), 0.8.4 (LotteryCandidate) |
| **Contract Framework** | Foundry (Forge) | Latest |
| **Auxiliary Build** | Hardhat | 2.28.2 |
| **Frontend Framework** | React | 18.2.0 |
| **Bundler** | Vite | 5.0.8 |
| **Frontend Language** | TypeScript | 5.2.2 |
| **CSS Framework** | Tailwind CSS | 3.4.0 |
| **Web3 Library** | wagmi / viem | 2.5.0 / 2.7.0 |
| **State Management** | TanStack React Query | 5.17.0 |
| **Local Blockchain** | Anvil | (Built-in Foundry) |
| **E2E Test Language** | Go | 1.22.6 |
| **Contract Library** | OpenZeppelin | git submodule |
| **L2 Interface** | Optimism (Tokamak fork) | feature/ton-staking-v3 branch |

## 2.4 External Dependencies (Git Submodules)

| Dependency | Path | Branch/Version | Purpose |
|--------|------|------------|------|
| forge-std | `lib/forge-std` | - | Foundry standard test library |
| openzeppelin-contracts | `lib/openzeppelin-contracts` | - | ERC20, SafeERC20, AccessControl |
| optimism | `lib/optimism` | `feature/ton-staking-v3` | L1/L2 Interfaces (DisputeGameFactory, SystemConfig, etc.) |
| tokamak-dao-contracts | `lib/tokamak-dao-contracts` | - | DAO Governance Interfaces |

> **Caution:** When changing commits in the `lib/optimism` submodule, you must explicitly specify `GIT_DIR`. Otherwise, there is a risk of altering the HEAD of the parent repository. (See README.md)

## 2.5 Token System

| Token | Decimals | Description | Unit Conversion |
|------|----------|------|----------|
| TON | 18 | Tokamak Network native token | 1 TON = `1e18` wei |
| WTON | 27 | Wrapped TON (Staking unit) | 1 WTON = `1e27` ray |
| Coinage | 27 | Staking receipt token per L2 | totalSupply increase = seigniorage |

**Conversion:** 1 TON = 1e9 WTON (Internally uses `swapFromTON`)

---

[Next: Directory Structure →](./03-directory-structure.md)
