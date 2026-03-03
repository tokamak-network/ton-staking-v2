# 10. Future Improvements

[← Back to Table of Contents](./README.md) | [← Previous: Known Issues](./09-known-issues.md)

---

## 10.1 Production Readiness (P0-P1)

| Priority | Item | Details | Est. Difficulty |
|---------|------|------|-----------|
| **P0** | Integrate VRF Oracle | Replace the random number of `drawWinner()` with Chainlink VRF v2.5. Requires a 2-step pattern: `requestDraw()` → `fulfillDraw()`. Needs VRF Subscription management to be added. | High |
| **P0** | Security Audit | Security review by a specialized smart contract auditing firm. Minimal scope covering LotteryCandidate + DAOCommittee extensions. | - |
| **P1** | Testnet Deployment | Deploy to Sepolia or Thanos Sepolia to test in a realistic environment. Set up wagmi multi-chain configurations and verify actual gas costs/transactions. | Medium |
| **P1** | Gas Optimization | Measure gas for iterating over the `_depositors` array, stress test large depositor (100+) scenarios, and evaluate batch processing logic if the gas limit is exceeded. | Medium |

---

## 10.2 Feature Improvements (P1-P3)

| Priority | Item | Details | Est. Difficulty |
|---------|------|------|-----------|
| **P1** | Withdrawal UI Implementation | Implement `requestWithdrawal`/`processWithdrawal` frontend components. Display withdrawal status (pending/processable/complete) and a block countdown. | Medium |
| **P2** | Change Entry Fee UI | Call `setEntryFee` from an operator-exclusive panel. Display current/next round entry fee. | Low |
| **P2** | Round Statistics Dashboard | Detailed statistics per round: Total participants, prize pool size, win probability, yield graph. | Medium |
| **P2** | Automatic ABI Generation | An npm script to automatically extract the frontend ABI from Forge build artifacts (`out/LotteryCandidate.sol/LotteryCandidate.json`). | Low |
| **P2** | nftgame-zk-dex Integration | Combine with `nftgame-zk-dex` to introduce engaging card game features beyond simple lotteries, enhancing staking rewards. | Medium |
| **P3** | Mobile Optimization | Improve Tailwind responsive breakpoints, mobile touch UX. | Low |
| **P3** | Frontend E2E Tests | Playwright-based automated tests: Wallet connection → Deposit → Enter Lottery → Draw scenario. | Medium |

---

## 10.3 Architecture Improvements (P1-P3)

| Priority | Item | Details | Est. Difficulty |
|---------|------|------|-----------|
| **P1** | Unify Solidity Versions | Upgrade LotteryCandidate-related files (`0.8.4`) to the project standard (`0.8.19`). Needs checking for breaking changes. | Low |
| **P2** | Event-Driven UI Updates | Subscribe to `Deposited`, `LotteryWinnerDrawn`, and `SeigniorageDistributed` events using `useWatchContractEvent` to reflect changes in real-time instead of polling. | Medium |
| **P2** | Multi-chain wagmi Setup | Add Sepolia, Thanos Sepolia, and Ethereum Mainnet chains to `wagmi.ts`. Dynamically select based on environment variables. | Low |
| **P3** | `_depositors` Cleanup Logic | Mechanism to remove depositors with a 0 balance from the array. Review using a swap-and-pop pattern or EnumerableSet. Requires analysis of trade-offs against gas costs. | High |
| **P3** | Automatic Seigniorage Distribution | Automatically call `updateSeigniorage()` upon deposit/withdrawal to reflect the latest rewards. Trade-off involves increased gas costs. | Medium |

---

## 10.4 Improvement Dependencies

```
P0: VRF Integration ──┐
P0: Security Audit ──┼── P1: Testnet Deployment ──── Mainnet Deployment
P1: Gas Optimization ┘                │
                                 │
P1: Withdrawal UI ─────────────────────┘
P1: Unify Solidity Versions ───────────┘
```

---

*This document was created as of 2026-03-03, and priorities may need to be adjusted based on the project status.*

---

[← Back to Table of Contents](./README.md)
