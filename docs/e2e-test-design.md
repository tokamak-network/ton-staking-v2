# TON Staking V3 E2E Test Design Document

## Overview

This document describes the E2E (End-to-End) test design for TON Staking V3 RAT (Randomized Attention Test) integration with Optimism.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         E2E Test Environment                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐     ┌─────────────────┐     ┌───────────────┐  │
│  │   TON Staking   │     │    Optimism     │     │   op-e2e      │  │
│  │   V3 RAT        │◄───►│ DisputeGame     │◄───►│   Test Suite  │  │
│  │   Contract      │     │   Factory       │     │   (Go)        │  │
│  └─────────────────┘     └─────────────────┘     └───────────────┘  │
│           │                      │                      │           │
│           │                      │                      │           │
│           ▼                      ▼                      ▼           │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Local L1/L2 Devnet                        │   │
│  │                    (Kurtosis / devnet-allocs)                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Test File Structure

```
ton-staking-v2/
├── op-e2e/
│   ├── faultproofs/
│   │   └── rat_ton_staking_test.go    # RAT integration E2E tests
│   ├── e2eutils/
│   │   └── rat/
│   │       ├── helper.go              # RAT test helper
│   │       └── factory_helper.go      # RAT factory helper
│   └── bindings/
│       └── rat.go                     # Go bindings for TON Staking RAT
└── packages/contracts-bedrock/
    └── scripts/
        └── deploy/
            └── DeployTONStakingRAT.s.sol  # RAT deployment script
```

## System Configuration Options

### Account/Key Setup

```go
// Test accounts from sys.Cfg.Secrets
var (
    Alice   = sys.Cfg.Secrets.Alice   // Honest validator
    Bob     = sys.Cfg.Secrets.Bob     // Dishonest actor
    Mallory = sys.Cfg.Secrets.Mallory // Alternative actor
)

// Usage in tests
game.StartChallenger(ctx, "Challenger", op_e2e_challenger.WithPrivKey(sys.Cfg.Secrets.Alice))
```

### System Options

```go
// Available system configuration options
opts := []SystemConfigOption{
    WithBatcherStopped(),      // Start with batcher stopped
    WithSequencerWindowSize(n), // Set sequencer window size
    WithRATEnabled(),          // Enable RAT contract
    WithRATTriggerProbability(prob), // Set trigger probability
}

sys, l1Client := StartFaultDisputeSystemWithRAT(t, opts...)
```

## Test Scenarios

### 1. RAT Trigger Flow Test

**Test**: `TestRATTriggerOnGameCreation`

**Purpose**: Verify RAT attention test is triggered when DisputeGame is created.

**Flow**:
```
1. Deploy TON Staking V3 RAT contract
2. Deploy Optimism L2 with ratAddress set
3. Create FaultDisputeGame via DisputeGameFactory
4. Verify IRAT.triggerAttentionTest() is called
5. Verify AttentionTestTriggered event is emitted
6. Verify validator is selected and bond is locked
```

**Code Outline**:
```go
func TestRATTriggerOnGameCreation(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    // Start system with RAT enabled
    sys, l1Client := StartFaultDisputeSystemWithRAT(t)
    t.Cleanup(sys.Close)

    // Get RAT contract instance
    ratContract := GetRATContract(t, sys)

    // Record initial validator state
    validatorBefore := ratContract.GetValidatorRegistration(validator, systemConfig)

    // Create dispute game
    disputeGameFactory := NewFactoryHelper(t, ctx, sys)
    game := disputeGameFactory.StartOutputGame(ctx, "sequencer", 1, common.Hash{0x01})

    // Verify RAT attention test was triggered
    ratContract.WaitForAttentionTest(ctx, game.GameAddress())

    // Verify validator bond was locked
    validatorAfter := ratContract.GetValidatorRegistration(validator, systemConfig)
    require.Less(t, validatorAfter.DepositedAmount, validatorBefore.DepositedAmount)
}
```

### 2. Evidence Submission Test

**Test**: `TestRATEvidenceSubmission`

**Purpose**: Verify validator can submit correct evidence and restore bond.

**Flow**:
```
1. Trigger RAT attention test
2. Validator submits correct evidence
3. Verify evidence is validated
4. Verify bond is restored to validator
5. Verify EvidenceSubmitted event is emitted
```

**Code Outline**:
```go
func TestRATEvidenceSubmission(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    sys, _ := StartFaultDisputeSystemWithRAT(t)
    t.Cleanup(sys.Close)

    ratContract := GetRATContract(t, sys)

    // Create game and trigger RAT
    game := CreateDisputeGameWithRAT(t, ctx, sys)
    testId := ratContract.GetTestIdByGame(game.GameAddress())
    attentionTest := ratContract.GetAttentionTest(testId)

    // Generate correct evidence
    evidence := GenerateCorrectEvidence(attentionTest.BatchHash)

    // Submit evidence as validator
    tx := ratContract.SubmitEvidence(
        attentionTest.SystemConfig,
        attentionTest.BatchIndex,
        evidence,
        WithSigner(validator),
    )

    // Verify bond restored
    receipt := WaitForReceipt(ctx, l1Client, tx)
    require.True(t, receipt.Status == 1)

    // Verify event
    event := FindEvent[EvidenceSubmitted](receipt)
    require.Equal(t, validator, event.Validator)
}
```

### 3. Claim Resolution Bond Refund Test

**Test**: `TestRATResolveClaimBondRefund`

**Purpose**: Verify bond is refunded when validator wins the game as challenger.

**Flow**:
```
1. Trigger RAT attention test
2. Validator participates in dispute game as challenger
3. Validator wins the game
4. FaultDisputeGame calls IRAT.resolveClaim(claimant)
5. Verify bond is refunded
6. Verify BondRestored event is emitted
```

**Code Outline**:
```go
func TestRATResolveClaimBondRefund(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    sys, l1Client := StartFaultDisputeSystemWithRAT(t)
    t.Cleanup(sys.Close)

    ratContract := GetRATContract(t, sys)

    // Create dishonest game
    game := CreateDishonestDisputeGame(t, ctx, sys)

    // Start honest challenger (validator)
    game.StartChallenger(ctx, "Challenger", WithPrivKey(sys.Cfg.Secrets.Alice))

    // Play game until challenger wins
    PlayGameUntilChallengerWins(ctx, game)

    // Wait for game resolution
    sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
    game.WaitForGameStatus(ctx, gameTypes.GameStatusChallengerWon)

    // Verify bond was refunded via resolveClaim
    validatorInfo := ratContract.GetValidatorRegistration(validator, systemConfig)
    require.True(t, validatorInfo.DepositedAmount >= minimumDeposit)
}
```

### 4. Evidence Submission Period Expiry Test

**Test**: `TestRATEvidenceSubmissionExpiry`

**Purpose**: Verify bond is slashed when evidence submission period expires.

**Flow**:
```
1. Trigger RAT attention test
2. Do NOT submit evidence
3. Wait for evidence submission period to expire
4. Call finalizeSlash()
5. Verify bond is slashed (not restored)
6. Verify validator removed from active set if below D_min
```

**Code Outline**:
```go
func TestRATEvidenceSubmissionExpiry(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    sys, l1Client := StartFaultDisputeSystemWithRAT(t)
    t.Cleanup(sys.Close)

    ratContract := GetRATContract(t, sys)

    // Create game and trigger RAT
    game := CreateDisputeGameWithRAT(t, ctx, sys)
    testId := ratContract.GetTestIdByGame(game.GameAddress())
    attentionTest := ratContract.GetAttentionTest(testId)

    // Get initial bond amount
    bondBefore := attentionTest.BondAmount

    // Advance time past evidence submission period
    sys.TimeTravelClock.AdvanceTime(evidenceSubmissionPeriod + 1)

    // Finalize slash
    tx := ratContract.FinalizeSlash(testId)
    receipt := WaitForReceipt(ctx, l1Client, tx)
    require.True(t, receipt.Status == 1)

    // Verify ValidatorSlashed event
    event := FindEvent[ValidatorSlashed](receipt)
    require.Equal(t, bondBefore, event.SlashedAmount)
}
```

### 5. Multi-L2 RAT Identification Test

**Test**: `TestRATMultiL2Identification`

**Purpose**: Verify RAT correctly identifies different L2 chains via SystemConfig.

**Flow**:
```
1. Deploy RAT contract
2. Deploy two L2 chains (L2-A, L2-B) with different SystemConfigs
3. Trigger attention test from L2-A
4. Trigger attention test from L2-B
5. Verify events contain correct systemConfig for each L2
6. Verify validators can distinguish which L2 each test belongs to
```

**Code Outline**:
```go
func TestRATMultiL2Identification(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    // Start system with two L2 chains
    sys := StartMultiL2System(t, 2)
    t.Cleanup(sys.Close)

    ratContract := GetRATContract(t, sys)

    // Create games on both L2s
    gameL2A := CreateDisputeGame(t, ctx, sys, "l2-a")
    gameL2B := CreateDisputeGame(t, ctx, sys, "l2-b")

    // Get attention tests
    testIdL2A := ratContract.GetTestIdByGame(gameL2A.GameAddress())
    testIdL2B := ratContract.GetTestIdByGame(gameL2B.GameAddress())
    testL2A := ratContract.GetAttentionTest(testIdL2A)
    testL2B := ratContract.GetAttentionTest(testIdL2B)

    // Verify different systemConfigs
    require.NotEqual(t, testL2A.SystemConfig, testL2B.SystemConfig)
    require.Equal(t, sys.SystemConfigA, testL2A.SystemConfig)
    require.Equal(t, sys.SystemConfigB, testL2B.SystemConfig)
}
```

### 6. RAT Probability Test

**Test**: `TestRATProbabilityTrigger`

**Purpose**: Verify RAT trigger probability works correctly.

**Flow**:
```
1. Set RAT trigger probability to 50% (0.5e27 in RAY)
2. Create 100 dispute games
3. Count how many triggered RAT attention tests
4. Verify approximately 50% triggered (within statistical tolerance)
```

### 7. Validator Staking Test

**Test**: `TestRATValidatorStaking`

**Purpose**: Verify validator staking and validity management.

**Flow**:
```
1. Register as new validator with minimum deposit (D_min)
2. Verify added to active validators
3. Trigger RAT and get slashed (reduce deposit below D_min)
4. Verify removed from active validators
5. Re-register with additional deposit
6. Verify re-added to active validators
```

### 8. Valid Output Root Defense Test

**Test**: `TestRATValidOutputRootDefense`

**Purpose**: Verify RAT behavior when output root is valid (defender should win).

**Flow**:
```
1. Create dispute game with correct output root
2. Trigger RAT attention test
3. Validator submits correct evidence
4. Defender wins the game
5. Verify RAT bond is restored (not slashed)
```

**Code Outline**:
```go
func TestRATValidOutputRootDefense(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    sys, l1Client := StartFaultDisputeSystemWithRAT(t)
    t.Cleanup(sys.Close)

    ratContract := GetRATContract(t, sys)
    disputeGameFactory := NewFactoryHelper(t, ctx, sys)

    // Create game with CORRECT root (defender should win)
    game := disputeGameFactory.StartOutputGameWithCorrectRoot(ctx, "sequencer", 1)

    // Start honest challenger
    game.StartChallenger(ctx, "Challenger", op_e2e_challenger.WithPrivKey(sys.Cfg.Secrets.Alice))

    // Wait for game resolution
    sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
    game.WaitForGameStatus(ctx, gameTypes.GameStatusDefenderWon)

    // Verify RAT bond was NOT slashed (defender won means no dispute)
    validatorInfo := ratContract.GetValidatorRegistration(validator, systemConfig)
    require.True(t, validatorInfo.DepositedAmount >= initialDeposit)
}
```

### 9. Unsafe Proposal RAT Test

**Test**: `TestRATUnsafeProposal`

**Purpose**: Verify RAT behavior when batch data is not available on L1.

**Flow**:
```
1. Start system with batcher stopped
2. Create dispute game (data unavailable on L1)
3. Trigger RAT attention test
4. Validator cannot generate valid evidence
5. Verify RAT slash behavior for unavailable data
```

**Code Outline**:
```go
func TestRATUnsafeProposal(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    // Start with batcher stopped - no L1 data available
    sys, l1Client := StartFaultDisputeSystemWithRAT(t, WithBatcherStopped())
    t.Cleanup(sys.Close)

    ratContract := GetRATContract(t, sys)
    disputeGameFactory := NewFactoryHelper(t, ctx, sys)

    // Create game for unsafe block (data not on L1)
    game := disputeGameFactory.StartOutputGame(ctx, "sequencer", 1, common.Hash{0x01})

    // Verify RAT handles unavailable data correctly
    // ...
}
```

### 10. Future Block Proposal Test

**Test**: `TestRATFutureBlockProposal`

**Purpose**: Verify RAT behavior when proposal is for a future block.

**Flow**:
```
1. Create dispute game for block 10,000,000 (far future)
2. Verify RAT handles future block scenario
3. Game should resolve as challenger wins (invalid proposal)
```

### 11. Debug Logging Test

**Test**: Helper functions for debugging during E2E tests.

```go
// Log game state for debugging
func (g *RATGameHelper) LogGameData(ctx context.Context) {
    g.T.Logf("=== RAT Game State ===")
    g.T.Logf("Game Address: %s", g.GameAddr)
    g.T.Logf("RAT Contract: %s", g.RATAddr)

    testId := g.RATContract.GetTestIdByGame(g.GameAddr)
    attentionTest := g.RATContract.GetAttentionTest(testId)
    g.T.Logf("Attention Test Status: %v", attentionTest.Status)
    g.T.Logf("Validator: %s", attentionTest.ValidatorAddress)
    g.T.Logf("Bond Amount: %v", attentionTest.BondAmount)
    g.T.Logf("======================")
}
```

## Helper Functions

### RAT Contract Helper (`e2eutils/rat/helper.go`)

```go
package rat

type RATHelper struct {
    client  *ethclient.Client
    address common.Address
    abi     abi.ABI
}

func NewRATHelper(client *ethclient.Client, address common.Address) *RATHelper

func (r *RATHelper) GetValidatorRegistration(validator, systemConfig common.Address) (*ValidatorRegistration, error)

func (r *RATHelper) GetAttentionTest(testId [32]byte) (*AttentionTest, error)

func (r *RATHelper) GetTestIdByGame(gameAddress common.Address) ([32]byte, error)

func (r *RATHelper) RegisterValidator(
    ctx context.Context,
    opts *bind.TransactOpts,
    systemConfig common.Address,
    depositAmount *big.Int,
) (*types.Transaction, error)

func (r *RATHelper) SubmitEvidence(
    ctx context.Context,
    opts *bind.TransactOpts,
    systemConfig common.Address,
    batchIndex uint32,
    evidence []byte,
) (*types.Transaction, error)

func (r *RATHelper) FinalizeSlash(
    ctx context.Context,
    opts *bind.TransactOpts,
    testId [32]byte,
) (*types.Transaction, error)

func (r *RATHelper) WaitForAttentionTest(ctx context.Context, gameAddress common.Address) (*AttentionTest, error)
```

### System Setup Helper

```go
func StartFaultDisputeSystemWithRAT(t *testing.T, opts ...SystemConfigOption) (*System, *ethclient.Client) {
    // 1. Deploy TON Staking V3 RAT contract
    // 2. Configure Optimism with ratAddress
    // 3. Start devnet
    // 4. Return system and L1 client
}
```

## Deployment Script Integration

### TON Staking RAT Deployment (`DeployTONStakingRAT.s.sol`)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {RAT} from "ton-staking-v2/src/validator/RAT.sol";

contract DeployTONStakingRAT is Script {
    function run() external returns (address ratAddress) {
        vm.startBroadcast();

        RAT rat = new RAT();
        // NOTE: ratTriggerProbability should be determined based on game theory formula:
        // C_off ≥ (c_m · N) / π_a
        rat.initialize(
            seigManager,           // SeigManager address
            wton,                  // WTON address
            ton,                   // TON address
            layer2Manager,         // Layer2Manager address (V3: replaced depositManager)
            owner,                 // Owner address
            0.01e27                // ratTriggerProbability (π_a) - adjust based on game theory
        );

        // Set RAT parameters (ratTriggerProbability is now set in initialize)
        rat.setSlashingPenalty(100e27);           // C_off = 100 WTON
        rat.setValidatorBuffer(100e27);           // Δ_validator = 100 WTON
        rat.setMinimumThreshold(200e27);          // D_min = 200 WTON (C_off + Δ)
        rat.setEvidenceSubmissionPeriod(1 hours); // 1 hour
        rat.setAuthorizedTrigger(disputeGameFactory);

        vm.stopBroadcast();

        return address(rat);
    }
}
```

## Test Configuration

### Environment Variables

```bash
# E2E test configuration
export RAT_SLASHING_PENALTY=100000000000000000000000000000  # 100 WTON (RAY)
export RAT_VALIDATOR_BUFFER=100000000000000000000000000000  # 100 WTON (RAY)
export RAT_MINIMUM_THRESHOLD=200000000000000000000000000000 # 200 WTON (RAY)
export RAT_EVIDENCE_SUBMISSION_PERIOD=3600                  # 1 hour in seconds
export RAT_TRIGGER_PROBABILITY=10000000000000000000000000   # 1% (0.01 RAY)
```

### Makefile Target

```makefile
.PHONY: test-e2e-rat
test-e2e-rat:
	cd op-e2e && go test -v -run "TestRAT" ./faultproofs/...

.PHONY: devnet-allocs-rat
devnet-allocs-rat:
	$(MAKE) devnet-allocs
	# Deploy TON Staking RAT
	forge script scripts/deploy/DeployTONStakingRAT.s.sol --broadcast
```

## Interface Reference

### IRAT Interface (from TON Staking V3)

```solidity
interface IRAT {
    // ==========================================
    // Structs (defined in RATStorage)
    // ==========================================

    struct ValidatorRegistration {
        uint256 depositedAmount;        // Current valid deposit (after pre-deduction)
        uint256 totalBondForRAT;        // Total amount locked in ongoing RAT tests
        uint256 pendingRewards;         // Unclaimed validator rewards
        uint256 coinageFactorAtDeposit; // Coinage factor at deposit time
        uint32 validatorIndex;          // Validator index
        bool isActive;                  // Active status
    }

    struct AttentionTest {
        address validatorAddress;       // Selected validator
        address systemConfig;           // L2 SystemConfig address
        uint32 batchIndex;              // Batch index
        bytes32 batchHash;              // Batch hash
        uint256 bondAmount;             // Pre-deducted bond (C_off)
        uint256 createdAt;              // Creation time
        uint256 deadline;               // Response deadline
        AttentionTestStatus status;     // Status (Pending/Responded/Slashed/Expired)
    }

    // ==========================================
    // Events
    // ==========================================

    event ValidatorRegistered(
        address indexed validator,
        address indexed systemConfig,
        uint256 depositAmount,
        uint256 registrationId
    );

    event ValidatorDeactivated(
        address indexed validator,
        address indexed systemConfig,
        uint256 returnedAmount
    );

    event AttentionTestTriggered(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        address gameAddress,
        uint32 batchIndex,
        uint256 deadline
    );

    event EvidenceSubmitted(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint32 batchIndex
    );

    event ValidatorSlashed(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint256 slashedAmount,
        bool removedFromSet
    );

    event BondRestored(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint256 restoredAmount
    );

    event DepositAdded(
        address indexed validator,
        address indexed systemConfig,
        uint256 amount
    );

    // ==========================================
    // View Functions
    // ==========================================

    function getMinimumCollateral() external view returns (uint256);
    function validateSlashingPenalty(uint256 n) external view returns (bool);
    function getValidatorCount(address systemConfig) external view returns (uint256);
    function getActiveValidatorCount(address systemConfig) external view returns (uint256);
    function getTotalPendingRewards(address validator) external view returns (uint256);
    function getPendingRewards(address validator, address systemConfig) external view returns (uint256);

    // ==========================================
    // Validator Management
    // ==========================================

    function registerValidator(address systemConfig, uint256 depositAmount) external;
    function deactivateValidator(address systemConfig) external;
    function addDeposit(address systemConfig, uint256 amount) external;

    // ==========================================
    // RAT Operations
    // ==========================================

    /// @notice Trigger RAT test (called by DisputeGameFactory)
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice Submit RAT evidence
    function submitEvidence(
        address systemConfig,
        uint32 batchIndex,
        bytes calldata evidence
    ) external;

    /// @notice Finalize slash for non-responding validator
    function finalizeSlash(bytes32 testId) external;

    /// @notice Called by FaultDisputeGame when game resolves (refund bond if challenger wins)
    function resolveClaim(address _claimant) external;

    // ==========================================
    // Rewards
    // ==========================================

    function claimRewards(address systemConfig) external;
    function claimRewardsBatch(address[] calldata systemConfigs) external;
    function distributeValidatorReward(address systemConfig, uint256 amount) external;

    // ==========================================
    // Governance
    // ==========================================

    function setAttentionCost(uint256 cost) external;
    function setSlashingPenalty(uint256 penalty) external;
    function setValidatorBuffer(uint256 buffer) external;
    function setMinimumThreshold(uint256 threshold) external;
    function setRatTriggerProbability(uint256 probability) external;
    function setEvidenceSubmissionPeriod(uint256 period) external;
}
```

## Event Flow Diagram

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│     User/       │      │ DisputeGame     │      │   TON Staking   │
│   Sequencer     │      │    Factory      │      │    V3 RAT       │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │ create(...)            │                        │
         │───────────────────────►│                        │
         │                        │                        │
         │                        │ triggerAttentionTest() │
         │                        │ (gameAddr, systemConfig,│
         │                        │  batchIdx, batchHash,  │
         │                        │  blockHash)            │
         │                        │───────────────────────►│
         │                        │                        │
         │                        │                        │ Select validator
         │                        │                        │ Lock bond (C_off)
         │                        │                        │
         │                        │◄──────────────────────│
         │                        │                        │
         │                        │                        │ emit AttentionTestTriggered
         │                        │                        │
         │◄───────────────────────│                        │
         │                        │                        │
         │                        │                        │
┌────────┴────────┐      ┌────────┴────────┐      ┌────────┴────────┐
│    Validator    │      │ FaultDispute    │      │   TON Staking   │
│                 │      │     Game        │      │    V3 RAT       │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │ submitEvidence()       │                        │
         │ (systemConfig, batchIndex, evidence)            │
         │────────────────────────────────────────────────►│
         │                        │                        │
         │                        │                        │ Verify evidence
         │                        │                        │ Restore bond
         │                        │                        │
         │◄───────────────────────────────────────────────│
         │                        │                        │
         │                        │                        │ emit EvidenceSubmitted
         │                        │                        │
         │ (or) wins game as      │                        │
         │      challenger        │                        │
         │◄──────────────────────│                        │
         │                        │                        │
         │                        │ resolveClaim(claimant) │
         │                        │───────────────────────►│
         │                        │                        │
         │                        │                        │ Refund bond
         │                        │                        │
         │                        │◄──────────────────────│
         │                        │                        │
         │                        │                        │ emit BondRestored
```

## Reference: Asterisc E2E Test Comparison

This design was compared against [asterisc/op-e2e/faultproofs](https://github.com/ethereum-optimism/asterisc) E2E tests:

| Asterisc Test | RAT Equivalent | Status |
|--------------|----------------|--------|
| `TestOutputAsteriscGame` | `TestRATTriggerOnGameCreation` | ✅ Covered |
| `TestOutputAsterisc_ChallengeAllZeroClaim` | - | ⚠️ Consider adding |
| `TestOutputAsteriscDefendStep` | `TestRATEvidenceSubmission` | ✅ Covered |
| `TestOutputAsteriscProposedOutputRootValid` | `TestRATValidOutputRootDefense` | ✅ Added |
| `TestOutputAsteriscPoisonedPostState` | - | ❌ Not applicable |
| `TestDisputeOutputRootBeyondProposedBlock` | `TestRATFutureBlockProposal` | ✅ Added |
| `TestInvalidateUnsafeProposal` | `TestRATUnsafeProposal` | ✅ Added |
| `TestMultipleGameTypes` | - | ❌ Not applicable (single RAT) |
| `TestLocalPreimages` | - | ❌ Not applicable |

### Key Patterns from Asterisc:

1. **Account Setup**: Use `sys.Cfg.Secrets.Alice/Bob/Mallory` for test accounts
2. **System Options**: `WithBatcherStopped()`, `WithSequencerWindowSize()` for various scenarios
3. **Game Helpers**: `game.LogGameData(ctx)` for debugging
4. **Time Travel**: `sys.TimeTravelClock.AdvanceTime()` for time-based tests
5. **Wait Functions**: `game.WaitForGameStatus()`, `claim.WaitForCounterClaim()`

## Next Steps

1. Implement Go bindings for TON Staking RAT contract
2. Create RAT helper functions in `e2eutils/rat/`
3. Implement test scenarios in `faultproofs/rat_ton_staking_test.go`
4. Add deployment script for devnet setup
5. Integrate with CI/CD pipeline
