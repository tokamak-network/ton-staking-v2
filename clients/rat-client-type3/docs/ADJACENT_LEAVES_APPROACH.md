# Adjacent Leaves Approach - State Trie Verification

## Overview

The **Adjacent Leaves** approach is an alternative RAT verification method for Type 3 rollups that uses L2 state Patricia trie iteration instead of fraud proofs. This approach requires validators to prove they are running a full op-geth node with access to the complete state database.

## Key Concept

Instead of verifying L2 state by deriving it from L1 batches (fraud proof approach), validators demonstrate node operation by:

1. **Accessing L2 State Database**: Direct read access to op-geth's state trie (requires full node)
2. **Finding Adjacent Leaves**: Iterate the entire state Patricia trie to find two consecutive account entries
3. **Generating Merkle Proofs**: Prove both leaves exist in the state root at a specific block

## Why This Approach?

### Advantages
- **Simpler Implementation**: No need for complex batch decoding and EVM execution
- **Proves Full Node Operation**: External RPC cannot iterate state trie (only `eth_getProof` for specific addresses)
- **Faster Evidence Generation**: Direct database access vs full block re-execution
- **Less Computation**: Reading existing state vs re-executing all transactions

### Requirements
- **Full op-geth Node**: Must run your own op-geth with state database access
- **op-node in Follower Mode**: Syncs L2 state from L1 batch data (trustless)
- **State DB Access**: Read permission to op-geth's `chaindata` directory

## Architecture

```
┌────────────────────────────────────────────────────────┐
│                    L1 (Ethereum)                       │
│                                                        │
│  ┌──────────────┐                                     │
│  │ Batch Inbox  │ ← L2 transaction batches            │
│  └──────────────┘                                     │
└────────────────────────────────────────────────────────┘
         ▼
┌────────────────────────────────────────────────────────┐
│                 op-node (Follower)                     │
│  - Derives L2 blocks from L1 batch data                │
│  - Trustless source of L2 state                        │
│  - Sends execution payloads to op-geth                 │
└────────────────────────────────────────────────────────┘
         ▼
┌────────────────────────────────────────────────────────┐
│                    op-geth                             │
│  - Executes L2 blocks from op-node                     │
│  - Stores state in Patricia trie (LevelDB)             │
│  - Provides RPC for block headers                      │
└────────────────────────────────────────────────────────┘
         ▼
┌────────────────────────────────────────────────────────┐
│              RAT Client (Adjacent Leaves)              │
│                                                        │
│  1. Monitor L1 for AttentionTestTriggered              │
│  2. Open op-geth state DB (direct read)                │
│  3. Iterate state trie to find adjacent leaves         │
│  4. Generate Merkle proofs for both leaves             │
│  5. Submit evidence to L1                              │
└────────────────────────────────────────────────────────┘
```

## Trust Model

This approach is **fully trustless**:

1. **L1 Batch Data**: Posted to L1 (trustless)
2. **op-node Derivation**: Deterministic derivation from L1 batches (trustless)
3. **op-geth Execution**: Deterministic EVM execution (trustless)
4. **State Trie**: Cryptographically verified Patricia trie (trustless)
5. **Merkle Proofs**: Cryptographic proof of leaf inclusion (trustless)

**Key Point**: You MUST run your own op-node + op-geth. Using an external RPC defeats the purpose because:
- External RPC cannot iterate state trie (only specific addresses via `eth_getProof`)
- RAT client needs direct database access
- Proves validator is running full infrastructure

## Technical Details

### State Patricia Trie

Ethereum's state is stored in a Patricia Merkle Trie:

```
State Root (32 bytes hash)
    │
    ├─ Branch Node
    │   ├─ Leaf: Account A (keccak256(address_A) → RLP(account_A))
    │   ├─ Leaf: Account B (keccak256(address_B) → RLP(account_B))  ← Adjacent!
    │   └─ ...
    └─ ...
```

**Key Properties**:
- **Keys**: `keccak256(address)` (sorted lexicographically)
- **Values**: `RLP(nonce, balance, storageRoot, codeHash)`
- **Iteration**: Trie iterator yields leaves in sorted key order
- **Adjacency**: Two consecutive leaves in iteration order

### Finding Adjacent Leaves

**How is the target value determined?**

The target value comes from the **StateRoot** of the challenged L2 block:
- L2 block number is determined by DisputeGame (not random)
- StateRoot is fetched from that specific block
- StateRoot (32 bytes hash) is converted to big.Int as the target value
- Used to select an unpredictable position in the state trie

**Algorithm**:

```go
// 1. Get L2 block number from DisputeGame contract
blockNumber := game.L2BlockNumber()

// 2. Get state root for that block
stateRoot := GetStateRoot(blockNumber)

// 3. Convert StateRoot to big.Int (this becomes the "randomValue" for search)
randomValue := new(big.Int).SetBytes(stateRoot[:])

// 4. Collect all accounts from state trie via debug_accountRange
accounts := GetAccountRange(stateRoot, blockNumber) // Sorted by keccak256(address)

// 5. Binary search for position
randomHash := BigToHash(randomValue) // = stateRoot
idx := BinarySearch(accounts, randomHash)

// 6. Return adjacent pair
leafA := accounts[idx-1]  // leafA.key < stateRoot (as big.Int)
leafB := accounts[idx]    // leafB.key >= stateRoot (as big.Int)
```

**Edge Cases**:
- If `stateRoot` < all keys: Use first two accounts
- If `stateRoot` > all keys: Use last two accounts
- Normal case: `leafA.key < stateRoot <= leafB.key`

**Why StateRoot as target?**
- **Unpredictable position**: StateRoot is a 32-byte hash, selects arbitrary position in trie
- **Pre-computing impossible**: Cannot know which accounts will be adjacent to StateRoot
- **Forces archive mode**: Must have state at the challenged block (may be in past)
- **Proves full state possession**: Must iterate entire state trie to find adjacent leaves

### Evidence Structure

```go
type StateLeafEvidence struct {
    // Leaf A (state trie account)
    LeafAKey   [32]byte  // keccak256(address)
    LeafAValue []byte    // RLP(nonce, balance, storageRoot, codeHash)
    LeafAProof [][]byte  // Merkle proof nodes

    // Leaf B (adjacent account)
    LeafBKey   [32]byte
    LeafBValue []byte
    LeafBProof [][]byte

    // State context
    StateRoot   [32]byte
    BlockNumber uint256
}
```

**Verification on L1**:
1. Verify OutputRootProof: `hash(outputRootProof) == rootClaim`
2. Extract stateRoot from OutputRootProof
3. Check `leafA.key < stateRoot < leafB.key` (StateRoot as Target!)
4. Verify `leafA.proof` → proves leafA exists in stateRoot
5. Verify `leafB.proof` → proves leafB exists in stateRoot
6. Verify divergence witness (proves no leaves between leafA and leafB)
7. Success → Validator has full state trie access at challenged block

## Implementation

### Package Structure

```
clients/rat-client-type3/
├── pkg/
│   ├── l2sync/
│   │   ├── state_trie.go           # Patricia trie iteration
│   │   ├── synchronizer_state.go   # State DB access wrapper
│   │   └── types.go                # Type definitions
│   ├── evidence/
│   │   └── state_leaf_evidence.go  # Evidence structure
│   ├── client/
│   │   ├── config.go               # Config with StateDBPath
│   │   └── service_adjacent.go     # Service using state syncer
│   └── submitter/
│       └── adjacent_submitter.go   # Evidence submission
└── docs/
    └── ADJACENT_LEAVES_APPROACH.md # This document
```

### Key Components

#### 1. StateSynchronizer (`synchronizer_state.go`)

```go
type StateSynchronizer struct {
    stateDB ethdb.Database    // Direct access to op-geth state DB
    l2RPC   *ethclient.Client // For block headers
}

// Find adjacent leaves in state trie for given block
func (s *StateSynchronizer) FindAdjacentLeaves(
    ctx context.Context,
    randomValue *big.Int,
    blockNumber uint64,
) (*AdjacentLeaves, error)
```

**Key Methods**:
- `FindAdjacentLeaves()`: Main entry point
- `GetStateRoot()`: Get state root for block
- `GetLatestBlockNumber()`: Check sync status

#### 2. State Trie Iterator (`state_trie.go`)

```go
// Iterate all leaves in state trie
func CollectAllLeaves(
    db ethdb.Database,
    stateRoot common.Hash,
) ([]*StateTrieLeaf, error)

// Find two adjacent leaves around random value
func FindAdjacentLeavesInStateTrie(
    db ethdb.Database,
    stateRoot common.Hash,
    randomValue *big.Int,
) (*StateTrieLeaf, *StateTrieLeaf, error)

// Generate Merkle proof for a leaf
func GenerateStateProof(
    db ethdb.Database,
    stateRoot common.Hash,
    leafKey common.Hash,
) ([][]byte, error)
```

#### 3. State Leaf Evidence (`state_leaf_evidence.go`)

```go
type StateLeafEvidence struct {
    LeafAKey, LeafAValue, LeafAProof
    LeafBKey, LeafBValue, LeafBProof
    StateRoot, BlockNumber
}

// Methods
func (e *StateLeafEvidence) Encode() ([]byte, error)
func (e *StateLeafEvidence) Validate() error
func (e *StateLeafEvidence) VerifyRange(randomValue *big.Int) bool
```

## Configuration

### Required Settings

```yaml
# L2 RPC (op-geth)
l2_rpc_url: "http://localhost:8545"

# State DB Path (REQUIRED for adjacent leaves)
state_db_path: "/path/to/op-geth/chaindata"
# Example: ~/.ethereum/optimism/geth/chaindata

# Other settings...
l1_rpc_url: "http://localhost:9545"
rat_contract: "0x..."
private_key: "0x..."
```

### State DB Path Discovery

The state database is typically located at:

```bash
# Default op-geth data directory
~/.ethereum/geth/chaindata

# Custom data directory
<datadir>/geth/chaindata

# Optimism
~/.ethereum/optimism/geth/chaindata

# Docker
/root/.ethereum/geth/chaindata
```

**To find it**:
```bash
# Check op-geth startup logs
grep "Database" op-geth.log

# Or check process
ps aux | grep geth
# Look for --datadir flag
```

## Verification Flow

1. **Monitor L1**:
   ```go
   event := <-monitor.Events() // AttentionTestTriggered
   gameAddress := event.GameAddress
   ```

2. **Get L2 Block Number from DisputeGame**:
   ```go
   blockNumber := disputeGame.L2BlockNumber()
   ```

3. **Get StateRoot and Convert to Target Value**:
   ```go
   stateRoot := l2Client.BlockByNumber(blockNumber).StateRoot()
   randomValue := new(big.Int).SetBytes(stateRoot[:])
   ```

4. **Find Adjacent Leaves**:
   ```go
   leaves := stateSyncer.FindAdjacentLeaves(ctx, randomValue, blockNumber)
   // Returns: leafA, leafB, proofA, proofB, stateRoot, divergenceWitness
   ```

4. **Create Evidence**:
   ```go
   evidence := NewStateLeafEvidence(leaves)
   ```

5. **Submit to L1**:
   ```go
   receipt := submitter.SubmitEvidence(ctx, testID, randomValue, evidence)
   // Note: randomValue is used for client-side range validation only
   // On-chain: RAT.submitEvidence(testID, evidenceType=1, evidenceData)
   ```

## Setup Guide

### 1. Run op-node (Follower Mode)

```bash
op-node \
  --l1=http://localhost:9545 \
  --l2=http://localhost:8545 \
  --l2.jwt-secret=./jwt.txt \
  --rollup.config=./rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9546
```

### 2. Run op-geth

```bash
op-geth \
  --datadir=/data/optimism \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=./jwt.txt \
  --syncmode=full \  # IMPORTANT: full mode required
  --gcmode=archive   # Recommended for historical state access
```

### 3. Run RAT Client

```bash
./bin/rat-client \
  --l1-rpc=http://localhost:9545 \
  --l2-rpc=http://localhost:8545 \
  --state-db-path=/data/optimism/geth/chaindata \
  --rat-contract=0x... \
  --private-key=0x...
```

## Performance

### Time Complexity

- **State Trie Iteration**: O(n) where n = number of accounts
  - Typical L2: ~100k accounts → ~10 seconds
  - Large L2: ~1M accounts → ~100 seconds

- **Binary Search**: O(log n)
  - Negligible (~10 iterations for 1M accounts)

- **Merkle Proof Generation**: O(depth)
  - Trie depth: ~16-20 levels → milliseconds

**Total**: ~10-100 seconds depending on state size

### Optimization

The implementation includes optimizations:

1. **Pre-allocated Arrays**: Reduce memory allocations during iteration
2. **Sorted Iteration**: Trie iterator yields leaves in order (no sorting needed)
3. **Parallel Proof Generation**: Generate proofA and proofB concurrently
4. **Local Verification**: Verify proofs before submission

## Comparison with Fraud Proof Approach

| Aspect | Adjacent Leaves | Fraud Proof |
|--------|----------------|-------------|
| **Complexity** | Low (read state DB) | High (batch decode + EVM) |
| **Computation** | Minimal (iterate trie) | Heavy (execute txs) |
| **Dependencies** | State DB access | Full derivation pipeline |
| **Proof Type** | State inclusion | Execution trace |
| **Evidence Size** | ~2-5 KB | ~50-200 KB |
| **Generation Time** | 10-100 seconds | 5-30 minutes |
| **Full Node Proof** | ✅ Yes (direct DB access) | ⚠️ No (can use RPC) |

## Security Considerations

### Trustlessness

The approach maintains full trustlessness:

1. **State Root from L1**: Op-geth state root derives from L1 batches (via op-node)
2. **Merkle Proofs**: Cryptographically prove leaf inclusion
3. **On-chain Verification**: L1 contract verifies all proofs

### Attack Resistance

**Cannot Fake State Access**:
- External RPC cannot iterate full trie (only `eth_getProof` for specific addresses)
- RAT client MUST have local state DB access
- Proves validator runs full node

**Merkle Proof Security**:
- Proofs are cryptographically sound
- L1 contract verifies against state root
- Cannot forge proofs without breaking keccak256

### Operational Security

1. **State DB Permissions**: Read-only access sufficient
2. **Concurrent Access**: LevelDB supports multiple readers
3. **No State Modification**: RAT client never writes to state DB
4. **Graceful Degradation**: Falls back if state DB unavailable

## Limitations

1. **Full Node Required**: Cannot use light clients or external RPC
2. **State Size Growth**: Iteration time increases with state size
3. **Historical Blocks**: Requires archive mode for old blocks (or recent blocks only)
4. **Single L2**: Must run separate op-geth per L2 chain

## Future Optimizations

1. **Incremental Iteration**: Cache trie position between tests
2. **State Pruning**: Only keep recent state roots
3. **Parallel Iteration**: Split trie iteration across goroutines
4. **Proof Caching**: Cache proofs for frequently accessed leaves

## References

- [Ethereum Patricia Trie Specification](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)
- [go-ethereum Trie Implementation](https://github.com/ethereum/go-ethereum/tree/master/trie)
- [op-geth State Database](https://github.com/ethereum-optimism/op-geth)
- [RAT Contract Specification](../../src/validator/RAT.sol)

## See Also

- [op-node Setup Guide](./opnode-setup.md)
- [Main README](../README.md)
- [RAT Client Implementation Plan](../../docs/rat-client-implementation-plan.md)
