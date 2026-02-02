# TON Staking V3 - E2E Tests

End-to-end tests for TON Staking V3 system using Go tests with isolated Anvil nodes.

## Quick Start

```bash
# 1. Generate genesis file (once)
cd .. && make devnet-allocs-offline

# 2. Run E2E tests
cd op-e2e && make test
```

## What's Here

- **`faultproofs/rat_system_test.go`** - 3 system tests verifying startup, balances, and contract calls
- **`faultproofs/rat_challenge_test.go`** - 4 RAT scenario tests (646 lines)
- **`faultproofs/rat_state_root_test.go`** - RAT State Root E2E test with L2 geth integration (434 lines)
- **`faultproofs/rat_challenge_helpers.go`** - Reusable test helpers (313 lines, 11 functions)
- **`e2eutils/rat/system.go`** - `StartTONStakingSystem()` helper that starts isolated Anvil nodes with genesis state
- **`bindings/`** - Contract bindings (RAT, FaultDisputeGame, DelayedWETH, etc.)
- **`Makefile`** - Test commands

## Test Architecture

Each test runs in **parallel** with its own **isolated Anvil node**:

```
Test 1 (Port 57340) → Isolated Anvil with genesis
Test 2 (Port 57341) → Isolated Anvil with genesis
Test 3 (Port 57342) → Isolated Anvil with genesis
```

Tests use pre-deployed contracts from genesis file (`.devnet/genesis-l1-staking-v3.json`).

## Tests

**Total: 7 tests (3 system + 3 RAT scenario + 1 RAT Client E2E)**
**Duration: ~35 seconds (parallel)**

### System Tests (3)

1. **TestTONStakingSystemStartup** (~1s) - Verify all contracts deployed with code
2. **TestAccountBalances** (~1s) - Verify test account balances from genesis
3. **TestRATContractCall** (~1s) - Verify RAT contract is callable

### RAT Scenario Tests (3)

4. **TestSimpleRAT_ValidatorRegistration** (~4s) - Validator registration with TON deposit
5. **TestSimpleRAT_GameCreation** (~6s) - DisputeGame creation and RAT trigger
6. **TestSimpleRAT_ChallengerWins** (~20s) - Full challenger wins scenario with bond claiming
   - Includes 2-step credit claiming with DelayedWETH (7-day delay)
   - Dynamic withdrawal delay query from contract
   - Comprehensive bond restoration verification

### RAT Client E2E Test (1)

7. **TestRATClient_EvidenceSubmission_E2E** (~71s) - Complete RAT client evidence submission flow with L2 integration
   - Starts isolated L1 (Anvil) with genesis containing all deployed contracts
   - Starts isolated L2 (geth dev mode) with archive state
   - Creates transactions on L2 to generate state changes
   - Computes OutputRootProof (hash of version, stateRoot, messagePasserStorageRoot, blockHash)
   - Registers validator first (prerequisite for RAT)
   - Creates DisputeGame with OutputRootProof as rootClaim (triggers RAT automatically)
   - Launches RAT client as subprocess to monitor and submit evidence
   - Verifies StateLeafEvidence submission using Type 3 verifier (adjacent leaves proof)
   - Validates complete evidence verification on-chain (Gas: ~277k)
   - **Full integration test**: L1 + L2 + RAT client + OutputRootProof + StateLeafEvidence
   - **Type 3**: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME rollup architecture

## Running Tests

```bash
# All tests (7 tests, ~80s)
make test

# System tests only (3 tests)
GOWORK=off go test -v -run "TestTONStakingSystemStartup|TestAccountBalances|TestRATContractCall" ./faultproofs

# RAT scenario tests only (3 tests)
GOWORK=off go test -v -run TestSimpleRAT ./faultproofs

# RAT Client E2E test (requires L2 geth)
GOWORK=off go test -v -run TestRATClient_EvidenceSubmission_E2E ./faultproofs

# Specific test
GOWORK=off go test -v -run TestSimpleRAT_ChallengerWins ./faultproofs

# With detailed output
GOWORK=off go test -v ./faultproofs -timeout 300s
```

## Documentation

For detailed documentation, see:
- **[E2E Test Guide](../docs/test/e2e-tests.md)** - Complete guide with architecture details
- **[Test Overview](../docs/test/README.md)** - All test categories

## Prerequisites

- Go 1.22+
- Foundry (for Anvil)
- Geth (for L2 in TestRATClient_EvidenceSubmission_E2E)
- Genesis file generated: `make devnet-allocs-offline` (from project root)
- RAT client binary built: `cd clients/rat-client-type3 && go build`

## Troubleshooting

### Genesis file not found
```bash
cd .. && make devnet-allocs-offline
```

### Port conflicts
Tests use dynamic port allocation. If issues persist:
```bash
pkill anvil
pkill geth
```

### RAT client binary not found
Build the RAT client before running TestRATClient_EvidenceSubmission_E2E:
```bash
cd clients/rat-client-type3 && go build -o bin/rat-client-type3 cmd/main.go
```

## Test Details

### TestRATClient_EvidenceSubmission_E2E Architecture

This test validates the complete RAT client evidence submission flow for **Type 3 rollups**.

**What is Type 3?**
- **Type 3** = `OPTIMISM_BEDROCK_WITH_DISPUTE_GAME`
- Rollup architecture: Optimism Bedrock + DisputeGameFactory
- Uses DisputeGame system for fraud proofs (vs. legacy fault proof system)
- Supports OutputRootProof-based state verification
- RAT supports multiple rollup types (Type 3, Type 4, etc.) with different verifiers

**Components:**
- **L1 (Anvil)**: Pre-deployed contracts from genesis (RAT, DisputeGameFactory, SystemConfig)
- **L2 (geth)**: Dev mode with archive state and debug APIs enabled
- **RAT Client**: Go subprocess monitoring L1 events and submitting evidence
- **Contracts**: Type3EvidenceVerifier library for Type 3 rollup evidence verification

**Flow:**
1. Start isolated L1 with genesis (all contracts deployed)
2. Start isolated L2 geth with dynamic ports
3. Generate L2 state by sending transactions
4. Query L2 state: `eth_getBlockByNumber`, `debug_accountRange`, `eth_getProof`
5. Compute OutputRootProof components:
   - `version`: 32-byte zero (always 0x0)
   - `stateRoot`: L2 state root from block header
   - `messagePasserStorageRoot`: L2ToL1MessagePasser storage root
   - `latestBlockHash`: L2 block hash
6. Register validator with TON deposit (prerequisite for RAT)
7. Create DisputeGame with `rootClaim = hash(OutputRootProof)` (RAT auto-triggers)
8. Launch RAT client subprocess that:
   - Monitors `AttentionTestTriggered` events
   - Finds adjacent leaves in L2 state trie using `debug_accountRange`
   - Generates Merkle proofs using `eth_getProof`
   - Encodes StateLeafEvidence with OutputRootProof
   - Submits evidence to RAT contract
9. Verify evidence on-chain:
   - Validates OutputRootProof: `hash(outputRootProof) == rootClaim`
   - Validates adjacency: `leafA.key < stateRoot <= leafB.key` (**State Root as Target!**)
   - Validates Merkle proofs: Both leaves verify against stateRoot
   - All validations pass → Evidence accepted

**Evidence Format:**

Type 3 rollups currently implement:
- **Evidence Type 1**: StateLeafEvidence (state possession proof via adjacent leaves)

Note: Evidence Type 0 (FraudProof via batch derivation) is planned but not yet implemented.

This test uses **Evidence Type 1 (StateLeafEvidence)**:
```solidity
struct StateLeafEvidence {
    bytes32 leafAKey;          // keccak256(address)
    bytes leafAValue;          // RLP(account)
    bytes[] leafAProof;        // Merkle proof
    bytes32 leafBKey;          // Adjacent leaf key
    bytes leafBValue;          // RLP(account)
    bytes[] leafBProof;        // Merkle proof
    bytes32 stateRoot;         // L2 state root (deprecated, use OutputRootProof)
    uint256 blockNumber;       // L2 block number
    OutputRootProof outputRootProof;  // Proves stateRoot authenticity
}

struct OutputRootProof {
    bytes32 version;                      // Always 0x0
    bytes32 stateRoot;                    // L2 state root
    bytes32 messagePasserStorageRoot;     // L2ToL1MessagePasser storage root
    bytes32 latestBlockhash;              // L2 block hash
}
```

**Key Technical Details:**
- **State Root as Target**: The stateRoot itself is the target value being proven (not a random value)
  - Validator must prove they possess full L2 state by finding adjacent leaves where `leafA.key < stateRoot <= leafB.key`
  - This proves the validator knows the entire state trie structure
- **ABI Encoding**: Uses `abi.encode(struct)` format (includes 32-byte offset)
- **Merkle Proof**: Optimism's MerkleTrie.sol verifies Patricia trie proofs
- **Account Data**: Must use `eth_getProof` data (not `debug_accountRange`)
- **Adjacency**: Proven by providing two consecutive leaves in sorted key order that bracket the stateRoot
- **Gas Cost**: ~277k for full verification (includes 2 Merkle proofs + validation)

**Success Criteria:**
- ✅ L1 and L2 start successfully
- ✅ OutputRootProof computed correctly
- ✅ DisputeGame created with correct rootClaim
- ✅ Validator registered and RAT triggered
- ✅ RAT client detects event and generates evidence
- ✅ Evidence submitted on-chain (transaction receipt obtained)
- ✅ All on-chain validations pass:
  - OutputRootProof hash matches rootClaim
  - StateRoot falls within adjacent leaf range (State Root as Target)
  - Both Merkle proofs verify against stateRoot
- ✅ Gas usage reasonable (~277k)
