# TON Staking V3 RAT Clients

This directory contains RAT (Randomized Attention Test) client implementations for different rollup types.

## Overview

RAT clients validate that validators possess the complete L2 state at challenged blocks by proving they can find adjacent leaves in the state trie. Each rollup type requires its own client implementation due to different:
- State trie formats
- Proof generation methods
- Contract verification logic

## Directory Structure

```
clients/
├── rat-client-type3/        # Type 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME (✅ Implemented)
│   ├── cmd/
│   ├── pkg/
│   ├── docs/
│   └── README.md
├── rat-client-type4/        # Type 4: Future rollup type (TBD)
└── rat-client-type5/        # Type 5: Future rollup type (TBD)
```

## Supported Rollup Types

From `src/layer2/L1BridgeRegistryV1_2.sol`:

```solidity
enum TYPE_ROLLUPCONFIG {
    NONE,                                    // 0 - Not registered
    LEGACY,                                  // 1 - TOKAMAK (Legacy) - No RAT
    OPTIMISM_BEDROCK,                        // 2 - Optimism Bedrock - No RAT
    OPTIMISM_BEDROCK_WITH_DISPUTE_GAME       // 3 - Optimism Bedrock + DisputeGame + RAT ✅
}
```

- **Type 1, 2**: Do not use RAT
- **Type 3**: Uses RAT with State Leaf Evidence approach (current implementation)
- **Type 4+**: Future types with RAT support

---

## Type 3: State Leaf Evidence Approach

### How It Works

Type 3 uses the **Adjacent Leaves Method** to prove state possession:

```
1. Monitor L1 for AttentionTestTriggered events
   ↓
2. Query DisputeGame for L2 block number and get StateRoot
   ↓
3. Convert StateRoot to big.Int (target value for binary search)
   ↓
4. Iterate state trie via debug_accountRange (requires archive mode)
   ↓
5. Binary search: Find adjacent leaves where leafA.key < stateRoot < leafB.key
   ↓
6. Generate Merkle proofs for both leaves (eth_getProof)
   ↓
7. Calculate divergence witness (proves no leaves between leafA and leafB)
   ↓
8. Encode StateLeafEvidence with OutputRootProof and DivergenceWitness
   ↓
9. Submit to RAT contract: submitEvidence(testID, evidenceType=1, evidenceData)
```

### Key Features

- ✅ **Compact Proofs** - Proves state possession without revealing entire state
- ✅ **RPC-Based** - Uses L2 debug APIs (`debug_accountRange`, `eth_getProof`)
- ⚠️ **Archive Mode Recommended** - Requires state at challenged block (may be in past)
- ✅ **Gas Efficient** - ~280k gas for full verification
- ✅ **No Batch Execution** - Direct state trie access (simpler than batch replay)

### Security Model

**Trustless State Verification:**
- ✅ Fetch state data from L2 RPC with cryptographic proof verification
- ✅ Verify Merkle proofs against finalized L1 state root (from DisputeGameFactory)
- ✅ L2 node cannot lie (proofs must match L1 finalized state root)
- ✅ Validator slashed if evidence is invalid

**What validators prove:**
- Possession of complete L2 state at specific block
- Ability to find adjacent leaves in state trie
- Knowledge of divergence point in Merkle Patricia Trie

See [Type 3 Architecture](./rat-client-type3/docs/ARCHITECTURE.md) for detailed security analysis.

---

## Prerequisites

### L2 Node Setup (For Production Validators)

**Important:** Production validators must run their own L2 node with debug APIs enabled.

> **Note:** For E2E testing, L2 node setup is automatic. This section is for validators running in production.

#### Required Components

Use **op-node** + **op-geth** to derive L2 state from L1 batch data:

**1. op-node (Rollup Node):**
```bash
# Derives L2 state from L1 batch data
# Operates as a follower node, validating batches against L1
op-node \
  --l1=<L1_RPC> \
  --l2=http://localhost:8551 \
  --l2.jwt-secret=./jwt.hex \
  --rollup.config=./rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545
```

**2. op-geth (Execution Engine):**
```bash
# Enable debug APIs for RAT client
op-geth \
  --datadir=./datadir \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=eth,debug,net,web3 \
  --authrpc.addr=localhost \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=./jwt.hex \
  --syncmode=full \
  --gcmode=archive  # RECOMMENDED: Ensures state availability for RAT challenges
```

**Important:** Use `--gcmode=archive` to ensure challenged blocks' state is always available, even if validator misses initial alert.

#### Why This Setup?

- ✅ **Trustless** - Derives L2 state from L1 batch data
- ✅ **Validated** - op-node validates all batches against L1
- ✅ **Complete Historical State** - Archive mode preserves all past blocks' state (critical for RAT)
- ✅ **Debug APIs** - op-geth provides required debug APIs with historical access
- ✅ **Independent** - No reliance on external RPC providers
- ✅ **Reliable** - Can respond to RAT challenges even if offline temporarily

#### Required Node Capabilities

**Node Types Explained:**

| Node Type | State Storage | Disk Usage | Use Case for RAT |
|-----------|---------------|------------|------------------|
| **Light Node** | Only block headers | ~1 GB | ❌ Not suitable - no state trie |
| **Full Node** | Recent N blocks' state | ~500 GB | ⚠️ **Risky** - may prune challenged state |
| **Archive Node** | **All historical** state | ~10+ TB | ✅ **Recommended** - always has challenged state |

**Why Archive Node is Recommended for RAT:**

**The Problem with Full Nodes:**
```
Time T: DisputeGame created for L2 block #12345
        - state root = 0xabc...
        - RAT triggered

Time T+1h: Validator submits evidence
           - Must prove possession of state at block #12345
           - Must find adjacent leaves in block #12345's state trie
           - ❌ Full node may have already pruned block #12345's state!
```

**Key Insight:**
- RAT challenges reference **specific past L2 blocks**, not current block
- Validator must access state **at that exact past block**
- If Full node pruned that block's state → **Evidence submission impossible** → **Slashing**

**Full Node Pruning:**
- Default `--gcmode=full`: Keeps limited recent state (typically last 128 blocks or configurable via `--history.state`)
- L2 blocks generated every ~2s
- evidenceSubmissionPeriod = 1 hour
- **State is pruned long before deadline!**
- Example: With 128 blocks retention = ~4 minutes of history, far less than 1 hour needed

**Archive Node (Recommended):**
- Stores **all historical state** from genesis
- Never prunes old state
- **Always has state for any challenged block**
- Disk: ~10+ TB (but necessary for reliable validator operation)

**Alternative: Extended State Retention (Not Recommended)**
```bash
# Option 1: Increase state history retention (still has limits)
op-geth --gcmode=full --history.state=180000  # ~100 hours at 2s/block

# Option 2: Use path-based state scheme (experimental)
op-geth --state.scheme=path --gcmode=full
```

**Problems with these alternatives:**
- Still has retention limits (not truly unlimited)
- May not cover long offline periods
- More complex configuration
- **Not recommended for production validators**

**Recommendation:** Use `--gcmode=archive` for reliable, guaranteed state access.

**Required Debug APIs:**
- `debug_accountRange` - Iterate through all accounts in state trie **at specific block height**
- `eth_getProof` - Generate Merkle proofs for specific accounts **at specific block height**

Both APIs must support historical queries (e.g., `eth_getProof(account, [], "0x12345")` for block #0x12345).

**Why Light Nodes Don't Work:**

Light nodes only sync block headers and don't maintain full state tries, so they cannot provide `debug_accountRange` or generate Merkle proofs.

**Note:** Public RPC endpoints (Infura, Alchemy, etc.) do not expose debug APIs. **Production validators must run their own archive node infrastructure.**

---

## Quick Start

### 1. Build RAT Client

```bash
# From project root
make rat-client-build

# Or directly
cd clients/rat-client-type3
go build -o bin/rat-client-type3 ./cmd
```

### 2. Configure

```bash
cd clients/rat-client-type3
cp config.example.yaml config.yaml
# Edit config.yaml with your settings
```

**Minimum required configuration:**
```yaml
# Verification mode
verification_mode: l2rpc  # Use L2 RPC with debug APIs

# L1 Configuration
l1:
  rpc_url: "http://localhost:8545"
  beacon_url: "http://localhost:5052"

# RPC endpoints
rpc:
  urls:
    - "http://localhost:9545"  # L2 geth with debug APIs

# Contract addresses
contracts:
  rat_contract: "0x..."
  system_config: "0x..."
  dispute_game_factory: "0x..."
  l1_bridge_registry: "0x..."
  batch_inbox: "0xff03000000000000000000000000000000000000"
  batcher_address: "0x..."

# Validator identity
validator:
  private_key: "${VALIDATOR_PRIVATE_KEY}"  # Use environment variable

# RAT client settings
rat:
  poll_interval: 12s
  deadline_buffer: 10m
  max_gas_price: 100  # gwei
```

### 3. Run

```bash
# From project root (uses config.yaml)
make rat-client-run

# Or with CLI flags (minimal required flags)
./clients/rat-client-type3/bin/rat-client-type3 \
  --l1-rpc http://localhost:8545 \
  --l2-rpc http://localhost:9545 \
  --private-key 0x... \
  --rat-contract 0x... \
  --system-config 0x...

# Optional: Specify starting block
./clients/rat-client-type3/bin/rat-client-type3 \
  --l1-rpc http://localhost:8545 \
  --l2-rpc http://localhost:9545 \
  --private-key 0x... \
  --rat-contract 0x... \
  --system-config 0x... \
  --start-block 12345
```

---

## Testing

### Unit Tests

```bash
# Test RAT client Type 3
make rat-client-test

# Or directly
cd clients/rat-client-type3
go test ./pkg/...
```

### E2E Integration Tests

```bash
# Generate genesis file (once)
make devnet-allocs-offline

# Run E2E tests with RAT client
make test-e2e
```

**Test Environment:**

E2E tests automatically provision isolated test environments:
- **L1**: Anvil (local Ethereum node) with pre-deployed contracts from genesis
- **L2**: Geth in dev mode with debug APIs enabled
- **RAT Client**: Binary executed as subprocess

No manual L2 node setup required for testing.

**Test Coverage:**
- ✅ System initialization (3 tests)
- ✅ RAT scenarios (3 tests)
- ✅ RAT client integration (1 test)
- Total: 7/7 tests passing

See [E2E Tests Guide](../op-e2e/README.md) for details.

---

## Documentation

### Type 3 RAT Client
- [Quick Start Guide](./rat-client-type3/README.md) - Configuration and usage
- [Architecture](./rat-client-type3/docs/ARCHITECTURE.md) - System design, components, and technical details
- [Testing Guide](./rat-client-type3/docs/TESTING_GUIDE.md) - How to test

### System Documentation
- [E2E Tests](../op-e2e/README.md) - E2E test documentation

---

## Advanced: Adding New Rollup Types

<details>
<summary>Click to expand instructions for implementing Type 4+ rollups</summary>

To add support for a new rollup type (e.g., Type 4):

### 1. Create Directory Structure

```bash
mkdir -p clients/rat-client-type4/{cmd,pkg}
```

### 2. Implement Type-Specific Components

Depending on rollup architecture, implement:
- Batch fetcher (from L1 DA layer)
- Batch decoder (type-specific format)
- State executor (if batch replay approach)
- Evidence generator (type-specific proofs)

### 3. Add Solidity Verifier

```solidity
// src/validator/libraries/Type4EvidenceVerifier.sol
library Type4EvidenceVerifier {
    struct Evidence { /* type-specific */ }
    function verify(...) internal pure returns (bool) { /* type-specific */ }
}
```

### 4. Update RAT.sol

```solidity
if (rollupType == 4) {
    return Type4EvidenceVerifier.verify(batchHash, evidenceData);
}
```

### 5. Add Build Targets

```makefile
# Makefile
RAT_CLIENT_TYPE4_DIR := clients/rat-client-type4
rat-client-type4-build:
    cd $(RAT_CLIENT_TYPE4_DIR) && go build -o bin/rat-client-type4 ./cmd
```

</details>

---

## License

MIT
