# RAT Fast Withdrawal Documentation

## Overview

RAT Fast Withdrawal enables instant withdrawals (bypassing the 7-day delay) using RAT validator signatures.

---

## Documents

### 1. Integration Guide
**[RAT_FAST_WITHDRAWAL_INTEGRATION.md](./RAT_FAST_WITHDRAWAL_INTEGRATION.md)**

Complete guide for Layer2 projects to integrate RAT Fast Withdrawal:
- OptimismPortal2 modifications (onlyRAT access control)
- RAT Fee System (TON-based fixed fee)
- Deployment steps
- Verification checklist

**Target audience:** Layer2 development teams

---

### 2. Feature Documentation
**[GAME_CLAIM_CHECK.md](./GAME_CLAIM_CHECK.md)**

Latest feature: DisputeGame claim check functionality
- Blocks fast withdrawal if disputes exist
- Implementation details
- Test coverage
- Security considerations

**Target audience:** Developers, Security reviewers

---

## Implementation Status

### Completed

**Smart Contracts (Phase 1)**
- RAT Fast Withdrawal contract (`src/validator/RATFastWithdrawal.sol`)
- BLS aggregated signature verification
- Adjacent leaves proof verification
- Game claim check (blocks if dispute exists)
- Unanimous consensus requirement (100% validators)
- Fee system: Fixed TON fee (e.g., 10 TON)
- Fee distribution (Aggregator + Validators) in TON
- Fee reclaim on timeout
- OptimismPortal2 integration (`proveAndRequestFastWithdrawal` - RAT only)
- Test coverage: 704 Solidity tests passed

**Go Clients (Phase 2)**
- Validator Node (`clients/fast-withdrawal/validator/`) - 46MB binary
- Aggregator Service (`clients/fast-withdrawal/aggregator/`) - 47MB binary
- libp2p P2P network (GossipSub + DHT)
- BLS signing (herumi/bls-eth-go-binary)
- L1 event monitoring, L2 proof generation
- Off-chain BLS signature verification
- *big.Int bitmap (unlimited validators)

**Portal Integration (Phase 3)**
- OptimismPortal2 `proveAndRequestFastWithdrawal()` - RAT only access control
- OptimismPortal2 `setWithdrawalVerified()` - RAT only
- OptimismPortal2 `fastWithdrawalFinalize()` - RAT verified
- op-proposer gas limit fix

### Pending
- E2E integration tests (devnet)
- Testnet deployment

---

## Architecture

### Fee Flow (TON)
```
User → TON.approve(RAT, fee)
  ↓
User → RAT.requestFastWithdrawal()
  ↓ RAT collects TON fee via transferFrom
  ↓ RAT calls Portal.proveAndRequestFastWithdrawal() (RAT only)
  ↓
Validators → BLS signatures (offchain)
  ↓
Aggregator → RAT.verifyAndExecuteFastWithdrawal()
  ↓ Portal.setWithdrawalVerified + fastWithdrawalFinalize
  ↓ TON fees distributed (aggregator + validators)
  ↓
Done (3 minutes vs 7 days)

Timeout:
  User → RAT.reclaimFee() → TON refund
  User → Portal.finalizeWithdrawalTransaction() → 7-day path
```

### Access Control
| Function | Caller | Restriction |
|----------|--------|-------------|
| `Portal.proveAndRequestFastWithdrawal` | **RAT only** | `OptimismPortal_OnlyRAT` |
| `Portal.setWithdrawalVerified` | **RAT only** | `OptimismPortal_OnlyRAT` |
| `RAT.requestFastWithdrawal` | Anyone (User) | TON fee required |
| `RAT.verifyAndExecuteFastWithdrawal` | Anyone (Aggregator) | Valid BLS signature |
| `RAT.reclaimFee` | Anyone | Deadline passed |

---

## Quick Links

### Current Implementation
- **RAT Fast Withdrawal:** `src/validator/RATFastWithdrawal.sol`
- **Fast Withdrawal Library:** `src/libraries/RATFastWithdrawalLib.sol`
- **BLS Library:** `src/libraries/BLS12381.sol`
- **Adjacent Leaves Verifier:** `src/libraries/AdjacentLeavesVerifier.sol`

### Tests
- **Scenarios:** `test/v3/scenarios/FastWithdrawalScenarios.t.sol`
- **E2E Tests:** `test/v3/scenarios/FastWithdrawalE2E.t.sol`
- **E2E Fork Tests:** `test/v3/scenarios/FastWithdrawalE2EFork.t.sol`

---

## Related Documentation

For OptimismPortal2 integration planning:
- See: `optimism/ton-staking-v3/RAT_FAST_WITHDRAWAL_INTEGRATION.md`

---

*Last Updated: 2026-02-11*
