# LotteryCandidate Project Handover Document

**Date:** 2026-03-03
**Author:** Previous Developer
**Audience:** Successor Developer
**Project Branch:** `lotteryCandidate` (base: `ton-staking-v2`)
**Latest Commit:** `2ab17fa1` (Fixed seigniorage distribution error)

---

## Document Structure

> Each section is separated into an independent document.
> If reading for the first time, read in order starting from section 1. If you need a specific topic, refer to that document individually.

| # | Document | Description | Audience |
|---|------|------|------|
| 1 | [Project Overview](./01-project-overview.md) | Purpose, target users, core features | All |
| 2 | [System Architecture](./02-system-architecture.md) | Overall structural diagram, tech stack, external dependencies | All |
| 3 | [Directory Structure](./03-directory-structure.md) | Explanation of folder/file structures and roles | All |
| 4 | [Core Business Logic](./04-business-logic.md) | Data flow for deposit/lottery/seigniorage/withdrawal | Backend Devs |
| 5 | [Data Structure](./05-data-structure.md) | Storage schema, state management methods | Backend Devs |
| 6 | [API Specification](./06-api-specification.md) | Complete specifications for contract functions/events | Backend + Frontend |
| 7 | [Deployment and Operations](./07-deployment-operations.md) | Execution methods, environment variables, testing methods | Ops/DevOps |
| 8 | [Security Considerations](./08-security.md) | Security vulnerabilities and access controls | All |
| 9 | [Known Issues / Technical Debt](./09-known-issues.md) | Identified issues, technical debt, troubleshooting | All |
| 10| [Future Improvements](./10-future-improvements.md) | Improvement items by priority | PM/Lead |

---

## Onboarding Checklist (3-7 Day Plan)

### Day 1-2: Environment Setup and Demo Execution
- [ ] Clone repository (`git clone --recurse-submodules`)
- [ ] Install Foundry (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- [ ] Install Node.js v18+
- [ ] Run `./run-lottery-demo.sh` to verify full demo operation
- [ ] Add Anvil network to MetaMask and import test accounts
- [ ] Personally experience the flow: Deposit → Enter Lottery → Claim Seigniorage → Draw

### Day 3-4: Understanding Core Code
- [ ] [Data Structure](./05-data-structure.md) → Understand `LotteryCandidateStorage.sol` storage
- [ ] [Business Logic](./04-business-logic.md) → Analyze core flow in `LotteryCandidate.sol`
- [ ] Understand the factory pattern in `src/dao/factory/LotteryCandidateFactory.sol`
- [ ] Trace `createLotteryCandidate()` flow in `src/dao/DAOCommittee_V1.sol`
- [ ] Run and analyze `test/v3/scenarios/LotteryCandidate.t.sol` tests
- [ ] Understand proxy pattern (`LotteryCandidateProxy` → `LotteryCandidate`)

### Day 5-6: Understanding System Integrations
- [ ] Trace deposit/withdrawal flow with `DepositManager`
- [ ] Understand seigniorage generation/distribution mechanism with `SeigManager`
- [ ] [Known Issues](./09-known-issues.md) → Familiarize with Seigniorage Troubleshooting Guide
- [ ] Grasp frontend code (`demo-frontend/`) structure
- [ ] Understand deployment sequence in `script/DeployLotteryDemo.s.sol`

### Day 7: Practice and Verification
- [ ] Run all existing tests (`forge test`) and confirm they pass
- [ ] Try adding a simple test case (e.g., lottery with 3+ participants)
- [ ] Check and reproduce items in the Known Issues list
- [ ] Organize any questions

---

## Reference Documents

| Document | Path | Description |
|------|------|------|
| Project README | `README.md` / `README_kr.md` | Full overview of TON Staking V3 |
| LotteryCandidate Overview | `docs/LotteryCandidate/en/README.md` | Introduction to LotteryCandidate |
| Contract Structure | `docs/LotteryCandidate/en/contracts.md` | Detailed contract explanations |
| Scenario Docs | `docs/LotteryCandidate/en/scenario.md` | Usage scenarios |
| Demo Guide (Detailed) | `docs/LotteryCandidate/kr/demo.md` | Most comprehensive demo guide |
| Seigniorage Issue Report | `docs/LotteryCandidate/seigniorage-update-report.md` | Record of fixing seigniorage bugs |
| Seigniorage Troubleshooting | `docs/LotteryCandidate/seigniorage-troubleshooting.md` | Guide for solving seigniorage issues |
| V3 System Specifications | `docs/specs-kr/` | Complete system specs (12 files) |
| Test Docs | `docs/test/` | Testing guide (8 files) |
| Deployment Guide | `docs/deployment/` | Detailed deployment guide |
| Whitepapers | `docs/*.pdf` | Tokamak Economics V1~V3 |

---

*This document was written as of 2026-03-03 and may require updates when the code changes.*
