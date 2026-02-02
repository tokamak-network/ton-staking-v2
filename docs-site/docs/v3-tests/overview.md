---
id: overview
title: Test Overview
sidebar_position: 1
---

# TON Staking V3 Test List

> **Last Updated**: 2026-01-27

## Test ID Naming Conventions

| Prefix | Target Contract/Feature | Description |
|--------|-------------------------|-------------|
| SM | SeigManager | Seigniorage Manager tests |
| DM | DepositManager | Deposit/Withdrawal Manager tests |
| LBR | L1BridgeRegistry | L1 Bridge Registry tests |
| L2M | Layer2Manager | Layer2 Manager tests |
| RAT | RAT (Random Attention Test) | Validator attention test related |
| VR | ValidatorReward | Validator reward contract tests |
| MIG | Migration | V2→V3 migration tests |
| INT | Integration | Cross-contract integration tests |
| SEC | Security | Security/permission tests |
| SD | Seigniorage Distribution | Seigniorage distribution formula verification |
| INV | Invariant | Invariant tests |
| E2E | End-to-End | Full scenario tests |
| EDGE | Edge Case | Boundary/edge case tests |
| SCENSEQ | Scenario Sequencer | Sequencer scenario tests |
| SCENVAL | Scenario Validator | Validator scenario tests |
| GAS | Gas Measurement | Gas cost measurement tests |

**Suffix Conventions:**
- `-V2` / `-V3`: Distinguish V2/V3 modes
- `-Type2` / `-Type3`: Distinguish rollupType 2/3
- Numbers: Sequential test numbers (e.g., SM-001, SM-002)

## Test Statistics

### Solidity Tests
- **Total Tests**: 526 passed
- **Coverage**:
  - V3 Effective Coverage: 88.5% (lines)
  - Full System: 54.12% (lines, including infrastructure)
- **Execution Time**: ~2 minutes

### Go Tests
- **op-e2e Tests**: 7 (3 system + 3 RAT scenarios + 1 RAT Client E2E)
- **RAT Client Unit Tests**: 60
- **Total Go Tests**: 67
- **Execution Time**:
  - op-e2e: ~80 seconds
  - RAT Client Unit: ~5 seconds

### Total
- **Solidity**: 526
- **Go E2E**: 7
- **Go Unit**: 60
- **Grand Total**: **593 tests**

---

## Next Steps

For detailed test information, see each category:

- [V2 Mode Tests](v2-mode-tests.md) - 44 tests
- [V3 Mode Tests](v3-mode-tests.md) - 493 tests
- [Scenario Tests](scenario-tests.md) - 18 tests
- [Go E2E Tests](e2e-tests.md) - 7 tests
- [RAT Client Unit Tests](rat-client-unit-tests.md) - 60 tests
