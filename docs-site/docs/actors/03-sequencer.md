---
id: actors-sequencer
sidebar_position: 3
---

# Sequencer

## Definition

Operators who determine transaction order for L2 rollups and submit batches.

## Role

- Determine L2 transaction order
- Submit batch data to L1
- Submit Output Root (create DisputeGame)
- Deposit collateral in existing staking system (coinage)

## Reward

```
Sequencer reward = o_i = (1 - α) · S_i

Where:
- S_i = L2 i's seigniorage = y(x) · (B̃_i / x)
- α = Validator distribution ratio (e.g., 20%)
```

## Risk

**Full collateral slashing on Fraud**

```
Sequencer collateral = D_sequencer = H_max · C_max + Δ_sequencer

On slashing:
- Challenger reward: C_max + Δ/n (to each challenger)
- Remainder: DAO Treasury
```

## Eligibility Condition

```
T_i ≥ max(θ · B_i, H_max · C_max + Δ_sequencer)

Where:
- T_i = Sequencer staking amount (SeigManager.getSequencerStaked(layer2))
- θ · B_i = Seigniorage eligibility condition (Whitepaper Rule 4)
- H_max · C_max + Δ_sequencer = Fraud Proof cost coverage (Whitepaper Formula 1)

Parameters:
- θ = Minimum staking ratio (e.g., 10%)
- B_i = Bridged TON
- H_max = Maximum simultaneous challengers
- C_max = Maximum cost per Fraud Proof
- Δ_sequencer = Sequencer additional reward
```

## Interactions

```
┌────────────────────────────────────────────────────────────┐
│                         Sequencer                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Collateral Deposit (uses existing staking):          │   │
│  │   DepositManager.deposit(layer2, amount)             │   │
│  │   → Query collateral via SeigManager.getSequencerStaked(layer2)│
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Operations:                                          │   │
│  │   1. Collect L2 transactions and determine order     │   │
│  │   2. Submit batch data to L1                         │   │
│  │   3. Submit Output Root (DisputeGameFactory.create)  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Seigniorage Distribution (V3):                       │   │
│  │   When SeigManager.updateSeigniorage() is called     │   │
│  │   → When eligibility met (T_i ≥ max(θ·B_i, D_seq))  │   │
│  │   → Sequencer reward: o_i = (1-α) · S_i             │   │
│  │   → WTON mint → Layer2Manager → OperatorManager     │   │
│  │   ※ V3: No seigniorage for general stakers          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Reward Receipt:                                      │   │
│  │   OperatorManager.claimERC20(wton, amount)           │   │
│  │   → Receive accumulated WTON from OperatorManager     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Staking Amount Withdrawal:                            │   │
│  │   DepositManager.requestWithdrawal(layer2, amount)   │   │
│  │   (processRequest after 2 weeks wait)                │   │
│  │   ※ Cannot withdraw below collateral (max(θ·B_i, D_seq))│
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## Sequencer Journey Guide

The complete process for new sequencers to participate in the V3 system.

### New Sequencer Participation Flow

**Step 1: L2 Registration**

```solidity
// 1. Register L2 through L1BridgeRegistry
L1BridgeRegistry.registerRollupConfig(
    systemConfig,  // rollupConfig address
    type,          // 1=TOKAMAK, 2=BEDROCK, 3=BEDROCK_WITH_DISPUTE_GAME
    l2TON,         // L2 TON address
    "L2 Name"
);

// 2. Register CandidateAddOn (sequencer) with initial deposit
// Method A: Deposit with TON
Layer2Manager.registerCandidateAddOn(
    systemConfig,
    initialAmount,  // TON units (must be >= minimumInitialDepositAmount)
    true,           // flagTon = true
    "memo"
);

// Method B: Deposit with WTON
Layer2Manager.registerCandidateAddOn(
    systemConfig,
    initialAmount,  // WTON units (RAY)
    false,          // flagTon = false
    "memo"
);

// Or use TON.approveAndCall
TON.approveAndCall(
    Layer2Manager,
    initialAmount,
    abi.encode(systemConfig, "memo")
);
```

**Step 2: V3 Eligibility Check**

Eligibility can be checked in two ways:

**Method A: Direct Function Call (view function)**
```solidity
// Query current eligibility status
(bool eligible, uint256 required, uint256 current) = 
    SeigManager.checkCurrentEligibility(layer2);

// eligible: current eligibility status
// required: required collateral = max(θ × B_i, D_sequencer)
// current: current staking amount
```

**Method B: Event Monitoring (Recommended)**
```solidity
// Subscribe to EligibilityChanged event
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);

// Emitted when:
// - onBridgedTonChange() called (TYPE 3)
// - onDeposit() / onWithdraw() called
// - updateSeigniorage() called
```

**Step 3: Additional Deposit if Seigniorage Eligibility Not Met (Optional)**

In V3, eligibility conditions must be met to receive seigniorage:
- `T_i ≥ max(θ·B_i, D_sequencer)`
- Initial `minimumInitialDepositAmount` may not be sufficient
- Especially as Bridged TON(B_i) increases, required collateral increases

```solidity
if (!eligible) {
    // Calculate shortage
    uint256 shortage = required - current;
    
    // Additional deposit to restore eligibility
    DepositManager.deposit(layer2, shortage);
    
    // onDeposit() automatically called → eligibility re-evaluation
    // Or eligibility checked on next updateSeigniorage()
}
```

**Note**: Even when ineligible:
- L2 operates normally (can produce blocks)
- Only seigniorage not received (`effectiveBridgedTON = 0`)

**Step 4: Receive Seigniorage**

Seigniorage is distributed in two steps:

```solidity
// Step 1: Auto-transfer from SeigManager to OperatorManager
//         (Anyone can call updateSeigniorage())
SeigManager.updateSeigniorage();
// ↓
// Layer2Manager.transferL2Seigniorage() called
// ↓
// WTON transferred to OperatorManager

// Step 2: Claim from OperatorManager to sequencer
//         (Only owner or manager can call)
OperatorManager.claimERC20(WTON_ADDRESS, amount);
// ↓
// WTON transferred to manager address
```

### Slashing and Recovery

**Slashing Occurrence**:

```
1. Submit incorrect Output Root
   ↓
2. Challenger submits Fraud Proof
   ↓
3. DisputeGame resolved (status not DEFENDER_WINS)
   ↓
4. Anyone calls slashSequencerByGame(gameAddress)
   ↓
5. Full collateral confiscated (coinage.burnFrom)
   - Challenger reward: C_max + Δ/n
   - Remainder: DAO Treasury
   ↓
6. Event: SequencerSlashed
```

**Recovery Impossible**:
- Full collateral loss on slashing
- L2 re-registration required
- Start from scratch as new sequencer
