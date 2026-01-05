# E2E Testing Quick Guide

## 🚀 Quick Start (Single Command)

```bash
# Clean start
make devnet-clean
make devnet-allocs
make test-e2e
```

## 📋 Step-by-Step Guide

### Step 1: Clean Previous State (if exists)
```bash
make devnet-clean
```

### Step 2: Setup Devnet
This will:
- Build Optimism contracts
- Generate devnet allocs
- Start L1 Anvil
- Deploy complete TON Staking V3 system
- Connect RAT to DisputeGameFactory

```bash
make devnet-allocs
make devnet-allocs 2>&1 | tee log-devnet-allocs.log

```

**Expected output:**
```
=== TON Staking V3 Devnet Setup ===
[1/4] Copying devnet state from lib/optimism...
[2/4] Starting L1 devnet...
[3/4] Deploying TON Staking V3 Full System...
[4/4] Verifying RAT connection to DisputeGameFactory...

=== Devnet Setup Complete ===
```

### Step 3: Verify Deployment

**Option A: Quick Status Check**
```bash
make devnet-status
```

**Expected output:**
```
=== Devnet Status ===
L1 RPC (localhost:8545):
  ✓ Running (Chain ID: 900)

RAT Deployment:
  ✓ Deployed
  RAT: 0x...
  DisputeGameFactory: 0x...
```

**Option B: Comprehensive Verification**
```bash
# Verify Optimism contracts in allocs
make devnet-verify-allocs

# Verify Optimism contracts on running Anvil
make devnet-verify-runtime
```

These verification scripts check:
- All critical Optimism L1 contracts (DisputeGameFactory, OptimismPortal, SystemConfig, etc.)
- Contract addresses match between addresses.json and allocs-l1.json
- Contract code is properly deployed on the running Anvil instance

### Step 4: Run Tests

**Option A: All E2E Tests**
```bash
make test-e2e
```

**Option B: Unit Tests Only (fast, no devnet needed)**
```bash
make test-e2e-unit
```

**Option C: Integration Tests Only**
```bash
make test-e2e-integration
```

**Option D: Specific Test**
```bash
cd op-e2e
go test -v -run TestRATTriggerOnGameCreation ./faultproofs/... -timeout 300s
```

### Step 5: Stop Devnet (when done)
```bash
make devnet-down
```

## 🔍 Troubleshooting

### Verify Optimism L1 Deployment
```bash
# Check if Optimism contracts are in allocs
make devnet-verify-allocs

# Check if Optimism contracts are deployed on running Anvil
make devnet-verify-runtime
```

If verification fails:
- **Missing contracts in allocs**: Run `make devnet-clean && make devnet-allocs-optimism`
- **Missing contracts at runtime**: Check if allocs loaded correctly, view anvil logs
- **Address mismatch**: Ensure lib/optimism submodule is on correct commit

### Check if L1 is running
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545
```

### Check deployed contracts
```bash
cat .devnet/addresses.json | jq
cat .devnet/optimism-addresses.json | jq
```

### View L1 logs
```bash
tail -f .devnet/anvil.log
```

### Full reset
```bash
make devnet-clean
make devnet-allocs
```

## 📊 Test Categories

| Category | Count | Devnet | Description |
|----------|-------|--------|-------------|
| Unit | 2 | ❌ | Helper functions, constants |
| Integration | 5 | ✅ | RAT contract interactions |
| E2E | 9 | ✅ | Full Optimism integration |

## 🎯 Key Test Scenarios

1. **RAT Trigger** - DisputeGame creation triggers RAT
2. **Evidence Submission** - Validator submits evidence
3. **Bond Refund** - Game winner gets bond back
4. **Slashing** - Timeout causes validator slashing
5. **Multi-L2** - Multiple L2 chains support
6. **Validator Staking** - Validator registration and removal
7. **Valid Output** - Correct output root defense
8. **Unsafe Proposal** - Missing batch data handling
9. **Future Block** - Future block proposal handling

## 📁 Important Files

- `.devnet/addresses.json` - All contract addresses
- `.devnet/.env` - Environment variables
- `.devnet/anvil.log` - L1 devnet logs
- `op-e2e/faultproofs/` - Test files

## 🔗 Documentation

- [E2E Test Design](docs/e2e-test-design.md)
- [Go E2E Test Guide](docs/test/go-e2e-test-guide.md)
