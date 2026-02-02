---
id: e2e-tests
title: Go E2E Tests
sidebar_position: 5
---

# Go E2E Tests (7 tests)

op-e2e integration tests covering full L1-L2 stack verification.

**Location**: `op-e2e/faultproofs/`

## System Tests (3 tests)

### Basic System Verification

| ID | Test Function | File | Description | Time |
|----|--------------|------|-------------|------|
| SYS-001 | TestTONStakingSystemStartup | rat_system_test.go | Contract deployment verification | ~1s |
| SYS-002 | TestAccountBalances | rat_system_test.go | Genesis balance verification | ~1s |
| SYS-003 | TestRATContractCall | rat_system_test.go | RAT contract call verification | ~1s |

**Coverage:**
- ✅ L1 contract deployment
- ✅ Genesis account balances
- ✅ RAT contract basic calls

---

## RAT Scenario Tests (3 tests)

### RAT Full Flow Verification

| ID | Test Function | File | Description | Time |
|----|--------------|------|-------------|------|
| RAT-E2E-001 | TestSimpleRAT_ValidatorRegistration | rat_challenge_test.go | Validator registration flow | ~4s |
| RAT-E2E-002 | TestSimpleRAT_GameCreation | rat_challenge_test.go | DisputeGame creation and RAT trigger | ~6s |
| RAT-E2E-003 | TestSimpleRAT_ChallengerWins | rat_challenge_test.go | Challenger wins full scenario | ~20s |

**Coverage:**
- ✅ Validator registration and collateral deposit
- ✅ DisputeGame creation
- ✅ RAT automatic trigger
- ✅ Slashing on evidence failure
- ✅ Challenger reward payment

---

## RAT Client E2E Test (1 test)

### Complete Integration Test

| ID | Test Function | File | Description | Time |
|----|--------------|------|-------------|------|
| RAT-CLIENT-E2E-001 | TestRATClient_EvidenceSubmission_E2E | rat_state_root_test.go | RAT Client full integration test | ~71s |

**Test Environment:**
- **L1**: Isolated Anvil with genesis (all contracts pre-deployed)
- **L2**: Isolated geth dev mode with archive state

**Test Steps:**

1. **L2 transaction creation and state change**
2. **OutputRootProof calculation**
   ```go
   type OutputRootProof struct {
       Version                  [32]byte
       StateRoot                [32]byte
       MessagePasserStorageRoot [32]byte
       BlockHash                [32]byte
   }
   ```
3. **Validator registration (prerequisite)**
4. **DisputeGame creation (automatic RAT trigger)**
5. **RAT Client subprocess execution**
6. **Adjacent Leaves evidence generation (using debug API)**
7. **StateLeafEvidence on-chain submission**
8. **Type 3 Evidence Verifier validation**
9. **Gas measurement** (~277k gas)

**Coverage:**
- ✅ L1 (Anvil) + L2 (geth) integration
- ✅ OutputRootProof calculation and verification
- ✅ DisputeGame creation and RAT trigger
- ✅ RAT Client subprocess execution
- ✅ Adjacent leaves actual evidence generation (debug API)
- ✅ StateLeafEvidence on-chain submission and verification
- ✅ Type 3 Evidence Verifier integration

---

## Execution

### Run All Tests

```bash
cd op-e2e
make test
```

### Run Specific Tests

```bash
# System tests only
GOWORK=off go test -v -run TestTONStakingSystemStartup ./faultproofs

# RAT scenario tests
GOWORK=off go test -v -run TestSimpleRAT ./faultproofs

# RAT Client E2E test
GOWORK=off go test -v -run TestRATClient_EvidenceSubmission_E2E ./faultproofs
```

### Execution Time

- **All 7 tests**: ~80 seconds
- **System tests (3)**: ~3 seconds
- **RAT scenarios (3)**: ~30 seconds
- **RAT Client E2E (1)**: ~71 seconds

---

## Next Steps

- [RAT Client Unit Tests](rat-client-unit-tests.md) - RAT Client Go unit tests
- [V3 Mode Tests](v3-mode-tests.md) - Solidity integration tests
- [Back to Overview](overview.md)
