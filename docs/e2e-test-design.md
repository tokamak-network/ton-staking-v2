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
    Alice   = sys.Cfg.Secrets.Alice   // Honest challenger
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
6. Verify challenger is selected and bond is locked
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

    // Record initial challenger state
    challengerBefore := ratContract.GetChallengerInfo(challenger)

    // Create dispute game
    disputeGameFactory := NewFactoryHelper(t, ctx, sys)
    game := disputeGameFactory.StartOutputGame(ctx, "sequencer", 1, common.Hash{0x01})

    // Verify RAT attention test was triggered
    ratContract.WaitForAttentionTest(ctx, game.GameAddress())

    // Verify challenger bond was locked
    challengerAfter := ratContract.GetChallengerInfo(challenger)
    require.Less(t, challengerAfter.StakingAmount, challengerBefore.StakingAmount)
}
```

### 2. Evidence Submission Test

**Test**: `TestRATEvidenceSubmission`

**Purpose**: Verify challenger can submit correct evidence and restore bond.

**Flow**:
```
1. Trigger RAT attention test
2. Challenger submits correct evidence (proofLV, proofRV)
3. Verify evidence is validated
4. Verify bond is restored to challenger
5. Verify CorrectEvidenceSubmitted event is emitted
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
    attentionTest := ratContract.GetAttentionTest(game.GameAddress())

    // Generate correct evidence
    proofLV, proofRV := GenerateCorrectEvidence(attentionTest.StateRoot)

    // Submit evidence as challenger
    tx := ratContract.SubmitCorrectEvidence(
        game.GameAddress(),
        proofLV,
        proofRV,
        WithSigner(challenger),
    )

    // Verify bond restored
    receipt := WaitForReceipt(ctx, l1Client, tx)
    require.True(t, receipt.Status == 1)

    // Verify event
    event := FindEvent[CorrectEvidenceSubmitted](receipt)
    require.Equal(t, challenger, event.Challenger)
}
```

### 3. Claim Resolution Bond Refund Test

**Test**: `TestRATResolveClaimBondRefund`

**Purpose**: Verify bond is refunded when challenger wins the game.

**Flow**:
```
1. Trigger RAT attention test
2. Challenger participates in dispute game
3. Challenger wins the game
4. FaultDisputeGame calls IRAT.resolveClaim(claimant)
5. Verify bond is refunded
6. Verify BondRefunded event is emitted
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

    // Start honest challenger
    game.StartChallenger(ctx, "Challenger", WithPrivKey(sys.Cfg.Secrets.Alice))

    // Play game until challenger wins
    PlayGameUntilChallengerWins(ctx, game)

    // Wait for game resolution
    sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
    game.WaitForGameStatus(ctx, gameTypes.GameStatusChallengerWon)

    // Verify bond was refunded via resolveClaim
    challengerInfo := ratContract.GetChallengerInfo(challenger)
    require.True(t, challengerInfo.StakingAmount >= perTestBondAmount)
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
4. Verify bond is slashed (not restored)
5. Verify challenger validity status updated if below minimum
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
    attentionTest := ratContract.GetAttentionTest(game.GameAddress())

    // Get initial bond amount
    bondBefore := attentionTest.BondAmount

    // Advance time past evidence submission period
    advanceBlocks(t, l1Client, evidenceSubmissionPeriod + 1)

    // Try to submit evidence - should fail
    _, err := ratContract.SubmitCorrectEvidence(
        game.GameAddress(),
        proofLV,
        proofRV,
        WithSigner(challenger),
    )
    require.Error(t, err)
    require.Contains(t, err.Error(), "EvidenceSubmissionExpired")
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
    testL2A := ratContract.GetAttentionTest(gameL2A.GameAddress())
    testL2B := ratContract.GetAttentionTest(gameL2B.GameAddress())

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
1. Set RAT trigger probability to 50% (50000/100000)
2. Create 100 dispute games
3. Count how many triggered RAT attention tests
4. Verify approximately 50% triggered (within statistical tolerance)
```

### 7. Challenger Staking Test

**Test**: `TestRATChallengerStaking`

**Purpose**: Verify challenger staking and validity management.

**Flow**:
```
1. Stake as new challenger
2. Verify added to validChallengers array
3. Trigger RAT and reduce stake below minimum
4. Verify removed from validChallengers array
5. Stake again to restore validity
6. Verify re-added to validChallengers array
```

### 8. Valid Output Root Defense Test

**Test**: `TestRATValidOutputRootDefense`

**Purpose**: Verify RAT behavior when output root is valid (defender should win).

**Flow**:
```
1. Create dispute game with correct output root
2. Trigger RAT attention test
3. Challenger submits correct evidence
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
    challengerInfo := ratContract.GetChallengerInfo(challenger)
    require.True(t, challengerInfo.StakingAmount >= initialStake)
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
4. Challenger cannot generate valid evidence
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

    attentionTest := g.RATContract.GetAttentionTest(g.GameAddr)
    g.T.Logf("Attention Test Status: %v", attentionTest.Status)
    g.T.Logf("Challenger: %s", attentionTest.ChallengerAddress)
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

func (r *RATHelper) GetChallengerInfo(challenger common.Address) (*ChallengerInfo, error)

func (r *RATHelper) GetAttentionTest(gameAddress common.Address) (*AttentionInfo, error)

func (r *RATHelper) Stake(ctx context.Context, opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error)

func (r *RATHelper) SubmitCorrectEvidence(
    ctx context.Context,
    opts *bind.TransactOpts,
    gameAddress common.Address,
    proofLV, proofRV [32]byte,
) (*types.Transaction, error)

func (r *RATHelper) WaitForAttentionTest(ctx context.Context, gameAddress common.Address) (*AttentionInfo, error)
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
        rat.initialize(
            disputeGameFactory,
            perTestBondAmount,
            evidenceSubmissionPeriod,
            minimumStakingBalance,
            ratTriggerProbability,
            manager
        );

        vm.stopBroadcast();

        return address(rat);
    }
}
```

## Test Configuration

### Environment Variables

```bash
# E2E test configuration
export RAT_PER_TEST_BOND_AMOUNT=100000000000000000  # 0.1 ETH
export RAT_EVIDENCE_SUBMISSION_PERIOD=100           # 100 blocks
export RAT_MINIMUM_STAKING_BALANCE=1000000000000000000  # 1 ETH
export RAT_TRIGGER_PROBABILITY=50400                # Weekly probability
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

### IRAT Interface (from Optimism)

```solidity
interface IRAT {
    /// @notice Triggers attention test (called by DisputeGameFactory)
    function triggerAttentionTest(
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice Called when a claim is resolved in FaultDisputeGame
    function resolveClaim(address claimant) external;
}
```

### RAT Contract Interface (TON Staking V3)

```solidity
interface ITONStakingRAT is IRAT {
    struct ChallengerInfo {
        uint256 stakingAmount;
        uint256 totalSlashedAmount;
        uint32 validatorIndex;
        bool isValid;
    }

    struct AttentionInfo {
        bytes32 stateRoot;
        uint96 bondAmount;
        address challengerAddress;
        uint64 l1BlockNumber;
        bool evidenceSubmitted;
    }

    event ChallengerStaked(address indexed challenger, uint256 amount);
    event AttentionTriggered(address indexed gameAddress, address indexed challenger);
    event CorrectEvidenceSubmitted(address indexed gameAddress, address indexed challenger, uint256 restoredAmount);
    event BondRefunded(address indexed gameAddress, address indexed challenger, uint256 refundedAmount);

    function stake() external payable;
    function getChallengerInfo(address _challenger) external view returns (ChallengerInfo memory);
    function submitCorrectEvidence(address _gameAddress, bytes32 _proofLV, bytes32 _proofRV) external;
    function getValidChallengerCount() external view returns (uint256);
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
         │                        │───────────────────────►│
         │                        │                        │
         │                        │                        │ Select challenger
         │                        │                        │ Lock bond
         │                        │                        │
         │                        │◄──────────────────────│
         │                        │                        │
         │                        │                        │ emit AttentionTriggered
         │                        │                        │
         │◄───────────────────────│                        │
         │                        │                        │
         │                        │                        │
┌────────┴────────┐      ┌────────┴────────┐      ┌────────┴────────┐
│   Challenger    │      │ FaultDispute    │      │   TON Staking   │
│   (Validator)   │      │     Game        │      │    V3 RAT       │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │ submitCorrectEvidence()│                        │
         │────────────────────────────────────────────────►│
         │                        │                        │
         │                        │                        │ Verify proof
         │                        │                        │ Restore bond
         │                        │                        │
         │◄───────────────────────────────────────────────│
         │                        │                        │
         │                        │                        │ emit CorrectEvidenceSubmitted
         │                        │                        │
         │ (or) resolveClaim()    │                        │
         │        wins game       │                        │
         │◄──────────────────────│                        │
         │                        │                        │
         │                        │ resolveClaim(claimant) │
         │                        │───────────────────────►│
         │                        │                        │
         │                        │                        │ Refund bond
         │                        │                        │
         │                        │◄──────────────────────│
         │                        │                        │
         │                        │                        │ emit BondRefunded
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
