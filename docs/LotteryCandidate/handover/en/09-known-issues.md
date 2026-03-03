# 9. Known Issues / Technical Debt

[← Back to Table of Contents](./README.md) | [← Previous: Security Considerations](./08-security.md)

---

## 9.1 Identified Issues

### Issue #1: First-Call Trap

| Item | Details |
|------|------|
| **Severity** | Medium |
| **Status** | Resolved (Bypass) |
| **Location** | `SeigManagerV3_2` (V2 Mode) |
| **Symptoms** | Seigniorage is not distributed upon the first `updateSeigniorage()` call |
| **Cause** | In V2 mode, the first call only sets `startBlock` without actually calculating rewards |
| **Bypass Method** | Automatically calls `updateSeigniorage()` once after deployment in `run-lottery-demo.sh` |
| **Fundamental Solution** | **Not yet resolved.** Needs review to automatically call upon initialization at the contract level or handle it in the factory |

### Issue #2: Same-Block Revert

| Item | Details |
|------|------|
| **Severity** | Low |
| **Status** | Resolved (Bypass) |
| **Location** | `SeigManager` - `LastSeigBlockError` check |
| **Symptoms** | Reverts if deployment and `updateSeigniorage()` are executed in the same block |
| **Bypass Method** | Secure a block interval using `sleep 2` in `run-lottery-demo.sh` |
| **Remarks** | Only occurs under Anvil's `--block-time 1` setting. On mainnet, block intervals naturally exist |

### Issue #3: UI Precision Issue

| Item | Details |
|------|------|
| **Severity** | Low |
| **Status** | Resolved |
| **Location** | `demo-frontend/src/components/SeignioragePanel.tsx` |
| **Symptoms** | Extremely small seigniorage amounts (~0.000000194 WTON) display as "0.0000" when formatted with `toFixed(4)` |
| **Resolution** | Implemented dual display: Scientific notation (`1.94e-7`) + nWTON approximation (`~0.19 nWTON`) |

### Issue #4: Random Number Generation Security

| Item | Details |
|------|------|
| **Severity** | High (Mainnet) / Low (Demo) |
| **Status** | Unresolved |
| **Location** | `src/dao/LotteryCandidate.sol` - `drawWinner()` |
| **Symptoms** | Pseudo-randomness based on `block.prevrandao` can be manipulated by block producers |
| **Required Action** | MUST integrate Chainlink VRF before mainnet deployment |
| **Details** | See [Security Considerations 8.1](./08-security.md#81-random-number-generation-vulnerability-severity-high---mainnet) |

### Issue #5: Withdrawal UI Not Implemented

| Item | Details |
|------|------|
| **Severity** | Medium |
| **Status** | Unresolved |
| **Location** | `demo-frontend/` |
| **Symptoms** | `requestWithdrawal` and `processWithdrawal` ABIs are defined in `abi.ts`, but there are no UI components |
| **Required Action** | Implement withdrawal request/processing components |

### Issue #6: Manual Frontend ABI Management

| Item | Details |
|------|------|
| **Severity** | Low |
| **Status** | Unresolved |
| **Location** | `demo-frontend/src/contracts/abi.ts` |
| **Symptoms** | The ABI is manually written rather than automatically generated from the Solidity source |
| **Risks** | Potential for missed ABI synchronization upon contract changes |
| **Required Action** | Write a script to automatically extract the ABI from Forge build artifacts (`out/`) |

---

## 9.2 Technical Debt

| # | Item | Description | Impact |
|---|------|------|------|
| 1 | **Solidity Version Mismatch** | The main project is `0.8.19`, whereas LotteryCandidate-related files are `0.8.4` | Compatibility warnings during compilation, cannot use latest features |
| 2 | **Proxy Storage Precautions** | `LotteryCandidateStorage` is inherited after `ProxyStorage`. Storage slot order must be carefully monitored | Potential data corruption upon upgrade mistakes |
| 3 | **_depositors Array Non-Deletion** | Depositors whose balance drops to 0 are not removed from the `_depositors` array | Skyrocketing gas costs for seigniorage distribution with a large number of depositors |
| 4 | **totalDeposited/Coinage Mismatch** | Temporary mismatch between `_balances` sum (`totalDeposited`) and Coinage `totalSupply` depending on seigniorage timing | Could impact accurate stake calculations |
| 5 | **Hardcoded Local Chain** | Only the Anvil chain (ID: 31337) is set up in `wagmi.ts` | Required code changes when deploying to testnet/mainnet |
| 6 | **SimpleMockDAOProxy** | A simplified DAO proxy is used in the demo deployment | Must be replaced with the official DAO proxy for production |

---

## 9.3 Seigniorage Troubleshooting Guide

If seigniorage is not being distributed, check the following 4 causes in order:

### Cause 1: Insufficient Block Interval
- **Symptoms:** The `updateSeigniorage()` transaction succeeds, but there is no balance change.
- **Cause:** Not enough blocks have been generated since the last call (`span = currentBlock - lastSeigBlock`).
- **Resolution:** Retry after more blocks have passed (in the demo, use "Advance Blocks" in Dev Tools).

### Cause 2: First-Call Trap
- **Symptoms:** Reward is 0 upon the first initial call.
- **Cause:** V2 mode's first call only sets `startBlock`.
- **Resolution:** Operates normally from the 2nd call onwards. Handled automatically by `run-lottery-demo.sh`.

### Cause 3: Depleted Operator Minimum Stake
- **Symptoms:** The transaction succeeds, but the reward is 0.
- **Cause:** The Operator (LotteryCandidate) balance is less than `SeigManager.minimumAmount()`.
- **Resolution:** Ensure a sufficient amount is deposited (Demo: 1001 TON or more).

### Cause 4: Silent Success
- **Symptoms:** Transaction success ≠ Reward distribution success.
- **Cause:** `SeigManager.updateSeigniorageV2()` returns `true` even if the reward is 0.
- **Resolution:** You must verify actual balance changes.

> **Detailed Documents:**
> - `docs/LotteryCandidate/seigniorage-troubleshooting.md`
> - `docs/LotteryCandidate/seigniorage-update-report.md`

---

[Next: Future Improvements →](./10-future-improvements.md)
