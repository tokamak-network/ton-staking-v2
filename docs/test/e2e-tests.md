# E2E Tests Guide

## Overview

End-to-end tests verify the complete TON Staking V3 system using Go tests with isolated Anvil nodes. Each test starts its own independent node with genesis state containing all pre-deployed contracts.

**Framework:** Go (testing package)
**Location:** `op-e2e/faultproofs/rat_system_test.go`
**Total Tests:** 3 core tests
**Run Time:** ~3 seconds (parallel execution)

## Quick Start

```bash
# 1. Generate genesis file (once)
make devnet-allocs-offline

# 2. Run E2E tests
make test-e2e

# Or from op-e2e directory
cd op-e2e && make test
```

## Architecture

### Genesis-Based Testing (Genesis-Based Testing)

```
┌─────────────────────────────────────────────────┐
│ 1. Generate Genesis (Once)                     │
│    make devnet-allocs-offline                  │
│    └─ Creates .devnet/genesis-l1-staking-v3.json
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│ 2. E2E Tests (Parallel)                        │
├─────────────────────────────────────────────────┤
│ TestTONStakingSystemStartup (Port: 57340)     │
│ TestAccountBalances (Port: 57341)              │
│ TestRATContractCall (Port: 57342)              │
└─────────────────────────────────────────────────┘
     │                │                │
     ▼                ▼                ▼
  [Anvil]         [Anvil]          [Anvil]
  Isolated        Isolated         Isolated
  Node            Node             Node
```

**Key Benefits:**
- ✅ No manual devnet management
- ✅ Tests run in parallel with isolated nodes
- ✅ Each test gets fresh state
- ✅ Fast execution with genesis caching
- ✅ Dynamic port allocation (no conflicts)

## Test Files

### Core E2E Test File

**File:** `op-e2e/faultproofs/rat_system_test.go`

**Tests:**
1. `TestTONStakingSystemStartup` - System startup verification
2. `TestAccountBalances` - Account balance verification
3. `TestRATContractCall` - RAT contract interaction

### Helper Files

**File:** `op-e2e/e2eutils/rat/system.go`

Core system helper that:
- Finds genesis file
- Starts Anvil with genesis
- Connects L1 client
- Provides deployment addresses

## Running E2E Tests

### Prerequisites

```bash
# 1. Install Go (1.22+)
go version

# 2. Install Foundry (for Anvil)
anvil --version

# 3. Generate genesis file
make devnet-allocs-offline
```

### Run All E2E Tests

```bash
# From project root
make test-e2e

# From op-e2e directory
cd op-e2e && make test
```

### Run Specific Test

```bash
cd op-e2e
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs
```

### Run with More Details

```bash
# Verbose output
cd op-e2e
GOWORK=off go test -v ./faultproofs -timeout 300s

# Show anvil logs
cd op-e2e
GOWORK=off go test -v ./faultproofs 2>&1 | grep -E "anvil|✓"
```

## Test Details

### 1. TestTONStakingSystemStartup

Verifies that all contracts are deployed and have code.

**Duration:** ~1.0s

**Verifies:**
- ✅ L1 client connection (Chain ID: 900)
- ✅ TON contract deployed (2798 bytes)
- ✅ WTON contract deployed (4037 bytes)
- ✅ RAT contract deployed (1901 bytes)
- ✅ SeigManager contract deployed (9089 bytes)
- ✅ DisputeGameFactory contract deployed (2059 bytes)

**Run:**
```bash
GOWORK=off go test -C op-e2e -v -run TestTONStakingSystemStartup ./faultproofs
```

**Expected Output:**
```
=== RUN   TestTONStakingSystemStartup
    system.go:152: === TON Staking V3 System Ready ===
    system.go:153: RAT: 0xBa3e08b4753E68952031102518379ED2fDADcA30
    system.go:154: SeigManager: 0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe
    rat_system_test.go:31: ✓ L1 client connected (Chain ID: 900)
    rat_system_test.go:37: ✓ TON contract deployed at 0x0C22... (2798 bytes)
    rat_system_test.go:43: ✓ WTON contract deployed at 0x0F59... (4037 bytes)
    rat_system_test.go:49: ✓ RAT contract deployed at 0xBa3e... (1901 bytes)
--- PASS: TestTONStakingSystemStartup (1.03s)
```

### 2. TestAccountBalances

Verifies test account balances from genesis.

**Duration:** ~1.0s

**Verifies:**
- ✅ TON Staking deployer has ETH balance (10000 ETH)
- ✅ Validator account has ETH balance (10000 ETH)

**Run:**
```bash
GOWORK=off go test -C op-e2e -v -run TestAccountBalances ./faultproofs
```

**Expected Output:**
```
=== RUN   TestAccountBalances
    rat_system_test.go:83: ✓ Deployer 0x7099... has 10000000000000000000000 wei
    rat_system_test.go:92: ✓ Validator 0x90F7... has 10000000000000000000000 wei
--- PASS: TestAccountBalances (1.03s)
```

### 3. TestRATContractCall

Verifies RAT contract is callable.

**Duration:** ~1.0s

**Verifies:**
- ✅ RAT contract address accessible
- ✅ Can create transactor for RAT
- ✅ Contract ready for calls

**Run:**
```bash
GOWORK=off go test -C op-e2e -v -run TestRATContractCall ./faultproofs
```

**Expected Output:**
```
=== RUN   TestRATContractCall
    rat_system_test.go:131: ✓ RAT contract ready for calls at 0xBa3e...
--- PASS: TestRATContractCall (1.03s)
```

## System Architecture

### StartTONStakingSystem Helper

**File:** `op-e2e/e2eutils/rat/system.go:53`

```go
func StartTONStakingSystem(t *testing.T) *TONStakingSystem
```

**What it does:**
1. Finds project root (looks for Makefile + .devnet/)
2. Loads genesis file: `.devnet/genesis-l1-staking-v3.json`
3. Loads deployment addresses: `.devnet/addresses.json`
4. Allocates free port dynamically (e.g., 57340, 57341, 57342)
5. Starts Anvil with genesis: `anvil --init genesis-l1-staking-v3.json --port <port>`
6. Connects L1 client: `http://localhost:<port>`
7. Returns TONStakingSystem with all addresses

**Returns:**
```go
type TONStakingSystem struct {
    T             *testing.T
    Ctx           context.Context
    L1Client      *ethclient.Client
    AnvilCmd      *exec.Cmd
    Addresses     *DeploymentAddresses
}
```

### Deployment Addresses

**File:** `.devnet/addresses.json`

```json
{
  "chainId": 900,
  "ton": "0x0C22C771Dc111c509c869240Fc87B910ED58Cc53",
  "wton": "0x0F598169700525DfBB8f22b678431892e06096cb",
  "ratProxy": "0xBa3e08b4753E68952031102518379ED2fDADcA30",
  "seigManagerProxy": "0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe",
  "disputeGameFactory": "0xaa8847B69905765537bEb988224C1BbF9a91e6fB",
  "systemConfig": "0x7a2e8398A198467102582e768E2F0005c3a5B7e9",
  "accounts": {
    "optimismDeployer": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "tonStakingDeployer": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "validator": "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
  }
}
```

## Parallel Execution

Tests run in **parallel** by default due to `t.Parallel()`:

```go
func TestTONStakingSystemStartup(t *testing.T) {
    t.Parallel()  // Enables parallel execution
    // ...
}
```

**Benefits:**
- Each test gets isolated Anvil node
- Dynamic port allocation prevents conflicts
- Tests complete faster (~3s total vs ~3s sequential)

**Port Allocation:**
```
TestTONStakingSystemStartup → Port 57340
TestAccountBalances         → Port 57341
TestRATContractCall         → Port 57342
```

## Adding New E2E Tests

### 1. Create Test Function

**File:** `op-e2e/faultproofs/rat_system_test.go`

```go
func TestYourNewFeature(t *testing.T) {
    t.Parallel()  // Enable parallel execution

    // Start system (gets isolated node + genesis)
    sys := rat.StartTONStakingSystem(t)
    ctx := sys.Ctx

    t.Log("=== Testing Your Feature ===")

    // Your test logic here
    // ... interact with sys.L1Client
    // ... use sys.Addresses.RATProxy, etc.

    t.Log("=== Test Complete ===")
}
```

### 2. Run Your Test

```bash
cd op-e2e
GOWORK=off go test -v -run TestYourNewFeature ./faultproofs
```

## Genesis File Generation

### How Genesis is Created

**Command:** `make devnet-allocs-offline`

**Process:**
```
1. lib/optimism devnet allocs
   └─ Optimism L1 contracts (DisputeGameFactory, etc.)

2. Load Optimism allocs in Solidity
   └─ vm.loadAllocs("allocs-l1.json")

3. Deploy TON Staking V3 contracts
   └─ TON, WTON, SeigManager, RAT, etc.

4. Dump state to allocs
   └─ vm.dumpState("allocs-l1-staking-v3.json")

5. Convert to genesis format
   └─ jq script wraps allocs with genesis metadata
   └─ Output: genesis-l1-staking-v3.json
```

**Result:**
- **File:** `.devnet/genesis-l1-staking-v3.json` (1.8MB)
- **Contracts:** 104 contracts with code
- **Accounts:** 107 total accounts

### Regenerating Genesis

```bash
# Clean old genesis
make devnet-clean

# Regenerate
make devnet-allocs-offline
```

## Troubleshooting

### Error: Genesis file not found

**Error:**
```
Genesis file not found at .devnet/genesis-l1-staking-v3.json
Run 'make devnet-allocs-offline' first
```

**Fix:**
```bash
make devnet-allocs-offline
```

### Error: Port already in use

**Error:**
```
Error: Address already in use (os error 48)
```

**Cause:** Another Anvil instance is running

**Fix:**
```bash
# Kill all anvil processes
pkill anvil

# Or use different port (automatic in parallel mode)
```

### Error: Tests fail with "no code"

**Cause:** Genesis file is invalid or corrupted

**Fix:**
```bash
# Regenerate genesis
make devnet-clean
make devnet-allocs-offline
```

## Performance Tips

1. **Cache Genesis:** Generate once, reuse for all tests
2. **Run in Parallel:** Use `t.Parallel()` for faster execution
3. **Dynamic Ports:** Let system allocate ports automatically
4. **Clean Shutdown:** Tests auto-cleanup Anvil processes

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Install Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.22'

      - name: Generate Genesis
        run: make devnet-allocs-offline

      - name: Run E2E Tests
        run: make test-e2e
```

## Makefile Commands

```bash
# Generate genesis
make devnet-allocs-offline

# Run E2E tests
make test-e2e

# Run unit tests only (from op-e2e)
cd op-e2e && make test-rat-unit

# Clean genesis
make devnet-clean
```

## Next Steps

- [Unit Tests Guide](./unit-tests.md) - Solidity unit tests
- [Integration Tests Guide](./integration-tests.md) - Full scenario testing
- [Coverage Matrix](./coverage-matrix.md) - Coverage details
- [Adding New Tests](#adding-new-e2e-tests) - How to extend E2E suite
