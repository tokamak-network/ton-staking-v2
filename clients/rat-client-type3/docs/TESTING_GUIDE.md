# RAT Client Type 3 - Testing Guide

## Overview

This guide covers testing for the RAT Client Type 3 implementation.

## Test Types

### 1. Unit Tests

Unit tests verify individual components in isolation.

**Test Files**:
- `pkg/monitor/event_monitor_test.go` - Event monitoring
- `pkg/evidence/state_leaf_evidence_test.go` - Evidence structure
- `pkg/derivation/proof_verified_state_test.go` - Proof verification
- `pkg/l2sync/state_trie_test.go` - State trie iteration
- `pkg/l2sync/divergence_test.go` - Divergence witness
- `pkg/l2sync/synchronizer_state_test.go` - State synchronizer
- `pkg/submitter/adjacent_submitter_test.go` - Evidence submission

**Run Unit Tests**:
```bash
# From project root
make rat-client-test

# Or directly
cd clients/rat-client-type3
go test -v ./pkg/...
```

### 2. Full System E2E Tests

For complete end-to-end testing including RAT contract deployment, L1/L2 node setup, and evidence verification:

**See**: [E2E Tests Guide](../../../op-e2e/README.md)

The full system E2E tests (`op-e2e/faultproofs/`) verify:
- System initialization with genesis deployment
- RAT contract triggering and monitoring
- RAT client binary execution as subprocess
- Evidence submission and on-chain verification
- Complete validator workflow

## Test Coverage

```bash
cd clients/rat-client-type3
go test -cover ./pkg/...
```

## References

- [E2E Tests Guide](../../../op-e2e/README.md) - Full system integration tests
- [System Architecture](./ARCHITECTURE.md) - System design
- [RAT Client README](../README.md) - Setup and configuration
