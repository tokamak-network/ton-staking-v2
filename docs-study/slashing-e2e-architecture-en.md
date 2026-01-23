# Slashing E2E Test Architecture

## Core: Testing in a Real Optimism Environment, Not Mocks

Slashing E2E tests validate the full slashing process using **real Optimism DisputeGameFactory and FaultDisputeGame** contracts.

---

## Test Environment Comparison

### Forge Tests (Solidity) - Unit Tests
**Location**: `test/Slashing/SlashingTest.t.sol`

```solidity
// Mock contracts
MockDisputeGameFactory mockDGF;
MockFaultDisputeGame2 mockGame;

// Simulated environment
mockGame.setStatus(GameStatus.CHALLENGER_WINS);
```

**Characteristics**:
- Fast execution
- Suitable for unit testing
- Validates slashing logic
- Cannot verify real Optimism integration
- Skips DisputeGame creation/resolution process

---

### E2E Tests (Go) - Integration Tests
**Location**: `op-e2e/slashing/slashing_test.go`

```go
// Real Optimism contracts
dgf := bindings.NewDisputeGameFactory(
    sys.Addresses.DisputeGameFactory,  // Actual address from Genesis
    sys.L1Client                        // Real Anvil L1 client
)

// Real transaction execution
createGameTx, err := dgf.Create(
    proposerAuth,
    gameType,      // 0 = FaultDisputeGame
    rootClaim,     // Invalid root claim
    extraData      // L2 block number
)
```

**Characteristics**:
- **Real Optimism environment**
- **Real DisputeGameFactory**
- **Real FaultDisputeGame creation**
- **Real RAT trigger mechanism**
- **Same flow as production**
- Slower execution (requires Anvil node startup)

---

## E2E Test Architecture

### 1. Genesis-Based Test Environment

```
┌─────────────────────────────────────────────────────────┐
│ Genesis File (.devnet/genesis-l1-staking-v3.json)      │
├─────────────────────────────────────────────────────────┤
│ Optimism L1 Contracts (104)                             │
│  ├─ DisputeGameFactory                                 │
│  ├─ FaultDisputeGame (implementation)                  │
│  ├─ DelayedWETH                                        │
│  └─ SystemConfig                                       │
│                                                         │
│ TON Staking Contracts (15)                              │
│  ├─ RAT (Rollup Attention Test)                        │
│  ├─ SeigManager (+ Slashing)                           │
│  ├─ DepositManager (+ Slashing)                        │
│  ├─ Layer2Manager (+ Slashing)                         │
│  └─ DAOCommittee                                       │
└─────────────────────────────────────────────────────────┘
                        ↓
            ┌───────────────────────┐
            │   Anvil L1 Node       │
            │  (isolated per test)  │
            └───────────────────────┘
                        ↓
            ┌───────────────────────┐
            │   E2E Test (Go)       │
            │  - Real transactions  │
            │  - Real contracts     │
            └───────────────────────┘
```

### 2. Actual Slashing Flow

```
Step 1: Operator registration
  └─ Layer2Manager.registerCandidateAddOn()
  └─ DepositManager.deposit(50,000 WTON)

Step 2: DisputeGame creation (real!)
  └─ DisputeGameFactory.create(wrongRootClaim)
  └─ FaultDisputeGame contract deployed
  └─ RAT.onDisputeGameCreated() called automatically

Step 3: RAT trigger (real!)
  └─ RAT selects Validator
  └─ Validator bond locked
  └─ AttentionTestTriggered event emitted

Step 4: Challenger attack (real!)
  └─ FaultDisputeGame.attack(correctClaim)
  └─ Game state updated

Step 5: Game resolution (real!)
  └─ Time passes (7 days)
  └─ FaultDisputeGame.resolveClaim()
  └─ Game status = CHALLENGER_WINS

Step 6: Slashing execution (real!)
  └─ Layer2Manager.slashingCandidate()
  └─ DepositManager.slash()
  └─ SeigManager.onSlash()
  └─ Operator stake burned
  └─ Challenger reward (10%)
```

---

## Evidence of Real Contract Usage

### Genesis addresses (actually deployed)
```json
{
  "chainId": 900,
  "disputeGameFactory": "0xb606Ad4a2Ba58ba7cE88fe50A2b7991EB0e1d4F3",
  "systemConfig": "0xe705b6429e79D1a2Ce8E84df065c27b9c4Eed3C4",
  "ratProxy": "0x49FcbCC4E425add3a45AFC82F4dD0E5c227A0Ff8",
  "seigManagerProxy": "0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe",
  "depositManagerProxy": "0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C",
  "layer2ManagerProxy": "0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44"
}
```

### Code evidence: `createDisputeGameWithWrongClaim()`
```go
// op-e2e/e2eutils/rat/helpers.go (or local helpers)

func createDisputeGameWithWrongClaim(...) {
    // Real DisputeGameFactory connection
    dgf, err := bindings.NewDisputeGameFactory(
        sys.Addresses.DisputeGameFactory,  // ← Real address!
        sys.L1Client                        // ← Real client!
    )
    
    // Real initBond fetch
    initBond, err := dgf.InitBonds(callOpts, gameType)
    
    // Real transaction submission
    createGameTx, err := dgf.Create(
        proposerAuth,
        gameType,
        rootClaim,
        extraData
    )
    
    // Real transaction wait
    receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
    
    // Real event parsing
    for _, log := range receipt.Logs {
        if log.Topics[0].Hex() == eventDisputeGameCreated {
            gameAddress = common.HexToAddress(log.Topics[1].Hex())
        }
    }
}
```

---

## Why E2E Tests Matter

### What Forge tests cannot verify:

1. **DisputeGameFactory integration**
   - E2E: Real game creation process
   - Forge: Simulated with mocks

2. **RAT automatic trigger**
   - E2E: DisputeGameFactory → RAT event chain
   - Forge: Manual RAT invocation

3. **FaultDisputeGame state management**
   - E2E: Real game logic (attack, resolve)
   - Forge: Mock state setup

4. **Cross-contract interaction**
   - E2E: RAT ↔ DisputeGame ↔ Layer2Manager ↔ DepositManager
   - Forge: Individual contract tests

5. **Event chain**
   - E2E: Real events emitted and parsed
   - Forge: Event simulation

---

## Test Strategy

### Layered testing approach

```
┌─────────────────────────────────────────┐
│ E2E Tests (Go)                          │
│ - Real Optimism environment             │
│ - Full slashing flow                    │
│ - Integration validation                │
└─────────────────────────────────────────┘
                 ↑ integration
┌─────────────────────────────────────────┐
│ Integration Tests (Solidity)            │
│ - Multi-contract interaction            │
│ - Scenario tests                        │
└─────────────────────────────────────────┘
                 ↑ integration
┌─────────────────────────────────────────┐
│ Unit Tests (Solidity)                   │
│ - Mocks                                 │
│ - Individual function tests             │
│ - Fast feedback                         │
└─────────────────────────────────────────┘
```

**Each level complements the others.**

---

## How to Run E2E Tests

### 1. Generate Genesis (once)
```bash
make devnet-allocs-offline
```

### 2. Run E2E tests
```bash
# Full run
make test-e2e

# Slashing tests only
cd op-e2e
GOWORK=off go test -v ./slashing/...
```

### 3. Test flow
```
1. StartTONStakingSystem()
   └─ Load Genesis
   └─ Start Anvil node (isolated port)
   └─ All contracts deployed

2. Execute real transactions
   └─ Operator registration
   └─ DisputeGame creation
   └─ Challenger attack
   └─ Slashing execution

3. Verify results
   └─ Operator stake = 0
   └─ Challenger reward = 10%
   └─ Burned = 90%

4. Node shutdown (automatic)
```

---

## Reliability Guarantees

### What E2E tests guarantee:

1. **Real Optimism compatibility**
   - DisputeGameFactory interface
   - FaultDisputeGame protocol
   - Event formats

2. **Full system integration**
   - RAT ↔ Optimism integration
   - End-to-end slashing flow
   - Cross-contract call chain

3. **Production readiness**
   - Same conditions as real environment
   - Real transaction gas costs
   - Real event handling

---

## References

### Related files
- **E2E tests**: `op-e2e/slashing/slashing_test.go`
- **Helper functions**: `op-e2e/slashing/slashing_helpers.go`
- **Shared helpers**: `op-e2e/e2eutils/rat/helpers.go`
- **Genesis script**: `script/DeployV3SlashForDevnet.s.sol`

### Existing E2E test example
- `op-e2e/faultproofs/rat_challenge_test.go:TestSimpleRAT_ChallengerWins`
  - Real DisputeGame creation and resolution
  - RAT trigger and bond handling
  - Full Challenger-wins flow

---

## Conclusion

**Slashing E2E tests validate the full slashing process in a real Optimism environment, not mocks.**

This enables:
- Optimism integration verification
- Production readiness confirmation
- Assurance of behavior in a real environment

**E2E tests = real-environment simulation = final quality assurance**
