# E2E Tests Guide

## Overview

End-to-end tests verify the complete TON Staking V3 system using Go tests with isolated Anvil nodes. Each test starts its own independent node with genesis state containing all pre-deployed contracts.

**Framework:** Go (testing package)
**Location:** `op-e2e/faultproofs/`
**Total Tests:** 7 tests (3 system + 4 RAT scenario)
**Run Time:** ~21 seconds (parallel execution)

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

### System Test File

**File:** `op-e2e/faultproofs/rat_system_test.go`

**Tests:**
1. `TestTONStakingSystemStartup` - System startup verification
2. `TestAccountBalances` - Account balance verification
3. `TestRATContractCall` - RAT contract interaction

### RAT Scenario Test File

**File:** `op-e2e/faultproofs/rat_challenge_test.go`

**Tests:**
1. `TestSimpleRAT_ValidatorRegistration` - Validator registration flow
2. `TestSimpleRAT_GameCreation` - DisputeGame creation and RAT trigger
3. `TestSimpleRAT_EvidenceSubmission` - Evidence submission to RAT
4. `TestSimpleRAT_ChallengerWins` - Full challenger wins scenario with bond claiming

### Helper Files

**File:** `op-e2e/e2eutils/rat/system.go`

Core system helper that:
- Finds genesis file
- Starts Anvil with genesis
- Connects L1 client
- Provides deployment addresses

**File:** `op-e2e/faultproofs/rat_challenge_helpers.go`

Reusable test helper functions (313 lines):
- **Account Setup**: `setupTestAccounts()` - Creates validator, deployer, proposer accounts
- **Contract Connection**: `connectTestContracts()` - Connects to RAT and TON contracts
- **Deposit Helpers**: `getTestDepositAmount()`, `adjustMinimumCollateral()`
- **Registration**: `registerValidatorWithTON()` - Handles TON approval and validator registration
- **Game Creation**: `createDisputeGame()`, `createDisputeGameWithWrongClaim()`
- **Event Parsing**: `parseRATTriggerEvent()`, `parseRATTriggerEventWithBatchIndex()`, `parseDisputeGameCreatedEvent()`
- **Time Manipulation**: `advanceTimeAndMine()` - Anvil time advancement helper

These helpers eliminate ~400 lines of duplicate code across the 4 RAT scenario tests.

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

## RAT Scenario Tests

### 4. TestSimpleRAT_ValidatorRegistration

Tests the validator registration flow with TON token deposit.

**Duration:** ~4.1s

**Test Flow:**
1. Adjust minimum collateral requirements
2. Approve TON tokens for RAT contract
3. Register validator with deposit
4. Verify registration data

**Verifies:**
- ✅ TON approval succeeds
- ✅ Validator registration succeeds
- ✅ Deposit amount recorded correctly
- ✅ Validator appears in active validator list

**Run:**
```bash
GOWORK=off go test -C op-e2e -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs
```

### 5. TestSimpleRAT_GameCreation

Tests DisputeGame creation and RAT trigger mechanism.

**Duration:** ~6.1s

**Test Flow:**
1. Register validator with TON deposit
2. Proposer creates DisputeGame with wrong root claim
3. RAT automatically triggered
4. Parse AttentionTestTriggered event

**Verifies:**
- ✅ DisputeGame created successfully
- ✅ RAT triggered on wrong root claim
- ✅ Validator selected correctly
- ✅ Validator bond locked (deducted from deposit)

**Run:**
```bash
GOWORK=off go test -C op-e2e -v -run TestSimpleRAT_GameCreation ./faultproofs
```

### 6. TestSimpleRAT_EvidenceSubmission

Tests evidence submission to RAT for dispute resolution.

**Duration:** ~8.1s

**Test Flow:**
1. Register validator
2. Create DisputeGame (triggers RAT)
3. Submit evidence data to RAT
4. Verify EvidenceSubmitted event

**Verifies:**
- ✅ Evidence submission succeeds
- ✅ EvidenceSubmitted event emitted
- ✅ Evidence data recorded on-chain

**Run:**
```bash
GOWORK=off go test -C op-e2e -v -run TestSimpleRAT_EvidenceSubmission ./faultproofs
```

### 7. TestSimpleRAT_ChallengerWins

**Full end-to-end test of challenger winning scenario with bond claiming.**

**Duration:** ~20.1s

**Test Flow:**
1. **Validator Registration** - Register with 50000 TON deposit
2. **Game Creation** - Proposer creates game with wrong root claim (0xFF...)
3. **RAT Trigger** - Validator bond locked automatically
4. **Attack Wrong Claim** - Validator attacks with correct claim (0x00...)
5. **Time Advancement** - Fast-forward past game clock duration
6. **Game Resolution** - Resolve claims and game (CHALLENGER_WINS)
7. **RAT Resolution** - Call RAT.resolveClaim() to restore validator bond
8. **Bond Claiming** - Two-step credit claiming process:
   - Query DelayedWETH delay dynamically (7 days)
   - First claimCredit call: Unlock WETH
   - Advance time by withdrawal delay
   - Second claimCredit call: Transfer ETH

**Verifies:**
- ✅ Validator registered with TON deposit
- ✅ DisputeGame created, RAT triggered
- ✅ Validator bond locked (TotalBondForRAT > 0)
- ✅ Attack transaction succeeds
- ✅ Game resolves with status CHALLENGER_WINS
- ✅ RAT.resolveClaim restores validator bond (TotalBondForRAT = 0)
- ✅ Validator deposit fully restored
- ✅ Game bonds credited (root bond + attack bond)
- ✅ DelayedWETH delay queried dynamically (604800 seconds / 7 days)
- ✅ Credit balance matches total game bonds (0.171325 ETH)
- ✅ First claimCredit unlocks WETH
- ✅ Second claimCredit transfers ETH after delay
- ✅ Credit balance cleared to 0
- ✅ Net ETH gain verified (0.170921 ETH after gas)

**Key Features:**
- **Dynamic Delay Query**: Retrieves withdrawal delay from DelayedWETH contract
- **Two-Step Claiming**: Demonstrates Optimism's credit system mechanics
- **Comprehensive Verification**: Checks RAT bond restoration AND game bond claiming

**Run:**
```bash
GOWORK=off go test -C op-e2e -v -run TestSimpleRAT_ChallengerWins ./faultproofs
```

**Expected Output (Key Sections):**
```
=== RUN   TestSimpleRAT_ChallengerWins
    rat_challenge_test.go:579: === Testing RAT Challenger Wins Flow ===
    rat_challenge_test.go:634: ✓ Validator initial ETH balance: 10000000000000000000000 wei
    rat_challenge_test.go:946: ✓ DelayedWETH address: 0x43a3167835766d01750259047b57bc97d7553608
    rat_challenge_test.go:953: ✓ Withdrawal delay from contract: 604800 seconds (7.0 days)
    rat_challenge_test.go:1009: ✅ ETH balance change matches expected (credit transferred successfully)
    rat_challenge_test.go:1017: ✅ Net ETH gain (credit received minus gas): 170920574303014998 wei (0.170921 ETH)
    rat_challenge_test.go:1040: ✅ Step 8: Net ETH gain after gas: 170920574303014998 wei (0.170921 ETH)
--- PASS: TestSimpleRAT_ChallengerWins (20.14s)
```

### Running All RAT Tests

```bash
# Run all RAT scenario tests
GOWORK=off go test -C op-e2e -v -run TestSimpleRAT ./faultproofs

# Expected output summary
--- PASS: TestSimpleRAT_ValidatorRegistration (4.10s)
--- PASS: TestSimpleRAT_GameCreation (6.12s)
--- PASS: TestSimpleRAT_EvidenceSubmission (8.13s)
--- PASS: TestSimpleRAT_ChallengerWins (20.18s)
PASS
ok      github.com/tokamak-network/ton-staking-v2/op-e2e/faultproofs    20.663s
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

Choose the appropriate file based on test type:

**System Tests:** `op-e2e/faultproofs/rat_system_test.go`
**RAT Scenario Tests:** `op-e2e/faultproofs/rat_challenge_test.go`

```go
func TestSimpleRAT_YourNewScenario(t *testing.T) {
    t.Parallel()  // Enable parallel execution

    // Start system (gets isolated node + genesis)
    sys := rat.StartTONStakingSystem(t)
    callOpts := &bind.CallOpts{Context: sys.Ctx}

    t.Log("=== Testing Your Scenario ===")

    // Setup accounts and contracts using helpers
    accounts := setupTestAccounts(t, sys)
    contracts := connectTestContracts(t, sys)

    // Get deposit amount and adjust collateral
    depositAmount := getTestDepositAmount()
    adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

    // Register validator
    registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)

    // Your test logic here
    // Example: Create dispute game
    rootClaim := [32]byte{0x01, 0x02, 0x03}
    gameReceipt, gameAddress := createDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

    // Parse events
    testID, triggered := parseRATTriggerEvent(t, gameReceipt, accounts.Validator.Addr)
    if triggered {
        t.Logf("✓ RAT triggered with test ID: %x", testID)
    }

    t.Log("=== Test Complete ===")
}
```

### 2. Common Patterns

**Using Test Helpers (Recommended):**
```go
// Setup accounts and contracts
accounts := setupTestAccounts(t, sys)
contracts := connectTestContracts(t, sys)

// Get deposit amount and adjust collateral
depositAmount := getTestDepositAmount()
adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

// Register validator
registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)

// Create dispute game
rootClaim := [32]byte{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}
gameReceipt, gameAddress := createDisputeGameWithWrongClaim(t, sys, accounts.Proposer.Auth)

// Parse RAT trigger event
testID, ratTriggered := parseRATTriggerEvent(t, gameReceipt, accounts.Validator.Addr)

// Advance time
advanceTimeAndMine(t, sys, 604800) // 7 days
```

**Working with FaultDisputeGame:**
```go
// Connect to game
game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
require.NoError(t, err)

// Query DelayedWETH dynamically
wethAddr, err := game.Weth(callOpts)
require.NoError(t, err)

delayedWETH, err := bindings.NewDelayedWETHMinimal(wethAddr, sys.L1Client)
require.NoError(t, err)

withdrawalDelay, err := delayedWETH.Delay(callOpts)
require.NoError(t, err)
```

### 3. Run Your Test

```bash
cd op-e2e
GOWORK=off go test -v -run TestSimpleRAT_YourNewScenario ./faultproofs
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
# Generate genesis (run once)
make devnet-allocs-offline

# Run all E2E tests (system + RAT scenarios)
make test-e2e

# Run only system tests
cd op-e2e && GOWORK=off go test -v -run "TestTONStakingSystemStartup|TestAccountBalances|TestRATContractCall" ./faultproofs

# Run only RAT scenario tests
cd op-e2e && GOWORK=off go test -v -run TestSimpleRAT ./faultproofs

# Run specific test
cd op-e2e && GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs

# Clean genesis
make devnet-clean
```

## Next Steps

- [Unit Tests Guide](./unit-tests.md) - Solidity unit tests
- [Integration Tests Guide](./integration-tests.md) - Full scenario testing
- [Coverage Matrix](./coverage-matrix.md) - Coverage details
- [Adding New Tests](#adding-new-e2e-tests) - How to extend E2E suite
