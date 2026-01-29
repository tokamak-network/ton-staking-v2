# E2E Tests Guide (Go)

> 🔬 End-to-end testing with real Anvil nodes

## 📋 Overview

| **Attribute** | **Value** |
|--------------|-----------|
| **Framework** | Go (testing package) |
| **Location** | `op-e2e/faultproofs/` |
| **Total Tests** | 7 tests (3 system + 4 RAT) |
| **Duration** | ~21 seconds (parallel) |
| **Isolation** | Each test = own Anvil node |

**What E2E tests verify:**
- ✅ Complete system startup
- ✅ Real contract interactions
- ✅ RAT trigger mechanisms
- ✅ DisputeGame integration
- ✅ Evidence submission flows
- ✅ Bond claiming (DelayedWETH)

---

## 🚀 Quick Start

### Step 1: Generate Genesis (First Time Only)
```bash
# From project root
cd /Users/zena/tokamak-projects/ton-staking-v2
make devnet-allocs-offline
```

**What this does:**
- Deploys all contracts to a local Anvil
- Saves state to `.devnet/genesis-l1-staking-v3.json`
- Takes ~30 seconds
- Only needed once (or when contracts change)

### Step 2: Run E2E Tests
```bash
# Option A: From project root
make test-e2e

# Option B: From op-e2e directory
cd op-e2e
make test
```

**Output:**
```
=== RUN   TestTONStakingSystemStartup
--- PASS: TestTONStakingSystemStartup (1.2s)
=== RUN   TestAccountBalances
--- PASS: TestAccountBalances (1.1s)
...
PASS
ok      github.com/tokamak-network/ton-staking-v2/op-e2e/faultproofs    21.345s
```

---

## 🏗️ Architecture

### Genesis-Based Testing

```
┌────────────────────────────────────────────────┐
│  Step 1: Generate Genesis (Once)              │
│                                                │
│  $ make devnet-allocs-offline                 │
│                                                │
│  ┌──────────────────────────────────────┐    │
│  │ .devnet/genesis-l1-staking-v3.json   │    │
│  │ - All contracts pre-deployed          │    │
│  │ - Test accounts funded                │    │
│  │ - Parameters configured               │    │
│  └──────────────────────────────────────┘    │
└────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────┐
│  Step 2: E2E Tests (Parallel Execution)       │
├────────────────────────────────────────────────┤
│  Test 1                Test 2        Test 3   │
│  ↓ Load Genesis        ↓             ↓        │
│  ↓ Start Anvil         ↓             ↓        │
│  ↓ Port: 57340         57341         57342    │
│  ↓ Run Test            ↓             ↓        │
│  ↓ Cleanup             ↓             ↓        │
│  ✓ PASS                ✓             ✓        │
└────────────────────────────────────────────────┘
```

**Key Benefits:**
- 🚀 **Fast:** No manual devnet startup
- 🔒 **Isolated:** Each test = clean state
- ⚡ **Parallel:** All tests run simultaneously
- 🎯 **Consistent:** Same genesis = reproducible

---

## 📂 Test Files Structure

```
op-e2e/
├── faultproofs/
│   ├── rat_system_test.go          # 3 system tests
│   ├── rat_challenge_test.go       # 4 RAT scenarios
│   └── rat_challenge_helpers.go    # Reusable helpers (313 lines)
├── e2eutils/rat/
│   └── system.go                   # Anvil management
└── bindings/
    ├── rat.go                      # RAT contract binding
    ├── wton.go                     # WTON contract binding
    └── ...                         # Other bindings
```

---

## 🧪 Test List

### System Tests (3) - Basic Verification

#### Test 1: System Startup
```bash
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs
```
**Duration:** ~1 second  
**Verifies:**
- ✓ L1 client connects (Chain ID: 900)
- ✓ TON contract deployed
- ✓ WTON contract deployed
- ✓ RAT contract deployed
- ✓ SeigManager contract deployed
- ✓ DisputeGameFactory deployed

**Example Output:**
```
✓ L1 client connected (Chain ID: 900)
✓ TON contract deployed at 0x... (12345 bytes)
✓ WTON contract deployed at 0x... (23456 bytes)
✓ RAT contract deployed at 0x... (34567 bytes)
```

---

#### Test 2: Account Balances
```bash
GOWORK=off go test -v -run TestAccountBalances ./faultproofs
```
**Duration:** ~1 second  
**Verifies:**
- ✓ Deployer has ETH balance
- ✓ Validator has ETH balance

---

#### Test 3: RAT Contract Call
```bash
GOWORK=off go test -v -run TestRATContractCall ./faultproofs
```
**Duration:** ~1 second  
**Verifies:**
- ✓ RAT.getMinimumCollateral() works
- ✓ RAT.getActiveValidatorCount() works

---

### RAT Scenario Tests (4) - Real Workflows

#### Test 4: Validator Registration
```bash
GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs
```
**Duration:** ~4 seconds  
**Flow:**
1. Check validator WTON balance (100,000 WTON)
2. WTON.approve(depositManager, 50,000 WTON)
3. DepositManager.deposit(layer2, 50,000 WTON)
4. RAT.registerValidator(systemConfig)
5. Verify: isValidatorActive() == true

**Example Output:**
```
✓ Validator address: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
✓ Deposit amount: 50000000000000000000000000000 WTON
✓ Validator WTON balance: 100000000000000000000000000000
✓ WTON.approve() succeeded
✓ DepositManager.deposit() succeeded
✓ RAT.registerValidator() succeeded
✓ Validator is active
✅ Successfully registered validator with RAT
```

---

#### Test 5: DisputeGame Creation & RAT Trigger
```bash
GOWORK=off go test -v -run TestSimpleRAT_GameCreation ./faultproofs
```
**Duration:** ~6 seconds  
**Flow:**
1. Register validator
2. Verify DisputeGameFactory configuration
   - RAT address set
   - SystemConfig address set
3. Check L1BridgeRegistry mapping
4. Create DisputeGame (triggers RAT)
5. Parse AttentionTestTriggered event

**Example Output:**
```
✓ Validator registered
✓ Active validators: 1
✓ RAT on DisputeGameFactory: 0x...
✓ SystemConfig matches
✓ L1BridgeRegistry mapping confirmed
✓ DisputeGame created
✓ RAT triggered (testID: 0x...)
```

---

#### Test 6: Evidence Submission
```bash
GOWORK=off go test -v -run TestSimpleRAT_EvidenceSubmission ./faultproofs
```
**Duration:** ~8 seconds  
**Flow:**
1. Register validator (collateral: 50,000 WTON)
2. Create DisputeGame → RAT triggers
3. Check bondAmount deducted (10 WTON)
4. Get testID from AttentionTest
5. Submit evidence before deadline
6. Verify collateral restored

**Example Output:**
```
✓ Validator registered with 50000 WTON
✓ DisputeGame created
✓ RAT testID: 0x1234...
✓ bondAmount deducted: 10000000000000000000000000000 WTON
✓ Collateral after deduction: 49990 WTON
✓ submitEvidence() succeeded
✓ Collateral restored: 50000 WTON
```

---

#### Test 7: Challenger Wins (Full Flow) ⭐
```bash
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs
```
**Duration:** ~20 seconds  
**Most Complex Test** - Full challenge game flow

**Flow:**
1. Register validator (50,000 WTON)
2. Create DisputeGame with **WRONG** root claim
3. RAT triggers → deduct bondAmount (10 WTON)
4. Validator attacks root claim
5. Wait for game clock to expire
6. Resolve game → CHALLENGER_WINS
7. **2-Step Bond Claiming:**
   - Step 1: `claimCredit()` → credit recorded in DelayedWETH
   - Step 2: `unlock()` (after 7-day delay) → receive WETH
8. Verify collateral fully restored

**Example Output:**
```
Step 1: Registering validator...
✓ Validator registered

Step 2: Creating DisputeGame with WRONG root claim...
✓ DisputeGame created at: 0x...
✓ RAT testID: 0x...
✓ bondAmount deducted: 10000000000000000000000000000 WTON

Step 3: Parsing RAT trigger event...
✓ RAT triggered successfully

Step 4: Validator attacks wrong root claim...
✓ Attack tx mined (status: 1, gas: 123456)

Step 5: Waiting for game clock to expire...
✓ Advancing time by 302400 seconds
✓ Game clock expired

Step 6: Resolving game...
✓ Game resolved: CHALLENGER_WINS

Step 7: Claiming bonds (2-step process)...
✓ Step 1: claimCredit() succeeded
✓ Credit recorded in DelayedWETH
✓ Step 2: Advancing time by 604800 seconds (7 days)
✓ Step 2: unlock() succeeded
✓ WETH balance increased

Step 8: Verifying collateral restoration...
✓ Final collateral: 50000 WTON (fully restored)
```

---

## 🔧 Helper Functions

### Account Setup
```go
setupTestAccounts(t, sys)
// Creates:
// - validator (Anvil account #3)
// - deployer (Anvil account #1)
// - proposer (Anvil account #4)
```

### Contract Connection
```go
connectTestContracts(t, sys)
// Connects to:
// - RAT, WTON, SeigManager, DepositManager
```

### Validator Registration
```go
registerValidatorWithTON(t, sys, contracts, auth, depositAmount)
// 1. WTON.approve()
// 2. DepositManager.deposit()
// 3. RAT.registerValidator()
```

### Game Creation
```go
createDisputeGameWithWrongClaim(t, sys, auth)
// Creates game with invalid root claim
// Returns: receipt, gameAddress
```

### Event Parsing
```go
parseRATTriggerEventWithBatchIndex(t, receipt, validator)
// Returns: testID, batchIndex, triggered
```

---

## 💻 Running Tests

### All Tests
```bash
cd op-e2e
make test
```

### Specific Test
```bash
cd op-e2e
GOWORK=off go test -v -run <TestName> ./faultproofs
```

### With Timeout
```bash
cd op-e2e
GOWORK=off go test -v ./faultproofs -timeout 300s
```

### Save Logs
```bash
cd op-e2e
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs 2>&1 | tee test.log
```

### Sequential Execution (No Parallel)
```bash
cd op-e2e
GOWORK=off go test -v -p 1 ./faultproofs
```

---

## 🐛 Troubleshooting

### Genesis File Not Found
**Error:** `Genesis file not found at .devnet/genesis-l1-staking-v3.json`

**Fix:**
```bash
cd /Users/zena/tokamak-projects/ton-staking-v2
make devnet-allocs-offline
```

---

### Port Already in Use
**Error:** `bind: address already in use`

**Fix:**
```bash
# Kill existing Anvil processes
pkill anvil

# Or run tests sequentially
cd op-e2e
GOWORK=off go test -v -p 1 ./faultproofs
```

---

### Test Timeout
**Error:** `panic: test timed out after 2m0s`

**Fix:**
```bash
cd op-e2e
GOWORK=off go test -v ./faultproofs -timeout 300s
```

---

### Clear Test Cache
```bash
cd op-e2e
make clean
```

---

## 📊 Test Summary Table

| Test | Duration | Purpose | Complexity |
|------|----------|---------|------------|
| **TestTONStakingSystemStartup** | ~1s | Contract deployment verification | ⭐ Easy |
| **TestAccountBalances** | ~1s | Account funding verification | ⭐ Easy |
| **TestRATContractCall** | ~1s | Contract call verification | ⭐ Easy |
| **TestSimpleRAT_ValidatorRegistration** | ~4s | Validator registration flow | ⭐⭐ Medium |
| **TestSimpleRAT_GameCreation** | ~6s | DisputeGame + RAT trigger | ⭐⭐ Medium |
| **TestSimpleRAT_EvidenceSubmission** | ~8s | Evidence submission flow | ⭐⭐⭐ Hard |
| **TestSimpleRAT_ChallengerWins** | ~20s | Full challenge + bond claim | ⭐⭐⭐⭐ Expert |

---

## 🎯 What Each Test Validates

### System Tests
- [x] All contracts deployed with code
- [x] Chain ID correct (900)
- [x] Test accounts funded
- [x] Contract functions callable

### RAT Scenario Tests
- [x] Validator registration (deposit + register)
- [x] RAT trigger on DisputeGame creation
- [x] Bond deduction (pre-slashing)
- [x] Evidence submission
- [x] Bond restoration on success
- [x] Challenge game flow
- [x] 2-step bond claiming (DelayedWETH)
- [x] Full collateral restoration

---

## 📚 Related Documentation

- **Genesis Setup:** [op-e2e-genesis-setup.md](./op-e2e-genesis-setup.md)
- **Unit Tests:** [unit-tests.md](./unit-tests.md)
- **Integration Tests:** [integration-tests.md](./integration-tests.md)

---

## 🔗 Quick Links

- **Test Code:** `op-e2e/faultproofs/`
- **Helper Code:** `op-e2e/faultproofs/rat_challenge_helpers.go`
- **System Util:** `op-e2e/e2eutils/rat/system.go`
- **Bindings:** `op-e2e/bindings/`
