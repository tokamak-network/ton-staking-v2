# TON Staking V3 Test Documentation

## Quick Start

**From project root (`/ton-staking-v2`):**

```bash
# Unit Tests (Solidity)
forge test

# E2E Tests (Go)
make devnet-allocs-offline  # Generate genesis (once)
make test-e2e               # Run E2E tests
```

**From op-e2e directory:**

```bash
cd op-e2e
make test  # Run E2E tests (requires genesis)
```

## Test Categories

### Unit Tests (Solidity)
- **Run:** `forge test`
- **Total:** 150+ tests
- **Guide:** [unit-tests.md](./unit-tests.md)

### Integration Tests (Solidity)
- **Run:** `forge test --match-path test/v3/V3ScenarioReal.t.sol` (specific) or `forge test` (all)
- **Total:** 8 tests
- **Guide:** [integration-tests.md](./integration-tests.md)

### E2E Tests (Go)
- **Run:** `make test-e2e` (from project root) or `cd op-e2e && make test`
- **Total:** 3 tests
- **Guide:** [e2e-tests.md](./e2e-tests.md)

## Documentation

| File | Description |
|------|-------------|
| [unit-tests.md](./unit-tests.md) | Solidity unit tests guide |
| [integration-tests.md](./integration-tests.md) | Solidity integration tests guide |
| [e2e-tests.md](./e2e-tests.md) | Go E2E tests guide |
| [coverage-matrix.md](./coverage-matrix.md) | Feature coverage status |
| [gap-analysis.md](./gap-analysis.md) | Test gap analysis |

## Full Test Suite

```bash
forge test && make test-e2e
```
