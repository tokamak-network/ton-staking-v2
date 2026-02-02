# Go Client Implementation

## 4.1 Package Structure

```
clients/rat-client-type3/
├── cmd/main.go                 # Entry point
├── pkg/
│   ├── monitor/                # L1 event monitoring
│   ├── l2sync/                 # L2 state synchronization ⭐ (Debug RPC)
│   ├── evidence/               # Evidence generation (StateLeafEvidence)
│   ├── verification/           # OutputRootProof verification (optional)
│   ├── submitter/              # Evidence submission (L1 transaction)
│   └── client/                 # Main service
│       └── service_adjacent.go # ⭐ Actual production use
└── test/                       # E2E tests
    └── state_leaf_rpc_e2e_test.go  ⭐ Recommended
```

## 4.2 Core Packages

### monitor - L1 Event Detection
- Monitor `AttentionTestTriggered` events from RAT contract
- Filter for own validator address
- Apply L1 confirmations

### l2sync - Find Adjacent Leaves ⭐
- **Debug RPC Mode** (✅ Production): `debug_accountRange` + `eth_getProof`
- Divergence node calculation
- Gap pre-verification

**Core File**: `pkg/l2sync/state_rpc.go`

### evidence - Evidence Generation
- Create StateLeafEvidence structure
- Add OutputRootProof
- Calculate DivergenceWitness
- ABI encoding (Solidity compatible)

### verification - OutputRootProof Verification
- **Method 1**: Calculate directly with L2 RPC (`eth_getProof`)
- **Method 2**: Use OpNode Rollup RPC (`optimism_outputAtBlock`)
- Verify state root integrity

### submitter - Evidence Submission
- Call RAT contract `submitEvidence()`
- Gas price optimization
- Retry logic

## 4.3 Debug RPC-based Evidence Generation Flow

```
[RAT Test Triggered]
       ↓
[EventMonitor Detection]
       ↓
[L2 Block Determination (DisputeGame query)]
       ↓
[StateRoot Query (L2 RPC)]
       ↓
[(Optional) OutputRootProof Verification]
├─ L2 RPC: Calculate with eth_getProof
└─ Or OpNode: optimism_outputAtBlock
       ↓
┌──────────────────────────────────┐
│ l2sync.FindAdjacentLeavesViaRPC  │ ⭐ Main logic
├──────────────────────────────────┤
│ 1. Call debug_accountRange       │
│    → Query all accounts          │
│ 2. Binary search                 │
│    → Find position by StateRoot  │
│ 3. Select adjacent addresses     │
│    → leafA.key < stateRoot <= leafB.key │
│ 4. Call eth_getProof (x2)        │
│    → Get Merkle proofs           │
│ 5. Account RLP encoding          │
│ 6. Local verification            │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ l2sync.FindDivergenceNode        │
├──────────────────────────────────┤
│ 1. Find common ancestor of proofs│
│ 2. Extract indexA, indexB        │
│ 3. Check direct divergence       │
│ 4. Pre-verify gap                │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ evidence.NewStateLeafEvidence    │
├──────────────────────────────────┤
│ 1. Verify key order              │
│ 2. Add OutputRootProof           │
│ 3. Add DivergenceWitness         │
│ 4. ABI encoding                  │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ submitter.SubmitEvidence         │
├──────────────────────────────────┤
│ Call RAT.submitEvidence()        │
└──────────────────────────────────┘

⭐ Generate and submit evidence when OutputRootProof is correct
```

## 4.4 Core Function: FindAdjacentLeavesViaRPC()

**Debug RPC Mode** (✅ **Production Use** - Geth v1.13+ PBSS compatible):

```go
// 1. Query all accounts with debug_accountRange
result, err := client.CallContext(ctx, &result, "debug_accountRange",
    blockHex,                    // Block number
    "0x0000...0000",            // Start address (full query)
    10000000,                    // Max count (sufficiently large)
    false, false, false)

// 2. Sorted accounts (sorted by keccak256(address))
sorted := SortAccountsByKey(result.Accounts)

// 3. Find position with binary search based on StateRoot
randomHash := common.BigToHash(new(big.Int).SetBytes(stateRoot[:]))
idx := BinarySearch(sorted, randomHash)

// 4. Select adjacent leaves
if idx == 0 {
    // StateRoot < all keys → Use first two accounts
    accountA, accountB = sorted[0], sorted[1]
} else if idx >= len(sorted) {
    // StateRoot > all keys → Use last two accounts
    accountA, accountB = sorted[len-2], sorted[len-1]
} else {
    // General case: leafA.key < stateRoot <= leafB.key
    accountA, accountB = sorted[idx-1], sorted[idx]
}

// 5. Get Merkle proofs with eth_getProof
proofA, accountDataA := client.CallContext("eth_getProof", accountA.Address, [], blockHex)
proofB, accountDataB := client.CallContext("eth_getProof", accountB.Address, [], blockHex)

// 6. Account RLP encoding
leafAValue := RLP(accountDataA.Nonce, accountDataA.Balance,
                  accountDataA.StorageHash, accountDataA.CodeHash)
leafBValue := RLP(accountDataB.Nonce, accountDataB.Balance,
                  accountDataB.StorageHash, accountDataB.CodeHash)

// 7. Local verification
VerifyStateProof(stateRoot, leafA.Key, leafA.Value, proofA)
VerifyStateProof(stateRoot, leafB.Key, leafB.Value, proofB)
```

**Advantages**:
- ✅ Geth v1.13+ **PBSS (Path-Based State Storage) compatible**
- ✅ No direct StateDB access needed
- ✅ Very fast
- ✅ Lightweight resources
- ✅ **In production use**

**Requirements**:
- L2 RPC node (op-geth, archive mode)
- `debug_accountRange` API enabled ⭐
- `eth_getProof` API enabled

**⚠️ Note**: In Geth v1.13+, direct StateDB access is restricted due to PBSS. **Use Debug RPC mode.**

## 4.5 Core Function: FindDivergenceNode()

**Purpose**: Calculate divergence point off-chain → save on-chain gas

```go
// 1. Compare proofs from beginning
for i := 0; i < minLen; i++ {
    if hash(proofA[i]) != hash(proofB[i]) {
        divergenceNode = proofA[i-1]  // Previous node is divergence point
        break
    }
}

// 2. Extract indexA, indexB from divergence node
indexA, indexB = FindChildIndices(divergenceNode, leafAKey, leafBKey, depth)

// 3. Check direct divergence (Best Practice)
isDirectDivergence := VerifyDirectDivergence(divergenceNode, indexA, indexB)

// 4. Pre-verify gap (prevent on-chain failure)
if indexB - indexA > 1 {
    gapValid := VerifyGapBetweenIndices(divergenceNode, indexA, indexB)
    if !gapValid {
        return error("Gap has data - abort evidence submission")
        // Prevent gas waste! Avoid on-chain verification failure
    }
}
```

---

**Next**: [OutputRootProof Verification](./05-outputrootproof-verification.md)
