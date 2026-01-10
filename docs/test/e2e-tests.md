# E2E Tests Guide

## Overview

End-to-end tests verify the complete TON Staking V3 system using Go tests with isolated Anvil nodes.

**Framework:** Go (testing package)
**Location:** `op-e2e/faultproofs/`
**Total Tests:** 8 tests (3 system + 4 RAT scenario + 1 State Root E2E)

## Documentation

For detailed E2E test documentation, including test architecture, TestRATStateRootAsTarget details, and Type 3 evidence verification, please see:

**👉 [op-e2e/README.md](../../op-e2e/README.md)**

## Quick Start

```bash
# 1. Generate genesis file (once)
make devnet-allocs-offline

# 2. Run E2E tests
make test-e2e

# Or from op-e2e directory
cd op-e2e && make test
```

## Test Files

- **System Tests:** `op-e2e/faultproofs/rat_system_test.go` (3 tests)
- **RAT Scenario Tests:** `op-e2e/faultproofs/rat_challenge_test.go` (4 tests)
- **State Root E2E Test:** `op-e2e/faultproofs/rat_state_root_test.go` (1 test)
- **Test Helpers:** `op-e2e/faultproofs/rat_challenge_helpers.go`
- **System Utils:** `op-e2e/e2eutils/rat/system.go`

## Running Tests

```bash
# All tests (8 tests, ~40s)
make test-e2e

# Specific test
cd op-e2e && go test -v -run TestRATStateRootAsTarget ./faultproofs

# State Root test only
make test-rat-state-root
```

---

**📖 For complete documentation, architecture details, and Type 3 verification flow, see [op-e2e/README.md](../../op-e2e/README.md)**
