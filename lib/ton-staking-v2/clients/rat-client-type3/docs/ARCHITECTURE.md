# RAT Client Type 3 - Architecture

## Overview

The RAT (Randomized Attention Test) Client is a system for **verifying that validators directly own L2 rollup nodes** in TON Staking V3. For Type 3 rollups (Optimism Bedrock with DisputeGameFactory), it confirms validator's full op-geth node operation through **State Trie-based verification using debug API**.

**Key Requirements:**
- Use of `debug_accountRange` API → Requires full node + debug API
- L2 block selection via StateRoot → Cannot predict which block will be selected
- Debug API is only available on self-hosted nodes

## Design Philosophy

### Purpose: Validator Liveness Proof

```
Liveness = Direct full node ownership + Real-time L2 monitoring
Correctness = Verification that state is correct

RAT Client = Liveness verification (20-30 minutes, debug API)
DisputeGame = Correctness verification (7 days, L1-only)

→ 2-tier security model
```

**Verification Time Details:**
- **Production**: ~20-30 minutes
  - Reorg protection (64 confirmations): ~12.8 minutes
  - State iteration + proof generation: ~5-15 minutes
- **Test/Devnet**: ~5-10 minutes
  - Reorg protection (1-6 confirmations): ~12 seconds-1.2 minutes
  - State iteration + proof generation: ~5-10 minutes

**Core Design Principles:**
1. **Fast**: Evidence submission within 20-30 minutes (Production)
2. **Simple**: State trie iteration instead of complex fraud proofs
3. **Practical**: Use of debug API (state trie access)
4. **Fallback capable**: Final verification via DisputeGame on failure

### Trade-offs

| Item | RAT Client | DisputeGame (Optimism) |
|------|-----------|------------------------|
| Verification Time | 20-30 minutes (Production) | 7 days |
| Complexity | Low | High |
| Cost | Low (1-2 tx) | High (dozens of tx) |
| Requirements | Full op-geth + debug API | L1 only |
| Verification Content | Liveness (node ownership + monitoring) | Correctness (state accuracy) |
| Purpose | Fast path (99% of cases) | Final safety (1% suspicious cases) |

## System Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                         │
│                                                               │
│  ┌─────────────────┐              ┌─────────────────┐        │
│  │  RAT Contract   │              │  Batch Inbox    │        │
│  │  - Trigger test │              │  - L2 batches   │        │
│  │  - Verify proof │              └─────────────────┘        │
│  └─────────────────┘                       │                 │
│         ▲                                  │                 │
└─────────┼──────────────────────────────────┼─────────────────┘
          │                                  │
          │ Evidence                         │ Batches
          │                                  ▼
┌─────────┴──────────────────────────────────────────────────────┐
│                    Validator Infrastructure                    │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                       op-node                            │ │
│  │  - Derives L2 blocks from L1 batches (trustless)         │ │
│  │  - Provides OutputRootProof                              │ │
│  │  - Sends execution payloads to op-geth                   │ │
│  └──────────────────────────────────────────────────────────┘ │
│                              │                                 │
│                              ▼                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                      op-geth                             │ │
│  │  - Executes L2 blocks                                    │ │
│  │  - Stores state in Patricia trie (State DB)              │ │
│  │  - Provides debug_accountRange (state iteration)         │ │
│  │  - Provides eth_getProof (Merkle proof generation)       │ │
│  └──────────────────────────────────────────────────────────┘ │
│                              │                                 │
│                              │ RPC Calls                       │
│                              ▼                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                  RAT Client Type 3                       │ │
│  │                                                          │ │
│  │  ┌────────────────┐  ┌────────────────┐                │ │
│  │  │ Event Monitor  │  │ Op-node Client │                │ │
│  │  │ - Watch L1     │  │ - Get OutputRoot│               │ │
│  │  └────────────────┘  └────────────────┘                │ │
│  │          │                    │                         │ │
│  │          ▼                    ▼                         │ │
│  │  ┌──────────────────────────────────┐                  │ │
│  │  │   RPC Client                     │                  │ │
│  │  │   - Call debug_accountRange      │                  │ │
│  │  │   - Select adjacent leaves       │                  │ │
│  │  │   - Call eth_getProof            │                  │ │
│  │  └──────────────────────────────────┘                  │ │
│  │          │                                              │ │
│  │          ▼                                              │ │
│  │  ┌──────────────────────────────────┐                  │ │
│  │  │   Evidence Generator             │                  │ │
│  │  │   - Assemble StateLeafEvidence   │                  │ │
│  │  │   - Add OutputRootProof          │                  │ │
│  │  │   - ABI encoding                 │                  │ │
│  │  └──────────────────────────────────┘                  │ │
│  │          │                                              │ │
│  │          ▼                                              │ │
│  │  ┌──────────────────────────────────┐                  │ │
│  │  │   Evidence Submitter             │                  │ │
│  │  │   - Build tx                     │                  │ │
│  │  │   - Sign & submit                │                  │ │
│  │  │   - Gas management               │                  │ │
│  │  └──────────────────────────────────┘                  │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Event Monitor (`pkg/monitor`)

**Role**: Monitors L1 RAT contract to detect AttentionTest events

```go
type AttentionTestTriggered struct {
    TestID      [32]byte
    SystemConfig common.Address
    BatchIndex  uint64
    RandomValue *big.Int
}
```

**Key Features:**
- L1 block polling (12-second intervals)
- Event parsing
- Reorg protection (64 confirmations, ~12.8 minutes)
  - Production: 64 confirmations (safety)
  - Test/Devnet: 1-6 confirmations (fast testing)

### 2. Op-node Client (`pkg/verification`)

**Role**: Queries OutputRootProof via op-node's Rollup RPC

```go
type OutputRootProof struct {
    Version                  [32]byte    // Always 0x0
    StateRoot                common.Hash
    MessagePasserStorageRoot common.Hash
    LatestBlockHash          common.Hash
}
```

**Core**: Structure for verifying authenticity of L2 state root

### 3. State Synchronizer (`pkg/l2sync`)

**Role**: Traverses L2 state trie to find adjacent leaf pairs

**Key Components:**
- `StateTrie`: Patricia trie iterator
- `StateRPC`: RPC-based state fetcher (uses `debug_accountRange`)
- `AdjacentLeaves`: Adjacent leaf pairs + Merkle proofs

**Using `debug_accountRange` API:**
```go
// debug_accountRange queries a specific range of state trie with pagination
// Parameters: (stateRoot, startKey, maxResults, excludeCode, excludeStorage)
debug_accountRange(stateRoot, startKey, 1000, true, true)

// Returns: {
//   accounts: { "0x123...": { balance, nonce, ... }, ... }
//   next: "0x456..."  // Next page start key
// }
```

**Why Full Node + Debug API is Required:**
```
Regular RPC (eth_getProof):
  - Can only query proof for specific addresses
  - Anyone can call via external RPC
  - Can prepare evidence in advance if address is known
  → Full node not required

debug_accountRange:
  - Traverses state trie to find adjacent leaves
  - Uses StateRoot from L2 block specified in DisputeGame as target
  - Finds adjacent leaves based on StateRoot itself
  - Most public RPCs disable debug API
  → Full node required
  → Debug API activation required
  → Self-hosted op-geth required
```

**StateRoot as Target:**
- L2 block is already specified when DisputeGame is created
- Fetch StateRoot of that block and use as target value
- Convert StateRoot to big.Int for use in binary search
- Must always maintain state of that block

**How StateRoot is Used as Target:**

```
1. Receive AttentionTestTriggered event from RAT contract
   - gameAddress: DisputeGame contract address
   - batchIndex: Game index

2. Query L2 block number from DisputeGame contract
   blockNumber := game.l2BlockNumber()

3. Query StateRoot of that block
   stateRoot := l2Client.GetBlockByNumber(blockNumber).StateRoot

4. Convert StateRoot to big.Int (target value)
   randomValue := new(big.Int).SetBytes(stateRoot[:])

5. Find adjacent leaves in state trie
   leafA.key < randomValue <= leafB.key
```

**Why Pre-computed Proof is Impossible:**

Due to the nature of Patricia Merkle Trie, **even a single account change updates the entire path to the Root**:

```
Account A balance change in block N:
  1. Recalculate account A's leaf hash
  2. Recalculate branch node hash containing account A
  3. Recalculate parent branch node hash
  4. ...Recalculate all parent node hashes up to Root
  5. State Root: Root_N → Root_N+1 (completely changed!)

Result:
  - Even if account B is not changed at all
  - State Root changes to Root_N+1
  - Account B's proof must be newly generated based on Root_N+1
  - Proof based on Root_N fails verification!

→ To generate proof with challenged block's StateRoot
→ Must maintain state of that block (Archive mode recommended)
→ Must access state of past blocks!
```

**State Patricia Trie Structure:**

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

**Binary Search Algorithm**:

```go
// 1. Get L2 block number from DisputeGame contract
blockNumber := game.L2BlockNumber()

// 2. Get state root for that block
stateRoot := GetStateRoot(blockNumber)

// 3. Convert StateRoot to big.Int (this becomes the target value)
targetValue := new(big.Int).SetBytes(stateRoot[:])

// 4. Collect all accounts from state trie via debug_accountRange
accounts := GetAccountRange(stateRoot, blockNumber) // Sorted by keccak256(address)

// 5. Binary search for position
targetHash := BigToHash(targetValue) // = stateRoot
idx := BinarySearch(accounts, targetHash)

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

### 4. Evidence Generator (`pkg/evidence`)

**Role**: Generates StateLeafEvidence and ABI encoding

```go
type StateLeafEvidence struct {
    // Adjacent leaves
    LeafAKey   common.Hash
    LeafAValue []byte
    LeafAProof [][]byte
    LeafBKey   common.Hash
    LeafBValue []byte
    LeafBProof [][]byte

    // State verification
    StateRoot   common.Hash
    BlockNumber uint64

    // Output root proof
    OutputRootProof OutputRootProof
}
```

**Verification Logic (on-chain):**
1. OutputRootProof → rootClaim verification (hash(outputRootProof) == rootClaim)
2. Extract StateRoot (from OutputRootProof)
3. **Range verification: leafA.key < stateRoot < leafB.key** (StateRoot as Target!)
4. LeafA Merkle proof → StateRoot verification
5. LeafB Merkle proof → StateRoot verification
6. Divergence verification (proves no other leaf exists between leafA and leafB)
7. All pass → Validator is operating a full node!

### 5. Evidence Submitter (`pkg/submitter`)

**Role**: Submits StateLeafEvidence to RAT contract

**Key Features:**
- StateLeafEvidence ABI encoding
- Calls RAT.submitEvidence(testID, evidenceType, evidenceData)
  - evidenceType = 1 (StateLeaf)
  - evidenceData = abi.encode(StateLeafEvidence)
- Gas estimation and limits (max gas price setting)
- Transaction signing and submission
- Receipt waiting and verification
- Deadline check (10-minute buffer before submission)

**Note**: randomValue is only used internally in client (for range verification), not transmitted on-chain

## Verification Process

### Overall Flow

```
1. [L1] RAT contract triggers AttentionTest
   - Automatically triggered when DisputeGame is created
   - TestID generation
   - Provides gameAddress, batchIndex
   - Sets deadline (e.g., 1 hour)

2. [RAT Client] Event detection
   - Receives AttentionTestTriggered event
   - Extracts TestID, validator, gameAddress, batchIndex, deadline
   - Queries batchHash (output root) from RAT contract

3. [L2 Block Number Query]
   - Queries l2BlockNumber() from DisputeGame contract
   - Challenged L2 block is already determined

4. [StateRoot Query and Verification]
   - Queries StateRoot of that block from L2 client
   - Gets OutputRootProof from op-node
   - Verifies OutputRootProof: hash(outputRootProof) == batchHash

5. [StateRoot as Target]
   - Converts StateRoot to big.Int (randomValue)
   - randomValue := new(big.Int).SetBytes(stateRoot[:])

6. [Find Adjacent Leaves]
   - Queries all accounts in state trie via debug_accountRange
   - Binary search: leafA.key < randomValue <= leafB.key
   - Generates Merkle proofs via eth_getProof

7. [Calculate Divergence Witness]
   - Finds divergence point of LeafA and LeafB
   - Extracts branch node and indices

8. [Generate Evidence]
   - Creates StateLeafEvidence structure
   - Includes OutputRootProof
   - Includes DivergenceWitness
   - ABI encoding

9. [L1 Submission]
   - RAT.submitEvidence(testID, evidenceType=1, evidenceData)
   - evidenceType = 1 (StateLeaf)
   - Gas estimation and submission

10. [On-chain Verification]
   - OutputRootProof verification
   - Checks leafA.key < stateRoot < leafB.key
   - Merkle proof verification
   - Divergence verification
   - Success → Validator is operating an archive node!
```

### StateRoot as Target Method

**L2 Block Determination:**

```go
// 1. Query l2BlockNumber from DisputeGame (already determined)
blockNumber := game.L2BlockNumber()

// 2. Query StateRoot of that block
stateRoot := l2Client.BlockByNumber(blockNumber).StateRoot()

// 3. Convert StateRoot to big.Int (target value)
randomValue := new(big.Int).SetBytes(stateRoot[:])

// 4. Find adjacent leaves based on StateRoot
// Binary search: leafA.key < randomValue <= leafB.key
adjacentLeaves := FindAdjacentLeaves(stateRoot, randomValue, blockNumber)
```

**Why Use StateRoot as Target?**
- **Unpredictable**: StateRoot is a 32-byte hash, selects arbitrary position
- **Prevents pre-computed proof**: Cannot know in advance which account pair will be selected
- **Archive mode required**: Must maintain state of past blocks to generate proof
- **Full state proof**: Must maintain entire state trie to find adjacent leaves

## Trust Model

### Trustless Components

1. **L1 Data**: Ethereum L1 consensus (fully trustless)
2. **op-node**: Deterministic derivation from L1 batch data (trustless)
3. **State Trie**: Cryptographic Merkle Patricia Trie (trustless)
4. **Merkle Proofs**: Cryptographic verification (trustless)

### Trust Assumptions

1. **op-geth Execution**: Assumes validator executes op-geth honestly
   - **Why OK?**: RAT verifies Liveness (node operation)
   - **Correctness**: DisputeGame guarantees state accuracy

2. **debug API Access**: Validator uses debug API on their own op-geth
   - **Requirement**: Debug API is only provided by self-hosted nodes
   - **Security**: Public RPCs disable debug API
   - **Archive Mode**: Must maintain state of challenged block (may be a past block)
   - **Verification**: Confirms state consistency via Merkle proof

### Security Model

```
RAT Client (Fast):
  - Liveness verification
    * Direct full node ownership (debug API)
    * Real-time L2 monitoring
  - 20-30 minutes (Production)
  - Most (99%) of cases

      Failure? → Suspicious
         ↓
DisputeGame (Slow):
  - Correctness verification
    * State accuracy
    * L1 data only
  - 7 days
  - Final safety guarantee
```

## Design Decisions

### 1. Why Adjacent Leaves?

**Alternatives:**
- ❌ eth_getProof for random address: Possible via external RPC (full node not required)
- ❌ Full state re-execution: Too slow (hours)
- ❌ Challenge-response: Too complex, requires multiple rounds

**Adjacent Leaves + debug_accountRange:**
- ✅ Requires full node + debug API
- ✅ Cannot use public RPC (most disable debug API)
- ✅ Fast (20-30 minutes)
- ✅ Simple (1 tx)
- ✅ Prevents caching via StateRoot
- ✅ Unpredictable (cannot know in advance which account will be selected)

**Comparison with Fraud Proof Approach:**

| Aspect | Adjacent Leaves (RPC-based) | Fraud Proof |
|--------|----------------|-------------|
| **Complexity** | Low (RPC calls) | High (batch decode + EVM) |
| **Computation** | Minimal (iterate via debug APIs) | Heavy (execute txs) |
| **Dependencies** | L2 RPC with debug APIs | Full derivation pipeline |
| **Proof Type** | State inclusion | Execution trace |
| **Evidence Size** | ~2-5 KB | ~50-200 KB |
| **Generation Time** | Fast (RPC-dependent) | Slow (full derivation) |
| **Full Node Proof** | ✅ Yes (requires debug APIs) | ❌ Not implemented |
| **Implementation Status** | ✅ Complete & Tested | ❌ Planned only |

### 2. Why Depend on Debug API?

**Different verification purposes:**
```
RAT Client = Liveness
  - Direct full node ownership?
  - Real-time L2 monitoring?

DisputeGame = Correctness
  - Is state correct?
  - Does it match L1 data?
```

**Core of Liveness Verification:**
"Does the validator directly operate a full op-geth node and monitor L2?"

**Why Debug API is Required:**
```
debug_accountRange:
  - Only enabled on full nodes (Archive nodes also possible)
  - Most public RPCs disable it (security/resource reasons)
  - External services like Infura, Alchemy unavailable
  - L2 block selection via StateRoot → Cannot predict which block will be selected
  → Self-hosted op-geth required!
  → Debug API activation required!
  → Must maintain state of all blocks!

eth_getProof (regular API):
  - Can be called from any RPC
  - Only queries specific addresses (can prepare in advance)
  - Can depend on external services
  → Full node + debug API not required
```

**Why is This Sufficient?**
- RAT = Liveness (node operation + monitoring)
- DisputeGame = Correctness (state accuracy)
- Debug API requirement + StateRoot = Liveness verification

### 3. Why OutputRootProof?

**On-chain Verification Efficiency:**
```
Option 1: Submit only StateRoot
  → No way to compare with rootClaim on-chain
  → Challenger doesn't know rootClaim

Option 2: Submit OutputRootProof
  → Verify OutputRootProof.StateRoot
  → Hash entire OutputRootProof → Compare with rootClaim
  → Verification complete!
```

### 4. Why E2E Test?

**Reliability:**
- State trie iteration is complex
- Merkle proof generation is tricky
- ABI encoding must be accurate

→ E2E test with actual op-geth state is essential

## Performance Considerations

### State Trie Iteration

```
Problem: State trie size
  - Mainnet: ~millions of accounts
  - Iteration: Minutes to tens of minutes

Solution: Parallel fetching
  - RPC-based: Pagination via debug_accountRange
  - Direct DB: Faster (LevelDB iterator)
```

### Merkle Proof Generation

```
Problem: Proof size
  - Trie depth: ~64 levels
  - Proof size: ~2-4KB per leaf

Optimization: Compact encoding
  - Use RLP
  - Remove duplicates (same branch node)
```

## Limitations

The current implementation has the following limitations:

### 1. Debug APIs Required
- Public RPC providers (Infura, Alchemy, etc.) don't expose `debug_accountRange` API
- Validators must run their own L2 node with debug APIs enabled
- Cannot rely on external RPC services for evidence generation

### 2. Archive Mode Required
- Must access state at specific past blocks (challenges may reference old blocks)
- Full nodes with default pruning may have already deleted challenged block's state
- Archive mode recommended to ensure state availability (disk: ~10+ TB)

### 3. L2 Node Dependency
- Validators must run and maintain their own op-geth infrastructure
- Requires technical expertise for node operation and maintenance
- Node must stay synced to respond to challenges

### 4. RPC Performance Dependency
- State iteration speed depends on L2 RPC performance
- Large state tries (1M+ accounts) may take significant time to iterate
- Network latency affects proof generation time

### 5. Single Verification Method
- Currently only implements state trie iteration approach (Evidence Type 1)
- Fraud Proof approach (Evidence Type 0) planned but not implemented
- No fallback if debug APIs become unavailable

## Future Improvements

### 1. Stateless Execution Mode

Currently focused only on state trie iteration
Future: Can add L1-only execution
```
Stateless Executor:
  - Uses only L1 batch data
  - State pre-fetching with proofs
  - Fully trustless
  - Slow but L2 RPC not required
```

### 2. Multiple Verification Methods

```
Fast Path (current):
  - Adjacent leaves
  - 20-30 minutes (Production)

Medium Path (future):
  - Stateless execution
  - 1-2 hours
  - L2 RPC not required

Slow Path (always):
  - DisputeGame
  - 7 days
  - Final safety
```

## Reference Implementation

Key Files:
- `pkg/client/service_adjacent.go` - Main service
- `pkg/l2sync/state_trie.go` - State trie iterator
- `pkg/evidence/state_leaf_evidence.go` - Evidence structure
- `pkg/submitter/adjacent_submitter.go` - Submission logic
- `test/state_leaf_e2e_test.go` - E2E tests

## Conclusion

RAT Client Type 3 is a **practical system for verifying Validator Liveness**:

**What is Liveness?**
- Direct full node ownership (Self-hosted op-geth with Archive mode)
- L2 monitoring (maintaining state of challenged block)
- Debug API access (Public RPC unavailable)

**Core Features:**
- Fast (20-30 minutes, Production)
- Simple (adjacent leaves + debug API)
- Practical (StateRoot as target, cannot predict which account will be selected)
- Safe (DisputeGame fallback)

**Design Philosophy:**
- Liveness (RAT) vs Correctness (DisputeGame)
- Debug API requirement → Full node + debug mode required
- StateRoot → Prevents pre-computed proof
- Handles 99% of cases quickly
- Resolves 1% suspicious cases via DisputeGame
- Achieves balance with 2-tier security model

