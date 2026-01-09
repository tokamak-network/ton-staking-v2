# RAT Client Type 3 Implementation Plan

## Overview
Implement a RAT (Randomized Attention Test) client in Go **specifically for TON Staking V3 Rollup Type 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)**.

**Important**: This is a Type 3-specific implementation. Future rollup types (Type 4, Type 5, etc.) will have their own separate RAT client implementations. This client is NOT designed for cross-type compatibility. The client monitors L1 for RAT events, verifies proposer-submitted state roots by deriving L2 state from L1 batch data, generates fraud-proof-style evidence with Merkle proofs, and submits evidence to the RAT contract.

### TON Staking Rollup Types (L1BridgeRegistryV1_2)
```solidity
enum TYPE_ROLLUPCONFIG {
    NONE,                                    // 0 - Not registered
    LEGARCY,                                 // 1 - TOKAMAK (Legacy) with L1StandardBridge
    OPTIMISM_BEDROCK,                        // 2 - Optimism Bedrock without RAT
    OPTIMISM_BEDROCK_WITH_DISPUTE_GAME       // 3 - Optimism Bedrock + DisputeGameFactory + RAT
}
```

This RAT client is specifically for **Type 3 rollups (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)** where:
- DisputeGameFactory automatically calls `RAT.triggerAttentionTest()` on game creation
- FaultDisputeGame calls `RAT.resolveClaim()` when challenger wins
- Validators must respond to attention tests to maintain their bonds

## User Requirements
- **Language**: Go (custom implementation, reference Optimism code but don't import)
- **Evidence Format**: Fraud proof style with Merkle proofs and execution traces
- **Scope**: Monitor single L2 (one SystemConfig)
- **Verification Method**: Trustless derivation from L1 data (see below)

## Trustless Verification Flow

**Critical Design Principle**: The RAT client **MUST NOT trust the L2 node** for verification. All L2 state must be derived from L1 batch data to ensure trustless verification even if the L2 node is malicious.

### Why Trustless?

If the RAT client fetches L2 block headers from the L2 RPC endpoint:
```go
// ❌ WRONG - Trusts L2 node
header := l2Client.HeaderByNumber(l2BlockNum)
headerRLP := rlp.EncodeToBytes(header)
```

**Problem**: If the L2 node is compromised or malicious, it can return fake headers with incorrect state roots, invalidating the entire verification process.

### Correct Approach: Derive from L1 Data

```
L1 Batch Data → Decode Batches → Execute Transactions → Compute State Root → Reconstruct L2 Header
```

**Step-by-step**:

1. **Fetch batch data from L1 DA** (calldata/blobs):
   ```go
   batches := FetchL1Batches(finalizedL2Block, currentL1Block)
   ```

2. **Decode batches** to extract transactions:
   ```go
   for batch := range batches {
       txs := DecodeBatch(batch)  // Get raw transactions
   }
   ```

3. **Execute transactions** to derive state:
   ```go
   stateDB := NewStateDB(finalizedStateRoot)  // Start from finalized state

   for tx := range batch.Transactions {
       receipt := ApplyTransaction(stateDB, tx)
       gasUsed += receipt.GasUsed
   }

   newStateRoot := stateDB.IntermediateRoot()  // Computed state root
   ```

4. **Reconstruct L2 block header** from execution results:
   ```go
   header := types.Header{
       ParentHash:  batch.ParentHash,
       Root:        newStateRoot,           // From execution
       TxHash:      deriveTxHash(txs),      // Computed from txs
       ReceiptHash: deriveReceiptHash(receipts),
       Number:      blockNum,
       GasUsed:     gasUsed,
       Timestamp:   batch.Timestamp,
       // ... other fields from batch
   }

   headerRLP := rlp.EncodeToBytes(header)
   blockHash := keccak256(headerRLP)
   ```

5. **Compute output root** from derived data:
   ```go
   withdrawalRoot := stateDB.GetStorageRoot(L2ToL1MessagePasser)

   outputRoot := keccak256(abi.encodePacked(
       bytes32(0),        // version
       newStateRoot,      // from execution
       withdrawalRoot,    // from state trie
       blockHash          // from derived header
   ))
   ```

6. **Compare** computed vs claimed:
   ```go
   if outputRoot != claimedOutputRoot {
       // Generate fraud proof evidence
       submitEvidence(testId, evidence)
   }
   ```

**Key Benefits**:
- ✅ **Trustless**: No dependency on L2 node honesty
- ✅ **Verifiable**: All data derived from L1 (immutable, consensus-backed)
- ✅ **Complete**: Can reconstruct entire L2 state from L1 data
- ✅ **Fraud-proof ready**: Evidence includes Merkle proofs of L1 data

**Implementation Requirements**:
- EVM execution engine (reference go-ethereum/core/state)
- State trie (Patricia Merkle Tree) implementation
- RLP encoding/decoding
- Optimism-specific state transitions (L1 attributes deposit tx)

## Project Structure

```
ton-staking-v2/
└── clients/
    └── rat-client-type3/
        ├── cmd/main.go                              # CLI entrypoint
        ├── pkg/
        │   ├── client/
        │   │   ├── service.go                       # Main service lifecycle
        │   │   ├── config.go                        # Configuration
        │   │   └── cli.go                           # CLI flags
        │   ├── monitor/
        │   │   └── event_monitor.go                 # L1 event monitoring
        │   ├── derivation/
        │   │   ├── batch_fetcher.go                 # Fetch L1 batches
        │   │   ├── batch_decoder.go                 # Decode batches
        │   │   └── state_executor.go                # L2 state derivation
        │   ├── verification/
        │   │   └── output_root.go                   # Output root computation
        │   ├── evidence/
        │   │   ├── generator.go                     # Evidence generation
        │   │   └── merkle.go                        # Merkle proof construction
        │   └── submitter/
        │       └── evidence_submitter.go            # Submit to RAT contract
        ├── bin/rat-client-type3                     # Binary output
        ├── go.mod                                   # Module: github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3
        └── README.md
```

## Core Components

### 1. Event Monitor (`pkg/monitor/event_monitor.go`)
**Responsibility**: Poll L1 for `AttentionTestTriggered` events

**Algorithm**:
```
Loop every 12 seconds:
1. Query eth_getLogs from lastProcessedBlock to currentBlock
   - Filter: contract=RAT, topic2=validatorAddress
2. For each event:
   - Parse testId, systemConfig, batchIndex, deadline
   - Check systemConfig matches configured value
   - Check deadline hasn't passed
   - Push to processing queue
3. Handle L1 reorgs (maintain 64-block cache)
```

**Critical**: Must detect reorgs and reprocess invalidated events

### 2. Batch Fetcher (`pkg/derivation/batch_fetcher.go`)
**Responsibility**: Fetch L1 batch data from finalized blocks

**Algorithm**:
```
FetchBatches(finalizedL2Block):
1. Get L2 block's L1 origin
2. For each L1 block from (origin + 1) to current:
   - Filter txs: to=BatchInbox, from=BatcherAddr
   - Extract batch data:
     * Pre-Ecotone: calldata
     * Post-Ecotone: blobs (eth_getBlobSidecars)
3. Return raw batch list with L1 provenance
```

**Data Sources**: Calldata, EIP-4844 blobs, AltDA

### 3. Batch Decoder (`pkg/derivation/batch_decoder.go`)
**Responsibility**: Decode frames → channels → batches

**Pipeline**:
```
RawBytes → Frames → Channels → Decompress → Batches
```

**Batch Formats**:
- Type 0 (SingularBatch): RLP([parentHash, epochNum, epochHash, timestamp, txs])
- Type 1 (SpanBatch): Custom encoding for multiple blocks

### 4. State Executor (`pkg/derivation/state_executor.go`)
**Responsibility**: Derive L2 state from batches **without trusting L2 node**

**Trustless Approach** (Derive from L1 Data):
```
DeriveL2State(batches, finalizedStateRoot):
1. Initialize state from last finalized L2 block
   - stateDB := NewStateDB(finalizedStateRoot)

2. For each batch:
   a) Execute transactions:
      - For each tx in batch.Transactions:
        * Apply tx to stateDB
        * Compute receipt
        * Track gas used

   b) Compute state root after execution:
      - newStateRoot := stateDB.IntermediateRoot()

   c) Reconstruct L2 block header:
      - header := types.Header{
          ParentHash:  expectedParent,
          Root:        newStateRoot,
          TxHash:      deriveTxHash(batch.Transactions),
          ReceiptHash: deriveReceiptHash(receipts),
          Number:      blockNum,
          GasUsed:     totalGasUsed,
          Timestamp:   batch.Timestamp,
          // ... other fields from batch
        }

   d) Encode header to RLP:
      - headerRLP := rlp.EncodeToBytes(header)
      - blockHash := keccak256(headerRLP)

3. Return (blockNum, newStateRoot, blockHash, headerRLP)
```

**Critical**: L2 block header and state root are **derived entirely from L1 batch data**, not fetched from L2 node. This ensures trustless verification even if L2 node is malicious.

**Implementation Notes**:
- Requires EVM execution engine (reference go-ethereum/core/state)
- Must maintain state trie (Patricia Merkle Tree)
- Must handle Optimism-specific state transitions (L1 attributes deposit tx)
- Can optimize by using L2 RPC for initial finalized state, then derive forward

### 5. Output Root Computation (`pkg/verification/output_root.go`)
**Responsibility**: Compute L2 output root from **derived L2 state** (not from L2 RPC)

**Algorithm**:
```go
ComputeOutputRoot(derivedHeader, derivedStateRoot):
1. Compute withdrawal storage root from derived state:
   - Post-Isthmus:
     * withdrawalRoot := derivedHeader.WithdrawalsHash
   - Pre-Isthmus:
     * Query stateDB for L2ToL1MessagePasser account
     * withdrawalRoot := stateDB.GetStorageRoot(L2ToL1MessagePasser)

2. Construct OutputV0:
   - StateRoot: derivedStateRoot (from batch execution)
   - MessagePasserStorageRoot: withdrawalRoot (from state trie)
   - BlockHash: keccak256(rlp.Encode(derivedHeader))

3. Compute output root hash:
   outputRoot := keccak256(abi.encodePacked(
       bytes32(0),           // version
       derivedStateRoot,
       withdrawalRoot,
       derivedBlockHash
   ))

4. Return outputRoot
```

**Critical**: All data comes from **locally derived state**, not from L2 RPC queries

### 6. Evidence Generator (`pkg/evidence/generator.go`)
**Responsibility**: Generate fraud-proof evidence with Merkle proofs for **on-chain verification**

**Evidence Structure (ABI-encoded for Solidity verification)**:
```solidity
struct Evidence {
    // L2 data
    uint256 l2BlockNumber;
    bytes32 l2BlockHash;
    bytes32 l2StateRoot;
    bytes32 withdrawalRoot;
    bytes32 outputRoot;

    // L1 provenance
    uint256 l1BlockNumber;
    bytes32 l1BlockHash;
    uint256 l1TxIndex;
    bytes32 l1TxHash;
    bytes   batchData;

    // Merkle proofs (for on-chain verification)
    bytes32[] stateProof;      // Proves stateRoot in L2 block header
    bytes32[] withdrawalProof; // Proves withdrawal storage root
    bytes32[] batchProof;      // Proves batch data in L1 tx trie
    bytes     l2HeaderRLP;     // Full L2 block header RLP for verification
}
```

**On-Chain Verification Gas Cost**: ~200,000 - 500,000 gas
- Merkle proof verification: ~30,000 gas per proof
- RLP decoding: ~50,000 gas
- Total: 3 proofs + RLP + computation

**Algorithm**:
```
GenerateEvidence(testId, batchIndex, computedStateRoot):
1. Build Merkle proof for batch data in L1 block
   - Compute L1 transaction trie
   - Generate proof for batcher tx at txIndex
2. Build Merkle proof for L2 state root
   - RLP encode L2 block header
   - Generate proof for stateRoot field
3. Build Merkle proof for withdrawal storage root
   - Get account proof for L2ToL1MessagePasser
   - Extract storage trie proof
4. Encode all proofs compactly
```

### 7. Evidence Submitter (`pkg/submitter/evidence_submitter.go`)
**Responsibility**: Submit evidence to RAT contract

**Algorithm**:
```
SubmitEvidence(testId, evidence, deadline):
1. Check: deadline - now >= 10 minutes (safety buffer)
2. Encode evidence bytes
3. Build tx: submitEvidence(systemConfig, batchIndex, evidenceBytes)
4. Submit via TxManager with gas bumping
5. Wait for receipt and verify success
```

## Main Processing Flow

```
1. EventMonitor detects AttentionTestTriggered
   ↓
2. Check: validatorAddress == myAddress && systemConfig == myConfig
   ↓
3. Fetch L1 batches from finalized block to current
   ↓
4. Decode batches (frames → channels → batches)
   ↓
5. Derive L2 state (execute batches, compute state roots)
   ↓
6. Compute output root at target L2 block
   ↓
7. Compare: computed output root vs claimed output root
   ↓
   ┌─────────┬─────────┐
   │ MATCH   │ MISMATCH│
   ↓         ↓
8a. Generate 8b. Participate in
    evidence      FaultDisputeGame
    ↓
9. Submit evidence to RAT contract
   ↓
10. Bond restored (success)
```

## On-Chain Verification Requirements

### RAT Contract Modifications Needed

The current `RAT.sol` has a TODO placeholder for evidence verification. **On-chain verification requires implementing**:

```solidity
// RAT.sol additions needed:

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { RLPReader } from "src/libraries/rlp/RLPReader.sol";

struct Evidence {
    uint256 l2BlockNumber;
    bytes32 l2BlockHash;
    bytes32 l2StateRoot;
    bytes32 withdrawalRoot;
    bytes32 outputRoot;
    uint256 l1BlockNumber;
    bytes32 l1BlockHash;
    uint256 l1TxIndex;
    bytes32 l1TxHash;
    bytes   batchData;
    bytes32[] stateProof;
    bytes32[] withdrawalProof;
    bytes32[] batchProof;
    bytes     l2HeaderRLP;
}

function _verifyEvidence(bytes32 batchHash, bytes calldata evidenceData)
    internal pure returns (bool)
{
    Evidence memory ev = abi.decode(evidenceData, (Evidence));

    // 1. Verify state root in L2 block header
    if (!_verifyStateRootInHeader(ev.l2BlockHash, ev.l2StateRoot, ev.stateProof, ev.l2HeaderRLP)) {
        return false;
    }

    // 2. Verify withdrawal storage root
    if (!_verifyWithdrawalRoot(ev.l2BlockHash, ev.withdrawalRoot, ev.withdrawalProof)) {
        return false;
    }

    // 3. Verify batch data in L1
    if (!_verifyBatchDataInL1(ev.l1BlockHash, ev.l1TxIndex, ev.batchData, ev.batchProof)) {
        return false;
    }

    // 4. Compute and verify output root
    bytes32 computedOutputRoot = keccak256(abi.encodePacked(
        bytes32(0),           // version
        ev.l2StateRoot,
        ev.withdrawalRoot,
        ev.l2BlockHash
    ));

    return computedOutputRoot == batchHash;
}

function _verifyStateRootInHeader(
    bytes32 blockHash,
    bytes32 stateRoot,
    bytes32[] memory proof,
    bytes memory headerRLP
) internal pure returns (bool) {
    // Verify blockHash = keccak256(headerRLP)
    if (keccak256(headerRLP) != blockHash) return false;

    // Decode RLP and extract stateRoot (4th field)
    // Verify via Merkle proof
    // Return true if valid
}

function _verifyWithdrawalRoot(
    bytes32 blockHash,
    bytes32 withdrawalRoot,
    bytes32[] memory proof
) internal pure returns (bool) {
    // Verify L2ToL1MessagePasser storage root via Merkle proof
}

function _verifyBatchDataInL1(
    bytes32 l1BlockHash,
    uint256 txIndex,
    bytes memory batchData,
    bytes32[] memory proof
) internal pure returns (bool) {
    // Verify batchData exists in L1 transaction trie via Merkle proof
}
```

**Dependencies:**
- OpenZeppelin MerkleProof library
- Optimism RLPReader library (already exists)
- Trie proof verification utilities

**Gas Estimates:**
- State root verification: ~80,000 gas
- Withdrawal root verification: ~60,000 gas
- Batch data verification: ~80,000 gas
- RLP decoding: ~50,000 gas
- **Total: ~270,000 - 500,000 gas**

## Implementation Phases

### Phase 0: Contract Preparation (Week 0)
**PREREQUISITE**: RAT.sol must be updated with on-chain verification logic before client development

- [ ] Implement Evidence struct in RAT.sol
- [ ] Implement _verifyEvidence() function
- [ ] Implement Merkle proof verification helpers
- [ ] Add RLP decoding for L2 headers
- [ ] Test on-chain verification with sample proofs
- [ ] Deploy updated RAT contract

**Deliverable**: RAT contract with complete on-chain verification

### Phase 1: Infrastructure (Week 1-2)
- [ ] Create project structure
- [ ] Implement RATClientService with lifecycle (Start/Stop)
- [ ] Implement EventMonitor with L1 polling
- [ ] Implement event parsing and filtering
- [ ] Add CLI and configuration

**Deliverable**: Service that detects RAT events

### Phase 2: Batch Processing (Week 3-4)
- [ ] Implement BatchFetcher (calldata + blobs)
- [ ] Implement frame parsing
- [ ] Implement channel assembly and decompression
- [ ] Implement batch decoder (SingularBatch, SpanBatch)

**Deliverable**: Service that fetches and decodes batches

### Phase 3: State Derivation (Week 5-6)
- [ ] Implement StateExecutor (L2 RPC verification)
- [ ] Implement OutputRoot computation
- [ ] Handle Isthmus vs pre-Isthmus
- [ ] Implement state root comparison

**Deliverable**: Service that verifies state roots

### Phase 4: Evidence (Week 7-8)
- [ ] Implement Merkle proof construction
- [ ] Implement batch data proof
- [ ] Implement state proof + withdrawal proof
- [ ] Implement evidence encoding

**Deliverable**: Service that generates evidence

### Phase 5: Submission (Week 9-10)
- [ ] Implement EvidenceSubmitter with TxManager
- [ ] Implement gas estimation and bumping
- [ ] Implement deadline checking
- [ ] Add retry logic

**Deliverable**: Fully functional RAT client

### Phase 6: Production (Week 11-12)
- [ ] Add metrics (Prometheus)
- [ ] Implement L1 reorg handling
- [ ] Add comprehensive logging
- [ ] E2E tests with op-e2e framework
- [ ] Performance optimization

**Deliverable**: Production-ready RAT client

## Critical Files to Create

**Priority 1 (Core)**:
1. `pkg/client/service.go` - Service lifecycle, orchestrates all components
2. `pkg/monitor/event_monitor.go` - Detect RAT events from L1
3. `pkg/derivation/batch_fetcher.go` - Fetch L1 batch data

**Priority 2 (Verification)**:
4. `pkg/derivation/batch_decoder.go` - Decode batches
5. `pkg/verification/output_root.go` - Compute output root
6. `pkg/derivation/state_executor.go` - Derive L2 state

**Priority 3 (Evidence)**:
7. `pkg/evidence/generator.go` - Generate evidence with proofs
8. `pkg/evidence/merkle.go` - Merkle proof construction
9. `pkg/submitter/evidence_submitter.go` - Submit to RAT

**Priority 4 (Support)**:
10. `pkg/client/config.go` - Configuration structures
11. `cmd/rat-client-type3/main.go` - CLI entrypoint

## Future Rollup Types

This implementation is **Type 3 specific**. When new rollup types are introduced:

- **Type 4**: Will require a new `rat-client-type4` project with its own verification logic
- **Type 5**: Will require a new `rat-client-type5` project
- **No cross-compatibility**: Each type has fundamentally different architectures and verification methods

**Type 3 Characteristics:**
- Uses DisputeGameFactory for game creation
- Integrates with FaultDisputeGame for fraud proofs
- Optimism Bedrock batch format (frames → channels → batches)
- Output root verification (state root + withdrawal root + block hash)

## Key Algorithms

### Batch Format Handling

**SingularBatch (Type 0)**:
```go
type SingularBatch struct {
    ParentHash   common.Hash
    EpochNum     uint64
    EpochHash    common.Hash
    Timestamp    uint64
    Transactions [][]byte
}
```

**SpanBatch (Type 1)**: Custom encoding for multiple blocks (see Optimism spec)

### Output Root Computation

```go
// Pre-Isthmus
proof := l2Client.GetProof(L2ToL1MessagePasser, nil, blockHash)
withdrawalRoot := proof.StorageHash

// Post-Isthmus
withdrawalRoot := *header.WithdrawalsHash

// Compute output root
output := OutputV0{
    StateRoot: header.Root,
    MessagePasserStorageRoot: withdrawalRoot,
    BlockHash: blockHash,
}
outputRoot := keccak256(version || stateRoot || wdRoot || blockHash)
```

### L1 Reorg Handling

```
On each poll:
1. Fetch L1 head
2. Verify blockHash at (head - 64) matches cache
3. If mismatch:
   - Binary search for reorg depth
   - Rewind lastProcessedBlock
   - Clear invalid events
   - Re-fetch from reorg point
```

## Configuration

```yaml
# L1/L2 RPC endpoints
l1_rpc: "https://mainnet.infura.io/v3/..."
l2_rpc: "https://optimism-mainnet.infura.io/v3/..."

# Validator identity
private_key: "0x..."
validator_address: "0x..."

# Contract addresses
rat_contract: "0x..."
system_config: "0x..."
batch_inbox: "0x..."
batcher_address: "0x..."

# Monitoring
poll_interval: 12s
confirmations: 64

# Derivation
derivation_timeout: 5m
l1_lookback_blocks: 1000

# Submission
deadline_buffer: 10m
gas_limit: 500000
```

## Testing Strategy

### Unit Tests
- Batch decoder (all formats, compression)
- Output root computation (pre/post Isthmus)
- Merkle proof generation
- Event parsing
- Reorg detection

### Integration Tests
- Full pipeline with local Anvil + op-geth
- RAT event trigger and processing
- Evidence submission to RAT contract
- L1 reorg recovery

### E2E Tests
- Use op-e2e framework
- Real batch data from L1
- Multiple validators competing

## Security Considerations

1. **Private Key**: Never log, use secure key management
2. **RPC Trust**: Validate responses, detect malicious providers
3. **Deadline Safety**: 10-minute buffer before deadline
4. **Reorg Protection**: Wait 64 confirmations before processing
5. **Gas Cap**: Max gas price to prevent DoS
6. **Proof Validation**: Verify all Merkle proofs before submission

## References

### Optimism Codebase (for reference only, don't import):
- Derivation pipeline: `lib/optimism/op-node/rollup/derive/`
- Batch formats: `lib/optimism/op-node/rollup/derive/batch.go`
- Output root: `lib/optimism/op-service/eth/output.go`
- State execution: `lib/optimism/op-program/client/l2/engine.go`

### TON Staking V3:
- RAT contract: `src/validator/RAT.sol`
- RAT bindings: `op-e2e/bindings/rat.go`
- E2E test helpers: `op-e2e/faultproofs/rat_challenge_helpers.go`

### Service patterns:
- Op-batcher: `lib/optimism/op-batcher/batcher/service.go`
- Op-proposer: `lib/optimism/op-proposer/proposer/l2_output_submitter.go`

## Success Criteria

1. **Functional**: Correctly verifies state roots and submits evidence
2. **Reliable**: Handles L1 reorgs and network failures gracefully
3. **Timely**: Submits evidence before deadline (with 10min buffer)
4. **Observable**: Comprehensive metrics and logging
5. **Tested**: >80% code coverage, passing E2E tests
6. **Production-ready**: Proper error handling, graceful shutdown
