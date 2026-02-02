# Deployment and Operations

## 6.1 Required Infrastructure

### Overall Architecture

**Validators must operate Follower Mode L2 nodes**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Validator Infrastructure                 │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  L1 RPC (Ethereum)                                 │   │
│  │  - Monitor RAT contract events                     │   │
│  │  - Send evidence submission transactions           │   │
│  │  - Query batch data (BatchInbox)                   │   │
│  └────────────────────────────────────────────────────┘   │
│                          ▲                                  │
│                          │ L1 Data                          │
│                          ▼                                  │
│  ┌────────────────────────────────────────────────────┐   │
│  │  op-node (Follower Mode) ⭐ Recommended            │   │
│  │  - Read L1 batch data                              │   │
│  │  - Reconstruct L2 blocks (trustless derivation)    │   │
│  │  - Generate execution payload                      │   │
│  │  - Provide OutputRootProof                         │   │
│  └────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          │ Engine API (JWT auth)            │
│                          ▼                                  │
│  ┌────────────────────────────────────────────────────┐   │
│  │  op-geth (Archive + Debug) ⭐ Required             │   │
│  │  - Receive blocks from op-node via Engine API      │   │
│  │  - Archive mode (--gcmode=archive)                 │   │
│  │  - Debug API (debug_accountRange, eth_getProof)   │   │
│  │  - Store L2 state (Patricia Trie)                 │   │
│  └────────────────────────────────────────────────────┘   │
│             ▲                          ▲                    │
│             │                          │                    │
│    Engine API (8551)          Debug RPC (8545)             │
│             │                          │                    │
│  ┌────────────────────────────────────────────────────┐   │
│  │  RAT Client Type 3                                 │   │
│  │  - Detect L1 events                                │   │
│  │  - Find adjacent leaves with debug_accountRange    │   │
│  │  - Generate Merkle proofs with eth_getProof        │   │
│  │  - Verify OutputRootProof (op-node or L2 RPC)     │   │
│  │  - Generate and submit evidence                    │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Key Points**:
1. **Validator = Follower Mode Challenger node operator**
2. **op-node**: Reconstruct L2 from L1 batch data (100% trustless)
3. **op-geth**: Execute blocks sent by op-node and store state
4. **RAT Client**: Use op-geth's debug API

### Core Principles

**✅ Validator = Follower Mode L2 Node Operation**:
- Validators must operate **Challenger's Follower Mode**
- Read L1 batch data to **trustlessly reconstruct** L2
- op-node + op-geth connected via Engine API
- **This is the core of "full node operation proof"!**

**✅ op-node (Follower Mode) - Required**:
- Read batch data from L1 (100% trustless)
- Reconstruct L2 blocks (Derivation Pipeline)
- Send blocks to op-geth via Engine API
- Provide OutputRootProof to RAT Client

**✅ op-geth (Archive + Debug) - Required**:
- Receive blocks from op-node via Engine API
- Preserve all historical state in Archive mode (`--gcmode=archive`)
- Enable Debug API (`debug_accountRange`, `eth_getProof`)
- RAT Client finds adjacent leaves via debug RPC

**❌ Cannot Use Public L2 RPC**:
- No debug API → Cannot find adjacent leaves
- No trustless derivation
- Cannot use external providers like Infura, Alchemy
- **Validators must operate their own L2 node**

## 6.2 Why is Archive Mode Required?

**RAT Challenge Characteristics:**
```
Time T: DisputeGame created (L2 block #12345)
        - State root = 0xabc...
        - RAT triggered

Time T+1h: Validator must submit evidence
           - Must prove possession of state at block #12345
           - ❌ Full node may have pruned block #12345's state!
           - ✅ Archive node always has it
```

**Full Node Problem**:
- Default `--gcmode=full`: Only keeps recent 128 blocks
- L2 block generation: Every ~2 seconds
- evidenceSubmissionPeriod: 1 hour
- **128 blocks = ~4 minutes** → State from 1 hour ago already deleted!

**Archive Node (Required)**:
- Preserve all historical state
- Disk: ~10+ TB
- **Can access state at any past block**

**Patricia Merkle Trie Characteristics:**
```
Account A balance change (block N → N+1):
  1. Recalculate account A's leaf hash
  2. Recalculate parent branch node hash
  3. ... Recalculate all paths to Root
  4. State Root: Completely changed!

Result:
  - Even if account B unchanged
  - State Root changed → All proofs must be regenerated
  - Proof based on Root_N will fail verification
  → Must possess state of challenged block!
```

## 6.3 Why is Debug API Required?

**Security Mechanism**:

| API | Role | Public RPC Support | Full Node Proof |
|-----|------|-----------------|---------------|
| `debug_accountRange` | Traverse entire state trie | ❌ Mostly disabled | ✅ Required |
| `eth_getProof` | Generate Merkle proof | ✅ Mostly supported | ⚠️ Insufficient alone |

**Attempting Public RPC Use**:
```
Validator → Public RPC (Infura, Alchemy)
         → Call debug_accountRange
         → ❌ Method not found (disabled)
         → Cannot generate evidence
         → Validator disqualified (slashing)
```

**Self-hosted op-geth**:
```
Validator → Self-hosted op-geth (archive + debug API)
         → Call debug_accountRange
         → ✅ Success (access entire state trie)
         → Find adjacent leaves
         → Generate StateLeafEvidence
         → Submit evidence
         → ✅ Prove full node operation
```

**Liveness vs Correctness**:
```
RAT Client = Liveness Verification
  - Possess full archive node directly?
  - Monitor L2 in real-time?
  - Debug API accessible? (Public RPC not possible)

DisputeGame = Correctness Verification
  - Is state correct?
  - Does it match L1 data?
```

**Trustless Level**:
- Debug API itself: Trust self-hosted node (operator manages directly)
- Merkle proofs: Cryptographically verifiable (100% trustless)
- OutputRootProof: L2 RPC (trust) or OpNode (L1-based, 100% trustless)

**Conclusion**: Debug API is **Liveness Proof** (full node operation), DisputeGame is **Correctness Proof** (state accuracy)

## 6.4 Component Details

### 1. L1 RPC Access

**Purpose**:
- Monitor RAT contract events
- Query DisputeGameFactory
- Send evidence submission transactions

**Options**:
- Self-hosted Ethereum node (Geth, Erigon, etc.)
- Or providers like Infura, Alchemy

**Requirements**:
- Stable connection
- Transaction sending capability

### 2. op-node (Follower Mode) ⭐ Recommended (Validator Best Practice)

**Role**: Reconstruct L2 blocks from L1 batch data (100% trustless)

**Important**: Validators must operate Follower Mode op-node

```bash
op-node \
  --l1=https://ethereum-rpc.example.com \
  --l2=http://localhost:8551 \              # Engine API (op-geth)
  --l2.jwt-secret=/data/jwt.hex \            # JWT authentication
  --rollup.config=/data/rollup.json \        # L2 configuration
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \                          # Rollup RPC (used by RAT Client)
  --l1.trustrpc=false                        # Trustless mode
```

**Trustless Derivation Process**:
```
1. Read batch data from L1 (BatchInbox contract)
2. Decode batch (SingularBatch, SpanBatch)
3. Extract L2 transactions
4. Generate execution payload
5. Send to op-geth via Engine API (JWT auth)
6. op-geth executes block and stores state
```

**Requirements**:
- CPU: 2-4 cores
- RAM: 4-8 GB
- Storage: ~100 GB SSD
- L1 RPC access
- rollup.json (L2 network configuration)

**Important**:
- **Validators must operate Follower Mode op-node**
- Trustlessly reconstruct L2 from L1 batch data
- Connect to op-geth via Engine API to send blocks

### 3. op-geth (Archive + Debug) ⭐ Required

**Role**: Execute blocks sent by op-node, store state, and provide debug API

```bash
op-geth \
  --datadir=/data/op-geth \
  --http \
  --http.api=eth,net,web3,debug \     # ⭐ debug API required!
  --http.addr=0.0.0.0 \
  --http.port=8545 \                   # Used by RAT Client
  --http.corsdomain="*" \
  --ws \
  --ws.api=eth,net,web3,debug \       # ⭐ debug API required!
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --authrpc.addr=localhost \           # ⭐ Engine API (op-node connection)
  --authrpc.port=8551 \                # ⭐ Engine API port
  --authrpc.jwtsecret=/data/jwt.hex \  # ⭐ JWT authentication
  --syncmode=full \
  --gcmode=archive                     # ⭐ Archive mode required!
```

**Archive Mode (--gcmode=archive)**:
- Preserve all historical state
- Disable pruning
- Disk: ~10+ TB
- **Can access state at any past block**

**debug API (--http.api=debug)**:
- `debug_accountRange`: Traverse entire state trie
- `eth_getProof`: Generate Merkle proof
- **Only available on self-hosted nodes**
- Public RPC mostly disables this

**Requirements**:
- CPU: 4-8 cores
- RAM: 16-32 GB
- Storage: ~10+ TB NVMe SSD (Archive mode)
- JWT secret (shared with op-node)

**Important**:
- **Must connect to op-node via Engine API** (JWT auth)
- Execute only blocks sent by op-node (trustless derivation)
- No P2P sync needed (Follower Mode)

**⚠️ Full Node Problem**:
```
--gcmode=full (default):
  - Only keeps recent 128 blocks
  - L2 block: Every ~2 seconds
  - 128 blocks = ~4 minutes
  - evidenceSubmissionPeriod = 1 hour
  → State from 4 minutes ago already deleted!
  → Cannot submit RAT evidence!
  → Validator disqualified (Slashing)!
```

**Conclusion**: Archive mode required!

### 4. RAT Client

**Role**: Generate evidence using op-geth's debug API

**APIs Used**:
1. **op-geth debug RPC** (required):
   - `debug_accountRange`: Find adjacent leaves
   - `eth_getProof`: Generate Merkle proofs

2. **OutputRootProof Generation**:
   - Method 1: L2 RPC (query MessagePasser storage root with `eth_getProof`)
   - Method 2: op-node Rollup RPC (`optimism_outputAtBlock`)

**Requirements**:
- CPU: 1-2 cores
- RAM: 2-4 GB
- Storage: ~10 GB

## 6.5 System Specifications

**Validator Required Configuration (Follower Mode L2 Node)**:

| Component | CPU | RAM | Storage | Role |
|----------|-----|-----|---------|------|
| L1 RPC | - | - | - | Self-hosted or Provider |
| op-node | 2-4 cores | 4-8 GB | ~100 GB SSD | Reconstruct L2 from L1 (Follower Mode) |
| op-geth | 4-8 cores | 16-32 GB | ~10+ TB NVMe | Archive + Debug API |
| RAT Client | 1-2 cores | 2-4 GB | ~10 GB | Generate Adjacent Leaves evidence |
| **Total** | **7-14 cores** | **22-44 GB** | **~10+ TB** | |

**Core Principles**:
- Validators must operate Follower Mode L2 node
- Connect op-node + op-geth via Engine API (JWT auth)
- Trustlessly reconstruct L2 from L1 batch data
- Cannot use Public L2 RPC

## 6.6 Deployment Steps

### Step 1: Generate JWT Secret (Required)

```bash
openssl rand -hex 32 > /data/jwt.hex
```

**Important**: op-node and op-geth must share the same JWT secret for Engine API authentication

### Step 2: Prepare Rollup Config (Required)

```bash
# Download or generate rollup.json
# Different for each L2 chain (genesis, block time, contracts, etc.)
curl -o /data/rollup.json https://example.com/optimism-rollup.json

# Or create manually
cat > /data/rollup.json <<EOF
{
  "genesis": {
    "l1": {...},
    "l2": {...}
  },
  "block_time": 2,
  ...
}
EOF
```

### Step 3: Start op-geth (Required)

```bash
op-geth \
  --datadir=/data/op-geth \
  --http \
  --http.api=eth,net,web3,debug \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --ws \
  --ws.api=eth,net,web3,debug \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --authrpc.addr=localhost \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/data/jwt.hex \
  --syncmode=full \
  --gcmode=archive
```

**Wait for sync**: Days to weeks (depending on chain size)

### Step 4: Start op-node (Required)

```bash
op-node \
  --l1=https://ethereum-rpc.example.com \
  --l2=http://localhost:8551 \
  --l2.jwt-secret=/data/jwt.hex \
  --rollup.config=/data/rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --l1.trustrpc=false
```

**Check sync status**:
```bash
curl http://localhost:9545 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'
```

### Step 5: Test debug API (Required)

```bash
# Test debug_accountRange
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"debug_accountRange",
    "params":["latest", "0x0000000000000000000000000000000000000000", 10, false, false, false],
    "id":1
  }'

# Test eth_getProof
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_getProof",
    "params":["0x0000000000000000000000000000000000000000", [], "latest"],
    "id":1
  }'
```

**Both must return successful responses for RAT Client to run!**

### Step 6: Configure RAT Client

```yaml
# config.yaml
# RAT Client configuration (based on service_adjacent.go)

# L1 Configuration
l1:
  rpc_url: "https://ethereum-rpc.example.com"
  beacon_url: "http://localhost:5052"  # For EIP-4844 blobs

# L2 RPC (Self-hosted op-geth with debug API) ⭐ Required
l2:
  rpc_url: "http://localhost:8545"  # debug_accountRange + eth_getProof

# op-node RPC - OutputRootProof verification
opnode:
  rpc_url: "http://localhost:9545"  # op-node Rollup RPC

# Contract addresses
contracts:
  rat_contract: "0x..."
  dispute_game_factory: "0x..."
  l1_bridge_registry: "0x..."
  batch_inbox: "0xff03000000000000000000000000000000000000"

# Validator identity
validator:
  private_key: "${VALIDATOR_PRIVATE_KEY}"  # Environment variable recommended
  address: "0x..."  # Derived from private key

# RAT Client Settings
rat:
  poll_interval: 12s          # L1 event polling interval
  deadline_buffer: 10m        # Evidence submission deadline buffer
  max_gas_price: 100          # gwei
  gas_limit: 500000
  confirmations: 64           # Production: 64, Devnet: 1-6

# Verification Settings
verification:
  enable_proof_verification: true
  rpc_timeout: 20m

# Logging
logging:
  level: info  # debug | info | warn | error
  format: json # json | text

# Metrics
metrics:
  enabled: true
  addr: "0.0.0.0"
  port: 7300
```

### Step 7: Start RAT Client

```bash
cd clients/rat-client-type3
go build -o bin/rat-client ./cmd
./bin/rat-client --config config.yaml
```

**Check logs**:
```
RAT Client running in Adjacent Leaves mode (State Root as Target)
Using RPC mode (debug_accountRange + eth_getProof)
Validator: 0x...
RAT Contract: 0x...
Press Ctrl+C to stop...
```

## References

### Code
- `clients/rat-client-type3/cmd/main.go` - Entry point
- `clients/rat-client-type3/pkg/client/service_adjacent.go` ⭐ Production use
- `clients/rat-client-type3/pkg/l2sync/state_rpc.go` ⭐ Debug RPC implementation
- `clients/rat-client-type3/test/state_leaf_rpc_e2e_test.go` ⭐ Recommended
- `src/validator/libraries/Type3EvidenceVerifier.sol`
- `test/v3/rat-client/RATClient.t.sol`

### Documentation
- 12. Optimism Integration
- clients/rat-client-type3/docs/ARCHITECTURE_KR.md
- clients/README.md

### External References
- Geth v1.13+ PBSS (Path-Based State Storage)
- Optimism Derivation Specification
- Optimism op-node + op-geth Architecture
- Ethereum Patricia Trie Specification

---

**Last Updated**: 2026-01-30
