# Advanced Slashing Handover Document

> **Date Written**: 2026-03-03
> **Project**: ton-staking-v2 / Advanced Slashing
> **Branches**: `ton-staking-3/dev-slash-front2` (Dev), `ton-staking-v2` (Main)

---

## Document Structure

This handover document is separated by topic. If reading for the first time, it is recommended to read in numerical order.

| # | Document | Description | Target Audience |
|---|----------|-------------|-----------------|
| 1 | [01-overview.md](./01-overview.md) | Project overview, purpose, legacy issues, and solutions | Everyone |
| 2 | [02-architecture.md](./02-architecture.md) | System architecture, overall flow, and layer structure | Everyone |
| 3 | [03-contracts.md](./03-contracts.md) | Core contract changes details (6 components) | Developers |
| 4 | [04-reward-logic.md](./04-reward-logic.md) | Winner determination criteria, reward distribution formula, and security design | Developers |
| 5 | [05-build-deploy.md](./05-build-deploy.md) | Build, deployment pipelines, and Go pipeline | Developers / DevOps |
| 6 | [06-testing.md](./06-testing.md) | Testing guide (Foundry 62, E2E 52) | Developers / QA |
| 7 | [07-issues.md](./07-issues.md) | Resolved key issues, limitations, and precautions | Developers |
| 8 | [08-file-map.md](./08-file-map.md) | Full file path map (Contracts, tests, deployments) | Developers |
| 9 | [09-quickstart.md](./09-quickstart.md) | Quickstart guide for new maintainers | New Maintainers |

---

## One-Line Summary

**A system that evenly distributes slashing rewards to all Challengers who win in the Optimism Fault Proof.**

Previously, only the first counter received a reward, but by introducing the `WinningChallengerTracker` external contract, it tracks all winning Challengers and evenly distributes WTON to them.

---

## Implementation Status

| Phase | Status |
|-------|--------|
| Tracking Layer (WinningChallengerTracker) | ✅ Completed |
| Integration Layer (Factory, Game integration) | ✅ Completed |
| Slashing Layer (Multi-challenger reward distribution) | ✅ Completed |
| Foundry unit tests (62) | ✅ All passed |
| E2E tests - Mock based (41) | ✅ All passed |
| E2E tests - Real FaultDisputeGame (11) | ✅ All passed |

---

## Detailed References

Original design/implementation documents can be found in `docs-study/AdvancedSlash/`.
