---
id: 02-system-architecture
sidebar_position: 2
---
# TON Staking V3 System Architecture

## 1. Overall Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    L1 (Ethereum)                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            Core Staking System                                   │ │
│  │                                                                                  │ │
│  │  ┌──────────────┐     ┌──────────────────┐                                      │ │
│  │  │   TON/WTON   │────►│  DepositManager  │                                      │ │
│  │  │   (Tokens)   │     │  (Staking Mgmt)   │                                      │ │
│  │  └──────────────┘     └────────┬─────────┘                                      │ │
│  │                                │                                                │ │
│  │                                ▼                                                │ │
│  │                        ┌──────────────────┐     ┌─────────────────┐             │ │
│  │                        │   SeigManager    │◄───►│    Coinage      │             │ │
│  │                        │ (Seigniorage)    │     │  (Receipt Token) │             │ │
│  │                        └────────┬─────────┘     └─────────────────┘             │ │
│  │                                │                                                │ │
│  │           ┌────────────────────┼────────────────────┐                          │ │
│  │           │                    │                                              │ │
│  │           ▼                    ▼                                              │ │
│  │  ┌─────────────────┐  ┌──────────────────┐                                    │ │
│  │  │  Layer2Manager  │  │ ValidatorReward  │                                    │ │
│  │  │   (L2 Mgmt)      │  │  (Validator Rwd) │                                    │ │
│  │  └────────┬────────┘  └────────┬─────────┘                                    │ │
│  │           │                    │                                              │ │
│  └───────────┼────────────────────┼──────────────────────────────────────────────┘ │
│              │                    │                                                │
│  ┌───────────┼────────────────────┼──────────────────────────────────────────────┐ │
│  │           ▼                    ▼                                              │ │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────────────┐       │ │
│  │  │L1BridgeRegistry │  │       RAT        │  │  Optimism Contracts      │       │ │
│  │  │(Bridge/TVL Qry) │  │ (Validator/C_off) │  │  - DisputeGameFactory    │       │ │
│  │  └────────┬────────┘  └──────────────────┘  │  - FaultDisputeGame      │       │ │
│  │           │                                  │  - OptimismPortal        │       │ │
│  │           │           Validator/Bridge       │  - SystemConfig          │       │ │
│  │           │              System              └─────────────────────────┘       │ │
│  └───────────┼────────────────────────────────────────────────────────────────────┘ │
│              │                                                                      │
│              │  Bridged TON                                                         │
│              ▼                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                         L1 Bridge Contracts                                   │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │  │
│  │  │ L1StandardBridge │  │ OptimismPortal  │  │    ... (N개)    │              │  │
│  │  │    (Type 2)      │  │    (Type 3)     │  │                │              │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘              │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         │ L1 ↔ L2 Bridge
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                    L2 (Rollups)                                       │
│                                                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐ │
│  │  Titan L2                     Thanos L2                    Other L2s            │ │
│  │  ┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐   │ │
│  │  │ L2StandardBridge│         │ L2StandardBridge│         │       ...       │   │ │
│  │  │   TON Balance   │         │   TON Balance   │         │                 │   │ │
│  │  └─────────────────┘         └─────────────────┘         └─────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Contract Dependency Relationships

### 2.1 Core Dependencies

```
                            ┌─────────────────┐
                            │   DAOCommittee  │
                            │   (Governance)  │
                            └────────┬────────┘
                                     │ owner/admin
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                               │
│  ┌─────────────┐       ┌─────────────────┐       ┌────────────────┐         │
│  │   TON       │◄─────►│     WTON        │◄─────►│ DepositManager │         │
│  │ (18 dec)    │       │  (27 dec)       │       └───────┬────────┘         │
│  └─────────────┘       └─────────────────┘               │                  │
│                                                          │ onDeposit        │
│  ┌─────────────────────────────────────────┐             │ onWithdraw       │
│  │            Layer2Manager                │◄────────────┤                  │
│  │                                          │             │                  │
│  │  - layerInfo[layer2]                    │             │                  │
│  │  - operatorInfo[operator]               │             │                  │
│  └───────────────────┬──────────────────────┘             ▼                  │
│                      │                           ┌─────────────────┐         │
│                      │ getBridgedTON             │  SeigManager    │         │
│                      ▼                           │                 │         │
│  ┌─────────────────────────────────────────┐     │ V3 분배 로직:    │         │
│  │           L1BridgeRegistry              │────►│ - y(x)=L·x/(k+x)│         │
│  │                                          │     │ - T_i ≥ max(θ·B_i, D_seq) │
│  │  - rollupType[config]                   │     │ - α 검증자 분배  │         │
│  │  - layer2TVL(config)                    │     └────────┬────────┘         │
│  └─────────────────────────────────────────┘              │                  │
│                                                           │                  │
│                                                          │                  │
│                                                          ▼                  │
│                          ┌──────────────────┐  ┌──────────────────┐         │
│                          │ ValidatorReward  │  │       RAT        │         │
│                          │                  │  │                  │         │
│                          │ - 검증자 보상     │  │ - 검증자 등록     │         │
│                          │ - Per-L2 분배    │◄─┤ - RAT 테스트      │         │
│                          └──────────────────┘  │ - C_off 페널티    │         │
│                                                └──────────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Call Direction

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          데이터 흐름 방향                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  DisputeGameFactory ──► RAT.triggerAttentionTest()                      │
│                                                                          │
│  OptimismPortal ──► SeigManager.onBridgedTonChange()                    │
│                                                                          │
│  DepositManager ──► SeigManager.onDeposit() / onWithdraw()              │
│                  ──► SeigManager.onStakingChange()                       │
│                                                                          │
│  SeigManager ──► ValidatorReward.distributeL2Rewards()                  │
│              ──► Layer2Manager.transferL2Seigniorage()                  │
│              ──► L1BridgeRegistry.layer2TVL()                           │
│              ──► Coinage.balanceOf(operator) (시퀀서 담보금)            │
│                                                                          │
│  ValidatorReward ──► RAT.getL2Validators()                              │
│                  ──► RAT.isValidatorActive()                             │
│                                                                          │
│  FaultDisputeGame ──► RAT.resolveClaim()                                │
│                                                                          │
│  누구나 ──► SeigManager.slashSequencerByGame() (Permissionless)          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Proxy Patterns

Two proxy patterns are used in the system.

### 3.1 Multi-Implementation Pattern (Selector Routing) - Existing Core Contracts

Existing core contracts use a **function-by-function routing (Selector Routing)** multi-implementation pattern:

```
┌─────────────────────────────────────────────────────────────────────┐
│            Multi-Implementation Proxy (Selector Routing)             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Call Flow:                                                          │
│  1. Function call → Proxy fallback()                                 │
│  2. Query selectorImplementation[selector]                            │
│  3-A. Selector registered → delegatecall to that implementation      │
│  3-B. Selector not registered → delegatecall to default (index 0)   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  예시: SeigManagerProxy                                       │   │
│  │                                                               │   │
│  │  initialize()  → selectorImpl 없음 → V1_2 (기본 구현체)       │   │
│  │  pause()       → selectorImpl[0x8456cb59] = V1_3 → V1_3      │   │
│  │  setRAT()      → selectorImpl[0x...] = V1_4 → V1_4           │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Applied Contracts:                                                  │
│  - SeigManager (V1_2 default, V1_3/V1_4 routing)                     │
│  - DepositManager (Base default, SetDelay/V1_1/V1_2 routing)        │
│  - Layer2Manager (V1_1 default, V1_2 routing)                        │
│  - L1BridgeRegistry (V1_2 standalone - includes all V1_1 functions)│
│                                                                      │
│  Management: DAOCommittee (upgradeTo, setSelectorImplementations2)   │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 OpenZeppelin TransparentUpgradeableProxy - V3 New Contracts

New contracts added in V3 use OpenZeppelin's TransparentUpgradeableProxy (ERC1967):

```
┌─────────────────────────────────────────────────────────────────────┐
│              TransparentUpgradeableProxy (ERC1967)                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────────┐      ┌───────────────────────────────┐      │
│  │  RATProxy         │─────►│  RAT (Single Implementation)   │      │
│  │                   │      └───────────────────────────────┘      │
│  │  ERC1967 Slot:    │                                              │
│  │  - _IMPL_SLOT     │      ┌───────────────────────────────┐      │
│  │  - _ADMIN_SLOT    │      │  ValidatorRewardV1            │      │
│  └───────────────────┘      │  (Single Implementation)     │      │
│          │                   └───────────────────────────────┘      │
│          ▼                                                          │
│  ┌───────────────────┐                                              │
│  │   ProxyAdmin      │  ← Auto-created on deployment                │
│  │   (DAO Managed)   │                                              │
│  └───────────────────┘                                              │
│                                                                      │
│  Applied Contracts:                                                  │
│  - RAT (RATProxy)                                                    │
│  - ValidatorReward (ValidatorRewardProxy)                            │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.3 ERC1967Proxy Custom - OperatorManager

OperatorManager uses a custom proxy based on ERC1967Upgrade:

```
┌─────────────────────────────────────────────────────────────────────┐
│                  OperatorManagerProxy (ERC1967 기반)                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────────┐      ┌───────────────────────────────┐      │
│  │OperatorMgrProxy   │─────►│  OperatorManagerV1_2 (기본) 🆕 │      │
│  │                   │      └───────────────────────────────┘      │
│  │ - Ownable         │                                              │
│  │ - ERC1967Upgrade  │                                              │
│  └───────────────────┘                                              │
│                                                                      │
│  Features: Factory creates proxy per L2, Owner manages upgrades     │
└─────────────────────────────────────────────────────────────────────┘
```

**V3 Changes:**
- OperatorManagerFactory creates new proxies with **V1_2 logic**
- TYPE 1/2 rollups also created with V1_2 (preparation for future TYPE 3 upgrade)
- Existing deployed TYPE 1/2 OperatorManagers require **manual upgrade to V1_2 logic**

```solidity
// Upgrade existing OperatorManager to V1_2 (manual)
OperatorManagerProxy(operatorManager).upgradeTo(address(operatorManagerV1_2Impl));
```

### 3.4 Storage Inheritance Chain

```solidity
// SeigManager storage inheritance
contract SeigManagerV3_1 is
    ProxyStorage,              // Basic proxy storage
    AuthControlSeigManager,    // Access control
    SeigManagerStorage,        // V1 storage
    SeigManagerV1_1Storage,    // V1.1 additional storage
    DSMath,                    // Math library
    SeigManagerV1_3Storage,    // V1.3 additional storage
    SeigManagerV1_4Storage     // V1.4 additional storage (V3)
```

---

## 4. Rollup Type-Specific Architecture

### 4.1 Supported Rollup Types

| Type | Name | TVL Query Method |
|------|------|------------------|
| Type 1 | TOKAMAK (Legacy) | L1StandardBridge balance |
| Type 2 | OPTIMISM_BEDROCK | OptimismPortal balance |
| Type 3 | OPTIMISM_BEDROCK_WITH_DISPUTE_GAME | OptimismPortal balance |

### 4.2 Type 3 Architecture (Recommended)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    Type 3 (Dispute Game Support)                         │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐      │
│  │  SystemConfig   │────│ OptimismPortal  │────│  SeigManager    │      │
│  │   (L2 Config)   │    │   (L1↔L2 Bridge)│    │ (onBridgedTON   │      │
│  └─────────────────┘    └────────┬────────┘    │  Change Callback)│      │
│                                  │              └─────────────────┘      │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                     DisputeGameFactory                              │ │
│  │                                                                      │ │
│  │  create() ──► Create FaultDisputeGame                              │ │
│  │           ──► Call RAT.triggerAttentionTest()                      │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                      FaultDisputeGame                               │ │
│  │                                                                      │ │
│  │  - Fraud Proof processing                                           │ │
│  │  - resolveClaim() ──► RAT.resolveClaim() (when challenger wins)    │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Data Flow

### 5.1 Seigniorage Distribution Data Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          Seigniorage Distribution Flow                      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. updateSeigniorage() call                                               │
│     │                                                                       │
│     ▼                                                                       │
│  2. L1BridgeRegistry.layer2TVL() ──► Query Bridged TON                     │
│     │                                                                       │
│     ▼                                                                       │
│  3. SeigManager.getSequencerStaked() ──► Query staking                     │
│     │                                                                       │
│     ▼                                                                       │
│  4. Eligibility check: T_i ≥ max(θ·B_i, D_sequencer)                       │
│     │                                                                       │
│     ▼                                                                       │
│  5. Hyperbolic calculation: y(x) = L · (x / (k + x))                      │
│     │                                                                       │
│     ▼                                                                       │
│  6. L2 seigniorage: S_i = y(x) · (B̃_i / x)                                │
│     │                                                                       │
│     ├──► Sequencer: (1-α) · S_i ──► OperatorManager                        │
│     │                                                                       │
│     └──► Validator: α · S_i ──► ValidatorReward.distributeL2Rewards()     │
│                              │                                              │
│                              ├──► |V_i| > 0: Equal distribution to validators│
│                              │                                              │
│                              └──► |V_i| = 0: DAO Treasury                  │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Validator Registration Data Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           Validator Registration Flow                       │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Method 1: Direct registerValidator call                                    │
│  1. Call RAT.registerValidator(systemConfig)                                │
│     │                                                                       │
│     ▼                                                                       │
│  2. Check current staking amount: stakeOf(layer2, validator)                 │
│     │                                                                       │
│     ├─ Staking amount >= D_min: Register validator immediately             │
│     │   │                                                                   │
│     │   ▼                                                                   │
│     │   Activate validator + emit event: ValidatorRegistered                │
│     │                                                                       │
│     └─ Staking amount < D_min: Registration fails (insufficient collateral)│
│                                                                             │
│  Method 2: Use approveAndCall (when collateral insufficient)                │
│  1. Call TON.approveAndCall(RAT, amount, data)                              │
│     │                                                                       │
│     │ data = [SystemConfig address] (32 bytes)                             │
│     ▼                                                                       │
│  2. RAT.onApprove() called                                                  │
│     │                                                                       │
│     ▼                                                                       │
│  3. RAT stakes TON through DepositManager                                  │
│     │                                                                       │
│     ▼                                                                       │
│  4. Activate validator + emit event: ValidatorRegistered                    │
│                                                                             │
│  Key Features:                                                              │
│  - V3: Uses existing staking amount (coinage) as validator collateral       │
│  - If collateral insufficient, stake through DepositManager                │
│  - RAT does not hold collateral directly                                    │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 Validator Deactivation/Re-registration Data Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        Validator Deactivation/Re-registration Flow         │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Validator Deactivation (Voluntary):                                        │
│  1. Call RAT.deactivateValidator(systemConfig)                              │
│     │                                                                       │
│     ▼                                                                       │
│  2. Remove from validators array (O(n) - deactivator pays gas)             │
│     │                                                                       │
│     ▼                                                                       │
│  3. isActive = false                                                        │
│     │                                                                       │
│     ▼                                                                       │
│  4. Emit event: ValidatorDeactivated                                       │
│                                                                             │
│  - Can deactivate even if RAT test in progress                             │
│  - bondAmount already pre-deducted, slashing guaranteed                    │
│  - Collateral remains in coinage (withdraw through DepositManager)         │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────────│
│                                                                             │
│  Validator Removal (Automatic):                                             │
│  1. At triggerAttentionTest:                                               │
│     After bondAmount deduction, remaining < threshold                      │
│     │                                                                       │
│     ├─ threshold = C_off (relaxedValidatorCheck=true)                      │
│     └─ threshold = D_min (relaxedValidatorCheck=false)                      │
│                                                                             │
│  2. Remove from validators array                                            │
│     │                                                                       │
│     ▼                                                                       │
│  3. isActive = false                                                        │
│                                                                             │
│  - SeigManager.onWithdraw rejects withdrawal but does not remove validator  │
│    (Enforces condition: balance after withdrawal >= D_min)                 │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────────│
│                                                                             │
│  Validator Re-registration (Manual):                                        │
│  1. Replenish collateral: Deposit D_min or more via DepositManager.deposit()│
│     │                                                                       │
│     ▼                                                                       │
│  2. Call RAT.registerValidator(systemConfig)                               │
│     │                                                                       │
│     ├─ Check isActive = false status                                       │
│     ├─ Check collateral >= D_min                                           │
│     │                                                                       │
│     ▼                                                                       │
│  3. isActive = true (reactivated)                                           │
│                                                                             │
│  - Can re-register even if RAT test in progress                            │
│  - Collateral in coinage allows slashing processing                        │
│  - V3: Validator rewards managed separately by ValidatorReward contract     │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────────│
│                                                                             │
│  Validator Reactivation (Automatic):                                        │
│  1. Restore collateral (evidence submission or challenge win)              │
│     │                                                                       │
│     ▼                                                                       │
│  2. Automatic reactivation attempt inside submitEvidence() or resolveClaim()│
│     │                                                                       │
│     ├─ Check isActive = false                                              │
│     ├─ Check restored collateral >= threshold                              │
│     │  └─ Threshold: relaxedValidatorCheck ? C_off : D_min                 │
│     │                                                                       │
│     ▼                                                                       │
│  3. isActive = true (automatic reactivation)                                │
│                                                                             │
│  - If collateral below threshold, not reactivated (manual re-registration needed)│
│  - Emits ValidatorReactivated event on reactivation                         │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Event-Based Communication

### 6.1 Key Events

| Contract | Event | Purpose |
|----------|-------|---------|
| SeigManager | `V3SeigniorageDistributed` | Seigniorage distribution completed |
| SeigManager | `EligibilityChanged` | L2 eligibility changed |
| RAT | `AttentionTestTriggered` | RAT test started |
| RAT | `EvidenceSubmitted` | Evidence submission completed |
| RAT | `ValidatorSlashed` | Validator slashed |
| ValidatorReward | `L2RewardDistributed` | Validator reward distributed |
| SeigManager | `SequencerSlashed` | Sequencer slashed |

### 6.2 Off-chain Monitoring

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         Off-chain Monitoring                                │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Validator Client:                                                          │
│                                                                             │
│  1. Subscribe to RAT.AttentionTestTriggered event                           │
│     │                                                                       │
│     ▼                                                                       │
│  2. Check if selected validator (validator == myAddress)                    │
│     │                                                                       │
│     ▼                                                                       │
│  3. Verify that L2 batch                                                    │
│     │                                                                       │
│     ▼                                                                       │
│  4. Call RAT.submitEvidence()                                               │
│                                                                             │
│                                                                             │
│  Sequencer Client:                                                          │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Monitoring Targets                                                   │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ 1. SeigManager.EligibilityChanged event                             │   │
│  │    → Detect eligibility status change                                │   │
│  │    → Add collateral when eligible=false                              │   │
│  │                                                                      │   │
│  │ 2. SeigManager.SequencerSlashed event                               │   │
│  │    → Slashing occurred, isActive=false                               │   │
│  │    → Re-registration needed                                          │   │
│  │                                                                      │   │
│  │ 3. Bridged TON changes (TYPE 1/2 need direct check)                  │   │
│  │    → Call SeigManager.checkCurrentEligibility(layer2)                │   │
│  │    → Add collateral when eligible=false                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Sequencer Status Distinction                                         │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ 1. Sequencer Registration Status (status in Layer2Manager)           │   │
│  │    - 0: none (not registered)                                        │   │
│  │    - 1: registered                                                   │   │
│  │    - 2: paused                                                       │   │
│  │                                                                      │   │
│  │ 2. Seigniorage Eligibility Status (isEligible in SeigManager)       │   │
│  │    - false when T_i < max(θ·B_i, D_sequencer)                       │   │
│  │    - Whether staking conditions met                                  │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ status      │ isEligible │ Status                                   │   │
│  │─────────────┼────────────┼──────────────────────────────────────────│   │
│  │ registered  │   true     │ Receiving seigniorage                    │   │
│  │ registered  │   false    │ Registered, insufficient collateral      │   │
│  │ paused      │     -      │ Paused (no seigniorage)                  │   │
│  │ none        │     -      │ Not registered                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Functions Changing Sequencer Registration Status (status)           │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ Layer2Manager.registerCandidateAddOn()                              │   │
│  │   → status = 1 (registered)                                         │   │
│  │                                                                      │   │
│  │ L1BridgeRegistry.rejectCandidateAddOn()                             │   │
│  │   → status = 2 (paused)                                             │   │
│  │                                                                      │   │
│  │ L1BridgeRegistry.restoreCandidateAddOn()                            │   │
│  │   → status = 1 (registered)                                         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Functions Changing Seigniorage Eligibility Status (isEligible)      │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ DepositManager.deposit()                                            │   │
│  │   → SeigManager.onDeposit() called                                  │   │
│  │   → Add collateral, isEligible can be restored                      │   │
│  │                                                                      │   │
│  │ DepositManager.requestWithdrawal()                                  │   │
│  │   → SeigManager.onWithdraw() called (check min collateral)          │   │
│  │   → Eligibility re-evaluated on next updateSeigniorage()            │   │
│  │                                                                      │   │
│  │ DepositManager.withdrawAndDepositL2()                               │   │
│  │   → SeigManager.onWithdraw() called (L1 withdrawal)                 │   │
│  │   → SeigManager.onStakingChange() called (immediate re-evaluation)  │   │
│  │   → Decrease collateral, isEligible can be lost                     │   │
│  │                                                                      │   │
│  │ onBridgedTonChange() [TYPE 3 auto-call]                             │   │
│  │   → Re-evaluate eligibility on Bridged TON change                    │   │
│  │   → Auto-update isEligible status                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Security Architecture

### 7.1 Access Control

```
┌────────────────────────────────────────────────────────────────────────────┐
│                            Access Control                                   │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Owner/Admin (DAOCommittee):                                                │
│  - Parameter settings (d, θ, α, k, π_a, C_off, etc.)                      │
│  - Contract address settings                                               │
│  - V3 migration execution                                                  │
│  - Pause/resume                                                             │
│                                                                             │
│  onlyDepositManager:                                                        │
│  - SeigManager.onDeposit()                                                 │
│  - SeigManager.onWithdraw()                                                │
│  - SeigManager.onStakingChange()                                           │
│                                                                             │
│  onlySeigManager:                                                           │
│  - ValidatorReward.distributeL2Rewards()                                   │
│                                                                             │
│  whenV3Active + internal portal verification:                              │
│  - SeigManager.onBridgedTonChange()                                        │
│    → whenV3Active: Only callable after V3 migration                        │
│    → Internal verification: Check if msg.sender is registered OptimismPortal│
│                                                                             │
│  onlySelectedValidator:                                                     │
│  - RAT.submitEvidence()                                                    │
│    → Only callable by selected validator (test.validatorAddress)           │
│                                                                             │
│  Permissionless:                                                            │
│  - SeigManager.updateSeigniorage()                                         │
│  - SeigManager.slashSequencerByGame()                                      │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Reentrancy Prevention

```solidity
// ifFree modifier (ReentrancyGuard)
modifier ifFree() {
    require(!_lock, "locked");
    _lock = true;
    _;
    _lock = false;
}
```

---

## 8. Related Documents

- [01-system-overview.md](./01-system-overview.md): System Overview
- [03-contract-structure.md](./03-contract-structure.md): Contract Structure
- [04-contract-roles.md](./04-contract-roles.md): Contract Roles
- [05-actors.md](./05-actors.md): Actor Definitions
- [06-function-specs.md](./06-function-specs.md): Detailed Function Descriptions
