---
id: 04-contract-roles
sidebar_position: 4
---
# TON Staking V3 Contract Roles

## 1. Contract Role Overview

| Contract | Main Role | Core Responsibilities |
|----------|-----------|----------------------|
| **SeigManager** | Seigniorage distribution | Seigniorage calculation, distribution, eligibility management, sequencer slashing |
| **DepositManager** | Staking management | TON/WTON deposits, withdrawal processing |
| **Layer2Manager** | L2 management | L2 registration, Bridged TON queries |
| **L1BridgeRegistry** | Bridge registration | Bridge/portal registration, TVL queries |
| **RAT** | Validator management | Validator registration, RAT tests, C_off penalty |
| **ValidatorReward** | Validator rewards | Reward distribution, claim processing |

---

## 2. SeigManager

### 2.1 Role

The **core contract** of the TON Staking system, responsible for calculating and distributing seigniorage (newly issued TON).

### 2.2 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **Seigniorage calculation** | Calculate seigniorage per block |
| **V3 distribution logic** | Hyperbolic function, eligibility condition application |
| **Eligibility management** | Check/update L2 eligibility (T_i ≥ θ·B_i) |
| **Validator reward distribution** | Send α·S_i to ValidatorReward |
| **DAO distribution** | Send d·A to DAO Treasury |
| **Coinage management** | Manage staking receipt tokens |

### 2.3 Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SeigManager Interactions                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:                                                                  │
│  ┌─────────────────┐                                                    │
│  │ DepositManager  │──► onDeposit(), onWithdraw(), onStakingChange()   │
│  │ OptimismPortal  │──► onBridgedTonChange() (Type 3)                  │
│  │ Anyone          │──► updateSeigniorage()                             │
│  └─────────────────┘                                                    │
│                                                                          │
│  Queries:                                                                │
│  ┌─────────────────┐                                                    │
│  │ L1BridgeRegistry│◄── layer2TVL()                                    │
│  │ Coinage        │◄── balanceOf(operator) (sequencer/validator collateral)│
│  │ Layer2Manager   │◄── getLayer2BySystemConfig()                      │
│  └─────────────────┘                                                    │
│                                                                          │
│  Output:                                                                 │
│  ┌─────────────────┐                                                    │
│  │ ValidatorReward │──► distributeL2Rewards()                          │
│  │ Layer2Manager   │──► transferL2Seigniorage()                        │
│  │ WTON            │──► mint() (seigniorage issuance)                   │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.4 Core State

- `v3Migrated`: V3 mode activation status
- `daoDistributionRatio` (d): DAO distribution ratio
- `minStakingRatio` (θ): Minimum staking ratio
- `validatorDistributionRatio` (α): Validator distribution ratio
- `halfSaturationPoint` (k): Half saturation point
- `totalEffectiveBridgedTON` (x): Total effective Bridged TON
- `bridgedTONInfo[layer2]`: L2-specific Bridged TON information

---

## 3. DepositManager

### 3.1 Role

Acts as the **deposit/withdrawal gateway** for TON/WTON staking.

### 3.2 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **WTON staking** | `deposit()` function |
| **TON staking** | `onApprove()` callback (approveAndCall) |
| **Withdrawal request** | `requestWithdrawal()` |
| **Withdrawal processing** | `processRequest()` (after 2 weeks wait) |
| **Staking notification** | Request eligibility re-evaluation to SeigManager |

### 3.3 Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DepositManager Interactions                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:                                                                  │
│  ┌─────────────────┐                                                    │
│  │ Staker          │──► deposit(), requestWithdrawal(), processRequest()│
│  │ WTON           │──► onApprove() (via TON.approveAndCall)            │
│  └─────────────────┘                                                    │
│                                                                          │
│  Output:                                                                 │
│  ┌─────────────────┐                                                    │
│  │ SeigManager    │──► onDeposit(), onWithdraw(), onStakingChange()    │
│  │ Coinage        │──► Manage staking receipt tokens                    │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.4 Core State

- `_withdrawalRequests[layer2][account]`: Withdrawal request list
- `globalWithdrawalDelay`: Global withdrawal delay (block count)

> **Staking amount query**: Use `SeigManager.stakeOf(layer2, account)`

---

## 4. Layer2Manager

### 4.1 Role

Handles **registration and management** of L2 rollups.

### 4.2 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **L2 registration** | Register Layer2/Operator/OperatorManager |
| **Bridged TON query** | Query through L1BridgeRegistry |
| **SystemConfig mapping** | Manage SystemConfig ↔ Layer2 mapping |
| **Seigniorage transfer** | Deliver seigniorage to sequencer |

### 4.3 Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Layer2Manager Interactions                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:                                                                  │
│  ┌─────────────────┐                                                    │
│  │ DAO/Admin      │──► registerLayer2(), setOperator()                 │
│  │ SeigManager    │──► transferL2Seigniorage()                         │
│  └─────────────────┘                                                    │
│                                                                          │
│  Queries:                                                                │
│  ┌─────────────────┐                                                    │
│  │ L1BridgeRegistry│◄── layer2TVL()                                    │
│  └─────────────────┘                                                    │
│                                                                          │
│  Output:                                                                 │
│  ┌─────────────────┐                                                    │
│  │ OperatorManager│──► Transfer seigniorage WTON                        │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.4 Core State

- `layerInfo[layer2]`: L2-specific information (operator, status, etc.)
- `operatorInfo[operator]`: Operator information
- `rollupConfigInfo[systemConfig]`: SystemConfig-specific information

---

## 5. L1BridgeRegistry

### 5.1 Role

Handles **registration and TVL queries** for L1 bridges/portals. V1_2 includes all functions from V1_1.

### 5.2 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **Bridge registration** | Register L1StandardBridge, OptimismPortal, DisputeGameFactory |
| **Rollup type management** | Distinguish Type 1/2/3, TYPE 1/2 → 3 upgrade |
| **TVL query** | Query L2-specific Bridged TON balance |
| **Portal reverse query** | Portal → rollupConfig mapping |
| **Seigniorage management** | Stop/restore seigniorage issuance per rollup |
| **Type-specific permission management** | Delegate registration via typeRegistrant[n] |

### 5.3 Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      L1BridgeRegistry Interactions                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:                                                                  │
│  ┌─────────────────┐                                                    │
│  │ Owner          │──► setAddresses(), setSeigniorageCommittee()       │
│  │ Manager        │──► registerRollupConfigByManager(), upgradeToType3()│
│  │ SeigniorageCmt │──► rejectCandidateAddOn(), restoreCandidateAddOn()  │
│  │ Registrant     │──► registerRollupConfig()                           │
│  │ typeRegistrant │──► registerRollupConfigByType()                     │
│  └─────────────────┘                                                    │
│                                                                          │
│  Query Provider:                                                         │
│  ┌─────────────────┐                                                    │
│  │ SeigManager    │◄── layer2TVL(), rollupType()                       │
│  │ Layer2Manager  │◄── layer2TVL()                                     │
│  │ RAT            │◄── rollupConfigWithDisputeGameFactory()            │
│  └─────────────────┘                                                    │
│                                                                          │
│  TVL Query Method: TON.balanceOf(address)                               │
│  ┌─────────────────┐                                                    │
│  │ L1StandardBridge│◄── TON.balanceOf(bridge) (Type 1)                 │
│  │ OptimismPortal │◄── TON.balanceOf(portal) (Type 2, 3)               │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.4 Core State

**V1 Storage**:
- `rollupInfo[rollupConfig]`: Rollup information (type, l2TON, rejectedSeigs, etc.)
- `l1Bridge[bridge]`: L1StandardBridge registration status
- `portal[portal]`: OptimismPortal registration status

**V1_2 Storage**:
- `disputeGameFactory[rollupConfig]`: DisputeGameFactory registration status
- `rollupConfigWithDisputeGameFactory[factory]`: Factory → rollupConfig reverse mapping
- `rollupConfigWithPortal[portal]`: Portal → rollupConfig reverse mapping
- `typeRegistrant[type]`: Type-specific registration authority

---

## 6. RAT (Randomized Attention Test)

### 6.1 Role

Manages validator **registration, RAT tests, and C_off penalties**.

### 6.2 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **Validator registration** | Register validators per L2 and manage collateral |
| **RAT trigger** | Probabilistic trigger on DisputeGame creation |
| **Evidence verification** | Process validator evidence submission |
| **Collateral restoration** | Restore on evidence submission/challenge win |
| **C_off penalty** | Confiscate C_off on no response |
| **Validator queries** | Provide validator information to ValidatorReward |

### 6.3 Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            RAT Interactions                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:                                                                  │
│  ┌───────────────────────┐                                              │
│  │ Validator            │──► registerValidator(), submitEvidence()     │
│  │                      │──► deactivateValidator(), addDeposit()       │
│  │ DisputeGameFactory   │──► triggerAttentionTest()                    │
│  │ FaultDisputeGame     │──► resolveClaim() (on challenge win)         │
│  │ WTON                 │──► onApprove() (approveAndCall registration) │
│  └───────────────────────┘                                              │
│                                                                          │
│  Query Provider:                                                         │
│  ┌─────────────────┐                                                    │
│  │ ValidatorReward│◄── getL2Validators(), isValidatorActive()         │
│  │               │◄── getActiveValidatorCount()                        │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.4 Core State

- `validatorRegistrations[systemConfig][validator]`: Validator registration information
- `validatorPools[systemConfig]`: L2-specific validator pool
- `attentionTests[testId]`: RAT test information
- `slashingPenalty` (C_off): Slashing penalty
- `minimumThreshold` (D_min): Minimum collateral threshold
- `ratTriggerProbability` (π_a): RAT trigger probability
- `evidenceSubmissionPeriod`: Evidence submission period

---

## 7. ValidatorReward

### 7.1 Role

Dedicated to validator **reward distribution and claims**.

### 7.2 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **L2-specific reward distribution** | Receive α·S_i from SeigManager then distribute |
| **Equal distribution** | Distribute equally to active validators |
| **Treasury allocation** | Send to DAO Treasury when no validators |
| **Reward claims** | Process validator reward claims |
| **Per-L2 tracking** | Track reward history per L2 |

### 7.3 Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       ValidatorReward Interactions                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:                                                                  │
│  ┌─────────────────┐                                                    │
│  │ SeigManager    │──► distributeL2Rewards(systemConfig, amount)       │
│  │ Validator      │──► claimAllRewards()                               │
│  └─────────────────┘                                                    │
│                                                                          │
│  Queries:                                                                │
│  ┌─────────────────┐                                                    │
│  │ RAT            │◄── getL2Validators(), isValidatorActive()         │
│  └─────────────────┘                                                    │
│                                                                          │
│  Output:                                                                 │
│  ┌─────────────────┐                                                    │
│  │ Validator      │──► Transfer WTON reward                            │
│  │ DAO Treasury   │──► Transfer WTON when no validators                │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.4 Core State

- `validatorPendingRewards[validator]`: Total unclaimed rewards
- `validatorL2PendingRewards[validator][systemConfig]`: L2-specific unclaimed rewards

---

## 8. Role Summary Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Role Division Summary                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  Seigniorage Flow:                                                              │
│  ┌──────────┐    Calculate/    ┌──────────────┐    Sequencer   ┌──────────────┐ │
│  │ WTON.mint│    Distribute     │ SeigManager  │    Share       │ Layer2Manager │ │
│  └──────────┘──────────────►│              │──────────────►│              │ │
│                             │              │               └──────────────┘ │
│                             │              │                                  │
│                             │              │    Validator  ┌───────────────┐ │
│                             │              │    Share      │ValidatorReward│ │
│                             └──────────────┘──────────────►│               │ │
│                                                             └───────────────┘ │
│                                                                                  │
│  Staking Flow:                                                                   │
│  ┌──────────┐     Deposit    ┌───────────────┐    Notify   ┌──────────────┐    │
│  │ Staker   │─────────────►│DepositManager │────────────►│ SeigManager  │    │
│  └──────────┘              └───────────────┘             └──────────────┘    │
│                                                                                  │
│  Validator Flow (V3: Uses existing staking):                                    │
│  ┌──────────┐    Staking    ┌───────────────┐                                  │
│  │ Validator│─────────────►│DepositManager │                                  │
│  └─────┬────┘              └───────────────┘                                  │
│        │ Register                (Collateral)                                  │
│        ▼                                                                         │
│  ┌───────────────┐   Provide    ┌───────────────┐                             │
│  │     RAT       │   Info       │ValidatorReward│                             │
│  └───────────────┘────────────►│               │                             │
│                                 └───────────────┘                             │
│                                                                                  │
│  Sequencer Flow (V3: Uses existing staking):                                    │
│  ┌──────────┐    Staking    ┌───────────────┐   Query      ┌──────────────┐  │
│  │ Sequencer│─────────────►│DepositManager │   Collateral  │ SeigManager  │  │
│  └──────────┘              └───────────────┘  (coinage)    └──────────────┘  │
│                                                                                  │
│  Bridged TON Flow:                                                              │
│  ┌──────────────┐   Notify   ┌──────────────┐    Query    ┌─────────────────┐ │
│  │OptimismPortal│──────────►│ SeigManager  │◄───────────│ L1BridgeRegistry│ │
│  └──────────────┘          └──────────────┘            └─────────────────┘ │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Related Documents

- [01-system-overview.md](./01-system-overview.md): System Overview
- [02-system-architecture.md](./02-system-architecture.md): System Architecture
- [03-contract-structure.md](./03-contract-structure.md): Contract Structure
- [05-actors.md](./05-actors.md): Actor Definitions
- [06-function-specs.md](./06-function-specs.md): Detailed Function Descriptions
