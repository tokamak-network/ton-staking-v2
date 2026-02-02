# OutputRootProof Verification

## 5.1 What is OutputRootProof?

Optimism's Output Root is a hash value that commits L2 state to L1:

```
OutputRoot = keccak256(
    version                  ||  // 0x0000...0000 (32 bytes)
    stateRoot                ||  // L2 state root
    messagePasserStorageRoot ||  // L2ToL1MessagePasser storage root
    blockHash                    // L2 block hash
)
```

**OutputRootProof Structure**:
```solidity
struct OutputRootProof {
    bytes32 version;                      // Always 0x0
    bytes32 stateRoot;                    // L2 state root
    bytes32 messagePasserStorageRoot;     // Withdrawal storage root
    bytes32 latestBlockHash;              // L2 block hash
}
```

## 5.2 Method 1: Generate OutputRootProof with L2 RPC (✅ Default)

**Advantages**:
- No OpNode needed
- Fast (no additional infrastructure)
- Complete with L2 RPC only

**Implementation** (`service_adjacent.go:431-490`):
```go
// 1. Query L2 block header
header, err := l2Client.HeaderByNumber(ctx, blockNumber)
stateRoot := header.Root
blockHash := header.Hash()

// 2. L2ToL1MessagePasser predeploy address
messagePasserAddr := common.HexToAddress("0x4200000000000000000000000000000000000016")

// 3. Query MessagePasser storage root with eth_getProof
proofResult, err := l2Client.CallContext(ctx, &result, "eth_getProof",
    messagePasserAddr, []string{}, blockHex)
messagePasserStorageRoot := proofResult.StorageHash

// 4. Generate OutputRootProof
outputRootProof := &OutputRootProof{
    Version:                  [32]byte{}, // 0x0
    StateRoot:                stateRoot,
    MessagePasserStorageRoot: messagePasserStorageRoot,
    LatestBlockHash:          blockHash,
}

// 5. Calculate and verify OutputRoot
computedOutputRoot := keccak256(
    outputRootProof.Version,
    outputRootProof.StateRoot,
    outputRootProof.MessagePasserStorageRoot,
    outputRootProof.LatestBlockHash,
)

if computedOutputRoot != expectedOutputRoot {
    return error("OutputRoot mismatch")
}
```

**Requirements**:
- L2 geth (archive mode)
- `eth_getProof` API
- L2ToL1MessagePasser predeploy contract

**Trustless Level**: Self-hosted L2 RPC trust required (practically trustless as operator manages directly)

## 5.3 Method 2: Query OutputRootProof from OpNode

**Advantages**:
- Trustlessly derived from L1
- Recalculate L2 state from L1 data
- 100% trustless verification

**Implementation** (`service_adjacent.go:374-390`):
```go
// Use op-node if configured
if s.opNodeClient != nil {
    opNodeProof, err := s.opNodeClient.GetOutputRootProof(ctx, blockNumber)
    if err != nil {
        log.Printf("Failed to get OutputRootProof from op-node: %v", err)
        // Fallback to L2 RPC calculation
    } else {
        // Use OutputRootProof from op-node
        ev.OutputRootProof = *opNodeProof
    }
}
```

**Requirements**:
- op-node running
- Rollup RPC access (`optimism_outputAtBlock`)
- L1 RPC access

**Trustless Level**: 100% (uses L1 data only)

**Note**: If `opNodeClient == nil`, errors are ignored and proceeds with L2 RPC

## 5.4 Role of OutputRootProof Verification

**Question**: What happens if OutputRootProof verification fails?

**Answer**:
- Current implementation: Return error and abort evidence submission (`service_adjacent.go:324`)
- When OpNode unavailable: Generate OutputRootProof with L2 RPC and continue

**Purpose**:
1. Verify StateRoot integrity
2. Verify correct L2 block number
3. Compare with DisputeGame rootClaim

**Important**: Generate and submit Adjacent Leaves evidence **when OutputRootProof is correct**
- RAT verifies Liveness (full node operation proof)
- Proves validator possesses correct state
- Evidence is submitted only when DisputeGame's rootClaim matches calculated OutputRoot

---

**Next**: [Deployment and Operations](./06-deployment-operations.md)
