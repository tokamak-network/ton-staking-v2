---
id: rat-client-unit-tests
title: RAT Client Unit Tests
sidebar_position: 6
---

# RAT Client Unit Tests (60 tests)

RAT Client Go package unit tests.

**Location**: `clients/rat-client-type3/pkg/`

## Test Package Structure

| Category | Tests | File | Key Tests |
|---------|-------|------|-----------|
| **Evidence** | 11 | evidence/state_leaf_test.go | Adjacent leaves generation, verification logic |
| **L2 Sync** | 32 | l2sync/syncer_test.go | L2 block sync, OutputRootProof queries |
| **Submitter** | 8 | submitter/adjacent_submitter_test.go | Evidence submission, ABI encoding |
| **Event Monitor** | 9 | client/event_monitor_test.go | L1 event subscription, filtering |

---

## Evidence Package (11 tests)

### Adjacent Leaves Search Algorithm
Binary search algorithm for detecting divergence in state trie.

### Divergence Witness Generation
Generate witness proving difference between two state roots.

### OutputRootProof Structure Verification
Validate OutputRootProof structure and calculation.

### Merkle Proof Generation
Generate and verify state trie Merkle proofs.

---

## L2 Sync Package (32 tests)

### L2 Block Header Queries
Query block headers from L2 geth.

### State Root Extraction
Extract state root from block headers.

### MessagePasser Storage Root Calculation
Calculate L2ToL1MessagePasser contract storage root.

### OutputRootProof Generation
Generate complete OutputRootProof structure.

### debug_accountRange API Calls
Query state trie using geth debug API.

### eth_getProof API Calls
Query Merkle proofs using standard JSON-RPC.

### Sync and Caching
Block synchronization and cache management.

### Error Handling
Network error and retry logic.

---

## Submitter Package (8 tests)

### StateLeafEvidence ABI Encoding
Solidity ABI-compatible encoding.

### submitEvidence Transaction Creation
L1 transaction creation and signing.

### Gas Estimation
Evidence submission gas cost estimation.

---

## Event Monitor Package (9 tests)

### AttentionTestTriggered Event Subscription
Real-time L1 RAT event subscription.

### Event Filtering
Filter by specific validator addresses.

### Block Range Queries
Query historical events.

### Reconnection Logic
WebSocket reconnection handling.

---

## Execution

### Run All Tests

```bash
cd clients/rat-client-type3
go test ./pkg/...
```

### Run by Package

```bash
# Evidence package
go test ./pkg/evidence/...

# L2 Sync package
go test ./pkg/l2sync/...

# Submitter package
go test ./pkg/submitter/...

# Event Monitor package
go test ./pkg/client/...
```

### Coverage

```bash
go test -cover ./pkg/...
```

---

## Next Steps

- [Go E2E Tests](e2e-tests.md) - op-e2e integration tests
- [V3 Mode Tests](v3-mode-tests.md) - Solidity tests
- [Back to Overview](overview.md)
