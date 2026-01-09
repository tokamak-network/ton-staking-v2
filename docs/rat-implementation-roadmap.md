# RAT (Randomized Attention Test) Implementation Roadmap

## Overview

This document outlines the phased approach for implementing the RAT system, starting with a basic Merkle proof-based verification and later upgrading to ZK proof for gas optimization.

## Architecture Evolution

### Phase 1: Basic Implementation (Merkle Proof)
```
┌─────────────────────────────────────────────────────────┐
│                   RAT Client (Go)                       │
│  - Monitor L1 AttentionTestTriggered events             │
│  - Query L2 state via Rollup RPC                        │
│  - Find adjacent leaves (leafA, leafB)                  │
│  - Generate Merkle proofs                               │
│  - Submit evidence to L1                                │
└────────────────┬────────────────────────────────────────┘
                 │ EvidenceData (leafA, leafB, proofs)
                 ▼
┌─────────────────────────────────────────────────────────┐
│               L1 RAT Contract                           │
│  - Verify Merkle proofs (leafA, leafB)                  │
│  - Check index continuity                               │
│  - Verify range (A <= random <= B)                      │
│  - Execute penalty/reward                               │
│                                                          │
│  Gas Cost: ~400-600k per verification                   │
└─────────────────────────────────────────────────────────┘
```

### Phase 2: ZK Upgrade (RISC Zero)
```
┌─────────────────────────────────────────────────────────┐
│              RAT Client (Go) - Host                     │
│  - Monitor L1 events                                    │
│  - Query L2 state                                       │
│  - Find adjacent leaves                                 │
│  - Call RISC Zero prover                                │
└────────────────┬────────────────────────────────────────┘
                 │ Private inputs
                 ▼
┌─────────────────────────────────────────────────────────┐
│         RISC Zero Guest Program (Rust)                  │
│  - Verify Merkle proofs                                 │
│  - Check index continuity                               │
│  - Verify range                                         │
│  - Generate ZK proof                                    │
└────────────────┬────────────────────────────────────────┘
                 │ ZK Proof (~few KB)
                 ▼
┌─────────────────────────────────────────────────────────┐
│            L1 RAT Contract (Upgraded)                   │
│  - Verify ZK proof via RISC Zero verifier               │
│  - Execute penalty/reward                               │
│                                                          │
│  Gas Cost: ~200-300k per verification (40-50% savings)  │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 1: Basic RAT Client Implementation

### 1.1 Goals
- ✅ Complete basic RAT Client functionality
- ✅ Test with local devnet (Anvil + op-node)
- ✅ E2E integration test
- ✅ Production-ready monitoring and submission

### 1.2 Components

#### A. RAT Contract (Solidity)
**Location**: `src/validator/RAT.sol`

**Current Status**: ✅ Implemented

**Key Functions**:
```solidity
function submitEvidence(
    uint256 gameIndex,
    uint8 evidenceType,
    bytes calldata evidenceData
) external;
```

**Evidence Type 3 Structure**:
```solidity
struct Type3Evidence {
    uint256 randomValue;
    uint256 leafAValue;
    uint256 leafAIndex;
    bytes32[] leafAProof;
    uint256 leafBValue;
    uint256 leafBIndex;
    bytes32[] leafBProof;
    bytes32 stateRoot;
}
```

**Verification Logic**:
1. Verify `leafA.proof` against `stateRoot`
2. Verify `leafB.proof` against `stateRoot`
3. Check `leafB.index == leafA.index + 1`
4. Check `leafA.value <= randomValue <= leafB.value`
5. Execute penalty if validator failed to respond

#### B. RAT Client (Go)
**Location**: `clients/rat-client/`

**Status**: 🔄 In Progress

**Architecture**:
```
clients/rat-client/
├── cmd/
│   └── rat-client/
│       └── main.go              # Entry point
├── pkg/
│   ├── l1monitor/
│   │   └── monitor.go           # L1 event monitoring
│   ├── l2sync/
│   │   ├── synchronizer.go      # L2 state synchronization
│   │   ├── tracker.go           # Validator state tracker
│   │   └── merkle.go            # Merkle tree construction
│   ├── finder/
│   │   └── adjacent.go          # Adjacent leaf finder
│   ├── prover/
│   │   └── merkle.go            # Merkle proof generation
│   ├── evidence/
│   │   ├── generator.go         # Evidence generation
│   │   └── types.go             # Evidence types
│   ├── submitter/
│   │   └── submitter.go         # L1 transaction submission
│   └── config/
│       └── config.go            # Configuration
├── go.mod
└── README.md
```

**Key Features**:
- **L1 Monitor**: Subscribe to `AttentionTestTriggered` events
- **L2 State Synchronizer**: Sync validator states from L2 (via op-node or indexer)
- **Validator State Tracker**: Maintain sorted list of validators and Merkle tree
- **Adjacent Leaf Finder**: Binary search for leaves closest to random value
- **Merkle Proof Generator**: Generate proofs for adjacent leaves
- **Evidence Generator**: Build Type 3 evidence structure
- **Submitter**: Submit evidence to RAT contract on L1
- **RPC Failover**: Primary L2 sync with indexer API fallback

**Configuration**:
```yaml
l1:
  rpc_url: "http://localhost:8545"
  rat_contract: "0xBa3e08b4753E68952031102518379ED2fDADcA30"

l2:
  sync_mode: "op-node"                  # "op-node" or "indexer"
  op_node_rpc: "http://localhost:9545" # Local op-node (primary)
  indexer_api: ""                       # Indexer API (fallback)
  l2_rpc: "http://localhost:9546"       # L2 geth RPC for state queries
  staking_contract: "0x..."             # TON Staking contract on L2

validator:
  private_key: "0x..."

monitoring:
  poll_interval: "10s"
  confirmation_blocks: 3
  sync_start_block: 0                   # Start syncing from this L2 block
```

**L2 State Synchronization Options**:

**Option 1: Direct op-node Sync (Recommended for Phase 1)**
```go
// RAT Client maintains its own validator state
type L2Synchronizer struct {
    l2RPC      *ethclient.Client
    tracker    *ValidatorStateTracker
}

// Subscribe to TON Staking contract events
func (s *L2Synchronizer) Start() {
    // Watch ValidatorStaked, ValidatorUnstaked events
    logs := make(chan types.Log)
    sub := s.l2RPC.SubscribeFilterLogs(ctx, query, logs)

    for {
        select {
        case log := <-logs:
            s.tracker.ProcessEvent(log)
            s.tracker.RebuildMerkleTree()
        }
    }
}
```

**Option 2: Indexer API (Future Enhancement)**
```go
// Query pre-built indexer service
type IndexerClient struct {
    apiURL string
}

func (c *IndexerClient) GetAdjacentLeaves(
    randomValue *big.Int,
    blockNumber uint64,
) (*AdjacentLeaves, error) {
    resp := c.get(fmt.Sprintf(
        "/api/v1/validators/adjacent?value=%s&block=%d",
        randomValue, blockNumber,
    ))

    // Still verify Merkle proofs locally!
    if !VerifyMerkleProof(resp.LeafA, resp.StateRoot) {
        return nil, errors.New("invalid proof from indexer")
    }

    return resp, nil
}
```

**Hybrid Approach** (Best of both worlds):
```go
func (c *RATClient) GetAdjacentLeaves(randomValue *big.Int) (*Evidence, error) {
    // Try local sync first
    if c.config.L2.SyncMode == "op-node" && c.synchronizer.IsSynced() {
        return c.synchronizer.FindAdjacentLeaves(randomValue)
    }

    // Fallback to indexer
    if c.config.L2.IndexerAPI != "" {
        evidence, err := c.indexer.GetAdjacentLeaves(randomValue, blockNumber)
        if err == nil && c.verifyEvidence(evidence) {
            return evidence, nil
        }
    }

    return nil, errors.New("no valid source for L2 state")
}
```

#### C. Testing Environment
**Location**: `docs/simple-rat-test-plan.md`

**Status**: ✅ Documented

**Setup**:
```bash
# Terminal 1: L1 (Anvil)
anvil --init .devnet/genesis-l1-staking-v3.json --port 8545

# Terminal 2: op-node (follower mode)
op-node \
  --l1=http://localhost:8545 \
  --rollup.config=.devnet/rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545

# Terminal 3: RAT Client
./bin/rat-client \
  --config=configs/devnet.yaml
```

### 1.3 Development Tasks

#### Task 1.3.1: Complete RAT Client Core
- [ ] Implement L1 event monitoring (`pkg/l1monitor/`)
- [ ] Implement L2 state synchronizer (`pkg/l2sync/synchronizer.go`)
  - Subscribe to TON Staking contract events on L2
  - Track validator state changes (stake, unstake)
- [ ] Implement validator state tracker (`pkg/l2sync/tracker.go`)
  - Maintain sorted list of validators
  - Build and update Merkle tree on state changes
- [ ] Implement adjacent leaf finder (`pkg/finder/adjacent.go`)
  - Binary search for leaves closest to random value
  - Return leafA, leafB with indices
- [ ] Implement Merkle proof generator (`pkg/prover/merkle.go`)
  - Generate proofs for specific leaves
  - Validate proofs locally
- [ ] Implement evidence generator (`pkg/evidence/generator.go`)
  - Build Type 3 evidence structure
  - Encode for contract submission
- [ ] Implement L1 submitter (`pkg/submitter/submitter.go`)
  - Submit evidence transactions to L1
  - Handle gas management and retries
- [ ] Add hybrid sync mode (op-node + indexer fallback)
- [ ] Add logging and metrics

**Estimated Time**: 4-5 days (increased due to L2 sync complexity)

#### Task 1.3.2: Generate rollup.json
**Script**: `scripts/generate-rollup-config.sh`

```bash
#!/bin/bash
# Generate rollup.json from genesis and addresses

DEVNET_DIR=".devnet"
GENESIS_FILE="$DEVNET_DIR/genesis-l1-staking-v3.json"
ADDRESSES_FILE="$DEVNET_DIR/addresses.json"
OPT_ADDRESSES_FILE="$DEVNET_DIR/optimism-addresses.json"
OUTPUT_FILE="$DEVNET_DIR/rollup.json"

# Extract genesis hash
L1_GENESIS_HASH=$(cast block 0 --rpc-url http://localhost:8545 -j | jq -r '.hash')

# Read contract addresses
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$OPT_ADDRESSES_FILE")
BATCH_INBOX="0xff00000000000000000000000000000000000998"

# Generate rollup.json
cat > "$OUTPUT_FILE" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "$L1_GENESIS_HASH",
      "number": 0
    },
    "l2": {
      "hash": "0x...",
      "number": 0
    },
    "l2_time": 0,
    "system_config": {
      "batcherAddr": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "overhead": "0x0",
      "scalar": "0x0",
      "gasLimit": 30000000
    }
  },
  "block_time": 2,
  "max_sequencer_drift": 600,
  "seq_window_size": 3600,
  "channel_timeout": 300,
  "l1_chain_id": 900,
  "l2_chain_id": 2151908,
  "batch_inbox_address": "$BATCH_INBOX",
  "deposit_contract_address": "0x...",
  "l1_system_config_address": "$SYSTEM_CONFIG"
}
EOF
```

**Estimated Time**: 2-3 hours

#### Task 1.3.3: E2E Testing
**Test Scenario**:
1. Start L1 (Anvil) with genesis
2. Start op-node in follower mode
3. Submit mock batch data to L1
4. Trigger AttentionTest via RAT contract
5. RAT Client detects event
6. RAT Client queries L2 state
7. RAT Client generates evidence
8. RAT Client submits evidence to L1
9. Verify penalty executed

**Script**: `scripts/e2e-rat-test.sh`

**Estimated Time**: 1-2 days

#### Task 1.3.4: Documentation
- [ ] RAT Client usage guide
- [ ] Configuration reference
- [ ] Deployment guide
- [ ] Troubleshooting guide

**Estimated Time**: 1 day

### 1.4 Phase 1 Completion Criteria
- ✅ RAT Client successfully monitors L1 events
- ✅ RAT Client synchronizes L2 validator state
- ✅ RAT Client maintains sorted validator list and Merkle tree
- ✅ RAT Client finds adjacent leaves for random values
- ✅ RAT Client generates valid Merkle proofs
- ✅ RAT Client submits evidence to L1
- ✅ E2E test passes consistently
- ✅ Documentation complete

**Total Estimated Time**: 7-10 days

---

## Phase 2: ZK Proof Integration (RISC Zero)

### 2.1 Goals
- 🎯 Reduce gas costs by 40-50%
- 🎯 Maintain security guarantees
- 🎯 Minimize changes to existing architecture
- 🎯 Enable trustless verification

### 2.2 Why RISC Zero?

**Advantages**:
1. **General-purpose zkVM**: Write verification logic in Rust (familiar to blockchain developers)
2. **No circuit expertise required**: No need to learn Circom/Cairo
3. **Code reuse**: Can adapt existing Merkle proof logic
4. **Proven security**: Used by production systems

**Trade-offs**:
- Proof size: ~100-300 KB (larger than Groth16's ~256 bytes)
- Verification cost: ~200-300k gas (vs Groth16's ~150k)
- Proving time: 10-30 seconds (acceptable for RAT use case)

### 2.3 Architecture Changes

#### A. New Components

**RISC Zero Guest Program** (Rust)
**Location**: `clients/rat-zkprover/guest/`

```rust
// guest/src/main.rs
use risc0_zkvm::guest::env;

fn main() {
    // Read private inputs
    let leaf_a: Leaf = env::read();
    let leaf_b: Leaf = env::read();
    let merkle_proof_a: Vec<[u8; 32]> = env::read();
    let merkle_proof_b: Vec<[u8; 32]> = env::read();

    // Read public inputs
    let state_root: [u8; 32] = env::read();
    let random_value: u64 = env::read();

    // Verification logic
    assert!(verify_merkle_proof(&leaf_a, &merkle_proof_a, &state_root));
    assert!(verify_merkle_proof(&leaf_b, &merkle_proof_b, &state_root));
    assert_eq!(leaf_b.index, leaf_a.index + 1);
    assert!(leaf_a.value <= random_value && random_value <= leaf_b.value);

    // Commit public outputs
    env::commit(&state_root);
    env::commit(&random_value);
}

fn verify_merkle_proof(leaf: &Leaf, proof: &[[u8; 32]], root: &[u8; 32]) -> bool {
    let mut hash = keccak256(&leaf.encode());
    for sibling in proof {
        hash = if leaf.index & 1 == 0 {
            keccak256(&[hash, *sibling].concat())
        } else {
            keccak256(&[*sibling, hash].concat())
        };
    }
    hash == *root
}
```

**RISC Zero Host Integration** (Go)
**Location**: `clients/rat-client/pkg/zkprover/`

```go
package zkprover

import (
    "github.com/risc0/risc0-go/groth16"
)

type ZKProver struct {
    guestBinary []byte
}

func (p *ZKProver) GenerateProof(
    leafA, leafB Leaf,
    proofsA, proofsB [][]byte,
    stateRoot [32]byte,
    randomValue uint64,
) ([]byte, error) {
    // Prepare inputs
    inputs := encodeInputs(leafA, leafB, proofsA, proofsB, stateRoot, randomValue)

    // Generate proof using RISC Zero
    receipt, err := groth16.Prove(p.guestBinary, inputs)
    if err != nil {
        return nil, err
    }

    return receipt.Seal, nil
}
```

**Verifier Contract** (Solidity)
**Location**: `src/validator/RATZKVerifier.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IRiscZeroVerifier } from "risc0/IRiscZeroVerifier.sol";

contract RATZKVerifier {
    IRiscZeroVerifier public immutable verifier;
    bytes32 public immutable imageId; // Guest program hash

    constructor(address _verifier, bytes32 _imageId) {
        verifier = IRiscZeroVerifier(_verifier);
        imageId = _imageId;
    }

    function verifyEvidence(
        bytes calldata seal,
        bytes32 stateRoot,
        uint256 randomValue
    ) external view returns (bool) {
        bytes memory journal = abi.encode(stateRoot, randomValue);
        verifier.verify(seal, imageId, sha256(journal));
        return true;
    }
}
```

#### B. RAT Contract Upgrade

**Location**: `src/validator/RAT.sol`

```solidity
// Add ZK verifier support
IRATZKVerifier public zkVerifier;

function submitEvidenceZK(
    uint256 gameIndex,
    bytes calldata zkProof,
    bytes32 stateRoot,
    uint256 randomValue
) external {
    // Verify ZK proof
    require(
        zkVerifier.verifyEvidence(zkProof, stateRoot, randomValue),
        "Invalid ZK proof"
    );

    // Execute penalty/reward
    _executeSlashing(gameIndex);
}
```

### 2.4 Development Tasks

#### Task 2.4.1: RISC Zero Guest Program
- [ ] Set up RISC Zero development environment
- [ ] Implement Merkle proof verification in Rust
- [ ] Implement verification logic
- [ ] Unit tests
- [ ] Build and test guest program

**Estimated Time**: 3-4 days

#### Task 2.4.2: Host Integration
- [ ] Add RISC Zero Go bindings
- [ ] Implement ZKProver wrapper
- [ ] Integrate with existing RAT Client
- [ ] Add proof generation to evidence flow
- [ ] Test proof generation locally

**Estimated Time**: 2-3 days

#### Task 2.4.3: Verifier Contract
- [ ] Deploy RISC Zero verifier on L1
- [ ] Implement RATZKVerifier
- [ ] Upgrade RAT contract with ZK support
- [ ] Test verification on-chain
- [ ] Gas benchmarking

**Estimated Time**: 2-3 days

#### Task 2.4.4: Migration Strategy
- [ ] Deploy new contracts (keep old ones)
- [ ] Run both systems in parallel
- [ ] Monitor gas savings
- [ ] Gradual migration
- [ ] Deprecate old system

**Estimated Time**: 1-2 days

#### Task 2.4.5: Documentation
- [ ] ZK proof architecture guide
- [ ] Guest program documentation
- [ ] Deployment guide
- [ ] Gas comparison analysis

**Estimated Time**: 1-2 days

### 2.5 Phase 2 Completion Criteria
- ✅ Guest program generates valid proofs
- ✅ On-chain verifier validates proofs
- ✅ Gas cost reduced by 40-50%
- ✅ E2E test with ZK proofs passes
- ✅ Production deployment successful

**Total Estimated Time**: 10-14 days

---

## Overall Timeline

```
Week 1-2: Phase 1 - Basic Implementation
├── Day 1-5: Complete RAT Client core (with L2 sync)
├── Day 6-7: Testing environment setup (rollup.json, op-node)
├── Day 8-9: E2E testing
└── Day 10: Documentation

Week 3-4: Phase 2 - ZK Integration
├── Day 11-14: RISC Zero guest program development
├── Day 15-17: Host integration (Go bindings)
├── Day 18-20: Verifier contracts deployment
├── Day 21-22: Migration and testing
└── Day 23-24: Documentation
```

**Total Estimated Time**: 4-5 weeks

---

## Success Metrics

### Phase 1
- **Functionality**: 100% event detection rate
- **Reliability**: < 1% false positive/negative
- **Performance**: < 30s evidence generation time
- **Gas Cost**: ~400-600k per verification

### Phase 2
- **Gas Savings**: 40-50% reduction
- **Proof Size**: < 500 KB
- **Proving Time**: < 60s
- **Security**: No degradation from Phase 1

---

## Risk Mitigation

### Phase 1 Risks
1. **op-node synchronization issues**
   - Mitigation: Fallback to external L2 RPC

2. **Merkle proof generation errors**
   - Mitigation: Extensive unit tests, reference implementations

3. **L1 transaction failures**
   - Mitigation: Retry logic, gas price management

### Phase 2 Risks
1. **RISC Zero proving time too long**
   - Mitigation: Optimize guest program, use faster hardware

2. **Proof verification failures**
   - Mitigation: Extensive testing, gradual rollout

3. **Gas costs not reduced enough**
   - Mitigation: Evaluate alternative ZK systems (Groth16, Plonky2)

---

## Next Steps

1. **Continue Phase 1 development**: Complete RAT Client implementation
2. **Set up testing environment**: Generate `rollup.json`, start op-node
3. **E2E testing**: Validate entire flow
4. **Plan Phase 2**: Research RISC Zero, prototype guest program

---

## References

- [RISC Zero Documentation](https://dev.risczero.com/)
- [RISC Zero Ethereum Integration](https://github.com/risc0/risc0-ethereum)
- [Optimism Rollup Node](https://github.com/ethereum-optimism/optimism/tree/develop/op-node)
- [Simple RAT Test Plan](./simple-rat-test-plan.md)
