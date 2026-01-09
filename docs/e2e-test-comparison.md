# E2E Test Scripts Comparison

## Overview
We have 4 different E2E test scripts, each with different complexity levels and requirements.

## Scripts Comparison

| Script | Infrastructure | Complexity | DisputeGame Creation | Works? |
|--------|---------------|------------|---------------------|--------|
| `run-e2e-test.sh` | Kurtosis (full devnet) | High | op-proposer (automatic) | ✅ Yes |
| `run-e2e-test-simple.sh` | Manual (L1+L2+op-node+proposer) | Very High | op-proposer (manual) | ⚠️ Complex setup |
| `run-e2e-test-minimal.sh` | Anvil + Mock op-node | Low | Mock only | ✅ Yes (limited) |
| `run-e2e-test-final.sh` | Anvil + geth | Medium | Forge script (manual) | ✅ Yes (practical) |

## Detailed Analysis

### 1. run-e2e-test.sh (Kurtosis - Original)
**What it does:**
- Uses Kurtosis to orchestrate full Optimism devnet
- L1 (Anvil) + L2 (op-geth) + op-node + op-batcher + op-proposer
- op-proposer automatically creates DisputeGames with real OutputRootProof

**Pros:**
- ✅ Complete, production-like environment
- ✅ Real DisputeGame creation
- ✅ One command: `make devnet-up`
- ✅ Already tested and working

**Cons:**
- ❌ Requires Kurtosis + Docker
- ❌ Takes 5-10 minutes to start
- ❌ Heavy resource usage

**Best for:** Full integration testing before production

---

### 2. run-e2e-test-simple.sh (Manual Optimism Stack)
**What it does:**
- Manually starts each Optimism component
- L1 (Anvil) + L2 (geth) + op-node + op-proposer
- Builds op-node and op-proposer from source

**Pros:**
- ✅ No Kurtosis dependency
- ✅ Real Optimism components

**Cons:**
- ❌ Most complex setup
- ❌ Requires Optimism repo and compilation
- ❌ Many moving parts (4+ processes)
- ❌ Difficult to debug
- ❌ Configuration complexity (genesis, rollup config, etc.)

**Best for:** Learning Optimism internals (not practical for testing)

---

### 3. run-e2e-test-minimal.sh (Mock Everything)
**What it does:**
- Anvil (L1) only
- Python mock op-node (HTTP server)
- Mock DisputeGame contracts
- Tests OutputRootProof structure only

**Pros:**
- ✅ Fastest to start
- ✅ No external dependencies
- ✅ Easy to debug
- ✅ Works immediately

**Cons:**
- ❌ Not real E2E (no actual L2 state)
- ❌ Can't test RAT client's state DB access
- ❌ Can't test real adjacent leaves search

**Best for:** Quick smoke tests, CI/CD

---

### 4. run-e2e-test-final.sh (Recommended Balance) ⭐
**What it does:**
- L1 (Anvil) + L2 (geth in dev mode)
- Real L2 state generation (transactions)
- Manual DisputeGame creation via Forge script
- Uses real state root from L2

**Pros:**
- ✅ Real L2 state DB (RAT client can access)
- ✅ Real state trie with adjacent leaves
- ✅ Medium complexity (manageable)
- ✅ No Kurtosis required
- ✅ Fast startup (~30 seconds)
- ✅ Can test full RAT flow

**Cons:**
- ⚠️ DisputeGame creation is manual (not automatic)
- ⚠️ Simplified (no op-node, no op-proposer)

**Best for:** RAT client development and testing

---

## Recommendation: Use run-e2e-test-final.sh

### Why This Is The Best Choice:

1. **Real L2 State DB**: RAT client can connect to geth's chaindata and search for adjacent leaves
2. **No Kurtosis**: Meets your requirement to avoid heavy orchestration
3. **Fast**: 30 seconds vs 10 minutes for Kurtosis
4. **Practical**: Tests what matters (RAT flow) without unnecessary complexity
5. **Debuggable**: Only 2 processes (L1 + L2)

### What You Can Test:

```
✅ L2 state generation (real transactions)
✅ State DB access (geth chaindata)
✅ Adjacent leaves search (real Patricia trie)
✅ OutputRootProof structure
✅ rootClaim hashing
✅ RAT client evidence submission
✅ Contract verification
```

### What's Simplified:

```
⚠️ DisputeGame creation (manual via Forge script, not op-proposer)
⚠️ No op-node (OutputRootProof mocked, but structure is correct)
⚠️ No op-batcher (not needed for RAT testing)
```

---

## Quick Start Guide

### Option 1: Full E2E (Kurtosis) - If you change your mind
```bash
cd clients/rat-client-type3
make devnet-up
# Wait 5-10 minutes
make test-e2e
```

### Option 2: Practical E2E (Recommended) ⭐
```bash
# Terminal 1: Start environment
./scripts/run-e2e-test-final.sh

# Terminal 2: Run RAT client
cd clients/rat-client-type3
cat > config.test.yaml <<EOF
l1_rpc_url: "http://localhost:8545"
l2_rpc_url: "http://localhost:9545"
state_db_path: "/tmp/rat-e2e-final-*/l2/geth/chaindata"
rat_contract: "0x5FbDB2315678afecb367f032d93F642f64180aa3"
validator_address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
private_key: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
EOF

./bin/rat-client --config config.test.yaml
```

### Option 3: Quick Smoke Test
```bash
./scripts/run-e2e-test-minimal.sh
# Tests OutputRootProof structure only
```

---

## What The RAT Client Will Do

When you run the RAT client with `run-e2e-test-final.sh`:

1. **Listen for RAT events** on L1
2. **Connect to L2 state DB** (geth chaindata)
3. **Find adjacent leaves** where leafA < stateRoot < leafB
4. **Fetch OutputRootProof** (from config or mock)
5. **Create evidence** with StateLeafEvidence structure
6. **Submit to L1** via RAT.submitEvidence()
7. **Contract verifies**:
   - hash(OutputRootProof) == rootClaim ✅
   - leafA < stateRoot < leafB ✅
   - Merkle proofs valid ✅

---

## My Recommendation

**Use `run-e2e-test-final.sh` for development and testing.**

It gives you 80% of the value with 20% of the complexity. You get:
- Real state DB access ✅
- Real adjacent leaves ✅
- Fast iteration ✅
- Easy debugging ✅

The only thing you sacrifice is automatic DisputeGame creation, which is fine for testing the RAT client logic.

When you're ready for production testing, switch to Kurtosis (`run-e2e-test.sh`) for the full experience.

---

## Next Steps

1. Try `run-e2e-test-final.sh` first
2. If it meets your needs, use it for development
3. Before deployment, run full Kurtosis test once to verify everything
